// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev all reward IDS that are given out in a battle pass
 * battle pass gives out the following rewards:
 * Premium passes: ids 1-999 reserved for issuing premium passes for new seasons.
 * seasons x needs to mint id x in order to give user a premium pass
 * Creator Token: NOT minted by the Battle Pass, it is minted by the creator token contract
 * however, a Battle Pass is allowed to give creator tokens as a reward.
 * So, the creator token whitelists the pass contract and when you want to give out the tokens
 * you specify id CREATOR_TOKEN_ID so that the contract knows that it has to call the token contract
 * Lootbox: ids 1001-9999 reserved for creating new lootboxes, a battle pass can give out new lootboxes as
 * a reward.
 * Redeemable: ids 10,000-19999 reserved for redeemable items. These are items that require manual intervention
 * by a creator
 * Special: ids 20000-29999 reserved for default items like nfts, game items, one off tokens, etc.
 * Currently defined special items:
 * - ids 20,100-20199 reserved for MTX game defender items
 * - ids 20,200-20299 reserved for MTX game attacker items
 * anything bove 30,000 is considered invalid to prevent mistakes
 */
uint256 constant PREMIUM_PASS_STARTING_ID = 1;
uint256 constant CREATOR_TOKEN_ID = 1_000;
uint256 constant LOOTBOX_STARTING_ID = 1_001;
uint256 constant REDEEMABLE_STARTING_ID = 10_000;
uint256 constant SPECIAL_STARTING_ID = 20_000;
uint256 constant INVALID_STARTING_ID = 30_000;

/// @dev special rewards
uint256 constant DEFENDER_STARTING_ID = 20_100;
uint256 constant CASTLE_ID = 20_100;
uint256 constant TURRET_ID = 20_101;
uint256 constant WALL_ID = 20_102;
uint256 constant GENERATOR_ID = 20_103;

uint256 constant ATTACKER_STARTING_ID = 20_200;
uint256 constant BOMBER_ID = 20_200;
uint256 constant RANGED_ID = 20_201;
uint256 constant MELEE_ID = 20_202;
uint256 constant EXPLOSIVE_ID = 20_203;
