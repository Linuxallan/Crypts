// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";

contract Loteria {

    // inicializar token
    ERC20 private token;

    // Direcciones principalnes
    address public owner;
    address public contrato;

    uint tokens_inicial = 10000;

    constructor () {  

        token = new ERC20(tokens_inicial);
        owner = msg.sender;
        contrato = address(this);
    }

    // --------------------------------- TOKEN --------------------------------

    event Compra(address, uint);

    // Convertir valor de tokens a ethers
    function ValorTokenEnEther(uint _tokens) internal pure returns(uint){

        return _tokens * (1 ether);
    }

    // Restringir la ejecucion solo por el contrato
    modifier Unicamente(address _account){

        require(_account == contrato, "No tienes permiso para ejecutar esta funcion");
        _;
    }

    // Minar tokens
    function MinarTokens(uint _tokens) external Unicamente(msg.sender){

        token.increaseTotalSupply(_tokens);
    }

    function ComprarTokens(uint _tokens) public payable returns(bool){

        uint enEthers = ValorTokenEnEther(_tokens);
        require (msg.value >= enEthers, "No puso suficiente ethers para comprar");

        uint supply = token.balaceOf(contrato);
        require (_tokens <= supply, "No hay suficiente suministro para comprar");

        // devolver excedente
        uint excedente = msg.value - enEthers;
        payable(msg.sender).transfer(excedente);

        // transferir a cliente
        token.transferir(msg.sender, _tokens);

        emit Compra(msg.sender, _tokens);

        return true;
    }

    function TokensDisponibles() public view returns(uint){
        return token.balaceOf(contrato);
    }

    function Poso() public view returns(uint){

        return token.balaceOf(owner);
    }

    function MisTokens() public view returns(uint){

        return token.balaceOf(msg.sender);
    }

    // --------------------------------- LOTERIA --------------------------------

    // Valor del voleto de la loteria
    uint public precioVoleto = 5;

    // Asociar voletos a un cliente
    mapping (address => uint []) VoletosCliente;

    // Aray de boletos
    uint [] Voletos_comprados;

    uint randNance = 0;

    // mapping para relaciona un voleto con la perona quien lo compro
    mapping (uint => address) DuenoVoleto;

    function ComprarVoleto(uint _numBoletos) public returns(bool){

        uint valor = _numBoletos * precioVoleto;

        require (valor <= MisTokens(), "No tienes suficientes fondos");

        token.transferirLoteria(msg.sender, owner, valor);

        // por cadaboleto comprado se ejecuta el for
        for (uint i = 0; i < _numBoletos; i++){

            uint random = uint(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNance))) % 10000);
            randNance++;

            VoletosCliente[msg.sender].push(random);
            Voletos_comprados.push(random);

            DuenoVoleto[random] = msg.sender;
        }

        return true;
    }

    function MisVoletos() public view returns (uint [] memory){

        return VoletosCliente[msg.sender];
    }

    function GenerarGanador() public Unicamente(msg.sender){
        
        require (Voletos_comprados.length > 0, "No se ha comprado ningun voleto");

        uint longitud = Voletos_comprados.length;

        // Eleccion aleatoria de una posicion del array
        uint posicion = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % longitud);
        // Eleccion del voleto
        uint eleccion = Voletos_comprados[posicion];
        // encontrar ganador
        address ganador = DuenoVoleto[eleccion];

        token.transferirLoteria(owner, ganador, Poso());
    }

    function DevoldertokensParaEthers(uint _tokens) public payable {

        require(_tokens > 0, "Da un valor correcto");
        require(_tokens >= MisTokens(), "No tienes suficientes tokens");

        token.transferirLoteria(msg.sender, address(this), _tokens);
        payable(msg.sender).transfer(ValorTokenEnEther(_tokens));
    }
}



