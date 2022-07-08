-include .env

#run dev script
execute_local   :; forge script script/Dev.s.sol:DevScript
execute_polygon :; forge script script/Dev.s.sol:DevScript --rpc-url $(POLYGON_RPC) --private-key $(PVT_KEY) --broadcast --legacy
execute_rinkeby	:; forge script script/Dev.s.sol:DevScript --rpc-url $(RINKEBY_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --broadcast 
execute_mainnet	:; forge script script/Dev.s.sol:DevScript --rpc-url $(MAINNET_RPC) --private-key $(PVT_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY) --verify --broadcast 

install 		:; foundryup && forge install && yarn install
lint    		:; prettier --write src/**/*.sol && prettier --write src/*.sol

test    		:; forge test
force_test		:; foge test --force
build			:; forge build
snapshot		:; forge snapshot --check
