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
    event SaleWindowUpdated(uint256, uint256);

    struct PaymentToken {
        address token;
        address priceFeed; // Chainlink USD price feed
        uint8 decimals;
        bool isStable;
        bool isAllowed;
    }

    mapping(address => PaymentToken) public paymentTokens;

    event Purchased(address indexed buyer, address indexed payToken, uint256 payAmount, uint256 tokenAmount);

    constructor(address _saleToken, uint256 _totalForSale, address _owner) Ownable(_owner) {
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
    }

    function getTokenPriceInUSD(address token) public view returns (uint256) {
        require(paymentTokens[token].isAllowed, "Token not allowed");
        if (paymentTokens[token].isStable) {
            return 1e8;
        }
        
        (, int256 price,,,) = AggregatorV3Interface(paymentTokens[token].priceFeed).latestRoundData();
        require(price > 0, "Invalid price");
        
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

    function buyTokens(address payToken, uint256 amountIn) external nonReentrant saleActive {
        require(paymentTokens[payToken].isAllowed, "Unsupported payment token");
        require(amountIn > 0, "Invalid amount");

        uint256 tokenAmount = calculateTokenAmount(payToken, amountIn);

        // Transfer stable token to contract
        IERC20(payToken).transferFrom(msg.sender, address(this), amountIn);

        // Transfer sale tokens to buyer
        saleToken.transfer(msg.sender, tokenAmount);
        tokensSold += tokenAmount;

        emit Purchased(msg.sender, payToken, amountIn, tokenAmount);
    }

    function buyTokens() public payable nonReentrant saleActive {
        require(msg.value > 0, "Invalid amount");

        uint256 tokenAmount = calculateTokenAmount(address(0), msg.value);

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

    function remainingTokens() external view returns (uint256) {
        return totalTokensForSale - tokensSold;
    }

    receive() external payable {
        buyTokens();
    } 
}