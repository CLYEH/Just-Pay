// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ITokenMessengerV2 {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller,
        uint256 maxFee,
        uint32 minFinalityThreshold
        ) external;
}

interface IMessageTransmitterV2{
    function receiveMessage(bytes calldata message, bytes calldata attestation) external returns(bool);
}

contract JustPayContract_test {
    //using ECDSA for bytes32;

    address public signer;
    address public operator;
    mapping(uint256 => bool) public usedNonces;

    address private tokenMessengerV2 = 0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA;
    address private messageTransmitterV2 = 0xE737e5cEBEEBa77EFE34D4aa090756590b1CE275;

    modifier onlyOperator {
        require(msg.sender == operator, "not operator");
        _;
    }
    
    modifier onlySigner {
        require(msg.sender == signer, "not Owner!");
        _;
    }

    modifier onlyAuthorized{
        require(msg.sender == operator || msg.sender == signer, "not authorized");
        _;
    }

    modifier onlySigned(
        uint256[] memory sourceChainIds, 
        uint256 nonce, 
        bytes memory signature
    ){
        // Check if sourcechain is approved
        bool matched = false;
        for(uint256 i = 0; i < sourceChainIds.length; i += 1){
            if(sourceChainIds[i] == block.chainid){
                matched = true;
                break;
            }
        }
        require(matched, "not authorized in this chain!");
        // check if this signature had been used
        require(!usedNonces[nonce],"nonce used!");
        usedNonces[nonce] = true;

        // 將訊息 hash 化
        bytes32 messageHash = keccak256(abi.encode(sourceChainIds, nonce));

        // 轉成 eth_signed message hash（自動加上前綴）
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        // 使用 ECDSA 恢復簽名者
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        address recovered = ecrecover(ethSignedMessageHash, v, r, s);
        require(recovered == signer, "Invalid signature");
        _;
    }

    constructor(address _signer, address _operator){
        signer = _signer;
        operator = _operator;
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function operatorUpdate(address newOperator) external onlyAuthorized{
        operator = newOperator;
    }

    function withdrawEth(address to, uint256 amount) external onlyAuthorized{
        require(address(this).balance <= amount);
        payable(address(to)).transfer(amount);
    }

    function transferToken(address token, address to, uint256 amount) external onlyAuthorized{
        IERC20(token).transfer(to, amount);
    }

    function trasferTokenFrom(address token, address to, uint amount) public onlyAuthorized{
        IERC20(token).transferFrom(signer, to, amount);
    }

    function withdrawToken(address token) external onlySigner{
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "Not enough token");
        IERC20(token).transfer(signer, amount);
    }

    function burnProxy(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller,
        uint256 maxFee,
        uint32 minFinalityThreshold,
        uint256[] memory sourceChainIds,
        uint256 nonce,
        bytes memory signature
        )external
        onlyOperator
        onlySigned(sourceChainIds, nonce, signature)
        {
            IERC20(burnToken).approve(tokenMessengerV2, amount);
            IERC20(burnToken).transferFrom(signer, address(this), amount);
            ITokenMessengerV2(tokenMessengerV2).depositForBurn(amount, destinationDomain, mintRecipient, burnToken, destinationCaller, maxFee, minFinalityThreshold);
        }

    function receiveMessageFromCCTP(bytes calldata message, bytes calldata attestation) external onlyOperator{
        IMessageTransmitterV2(messageTransmitterV2).receiveMessage(message, attestation);
    }

    receive() external payable{} 
}


contract Factory {
    event ContractDeployed(address deployedAddress);

    function computeAddress(uint256 _salt_int, address signer, address operator) external view returns (address) {
        bytes32 _salt = bytes32(_salt_int);
        bytes memory bytecode = abi.encodePacked(
            type(JustPayContract_test).creationCode,
            abi.encode(signer, operator)
        );
        return Create2.computeAddress(_salt, keccak256(bytecode), address(this));
    }

    function deploy(uint256 _salt_int, address signer, address operator) external returns (address) {
        bytes32 _salt = bytes32(_salt_int);
        bytes memory bytecode = abi.encodePacked(
            type(JustPayContract_test).creationCode,
            abi.encode(signer, operator)
        );
        address deployedAddr = Create2.deploy(0, _salt, bytecode);
        emit ContractDeployed(deployedAddr);
        return deployedAddr;
    }
}
