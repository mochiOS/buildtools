viewkit: viewkit-inputs fonts runtime rust-sysroot
	@output $(MMAKE_OUT)/components/viewkit.stamp
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/libraries/viewkit/Cargo.toml --lib
	mkdir -p $(MMAKE_OUT)/components
	touch $(MMAKE_OUT)/components/viewkit.stamp

appstore: appstore-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/appstore
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/appstore/Cargo.toml --bin appstore

binder: binder-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/binder
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/binder/Cargo.toml --bin binder

files: files-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/files
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/file/Cargo.toml --bin files

installer: installer-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/installer
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/installer/Cargo.toml --bin installer

settings: settings-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/settings
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/settings/Cargo.toml --bin settings

terminal: terminal-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/terminal
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/terminal/Cargo.toml --bin terminal

test-app: viewkit
	@watch applications/test.app/Cargo.toml
	@watch applications/test.app/Cargo.lock
	@watch applications/test.app/src/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/test_app
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/test.app/Cargo.toml --bin test_app

apps-bundle: applications-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/appstore
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/binder
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/files
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/installer
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/settings
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/terminal
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/test_app
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/appstore/Cargo.toml --bin appstore
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/binder/Cargo.toml --bin binder
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/file/Cargo.toml --bin files
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/installer/Cargo.toml --bin installer
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/settings/Cargo.toml --bin settings
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/terminal/Cargo.toml --bin terminal
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/test.app/Cargo.toml --bin test_app

apps: apps-bundle
