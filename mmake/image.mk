rootfs-stage: programs drivers fonts filesystem-inputs msign-tool
	@watch scripts/mmake/stage-rootfs.sh
	@watch scripts/mmake/development-users.db
	@output $(MMAKE_OUT)/image/rootfs/.ready
	$(SCRIPTS)/mmake/stage-rootfs.sh $(ROOT) $(MMAKE_OUT) $(MSIGN)

initfs-stage: core-service cexts rootfs
	@watch boot/config/kernel.conf
	@watch scripts/mmake/stage-initfs.sh
	@output $(MMAKE_OUT)/image/initfs/.ready
	$(SCRIPTS)/mmake/stage-initfs.sh $(ROOT) $(MMAKE_OUT)

rootfs: rootfs-stage config
	@watch scripts/mmake/make-ext2-image.sh
	@watch scripts/mmake/sync-ext2.py
	@output $(MMAKE_OUT)/image/rootfs.img
	$(SCRIPTS)/mmake/make-ext2-image.sh $(MMAKE_OUT)/image/rootfs $(MMAKE_OUT)/image/rootfs.img rootfs $(ROOT)/.config

initfs: initfs-stage config
	@watch scripts/mmake/make-ext2-image.sh
	@watch scripts/mmake/sync-ext2.py
	@output $(MMAKE_OUT)/image/initfs.img
	$(SCRIPTS)/mmake/make-ext2-image.sh $(MMAKE_OUT)/image/initfs $(MMAKE_OUT)/image/initfs.img initfs $(ROOT)/.config

esp: bootloader kernel initfs config
	@watch scripts/mmake/make-esp-image.sh
	@output $(MMAKE_OUT)/image/esp.img
	$(SCRIPTS)/mmake/make-esp-image.sh $(ROOT) $(MMAKE_OUT)

disk-image: esp rootfs config
	@watch scripts/mmake/make-disk-image.sh
	@watch scripts/mmake/patch-disk-partition.py
	@output $(MMAKE_OUT)/image/disk.img
	$(SCRIPTS)/mmake/make-disk-image.sh $(ROOT) $(MMAKE_OUT)

# Separate, non-release A/B partition prototype. Never replace `disk-image`.
boot-selection-seed:
	@watch boot/crates/boot-selection/Cargo.toml
	@watch boot/crates/boot-selection/src/lib.rs
	@watch boot/crates/boot-selection/src/storage.rs
	@watch boot/crates/boot-selection/src/bin/seed.rs
	@output $(MMAKE_OUT)/components/boot-selection-seed
	mkdir -p $(MMAKE_OUT)/components
	cargo build --offline --release --manifest-path $(ROOT)/boot/crates/boot-selection/Cargo.toml --target-dir $(MMAKE_OUT)/targets/boot-selection-host --bin boot-selection-seed
	install -m 0755 $(MMAKE_OUT)/targets/boot-selection-host/release/boot-selection-seed $(MMAKE_OUT)/components/boot-selection-seed

boot-selection-confirm-test:
	@watch boot/crates/boot-selection/Cargo.toml
	@watch boot/crates/boot-selection/src/lib.rs
	@watch boot/crates/boot-selection/src/storage.rs
	@watch boot/crates/boot-selection/src/bin/confirm_test.rs
	@output $(MMAKE_OUT)/components/boot-selection-confirm-test
	mkdir -p $(MMAKE_OUT)/components
	cargo build --offline --release --manifest-path $(ROOT)/boot/crates/boot-selection/Cargo.toml --target-dir $(MMAKE_OUT)/targets/boot-selection-host --bin boot-selection-confirm-test
	install -m 0755 $(MMAKE_OUT)/targets/boot-selection-host/release/boot-selection-confirm-test $(MMAKE_OUT)/components/boot-selection-confirm-test

boot-selection-gpt-probe:
	@watch boot/crates/boot-selection/Cargo.toml
	@watch boot/crates/boot-selection/src/lib.rs
	@watch boot/crates/boot-selection/src/gpt_identity.rs
	@watch boot/crates/boot-selection/src/bin/gpt_probe.rs
	@output $(MMAKE_OUT)/components/boot-selection-gpt-probe
	mkdir -p $(MMAKE_OUT)/components
	cargo build --offline --release --manifest-path $(ROOT)/boot/crates/boot-selection/Cargo.toml --target-dir $(MMAKE_OUT)/targets/boot-selection-host --bin boot-selection-gpt-probe
	install -m 0755 $(MMAKE_OUT)/targets/boot-selection-host/release/boot-selection-gpt-probe $(MMAKE_OUT)/components/boot-selection-gpt-probe

