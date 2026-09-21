HOST_TOOLS_DIR := $(MMAKE_OUT)/host-tools
MSIGN := $(HOST_TOOLS_DIR)/release/msign
MPACK := $(HOST_TOOLS_DIR)/release/mpack
PACKAGE ?=
PACKAGE_MANIFEST ?=
PACKAGE_PAYLOAD ?=
SIGNING_CARGO_PATCHES := --config "patch.\"https://github.com/mochiOS/syscalls\".mochios-certificate.path='$(ROOT)/user/crates/certificate'"

msign-tool:
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/msign/**
	@output $(MSIGN)
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo build --offline $(SIGNING_CARGO_PATCHES) --release --manifest-path $(ROOT)/tools/devkit/Cargo.toml --package msign --target-dir $(HOST_TOOLS_DIR)

msign-elf-test:
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/msign/**
	@always
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo test --offline $(SIGNING_CARGO_PATCHES) --manifest-path $(ROOT)/tools/devkit/Cargo.toml --package msign --target-dir $(HOST_TOOLS_DIR) elf

msign-test:
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/msign/**
	@always
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo test --offline $(SIGNING_CARGO_PATCHES) --manifest-path $(ROOT)/tools/devkit/Cargo.toml --package msign --target-dir $(HOST_TOOLS_DIR)

msign-elf-format:
	@watch tools/devkit/crates/msign/src/cli.rs
	@watch tools/devkit/crates/msign/src/main.rs
	@watch tools/devkit/crates/msign/src/commands/mod.rs
	@watch tools/devkit/crates/msign/src/commands/elf.rs
	@watch tools/devkit/crates/msign/src/elf_signature.rs
	@always
	rustfmt --edition 2021 --config skip_children=true $(ROOT)/tools/devkit/crates/msign/src/cli.rs $(ROOT)/tools/devkit/crates/msign/src/main.rs $(ROOT)/tools/devkit/crates/msign/src/commands/mod.rs $(ROOT)/tools/devkit/crates/msign/src/commands/elf.rs $(ROOT)/tools/devkit/crates/msign/src/elf_signature.rs

mpack-tool:
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/mpack/**
	@output $(MPACK)
	env CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}" CARGO_BUILD_JOBS=$(JOBS) cargo build --offline $(SIGNING_CARGO_PATCHES) --release --manifest-path $(ROOT)/tools/devkit/Cargo.toml --package mpack --target-dir $(HOST_TOOLS_DIR)

# PACKAGE is deliberately the only build-time input.  Key and certificate paths
# are selected by msign from the per-user identity store and never belong in the
# project build graph.
sign-package: msign-tool
	@always
	$(MSIGN) package sign-auto $(PACKAGE)

# Generic Kome-independent development package pipeline. Component build
# targets may depend on this target after producing PACKAGE_PAYLOAD.
package-and-sign: mpack-tool msign-tool
	@always
	$(MPACK) create --manifest "$(PACKAGE_MANIFEST)" --payload "$(PACKAGE_PAYLOAD)" --output "$(PACKAGE)" --force
	$(MSIGN) package sign-auto "$(PACKAGE)"
