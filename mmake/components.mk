fonts: fonts-inputs
	@watch scripts/mmake/build-fonts.sh
	@output $(ROOT)/libraries/fonts/out/fonts/.installed
	$(SCRIPTS)/mmake/build-fonts.sh $(ROOT)

ime-dictionary:
	@watch build/ime/ja.mime.sha256
	@output $(MMAKE_OUT)/components/ime/ja.mime
	mkdir -p $(MMAKE_OUT)/components/ime
	expected=`cut -d' ' -f1 $(ROOT)/build/ime/ja.mime.sha256`; output=$(MMAKE_OUT)/components/ime/ja.mime; if test -f "$output" && printf '%s  %s\n' "$expected" "$output" | sha256sum -c - >/dev/null 2>&1; then exit 0; fi; temporary="$output.new"; rm -f "$temporary"; curl --fail --location --retry 3 --output "$temporary" https://storage.mochios.org/mochios/ime/ja.mime; printf '%s  %s\n' "$expected" "$temporary" | sha256sum -c -; test `stat -c %s "$temporary"` -eq 163123094; chmod 0644 "$temporary"; mv "$temporary" "$output"

runtime: runtime-inputs
	@output $(OUT)/newlib-port/sdk/lib/crt0.o
	@output $(OUT)/newlib-port/sdk/lib/libmochi_user_newlib_runtime.a
	@output $(OUT)/newlib-port/sdk/lib/libgcc.a
	@output $(OUT)/newlib-port/sdk/lib/linker.ld
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_NET_OFFLINE=true bash $(ROOT)/user/scripts/build-newlib.sh --newlib-source $(ROOT)/libraries/newlib --output $(OUT)/newlib-port --abi-source $(ROOT)/core/crates/abi --libc-source $(ROOT)/libraries/libc --mboot-protocol-source $(ROOT)/services/mboot-protocol --syscalls-source $(ROOT)/user --toolchain nightly-2026-05-14 --jobs $(JOBS)

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

bootloader: boot-inputs config
	@output $(MMAKE_OUT)/components/BOOTX64.EFI
	mkdir -p $(MMAKE_OUT)/components
	features=uefi-dep; if grep -qx 'DEVELOPMENT_SYSTEM_SIGNATURES=y' $(ROOT)/.config; then features=$features,development-system-key; fi; if grep -qx 'REQUIRE_UEFI_SECURE_BOOT=y' $(ROOT)/.config; then features=$features,require-secure-boot; fi; minimum_build="${MOCHIOS_MINIMUM_BUILD:-}"; if grep -qx 'DEVELOPMENT_UEFI_SIGNING=y' $(ROOT)/.config; then minimum_build="${minimum_build:-1}"; fi; case "$minimum_build" in ''|*[!0-9]*|0) echo 'MOCHIOS_MINIMUM_BUILD must be an explicit positive integer' >&2; exit 1;; esac; MOCHIOS_MINIMUM_BUILD="$minimum_build" RUSTFLAGS='--cfg curve25519_dalek_backend="serial"' cargo +nightly-2026-05-14 build --offline -Z build-std=core,alloc,compiler_builtins --release --target x86_64-unknown-uefi --target-dir $(MMAKE_OUT)/targets/bootloader --config "patch.\"https://github.com/mochiOS/mnu\".mnu-abi.path='$(ROOT)/core/crates/abi'" --manifest-path $(ROOT)/boot/Cargo.toml --features "$features"
	if test -f $(MMAKE_OUT)/targets/bootloader/x86_64-unknown-uefi/release/boot.efi; then unsigned=$(MMAKE_OUT)/targets/bootloader/x86_64-unknown-uefi/release/boot.efi; else unsigned=$(MMAKE_OUT)/targets/bootloader/x86_64-unknown-uefi/release/boot; fi; command -v sbsign >/dev/null; command -v sbverify >/dev/null; if grep -qx 'DEVELOPMENT_UEFI_SIGNING=y' $(ROOT)/.config; then command -v openssl >/dev/null; key=$(MMAKE_OUT)/components/ovmf-development-key.pem; trap 'rm -f -- "$key"' EXIT; openssl pkey -in /usr/share/ovmf/PkKek-1-snakeoil.key -passin pass:snakeoil -out "$key" >/dev/null 2>&1; chmod 0600 "$key"; cert=/usr/share/ovmf/PkKek-1-snakeoil.pem; else key="${MOCHIOS_UEFI_SIGNING_KEY:-}"; cert="${MOCHIOS_UEFI_SIGNING_CERT:-}"; test -n "$key" -a -n "$cert" || { echo 'MOCHIOS_UEFI_SIGNING_KEY and MOCHIOS_UEFI_SIGNING_CERT are required' >&2; exit 1; }; fi; test -r "$key" -a -r "$cert"; sbsign --key "$key" --cert "$cert" --output $(MMAKE_OUT)/components/BOOTX64.EFI.new "$unsigned" >/dev/null; sbverify --cert "$cert" $(MMAKE_OUT)/components/BOOTX64.EFI.new >/dev/null; chmod 0644 $(MMAKE_OUT)/components/BOOTX64.EFI.new; mv $(MMAKE_OUT)/components/BOOTX64.EFI.new $(MMAKE_OUT)/components/BOOTX64.EFI
