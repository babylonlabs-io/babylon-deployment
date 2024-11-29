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

build-covenant-signer:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-signer build

build-covenant-signer-in-covd:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator/covenant-signer build

build-btc-staker:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker build

build-staking-indexer:
	$(MAKE) -C $(GIT_TOPLEVEL)/staking-indexer build

build-all: build-babylond build-vigilante build-fpd build-covd build-btc-staker build-staking-indexer build-covenant-signer build-covenant-signer-in-covd

bbn-start-btc-del-stop-exportgen-start: build-all
	./bbn-start-btc-del-stop-exportgen-start.sh

bbn-start-and-add-btc-delegation: build-all
	./bbn-start-and-add-btc-delegation.sh

bbn-upgrade-v1: build-all
	./bbn-start-and-upgrade-v1.sh

stop-all:
	$(STOP_PATH)/kill-all-process.sh
	rm -rf $(CURDIR)/data
