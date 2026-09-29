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

binder-test: viewkit
	@watch applications/binder/Cargo.toml
	@watch applications/binder/Cargo.lock
	@watch applications/binder/src/**
	@always
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/applications/binder/Cargo.toml --target-dir $(MMAKE_OUT)/targets/binder

edit: edit-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/edit
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/edit/Cargo.toml --bin edit

edit-test: viewkit
	@watch applications/edit/Cargo.toml
	@watch applications/edit/Cargo.lock
	@watch applications/edit/src/**
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/appcore/**
	@always
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/applications/edit/Cargo.toml --target-dir $(MMAKE_OUT)/targets/edit

files: files-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/files
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/file/Cargo.toml --bin files

installer: installer-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/installer
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/installer/Cargo.toml --bin installer

settings: settings-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/settings
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/settings/Cargo.toml --bin settings

system-monitor: system-monitor-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/system-monitor
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/system-monitor/Cargo.toml --bin system-monitor

system-monitor-test: viewkit
	@watch applications/system-monitor/Cargo.toml
	@watch applications/system-monitor/Cargo.lock
	@watch applications/system-monitor/src/**
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/appcore/**
	@always
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/applications/system-monitor/Cargo.toml --target-dir $(MMAKE_OUT)/targets/system-monitor

terra: terra-inputs viewkit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/terra
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/terra/Cargo.toml --bin terra

terra-test: viewkit
	@watch applications/terra/Cargo.toml
	@watch applications/terra/Cargo.lock
	@watch applications/terra/src/**
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/appcore/**
	@always
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo test --offline $(CARGO_PATCHES) --manifest-path $(ROOT)/applications/terra/Cargo.toml --target-dir $(MMAKE_OUT)/targets/terra

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
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/edit
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/files
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/installer
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/settings
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/system-monitor
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/terra
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/terminal
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/test_app
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/appstore/Cargo.toml --bin appstore
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/binder/Cargo.toml --bin binder
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/edit/Cargo.toml --bin edit
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/file/Cargo.toml --bin files
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/installer/Cargo.toml --bin installer
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/settings/Cargo.toml --bin settings
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/system-monitor/Cargo.toml --bin system-monitor
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/terra/Cargo.toml --bin terra
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/terminal/Cargo.toml --bin terminal
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/applications/test.app/Cargo.toml --bin test_app

apps: appstore binder edit files installer settings system-monitor terra terminal test-app
