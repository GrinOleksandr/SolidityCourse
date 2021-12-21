const Vendor = artifacts.require('Vendor');
const Proxy = artifacts.require('ERC1967Proxy');
const VendorV2 = artifacts.require('VendorV2');

const sgrnTokenContractAddressRinkeby = '0x58F56eFb1Bc4D0c566c493E019EE7dDcc987f720';
const daiTokenContractAddressRinkeby = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
const sigmaNFTTokenAddressRinkeby = '0x515Dcbe2cCF7d159CBc7C74DA99DeeD04F671725';
const myNFTTokenId = 0;

module.exports = async function (deployer) {
  await deployer.deploy(Vendor);
  const implementationInstance = await Vendor.deployed();

  const data = await implementationInstance.contract.methods
    .initialize(
      sgrnTokenContractAddressRinkeby,
      daiTokenContractAddressRinkeby,
      sigmaNFTTokenAddressRinkeby,
      myNFTTokenId,
    )
    .encodeABI();

  await deployer.deploy(Proxy, implementationInstance.address, data);

  await deployer.deploy(VendorV2);
};
