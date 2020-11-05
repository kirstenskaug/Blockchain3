pragma solidity >=0.4.10 <0.8.0;

//TODO: HUSKER Å LEGGE TIL ONLYBUYER
//TODO: Endre navn på SetBuyer state fordi det er da man setter alle variablene
//TODO: Sett tilgangscontroll på alle set-funksjonene (insState SetBuyer), ikke senere. 
//TODO: Call initilalizeContract for something else.

contract BilBoydDealership {
      
    //Define variables
    uint public weeklyPrice; 
    address payable public seller; // seller
    address payable public buyer; // buyer 
    enum State { Created, SetBuyer, Locked, Release, Inactive}
    State public state;
    Car[] cars;
    uint public milagecap;
    uint public experience;
    uint public duration;
    uint public deposit;
    
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
    
    Car Mini = Car("Mini",100); 
    Car SUV = Car("SUV",200);
    Car Pickup = Car("Pickup",300);
    
    
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
        if(finalPrice == (weeklyPrice+deposit)) {
            emit PurchaseConfirmed();
            
            //buyer = msg.sender;
             seller.transfer(finalPrice);
             deposit = 0;
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
    
    function setMilageCap(uint _milagecap) public returns(string memory) {
        if (_milagecap < 300) {
            return "This is too low";
        } else if(_milagecap > 500) {   
            return "The milage cap is too high";
        } else {
            milagecap = _milagecap;
        }
    }
    
    function setExperience(uint _experience) public returns(string memory) {
        experience = _experience;
    }
    
    function setContractDuration(uint _duration) public returns(string memory) {
        require(_duration > 0, "Duration must be between 1 and 3 years.");
        require(_duration < 4, "Duration must be between 1 and 3 years.");
        duration = _duration;
    }
    
    //Contract sets the weekly rent
    function calulateWeeklyPrice() public {
        weeklyPrice = calulateRentalPrice(experience, buyerCar.price, milagecap, duration);
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
    
    function getContractDuration() public view returns(uint) {
        return duration;
    }
    
    function getCurrentVehicle() public view returns(string memory){

        return string(abi.encodePacked(buyerCar.name));
    }
    
    //Shows to the user the total weekly rent
    function getWeeklyPrice() public view returns (uint) {
        return weeklyPrice;
    }
    
    //Shows to the user the current experience
    function getExperience() public view returns (uint) {
        return experience;
    }
    
    function getDeposituPrice() public view returns (uint) {
        return deposit;
    }
    
    
    
    
    
    
    
    
    
    /* HELPER FUNCTIONS */
    
    function getNow() public view returns (uint256 des) {
        uint256 des = block.timestamp;
        return des;
    }
    
    function setTestValues() public returns(string memory des) {
        initialiseContract();
        experience = 6;
        duration = 1;
        milagecap = 300;
        buyerCar = cars[1];
        weeklyPrice = calulateRentalPrice(experience, buyerCar.price, milagecap, duration);
      
    }
    
    //Price for weekly rent
    function calulateRentalPrice(uint _experience, uint basePrice, uint _milagecap, uint _duration) private returns(uint finalPrice){
        uint extraPrice = (_milagecap - 300);
        uint finalPrice = basePrice + extraPrice;
        if(state == State.SetBuyer) {
            deposit = weeklyPrice*4;
        } else {
            deposit = 0;
        }
        
        if (_experience < 2) {
            finalPrice = finalPrice + 50;
        } else if(_experience == 3) {
            finalPrice = finalPrice +30;
        } else if(_experience == 4){
            finalPrice = finalPrice + 20;
        }
        
        if (duration == 2){
            finalPrice = finalPrice - 10;
        } else if (duration == 3) {
            finalPrice = finalPrice - 20;
        }

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
