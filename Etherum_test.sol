pragma solidity >=0.4.22 <0.7.0;

contract BilBoydDealership {
    uint public value; 
    address payable public BilBoyd; // seller
    address payable public Mattia; // buyer 
    enum vehicle_choices {Pickup, SUV, Mini, Tesla}
    vehicle_choices choice;
    vehicle_choices constant defaultChoice = vehicle_choices.Tesla;
    
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
    
    
    
    //Mattia must choose values for the car 
    function getCoice() public view returns (vehicle_choices) {
        return choice;
    }
  
}
