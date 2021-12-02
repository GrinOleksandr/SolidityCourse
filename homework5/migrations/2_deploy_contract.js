const TestToken = artifacts.require("TestToken");
const Vendor = artifacts.require("Vendor");

module.exports =async function (deployer) {

   await deployer.deploy(Vendor);
   const vendorInstance = await Vendor.deployed();

   await deployer.deploy(TestToken, vendorInstance.address, 1000000);
   const testTokenInstance = await TestToken.deployed();
   await vendorInstance.setTokenContractAddress(testTokenInstance.address);
};
