// SPDX-License-Identifier: MIT
pragma solidity >0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";
contract Practica_Libre_Atracciones{
   
    // --------------------------------- DECLARACIONES INICIALES ---------------------------------
    // Instancia del contato token
    ERC20Basic private token;
   
    // Direccion de Disney (owner)
    address payable public owner; //Devuelve la Account en la que estemos
   
    //Declaramos la comida que habrá disponible
    string [] private product_sushi;
    uint [] private price_sushi;
    string [] private product_pizza;
    uint [] private price_pizza;
    string [] private product_ensalada;
    uint [] private price_ensalada;
   
    //Declaramos los souvenirs
    string [] private product_souvenir;
    uint [] private price_souvenir;
 
    // Constructor
    constructor () public {
        token = new ERC20Basic(10000);
        owner = msg.sender;
        product_sushi = ["nigiri atun","maki salmon","maki pez mantequilla",
        "rolls spicy tuna", "rolls california","gyozas"];
        price_sushi = [3, 3, 3, 8, 8, 2];
        product_ensalada = ["ensalada basica", "ensalada cesar", "ensalada de atún",
        "ensalada de aguacate"];
        price_ensalada = [3,6,5,7];
        product_pizza = ["pizza margarita", "pizza 4 estaciones", "pizza caprichosa",
        "pizza 4 quesos"];
        price_pizza = [3,5,5,5];
        product_souvenir = ["muñeco mickey","muñeco minnie","camiseta disney", "taza disney", "llavero mickey","llavero minnie"];
        price_souvenir = [3, 3, 3, 8, 8, 2];
    }
   
    // Estructura de datos para almacenar a los clientes de Disney
    struct cliente {
        uint tokens_comprados;
        string [] atracciones_disfrutadas;
        string [] souvenirs_comprados;
    }
    // Mapping para el registro de clientes
    mapping (address => cliente) public Clientes;
   
   
    // --------------------------------- GESTION DE TOKENS ---------------------------------
    // Funcion para establecer el precio de un Token
    function PrecioTokens(uint _numTokens) internal pure returns (uint) {
        // Conversion de Tokens a Ethers: 1 Token -> 1 ether
        return _numTokens*(1 ether);
    }
   
    // Funcion para comprar Tokens en disney
    function CompraTokens(uint _numTokens) public payable {
        // Establecer el precio de los Tokens
        uint coste = PrecioTokens(_numTokens);
        // Se evalua el dinero que el cliente paga por los Tokens
        require (msg.value >= coste, "Compra menos Tokens o paga con mas ethers.");
        // Diferencia de lo que el cliente paga
        uint returnValue = msg.value - coste;
        // Disney retorna la cantidad de ethers al cliente
        msg.sender.transfer(returnValue);
        // Obtencion del numero de tokens disponibles
        uint Balance = balanceOf();
        require(_numTokens <= Balance, "Compra un numero menor de Tokens");
        // Se transfiere el numero de tokens al cliente
        token.transfer(msg.sender, _numTokens);
        // Registro de tokens comprados
        Clientes[msg.sender].tokens_comprados += _numTokens;
    }
   
    // Balance de tokens del contrato disney
    function balanceOf() public view returns (uint) {
        return token.balanceOf(address(this));
    }
   
    // Visualizar el numero de tokens restantes de un Cliente
    function MisTokens() public view returns (uint){
        return token.balanceOf(msg.sender);
    }
   
    // Modificador para controlar las funciones ejecutables por disney
    modifier Unicamente(address _direccion) {
        require(_direccion == owner, "No tienes permisos para ejecutar esta funcion.");
        _;
    }
 
    // Funcion para que un cliente de Disney pueda devolver Tokens
    function DevolverTokens (uint _numTokens) public payable {
        // El numero de tokens a devolver es positivo
        require (_numTokens > 0, "Necesitas devolver una cantidad positiva de tokens.");
        // El usuario debe tener el numero de tokens que desea devolver
        require (_numTokens <= MisTokens(), "No tienes los tokens que deseas devolver.");
        // El cliente devuelve los tokens
         token.transferencia_disney(msg.sender, address(this),_numTokens);
         // Devolucion de los ethers al cliente
         msg.sender.transfer(PrecioTokens(_numTokens));
    }
   
 
 
    //------------------------------ DESCRIPCION DE LA ZONA DE LAS ATRACCIONES ------------------------------
 
    // Eventos Atracciones
    event disfruta_atraccion(string, uint, address);
    event nueva_atraccion(string, uint);
    event baja_atraccion(string);
   
    // Estructura de la atraccion
    struct atraccion {
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion;
    }
 
    // Mapping para relacion un nombre de una atraccion con una estructura de datos de la atraccion
    mapping (string => atraccion) public MappingAtracciones;
    // Array para almacenar el nombre de las atracciones
    string [] Atracciones;
    // Mapping para relacionar una identidad (cliente) con su historial de atracciones en DISNEY
    mapping (address => string []) HistorialAtracciones;
   
   
    // Crear nuevas atracciones para DISNEY (SOLO es ejecutable por Disney)
    function NuevaAtraccion(string memory _nombreAtraccion, uint _precio) public Unicamente (msg.sender) {
        // Creacion de una atraccion en Disney
        MappingAtracciones[_nombreAtraccion] = atraccion(_nombreAtraccion,_precio, true);
        // Almacenamiento en un array el nombre de la atraccion
        Atracciones.push(_nombreAtraccion);
        // Emision del evento para la nueva atraccion
        emit nueva_atraccion(_nombreAtraccion, _precio);
    }
   
    // Dar de baja a las atracciones en Disney
    function BajaAtraccion (string memory _nombreAtraccion) public Unicamente(msg.sender){
        // El estado de la atraccion pasa a FALSE => No esta en uso
        MappingAtracciones[_nombreAtraccion].estado_atraccion = false;
        // Emision del evento para la baja de la atraccion
        emit baja_atraccion(_nombreAtraccion);
     }
         
    // Visualizar las atracciones de Disney
    function Disp_Atracciones() public view returns (string [] memory){
        return Atracciones;
    }
 
    // Funcion para subirse a una atraccion de disney y pagar en tokens
    function SubirseAtraccion (string memory _nombreAtraccion) public {
        // Precio de la atraccion (en tokens)
        uint tokens_atraccion = MappingAtracciones[_nombreAtraccion].precio_atraccion;
        // Verifica el estado de la atraccion (si esta disponible para su uso)
        require (MappingAtracciones[_nombreAtraccion].estado_atraccion == true,
                    "La atraccion no esta disponible en estos momentos.");
        // Verifica el numero de tokens que tiene el cliente para subirse a la atraccion
        require(tokens_atraccion <= MisTokens(),
                "Necesitas mas Tokens para subirte a esta atraccion.");
        token.transferencia_disney(msg.sender, address(this),tokens_atraccion);
        // Almacenamiento en el historial de atracciones del cliente
        HistorialAtracciones[msg.sender].push(_nombreAtraccion);
        // Emision del evento para disfrutar de la atraccion
        emit disfruta_atraccion(_nombreAtraccion, tokens_atraccion, msg.sender);
    }
   
    // Visualiza el historial completo de atracciones disfrutadas por un cliente
    function Hist_Atraccion() public view returns (string [] memory) {
        return HistorialAtracciones[msg.sender];
    }
 
    //-------------------------- DESCRIPCIÓN DE LOS 3 TIPOS DE COMIDA --------------------------
    // EVENTOS Y ESTRUCTURAS
 
    // Eventos Comidas
    //Sushi
    event rest_sushi(string, uint, bool);
    event baja_sushi(string);
    event disfruta_sushi(string, uint, address);
    // Estructura del sushi
    struct sushi {
        string nombre_sushi;
        uint precio_sushi;
        bool estado_sushi;
    }
    //Pizza
    event rest_pizza(string, uint, bool);
    event baja_pizza(string);
    event disfruta_pizza(string, uint, address);
    // Estructura de la pizza
    struct pizza {
        string nombre_pizza;
        uint precio_pizza;
        bool estado_pizza;
    }
    //Ensalada
    event rest_ensalada(string, uint, bool);
    event baja_ensalada(string);
    event disfruta_ensalada(string, uint, address);
    // Estructura de la ensalada
    struct ensalada {
        string nombre_ensalada;
        uint precio_ensalada;
        bool estado_ensalada;
    }
 
    // Mapping para relacion un nombre de un sushi con una estructura de datos del sushi
    mapping (string => sushi) public MappingSushi;
    // Mapping para relacion un nombre de una pizza con una estructura de datos de la pizza
    mapping (string => pizza) public MappingPizza;
    // Mapping para relacion un nombre de una ensalada con una estructura de datos de la ensalada
    mapping (string => ensalada) public MappingEnsalada;
 
    // Crear nuevos sushis para la comida en DISNEY (SOLO es ejecutable por Disney)
    function OpenSushi() public Unicamente (msg.sender) {
        for (uint i = 0; i < 6; i++) {
            // Creacion de un sushi en Disney
            MappingSushi[product_sushi[i]] = sushi(product_sushi[i], price_sushi[i], true);
            // Almacenar en un array los sushis que puede realizar una persona
            Comidas.push(product_sushi[i]);
            // Emision del evento para la nueva comida en Disney
            emit rest_sushi(product_sushi[i],price_sushi[i], true);
        }
    }
    // Crear nuevas pizzas para la comida en DISNEY (SOLO es ejecutable por Disney)
    function OpenPizza() public Unicamente (msg.sender) {
        for (uint i = 0; i < 4; i++) {
            // Creacion de una comida en Disney
            MappingPizza[product_pizza[i]] = pizza(product_pizza[i], price_pizza[i], true);
            // Almacenar en un array las comidas que puede realizar una persona
            Comidas.push(product_pizza[i]);
            // Emision del evento para la nueva comida en Disney
            emit rest_pizza(product_pizza[i], price_pizza[i], true);
        }
    }
    // Crear nuevas ensaladas para la comida en DISNEY (SOLO es ejecutable por Disney)
    function OpenEnsalada() public Unicamente (msg.sender) {
        for (uint i = 0; i < 4; i++) {
            // Creacion de una comida en Disney
            MappingEnsalada[product_ensalada[i]] = ensalada(product_ensalada[i], price_ensalada[i], true);
            // Almacenar en un array las comidas que puede realizar una persona
            Comidas.push(product_ensalada[i]);
            // Emision del evento para la nueva comida en Disney
            emit rest_ensalada(product_ensalada[i], price_ensalada[i], true);
        }
    }
 
    // Dar de baja un sushi de Disney
    function BajaSushi (string memory _sushi) public Unicamente(msg.sender){
        // El estado de la comida pasa a FALSE => No se puede comer
        MappingSushi[_sushi].estado_sushi = false;
        // Emision del evento para la baja de la comida
        emit baja_sushi(_sushi);
     }
    // Dar de baja una pizza de Disney
    function BajaPizza (string memory _pizza) public Unicamente(msg.sender){
        // El estado de la comida pasa a FALSE => No se puede comer
        MappingPizza[_pizza].estado_pizza = false;
        // Emision del evento para la baja de la comida
        emit baja_pizza(_pizza);
     }
    // Dar de baja una ensalada de Disney
    function BajaEnsalada (string memory _ensalada) public Unicamente(msg.sender){
        // El estado de la comida pasa a FALSE => No se puede comer
        MappingEnsalada[_ensalada].estado_ensalada = false;
        // Emision del evento para la baja de la comida
        emit baja_ensalada(_ensalada);
     }
   
    // Funcion para comprar sushi con tokens
    function ComprarSushi (string memory _sushi) public {
        // Precio de la comida (en tokens)
        uint tokens_sushi = MappingSushi[_sushi].precio_sushi;
        // Verifica el estado de la comida (si esta disponible)
        require (MappingSushi[_sushi].estado_sushi == true,
                    "La comida no esta disponible en estos momentos.");
        // Verifica el numero de tokens que tiene el cliente para comer esa comida
        require(tokens_sushi <= MisTokens(),
                "Necesitas mas Tokens para comer esta comida.");
        token.transferencia_disney(msg.sender, address(this),tokens_sushi);
        // Almacenamiento en el historial de comidas del cliente
        HistorialComidas[msg.sender].push(_sushi);
        // Emision del evento para disfrutar de la comida
        emit disfruta_sushi(_sushi, tokens_sushi, msg.sender);
    }
   
    // Funcion para comprar pizza con tokens
    function ComprarPizza (string memory _pizza) public {
        // Precio de la comida (en tokens)
        uint tokens_pizza = MappingPizza[_pizza].precio_pizza;
        // Verifica el estado de la comida (si esta disponible)
        require (MappingPizza[_pizza].estado_pizza == true,
                    "La comida no esta disponible en estos momentos.");
        // Verifica el numero de tokens que tiene el cliente para comer esa comida
        require(tokens_pizza <= MisTokens(),
                "Necesitas mas Tokens para comer esta comida.");
        token.transferencia_disney(msg.sender, address(this),tokens_pizza);
        // Almacenamiento en el historial de comidas del cliente
        HistorialComidas[msg.sender].push(_pizza);
        // Emision del evento para disfrutar de la comida
        emit disfruta_pizza(_pizza, tokens_pizza, msg.sender);
    }
   
    // Funcion para comprar ensalada con tokens
    function ComprarEnsalada (string memory _ensalada) public {
        // Precio de la comida (en tokens)
        uint tokens_ensalada = MappingEnsalada[_ensalada].precio_ensalada;
        // Verifica el estado de la comida (si esta disponible)
        require (MappingEnsalada[_ensalada].estado_ensalada == true,
                    "La comida no esta disponible en estos momentos.");
        // Verifica el numero de tokens que tiene el cliente para comer esa comida
        require(tokens_ensalada <= MisTokens(),
                "Necesitas mas Tokens para comer esta comida.");
        token.transferencia_disney(msg.sender, address(this),tokens_ensalada);
        // Almacenamiento en el historial de comidas del cliente
        HistorialComidas[msg.sender].push(_ensalada);
        // Emision del evento para disfrutar de la comida
        emit disfruta_ensalada(_ensalada, tokens_ensalada, msg.sender);
    }
 
    // Array para almacenar el nombre de las comidas
    string [] Comidas;
    // Mapping para relacionar una identidad (cliente) con su historial de comidas en DISNEY
    mapping (address => string []) HistorialComidas;
    // Visualizar las comidas de Disney
    function Disp_Comidas() public view returns (string [] memory){
        return Comidas;
    }
    // Visualiza el historial completo de comidas disfrutadas por un cliente
    function Hist_Comida() public view returns (string [] memory) {
        return HistorialComidas[msg.sender];
    }
 
 
    //---------------------- DESCRIPCIÓN DE LA TIENDA DE SOUVENIRS ----------------------
    // EVENTOS Y ESTRUCTURAS
 
    // Eventos Objetos
    //Souvenir
    event vende_souvenir(string, uint, bool);
    event agotado_souvenir(string);
    event compra_souvenir(string, uint, address);
    // Estructura del souvenir
    struct souvenir {
        string nombre_souvenir;
        uint precio_souvenir;
        bool estado_souvenir;
    }
 
    // Mapping para relacion un nombre de un souvenir con una estructura de datos del souvenir
    mapping (string => souvenir) public MappingSouvenir;
 
    // Crear nuevos souvenirs para la tienda en DISNEY (SOLO es ejecutable por Disney)
    function OpenSouvenir() public Unicamente (msg.sender) {
        for (uint i = 0; i < 6; i++) {
            // Creacion de un objeto en Disney
            MappingSouvenir[product_souvenir[i]] = souvenir(product_souvenir[i], price_souvenir[i], true);
            // Almacenar en un array los objetos que puede comprar una persona
            Souvenirs.push(product_souvenir[i]);
            // Emision del evento para el nuevo souvenir en Disney
            emit vende_souvenir(product_souvenir[i], price_souvenir[i], true);
        }
    }
 
    // Dar de baja un souvenir de Disney
    function AgotadoSouvenir (string memory _souvenir) public Unicamente(msg.sender){
        // El estado del objeto pasa a FALSE => No se puede comprar
        MappingSouvenir[_souvenir].estado_souvenir = false;
        // Emision del evento para la baja del objeto
        emit agotado_souvenir(_souvenir);
     }
 
     // Funcion para comprar souvenir con tokens
    function ComprarSouvenir (string memory _souvenir) public {
        // Precio del souvenir (en tokens)
        uint tokens_souvenir = MappingSouvenir[_souvenir].precio_souvenir;
        // Verifica el estado del objeto (si esta disponible)
        require (MappingSouvenir[_souvenir].estado_souvenir == true,
                    "El souvenir no esta disponible en estos momentos.");
        // Verifica el numero de tokens que tiene el cliente para comprar
        require(tokens_souvenir <= MisTokens(),
                "Necesitas mas Tokens para comprar este objeto.");
        token.transferencia_disney(msg.sender, address(this),tokens_souvenir);
        // Almacenamiento en el historial de compra del cliente
        HistorialSouvenirs[msg.sender].push(_souvenir);
        // Emision del evento para disfrutar del souvenir
        emit compra_souvenir(_souvenir, tokens_souvenir, msg.sender);
    }
 
    // Array para almacenar el nombre de los souvenirs
    string [] Souvenirs;
    // Mapping para relacionar una identidad (cliente) con su historial de compras en DISNEY
    mapping (address => string []) HistorialSouvenirs;
    // Visualizar los souvenirs de Disney
    function Disp_Souvenirs() public view returns (string [] memory){
        return Souvenirs;
    }
    // Visualiza el historial completo de souvenirs comprados por un cliente
    function Hist_Tienda() public view returns (string [] memory) {
        return HistorialSouvenirs[msg.sender];
    }
 
}
