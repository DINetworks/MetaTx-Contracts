# Security Best Practices

Comprehensive security guidelines for developing and deploying MetaTx-Contracts.

## Overview

Security is paramount when dealing with meta-transactions and gas credit systems. This guide covers best practices for smart contract development, deployment, integration, and ongoing maintenance.

## Smart Contract Security

### Access Control

#### Implement Proper Role Management

```solidity
// Use OpenZeppelin's AccessControl for granular permissions
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SecureMetaTxGateway is AccessControl {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    modifier onlyRelayer() {
        require(hasRole(RELAYER_ROLE, msg.sender), "Not authorized relayer");
        _;
    }
    
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized admin");
        _;
    }
    
    function addRelayer(address relayer) external onlyAdmin {
        grantRole(RELAYER_ROLE, relayer);
    }
}
```

#### Multi-Signature for Critical Operations

```solidity
// Use Gnosis Safe or similar for admin operations
contract MultiSigGateway {
    address public multiSigWallet;
    
    modifier onlyMultiSig() {
        require(msg.sender == multiSigWallet, "Only multisig allowed");
        _;
    }
    
    function upgradeContract(address newImplementation) external onlyMultiSig {
        _upgradeTo(newImplementation);
    }
}
```

### Input Validation

#### Comprehensive Parameter Validation

```solidity
contract ValidatedGateway {
    uint256 public constant MAX_DEADLINE = 1 hours;
    uint256 public constant MAX_BATCH_SIZE = 10;
    
    function executeMetaTransactions(
        MetaTransaction[] calldata transactions
    ) external payable {
        require(transactions.length > 0, "Empty transaction batch");
        require(transactions.length <= MAX_BATCH_SIZE, "Batch too large");
        
        for (uint256 i = 0; i < transactions.length; i++) {
            validateTransaction(transactions[i]);
        }
        
        // Continue with execution...
    }
    
    function validateTransaction(MetaTransaction calldata transaction) internal view {
        require(transaction.to != address(0), "Invalid target address");
        require(transaction.deadline > block.timestamp, "Transaction expired");
        require(
            transaction.deadline <= block.timestamp + MAX_DEADLINE,
            "Deadline too far in future"
        );
        require(transaction.signature.length == 65, "Invalid signature length");
    }
}
```

#### Address Validation

```solidity
function isValidAddress(address addr) internal pure returns (bool) {
    return addr != address(0) && addr != address(this);
}

function validateAddresses(MetaTransaction calldata transaction) internal view {
    require(isValidAddress(transaction.to), "Invalid target");
    require(transaction.to != address(this), "Cannot target self");
}
```

### Signature Security

#### Robust EIP-712 Implementation

```solidity
contract SecureSignatures {
    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public executedTransactions;
    
    function verifySignature(
        MetaTransaction calldata transaction,
        address expectedSigner
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                METATRANSACTION_TYPEHASH,
                transaction.to,
                transaction.value,
                keccak256(transaction.data),
                transaction.nonce,
                transaction.deadline
            ))
        );
        
        address recovered = ECDSA.recover(digest, transaction.signature);
        return recovered == expectedSigner;
    }
    
    function preventReplay(MetaTransaction calldata transaction) internal {
        bytes32 txHash = keccak256(abi.encode(transaction));
        require(!executedTransactions[txHash], "Transaction already executed");
        executedTransactions[txHash] = true;
    }
}
```

#### Nonce Management

```solidity
contract SecureNonces {
    mapping(address => uint256) private _nonces;
    
    function getNonce(address user) external view returns (uint256) {
        return _nonces[user];
    }
    
    function _incrementNonce(address user) internal {
        _nonces[user] = _nonces[user] + 1;
    }
    
    function validateNonce(address user, uint256 nonce) internal view {
        require(nonce == _nonces[user], "Invalid nonce");
    }
}
```

### Reentrancy Protection

