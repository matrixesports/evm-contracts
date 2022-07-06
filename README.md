# EVM contracts used in the MTX ecosystem

## [![tests](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/tests.yml) [![lints](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml/badge.svg)](https://github.com/matrixesports/evm-contracts/actions/workflows/lints.yml)

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
