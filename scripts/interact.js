import { ethers } from "ethers";

// 使用 AbiCoder（v6 是 ethers.AbiCoder.from()）
const abiCoder = ethers.AbiCoder.defaultAbiCoder();

// 定義型別與值
const types = ["uint256[]", "uint256[]", "uint256[]", "uint256", "uint256", "address"];
const values = [
  [11155111],
  [100000],
  [0],
  1743878343,
  84532,
  "0x55F574536032599068C2Ce9E73f18d244345E262"
];

// ABI encode 並計算 keccak256
const encoded = abiCoder.encode(types, values);
const messageHash = ethers.keccak256(encoded);

console.log("Encoded:", encoded);
console.log("Message Hash:", messageHash);