#### Comprehensive Guards

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ReentrancyProtectedGateway is ReentrancyGuard {
    function executeMetaTransactions(
        MetaTransaction[] calldata transactions
    ) external payable nonReentrant {
        // Implementation with reentrancy protection
        for (uint256 i = 0; i < transactions.length; i++) {
            _executeTransaction(transactions[i]);
        }
    }
    
    function _executeTransaction(MetaTransaction calldata transaction) internal {
        // Use low-level call with reentrancy checks
        (bool success, bytes memory returnData) = transaction.to.call{
            value: transaction.value
        }(transaction.data);
        
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}
```

### Gas Safety

#### Gas Limit Management

```solidity
contract GasSecureGateway {
    uint256 public constant MAX_GAS_PER_TRANSACTION = 500000;
    uint256 public constant MAX_TOTAL_GAS = 5000000;
    
    function executeWithGasLimits(
        MetaTransaction[] calldata transactions
    ) external payable {
        uint256 totalGasUsed = 0;
        
        for (uint256 i = 0; i < transactions.length; i++) {
            uint256 gasStart = gasleft();
            
            // Execute with gas limit
            bool success = this.executeTransactionWithLimit{
                gas: MAX_GAS_PER_TRANSACTION
            }(transactions[i]);
            
            uint256 gasUsed = gasStart - gasleft();
            totalGasUsed += gasUsed;
            
            require(totalGasUsed <= MAX_TOTAL_GAS, "Total gas limit exceeded");
            require(success, "Transaction failed");
        }
    }
}
```

## Price Oracle Security

### Chainlink Integration Best Practices

#### Secure Price Feed Usage

```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SecurePriceFeeds {
    uint256 public constant PRICE_STALENESS_THRESHOLD = 3600; // 1 hour
    uint256 public constant PRICE_DEVIATION_THRESHOLD = 500; // 5%
    
    mapping(address => AggregatorV3Interface) public priceFeeds;
    mapping(address => uint256) public lastValidPrices;
    
    function getSecurePrice(address token) external view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[token];
        require(address(priceFeed) != address(0), "Price feed not set");
        
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        // Validate price data
        validatePriceData(price, updatedAt, roundId, answeredInRound);
        
        // Check for significant price deviation
        validatePriceDeviation(token, uint256(price));
        
        return uint256(price);
    }
    
    function validatePriceData(
        int256 price,
        uint256 updatedAt,
        uint80 roundId,
        uint80 answeredInRound
    ) internal view {
        require(price > 0, "Invalid price");
        require(updatedAt > 0, "Invalid timestamp");
        require(roundId > 0, "Invalid round ID");
        require(answeredInRound >= roundId, "Stale price");
        require(
            block.timestamp - updatedAt <= PRICE_STALENESS_THRESHOLD,
            "Price too stale"
        );
    }
    
    function validatePriceDeviation(address token, uint256 newPrice) internal view {
        uint256 lastPrice = lastValidPrices[token];
        if (lastPrice > 0) {
            uint256 deviation = newPrice > lastPrice
                ? ((newPrice - lastPrice) * 10000) / lastPrice
                : ((lastPrice - newPrice) * 10000) / lastPrice;
            
            require(
                deviation <= PRICE_DEVIATION_THRESHOLD,
                "Price deviation too large"
            );
        }
    }
}
```

#### Circuit Breaker Pattern

```solidity
contract CircuitBreaker {
    bool public emergencyPaused = false;
    uint256 public pausedUntil = 0;
    
    modifier notPaused() {
        require(!emergencyPaused, "Contract paused");
        require(block.timestamp > pausedUntil, "Contract temporarily paused");
        _;
    }
    
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPause(block.timestamp);
    }
    
    function temporaryPause(uint256 duration) external onlyOwner {
        pausedUntil = block.timestamp + duration;
        emit TemporaryPause(block.timestamp + duration);
    }
}
```

## Frontend Security

### Signature Validation

#### Client-Side Verification

```javascript
class SignatureValidator {
  constructor(domain, types) {
    this.domain = domain;
    this.types = types;
  }

