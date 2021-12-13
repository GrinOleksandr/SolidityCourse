//this is MOCK NFT-token

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MockNFTToken is ERC721URIStorage {
    constructor(uint256 tokenId) ERC721("MOCK Sasha Grin NFT", "MOCK_SGNFT") public {
        _mint(msg.sender, tokenId);
    }
}