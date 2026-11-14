# Static, display-only target list. No build dependencies or discovery scripts.
MMAKE_HELP_INTRO := 'mochiOS build targets' 'Usage: mmake [OPTIONS] <target>'
MMAKE_HELP_GENERAL := '  help  Show this list (no build steps)' '  bootstrap  Install local mdp and mdev commands (Python 3.11+; no downloads)'
MMAKE_HELP_BUILD := 'Build and run:' '  all  build  image  full  run  run-existing  release  mboot-image  measure-kernel-size' '  mdp-assemble  Compose locked MDPs without building producers (MDP_ASSEMBLY_LOCK, MDP_OUTPUT)'
MMAKE_HELP_CONFIG := 'Configuration:' '  app-sdk  config  olddefconfig  menuconfig' '  development-tools  Build configured native Clang/LLD and offline signing tools'
MMAKE_HELP_PREVIEW := 'Linux UI and previews:' '  preview-files  preview-settings  preview-binder  preview-appstore  preview-edit  preview-app APP=<directory>  preview-check' '  ui-test  ui-boundaries  ui  ui-check  preview-calendar  preview-calculator  preview-mail' '  preview-keychain  preview-disk-utility  preview-fonts'
MMAKE_HELP_COMPONENTS := 'Core components:' '  fonts  ime-dictionary  runtime  rust-sysroot  kernel  bootloader  drivers  cexts  mdriver'
MMAKE_HELP_SDK := 'Libraries and SDK:' '  viewkit  appcore  appcore-format'
MMAKE_HELP_APPS := 'Applications:' '  appstore  keychain  mail  calculator  disk-utility  fonts-app  calendar  binder  edit  files' '  installer  settings  system-monitor  viewer  terminal  test-app  apps-bundle  apps  system-apps'
MMAKE_HELP_SERVICES := 'Services:' '  capability  compositor  core-service  display  drivers-service  filesystem-service' '  posix-service  input  linux-service  logger  mboot-agent  network  package-service  secure-ui' '  service-manager  signature  tty  update-service  user-service  workspace-service' '  services-bundle  services  keychain-service'
MMAKE_HELP_PROGRAMS := 'Command-line programs:' '  msh  coreutils  rust-std-demo  binaries-bundle  programs'
MMAKE_HELP_IMAGES := 'Images and staging:' '  rootfs-stage  initfs-stage  rootfs  data  initfs  esp  disk-image  artifacts  installer-image'
MMAKE_HELP_AB_IMAGES := 'A/B images and image tools:' '  boot-selection-seed  boot-selection-confirm-test  boot-selection-gpt-probe' '  system-image-sign-tool  system-slot-image-tool  ab-esp  ab-layout-image  normal-update-payload' '  ab-slot-b-image  ab-trial-b-image'
MMAKE_HELP_SIGNING := 'Packaging and signing:' '  msign-tool  msign-elf-format  mpack-tool  sign-package  package-and-sign'
MMAKE_HELP_TESTS := 'Tests:' '  test  KVM guest suite and release-quality evidence' '  host-test  Quick host suite (no VM)' '  image-applications-test  System/Store/installer application separation' '  development-tools-test  Native development tool build and cache orchestration' '  git-dependencies-test  Repository-portable Cargo dependencies and local SDK overrides' '  native-test-tools  native-test-services  Prerequisites for isolated signed VM fixtures' '  binder-test  edit-test  system-monitor-test  viewer-test  msign-elf-test' '  msign-test  appcore-test  smoke-log-test  smoke-test  smoke-test-kvm  smoke-test-tcg' '  ext2-write-test  ext2-write-fixture-test  ext2-cext-test  ext2-write-test-tcg' '  tls-http-smoke-test  accounts-https-smoke-test  developer-pki-sync-smoke-test' '  developer-pki-production-e2e  diagnostics-test  net-device-protocol-test  input-test' '  http-client-test  boot-selection-test  system-image-test  ab-slot-selection-test' '  ab-layout-test  ab-layout-smoke-test-kvm  system-signature-smoke-test-kvm' '  boot-assets-signature-smoke-test-kvm  secure-boot-smoke-test-kvm  anti-rollback-smoke-test-kvm' '  system-data-smoke-test-kvm  ab-slot-b-test  ab-trial-b-test  ab-trial-confirm-test' '  ab-slot-b-smoke-test-kvm  ab-boot-slot-smoke-test-kvm  ab-trial-rollback-smoke-test-kvm' '  ab-trial-confirm-smoke-test-kvm  workspace-test  service-manager-test'
MMAKE_HELP_CLEANUP := 'Cleanup:' '  clean  clean-runner'
MMAKE_HELP_OPTIONS := 'Run mmake --help for command-line options.'

# mmake suppresses recipe stdout unless verbose. Show help directly on terminals;
# redirected/headless output is available with mmake -v help.
help:
	@always
	if test -t 0; then exec 3>/dev/tty; else exec 3>&1; fi
	printf '%s\n' $(MMAKE_HELP_INTRO) '' $(MMAKE_HELP_GENERAL) '' $(MMAKE_HELP_BUILD) '' $(MMAKE_HELP_CONFIG) '' $(MMAKE_HELP_PREVIEW) '' $(MMAKE_HELP_COMPONENTS) '' $(MMAKE_HELP_SDK) '' $(MMAKE_HELP_APPS) '' $(MMAKE_HELP_SERVICES) '' $(MMAKE_HELP_PROGRAMS) '' $(MMAKE_HELP_IMAGES) '' $(MMAKE_HELP_AB_IMAGES) '' $(MMAKE_HELP_SIGNING) '' $(MMAKE_HELP_TESTS) '' $(MMAKE_HELP_CLEANUP) '' $(MMAKE_HELP_OPTIONS) >&3
