const Vendor = artifacts.require('Vendor');
const Proxy = artifacts.require('ERC1967Proxy');

const sgrnTokenContractAddressKovan = '0x8e2892D455D8bbdDE5bE2D8D14A1F9416d6fa2F1';
const daiTokenContractAddressKovan = '0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa';

module.exports = async function (deployer) {
  await deployer.deploy(Vendor);
  const implementationInstance = await Vendor.deployed();

  const data = await implementationInstance.contract.methods
    .initialize(sgrnTokenContractAddressKovan, daiTokenContractAddressKovan)
    .encodeABI();

  await deployer.deploy(Proxy, implementationInstance.address, data);
};
