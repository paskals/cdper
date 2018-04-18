var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "purity youth scorpion junk exhaust joke engine access hammer machine alley cruel";

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {	
    gan: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777" // Match any network id
    },
    ganc: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "5777" // Match any network id
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"),
      network_id: "3"
    },
    kovan: {
      provider: new HDWalletProvider(mnemonic, "https://kovan.infura.io/"),
      network_id: "42"
    }
  },
  
  solc: {
		optimizer: {
			enabled: true,
			runs: 200
		}
	}
};
