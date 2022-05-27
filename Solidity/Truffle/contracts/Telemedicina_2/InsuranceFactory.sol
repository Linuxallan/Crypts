// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./OperacionesBasicas.sol";
import "./Laboratorio.sol";
import "./Aseguradora.sol";

contract InsuranceFactory is OperacionesBasicas {

    ERC20 private token;

    // insurance : seguro : direccion del contrato 'seguro'(servicio)
    address Insurance_Dir;
    address payable public Aseguradora_Dir;

    constructor () {

        token = new ERC20(10000);
        Insurance_Dir = address(this);
        Aseguradora_Dir = payable(msg.sender);
    }

    struct Cliente {

        address direccion;
        bool estado;
        address contrato_seguro;
    }

    struct Servicio {

        string nombre;
        uint valor;
        bool estado;
    }

    struct Lab {

        address direccion;
        bool validacion;
    }

    // Mappings
    mapping (address => Cliente) Clientes_Mapp;
    mapping(address => Lab) Labs_Mapp;
    mapping(string => Servicio) Servicios_Mapp;

    // Arrays
    string [] serviciosNombre_Array;
    address [] direccionesAseguradoras_Array;
    address [] direccionesLabs_Array;
    address [] direccionesClientes_Array;

    // restricciones
    modifier UnicClientes(address _account){

        FuncionUnicCliente(_account);
        _;
    }

    function FuncionUnicCliente(address _account) public view {
        
        require(Clientes_Mapp[_account].estado == true);
    }

    modifier UnicAseguradora(address _account) {

        require(_account == Aseguradora_Dir);
        _;
    }

    modifier Cliente_o_Aseguradora(address _cliente, address _aseguradora){

        require ((Clientes_Mapp[_cliente].estado == true && _cliente == _aseguradora) 
        || _aseguradora == Aseguradora_Dir);
        _;
    }

    // Eventos
    event Tokens_comprados_event(uint);
    event Nuevo_cliente_event(address _cliente, address _aseguradora);
    event Servicio_creado_event(string _servicio, uint _valor);
    event Nuevo_lab_event(address, address);

    // --------------------------- LOGICA --------------------

    function AsociarLab() public returns(bool){
        
        // Crear instancia de contrato Laboratorio
        address lab_contract = address(new Laboratorio(msg.sender, Insurance_Dir));
        Labs_Mapp[msg.sender] = Lab(lab_contract, true);

        direccionesLabs_Array.push(msg.sender);

        emit Nuevo_lab_event(msg.sender, lab_contract);

        return true;
    }

    function VerLaboratorios() public view UnicAseguradora(msg.sender) returns(address [] memory) {
        
        return direccionesLabs_Array;
    }

    function VerClientes() public view UnicAseguradora(msg.sender) returns(address [] memory) {
        
        return direccionesClientes_Array;
    }

    function BajaCliente(address _addrCliente) public UnicAseguradora(msg.sender) {
        
        Clientes_Mapp[_addrCliente].estado = false;
        Aseguradora(Clientes_Mapp[_addrCliente].contrato_seguro).BajarContratoCliente();
    }

    function ConsultarHistorialServiciosEfectuadosAClientes(address _addrCliente, address _addrAseguradora) public view Cliente_o_Aseguradora(_addrCliente, _addrAseguradora) returns(string memory){
        
        string memory historial = "";
        address dirCliente = Clientes_Mapp[_addrCliente].contrato_seguro;

        for(uint i = 0 ; i < serviciosNombre_Array.length ; i++){

            if(Servicios_Mapp[serviciosNombre_Array[i]].estado == true 
            && (Aseguradora(dirCliente).EstadoServicioSolicitadoCliente(serviciosNombre_Array[i]) == true)){

                Aseguradora.ServicioSolicitado memory servicio = Aseguradora(dirCliente).HistorialSolicitudesClientes(serviciosNombre_Array[i]);
                
                historial = string(abi.encodePacked(historial, "(", servicio.nombre, ", ", uint2str(servicio.valor), " )"));
            }
        }
        return historial;
    }

    // ----------------------- LOGICA SERVICIOS ---------------

    // requisito para otros contratos
    function EstadoServicio(string memory _servicio) public view returns(bool) {
        
        return Servicios_Mapp[_servicio].estado;
    }
    function CrearServicio(string memory _name, uint _valor) public UnicAseguradora(msg.sender) {
        
        Servicios_Mapp[_name] = Servicio(_name, _valor, true);
        serviciosNombre_Array.push(_name);

        emit Servicio_creado_event(_name, _valor);
    }

    function BajarServicio(string memory _name) public UnicAseguradora(msg.sender) {
        
        require(Servicios_Mapp[_name].estado == true);

        Servicios_Mapp[_name].estado = false;
    }

    function GetPrecioServicio(string memory _servicio) public view returns(uint) {
        
        require (Servicios_Mapp[_servicio].estado == true);

        return Servicios_Mapp[_servicio].valor;
    }

    function ConsultarServicioActivos() public view returns(string [] memory) {
        
        string [] memory servicios_activos = new string[](serviciosNombre_Array.length);

        uint contador = 0;

        for(uint i = 0 ; i < serviciosNombre_Array.length; i++){

            if(Servicios_Mapp[serviciosNombre_Array[i]].estado){

                servicios_activos[contador] = serviciosNombre_Array[i];
                contador++;
            }
        }
        return servicios_activos;
    }

    function ComprarTokens(address _account, uint _tokens) public UnicClientes(msg.sender){

        require(_tokens > 0);

        // revisar que el suministro del contrato sea suficiente
        require(token.balanceOf(Insurance_Dir) >= _tokens);

        token.transferir(_account, _tokens);
        
        emit Tokens_comprados_event(_tokens);
    }

    function MinarTokensParaAseguradoraContract(uint _tokens) public UnicAseguradora(msg.sender) {
        
        token.increaseTotalSupply(_tokens);
    }

}