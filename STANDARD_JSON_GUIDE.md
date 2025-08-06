# Solidity Standard JSON Input for BSCScan Verification

## Overview

When verifying complex contracts with multiple imports on BSCScan, you need to use the **"Solidity Standard JSON Input"** verification method instead of flattening.

## 🚀 Quick Steps

### 1. Generate Standard JSON Input

**Option A: From Build Info (Recommended)**
```bash
# Compile your contracts first
npm run compile

# Extract Standard JSON from build artifacts
npm run extract-build
```

**Option B: Generate Fresh**
```bash
# Generate new Standard JSON Input
npm run generate-json
```

### 2. Use for BSCScan Verification

1. Go to **https://bscscan.com/verifyContract**
2. Select **"Solidity (Standard-Json-Input)"**
3. **Compiler Settings**:
   - Compiler: `v0.8.20+commit.a1b79de6`
   - Open Source License: `MIT`
4. **Upload the generated JSON file** (`standard-json-input.json` or `standard-json-input-from-build.json`)

## 📁 What Gets Included

The Standard JSON Input includes:
- ✅ All your contract source files
- ✅ All imported dependencies (@openzeppelin, @chainlink)
- ✅ Exact compiler settings (optimizer, viaIR, etc.)
- ✅ Proper import remappings

## 🔧 Manual Method (If Scripts Don't Work)

### Step 1: Get Your Compilation Input

After running `npx hardhat compile`, check the build info:

```bash
# Look in artifacts/build-info/ for JSON files
ls artifacts/build-info/
```

### Step 2: Extract Input Section

Open the latest build-info JSON file and copy the `"input"` section. This is your Standard JSON Input.

### Step 3: Verify Structure

Your Standard JSON should look like:

```json
{
  "language": "Solidity",
  "sources": {
    "contracts/GasCreditVault.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\n..."
    },
    "@openzeppelin/contracts/...": {
      "content": "..."
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "viaIR": true,
    "outputSelection": { ... },
    "remappings": [
      "@openzeppelin/=node_modules/@openzeppelin/",
      "@chainlink/=node_modules/@chainlink/"
    ]
  }
}
```

## 🎯 BSCScan Verification Steps

### 1. **Contract Type**: Solidity (Standard-Json-Input)
### 2. **Compiler**: v0.8.20+commit.a1b79de6  
### 3. **License**: MIT
### 4. **Upload**: Your generated JSON file
### 5. **Constructor Args**: (Usually empty for UUPS proxies)

## 📋 Verification Checklist

- [ ] Contract compiled successfully (`npm run compile`)
- [ ] Standard JSON generated (`npm run extract-build`)
- [ ] JSON file contains all source files
- [ ] Compiler version matches (v0.8.20)
- [ ] Using implementation address (not proxy)
- [ ] Constructor arguments correct (if any)

## 🐛 Troubleshooting

### Issue: "Sources not found"
- **Solution**: Make sure all imports are included in the JSON

### Issue: "Compilation failed"  
- **Solution**: Verify compiler settings match exactly

### Issue: "Constructor arguments"
- **Solution**: For UUPS proxies, usually leave empty

### Issue: "Files missing"
- **Solution**: Use the build-info extraction method

## 🔄 Alternative: Hardhat Verify

If Standard JSON doesn't work, try Hardhat's automatic verification:

```bash
npx hardhat verify --contract contracts/GasCreditVault.sol:GasCreditVault --network bsc 0xYOUR_IMPLEMENTATION_ADDRESS
```

## 📝 Example Files Generated

After running the scripts, you'll have:
- `standard-json-input.json` - Fresh generation
- `standard-json-input-from-build.json` - From build artifacts

Use either file for BSCScan verification!
