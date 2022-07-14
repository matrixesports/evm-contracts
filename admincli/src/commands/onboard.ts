import { Command, CliUx } from "@oclif/core";
import { ethers } from "hardhat";
import { Healper } from "../scripts/healper";
import { Deployer } from "../scripts/deployer";
import path from "path";
import fs from "fs";

export default class Onboard extends Command {
    static description = "Onboarding: deploy CreatorToken and BattlePass, whitelists BattlePass and create season";
    healper = new Healper();
    deployer = new Deployer();
    crafting = "0x0000000000000000000000000000000000000000";
    game = "0x0000000000000000000000000000000000000000";    
    // prod - 5; dev - 0
    blocksToWait = 0;

    public async run(): Promise<void> {
        if (process.env.ENV === "prod") { this.blocksToWait = 5; }
        const creator_id = await CliUx.ux.prompt("What's the creator_id?");
        if (isNaN(Number(creator_id))) {
            this.log("Please enter a valid number!");
            process.exit(1);
        }

        const name = await CliUx.ux.prompt("What's the name?");
        const symbol = await CliUx.ux.prompt("What's the symbol?");
        let dbname = await CliUx.ux.prompt("What's the name for the db entry?");
        this.log("deploying...");
        await this.deployer.deployCreatorToken(creator_id, dbname, name, symbol, "18");

        await this.dirInit(creator_id);

        await CliUx.ux.prompt(`Please upload images to creator/${creator_id}/pass/images.[y]`);
        const uri = await this.healper.upload(creator_id, "pass", CliUx.ux.prompt);

        this.log("Default crafting address: " + this.crafting);
        let answer = await CliUx.ux.prompt("Do you want to use default crafting address?[y/n]");
        if (answer === 'n') {
            this.crafting = await CliUx.ux.prompt("What's the address of the game contract?");
            if (!ethers.utils.isAddress(this.crafting)) {
                this.log("Please enter a valid ETH address");
                process.exit(1);
            }
        }

        this.log("Default game address: " + this.game);
        answer = await CliUx.ux.prompt("Do you want to use default game address?[y/n]");
        if (answer === 'n') {
            this.game = await CliUx.ux.prompt("What's the address of the game contract?");
            if (!ethers.utils.isAddress(this.game)) {
                this.log("Please enter a valid ETH address");
                process.exit(1);
            }
        }
        dbname = await CliUx.ux.prompt("What's the name for the db entry?");
        this.log("deploying...");
        await this.deployer.deployBattlePass(creator_id, dbname, uri, this.crafting, this.game);

        this.log("succesfull!");
    }

    async dirInit(creator_id: string) {
        let root = path.join(process.env.CREATORS_DIR!, creator_id.toString());
        if (!fs.existsSync(root)) {
            fs.mkdirSync(root);
        }
        if (!fs.existsSync(path.join(root, "pass"))) {
            fs.mkdirSync(path.join(root, "pass"));
        }
        if (!fs.existsSync(path.join(root, "pass", "metadata"))) {
            fs.mkdirSync(path.join(root, "pass", "metadata"));
        }
        if (!fs.existsSync(path.join(root, "pass", "images"))) {
            fs.mkdirSync(path.join(root, "pass", "images"));
        }
        
        fs.writeFile(path.join(root, "pass", "README.md"), "", function (err) {
            if (err) throw err;
        });
        this.log("Directory and READ.md are created successfully.");
    }
}