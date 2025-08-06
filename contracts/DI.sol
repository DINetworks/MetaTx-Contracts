// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DI is ERC20, ERC20Permit, ERC20Votes, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 ether;

    struct AllocationAddresses {
        address presaleContract;
        address marketingWallet;
        address teamAllocationContract;
        address airdropContract;
        address stakingContract;
        address kolAllocationContract;
        address treasuryWallet;
        address ecosystemWallet;
        address liquidityWallet;
    }

    AllocationAddresses public allocationAddresses;

    constructor(address _owner)
        ERC20("DI Network", "DI")
        ERC20Permit("DI")
        Ownable(_owner)
    {
           
    }

    function allocateToken(AllocationAddresses memory addrs) external onlyOwner {
        require(
            addrs.presaleContract != address(0) &&
            addrs.marketingWallet != address(0) &&
            addrs.kolAllocationContract != address(0) &&
            addrs.teamAllocationContract != address(0) &&
            addrs.treasuryWallet != address(0) &&
            addrs.ecosystemWallet != address(0) &&
            addrs.stakingContract != address(0) &&
            addrs.liquidityWallet != address(0) &&
            addrs.airdropContract != address(0),
            "Invalid address"
        );

        allocationAddresses.presaleContract = addrs.presaleContract;
        allocationAddresses.marketingWallet = addrs.marketingWallet;
        allocationAddresses.kolAllocationContract = addrs.kolAllocationContract;
        allocationAddresses.teamAllocationContract = addrs.teamAllocationContract;
        allocationAddresses.treasuryWallet = addrs.treasuryWallet;
        allocationAddresses.ecosystemWallet = addrs.ecosystemWallet;
        allocationAddresses.stakingContract = addrs.stakingContract;
        allocationAddresses.liquidityWallet = addrs.liquidityWallet;
        allocationAddresses.airdropContract = addrs.airdropContract;     
            
        uint256 presaleAllocation = 150_000_000 ether;
        uint256 marketingAllocation = 100_000_000 ether;
        uint256 kolAllocation = 50_000_000 ether;
        uint256 teamAllocation = 50_000_000 ether;
        uint256 treasuryAllocation = 150_000_000 ether;
        uint256 ecosystemAllocation = 300_000_000 ether;
        uint256 stakingAllocation = 100_000_000 ether;
        uint256 liquidityAllocation = 150_000_000 ether;
        uint256 airdropAllocation = 50_000_000 ether;

        // Mint
        _mint(allocationAddresses.presaleContract, presaleAllocation);
        _mint(allocationAddresses.marketingWallet, marketingAllocation);
        _mint(allocationAddresses.kolAllocationContract, kolAllocation);
        _mint(allocationAddresses.teamAllocationContract, teamAllocation);
        _mint(allocationAddresses.treasuryWallet, treasuryAllocation);
        _mint(allocationAddresses.ecosystemWallet, ecosystemAllocation - stakingAllocation);
        _mint(allocationAddresses.stakingContract, stakingAllocation);
        _mint(allocationAddresses.liquidityWallet, liquidityAllocation);
        _mint(allocationAddresses.airdropContract, airdropAllocation);
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    // Required overrides
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address sender)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(sender);
    }
}