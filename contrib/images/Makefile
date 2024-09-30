ifeq ($(BITCOIN_CORE_VERSION),)
	BITCOINDSIM_TAG := latest
else
	BITCOINDSIM_BUILD_ARG := --build-arg BITCOIN_CORE_VERSION=$(BITCOIN_CORE_VERSION)
	BITCOINDSIM_TAG := $(BITCOIN_CORE_VERSION)
endif

all: bitcoinsim

bitcoindsim:
	docker build --platform "linux/amd64" --tag babylonchain/bitcoindsim:$(BITCOINDSIM_TAG) -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoindsim $(BITCOINDSIM_BUILD_ARG)

bitcoindsim-rmi:
	docker rmi babylonchain/bitcoindsim 2>/dev/null; true

.PHONY: all bitcoindsim bitcoindsim-rmi
