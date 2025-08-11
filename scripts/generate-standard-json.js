const fs = require('fs');
const path = require('path');

async function generateStandardJsonInput() {
  // Define compiler settings (matching hardhat.config.js)
  const compilerSettings = {
    optimizer: {
      enabled: true,
      runs: 200
    },
    viaIR: true
  };
  
  // Read all source files
  const contractsDir = path.join(__dirname, '../contracts');
  const sources = {};
  
  function readSourcesRecursively(dir) {
    const files = fs.readdirSync(dir);
    
    for (const file of files) {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory()) {
        readSourcesRecursively(filePath);
      } else if (file.endsWith('.sol')) {
        // Use relative path from project root
        const relativePath = path.relative(path.join(__dirname, '..'), filePath).replace(/\\/g, '/');
        const content = fs.readFileSync(filePath, 'utf8');
        sources[relativePath] = { content };
      }
    }
  }
  
  readSourcesRecursively(contractsDir);
  
  // Create Standard JSON Input
  const standardJsonInput = {
    language: "Solidity",
    sources: sources,
    settings: {
      optimizer: compilerSettings.optimizer,
      viaIR: compilerSettings.viaIR,
      outputSelection: {
        "*": {
          "*": [
            "abi",
            "evm.bytecode",
            "evm.deployedBytecode",
            "evm.methodIdentifiers",
            "metadata"
          ]
        }
      },
      // Add remappings if you have any
      remappings: [
        "@openzeppelin/=node_modules/@openzeppelin/",
        "@chainlink/=node_modules/@chainlink/"
      ]
    }
  };

  // Write to file
  const outputPath = path.join(__dirname, '../standard-json-input.json');
  fs.writeFileSync(
    outputPath, 
    JSON.stringify(standardJsonInput, null, 2)
  );  console.log('✅ Standard JSON Input generated: standard-json-input.json');
  console.log('📁 Files included:', Object.keys(sources));
}

generateStandardJsonInput().catch(console.error);
