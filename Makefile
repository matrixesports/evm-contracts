-include .env

ifdef sig
else
	sig='run()'
endif

#run dev script
execute_local   :; forge script script/Dev.s.sol:DevScript --sig $(sig)
execute_matic   :; forge script script/Dev.s.sol:DevScript --rpc-url $(POLYGON_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(POLYGONSCAN_API_KEY) --verify --broadcast --legacy --chain-id 137 --slow --sig "$(sig)"
execute_rinkeby	:; forge script script/Dev.s.sol:DevScript --rpc-url $(RINKEBY_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --broadcast --slow --sig $(sig)
execute_mainnet	:; forge script script/Dev.s.sol:DevScript --rpc-url $(MAINNET_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --broadcast --slow --sig $(sig)

install 		:; foundryup && forge install && yarn install && npx hardhat clean && npx hardhat compile
lint    		:; prettier --write src/**/*.sol && prettier --write src/*.sol

