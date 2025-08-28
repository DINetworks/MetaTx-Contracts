const dotenv = require('dotenv')
const { ContractFactory, parseUnits } = require('ethers');
const artifactsDI = require('../artifacts/contracts/DI.sol/DI.json')
const artifactsDIVote = require('../artifacts/contracts/DIVote.sol/DIVote.json')
const artifactsKOLAllocation = require('../artifacts/contracts/KOLAllocation.sol/KOLAllocation.json')
const artifactsTeamAllocation = require('../artifacts/contracts/TeamAllocation.sol/TeamAllocation.json')
const artifactsDIAirdrop = require('../artifacts/contracts/TokenAirdrop.sol/TokenAirdrop.json')
const artifactsDIPresale = require('../artifacts/contracts/TokenPresale.sol/TokenPresale.json')
const artifactsDIStaking = require('../artifacts/contracts/TokenStaking.sol/TokenStaking.json')

dotenv.config()

const marketingWallet = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
const treasuryWallet = '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'
const ecosystemWallet = '0x90F79bf6EB2c4f870365E785982E1f101E93b906'
const liquidityWallet = '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65'

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

const USDT = "0x55d398326f99059ff775485246999027b3197955"
const USDC = "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"

const BNB_ORACLE = "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526"

async function main() {

    const [wallet] = await ethers.getSigners(); 
    const owner = wallet.address

    const DIFactory = new ContractFactory(artifactsDI.abi, artifactsDI.bytecode, wallet);
    const DIContract = await DIFactory.deploy(owner)
    await DIContract.waitForDeployment();
    const DIContractAddress = DIContract.target;
    console.log(artifactsDI.contractName, DIContractAddress)

    const DIVoteFactory = new ContractFactory(artifactsDIVote.abi, artifactsDIVote.bytecode, wallet);
    const DIVoteContract = await DIVoteFactory.deploy(DIContractAddress, owner)
    await DIVoteContract.waitForDeployment();
    console.log(artifactsDIVote.contractName, DIVoteContract.target)

    const KOLAllocationFactory = new ContractFactory(artifactsKOLAllocation.abi, artifactsKOLAllocation.bytecode, wallet);
    const KOLAllocationContract = await KOLAllocationFactory.deploy(DIContractAddress, owner)
    await KOLAllocationContract.waitForDeployment();
    console.log(artifactsKOLAllocation.contractName, KOLAllocationContract.target)

    const TeamAllocationFactory = new ContractFactory(artifactsTeamAllocation.abi, artifactsTeamAllocation.bytecode, wallet);
    const TeamAllocationContract = await TeamAllocationFactory.deploy(DIContractAddress, owner)
    await TeamAllocationContract.waitForDeployment();
    console.log(artifactsTeamAllocation.contractName, TeamAllocationContract.target)

    const TokenAirdropFactory = new ContractFactory(artifactsDIAirdrop.abi, artifactsDIAirdrop.bytecode, wallet);
    const TokenAirdropContract = await TokenAirdropFactory.deploy(DIContractAddress, owner)
    await TokenAirdropContract.waitForDeployment();
    console.log(artifactsDIAirdrop.contractName, TokenAirdropContract.target)

    const TokenPresaleFactory = new ContractFactory(artifactsDIPresale.abi, artifactsDIPresale.bytecode, wallet);
    const TokenPresaleContract = await TokenPresaleFactory.deploy(DIContractAddress, parseUnits("150000000", 18), owner)
    await TokenPresaleContract.waitForDeployment();
    console.log(artifactsDIPresale.contractName, TokenPresaleContract.target)

    const TokenStakingFactory = new ContractFactory(artifactsDIStaking.abi, artifactsDIStaking.bytecode, wallet);
    const TokenStakingContract = await TokenStakingFactory.deploy(DIContractAddress, owner)
    await TokenStakingContract.waitForDeployment();
    console.log(artifactsDIStaking.contractName, TokenStakingContract.target)

    // Define allocation addresses
    const allocationAddresses = {
        presaleContract: TokenPresaleContract.target,
        kolAllocationContract: KOLAllocationContract.target,
        teamAllocationContract: TeamAllocationContract.target,
        stakingContract: TokenStakingContract.target,
        airdropContract: TokenAirdropContract.target,
        marketingWallet,
        treasuryWallet, 
        ecosystemWallet, 
        liquidityWallet
    }

    const txSaleWindow = await TokenPresaleContract.connect(wallet).setSaleWindow(Math.floor(new Date('2025-05-01').getTime() / 1000 + 3600 * 9), Math.floor(new Date('2025-12-28').getTime() / 1000 + 3600 * 9))
    await txSaleWindow.wait()

    const txStakeWindow = await TokenStakingContract.connect(wallet).setStartTimeForStaking(Math.floor(new Date().getTime() / 1000 + 15));
    await txStakeWindow.wait()

    const txAddTokens1 = await TokenPresaleContract.connect(wallet).addPaymentToken(USDT, ZERO_ADDRESS, 18n, true)
    await txAddTokens1.wait()

    const txAddTokens2 = await TokenPresaleContract.connect(wallet).addPaymentToken(USDC, ZERO_ADDRESS, 18n, true)
    await txAddTokens2.wait()

    const txAddTokens3 = await TokenPresaleContract.connect(wallet).addPaymentToken(ZERO_ADDRESS, BNB_ORACLE, 18n, false)
    await txAddTokens3.wait()

    // Call allocateToken with the struct
    const txAllocation = await DIContract.connect(wallet).allocateToken(allocationAddresses);
    await txAllocation.wait()

    console.log("Token allocation completed.");
}

main()
.then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });