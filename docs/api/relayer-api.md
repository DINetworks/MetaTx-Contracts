## Overview

Complete API documentation for the Meta Transaction Relayer, featuring gas compensation, multi-source price oracle, and comprehensive cost estimation.

## 🚀 Core Features

- **Gas Compensation System**: Configurable multiplier ensures relayer sustainability
- **Multi-Source Price Oracle**: CoinGecko, Chainlink, and CoinMarketCap integration
- **Comprehensive Cost Estimation**: Detailed transaction cost analysis
- **Credit Management**: Token-based gas credit system
- **Multi-Chain Support**: Ethereum, BSC, Polygon, Arbitrum, Optimism, Base, Avalanche

## 📡 API Endpoints

### Meta Transaction API Host
https://relayer.dinetwork.tech

### Meta Transaction Execution

#### Execute Meta-Transaction
```http
POST /api/meta-tx/execute
```

Execute gasless meta-transactions on behalf of users.

**Request Body:**
```json
{
  "chainId": 56,
  "from": "0x742d35Cc6636C0532925a3b8D9C115E2b9e4f",
  "metaTxs": [
    {
      "to": "0xContractAddress1...",
      "value": "0",
      "data": "0x..."
    },
    {
      "to": "0xContractAddress2...",
      "value": "1000000000000000000",
      "data": "0x..."
    }
  ],
  "signature": "0x...",
  "nonce": 123,
  "deadline": 1703097600
}
```

MetaTransaction struct:

```solidity
struct MetaTransaction {
  address to;    // Target contract to call
  uint256 value; // ETH value to send (in wei)
  bytes data;    // Function call data
}

MetaTransaction[] metaTxs;
```

**Response:**
```json
{
  "success": true,
  "data": {
    "txHash": "0x...",
    "batchId": 456,
    "gasCostNative": "3000000000000000",
    "requiredValue": "1000000000000000000",
    "totalNativeCost": "4005000000000000",
    "usdValueConsumed": "7.50",
    "blockNumber": "18500000",
    "blockHash": "0x...",
    "status": "success",
    "timestamp": 1703097500
  }
}
```

#### Estimate Transaction Cost
```js
POST /api/meta-tx/estimate
```

Get comprehensive cost estimation including gas compensation and credit requirements.
**Request Body:**
```json
{
  "chainId": 56,
  "from": "0x742d35Cc6636C0532925a3b8D9C115E2b9e4f",
  "metaTxs": [
    {
      "to": "0xContractAddress1...",
      "value": "0",
      "data": "0x..."
    }
  ],
  "signature": "0x...",
  "nonce": 123,
  "deadline": 1703097600
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "chainId": 56,
    "gasCostNative": "115500000000000",
    "requiredValue": "0",
    "totalNativeCost": "115500000000000",
    "totalUsdCost": "0.345",
    "requiredCredits": "345000000000000000",
    "userCredits": "1000000000000000000",
    "hasEnoughCredits": true,
    "creditDeficit": "0",
    "breakdown": {
      "gasCostUsd": 0.345,
      "requiredValueUsd": 0,
      "totalCostUsd": 0.345
    },
    "timestamp": 1703097500
  }
}
```

**Key Fields:**
- `gasCostNative`: Gas cost with compensation multiplier applied
- `hasEnoughCredits`: Whether user can afford the transaction
- `creditDeficit`: Amount of additional credits needed (if any)
- `breakdown`: Detailed USD cost analysis

#### Get User Nonce
```http
GET /api/meta-tx/nonce/:address
```

Get the current nonce for a user address.

**Response:**
```json
{
  "success": true,
  "data": {
    "address": "0x742d35Cc6636C0532925a3b8D9C115E2b9e4f",
    "nonce": "123",
    "chainId": 56
  }
}
```

#### Get Transaction Status
```http
GET /api/meta-tx/status/:batchId
```

Get status and details of a transaction batch.

**Response:**
```json
{
  "success": true,
  "data": {
    "batchId": 456,
    "user": "0x742d35Cc6636C0532925a3b8D9C115E2b9e4f",
    "relayer": "0x...",
    "gasUsed": "150000",
    "timestamp": "1703097500",
    "successes": [true, true, false],
    "transactionCount": 3
  }
}
```

#### Get Transaction Receipt
```http
GET /api/meta-tx/receipt/:txHash
```

Get detailed transaction receipt information.

**Response:**
```json
{
  "success": true,
  "data": {
    "txHash": "0x...",
    "blockNumber": "18500000",
    "blockHash": "0x...",
    "gasUsed": "150000",
    "status": "success",
    "logs": [...],
    "chainId": 56
  }
}
```

