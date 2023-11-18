source .env

forge script script/DeploySwirlio.s.sol:DeploySwirlio --chain-id 5 --rpc-url https://rpc.ankr.com/eth_goerli \
    --broadcast --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify -vvvv