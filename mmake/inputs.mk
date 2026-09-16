kernel-inputs: config
	@watch .config
	@watch core/Cargo.toml
	@watch core/Cargo.lock
	@watch core/build.rs
	@watch core/src/**
	@watch core/crates/**
	@watch core/kernel.ld
	@watch core/domain.ld
	@watch core/x86_64-mochios.json

boot-inputs: config
	@watch .config
	@watch boot/Cargo.toml
	@watch boot/Cargo.lock
	@watch boot/build.rs
	@watch boot/src/**
	@watch boot/crates/**
	@watch boot/domain.ld
	@watch core/crates/abi/**

fonts-inputs:
	@watch libraries/fonts/fonts.conf
	@watch libraries/fonts/scripts/**

rust-source-state:
	@always
	@output $(MMAKE_OUT)/fingerprints/rust.sha256
	$(SCRIPTS)/mmake/source-fingerprint.sh $(ROOT)/libraries/rust $(MMAKE_OUT)/fingerprints/rust.sha256

newlib-source-state:
	@always
	@output $(MMAKE_OUT)/fingerprints/newlib.sha256
	$(SCRIPTS)/mmake/source-fingerprint.sh $(ROOT)/libraries/newlib $(MMAKE_OUT)/fingerprints/newlib.sha256

runtime-inputs: config rust-source-state newlib-source-state
	@watch .config
	@watch build/rust-std-toolchain
	@watch out/mmake/fingerprints/rust.sha256
	@watch out/mmake/fingerprints/newlib.sha256
	@watch user/Cargo.toml
	@watch user/Cargo.lock
	@watch user/crates/**
	@watch user/targets/**
	@watch user/scripts/**
	@watch libraries/libc/Cargo.toml
	@watch libraries/libc/build.rs
	@watch libraries/libc/src/**
	@watch libraries/libc/newlib/**

viewkit-inputs: runtime-inputs fonts-inputs
	@watch version.toml
	@watch mboot/Cargo.toml
	@watch libraries/viewkit/Cargo.toml
	@watch libraries/viewkit/Cargo.lock
	@watch libraries/viewkit/build.rs
	@watch libraries/viewkit/src/**

services-inputs: runtime-inputs
	@watch services/Cargo.toml
	@watch services/Cargo.lock
	@watch services/capability/**
	@watch services/compositor/**
	@watch services/core/**
	@watch services/display/**
	@watch services/drivers/**
	@watch services/input/**
	@watch services/linux/**
	@watch services/logger/**
	@watch services/mboot-agent/**
	@watch services/mboot-protocol/**
	@watch services/network/**
	@watch services/package/**
	@watch services/permission-prompt-protocol/**
	@watch services/secure-ui/**
	@watch services/service-manager/**
	@watch services/signature/**
	@watch services/tty/**
	@watch services/update/**
	@watch services/user/**

binder-inputs: viewkit-inputs
	@watch applications/binder/Cargo.toml
	@watch applications/binder/Cargo.lock
	@watch applications/binder/src/**
	@watch applications/binder/crates/**
	@watch applications/binder/resources/**
	@watch applications/binder/about.toml
	@watch applications/binder/manifest.toml

files-inputs: viewkit-inputs
	@watch applications/file/Cargo.toml
	@watch applications/file/Cargo.lock
	@watch applications/file/src/**
	@watch applications/file/resources/**
	@watch applications/file/appicon.svg
	@watch applications/file/about.toml
	@watch applications/file/manifest.toml

installer-inputs: viewkit-inputs
	@watch applications/installer/Cargo.toml
	@watch applications/installer/Cargo.lock
	@watch applications/installer/src/**
	@watch applications/installer/appicon.svg
	@watch applications/installer/about.toml
	@watch applications/installer/manifest.toml

settings-inputs: viewkit-inputs
	@watch applications/settings/Cargo.toml
	@watch applications/settings/Cargo.lock
	@watch applications/settings/build.rs
	@watch applications/settings/src/**
	@watch applications/settings/appicon.png
	@watch applications/settings/about.toml
	@watch applications/settings/manifest.toml

terminal-inputs: viewkit-inputs
	@watch applications/terminal/Cargo.toml
	@watch applications/terminal/Cargo.lock
	@watch applications/terminal/src/**
	@watch applications/terminal/appicon.svg
	@watch applications/terminal/about.toml
	@watch applications/terminal/manifest.toml

applications-inputs: binder-inputs files-inputs installer-inputs settings-inputs terminal-inputs
	@watch applications/test.app/Cargo.toml
	@watch applications/test.app/Cargo.lock
	@watch applications/test.app/src/**
	@watch applications/test.app/about.toml
	@watch applications/test.app/manifest.toml

drivers-inputs: runtime-inputs
	@watch drivers/usb-driver/Cargo.toml
	@watch drivers/usb-driver/build.rs
	@watch drivers/usb-driver/src/**
	@watch drivers/usb-driver/linker.ld
	@watch drivers/usb-driver/manifest.toml
	@watch drivers/ps2/**
	@watch drivers/virtio-net-driver/Cargo.toml
	@watch drivers/virtio-net-driver/build.rs
	@watch drivers/virtio-net-driver/src/**
	@watch drivers/virtio-net-driver/linker.ld
	@watch drivers/virtio-net-driver/manifest.toml

cext-inputs: runtime-inputs
	@watch cexts/Cargo.toml
	@watch cexts/Cargo.lock
	@watch cexts/crates/**
	@watch cexts/disk.cext/**
	@watch cexts/ext2.cext/**
	@watch scripts/pack-cext.pl

filesystem-inputs: applications-inputs services-inputs drivers-inputs cext-inputs fonts-inputs
	@watch binaries/coreutils/Cargo.toml
	@watch binaries/coreutils/Cargo.lock
	@watch binaries/coreutils/src/**
	@watch binaries/coreutils/manifest.toml
	@watch binaries/msh/Cargo.toml
	@watch binaries/msh/Cargo.lock
	@watch binaries/msh/src/**
	@watch binaries/msh/resources/**
	@watch binaries/msh/manifest.toml
	@watch resources/**
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/**
	@watch tools/devkit/fixtures/**
	@watch version.toml
	@watch .pubkey

image-inputs: kernel-inputs boot-inputs filesystem-inputs
	@watch scripts/build-sample-mpkg.pl