### Credit Management

#### Get User Credits
```http
GET /api/credits/:address
```

Get credit balance for a user address.

**Response:**
```json
{
  "success": true,
  "data": {
    "address": "0x742d35Cc6636C0532925a3b8D9C115E2b9e4f",
    "credits": "1000000000000000000",
    "creditsFormatted": "1.000000",
    "chainId": 56
  }
}
```

#### Calculate Credit Value
```http
POST /api/credits/calculate
```

Calculate credit value for a given token amount.

**Request Body:**
```json
{
  "chainId": 56,
  "token": "0x...",
  "amount": "100"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "0x...",
    "amount": "100",
    "creditValue": "1000000000000000000",
    "creditValueFormatted": "1.000000",
    "chainId": 56
  }
}
```

#### Get Whitelisted Tokens
```http
GET /api/credits/tokens
```

Get list of tokens accepted for credit deposits.

**Response:**
```json
{
  "success": true,
  "data": {
    "tokens": ["0x...", "0x..."],
    "count": 2,
    "chainId": 56
  }
}
```

### Price Oracle & Market Data

#### Get Price Source Status
```http
GET /api/price/status/:chainId
```

Check health and status of all price sources for a specific chain.

**Response:**
```json
{
  "success": true,
  "data": {
    "chainId": 56,
    "tokenId": "binancecoin",
    "tokenSymbol": "BNB",
    "sources": {
      "coingecko": 245.67,
      "chainlink": 245.82,
      "coinmarketcap": 245.45
    },
    "healthMetrics": {
      "totalSources": 3,
      "workingSources": 3,
      "healthPercentage": 100
    }
  }
}
```

**Price Sources:**
- **CoinGecko**: Real-time market data (primary)
- **Chainlink**: On-chain price feeds (decentralized)
- **CoinMarketCap**: Alternative market data (backup)

#### Get Current Token Price
```http
GET /api/price/current/:chainId
```

Get the current token price for a specific chain.

**Response:**
```json
{
  "success": true,
  "data": {
    "chainId": 56,
    "tokenId": "binancecoin",
    "finalPrice": 245.67,
    "priceSourceDetails": {
      "coingecko": 245.67,
      "chainlink": 245.82,
      "coinmarketcap": 245.45
    },
    "timestamp": "2025-08-12T10:30:00.000Z"
  }
}
```

#### Get Multi-Chain Health Overview
```http
GET /api/price/health
```

Get health status for all supported chains.

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "totalChains": 8,
      "operationalChains": 7,
      "healthPercentage": 87.5
    },
    "chains": {
      "1": {
        "tokenSymbol": "ETH",
        "workingSources": 3,
        "healthPercentage": 100,
        "status": "operational"
      },
      "56": {
        "tokenSymbol": "BNB",
        "workingSources": 3,
        "healthPercentage": 100,
        "status": "operational"
      }
    },
    "timestamp": "2025-08-12T10:30:00.000Z"
  }
}
```

#### Clear Price Cache (Admin)
```http
POST /api/price/cache/clear
```

Clear the price cache to force fresh price fetching. Requires admin access.

**Response:**
```json
{
  "success": true,
  "message": "Price cache cleared successfully",
  "timestamp": "2025-08-12T10:30:00.000Z"
}
```

### Utility & System Information

#### Get Current Gas Prices
```http
GET /api/gas-price?chainId=56
```

Get current gas price for a specific chain.

**Response:**
```json
{
  "success": true,
  "data": {
    "chainId": 56,
    "chainName": "BSC",
    "gasPrice": "5000000000",
    "gasPriceGwei": "5.0",
    "timestamp": 1703097500
  }
}
```

#### Get Supported Chains
```http
GET /api/chains
```

Get list of all supported blockchain networks.

**Response:**
```json
{
  "success": true,
  "data": {
    "chains": [
      {
        "chainId": 1,
        "name": "Ethereum",
        "nativeCurrency": "ETH",
        "testnet": false
      },
      {
        "chainId": 56,
        "name": "BSC",
        "nativeCurrency": "BNB", 
        "testnet": false
      }
    ],
    "count": 8
  }
}
```

#### Calculate Transaction Fee
```http
POST /api/calculate-fee
```

Calculate transaction fees in USD for given gas parameters.

**Request Body:**
```json
{
  "chainId": 56,
  "gasUsed": 21000
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "chainId": 56,
    "gasUsed": 21000,
    "gasPrice": "5000000000",
    "fee": "105000000000000",
    "feeInEth": "0.000105",
    "feeInUsd": 0.25,
    "timestamp": 1703097500
  }
}
```

#### Detailed Health Check
```http
GET /api/health-detailed
```

Get comprehensive system health and status information.

**Response:**
```json
{
  "success": true,
  "data": {
    "service": "Meta Transaction Relayer API",
    "version": "1.0.0",
    "timestamp": "2025-08-12T10:30:00.000Z",
    "uptime": 3600,
    "environment": "production",
    "network": {
      "chainId": 56,
      "name": "BSC",
      "rpcStatus": "connected"
    },
    "relayer": {
      "address": "0x...",
      "status": "active"
    },
    "contracts": {
      "metaTxGateway": {
        "address": "0x...",
        "status": "configured"
      },
      "gasCreditVault": {
        "address": "0x...",
        "status": "configured"
      }
    }
  }
}
```

## 💰 Gas Compensation System

### How It Works

The gas compensation system ensures relayer sustainability by applying a configurable multiplier to gas costs:

1. **Base Calculation**: `estimatedGas × currentGasPrice`
2. **Apply Multiplier**: `baseCost × gasCompensationMultiplier` 
3. **Result**: Compensated gas cost ensuring profitability

### Configuration

```env
# Default 10% markup for relayer compensation
GAS_COMPENSATION_MULTIPLIER=1.2

