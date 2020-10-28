pragma solidity >=0.4.22 <0.7.0;

contract BilBoydDealership {
    uint public value; 
    address payable public BilBoyd; // seller
    address payable public Mattia; // buyer 
    enum vehicle_choices {Pickup,Mini}  // SUV, Tesla
    vehicle_choices choice;
   // vehicle_choices constant defaultChoice = vehicle_choices.Tesla;
    enum State { Created, Locked, Inactive}
    State public state;
    
    enum milage_cap{ low, medium, high}
    milage_cap choiseCap;
    
    event PurchaseConfirmed();
    event Aborted();
    event ItemReceived();
    
    
/*    enum contract_duration {1year, 2year, 3year, 4year} //in years  
    contract_duration choice;
    contract_duration constant defaultChoice = vehicle_choices.Tesla;
*/    
    constructor() public payable {
        //vehicle_value = 5000;
        //driver_experience = ;//the more experience the less you pay
        //milage_cap = ;//the amount you can drive - the higher the more you pay (can set value to start with)
        //duration_of_contract = ;//the longer duration the less you pay per month 
    
        
    }
    
    struct Car {
        string registration_nr;
        
    }

    struct Buyer {
        string name;
        uint no_driving_years; //
        string tlfnr;   //
        address buyer_addr; // check address for eth cash - check for sufficient funds
        
    }
    function getCapChoise() public view returns (milage_cap){
        return choiseCap;
    }
   /* function setMilageCap() public returns(uint){
        uint cap = choiseCap;
        
        
    }
    */
    function calculatePayment() public view returns(uint){
        //calculate value
     /*   uint carType= getVehichleCoice();
        uint carValue;
        uint experience;
       
        if (carType==Pickup) { //500 dollar 
            carValue== 1000000000000000000;
        }
        if (carType==Mini){
           carValue== 200000000000000000;
        }
        experience= Buyer.no_driving_years;
        return value;
        */
    }
    
    
    
     modifier condition(bool _condition) {
        require(_condition);
        _;
    }
    
    // Define a modifier for a function that only the buyer can call
    modifier onlyBuyer() {
        require( msg.sender == Mattia , "Only buyer can call this.");
        _;
    }

    // Define a modifier for a function that only the seller can call
    modifier onlySeller() {
        require( msg.sender == BilBoyd , "Only seller can call this.");
        _;
    }
    
    modifier inState(State _state) {
        require( state == _state , "Invalid state.");
        _;
    }
        
        
        
        
        
    function abort() public onlySeller inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        BilBoyd.transfer(address(this).balance);
    }
        
    //setter 2*value for å få depositum
    function confirmPurchase() public inState(State.Created) condition(msg.value==(2*value)) payable
    {
        emit PurchaseConfirmed();
        Mattia= msg.sender;
        state= State.Locked;
    }
    
    
    //mattia (buyer) has received car, so the money will be drwan from 
    //mattias account. This will release locked amout of ether
    
    function confirmReceived() public onlyBuyer inState(State.Locked)
    {
        emit ItemReceived();
 
        state = State.Inactive;
    
        Mattia.transfer(value);
        BilBoyd.transfer(address(this).balance);
    }
    
    
    
    //Mattia must choose values for the car 
    function getVehichleCoice() public view returns (vehicle_choices) {
        return choice;
    }
    
   
   
  
}
