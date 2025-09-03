// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenStaking is Ownable {
    IERC20 public immutable stakingToken;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        LockDuration lockDuration;
        uint256 stakingShare;
        uint256 rewardDebt;
        uint256 claimedReward;
        uint256 pendingReward;
        uint256 totalAccumulatedReward;
        bool withdrawn;
    }

    struct TotalStakeInfo {
        uint256 totalStaked;
        uint256 stakingShare;
        uint256 rewardIndex;
        uint256 lastUpdatedAt;
        uint256 totalRewardDistributed;
        uint256 lastDistributedAt;
    }

    enum LockDuration {
        NORMAL,
        QUATERLY,
        HALF_YEARLY,
        YEARLY
    }

    uint256 constant YEAR = 365 days;
    uint256 constant DISTRIBITE_UNIT = 10_000 ether;
    uint256 constant totalRewardTokens = 100_000_000 ether;
    
    mapping(address => StakeInfo[]) public userStakes;
    TotalStakeInfo public totalStakes;

    uint256 public rewardMultiplier = 1e18;
    uint256 public stakingStartedAt;
    bool public stakingEnded;

    event RewardMultiplierUpdated(uint256);
    event Staked(address indexed user, uint256 stakedAmount, LockDuration duration);
    event Withdrawn(address indexed user, uint256 stakeIndex, uint256 amount);
    event ClaimedReward(address indexed user, uint256 stakeIndex, uint256 reward);

    constructor(address _stakingToken, address owner_) Ownable(owner_) {
        stakingToken = IERC20(_stakingToken);
    }
    
    function updateDistributeRate(uint256 newMultiplier) external onlyOwner accrueReward {
        rewardMultiplier = newMultiplier;
        emit RewardMultiplierUpdated(newMultiplier);
    }

    function setStartTimeForStaking(uint256 startAt) external onlyOwner {
        require(stakingStartedAt == 0, 'Staking already started');
        require(startAt > block.timestamp, 'Invalid timestamp');

        stakingStartedAt = startAt;
    }

    modifier stakingActive() {
        require(stakingStartedAt != 0 && block.timestamp >= stakingStartedAt, 'Staking not started');
        require(!stakingEnded, 'Staking ended');
        _;
    }

    function stake(uint256 amount, LockDuration duration) external stakingActive {
        require(amount > 0, "Amount must be > 0");

        stakingToken.transferFrom(msg.sender, address(this), amount);

        userStakes[msg.sender].push(StakeInfo({
            amount: amount,
            startTime: block.timestamp,
            endTime: block.timestamp + getLockDuration(duration),
            lockDuration: duration,
            stakingShare: 0,
            rewardDebt: 0,
            claimedReward: 0,
            pendingReward: 0,
            totalAccumulatedReward: 0,
            withdrawn: false
        }));

        updateStakingShare(msg.sender);
        emit Staked(msg.sender, amount, duration);
    }

    function withdraw(uint256 stakeIndex) external {
        StakeInfo storage info = userStakes[msg.sender][stakeIndex];
        require(!info.withdrawn, "Already withdrawn");
        require(block.timestamp >= info.startTime + getLockDuration(info.lockDuration) || stakingEnded, "Lock not expired");

        claimReward(stakeIndex);
        // Update total stakes (subtract the withdrawn amount and share)
        info.withdrawn = true;
        totalStakes.totalStaked -= info.amount;
        totalStakes.stakingShare -= info.stakingShare;

        stakingToken.transfer(msg.sender, info.amount);

        emit Withdrawn(msg.sender, stakeIndex, info.amount);
    }

    function claimReward(uint256 stakeIndex) public accrueReward {
        require(stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        StakeInfo storage info = userStakes[msg.sender][stakeIndex];
        require(!info.withdrawn, "Stake already withdrawn");

        uint256 pending = calculateClaimableReward(info);
        require(pending > 0, "No reward available");

        // Update all reward tracking fields
        info.claimedReward += pending;
        info.rewardDebt = (info.stakingShare * totalStakes.rewardIndex) / 1e18;

        stakingToken.transfer(msg.sender, pending);
        emit ClaimedReward(msg.sender, stakeIndex, pending);
    }

    function calculateClaimableReward(StakeInfo memory info) public view returns (uint256) {
        if (info.withdrawn) 
            return 0;

        uint256 accumulated = (info.stakingShare * totalStakes.rewardIndex) / 1e18;
        if (accumulated < info.rewardDebt) return 0;
        return accumulated - info.rewardDebt;
    }

    function updateStakingShare(address user) internal accrueReward {
        StakeInfo storage userStake = userStakes[user][userStakes[user].length - 1];
        uint256 share = calculateStakingShare(userStake.amount, userStake.lockDuration);

        // Set reward debt before increasing total share
        userStake.rewardDebt = (share * totalStakes.rewardIndex) / 1e18;

        totalStakes.totalStaked += userStake.amount;
        totalStakes.stakingShare += share;
        userStake.stakingShare = share;
    }

    modifier accrueReward() {
        if (totalStakes.lastUpdatedAt == 0)
            totalStakes.lastUpdatedAt = block.timestamp;

        if (block.timestamp > totalStakes.lastUpdatedAt && totalStakes.stakingShare > 0) {
            uint256 duration = block.timestamp - totalStakes.lastUpdatedAt;
            uint256 reward = (duration * getDistributionRate()) / 1 days;
            if (reward + totalStakes.totalRewardDistributed > totalRewardTokens) {
                reward = totalRewardTokens - totalStakes.totalRewardDistributed;
                stakingEnded = true;
            }
            totalStakes.rewardIndex += (reward * 1e18) / totalStakes.stakingShare;
            totalStakes.lastUpdatedAt = block.timestamp;
            totalStakes.totalRewardDistributed += reward;
        }
        _;
    }

    function updateReward() external accrueReward {

    }

    // this is reward amount per day
    function getDistributionRate() internal view returns(uint256) {
        return rewardMultiplier * DISTRIBITE_UNIT/ 1e18;
    }


    function calculateStakingShare(uint256 amount, LockDuration duration) internal pure returns(uint256) {
        return amount * getLockMultiplier(duration) * getAmountMultiplier(amount) / 1e4;
    }

    function calculateAPR() public view returns(uint256) {
        if (totalStakes.stakingShare == 0)
            return 0;

        return getDistributionRate() * 365 * 1e18 / totalStakes.stakingShare;
    } 

    function getLockDuration(LockDuration duration) public pure returns (uint256) {
        if (duration == LockDuration.QUATERLY) return YEAR / 4;
        if (duration == LockDuration.HALF_YEARLY) return YEAR / 2;
        if (duration == LockDuration.YEARLY) return YEAR;
        return 0;
    }

    function getLockMultiplier(LockDuration duration) public pure returns (uint256) {
        if (duration == LockDuration.QUATERLY) return 125;
        if (duration == LockDuration.HALF_YEARLY) return 150;
        if (duration == LockDuration.YEARLY) return 200;
        return 100;
    }

    function getAmountMultiplier(uint256 amount) public pure returns (uint256) {
        if (amount >= 500_000 ether) return 250;
        if (amount >= 200_000 ether) return 200;
        if (amount >= 100_000 ether) return 150;
        if (amount >= 50_000 ether) return 125;
        if (amount >= 20_000 ether) return 115;
        return 100;
    }

    function getStakes(address user) external view returns (StakeInfo[] memory stakes) {
        stakes = userStakes[user];
        for (uint256 i = 0; i < stakes.length; ++i) {
            stakes[i].pendingReward = calculateClaimableReward(stakes[i]);
        }
    }

    function getTotalStakes() external view returns (TotalStakeInfo memory) {
        return totalStakes;
    }
} 
