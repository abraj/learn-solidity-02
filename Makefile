# -include .env
include .env

build:; forge clean && forge build

deploy:
	forge script script/FundMe.s.sol:DeployFundMe --rpc-url $(RPC_URL) --broadcast --keystore $(KEYSTORE1) --password-file $(PWD_FILE1)

deploy-sepolia:
	forge script script/FundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --broadcast --keystore $(KEYSTORE2) --password-file $(PWD_FILE2) --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# verify-sepolia:
# 	forge verify-contract 0xF3a717DBC4E5a1baFE0D0DB8468706EA40403d3e src/FundMe.sol:FundMe --watch --compiler-version 0.8.24 --chain sepolia --etherscan-api-key $(ETHERSCAN_API_KEY)

# https://etherscan.freshstatus.io/
# https://sepolia.etherscan.io/address/0x2ed69cd751722fc552bc8c521846d55f6bd8f090
