const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("GasCreditVault", function () {
  let vault, owner, user, relayer, token, stableToken;
  let MockToken, MockAggregator;
  let tokenPriceFeed, stablePriceFeed;

  // Constants for better readability
  const TOKEN_DECIMALS = 18;
  const INITIAL_PRICE = ethers.parseUnits("200", 8); // $200
  const STABLE_PRICE = ethers.parseUnits("1", 8); // $1
  const LARGE_AMOUNT = ethers.parseEther("1000");
  const MEDIUM_AMOUNT = ethers.parseEther("100");
  const SMALL_AMOUNT = ethers.parseEther("10");

  before(async function () {
    [owner, user, relayer, other] = await ethers.getSigners();
  });

  beforeEach(async function () {
    // Deploy mock tokens
    MockToken = await ethers.getContractFactory("MockERC20");
    token = await MockToken.deploy("Mock Token", "MTKN", TOKEN_DECIMALS);
    await token.waitForDeployment();

    stableToken = await MockToken.deploy("Stable Token", "USDT", TOKEN_DECIMALS);
    await stableToken.waitForDeployment();

    // Deploy price feeds
    MockAggregator = await ethers.getContractFactory("MockAggregatorV3");
    tokenPriceFeed = await MockAggregator.deploy(INITIAL_PRICE, 8);
    await tokenPriceFeed.waitForDeployment();

    stablePriceFeed = await MockAggregator.deploy(STABLE_PRICE, 8);
    await stablePriceFeed.waitForDeployment();

    // Deploy vault
    const Vault = await ethers.getContractFactory("GasCreditVault", owner);

    vault = await upgrades.deployProxy(Vault, [], {
      initializer: "initialize",
      kind: "uups",
    })
    await vault.waitForDeployment();

    // Setup vault
    await vault.whitelistToken(token.target, tokenPriceFeed.target, false);
    await vault.whitelistToken(stableToken.target, stablePriceFeed.target, true);
    await vault.addWhitelistedRelayer(relayer.address);

    // Mint tokens to user
    await token.mint(user.address, LARGE_AMOUNT);
    await stableToken.mint(user.address, LARGE_AMOUNT);
  });

  describe("Deposit functionality", function () {
    it("should deposit and credit stable token correctly", async function () {
      await stableToken.connect(user).approve(vault.target, MEDIUM_AMOUNT);
      await vault.connect(user).deposit(stableToken.target, MEDIUM_AMOUNT);

      const credit = await vault.credits(user.address);
      expect(credit).to.equal(MEDIUM_AMOUNT);
    });

    it("should deposit and credit volatile token based on price feed", async function () {
      const depositAmount = ethers.parseEther("1"); // 1 token = $200
      await token.connect(user).approve(vault.target, depositAmount);
      await vault.connect(user).deposit(token.target, depositAmount);

      const expectedCredits = ethers.parseEther("200");
      const credit = await vault.credits(user.address);
      expect(credit).to.equal(expectedCredits);
    });

    it("should revert when depositing unwhitelisted token", async function () {
      const unlistedToken = await MockToken.deploy("Bad Token", "BAD", TOKEN_DECIMALS);
      await unlistedToken.waitForDeployment();

      await unlistedToken.mint(user.address, MEDIUM_AMOUNT);
      
      await unlistedToken.connect(user).approve(vault.target, MEDIUM_AMOUNT);
      await expect(
        vault.connect(user).deposit(unlistedToken.target, MEDIUM_AMOUNT)
      ).to.be.revertedWith("Token not whitelisted");
    });
  });

  describe("Credit consumption", function () {
    beforeEach(async function () {
      // Setup initial deposit for consumption tests
      await token.connect(user).approve(vault.target, MEDIUM_AMOUNT);
      await vault.connect(user).deposit(token.target, MEDIUM_AMOUNT);
    });

    it("should consume credits by relayer", async function () {
      await vault.connect(relayer).consumeCredit(user.address, SMALL_AMOUNT);
      const remaining = await vault.credits(user.address);
      expect(remaining).to.equal(ethers.parseEther("19990")); // 100 - 10
    });

    it("should revert when non-relayer tries to consume", async function () {
      await expect(
        vault.connect(other).consumeCredit(user.address, SMALL_AMOUNT)
      ).to.be.revertedWith("Caller not whitelisted relayers");
    });

    it("should revert when consuming more than available credits", async function () {
      const excessiveAmount = ethers.parseEther("20001");
      await expect(
        vault.connect(relayer).consumeCredit(user.address, excessiveAmount)
      ).to.be.revertedWith("Insufficient credits");
    });
  });

  describe("Withdrawal functionality", function () {
    it("should allow user to withdraw stable tokens", async function () {
      await stableToken.connect(user).approve(vault.target, MEDIUM_AMOUNT);
      await vault.connect(user).deposit(stableToken.target, MEDIUM_AMOUNT);

      await vault.connect(user).withdraw(stableToken.target, MEDIUM_AMOUNT);

      const credit = await vault.credits(user.address);
      expect(credit).to.equal(0);
    });

    it("should allow the owner to withdraw consumed credits", async function () {
      // Setup initial state
      await token.connect(user).approve(vault.target, MEDIUM_AMOUNT);
      await vault.connect(user).deposit(token.target, MEDIUM_AMOUNT);
      
      // Consume some credits
      await vault.connect(relayer).consumeCredit(user.address, SMALL_AMOUNT);
      
      // Owner withdraws
      const ownerBalanceBefore = await token.balanceOf(owner.address);
      await vault.connect(owner).withdrawConsumedCredits();
      const ownerBalanceAfter = await token.balanceOf(owner.address);

      expect(ownerBalanceAfter).to.be.gt(ownerBalanceBefore);
    });

    it("should revert when non-owner tries to withdraw consumed credits", async function () {
      await expect(
        vault.connect(user).withdrawConsumedCredits()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});