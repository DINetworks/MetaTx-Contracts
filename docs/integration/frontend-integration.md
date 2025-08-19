# Frontend Integration

Complete guide for integrating MetaTx-Contracts into your frontend application.

## Overview

This guide covers how to integrate meta-transaction functionality into your React/TypeScript frontend application, including user onboarding, transaction signing, and status monitoring.

## Prerequisites

- **Frontend Framework**: React 18+ or similar
- **Web3 Library**: ethers.js v6 or web3.js
- **TypeScript**: For type safety (recommended)
- **Wallet Connection**: MetaMask or WalletConnect

## Installation

### Required Dependencies

```bash
npm install ethers @types/node

# Optional but recommended
npm install @metamask/sdk @walletconnect/web3-provider
```

### Project Structure

```
src/
├── components/
│   ├── WalletConnection.tsx
│   ├── MetaTransactionForm.tsx
│   └── TransactionStatus.tsx
├── hooks/
│   ├── useWallet.ts
│   ├── useMetaTransaction.ts
│   └── useGasCredits.ts
├── services/
│   ├── contractService.ts
│   ├── relayerService.ts
│   └── signingService.ts
├── types/
│   └── contracts.ts
└── utils/
    ├── contractHelpers.ts
    └── formatters.ts
```

## Wallet Connection

### React Hook for Wallet Management

```typescript
// hooks/useWallet.ts
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

interface WalletState {
  address: string | null;
  provider: ethers.BrowserProvider | null;
  signer: ethers.JsonRpcSigner | null;
  chainId: number | null;
  isConnected: boolean;
}

export const useWallet = () => {
  const [wallet, setWallet] = useState<WalletState>({
    address: null,
    provider: null,
    signer: null,
    chainId: null,
    isConnected: false
  });

  const connectWallet = async () => {
    try {
      if (!window.ethereum) {
        throw new Error('MetaMask not installed');
      }

      const provider = new ethers.BrowserProvider(window.ethereum);
      const accounts = await provider.send('eth_requestAccounts', []);
      const signer = await provider.getSigner();
      const network = await provider.getNetwork();

      setWallet({
        address: accounts[0],
        provider,
        signer,
        chainId: Number(network.chainId),
        isConnected: true
      });
    } catch (error) {
      console.error('Failed to connect wallet:', error);
      throw error;
    }
  };

  const disconnectWallet = () => {
    setWallet({
      address: null,
      provider: null,
      signer: null,
      chainId: null,
      isConnected: false
    });
  };

  const switchNetwork = async (chainId: number) => {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: `0x${chainId.toString(16)}` }]
      });
    } catch (error: any) {
      if (error.code === 4902) {
        // Network not added to MetaMask
        await addNetwork(chainId);
      } else {
        throw error;
      }
    }
  };

  const addNetwork = async (chainId: number) => {
    const networks = {
      56: {
        chainId: '0x38',
        chainName: 'BNB Smart Chain',
        rpcUrls: ['https://bsc-dataseed1.binance.org/'],
        nativeCurrency: {
          name: 'BNB',
          symbol: 'BNB',
          decimals: 18
        },
        blockExplorerUrls: ['https://bscscan.com']
      },
      97: {
        chainId: '0x61',
        chainName: 'BNB Smart Chain Testnet',
        rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
        nativeCurrency: {
          name: 'tBNB',
          symbol: 'tBNB',
          decimals: 18
        },
        blockExplorerUrls: ['https://testnet.bscscan.com']
      }
    };

    await window.ethereum.request({
      method: 'wallet_addEthereumChain',
      params: [networks[chainId as keyof typeof networks]]
    });
  };

  useEffect(() => {
    // Auto-connect if previously connected
    const checkConnection = async () => {
      if (window.ethereum) {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.listAccounts();
        
        if (accounts.length > 0) {
          await connectWallet();
        }
      }
    };

    checkConnection();

    // Listen for account changes
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts: string[]) => {
        if (accounts.length === 0) {
          disconnectWallet();
        } else {
          connectWallet();
        }
      });

      window.ethereum.on('chainChanged', () => {
        window.location.reload();
      });
    }

    return () => {
      if (window.ethereum) {
        window.ethereum.removeAllListeners();
      }
    };
  }, []);

  return {
    ...wallet,
    connectWallet,
    disconnectWallet,
    switchNetwork
  };
};
```

