ROOT	?= ..
OUT	?= $(ROOT)/out
SCHEMA	?= $(ROOT)/build/schema.conf
CONFIG	?= $(ROOT)/.config

HOSTCC		?= cc
HOSTCFLAGS	?= -std=c11 -Wall -Wextra -O2
HOSTLDLIBS	?= -lncurses

MENUCONFIG	= $(OUT)/build/host/menuconfig

.PHONY: all build menuconfig clean

all: build

build: $(MENUCONFIG)

$(MENUCONFIG): menuconfig.c
	@mkdir -p $(OUT)/build/host
	@$(HOSTCC) $(HOSTCFLAGS) -o $@ $< $(HOSTLDLIBS)

menuconfig: build
	@$(MENUCONFIG) --schema $(SCHEMA) --config $(CONFIG)

clean:
	@rm -f $(MENUCONFIG)