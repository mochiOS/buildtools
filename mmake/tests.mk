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
	QEMU_ACCELERATOR=kvm $(SCRIPTS)/ext2-write-test.sh

ext2-write-test-tcg: image
	@always
	QEMU_ACCELERATOR=tcg $(SCRIPTS)/ext2-write-test.sh

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
