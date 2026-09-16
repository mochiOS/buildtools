config:
	@watch build/defaults.config
	@watch build/schema.conf
	@watch scripts/config/merge-config.pl
	@output $(ROOT)/.config
	@output $(ROOT)/build/config.mk
	perl $(SCRIPTS)/config/merge-config.pl --default $(ROOT)/build/defaults.config --in $(ROOT)/.config --out $(ROOT)/.config --mk $(ROOT)/build/config.mk

olddefconfig: config

menuconfig:
	@always
	make -C $(ROOT)/build menuconfig ROOT=$(ROOT) OUT=$(OUT) SCHEMA=$(ROOT)/build/schema.conf CONFIG=$(ROOT)/.config
	perl $(SCRIPTS)/config/merge-config.pl --default $(ROOT)/build/defaults.config --in $(ROOT)/.config --out $(ROOT)/.config --mk $(ROOT)/build/config.mk
