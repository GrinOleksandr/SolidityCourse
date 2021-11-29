//https://rinkeby.etherscan.io/address/0x18DAF3C01573B827A067BFd02349B0d5588242aB
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SGRN is ERC20 {
    constructor(uint256 initialSupply) ERC20("SashaGrin", "SGRN") {
        _mint(msg.sender, initialSupply);
    }
}