import "hardhat-preprocessor";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import fs from "fs";
import dotenv from "dotenv";

dotenv.config();
let POLYGON_RPC = process.env.POLYGON_RPC;
let POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;

let PVT_KEY;
if (process.env.ENV == "dev") {
  PVT_KEY = process.env.STAGING_PVT_KEY;
} else {
  PVT_KEY = process.env.PVT_KEY;
}

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

module.exports = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  defaultNetwork: "localhost",
  networks: {
    matic: {
      url: POLYGON_RPC,
      accounts: [PVT_KEY],
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
    },
  },
  etherscan: {
    apiKey: POLYGONSCAN_API_KEY,
  },
  typechain: {
    outDir: "./admincli/src/types",
    target: "ethers-v5",
  },
  preprocess: {
    eachLine: (hre: any) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
  paths: {
    sources: "./src",
    cache: "./cache_hardhat",
    artifacts: "./artifacts_hardhat",
  },
};
