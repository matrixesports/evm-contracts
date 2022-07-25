import { Command, CliUx } from "@oclif/core";
import { Helper } from "../scripts/helper";
import { ethers } from "hardhat";
import { BattlePass, BattlePass__factory, Crafting, Crafting__factory } from "./../types";
import { LevelInfoStruct } from "../types/src/battle-pass/BattlePass";
import { LootboxOptionStruct } from "../types/src/battle-pass/Rewards";
enum ACT {
  Season = 1,
  Lootbox = 2,
  Recipe = 3,
}
export default class Create extends Command {
  static description = "Interacts with deployed contracts";
  helper = new Helper();
  crafting = "0x0000000000000000000000000000000000000000";
  pass = "0x0000000000000000000000000000000000000000";
  blocksToWait = 0;
  public async run(): Promise<void> {
    if (process.env.ENV === "prod") {
      this.blocksToWait = 5;
    }
    const action = parseInt(
      await CliUx.ux.prompt(
        "Available actions:\n1: new Season\n2: new Lootbox\n3: new Recipe\nSelect type"
      )
    );
    if (isNaN(action) || action < 1 || action > Object.keys(ACT).length) {
      this.log("Please enter a valid number");
      process.exit(1);
    }

    const creator_id = await CliUx.ux.prompt("What's the creator_id?");
    if (isNaN(Number(creator_id))) {
      this.log("Please enter a valid number!");
      process.exit(1);
    }

    if (action === ACT.Season) {
      this.pass = await this.getContractAddress("BATTLE_PASS", creator_id);
      let factory = (await ethers.getContractFactory("BattlePass")) as BattlePass__factory;
      let contract = (await factory.attach(this.pass)) as BattlePass;
      this.log("sending tx to create new season...");
      try {
        const receipt = await contract.newSeason(
          await this.createSeason(),
          await this.helper.getMaticFeeData()
        );
        await ethers.provider.waitForTransaction(receipt.hash, this.blocksToWait);
        console.log("receipt received");
      } catch (e) {
        console.log("tx failed!!!");
        console.log(e);
        process.exit(1);
      }
      this.log("Season created");
    }
    if (action === ACT.Lootbox) {
      this.pass = await this.getContractAddress("BATTLE_PASS", creator_id);
      let factory = (await ethers.getContractFactory("BattlePass")) as BattlePass__factory;
      let contract = (await factory.attach(this.pass)) as BattlePass;
      this.log("sending tx to create new lootbox...");
      try {
        const receipt = await contract.newLootbox(
          await this.createLootbox(),
          await this.helper.getMaticFeeData()
        );
        await ethers.provider.waitForTransaction(receipt.hash, this.blocksToWait);
        console.log("receipt received");
      } catch (e) {
        console.log("tx failed!!!");
        console.log(e);
        process.exit(1);
      }
      this.log("Lootbox created");
    }
    if (action === ACT.Recipe) {
      this.pass = await this.getContractAddress("BATTLE_PASS", creator_id);
      this.log("Default crafting address: " + this.crafting);
      let answer = await CliUx.ux.prompt("Do you want to use default crafting address?[y/n]");
      if (answer === "n") {
        this.crafting = await CliUx.ux.prompt("What's the address of the crafting contract?");
        if (!ethers.utils.isAddress(this.crafting)) {
          this.log("Please enter a valid ETH address");
          process.exit(1);
        }
      }
      let factory = (await ethers.getContractFactory("Crafting")) as Crafting__factory;
      let contract = (await factory.attach(this.crafting)) as Crafting;
      this.log("Creating the input ingredients list...");
      let inputIng = await this.createIngredients();
      this.log("Creating the output ingredients list...");
      let outputIng = await this.createIngredients();
      this.log("sending tx to create new recipe...");
      try {
        const receipt = await contract.addRecipe(
          inputIng,
          outputIng,
          creator_id,
          await this.helper.getMaticFeeData()
        );
        await ethers.provider.waitForTransaction(receipt.hash, this.blocksToWait);
        console.log("receipt received");
      } catch (e) {
        console.log("tx failed!!!");
        console.log(e);
        process.exit(1);
      }
      this.log("Recipe created");
    }
  }

  async getContractAddress(ctr_type: string, creator_id: string) {
    const queryCommand = "SELECT address FROM contract WHERE creator_id=$1 AND ctr_type=$2";
    let res: any;
    try {
      res = await this.helper.queryDB(queryCommand, [parseInt(creator_id), ctr_type]);
    } catch (e) {
      this.log(`There's no ${ctr_type} contract deployed for creatorId ${creator_id}`);
    }
    return res.rows[0].address;
  }

