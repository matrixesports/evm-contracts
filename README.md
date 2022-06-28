# EVM contracts used in the MTX ecosystem

## [![tests](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml) [![lints](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml)

## Getting started

---

1. `yarn all`
2. setup env variables based on `.sampleenv` file

## Things to be careful of

---

- Run out of balance:
  - oracle and admin wallet
  - chainlink subscription
- submodules:
  - solmate, forge-std works fine with forge update
  - need to keep an eye on oz, master branch is dev branch, works on release branches, current version installed is v4.6.0. https://github.com/foundry-rs/foundry/issues/401
  - same for chainlink, current version installed is v1.4.1
- erc20 token takes decimals into account, so to give nice whole numbers account for that

## Development

---

1. This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.
2. `main` branch is for production and changes are only merged if all tests + front end integration tests pass.
3. use feature branches for all other changes
4. refer to `pull_request_template` when opening a PR
5. adhere to `https://sparkbox.com/foundry/semantic_commit_messages`, keep it simple, short and optimally each commit does 1 thing.

## Common commands:

---

1. `forge build`: compile contracts
2. `forge test`: run tests, use `forge test -vvvvv` to get detailed stack traces
3. 'forge snapshot`: gas snapshot for your tests
4. `forge clean`, `forge install`, `forge update`
5. `make execute`: to execute `script/Dev.s.sol` as a script on matic
6. `yarn lint`: lint files

## Contracts

---

Glossary:
Bundle: Multiple ERC20/721/1155 tokens

**Pass**: Battle pass primitive as used in games like Clash Royale. Supports creation of multiple seasons, minting of premium passes, tracking user xp per season and rewarding lootboxes when level is completed.

**Recipe**: Allows creation of recipes. A recipe takes NFT's as input, burns them and gives you new NFT's.

**Utils**: Helper contract to handle deposit/withdraw of mtx deployed rewards.

**_rewards/_**  
**Lootbox**: Lootbox/Treasure Chest primitive as used for rewards in games. Can handle creation of multiple lootboxes per contract. One lootbox contains multiple bundles, each bundle has an attached probability. The rewarded bundle is chosen by checking what probability range a random number computed using Chainlink's VRF service falls under for the give lootbox. You can essentially reward a user multiple erc20/721/1155 tokens and furthermore enforce rarity.

**MERC20/721/1155**: Normal mintable tokens that can be added in a lootbox. Includes mint/burn functionality, conforms to opensea standards for metadata. Highly customizable to meet creator needs.

**Redeemable**: Used when a creator wants to issue rewards that involve manual fulfillment or intervention. For example: Get a follow back on twitter, instagram, merch, etc. Once rewarded, user _redeems_ a reward. We keep track of fulfillment status and provide the user a way to see all of their redeemed rewards to ensure transparency and accountability.

## Structure heavily inspired by:

---

- https://github.com/Rari-Capital/solmate
- https://github.com/abigger87/femplate
- https://github.com/foundry-rs/forge-template
