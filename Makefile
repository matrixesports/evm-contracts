-include .env

#run dev script
execute :; forge script script/Dev.s.sol:DevScript --rpc-url $POLYGON_RPC --private-key $PVT_KEY --broadcast --legacy
run     :; forge script script/Dev.s.sol:DevScript

install :; foundryup && forge install && yarn install
lint    :; prettier --write src/**/*.sol && prettier --write src/*.sol

test    :; forge test
forceTest:; foge test --force
build	:; forge build
snapshot:; forge snapshot --check
