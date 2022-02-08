// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.9.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./BasicOperations.sol";
import "./ERC20.sol";

//Insurance Company Contract
contract InsuranceFactory is BasicOperations {
    //------------------- Token Contract Instance ------------------//
    ERC20Basic private token;

    //------------------- Necessary Addreses ------------------//
    address Insurance;
    address payable public Aseguradora;

    constructor() public {
        token = new ERC20Basic(100);
        Insurance = address(this); //Address of the contract being initialized
        Aseguradora = payable(msg.sender);
    }

    //------------------- Necessary Structures ------------------//
    struct client {
        address AddressClient;
        bool AuthorizationClient;
        address AddressContract;
    }

    struct service {
        string NameService;
        uint256 PriceTokenService;
        bool StatusService;
    }

    struct lab {
        address AddressContractLab;
        bool ValidationLab;
    }

    //------------------- Necessary Arrays for clients, services and labs ------------------//
    mapping(address => client) public MappingInsured;
    mapping(string => service) public MappingServices;
    mapping(address => lab) public MappingLabs;

    //------------------- Necessary Maps for clients, services and labs ------------------//
    address[] AddressesInsured;
    string[] private NameServices;
    address[] AddressesLabs;

    function FunctionOnlyInsured(address _addressInsured) public view {
        require(
            MappingInsured[_addressInsured].AuthorizationClient == true,
            "Unauthorized Insured Address"
        );
    }

    //------------------- Modifiers and Restrictions about insured and insurers ------------------//
    modifier OnlyInsured(address _addressInsured) {
        FunctionOnlyInsured(_addressInsured);
        _;
    }

    modifier OnlyInsurer(address _addressInsurer) {
        require(
            Aseguradora == _addressInsurer,
            "Unauthorized Insurance Address"
        );
        _;
    }

    modifier Insured_or_Insurer(
        address _addressInsured,
        address _IncomingAddress
    ) {
        require(
            (MappingInsured[_addressInsured].AuthorizationClient == true &&
                _addressInsured == _IncomingAddress) ||
                Aseguradora == _IncomingAddress,
            "Only Insurance company and insured"
        );
        _;
    }

    //------------------- Events ------------------//
    event EventBought(uint256); //Tokens EventBought
    event EventProvidedService(address, string, uint256); //Insured, Service Name, Price
    event EventLabCreated(address, address); //Lab, Contract
    event EventInsuredCreated(address, address); //idem
    event EventLostInsured(address); //Client address
    event EventServiceCreated(string, uint256); //name, Price
    event EventLostService(string);

    function LabCreation() public {
        AddressesLabs.push(msg.sender);

        address AddressLab = address(new Lab(msg.sender, Insurance));
        lab memory Laboratory = lab(AddressLab, true); //Struct creation
        MappingLabs[msg.sender] = Laboratory; //Mapping creation

        emit EventLabCreated(msg.sender, AddressLab); //Event emition
    }

    function InsuredContractCreation() public {
        AddressesInsured.push(msg.sender);

        address AddressInsured = address(
            new InsuranceHealthRecord(msg.sender, token, Insurance, Aseguradora)
        );
        MappingInsured[msg.sender] = client(msg.sender, true, AddressInsured);

        emit EventInsuredCreated(msg.sender, AddressInsured);
    }

    function Labs()
        public
        view
        OnlyInsurer(msg.sender)
        returns (address[] memory)
    {
        return AddressesLabs;
    }

    function Insured()
        public
        view
        OnlyInsurer(msg.sender)
        returns (address[] memory)
    {
        return AddressesInsured;
    }

    function CheckInsuredHistory(
        address _insuredAddress,
        address _consultantAddress
    )
        public
        view
        Insured_or_Insurer(_insuredAddress, _consultantAddress)
        returns (string memory)
    {
        string memory history = "";
        address insuredContractAddress = MappingInsured[_insuredAddress]
            .AddressContract;

        for (uint256 i = 0; i < NameServices.length; i++) {
            if (
                MappingServices[NameServices[i]].StatusService &&
                InsuranceHealthRecord(insuredContractAddress)
                    .InsuredServiceStatus(NameServices[i]) ==
                true
            ) //First I verify if the service is available and then I also varify if the service has been completed in the insured contract
            // InsuranceHealthRecord(insuredContractAddress) => se pasa por parentesis la direccion del contrato que quiero usar
            {
                (
                    string memory serviceName,
                    uint256 servicePrice
                ) = InsuranceHealthRecord(insuredContractAddress)
                        .InsuredHistory(NameServices[i]);
                history = string(
                    abi.encodePacked(
                        history,
                        "(",
                        serviceName,
                        ", ",
                        uint2str(servicePrice),
                        ") -------"
                    )
                );
            }
        }

        return history;
    }

    //----- Unsubscribe Clients -----//

    function unsubscribeClient(address _insuredAddress)
        public
        OnlyInsurer(msg.sender)
    {
        MappingInsured[_insuredAddress].AuthorizationClient = false;
        InsuranceHealthRecord(MappingInsured[_insuredAddress].AddressContract)
            .unsuscribe;

        emit EventLostInsured(_insuredAddress);
    }

    //----- Create and Disable Services -----//

    function StatusServices(string memory _serviceName)
        public
        view
        returns (bool)
    {
        return MappingServices[_serviceName].StatusService;
    }

    //--- Create new service ---//

    function newService(string memory _serviceName, uint256 _servicePrice)
        public
        OnlyInsurer(msg.sender)
    {
        MappingServices[_serviceName] = service(
            _serviceName,
            _servicePrice,
            true
        );
        NameServices.push(_serviceName);

        emit EventServiceCreated(_serviceName, _servicePrice);
    }

    //--- Remove service ---//

    function unsubscribeService(string memory _serviceName)
        public
        OnlyInsurer(msg.sender)
    {
        require(
            StatusServices(_serviceName) == true,
            "This service is not available"
        );
        MappingServices[_serviceName].StatusService = false;
        emit EventLostService(_serviceName);
    }

    //--- Check services prices ---//

    function getServicePrice(string memory _serviceName)
        public
        view
        returns (uint256 tokens)
    {
        require(
            StatusServices(_serviceName) == true,
            "This service is not available"
        );
        return MappingServices[_serviceName].PriceTokenService;
    }

    //----- Check Active Services -----//

    function checkActiveServices() public view returns (string[] memory) {
        string[] memory servicesList = new string[](NameServices.length);
        uint256 contador = 0;

        for (uint256 i = 0; i < NameServices.length; i++) {
            if (StatusServices(NameServices[i]) == true) {
                servicesList[contador] = (NameServices[i]);
                contador++;
            }
        }

        return servicesList;
    }

    //----- TOKENS -----//

    function buyTokens(address _insured, uint256 _numTokens)
        public
        payable
        OnlyInsured(_insured)
    {
        uint256 Balance = balanceOf();

        require(_numTokens <= Balance, "Buy a lower number of tokens");
        require(_numTokens > 0, "Buy a positive number of tokens");

        token.transfer(msg.sender, _numTokens); //tokens are stored in the insurance policy contract (insurance health record)
        emit EventBought(_numTokens);
    }

    function balanceOf() public view returns (uint256 tokens) {
        return token.balanceOf(Insurance);
    }

    function generateTokens(uint256 _numTokens) public OnlyInsurer(msg.sender) {
        token.increaseTotalSupply(_numTokens);
    }
}

