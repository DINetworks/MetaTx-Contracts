const fs = require('fs');
const path = require('path');

async function extractFromBuildInfo() {
  const buildInfoDir = path.join(__dirname, '../artifacts/build-info');
  
  if (!fs.existsSync(buildInfoDir)) {
    console.error('❌ Build info directory not found. Run: npx hardhat compile');
    console.error('📁 Looking for:', buildInfoDir);
    return;
  }
  
  const buildInfoFiles = fs.readdirSync(buildInfoDir);
  
  if (buildInfoFiles.length === 0) {
    console.error('❌ No build info files found. Run: npx hardhat compile');
    return;
  }
  
  // Get the latest build info file
  const latestBuildInfo = buildInfoFiles.sort().pop();
  const buildInfoPath = path.join(buildInfoDir, latestBuildInfo);
  
  console.log(`📖 Reading build info: ${latestBuildInfo}`);
  
  const buildInfo = JSON.parse(fs.readFileSync(buildInfoPath, 'utf8'));
  
  // Extract the input that was used for compilation
  const standardJsonInput = buildInfo.input;
  
  // Write to file
  const outputPath = path.join(__dirname, '../standard-json-input-from-build.json');
  fs.writeFileSync(
    outputPath,
    JSON.stringify(standardJsonInput, null, 2)
  );
  
  console.log('✅ Standard JSON Input extracted from build info');
  console.log('📁 File: standard-json-input-from-build.json');
  console.log('🔧 Compiler version:', buildInfo.solcVersion);
  console.log('📋 Sources included:', Object.keys(standardJsonInput.sources));
}

extractFromBuildInfo().catch(console.error);
