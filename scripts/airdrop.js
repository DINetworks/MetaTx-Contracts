// airdrop.js
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');
const path = require('path');

// 1. Load your airdrop list
const airdropList = [
  { address: '0x1234567890abcdef1234567890abcdef12345678', amount: 1000 },
  { address: '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd', amount: 2000 },
  // add more entries...
];

// 2. Generate leaves (hash of address + amount)
const leaves = airdropList.map(({ address, amount }) =>
  keccak256(Buffer.from(address.toLowerCase() + amount))
);

// 3. Create Merkle Tree
const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// 4. Get the Merkle Root
const merkleRoot = merkleTree.getHexRoot();
console.log('Merkle Root:', merkleRoot);

// 5. Save proofs for each user
const claims = {};
airdropList.forEach(({ address, amount }) => {
  const leaf = keccak256(Buffer.from(address.toLowerCase() + amount));
  const proof = merkleTree.getHexProof(leaf);

  claims[address.toLowerCase()] = {
    amount,
    proof,
  };
});

// 6. Save the root and claims to a JSON file
fs.writeFileSync(
  path.join(__dirname, 'airdrop_proofs.json'),
  JSON.stringify({ merkleRoot, claims }, null, 2)
);

console.log('Proofs generated and saved to airdrop_proofs.json');
