pragma solidity 0.8.10;

contract Interceptor {

    address public owner = msg.sender;
    event INTERCEPT(bytes message);
    event ErrorEventString(bytes reason);
    event ErrorEvent(bytes reason);

    fallback() external payable {
        emit INTERCEPT(msg.data);
    }

    function getBackEther() public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    function buy(address _exchangeInstance) public payable {
        (bool success, ) = _exchangeInstance.call{gas: 150000, value: msg.value}(abi.encodeWithSignature("buyTokens()"));
        require(success, "External call failed");
    }
}