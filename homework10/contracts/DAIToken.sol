//deployed at https://rinkeby.etherscan.io/address/0x58F56eFb1Bc4D0c566c493E019EE7dDcc987f720

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAIToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Mock DAI token", "DAI") {
        _mint(msg.sender, initialSupply * 10 ** 18);
    }
}