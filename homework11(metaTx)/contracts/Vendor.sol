//example deployed at https://kovan.etherscan.io/address/0xa95473557Fabc556E1C0C84d7de1aF058aCeC886#code

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract MinimalForwarder is EIP712Upgradeable {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 internal constant _TYPEHASH =
    keccak256("ForwardRequest(address from,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) public _nonces;

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public  returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);

        return _nonces[req.from] == req.nonce && signer == req.from;
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

abstract contract VRFConsumerBase is VRFRequestIDBase {
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    )
    internal
    virtual;

    uint256 constant private USER_SEED_PLACEHOLDER = 0;
    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee
    )
    internal
    returns (
        bytes32 requestId
    )
    {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    constructor(
        address _vrfCoordinator,
        address _link
    ) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function initializeVRFConsumerBase (
        address _vrfCoordinator,
        address _link
    ) internal {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function rawFulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    )
    external
    {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

contract Vendor is Initializable, OwnableUpgradeable, UUPSUpgradeable, ChainlinkClient, VRFConsumerBase, MinimalForwarder, BaseRelayRecipient    {
    using Chainlink for Chainlink.Request;
    event Log(string message);
    event LogBytes(bytes message);
    event RandomNumberUpdated(uint256 number);
    event MyTokensTransfered(uint256 number);
    event PriceUpdated(uint256 price);
    event TokensBought(address buyer, uint256 amount);

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

    mapping(uint256 => Operation) queue;
    mapping(bytes32 => uint256) getRequestIndexFromRandomnessRequestId;
    mapping(bytes32 => uint256) getRequestIndexFromPriceRequestId;

    bytes32 private keyHash;
    uint256 private randomResult;

    uint256 private eth_usd_price;
    address private oracle;
    bytes32 private jobId;
    uint256 private chainlinkFee;

    constructor()
    VRFConsumerBase(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ){
    }

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

        initializeVRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        );

        __EIP712_init("MinimalForwarder", "0.0.1");
    }

    function addToQueue (uint8 _operationTypeId,address sender, uint256 _amount, bytes32 _randomnessRequestId, bytes32 _priceRequestId) internal {
        Operation memory newOperation = Operation(sender, _operationTypeId, _amount, 0, 0);
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

    function buyTokens() public payable {
        bytes32 priceRequestId = request_ETH_USD_price();
        bytes32 randomnessRequestId = getRandomNumber();
        addToQueue(1, msg.sender, msg.value, randomnessRequestId, priceRequestId);
    }

    function buyTokensOnBehalfOf() public payable {
        bytes32 priceRequestId = request_ETH_USD_price();
        bytes32 randomnessRequestId = getRandomNumber();
        addToQueue(1, _msgSender(), msg.value, randomnessRequestId, priceRequestId);
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
            emit Log('buy_for_dai_1');
            return _buyTokensForDAI(request.sender, request.randomNumber, request.amount);
        }
    }

    function _buyTokensForETH(address sender, uint256 price, uint256 randomNumber, uint256 amountPayed) internal {
        IERC20 myTokenContract = IERC20(myTokenContractAddress);

        uint256 amountOfTokensToBuy = amountPayed * price * randomNumber / 35 / 10 ** 18 / 10;

        if(myTokenContract.balanceOf(address(this)) < amountOfTokensToBuy){
            (bool success,) = msg.sender.call{value:msg.value}("Sorry, there is not enough tokens");
            require(success, "External call failed");
            return;
        }

        try myTokenContract.transfer(sender, amountOfTokensToBuy) {
            emit MyTokensTransfered(amountOfTokensToBuy);
            emit TokensBought(sender, amountOfTokensToBuy);
        } catch Error(string memory reason) {
            emit Log(reason);
        } catch (bytes memory reason) {
            emit LogBytes(reason);
        }
    }

    function buyTokensForDAI(uint256 amountToBuy) public {
        require(amountToBuy > 0, "Maybe you would like to buy something greater than 0?");

        bytes32 randomnessRequestId = getRandomNumber();
        addToQueue(2, msg.sender, amountToBuy, randomnessRequestId, "");
    }

    function buyTokensForDAIOnBehalfOf(uint256 amountToBuy) public {
        require(amountToBuy > 0, "Maybe you would like to buy something greater than 0?");

        bytes32 randomnessRequestId = getRandomNumber();
        addToQueue(2, _msgSender(), amountToBuy, randomnessRequestId, "");
    }

    function _buyTokensForDAI(address sender, uint256 randomNumber, uint256 amount) internal {
        IERC20 DAITokenContract = IERC20(DAITokenContractAddress);
        IERC20 myTokenContract = IERC20(myTokenContractAddress);

        uint256 amountOfTokensToBuy = amount * randomNumber / 10;

        uint256 allowance = DAITokenContract.allowance(sender, address(this));

        if(DAITokenContract.balanceOf(sender) <= amount || myTokenContract.balanceOf(address(this)) <= amountOfTokensToBuy || allowance <= amount){
            return;
        }

        DAITokenContract.transferFrom(sender, address(this), amount);
        myTokenContract.transfer(sender, amountOfTokensToBuy);
        emit MyTokensTransfered(amountOfTokensToBuy);
        emit TokensBought(sender, amountOfTokensToBuy);
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK - fill contract with faucet");
        emit Log('Request for random number sent');
        return requestRandomness(keyHash, chainlinkFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomNumberUpdated(randomness);
        randomResult = (randomness % 26) + 5;
        emit RandomNumberUpdated(randomResult);

        uint256 index = getRequestIndexFromRandomnessRequestId[requestId];
        queue[index].randomNumber = randomResult;

        processBuyRequest(index);
    }

    function _msgSender() internal override(ContextUpgradeable,BaseRelayRecipient) view returns (address ret) {
        if (msg.data.length >= 20) {
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal override(ContextUpgradeable,BaseRelayRecipient) view returns (bytes calldata ret) {
        if (msg.data.length >= 20) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function versionRecipient() external override view returns (string memory){
        return 'V1';
    }
}