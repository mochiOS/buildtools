# Generated from build/application-sets.toml by scripts/mmake/image-applications.py --makefile.
system-apps: binder settings files terminal appstore disk-utility viewer fonts-app system-monitor keychain keyboard
system-applications-inputs: binder-inputs settings-inputs files-inputs terminal-inputs appstore-inputs disk-utility-inputs viewer-inputs fonts-app-inputs system-monitor-inputs keychain-inputs keyboard-inputs
installer-apps: installer
installer-applications-inputs: installer-inputs
ifeq ($(APPLICATION_TERRA_BUILTIN),y)
system-apps: terra
system-applications-inputs: terra-inputs
endif
ifeq ($(APPLICATION_EDIT_BUILTIN),y)
system-apps: edit
system-applications-inputs: edit-inputs
endif
ifeq ($(APPLICATION_CALENDAR_BUILTIN),y)
system-apps: calendar
system-applications-inputs: calendar-inputs
endif
ifeq ($(APPLICATION_MAIL_BUILTIN),y)
system-apps: mail
system-applications-inputs: mail-inputs
endif
ifeq ($(APPLICATION_CALCULATOR_BUILTIN),y)
system-apps: calculator
system-applications-inputs: calculator-inputs
endif
