start-deployment-btcstaking-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		start-deployment-btcstaking-bitcoind

start-deployment-btcstaking-bitcoind-demo:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		NUM_VALIDATORS=${NUM_VALIDATORS} \
		start-deployment-btcstaking-bitcoind-demo

stop-deployment-btcstaking-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-bitcoind \
		stop-deployment-btcstaking-bitcoind

start-deployment-btcstaking-phase1-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-phase1-bitcoind \
		start-deployment-btcstaking-phase1-bitcoind

start-deployment-btcstaking-phase1-bitcoind-demo:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-phase1-bitcoind \
		start-deployment-btcstaking-phase1-bitcoind-demo

stop-deployment-btcstaking-phase1-bitcoind:
	$(MAKE) -C $(CURDIR)/deployments/btcstaking-phase1-bitcoind \
		stop-deployment-btcstaking-phase1-bitcoind

start-deployment-faucet:
	$(MAKE) -C $(CURDIR)/deployments/faucet start-deployment-faucet

stop-deployment-faucet:
	$(MAKE) -C $(CURDIR)/deployments/faucet stop-deployment-faucet

start-deployment-btc-discord-faucet:
	$(MAKE) -C $(CURDIR)/deployments/btc-discord-faucet start-deployment-btc-discord-faucet

stop-deployment-btc-discord-faucet:
	$(MAKE) -C $(CURDIR)/deployments/btc-discord-faucet stop-deployment-btc-discord-faucet
