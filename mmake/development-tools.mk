# Development environment setup and artifact-only gates.
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

# Native tools are produced by tools/devkit/mdp.native.toml.
development-tools:
	@always
	test -f $(ROOT)/tools/devkit/out/mdp/devkit-native.tar.mdp || { echo 'Run mdp workspace build --select devkit-native.' >&2; exit 1; }

mdp-migration-test:
	@always
	python3 $(SCRIPTS)/tests/mdp-migration-test.py -q
