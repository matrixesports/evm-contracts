// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/Crafting.sol";
import "../src/BattlePass.sol";
import "forge-std/Test.sol";

contract BattlePassTest is Test {
    Crafting crafting = new Crafting();
    BattlePass bp;

    address mockUser = address(1);
    uint256 seasonId;

    LevelInfo[] levelInfo;
    LootboxOption[] lootbox;

    event Delegated(
        address indexed delegator,
        address indexed delegatee,
        uint256 indexed amount
    );

    event Undelegated(
        address indexed delegator,
        address indexed delegatee,
        uint256 indexed amount
    );

    function setUp() public {
        bp = new BattlePass("", address(crafting));
        LevelInfo memory _levelInfo = LevelInfo(1, 0, 0, 0, 0);
        levelInfo.push(_levelInfo);
        _levelInfo = LevelInfo(1, 1, 10, 2, 10);
        levelInfo.push(_levelInfo);
        _levelInfo = LevelInfo(1, 1000, 10, 1001, 20);
        levelInfo.push(_levelInfo);
        _levelInfo = LevelInfo(1, 1002, 10, 1003, 10);
        levelInfo.push(_levelInfo);
        _levelInfo = LevelInfo(1, 10000, 10, 10001, 10);
        levelInfo.push(_levelInfo);
        _levelInfo = LevelInfo(1, 20000, 10, 20100, 20);
        levelInfo.push(_levelInfo);
        _levelInfo = LevelInfo(0, 0, 0, 29999, 20);
        levelInfo.push(_levelInfo);
        seasonId = bp.newSeason(levelInfo);
    }

    function testConstructor() public {
        assertEq(bp.tokenURI(), "");
        assertEq(bp.crafting(), address(crafting));
        assertEq(bp.PREMIUM_PASS_STARTING_ID(), 1);
        assertEq(bp.CREATOR_TOKEN_ID(), 1000);
        assertEq(bp.LOOTBOX_STARTING_ID(), 1001);
        assertEq(bp.REDEEMABLE_STARTING_ID(), 10000);
        assertEq(bp.SPECIAL_STARTING_ID(), 20000);
        assertEq(bp.INVALID_STARTING_ID(), 30000);
        assertEq(bp.lootboxId(), bp.LOOTBOX_STARTING_ID() - 1);
    }

    function unauthorized() public {
        vm.startPrank(mockUser);
        vm.expectRevert(abi.encodePacked("UNAUTHORIZED"));
    }

    function testRevertGiveXpNonOwner() public {
        unauthorized();
        bp.giveXp(seasonId, 1, mockUser);
    }

    function testGiveXp(uint256 xp) public {
        bp.giveXp(seasonId, xp, mockUser);
        (uint256 _xp,) = bp.userInfo(mockUser, 1);
        assertEq(_xp, xp);
    }

    function testRevertSetXpNonOwner() public {
        unauthorized();
        bp.setXp(seasonId, 1, 1);
    }

    function testSetXp(uint256 xp) public {
        bp.setXp(seasonId, 1, xp);
        (uint256 xpToCompleteLevel,,,,) = bp.seasonInfo(seasonId, 1);
        assertEq(xpToCompleteLevel, xp);
    }

    function testRevertNewSeasonLastLevelNonZeroXp() public {
        LevelInfo memory _levelInfo = LevelInfo(1, 0, 0, 29999, 20);
        levelInfo.push(_levelInfo);
        vm.expectRevert(IncorrectSeasonDetails.selector);
        bp.newSeason(levelInfo);
    }

    function testNewSeason() public {
        uint256 maxLevel = bp.getMaxLevel(seasonId);
        assertEq(maxLevel + 1, levelInfo.length);

        for (uint256 x; x <= maxLevel; x++) {
            (
                uint256 xpToCompleteLevel,
                uint256 freeRewardId,
                uint256 freeRewardQty,
                uint256 premiumRewardId,
                uint256 premiumRewardQty
            ) = bp.seasonInfo(seasonId, x);
            assertEq(xpToCompleteLevel, levelInfo[x].xpToCompleteLevel);
            assertEq(freeRewardId, levelInfo[x].freeRewardId);
            assertEq(freeRewardQty, levelInfo[x].freeRewardQty);
            assertEq(premiumRewardId, levelInfo[x].premiumRewardId);
            assertEq(premiumRewardQty, levelInfo[x].premiumRewardQty);
        }
        uint256 newSeasonId = bp.newSeason(levelInfo);
        assertEq(newSeasonId, seasonId + 1);
    }

    function testRevertAddRewardNonOwner() public {
        unauthorized();
        bp.addReward(seasonId, 1, false, 1, 1);
    }

    function testAddReward() public {
        bp.addReward(seasonId, 1, false, 1, 1);
        bp.addReward(seasonId, 1, true, 1, 1);
        (
            ,
            uint256 freeRewardId,
            uint256 freeRewardQty,
            uint256 premiumRewardId,
            uint256 premiumRewardQty
        ) = bp.seasonInfo(seasonId, 1);
        assertEq(freeRewardId, 1);
        assertEq(freeRewardQty, 1);
        assertEq(premiumRewardId, 1);
        assertEq(premiumRewardQty, 1);
    }

    function testRevertClaimRewardNotAtLevel() public {
        vm.startPrank(mockUser);
        vm.expectRevert(NotAtLevelNeededToClaimReward.selector);
        bp.claimReward(seasonId, 1, false);
    }

    function testRevertClaimRewardAlreadyClaimed() public {
        bp.giveXp(seasonId, 10, mockUser);
        vm.startPrank(mockUser);
        bp.claimReward(seasonId, 1, false);
        vm.expectRevert(RewardAlreadyClaimed.selector);
        bp.claimReward(seasonId, 1, false);
    }

    function testRevertClaimRewardNoPremium() public {
        bp.giveXp(seasonId, 10, mockUser);
        vm.startPrank(mockUser);
        vm.expectRevert(NeedPremiumPassToClaimPremiumReward.selector);
        bp.claimReward(seasonId, 1, true);
    }

    function testClaimReward() public {
        bp.giveXp(seasonId, 100, mockUser);
        vm.startPrank(mockUser);

        for (uint256 x; x < levelInfo.length; x++) {
            bp.claimReward(seasonId, x, false);
            assertEq(
                bp.balanceOf(mockUser, levelInfo[x].freeRewardId),
                levelInfo[x].freeRewardQty
            );
            assertTrue(bp.isRewardClaimed(mockUser, seasonId, x, false));
        }

        //already gave a premium pass in free reward
        //premium reward at level 0 is 0, claiming it shouldnt burn the premium pass
        assertTrue(bp.isUserPremium(mockUser, seasonId));
        uint256 oldPremiumPassBalance = bp.balanceOf(mockUser, seasonId);
        bp.claimReward(seasonId, 0, true);
        uint256 newPremiumPassBalance = bp.balanceOf(mockUser, seasonId);
        assertEq(oldPremiumPassBalance, newPremiumPassBalance);

        (, bool claimedPremiumPass) = bp.userInfo(mockUser, seasonId);
        assertFalse(claimedPremiumPass);

        //claiming first premium reward should burn it
        bp.claimReward(seasonId, 1, true);
        (, claimedPremiumPass) = bp.userInfo(mockUser, seasonId);
        assertTrue(claimedPremiumPass);
        assertEq(oldPremiumPassBalance - 1, bp.balanceOf(mockUser, seasonId));

        for (uint256 x = 2; x < levelInfo.length; x++) {
            bp.claimReward(seasonId, x, true);
            assertEq(
                bp.balanceOf(mockUser, levelInfo[x].premiumRewardId),
                levelInfo[x].premiumRewardQty
            );
            assertTrue(bp.isRewardClaimed(mockUser, seasonId, x, true));
        }
    }

    function testClaimRewardWithMetaTx() public {
        bp.giveXp(seasonId, 100, mockUser);

        for (uint256 x; x < levelInfo.length; x++) {
            (bool success,) = address(bp).call(
                abi.encodePacked(
                    abi.encodeWithSelector(bp.claimReward.selector, seasonId, x, false),
                    mockUser
                )
            );
            assertTrue(success);
            assertEq(
                bp.balanceOf(mockUser, levelInfo[x].freeRewardId),
                levelInfo[x].freeRewardQty
            );
            assertTrue(bp.isRewardClaimed(mockUser, seasonId, x, false));
        }

        //already gave a premium pass in free reward
        //premium reward at level 0 is 0, claiming it shouldnt burn the premium pass
        assertTrue(bp.isUserPremium(mockUser, seasonId));
        uint256 oldPremiumPassBalance = bp.balanceOf(mockUser, seasonId);
        (bool success,) = address(bp).call(
            abi.encodePacked(
                abi.encodeWithSelector(bp.claimReward.selector, seasonId, 0, true),
                mockUser
            )
        );
        assertTrue(success);
        uint256 newPremiumPassBalance = bp.balanceOf(mockUser, seasonId);
        assertEq(oldPremiumPassBalance, newPremiumPassBalance);

        (, bool claimedPremiumPass) = bp.userInfo(mockUser, seasonId);
        assertFalse(claimedPremiumPass);

        //claiming first premium reward should burn it
        (success,) = address(bp).call(
            abi.encodePacked(
                abi.encodeWithSelector(bp.claimReward.selector, seasonId, 1, true),
                mockUser
            )
        );
        assertTrue(success);
        (, claimedPremiumPass) = bp.userInfo(mockUser, seasonId);
        assertTrue(claimedPremiumPass);
        assertEq(oldPremiumPassBalance - 1, bp.balanceOf(mockUser, seasonId));

        for (uint256 x = 2; x < levelInfo.length; x++) {
            (success,) = address(bp).call(
                abi.encodePacked(
                    abi.encodeWithSelector(bp.claimReward.selector, seasonId, x, true),
                    mockUser
                )
            );
            assertTrue(success);
            assertEq(
                bp.balanceOf(mockUser, levelInfo[x].premiumRewardId),
                levelInfo[x].premiumRewardQty
            );
            assertTrue(bp.isRewardClaimed(mockUser, seasonId, x, true));
        }
    }

    function testIsUserPremium() public {
        assertFalse(bp.isUserPremium(mockUser, seasonId));
        bp.mint(mockUser, seasonId, 1);
        assertTrue(bp.isUserPremium(mockUser, seasonId));

        address anotherMockUser = address(2);
        bp.mint(anotherMockUser, seasonId, 1);
        bp.giveXp(seasonId, 10, mockUser);
        vm.prank(mockUser);
        bp.claimReward(seasonId, 1, true);
        assertEq(0, bp.balanceOf(mockUser, seasonId));
        assertTrue(bp.isUserPremium(mockUser, seasonId));
    }

    function testLevel() public {
        uint256 maxLevel = bp.getMaxLevel(seasonId);
        for (uint256 x; x < maxLevel; x++) {
            assertEq(bp.level(mockUser, seasonId), x);
            bp.giveXp(seasonId, levelInfo[x].xpToCompleteLevel - 1, mockUser);
            assertEq(bp.level(mockUser, seasonId), x);
            bp.giveXp(seasonId, 1, mockUser);
            assertEq(bp.level(mockUser, seasonId), x + 1);
        }
        assertEq(bp.level(mockUser, seasonId), maxLevel);
        bp.giveXp(seasonId, 100000000, mockUser);
        assertEq(bp.level(mockUser, seasonId), maxLevel);
    }

    function testGetMaxLevel() public {
        uint256 maxLevel = bp.getMaxLevel(seasonId);
        assertEq(maxLevel, levelInfo.length - 1);
    }

    function testIsRewardClaimed() public {
        bp.giveXp(seasonId, 100, mockUser);
        vm.startPrank(mockUser);
        assertFalse(bp.isRewardClaimed(mockUser, seasonId, 1, false));
        bp.claimReward(seasonId, 1, false);
        assertTrue(bp.isRewardClaimed(mockUser, seasonId, 1, false));
    }

    // reward contract tests:

    function testRevertMintNotAllowed(address dprk) public {
        vm.assume(dprk != address(this));
        vm.assume(dprk != address(crafting));
        vm.startPrank(dprk);
        vm.expectRevert(NoAccess.selector);
        bp.mint(mockUser, 1, 1);
    }

    function testRevertBurnNotAllowed(address dprk) public {
        vm.assume(dprk != address(this));
        vm.assume(dprk != address(crafting));
        vm.startPrank(dprk);
        vm.expectRevert(NoAccess.selector);
        bp.burn(mockUser, 1, 1);
    }

    function testMint() public {
        bp.mint(mockUser, 1, 1);
        vm.prank(address(crafting));
        bp.mint(mockUser, 1, 1);
        assertEq(bp.balanceOf(mockUser, 1), 2);
    }

    function testBurn() public {
        bp.mint(mockUser, 1, 2);
        bp.burn(mockUser, 1, 1);
        vm.prank(address(crafting));
        bp.burn(mockUser, 1, 1);
        assertEq(bp.balanceOf(mockUser, 1), 0);
    }

    function testRevertSetURI() public {
        unauthorized();
        bp.setURI("yes");
    }

    function testURI() public {
        bp.setURI("yes");
        assertEq("yes", bp.tokenURI());
    }

    function testRevertNewLootboxNonOwner() public {
        unauthorized();
        bp.newLootbox(lootbox);
    }

    function testRevertNewLootboxIncorrectOptions() public {
        //empty
        vm.expectRevert(IncorrectLootboxOptions.selector);
        bp.newLootbox(lootbox);

        //id, qty mismatch
        LootboxOption memory option;
        lootbox.push(option);
        lootbox[0].ids.push(1);
        vm.expectRevert(IncorrectLootboxOptions.selector);
        bp.newLootbox(lootbox);

        //prob doesnt add upto 100
        lootbox[0].qtys.push(1);
        vm.expectRevert(IncorrectLootboxOptions.selector);
        bp.newLootbox(lootbox);
    }

    function createLootbox() public returns (uint256) {
        LootboxOption memory option;
        lootbox.push(option);
        lootbox.push(option);

        lootbox[0].rarityRange[1] = 50;
        lootbox[0].ids.push(1);
        lootbox[0].ids.push(2);
        lootbox[0].qtys.push(10);
        lootbox[0].qtys.push(10);

        lootbox[1].rarityRange[0] = 50;
        lootbox[1].rarityRange[1] = 100;
        lootbox[1].ids.push(2);
        lootbox[1].ids.push(3);
        lootbox[1].qtys.push(10);
        lootbox[1].qtys.push(10);
        return bp.newLootbox(lootbox);
    }

    function testNewLootbox() public {
        uint256 oldLootboxId = bp.lootboxId();
        uint256 lootboxId = createLootbox();
        assertEq(oldLootboxId + 1, lootboxId);

        for (uint256 x; x < lootbox.length; x++) {
            LootboxOption memory storedOption =
                bp.getLootboxOptionByIdx(lootboxId, x);
            assertEq(storedOption.rarityRange[0], lootbox[x].rarityRange[0]);
            assertEq(storedOption.rarityRange[1], lootbox[x].rarityRange[1]);
            for (uint256 y; y < lootbox[x].ids.length; y++) {
                assertEq(storedOption.ids[y], lootbox[x].ids[y]);
                assertEq(storedOption.qtys[y], lootbox[x].qtys[y]);
            }
        }
    }

    function testOpenLootboxNotOwned() public {
        vm.expectRevert(stdError.arithmeticError);
        bp.openLootbox(1);
    }

    function testOpenLootbox() public {
        uint256 lootboxId = createLootbox();
        bp.mint(mockUser, lootboxId, 1);
        vm.startPrank(mockUser);
        uint256 idxOpened = bp.openLootbox(lootboxId);
        for (uint256 y; y < lootbox[idxOpened].ids.length; y++) {
            assertEq(
                bp.balanceOf(mockUser, lootbox[idxOpened].ids[y]),
                lootbox[idxOpened].qtys[y]
            );
        }
        assertEq(bp.balanceOf(mockUser, lootboxId), 0);
    }

    function testOpenLootboxMetaTx() public {
        uint256 lootboxId = createLootbox();
        bp.mint(mockUser, lootboxId, 1);
        (bool success, bytes memory data) = address(bp).call(
            abi.encodePacked(
                abi.encodeWithSelector(bp.openLootbox.selector, lootboxId), mockUser
            )
        );
        assertTrue(success);
        uint256 idxOpened = uint256(bytes32(data));
        for (uint256 y; y < lootbox[idxOpened].ids.length; y++) {
            assertEq(
                bp.balanceOf(mockUser, lootbox[idxOpened].ids[y]),
                lootbox[idxOpened].qtys[y]
            );
        }
        assertEq(bp.balanceOf(mockUser, lootboxId), 0);
    }

    function testGetLootboxOptionsLength() public {
        uint256 lootboxId = createLootbox();
        assertEq(bp.getLootboxOptionsLength(lootboxId), lootbox.length);
    }

    function testRevertDelegate(uint256 amount, uint256 delegateAmount)
        public
    {
        vm.assume(amount < delegateAmount);
        bp.mint(mockUser, bp.CREATOR_TOKEN_ID(), amount);
        vm.startPrank(mockUser);
        vm.expectRevert(stdError.arithmeticError);
        bp.delegate(address(100), delegateAmount);
    }

    function testDelegate(uint256 amount, uint256 delegateAmount) public {
        uint256 id = bp.CREATOR_TOKEN_ID();
        address delegatee = address(100);
        vm.assume(amount >= delegateAmount);
        bp.mint(mockUser, id, amount);
        vm.startPrank(mockUser);
        vm.expectEmit(true, true, true, true);
        emit Delegated(mockUser, delegatee, delegateAmount);
        bp.delegate(delegatee, delegateAmount);
        assertEq(amount - delegateAmount, bp.balanceOf(mockUser, id));
        assertEq(bp.delegatedBy(mockUser, delegatee), delegateAmount);
        assertEq(bp.delegatedTotal(delegatee), delegateAmount);
    }

    function testDelegateMetaTx(uint256 amount, uint256 delegateAmount)
        public
    {
        uint256 id = bp.CREATOR_TOKEN_ID();
        address delegatee = address(100);
        vm.assume(amount >= delegateAmount);
        bp.mint(mockUser, id, amount);

        vm.expectEmit(true, true, true, true);
        emit Delegated(mockUser, delegatee, delegateAmount);
        (bool success,) = address(bp).call(
            abi.encodePacked(
                abi.encodeWithSelector(bp.delegate.selector, delegatee, delegateAmount),
                mockUser
            )
        );
        assertTrue(success);
        assertEq(amount - delegateAmount, bp.balanceOf(mockUser, id));
        assertEq(bp.delegatedBy(mockUser, delegatee), delegateAmount);
        assertEq(bp.delegatedTotal(delegatee), delegateAmount);
    }

    function testRevertUndelegateUnderflow(uint256 undelegateAmount) public {
        vm.assume(undelegateAmount > 0);
        bp.mint(mockUser, bp.CREATOR_TOKEN_ID(), undelegateAmount);
        vm.startPrank(mockUser);
        bp.delegate(address(100), undelegateAmount);
        vm.expectRevert(stdError.arithmeticError);
        bp.undelegate(address(100), undelegateAmount + 1);
    }

    function testUndelegate(
        uint256 amount,
        uint256 delegate,
        uint256 undelegate
    )
        public
    {
        vm.assume(amount > 0);
        vm.assume(amount > delegate);
        vm.assume(delegate > undelegate);

        uint256 id = bp.CREATOR_TOKEN_ID();
        address delegatee = address(100);
        bp.mint(mockUser, id, amount);
        vm.startPrank(mockUser);

        bp.delegate(delegatee, delegate);
        vm.expectEmit(true, true, true, true);
        emit Undelegated(mockUser, delegatee, undelegate);
        bp.undelegate(delegatee, undelegate);

        assertEq(amount - delegate + undelegate, bp.balanceOf(mockUser, id));
        assertEq(bp.delegatedBy(mockUser, delegatee), delegate - undelegate);
        assertEq(bp.delegatedTotal(delegatee), delegate - undelegate);
    }

    function testUndelegateMetaTx(
        uint256 amount,
        uint256 delegate,
        uint256 undelegate
    )
        public
    {
        vm.assume(amount > 0);
        vm.assume(amount > delegate);
        vm.assume(delegate > undelegate);

        uint256 id = bp.CREATOR_TOKEN_ID();
        address delegatee = address(100);
        bp.mint(mockUser, id, amount);

        (bool success,) = address(bp).call(
            abi.encodePacked(
                abi.encodeWithSelector(bp.delegate.selector, delegatee, delegate),
                mockUser
            )
        );
        assertTrue(success);
        vm.expectEmit(true, true, true, true);
        emit Undelegated(mockUser, delegatee, undelegate);
        (success,) = address(bp).call(
            abi.encodePacked(
                abi.encodeWithSelector(bp.undelegate.selector, delegatee, undelegate),
                mockUser
            )
        );
        assertTrue(success);

        assertEq(amount - delegate + undelegate, bp.balanceOf(mockUser, id));
        assertEq(bp.delegatedBy(mockUser, delegatee), delegate - undelegate);
        assertEq(bp.delegatedTotal(delegatee), delegate - undelegate);
    }

    function testUri() public {
        assertEq(bp.uri(1), "/1.json");
    }

    function testRevertCheckTypeOutOfBounds(uint256 id) public {
        vm.assume(id >= 30000);
        vm.expectRevert(abi.encodeWithSelector(InvalidId.selector, id));
        bp.checkType(id);
    }
}