### Wallet Connection Component

```typescript
// components/WalletConnection.tsx
import React from 'react';
import { useWallet } from '../hooks/useWallet';

export const WalletConnection: React.FC = () => {
  const {
    address,
    chainId,
    isConnected,
    connectWallet,
    disconnectWallet,
    switchNetwork
  } = useWallet();

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  const handleNetworkSwitch = async () => {
    try {
      await switchNetwork(56); // BSC Mainnet
    } catch (error) {
      console.error('Failed to switch network:', error);
    }
  };

  if (!isConnected) {
    return (
      <button
        onClick={connectWallet}
        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      >
        Connect Wallet
      </button>
    );
  }

  return (
    <div className="flex items-center space-x-4">
      <div className="text-sm">
        <div>Connected: {formatAddress(address!)}</div>
        <div>Chain ID: {chainId}</div>
      </div>
      
      {chainId !== 56 && (
        <button
          onClick={handleNetworkSwitch}
          className="bg-yellow-500 hover:bg-yellow-700 text-white font-bold py-1 px-2 rounded text-sm"
        >
          Switch to BSC
        </button>
      )}
      
      <button
        onClick={disconnectWallet}
        className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
      >
        Disconnect
      </button>
    </div>
  );
};
```

## Contract Integration

### Contract Service

```typescript
// services/contractService.ts
import { ethers } from 'ethers';

// Contract ABIs (simplified for example)
export const METATX_GATEWAY_ABI = [
  "function executeMetaTransactions(tuple(address to, uint256 value, bytes data, uint256 nonce, uint256 deadline, bytes signature)[] transactions) external payable",
  "function getNonce(address user) external view returns (uint256)",
  "function name() external view returns (string)",
  "function version() external view returns (string)",
  "event MetaTransactionExecuted(address indexed user, address indexed to, bool success, bytes returnData)"
];

export const GAS_CREDIT_VAULT_ABI = [
  "function getCreditBalance(address user) external view returns (uint256)",
  "function depositCredits(address token, uint256 amount) external",
  "function transferCredits(address to, uint256 amount) external",
  "function calculateCredits(address token, uint256 tokenAmount) external view returns (uint256)"
];

export const ERC20_ABI = [
  "function balanceOf(address owner) external view returns (uint256)",
  "function transfer(address to, uint256 amount) external returns (bool)",
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function allowance(address owner, address spender) external view returns (uint256)",
  "function decimals() external view returns (uint8)",
  "function symbol() external view returns (string)"
];

export interface ContractAddresses {
  metaTxGateway: string;
  gasCreditVault: string;
  tokens: {
    [symbol: string]: string;
  };
}

export class ContractService {
  private provider: ethers.Provider;
  private signer?: ethers.Signer;
  private addresses: ContractAddresses;

  constructor(
    provider: ethers.Provider,
    addresses: ContractAddresses,
    signer?: ethers.Signer
  ) {
    this.provider = provider;
    this.signer = signer;
    this.addresses = addresses;
  }

  // MetaTxGateway Contract
  getMetaTxGateway(withSigner = false) {
    const providerOrSigner = withSigner && this.signer ? this.signer : this.provider;
    return new ethers.Contract(
      this.addresses.metaTxGateway,
      METATX_GATEWAY_ABI,
      providerOrSigner
    );
  }

  // GasCreditVault Contract
  getGasCreditVault(withSigner = false) {
    const providerOrSigner = withSigner && this.signer ? this.signer : this.provider;
    return new ethers.Contract(
      this.addresses.gasCreditVault,
      GAS_CREDIT_VAULT_ABI,
      providerOrSigner
    );
  }

  // ERC20 Token Contract
  getTokenContract(tokenSymbol: string, withSigner = false) {
    const tokenAddress = this.addresses.tokens[tokenSymbol];
    if (!tokenAddress) {
      throw new Error(`Token ${tokenSymbol} not found`);
    }

    const providerOrSigner = withSigner && this.signer ? this.signer : this.provider;
    return new ethers.Contract(tokenAddress, ERC20_ABI, providerOrSigner);
  }

  // Get user's nonce for meta-transactions
  async getUserNonce(userAddress: string): Promise<bigint> {
    const gateway = this.getMetaTxGateway();
    return await gateway.getNonce(userAddress);
  }

  // Get user's gas credit balance
  async getCreditBalance(userAddress: string): Promise<bigint> {
    const vault = this.getGasCreditVault();
    return await vault.getCreditBalance(userAddress);
  }

  // Get token balance
  async getTokenBalance(userAddress: string, tokenSymbol: string): Promise<bigint> {
    const token = this.getTokenContract(tokenSymbol);
    return await token.balanceOf(userAddress);
  }

  // Get token allowance
  async getTokenAllowance(
    userAddress: string,
    spenderAddress: string,
    tokenSymbol: string
  ): Promise<bigint> {
    const token = this.getTokenContract(tokenSymbol);
    return await token.allowance(userAddress, spenderAddress);
  }
}
```