contract InsuranceHealthRecord is BasicOperations {
    enum Estado {
        alta,
        baja
    }

    //Owner => propietario
    struct owner {
        address addressOwner;
        uint256 balanceOwner;
        Estado estado;
        IERC20 tokens;
        address insurance;
        address payable aseguradora;
    }

    owner propietario;

    constructor(
        address _owner,
        IERC20 _token,
        address _insurance,
        address payable _aseguradora
    ) public {
        propietario.addressOwner = _owner;
        propietario.balanceOwner = 0; //initially must be 0
        propietario.estado = Estado.alta;
        propietario.tokens = _token;
        propietario.insurance = _insurance;
        propietario.aseguradora = _aseguradora;
    }

    struct RequestServices {
        string serviceName;
        uint256 servicePrice;
        bool serviceStatus;
    }

    struct LabRequestServices {
        string serviceName;
        uint256 servicePrice;
        address labAddress;
    }

    mapping(string => RequestServices) insuredHistory; //using the test name you can recieve all the information about the service
    LabRequestServices[] insuredLabHistory;
    //RequestServices [] requestServices;

    //----- EVENTS -----//

    event EventSelfDestruct(address);
    event EventGiveBackTokens(address, uint256);
    event EventPaidService(address, string, uint256);
    event EventLabServiceRequest(address, address, string); //lab - insured - servicename

    modifier Only(address _address) {
        require(
            _address == propietario.addressOwner,
            "You are not the contract owner"
        );
        _;
    }

    function AseguradoraHistory()
        public
        view
        Only(msg.sender)
        returns (string memory)
    {
        return
            InsuranceFactory(propietario.insurance).CheckInsuredHistory(
                msg.sender,
                msg.sender
            );
    }

    function InsuredLabHistory()
        public
        view
        returns (LabRequestServices[] memory)
    {
        return insuredLabHistory;
    }

    function InsuredHistory(string memory _service)
        public
        view
        returns (string memory serviceName, uint256 servicePrice)
    {
        return (
            insuredHistory[_service].serviceName,
            insuredHistory[_service].servicePrice
        );
    }

    function InsuredServiceStatus(string memory _service)
        public
        view
        returns (bool)
    {
        return insuredHistory[_service].serviceStatus;
    }

    function unsuscribe() public Only(msg.sender) {
        emit EventSelfDestruct(msg.sender);
        selfdestruct(payable(msg.sender));
    }

    //----- TOKENS -----//

    function buyTokens(uint256 _numTokens) public payable Only(msg.sender) {
        require(_numTokens > 0, "Buy a positive number of tokens");

        uint256 cost = calcularPrecioToken(_numTokens);
        require(msg.value >= cost, "you don't have enough ethers balance");

        uint256 returnValue = msg.value - cost;
        payable(msg.sender).transfer(returnValue);

        InsuranceFactory(propietario.insurance).buyTokens(
            msg.sender,
            _numTokens
        ); //InsuranceHealthRecord make the purchase, so the InsuranceHealthRecord contract store the tokens
    }

    function balanceOf()
        public
        view
        Only(msg.sender)
        returns (uint256 _balance)
    {
        return propietario.tokens.balanceOf(address(this)); //en propietario.tokens se guarda el token que es la llave a todas las funciones de ERC20
        //Tokens are stored in the contract address
    }

    function giveBackTokens(uint256 _numTokens)
        public
        payable
        Only(msg.sender)
    {
        require(_numTokens > 0, "Tokens need to be positive");
        require(
            _numTokens <= balanceOf(),
            "You do not have those tokens in your account"
        );
        propietario.tokens.transfer(propietario.aseguradora, _numTokens); //No deberian enviarse estos tokens a Insurance (contrato inicial) ? Ya que inicialmente el contrato alberga los mismos
        payable(msg.sender).transfer(calcularPrecioToken(_numTokens));

        emit EventGiveBackTokens(msg.sender, _numTokens);
    }

    function serviceRequest(string memory _service) public Only(msg.sender) {
        require(
            InsuranceFactory(propietario.insurance).StatusServices(_service) ==
                true,
            "Service not available"
        );

        uint256 tokensPaid = InsuranceFactory(propietario.insurance)
            .getServicePrice(_service);
        require(tokensPaid <= balanceOf(), "Yo need more tokens");

        propietario.tokens.transfer(propietario.aseguradora, tokensPaid); //The owner transfers the tokens to his Insurer to pay for the service

        insuredHistory[_service] = RequestServices(_service, tokensPaid, true);

        emit EventPaidService(msg.sender, _service, tokensPaid);
    }

    function labServiceRequest(address _addressLab, string memory _service)
        public
        payable
        Only(msg.sender)
    {
        Lab contractLab = Lab(_addressLab);

        require(
            msg.value == contractLab.checkServicesPrice(_service) * 1 ether,
            "Invalid Operation"
        );
        contractLab.giveService(msg.sender, _service);
        payable(contractLab.LabAddress()).transfer(
            contractLab.checkServicesPrice(_service) * 1 ether
        ); //payable is necessary here becasuse I'm not using msg.sender as the recipient address

        insuredLabHistory.push(
            LabRequestServices(
                _service,
                contractLab.checkServicesPrice(_service),
                _addressLab
            )
        );

        emit EventLabServiceRequest(_addressLab, msg.sender, _service);
    } //service request to a specific lab
}

