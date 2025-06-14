// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

interface ISwap{
    function swap(address tokenIn, address tokenOut, uint256 amount) external;
}

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

interface IAAVEV3{
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

contract JustPayContract{

    address public signer;
    address public operator;

    // usedNonnces[nonce] => bool
    mapping(uint256 => bool) public usedNonces;
    // domainId[chainId] => domainid
    mapping(uint256 => uint256) domainId;

    struct LocalSignature{
        uint256 sourceChainId;
        uint256 amount;
        uint256 nonce;
        uint256 destinationChainId;
        address targetAddress;
    }

    /* mainnet
    address private tokenMessengerV2 = 0x28b5a0e9C621a5BadaA536219b3a228C8168cf5d; 
    address private messageTransmitterV2 = 0x81D40F21F12A8F0E3252Bccb954D722d4c464B64;
    */

    // testnet
    address private tokenMessengerV2 = 0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA;
    address private messageTransmitterV2 = 0xE737e5cEBEEBa77EFE34D4aa090756590b1CE275;

    event usedNoncesEvent(uint32 indexed chainId, uint256 indexed nonceUsed);
    event tokenTransferEvent(address to, uint256 amount);
    event depositForBurnEvent(uint256 indexed amount);

    modifier onlySigner{
        require(msg.sender == signer, "You are not the owner!");
        _;
    }

    modifier onlyOperator{
        require(msg.sender == operator, "You are not the operator!");
        _;
    }

    constructor(address _signer, address _operator){
        signer = _signer;
        operator = _operator;

        // testnet
        domainId[11155111] = 0;   // Ethereum
        domainId[43113] = 1;      // Avalance
        domainId[84532] = 6;      // Base
        domainId[59141] = 11;     // Linea

        /* mainnet
        domainId[1] = 0;        // Ethereum
        domainId[43114] = 1;    // Avalance
        domainId[8453] = 6;     // Base
        domainId[59144] = 11;   // Linea
        */
    }

    function arraySum(uint256[] memory numbers) internal pure returns (uint256) {
        uint256 total = 0;
        uint256 len = numbers.length;
        for(uint256 i = 0; i < len; i++) {
            total += numbers[i];
        }
        return total;
    }

    function signatureVerifier(
        uint256[] memory sourceChainIds, 
        uint256[] memory amountEach,
        uint256[] memory nonces, 
        uint256 expirey,
        uint256 destinationChainId,
        address targetAddress,
        bytes memory signature
        ) public 
        returns(LocalSignature memory){
            require(block.timestamp < expirey, "signature is expired");
            uint256 localIndex;
            bool matched = false;
            for(uint256 i = 0; i < sourceChainIds.length; i += 1){
                if(sourceChainIds[i] == block.chainid){
                    localIndex = i;
                    matched = true;
                    break;
                }
            }
            require(matched, "not authorized source chain");
            require(!usedNonces[nonces[localIndex]], "nonce used!");
            usedNonces[nonces[localIndex]] = true;
            emit usedNoncesEvent(uint32(block.chainid), nonces[localIndex]);

            // 將訊息 hash 化
            bytes32 messageHash = keccak256(abi.encode(sourceChainIds, amountEach, nonces, expirey, destinationChainId, targetAddress));
            // 轉成 eth_signed message hash（自動加上前綴）
            bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
            // 使用 ECDSA 恢復簽名者
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
            address recovered = ecrecover(ethSignedMessageHash, v, r, s);
            //address recovered = ethSignedMessageHash.recover(signature);
            require(recovered == signer, "Invalid signature");

            LocalSignature memory sigContext = LocalSignature({
                sourceChainId: sourceChainIds[localIndex],
                amount: amountEach[localIndex],
                nonce: nonces[localIndex],
                destinationChainId: destinationChainId,
                targetAddress: targetAddress
            });

            return sigContext;
        }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function proxyTransfer(
        address token,
        uint256[] memory sourceChainIds, 
        uint256[] memory amountEach,
        uint256[] memory nonces,
        uint256 expirey,
        uint256 destinationChainId,
        address targetAddress,
        bytes memory signature
        )external onlyOperator {
            LocalSignature memory sigContent = signatureVerifier(sourceChainIds, amountEach, nonces, expirey, destinationChainId, targetAddress, signature);
            require(destinationChainId == block.chainid);
            address to = sigContent.targetAddress;
            uint256 amount = arraySum(amountEach);
            IERC20(token).transferFrom(signer, to, amount);
            emit tokenTransferEvent(to, amount);
    }

    function proxyDepositForBurn(
        address burnToken,
        uint256 maxFee,
        uint32 minFinalityThreshold,
        uint256[] memory sourceChainIds, 
        uint256[] memory amountEach,
        uint256[] memory nonces,
        uint256 expirey,
        uint256 destinationChainId,
        address targetAddress,
        bytes memory signature
    ) external onlyOperator{
        LocalSignature memory sigContent = signatureVerifier(sourceChainIds, amountEach, nonces, expirey, destinationChainId, targetAddress, signature);
        
        uint256 amount = sigContent.amount;
        uint32 destinationDomain = uint32(domainId[sigContent.destinationChainId]);
        bytes32 mintRecipient = bytes32(uint256(uint160(signer)));
        bytes32 destinationCaller = bytes32(uint256(uint160(address(0))));

        IERC20(burnToken).approve(tokenMessengerV2, amount);
        IERC20(burnToken).transferFrom(signer, address(this), amount);
        ITokenMessengerV2(tokenMessengerV2).depositForBurn(amount, destinationDomain, mintRecipient, burnToken, destinationCaller, maxFee, minFinalityThreshold);
        emit depositForBurnEvent(amount);
    }

    function proxyReceiveMessage(
        bytes calldata message,
        bytes calldata attestation
    ) external{
        IMessageTransmitterV2(messageTransmitterV2).receiveMessage(message, attestation);
    }

    function depositToAAVE(address aaveV3, address asset, uint256 amount) public onlyOperator{
        IERC20(asset).transferFrom(signer, address(this), amount);
        
        // 記錄 swap 前的餘額
        uint256 balanceBefore = IERC20(0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f).balanceOf(address(this));
        
        // 授權並執行 swap
        IERC20(asset).approve(0x364687AAF0A70c418Fe5FF8e9746B254f319B33E, amount);
        ISwap(0x364687AAF0A70c418Fe5FF8e9746B254f319B33E).swap(asset, 0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f, amount);
        
        // ✅ 計算實際收到的代幣數量
        uint256 balanceAfter = IERC20(0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f).balanceOf(address(this));
        uint256 receivedAmount = balanceAfter - balanceBefore;
        
        // ✅ 確保有收到代幣
        require(receivedAmount > 0, "Swap failed or received 0 tokens");
        
        // ✅ 使用實際數量進行授權和存款
        IERC20(0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f).approve(aaveV3, receivedAmount);
        IAAVEV3(aaveV3).supply(0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f, receivedAmount, signer, 0);
        
        // ✅ 添加事件記錄
        emit tokenTransferEvent(signer, receivedAmount); // 或創建新的事件
    }

    function proxyDepositForBurnV2(
        address burnToken,
        uint256 maxFee,
        uint32 minFinalityThreshold,
        uint256[] memory sourceChainIds, 
        uint256[] memory amountEach,
        uint256[] memory nonces,
        uint256 expirey,
        uint256 destinationChainId,
        address targetAddress,
        address aaveV3,
        uint256 amountWithdrawFromAAVE,
        bytes memory signature
    ) external onlyOperator{
        LocalSignature memory sigContent = signatureVerifier(sourceChainIds, amountEach, nonces, expirey, destinationChainId, targetAddress, signature);
        
        uint256 amount = sigContent.amount;
        uint32 destinationDomain = uint32(domainId[sigContent.destinationChainId]);
        bytes32 mintRecipient = bytes32(uint256(uint160(signer)));
        bytes32 destinationCaller = bytes32(uint256(uint160(address(0))));

        if (amountWithdrawFromAAVE > 0){
            IAAVEV3(aaveV3).withdraw(0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f, amountWithdrawFromAAVE, address(this));
            ISwap(0x364687AAF0A70c418Fe5FF8e9746B254f319B33E).swap(0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f, burnToken, amountWithdrawFromAAVE);
        }

        IERC20(burnToken).approve(tokenMessengerV2, amount);
        IERC20(burnToken).transferFrom(signer, address(this), amount);
        ITokenMessengerV2(tokenMessengerV2).depositForBurn(amount, destinationDomain, mintRecipient, burnToken, destinationCaller, maxFee, minFinalityThreshold);
        emit depositForBurnEvent(amount);
    }

}

contract Factory {
    event ContractDeployed(address indexed deployedAddress);

    function computeAddress(uint256 _salt_int, address signer, address operator) external view returns (address) {
        bytes32 _salt = bytes32(_salt_int);
        bytes memory bytecode = abi.encodePacked(
            type(JustPayContract).creationCode,
            abi.encode(signer, operator)
        );
        return Create2.computeAddress(_salt, keccak256(bytecode), address(this));
    }

    function deploy(uint256 _salt_int, address signer, address operator) external returns (address) {
        bytes32 _salt = bytes32(_salt_int);
        bytes memory bytecode = abi.encodePacked(
            type(JustPayContract).creationCode,
            abi.encode(signer, operator)
        );
        address deployedAddr = Create2.deploy(0, _salt, bytecode);
        emit ContractDeployed(deployedAddr);
        return deployedAddr;
    }
}


contract Swap{
    address public aaveTestUSDC = 0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f;
    address public circleTestUSDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    address public signer;

    constructor(){
        signer = msg.sender;
    }

    function swap(address tokenIn, address tokenOut, uint256 amount) external{
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenOut).transfer(msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external{
        require(msg.sender == signer, "You are not the signer!");
        IERC20(token).transfer(signer, amount);
    }
}