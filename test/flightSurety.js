
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyApp.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyApp.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

 
  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, {from:config.owner});
      }
      catch(e) {
          console.log(e); 
          accessDenied = true;
      }
      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true, {from:config.owner});

      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false, {from:config.owner});

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true, {from:config.owner});

      assert.equal(reverted, true, "Access not blocked for requireIsOperational");
  });

  it(`(airline) can successfully register first airline during contract deployment`, async function () {

    // ensures the first airline was created during deployment of the App contract

    let airlineFound = true;
    var result; 
    
    try 
    {   
        result = await config.flightSuretyApp.fetchAirlineStatus(config.firstAirline);       
    }
    catch(e) {
        airlineFound = false;
    }

    assert.equal(airlineFound, true, "Error: Airline not found or error");
    assert.equal(result[0], config.firstAirlineName, 'Error: First airline name does not match');
    assert.equal(result[1], 1, 'Error: First airline state does not match RegistereNotFunded');
    assert.equal(result[2], 0, 'Error: First airline minimum required votes do not match');
    assert.equal(result[3], 0, 'ErError: First airline positive received votes do not match'); 
});

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    let newAirlineName = 'Udacity #2';

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirlineName, newAirline, {from: config.firstAirline});
    }
    catch(e) {
        console.log(e); 
    }
    let result = await config.flightSuretyApp.fetchAirlineStatus(newAirline); 
    
    // ASSERT
    assert.equal(result[0], '', 'Error: Airline was created using unfunded airline');
  });
 
  it('(airline) can fund an airline', async () => {
    
    // ARRANGE
    var txn; ;
    var airlineStatus;
    var oldContractBalance;
    var newContractBalance;
    const payment = web3.utils.toWei('10', 'ether'); 

    // ACT
    try {
      oldContractBalance = await config.flightSuretyApp.getContractBalance.call();
      txn = await config.flightSuretyApp.fundAirline({from: config.firstAirline, value: payment});
      newContractBalance = await config.flightSuretyApp.getContractBalance.call(); 
      
      airlineStatus = await config.flightSuretyApp.fetchAirlineStatus(config.firstAirline);         
    }
    catch(e) {
        console.log(e); 
    }
      
    // ASSERT
    assert.equal(oldContractBalance < newContractBalance, true, 'Error: Balance of the contract did not change'); 
    assert.equal(txn.logs[0].event, 'AirlineFunded', 'Error: Airline was not funded correctly');
    assert.equal(airlineStatus.isFunded, true, 'Error: Airline did not change to the correct IsFunded State');
  });

 /* it('(airline) can register an Airline using registerAirline() if it is funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[3];
    let newAirlineName = 'Udacity #3';

    // ACT
    try {
        let fundResult = config.flightSuretyApp.fundAirline({from: config.firstAirline});
        if(fundResult){
          
        } 

        
    }
    catch(e) {
        console.log(e); 
    }
    let result = await config.flightSuretyApp.fetchAirlineStatus(newAirline); 
    
    // ASSERT
    assert.equal(result[0], '', 'Error: Airline was created using unfunded airline');
  });*/
});