contract Lab is BasicOperations {
    address public LabAddress;
    address InsuranceCompanyContract;

    constructor(address _account, address _InsuranceCompanyAddress) public {
        LabAddress = _account;
        InsuranceCompanyContract = _InsuranceCompanyAddress;
    }

    //----- Mappings and Arrays -----//

    mapping(address => string) public SolicitedService; //pacient => service

    address[] public ServiceRequests;

    mapping(address => ServiceResult) LabServiceResults;

    mapping(string => LabService) LabServices;

    //----- Structs -----//

    struct ServiceResult {
        string service_diagnosis;
        string IPFS_code;
    }

    struct LabService {
        string serviceName;
        uint256 price;
        bool availability;
    }

    string[] labServicesName;

    //----- Events ----//

    event EventAvaliableService(string, uint256);
    event EventGiveService(address, string);

    //----- Functions and Modifiers -----//

    modifier OnlyLab(address _labAddress) {
        require(_labAddress == LabAddress, "Restricted Function");
        _;
    }

    function newLabService(string memory _service, uint256 _price)
        public
        OnlyLab(msg.sender)
    {
        LabServices[_service] = LabService(_service, _price, true);
        labServicesName.push(_service);
        emit EventAvaliableService(_service, _price);
    }

    function CheckServices() public view returns (string[] memory) {
        return labServicesName;
    }

    function checkServicesPrice(string memory _service)
        public
        view
        returns (uint256)
    {
        return LabServices[_service].price;
    }

    function giveService(address _insuredAddress, string memory _service)
        public
    {
        InsuranceFactory IF = InsuranceFactory(InsuranceCompanyContract);

        IF.FunctionOnlyInsured(_insuredAddress); //verify if he/she is a real insured
        require(
            LabServices[_service].availability == true,
            "Service not available"
        ); //verify if the service is available

        SolicitedService[_insuredAddress] = _service;
        ServiceRequests.push(_insuredAddress);

        emit EventGiveService(_insuredAddress, _service);
    }

    function GiveResults(
        address _insuredAddress,
        string memory _diagnosis,
        string memory _IPFScode
    ) public OnlyLab(msg.sender) {
        LabServiceResults[_insuredAddress] = ServiceResult(
            _diagnosis,
            _IPFScode
        );
    }

    function VisualizeResults(address _insuredAddress)
        public
        view
        returns (string memory _diagnosis, string memory _IPFScode)
    {
        return (
            LabServiceResults[_insuredAddress].service_diagnosis,
            LabServiceResults[_insuredAddress].IPFS_code
        );
    }
}
