// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {JustPayContract} from "./JustPay.sol"; // should replace

contract Factory {
    event ContractDeployed(address deployedAddress);
 
    function computeAddress(uint256 _salt_int, address operator) external view returns (address){
        bytes32 _salt = bytes32(_salt_int);
        bytes memory bytecode = abi.encodePacked(
            type(JustPayContract).creationCode,
            abi.encode(msg.sender),
            abi.encode(operator)
        );
        return Create2.computeAddress(_salt, keccak256(bytecode), address(this));
    }

    function deploy(uint256 _salt_int, address operator) external returns (address){
        bytes32 _salt = bytes32(_salt_int);
        bytes memory bytecode = abi.encodePacked(
            type(JustPayContract).creationCode,
            abi.encode(msg.sender),
            abi.encode(operator)
        );
        address deployedAddr = Create2.deploy(0, _salt, bytecode);
        emit ContractDeployed(deployedAddr);
        return deployedAddr;
    }
}