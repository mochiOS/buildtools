# Terminal editor port; consume the configured native toolchain.
vim: runtime-inputs runtime rust-sysroot msign-tool
	@watch .config
	@watch scripts/vim/**
	@watch user/crates/**
	@watch user/runtime/**
	@watch user/libc-port/include/**
	@output $(OUT)/vim-port/release/.ready
	if ! grep -qx 'USER_INSTALL_DEVELOPER_TOOLS=y' $(ROOT)/.config; then mkdir -p $(OUT)/vim-port/release; printf 'disabled\n' > $(OUT)/vim-port/release/.ready; exit 0; fi; env RUSTC=$(RUST_OVERLAY)/bin/rustc RUSTDOC=$(RUST_OVERLAY)/bin/rustdoc CARGO_BUILD_JOBS="${MMAKE_JOBS}" $(RUST_OVERLAY)/bin/cargo build --offline -Z build-std=core,alloc,compiler_builtins -Z json-target-spec $(CARGO_PATCHES) --manifest-path $(ROOT)/user/Cargo.toml -p mochi-user-newlib-runtime --release --target $(RUST_TARGET) --target-dir $(OUT)/vim-port/runtime && python3 $(SCRIPTS)/vim/build.py --sdk $(RUST_SDK) --runtime $(OUT)/vim-port/runtime/x86_64-unknown-mochios/release/libmochi_user_newlib_runtime.a --msign $(MSIGN) --jobs "${MMAKE_JOBS}"

