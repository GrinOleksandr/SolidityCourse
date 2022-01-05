//example deployed at https://kovan.etherscan.io/address/0xa95473557Fabc556E1C0C84d7de1aF058aCeC886#code

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

contract Vendor is Initializable, OwnableUpgradeable, UUPSUpgradeable    {
    event Log(string message);
    event LogBytes(bytes message);
    event RandomNumberUpdated(uint256 number);
    event MyTokensTransfered(uint256 number);
    event PriceUpdated(uint256 price);
    event BuyingTokens(address sender, uint256 amount,uint256 senderDaiBalance, uint256 vendorBalance, uint256  alowance );

    address aggregatorAddressFor_ETH_USD;
    address DAITokenContractAddress;
    address myTokenContractAddress;

    constructor (address tokenContractAddress, address _DAITokenContractAddress)  public initializer
    {
        DAITokenContractAddress = _DAITokenContractAddress;
        myTokenContractAddress = tokenContractAddress;
        aggregatorAddressFor_ETH_USD = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        _transferOwnership(msg.sender);
    }


    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function buyTokens() public payable {
        IERC20 myTokenContract = IERC20(myTokenContractAddress);
        uint256 tokenPrice = uint256(getLatestPrice(aggregatorAddressFor_ETH_USD)) / getStudentsAmount();
        uint256  amountOfTokensToBuy = msg.value/tokenPrice;

        if(myTokenContract.balanceOf(address(this)) < amountOfTokensToBuy){
            (bool success,) = msg.sender.call{value:msg.value}("Sorry, there is not enough tokens");
            require(success, "External call failed");
            return;
        }

        try myTokenContract.transfer(msg.sender, amountOfTokensToBuy) {
            emit Log("tokens transfered");
        } catch Error(string memory reason) {
            emit Log(reason);
        } catch (bytes memory reason) {
            emit LogBytes(reason);
        }
    }

    function buyTokensForDAI(uint256 amountToBuy) public {
        emit Log('tokens successfully bought');
        IERC20 DAITokenContract = IERC20(DAITokenContractAddress);
        IERC20 myTokenContract = IERC20(myTokenContractAddress);
        emit BuyingTokens(msg.sender, amountToBuy,DAITokenContract.balanceOf(msg.sender),myTokenContract.balanceOf(address(this)), DAITokenContract.allowance(msg.sender, address(this)));

        //        uint256 amountOfDAITokensToPay = amountToBuy;

        //        require(DAITokenContract.balanceOf(msg.sender) >= amountOfDAITokensToPay, "Sorry, you do not have enough DAI-tokens for swap");
        //        require(myTokenContract.balanceOf(address(this)) >= amountToBuy, "Sorry, there is not enough tokens on my balance");

        //        uint256 allowance = DAITokenContract.allowance(msg.sender, address(this));
        //        require(allowance >= amountToBuy, "Check the token allowance please");

        //        DAITokenContract.transferFrom(msg.sender, address(this), amountToBuy);
        //        myTokenContract.transfer(msg.sender, amountToBuy);

    }

    function getLatestPrice(address aggregatorAddress) internal returns (uint256){
        (,int price,,,) = AggregatorV3Interface(aggregatorAddress).latestRoundData();
        uint8 decimals = AggregatorV3Interface(aggregatorAddress).decimals();

        return uint256(price)/10**decimals;
    }

    function getStudentsAmount() internal view returns(uint256) {
        return 35;
    }
}