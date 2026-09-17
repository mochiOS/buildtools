fonts: fonts-inputs
	@watch scripts/mmake/build-fonts.sh
	@output $(ROOT)/libraries/fonts/out/fonts/.installed
	$(SCRIPTS)/mmake/build-fonts.sh $(ROOT)

runtime: runtime-inputs
	@output $(OUT)/newlib-port/sdk/lib/crt0.o
	@output $(OUT)/newlib-port/sdk/lib/libmochi_user_newlib_runtime.a
	@output $(OUT)/newlib-port/sdk/lib/linker.ld
	env CARGO_HOME=$(MMAKE_CARGO_HOME) CARGO_NET_OFFLINE=true bash $(ROOT)/user/scripts/build-newlib.sh --newlib-source $(ROOT)/libraries/newlib --output $(OUT)/newlib-port --abi-source $(ROOT)/core/crates/abi --toolchain nightly-2026-05-14 --jobs $(JOBS)

rust-sysroot: runtime-inputs
	@watch scripts/mmake/prepare-rust-sysroot.sh
	@output $(OUT)/rust-std/sysroot-overlay/.ready
	$(SCRIPTS)/mmake/prepare-rust-sysroot.sh $(ROOT) $(MMAKE_OUT)

kernel: kernel-inputs
	@output $(MMAKE_OUT)/components/kernel.elf
	@output $(MMAKE_OUT)/components/kernel.debug
	@output $(MMAKE_OUT)/components/kernel.meta
	mkdir -p $(MMAKE_OUT)/components
	toolchain=`sed -n 's/^KERNEL_RUST_TOOLCHAIN=//p' $(ROOT)/.config | tr -d '"' | tail -n1`; features=kernel-bin; if grep -qx 'KERNEL_PERFORMANCE_INSTRUMENTATION=y' $(ROOT)/.config; then features=$features,performance-instrumentation; fi; RUSTFLAGS='--cfg curve25519_dalek_backend="serial"' cargo "+$toolchain" build --offline -Z build-std=core,alloc,compiler_builtins --release --target x86_64-unknown-none --target-dir $(MMAKE_OUT)/targets/kernel --features "$features" --manifest-path $(ROOT)/core/Cargo.toml
	objcopy --only-keep-debug $(MMAKE_OUT)/targets/kernel/x86_64-unknown-none/release/kernel $(MMAKE_OUT)/components/kernel.debug
	objcopy --strip-all $(MMAKE_OUT)/targets/kernel/x86_64-unknown-none/release/kernel $(MMAKE_OUT)/components/kernel.elf
	objcopy --add-gnu-debuglink=$(MMAKE_OUT)/components/kernel.debug $(MMAKE_OUT)/components/kernel.elf
	nm -n --defined-only $(MMAKE_OUT)/targets/kernel/x86_64-unknown-none/release/kernel | awk '$3 == "secondary_cpu_entry" { count++; value=tolower($1) } END { if (count != 1) exit 1; printf "secondary_cpu_entry=0x%s\n", value }' > $(MMAKE_OUT)/components/kernel.meta.new
	mv $(MMAKE_OUT)/components/kernel.meta.new $(MMAKE_OUT)/components/kernel.meta

bootloader: boot-inputs
	@output $(MMAKE_OUT)/components/BOOTX64.EFI
	mkdir -p $(MMAKE_OUT)/components
	RUSTFLAGS='--cfg curve25519_dalek_backend="serial"' cargo +nightly-2026-05-14 build --offline -Z build-std=core,alloc,compiler_builtins --release --target x86_64-unknown-uefi --target-dir $(MMAKE_OUT)/targets/bootloader --config "patch.\"https://github.com/mochiOS/mnu\".mnu-abi.path='$(ROOT)/core/crates/abi'" --manifest-path $(ROOT)/boot/Cargo.toml
	if test -f $(MMAKE_OUT)/targets/bootloader/x86_64-unknown-uefi/release/boot.efi; then install -m 0644 $(MMAKE_OUT)/targets/bootloader/x86_64-unknown-uefi/release/boot.efi $(MMAKE_OUT)/components/BOOTX64.EFI; else install -m 0644 $(MMAKE_OUT)/targets/bootloader/x86_64-unknown-uefi/release/boot $(MMAKE_OUT)/components/BOOTX64.EFI; fi
