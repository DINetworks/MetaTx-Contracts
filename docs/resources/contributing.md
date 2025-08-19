# Contributing

Guidelines for contributing to MetaTx-Contracts project.

## Welcome Contributors! 🎉

We're excited that you're interested in contributing to MetaTx-Contracts! This document provides guidelines and information to help you contribute effectively to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Contribution Types](#contribution-types)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Security Considerations](#security-considerations)
- [Community and Support](#community-and-support)

## Code of Conduct

### Our Commitment

We are committed to making participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behaviors include:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behaviors include:**
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission
- Other conduct which could reasonably be considered inappropriate in a professional setting

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project team at conduct@metatx-contracts.com. All complaints will be reviewed and investigated promptly and fairly.

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Node.js** (v18.0.0 or higher)
- **npm** or **yarn** package manager
- **Git** for version control
- **Code editor** (VS Code recommended)
- **MetaMask** or similar wallet for testing

### Environment Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/MetaTx-Contracts.git
   cd MetaTx-Contracts
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run tests**
   ```bash
   npm test
   ```

5. **Compile contracts**
   ```bash
   npx hardhat compile
   ```

### Project Structure

```
MetaTx-Contracts/
├── contracts/           # Smart contracts
│   ├── MetaTxGateway.sol
│   ├── GasCreditVault.sol
│   └── mock/           # Test contracts
├── scripts/            # Deployment scripts
├── test/              # Test files
├── docs/              # Documentation
├── artifacts/         # Compiled contracts
├── cache/             # Hardhat cache
└── hardhat.config.js  # Hardhat configuration
```

## Development Workflow

### Branch Strategy

We use **Git Flow** with the following branches:

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`feature/*`**: New features
- **`bugfix/*`**: Bug fixes
- **`hotfix/*`**: Critical production fixes
- **`release/*`**: Release preparation

### Workflow Steps

1. **Create a feature branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code following our standards
   - Add/update tests
   - Update documentation

3. **Test your changes**
   ```bash
   npm test
   npm run lint
   npm run coverage
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   # Create PR on GitHub
   ```

### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools

**Examples:**
```bash
feat: add native token support to MetaTxGateway
fix: resolve nonce synchronization issue
docs: update API documentation for GasCreditVault
test: add comprehensive signature validation tests
```

## Contribution Types

### 🔧 Code Contributions

#### Smart Contract Development
- **New Features**: Implement new functionality
- **Bug Fixes**: Fix identified issues
- **Optimizations**: Gas optimization and performance improvements
- **Security Enhancements**: Improve contract security

#### Frontend/SDK Development
- **Integration Libraries**: JavaScript/TypeScript SDKs
- **Example Applications**: Demo applications and tutorials
- **Developer Tools**: CLI tools and utilities

#### Infrastructure
- **Deployment Scripts**: Automated deployment tools
- **CI/CD**: Continuous integration improvements
- **Monitoring**: Observability and alerting systems

### 📚 Documentation

#### Technical Documentation
- **API References**: Contract and SDK documentation
- **Integration Guides**: Step-by-step tutorials
- **Architecture Docs**: System design documentation

#### User Documentation
- **User Guides**: End-user documentation
- **FAQ Updates**: Common questions and answers
- **Troubleshooting**: Problem resolution guides

### 🧪 Testing

#### Test Development
- **Unit Tests**: Individual function testing
- **Integration Tests**: End-to-end testing
- **Security Tests**: Vulnerability testing
- **Performance Tests**: Gas usage and efficiency testing

#### Quality Assurance
- **Manual Testing**: User interface testing
- **Regression Testing**: Ensuring fixes don't break existing functionality
- **Cross-browser Testing**: Compatibility testing

### 🐛 Bug Reports

#### Reporting Issues
1. **Search existing issues** to avoid duplicates
2. **Use issue templates** provided
3. **Provide detailed information**:
   - Environment details
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots/logs if applicable

#### Issue Template
```markdown
**Bug Description**
A clear and concise description of the bug.

**Environment**
- OS: [e.g. macOS 12.0]
- Browser: [e.g. Chrome 96.0]
- MetaMask Version: [e.g. 10.5.0]
- Network: [e.g. BSC Mainnet]

**Steps to Reproduce**
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected Behavior**
A clear description of what you expected to happen.

**Actual Behavior**
A clear description of what actually happened.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Additional Context**
Add any other context about the problem here.
```

## Coding Standards

### Solidity Standards

#### Code Style
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ExampleContract
 * @dev Brief description of the contract
 * @author MetaTx-Contracts Team
 */
contract ExampleContract is Ownable, ReentrancyGuard {
    // State variables
    uint256 public constant MAX_SUPPLY = 1000000;
    mapping(address => uint256) private _balances;
    
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    
    // Custom errors
    error InsufficientBalance(uint256 requested, uint256 available);
    
    /**
     * @dev Constructor sets initial values
     * @param initialOwner Address of the initial owner
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        // Constructor logic
    }
    
    /**
     * @dev Mints tokens to specified address
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be positive");
        
        _balances[to] += amount;
        emit TokensMinted(to, amount);
    }
}
```

#### Best Practices
- **Use latest Solidity version** (^0.8.20)
- **Follow OpenZeppelin patterns** for security
- **Use custom errors** instead of require strings (gas efficient)
- **Comprehensive NatSpec documentation**
- **Consistent naming conventions**:
  - Contracts: `PascalCase`
  - Functions: `camelCase`
  - Variables: `camelCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Private variables: `_camelCase`

### JavaScript/TypeScript Standards

#### Code Style
```javascript
// Use ESLint and Prettier for formatting
import { ethers } from 'ethers';
import { expect } from 'chai';

/**
 * Utility class for managing meta-transactions
 */
class MetaTransactionManager {
  constructor(gateway, signer) {
    this.gateway = gateway;
    this.signer = signer;
    this.nonce = null;
  }

  /**
   * Executes a meta-transaction
   * @param {Object} transaction - Transaction parameters
   * @param {string} transaction.to - Target address
   * @param {BigInt} transaction.value - ETH value
   * @param {string} transaction.data - Call data
   * @returns {Promise<Object>} Transaction receipt
   */
  async executeTransaction(transaction) {
    try {
      const signedTx = await this.signTransaction(transaction);
      const receipt = await this.submitTransaction(signedTx);
      return receipt;
    } catch (error) {
      console.error('Transaction execution failed:', error);
      throw error;
    }
  }

  async signTransaction(transaction) {
    // Implementation
  }
}

export { MetaTransactionManager };
```

#### Configuration Files

**ESLint** (`.eslintrc.js`):
```javascript
module.exports = {
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
    'prettier'
  ],
  plugins: ['@typescript-eslint'],
  rules: {
    'no-console': 'warn',
    'no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    'prefer-const': 'error'
  }
};
```

**Prettier** (`.prettierrc`):
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
```

## Testing Guidelines

### Smart Contract Testing

#### Test Structure
```javascript
const { expect } = require('chai');
const { ethers } = require('hardhat');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('MetaTxGateway', function () {
  // Test fixture
  async function deployFixture() {
    const [owner, user, relayer] = await ethers.getSigners();
    
    const MetaTxGateway = await ethers.getContractFactory('MetaTxGateway');
    const gateway = await upgrades.deployProxy(MetaTxGateway, [owner.address]);
    
    return { gateway, owner, user, relayer };
  }

  describe('Deployment', function () {
    it('Should set the right owner', async function () {
      const { gateway, owner } = await loadFixture(deployFixture);
      expect(await gateway.owner()).to.equal(owner.address);
    });
  });

  describe('Meta-transaction execution', function () {
    it('Should execute valid meta-transaction', async function () {
      const { gateway, user } = await loadFixture(deployFixture);
      
      // Test implementation
      const transaction = {
        to: user.address,
        value: 0,
        data: '0x',
        nonce: 0,
        deadline: Math.floor(Date.now() / 1000) + 300
      };
      
      const signature = await signTransaction(user, transaction);
      
      await expect(gateway.executeMetaTransactions([{
        ...transaction,
        signature
      }])).to.emit(gateway, 'MetaTransactionExecuted');
    });

    it('Should reject expired transactions', async function () {
      const { gateway, user } = await loadFixture(deployFixture);
      
      const expiredTransaction = {
        to: user.address,
        value: 0,
        data: '0x',
        nonce: 0,
        deadline: Math.floor(Date.now() / 1000) - 300 // Past deadline
      };
      
      const signature = await signTransaction(user, expiredTransaction);
      
      await expect(gateway.executeMetaTransactions([{
        ...expiredTransaction,
        signature
      }])).to.be.revertedWithCustomError(gateway, 'ExpiredDeadline');
    });
  });
});
```

#### Testing Best Practices
- **Use fixtures** for consistent test setup
- **Test edge cases** and error conditions
- **Use custom error testing** with Hardhat
- **Test gas usage** for optimization
- **Mock external dependencies** (oracles, tokens)

### Coverage Requirements

- **Smart Contracts**: Minimum 90% coverage
- **JavaScript/TypeScript**: Minimum 80% coverage
- **Critical paths**: 100% coverage required

```bash
# Run coverage
npm run coverage

# View coverage report
open coverage/index.html
```

## Documentation

### Documentation Standards

#### Code Documentation
- **Smart contracts**: Complete NatSpec documentation
- **JavaScript/TypeScript**: JSDoc comments
- **Complex logic**: Inline comments explaining why, not what

#### GitBook Documentation
- **Clear structure**: Logical organization
- **Code examples**: Working, tested examples
- **Diagrams**: Mermaid diagrams for complex flows
- **Cross-references**: Links between related sections

#### README Files
Each major component should have a README with:
- Purpose and overview
- Installation instructions
- Usage examples
- API reference links
- Contributing guidelines

### Documentation Process

1. **Write docs with code**: Documentation is part of development
2. **Review for clarity**: Have others review your documentation
3. **Test examples**: Ensure all code examples work
4. **Update existing docs**: Keep documentation current with changes

## Pull Request Process

### PR Checklist

Before submitting a PR, ensure:

- [ ] **Code Quality**
  - [ ] Code follows style guidelines
  - [ ] No linting errors
  - [ ] All tests pass
  - [ ] Code coverage maintained

- [ ] **Documentation**
  - [ ] Code is well-documented
  - [ ] README updated if needed
  - [ ] GitBook documentation updated
  - [ ] Changelog entry added

- [ ] **Testing**
  - [ ] New tests added for new functionality
  - [ ] Edge cases covered
  - [ ] Integration tests updated
  - [ ] Manual testing completed

- [ ] **Security**
  - [ ] Security implications considered
  - [ ] No hardcoded secrets
  - [ ] Input validation implemented
  - [ ] Access controls verified

### PR Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Coverage maintained/improved

## Documentation
- [ ] Code comments updated
- [ ] README updated
- [ ] GitBook documentation updated
- [ ] API documentation updated

## Security
- [ ] Security implications reviewed
- [ ] No sensitive data exposed
- [ ] Access controls verified
- [ ] Input validation implemented

## Additional Notes
Any additional information, concerns, or considerations.
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs
2. **Code Review**: At least one maintainer review
3. **Security Review**: For security-sensitive changes
4. **Testing**: Manual testing if needed
5. **Documentation Review**: Documentation accuracy
6. **Approval**: Final approval from maintainer

### Merge Criteria

PRs will be merged when:
- All automated checks pass
- Code review approved
- Documentation updated
- No conflicts with base branch
- Follows contribution guidelines

## Security Considerations

### Security Review Process

For security-sensitive contributions:

1. **Security Review Required**: All smart contract changes
2. **Threat Modeling**: Consider attack vectors
3. **Static Analysis**: Use security analysis tools
4. **Audit Trail**: Document security decisions

### Reporting Vulnerabilities

**Do not report security vulnerabilities publicly.**

Instead:
1. Email security@metatx-contracts.com
2. Include detailed description
3. Provide proof of concept if possible
4. Allow reasonable time for fix before disclosure

### Security Bounty

We offer rewards for responsibly disclosed vulnerabilities:
- **Critical**: $5,000 - $10,000
- **High**: $1,000 - $5,000
- **Medium**: $500 - $1,000
- **Low**: $100 - $500

## Community and Support

### Communication Channels

- **GitHub Discussions**: General discussions and Q&A
- **Discord**: Real-time community chat
- **Telegram**: Development updates
- **Twitter**: Project announcements
- **Email**: Direct contact for sensitive matters

### Getting Help

- **Documentation**: Start with this GitBook
- **GitHub Issues**: Report bugs or request features
- **Discord**: Ask questions in community channels
- **Stack Overflow**: Tag questions with `metatx-contracts`

### Mentorship

New contributors can get mentorship:
- **Good First Issues**: Tagged for beginners
- **Mentorship Program**: Pair with experienced contributors
- **Code Review**: Learn from feedback
- **Documentation**: Start with documentation contributions

## Recognition

### Contributor Recognition

We recognize contributions through:

- **Contributors Page**: Listed on project website
- **Release Notes**: Acknowledged in release notes
- **Social Media**: Highlighted on Twitter/Discord
- **Swag**: Project merchandise for regular contributors
- **Conference Opportunities**: Speaking opportunities at events

### Hall of Fame

Outstanding contributors may be invited to:
- **Core Team**: Join the core development team
- **Advisory Board**: Provide strategic guidance
- **Ambassador Program**: Represent the project

## Development Resources

### Useful Tools

- **Hardhat**: Ethereum development environment
- **OpenZeppelin**: Secure smart contract library
- **Ethers.js**: Ethereum library for JavaScript
- **Remix**: Online Solidity IDE
- **MythX**: Security analysis platform
- **Slither**: Static analysis tool

### Learning Resources

- **Solidity Documentation**: https://docs.soliditylang.org/
- **OpenZeppelin Learn**: https://docs.openzeppelin.com/learn/
- **Ethereum.org**: https://ethereum.org/developers/
- **Hardhat Documentation**: https://hardhat.org/docs/

## License

By contributing to MetaTx-Contracts, you agree that your contributions will be licensed under the MIT License.

## Questions?

If you have any questions about contributing, please:

1. Check this contributing guide
2. Search existing GitHub issues
3. Ask in our Discord community
4. Create a GitHub discussion
5. Email contributors@metatx-contracts.com

---

**Thank you for contributing to MetaTx-Contracts!** 🚀

Your contributions help make decentralized applications more accessible and user-friendly. We appreciate your time and effort in making this project better for everyone.