  validateBeforeSigning(transaction) {
    // Validate addresses
    if (!ethers.isAddress(transaction.to)) {
      throw new Error('Invalid target address');
    }

    // Validate amounts
    if (transaction.value < 0) {
      throw new Error('Invalid value amount');
    }

    // Validate deadline
    const now = Math.floor(Date.now() / 1000);
    if (transaction.deadline <= now) {
      throw new Error('Transaction deadline in the past');
    }

    if (transaction.deadline > now + 3600) { // 1 hour max
      throw new Error('Deadline too far in future');
    }

    // Validate data format
    if (!transaction.data.startsWith('0x')) {
      throw new Error('Invalid data format');
    }
  }

  async verifySignature(transaction, signature, expectedSigner) {
    try {
      const recoveredAddress = ethers.verifyTypedData(
        this.domain,
        this.types,
        transaction,
        signature
      );

      return recoveredAddress.toLowerCase() === expectedSigner.toLowerCase();
    } catch (error) {
      console.error('Signature verification failed:', error);
      return false;
    }
  }

  sanitizeTransactionData(transaction) {
    return {
      to: transaction.to.toLowerCase(),
      value: BigInt(transaction.value).toString(),
      data: transaction.data.toLowerCase(),
      nonce: BigInt(transaction.nonce).toString(),
      deadline: BigInt(transaction.deadline).toString()
    };
  }
}
```

### Secure Storage

#### Private Key Management

```javascript
class SecureKeyManager {
  constructor() {
    this.encryptionKey = null;
  }

  // Never store private keys in localStorage or sessionStorage
  async getPrivateKey() {
    // Use secure methods like MetaMask or hardware wallets
    throw new Error('Use external wallet for key management');
  }

  // For development only - use environment variables
  getDevPrivateKey() {
    if (process.env.NODE_ENV !== 'development') {
      throw new Error('Development keys only in dev environment');
    }
    return process.env.PRIVATE_KEY;
  }

  // Secure session management
  async createSecureSession(duration = 3600) {
    const sessionToken = crypto.randomUUID();
    const expiryTime = Date.now() + (duration * 1000);
    
    // Store in secure, httpOnly cookie
    document.cookie = `session=${sessionToken}; Secure; HttpOnly; SameSite=Strict; Max-Age=${duration}`;
    
    return { sessionToken, expiryTime };
  }
}
```

### Input Sanitization

#### Comprehensive Input Validation

```javascript
class InputSanitizer {
  static sanitizeAddress(address) {
    if (!address || typeof address !== 'string') {
      throw new Error('Invalid address format');
    }

    const cleaned = address.trim().toLowerCase();
    
    if (!ethers.isAddress(cleaned)) {
      throw new Error('Invalid Ethereum address');
    }

    return cleaned;
  }

  static sanitizeAmount(amount) {
    if (amount === null || amount === undefined) {
      throw new Error('Amount is required');
    }

    const cleaned = amount.toString().trim();
    
    try {
      const bigIntAmount = BigInt(cleaned);
      if (bigIntAmount < 0n) {
        throw new Error('Amount cannot be negative');
      }
      return bigIntAmount;
    } catch (error) {
      throw new Error('Invalid amount format');
    }
  }

  static sanitizeCalldata(data) {
    if (!data) return '0x';
    
    const cleaned = data.trim();
    
    if (!cleaned.startsWith('0x')) {
      throw new Error('Calldata must start with 0x');
    }

    if (cleaned.length % 2 !== 0) {
      throw new Error('Calldata must have even length');
    }

    if (!/^0x[0-9a-fA-F]*$/.test(cleaned)) {
      throw new Error('Calldata contains invalid characters');
    }

    return cleaned.toLowerCase();
  }

