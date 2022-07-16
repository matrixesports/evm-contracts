import { Command, CliUx } from "@oclif/core";
import { Helper } from "../scripts/helper";
import { Deployer } from "../scripts/deployer";
import { ethers } from "hardhat";

export default class Deploy extends Command {
    static description = "Deploy EVM contracts";
    helper = new Helper();
    deployer = new Deployer();
    crafting = "0x0000000000000000000000000000000000000000";
    game = "0x0000000000000000000000000000000000000000";
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
        const ctr_type = this.contracts.get(selector);

        const creator_id = await CliUx.ux.prompt("What's the creator_id?");
        if (isNaN(Number(creator_id))) {
            this.log("Please enter a valid number!");
            process.exit(1);
        }

        if (ctr_type === "BattlePass") {
            await CliUx.ux.prompt(`Please upload images to creator/${creator_id}/pass/images.[y]`);
            const uri = await this.helper.upload(creator_id, "pass", CliUx.ux.prompt);

            this.log("Default crafting address: " + this.crafting);
            let answer = await CliUx.ux.prompt("Do you want to use default crafting address?[y/n]");
            if (answer === 'n') {
                this.crafting = await CliUx.ux.prompt("What's the address of the crafting contract?");
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
            const dbname = await CliUx.ux.prompt("What's the name for the db entry?");
            this.log("deploying...");
            const pass = await this.deployer.deployBattlePass(creator_id, dbname, uri, this.crafting, this.game);
            await this.helper.addToBP(pass, dbname, CliUx.ux.prompt);
        }
        if (ctr_type === "Crafting") {
            const dbname = await CliUx.ux.prompt("What's the name for the db entry?");
            this.log("deploying...");
            await this.deployer.deployCrafting(dbname);
        }
        if (ctr_type === "CreatorToken") {
            const name = await CliUx.ux.prompt("What's the name?");
            const symbol = await CliUx.ux.prompt("What's the symbol?");
            const dbname = await CliUx.ux.prompt("What's the name for the db entry?");
            this.log("deploying...");
            await this.deployer.deployCreatorToken(creator_id, dbname, name, symbol, "18");
        }
        this.log("succesfull!");
    }
}
