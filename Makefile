-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

build:; forge build

install :; forge install Cyfrin/foundry-devops@0.1.0  && forge install smartcontractkit/chainlink@42c74fcd30969bca26a9aadc07463d1c2f473b8c  && forge install foundry-rs/forge-std@v1.7.0 && forge install transmissions11/solmate@v6

test:; forge test


deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(ETH_SEPOLIA) --account sepolia --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --account default --broadcast --rpc-url http://127.0.0.1:8545