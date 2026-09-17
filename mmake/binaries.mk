msh: runtime rust-sysroot
	@watch binaries/msh/Cargo.toml
	@watch binaries/msh/Cargo.lock
	@watch binaries/msh/src/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/msh
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/binaries/msh/Cargo.toml --bin msh

coreutils: runtime rust-sysroot
	@watch binaries/coreutils/Cargo.toml
	@watch binaries/coreutils/Cargo.lock
	@watch binaries/coreutils/src/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/mperf
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/mpk
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/net
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/ls
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/useradd
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/binaries/coreutils/Cargo.toml --bins

rust-std-demo: runtime rust-sysroot
	@watch user/apps/rust-std-demo/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/rust-std-demo
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/user/apps/rust-std-demo/Cargo.toml --bin rust-std-demo

binaries-bundle: runtime rust-sysroot
	@watch binaries/msh/Cargo.toml
	@watch binaries/msh/Cargo.lock
	@watch binaries/msh/src/**
	@watch binaries/msh/resources/**
	@watch binaries/msh/manifest.toml
	@watch binaries/coreutils/Cargo.toml
	@watch binaries/coreutils/Cargo.lock
	@watch binaries/coreutils/src/**
	@watch binaries/coreutils/manifest.toml
	@watch user/apps/rust-std-demo/Cargo.toml
	@watch user/apps/rust-std-demo/Cargo.lock
	@watch user/apps/rust-std-demo/src/**
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/msh
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/mperf
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/mpk
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/net
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/ls
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/useradd
	@output $(RUST_TARGET_DIR)/x86_64-unknown-mochios/release/rust-std-demo
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/binaries/msh/Cargo.toml --bin msh
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/binaries/coreutils/Cargo.toml --bins
	$(MOCHIOS_CARGO) --manifest-path $(ROOT)/user/apps/rust-std-demo/Cargo.toml --bin rust-std-demo

programs: services apps msh coreutils rust-std-demo
