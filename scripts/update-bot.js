const { JsonRpcProvider, Wallet, parseUnits } = require("ethers")
const artifactsDINStaking = require('../artifacts/contracts/TokenStaking.sol/TokenStaking.json')

const dotenv = require('dotenv');
const { Contract } = require("ethers");

dotenv.config();

const provider = new JsonRpcProvider("http://127.0.0.1:8545")
const wallet = new Wallet(process.env.PRIVATE_KEY, provider)

async function main() {
    const nonce = await wallet.getNonce()

    const TokenStakingContract = new Contract('0x0165878A594ca255338adfa4d48449f69242Eb8F', artifactsDINStaking.abi, provider)
    const txStakeWindow = await TokenStakingContract.connect(wallet).updateReward({nonce});
    await txStakeWindow.wait()
}

main()
.then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });