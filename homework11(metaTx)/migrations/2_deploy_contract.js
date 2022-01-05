const Forwarder = artifacts.require('MinimalForwarder');
const Vendor = artifacts.require('Vendor');
// const Proxy = artifacts.require('ERC1967Proxy');

const sgrnTokenContractAddressRinkeby = '0x58F56eFb1Bc4D0c566c493E019EE7dDcc987f720';
const daiTokenContractAddressRinkeby = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
const minimalForwarderAddressRinkeby = '0x039a437431c2fEC0903e67112973787D8046e5AD';

module.exports = async function (deployer) {
  // await deployer.deploy(Forwarder);

  await deployer.deploy(
    Vendor,
    sgrnTokenContractAddressRinkeby,
    daiTokenContractAddressRinkeby,
    minimalForwarderAddressRinkeby,
  );
  // const implementationInstance = await Vendor.deployed();
  //
  // const data = await implementationInstance.contract.methods
  //     .initialize(sgrnTokenContractAddressRinkeby, daiTokenContractAddressRinkeby)
  //     .encodeABI();
  //
  // await deployer.deploy(Proxy, implementationInstance.address, data);
};
