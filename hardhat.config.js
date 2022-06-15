require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 const private_key = process.env.private_key2
 const project_ID = process.env.infura_project_id
 const ALCHEMY_ID = `https://eth-rinkeby.alchemyapi.io/v2/${process.env.alchemy_project_id}`;

module.exports = {
  defaultNetwork: 'rinkeby',
  solidity: {
    version : "0.8.4",
    settings : {
      "optimizer": {
        "enabled": true,
        "runs": 2000,
        "details": {
          "yul": true,
          "yulDetails": {
            "stackAllocation": true,
            "optimizerSteps": "dhfoDgvulfnTUtnIf"
          }
        }
      },
      "outputSelection": {
        "*": {
          "*": [
            "evm.bytecode",
            "evm.deployedBytecode",
            "devdoc",
            "userdoc",
            "metadata",
            "abi"
          ]
        }
      },
      "libraries": {}
    }
  },
  mocha: {
    timeout: 20000,
  },
  networks: {
    rinkeby: {
      url : ALCHEMY_ID,
      //url: `https://rinkeby.infura.io/v3/${project_ID}`, // Add your deployment URL. Remember to use and refer to .env
      accounts: [`${private_key}`], // Add your private key. Remember to use and refer to .env
      gas: "auto",
      gasPrice: "auto",
      gasLimit: 990000000
    },
    ropsten: {
      url : ALCHEMY_ID,
      //url: `https://ropsten.infura.io/v3/${project_ID}`, // Add your deployment URL. Remember to use and refer to .env
      accounts: [`${private_key}`], // Add your private key. Remember to use and refer to .env
      gas: 2100000,
      gasPrice: 8000000000,
      gasLimit: 16000000
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${project_ID}`, // Add your deployment URL. Remember to use and refer to .env
      accounts: [`${private_key}`], // Add your private key. Remember to use and refer to .env
      gas: 2100000,
      gasPrice: 8000000000,
      gasLimit: 16000000
    },
  },
};
