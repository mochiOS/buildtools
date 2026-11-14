# This lightweight gate checks its bounded stage receipts on every invocation.
# Unchanged builds do not run CMake, Cargo, or download LLVM again.
bootstrap:
	@always
	python3 $(SCRIPTS)/dev/bootstrap.py

# This target consumes a reviewed assembly lock. It never invokes producers.
# The output must not already exist; use MDP_OUTPUT for a new composition.
mdp-assemble:
	@always
	python3 $(SCRIPTS)/dev/assemble-mdp.py

development-environment-test:
	@always
	python3 -m unittest discover -s $(ROOT)/tools/mdp/tests -q
	python3 -m unittest discover -s $(ROOT)/tools/mdev/tests -q
	python3 $(SCRIPTS)/tests/development-bootstrap-test.py -q
	python3 $(SCRIPTS)/tests/development-mdp-test.py -q
	bash -n $(SCRIPTS)/runner.sh $(SCRIPTS)/dev/run-vm.sh

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
