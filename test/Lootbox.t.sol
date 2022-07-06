// //SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0;

// import "./Helper.sol";
// import "../src/rewards/Lootbox.sol";
// import "./mocks/LinkToken.sol";
// import "./mocks/MockVRFCoordinatorV2.sol";

// //based on https://github.com/smartcontractkit/foundry-starter-kit/blob/main/src/VRFConsumerV2.sol
// contract LootboxTest is Helper {
//     uint256 public constant bundleCount = 5;
//     uint256 public constant tokenCount = 5;

//     Lootbox public lootbox;
//     uint256 public lootboxId;
//     LootboxBundle[bundleCount] bundles;

//     LinkToken public linkToken;
//     MockVRFCoordinatorV2 public vrfCoordinator;
//     uint96 constant FUND_AMOUNT = 1 * 10**18;
//     uint64 subId;
//     bytes32 keyHash;

//     event NewLootbox(address indexed admin, uint256 indexed lootboxId);
//     event LootboxOpened(address indexed user, uint256 indexed lootboxId, uint256 index);
//     event RequestedRandomWords(address indexed user, uint256 indexed id, uint256 requestId);

//     function setUp() public {
//         linkToken = new LinkToken();
//         vrfCoordinator = new MockVRFCoordinatorV2();
//         subId = vrfCoordinator.createSubscription();
//         vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);
//         lootbox = new Lootbox(uri, mockPass, mockRecipe, subId, address(vrfCoordinator), keyHash);
//         vrfCoordinator.addConsumer(subId, address(lootbox));

//         lootboxId = lootbox.newLootbox(createLootboxBundles());
//     }

//     function createLootboxBundles() private returns (LootboxBundle[] memory _bundles) {
//         _bundles = new LootboxBundle[](bundleCount);
//         uint256 rarityScore;
//         //5 bundles, 20% of getting each; 0-2;2-4;4-6;6-8;8-10; upper bound is not included
//         for (uint256 x; x < bundleCount; x++) {
//             bundles[x].rarityRange[0] = rarityScore;
//             rarityScore += 2;
//             bundles[x].rarityRange[1] = rarityScore;

//             for (uint256 y; y < tokenCount; y++) {
//                 bundles[x].erc20s.push(newERC20Reward(address(lootbox), mockRecipe, y + 10));
//                 bundles[x].erc721s.push(newERC721Reward(address(lootbox), mockRecipe));
//                 bundles[x].erc1155s.push(
//                     newERC1155Reward(address(lootbox), mockRecipe, y + 1, y + 10)
//                 );
//             }
//             _bundles[x] = bundles[x];
//         }
//     }

//     function testConstructor() public {
//         assertEq(lootbox.subscriptionId(), subId);
//         assertEq(lootbox.keyHash(), keyHash);
//         assertEq(lootbox.hasRole(lootbox.DEFAULT_ADMIN_ROLE(), address(this)), true);
//         assertEq(lootbox.hasRole(MINTER_ROLE, address(this)), true);
//         assertEq(lootbox.hasRole(MINTER_ROLE, mockPass), true);
//         assertEq(lootbox.hasRole(MINTER_ROLE, mockRecipe), true);
//     }

//     function testNewLootbox() public {
//         LootboxBundle[] memory _bundles = createLootboxBundles();
//         vm.expectEmit(true, false, false, true);
//         emit NewLootbox(address(this), 2);
//         lootboxId = lootbox.newLootbox(_bundles);
//         for (uint256 x; x < bundleCount; x++) {
//             LootboxBundle memory bundleAdded = lootbox.getLootboxBundle(lootboxId, x);
//             for (uint256 y; y < tokenCount; y++) {
//                 assert20Reward(_bundles[x].erc20s[y], bundleAdded.erc20s[y]);
//                 assert721Reward(_bundles[x].erc721s[y], bundleAdded.erc721s[y]);
//                 assert1155Reward(_bundles[x].erc1155s[y], bundleAdded.erc1155s[y]);
//                 assertEq(_bundles[x].rarityRange[0], bundleAdded.rarityRange[0]);
//                 assertEq(_bundles[x].rarityRange[1], bundleAdded.rarityRange[1]);
//             }
//         }
//     }

//     function testCannotAddNewLootboxIncorrectProbability() public {
//         LootboxBundle[] memory _bundles = createLootboxBundles();
//         _bundles[bundleCount - 1].rarityRange[1] = 11;
//         vm.expectRevert(abi.encodeWithSelector(ProbabilityRangeIncorrect.selector, address(this)));
//         lootboxId = lootbox.newLootbox(_bundles);

//         _bundles[bundleCount - 1].rarityRange[0] = 7;
//         _bundles[bundleCount - 1].rarityRange[1] = 10;
//         vm.expectRevert(abi.encodeWithSelector(ProbabilityRangeIncorrect.selector, address(this)));
//         lootboxId = lootbox.newLootbox(_bundles);
//     }

//     function testOpenLootbox() public {
//         lootbox.mint(mockUser, lootboxId, 1, "");
//         vm.expectEmit(true, true, false, true);
//         emit RequestedRandomWords(mockUser, lootboxId, 1);
//         uint256 requestId = lootbox.openLootbox(lootboxId, mockUser);

//         assertEq(lootbox.requestIdToUser(requestId), mockUser);
//         assertEq(lootbox.requestIdToLootboxId(requestId), lootboxId);
//         assertEq(MERC1155(address(lootbox)).balanceOf(mockUser, lootboxId), 0);

//         //simulate chainlink oracle
//         vrfCoordinator.fulfillRandomWords(requestId, address(lootbox));

//         uint256 bundleOpened = lootbox.requestIdToIndexOpened(requestId);
//         LootboxBundle memory bundle = lootbox.getLootboxBundle(lootboxId, bundleOpened);
//         for (uint256 y; y < bundle.erc20s.length; y++) {
//             assertEq(checkERC20Balance(bundle.erc20s[y], mockUser), bundle.erc20s[y].qty);
//         }
//         for (uint256 y; y < bundle.erc721s.length; y++) {
//             assertEq(checkERC721Balance(bundle.erc721s[y], mockUser), 1);
//         }
//         for (uint256 y; y < bundle.erc1155s.length; y++) {
//             assertEq(checkERC1155Balance(bundle.erc1155s[y], mockUser), bundle.erc1155s[y].qty);
//         }
//     }

//     function testCannotOpenLootboxNotOwned() public {
//         vm.expectRevert(stdError.arithmeticError);
//         lootbox.openLootbox(lootboxId, mockUser);
//     }
// }
