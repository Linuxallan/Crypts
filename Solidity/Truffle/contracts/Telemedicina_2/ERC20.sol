// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

interface IERC20 {

    function totalSupply () external view returns(uint);

    function increaseTotalSupply (uint _tokens) external;

    function balanceOf(address _account) external view returns(uint);

    function saldoDelegate(address _delegate, address _owner) external view returns(uint);

    function transferir(address _recipient, uint _tokens) external returns (bool);
    
    function transferFromDelegate(address _delegate, address _owner, uint _tokens) external returns(bool);

    event Transfer_event(address, address, uint);
    event Approval_event(address, address, uint);
}

contract ERC20 is IERC20 {

    string public constant name = "ERC20_Telemedicina_2";
    string public constant symbol = "TEL2";
    uint public constant decimals = 2;

    using SafeMath for uint;

    uint Total_Supply;
    mapping (address => uint) Balances_Mapp;

    constructor (uint _initialSupply){

        Total_Supply = _initialSupply;
        Balances_Mapp[msg.sender] = Total_Supply;
    }

    // Delegate
    mapping (address => mapping(address => uint)) Delegate_Mapp;

    // ------------------------------------------------------------

    function totalSupply() public override view returns(uint){

        return Total_Supply;
    }

    function increaseTotalSupply(uint _tokens) public override {
        
        Total_Supply += _tokens;

        Balances_Mapp[msg.sender] += _tokens;
    }

    function balanceOf(address _account) public view override returns(uint) {
        
        return Balances_Mapp[_account];
    }

    function saldoDelegate(address _owner, address _delegate) public override view returns(uint) {
        
        return Delegate_Mapp[_owner][_delegate];
    }

    function transferir(address _recipient, uint _tokens) public override returns(bool) {
        
        require(Balances_Mapp[msg.sender] >= _tokens, "No tienes fondos suficiente");

        Balances_Mapp[msg.sender] = Balances_Mapp[msg.sender].sub(_tokens);
        Balances_Mapp[_recipient] = Balances_Mapp[_recipient].add(_tokens);
        
        emit Transfer_event(msg.sender, _recipient, _tokens);

        return true;
    }

    function transferFromDelegate(address _owner, address _recipient, uint _tokens) public override returns(bool) {
        
        require(Balances_Mapp[_owner] >= _tokens);
        require(Delegate_Mapp[_owner][msg.sender] >= _tokens);

        Delegate_Mapp[_owner][msg.sender] = Delegate_Mapp[_owner][msg.sender].sub(_tokens);
        Balances_Mapp[_owner] = Balances_Mapp[_owner].sub(_tokens);

        Balances_Mapp[_recipient] = Balances_Mapp[_recipient].add(_tokens);

        emit Transfer_event(_owner, _recipient, _tokens);
        return true;
    }
}