# Examples:
# GAS_COMPENSATION_MULTIPLIER=1.05  # 5% markup
# GAS_COMPENSATION_MULTIPLIER=1.25  # 15% markup
```

### Benefits

- **Sustainable Operations**: Ensures relayer profitability
- **Covers Operational Costs**: Infrastructure and maintenance
- **Market Responsive**: Adjustable based on conditions
- **Transparent**: Clear compensation methodology

## 🔍 Multi-Source Price Oracle

### Price Source Priority

1. **CoinGecko API** - Real-time market data (primary)
2. **Chainlink Price Feeds** - On-chain, decentralized
3. **CoinMarketCap API** - Alternative market data (backup)
4. **Hardcoded Fallback** - Emergency values

### Supported Tokens

| Chain | Token | CoinGecko ID | Fallback Price |
|-------|-------|--------------|----------------|
| Ethereum | ETH | ethereum | $2,500 |
| BSC | BNB | binancecoin | $300 |
| Polygon | MATIC | matic-network | $0.80 |
| Avalanche | AVAX | avalanche-2 | $25 |

### Error Handling

- **Automatic Fallback**: Tries next source if one fails
- **Caching**: 1-minute cache for reliability
- **Rate Limiting**: Prevents API quota exhaustion
- **Graceful Degradation**: Always provides a price

## 🧪 Testing

### Test Commands

```bash
# Run all tests
npm test

# Specific test suites
npm run test:unit      # Unit tests
npm run test:api       # API integration tests  
npm run test:meta-tx   # Meta-transaction tests
npm run test:price     # Price oracle tests
```

### Test Coverage

- ✅ Gas compensation calculations
- ✅ Multi-source price fetching
- ✅ Credit management
- ✅ API endpoint validation
- ✅ Error handling scenarios
- ✅ Configuration management

## 🔧 Configuration

### Required Environment Variables

```env
# Network Configuration
CHAIN_ID=56
RPC_URL=https://bsc-dataseed.binance.org/
CHAIN_NAME=BSC

# Relayer Configuration  
RELAYER_PRIVATE_KEY=0x...
RELAYER_ADDRESS=0x...

# Contract Addresses
METATX_GATEWAY_ADDRESS=0x...
GAS_CREDIT_VAULT_ADDRESS=0x...

# Gas Compensation
GAS_COMPENSATION_MULTIPLIER=1.2

# Optional Configuration
PORT=3000
NODE_ENV=production
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
RELAYER_API_KEY=your-secret-key
```

### Optional API Keys

```env
# For higher rate limits
COINMARKETCAP_API_KEY=your-api-key
```

## 📊 Response Format

All API responses follow this standardized format:

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human readable error message",
  "details": [] // Optional validation details
}
```

### Common Error Codes

- `UNSUPPORTED_CHAIN` - Chain ID not supported
- `VALIDATION_ERROR` - Invalid request parameters
- `INSUFFICIENT_CREDITS` - User has insufficient credits
- `EXECUTION_FAILED` - Transaction execution failed
- `PRICE_FETCH_FAILED` - Unable to fetch current prices
- `NETWORK_ERROR` - RPC or network connectivity issues