  static sanitizeDeadline(deadline) {
    const now = Math.floor(Date.now() / 1000);
    const deadlineNum = Number(deadline);
    
    if (!Number.isInteger(deadlineNum) || deadlineNum <= 0) {
      throw new Error('Invalid deadline format');
    }

    if (deadlineNum <= now) {
      throw new Error('Deadline must be in the future');
    }

    if (deadlineNum > now + 3600) { // Max 1 hour
      throw new Error('Deadline too far in future');
    }

    return deadlineNum;
  }
}
```

## Relayer Security

### Authentication and Authorization

#### API Key Management

```javascript
class RelayerSecurity {
  constructor(config) {
    this.apiKeys = new Map();
    this.rateLimits = new Map();
    this.config = config;
  }

  generateApiKey(userId) {
    const apiKey = crypto.randomBytes(32).toString('hex');
    const hashedKey = crypto.createHash('sha256').update(apiKey).digest('hex');
    
    this.apiKeys.set(hashedKey, {
      userId,
      createdAt: Date.now(),
      lastUsed: null,
      permissions: ['submit_transactions']
    });

    return apiKey;
  }

  validateApiKey(apiKey) {
    const hashedKey = crypto.createHash('sha256').update(apiKey).digest('hex');
    const keyData = this.apiKeys.get(hashedKey);
    
    if (!keyData) {
      throw new Error('Invalid API key');
    }

    // Update last used timestamp
    keyData.lastUsed = Date.now();
    
    return keyData;
  }

  checkRateLimit(userId) {
    const now = Date.now();
    const windowMs = 60000; // 1 minute
    const maxRequests = 60;
    
    if (!this.rateLimits.has(userId)) {
      this.rateLimits.set(userId, { count: 0, resetTime: now + windowMs });
    }
    
    const userLimit = this.rateLimits.get(userId);
    
    if (now > userLimit.resetTime) {
      userLimit.count = 0;
      userLimit.resetTime = now + windowMs;
    }
    
    if (userLimit.count >= maxRequests) {
      throw new Error('Rate limit exceeded');
    }
    
    userLimit.count++;
  }
}
```

### Transaction Validation

#### Server-Side Verification

```javascript
class RelayerValidator {
  constructor(gateway, vault) {
    this.gateway = gateway;
    this.vault = vault;
  }

  async validateMetaTransaction(transaction, expectedSigner) {
    // Validate signature
    await this.validateSignature(transaction, expectedSigner);
    
    // Validate nonce
    await this.validateNonce(transaction.nonce, expectedSigner);
    
    // Validate deadline
    this.validateDeadline(transaction.deadline);
    
    // Validate gas credits
    await this.validateGasCredits(transaction, expectedSigner);
    
    // Validate target contract
    await this.validateTarget(transaction);
  }

  async validateSignature(transaction, expectedSigner) {
    const domain = await this.getDomainSeparator();
    const types = this.getTypeDefinition();
    
    const recoveredAddress = ethers.verifyTypedData(
      domain,
      types,
      {
        to: transaction.to,
        value: transaction.value.toString(),
        data: transaction.data,
        nonce: transaction.nonce.toString(),
        deadline: transaction.deadline.toString()
      },
      transaction.signature
    );

    if (recoveredAddress.toLowerCase() !== expectedSigner.toLowerCase()) {
      throw new Error('Invalid signature');
    }
  }

  async validateNonce(nonce, user) {
    const currentNonce = await this.gateway.getNonce(user);
    if (BigInt(nonce) !== currentNonce) {
      throw new Error(`Invalid nonce. Expected: ${currentNonce}, Got: ${nonce}`);
    }
  }

  validateDeadline(deadline) {
    const now = Math.floor(Date.now() / 1000);
    if (Number(deadline) <= now) {
      throw new Error('Transaction deadline has passed');
    }
  }

  async validateGasCredits(transaction, user) {
    const creditBalance = await this.vault.getCreditBalance(user);
    const estimatedGas = await this.estimateGas(transaction);
    const gasPrice = await this.gateway.provider.getGasPrice();
    const requiredCredits = estimatedGas * gasPrice;

    if (creditBalance < requiredCredits) {
      throw new Error('Insufficient gas credits');
    }
  }

