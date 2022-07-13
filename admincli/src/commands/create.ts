import { Command, CliUx } from "@oclif/core";
import { Healper } from "../scripts/healper";
import { ethers } from "hardhat";
import { BattlePass, BattlePass__factory } from "./../types";
import { LevelInfoStruct } from "../types/src/battle-pass/BattlePass";
import { LootboxOptionStruct } from "../types/src/battle-pass/Rewards";

enum ACT {
    Season = 1,
    Lootbox = 2,
    Recipe = 3,
}
export default class Create extends Command {
    creator_id = "";
    healper = new Healper();
    crafting = "0x0000000000000000000000000000000000000000";
    game = "0x0000000000000000000000000000000000000000";
    creatorToken = "0x0000000000000000000000000000000000000000";
    pass = "0x0000000000000000000000000000000000000000";
    static description = "Interacts with deployed contracts";
    // prod - 5; dev - 0
    blocksToWait = 0;    

    public async run(): Promise<void> {
        if (process.env.ENV === "prod") { this.blocksToWait = 5; }
        const action = parseInt(
            await CliUx.ux.prompt(
                "Available actions:\n1: new Season\n2: new Lootbox\n3: new Recipe\nSelect type"
            )
        );
        if (isNaN(action) || action < 1 || action > Object.keys(ACT).length) {
            this.log("Please enter a valid number");
            process.exit(1);
        }

        this.creator_id = await CliUx.ux.prompt("What's the creator_id?");
        if (isNaN(Number(this.creator_id))) {
            this.log("Please enter a valid number!");
            process.exit(1);
        }

        if (action === ACT.Season) {
            this.pass = await this.getContractAddress("BattlePass");
            let factory = (await ethers.getContractFactory("BattlePass")) as BattlePass__factory;
            let contract = (await factory.attach(this.pass)) as BattlePass;
            this.log("sending tx to create new season...");
            try {
                const receipt = await contract.newSeason(await this.createSeason(), await this.healper.getMaticFeeData());
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

        }
    }

    async getContractAddress(ctr_type: string) {
        const queryCommand =
        "SELECT address FROM contract WHERE creator_id=$1 AND ctr_type=$2";
        let res: any;
        try {
            res = await this.healper.queryDB(queryCommand, [this.creator_id, ctr_type]);
        } catch (e) {
            this.log("There's no CreatorToken contract deployed");
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
        return {free_id, free_qty, prem_id, prem_qty};
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
                premiumRewardQty: prem_qty
            })
        }
        return levelsInfo;
    }

    async createLootbox() {
        let lootboxOptions: LootboxOptionStruct;
    }
}
