smoke-log-test:
	@watch scripts/check-smoke-logs.sh
	@watch scripts/tests/smoke-log-check-test.sh
	@always
	$(SCRIPTS)/tests/smoke-log-check-test.sh

smoke-test: image smoke-log-test
	@always
	$(SCRIPTS)/smoke-test.sh

smoke-test-kvm: image smoke-log-test
	@always
	QEMU_ACCELERATOR=kvm $(SCRIPTS)/smoke-test.sh

smoke-test-tcg: image smoke-log-test
	@always
	QEMU_ACCELERATOR=tcg $(SCRIPTS)/smoke-test.sh

ext2-write-test: image
	@always
	QEMU_ACCELERATOR=kvm MSIGN="$(MSIGN)" $(SCRIPTS)/ext2-write-test.sh

ext2-write-fixture-test: image
	@always
	EXT2_TEST_PREPARE_ONLY=1 MSIGN="$(MSIGN)" $(SCRIPTS)/ext2-write-test.sh

ext2-cext-test:
	@always
	cargo test --offline --manifest-path $(ROOT)/cexts/Cargo.toml --target-dir $(MMAKE_OUT)/targets/ext2-cext-host --config "patch.\"https://github.com/mochiOS/cexts\".mochi-cext-abi.path='$(ROOT)/cexts/crates/cext-abi'" -p mochi-ext2-cext --lib

ext2-write-test-tcg: image
	@always
	QEMU_ACCELERATOR=tcg MSIGN="$(MSIGN)" $(SCRIPTS)/ext2-write-test.sh

tls-http-smoke-test: config smoke-log-test
	@always
	$(SCRIPTS)/tls-http-smoke-test.sh

accounts-https-smoke-test: image smoke-log-test
	@always
	$(SCRIPTS)/accounts-https-smoke-test.sh

developer-pki-sync-smoke-test:
	@always
	$(SCRIPTS)/developer-pki-sync-smoke-test.sh

developer-pki-production-e2e:
	@always
	$(SCRIPTS)/developer-pki-production-e2e.sh

diagnostics-test:
	@always
	cargo test --offline --config "patch.\"https://github.com/mochiOS/syscalls\".mochios-net-device-protocol.path='$(ROOT)/user/crates/net-device-protocol'" --manifest-path $(ROOT)/services/update/Cargo.toml --lib

net-device-protocol-test:
	@always
	cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/user/crates/net-device-protocol/Cargo.toml --lib

http-client-test:
	@always
	cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/user/crates/http-client/Cargo.toml --lib

boot-selection-test:
	@always
	cargo test --offline --manifest-path $(ROOT)/boot/crates/boot-selection/Cargo.toml --lib

system-image-test:
	@always
	cargo test --offline --manifest-path $(ROOT)/boot/Cargo.toml --package mochios-system-image --lib

ab-slot-selection-test:
	@always
	cargo test --offline --manifest-path $(ROOT)/core/crates/abi/Cargo.toml --lib
	cargo test --offline --manifest-path $(ROOT)/cexts/Cargo.toml -p mochi-ext2-cext --lib --config "patch.\"https://github.com/mochiOS/cexts\".mochi-cext-abi.path='$(ROOT)/cexts/crates/cext-abi'"

ab-layout-test: ab-layout-image boot-selection-gpt-probe
	@watch scripts/tests/ab-layout-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-layout-test.sh $(MMAKE_OUT)/image/ab-layout.img $(MMAKE_OUT)/image/ab-esp.img $(MMAKE_OUT)/image/rootfs.img $(MMAKE_OUT)/components/boot-selection-seed $(MMAKE_OUT)/components/kernel.elf $(MMAKE_OUT)/components/kernel.meta $(MMAKE_OUT)/image/initfs.img $(MMAKE_OUT)/components/boot-selection-gpt-probe

ab-layout-smoke-test-kvm: ab-layout-test smoke-log-test
	@watch scripts/tests/ab-layout-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-layout-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-layout.img

system-signature-smoke-test-kvm: ab-layout-test smoke-log-test
	@watch scripts/tests/system-signature-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/system-signature-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-layout.img

boot-assets-signature-smoke-test-kvm: ab-layout-test smoke-log-test
	@watch scripts/tests/system-signature-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/system-signature-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-layout.img kernel
	bash $(SCRIPTS)/tests/system-signature-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-layout.img initfs

secure-boot-smoke-test-kvm: ab-layout-test smoke-log-test
	@watch scripts/tests/secure-boot-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/secure-boot-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-layout.img $(MMAKE_OUT)/targets/bootloader/x86_64-unknown-uefi/release/boot.efi

anti-rollback-smoke-test-kvm: ab-layout-test smoke-log-test
	@watch scripts/tests/anti-rollback-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/anti-rollback-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-layout.img $(MMAKE_OUT)/components/system-image-sign

system-data-smoke-test-kvm: ab-layout-test smoke-log-test
	@watch scripts/tests/system-data-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/system-data-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-layout.img $(MMAKE_OUT)/components/system-image-sign

ab-slot-b-test: ab-slot-b-image ab-layout-test
	@watch scripts/tests/ab-slot-b-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-slot-b-test.sh $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed

ab-trial-b-test: ab-trial-b-image ab-layout-test
	@watch scripts/tests/ab-slot-b-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-slot-b-test.sh $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed trial

ab-trial-confirm-test: ab-trial-b-test boot-selection-confirm-test
	@watch scripts/tests/ab-trial-confirm-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-trial-confirm-test.sh $(MMAKE_OUT) $(MMAKE_OUT)/components/boot-selection-seed $(MMAKE_OUT)/components/boot-selection-confirm-test

ab-slot-b-smoke-test-kvm: ab-slot-b-test smoke-log-test
	@watch scripts/tests/ab-layout-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-layout-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-slot-b.img B

ab-boot-slot-smoke-test-kvm: ab-slot-b-test smoke-log-test
	@watch scripts/tests/ab-layout-kvm-test.sh
	@watch scripts/tests/ab-boot-slot-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-boot-slot-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-slot-b.img

ab-trial-rollback-smoke-test-kvm: ab-trial-b-test smoke-log-test
	@watch scripts/tests/ab-layout-kvm-test.sh
	@watch scripts/tests/ab-trial-rollback-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-trial-rollback-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-trial-b.img

ab-trial-confirm-smoke-test-kvm: ab-trial-confirm-test smoke-log-test
	@watch scripts/tests/ab-layout-kvm-test.sh
	@watch scripts/tests/ab-trial-confirm-kvm-test.sh
	@always
	bash $(SCRIPTS)/tests/ab-trial-confirm-kvm-test.sh $(ROOT) $(MMAKE_OUT)/image/ab-trial-b.img $(MMAKE_OUT)/components/boot-selection-confirm-test
workspace-test:
	@always
	cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/user/crates/workspace-protocol/Cargo.toml --lib
	cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/services/workspace/Cargo.toml --bin workspace-service

service-manager-test:
	@always
	cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/services/service-manager/Cargo.toml --lib
