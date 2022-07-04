import { Command, Flags, CliUx } from "@oclif/core";
import { Helper } from "../scripts/helper";
import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";
import {
    Pass__factory,
    Lootbox__factory,
    MERC1155__factory,
    MERC20__factory,
    MERC721__factory,
    Recipe__factory,
    Redeemable__factory,
} from "../types";

export default class Deploy extends Command {
    contracts = new Map<number, string>([
        [1, "Pass"],
        [2, "Recipe"],
        [3, "Lootbox"],
        [4, "Redeemable"],
        [5, "ERC20"],
        [6, "ERC721"],
        [7, "ERC1155"],
    ]);
    name = "";
    symbol = "";
    decimals = "";
    pass = "";
    recipe = "";
    uri = "";
    target = "";
    subid = "";
    vrfc = "";
    keyhash = "";

    static description = "Deploy contract and upload metadata";
    static examples = ["deploy -i"];
    static flags = {
        interactive: Flags.boolean({ char: "i", description: "interactive mode" }),
    };

    public async run(): Promise<void> {
        const { flags } = await this.parse(Deploy);

        console.log(typeof ContractFactory);
        if (flags.interactive) {
            this.interactive();
        } else {
            console.log("Only interactive mode, use -i");
            process.exit(1);
        }
    }

    async interactive() {
        let healper = new Helper();

        const selector = parseInt(
            await CliUx.ux.prompt(
                "Available contract types:\n1: Pass\n2: Recipe\n3: Lootbox\n4: Redeemable\n5: ERC20\n6: ERC721\n7: ERC1155\nSelect type"
            )
        );
        if (isNaN(selector) || selector < 1 || selector > this.contracts.size) {
            this.log("Please enter a valid number");
            process.exit(1);
        }
        const ctr_type = this.contracts.get(selector)!;

        const creator = await CliUx.ux.prompt("What's the creator_id");
        if (isNaN(creator)) {
            this.log("Please enter a valid number");
            process.exit(1);
        }

        if (["ERC20", "ERC721"].includes(ctr_type)) {
            this.name = await CliUx.ux.prompt("What's the name?");
        }
        if (["ERC20", "ERC721"].includes(ctr_type)) {
            this.symbol = await CliUx.ux.prompt("What's the symbol?");
        }
        if (["ERC20", "ERC721", "ERC1155", "Lootbox", "Redeemable"].includes(ctr_type)) {
            const queryCommand =
                "SELECT address FROM contract WHERE creator_id=$1 AND ctr_type='Pass'";
            try {
                let res = await healper.queryDB(queryCommand, [creator]);
                this.pass = res.rows[0].address;
            } catch (e) {
                console.log("There's no pass contract deployed");
                process.exit(1);
            }
        }
        if (!(ctr_type === "Recipe")) {
            this.recipe = await CliUx.ux.prompt("Give MINTER_ROLE to Recipe address");
            if (!ethers.utils.isAddress(this.recipe)) {
                this.log("Please enter a valid ETH address");
                process.exit(1);
            }
        }
        if (ctr_type === "ERC20") {
            this.decimals = await CliUx.ux.prompt("How many decimals?");
            if (isNaN(Number(this.decimals))) {
                this.log("Please enter a valid number");
                process.exit(1);
            }
        } else {
            if (ctr_type === "Pass") {
                this.uri = "";
            } else {
                let dir = await CliUx.ux.prompt("What's the name of the source directory");
                this.uri = await healper.upload(creator, dir, CliUx.ux.prompt);
            }
        }

        console.log("deploying...");
        let contract: Contract;
        let args: string[];
        let factory;
        switch (ctr_type) {
            case "Pass":
                factory = (await ethers.getContractFactory(ctr_type)) as Pass__factory;
                contract = await factory.deploy("", this.recipe, await healper.getMaticFeeData());
                args = ["", this.recipe];
                break;
            case "Recipe":
                factory = (await ethers.getContractFactory(ctr_type)) as Recipe__factory;
                contract = await factory.deploy(this.uri, await healper.getMaticFeeData());
                args = [this.uri];
                break;
            case "Lootbox":
                this.parseVRFC();
                factory = (await ethers.getContractFactory(ctr_type)) as Lootbox__factory;
                contract = await factory.deploy(
                    this.uri,
                    this.pass,
                    this.recipe,
                    this.subid,
                    this.vrfc,
                    this.keyhash,
                    await healper.getMaticFeeData()
                );
                args = [this.uri, this.pass, this.recipe, this.subid, this.vrfc, this.keyhash];
                break;
            case "Redeemable":
                factory = (await ethers.getContractFactory(ctr_type)) as Redeemable__factory;
                contract = await factory.deploy(
                    this.uri,
                    this.pass,
                    this.recipe,
                    await healper.getMaticFeeData()
                );
                args = [this.uri, this.pass, this.recipe];
                break;
            case "ERC20":
                factory = (await ethers.getContractFactory(ctr_type)) as MERC20__factory;
                contract = await factory.deploy(
                    this.name,
                    this.symbol,
                    this.decimals,
                    this.pass,
                    this.recipe,
                    await healper.getMaticFeeData()
                );
                args = [this.name, this.symbol, this.decimals, this.pass, this.recipe];
                break;
            case "ERC721":
                factory = (await ethers.getContractFactory(ctr_type)) as MERC721__factory;
                contract = await factory.deploy(
                    this.name,
                    this.symbol,
                    this.uri,
                    this.pass,
                    this.recipe,
                    await healper.getMaticFeeData()
                );
                args = [this.name, this.symbol, this.uri, this.pass, this.recipe];
                break;
            case "ERC1155":
                factory = (await ethers.getContractFactory(ctr_type)) as MERC1155__factory;
                contract = await factory.deploy(
                    this.uri,
                    this.pass,
                    this.recipe,
                    await healper.getMaticFeeData()
                );
                args = [this.uri, this.pass, this.recipe];
                break;
        }

        console.log("waiting...");
        //await ethers.provider.waitForTransaction(contract!.deployTransaction.hash);
        await ethers.provider.waitForTransaction(contract!.deployTransaction.hash, 5);
        console.log(ctr_type + " deployed to:", contract!.address);
        await healper.verify(contract!.address, args!);
        const dbname = await CliUx.ux.prompt("What's the name for the db");
        const queryCommand = "INSERT INTO contract Values($1,$2,$3,$4,$5,$6)";
        const queryArgs = [
            contract!.address,
            "matic",
            dbname,
            creator,
            healper.getABI(ctr_type),
            ctr_type,
        ];
        console.log("quering db...");
        await healper.queryDB(queryCommand, queryArgs);
        console.log("done");
    }

