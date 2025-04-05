import { ethers } from "ethers";

// 使用 AbiCoder（v6 是 ethers.AbiCoder.from()）
const abiCoder = ethers.AbiCoder.defaultAbiCoder();

// 定義型別與值
const types = ["uint256[]", "uint256[]", "uint256[]", "uint256", "address"];
const values = [
    [84532],
    [100000],
    [1],
  1,
  "0x3d94E55a2C3Cf83226b3D056eBeBb43b4731417f"
];

// ABI encode 並計算 keccak256
const encoded = abiCoder.encode(types, values);
const messageHash = ethers.keccak256(encoded);

console.log("Encoded:", encoded);
console.log("Message Hash:", messageHash);