### Meta-Transaction Hook

```typescript
// hooks/useMetaTransaction.ts
import { useState } from 'react';
import { ethers } from 'ethers';
import { ContractService } from '../services/contractService';
import { SigningService } from '../services/signingService';
import { RelayerService } from '../services/relayerService';

export interface MetaTransaction {
  to: string;
  value: bigint;
  data: string;
  nonce: bigint;
  deadline: bigint;
}

export interface MetaTransactionWithSignature extends MetaTransaction {
  signature: string;
}

interface MetaTransactionState {
  isLoading: boolean;
  error: string | null;
  txHash: string | null;
}

export const useMetaTransaction = (
  contractService: ContractService,
  signingService: SigningService,
  relayerService: RelayerService
) => {
  const [state, setState] = useState<MetaTransactionState>({
    isLoading: false,
    error: null,
    txHash: null
  });

  const executeMetaTransaction = async (
    userAddress: string,
    transactions: Omit<MetaTransaction, 'nonce' | 'deadline'>[]
  ) => {
    setState({ isLoading: true, error: null, txHash: null });

    try {
      // Get user's current nonce
      const nonce = await contractService.getUserNonce(userAddress);
      
      // Set deadline (5 minutes from now)
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 300);

      // Prepare transactions with nonce and deadline
      const metaTransactions: MetaTransaction[] = transactions.map((tx, index) => ({
        ...tx,
        nonce: nonce + BigInt(index),
        deadline
      }));

      // Sign transactions
      const signedTransactions: MetaTransactionWithSignature[] = await Promise.all(
        metaTransactions.map(async (tx) => {
          const signature = await signingService.signMetaTransaction(tx, userAddress);
          return { ...tx, signature };
        })
      );

      // Submit to relayer
      const txHash = await relayerService.submitMetaTransactions(
        userAddress,
        signedTransactions
      );

      setState({ isLoading: false, error: null, txHash });
      return txHash;
    } catch (error: any) {
      const errorMessage = error.message || 'Failed to execute meta-transaction';
      setState({ isLoading: false, error: errorMessage, txHash: null });
      throw error;
    }
  };

  const resetState = () => {
    setState({ isLoading: false, error: null, txHash: null });
  };

  return {
    ...state,
    executeMetaTransaction,
    resetState
  };
};
```

## Transaction Signing

### Signing Service

