//example deployed at  https://rinkeby.etherscan.io/address/0x7ea75b21D0A69cfad760d4fe95ab086C1508D2cd#code

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

    address studentsContractAddress;
    address aggregatorAddressFor_ETH_USD;
    address DAITokenContractAddress;
    address myTokenContractAddress;
    address NFTTokenContractAddress;
    uint256 keyNftTokenId;

    bytes32 public keyHash;
    uint256 public randomResult;

    event PriceUpdated(uint256 price);
    uint256 public eth_usd_price;
    address private oracle;
    bytes32 private jobId;
    uint256 private chainlinkFee;

    modifier hasKeyNFTToken() {
        _isTokenHolder();
        _;
    }

    constructor()
    VRFConsumerBase(
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
    )
    {}

    function initialize(address tokenContractAddress, address _DAITokenContractAddress, address nftTokenContractAddress, uint256 _keyNftTokenId)  public initializer
    {
        studentsContractAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
        aggregatorAddressFor_ETH_USD = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        DAITokenContractAddress = _DAITokenContractAddress;
        myTokenContractAddress = tokenContractAddress;
        NFTTokenContractAddress = nftTokenContractAddress;
        keyNftTokenId = _keyNftTokenId;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        chainlinkFee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        setPublicChainlinkToken();
        oracle = 0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e;
        jobId = "6d1bfe27e7034b1d87b5270556b17277";
        _transferOwnership(msg.sender);
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
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _isTokenHolder() internal view {
        IERC721 NFTTokenContract = IERC721(NFTTokenContractAddress);
        require(NFTTokenContract.balanceOf(msg.sender) > 0 , "Sorry, you don't have a key to use this.");
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

        try myTokenContract.transfer(msg.sender, amountOfTokensToBuy) {
            emit Log("tokens transfered");
        } catch Error(string memory reason) {
            emit Log(reason);
        } catch (bytes memory reason) {
            emit LogBytes(reason);
        }
    }

    function buyTokensForDAI(uint256 amountToBuy) public hasKeyNFTToken {
        IERC20 DAITokenContract = IERC20(DAITokenContractAddress);
        IERC20 myTokenContract = IERC20(myTokenContractAddress);
        require(amountToBuy > 0, "Maybe you would like to buy something greater than 0?");

        uint256 amountOfDAITokensToPay = amountToBuy;

        require(DAITokenContract.balanceOf(msg.sender) >= amountOfDAITokensToPay, "Sorry, you do not have enough DAI-tokens for swap");
        require(myTokenContract.balanceOf(address(this)) >= amountToBuy, "Sorry, there is not enough tokens on my balance");

        uint256 allowance = DAITokenContract.allowance(msg.sender, address(this));
        require(allowance >= amountToBuy, "Check the token allowance please");

        DAITokenContract.transferFrom(msg.sender, address(this), amountToBuy);
        myTokenContract.transfer(msg.sender, amountToBuy);

    }

    function getLatestPrice(address aggregatorAddress) internal returns (uint256){
        (,int price,,,) = AggregatorV3Interface(aggregatorAddress).latestRoundData();
        uint8 decimals = AggregatorV3Interface(aggregatorAddress).decimals();

        return uint256(price)/10**decimals;
    }

    function getStudentsAmount() internal view returns(uint256) {
        string[] memory studentsList = studentsInterface(studentsContractAddress).getStudentsList();
        return studentsList.length;
    }

   function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK - fill contract with faucet");
        emit Log('Request for random number sent');
        return requestRandomness(keyHash, chainlinkFee);
   }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomNumberUpdated(randomness);
        randomResult = randomness;
    }

    function myAddress() public view returns(address){
        return address(this);
    }
}