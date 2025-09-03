// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80, int256 answer, uint256, uint256, uint80);
}

contract TokenPresale is Ownable, ReentrancyGuard {
    IERC20 public immutable saleToken;
    uint256 public immutable totalTokensForSale;
    uint256 public tokensSold;
    uint256 constant baseRatePerUSD = 20; // 20 sale tokens per $1
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    // Maximum allowed age (in seconds) for oracle price data
    uint256 public maxPriceAge = 1 hours;
    
    event MaxPriceAgeUpdated(uint256);

    event SaleWindowUpdated(uint256, uint256);

    event PaymentTokenAdded(address token, address priceFeed, uint8 decimals, bool isStable);

    struct PaymentToken {
        address token;
        address priceFeed; // Chainlink USD price feed
        uint8 decimals;
        bool isStable;
        bool isAllowed;
    }

    mapping(address => PaymentToken) public paymentTokens;

    event Purchased(address indexed buyer, address indexed payToken, uint256 payAmount, uint256 tokenAmount);

    constructor(address _saleToken, uint256 _totalForSale, address owner_) Ownable(owner_) {
        saleToken = IERC20(_saleToken);
        totalTokensForSale = _totalForSale;
    }

    modifier saleActive() {
        require(block.timestamp >= startTimestamp, "Sale not started");
        require(block.timestamp <= endTimestamp, "Sale ended");
        _;
    }

    modifier saleOngoing() {
        require(endTimestamp == 0 || block.timestamp < endTimestamp, "Sale ended");
        _;
    }

    function setSaleWindow(uint256 _start, uint256 _end) external onlyOwner saleOngoing {
        require(_start < _end, "Invalid time range");
        startTimestamp = _start;
        endTimestamp = _end;
        emit SaleWindowUpdated(_start, _end);
    }    

    function setMaxPriceAge(uint256 _seconds) external onlyOwner {
        require(_seconds > 0, "Invalid age");
        maxPriceAge = _seconds;
        emit MaxPriceAgeUpdated(_seconds);
    }

    function addPaymentToken(
        address token,
        address priceFeed,
        uint8 decimals,
        bool isStable
    ) external onlyOwner {
        paymentTokens[token] = PaymentToken({
            token: token,
            priceFeed: priceFeed,
            decimals: decimals,
            isStable: isStable,
            isAllowed: true
        });
        emit PaymentTokenAdded(token, priceFeed, decimals, isStable);
    }

    function getTokenPriceInUSD(address token) public view returns (uint256) {
        require(paymentTokens[token].isAllowed, "Token not allowed");
        if (paymentTokens[token].isStable) {
            return 1e8;
        }
        address feed = paymentTokens[token].priceFeed;
        require(feed != address(0), "Missing price feed");

        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) =
            AggregatorV3Interface(feed).latestRoundData();

        require(price > 0, "Invalid price");
        require(updatedAt != 0, "Round not complete");
        // answeredInRound must be >= roundId to ensure the answer is for this round
        require(answeredInRound >= roundId, "Stale answeredInRound");
        // timestamp sanity checks
        require(updatedAt <= block.timestamp, "Oracle timestamp in future");
        require(block.timestamp - updatedAt <= maxPriceAge, "Price too old");

        return uint256(price); // 8 decimals typically
    }

    // Power curve rate: rate = 1 + 1.25 * (1 - x^2)
    function getDynamicRate() public view returns (uint256) {
        uint256 remaining = totalTokensForSale - tokensSold;
        uint256 remainingInBps =  remaining * 1e18 / totalTokensForSale;

        uint256 squared = (remainingInBps * remainingInBps) / 1e18;
        uint256 factor = 1e18 + 2e18 * (1e18 - squared) / 1e18;

        return factor / baseRatePerUSD;
    }

    function convertDecimals(uint256 amount, uint8 from, uint8 to) internal pure returns (uint256) {
        unchecked {
            return from > to ? 
                amount / (10 ** (from - to)) :
                amount * (10 ** (to - from));
        }
    }

    function calculateTokenAmount(address payToken, uint256 amountIn) public view returns (uint256 tokenAmount) {
        require(paymentTokens[payToken].isAllowed, "Token not allowed");
        PaymentToken memory info = paymentTokens[payToken];
        uint256 tokenUSDPrice = getTokenPriceInUSD(payToken);
        uint256 dynamicRate = getDynamicRate();

        tokenAmount = (convertDecimals(amountIn, info.decimals, 18) * tokenUSDPrice * 1e18) / (dynamicRate * 1e8); // Normalize decimals
        require(tokensSold + tokenAmount <= totalTokensForSale, "Exceeds sale supply");
    }

    function buyTokens(address payToken, uint256 amountIn, uint256 minTokensOut) external nonReentrant saleActive {
        require(paymentTokens[payToken].isAllowed, "Unsupported payment token");
        require(amountIn > 0, "Invalid amount");

        uint256 tokenAmount = calculateTokenAmount(payToken, amountIn);
        require(tokenAmount >= minTokensOut, "Insufficient output amount");

        // Transfer stable token to contract
        IERC20(payToken).transferFrom(msg.sender, address(this), amountIn);

        // Transfer sale tokens to buyer
        saleToken.transfer(msg.sender, tokenAmount);
        tokensSold += tokenAmount;

        emit Purchased(msg.sender, payToken, amountIn, tokenAmount);
    }

    function buyTokens(uint256 minTokensOut) public payable nonReentrant saleActive {
        // Delegate core ETH purchase logic to internal helper
        _buyWithETH(minTokensOut);
    }
    
    // Internal helper to handle ETH purchases (used by public buyTokens and fallback)
    function _buyWithETH(uint256 minTokensOut) internal {
        require(msg.value > 0, "Invalid amount");

        uint256 tokenAmount = calculateTokenAmount(address(0), msg.value);
        require(tokenAmount >= minTokensOut, "Insufficient output amount");

        // Transfer sale tokens to buyer
        saleToken.transfer(msg.sender, tokenAmount);
        tokensSold += tokenAmount;

        emit Purchased(msg.sender, address(0), msg.value, tokenAmount);
    }

    function withdraw(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "Nothing to withdraw");
        IERC20(token).transfer(to, bal);
    }

    function withdrawETH(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "Nothing to withdraw");
        to.transfer(bal);
    }

    function remainingTokens() external view returns (uint256) {
        return totalTokensForSale - tokensSold;
    }
    
    // Fallback accepts calldata-encoded uint256(minTokensOut) and processes purchase
    fallback() external payable nonReentrant saleActive {
        // Expect ABI-encoded uint256(minTokensOut) in calldata
        require(msg.data.length == 32, "Missing minTokensOut");
        uint256 minTokensOut = abi.decode(msg.data, (uint256));
        _buyWithETH(minTokensOut);
    }

    // Prevent plain ETH transfers without calldata to avoid accidental loss of funds
    receive() external payable {
        revert("Provide minTokensOut in calldata (use fallback)");
    }
}