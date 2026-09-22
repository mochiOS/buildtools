preview-files:
	@always
	$(SCRIPTS)/dev/preview-app.sh files run $(CARGO_PATCHES)

preview-settings:
	@always
	$(SCRIPTS)/dev/preview-app.sh settings run $(CARGO_PATCHES)

preview-binder:
	@always
	$(SCRIPTS)/dev/preview-app.sh binder run $(CARGO_PATCHES)

preview-appstore:
	@always
	$(SCRIPTS)/dev/preview-app.sh appstore run $(CARGO_PATCHES)

preview-check:
	@always
	$(SCRIPTS)/dev/preview-app.sh check all $(CARGO_PATCHES)

ui-test:
	@always
	$(SCRIPTS)/dev/preview-app.sh test all $(CARGO_PATCHES)
