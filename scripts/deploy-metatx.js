const dotenv = require('dotenv')
const { ethers, upgrades } = require("hardhat")
const { Wallet, JsonRpcProvider } = require('ethers');

dotenv.config()

const provider = new JsonRpcProvider(process.env.BSC_RPC_URL); 
const wallet = new Wallet(process.env.PRIVATE_KEY, provider);
const RELAYER = '0xE70C7b350F81D5aF747697f5553EF8a5726f7344'

// owner = 0x075Fee80E95ff922Ec067AEd2657b11359990479
// relayer = 0xE70C7b350F81D5aF747697f5553EF8a5726f7344
const TOKENS = {
  DI: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
  USDT: "0x55d398326f99059ff775485246999027b3197955",
  USDC: "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"
}

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

async function main() {

  const CreditVault = await ethers.getContractFactory("GasCreditVault", wallet);
  const creditVault = await upgrades.deployProxy(CreditVault, [], {
    initializer: "initialize",
    kind: "uups"
  })
  await creditVault.waitForDeployment();
  console.log('GasCreditVault(Proxy)', creditVault.target)
  
  // Setup vault
  const whitelistTx1 = await creditVault.whitelistToken(TOKENS.USDT, ZERO_ADDRESS, true);
  await whitelistTx1.wait()

  const whitelistTx2 = await creditVault.whitelistToken(TOKENS.USDC, ZERO_ADDRESS, true);
  await whitelistTx2.wait()

  const relayerTx = await creditVault.addWhitelistedRelayer(RELAYER);
  await relayerTx.wait()

  // const whitelistTx3 = await creditVault.whitelistToken(TOKENS.DI, DI_ORACLE, false);
  // await whitelistTx3.wait()
  
  // const addRelayerTx = await creditVault.addWhitelistedRelayer(RELAYER.address);
  // await addRelayerTx.wait()

  const GatewayFactory = await ethers.getContractFactory("MetaTxGateway", wallet);
  const gatewayContract = await upgrades.deployProxy(GatewayFactory, [], {
    initializer: "initialize",
    kind: "uups"
  })
  await gatewayContract.waitForDeployment();
  console.log('MetaTxGateway(Proxy)', gatewayContract.target);

  console.log("MetaTx Contracts deployment completed.");
}

main()
.then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });