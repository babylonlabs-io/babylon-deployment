DOCKER := $(shell which docker)
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)
NUM_FINALITY_PROVIDERS := 3

# Build submodules only if the executor specifies to build submodules
ifneq ($(USE_DOCKERHUB_IMAGES),TRUE)
EXTRA_BUILD_TARGET := build-babylond build-vigilante build-btc-staker build-finality-provider build-covenant-emulator build-covenant-signer
endif

ifeq ($(USE_DOCKERHUB_IMAGES),TRUE)
BABYLOND_IMAGE= "babylonlabs/babylond:v1.0.0-rc.5"
VIGILANTE_IMAGE= "babylonlabs/vigilante:v0.19.9"
BTCSTAKER_IMAGE= "babylonlabs/btc-staker:v0.15.1"
FP_IMAGE= "babylonlabs/finality-provider:v1.0.0-rc.1"
COVENANT_IMAGE= "babylonlabs/covenant-emulator:v0.12.0"
COVENANT_SIGNER_IMAGE= "babylonlabs/covenant-signer:v0.12.0"
else
BABYLOND_IMAGE= "babylonlabs-io/babylond"
VIGILANTE_IMAGE= "babylonlabs-io/vigilante"
BTCSTAKER_IMAGE= "babylonlabs-io/btc-staker"
FP_IMAGE= "babylonlabs-io/finality-provider"
COVENANT_IMAGE= "babylonlabs-io/covenant-emulator"
COVENANT_SIGNER_IMAGE= "babylonlabs-io/covenant-signer"
endif

build-bitcoindsim:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images bitcoindsim

build-babylond:
	$(MAKE) -C $(GIT_TOPLEVEL)/babylon/contrib/images babylond

build-vigilante:
	$(MAKE) -C $(GIT_TOPLEVEL)/vigilante build-docker

build-btc-staker:
	$(MAKE) -C $(GIT_TOPLEVEL)/btc-staker build-docker

build-finality-provider:
	$(MAKE) -C $(GIT_TOPLEVEL)/finality-provider build-docker

build-covenant-emulator:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator build-docker

build-covenant-signer:
	$(MAKE) -C $(GIT_TOPLEVEL)/covenant-emulator/covenant-signer build-docker

build-tmkms:
	$(MAKE) -C $(GIT_TOPLEVEL)/contrib/images tmkms

build-deployment-btcstaking-bitcoind: build-bitcoindsim build-tmkms $(EXTRA_BUILD_TARGET)

start-deployment-btcstaking-bitcoind: stop-deployment-btcstaking-bitcoind build-deployment-btcstaking-bitcoind
	BABYLOND_IMAGE=${BABYLOND_IMAGE} \
		NUM_FINALITY_PROVIDERS=$(NUM_FINALITY_PROVIDERS) ./pre-deployment.sh
	BABYLOND_IMAGE=$(BABYLOND_IMAGE) \
		VIGILANTE_IMAGE=$(VIGILANTE_IMAGE) \
		BTCSTAKER_IMAGE=$(BTCSTAKER_IMAGE) \
		COVENANT_IMAGE=$(COVENANT_IMAGE) \
		COVENANT_SIGNER_IMAGE=$(COVENANT_SIGNER_IMAGE) \
		FP_IMAGE=$(FP_IMAGE) \
		docker compose -f artifacts/docker-compose.yml up -d
	NUM_FINALITY_PROVIDERS=$(NUM_FINALITY_PROVIDERS) ./post-deployment.sh

start-deployment-btcstaking-bitcoind-demo: start-deployment-btcstaking-bitcoind
	NUM_FINALITY_PROVIDERS=$(NUM_FINALITY_PROVIDERS) ./btcstaking-demo.sh

stop-deployment-btcstaking-bitcoind:
	BABYLOND_IMAGE=$(BABYLOND_IMAGE) \
		VIGILANTE_IMAGE=$(VIGILANTE_IMAGE) \
		BTCSTAKER_IMAGE=$(BTCSTAKER_IMAGE) \
		COVENANT_IMAGE=$(COVENANT_IMAGE) \
		COVENANT_SIGNER_IMAGE=$(COVENANT_SIGNER_IMAGE) \
		FP_IMAGE=$(FP_IMAGE) \
		docker compose -f artifacts/docker-compose.yml down
	rm -rf $(CURDIR)/.testnets
