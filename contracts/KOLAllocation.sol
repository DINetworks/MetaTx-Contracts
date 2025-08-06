// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KOLAllocation is Ownable {
    struct Member {
        string name;
        uint256 balance;
        uint256 startTime;
        uint256 withdrawn;
    }

    IERC20 public immutable token;

    uint256 public constant VESTING_DURATION = 180 days;
    uint256 public constant CLIFF_DURATION = 30 days;
    uint256 private constant NOT_FOUND = type(uint256).max;

    address[] public wallets;
    Member[] public membersInfo;

    uint256 public totalAllocated;
    uint256 public totalWithdrawn;

    constructor(address _token, address _owner) Ownable(_owner) {
        token = IERC20(_token);
    }

    function allocateTokens(
        address[] calldata _wallets,
        string[] calldata names,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            _wallets.length == names.length && names.length == amounts.length,
            "Mismatched input lengths"
        );

        for (uint256 i = 0; i < _wallets.length; ++i) {
            wallets.push(_wallets[i]);
            membersInfo.push(Member({
                name: names[i],
                balance: amounts[i],
                startTime: block.timestamp,
                withdrawn: 0
            }));
            totalAllocated += amounts[i];
        }
    }

    function withdraw() external {
        uint256 index = getMemberIndex(msg.sender);
        require(index != NOT_FOUND, "No Member wallet");

        Member storage member = membersInfo[index];
        uint256 withdrawable = calculateWithdrawable(member);
        require(withdrawable > 0, "Nothing to withdraw");

        member.withdrawn += withdrawable;
        totalWithdrawn += withdrawable;
        token.transfer(msg.sender, withdrawable);
    }

    function getWithdrawable() external view returns (uint256) {
        uint256 index = getMemberIndex(msg.sender);
        require(index != NOT_FOUND, "No Member wallet");
        return calculateWithdrawable(membersInfo[index]);
    }

    function calculateWithdrawable(Member memory member) internal view returns (uint256) {
        if (block.timestamp < member.startTime + CLIFF_DURATION) {
            return 0;
        }

        uint256 elapsed = block.timestamp - member.startTime;
        uint256 vested;

        if (elapsed >= VESTING_DURATION) {
            vested = member.balance;
        } else {
            // 20% after cliff, remaining linearly over remaining time
            uint256 initial = member.balance / 5;
            uint256 linearPart = (member.balance * 4 * (elapsed - CLIFF_DURATION)) / (VESTING_DURATION * 5);
            vested = initial + linearPart;
        }

        if (vested > member.balance) vested = member.balance;

        return vested - member.withdrawn;
    }

    function getMemberIndex(address wallet) internal view returns (uint256) {
        for (uint256 i = 0; i < wallets.length; ++i) {
            if (wallets[i] == wallet) return i;
        }
        return NOT_FOUND;
    }

    function getMemberCount() external view returns (uint256) {
        return wallets.length;
    }

    function getMember(address wallet) external view returns (Member memory) {
        uint256 index = getMemberIndex(wallet);
        require(index != NOT_FOUND, "No Member wallet");
        return membersInfo[index];
    }
}