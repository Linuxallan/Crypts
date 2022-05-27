// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

contract OperacionesBasicas {

    using SafeMath for uint;

    function CalcularPrecioTokenEther(uint _tokens) internal pure returns(uint) {
        
        return _tokens.mul(1 ether);
    }

    function GetBalanceContract() public view returns(uint) {
        
        // balance : comando reservado (parece)
        return payable(address(this)).balance;
    }

    function uint2str(uint _i) internal pure returns(string memory){
        
        if(_i == 0){
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len -1;
        while (_i != 0){
            uint8 u = uint8(48 + _i % 10);
            bstr[k--] = bytes1(u);
            _i /= 10;
        }
        return string(bstr);
    }
}