```typescript
// services/signingService.ts
import { ethers } from 'ethers';
import { MetaTransaction } from '../hooks/useMetaTransaction';

export class SigningService {
  private signer: ethers.JsonRpcSigner;
  private domain: ethers.TypedDataDomain;

  constructor(signer: ethers.JsonRpcSigner, chainId: number, verifyingContract: string) {
    this.signer = signer;
    this.domain = {
      name: 'MetaTxGateway',
      version: '2.0.0',
      chainId,
      verifyingContract
    };
  }

  private getMetaTransactionTypes() {
    return {
      MetaTransaction: [
        { name: 'to', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'data', type: 'bytes' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
      ]
    };
  }

  async signMetaTransaction(transaction: MetaTransaction, userAddress: string): Promise<string> {
    try {
      // Verify signer address matches user address
      const signerAddress = await this.signer.getAddress();
      if (signerAddress.toLowerCase() !== userAddress.toLowerCase()) {
        throw new Error('Signer address does not match user address');
      }

      // Sign using EIP-712
      const signature = await this.signer.signTypedData(
        this.domain,
        this.getMetaTransactionTypes(),
        {
          to: transaction.to,
          value: transaction.value.toString(),
          data: transaction.data,
          nonce: transaction.nonce.toString(),
          deadline: transaction.deadline.toString()
        }
      );

      return signature;
    } catch (error) {
      console.error('Failed to sign meta-transaction:', error);
      throw error;
    }
  }

  // Verify signature (for testing)
  async verifySignature(
    transaction: MetaTransaction,
    signature: string,
    expectedSigner: string
  ): Promise<boolean> {
    try {
      const recoveredAddress = ethers.verifyTypedData(
        this.domain,
        this.getMetaTransactionTypes(),
        {
          to: transaction.to,
          value: transaction.value.toString(),
          data: transaction.data,
          nonce: transaction.nonce.toString(),
          deadline: transaction.deadline.toString()
        },
        signature
      );

      return recoveredAddress.toLowerCase() === expectedSigner.toLowerCase();
    } catch (error) {
      console.error('Failed to verify signature:', error);
      return false;
    }
  }
}
```

## Relayer Integration

### Relayer Service

