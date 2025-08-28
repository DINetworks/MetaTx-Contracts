const { JsonRpcProvider, Wallet, parseUnits, parseEther } = require("ethers")
const artifactsDINStaking = require('../artifacts/contracts/TokenStaking.sol/TokenStaking.json')
const artifactsTokenPresale = require('../artifacts/contracts/TokenPresale.sol/TokenPresale.json')

const dotenv = require('dotenv');
const { Contract } = require("ethers");
const { ethers } = require("hardhat");

dotenv.config();

// const provider = new JsonRpcProvider("http://127.0.0.1:8545")
// const wallet = new Wallet(process.env.PRIVATE_KEY, provider)

async function main() {
  const [deployer] = await ethers.getSigners();
  const TokenPresaleContract = new Contract('0x4Cde30889899C246A9B961857f1F95F4da28bcD6', artifactsTokenPresale.abi, deployer);
  const receivedDiAmount = await TokenPresaleContract.calculateTokenAmount('0x0000000000000000000000000000000000000000', 158925343422557n)
  console.log(`Received DI for 0.000158925343422557 BNB: ${receivedDiAmount}`);
  // const nonce = await wallet.getNonce()

  // const TokenStakingContract = new Contract('0x0165878A594ca255338adfa4d48449f69242Eb8F', artifactsDINStaking.abi, provider)
  // const txStakeWindow = await TokenStakingContract.connect(wallet).updateReward({nonce});
  // await txStakeWindow.wait()
}

main()
.then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });