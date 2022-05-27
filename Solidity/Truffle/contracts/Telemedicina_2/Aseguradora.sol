// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./OperacionesBasicas.sol";
import "./Laboratorio.sol";

contract Aseguradora is OperacionesBasicas {

    enum Estado {Alta, Baja}

    struct Owner {

        address direccion;
        uint saldo;
        Estado estado;
        ERC20 token;
        address insurance;
        address payable aseguradora;
    }

    Owner Propietario;

    constructor(address _owner, ERC20 _token, address _insurance, address _aseguradora){

        Propietario.direccion = _owner;
        Propietario.saldo = 0;
        Propietario.estado = Estado.Alta;
        Propietario.token = _token;
        Propietario.insurance = _insurance;
        Propietario.aseguradora = payable(_aseguradora);
    }

    // Objetos complejos
    struct ServicioSolicitado {

        string nombre;
        uint valor;
        bool estado;
    }

    struct ServicioSolicitado_LabDefinido {

        string nombre;
        uint valor;
        address dir_lab;
    }

    // Eventos
    event BajaCLiente(address);

    // Restricciones 
    modifier UnicAseguradora(address _account){

        require(_account == Propietario.direccion);
        _;
    }

    // Mappings
    mapping(string => ServicioSolicitado) HistorialSolicitudes_cliente_Mapp;

    // Arrays
    ServicioSolicitado_LabDefinido [] HistorialSolicitudes_labDefinido_Array;

    function BajarContratoCliente() public UnicAseguradora(msg.sender) {
        
        // Primero el evento, despues la destruccion
        emit BajaCLiente(msg.sender);

        selfdestruct(payable(msg.sender));
    }

    function EstadoServicioSolicitadoCliente(string memory _servicio) public view returns(bool) {
        
        return HistorialSolicitudes_cliente_Mapp[_servicio].estado;
    }

    function HistorialSolicitudesClientes(string memory _servicio) public view returns(ServicioSolicitado memory) {
        
        return HistorialSolicitudes_cliente_Mapp[_servicio];
    }

    function SolicitudesHistorial_LabDefinido() public view returns(ServicioSolicitado_LabDefinido [] memory) {
        
        return HistorialSolicitudes_labDefinido_Array;
    }

    function ComprarTokensPorAseguradora(uint _tokens) public payable UnicAseguradora(msg.sender) {
        
        require(_tokens > 0);
        uint valorEther = CalcularPrecioTokenEther(_tokens);
        require(msg.value >= valorEther);

        uint returnValue = msg.value - valorEther;

        // Retornar ethers
        payable(msg.sender).transfer(returnValue);

        // Se accede a una funcion en el contrat IsuranceFactory para comorar tokens
        InsuranceFactory(Propietario.insurance).ComprarTokens(msg.sender, _tokens);
    }

    function BalanceOf() public view UnicAseguradora(msg.sender) returns(uint) {
        
        return Propietario.token.balanceOf(address(this));
    }

    function DevolverTokens(uint _tokens) public UnicAseguradora(msg.sender)  {
        
        require(_tokens > 0);
        require(_tokens <= BalanceOf(), "Escede sus fondos");

        Propietario.token.transferir(Propietario.aseguradora, _tokens);

        payable(msg.sender).transfer(CalcularPrecioTokenEther(_tokens));
    }

    function PedirServicio(string memory _servicio) public UnicAseguradora(msg.sender) {
        
        require(InsuranceFactory(Propietario.insurance).EstadoServicio(_servicio) == true);

        uint costoServicio = InsuranceFactory(Propietario.insurance).GetPrecioServicio(_servicio);

        require(costoServicio <= BalanceOf());

        Propietario.token.transferir(Propietario.aseguradora, costoServicio);

        HistorialSolicitudes_cliente_Mapp[_servicio] = ServicioSolicitado(_servicio, costoServicio, true);
    }

    function PedirServicioLabDefinido(address _dir_lab, string memory _servicio) payable public UnicAseguradora(msg.sender) {
        
        Laboratorio lab = Laboratorio(_dir_lab);

        require(msg.value == lab.ConsultarPrecioServicio(_servicio) * 1 ether);

        lab.PrestarServicio(msg.sender, _servicio);
        payable(lab.DireccionLab()).transfer(lab.ConsultarPrecioServicio(_servicio) * 1 ether);

        HistorialSolicitudes_labDefinido_Array.push(ServicioSolicitado_LabDefinido(_servicio, lab.ConsultarPrecioServicio(_servicio), _dir_lab));
    }
}