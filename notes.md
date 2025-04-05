# Project Ideas

## Project Name: **Just Pay**(?)
## Project Goals
> With Circle's latest CCTPv2, which offers a `fast transfer` feature for users to cross their USDC 1:1 through chains **JUST IN SECONDS**. We can literally leverage this protocol to build a payment system which achieve the goal of `chain abstraction` and also a seamless user experience just like Line Pay, a Web2 service which is super popular in Taiwan.
1. `Just Pay` lets `users (consumer)` not to concern whatever chain they are using to receive or transfer USDC. They just need to concern how much USDC they are gonna send, and with one-click, "BOOM", Done! An extremely truly `USDC as a service` experience.
2. `receivers` are able to create a QR Code for users to pay
   - Generate a one-tme QR Code with the amount to receive
   - Generate a long-term QR Code for `consumers` to scan and input the amount manually to pay.
3. (Optional) `Receivers` get a notification once transaction has done. (Not sure if it is possible with web dapp, or maybe t's possible to build a PWA(Well, maybe for the final project in class))

## Implementation Details
### Smart Contract
Since Linea doesn't support the latest version of EVM, the contract compiled config:
```javascript
solidity: {
    version: "0.8.17",
    settings: {
      evmVersion: "london",
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    }
  }
```
  You need specified version of openzeppelin library
  ```
  npm install @openzeppelin/contracts@4.9.6
  ```
1. `Factory`
   1. `Factory` Leverages **Create2** to deploy `JustPay` contract
   2. Should assign `user`(or/and `operator`) as the owner of`Justpay` contract
   3. Needs to be deployed on `Ethereum Sepolia`, `Base Sepolia`, `Avalanche Fuji`, `Linea Sepolia`
2. `JustPay`
   1. Every transations should only be executed with `user's signature` and by `operatorKey`
   2. `function withdrawEth(address user, uint256 amount) // you don't want to stuck your ETH`
   3. `transferUSDC()`
   4. `transferUSDCviaCCTPv2()`??
   5. `transferToken(address token, address user, uint256 amount) // you don't want to stuck any other token in the contract`
   6. `signatureChecker(...)` to be research how it works
   7. **How to interact with CCTP v2**
3. (Optional) JustPayProxy
   1. for contract upgrade.
   2. Not necessary in MVP

#### Testnet Deployments
1. ETH Sepolia (tested!)
https://sepolia.etherscan.io/address/0x49aa018dC29772561795E13a09aCA3DaAF4777Be
2. Base Sepolia (tested!)
https://sepolia.basescan.org/address/0x49aa018dC29772561795E13a09aCA3DaAF4777Be
3. Avalanche Fuji (tested!)
https://testnet.snowtrace.io/address/0x49aa018dC29772561795E13a09aCA3DaAF4777Be/contract/43113
4. Linea Sepolia (tested!)
https://sepolia.lineascan.build/address/address/0x49aa018dC29772561795E13a09aCA3DaAF4777Be

### Frontend
1. **Able to connect to wallet, some references:**
   1. WalletConnect https://docs.reown.com/
   2. Rainbow Kit https://www.rainbowkit.com/
2. Able to show the USDC balance sums (through 4 testnet chains)
3. **Able to interact with smart contracts accordingly**
4. Able to create a long-term QR Code for others to pay
5. Able to create a one-time QR Code for others to pay
6. Able to scan a QR Code which then trigger a transaction
7. **Able to make user sign with their wallet**

### Backend
1. Able to scan all the addresses that belongs to the wallet connected **(frontend?)**
2. Holds an `OperatorKey` to execute whatever users signed
3. Listen to every `user`s' transaction request

### Problems to be solved
1. Gas fee
   - (X) `Users` top-up gas fee to `operator` manually on every chain (UX Sucks)
   - (△) Introduce [Paymaster](#circle---enable-end-users-to-pay-for-gas-using-usdc) from CCTPv2
     - Worth to try: Initially top up some USDC to `operator`, and every time
     - ~~Another chance to win a Hackathon bounty~~
   - (O) Everytime a `user` create a `Just Pay` accounrt through `Factory`, the UI automatically guides `users` to send a little amount of ETH into `operator`.
     - (for future) The system(eg. backend) should record how much gas a `user` has spent and left.
2. How to create the `signature` mechanism?
3. How to trigger `CCTPv2` onchain?

## Prizes to submit：
#### **Circle - Build a Multichain USDC Payment System**
> Up to 2 teams will receive $2,000
- Description
  - Build an application that enables multichain USDC payments and payouts using Fast Transfers from CCTP V2. *Please note that CCTP V2 currently supports Ethereum, Avalanche and Base.
- Example Use Cases
1. Liquidity Provider Intent System - Enable liquidity providers to send and receive USDC across multiple chains.
2. Multichain Treasury Management - Help businesses manage USDC balances across multiple chains
3. Universal Merchant Payment Gateway – Implement a multi-chain checkout system for merchants to accept USDC payments across various blockchains which rebalance to desired chain via CCTP V2.

### Additional
> If time is enough to implement
#### **Circle - Enable end users to pay for gas using USDC**
> $2,000
- Description
	- Develop an application that enables users to **pay network fees in USDC** instead of native tokens by leveraging Circle Paymaster. *Please note that Circle Paymaster currently supports Arbitrum and Base*
- Example Use Cases
1. DeFi Protocols - Enable USDC as the default gas payment token for transaction activitiy in dApps like Lido, AAVE, etc..
2. Simplified transactions - Make it easier for users to perform transactions in USDC or other tokens while network fees are paid from their USDC balance.

#### **Circle - Implement Hooks for CCTP V2 Transfers**
> $2,000
- Description
	- Develop an application that automates follow-on actions after a cross-chain USDC transfer by leveraging CCTP Hooks, enabling seamles, programmable workflows.



## CCTP V2

### Test CCTP v2 transaction
User transfers 1 USDC from Base to Avalanche
1. source transaction(from Base)
https://basescan.org/tx/0x262987d9e9cc5a0579f4995da5780e36d826053428281d4a81d3e722012c34e3


| #   | Name                 | Type    | Data                                                               |
| --- | -------------------- | ------- | ------------------------------------------------------------------ |
| 0   | amount               | uint256 | 1000000                                                            |
| 1   | destinationDomain    | uint32  | 1                                                                  |
| 2   | mintRecipient        | bytes32 | 0x0000000000000000000000005c2632cedb167609c7f12e9bbfbc5665cfd66d40 |
| 3   | burnToken            | address | 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913                         |
| 4   | destinationCaller    | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
| 5   | maxFee               | uint256 | 100                                                                |
| 6   | minFinalityThreshold | uint32  | 500                                                                |


2. Circle Iris attestation and message(you need these info to receive transfered USDC)
https://iris-api.circle.com/v2/messages/6?transactionHash=0x262987d9e9cc5a0579f4995da5780e36d826053428281d4a81d3e722012c34e3

```json
{"messages":[{"attestation":"0x16cb98f66ee534db19669a851eadc319a6da1070a8e8352cd7b6744aa7a6781a6d840dbbe1c69963f3d519bc0a8c1ed5ce5f649c86b4cad008cbca0d097a364a1c121405ac78591a5e279311fe07cf1c0fb89e3ade79ae4082efe67a38be72d7e93854ee341ec9ff80bd87e884dfdc37b6803d0c40ac83a08b9220e26d20b3b6ff1b","message":"0x000000010000000600000001be761cca8a69cb0e710f3c765ca929dacd58ab31238952b2889b406f6406866b00000000000000000000000028b5a0e9c621a5badaa536219b3a228c8168cf5d00000000000000000000000028b5a0e9c621a5badaa536219b3a228c8168cf5d0000000000000000000000000000000000000000000000000000000000000000000001f4000003e800000001000000000000000000000000833589fcd6edb6e08f4c7c32d4f71b54bda029130000000000000000000000005c2632cedb167609c7f12e9bbfbc5665cfd66d4000000000000000000000000000000000000000000000000000000000000f42400000000000000000000000005c2632cedb167609c7f12e9bbfbc5665cfd66d4000000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000388a9f0","eventNonce":"0xbe761cca8a69cb0e710f3c765ca929dacd58ab31238952b2889b406f6406866b","cctpVersion":2,"status":"complete"}]}
```

3. destination transaction(to Avalanche)
https://snowtrace.io/tx/0xfd099dd6849803a1179211854a5b6b2ed37d4cfad9fc8b70136af35984d5a148?chainid=43114
input data same as above(`attestation` and `message`)

## Signature

1. Solidity sample code
https://solidity-by-example.org/signature/

2. Javascript sample code
https://github.com/t4sk/hello-erc20-permit/blob/main/test/verify-signature.js


## Reference
1. Circle relevant contract addresses onchain https://developers.circle.com/stablecoins/evm-smart-contracts
2. USDC Faucet https://faucet.circle.com/
3. Circle github https://github.com/circlefin/evm-cctp-contracts/tree/master
4. Openzeppelin for cryptography https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
5. Testnet faucets


|     Chain      | Gas Token | Chain ID    |
|:--------------:|:---------:| --- |
|  ETH Sepolia   |    ETH    |  111555111   |
|  Base Sepolia  |    ETH    |     |
| Avalanche Fuji |   AVAX    |     |
| Linea Sepolia  |    ETH    |     |

- https://cloud.google.com/application/web3/faucet/ethereum
- https://www.alchemy.com/faucets
- https://faucets.chain.link/fuji
- https://build.avax.network/docs/dapps/smart-contract-dev/get-test-funds


# Just Pay Factory Contract Address
0xBA2D4feEBFFec726b16C5eDc858ab2471A9752aF