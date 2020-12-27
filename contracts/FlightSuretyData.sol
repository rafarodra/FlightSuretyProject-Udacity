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

    //CONSTS
    uint8 private constant FOUNDING_AIRLINES = 4;

    enum AirlineState 
    { 
        PendingApproval,  // 0
        RegisteredNotFunded,  // 1
        RegisteredFunded //2
    }

    struct Airline {
        string name;
        AirlineState state;
        uint256 minRequiredVotes; 
        uint256 positiveReceivedVotes; 
    }

    mapping(address => Airline) private airlines;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AirlineRegistered(string airlineName); 

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
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
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
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
    modifier requireActiveAirline()
    {
        require(isAirlineActive(msg.sender), "Caller is not an active airline");
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
    function isAirlineActive(address addr) 
                            public 
                            view 
                            returns(bool) 
    {
        bool retval = false; 
        if(airlines[addr].state == AirlineState.RegisteredFunded)
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
                            requireIsOperational
    {
        operational = mode;
    }

    /**
    * @dev Gets the required votes to be accepted as a registered member
    *
    * @return A uint256 with the minimum required votes 
    */
    function getRequiredVotes() public view returns(uint256){
        if(totalRegisteredAirlines <= FOUNDING_AIRLINES){
            return 0; 
        } 
        else{
            return totalRegisteredAirlines % 2; 
        }

    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (string memory airlineName,
                            address airlineAddress
                            )
                            external
                            requireIsOperational
                            requireActiveAirline

    {
        AirlineState newState = AirlineState.PendingApproval; 

        if(totalRegisteredAirlines <= FOUNDING_AIRLINES){
             newState = AirlineState.RegisteredNotFunded; 
        }       

        airlines[airlineAddress] = Airline(airlineName, newState, getRequiredVotes(), 0);
        emit AirlineRegistered(airlineName); 
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

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

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
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
    {
        fund();
    }


}

