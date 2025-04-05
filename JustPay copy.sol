// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

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

contract JustPayContract{

    address public signer;
    address public operator;
    mapping(uint256 => bool) public usedNonces;

    address private tokenMessengerV2 = 0x28b5a0e9C621a5BadaA536219b3a228C8168cf5d;
    address private messageTransmitterV2 = 0x81D40F21F12A8F0E3252Bccb954D722d4c464B64;

    struct ChainAllowance {
        uint256 chainId;           // source chain (即 block.chainid)
        uint256 amount;            // 授權可動用的 USDC 金額
        uint256 nonce;             // 該鏈上唯一使用一次
    }

    struct Permit {
        address signer;       // 使用者錢包地址
        address targetAddress; // 目標地址
        uint256 destinationChainId; // 目標鏈
        uint256 totalAmount; // 發送總金額
        uint256 deadline;     // 簽名過期時間
        ChainAllowance[] allowances;
    }

    bytes32 public constant CHAIN_ALLOWANCE_TYPEHASH = keccak256(
        "ChainAllowance(uint256 chainId,uint256 amount,uint256 nonce)"
    );

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address signer,address targetAddress,uint256 destinationChainId,uint256 totalAmount,uint256 deadline,ChainAllowance[] allowances)ChainAllowance(uint256 chainId,uint256 amount,uint256 nonce)"
    );

    bytes32 public DOMAIN_SEPARATOR;
    bool public initialized;

    event usedNoncesEvent(uint256 indexed nonceUsed);
    event depositForBurnEvent(uint256 indexed amount);

    function initializeDomainSeparator(uint256 chainId) external onlyOperator { // should be call once after deploy
        require(!initialized, "Already initialized");
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
            keccak256("JustPay"),
            chainId,
            address(this)
        ));
        initialized = true;
    }

    function verifyPermit(
        Permit calldata permit,
        uint8 v,
        bytes32 r,
        bytes32 s
        // uint32 expectedDestinationDomain
    ) internal returns (bool) {
        // 驗證效期
        require(permit.deadline >= block.timestamp, "Permit expired");

        bytes32[] memory hashedAllowances = new bytes32[](permit.allowances.length);
        for (uint i = 0; i < permit.allowances.length; i++) {
            ChainAllowance calldata ca = permit.allowances[i];
            hashedAllowances[i] = keccak256(abi.encode(
                CHAIN_ALLOWANCE_TYPEHASH,
                ca.chainId,
                //ca.destinationDomain,
                ca.amount,
                ca.nonce
            ));
        }

        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TYPEHASH,
            permit.signer,
            permit.targetAddress,
            permit.destinationChainId,
            permit.totalAmount,
            permit.deadline,
            keccak256(abi.encodePacked(hashedAllowances))
        ));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        address recovered = ecrecover(digest, v, r, s);
        require(recovered == permit.signer, "Invalid signature");
        
        // 找到符合這條鏈 + 目的鏈的 allowance
        for (uint i = 0; i < permit.allowances.length; i++) {
            ChainAllowance calldata ca = permit.allowances[i];
            if (ca.chainId == block.chainid) {
                require(!usedNonces[ca.nonce], "Nonce used");
                usedNonces[ca.nonce] = true;
                emit usedNoncesEvent(ca.nonce);
            }
        }
        return true;
       

        // revert("No valid allowance for this chain and destination");
    }

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
    }

    function proxyTransfer(
        address token,
        address to,
        Permit calldata permit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOperator {
        if(verifyPermit(permit, v, r, s) == true){
            uint256 amount = permit.totalAmount;
            IERC20(token).transferFrom(signer, to, amount);
        }else{revert("signature invalid!");}
        
    }

    function proxyDepositForBurn(
        Permit calldata permit,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint32 destinationDomain, // Defined by CCTP
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller, 
        uint256 maxFee,
        uint32 minFinalityThreshold
    ) external onlyOperator{
        if(verifyPermit(permit, v, r, s) == true){
            uint256 amount = permit.totalAmount;
            ITokenMessengerV2(tokenMessengerV2).depositForBurn(amount, destinationDomain, mintRecipient, burnToken, destinationCaller, maxFee, minFinalityThreshold);
            emit depositForBurnEvent(amount);
        }else{revert("signature invalid!");}
    }

    function testSignature(
        Permit calldata permit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns(bool){
        bool output = verifyPermit(permit, v, r, s);
        return output;
    }

    /*
    function proxyReceiveMessage(
        bytes calldata message,
        bytes calldata attestation
    ) external onlyOperator{

    }
    */

}

contract Factory {
    event ContractDeployed(address deployedAddress);

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