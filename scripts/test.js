const { Interface } = require("ethers");

const iface = new Interface(["function ignite()"]);
const sighash = iface.getFunction("ignite").selector;

console.log(sighash);  // e.g. 0x8f4ffcb1