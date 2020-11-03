pragma solidity >=0.4.10 <0.8.0;

//TODO: HUSKER Å LEGGE TIL ONLYBUYER

contract BilBoydDealership {
      
    //Define variables
    uint weeklyPrice; 
    address payable public seller; // seller
    address payable public buyer; // buyer 
    enum State { Created, SetBuyer, Locked, Release, Inactive}
    State public state;
    Car[] cars;
    uint milagecap;
    
    //Define customer variables
    Car buyerCar;
    
    //Define events
    event PurchaseConfirmed();
    event Aborted();
    event ItemReceived();
    event SellerRefunded();
    event SetBuyer();
    
    
     //Define Car struct
    
    struct Car {
        string name;
        uint price;
    }
    
    Car Mini = Car("Mini",1000000000000000000); 
    Car SUV = Car("SUV",1000000000000000000);
    Car Pickup = Car("Pickup",1000000000000000000);
    
    
    constructor() public payable {
        cars.push(Mini);
        cars.push(SUV);
        cars.push(Pickup);
        seller = msg.sender;
        weeklyPrice = msg.value;
    }
    
    
    /* 
    Define modifiers for access control.
    These are used to restrict access to methods in the contract
    */
    
     modifier condition(bool _condition) {
        require(_condition);
        _;
    }
    
    // Define a modifier for a function that only the buyer can call
    modifier onlyBuyer() {
        require( msg.sender == buyer , "Only buyer can call this.");
        _;
    } 

    // Define a modifier for a function that only the seller can call
    modifier onlySeller() {
        require( msg.sender == seller , "Only seller can call this.");
        _;
    }
    
    modifier inState(State _state) {
        require( state == _state , "Invalid state.");
        _;
    }
    
    
    /* 
    Define actions that that can be executed on the contract, which will be written to the blockchain
    @notice Color of buttons are orange
    */
    
    function abort() public onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }
    
    function initialiseContract() public inState(State.Created) {
        emit SetBuyer();
        buyer = msg.sender;
        state = State.SetBuyer;
    }
    
    function confirmPurchase(uint finalPrice) public inState(State.SetBuyer)  payable {
        //Husk på depositum  - condition(msg.value * 2 == value)
        if(finalPrice == weeklyPrice) {
            emit PurchaseConfirmed();
            //buyer = msg.sender;
             state = State.Locked;
        }
        
    }

    function confirmReceived() public onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        state = State.Release;
        buyer.transfer(weeklyPrice);
    }

    function refundSeller() public onlySeller inState(State.Release) {
        emit SellerRefunded();
        state = State.Inactive;
        seller.transfer(3 * weeklyPrice);
    }
    

    function setVehicleChoice(string memory car) public returns(string memory) {
        for(uint i = 0; i < cars.length; i++){
            if((keccak256(abi.encodePacked((cars[i].name))) == keccak256(abi.encodePacked((car))))) {
                buyerCar = cars[i];
                buyer = msg.sender;
                return car;
            } 
        }
        return "The vehicle does not exist";
    }
    
    function setMilageCap(uint _milagecap) public onlyBuyer returns(string memory) {
        if (_milagecap < 300) {
            return "This is too low";
        } else if(_milagecap > 500) {
            return "The milage cap is too high";
        } else {
            milagecap = _milagecap;
        }
    }
    
    //Contract sets the weekly rent
    function calulateWeeklyPrice() public {
        weeklyPrice = calulateRentalPrice(buyerCar.price, milagecap);
    }
    
   
    
   
    /* Define actions that will not be executed on the blockchain, only return data
    @notice Color of buttons are blue
    */

     function getVehicleChoices() public view returns(string memory){
        
        string memory choice;
        for(uint i=0; i < cars.length; i++){
            choice = string(abi.encodePacked(cars[i].name,", ",choice));
        }

        return choice;
    }
    
     function getMilageCap() public view returns(string memory) {
        if( milagecap > 0){
            return uint2str(milagecap);
        } else {
            return "The milage cap must be between 300km and 500km";
        }
    }
    
    function getCurrentVehicle() public view returns(string memory){

        return string(abi.encodePacked(buyerCar.name));
    }
    
    //Shows to the user the total weekly rent
    function getWeeklyPrice() public view returns (uint) {
        return weeklyPrice;
    }
    
    
    
    
    
    
    
    
    /* HELPER FUNCTIONS */
    
    //Price for weekly rent
    function calulateRentalPrice(uint basePrice, uint _milagecap) public returns(uint weeklyRent){
        uint extraPrice = (_milagecap - 300) * 26000000000000;
        uint finalPrice = basePrice + extraPrice;
        return finalPrice;
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
        bstr[k--] = byte(uint8(48 + _i % 10));
        _i /= 10;
    }
    return string(bstr);
}
       
}

