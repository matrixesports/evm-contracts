const hre = require("hardhat");
const { Pool } = require("pg");
const axios = require("axios");
const dotenv = require("dotenv");
const { ethers } = require("hardhat");
dotenv.config();

let connectionString;
if (process.env.ENV == "dev") {
  connectionString = process.env.STAGING_RAILWAY_URL;
} else {
  connectionString = process.env.RAILWAY_URL;
}

const pool = new Pool({
  connectionString,
});

async function main() {
  let creator_id = 12;

  //   args = [
  //     "ipfs://QmRhxn2VDcuzcsoAW3EojCumSncLUxk5fZUfecjxEZZWAt",
  //     ethers.constants.AddressZero,
  //     ethers.constants.AddressZero,
  //     ethers.constants.AddressZero,
  //   ];

  //   console.log("deploying...");
  //   let passAddress = await deploy("BattlePass", args);
  //   await verify(passAddress, args);
  let passAddress = "0x2697B92eE8231d59d4f73971279C86a03FF1fe3D";

  //   passAddress = ethers.utils.getAddress(passAddress);
  //   let name = "RocketCR";
  //   let description = "Clash Royale Streamer";
  //   let abi = getABI("BattlePass");
  //   //   await addtodb(passAddress, "matic", name, abi, creator_id, "BATTLE_PASS");
  //   let date = new Date();
  //   await addtopassdb(
  //     passAddress,
  //     name,
  //     description,
  //     "4.99",
  //     "USD",
  //     date,
  //     ["CASHAPP", "PAYPAL_EMAIL", "VENMO_USERNAME"],
  //     [
  //       "INSTAGRAM_USERNAME",
  //       "TWITTER_USERNAME",
  //       "TWITCH_USERNAME",
  //       "CLASH_USERNAME",
  //       "PREFERRED_SOCIAL",
  //     ]
  //   );
  //   console.log("gg");
}

async function deploy(name, args) {
  let Contract = await ethers.getContractFactory(name);
  let ctr = await Contract.deploy(...args);
  console.log("waiting...");
  await hre.ethers.provider.waitForTransaction(ctr.deployTransaction.hash, 5);
  console.log(name + " deployed to:", ctr.address);
  return ctr.address;
}

async function verify(address, args) {
  console.log("verifying...");
  await hre.run("verify:verify", {
    address: address,
    constructorArguments: [...args],
  });
  console.log("verified...");
}

async function addtopassdb(
  address,
  name,
  description,
  price,
  currency,
  end_date,
  required_user_payment_options,
  required_user_social_options
) {
  console.log("adding...");
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const queryText = "INSERT INTO battlepass Values($1,$2,$3,$4,$5,$6,$7,$8)";
    const query_args = [
      address,
      name,
      description,
      price,
      currency,
      end_date,
      required_user_social_options,
      required_user_payment_options,
    ];
    await client.query(queryText, query_args);
    await client.query("COMMIT");
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
  console.log("added...");
}

async function addtodb(address, network, name, abi, creator_id, ctr_type) {
  console.log("adding...");
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const queryText = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
    const query_args = [address, network, name, creator_id, abi, ctr_type];
    await client.query(queryText, query_args);
    await client.query("COMMIT");
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
  console.log("added...");
}

function getABI(name) {
  let compiled = require(process.cwd() + `/out/${name}.sol/${name}.json`);
  return JSON.stringify(compiled.abi);
}

async function queryDB(query, args) {
  let res;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    res = await client.query(query, args);
    await client.query("COMMIT");
    return res;
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}

async function getMaticFeeData() {
  try {
    const { data } = await axios({
      method: "get",
      url: "https://gasstation-mainnet.matic.network/v2",
    });
    let maxFeePerGas = ethers.utils.parseUnits(Math.ceil(data.fast.maxFee) + "", "gwei");
    let maxPriorityFeePerGas = ethers.utils.parseUnits(
      Math.ceil(data.fast.maxPriorityFee) + "",
      "gwei"
    );

    return {
      maxPriorityFeePerGas,
      maxFeePerGas,
    };
  } catch (e) {
    console.log(e);
    return {
      maxPriorityFeePerGas: ethers.utils.parseUnits(Math.ceil(40) + "", "gwei"),
    };
  }
}
module.exports = {
  queryDB,
  getMaticFeeData,
};
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
