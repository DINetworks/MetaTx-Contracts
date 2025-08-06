const dotenv = require('dotenv');
const { JsonRpcProvider, Wallet, parseUnits } = require("ethers")
const artifactsDINStaking = require('../artifacts/contracts/TokenStaking.sol/TokenStaking.json')


dotenv.config();

const provider = new JsonRpcProvider("http://127.0.0.1:8545")
const wallet = new Wallet(process.env.PRIVATE_KEY, provider)
const RELAYER = new Wallet(process.env.RELAYER_PRIVATE_KEY, provider)

async function main() {

    const txTransfer = await wallet.sendTransaction({
      to: '0xa9315C1C008c022c4145E993eC9d1a3AF73D0A62',
      value: parseUnits('100', 18)
    })
    await txTransfer.wait()
  
    const txTransfer2 = await wallet.sendTransaction({
      to: RELAYER.address,
      value: parseUnits('100', 18)
    })
    await txTransfer2.wait()

    console.log(`sent 100ETH to 0xa9315C1C008c022c4145E993eC9d1a3AF73D0A62`)
    console.log(`sent 100ETH to ${RELAYER.address}`)

    // const TokenStakingContract = new Contract('0x0165878A594ca255338adfa4d48449f69242Eb8F', artifactsDINStaking.abi, provider)
    // const txStakeWindow = await TokenStakingContract.connect(wallet).setStartTimeForStaking(Math.floor(new Date().getTime() / 1000 + 9));
    // await txStakeWindow.wait()
}

main()
.then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });