//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(address _to, uint256 initialSupply) ERC20("Sasha Grin token", "SGRN") {
        _mint(_to, initialSupply * 10 ** 18);
    }
}