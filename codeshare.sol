pragma solidity >=0.4.10 <0.8.0;

//Navn på SetBuyer-state er endret til Claimed


//TODO: Edit confirmWeeklyPurchase to change state after the correct amount of time (years), instead of after 20 seconds used for testing
//TODO: feilmelding hvis man sender feil depositum

/* 
* INSTRUCTIONS: 
* Welcome to BilBoyd's smart contract car rental!

This contract is made for the BilBoyd company for a renter that would like a long term car rental. 
Thank you for choosing us as your car rental company of choice. 

Please go through the following steps in order to rent a car from us, on the Blockschain!

1. Claim the contract by pressing the InitializeContract-button. This will lock your address as the renter and can not be changed by anyone else after this step is complete.
	 Do not worry, you have not commited to pay anything yet.

2. Check which cars are currently available for rent by pressing the getVehicleChoices-button

3. ...

---
*/



contract BilBoydDealership {

    /* ----------------------------------------
    Define variables used in the contract* 
    ------------------------------------------*/
    
    address payable public seller; 
    address payable public buyer; 
    
    enum State { Created, Claimed, Locked, Active, EndOptions, Inactive}
    State public state;
    
    Car[] cars;
    Car buyerCar;
    
    //Variables
    uint public milagecap;
    uint public experience;
    uint public duration;
    uint public deposit;
    uint public sellerDeposit;
    uint public contractStart;
    uint public loyaltyYears = 0;
    uint public weeklyPrice;
    uint public numberOfPayments=0;
    uint public contractDeployTime;
    
    //Define events
    event PurchaseConfirmed();
    event Aborted();
    event ItemReceived();
    event SellerRefunded();
    event Claimed();
    
    //Data structure describing a Car object
    struct Car {
        string name;
        uint price;
        uint buyPrice;
    }
    
    //Initializing cars
    Car Mini = Car("Mini",100,15000); 
    Car SUV = Car("SUV",200,20000);
    Car Pickup = Car("Pickup",300,30000);
    
    
    /*---------------------------------------
    Define constructor
    @info the constructors makes sure that the seller invests a deposit un the contract to protect the buyer if the seller is insolvant
    ----------------------------------------*/
    
    constructor() public payable {
        sellerDeposit = dollar2wei(250);
        require(msg.value == sellerDeposit, "As a seller you have to deposit 6500000000000000000 wei");
        cars.push(Mini);
        cars.push(SUV);
        cars.push(Pickup);
        seller = msg.sender;
        
    }
    
    
    /*----------------------------------------
    Define modifiers for access control.
    These are used to restrict access to methods in the contract
    ------------------------------------------*/
      
    
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
    

    /*----------------------------------------
    Define actions that that can be executed on the contract, which will be written to the blockchain
    @notice Color of buttons are orange
    ------------------------------------------*/
    

    /*
    * Allows the seller to abort the contract while it's being created, before a buyer initializes the contract. 
    * Insures that the seller can collect its deposit if the buyer doesn't want the contract anyway.
    */
    function abort() public onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }
    
   function sellerDepositRefund() public onlySeller inState(State.Claimed) {
        uint timer = getNow() - contractInitTime;
        if(timer > 60) { // skal være 604800 (en uke)
            emit Aborted();
            state = State.Inactive;
            seller.transfer(address(this).balance);
        }
    }
  
    /*
    * Initilalizes the contract, which locks the buyer address to the person initializing the contract
    * After this no one else can change variables on the contract exept the buyer (and seller on its specific functions) 
    */
    function initialiseContract() public inState(State.Created) {
      
        emit Claimed();
        buyer = msg.sender;
        state = State.Claimed;
        contractInitTime = getNow();
    }
    
     /*
    * When the buyer has finished setting the values for the rental (setMilageCap, setExperience, setContractDuration, setVehicleChoice),
    * this method is used to lock a deposit and the weeklyPrice*2 into the contract. The contract is then started and transitioned into the Active state.
    */
    function confirmInitialPurchase() public onlyBuyer inState(State.Claimed)  payable {
        uint price = 2*weeklyPrice;
        require(msg.value == deposit+price, "The initial purchase should be the amount of the deposit added with 2 times the weekly rent.");
        emit PurchaseConfirmed();
        constractStart = getNow();
        state = State.Locked;
        }
    }
    
     /*
    * After the initial signing of the contract is done, the buyer can transfer money every week with this method by sending a value that is
    * equal to the value of weeklyPrice. The money is directly transferred to the sellers account. 
    * The method also checks whether the contract will expire in the next week and transitions the contract into the Endoptions state if that is the case.
    */
    function confirmWeeklyPurchase() public onlyBuyer inState(State.Active) payable {
        require(msg.value == weeklyPrice, "You should pay the full weekly amount for the rent");
        seller.transfer(weeklyPrice);
        //should multiply by 31556926 seconds (1 year). Is set to 1 min for testing purposes.
        uint contractDurationSeconds = duration*70;
        uint contractEnd = contractStart + contractDurationSeconds;
        uint weekSeconds = 604800;
        numberOfPayments = numberOfPayments+ 1;
        //should be "< weekSeconds" instead of "< 40"
        int a = int(contractEnd);
        if(int(contractEnd)-int(getNow()) < 40) {
                state = State.EndOptions;
            }
        }

  
    /*
    * This method will be called when buyer does not pay for a set amount of weeks (here 4). 
    * The seller then gets the deposit and the contract is terminated 
    */ 
    function abortContract() public onlySeller inState(State.Active) payable {
        //calculate the numb of payments that should have been transferred
       
        uint weekSeconds = 604800;
        //uint numWeeks= (getNow()-contractStart)/604800; //dette blir ikke riktig
        uint numWeeks= 4;
        uint diffWeeks=  numWeeks - numberOfPayments;
        
        if ( diffWeeks >2 ){    
            //When buyer has missed two or more payments, the seller can take the deposit and terminate the contract
            seller.transfer(address(this).balance); //the deposit
            state = State.Inactive;
            
        }
    }
    
    
    /*
    * This method is for the buyer to click to confirm that they have received the car. 
    * The buyer then receives the extra weeklyPrice value he/she payed during initializing 
    * to ensure a safe transfer and agreement of contract. 
    */
    function confirmReceived() public onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        state = State.Active;
        buyer.transfer(weeklyPrice);
    }


    /*
    * This method is used to refund the Seller its deposit for the initialization of the contract 
    * as well as transferring the first weekly payment of the buyer to the seller. 
    */
    function refundSeller() public onlySeller inState(State.Active) {
        emit SellerRefunded();
        require(address(this).balance - deposit > 0, "The weekly payment has not yet been paid by the buyer");
        if(sellerDeposit > 0) {
            seller.transfer(weeklyPrice + sellerDeposit);
        } else {
            seller.transfer(weeklyPrice);
        }
        sellerDeposit = 0;

    }
    
    /*
    * With this method, the buyer can choose the vehicle he/she would like to rent
    */
    function setVehicleChoice(string memory car) public returns(string memory) {
        for(uint i = 0; i < cars.length; i++){
            if((keccak256(abi.encodePacked((cars[i].name))) == keccak256(abi.encodePacked((car))))) {
                buyerCar = cars[i];
                //buyer = msg.sender;
                return car;
            } 
        }
        return "The vehicle does not exist";
    }
    
    /*
    * The buyer chooses the milage he/she wants to have, between 300 and 500 km
    */
    function setMilageCap(uint _milagecap) public returns(string memory) {
        if (_milagecap < 300) {
            return "This is too low";
        } else if(_milagecap > 500) {   
            return "The milage cap is too high";
        } else {
            milagecap = _milagecap;
        }
    }
    
    /* 
    * The buyer enters his/her driving experience in years. The number of years driven affects the renting price. 
    * If the buyer is inexperienced (has driven less than 5 years) there is an extra fee that works as insurance on the car. 
    */
    function setExperience(uint _experience) public returns(string memory) {
        experience = _experience;
    }
    
    /*
    * The buyer sets the amount of years he/she wants the contract to be (how long they will rent the car)
    */
    function setContractDuration(uint _duration) public returns(string memory) {
        require(_duration > 0, "Duration must be between 1 and 3 years.");
        require(_duration < 4, "Duration must be between 1 and 3 years.");
        duration = _duration;
    }
    
    /*
    * Thie method is used to calculate the weekly rent based on the parameters that the buyer sets,
    * including loyaltyYears.
    */
    function calculateWeeklyPrice() public {
        weeklyPrice = calculateRentalPrice(experience, buyerCar.price, milagecap, duration, loyaltyYears);
    }
    
  
   /*----------------------------------------
    * Define methods that the buyer can call after the contract has expired. 
    * We define one method for each option that the buyer has, 4 in total.
    ------------------------------------------*/
    
    /*
    * If the buyer wants to terminate the contract after it has expired, they can click this button. 
    */
    function terminateContract() public onlyBuyer inState(State.EndOptions) {
        buyer.transfer(deposit);
        deposit = 0;
        state = State.Inactive;
    }
    
    /*
    * If the buyer wants to extend the contract with the same car, he/she can click this button. 
    * This function adds a year to the buyers loyalty-tracker as well, which will give the buyer bonuses on further renting 
    */
    function extendContract() public onlyBuyer inState(State.EndOptions) {
        //Recompute weekly price
        //Setstate to active with the new price
        loyaltyYears = loyaltyYears + 1;
        experience= experience +1;
        contractStart = getNow();
        weeklyPrice = calculateRentalPrice(experience, buyerCar.price, milagecap, duration, loyaltyYears);
        state = State.Active;
    }
    
    /*
    * If the buyer wants to buy the car he is renting after the contract has expired.   
    * Directly transfer to seller because the buyer already has the car
    */
    function buyCar() public onlyBuyer inState(State.EndOptions) payable {
        require(deposit+msg.value == buyerCar.buyPrice);
        seller.transfer(buyerCar.buyPrice);
        state = State.Inactive;
        
    } 
    
    /* 
    * If the buyer wants to rent a new type of car. Loyalty points are still collected and applied to the new car-contract
    * The buyer has to enter the information anew? 
    */
    function newContract() public onlyBuyer inState(State.EndOptions) {
        loyaltyYears = loyaltyYears + 1;
        state = State.Claimed;
      	buyer.transfer(deposit);
        resetChoices();
        
    }
    // driver will have 1 year more experience
   
    
    /*---------------------------------------
    * Define actions that will not be executed on the blockchain.
    * These methods only return data and does not demand any update on the blockchain
    * @info The color of the buttons for these methods are blue
    ----------------------------------------*/

     
  	 function getVehicleChoices() public view returns(string memory){
        
        string memory choice;
        for(uint i=0; i < cars.length; i++){
            choice = string(abi.encodePacked(cars[i].name,", ",choice));
        }
        return choice;
    }
    
		/*
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
    
    function getState() public view returns (uint) {
        if(state == State.SetBuyer) {
            return 1;
        }
        return 0;
    }
    */
    
  	/*
    * Returns the current balance of the money locked inside the smart contract
    */
     function getBalance() public view returns (uint) {
         return address(this).balance;
     }
    
  
  	/* 
    * The buyer may check the price for buying the car he/she is currenty renting
    */
    function getBuyPriceForCurrentVehicle() public view returns(uint) {
        return buyerCar.buyPrice;
    }
    
    
    

  	/*---------------------------------------
    * HELPER FUNCTIONS 
    * These methods are used internally in the contract to make the logic simpler.
    ----------------------------------------*/
  
  	/*
    * Gets the current time (UNIX-format)
    */
    function getNow() public view returns (uint256 des) {
        uint256 des = block.timestamp;
        return des;
    }
    
  	/* 
    * Sets test values for the buyer to make testing easier. Also initializes the contract and calulates the weekly price.
    * TODO: Delete this method before delievry 
    */
    function setTestValues() public returns(string memory des) {
        initialiseContract();
        loyaltyYears = 0;
        experience = 6;
        duration = 1;
        milagecap = 300;
        buyerCar = cars[1];
        weeklyPrice = calculateRentalPrice(experience, buyerCar.price, milagecap, duration, loyaltyYears);
      
    }
    
    /*
    * This method contains the logic for calculating the rental price of a give car with parameters given by the buyer
    * in addition to loyalty years.
    */
    function calculateRentalPrice(uint _experience, uint basePrice, uint _milagecap, uint _duration, uint loyaltyYears) private returns(uint finalPrice){
        uint extraPrice = (_milagecap - 300);
        uint finalPrice = basePrice + extraPrice;
        
        
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
        
        if(state == State.SetBuyer) {
            deposit = finalPrice*4;
        }
        
        if(loyaltyYears < 10){
            finalPrice = finalPrice - (loyaltyYears*5);
        } else {
            finalPrice = finalPrice - 50;
        }
            
        
        return finalPrice;
    }
 	
  	/*
    * Convert uint to string
    */
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
    
  	/* 
    * Convert dollar to with fixed rate
    */
    function dollar2wei(uint _i) internal pure returns (uint){
        return _i*26000000000000000;
    } 
    
  	/* 
    * Function to set state if the state suddenly needs change during testing
    */
    function setState(uint input) public returns (uint){
        state = State(input);
    } 
    
    
  	/* 
    * Resets the parameters of the contract, 
    * needed if the buyer wants to extend a contract with a new car
    */
    function resetChoices() internal {
        experience = 0;
        milagecap = 0;
        duration = 0;
        weeklyPrice=0;
        sellerDeposit=0;
        deposit=0;
        buyerCar.name="Not car selected";
    }
    
   
}
