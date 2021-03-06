pragma solidity >=0.4.22 <0.7.0;

contract BilBoydDealership {
    uint public value; 
    address payable public seller; // seller
    address payable public buyer; // buyer 
    enum vehicle_choices {Pickup,Mini}  // SUV, Tesla
    vehicle_choices choice;
   // vehicle_choices constant defaultChoice = vehicle_choices.Tesla;
   
    enum State { Created, Locked, Release, Inactive}
    State public state;
    
    enum milage_cap{ low, medium, high}
    milage_cap choiseCap;
    
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
    
    event PurchaseConfirmed();
    event Aborted();
    event ItemReceived();
    event SellerRefunded();
      
    
    
/*    enum contract_duration {1year, 2year, 3year, 4year} //in years  
    contract_duration choice;
    contract_duration constant defaultChoice = vehicle_choices.Tesla;
*/    
    constructor() public payable {
        seller =msg.sender;
        value = msg.value;
        //vehicle_value = 5000;
        //driver_experience = ;//the more experience the less you pay
        //milage_cap = ;//the amount you can drive - the higher the more you pay (can set value to start with)
        //duration_of_contract = ;//the longer duration the less you pay per month 
    
        
    }
    
     function abort()
        public
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is
        // reentrancy-safe, because it is the
        // last call in this function and we
        // already changed the state.
        seller.transfer(address(this).balance);
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase()
        public
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }

    
    
    //mattia (buyer) has received car, so the money will be drwan from 
    //mattias account. This will release locked amout of ether
    
     /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived()
        public
        onlyBuyer
        inState(State.Locked)
    {
        emit ItemReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Release;

        buyer.transfer(value);
    }

    /// This function refunds the seller, i.e.
    /// pays back the locked funds of the seller.
    function refundSeller()
        public
        onlySeller
        inState(State.Release)
    {
        emit SellerRefunded();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;

        seller.transfer(3 * value);
    }
    
    
    
    /*
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
    
    
    function setMilageCap() public returns(uint){
        uint cap = choiseCap;
        
        
    }
    
 //   function calculatePayment() public view returns(uint){
        //calculate value
        uint carType= getVehichleCoice();
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
        
    }
    
    
  
    
    
    modifier ifClient() {
        if(client != msg.sender) {
            assert(false);
        }
    }
    
    function depositFunds() payable public {
        UpdateStatus('User transferred some money', msg.value);
    }
    
function withdrawFunds(unit amount) ifClient public 
        UpdateStatus('User transferred some money', 0);
        if(client.send(amount) || client.balance > amount){
            _switch = true;
        }
        else if(client.balance < amount){
            assert(false);
            _switch = false;
        }
    }
    
        
        
   
    
    
    //Mattia must choose values for the car 
    function getVehichleCoice() public view returns (vehicle_choices) {
        return choice;
    }
        */
   
   
  
}
