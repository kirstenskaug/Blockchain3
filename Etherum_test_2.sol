pragma solidity >=0.4.10 <0.8.0;



contract BilBoydDealership {
      
    //Define variables
    uint public value; 
    address payable public seller; // seller
    address payable public buyer; // buyer 
    enum State { Created, Locked, Release, Inactive}
    State public state;
    Car[] cars;
    
    //Define events
    event PurchaseConfirmed();
    event Aborted();
    event ItemReceived();
    event SellerRefunded();
    
    
     //Define Car struct
    
    struct Car {
        string name;
        uint price;
        string milageCap;
    }
   
     //Define MilageCap struct
    struct milageCap {
        string low;
        string medium;
        string high;
    }
    
    milageCap _milageCap = milageCap("low", "medium", "high");
    Car Mini = Car("Mini",1000000000000000000, _milageCap.low);  
    Car Pickup = Car("Pickup",1000000000000000000, _milageCap.medium);
    
    
    constructor() public payable {
        cars.push(Mini);
        cars.push(Pickup);
        seller = msg.sender;
        value = msg.value;
        
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
    
    function confirmPurchase() public inState(State.Created)  payable {
        //Husk på depositum  - condition(msg.value * 2 == value)
        emit PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }

    function confirmReceived() public onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        state = State.Release;
        buyer.transfer(value);
    }

    function refundSeller() public onlySeller inState(State.Release) {
        emit SellerRefunded();
        state = State.Inactive;
        seller.transfer(3 * value);
    }
    
    function getVehicleChoices() public view returns(string memory){

        return string(abi.encodePacked(cars[0].name,", ",cars[1].name));
    }

       
}











