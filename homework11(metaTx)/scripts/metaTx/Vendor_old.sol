//example deployed at https://kovan.etherscan.io/address/0xa95473557Fabc556E1C0C84d7de1aF058aCeC886#code

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    event Log(string message);
    event test1(uint256 number1);
    event test2(uint256 number2);
    event test3(address number3);
    event test4(address number4);
    event test5(uint256 number5);
    //
    //    uint256 public test1;
    //    uint256 public test2;
    //    address public test3;
    //    address public test4;
    //    uint256 public test5;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    struct BuyForDaiRequest {
        address from;
        uint256 value;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
    keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    bytes32 internal constant _TYPEHASH_BUY_FOR_DAI_REQUEST =
    keccak256("BuyForDaiRequest(address from,uint256 value,uint256 nonce,bytes data)");

    mapping(address => uint256) public _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function initMinimalForwarder() public {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public  returns (bool) {
        address signer = _extractSigner(req, signature);

        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function verifyBuyForDaiRequest(BuyForDaiRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH_BUY_FOR_DAI_REQUEST, req.from, req.value, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function _extractSigner(ForwardRequest calldata req, bytes calldata signature) internal returns (address){
        return _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
    public
    payable
    returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = address(this).call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        return (success, returndata);
    }
}

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

contract Vendor is Initializable, OwnableUpgradeable, UUPSUpgradeable, MinimalForwarder    {
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
        emit BuyingTokens(tx.origin, amountToBuy,DAITokenContract.balanceOf(msg.sender),myTokenContract.balanceOf(address(this)), DAITokenContract.allowance(msg.sender, address(this)));

        //        uint256 amountOfDAITokensToPay = amountToBuy;

        //        require(DAITokenContract.balanceOf(msg.sender) >= amountOfDAITokensToPay, "Sorry, you do not have enough DAI-tokens for swap");
        //        require(myTokenContract.balanceOf(address(this)) >= amountToBuy, "Sorry, there is not enough tokens on my balance");

        //        uint256 allowance = DAITokenContract.allowance(msg.sender, address(this));
        //        require(allowance >= amountToBuy, "Check the token allowance please");

        //        DAITokenContract.transferFrom(msg.sender, address(this), amountToBuy);
        //        myTokenContract.transfer(msg.sender, amountToBuy);

    }

//    function buyTokensForDAIOnBehalf(BuyForDaiRequest calldata req, bytes calldata signature) public {
//        emit Log('tokens successfully bought');
//        IERC20 DAITokenContract = IERC20(DAITokenContractAddress);
//        IERC20 myTokenContract = IERC20(myTokenContractAddress);
//        emit BuyingTokens(buyer, amountToBuy,DAITokenContract.balanceOf(msg.sender),myTokenContract.balanceOf(address(this)), DAITokenContract.allowance(msg.sender, address(this)));
//
//        //        uint256 amountOfDAITokensToPay = amountToBuy;
//
//        //        require(DAITokenContract.balanceOf(msg.sender) >= amountOfDAITokensToPay, "Sorry, you do not have enough DAI-tokens for swap");
//        //        require(myTokenContract.balanceOf(address(this)) >= amountToBuy, "Sorry, there is not enough tokens on my balance");
//
//        //        uint256 allowance = DAITokenContract.allowance(msg.sender, address(this));
//        //        require(allowance >= amountToBuy, "Check the token allowance please");
//
//        //        DAITokenContract.transferFrom(msg.sender, address(this), amountToBuy);
//        //        myTokenContract.transfer(msg.sender, amountToBuy);
//
//    }

    function buyTokensForDAIOnBehalf(ForwardRequest calldata req, bytes calldata signature)
    public
    payable
    returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");

        IERC20 DAITokenContract = IERC20(DAITokenContractAddress);
        IERC20 myTokenContract = IERC20(myTokenContractAddress);

        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = address(this).call{value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        emit BuyingTokens(req.from, amount,DAITokenContract.balanceOf(msg.sender),myTokenContract.balanceOf(address(this)), DAITokenContract.allowance(msg.sender, address(this)));

        (uint256 amount) = abi.decode(req.data,(uint256));



        return (success, returndata);
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