  async getRewardInfo() {
    const free_id = await CliUx.ux.prompt("What's the FREE reward id?");
    if (isNaN(free_id) || free_id < 0) {
      this.log("Please enter a valid number");
      process.exit(1);
    }

    const free_qty = await CliUx.ux.prompt("What's the FREE reward qty?");
    if (isNaN(free_qty) || free_qty < 0) {
      this.log("Please enter a valid number");
      process.exit(1);
    }

    const prem = await CliUx.ux.prompt("Do you want a PREMIUM reward?[y/n]");
    let prem_id = 0;
    let prem_qty = 0;
    if (prem === "y") {
      prem_id = await CliUx.ux.prompt("What's the PREMIUM reward id?");
      if (isNaN(prem_id) || prem_id < 0) {
        this.log("Please enter a valid number");
        process.exit(1);
      }

      prem_qty = await CliUx.ux.prompt("What's the PREMIUM reward qty?");
      if (isNaN(prem_qty) || prem_qty < 0) {
        this.log("Please enter a valid number");
        process.exit(1);
      }
    }
    return { free_id, free_qty, prem_id, prem_qty };
  }

  async createSeason() {
    let levelsInfo: LevelInfoStruct[] = [];

    const levels = parseInt(await CliUx.ux.prompt("What's the number of levels"));
    if (isNaN(levels) || levels < 0) {
      this.log("Please enter a valid number");
      process.exit(1);
    }

    for (let lvl = 0; lvl <= levels; lvl++) {
      console.log(`Creating info for level ${lvl + 1}`);
      let xp: any;
      if (lvl != levels) {
        xp = await CliUx.ux.prompt("What's the needed xp");
        if (isNaN(xp) || xp < 0) {
          this.log("Please enter a valid number");
          process.exit(1);
        }
      } else {
        xp = "0";
      }
      const { free_id, free_qty, prem_id, prem_qty } = await this.getRewardInfo();
      levelsInfo.push({
        xpToCompleteLevel: xp,
        freeRewardId: free_id,
        freeRewardQty: free_qty,
        premiumRewardId: prem_id,
        premiumRewardQty: prem_qty,
      });
    }
    return levelsInfo;
  }

  async createLootbox() {
    let lootboxOptions: LootboxOptionStruct[] = [];
    let jointprob = 0;
    let counter = 1;
    let maxProb = 100;
    while (jointprob < maxProb) {
      this.log(`Creating lootboxOption ${counter}...`);
      const rarity = parseInt(
        await CliUx.ux.prompt(
          `Max available rarity ${maxProb - jointprob}\nWhat's the rarity for this option?`
        )
      );
      if (isNaN(rarity) || rarity < 0 || rarity > maxProb - jointprob) {
        this.log("Please enter a valid number");
        process.exit(1);
      }
      const rewards = parseInt(await CliUx.ux.prompt("What's the number of rewards?"));
      if (isNaN(rewards) || rewards < 0) {
        this.log("Please enter a valid number");
        process.exit(1);
      }
      let ids: string[] = [];
      let qtys: string[] = [];
      for (let i = 0; i < rewards; i++) {
        const id = await CliUx.ux.prompt(`What's the id for reward ${i + 1}?`);
        if (isNaN(id) || id < 0) {
          this.log("Please enter a valid number");
          process.exit(1);
        }
        ids.push(id);
        const qty = await CliUx.ux.prompt(`What's the qty for reward ${i + 1}?`);
        if (isNaN(qty) || qty < 0) {
          this.log("Please enter a valid number");
          process.exit(1);
        }
        qtys.push(qty);
      }
      lootboxOptions.push({
        rarityRange: [jointprob, jointprob + rarity],
        ids: ids,
        qtys: qtys,
      });
      jointprob += rarity;
    }
    return lootboxOptions;
  }

  async createIngredients() {
    const ingNum = parseInt(await CliUx.ux.prompt("What's the number of ingredients?"));
    if (isNaN(ingNum) || ingNum < 0) {
      this.log("Please enter a valid number");
      process.exit(1);
    }
    let tokens: string[] = [];
    let ids: string[] = [];
    let qtys: string[] = [];

    for (let i = 0; i < ingNum; i++) {
      const lookup = await CliUx.ux.prompt(
        "Do you want to choose from all BattlePass contracts?[y/n]"
      );
      if (lookup === "y") {
        const queryCommand =
          "SELECT address, name, creator_id FROM contract WHERE ctr_type='BattlePass'";
        const query = await this.helper.queryDB(queryCommand, []);
        for (const [index, row] of query.rows.entries()) {
          console.log(
            `${index + 1}: BattlePass for creatorId ${row.creator_id} and name ${row.name}`
          );
        }
        const selector = parseInt(
          await CliUx.ux.prompt(`Select BattlePass for ingredient ${i + 1}`)
        );
        if (isNaN(selector) || selector < 0 || selector > query.rows.length) {
          this.log("Please enter a valid number");
          process.exit(1);
        }
        tokens.push(query.rows[selector - 1].address);
      } else {
        tokens.push(this.pass);
      }

      const id = await CliUx.ux.prompt(`What's the id for reward ${i + 1}?`);
      if (isNaN(id) || id < 0) {
        this.log("Please enter a valid number");
        process.exit(1);
      }
      ids.push(id);
      const qty = await CliUx.ux.prompt(`What's the qty for reward ${i + 1}?`);
      if (isNaN(qty) || qty < 0) {
        this.log("Please enter a valid number");
        process.exit(1);
      }
      qtys.push(qty);
    }
    return {
      tokens: tokens,
      ids: ids,
      qtys: qtys,
    };
  }
}