  async validateTarget(transaction) {
    // Check if target is a contract
    const code = await this.gateway.provider.getCode(transaction.to);
    
    if (code === '0x' && transaction.data !== '0x') {
      throw new Error('Cannot send data to EOA');
    }

    // Blacklist check
    if (this.isBlacklisted(transaction.to)) {
      throw new Error('Target address is blacklisted');
    }
  }

  isBlacklisted(address) {
    const blacklist = [
      // Add known malicious addresses
    ];
    return blacklist.includes(address.toLowerCase());
  }
}
```

## Monitoring and Alerting

### Real-Time Monitoring

#### Security Event Detection

```javascript
class SecurityMonitor {
  constructor(contracts, alertChannels) {
    this.contracts = contracts;
    this.alertChannels = alertChannels;
    this.thresholds = {
      largeTransaction: ethers.parseEther('10'), // 10 ETH
      suspiciousGas: 1000000, // 1M gas
      rapidTransactions: 100, // 100 tx per minute
      priceDeviation: 1000 // 10%
    };
  }

  async startMonitoring() {
    // Monitor large transactions
    this.contracts.gateway.on('MetaTransactionExecuted', async (user, to, success, returnData, event) => {
      const tx = await event.getTransaction();
      
      if (tx.value > this.thresholds.largeTransaction) {
        await this.alert('LARGE_TRANSACTION', {
          user,
          amount: ethers.formatEther(tx.value),
          txHash: tx.hash
        });
      }
    });

    // Monitor failed transactions
    this.contracts.gateway.on('MetaTransactionExecuted', async (user, to, success, returnData, event) => {
      if (!success) {
        await this.alert('TRANSACTION_FAILED', {
          user,
          target: to,
          txHash: event.transactionHash,
          returnData
        });
      }
    });

    // Monitor gas usage
    this.contracts.gateway.on('MetaTransactionExecuted', async (user, to, success, returnData, event) => {
      const receipt = await event.getTransactionReceipt();
      
      if (receipt.gasUsed > this.thresholds.suspiciousGas) {
        await this.alert('HIGH_GAS_USAGE', {
          user,
          gasUsed: receipt.gasUsed.toString(),
          txHash: receipt.transactionHash
        });
      }
    });

    // Monitor rapid transaction patterns
    this.monitorTransactionRate();
  }

  async alert(type, data) {
    const alertMessage = {
      type,
      timestamp: new Date().toISOString(),
      data,
      severity: this.getSeverity(type)
    };

    console.error(`Security Alert [${type}]:`, alertMessage);

    // Send to alert channels
    for (const channel of this.alertChannels) {
      try {
        await channel.send(alertMessage);
      } catch (error) {
        console.error('Failed to send alert:', error);
      }
    }
  }

  getSeverity(type) {
    const severityMap = {
      'LARGE_TRANSACTION': 'medium',
      'TRANSACTION_FAILED': 'low',
      'HIGH_GAS_USAGE': 'medium',
      'RAPID_TRANSACTIONS': 'high',
      'PRICE_MANIPULATION': 'critical'
    };
    return severityMap[type] || 'low';
  }

  async monitorTransactionRate() {
    const userTransactionCounts = new Map();
    const timeWindow = 60000; // 1 minute

    setInterval(() => {
      for (const [user, data] of userTransactionCounts) {
        if (data.count > this.thresholds.rapidTransactions) {
          this.alert('RAPID_TRANSACTIONS', {
            user,
            count: data.count,
            timeWindow: '1 minute'
          });
        }
      }
      userTransactionCounts.clear();
    }, timeWindow);

    this.contracts.gateway.on('MetaTransactionExecuted', (user) => {
      const userData = userTransactionCounts.get(user) || { count: 0 };
      userData.count++;
      userTransactionCounts.set(user, userData);
    });
  }
}
```

### Audit Logging

#### Comprehensive Logging

```javascript
class AuditLogger {
  constructor(logDestinations) {
    this.destinations = logDestinations;
  }

