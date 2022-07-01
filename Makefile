-include .env

all:;install 
# Clean the repo
clean  :; forge clean

# Install the Modules
install :; forge install

# Update Dependencies
update:; forge update

# Builds
build  :; forge build

# Tests
test :; forge test # --ffi # enable if you need the `ffi` cheat code on HEVM

# Generate Gas Snapshots
snapshot :; forge clean && forge snapshot

#run dev script
execute :; 

# Lints
lint :; prettier --write src/**/*.sol && prettier --write src/*.sol