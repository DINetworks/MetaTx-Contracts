// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title MetaTxGateway
 * @notice Gateway for executing gasless meta-transactions on any EVM chain
 * @dev Does not handle gas credits - relies on external relayer for credit management
 * @dev Only supports batch execution - single meta-transactions must be wrapped in a batch
 * @dev Upgradeable contract using UUPS pattern with pause functionality
 */
contract MetaTxGateway is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using ECDSA for bytes32;

    // EIP-712 Domain Separator
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    // EIP-712 Meta Transaction Typehash for batch transactions
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        "MetaTransaction(address from,bytes metaTxData,uint256 nonce,uint256 deadline)"
    );
    
    // Relayer management
    mapping(address => bool) public authorizedRelayers;
    
    // Nonce management for replay protection
    mapping(address => uint256) public nonces;

    // Mapping from batch transaction ID to log
    uint256 public nextBatchId;

    // Pause-related state variables
    struct PauseInfo {
        uint256 pausedAt;
        string pauseReason;
    }
    
    PauseInfo public pauseState;

    struct MetaTransaction {
        address to;        // Target contract to call
        uint256 value;     // ETH value to send (usually 0)
        bytes data;        // Function call data
    }

    event RelayerAuthorized(address indexed relayer, bool authorized);
    event MetaTransactionExecuted(
        address indexed user,
        address indexed relayer,
        address indexed target,
        bool success
    );
    event NativeTokenUsed(
        uint256 indexed batchId,
        uint256 totalRequired,
        uint256 totalUsed,
        uint256 refunded
    );
    event PausedWithReason(string reason);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with the initial owner
     * @notice This function can only be called once during deployment
     */
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    // Owner functions ==============================================

    /**
     * @notice Authorize/deauthorize a relayer
     * @param relayer Relayer address
     * @param authorized True to authorize, false to deauthorize
     */
    function setRelayerAuthorization(address relayer, bool authorized) external onlyOwner {
        require(relayer != address(0), "Invalid relayer address");
        authorizedRelayers[relayer] = authorized;
        emit RelayerAuthorized(relayer, authorized);
    }

    // Pause management functions ================================
    /**
     * @notice Pause the contract with a reason
     * @param reason Reason for pausing the contract
     */
    function pauseWithReason(string calldata reason) external onlyOwner {
        require(!paused(), "Already paused");
        require(bytes(reason).length > 0, "Pause reason required");
        
        pauseState = PauseInfo({
            pausedAt: block.timestamp,
            pauseReason: reason
        });
        
        _pause();
        emit PausedWithReason(reason);
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        require(paused(), "Not paused");
        _unpause();
    }

    

    // Meta-transaction functions ================================

    /**
     * @notice Execute a meta-transaction on behalf of a user (internal use only)
     * @param from User's address
     * @param metaTx Meta-transaction data
     * @return success True if the transaction was successful
     */
    function _executeMetaTransaction(
        address from,
        MetaTransaction memory metaTx
    ) internal returns (bool success) {
        // Execute the transaction with try-catch to handle failures gracefully
        try this._safeExecuteCall(metaTx.to, metaTx.value, metaTx.data) returns (bool _success) {
            success = _success;
        } catch {
            success = false;
        }
        
        emit MetaTransactionExecuted(from, msg.sender, metaTx.to, success);
        
        return success;
    }

    /**
     * @notice Helper function to safely execute external calls
     * @dev This function is external to allow try-catch usage
     */
    function _safeExecuteCall(address target, uint256 value, bytes calldata data) external returns (bool success) {
        require(msg.sender == address(this), "Only self-calls allowed");
        (success, ) = target.call{value: value}(data);
        return success;
    }

    /**
     * @notice Calculate total native token value required for batch transactions
     * @param metaTxs Array of meta-transactions
     * @return totalValue Total native token value needed
     */
    function _calculateTotalValue(MetaTransaction[] memory metaTxs) internal pure returns (uint256 totalValue) {
        for (uint256 i = 0; i < metaTxs.length; i++) {
            totalValue += metaTxs[i].value;
        }
        return totalValue;
    }

    /**
     * @notice Batch execute multiple meta-transactions
     * @param from User's address
     * @param metaTxData Encoded bytes of Array of meta-transactions
     * @param signature signature corresponding to entire meta transaction
     * @param nonce User's nonce
     * @param deadline Transaction deadline
     * @return successes Array of success status for each transaction
     */
    function executeMetaTransactions(
        address from,
        bytes calldata metaTxData,
        bytes calldata signature,
        uint256 nonce,
        uint256 deadline
    ) external payable nonReentrant whenNotPaused returns (bool[] memory successes) {
        require(authorizedRelayers[msg.sender], "Unauthorized relayer");
        require(block.timestamp <= deadline, "Transaction expired");
        require(nonce == nonces[from], "Invalid nonce");
        require(_verifySignature(from, metaTxData, signature, nonce, deadline), "Invalid signature");

        MetaTransaction[] memory metaTxs = abi.decode(metaTxData, (MetaTransaction[]));
        require(metaTxs.length > 0, "Empty batch Txs");

        // Calculate total value required for all meta-transactions
        uint256 totalValueRequired = 0;
        if (msg.value > 0) {
            totalValueRequired = _calculateTotalValue(metaTxs);
            require(msg.value == totalValueRequired, "Incorrect native token amount");
        }

        successes = new bool[](metaTxs.length);

        // Store batch transaction log
        uint256 batchId = nextBatchId++;
        uint256 valueUsed = 0;

        // Execute all transactions in the batch
        for (uint256 i = 0; i < metaTxs.length; i++) {
            bool success = _executeMetaTransaction(from, metaTxs[i]);
            
            // Track value used for each transaction
            if (success) {
                valueUsed += metaTxs[i].value;
            }
        }

        // Refund unused native tokens if any transactions failed
        if (totalValueRequired > 0) {
            uint256 refundAmount = totalValueRequired - valueUsed;
            if (refundAmount > 0) {
                (bool refundSuccess, ) = payable(from).call{value: refundAmount}("");
                require(refundSuccess, "Refund failed");
            }

            emit NativeTokenUsed(batchId, totalValueRequired, valueUsed, refundAmount);
        }
        
        // Increment nonce to prevent replay
        nonces[from]++;        

        return successes;
    }

    // Helper functions ==========================================

    /**
     * @notice Verify EIP-712 signature for batch meta-transactions
     * @param from User's address
     * @param metaTxData Encoded bytes of Meta-transactions data
     * @param signature User's signature
     * @param nonce User's nonce
     * @param deadline User's deadline
     * @return valid True if signature is valid
     */
    function _verifySignature(
        address from,
        bytes calldata metaTxData,
        bytes calldata signature,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bool valid) {
        bytes32 domainSeparator = this.getDomainSeparator();

        bytes32 structHash = keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            from,
            keccak256(metaTxData),
            nonce,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            structHash
        ));

        address recoveredSigner = digest.recover(signature);
        return recoveredSigner == from;
    }

    // View functions ============================================

    /**
     * @notice Get total native token value required for meta-transactions (external view)
     * @param metaTxData Encoded bytes of meta-transactions
     * @return totalValue Total native token value needed
     */
    function calculateRequiredValue(bytes calldata metaTxData) external pure returns (uint256 totalValue) {
        MetaTransaction[] memory metaTxs = abi.decode(metaTxData, (MetaTransaction[]));
        return _calculateTotalValue(metaTxs);
    }

    /**
     * @notice Get the current nonce for a user
     * @param user User address
     * @return currentNonce Current nonce value
     */
    function getNonce(address user) external view returns (uint256 currentNonce) {
        return nonces[user];
    }

    /**
     * @notice Check if a relayer is authorized
     * @param relayer Relayer address
     * @return isAuthorized True if relayer is authorized
     */
    function isRelayerAuthorized(address relayer) external view returns (bool isAuthorized) {
        return authorizedRelayers[relayer];
    }

    /**
     * @notice Get the domain separator for EIP-712
     * @return separator Domain separator hash
     */
    function getDomainSeparator() external view returns (bytes32 separator) {
        return keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("MetaTxGateway"),
            keccak256("1"), // Version 2 with native token support
            block.chainid,
            address(this)
        ));
    }

    /**
     * @notice Get total number of batch transactions processed
     * @return count Total batch transaction count
     */
    function getTotalBatchCount() external view returns (uint256 count) {
        return nextBatchId;
    }

    /**
     * @notice Get the contract version
     * @return version The version string for this contract
     */
    function getVersion() external pure returns (string memory version) {
        return "v1.0.0-native-token-support";
    }

    // Upgrade authorization =====================================

    /**
     * @dev Authorizes contract upgrades (UUPS pattern)
     * @param newImplementation The address of the new implementation
     * @notice Only owner can authorize upgrades
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}