system-image-sign-tool:
	@watch boot/Cargo.toml
	@watch boot/crates/system-image/**
	@output $(MMAKE_OUT)/components/system-image-sign
	cargo build --offline --release --manifest-path $(ROOT)/boot/Cargo.toml --target-dir $(MMAKE_OUT)/targets/system-image-host --package mochios-system-image --features std --bin system-image-sign
	install -m 0755 $(MMAKE_OUT)/targets/system-image-host/release/system-image-sign $(MMAKE_OUT)/components/system-image-sign

system-slot-image-tool:
	@watch boot/Cargo.toml
	@watch boot/crates/system-image/**
	@output $(MMAKE_OUT)/components/system-slot-image
	cargo build --offline --release --manifest-path $(ROOT)/boot/Cargo.toml --target-dir $(MMAKE_OUT)/targets/system-image-host --package mochios-system-image --features std --bin system-slot-image
	install -m 0755 $(MMAKE_OUT)/targets/system-image-host/release/system-slot-image $(MMAKE_OUT)/components/system-slot-image

ab-esp: bootloader kernel initfs
	@watch scripts/mmake/make-ab-esp-image.sh
	@output $(MMAKE_OUT)/image/ab-esp.img
	bash $(SCRIPTS)/mmake/make-ab-esp-image.sh $(ROOT) $(MMAKE_OUT)

ab-layout-image: ab-esp rootfs boot-selection-seed system-image-sign-tool config
	@watch scripts/mmake/build-ab-layout-image.sh
	@output $(MMAKE_OUT)/image/ab-layout.img
	bash $(SCRIPTS)/mmake/build-ab-layout-image.sh $(ROOT) $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed $(MMAKE_OUT)/components/system-image-sign

ab-slot-b-image: ab-layout-image boot-selection-seed
	@watch scripts/mmake/build-ab-slot-b-image.sh
	@output $(MMAKE_OUT)/image/ab-slot-b.img
	bash $(SCRIPTS)/mmake/build-ab-slot-b-image.sh $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed

ab-trial-b-image: ab-layout-image boot-selection-seed
	@watch scripts/mmake/build-ab-slot-b-image.sh
	@output $(MMAKE_OUT)/image/ab-trial-b.img
	bash $(SCRIPTS)/mmake/build-ab-slot-b-image.sh $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed trial

artifacts: disk-image initfs kernel bootloader
	@watch scripts/mmake/collect-artifacts.sh
	@output $(OUT)/artifacts/disk.img
	@output $(OUT)/artifacts/initfs.img
	@output $(OUT)/artifacts/kernel.elf
	@output $(OUT)/artifacts/BOOTX64.EFI
	@output $(OUT)/artifacts/SHA256SUMS
	$(SCRIPTS)/mmake/collect-artifacts.sh $(ROOT) $(MMAKE_OUT)

image: artifacts

full: image

run: image
	@always
	$(SCRIPTS)/runner.sh

run-existing:
	@always
	test -f $(OUT)/artifacts/disk.img
	$(SCRIPTS)/runner.sh

measure-kernel-size: image
	@watch scripts/measure-kernel-size.pl
	@output $(OUT)/metrics/kernel-size.json
	mkdir -p $(OUT)/metrics
	perl $(SCRIPTS)/measure-kernel-size.pl --kernel $(OUT)/artifacts/kernel.elf --output $(OUT)/metrics/kernel-size.json

mdriver:
	@always
	make -C $(ROOT)/mboot/mdriver build

mboot-image: image mdriver
	@always
	make -C $(ROOT)/mboot image CONFIG=$(ROOT)/mboot/config/intel-hardware.toml MNU_DIR=$(ROOT)/core MOCHIOS_SYSTEM_DIR=$(ROOT)/boot IMAGE=$(OUT)/mochiOS.img PXE_DIR=$(OUT)/pxe UEFI_NET_DIR=$(OUT)/uefi-net MDRIVER_KERNEL=$(ROOT)/mboot/mdriver/output/artifacts/vmlinux MDRIVER_INITRAMFS=$(ROOT)/mboot/mdriver/output/artifacts/initramfs.cpio MOCHIOS_INITFS=$(OUT)/artifacts/initfs.img MOCHIOS_ROOTFS=$(OUT)/image-build/rootfs.img

release: full mboot-image
	@always
	mkdir -p $(OUT)/releases
	cp --reflink=auto --sparse=always $(OUT)/mochiOS.img $(OUT)/releases/mochiOS.img.new
	chmod 0644 $(OUT)/releases/mochiOS.img.new
	mv $(OUT)/releases/mochiOS.img.new $(OUT)/releases/mochiOS.img

clean:
	@always
	rm -rf $(OUT)
	rm -rf $(ROOT)/.mmake

clean-runner:
	@always
	rm -rf $(OUT)/runner
