import { CliUx } from "@oclif/core";
import { ethers } from "hardhat";
import { Helper } from "../scripts/helper";
import {
  BattlePass__factory,
  CreatorToken,
  CreatorToken__factory,
  Crafting__factory,
} from "../types";
export class Deployer {
  helper = new Helper();
  blocksToWait = 0;

  constructor() {
    if (process.env.ENV === "prod") {
      this.blocksToWait = 5;
    }
  }

  async deployBattlePass(
    creator_id: string,
    dbname: string,
    uri: string,
    crafting: string,
    game: string
  ) {
    let queryCommand =
      "SELECT address FROM contract WHERE creator_id=$1 AND ctr_type='CREATOR_TOKEN'";
    let res;
    let creatorToken = ethers.constants.AddressZero;
    try {
      res = await this.helper.queryDB(queryCommand, [parseInt(creator_id)]);
      creatorToken = res.rows[0].address;
    } catch (e) {
      console.log("There's no CreatorToken contract deployed");
      let answer = await CliUx.ux.prompt("Do you want to set a CreatorToken address?[y/n]");
      if (answer === "y") {
        creatorToken = await CliUx.ux.prompt("What's the address of the game contract?");
        if (!ethers.utils.isAddress(creatorToken)) {
          console.log("Please enter a valid ETH address");
          process.exit(1);
        }
      }
    }

    let bp_factory = (await ethers.getContractFactory("BattlePass")) as BattlePass__factory;
    let bp_contract = await bp_factory.deploy(
      uri,
      crafting,
      game,
      creatorToken,
      await this.helper.getMaticFeeData()
    );

    await ethers.provider.waitForTransaction(bp_contract.deployTransaction.hash, this.blocksToWait);
    if (process.env.ENV === "prod") {
      await this.helper.verify(bp_contract.address, [uri, crafting, game, creatorToken]);
    }

    queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
    let queryArgs = [
      bp_contract.address,
      "matic",
      dbname,
      parseInt(creator_id),
      this.helper.getABI("BattlePass"),
      "BATTLE_PASS",
    ];
    await this.helper.queryDB(queryCommand, queryArgs);

    if (!(creatorToken === ethers.constants.AddressZero)) {
      let ct_factory = (await ethers.getContractFactory("CreatorToken")) as CreatorToken__factory;
      let ct_contract = (await ct_factory.attach(creatorToken)) as CreatorToken;
      try {
        const receipt = await ct_contract.toggleWhitelist(
          bp_contract.address,
          true,
          await this.helper.getMaticFeeData()
        );
        await ethers.provider.waitForTransaction(receipt.hash, this.blocksToWait);
        console.log("receipt received");
      } catch (e) {
        console.log("tx failed!!!");
        console.log(e);
      }
    }
    return bp_contract.address;
  }

  async deployCreatorToken(
    creator_id: string,
    dbname: string,
    name: string,
    symbol: string,
    decimals: string
  ) {
    let factory = (await ethers.getContractFactory("CreatorToken")) as CreatorToken__factory;
    let contract = await factory.deploy(
      name,
      symbol,
      decimals,
      ethers.constants.AddressZero,
      await this.helper.getMaticFeeData()
    );

    await ethers.provider.waitForTransaction(contract.deployTransaction.hash, this.blocksToWait);
    if (process.env.ENV === "prod") {
      await this.helper.verify(contract.address, [
        name,
        symbol,
        decimals,
        ethers.constants.AddressZero,
      ]);
    }

    const queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
    const queryArgs = [
      contract.address,
      "matic",
      dbname,
      parseInt(creator_id),
      this.helper.getABI("CreatorToken"),
      "CREATOR_TOKEN",
    ];
    await this.helper.queryDB(queryCommand, queryArgs);
    return contract.address;
  }

  async deployCrafting(dbname: string) {
    let factory = (await ethers.getContractFactory("Crafting")) as Crafting__factory;
    let contract = await factory.deploy(await this.helper.getMaticFeeData());

    await ethers.provider.waitForTransaction(contract.deployTransaction.hash, this.blocksToWait);
    if (process.env.ENV === "prod") {
      await this.helper.verify(contract.address, []);
    }

    const queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
    const queryArgs = [
      contract.address,
      "matic",
      dbname,
      0,
      this.helper.getABI("Crafting"),
      "CRAFTING",
    ];
    await this.helper.queryDB(queryCommand, queryArgs);
    return contract.address;
  }
}