```typescript
// services/relayerService.ts
import { MetaTransactionWithSignature } from '../hooks/useMetaTransaction';

export interface RelayerResponse {
  success: boolean;
  txHash?: string;
  error?: string;
  estimatedGas?: string;
}

export class RelayerService {
  private baseUrl: string;
  private apiKey?: string;

  constructor(baseUrl: string, apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  private getHeaders() {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    return headers;
  }

  async submitMetaTransactions(
    userAddress: string,
    transactions: MetaTransactionWithSignature[]
  ): Promise<string> {
    try {
      const response = await fetch(`${this.baseUrl}/meta-transactions`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({
          userAddress,
          transactions: transactions.map(tx => ({
            to: tx.to,
            value: tx.value.toString(),
            data: tx.data,
            nonce: tx.nonce.toString(),
            deadline: tx.deadline.toString(),
            signature: tx.signature
          }))
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP ${response.status}`);
      }

      const data: RelayerResponse = await response.json();
      
      if (!data.success || !data.txHash) {
        throw new Error(data.error || 'Failed to submit transactions');
      }

      return data.txHash;
    } catch (error) {
      console.error('Relayer submission failed:', error);
      throw error;
    }
  }

  async estimateGas(
    userAddress: string,
    transactions: MetaTransactionWithSignature[]
  ): Promise<string> {
    try {
      const response = await fetch(`${this.baseUrl}/meta-transactions/estimate`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({
          userAddress,
          transactions: transactions.map(tx => ({
            to: tx.to,
            value: tx.value.toString(),
            data: tx.data,
            nonce: tx.nonce.toString(),
            deadline: tx.deadline.toString(),
            signature: tx.signature
          }))
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data: RelayerResponse = await response.json();
      
      if (!data.success || !data.estimatedGas) {
        throw new Error(data.error || 'Failed to estimate gas');
      }

      return data.estimatedGas;
    } catch (error) {
      console.error('Gas estimation failed:', error);
      throw error;
    }
  }

  async getTransactionStatus(txHash: string): Promise<any> {
    try {
      const response = await fetch(`${this.baseUrl}/transactions/${txHash}`, {
        headers: this.getHeaders()
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Failed to get transaction status:', error);
      throw error;
    }
  }
}
```

## Gas Credits Management

### Gas Credits Hook

```typescript
// hooks/useGasCredits.ts
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { ContractService } from '../services/contractService';

interface GasCreditsState {
  balance: bigint;
  isLoading: boolean;
  error: string | null;
}

export const useGasCredits = (
  contractService: ContractService,
  userAddress: string | null
) => {
  const [state, setState] = useState<GasCreditsState>({
    balance: 0n,
    isLoading: false,
    error: null
  });

  const fetchBalance = async () => {
    if (!userAddress) return;

    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const balance = await contractService.getCreditBalance(userAddress);
      setState({ balance, isLoading: false, error: null });
    } catch (error: any) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error.message || 'Failed to fetch balance'
      }));
    }
  };

  const depositCredits = async (tokenSymbol: string, amount: string) => {
    if (!userAddress) throw new Error('User not connected');

    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const tokenContract = contractService.getTokenContract(tokenSymbol, true);
      const vault = contractService.getGasCreditVault(true);
      const tokenDecimals = await tokenContract.decimals();
      const parsedAmount = ethers.parseUnits(amount, tokenDecimals);

      // Check allowance
      const allowance = await contractService.getTokenAllowance(
        userAddress,
        contractService.addresses.gasCreditVault,
        tokenSymbol
      );

      // Approve if needed
      if (allowance < parsedAmount) {
        const approveTx = await tokenContract.approve(
          contractService.addresses.gasCreditVault,
          parsedAmount
        );
        await approveTx.wait();
      }

      // Deposit
      const depositTx = await vault.depositCredits(
        contractService.addresses.tokens[tokenSymbol],
        parsedAmount
      );
      await depositTx.wait();

      // Refresh balance
      await fetchBalance();
    } catch (error: any) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error.message || 'Failed to deposit credits'
      }));
      throw error;
    }
  };

  const transferCredits = async (toAddress: string, amount: string) => {
    if (!userAddress) throw new Error('User not connected');

    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const vault = contractService.getGasCreditVault(true);
      const parsedAmount = ethers.parseEther(amount);

      const transferTx = await vault.transferCredits(toAddress, parsedAmount);
      await transferTx.wait();

      // Refresh balance
      await fetchBalance();
    } catch (error: any) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error.message || 'Failed to transfer credits'
      }));
      throw error;
    }
  };

  useEffect(() => {
    if (userAddress) {
      fetchBalance();
    }
  }, [userAddress]);

  return {
    ...state,
    fetchBalance,
    depositCredits,
    transferCredits
  };
};
```

## React Components

### Meta-Transaction Form

```typescript
// components/MetaTransactionForm.tsx
import React, { useState } from 'react';
import { ethers } from 'ethers';
import { useMetaTransaction } from '../hooks/useMetaTransaction';
import { useGasCredits } from '../hooks/useGasCredits';

interface Props {
  userAddress: string;
  contractService: any;
  signingService: any;
  relayerService: any;
}

