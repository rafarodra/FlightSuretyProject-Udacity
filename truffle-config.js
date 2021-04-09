var HDWalletProvider = require("truffle-hdwallet-provider");
//var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

//var mnemonic = "network cost stem cabin suggest agent inch custom uncle coast liar clay";
var mnemonic = "notable glad upon around beauty term trophy impose remove grunt aspect mixed";


module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:7545/", 0, 50);
      },
      network_id: '*',
      //gas: 9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.6.0"
    }
  }
};