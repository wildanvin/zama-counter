pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import { SepoliaZamaFHEVMConfig } from "fhevm/config/ZamaFHEVMConfig.sol";
import { SepoliaZamaGatewayConfig } from "fhevm/config/ZamaGatewayConfig.sol";
import "fhevm/gateway/GatewayCaller.sol";

contract SimpleTestAsyncDecrypt is SepoliaZamaFHEVMConfig, SepoliaZamaGatewayConfig, GatewayCaller {
    ebool xBool;
    bool public yBool;

    constructor() {
        xBool = TFHE.asEbool(true);
        TFHE.allowThis(xBool);
    }

    function requestBool() public {
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(xBool);
        Gateway.requestDecryption(cts, this.myCustomCallback.selector, 0, block.timestamp + 100, false);
    }

    function myCustomCallback(uint256 /*requestID*/, bool decryptedInput) public onlyGateway returns (bool) {
        yBool = decryptedInput;
        return yBool;
    }
}
