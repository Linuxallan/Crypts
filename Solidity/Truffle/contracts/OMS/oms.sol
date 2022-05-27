// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract OMS {

    address public oms;

    constructor (){
        
        oms = msg.sender;
    }

    // Verificar que la direccion tenga permisos para crear su 
    // propio smart contract
    mapping (address => bool) public Centros_salud;
    mapping (address => address) public DireccionContrato_centroSalud;

    // Array de direcciones con smart contracts
    address [] public direcciones_salud;
    address [] Solicitudes;

    // Evento para nuevo contrato creado
    event CentroSaludCreado (address);

    // Verifica que solo la OMS pueda crear contratos inteligentes para 
    // un centro de salud
    modifier UnicamenteOMS(address _direccion){
        
        require(_direccion == oms, "No eres la OMS");
        _;
    }

    // Centro medico solicita su smart contract
    function SolicitarAcceso() public {

        Solicitudes.push(msg.sender);
    }

    // Visualizar quienes an hecho solicitud de smart contract a OMS
    function VerSolicitudes() public view UnicamenteOMS(msg.sender) returns(address [] memory){
        
        return Solicitudes;
    }

    // Dar el pase a un centro de salud para que cree su smart contract
    function HabilitarCentroSalud(address _account) public UnicamenteOMS(msg.sender) {
        
        Centros_salud[_account] = true;
        emit CentroSaludCreado(_account);
    }

    // Funcion para crear un smart contract para un centro de salud
    function FactoryCentroSalud() public {
        
        require(Centros_salud[msg.sender] == true, "No tienes permiso para cerar un contrato");

        // Generar un smart contract para el centro de salud
        address contrato_centroSalud = address(new CentroSalud(msg.sender));

        // Registrar el centro de salud creado
        direcciones_salud.push(contrato_centroSalud);

        DireccionContrato_centroSalud[msg.sender] = contrato_centroSalud;

        emit CentroSaludCreado (msg.sender);
    }
}

// -------------------------- CENTRO SALUD ----------------------

contract CentroSalud {

    // Direcciones iniciales del contrato, y centro de salud responsable
    address public contrato;
    address public centroSalud;

    constructor (address _account) {

        centroSalud = _account;
        contrato = address(this);
    }

    /* -- ANTIGUO
    // Relacionar el hah del paciente con su resultado (true, false)
    // Se relaciona el hash y no el nombre por que es privado
    mapping (bytes32 => bool) ResultadoCOVID;

    mapping (bytes32 => string) ResultadoCOVID_IPFS;
    */

    // -- NUEVO
    struct Resultado {

        bool resultado;
        string codigo_IPFS;
    }

    // Relaciona el hash de la persona anonimo con sus resultados en un objeto
    mapping (bytes32 => Resultado) Resultados;

    event ResultadosDisponibles (bytes32, string);

    modifier UnicamenteCentroSalud(address _account){

        require(_account == centroSalud, "No tienes autorizacion");
        _;
    }

    // Centro de salud publica resultados COVID de un paciente
    // ID cliente , Resultado , Codigo IPFS -->
    // Paciente : 12345X , true , QmUCryj8QwtjemdoJcAVU68D2xY4yG3LWe4fKvvWPgqppa
    function ResultadoMedicosCOVID(string memory _idPaciente, bool _resultado, string memory _ipfs) public UnicamenteCentroSalud(msg.sender) {
        
        // crear el hash del los datos del paciente para volverlo incognito
        bytes32 hash_paciente = keccak256(abi.encodePacked(_idPaciente));

        /* -- ANTIGUO
        // Asociar el hash de un paciente con su resultado COVID
        ResultadoCOVID[hash_paciente] = _resultado;

        // relacionar IPFS
        ResultadoCOVID_IPFS[hash_paciente] = _ipfs;

        */

        // -- NUEVO
        Resultados[hash_paciente] = Resultado(_resultado, _ipfs);

        emit ResultadosDisponibles(hash_paciente, "QmUCryj8QwtjemdoJcAVU68D2xY4yG3LWe4fKvvWPgqppa");
    }

    // funcion para que los clientes vean sus resultados
    function VisualizarResultados(string memory _idPaciente) public view returns(bool, string memory) {
        
        // crear el hash del paciente para extraer el objeto de sus datos a traves de un mapping
        bytes32 hash_paciente = keccak256(abi.encodePacked(_idPaciente));

        return (Resultados[hash_paciente].resultado, Resultados[hash_paciente].codigo_IPFS);
    }
}