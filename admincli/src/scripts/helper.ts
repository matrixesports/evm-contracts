import HardhatRuntimeEnvironment, { ethers } from "hardhat";
import { Pool } from "pg";
import axios, { AxiosRequestConfig, AxiosResponse } from "axios";
import FormData from "form-data";
import path from "path";
import fs from "fs";

let connectionString: string;
if (process.env.ENV == "dev") {
    connectionString = process.env.STAGING_RAILWAY_URL!;
} else {
    connectionString = process.env.RAILWAY_URL!;
}
const pool = new Pool({
    connectionString,
});

export class Helper {
    async verify(address: string, args: string[]) {
        console.log("verifying...");
        await HardhatRuntimeEnvironment.run("verify:verify", {
            address: address,
            constructorArguments: [...args],
        });
        console.log("verified...");
    }

    async upload(
        creator: string,
        dir: string,
        CliUx: (name: string, options?: any | undefined) => Promise<any>
    ) {
        console.log("Uploading images to ipfs");
        const imghash = await this.dirtoipfs(creator, path.join(creator, dir, "images"));
        await this.genMD(path.join(creator, dir), imghash, CliUx);
        console.log("Uploading metadata to ipfs");
        const uri = await this.dirtoipfs(creator, path.join(creator, dir, "metadata"));
        return uri;
    }

    async dirtoipfs(creator: string, dir: string) {
        const data = new FormData();
        let fulldir = path.join(process.env.CREATORS_DIR!, dir);
        const basedir = fulldir.split("/").slice(-1)[0];
        const parentdir = fulldir.split("/").slice(-2)[0];
        const { dirs, files } = this.fsrecurisve(fulldir);
        for (const file of files) {
            data.append(`file`, fs.createReadStream(file), {
                filepath: this.basePath(fulldir, file),
            });
        }

        let metadata = {
            name: creator + "-" + parentdir + "-" + basedir,
            keyvalues: { creator_id: creator },
        };
        data.append("pinataOptions", '{"cidVersion": 1}');
        data.append("pinataMetadata", JSON.stringify(metadata));
        let config: AxiosRequestConfig = {
            method: "post",
            url: "https://api.pinata.cloud/pinning/pinFileToIPFS",
            headers: {
                "Content-Type": `multipart/form-data; boundary=${data.getBoundary()}`,
                pinata_api_key: process.env.PINATA_API_KEY!,
                pinata_secret_api_key: process.env.PINATA_API_SECRET!,
                ...data.getHeaders(),
            },
            data: data,
        };
        const res: AxiosResponse = await axios(config);

        let readme = path.join(process.env.CREATORS_DIR!, dir, "/./../README.md");
        const payload = basedir + "   " + res.data.IpfsHash + "\n";
        fs.writeFileSync(readme, payload);
        fs.readFileSync(readme, "utf8");
        return res.data.IpfsHash;
    }

    async genMD(
        dir: string,
        ipfsHash: string,
        CliUx: (name: string, options?: any | undefined) => Promise<any>
    ) {
        const images = path.join(process.env.CREATORS_DIR!, dir, "images");
        const metadata = path.join(process.env.CREATORS_DIR!, dir, "metadata");

        let metapath;
        let counter = 1;
        const files = fs.readdirSync(images);
        for (const file of files) {
            console.log("Input metadata for " + dir + "/" + path.basename(file).toString());
            let payload = {
                name: await CliUx("What's the name"),
                description: await await CliUx("What's the description"),
                image: "ipfs://" + ipfsHash + "/" + path.basename(file),
            };
            metapath = path.join(metadata, counter.toString() + ".json");
            fs.writeFileSync(metapath, JSON.stringify(payload));
            counter += 1;
        }
    }

    async queryDB(queryCommand: string, queryArgs: string[]) {
        let res;
        const client = await pool.connect();
        try {
            await client.query("BEGIN");
            res = await client.query(queryCommand, queryArgs);
            await client.query("COMMIT");
            return res;
        } catch (e) {
            await client.query("ROLLBACK");
            throw e;
        } finally {
            client.release();
        }
    }

    async getMaticFeeData() {
        try {
            const { data } = await axios({
                method: "get",
                url: "https://gasstation-mainnet.matic.network/v2",
            });
            let maxFeePerGas = ethers.utils.parseUnits(Math.ceil(data.fast.maxFee) + "", "gwei");
            let maxPriorityFeePerGas = ethers.utils.parseUnits(
                Math.ceil(data.fast.maxPriorityFee) + "",
                "gwei"
            );

            return {
                maxPriorityFeePerGas,
                maxFeePerGas,
            };
        } catch (e) {
            console.log(e);
            return {
                maxPriorityFeePerGas: ethers.utils.parseUnits(Math.ceil(40) + "", "gwei"),
            };
        }
    }

    getABI(name: string) {
        let compiled = require(process.cwd() + `/out/${name}.sol/${name}.json`);
        return JSON.stringify(compiled.abi);
    }

    basePath(sourcePath: string, filePath: string) {
        let newString = sourcePath.startsWith("./") ? sourcePath.substring(2) : sourcePath;
        //make sure there isn't a dangling / to throw a false positive into the mix
        const lastIndexOfDirectory = newString.lastIndexOf("/");
        if (lastIndexOfDirectory === -1) {
            return filePath;
        }
        const lengthOfSource = sourcePath.length;
        //only trim if the / is the last character in the string
        if (lastIndexOfDirectory === lengthOfSource - 1) {
            newString = sourcePath.slice(0, -1);
        }

        //now that we're sure of no false positive, let's check and see where the "root" directory is
        const newLastIndex = newString.lastIndexOf("/");
        if (newLastIndex === -1) {
            return newString;
        } else {
            const pathGarbage = newString.substring(0, newLastIndex + 1);
            newString = filePath.split(pathGarbage)[1];
        }

        return newString;
    }

    fsrecurisve(dpath: string) {
        let dirs: string[] = [];
        let files: string[] = [];
        dirs.push(dpath);
        return (function walk(_dirs): any {
            if (!_dirs.length) return { dirs, files };

            let complete = 0;
            let __dirs = [];

            for (let dir of _dirs) {
                let _files = fs.readdirSync(dir, { withFileTypes: true });

                for (let entry of _files) {
                    let fpath = `${dir}/${entry.name}`;
                    if (entry.isDirectory()) {
                        __dirs.push(fpath);
                        dirs.push(fpath);
                    } else {
                        files.push(fpath);
                    }
                }

                if (++complete === _dirs.length) {
                    return walk(__dirs);
                }
            }
        })([dpath]);
    }
}
