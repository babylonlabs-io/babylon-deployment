ifeq ($(BITCOIN_CORE_VERSION),)
	BITCOINDSIM_TAG := latest
else
	BITCOINDSIM_BUILD_ARG := --build-arg BITCOIN_CORE_VERSION=$(BITCOIN_CORE_VERSION)
	BITCOINDSIM_TAG := $(BITCOIN_CORE_VERSION)
endif

all: bitcoinsim

bitcoindsim:
	docker build --platform "linux/amd64" --tag babylonlabs/bitcoindsim:$(BITCOINDSIM_TAG) -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoindsim $(BITCOINDSIM_BUILD_ARG)

ibcsim-gaia:
	docker build --tag babylonlabs/ibcsim-gaia -f ibcsim-gaia/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim-gaia

ibcsim-wasmd:
	docker build --tag babylonlabs/ibcsim-wasmd -f ibcsim-wasmd/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/ibcsim-wasmd

btcdsim-rmi:
	docker rmi babylonlabs/btcdsim 2>/dev/null; true

bitcoindsim-rmi:
	docker rmi babylonlabs/bitcoindsim 2>/dev/null; true

ibcsim-gaia-rmi:
	docker rmi babylonlabs/ibcsim-gaia 2>/dev/null; true

ibcsim-wasmd-rmi:
	docker rmi babylonlabs/ibcsim-wasmd 2>/dev/null; true

.PHONY: all btcdsim btcdsim-rmi bitcoindsim bitcoindsim-rmi ibcsim-gaia ibcsim-gaia-rmi ibcsim-wasmd ibcsim-wasmd-rmi
