// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GasCreditVault is Initializable, OwnableUpgradeable, UUPSUpgradeable  {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct TokenInfo {
        AggregatorV3Interface priceFeed;
        bool isStablecoin;
    }
    // Events
    event TokenWhitelisted(address indexed token, address priceFeed);
    event TokenRemoved(address indexed token);
    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 credited);
    event Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 credited);
    event CreditsConsumed(address indexed user, uint256 usdValue, uint256 creditCost);
    event CreditTransfer(address indexed sender, address indexed receiver, uint256 creditAmount);
    event OwnerWithdrawn(address indexed token, uint256 amount, uint256 creditedConsumed);
    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);
    event EmergencyWithdrawn(address indexed to, uint256 amount);
    event Paused();
    event Unpaused();

    EnumerableSet.AddressSet private whitelistedTokens;
    EnumerableSet.AddressSet private relayers;

    mapping(address => TokenInfo) public tokenInfo;
    mapping(address => uint256) public credits;
    mapping(address => mapping(address => uint256)) public creditsInToken;
    mapping(address => uint256) public totalConsumed;
    
    uint256 public totalConsumedCreditsWithdrawn;
    uint256 public totalConsumedCredits;

    uint256 public minimumConsume;
    uint8 public constant creditDecimals = 18;

    // bool public paused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        minimumConsume = 0.5 ether;
    }

    // Modifiers
    modifier onlyRelayer() {
        require(relayers.contains(msg.sender), "Caller not whitelisted relayers");
        _;
    }

    modifier onlyStablecoin(address token) {
        require(tokenInfo[token].isStablecoin, "Token not stablecoin");
        _;
    }

    // modifier whenNotPaused() {
    //     require(!paused, "Paused");
    //     _;
    // }

    // modifier whenPaused() {
    //     require(paused, "Unpaused");
    //     _;
    // }
    // Owner functions ==============================================

    // Function to add a whitelisted relayer
    function addWhitelistedRelayer(address relayer) external onlyOwner {
        require(relayer != address(0), "Invalid address");
        require(!relayers.contains(relayer), "Relayer already whitelisted");

        relayers.add(relayer);

        emit RelayerAdded(relayer);
    }

    // Function to remove a whitelisted relayer
    function removeWhitelistedRelayer(address relayer) external onlyOwner {
        require(relayers.contains(relayer), "Relayer not whitelisted");

        relayers.remove(relayer);

        emit RelayerRemoved(relayer);
    }

    function whitelistToken(
        address token,
        address priceFeed,
        bool isStablecoin
    ) external onlyOwner {
        require(!whitelistedTokens.contains(token), "Token already whitelisted");
        require(priceFeed != address(0), "Invalid price feed");
        
        whitelistedTokens.add(token);
        tokenInfo[token] = TokenInfo({
            priceFeed: AggregatorV3Interface(priceFeed),
            isStablecoin: isStablecoin
        });

        emit TokenWhitelisted(token, priceFeed);
    }

    function removeToken(address token) external onlyOwner {
        require(IERC20(token).balanceOf(address(this)) == 0, "None Zero Balance");
        require(whitelistedTokens.contains(token), "Token not whitelisted");
        whitelistedTokens.remove(token);
        delete tokenInfo[token];

        emit TokenRemoved(token);
    }

    // Emergency functions - pause/unpause protocol
    // function pause() external onlyOwner {
    //     require(!paused, "Already paused");
    //     paused = true;
    //     emit Paused();
    // }

    // function unpause() external onlyOwner {
    //     require(paused, "Not paused");
    //     paused = false;
    //     emit Unpaused();
    // }

    function emergencyWithdraw() external onlyOwner {
        address[] memory tokens = whitelistedTokens.values();
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(owner(), balance);

            emit EmergencyWithdrawn(token, balance);
        }        
    }

    function setMinimumConsume(uint256 _minimum) external onlyOwner {
        require(_minimum > 0, "Minimum must be > 0");
        minimumConsume = _minimum;
    }

    // User functions ==============================================
    function deposit(address token, uint256 amount) external {
        require(whitelistedTokens.contains(token), "Token not whitelisted");
        require(amount > 0, "Amount must be > 0");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 creditedAmount = calculateCreditValue(token, amount);

        credits[msg.sender] += creditedAmount;
        creditsInToken[msg.sender][token] += creditedAmount;

        emit Deposited(msg.sender, token, amount, creditedAmount);
    }

    function withdraw(address token, uint256 creditAmount) external onlyStablecoin(token) {
        require(creditsInToken[msg.sender][token] >= creditAmount, "Insufficient token balance");

        uint256 tokenAmount = calculateTokenValue(token, creditAmount);
        require(IERC20(token).balanceOf(address(this)) >= tokenAmount, "Insufficient token in Vault");

        // Update credits
        credits[msg.sender] -= creditAmount;
        creditsInToken[msg.sender][token] -= creditAmount;

        IERC20(token).safeTransfer(msg.sender, tokenAmount);

        emit Withdrawn(msg.sender, token, tokenAmount, creditAmount);
    }

    // Consumption function ====================================
    function consumeCredit(address user, uint256 usdValue) external onlyRelayer {
        require(usdValue > 0, "Value must be > 0");

        uint256 creditCost = usdValue > minimumConsume ? usdValue : minimumConsume;

        require(credits[user] >= creditCost, "Insufficient credits");

        uint256 remaining = creditCost;

        // Iterate over whitelisted tokens and deduct credited and deposited accordingly
        address[] memory tokens = whitelistedTokens.values();
        for (uint256 i = 0; i < tokens.length && remaining > 0; ++i) {
            address token = tokens[i];
            uint256 userCredited = creditsInToken[user][token];

            if (userCredited == 0) continue;

            uint256 deduction = userCredited >= remaining ? remaining : userCredited;

            creditsInToken[user][token] -= deduction;

            remaining -= deduction;
        }

        credits[user] -= creditCost;
        totalConsumedCredits += creditCost;
        // require(remaining == 0, "Not enough credited tokens to burn");
    }

    function transferCredit(address receiver, uint256 credit) external {
        address sender = msg.sender;
        require(credit > minimumConsume && credits[sender] > credit, 'Invalid amount');
        
        uint256 remaining = credit;
        address[] memory tokens = whitelistedTokens.values();
        for (uint256 i = 0; i < tokens.length && remaining > 0; ++i) {
            address token = tokens[i];
            uint256 userCredited = creditsInToken[sender][token];

            if (userCredited == 0) continue;

            uint256 deduction = userCredited >= remaining ? remaining : userCredited;

            creditsInToken[sender][token] -= deduction;
            creditsInToken[receiver][token] += deduction;
            remaining -= deduction;
        }

        credits[receiver] += credit;
        credits[sender] -= credit;
        emit CreditTransfer(sender, receiver, credit);
    }

    function withdrawConsumedCredits() external onlyOwner {
        require(totalConsumedCredits > totalConsumedCreditsWithdrawn, "No new credits to withdraw");

        uint256 deltaCredits = totalConsumedCredits - totalConsumedCreditsWithdrawn;
        totalConsumedCredits = totalConsumedCredits;

        address[] memory tokens = whitelistedTokens.values();
        uint256 totalTokenAmount = 0;

        // Step 1: Calculate the total token amount corresponding to the consumed credits
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];

            // Get the token balance for the contract
            uint256 contractBalance = IERC20(token).balanceOf(address(this));
            if (contractBalance == 0) continue;

            // Calculate the credit value for the token balance in terms of consumed credits
            uint256 tokenValueInCredits = calculateCreditValue(token, contractBalance);

            // Withdraw the corresponding amount of tokens based on the consumed credits
            uint256 tokenAmount = (deltaCredits * contractBalance) / tokenValueInCredits;

            // Ensure we don’t withdraw more than the available balance
            if (tokenAmount > contractBalance) {
                tokenAmount = contractBalance;
            }

            // If tokenAmount is greater than zero, withdraw it to the owner
            if (tokenAmount > 0) {
                IERC20(token).safeTransfer(owner(), tokenAmount);
                totalTokenAmount += tokenAmount;
                emit OwnerWithdrawn(token, tokenAmount, deltaCredits);
            }
        }

        // Total withdrawal value for owner
        // require(totalTokenAmount > 0, "No tokens to withdraw");
    }

    // Price calculation functions ================================
    function calculateCreditValue(address token, uint256 amount) internal view returns (uint256) {
        TokenInfo memory info = tokenInfo[token];
        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        
        if (info.isStablecoin) {
            return convertDecimals(amount, tokenDecimals, creditDecimals);
        }

        (, int256 price,,,) = info.priceFeed.latestRoundData();
        
        uint8 _decimals = tokenDecimals + info.priceFeed.decimals();
        
        // Formula: (amount * price) / (10^(tokenDecimals + priceFeedDecimals - creditDecimals))
        return convertDecimals(amount * uint256(price), _decimals, creditDecimals);
    }

    function calculateTokenValue(address token, uint256 creditAmount) internal view returns (uint256) {
        TokenInfo memory info = tokenInfo[token];
        uint8 tokenDecimals = IERC20Metadata(token).decimals();

        if (info.isStablecoin) {
            return convertDecimals(creditAmount, creditDecimals, tokenDecimals);
        }

        (, int256 price,,,) = info.priceFeed.latestRoundData();
        
        uint8 _decimals = tokenDecimals + info.priceFeed.decimals();
        // Formula: (creditAmount * 10^(tokenDecimals + priceFeedDecimals)) / (price * 10 ^ creditDecimals) 
        return convertDecimals(creditAmount / uint256(price), creditDecimals, _decimals);
    }

    function convertDecimals(uint256 amount, uint8 from, uint8 to) internal pure returns (uint256) {
        unchecked {
            return from > to ? 
                amount / (10 ** (from - to)) :
                amount * (10 ** (to - from));
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    // View functions =============================================
    function getWhitelistedTokens() external view returns (address[] memory) {
        return whitelistedTokens.values();
    }

    function getCreditValue(address token, uint256 amount) external view returns (uint256) {
        return calculateCreditValue(token, amount);
    }

    function getTokenValue(address token, uint256 creditAmount) external view returns (uint256) {
        return calculateTokenValue(token, creditAmount);
    }
}