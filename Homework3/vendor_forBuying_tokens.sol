//https://rinkeby.etherscan.io/address/0xCC911935F295F1C9032F3401e45fc6C382db370c#code

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transferFrom(
address sender,
address recipient,
uint256 amount
) external returns (bool);
function transfer(address recipient, uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface studentsInterface {
function getStudentsList() external view returns (string[] memory studentsList);
}

contract DEX3 {
address tokenContract = 0x18DAF3C01573B827A067BFd02349B0d5588242aB;
address studentsContractAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
AggregatorV3Interface internal priceFeed;



constructor() {
priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
}

function buyTokens() public payable {
uint256  studentsAmount = getStudentsAmount();
int  latestPrice = getLatestPrice()/100000000;
uint256 tokenPrice = uint256(latestPrice) / studentsAmount;
uint256  amountOfTokensToBuy = msg.value/tokenPrice;



if(IERC20(tokenContract).balanceOf(address(this)) < amountOfTokensToBuy){
(bool sent, bytes memory data) = msg.sender.call{value:msg.value}("Sorry, there is not enough tokens");
}

IERC20(tokenContract).transfer(msg.sender, amountOfTokensToBuy);
}

function getLatestPrice() public view returns (int) {
(
uint80 roundID,
int price,
uint startedAt,
uint timeStamp,
uint80 answeredInRound
) = priceFeed.latestRoundData();
return price;
}

function getStudentsAmount() public view returns(uint256) {
string[] memory studentsList = studentsInterface(studentsContractAddress).getStudentsList();
return studentsList.length;
}
}