rootfs-stage: config mdp-workspace-build
	@always
	@watch mdp.assembly.lock
	@watch build/mdp/image.py
	@watch build/mdp/policy.toml
	@watch build/application-sets.toml
	@watch resources/system/**
	@watch resources/libraries/**
	@watch scripts/mmake/development-users.db
	python3 $(ROOT)/build/mdp/image.py --root $(ROOT)

initfs-stage: rootfs
	@watch boot/config/kernel.conf
	@watch scripts/mmake/stage-initfs.sh
	@output $(MMAKE_OUT)/image/initfs/.ready
	$(SCRIPTS)/mmake/stage-initfs.sh $(ROOT) $(MMAKE_OUT)

rootfs: rootfs-stage config
	@watch scripts/mmake/make-ext2-image.sh
	@watch scripts/mmake/sync-ext2.py
	@output $(MMAKE_OUT)/image/rootfs.img
	$(SCRIPTS)/mmake/make-ext2-image.sh $(MMAKE_OUT)/image/rootfs $(MMAKE_OUT)/image/rootfs.img rootfs $(ROOT)/.config

data: rootfs-stage config
	@watch scripts/mmake/make-data-image.sh
	@watch scripts/mmake/sync-ext2.py
	@output $(MMAKE_OUT)/image/data.img
	$(SCRIPTS)/mmake/make-data-image.sh $(ROOT) $(MMAKE_OUT)

initfs: initfs-stage config
	@watch scripts/mmake/make-ext2-image.sh
	@watch scripts/mmake/pack-boot-module.pl
	@watch scripts/mmake/pack-boot-extensions.py
	@watch scripts/mmake/sync-ext2.py
	@output $(MMAKE_OUT)/image/initfs.img
	$(SCRIPTS)/mmake/make-ext2-image.sh $(MMAKE_OUT)/image/initfs $(MMAKE_OUT)/image/initfs.img initfs $(ROOT)/.config

esp: initfs config
	@watch scripts/mmake/make-esp-image.sh
	@output $(MMAKE_OUT)/image/esp.img
	$(SCRIPTS)/mmake/make-esp-image.sh $(ROOT) $(MMAKE_OUT)

disk-image: esp rootfs data config
	@watch scripts/mmake/make-disk-image.sh
	@watch scripts/mmake/patch-disk-partition.py
	@output $(MMAKE_OUT)/image/disk.img
	$(SCRIPTS)/mmake/make-disk-image.sh $(ROOT) $(MMAKE_OUT)

# Separate, non-release A/B partition prototype. Never replace `disk-image`.
# Host image tools are supplied by the boot MDP, never built by the root.
boot-selection-seed: rootfs-stage
boot-selection-confirm-test: rootfs-stage
boot-selection-gpt-probe: rootfs-stage
system-image-sign-tool: rootfs-stage
system-slot-image-tool: rootfs-stage

ab-esp: initfs
	@watch scripts/mmake/make-ab-esp-image.sh
	@output $(MMAKE_OUT)/image/ab-esp.img
	bash $(SCRIPTS)/mmake/make-ab-esp-image.sh $(ROOT) $(MMAKE_OUT)

ab-layout-image: ab-esp rootfs boot-selection-seed system-image-sign-tool system-slot-image-tool config
	@watch scripts/mmake/build-ab-layout-image.sh
	@output $(MMAKE_OUT)/image/ab-layout.img
	bash $(SCRIPTS)/mmake/build-ab-layout-image.sh $(ROOT) $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed $(MMAKE_OUT)/components/system-image-sign $(MMAKE_OUT)/components/system-slot-image

normal-update-payload: ab-layout-image
	@watch scripts/mmake/build-update-payload.sh
	@output $(MMAKE_OUT)/image/mochios-update.moupdate
	bash $(SCRIPTS)/mmake/build-update-payload.sh $(MMAKE_OUT)/image/update-boot.img $(MMAKE_OUT)/image/update-system.img $(MMAKE_OUT)/image/mochios-update.moupdate

ab-slot-b-image: ab-layout-image boot-selection-seed
	@watch scripts/mmake/build-ab-slot-b-image.sh
	@output $(MMAKE_OUT)/image/ab-slot-b.img
	bash $(SCRIPTS)/mmake/build-ab-slot-b-image.sh $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed

ab-trial-b-image: ab-layout-image boot-selection-seed
	@watch scripts/mmake/build-ab-slot-b-image.sh
	@output $(MMAKE_OUT)/image/ab-trial-b.img
	bash $(SCRIPTS)/mmake/build-ab-slot-b-image.sh $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed trial

symbols: rootfs-stage
	@watch scripts/dev/archive-symbols.py
	@watch version.toml
	@output $(MMAKE_OUT)/symbols/index.json
	python3 $(SCRIPTS)/dev/archive-symbols.py --root $(ROOT) --rootfs $(MMAKE_OUT)/image/rootfs --kernel $(MMAKE_OUT)/components/kernel.elf --kernel-debug $(MMAKE_OUT)/components/kernel.debug --store $(MMAKE_OUT)/symbols

artifacts: disk-image initfs symbols
	@watch scripts/mmake/collect-artifacts.sh
	@output $(OUT)/images/system/disk.img
	@output $(OUT)/images/system/initfs.img
	@output $(OUT)/images/system/kernel.elf
	@output $(OUT)/images/system/BOOTX64.EFI
	@output $(OUT)/images/system/SHA256SUMS
	@output $(OUT)/images/system/symbols-index.json
	$(SCRIPTS)/mmake/collect-artifacts.sh $(ROOT) $(MMAKE_OUT)

image: artifacts

full: image

run: image
	@always
	bash $(SCRIPTS)/dev/run-vm.sh

run-existing:
	@always
	test -f $(OUT)/images/system/disk.img
	bash $(SCRIPTS)/dev/run-vm.sh

measure-kernel-size: image
	@watch scripts/measure-kernel-size.pl
	@output $(OUT)/reports/metrics/kernel-size.json
	mkdir -p $(OUT)/reports/metrics
	perl $(SCRIPTS)/measure-kernel-size.pl --kernel $(OUT)/images/system/kernel.elf --output $(OUT)/reports/metrics/kernel-size.json

# Hardware-media production belongs to mBoot's optional MDP producer.
mboot-image: rootfs-stage
	@always
	python3 $(ROOT)/build/mdp/hardware.py --root $(ROOT)

release: full mboot-image
	@always
	mkdir -p $(OUT)/images/releases
	cp --reflink=auto --sparse=always $(OUT)/images/hardware/mochiOS.img $(OUT)/images/releases/mochiOS.img.new
	chmod 0644 $(OUT)/images/releases/mochiOS.img.new
	mv $(OUT)/images/releases/mochiOS.img.new $(OUT)/images/releases/mochiOS.img

clean:
	@always
	rm -rf $(MMAKE_OUT)/image $(MMAKE_OUT)/symbols $(OUT)/images/system $(OUT)/images/installer $(OUT)/images/releases
	rm -rf $(ROOT)/.mmake

clean-runner:
	@always
	rm -rf $(OUT)/runner

# Installer UI is exclusive to this separate, first-boot image. Installer's
# existing write gate is unchanged; this target does not enable disk writes.
installer-rootfs-stage: config mdp-workspace-build
	@always
	@watch mdp.assembly.lock
	@watch build/mdp/image.py
	@watch build/mdp/policy.toml
	@watch build/application-sets.toml
	@watch resources/system/**
	@watch resources/libraries/**
	@watch scripts/mmake/development-users.db
	python3 $(ROOT)/build/mdp/image.py --root $(ROOT) --variant installer

installer-image: installer-rootfs-stage
	@watch scripts/mmake/make-installer-image.sh
	@watch scripts/mmake/make-ext2-image.sh
	@watch scripts/mmake/make-data-image.sh
	@watch scripts/mmake/stage-initfs.sh
	@watch scripts/mmake/make-esp-image.sh
	@watch scripts/mmake/make-disk-image.sh
	@watch scripts/mmake/patch-disk-partition.py
	@watch scripts/mmake/sync-ext2.py
	@watch scripts/mmake/pack-boot-module.pl
	@watch scripts/mmake/pack-boot-extensions.py
	@watch boot/config/kernel.conf
	@output $(MMAKE_OUT)/installer/image/disk.img
	@output $(OUT)/images/installer/disk.img
	bash $(SCRIPTS)/mmake/make-installer-image.sh $(ROOT) $(MMAKE_OUT)

image-applications-test:
	@always
	python3 $(SCRIPTS)/tests/image-applications-test.py
