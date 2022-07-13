import { Command, CliUx } from "@oclif/core";
import path from "path";
import fs from "fs";

export default class Init extends Command {
    creator_id = "";
    dir = "";
    static description = "Initialize directory structure for contract's metadata and images.";

    public async run(): Promise<void> {
        const mode = await CliUx.ux.prompt(
            "Initialize directory\n1: New creator\n2: New contract\nSelect target"
        );
        if (isNaN(mode) || mode < 1 || mode > 2) {
            this.log("Please enter a valid number");
            process.exit(1);
        }
        this.creator_id = await CliUx.ux.prompt("What's the creator_id");
        if (isNaN(Number(this.creator_id))) {
            this.log("Please enter a valid number");
            process.exit(1);
        }
        if (mode == 1) {
            this.dir = "pass";
        } else if (mode == 2) {
            this.dir = await CliUx.ux.prompt("What's the name for the source directory");
        } else {
            console.log("Target not supported");
            process.exit(1);
        }
        let root = path.join(process.env.CREATORS_DIR!, this.creator_id);
        if (!fs.existsSync(root)) {
            fs.mkdirSync(root);
        }
        if (!fs.existsSync(path.join(root, this.dir))) {
            fs.mkdirSync(path.join(root, this.dir));
        }
        if (!fs.existsSync(path.join(root, this.dir, "metadata"))) {
            fs.mkdirSync(path.join(root, this.dir, "metadata"));
        }
        if (!fs.existsSync(path.join(root, this.dir, "images"))) {
            fs.mkdirSync(path.join(root, this.dir, "images"));
        }
        console.log("Directory is created successfully.");
        fs.writeFile(path.join(root, this.dir, "README.md"), "", function (err) {
            if (err) throw err;
            console.log("README.md is created successfully.");
        });
    }
}
