const dotenv = require('dotenv')
const { ContractFactory, Wallet, JsonRpcProvider, parseUnits } = require('ethers');
const artifactsDIN = require('../artifacts/contracts/DIN.sol/DIN.json')
const artifactsDINVote = require('../artifacts/contracts/DINVote.sol/DINVote.json')
const artifactsKOLAllocation = require('../artifacts/contracts/KOLAllocation.sol/KOLAllocation.json')
const artifactsTeamAllocation = require('../artifacts/contracts/TeamAllocation.sol/TeamAllocation.json')
const artifactsDINAirdrop = require('../artifacts/contracts/TokenAirdrop.sol/TokenAirdrop.json')
const artifactsDINPresale = require('../artifacts/contracts/TokenPresale.sol/TokenPresale.json')
const artifactsDINStaking = require('../artifacts/contracts/TokenStaking.sol/TokenStaking.json')
const artifactsMockAggregator = require('../artifacts/contracts/mock/MockAggregatorV3.sol/MockAggregatorV3.json')
const artifactsMockUSDT = require('../artifacts/contracts/mock/MockUSDT.sol/MockUSDT.json')
const artifactsMockUSDC = require('../artifacts/contracts/mock/MockUSDC.sol/MockUSDC.json')

dotenv.config()

const provider = new JsonRpcProvider(process.env.RPC_URL); 
const wallet = new Wallet(process.env.PRIVATE_KEY, provider);

// owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

const marketingWallet = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
const treasuryWallet = '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'
const ecosystemWallet = '0x90F79bf6EB2c4f870365E785982E1f101E93b906'
const liquidityWallet = '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65'

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

async function main() {

    const owner = wallet.address

    const DINFactory = new ContractFactory(artifactsDIN.abi, artifactsDIN.bytecode, wallet);
    const DINContract = await DINFactory.deploy(owner)
    await DINContract.waitForDeployment();
    const DINContractAddress = DINContract.target;
    console.log(artifactsDIN.contractName, DINContractAddress)

    const DINVoteFactory = new ContractFactory(artifactsDINVote.abi, artifactsDINVote.bytecode, wallet);
    const DINVoteContract = await DINVoteFactory.deploy(DINContractAddress, owner)
    await DINVoteContract.waitForDeployment();
    console.log(artifactsDINVote.contractName, DINVoteContract.target)

    const KOLAllocationFactory = new ContractFactory(artifactsKOLAllocation.abi, artifactsKOLAllocation.bytecode, wallet);
    const KOLAllocationContract = await KOLAllocationFactory.deploy(DINContractAddress, owner)
    await KOLAllocationContract.waitForDeployment();
    console.log(artifactsKOLAllocation.contractName, KOLAllocationContract.target)

    const TeamAllocationFactory = new ContractFactory(artifactsTeamAllocation.abi, artifactsTeamAllocation.bytecode, wallet);
    const TeamAllocationContract = await TeamAllocationFactory.deploy(DINContractAddress, owner)
    await TeamAllocationContract.waitForDeployment();
    console.log(artifactsTeamAllocation.contractName, TeamAllocationContract.target)

    const TokenAirdropFactory = new ContractFactory(artifactsDINAirdrop.abi, artifactsDINAirdrop.bytecode, wallet);
    const TokenAirdropContract = await TokenAirdropFactory.deploy(DINContractAddress, owner)
    await TokenAirdropContract.waitForDeployment();
    console.log(artifactsDINAirdrop.contractName, TokenAirdropContract.target)

    const TokenPresaleFactory = new ContractFactory(artifactsDINPresale.abi, artifactsDINPresale.bytecode, wallet);
    const TokenPresaleContract = await TokenPresaleFactory.deploy(DINContractAddress, parseUnits("150000000", 18), owner)
    await TokenPresaleContract.waitForDeployment();
    console.log(artifactsDINPresale.contractName, TokenPresaleContract.target)

    const TokenStakingFactory = new ContractFactory(artifactsDINStaking.abi, artifactsDINStaking.bytecode, wallet);
    const TokenStakingContract = await TokenStakingFactory.deploy(DINContractAddress, owner)
    await TokenStakingContract.waitForDeployment();
    console.log(artifactsDINStaking.contractName, TokenStakingContract.target)

    const MockUSDTFactory = new ContractFactory(artifactsMockUSDT.abi, artifactsMockUSDT.bytecode, wallet);
    const MockUSDTContract = await MockUSDTFactory.deploy()
    await MockUSDTContract.waitForDeployment();
    console.log(artifactsMockUSDT.contractName, MockUSDTContract.target)

    const MockUSDCFactory = new ContractFactory(artifactsMockUSDC.abi, artifactsMockUSDC.bytecode, wallet);
    const MockUSDCContract = await MockUSDCFactory.deploy()
    await MockUSDCContract.waitForDeployment();
    console.log(artifactsMockUSDC.contractName, MockUSDCContract.target)

    const MockBNBOracleFactory = new ContractFactory(artifactsMockAggregator.abi, artifactsMockAggregator.bytecode, wallet);
    const MockBNBOracleContract = await MockBNBOracleFactory.deploy(parseUnits("649.4", 8), 8n)
    await MockBNBOracleContract.waitForDeployment();
    console.log("BNBOracleContract", MockBNBOracleContract.target)

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

    const txAddTokens1 = await TokenPresaleContract.connect(wallet).addPaymentToken(MockUSDTContract.target, ZERO_ADDRESS, 18n, true)
    await txAddTokens1.wait()

    const txAddTokens2 = await TokenPresaleContract.connect(wallet).addPaymentToken(MockUSDCContract.target, ZERO_ADDRESS, 18n, true)
    await txAddTokens2.wait()

    const txAddTokens3 = await TokenPresaleContract.connect(wallet).addPaymentToken(ZERO_ADDRESS, MockBNBOracleContract.target, 18n, false)
    await txAddTokens3.wait()

    // Call allocateToken with the struct
    const txAllocation = await DINContract.connect(wallet).allocateToken(allocationAddresses);
    await txAllocation.wait()

    console.log("Token allocation completed.");
}

main()
.then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });