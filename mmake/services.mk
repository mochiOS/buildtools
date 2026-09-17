capability: runtime rust-sysroot
	@watch services/capability/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/capability
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/capability/Cargo.toml --bin capability

compositor: runtime rust-sysroot
	@watch services/compositor/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/compositor
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/compositor/Cargo.toml --bin compositor

core-service: runtime rust-sysroot
	@watch services/core/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/core
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/core/Cargo.toml --bin core

display: runtime rust-sysroot
	@watch services/display/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/display
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/display/Cargo.toml --bin display

drivers-service: runtime rust-sysroot
	@watch services/drivers/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/drivers
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/drivers/Cargo.toml --bin drivers

input: runtime rust-sysroot
	@watch services/input/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/input
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/input/Cargo.toml --bin input

linux-service: runtime rust-sysroot
	@watch services/linux/**
	@watch services/mboot-protocol/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/linux
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/linux/Cargo.toml --bin linux

logger: runtime rust-sysroot
	@watch services/logger/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/logger
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/logger/Cargo.toml --bin logger

mboot-agent: runtime rust-sysroot
	@watch services/mboot-agent/**
	@watch services/mboot-protocol/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/mboot-agent
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/mboot-agent/Cargo.toml --bin mboot-agent

network: runtime rust-sysroot
	@watch services/network/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/network
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/network/Cargo.toml --bin network

package-service: runtime rust-sysroot
	@watch services/package/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/package
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/package/Cargo.toml --bin package

secure-ui: runtime rust-sysroot viewkit
	@watch services/secure-ui/**
	@watch services/permission-prompt-protocol/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/secure-ui
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/secure-ui/Cargo.toml --bin secure-ui

service-manager: runtime rust-sysroot
	@watch services/service-manager/**
	@watch services/permission-prompt-protocol/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/service-manager
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/service-manager/Cargo.toml --bin service-manager

signature: runtime rust-sysroot
	@watch services/signature/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/signature
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/signature/Cargo.toml --bin signature

tty: runtime rust-sysroot
	@watch services/tty/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/tty
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/tty/Cargo.toml --bin tty

update-service: runtime rust-sysroot
	@watch services/update/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/update
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/update/Cargo.toml --bin update

user-service: runtime rust-sysroot
	@watch services/user/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/user-service
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/user/Cargo.toml --bin user-service

services-bundle: services-inputs runtime rust-sysroot
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/capability
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/compositor
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/core
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/display
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/drivers
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/input
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/linux
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/logger
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/mboot-agent
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/network
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/package
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/secure-ui
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/service-manager
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/signature
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/tty
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/update
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/user-service
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/services/Cargo.toml --workspace

services: capability compositor core-service display drivers-service input linux-service logger mboot-agent network package-service secure-ui service-manager signature tty update-service user-service
