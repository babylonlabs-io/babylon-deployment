USE_DOCKERHUB_IMAGES ?= TRUE

start-deployment-btcstaking-bitcoind:
	USE_DOCKERHUB_IMAGES=$(USE_DOCKERHUB_IMAGES) \
		$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		start-deployment-btcstaking-bitcoind

start-deployment-btcstaking-bitcoind-demo:
	USE_DOCKERHUB_IMAGES=$(USE_DOCKERHUB_IMAGES) \
		$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		start-deployment-btcstaking-bitcoind-demo

stop-deployment-btcstaking-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		stop-deployment-btcstaking-bitcoind
