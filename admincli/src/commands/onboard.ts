import { Command, CliUx } from "@oclif/core";
import { ethers } from "hardhat";
import path from "path";
import fs from "fs";
import { BattlePass__factory, CreatorToken, CreatorToken__factory } from "../types";
import { Healper } from "../scripts/healper";

export default class Onboard extends Command {
    creator_id = "";
    healper = new Healper();
    crafting = "0x0000000000000000000000000000000000000000";
    game = "0x0000000000000000000000000000000000000000";
    creatorToken = "0x0000000000000000000000000000000000000000";
    pass = "0x0000000000000000000000000000000000000000";
    static description = "Onboarding: deploy CreatorToken and BattlePass, whitelists BattlePass and create season";
    // prod - 5; dev - 0
    blocksToWait = 0;
    
    public async run(): Promise<void> {
        if (process.env.ENV === "prod") { this.blocksToWait = 5; }
        this.creator_id = await CliUx.ux.prompt("What's the creator_id?");
        if (isNaN(Number(this.creator_id))) {
            this.log("Please enter a valid number!");
            process.exit(1);
        }
        await this.deployCreatorToken();
        await this.dirInit();
        await this.deployBattlePass();
    }

    async dirInit() {
        let root = path.join(process.env.CREATORS_DIR!, this.creator_id.toString());
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

    async deployCreatorToken() {
        const name = await CliUx.ux.prompt("What's the name?");
        const symbol = await CliUx.ux.prompt("What's the symbol?");
        const decimals = await CliUx.ux.prompt("How many decimals?");
        if (isNaN(Number(decimals))) {
            this.log("Please enter a valid number");
            process.exit(1);
        }

        this.log("deploying CreatorToken...");
        let factory = (await ethers.getContractFactory("CreatorToken")) as CreatorToken__factory;
        let contract = await factory.deploy(name, symbol, decimals, ethers.constants.AddressZero, await this.healper.getMaticFeeData());

        this.log("waiting...");
        await ethers.provider.waitForTransaction(contract.deployTransaction.hash, this.blocksToWait);
        if (process.env.ENV === "prod") {
            await this.healper.verify(contract.address, [name, symbol, decimals]);
        } 
        await this.addtodb(contract.address, this.healper.getABI("CreatorToken"), "CreatorToken");
        this.creatorToken = contract.address;
        console.log("CreatorToken deployed");
    }

    async deployBattlePass() {
        await CliUx.ux.prompt(`Please upload images to creator/${this.creator_id}/pass/images.[y]`);
        const uri = await this.healper.upload(this.creator_id, "pass", CliUx.ux.prompt);

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

        this.log("deploying Battle Pass...");
        let factory = (await ethers.getContractFactory("BattlePass")) as BattlePass__factory;
        let contract = await factory.deploy(uri, this.crafting, this.game, this.creatorToken, await this.healper.getMaticFeeData());

        this.log("waiting...");
        await ethers.provider.waitForTransaction(contract.deployTransaction.hash, this.blocksToWait); 
        if (process.env.ENV === "prod") {
            await this.healper.verify(contract.address, [uri, this.crafting, this.game, this.creatorToken]);
        }
    
        await this.addtodb(contract.address, this.healper.getABI("BattlePass"), "BattlePass");
        this.pass = contract.address;
        console.log("BattlePass deployed");
        await this.whitelist();
    }

    async addtodb(address: string, abi: string, ctr_type: string) {
        const dbname = await CliUx.ux.prompt("What's the name for the db entry?");
        const queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
        const queryArgs = [
            address,
            "matic",
            dbname,
            abi,
            this.creator_id,
            ctr_type,
        ];
        await this.healper.queryDB(queryCommand, queryArgs);
    }

    async whitelist() {
        this.log("sending tx to whitelist pass...");
        let factory = (await ethers.getContractFactory("CreatorToken")) as CreatorToken__factory;
        let contract = (await factory.attach(this.creatorToken)) as CreatorToken;
        try {
            const receipt = await contract.toggleWhitelist(this.pass, true, await this.healper.getMaticFeeData());
            await ethers.provider.waitForTransaction(receipt.hash, this.blocksToWait);
            console.log("receipt received");
        } catch (e) {
            console.log("tx failed!!!");
            console.log(e);
            process.exit(1);
        }
    }
}