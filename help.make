# Static, display-only command list. This target never builds or discovers inputs.
MMAKE_HELP_INTRO := 'mochiOS image assembly' 'Usage: mmake [OPTIONS] <target>'
MMAKE_HELP_GENERAL := 'Setup:' '  bootstrap  Install local mdp and mdev commands (Python 3.11+)' '  config  olddefconfig  menuconfig  Configure the product'
MMAKE_HELP_PRODUCERS := 'Build repositories separately with mdp:' '  mdp workspace lock  Record reviewed source, SDK and configuration inputs' '  mdp workspace build -j 4  Build all default producers and lock their artifacts' '  mdp workspace build --select app-terminal -j 4  Build one producer and its dependencies' '  mdp build --context <SDK-context.json>  Build from an independent repository'
MMAKE_HELP_BUILD := 'Assemble existing locked artifacts (no producer builds):' '  all  build  image  full  Create the normal OS image' '  installer-image  Create the separate installer image' '  mdp-assemble  Compose MDP_ASSEMBLY_LOCK into MDP_OUTPUT' '  rootfs-stage  rootfs  data  initfs-stage  initfs  esp  disk-image  artifacts  symbols'
MMAKE_HELP_VM := 'VMs:' '  run  Assemble the image and start the selected mdev VM' '  run-existing  Start with an existing image' '  mdev list  List development VMs' '  mdev --help  VM creation, selection and lifecycle commands'
MMAKE_HELP_PREVIEW := 'Linux UI previews:' '  ui  ui-tablet  ui-check  ui-test  ui-boundaries  preview-check' '  preview-app APP=<directory>' '  preview-files  preview-settings  preview-binder  preview-appstore  preview-edit' '  preview-calendar  preview-calculator  preview-mail  preview-keychain' '  preview-disk-utility  preview-fonts'
MMAKE_HELP_IMAGES := 'Optional hardware and update images:' '  mboot-image  Consume the optional mboot MDP (build it after the normal image)' '  release  Collect normal and hardware images locally; does not publish' '  ab-esp  ab-layout-image  normal-update-payload  ab-slot-b-image  ab-trial-b-image' '  measure-kernel-size  Measure the assembled kernel'
MMAKE_HELP_TESTS := 'Tests:' '  test  host-test  Existing guest and host integration suites' '  native-test-tools  native-test-services  Assemble locked fixture inputs' '  development-environment-test  MDP, VM lifecycle, bootstrap and composition tests' '  image-applications-test  System/Store/installer application separation' '  mdp-migration-test  Producer coverage, image input validation and package extraction'
MMAKE_HELP_CLEANUP := 'Cleanup:' '  clean  Remove assembled images; preserve producer caches, SDKs and development VMs' '  clean-runner  Remove legacy runner data' '' 'Run mmake --help for command-line options.'

help:
	@always
	if test -t 0; then exec 3>/dev/tty; else exec 3>&1; fi
	printf '%s\n' $(MMAKE_HELP_INTRO) '' $(MMAKE_HELP_GENERAL) '' $(MMAKE_HELP_PRODUCERS) '' $(MMAKE_HELP_BUILD) '' $(MMAKE_HELP_VM) '' $(MMAKE_HELP_PREVIEW) '' $(MMAKE_HELP_IMAGES) '' $(MMAKE_HELP_TESTS) '' $(MMAKE_HELP_CLEANUP) >&3