export const MetaTransactionForm: React.FC<Props> = ({
  userAddress,
  contractService,
  signingService,
  relayerService
}) => {
  const [toAddress, setToAddress] = useState('');
  const [value, setValue] = useState('');
  const [data, setData] = useState('0x');

  const { executeMetaTransaction, isLoading, error, txHash } = useMetaTransaction(
    contractService,
    signingService,
    relayerService
  );

  const { balance: creditBalance } = useGasCredits(contractService, userAddress);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const transactions = [{
        to: toAddress,
        value: ethers.parseEther(value || '0'),
        data: data || '0x'
      }];

      await executeMetaTransaction(userAddress, transactions);
    } catch (error) {
      console.error('Transaction failed:', error);
    }
  };

  return (
    <div className="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
      <h2 className="text-2xl font-bold mb-4">Submit Meta-Transaction</h2>
      
      <div className="mb-4 p-3 bg-gray-100 rounded">
        <p className="text-sm text-gray-600">
          Gas Credits: {ethers.formatEther(creditBalance)} credits
        </p>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2">
            To Address
          </label>
          <input
            type="text"
            value={toAddress}
            onChange={(e) => setToAddress(e.target.value)}
            placeholder="0x..."
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:border-blue-500"
            required
          />
        </div>

        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2">
            Value (ETH)
          </label>
          <input
            type="number"
            step="0.000000000000000001"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            placeholder="0.0"
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:border-blue-500"
          />
        </div>

        <div className="mb-6">
          <label className="block text-gray-700 text-sm font-bold mb-2">
            Data (Hex)
          </label>
          <textarea
            value={data}
            onChange={(e) => setData(e.target.value)}
            placeholder="0x"
            rows={3}
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:border-blue-500"
          />
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}

        {txHash && (
          <div className="mb-4 p-3 bg-green-100 border border-green-400 text-green-700 rounded">
            Transaction submitted: {txHash}
          </div>
        )}

        <button
          type="submit"
          disabled={isLoading || !toAddress}
          className={`w-full py-2 px-4 rounded-lg font-bold text-white ${
            isLoading || !toAddress
              ? 'bg-gray-400 cursor-not-allowed'
              : 'bg-blue-500 hover:bg-blue-700'
          }`}
        >
          {isLoading ? 'Submitting...' : 'Submit Transaction'}
        </button>
      </form>
    </div>
  );
};
```

### Gas Credits Manager

```typescript
// components/GasCreditsManager.tsx
import React, { useState } from 'react';
import { ethers } from 'ethers';
import { useGasCredits } from '../hooks/useGasCredits';

interface Props {
  userAddress: string;
  contractService: any;
}

