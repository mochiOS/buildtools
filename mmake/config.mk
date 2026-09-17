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
	make -C $(ROOT)/build build ROOT=$(ROOT) OUT=$(OUT)
	test -t 0
	$(OUT)/host/menuconfig --schema $(ROOT)/build/schema.conf --config $(ROOT)/.config </dev/tty >/dev/tty 2>&1
	perl $(SCRIPTS)/config/merge-config.pl --default $(ROOT)/build/defaults.config --in $(ROOT)/.config --out $(ROOT)/.config --mk $(ROOT)/build/config.mk
