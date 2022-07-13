import { Command, CliUx } from "@oclif/core";
import { Healper } from "../scripts/healper";
import { ethers } from "hardhat";
import { BattlePass__factory, CreatorToken, CreatorToken__factory, Crafting__factory } from "../types";

export default class Deploy extends Command {
    static description = "Deploy EVM contracts";
    creator_id = "";
    healper = new Healper();
    crafting = "0x0000000000000000000000000000000000000000";
    game = "0x0000000000000000000000000000000000000000";
    creatorToken = "0x0000000000000000000000000000000000000000";
    pass = "0x0000000000000000000000000000000000000000";
    // prod - 5; dev - 0
    blocksToWait = 0;
    contracts = new Map<number, string>([
        [1, "BattlePass"],
        [2, "Crafting"],
        [3, "CreatorToken"],
    ]);

    public async run(): Promise<void> {
        if (process.env.ENV === "prod") { this.blocksToWait = 5; }

        const selector = parseInt(
            await CliUx.ux.prompt(
                "Available contract types:\n1: Battle Pass\n2: Crafting\n3: CreatorToken\nSelect type"
            )
        );
        if (isNaN(selector) || selector < 1 || selector > this.contracts.size) {
            this.log("Please enter a valid number");
            process.exit(1);
        }
        const ctr_type = this.contracts.get(selector)!;

        this.creator_id = await CliUx.ux.prompt("What's the creator_id?");
        if (isNaN(Number(this.creator_id))) {
            this.log("Please enter a valid number!");
            process.exit(1);
        }

        if (ctr_type === "BattlePass") {
            const queryCommand =
            "SELECT address FROM contract WHERE creator_id=$1 AND ctr_type='CreatorToken'";
            try {
            let res = await this.healper.queryDB(queryCommand, [this.creator_id]);
            this.creatorToken = res.rows[0].address;
            } catch (e) {
                this.log("There's no CreatorToken contract deployed");
            }
            await this.deployBattlePass();
        }
        if (ctr_type === "Crafting") {
            await this.deployCrafting();
        }
        if (ctr_type === "CreatorToken") {
            await this.deployCreatorToken();
        }
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

    async deployCrafting() {
        this.log("deploying Crafting...");
        let factory = (await ethers.getContractFactory("Crafting")) as Crafting__factory;
        let contract = await factory.deploy(await this.healper.getMaticFeeData());

        this.log("waiting...");
        await ethers.provider.waitForTransaction(contract.deployTransaction.hash, this.blocksToWait); 
        if (process.env.ENV === "prod") {
            await this.healper.verify(contract.address, []);
        }
    
        await this.addtodb(contract.address, this.healper.getABI("Crafting"), "Crafting");
        this.pass = contract.address;
        console.log("Crafting deployed");
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
