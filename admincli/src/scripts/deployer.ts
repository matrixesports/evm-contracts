import { ethers } from "hardhat";
import { Healper } from "../scripts/healper";
import { BattlePass__factory, CreatorToken, CreatorToken__factory, Crafting__factory } from "../types";
export class Deployer {
    healper = new Healper();
    blocksToWait = 0;

    constructor() {
        if (process.env.ENV === "prod") { this.blocksToWait = 5; }
    }

    async deployBattlePass(creator_id: string, dbname: string, uri: string, crafting: string, game: string) {
        let queryCommand =
        "SELECT address FROM contract WHERE creator_id=$1 AND ctr_type='CreatorToken'";
        let res;
        let creatorToken;
        try {
            res = await this.healper.queryDB(queryCommand, [creator_id]);
            creatorToken = res.rows[0].address;
        } catch (e) {
            console.log("There's no CreatorToken contract deployed");
            process.exit(1);
        }

        let bp_factory = (await ethers.getContractFactory("BattlePass")) as BattlePass__factory;
        let bp_contract = await bp_factory.deploy(uri, crafting, game, creatorToken, await this.healper.getMaticFeeData());

        await ethers.provider.waitForTransaction(bp_contract.deployTransaction.hash, this.blocksToWait); 
        if (process.env.ENV === "prod") {
            await this.healper.verify(bp_contract.address, [uri, crafting, game, creatorToken]);
        }
    
        queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
        let queryArgs = [
            bp_contract.address,
            "matic",
            dbname,
            this.healper.getABI("BattlePass"),
            creator_id,
            "BattlePass",
        ];
        await this.healper.queryDB(queryCommand, queryArgs);

        let ct_factory = (await ethers.getContractFactory("CreatorToken")) as CreatorToken__factory;
        let ct_contract = (await ct_factory.attach(creatorToken)) as CreatorToken;

        try {
            const receipt = await ct_contract.toggleWhitelist(bp_contract.address, true, await this.healper.getMaticFeeData());
            await ethers.provider.waitForTransaction(receipt.hash, this.blocksToWait);
            console.log("receipt received");
        } catch (e) {
            console.log("tx failed!!!");
            console.log(e);
            process.exit(1);
        }

        return bp_contract.address
    }

    async deployCreatorToken(creator_id: string, dbname:string, name: string, symbol: string, decimals: string) {
        let factory = (await ethers.getContractFactory("CreatorToken")) as CreatorToken__factory;
        let contract = await factory.deploy(name, symbol, decimals, ethers.constants.AddressZero, await this.healper.getMaticFeeData());

        await ethers.provider.waitForTransaction(contract.deployTransaction.hash, this.blocksToWait);
        if (process.env.ENV === "prod") {
            await this.healper.verify(contract.address, [name, symbol, decimals, ethers.constants.AddressZero]);
        } 

        const queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
        const queryArgs = [
            contract.address,
            "matic",
            dbname,
            this.healper.getABI("CreatorToken"),
            creator_id,
            "CreatorToken",
        ];
        await this.healper.queryDB(queryCommand, queryArgs);
        return contract.address;
    }

    async deployCrafting(dbname: string) {
        let factory = (await ethers.getContractFactory("Crafting")) as Crafting__factory;
        let contract = await factory.deploy(await this.healper.getMaticFeeData());

        await ethers.provider.waitForTransaction(contract.deployTransaction.hash, this.blocksToWait); 
        if (process.env.ENV === "prod") {
            await this.healper.verify(contract.address, []);
        }
    
        const queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
        const queryArgs = [
            contract.address,
            "matic",
            dbname,
            this.healper.getABI("Crafting"),
            "0",
            "Crafting",
        ];
        await this.healper.queryDB(queryCommand, queryArgs);
        return contract.address
    }
}