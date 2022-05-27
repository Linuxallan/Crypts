// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./OperacionesBasicas.sol";
import "./ERC20.sol";

contract InsuranceFactory is OperacionesBasicas{

    // Token de tipo contrato ERC20
    ERC20 private token;

    // addres principales
    address Insurance_Dir;
    address payable public Aseguradora_Dir;

    // Inicializacion de contrato token y registro de direcciones principales
    constructor () {

        token = new ERC20(1000);
        Insurance_Dir = address(this);
        Aseguradora_Dir = payable(msg.sender);
    }

    // Objetos complejos
    struct Cliente {

        address direccion;
        bool autorizado;
        address contratoAddress; // Poliza seguro
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
    mapping (address => Cliente) ClientesMapp;

    mapping (address => Lab) LabsMapp;
    
    mapping (string => Servicio) ServiciosMapp;

    // Arrays
    string [] servicios_Array;
    address [] direccionesAseguradoras_Array;
    address [] direccionesLabs_Array;
    address [] direccionesClientes_Array;

    // Restricciones
    modifier UnicClientes(address _account) {

        // require(ClientesMapp[_account].autorizado == true, "No eres cliente asegurado");        
        FuncionUnicClientes(_account);
        _;
    }

    function FuncionUnicClientes(address _account) public view {
        
        require(ClientesMapp[_account].autorizado == true, "No eres cliente asegurado");  
    }

    modifier UnicAseguradora(address _account) {

        require(_account == Aseguradora_Dir, "No eres la aseguradora");
        _;
    }

    modifier Cliente_o_Aseguradora(address _cliente, address _aseguradora){
        
        require( (ClientesMapp[_cliente].autorizado == true && _cliente == _aseguradora)
            || _aseguradora == Aseguradora_Dir, "No eres cliente no la aseguradora");
        _;
    }

    //  Eventos
    event TokensComprados_event (uint);
    event ServicioProporcionado_event (address _cliente, string _servicio, uint tokens);
    event LabCreado_event (address _owner, address _laboratorio);
    event NuevoClienteAsegurado_event (address _cliente, address _aseguradora);
    event BajaCliente_event (address _cliente);
    event ServicioCreado (string _servicio, uint _valor);
    event BajaServicio_event (string);

    // ----------------------- LOGICA --------------------------

    function CrearLab() public {
        
        // Agrgar direccion laboratorio al array
        direccionesLabs_Array.push(msg.sender);

        // Crear un contrato Laboratorio
        // Obtener la direccion del contrato creado
        address labContract = address(new Laboratorio(msg.sender, Insurance_Dir));

        // Crear objeto complejo de tipo Lab
        Lab memory lab = Lab(labContract, true);

        // Mapping de laboratorio por su direccion: msg.sender = owner
        LabsMapp[msg.sender] = lab;

        emit LabCreado_event (msg.sender, labContract);
    }

    function CrearContratoAseguradora() public {
        
        direccionesAseguradoras_Array.push(msg.sender);
        address contrato = address(new Aseguradora(msg.sender, token, Insurance_Dir, Aseguradora_Dir));
        ClientesMapp[msg.sender] = Cliente(msg.sender, true, contrato);

        emit NuevoClienteAsegurado_event(msg.sender, contrato);
    }

    // Devolver lista de laboratorios disponibles
    function Laboratorios() public view UnicAseguradora(msg.sender) returns(address [] memory) {
        
        return direccionesAseguradoras_Array;
    }

    function Clientes() public view UnicAseguradora(msg.sender) returns(address [] memory) {
        
        return direccionesClientes_Array;
    }

    function ConsultarHistorialServiciosEfectuadosAClientes (address _addrCliente, address _addrAseguradora) public view Cliente_o_Aseguradora(_addrCliente, _addrAseguradora) returns(string memory){
        
        string memory historial = "";
        address dirCliente = ClientesMapp[_addrCliente].contratoAddress;

        for (uint i = 0 ; i < servicios_Array.length ; i++){

            if(ServiciosMapp[servicios_Array[i]].estado == true
                && (Aseguradora(dirCliente).EstadoServicioSolicitadoCliente(servicios_Array[i]) == true)){
                    
                    (Aseguradora.ServicioSolicitado memory servicio) = Aseguradora(dirCliente).HistorialSolicitudesClientes(servicios_Array[i]);
                    historial = string(abi.encodePacked(historial, "(", servicio.nombre, ", ", uint2str(servicio.valor), " )"));
                }
        }
        return historial;
    }

    // eliminar un cliente solo por la aseguradora
    function BajaCliente(address _accountCliente) public UnicAseguradora(msg.sender) {
        
        ClientesMapp[_accountCliente].autorizado = false;
        Aseguradora(ClientesMapp[_accountCliente].contratoAddress).BajarContratoCliente();
        emit BajaCliente_event(_accountCliente);
    }

    // -------------------- LOGICA SERVICIOS ---------------------

    function CrearServicio(string memory _name, uint256 _precio) public UnicAseguradora(msg.sender) {
        
        ServiciosMapp[_name] = Servicio(_name, _precio, true);
        servicios_Array.push(_name);
        emit ServicioCreado(_name, _precio);
    }

    // La validacion del estado del servicio se hizo en una funcion a parte
    // por que puede ser reusado.
    function BajaServicio(string memory _name) public UnicAseguradora(msg.sender){

        require(EstadoServicio(_name) == true, "No existe servicio");

        ServiciosMapp[_name].estado = false;
        emit BajaServicio_event(_name);
    }

    function EstadoServicio(string memory _name) public view returns(bool){
        
        return ServiciosMapp[_name].estado;
    }

    function GetPrecioServicio(string memory _nombre) public view returns(uint256){

        require(EstadoServicio(_nombre) == true, "El servicio no esta de alta");
        return ServiciosMapp[_nombre].valor;
    }

    // INTERESANTE COMO SE AGREGAN DATOS ESPECIFICOS AL ARRAY
    function ConsultarServicioActivos(string memory _name) public view returns(string [] memory){
        
        string [] memory serviciosActivos_Array = new string[](servicios_Array.length);
        uint contador = 0;

        for (uint256 i = 0; i < servicios_Array.length; i++) {
            
            if(EstadoServicio(_name)){

                serviciosActivos_Array[contador] = servicios_Array[i];
                contador++;
            }
        }
        return serviciosActivos_Array;
    }

    // Funcion para que una aseguradora compre tokens
    // No se por que es necesario la ingesta de la direccion como parametr
    function ComprarTokens(address _account, uint _tokens) public UnicClientes(msg.sender) {
        
        require(_tokens > 0);
        // Ver suministro de tokens del contrato
        require(token.balaceOf(Insurance_Dir) >= _tokens, "No hay suministro suficiente para comprar");
        
        token.transferir(_account, _tokens);

        emit TokensComprados_event(_tokens);
    }

    function MinarTokensParaAseguradoraContract(uint _tokens) public UnicAseguradora(msg.sender) {
        
        token.increaseTotalSupply(_tokens);
    }
}

    // ----------------------- CONTRATO LABORATORIO --------------------------

contract Laboratorio is OperacionesBasicas {

    address public Lab_Dir;
    address public Aseguradora_Dir;
    constructor (address _lab, address _insuranse){

        Lab_Dir = _lab;
        Aseguradora_Dir = _insuranse;
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

    mapping (address => string) ServicioSolicitado_Mapp;
    mapping (address => Resultado) ResultadosCliente_Mapp;

    mapping (string => ServicioLab) ServiciosLab_Mapp;

    address [] PeticionesServiciosDeCliente_Array;
    string [] ServiciosLab_Array;

    event ServicioFuncionando_event(string, uint);
    event DarServicio_event (address, string);

    modifier UnicamenteLab(address _account) {

        require(Lab_Dir == _account, "No eres el laboratorio");
        _;
    }

    function NuevoServicioLab(string memory _servicio, uint _precio) public UnicamenteLab(msg.sender) {
        
        ServiciosLab_Mapp[_servicio] = ServicioLab(_servicio, _precio, true);
        ServiciosLab_Array.push(_servicio);
        emit ServicioFuncionando_event(_servicio, _precio);
    }

    function DarResultado(address _cliente, string memory _diagnostico, string memory _ipfs) public UnicamenteLab(msg.sender) {
        
        ResultadosCliente_Mapp[_cliente] = Resultado(_diagnostico, _ipfs);
    }

    // MANERA NUEVA DE RETORNAR VALORES
    function VisualizarDiagnostico(address _cliente) public view returns(string memory _diagnostico, string memory _codigoIPFS) {
        
        _diagnostico =  ResultadosCliente_Mapp[_cliente].diagnostico;
        _codigoIPFS = ResultadosCliente_Mapp[_cliente].codigo_IPFS;
    }

    // mostrar servicios del laboratorio
    function ConsultarServicios() public view returns(string [] memory) {
        
        return ServiciosLab_Array;
    }

    function ConsultarPrecioServicio(string memory _servicio) public view returns(uint){

        return ServiciosLab_Mapp[_servicio].precio;
    }

    // Otorgar servicio a cliente
    function DarServicio(address _account, string memory _servicio) public{

        // Requerir que el cliente este asegurado
        InsuranceFactory IF = InsuranceFactory(Aseguradora_Dir);
        IF.FuncionUnicClientes(_account);

        require(ServiciosLab_Mapp[_servicio].estado == true, "No esta disponible el servicio");

        ServicioSolicitado_Mapp[_account] = _servicio;
        PeticionesServiciosDeCliente_Array.push(_account);

        emit DarServicio_event(_account, _servicio);
    }

    function DireccionLab() public view returns(address){
        return Lab_Dir;
    }
}


    // ----------------------- CONTRATO ASEGURADORA --------------------------

contract Aseguradora is OperacionesBasicas {

    enum Estado {Alta, Baja}

    struct Owner {
        address direcion;
        uint saldo;
        Estado estado;
        ERC20 tokens;
        address insurance;
        address payable aseguradora;
    }

    Owner Propietario;
    constructor (address _owner, ERC20 _token, address _insurance, address _aseguradora) {

        Propietario.direcion = _owner;
        Propietario.saldo = 0;
        Propietario.estado = Estado.Alta;
        Propietario.tokens = _token;
        Propietario.insurance = _insurance;
        Propietario.aseguradora = payable(_aseguradora);
    }

    // Solicitar servicio por parte del cliente
    struct ServicioSolicitado {

        string nombre;
        uint valor;
        bool estado;
    }

    // Servicio solicitado asociado a un laboratorio
    struct ServicioSolicitado_LabDefinido{

        string nombre;
        uint valor;
        address direccion_Lab;
    }

    // Asociar historial de solicitudes y almacenarlas en un Array de tipo objeto complejo
    mapping (string => ServicioSolicitado) HistorialSolicitudes_clienteMapp;
    ServicioSolicitado_LabDefinido [] HistorialSolicitudes_labDefinido_Array;

    // retornar historial de solicitudes de clientes con laboratorio definido
    function SolicitudesHistorial_LabDefinido() public view returns(ServicioSolicitado_LabDefinido [] memory) {
        
        return HistorialSolicitudes_labDefinido_Array;
    }

    function HistorialSolicitudesClientes(string memory _servicio) public view returns(ServicioSolicitado memory) {
        
        return HistorialSolicitudes_clienteMapp[_servicio];
    }

    function EstadoServicioSolicitadoCliente(string memory _servicio) public view returns(bool) {
        
        return HistorialSolicitudes_clienteMapp[_servicio].estado;
    }

    // restringir a solo el ppropietario de la poliza del contrato
    modifier Unicamente(address _account){

        require(_account == Propietario.direcion, "No eres propietario de la poliza");
        _;
    }

    event BajaCliente(address);

    function BajarContratoCliente() public Unicamente(msg.sender){
        
        emit BajaCliente(msg.sender);

        // selfdestruct : comando reservado de solidity para destruir contrato
        selfdestruct(payable(msg.sender));
    }

    function ComprarTokensPorAseguradora(uint _tokens) public payable Unicamente(msg.sender) {
        
        require(_tokens > 0);
        uint valorEther = CalcularPrecioToken(_tokens);
        require(msg.value >= valorEther, "No colocaste suficientes ehters para tu compra de tokens");

        uint returnValue = msg.value - valorEther;

        // Retornar ether de excedentes ingresados en msg.value
        payable(msg.sender).transfer(returnValue);

        // Se accede a una funcion en el contrat IsuranceFactory para comorar tokens
        InsuranceFactory(Propietario.insurance).ComprarTokens(msg.sender, _tokens);
    }

    function BalanceOf() public view Unicamente(msg.sender) returns(uint) {
        
        return Propietario.tokens.balaceOf(address(this));
    }

    // conversion de token a ethers para devolverlos a lo billetera
    function DevolverTokens(uint _tokens) public Unicamente(msg.sender) {
        
        require(_tokens > 0);
        require(_tokens <= BalanceOf(), "Excedes la cantidade de tokens que tienes para devolver");

        // El objeto Propietario tiene un atributo de tipo contrato token
        // --> asi puede acceder a las funciones del contrato token
        Propietario.tokens.transferir(Propietario.aseguradora, _tokens);

        payable(msg.sender).transfer(CalcularPrecioToken(_tokens));
    }

    // Cliente pide servicio
    function PedirServicio(string memory _servicio) public Unicamente(msg.sender) {
        
        require(InsuranceFactory(Propietario.insurance).EstadoServicio(_servicio) == true);

        uint costoServicio = InsuranceFactory(Propietario.insurance).GetPrecioServicio(_servicio);

        require(costoServicio <= BalanceOf(), "No tienes fondos suficiente");

        Propietario.tokens.transferir(Propietario.aseguradora, costoServicio);

        HistorialSolicitudes_clienteMapp[_servicio] = ServicioSolicitado(_servicio, costoServicio, true);
    }

    // Cliente pide servicio con laboratorio
    function PedirServicioLabDefinido(address _dir_lab, string memory _servicio) payable public Unicamente(msg.sender){

        Laboratorio lab = Laboratorio(_dir_lab);

        require(msg.value == lab.ConsultarPrecioServicio(_servicio) * 1 ether);    

        lab.DarServicio(msg.sender, _servicio);
        payable(lab.DireccionLab()).transfer(lab.ConsultarPrecioServicio(_servicio) * 1 ether);

        HistorialSolicitudes_labDefinido_Array.push(ServicioSolicitado_LabDefinido(_servicio, lab.ConsultarPrecioServicio(_servicio), _dir_lab));
    }
}