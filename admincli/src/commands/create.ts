import { Command, Flags, CliUx } from "@oclif/core";
import { Helper } from "../scripts/helper";
import { ethers } from "hardhat";
import { Pass, Pass__factory } from "./../types";
import { ERC1155RewardStruct, LevelInfoStruct } from "../types/src/Pass";

enum ACT {
    Season = 1,
    Lootbox = 2,
    Recipe = 3,
}
export default class Create extends Command {
    healper = new Helper();
    static description = "Interacts with deployed contracts";
    static examples = ["add -i"];
    static flags = {
        interactive: Flags.boolean({ char: "i", description: "interactive mode" }),
    };

    public async run(): Promise<void> {
        const { flags } = await this.parse(Create);

        if (flags.interactive) {
            this.interactive();
        } else {
            console.log("Only interactive mode, use -i");
            process.exit(1);
        }
    }

    async interactive() {
        const action = parseInt(
            await CliUx.ux.prompt(
                "Available actions\n1: Season \n2: Lootbox\n3: Recipe\nSelect action"
            )
        );
        if (isNaN(action) || action < 1 || action > Object.keys(ACT).length) {
            this.log("Please enter a valid number");
            process.exit(1);
        }
        const creator = await CliUx.ux.prompt("What's the creator_id");
        if (isNaN(creator)) {
            this.log("Please enter a valid number");
            process.exit(1);
        }

        switch (action) {
            case ACT.Season:
                let contract;
                const queryCommand =
                    "SELECT address FROM contract WHERE creator_id=$1 AND ctr_type='Pass'";
                let query = await this.healper.queryDB(queryCommand, [creator]);
                // try with no pass
                const pass_address = query.rows[0].address;
                const factory = (await ethers.getContractFactory("Pass")) as Pass__factory;
                const uri = await this.healper.upload(creator, "pass", CliUx.ux.prompt);
                try {
                    console.log("sending tx to update URI...");
                    contract = (await factory.attach(pass_address)) as Pass;
                    const receipt = await contract.setURI(
                        uri,
                        await this.healper.getMaticFeeData()
                    );
                    //await ethers.provider.waitForTransaction(receipt.hash);
                    await ethers.provider.waitForTransaction(receipt.hash, 5);
                    console.log("receipt received");
                } catch (e) {
                    console.log("tx failed!!!");
                    console.log(e);
                    process.exit(1);
                }
                const { levelsInfo, levels } = await this.createSeason(creator);

                try {
                    console.log("sending tx to create Season...");
                    const receipt = await contract.newSeason(
                        levels,
                        levelsInfo,
                        await this.healper.getMaticFeeData()
                    );
                    //await ethers.provider.waitForTransaction(receipt.hash);
                    await ethers.provider.waitForTransaction(receipt.hash, 5);
                    console.log("receipt received");
                } catch (e) {
                    console.log("tx failed!!!");
                    console.log(e);
                    process.exit(1);
                }
                break;
            case ACT.Lootbox:
                break;
            case ACT.Recipe:
                break;
        }
        console.log("Action successful");
    }

    async createReward(creator: string) {
        let reward: ERC1155RewardStruct;
        const queryCommand =
            "SELECT address, ctr_type, name FROM contract WHERE creator_id=$1 AND ctr_type!='Pass'";
        const query = await this.healper.queryDB(queryCommand, [creator]);
        for (const [index, row] of query.rows.entries()) {
            console.log(`${index + 1}: Reward of type ${row.ctr_type} and name ${row.name}`);
        }

        const selector = parseInt(await CliUx.ux.prompt("Select reward"));
        if (isNaN(selector) || selector < 0 || selector > query.rows.length) {
            this.log("Please enter a valid number");
            process.exit(1);
        }

        const reward_id = await CliUx.ux.prompt("What's the id");
        if (isNaN(reward_id) || reward_id < 0) {
            this.log("Please enter a valid number");
            process.exit(1);
        }

        const reward_qty = await CliUx.ux.prompt("What's the quantity");
        if (isNaN(reward_qty) || reward_qty < 0) {
            this.log("Please enter a valid number");
            process.exit(1);
        }
        reward = {
            token: query.rows[selector - 1].address,
            id: reward_id,
            qty: reward_qty,
        };
        return reward;
    }

    async createSeason(creator: string) {
        let levelsInfo: LevelInfoStruct[] = [];

        const levels = parseInt(await CliUx.ux.prompt("What's the number of levels"));
        if (isNaN(levels) || levels < 0) {
            this.log("Please enter a valid number");
            process.exit(1);
        }

        for (let lvl = 0; lvl <= levels; lvl++) {
            let freeReward: ERC1155RewardStruct;
            console.log(`Creating info for level ${lvl + 1}`);
            let xp: string;
            if (lvl != levels) {
                xp = await CliUx.ux.prompt("What's the needed xp");
                if (isNaN(levels) || levels < 0) {
                    this.log("Please enter a valid number");
                    process.exit(1);
                }
            } else {
                xp = "0";
            }

            console.log("Select free reward:");
            freeReward = await this.createReward(creator);
            const prem = await CliUx.ux.prompt("Do you want premium reward [y/n]");
            if (prem == "y") {
                console.log("Select free reward:");
                levelsInfo.push({
                    xpToCompleteLevel: xp,
                    freeReward: freeReward,
                    premiumReward: await this.createReward(creator),
                });
            } else if (prem == "n") {
                levelsInfo.push({
                    xpToCompleteLevel: xp,
                    freeReward: freeReward,
                    premiumReward: {
                        token: ethers.constants.AddressZero,
                        id: "0",
                        qty: "0",
                    },
                });
            } else {
                console.log("Invalid selection");
                process.exit(1);
            }
        }
        return { levelsInfo, levels };
    }
}
