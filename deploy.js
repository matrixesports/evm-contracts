const hre = require("hardhat");
const { Pool } = require("pg");
const axios = require("axios");
const dotenv = require("dotenv");
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
  let name;
  let args;
  let abi;
  let ctr_type;
  let creator_id = 25;

  // name = "Recipe";
  // args = [""];
  // abi = getABI(name);
  // ctr_type = name;
  // // let recipe_addy = await deploy(name, args);
  let recipe_addy = "0x34df2ad1fb25a8Ef566847Bc16C7b9d626482487";
  // await verify(recipe_addy, args);
  // await addtodb(recipe_addy, "matic", name, creator_id, abi, ctr_type);
  // console.log("gg");

  name = "BattlePass";
  args = [
    "ipfs://QmSaH8G32yjYDabsR4YPchycsbofUt9KyGaJS1RvT21kdq",
    recipe_addy,
    recipe_addy,
    recipe_addy,
  ];
  abi = getABI(name);
  ctr_type = "BATTLE_PASS";
  console.log("deploying...");
  //   let passAddress = await deploy(name, args);
  let passAddress = "0x8d8631397A54d277E3b3F545D2b2c828e0074638";
  //   await verify(passAddress, args);
  //   await addtodb(passAddress, "matic", name, abi, creator_id, ctr_type);
  console.log(await getMaticFeeData());
  console.log("gg");
  // let passAddress = "0x80e00860CF0749A0247785A4bC9E933b20251AFc";

  // name = "Lootbox";
  // args = [
  //     "",
  //     passAddress,
  //     recipe_addy,
  //     85,
  //     "0xAE975071Be8F8eE67addBC1A82488F1C24858067",
  //     "0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93",
  // ];
  // abi = getABI(name);
  // ctr_type = name;
  // let address = await deploy(name, args);
  // await verify(address, args);
  // await addtodb(address, "matic", name, creator_id, abi, ctr_type);
  // console.log("gg");

  //   name = "Redeemable";
  //   args = ["ipfs://QmX1TekzfXg2TfP1UUBVesSEvkXvw31zjQUcerfgdgVw8a", passAddress, recipe_addy];
  //   abi = getABI(name);
  //   ctr_type = name;
  //   let address = await deploy(name, args);
  //   await verify(address, args);
  //   await addtodb(address, "matic", name, abi, creator_id, "BATTLE_PASS");
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
async function addtodb(address, network, name, abi, creator_id, ctr_type) {
  console.log("adding...");
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const queryText = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
    const query_args = [address, network, name, abi, creator_id, ctr_type];
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