  async logTransaction(event, transaction, result) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      event,
      transaction: {
        user: transaction.user,
        to: transaction.to,
        value: transaction.value.toString(),
        nonce: transaction.nonce.toString(),
        deadline: transaction.deadline.toString(),
        hash: result.hash
      },
      result: {
        success: result.success,
        gasUsed: result.gasUsed?.toString(),
        blockNumber: result.blockNumber
      },
      metadata: {
        relayer: transaction.relayer,
        userAgent: transaction.userAgent,
        ipAddress: this.hashIP(transaction.ipAddress)
      }
    };

    await this.writeLog(logEntry);
  }

  async logSecurityEvent(event, details) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      type: 'SECURITY_EVENT',
      event,
      details,
      severity: details.severity || 'medium'
    };

    await this.writeLog(logEntry);
  }

  async writeLog(entry) {
    for (const destination of this.destinations) {
      try {
        await destination.write(entry);
      } catch (error) {
        console.error('Failed to write log:', error);
      }
    }
  }

  hashIP(ipAddress) {
    // Hash IP for privacy while maintaining audit trail
    return crypto.createHash('sha256').update(ipAddress).digest('hex').substring(0, 16);
  }
}
```

## Incident Response

### Emergency Procedures

#### Contract Pause Protocol

```solidity
contract EmergencyControls {
    bool public emergencyPaused = false;
    address public emergencyOperator;
    uint256 public pauseStartTime;
    uint256 public constant MAX_PAUSE_DURATION = 7 days;
    
    event EmergencyPause(address operator, uint256 timestamp);
    event EmergencyUnpause(address operator, uint256 timestamp);
    
    modifier notInEmergency() {
        require(!emergencyPaused, "Contract paused for emergency");
        _;
    }
    
    modifier onlyEmergencyOperator() {
        require(msg.sender == emergencyOperator, "Not emergency operator");
        _;
    }
    
    function emergencyPause() external onlyEmergencyOperator {
        emergencyPaused = true;
        pauseStartTime = block.timestamp;
        emit EmergencyPause(msg.sender, block.timestamp);
    }
    
    function emergencyUnpause() external onlyEmergencyOperator {
        emergencyPaused = false;
        pauseStartTime = 0;
        emit EmergencyUnpause(msg.sender, block.timestamp);
    }
    
    // Automatic unpause after maximum duration
    function autounpause() external {
        require(emergencyPaused, "Not paused");
        require(
            block.timestamp > pauseStartTime + MAX_PAUSE_DURATION,
            "Max pause duration not reached"
        );
        
        emergencyPaused = false;
        pauseStartTime = 0;
        emit EmergencyUnpause(address(0), block.timestamp);
    }
}
```

#### Recovery Procedures

```javascript
class IncidentResponse {
  constructor(contracts, communications) {
    this.contracts = contracts;
    this.communications = communications;
    this.procedures = new Map();
    this.setupProcedures();
  }

  setupProcedures() {
    this.procedures.set('PRICE_MANIPULATION', async () => {
      // 1. Pause price-sensitive operations
      await this.contracts.vault.pause();
      
      // 2. Notify stakeholders
      await this.communications.broadcast('Price manipulation detected. System paused.');
      
      // 3. Investigate price feeds
      const priceData = await this.auditPriceFeeds();
      
      // 4. Document incident
      await this.documentIncident('PRICE_MANIPULATION', priceData);
    });

    this.procedures.set('LARGE_DRAIN', async () => {
      // 1. Emergency pause
      await this.contracts.gateway.emergencyPause();
      
      // 2. Alert authorities
      await this.communications.alertAuthorities('Large fund drainage detected');
      
      // 3. Forensic analysis
      const analysis = await this.conductForensics();
      
      // 4. Prepare recovery plan
      await this.prepareRecoveryPlan(analysis);
    });
  }

