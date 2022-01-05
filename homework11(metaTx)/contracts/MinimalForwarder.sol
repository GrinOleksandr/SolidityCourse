pragma solidity ^0.8.10;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/MinimalForwarder.sol)


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

    bytes32 private constant _TYPEHASH =
    keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) public _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function initMinimalForwarder() public {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public  returns (bool) {
        emit Log('verifying');
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        emit test1(_nonces[req.from]);
        emit test2(req.nonce);
        emit test3(signer);
        emit test4(req.from);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function verify2(ForwardRequest calldata req, bytes calldata signature) public  returns (bool) {
        emit Log('verifying');
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        emit test1(_nonces[req.from]);
        emit test2(req.nonce);
        emit test3(signer);
        emit test4(req.from);
        return signer == req.from;
    }

    function verify3(ForwardRequest calldata req, bytes calldata signature) public  returns (address) {
        emit Log('verifying');
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        emit test1(_nonces[req.from]);
        emit test2(req.nonce);
        emit test3(signer);
        emit test4(req.from);
        return signer;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
    public
    payable
    returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > req.gas / 63);

        return (success, returndata);
    }
}

