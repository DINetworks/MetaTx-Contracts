```shell
npx hardhat compile
npm run deploy:metatx
npx hardhat verify --contract contracts/GasCreditVault.sol:GasCreditVault --network bsc <Deployed Address> 

```

verify is not working because hardhat-verify v2 does not supoort multi chain verification.

using postman to verify the contract on bsc.
docs.etherscan.io