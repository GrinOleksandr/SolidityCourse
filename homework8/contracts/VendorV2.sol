//example deployed at

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface studentsInterface {
    function getStudentsList() external view returns (string[] memory studentsList);
}


contract VendorV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable   {
    address studentsContractAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
    address aggregatorAddressFor_ETH_USD = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address aggregatorAddressFor_DAI_USD = 0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;
    address DAITokenContractAddress;
    address myTokenContractAddress;
    address NFTTokenContractAddress;
    uint256 keyNftTokenId;


    modifier hasKeyNFTToken() {
        _isTokenHolder();
        _;
    }

    function initialize(address tokenContractAddress, address _DAITokenContractAddress, address nftTokenContractAddress, uint256 _keyNftTokenId) public initializer {
        studentsContractAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
        aggregatorAddressFor_ETH_USD = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        aggregatorAddressFor_DAI_USD = 0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;
        DAITokenContractAddress = _DAITokenContractAddress;
        myTokenContractAddress = tokenContractAddress;
        NFTTokenContractAddress = nftTokenContractAddress;
        keyNftTokenId = _keyNftTokenId;
        _transferOwnership(msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _isTokenHolder() internal view {
        IERC721 NFTTokenContract = IERC721(NFTTokenContractAddress);
        require(NFTTokenContract.ownerOf(keyNftTokenId) == msg.sender, "Sorry, you don't have a key to use this.");
    }

    function buyTokens() public payable hasKeyNFTToken {
        IERC20 myTokenContract = IERC20(myTokenContractAddress);
        uint256 tokenPrice = uint256(getLatestPrice(aggregatorAddressFor_ETH_USD)) / getStudentsAmount();
        uint256  amountOfTokensToBuy = msg.value/tokenPrice;

        if(myTokenContract.balanceOf(address(this)) < amountOfTokensToBuy){
            (bool success,) = msg.sender.call{value:msg.value}("Sorry, there is not enough tokens");
            require(success, "External call failed");
            return;
        }

        myTokenContract.transfer(msg.sender, amountOfTokensToBuy);
    }

    function buyTokensForDAI(uint256 amountToBuy) public hasKeyNFTToken {
        IERC20 DAITokenContract = IERC20(DAITokenContractAddress);
        IERC20 myTokenContract = IERC20(myTokenContractAddress);
        require(amountToBuy > 0, "Maybe you would like to buy something greater than 0?");

        uint256 amountOfDAITokensToPay = amountToBuy/uint256(getLatestPrice(aggregatorAddressFor_DAI_USD));

        require(DAITokenContract.balanceOf(msg.sender) >= amountOfDAITokensToPay, "Sorry, you do not have enough DAI-tokens for swap");
        require(myTokenContract.balanceOf(address(this)) >= amountToBuy, "Sorry, there is not enough tokens on my balance");

        uint256 allowance = DAITokenContract.allowance(msg.sender, address(this));
        require(allowance >= amountToBuy, "Check the token allowance please");

        DAITokenContract.transferFrom(msg.sender, address(this), amountToBuy);
        myTokenContract.transfer(msg.sender, amountToBuy);
    }

    function getLatestPrice(address aggregatorAddress) internal view returns (uint256){
        (,int price,,,) = AggregatorV3Interface(aggregatorAddress).latestRoundData();
        uint8 decimals = AggregatorV3Interface(aggregatorAddress).decimals();
        return uint256(price)/10**decimals;
    }

    function getStudentsAmount() internal view returns(uint256) {
        string[] memory studentsList = studentsInterface(studentsContractAddress).getStudentsList();
        return studentsList.length;
    }
}