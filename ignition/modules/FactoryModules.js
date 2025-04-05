const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("FactoryModules", (m) => {

  const Factory = m.contract("Factory");

  //const target = m.call(Factory, "computeAddress", [0]);

  //const deployed = m.call(Factory, "deploy", [0]);

  //const testToken = m.contract("TestToken");
  //const lock = m.contract("Lock", [startTime, endTime]);

  //const setLockTx = m.call(rewardToken, "setLockContract", [lock]);
  //m.call(lock, "mintReward", [rewardToken], { after: [setLockTx] });
  
  return { Factory};
});