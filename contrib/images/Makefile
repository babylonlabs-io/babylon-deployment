ifeq ($(BITCOIN_CORE_VERSION),)
	BITCOINDSIM_TAG := latest
else
	BITCOINDSIM_BUILD_ARG := --build-arg BITCOIN_CORE_VERSION=$(BITCOIN_CORE_VERSION)
	BITCOINDSIM_TAG := $(BITCOIN_CORE_VERSION)
endif

all: bitcoinsim

bitcoindsim:
	docker build --platform "linux/amd64" --tag babylonlabs-io/bitcoindsim:$(BITCOINDSIM_TAG) -f bitcoindsim/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/bitcoindsim $(BITCOINDSIM_BUILD_ARG)

bitcoindsim-rmi:
	docker rmi babylonlabs-io/bitcoindsim 2>/dev/null; true

tmkms:
	docker build --platform "linux/amd64" --tag babylonlabs-io/tmkms:latest -f tmkms/Dockerfile \
		$(shell git rev-parse --show-toplevel)/contrib/images/tmkms

.PHONY: all bitcoindsim bitcoindsim-rmi tmkms
