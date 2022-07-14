# EVM contracts used in the MTX ecosystem

## [![tests](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml) [![lints](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml)

## Contracts

Each creator that we onboard gets their own `BattlePass`, `CreatorToken` and `Pathfinder` contract. Most functions have `onlyOwner` modifier since we'll be paying gas fees for the user and want to make the ux seamless.

### Crafting

---

- Allows a user to burn owned tokens and get new tokens in return based on a 'recipe'. So it can be said that a user `crafts` items based on `recipes`.
- A recipe defines what tokens, ids and quantities will be burned and what new tokens will be minted in return.
- Has minting rights over every `BattlePass` contract.
- For now, we only allows for recipes to be based on our deployed contracts. All items are a part of a creator's Battle Pass contracts.
- Users earn rewards in the BattlePass and use those items to craft new items.
- Only one deployed for the entire ecosystem.
  - `matic`:

### BattlePass

---

- 1 contract per creator.
- Similar to the mechanism that tracks xp and gives rewards in games.
- Responsibilities: store info on each level, track user progress, mint rewards upon level completion, create multiple seasons.
- Gives the game and crafting contract minting/burning priveleges.
- Handles metadata for display and minting of the creator token since it may be a reward at a level.
- Rewards can be of the following types:
  - PREMIUM_PASS: Allows access to premium rewards if a user has a premium pass.
  - CREATOR_TOKEN: Tokens specific to the creator the BattlePass is associated with.
  - LOOTBOX: Like a surprise box. Gives one set of rewards out of many based on predefined probabilities.
  - REDEEMABLE: Rewards that require manual intervention by creators irl.
  - SPECIAL: One off NFT's, in-game assets, etc.

### CreatorToken

---

- ERC20 token with delegation. The BattlePass contract mints this.

### MARPA

---

- stands for Matrix Advanced Research Projects Agency😤

### Pathfinder

---

- Clash of clans like game.
- Each creator community gets their own village with the goal of protecting their Castle in the middle of the village.
- They complete quests/challenges to get rewards that include game charecters like different kinds of Defenders.
- A player who wins a Defender, for ex a Bomber, then talks and coordinates with other members of the community to tactically place it on the map.
- Players can place/unplace their characters before the deadline. After the deadline the attack begins. Matrix places its attackers on the boundary, the game is started and all further actions happen autonomously. The attackers move on their own, the defenders protect themselves on their own. Progression happens by using a keeper service to execute the action and move functions every block.
- If the community wins then their creator gets rewarded.
- A Soul Bound Token representing win/lose is minted to the community after the game ends. Its supposed to act like a Badge of Honor or a Badge of Shame.
- The community can change the skins on their Defenders by passing governance proposals. We use a modified version of [DPD](https://intrago.xyz/) for it.
- In V2 we'll allow p2p fighting where different communities can attack each other.

## Things that the contracts allow us to do:

[add]

## Getting started

---

1. `yarn all`
2. setup env variables based on `.sampleenv` file

## Things to be careful of

---

- submodules:
  - solmate, forge-std works fine with forge update
  - need to keep an eye on oz, master branch is dev branch, works on release branches, current version installed is v4.6.0. https://github.com/foundry-rs/foundry/issues/401
- erc20 token takes decimals into account, so to give nice whole numbers, account for that

## Development

---

1. This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.
2. `main` branch is for production and changes are only merged if all tests + front end integration tests pass.
3. use feature branches for all other changes
4. refer to `pull_request_template` when opening a PR

## Repo Structure heavily inspired by:

---

- https://github.com/Rari-Capital/solmate
- https://github.com/abigger87/femplate
- https://github.com/foundry-rs/forge-template

## AdminCLI

CLI tool for deploying and interacting with the MTX contracts. You can specify the default network in the `hardhat.config.ts`. When the network is `localhost`, set the envirotment variable `ENV=dev`, otherwise set to `prod`. For netowrk configuration see [hardhat](https://hardhat.org/hardhat-runner/docs/config). 

### Usage 
---

`./admincli/run <command>`

- init 
  - Initializes the directory structure for each creator.  
    creators/
    - <creator_id>/
        - pass/
            - images/
            - metadata/
            - README.md
              - `images CID`
              - `metadata CID`
- deploy
  - `Battle Pass`
  - `Crafting`
  - `CreatorToken`
- onboard 
  - Deploys the `CreatorToken`, then the `BattlePass` and whitelists it.
- create
  - Season
  - Lootbox
  - Recipe 


