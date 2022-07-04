-include .env

#run dev script
execute :; forge script script/Dev.s.sol:DevScript --rpc-url $POLYGON_RPC --private-key $PVT_KEY --broadcast --legacy
run     :; forge script script/Dev.s.sol:DevScript