    async parseVRFC() {
        let conf_mode = await CliUx.ux.prompt(
            "Configure Lootbox VRFCoordinator\n1: Use .env\n2: Manual\nSelect configuration mode"
        );
        if (isNaN(conf_mode)) {
            this.log("Please enter a valid number");
            process.exit(1);
        }
        if (conf_mode == 1) {
            if (!ethers.utils.isAddress(process.env.VRF_COORDINATOR!)) {
                this.log("Please enter a valid VRF_COORDINATOR address in .env");
                process.exit(1);
            }
            this.subid = process.env.SUB_ID!;
            this.vrfc = process.env.VRF_COORDINATOR!;
            this.keyhash = process.env.KEY_HASH!;
        } else if (conf_mode == 2) {
            this.subid = await CliUx.ux.prompt("What's the VRFCoordinator's sub_id");
            if (isNaN(Number(this.subid))) {
                this.log("Please enter a valid number");
                process.exit(1);
            }
            this.vrfc = await CliUx.ux.prompt("What's the VRFCoordinator's address");
            if (!ethers.utils.isAddress(this.recipe)) {
                this.log("Please enter a valid ETH address");
                process.exit(1);
            }
            this.keyhash = await CliUx.ux.prompt("What's the VRFCoordinator's keyhash");
        } else {
            console.log("Configuration mode not supported");
            process.exit(1);
        }
    }
}
