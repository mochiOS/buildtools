# This lightweight gate checks its bounded stage receipts on every invocation.
# Unchanged builds do not run CMake, Cargo, or download LLVM again.
bootstrap:
	@always
	python3 $(SCRIPTS)/dev/bootstrap.py

# This target consumes a reviewed assembly lock. It never invokes producers.
# The output must not already exist; use MDP_OUTPUT for a new composition.
MDP_ASSEMBLY_LOCK ?= $(ROOT)/mdp.assembly.lock
MDP_OUTPUT ?= $(OUT)/mdp/assembled
mdp-assemble:
	@always
	$(ROOT)/tools/mdp/mdp assemble --lock $(MDP_ASSEMBLY_LOCK) --output $(MDP_OUTPUT)

development-tools: runtime-inputs runtime rust-sysroot config
	@always
	@watch scripts/mmake/build-development-tools.py
	@watch scripts/build-llvm-runtimes.sh
	@watch scripts/configure-llvm-target.sh
	@watch scripts/llvm/patches/**
	@watch tools/devkit/Cargo.toml
	@watch tools/devkit/Cargo.lock
	@watch tools/devkit/crates/msign/**
	@watch tools/devkit/crates/linker-driver/**
	@watch tools/devkit/crates/file-publication/**
	@output $(MMAKE_OUT)/components/development-tools.json
	python3 $(SCRIPTS)/mmake/build-development-tools.py --root $(ROOT) -- $(MOCHIOS_CARGO)

development-tools-test:
	@always
	python3 $(SCRIPTS)/tests/development-tools-build-test.py
