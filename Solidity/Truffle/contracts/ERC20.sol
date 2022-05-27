// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

interface IERC20 {
    
    // Devuelve la cantidad de token disponibles para el mundo: Suministro.
    function totalSupply() external view returns(uint256);
    
    // Incrementar el suministro de tokens y asociarlos a quien los ha minado
    function increaseTotalSupply(uint _tokensMinados) external;
    
    // Devuelve la cantidad de token de una direccion: Balance
    function balaceOf(address _account) external view returns(uint256);
    
    // Devuelve la cantidad de tokens que el spender (gastador) podra gastar en nombre del propietario (owner).
    function allowance(address _spender, address _owner) external view returns(uint256);
    
    // Devuelve true o false si se puede hacer la transferencia de tokens
    function transferir(address _recipient, uint256 _amount) external returns(bool);
    
    // Devuelve true o false si se puede o no hacer la transferencia de gasto.
    function approve(address _spender, uint256 _amount) external returns(bool);
    
    // Devuelve true o false si la operacion de transferencia fue exitosa o no.
    // La transferencia la ace un delegado que tiene a disposicion tokens concedidos de otro propietario.
    function transferFrom(address _spender, address _recipient, uint256 _amount) external returns(bool);
    
    // Evento que se debe emitir cuando una cantidad de tokens pasen de un Origen a un Destino.
    event Transfer(address indexed _owner, address indexed _to, uint256 _value);
    
    // Evento que se emite cuando el metodo allowance se ejecuta exitosamente.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ERC20Basic is IERC20{
    
    // Variables globales descriptivas de nustro token.
    string public constant name = "ERC20BlockchainAZ";
    string public constant symbol = "TAZ";
    uint8 public constant decimals = 2;
    
    // Se usara el metodo SafeMah para typos de datos uint256. Este metodo se encuentra en el archivo importado.
    using SafeMath for uint256; 
    
    // Mapping para referenciar a cada direccion su balance.
    mapping (address => uint) balances;
    
    // Mapping para delegar el uso de ciertos tokens, los tokens sihuen siendo del dueño, no hay transferencia.
    // El dueño de los tokens puede delegar el uso de sus tokens.
    mapping (address => mapping (address=> uint)) allowed;
    
    // Variiable que tiene la cantidad de inicio de tokens
    uint256 totalSupply_ ;
    
    // Se crea nuestro Token, Nace el token con un suministro definido.
    constructor (uint256 _initialSuply){
        
        totalSupply_ = _initialSuply;
        balances[msg.sender] = totalSupply_;
    }
    
    
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    
    
    function totalSupply() public override view returns(uint256){
        return totalSupply_;
    }
    
    function increaseTotalSupply(uint _tokensMinados) public override{
        
        // Sumar al suministro la cantidad de tokens minados.
        totalSupply_ += _tokensMinados;
        
        // Asignar los tokens minados a la cuenta de quien los esta registrando.
        balances[msg.sender] += _tokensMinados;
    }
    
    function balaceOf(address _account) public override view returns(uint256){
        return balances[_account];
    }
    
    function allowance(address _owner, address _delegate) public override view returns(uint256){
        return allowed[_owner][_delegate];
    }
    
    function transferir(address _recipient, uint256 _tokens) public override returns(bool){
        
        // Validar que el emisor tenga los suficientes tokens a transferir.
        require (balances[msg.sender] >= _tokens);
        
        // Operaciones de sumar y restar en los balances
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_recipient] = balances[_recipient].add(_tokens);
        
        // Notificar al mundo de la operacion: sistema distribuido.
        emit Transfer (msg.sender, _recipient, _tokens);
        
        return true;
    }
    
    function approve(address _delegate, uint256 _tokens) public override returns(bool){
        
        // Validar que el propietario de os tokens tenga los suficientes para delegar.
        require (balances[msg.sender] >= _tokens);
        
        // Delegar los tokens a una cuenta de tercero, NO se transfieren.
        allowed[msg.sender][_delegate] = _tokens;
        
        // Notificar al mundo de la operacion de delegacion de tokens.
        emit Approval (msg.sender, _delegate, _tokens);
        
        return true;
    }
    
    function transferFrom(address _owner, address _buyer, uint256 _tokens) public override returns(bool){
        
        // Validar que tanto el propietario como el delegado tengan a disposicion los tokens especificados.
        require (balances[_owner] >= _tokens);
        require (allowed[_owner][msg.sender] >= _tokens);
        
        // Restar los tokens delegados de la cuenta del delegado.
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_tokens);
        
        // Restar los tokens de la cuenta del propietario
        balances[_owner] = balances[_owner].sub(_tokens);
        
        // Sumar los tokens a la cuenta del comprador.
        balances[_buyer] = balances[_buyer].add(_tokens);
        
        // Evento para notificar al mundo de la transferencia.
        emit Transfer (_owner, _buyer, _tokens);
        
        return true;
    }
}