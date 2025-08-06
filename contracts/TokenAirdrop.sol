// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenAirdrop is Ownable {
    IERC20 public immutable token;
    bytes32 public merkleRoot;    
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    mapping(address => bool) public hasClaimed;

    event Claimed(address indexed account, uint256 amount);
    event MerkleRootUpdated(bytes32 indexed newRoot);
    event AirdropWindowUpdated(uint256, uint256);

    constructor(address _token, address _owner) Ownable(_owner) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    modifier airdropActive() {
        require(block.timestamp >= startTimestamp, "Sale not started");
        require(block.timestamp <= endTimestamp, "Sale ended");
        _;
    }

    function setAirdropWindow(uint256 _start, uint256 _end) external onlyOwner {
        require(_start < _end, "Invalid time range");
        startTimestamp = _start;
        endTimestamp = _end;
        emit AirdropWindowUpdated(_start, _end);
    }

    function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit MerkleRootUpdated(newRoot);
    }

    function claim(uint256 amount, bytes32[] calldata proof) external airdropActive {
        require(!hasClaimed[msg.sender], "Already claimed");
        require(merkleRoot != bytes32(0), "Merkle root not set");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        hasClaimed[msg.sender] = true;
        require(token.transfer(msg.sender, amount), "Transfer failed");

        emit Claimed(msg.sender, amount);
    }

    function recoverRemaining(address to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(to, balance), "Withdraw failed");
    }
}