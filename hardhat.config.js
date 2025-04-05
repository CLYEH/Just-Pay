require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ignition");
// require('@nomiclabs/hardhat-etherscan');
require('dotenv').config();

const { PRIVATE_KEY, ETHERSCAN_API_KEY, BASESCAN_API_KEY, LINEASCAN_API_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      evmVersion: "london",
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    }
  },

  networks:{
    zircuit: {
      url: `https://mainnet.zircuit.com`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    ethereum: {
      url: `https://eth-mainnet.g.alchemy.com/v2/zbtfz25b7bCDvZK3w-mObaiAnHygj48I`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    base: {
      url: `https://mainnet.base.org`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    avalanche: {
      url:`https://api.avax.network/ext/bc/C/rpc`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    linea: {
      url:`https://rpc.linea.build`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    polygon: {
      url:`https://polygon-mainnet.g.alchemy.com/v2/zbtfz25b7bCDvZK3w-mObaiAnHygj48I`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    eth_sepolia: {
      url:`https://eth-sepolia.g.alchemy.com/v2/zbtfz25b7bCDvZK3w-mObaiAnHygj48I`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    base_sepolia: {
      url:`https://sepolia.base.org`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    linea_sepolia: {
      url:`https://rpc.sepolia.linea.build`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    avalanche_fuji: {
      url:`https://avax-fuji.g.alchemy.com/v2/zbtfz25b7bCDvZK3w-mObaiAnHygj48I`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    polygon_amoy: {
      url:`https://polygon-amoy.g.alchemy.com/v2/zbtfz25b7bCDvZK3w-mObaiAnHygj48I`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
  },

  sourcify: {
    enabled: true,
    apiUrl: 'https://sourcify.dev/server',
    browserUrl: 'https://repo.sourcify.dev',
  },

  etherscan: {
    apiKey: {
      ethereum:[ETHERSCAN_API_KEY],
      base: [BASESCAN_API_KEY],
      snowtrace: "snowtrace",
      fuji: "snowtrace",
      linea: [LINEASCAN_API_KEY],
      linea_sepolia: [LINEASCAN_API_KEY],
      sepolia: [ETHERSCAN_API_KEY],
      base_sepolia: [BASESCAN_API_KEY],
    },
    customChains: [
      {
        network: "snowtrace",
        chainId: 43114,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan",
          browserURL: "https://avalanche.routescan.io"
        }
      },
      {
        network: "base_sepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org"
        }
      },
      {
        network: "fuji",
        chainId: 43113,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://testnet.snowtrace.io/"
        }
      },
      {
        network: "linea",
        chainId: 59144,
        urls: {
          apiURL: "https://api.lineascan.build/api",
          browserURL: "https://lineascan.build/"
        }
      },
      {
        network: "linea_sepolia",
        chainId: 59141,
        urls: {
          apiURL: "https://api-sepolia.lineascan.build/api",
          browserURL: "https://sepolia.lineascan.build/"
        }
      },
    ]
  }
   
};