export const GasCreditsManager: React.FC<Props> = ({
  userAddress,
  contractService
}) => {
  const [depositAmount, setDepositAmount] = useState('');
  const [selectedToken, setSelectedToken] = useState('USDT');
  const [transferAddress, setTransferAddress] = useState('');
  const [transferAmount, setTransferAmount] = useState('');

  const {
    balance,
    isLoading,
    error,
    depositCredits,
    transferCredits
  } = useGasCredits(contractService, userAddress);

  const handleDeposit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await depositCredits(selectedToken, depositAmount);
      setDepositAmount('');
    } catch (error) {
      console.error('Deposit failed:', error);
    }
  };

  const handleTransfer = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await transferCredits(transferAddress, transferAmount);
      setTransferAddress('');
      setTransferAmount('');
    } catch (error) {
      console.error('Transfer failed:', error);
    }
  };

  return (
    <div className="max-w-2xl mx-auto bg-white rounded-lg shadow-md p-6">
      <h2 className="text-2xl font-bold mb-6">Gas Credits Manager</h2>

      {/* Balance Display */}
      <div className="mb-6 p-4 bg-blue-50 rounded-lg">
        <h3 className="text-lg font-semibold text-blue-800">Current Balance</h3>
        <p className="text-2xl font-bold text-blue-600">
          {ethers.formatEther(balance)} credits
        </p>
      </div>

      {/* Deposit Section */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-4">Deposit Credits</h3>
        <form onSubmit={handleDeposit} className="space-y-4">
          <div className="flex space-x-4">
            <select
              value={selectedToken}
              onChange={(e) => setSelectedToken(e.target.value)}
              className="px-3 py-2 border rounded-lg focus:outline-none focus:border-blue-500"
            >
              <option value="USDT">USDT</option>
              <option value="USDC">USDC</option>
              <option value="BUSD">BUSD</option>
            </select>
            
            <input
              type="number"
              step="0.000001"
              value={depositAmount}
              onChange={(e) => setDepositAmount(e.target.value)}
              placeholder="Amount"
              className="flex-1 px-3 py-2 border rounded-lg focus:outline-none focus:border-blue-500"
              required
            />
          </div>
          
          <button
            type="submit"
            disabled={isLoading || !depositAmount}
            className={`w-full py-2 px-4 rounded-lg font-bold text-white ${
              isLoading || !depositAmount
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-green-500 hover:bg-green-700'
            }`}
          >
            {isLoading ? 'Processing...' : 'Deposit Credits'}
          </button>
        </form>
      </div>

      {/* Transfer Section */}
      <div className="mb-6">
        <h3 className="text-lg font-semibold mb-4">Transfer Credits</h3>
        <form onSubmit={handleTransfer} className="space-y-4">
          <input
            type="text"
            value={transferAddress}
            onChange={(e) => setTransferAddress(e.target.value)}
            placeholder="Recipient address (0x...)"
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:border-blue-500"
            required
          />
          
          <input
            type="number"
            step="0.000000000000000001"
            value={transferAmount}
            onChange={(e) => setTransferAmount(e.target.value)}
            placeholder="Amount in credits"
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:border-blue-500"
            required
          />
          
          <button
            type="submit"
            disabled={isLoading || !transferAddress || !transferAmount}
            className={`w-full py-2 px-4 rounded-lg font-bold text-white ${
              isLoading || !transferAddress || !transferAmount
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-purple-500 hover:bg-purple-700'
            }`}
          >
            {isLoading ? 'Processing...' : 'Transfer Credits'}
          </button>
        </form>
      </div>

      {/* Error Display */}
      {error && (
        <div className="p-3 bg-red-100 border border-red-400 text-red-700 rounded">
          {error}
        </div>
      )}
    </div>
  );
};
```

## Configuration

### Environment Variables

```typescript
// utils/config.ts
export const CONFIG = {
  // Contract addresses
  CONTRACTS: {
    BSC_MAINNET: {
      metaTxGateway: process.env.REACT_APP_METATX_GATEWAY_BSC || '',
      gasCreditVault: process.env.REACT_APP_GAS_CREDIT_VAULT_BSC || '',
      tokens: {
        USDT: process.env.REACT_APP_USDT_BSC || '0x55d398326f99059fF775485246999027B3197955',
        USDC: process.env.REACT_APP_USDC_BSC || '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
        BUSD: process.env.REACT_APP_BUSD_BSC || '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56'
      }
    },
    BSC_TESTNET: {
      metaTxGateway: process.env.REACT_APP_METATX_GATEWAY_TESTNET || '',
      gasCreditVault: process.env.REACT_APP_GAS_CREDIT_VAULT_TESTNET || '',
      tokens: {
        USDT: process.env.REACT_APP_USDT_TESTNET || '',
        USDC: process.env.REACT_APP_USDC_TESTNET || '',
        BUSD: process.env.REACT_APP_BUSD_TESTNET || ''
      }
    }
  },
  
  // Relayer configuration
  RELAYER: {
    BASE_URL: process.env.REACT_APP_RELAYER_URL || 'http://localhost:3001',
    API_KEY: process.env.REACT_APP_RELAYER_API_KEY
  },
  
  // Network configuration
  NETWORKS: {
    BSC_MAINNET: 56,
    BSC_TESTNET: 97
  }
};

