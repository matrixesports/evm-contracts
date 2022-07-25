-include .env


ifdef sig
else
	sig='run()'
endif


ifdef file
else
	file=script/Dev.s.sol:DevScript
endif

#run dev script

execute_local   :; forge script $(file) --sig $(sig)
execute_matic 	:; forge script $(file) --rpc-url $(POLYGON_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(POLYGONSCAN_API_KEY) --verify --broadcast --slow --sig $(sig) --chain-id 137 --with-gas-price 70000000000
execute_rinkeby	:; forge script $(file) --rpc-url $(RINKEBY_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --broadcast --slow --sig $(sig)
execute_mainnet	:; forge script $(file) --rpc-url $(MAINNET_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --broadcast --slow --sig $(sig)


install 		:; foundryup && forge install && yarn install && npx hardhat clean && npx hardhat compile && forge build
lint    		:; prettier --write src/**/*.sol && prettier --write src/*.sol

