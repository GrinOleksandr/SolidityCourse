//example deployed at https://rinkeby.etherscan.io/address/0x7ea75b21D0A69cfad760d4fe95ab086C1508D2cd
//example deployed at https://kovan.etherscan.io/address/0x18DAF3C01573B827A067BFd02349B0d5588242aB
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


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


contract Vendor is Initializable, OwnableUpgradeable, UUPSUpgradeable, VRFConsumerBase, ChainlinkClient    {
    using Chainlink for Chainlink.Request;
    event Log(string message);
    event LogBytes(bytes message);
    event RandomNumberUpdated(uint256 number);
    event MyTokensTransfered(uint256 number);

    address aggregatorAddressFor_ETH_USD;
    address DAITokenContractAddress;
    address myTokenContractAddress;
    uint256 requestIndex;
    struct Operation {
        address sender;
        uint8 operationTypeId;
        uint256 amount;
        uint256 randomNumber;
        uint256 eth_usd_price;
    }

//    User[] public queue;
    mapping(uint256 => Operation) public queue;
    mapping(bytes32 => uint256) getRequestIndexFromRandomnessRequestId;
    mapping(bytes32 => uint256) getRequestIndexFromPriceRequestId;

    bytes32 public keyHash;
    uint256 public randomResult;

    event PriceUpdated(uint256 price);
    uint256 public eth_usd_price;
    address private oracle;
    bytes32 private jobId;
    uint256 private chainlinkFee;

    ////to remove
    uint256 public test1;
    uint256 public test2;
    uint256 public test3;
    uint256 public test4;



    ///////

    constructor()
    VRFConsumerBase(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ){}

    function initialize(address tokenContractAddress, address _DAITokenContractAddress)  public initializer
    {
        DAITokenContractAddress = _DAITokenContractAddress;
        myTokenContractAddress = tokenContractAddress;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        chainlinkFee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "83ba9ddc927946198fbd0bf1bd8a8c25";
        _transferOwnership(msg.sender);
    }

    function addToQueue (uint8 _operationTypeId, uint256 _amount, bytes32 _randomnessRequestId, bytes32 _priceRequestId) public {
        Operation memory newOperation = Operation(msg.sender, _operationTypeId, _amount, 0, 0);
        queue[requestIndex] = newOperation;
        getRequestIndexFromRandomnessRequestId[_randomnessRequestId] = requestIndex;
        getRequestIndexFromPriceRequestId[_priceRequestId] = requestIndex;
    }

    function request_ETH_USD_price() public returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD&api_key=8ba055208fcf46cf3a795f380fa1b48083944638d81276bcef280b6a00328063");

        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "RAW.ETH.USD.VOLUME24HOUR");

        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        emit Log('chainlink price request sent');

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, chainlinkFee);
    }

    function fulfill(bytes32 _requestId, uint256 _eth_usd_price) public recordChainlinkFulfillment(_requestId)
    {
        emit PriceUpdated(_eth_usd_price);
        eth_usd_price = _eth_usd_price;

        uint256 index = getRequestIndexFromRandomnessRequestId[_requestId];
        queue[index].eth_usd_price = _eth_usd_price;

        processBuyRequest(index);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function buyTokens() public payable {
        bytes32 priceRequestId = request_ETH_USD_price();
        bytes32 randomnessRequestId = getRandomNumber();
        addToQueue(1, msg.value, randomnessRequestId, priceRequestId);
    }

    function processBuyRequest(uint256 index) internal {
        Operation memory request = queue[index];
        if(request.operationTypeId == 1){
            if(request.eth_usd_price == 0 || request.randomNumber == 0){
                return;
            }
            return _buyTokensForETH(request.sender, request.eth_usd_price, request.randomNumber, request.amount);
        }

        if(request.operationTypeId == 2){
            if(request.randomNumber == 0){
                return;
            }
            return _buyTokensForDAI(request.sender, request.randomNumber, request.amount);
        }
    }

    function _buyTokensForETH(address sender, uint256 price, uint256 randomNumber, uint256 amountPayed) internal {
        IERC20 myTokenContract = IERC20(myTokenContractAddress);
        uint256 multiplier = randomNumber/10;
        uint256 tokenPrice = price/35;
        uint256 amountOfTokensToBuy = (amountPayed/tokenPrice)*multiplier;

        ///////
        test1 = price;
        test2 = multiplier;
        test3 = tokenPrice;
        test4 = amountOfTokensToBuy;
        ///////

        //ToDo fix this
        if(myTokenContract.balanceOf(address(this)) < amountOfTokensToBuy){
            (bool success,) = msg.sender.call{value:msg.value}("Sorry, there is not enough tokens");
            require(success, "External call failed");
            return;
        }

        //ToDo fix this
        try myTokenContract.transfer(sender, amountOfTokensToBuy) {
            emit MyTokensTransfered(amountOfTokensToBuy);
        } catch Error(string memory reason) {
            emit Log(reason);
        } catch (bytes memory reason) {
            emit LogBytes(reason);
        }
    }

    function buyTokensForDAI(uint256 amountToBuy) public {
        bytes32 randomnessRequestId = getRandomNumber();
        addToQueue(2, amountToBuy, randomnessRequestId, 0x0);
    }

    function _buyTokensForDAI(address sender, uint256 randomNumber, uint256 amount) public {
        IERC20 DAITokenContract = IERC20(DAITokenContractAddress);
        IERC20 myTokenContract = IERC20(myTokenContractAddress);

        uint256 amountOfDAITokensToPay = amount;
        uint256 allowance = DAITokenContract.allowance(sender, address(this));

        if(amount > 0 || DAITokenContract.balanceOf(sender) >= amountOfDAITokensToPay || myTokenContract.balanceOf(address(this)) >= amount || allowance >= amount){
            return;
        }

        DAITokenContract.transferFrom(sender, address(this), amountOfDAITokensToPay);
        myTokenContract.transfer(sender, amount);
        emit MyTokensTransfered(amount);
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK - fill contract with faucet");
        emit Log('Request for random number sent');
        return requestRandomness(keyHash, chainlinkFee);
   }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomNumberUpdated(randomness);
        randomResult = (randomness % 30) + 5;
        emit RandomNumberUpdated(randomResult);

        uint256 index = getRequestIndexFromRandomnessRequestId[requestId];
        queue[index].randomNumber = randomResult;

        processBuyRequest(index);
    }

    function myAddress() public view returns(address){
        return address(this);
    }
}