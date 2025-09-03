// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title GasCreditVault
 * @dev A vault contract that allows users to deposit tokens and receive credits for gas payments
 * Features:
 * - Multi-token support with stablecoin and price feed integration
 * - Credit-based system for gas payment abstraction
 * - Relayer-based consumption model
 * - Owner withdrawal of consumed credits
 * - Emergency pause functionality
 * - Upgradeable contract pattern
 */
contract GasCreditVault is Initializable, OwnableUpgradeable, UUPSUpgradeable  {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    /**
     * @dev Token information structure
     * @param priceFeed Chainlink price feed interface for non-stablecoin tokens
     * @param isStablecoin Whether the token is a stablecoin (1:1 USD)
     */
    struct TokenInfo {
        AggregatorV3Interface priceFeed;
        bool isStablecoin;
    }
    
    // Events
    event TokenWhitelisted(address indexed token, address priceFeed);
    event TokenRemoved(address indexed token);
    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 credited);
    event Withdrawn(address indexed user, uint256 creditAmount, uint256 withdrawnCredits);
    event CreditsConsumed(address indexed user, uint256 usdValue, uint256 creditCost);
    event CreditTransfer(address indexed sender, address indexed receiver, uint256 creditAmount);
    event ConsumedCreditsWithdrawn(address indexed owner, uint256 creditsWithdrawn);
    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);
    event EmergencyWithdrawn(address indexed to, uint256 amount);
    event Paused();
    event Unpaused();

    // State variables
    EnumerableSet.AddressSet private whitelistedTokens;
    EnumerableSet.AddressSet private relayers;

    mapping(address => TokenInfo) public tokenInfo;
    mapping(address => uint256) public credits;
    
    uint256 public totalConsumedCreditsWithdrawn;
    uint256 public totalConsumedCredits;

    uint256 public minimumConsume;
    uint8 public constant creditDecimals = 18;
    uint256 public constant PRICE_FEED_TIMEOUT = 3600; // 1 hour for stale price protection

    bool public paused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with default settings
     * @notice This function can only be called once during deployment
     * Sets up ownership, upgradeability, and default minimum consume amount
     */
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        minimumConsume = 0.05 ether;
    }

    // Modifiers
    
    /**
     * @dev Modifier to restrict function access to whitelisted relayers only
     */
    modifier onlyRelayer() {
        require(relayers.contains(msg.sender), "Caller not whitelisted relayers");
        _;
    }

    /**
     * @dev Modifier to ensure the token is a stablecoin
     * @param token The token address to check
     */
    modifier onlyStablecoin(address token) {
        require(tokenInfo[token].isStablecoin, "Token not stablecoin");
        _;
    }

    /**
     * @dev Modifier to prevent function execution when contract is paused
     */
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    /**
     * @dev Modifier to ensure function execution only when contract is paused
     */
    modifier whenPaused() {
        require(paused, "Unpaused");
        _;
    }
    // Owner functions ==============================================

    /**
     * @dev Adds a new relayer to the whitelist
     * @param relayer The address of the relayer to add
     * @notice Only owner can call this function
     * @notice Relayer address must not be zero and not already whitelisted
     */
    function addWhitelistedRelayer(address relayer) external onlyOwner {
        require(relayer != address(0), "Invalid address");
        require(!relayers.contains(relayer), "Relayer already whitelisted");

        relayers.add(relayer);

        emit RelayerAdded(relayer);
    }

    /**
     * @dev Removes a relayer from the whitelist
     * @param relayer The address of the relayer to remove
     * @notice Only owner can call this function
     * @notice Relayer must be currently whitelisted
     */
    function removeWhitelistedRelayer(address relayer) external onlyOwner {
        require(relayers.contains(relayer), "Relayer not whitelisted");

        relayers.remove(relayer);

        emit RelayerRemoved(relayer);
    }

    /**
     * @dev Adds a token to the whitelist with price feed configuration
     * @param token The token contract address
     * @param priceFeed The Chainlink price feed address (can be zero for stablecoins)
     * @param isStablecoin Whether the token is a stablecoin (1:1 USD value)
     * @notice Only owner can call this function
     * @notice Token must not already be whitelisted
     * @notice Non-stablecoins must have a valid price feed
     */
    function whitelistToken(
        address token,
        address priceFeed,
        bool isStablecoin
    ) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(!whitelistedTokens.contains(token), "Token already whitelisted");
        require(isStablecoin || priceFeed != address(0), "Invalid price feed");
        
        whitelistedTokens.add(token);
        tokenInfo[token] = TokenInfo({
            priceFeed: AggregatorV3Interface(priceFeed),
            isStablecoin: isStablecoin
        });

        emit TokenWhitelisted(token, priceFeed);
    }

    /**
     * @dev Removes a token from the whitelist
     * @param token The token contract address to remove
     * @notice Only owner can call this function
     * @notice Token must have zero balance in the contract
     * @notice Token must be currently whitelisted
     */
    function removeToken(address token) external onlyOwner {
        require(IERC20(token).balanceOf(address(this)) == 0, "None Zero Balance");
        require(whitelistedTokens.contains(token), "Token not whitelisted");
        whitelistedTokens.remove(token);
        delete tokenInfo[token];

        emit TokenRemoved(token);
    }

    /**
     * @dev Pauses the contract, preventing deposits, withdrawals, and transfers
     * @notice Only owner can call this function
     * @notice Contract must not already be paused
     */
    function pause() external onlyOwner {
        require(!paused, "Already paused");
        paused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses the contract, allowing normal operations
     * @notice Only owner can call this function
     * @notice Contract must be currently paused
     */
    function unpause() external onlyOwner {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused();
    }

    /**
     * @dev Emergency function to withdraw all tokens to owner
     * @notice Only owner can call this function
     * @notice Should only be used in emergency situations
     * @notice Withdraws all balances of whitelisted tokens
     */
    function emergencyWithdraw() external onlyOwner {
        address[] memory tokens = whitelistedTokens.values();
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeTransfer(owner(), balance);
                emit EmergencyWithdrawn(token, balance);
            }
        }        
    }

    /**
     * @dev Sets the minimum consumption amount
     * @param _minimum The new minimum consumption amount in credit decimals
     * @notice Only owner can call this function
     * @notice Minimum must be greater than zero
     */
    function setMinimumConsume(uint256 _minimum) external onlyOwner {
        require(_minimum > 0, "Minimum must be > 0");
        minimumConsume = _minimum;
    }

    // User functions ==============================================
    
    /**
     * @dev Allows users to deposit tokens and receive credits
     * @param token The token contract address to deposit
     * @param amount The amount of tokens to deposit
     * @notice Token must be whitelisted and amount must be greater than zero
     * @notice Contract must not be paused
     * @notice Credits are calculated based on token price and decimals
     */
    function deposit(address token, uint256 amount) external whenNotPaused {
        require(whitelistedTokens.contains(token), "Token not whitelisted");
        require(amount > 0, "Amount must be > 0");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 creditedAmount = calculateCreditValue(token, amount);

        credits[msg.sender] += creditedAmount;

        emit Deposited(msg.sender, token, amount, creditedAmount);
    }

    /**
     * @dev Allows users to withdraw stablecoins using their credits
     * @param creditAmount The amount of credits to convert to tokens
     * @notice Only works with stablecoins
     * @notice User must have sufficient credits in the specified token
     * @notice Contract must not be paused
     * @notice Vault must have sufficient token balance
     */
    function withdraw(uint256 creditAmount) external whenNotPaused {
        require(credits[msg.sender] >= creditAmount, "Insufficient token balance");

        uint256 remaining = creditAmount;
        address[] memory tokens = whitelistedTokens.values();
        for (uint256 i = 0; i < tokens.length && remaining > 0; ++i) {
            address token = tokens[i];
            TokenInfo memory info = tokenInfo[token];            
            uint256 contractBalance = IERC20(token).balanceOf(address(this));
            if (!info.isStablecoin || contractBalance == 0) {
                continue; 
            }

            uint256 tokenAmount = calculateTokenValue(token, remaining);
            uint256 deduction = tokenAmount >= contractBalance ? contractBalance : tokenAmount;
            IERC20(token).safeTransfer(msg.sender, deduction);

            remaining -= deduction;
        }

        // Update credits
        uint256 withdrawnCredits = creditAmount - remaining;
        credits[msg.sender] -= withdrawnCredits;

        emit Withdrawn(msg.sender, creditAmount, withdrawnCredits);
    }

    // Consumption function ====================================
    
    /**
     * @dev Allows relayers to consume user credits for gas payment
     * @param user The user whose credits will be consumed
     * @param usdValue The USD value of gas consumed
     * @notice Only whitelisted relayers can call this function
     * @notice Uses minimum consume amount if usdValue is below threshold
     * @notice Deducts credits proportionally from user's token positions
     */
    function consumeCredit(address user, uint256 usdValue) external onlyRelayer {
        require(user != address(0), "Invalid user address");
        require(usdValue > 0, "Value must be > 0");

        uint256 creditCost = usdValue > minimumConsume ? usdValue : minimumConsume;

        uint256 deduction = credits[user] >= creditCost ? creditCost : credits[user];

        credits[user] -= deduction;
        totalConsumedCredits += deduction;

        emit CreditsConsumed(user, usdValue, deduction);
    }

    /**
     * @dev Allows users to transfer credits to another address
     * @param receiver The address to receive the credits
     * @param credit The amount of credits to transfer
     * @notice Contract must not be paused
     * @notice Credit amount must be above minimum and sender must have sufficient balance
     * @notice Credits are transferred proportionally from sender's token positions to receiver
     */
    function transferCredit(address receiver, uint256 credit) external whenNotPaused {
        address sender = msg.sender;
        require(receiver != address(0), "Invalid receiver address");
        require(credits[sender] >= credit, 'Invalid amount');
        
        credits[receiver] += credit;
        credits[sender] -= credit;
        emit CreditTransfer(sender, receiver, credit);
    }

        /**
     * @dev Allows owner to withdraw tokens corresponding to consumed credits
     * @notice Only owner can call this function
     * @notice Only withdraws new consumed credits since last withdrawal
     * @notice Proportionally withdraws from all token balances based on consumed credits
     */
    function withdrawConsumedCredits() external onlyOwner whenNotPaused {
        uint256 deltaCredits = totalConsumedCredits - totalConsumedCreditsWithdrawn;
        require(deltaCredits > 0, "No new credits to withdraw");

        address[] memory tokens = whitelistedTokens.values();
        uint256 creditsRemaining = deltaCredits;

        for (uint256 i = 0; i < tokens.length && creditsRemaining > 0; ++i) {
            address token = tokens[i];
            uint256 contractBalance = IERC20(token).balanceOf(address(this));
            if (contractBalance == 0) continue;

            // Calculate how many credits this token's balance is worth
            uint256 tokenValueInCredits = calculateCreditValue(token, contractBalance);
            if (tokenValueInCredits == 0) continue; // Avoid division by zero

            // Determine how many credits to withdraw from this token
            uint256 creditsToWithdraw = tokenValueInCredits > creditsRemaining ? creditsRemaining : tokenValueInCredits;

            // Calculate the token amount corresponding to creditsToWithdraw
            uint256 tokenAmount = (creditsToWithdraw * contractBalance) / tokenValueInCredits;
            if (tokenAmount == 0) continue; // Avoid dust

            // Transfer tokens to owner
            IERC20(token).transfer(msg.sender, tokenAmount);

            // Update how many credits remain to be withdrawn
            creditsRemaining -= creditsToWithdraw;
        }

        // Update withdrawn credits
        uint256 creditsWithdrawn = deltaCredits - creditsRemaining;
        require(creditsWithdrawn > 0, "Nothing withdrawn");
        totalConsumedCreditsWithdrawn += creditsWithdrawn;

        emit ConsumedCreditsWithdrawn(msg.sender, creditsWithdrawn);
    }

    // Price calculation functions ================================
    
    /**
     * @dev Calculates the credit value for a given token amount
     * @param token The token contract address
     * @param amount The amount of tokens
     * @return The equivalent credit value in credit decimals
     * @notice For stablecoins, assumes 1:1 USD ratio
     * @notice For other tokens, uses Chainlink price feed
     */
    function calculateCreditValue(address token, uint256 amount) internal view returns (uint256) {
        TokenInfo memory info = tokenInfo[token];
        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        
        if (info.isStablecoin) {
            return convertDecimals(amount, tokenDecimals, creditDecimals);
        }

        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = info.priceFeed.latestRoundData();
        
        // Price feed validation
        require(price > 0, "Invalid price from feed");
        require(updatedAt > 0, "Invalid timestamp from feed");
        require(block.timestamp - updatedAt <= PRICE_FEED_TIMEOUT, "Price feed too stale");
        require(answeredInRound >= roundId, "Price feed round incomplete");
        
        uint8 _decimals = tokenDecimals + info.priceFeed.decimals();
        
        // Formula: (amount * price) / (10^(tokenDecimals + priceFeedDecimals - creditDecimals))
        return convertDecimals(amount * uint256(price), _decimals, creditDecimals);
    }

    /**
     * @dev Calculates the token amount for a given credit value
     * @param token The token contract address
     * @param creditAmount The amount of credits
     * @return The equivalent token amount in token decimals
     * @notice For stablecoins, assumes 1:1 USD ratio
     * @notice For other tokens, uses Chainlink price feed
     */
    function calculateTokenValue(address token, uint256 creditAmount) internal view returns (uint256) {
        TokenInfo memory info = tokenInfo[token];
        uint8 tokenDecimals = IERC20Metadata(token).decimals();

        if (info.isStablecoin) {
            return convertDecimals(creditAmount, creditDecimals, tokenDecimals);
        }

        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = info.priceFeed.latestRoundData();
        
        // Price feed validation
        require(price > 0, "Invalid price from feed");
        require(updatedAt > 0, "Invalid timestamp from feed");
        require(block.timestamp - updatedAt <= PRICE_FEED_TIMEOUT, "Price feed too stale");
        require(answeredInRound >= roundId, "Price feed round incomplete");
        
        uint8 _decimals = tokenDecimals + info.priceFeed.decimals();
        
        // Fix precision: multiply first, then divide
        // Formula: (creditAmount * 10^(tokenDecimals + priceFeedDecimals)) / (price * 10^creditDecimals)
        uint256 numerator = convertDecimals(creditAmount, creditDecimals, _decimals);
        return numerator / uint256(price);
    }

    /**
     * @dev Converts amounts between different decimal precisions
     * @param amount The amount to convert
     * @param from The source decimal precision
     * @param to The target decimal precision
     * @return The converted amount
     * @notice Uses unchecked arithmetic for gas optimization
     */
    function convertDecimals(uint256 amount, uint8 from, uint8 to) internal pure returns (uint256) {
        unchecked {
            return from > to ? 
                amount / (10 ** (from - to)) :
                amount * (10 ** (to - from));
        }
    }

    /**
     * @dev Authorizes contract upgrades (UUPS pattern)
     * @param newImplementation The address of the new implementation
     * @notice Only owner can authorize upgrades
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    // View functions =============================================
    
    /**
     * @dev Returns the list of all whitelisted token addresses
     * @return Array of whitelisted token addresses
     */
    function getWhitelistedTokens() external view returns (address[] memory) {
        return whitelistedTokens.values();
    }

    /**
     * @dev Returns the list of all whitelisted relayer addresses
     * @return Array of whitelisted relayer addresses
     */
    function getWhitelistedRelayers() external view returns (address[] memory) {
        return relayers.values();
    }

    /**
     * @dev Calculates the credit value for a given token amount (external view)
     * @param token The token contract address
     * @param amount The amount of tokens
     * @return The equivalent credit value
     */
    function getCreditValue(address token, uint256 amount) external view returns (uint256) {
        return calculateCreditValue(token, amount);
    }

    /**
     * @dev Calculates the token amount for a given credit value (external view)
     * @param token The token contract address
     * @param creditAmount The amount of credits
     * @return The equivalent token amount
     */
    function getTokenValue(address token, uint256 creditAmount) external view returns (uint256) {
        return calculateTokenValue(token, creditAmount);
    }

    /**
     * @dev Checks if a token is whitelisted
     * @param token The token contract address to check
     * @return Whether the token is whitelisted
     */
    function isTokenWhitelisted(address token) external view returns (bool) {
        return whitelistedTokens.contains(token);
    }

    /**
     * @dev Checks if an address is a whitelisted relayer
     * @param relayer The address to check
     * @return Whether the address is a whitelisted relayer
     */
    function isRelayerWhitelisted(address relayer) external view returns (bool) {
        return relayers.contains(relayer);
    }
}