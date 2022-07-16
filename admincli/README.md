## AdminCLI

CLI tool for deploying and interacting with the MTX contracts. You can specify the default network in the `hardhat.config.ts`. When the network is `localhost`, set the environment variable `ENV=dev`, otherwise set to `prod`. For network configuration see [hardhat](https://hardhat.org/hardhat-runner/docs/config). 

### Usage

```bash
./admincli/run <command>
```

### Commands

- **`init`** 
  - Initializes the directory structure for each creator.  
    creators/
    - <creator_id>/
        - pass/
            - images/
            - metadata/
            - README.md
              - `images CID`
              - `metadata CID`
- **`deploy`**
  - Battle Pass
  - Crafting
  - Creator Token
- **`onboard`** 
  - Deploys the `CreatorToken`, then the `BattlePass` and whitelists it.
- **`create`**
  - Season
  - Lootbox
  - Recipe 

### Onboard 

 ```bash
./admincli/run onboard
```
1. Give a unique number for the `creator_id`
2. Give `name` and `symbol` for the Creator Token (decimals=18)
3. Give the `name` for the contract database entry
4. Deploys Creator Token and inserts into database
5. Initializes new directory structure for the Battle Pass images and metadata
5. Copy the `images` and type **`y`** to proceed
6. Pins images to Pinata and saves the CID in the creator's README
7. Generates the metadata
    - Give `name` and `description`
8. Pins metadata to Pinata and saves the CID in the creator's README
9. Use default Crafting `address` or give one
10. Use default Game `address` or give one
11. Give the `name` for the contract database entry
12. Deploys Battle Pass and inserts into database
13. Give details for the battlepass database entry
14. Inserts into database
15. Sends tx to whitelist the Battle Pass

 ```bash
./admincli/run create
```
16. Select **`1`** to create a new Season
17. Give the `creator_id`
18. Give the number of `levels`
19. For each level give `xp` and `free_reward`
    - At each level you can add a `premium_reward`
    - Set `id` and `qty` to 0 for level with no rewards
    - `xp` at last level is auto set to 0
20. Sends tx to create the new Season