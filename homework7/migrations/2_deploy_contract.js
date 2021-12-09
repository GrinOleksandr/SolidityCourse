// const Vendor = artifacts.require("Vendor");
const SashaNFTToken = artifacts.require("SashaNFTToken");

module.exports =async function (deployer) {
   // await deployer.deploy(Vendor,'0x58F56eFb1Bc4D0c566c493E019EE7dDcc987f720', '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa');

   await deployer.deploy(SashaNFTToken);
};
