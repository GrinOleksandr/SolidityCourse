const Vendor = artifacts.require("Vendor");

module.exports =async function (deployer) {
   await deployer.deploy(Vendor,'0x58F56eFb1Bc4D0c566c493E019EE7dDcc987f720');
};
