//deployed at https://rinkeby.etherscan.io/address/0xc83fB147a980c2AD2901386Edd0EAa1530DBAe39#code

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(address _to, uint256 initialSupply) ERC20("Sasha Grin token", "SGRN") {
        _mint(_to, initialSupply * 10 ** 18);
    }
}