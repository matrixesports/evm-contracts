-include .env

ifdef sig
else
	sig='run()'
endif

ifdef file
else
	file=script/Dev.s.sol:DevScript
endif

install 		:; yarn && yarn run prepare && foundryup && forge install && forge update && forge build && forge test && \
				python3 -m venv .venv && source .venv/bin/activate && pip3 install slither-analyzer && \
				pip3 install solc-select && solc-select install 0.8.15 && solc-select use 0.8.15 
lint    		:; forge fmt

#run dev script
execute_matic 	:; forge script $(file) --rpc-url $(POLYGON_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(POLYGONSCAN_API_KEY) --verify --delay 10 --retries 2 --broadcast --slow --sig $(sig) --chain-id 137 --with-gas-price 86000000000
execute_mainnet	:; forge script $(file) --rpc-url $(MAINNET_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --broadcast --slow --sig $(sig)

#line coverage, https://mirror.xyz/devanon.eth/RrDvKPnlD-pmpuW7hQeR5wWdVjklrpOgPCOA-PJkWFU
#for html reports, `brew install lcov` & go live with reports/ directory.
coverage 		:; forge coverage --report lcov && genhtml lcov.info -o report --branch-coverage && open report/index.html

slither 		:; source .venv/bin/activate && slither . --checklist