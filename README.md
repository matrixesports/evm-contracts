<div align="center">

# MATRIX EVM Contracts
</div>

<div align="center">

[![Tests](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml)[![Lints](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml)
</div>

## Getting started
 
### Instalation

```bash
yarn all
```
### Development

- Create `.env` file based on `.sampleenv`
- `main` branch is for production only. Changes are merged if all FE integrations and contracts tests pass.
- Use feature branches for all other changes.
- Refer to `pull_request_template` when opening a PR.
- This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.

## Contracts

Each creator gets their own `BattlePass`, `CreatorToken`, and `Pathfinder` contracts. Most functions use the `onlyOwner` modifier because we pay the gas fees for the users to make the UX seamless.

### BattlePass

- Each creator gets 1 `BattlePass` contract.
- Battle Pass is a system that rewards users for completing creator-specific quests during established periods known as `seasons`. Experience points or `xp` tracks user progression. The mechanism is similar to the one used in video games. 
- The contract is responsible for storing level information, tracking user progress, and minting rewards upon level completion. 
- There can be multiple seasons in 1 BattlePass
- The BattlePass can give minting/burning privileges by whitelisting contracts
- Rewards can be of the following types:
  - `PREMIUM_PASS`: A user who owns a premium pass can claim premium rewards
  - `CREATOR_TOKEN`: Creator-specific token associated with the BattlePass
  - `LOOTBOX`: Defined by a list of reward options. A user gets one of the reward options upon opening a lootbox; like a surprise box. 
  - `REDEEMABLE`: These require actions from the creators. When a user claims a redeemable reward, a ticket tracking the status of the reward is issued to the creator. The ticket is closed upon successful completion by the creator.
  - `SPECIAL`: Custom assets, such as one-of-one NFTs, in-game assets, etc.

### Crafting

- Allows users to `craft` new tokens based on a `recipe`.
- The recipe defines a list of input tokens, known as ingredients, and a list of output tokens. Crafting is then the act of burning the input tokens and minting the output tokens.
- Crafting uses ONLY items from Battle Pass contracts and must be whitelisted by all BattlePass for minting rights. 
- Deployed only once for the entire ecosystem:
  - `matic`:

### CreatorToken

- ERC20 token with delegation. The BattlePass contract mints this.

## MARPA (Matrix Advanced Research Projects Agency 😤)

- [TODO] 

### Pathfinder

- Clash of clans like game.
- Each creator community gets their own village with the goal of protecting their Castle in the middle of the village.
- They complete quests/challenges to get rewards that include game charecters like different kinds of Defenders.
- A player who wins a Defender, for ex a Bomber, then talks and coordinates with other members of the community to tactically place it on the map.
- Players can place/unplace their characters before the deadline. After the deadline the attack begins. Matrix places its attackers on the boundary, the game is started and all further actions happen autonomously. The attackers move on their own, the defenders protect themselves on their own. Progression happens by using a keeper service to execute the action and move functions every block.
- If the community wins then their creator gets rewarded.
- A Soul Bound Token representing win/lose is minted to the community after the game ends. Its supposed to act like a Badge of Honor or a Badge of Shame.
- The community can change the skins on their Defenders by passing governance proposals. We use a modified version of [DPD](https://intrago.xyz/) for it.
- In V2 we'll allow p2p fighting where different communities can attack each other.

## What can you do with the contracts?

- [TODO]

## Considerations

- submodules:
  - solmate, forge-std works fine with forge update
  - need to keep an eye on oz, master branch is dev branch, works on release branches, current version installed is v4.6.0. https://github.com/foundry-rs/foundry/issues/401
- erc20 token takes decimals into account, so to give nice whole numbers, account for that
- contracts should not allow bad inputs.if this is done properly then the ouput/queries by FE will not have to be checked.


## Acknowledgements

- Repo structure heavily inspired by [solmate](https://github.com/Rari-Capital/solmate), [femplate](https://github.com/abigger87/femplate), [foundry](https://github.com/foundry-rs/forge-template)
