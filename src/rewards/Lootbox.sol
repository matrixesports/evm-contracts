// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MERC1155.sol";
import "../Utils.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

///@dev rarity ranges means that if one token bundle added has 0-1, means it has a 10% prob of giving out, 0-10, random number is from 0-9
//am able to copy a list of structs in a struct to storage. but am not able to add that thing to another list
struct LootboxBundle {
    uint256[2] rarityRange;
    ERC20Reward[] erc20s;
    ERC721Reward[] erc721s;
    ERC1155Reward[] erc1155s;
}

error HowDidYouGetHere(uint256 lootboxId, address user, uint256 randomWord);
error ProbabilityRangeIncorrect(address admin);

//for matic mainnetØ
contract Lootbox is VRFConsumerBaseV2, MERC1155, ReentrancyGuard, Utils {
    event NewLootbox(address indexed admin, uint256 indexed lootboxId);
    event LootboxOpened(address indexed user, uint256 indexed lootboxId, uint256 index);
    event RequestedRandomWords(address indexed user, uint256 indexed id, uint256 requestId);

    uint256 public lootboxId;
    mapping(uint256 => LootboxBundle[]) internal rewards;

    uint64 public subscriptionId;
    VRFCoordinatorV2Interface internal coordinator;

    //optimization: use bytes to encode both
    mapping(uint256 => address) public requestIdToUser;
    mapping(uint256 => uint256) public requestIdToLootboxId;
    mapping(uint256 => uint256) public requestIdToIndexOpened;

    uint16 public constant requestConfirmations = 3;
    uint32 public constant numWords = 1;
    uint32 public callbackGasLimit = 10_000_000;

    // address public constant vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    //200gwei hash
    // bytes32 public constant keyHash =
    //     0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;
    bytes32 public keyHash;

    ///@dev create and topup subscription from dashboard, adds as consumer
    ///@dev pass can mint it, recipe can do something w it too
    constructor(
        string memory uri,
        address pass,
        address recipe,
        uint64 subId,
        address vrfCoordinator,
        bytes32 _keyHash
    ) MERC1155(uri, pass, recipe) VRFConsumerBaseV2(vrfCoordinator) {
        subscriptionId = subId;
        keyHash = _keyHash;
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    function adjustCallBackGasLimit(uint32 newLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        callbackGasLimit = newLimit;
    }

    function newLootbox(LootboxBundle[] calldata bundles)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        lootboxId++;

        uint256 cumulativeProbability;
        for (uint256 x = 0; x < bundles.length; x++) {
            for (uint256 y; y < bundles[x].erc20s.length; y++) {
                deposit(bundles[x].erc20s[y].token);
            }
            for (uint256 y; y < bundles[x].erc721s.length; y++) {
                deposit(bundles[x].erc721s[y].token);
            }
            for (uint256 y; y < bundles[x].erc1155s.length; y++) {
                deposit(bundles[x].erc1155s[y].token);
            }
            cumulativeProbability += (bundles[x].rarityRange[1] - bundles[x].rarityRange[0]);
            rewards[lootboxId].push(bundles[x]);
        }

        //probabilities should add to 1
        if (cumulativeProbability != 10 || bundles[bundles.length - 1].rarityRange[1] != 10)
            revert ProbabilityRangeIncorrect(_msgSender());

        emit NewLootbox(_msgSender(), lootboxId);
        return lootboxId;
    }

    /*//////////////////////////////////////////////////////////////////////
                            OPEN A LOOTBOX
    //////////////////////////////////////////////////////////////////////*/

    function openLootbox(uint256 id, address user) public returns (uint256 requestId) {
        _burn(user, id, 1);
        requestId = requestRandomWords();
        requestIdToUser[requestId] = user;
        requestIdToLootboxId[requestId] = id;
        emit RequestedRandomWords(user, id, requestId);
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
        nonReentrant
    {
        uint256 id = requestIdToLootboxId[requestId];
        address user = requestIdToUser[requestId];
        uint256 bundleRewardIdx = calculateIndexFromRandom(id, randomWords[0], user);
        requestIdToIndexOpened[requestId] = bundleRewardIdx;
        LootboxBundle memory bundle = rewards[id][bundleRewardIdx];
        for (uint256 y; y < bundle.erc20s.length; y++) {
            withdrawERC20(bundle.erc20s[y], user);
        }
        for (uint256 y; y < bundle.erc721s.length; y++) {
            withdrawERC721(bundle.erc721s[y], user);
        }
        for (uint256 y; y < bundle.erc1155s.length; y++) {
            withdrawERC1155(bundle.erc1155s[y], user);
        }
        emit LootboxOpened(user, id, bundleRewardIdx);
    }

    function calculateIndexFromRandom(
        uint256 id,
        uint256 randomWord,
        address user
    ) public view returns (uint256) {
        //0-9
        uint256 rangeNumber = randomWord % 10;
        LootboxBundle[] memory bundles = rewards[id];

        for (uint256 x; x < bundles.length; x++) {
            if (
                rangeNumber >= bundles[x].rarityRange[0] && rangeNumber < bundles[x].rarityRange[1]
            ) {
                return x;
            }
        }
        revert HowDidYouGetHere(id, user, randomWord);
    }

    function getLootboxBundleSize(uint256 id) public view returns (uint256) {
        return rewards[id].length;
    }

    function getLootboxBundle(uint256 id, uint256 index)
        public
        view
        returns (LootboxBundle memory)
    {
        return rewards[id][index];
    }
}
