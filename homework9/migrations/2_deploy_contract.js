const Vendor = artifacts.require('Vendor');
const Proxy = artifacts.require('ERC1967Proxy');
const VendorV2 = artifacts.require('VendorV2');
const TestToken = artifacts.require('TestToken');

// const sgrnTokenContractAddressRinkeby = '0x58F56eFb1Bc4D0c566c493E019EE7dDcc987f720';
// const daiTokenContractAddressRinkeby = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
// const sigmaNFTTokenAddressRinkeby = '0x515Dcbe2cCF7d159CBc7C74DA99DeeD04F671725';
// const myNFTTokenId = 0;

const sgrnTokenContractAddressKovan = '0x8e2892D455D8bbdDE5bE2D8D14A1F9416d6fa2F1';
const daiTokenContractAddressKovan = '0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa';

module.exports = async function (deployer) {
  // await deployer.deploy(TestToken, 10000000000);

  await deployer.deploy(Vendor, sgrnTokenContractAddressKovan, daiTokenContractAddressKovan);
  const implementationInstance = await Vendor.deployed();

  // const data = await implementationInstance.contract.methods
  //   .initialize(sgrnTokenContractAddressKovan, daiTokenContractAddressKovan)
  //   .encodeABI();

  // await deployer.deploy(Proxy, implementationInstance.address, data);
  //
  // await deployer.deploy(VendorV2);
};
