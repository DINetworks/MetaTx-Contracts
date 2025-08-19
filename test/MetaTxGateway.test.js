const { expect } = require("chai");
const { ethers } = require("hardhat")

describe("MetaTxGateway", () => {
  let gateway;
  let token;
  let owner;
  let relayer;
  let sender;
  let recipient;

  let chainId;

  beforeEach(async () => {
    [owner, relayer, sender, recipient] = await ethers.getSigners();
    chainId = (await ethers.provider.getNetwork()).chainId;

    const Token = await ethers.getContractFactory("MockERC20");
    token = await Token.connect(owner).deploy("MockToken", "MTK", 18);
    await token.waitForDeployment();

    const Gateway = await ethers.getContractFactory("MetaTxGateway");
    gateway = await Gateway.connect(owner).deploy(owner.address);
    await gateway.waitForDeployment();

    // Mint and approve tokens for sender
    await token.connect(owner).mint(sender.address, ethers.parseEther("100"));
    await token.connect(sender).approve(gateway.target, ethers.parseEther("100"));
  });

  it("should allow owner to add and remove relayers", async () => {
    await gateway.connect(owner).addWhitelistedRelayer(relayer.address);
    const relayers = await gateway.getWhitelistedRelayers();
    expect(relayers).to.include(relayer.address);

    await gateway.connect(owner).removeWhitelistedRelayer(relayer.address);
    const updated = await gateway.getWhitelistedRelayers();
    expect(updated).to.not.include(relayer.address);
  });

  it("should execute a valid meta transfer", async () => {
    const amount = ethers.parseEther("10");

    // Add relayer
    await gateway.connect(owner).addWhitelistedRelayer(relayer.address);

    const targets = [token.target];
    const recipients = [await recipient.address];
    const amounts = [amount];
    const transferData = ethers.AbiCoder.defaultAbiCoder().encode(
      ["address[]", "address[]", "uint256[]"],
      [targets, recipients, amounts]
    );

    const nonce = await gateway.nonces(sender.address);

    // EIP712 domain separator
    const domain = {
      name: "MetaTxGateway",
      version: "1",
      chainId,
      verifyingContract: gateway.target,
    };

    const types = {
      Transfer: [
        { name: "sender", type: "address" },
        { name: "transferData", type: "bytes" },
        { name: "nonce", type: "uint256" },
      ],
    };

    const value = {
      sender: sender.address,
      transferData,
      nonce,
    };

    const signature = await sender.signTypedData(domain, types, value);

    // Execute meta transfer from relayer
    await expect(
      gateway.connect(relayer).executeMetaTransfer(
        sender.address,
        transferData,
        nonce,
        signature
      )
    ).to.emit(gateway, "MetaTransactionExecuted");

    // Check balance
    const recipientBal = await token.balanceOf(recipient.address);
    expect(recipientBal).to.equal(amount);
  });

  it("should revert if called by non-relayer", async () => {
    const fakeRelayer = sender;

    const amount = ethers.parseEther("1");
    const transferData = ethers.AbiCoder.defaultAbiCoder().encode(
      ["address[]", "address[]", "uint256[]"],
      [[token.target], [await recipient.address], [amount]]
    );

    const nonce = await gateway.nonces(sender.address);

    const domain = {
      name: "MetaTxGateway",
      version: "1",
      chainId,
      verifyingContract: gateway.target,
    };

    const types = {
      Transfer: [
        { name: "sender", type: "address" },
        { name: "transferData", type: "bytes" },
        { name: "nonce", type: "uint256" },
      ],
    };

    const value = {
      sender: sender.address,
      transferData,
      nonce,
    };

    const signature = await sender.signTypedData(domain, types, value);

    // Reverts because fakeRelayer is not whitelisted
    await expect(
      gateway.connect(fakeRelayer).executeMetaTransfer(
        sender.address,
        transferData,
        nonce,
        signature
      )
    ).to.be.revertedWith("Caller not whitelisted relayers");
  });
});