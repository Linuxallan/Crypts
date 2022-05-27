// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./OperacionesBasicas.sol";
import "./InsuranceFactory.sol";

contract Laboratorio is OperacionesBasicas {

    address public Lab_Dir;
    address public Aseguradora_Dir;

    constructor (address _lab, address _insurance) {
        Lab_Dir = _lab;
        Aseguradora_Dir = _insurance;
    }

    struct Resultado {

        string diagnostico;
        string codigo_IPFS;
    }

    struct ServicioLab {

        string nombre;
        uint precio;
        bool estado;
    }

    // Mappings
    mapping (address => string) ServicioSolicitado_Mapp;
    mapping (address => Resultado) ResultadosCliente_Mapp;
    mapping (string => ServicioLab) ServiciosLab_Mapp;

    // Arrays
    address [] PeticionesServiciosDeCliente_Array;
    string [] ServiciosLabNombre_Array;

    // Eventos
    event ServicioFuncionando_event(string, uint);
    event ServicioEfectuado_event(address, string);

    // Restricciones
    modifier UnicLab(address _account) {
        require(_account == Lab_Dir);
        _;
    }

    function NuevoServicioLab(string memory _servicio, uint _valor) public UnicLab(msg.sender) {
        
        ServiciosLab_Mapp[_servicio] = ServicioLab(_servicio, _valor, true);

        ServiciosLabNombre_Array.push(_servicio);

        emit ServicioFuncionando_event(_servicio, _valor);
    }

    function DarResultado(address _cliente, string memory _diagnostico, string memory _ipfs) public UnicLab(msg.sender) {
        
        ResultadosCliente_Mapp[_cliente] = Resultado(_diagnostico, _ipfs);
    }

    //  ES UNA MANERA DIFERENTE DE RETORNAL VALORES
    function VisualizarDiagnostico(address _cliente) public view returns(string memory _diagnostico, string memory _ipfs) {
        
        _diagnostico = ResultadosCliente_Mapp[_cliente].diagnostico;
        _ipfs = ResultadosCliente_Mapp[_cliente].codigo_IPFS;
    }

    function ConsultarServicios() public view returns(string [] memory) {
        
        return ServiciosLabNombre_Array;
    }

    function ConsultarPrecioServicio(string memory _servicio) public view returns(uint) {
        
        return ServiciosLab_Mapp[_servicio].precio;
    }

    function DireccionLab() public view returns(address) {
        
        return Lab_Dir;
    }

    function PrestarServicio(address _account, string memory _servicio) public {
        
        // requerir que el cliente este asegurado
        InsuranceFactory ifac = InsuranceFactory(Aseguradora_Dir);
        ifac.FuncionUnicCliente(_account);

        require(ServiciosLab_Mapp[_servicio].estado == true, "No esta disponible el servicio");

        ServicioSolicitado_Mapp[_account] = _servicio;
        PeticionesServiciosDeCliente_Array.push(_account);

        emit ServicioEfectuado_event(_account, _servicio);
    }
}