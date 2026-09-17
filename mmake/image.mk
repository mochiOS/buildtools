rootfs-stage: programs drivers fonts filesystem-inputs msign-tool
	@watch scripts/mmake/stage-rootfs.sh
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
	@output $(MMAKE_OUT)/image/disk.img
	$(SCRIPTS)/mmake/make-disk-image.sh $(ROOT) $(MMAKE_OUT)

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
