HOST_TOOLS_DIR := $(MMAKE_OUT)/host-tools
MSIGN := $(HOST_TOOLS_DIR)/release/msign
MPACK := $(HOST_TOOLS_DIR)/release/mpack
PACKAGE ?=
PACKAGE_MANIFEST ?=
PACKAGE_PAYLOAD ?=

msign-tool:
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/msign/**
	@output $(MSIGN)
	env CARGO_HOME=$(MMAKE_CARGO_HOME) CARGO_BUILD_JOBS=$(JOBS) cargo build --offline --release --manifest-path $(ROOT)/tools/devkit/Cargo.toml --package msign --target-dir $(HOST_TOOLS_DIR)

mpack-tool:
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/mpack/**
	@output $(MPACK)
	env CARGO_HOME=$(MMAKE_CARGO_HOME) CARGO_BUILD_JOBS=$(JOBS) cargo build --offline --release --manifest-path $(ROOT)/tools/devkit/Cargo.toml --package mpack --target-dir $(HOST_TOOLS_DIR)

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