  async respondToIncident(incidentType, data) {
    console.log(`Responding to incident: ${incidentType}`);
    
    const procedure = this.procedures.get(incidentType);
    if (procedure) {
      await procedure();
    } else {
      await this.genericResponse(incidentType, data);
    }
  }

  async auditPriceFeeds() {
    const results = {};
    const tokens = ['USDT', 'USDC', 'BUSD'];
    
    for (const token of tokens) {
      try {
        const feed = this.contracts.priceFeeds[token];
        const data = await feed.latestRoundData();
        results[token] = {
          price: data.answer.toString(),
          updatedAt: data.updatedAt.toString(),
          roundId: data.roundId.toString(),
          valid: true
        };
      } catch (error) {
        results[token] = {
          error: error.message,
          valid: false
        };
      }
    }
    
    return results;
  }

  async conductForensics() {
    // Analyze recent transactions
    const recentBlocks = 100;
    const currentBlock = await this.contracts.gateway.provider.getBlockNumber();
    
    const suspiciousTransactions = [];
    
    for (let i = 0; i < recentBlocks; i++) {
      const blockNumber = currentBlock - i;
      const block = await this.contracts.gateway.provider.getBlock(blockNumber, true);
      
      for (const tx of block.transactions) {
        if (await this.isSuspicious(tx)) {
          suspiciousTransactions.push(tx);
        }
      }
    }
    
    return { suspiciousTransactions, blockRange: [currentBlock - recentBlocks, currentBlock] };
  }

  async isSuspicious(transaction) {
    // Analyze transaction patterns
    return (
      transaction.value > ethers.parseEther('100') || // Large value
      transaction.gasPrice > ethers.parseUnits('100', 'gwei') || // High gas price
      transaction.to === this.contracts.gateway.address // Targeting our contract
    );
  }
}
```

## Security Checklist

### Pre-Deployment

- [ ] **Smart Contract Security**
  - [ ] Code reviewed by multiple developers
  - [ ] External security audit completed
  - [ ] All tests passing (unit, integration, fuzzing)
  - [ ] Access controls properly implemented
  - [ ] Reentrancy guards in place
  - [ ] Input validation comprehensive
  - [ ] Gas limits and DoS protection

- [ ] **Price Oracle Security**
  - [ ] Multiple price feed sources
  - [ ] Staleness checks implemented
  - [ ] Price deviation monitoring
  - [ ] Circuit breaker mechanisms
  - [ ] Fallback price sources

- [ ] **Infrastructure Security**
  - [ ] Private keys secured (hardware wallets, HSMs)
  - [ ] Multi-signature wallets for admin functions
  - [ ] Secure key management procedures
  - [ ] Encrypted communication channels
  - [ ] Regular security updates

### Post-Deployment

- [ ] **Monitoring Setup**
  - [ ] Real-time transaction monitoring
  - [ ] Security event alerting
  - [ ] Performance monitoring
  - [ ] Price feed monitoring
  - [ ] Gas usage tracking

- [ ] **Incident Response**
  - [ ] Emergency procedures documented
  - [ ] Contact lists maintained
  - [ ] Recovery procedures tested
  - [ ] Communication channels established
  - [ ] Forensic tools ready

- [ ] **Maintenance**
  - [ ] Regular security reviews
  - [ ] Update procedures documented
  - [ ] Backup and recovery tested
  - [ ] Team training completed
  - [ ] Insurance coverage reviewed

## Conclusion

Security in meta-transaction systems requires a multi-layered approach covering smart contracts, oracles, infrastructure, and operational procedures. Regular audits, comprehensive monitoring, and well-tested incident response procedures are essential for maintaining system security.

{% hint style="danger" %}
**Security is Critical**: Always prioritize security over convenience. A single vulnerability can compromise the entire system and user funds.
{% endhint %}

For additional security resources and expert consultation, contact our security team at security@metatx-contracts.com.