export const getContractAddresses = (chainId: number) => {
  switch (chainId) {
    case 56:
      return CONFIG.CONTRACTS.BSC_MAINNET;
    case 97:
      return CONFIG.CONTRACTS.BSC_TESTNET;
    default:
      throw new Error(`Unsupported chain ID: ${chainId}`);
  }
};
```

## Error Handling

### Error Types

```typescript
// types/errors.ts
export enum ErrorType {
  WALLET_NOT_CONNECTED = 'WALLET_NOT_CONNECTED',
  NETWORK_NOT_SUPPORTED = 'NETWORK_NOT_SUPPORTED',
  INSUFFICIENT_CREDITS = 'INSUFFICIENT_CREDITS',
  SIGNATURE_FAILED = 'SIGNATURE_FAILED',
  RELAYER_ERROR = 'RELAYER_ERROR',
  CONTRACT_ERROR = 'CONTRACT_ERROR',
  TRANSACTION_FAILED = 'TRANSACTION_FAILED'
}

export class MetaTxError extends Error {
  public type: ErrorType;
  public details?: any;

  constructor(type: ErrorType, message: string, details?: any) {
    super(message);
    this.type = type;
    this.details = details;
    this.name = 'MetaTxError';
  }
}

export const handleError = (error: any): string => {
  if (error instanceof MetaTxError) {
    switch (error.type) {
      case ErrorType.WALLET_NOT_CONNECTED:
        return 'Please connect your wallet to continue';
      case ErrorType.NETWORK_NOT_SUPPORTED:
        return 'Please switch to a supported network (BSC)';
      case ErrorType.INSUFFICIENT_CREDITS:
        return 'Insufficient gas credits. Please deposit more credits.';
      case ErrorType.SIGNATURE_FAILED:
        return 'Transaction signature failed. Please try again.';
      case ErrorType.RELAYER_ERROR:
        return 'Relayer service error. Please try again later.';
      default:
        return error.message;
    }
  }

  // Handle common web3 errors
  if (error.code === 4001) {
    return 'Transaction rejected by user';
  }
  
  if (error.code === -32002) {
    return 'Request already pending. Please wait.';
  }

  return error.message || 'An unexpected error occurred';
};
```

## Testing

### Unit Tests

```typescript
// __tests__/useMetaTransaction.test.ts
import { renderHook, act } from '@testing-library/react-hooks';
import { useMetaTransaction } from '../hooks/useMetaTransaction';

describe('useMetaTransaction', () => {
  it('should execute meta-transaction successfully', async () => {
    // Test implementation
  });

  it('should handle execution errors', async () => {
    // Test error handling
  });
});
```

### Integration Tests

```typescript
// __tests__/integration.test.ts
import { render, screen, fireEvent } from '@testing-library/react';
import { MetaTransactionForm } from '../components/MetaTransactionForm';

describe('Integration Tests', () => {
  it('should submit meta-transaction end-to-end', async () => {
    // Test complete flow
  });
});
```

## Best Practices

### Security

1. **Validate Inputs**: Always validate user inputs before signing
2. **Check Deadlines**: Ensure transaction deadlines are reasonable
3. **Verify Signatures**: Validate signatures client-side before submission
4. **Handle Errors Gracefully**: Provide clear error messages to users

### Performance

1. **Cache Contract Instances**: Reuse contract instances where possible
2. **Batch Transactions**: Combine multiple operations when feasible
3. **Optimize Gas Estimation**: Cache gas estimates for similar transactions
4. **Use Loading States**: Provide feedback during async operations

### User Experience

1. **Clear Status Updates**: Show transaction progress to users
2. **Estimate Costs**: Display gas costs before execution
3. **Fallback Options**: Provide alternatives if meta-transactions fail
4. **Mobile Responsive**: Ensure compatibility across devices

{% hint style="success" %}
**Integration Complete!** Your frontend application is now ready to handle meta-transactions with gas credits. 🚀
{% endhint %}

## Next Steps

- **[Relayer Integration](relayer-integration.md)** - Set up your relayer service
- **[API Reference](../api/frontend.md)** - Detailed API documentation
- **[Troubleshooting](../guides/troubleshooting.md)** - Common issues and solutions
