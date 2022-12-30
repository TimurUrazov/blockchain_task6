require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
/** @type import('hardhat/config').HardhatUserConfig */

const ALCHEMY_KEY = process.env.ALCHEMY_KEY;

module.exports = {
  solidity: "0.6.6",
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
      },
    },
  },
};
