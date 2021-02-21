# SPDX-License-Identifier: BSD-2-Clause-Patent 
default: all

FILENAME ?=
OPTIONS ?= preallocation=metadata
SIZE ?= 16G
SUDO ?=

override OPTIONS := $(if $(OPTIONS),-o "$(OPTIONS)",)

#   create [--object objectdef] [-q] [-f fmt] [-b backing_file] [-F backing_fmt] [-u] [-o options] filename [size]

%.raw :
	@$(SUDO) bash mkraw.sh --size "$(SIZE)" --output "$@"

%.qcow2 : %.raw
	qemu-img convert -f raw -O qcow2 $(OPTIONS) "$<" "$(@)"

all:
ifeq ($(FILENAME),)
	$(error you need to set FILENAME)
endif
	$(MAKE) $(FILENAME).qcow2

.PHONY: default all

# vim:ft=make
