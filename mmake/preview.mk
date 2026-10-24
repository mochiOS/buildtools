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

preview-edit:
	@always
	$(SCRIPTS)/dev/preview-app.sh edit run $(CARGO_PATCHES)

preview-check:
	@always
	$(SCRIPTS)/dev/preview-app.sh check all $(CARGO_PATCHES)

ui-test:
	@always
	$(SCRIPTS)/dev/preview-app.sh test all $(CARGO_PATCHES)

# Linux desktop and actual host applications, without building the OS image.
ui: ime-dictionary
	@always
	$(SCRIPTS)/dev/desktop-ui.sh run $(CARGO_PATCHES)

ui-check:
	@always
	$(SCRIPTS)/dev/desktop-ui.sh --check $(CARGO_PATCHES)

preview-calendar:
	@always
	$(SCRIPTS)/dev/preview-app.sh calendar run $(CARGO_PATCHES)

preview-calculator:
	@always
	$(SCRIPTS)/dev/preview-app.sh calculator run $(CARGO_PATCHES)

preview-mail:
	@always
	$(SCRIPTS)/dev/preview-app.sh mail run $(CARGO_PATCHES)

preview-keychain:
	@always
	$(SCRIPTS)/dev/preview-app.sh keychain run $(CARGO_PATCHES)
