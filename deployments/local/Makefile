DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)
STOP_PATH := $(CURDIR)/stop

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon build

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante build

build-fpd:
	$(MAKE) -C $(GIT_TOPLEVEL)/finality-provider build

build-covd:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator build

build-btc-staker:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker build

build-all: build-babylond build-vigilante build-fpd build-covd build-btc-staker

bbn-start-stop-exportgen-start: build-all
	./bbn-start-stop-exportgen-start.sh

bbn-start-and-add-btc-delegation: build-all
	./bbn-start-and-add-btc-delegation.sh

bbn-upgrade-vanilla: build-all
	./bbn-start-and-upgrade-vanilla.sh

stop-all:
	$(STOP_PATH)/kill-all-process.sh
	rm -rf $(CURDIR)/data
