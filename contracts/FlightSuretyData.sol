// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint private totalRegisteredAirlines = 0; 
    address authorizedCaller; 

    //CONSTS
    uint8 private constant FOUNDING_AIRLINES = 4;
    uint256 private constant MEMBERSHIP_FEE = 10 ether;

    enum AirlineState 
    { 
        PendingApproval,  // 0
        Registered //1
    }

    struct Airline {
        string name;
        AirlineState state;
        bool isFunded; 
        uint256 minRequiredVotes; 
        uint256 positiveReceivedVotes;
        uint256 balance; 
    }

    struct Passenger{
        uint256 balance;
        uint256 withdrawableBalance;
    }

    struct FlightInsurance{ 
        mapping(address => uint256) insurancePaid; 
    }

    mapping(address => Airline) private airlines;
    mapping(string => FlightInsurance) private insurances; //string key = flight name
    mapping(address => Passenger) private passengers; 


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AirlineRegistered(string airlineName);
    event OperationalStatusChanged(bool status, address requestor);
    event AirlineFunded(address airline, uint256 amount, uint256 oldBalace, uint256 newBalance); 
    event InsuranceBought(address passenger, uint256 amount, uint256 oldBalace, uint256 newBalance);
    event dummyEvent(string text); 

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(isOperational(), "Data Contract is currently not operational");
        _; 
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the airline to be an active member
    */
    modifier requireActiveAirline(address addr)
    {
        if(totalRegisteredAirlines > 0){           
            require(isAirlineActive(addr), "Caller is not an active airline");            
        }        
        _;
    }

    /**
    * @dev Modifier that requires the minimum amount is meet in order to activate an airline
    */
    modifier requireMinimumFee()
    {
        require(msg.value >= MEMBERSHIP_FEE, "Amount sent is less than the membership fee");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    /**
    * @dev Get airline status
    *
    * @return A bool stating wheter the airline is an active member 
    */
    function isAirlineActive(address airlineAddress) 
                            public 
                            view 
                            returns(bool) 
    {
        bool retval = false; 
        if((airlines[airlineAddress].isFunded) && (airlines[airlineAddress].state == AirlineState.Registered))
        {
            retval = true;
        }
        return retval; 
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner
    {
        operational = mode;
        emit OperationalStatusChanged(operational, msg.sender); 
    }

    /**
    * @dev Gets the required votes to be accepted as a registered member
    *
    * @return A uint256 with the minimum required votes 
    */
    function getRequiredVotes() private view returns(uint256){
        if(totalRegisteredAirlines < FOUNDING_AIRLINES){
            return 0; 
        } 
        else{
            return totalRegisteredAirlines.div(2); 
        }
    }

    function getContractBalance() 
                                external 
                                view
                                returns (uint256)
                                {
        return address(this).balance; 
    }

    function getTotalRegisteredAirlines()
                                external
                                view
                                returns(uint256){
        
        return totalRegisteredAirlines; 
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(string memory airlineName, address airlineAddress, address requestorAddress) 
                                                                    external 
                                                                    requireIsOperational 
                                                                    requireActiveAirline(requestorAddress) 
    {
        AirlineState newState;

        if(totalRegisteredAirlines < FOUNDING_AIRLINES){
             newState = AirlineState.Registered;
             totalRegisteredAirlines = totalRegisteredAirlines.add(1);
        }
        else{
            newState = AirlineState.PendingApproval;
        }

        airlines[airlineAddress] = Airline(airlineName, newState, false, getRequiredVotes(), 0, 0);        
        emit AirlineRegistered(airlineName); 
    }

    /**
    * @dev Retrieves the current status of a given airline
    *
    */  
    function fetchAirlineStatus(address airlineAddress) 
                                        external 
                                        view 
                                        requireIsOperational 
                                        returns(
                                            string memory name, 
                                            uint256 state, 
                                            bool isFunded, 
                                            uint256 minRequiredVotes, 
                                            uint256 positiveReceivedVotes,
                                            uint256 balance
                                            ) 
    {
        FlightSuretyData.Airline memory airline = airlines[airlineAddress]; 
        return(airline.name, uint256(airline.state), airline.isFunded, airline.minRequiredVotes, airline.positiveReceivedVotes, airline.balance); 
    }

    /**
    * @dev Funds a given airline and tranfers the funds to the contract's balance
    *
    */ 
    function fundAirline(address airlineAddress)
                    external
                    payable
                    requireIsOperational
                    requireMinimumFee                    
    {
        uint256 oldBalance = airlines[airlineAddress].balance;  
        airlines[airlineAddress].balance = airlines[airlineAddress].balance.add(msg.value);
        airlines[airlineAddress].isFunded = true;        
        emit AirlineFunded(airlineAddress, msg.value, oldBalance, airlines[airlineAddress].balance);
    } 

    /**
    * @dev This function is to submit voting to approve a given airline
    *
    */ 
    function approveAirline(address airlineToApprove, address requestorAddress)
                                    external
                                    requireIsOperational
                                    requireActiveAirline(requestorAddress)
    {
        require(airlineToApprove != requestorAddress, "Votes cannot be emited by the same candidate airline"); 
        airlines[airlineToApprove].positiveReceivedVotes = airlines[airlineToApprove].positiveReceivedVotes.add(1);

        if (airlines[airlineToApprove].positiveReceivedVotes >= airlines[airlineToApprove].minRequiredVotes)
        {
            airlines[airlineToApprove].state = AirlineState.Registered; 
        }
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (       
                                address passenger                      
                            )
                            external
                            payable
                            requireIsOperational
    {
        uint256 oldBalance = airlines[airlineAddress].balance;  
        airlines[airlineAddress].balance = airlines[airlineAddress].balance.add(msg.value);
        airlines[airlineAddress].isFunded = true;        
        emit InsuranceBought(passenger, msg.value, oldBalance, airlines[airlineAddress].balance);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   
    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() 
                            external 
                            payable
                            requireIsOperational
    {
        
    }


}

