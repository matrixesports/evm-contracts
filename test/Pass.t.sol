// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Helper.sol";
import "../src/Pass.sol";

contract PassTest is Helper {
    uint256 public constant maxLevel = 5;
    address public defaultOracle = 0x744C907a37f4f595605E6FdE8cb5C3A022594D0a;

    Pass public pass;
    uint256 public seasonId;
    LevelInfo[] public levelInfo;

    event NewSeason(address indexed admin, uint256 seasonId);

    function setUp() public {
        pass = new Pass(uri, mockRecipe);
        for (uint256 x; x <= maxLevel; x++) {
            levelInfo.push(
                LevelInfo(
                    x + 10,
                    newERC1155Reward(address(pass), mockRecipe, x + 1, x + 10),
                    newERC1155Reward(address(pass), mockRecipe, x + 1, x + 10)
                )
            );
        }
        levelInfo[maxLevel].xpToCompleteLevel = 0;
        seasonId = pass.newSeason(maxLevel, levelInfo);
    }

    function testConstructor() public {
        assertEq(pass.hasRole(ORACLE_ROLE, pass.oracleAddress()), true);
        assertEq(defaultOracle, pass.oracleAddress());
        assertEq(pass.hasRole(pass.DEFAULT_ADMIN_ROLE(), address(this)), true);
        assertEq(pass.hasRole(MINTER_ROLE, address(this)), true);
        assertEq(pass.hasRole(MINTER_ROLE, address(pass)), true);
        assertEq(pass.hasRole(MINTER_ROLE, mockRecipe), true);
        assertEq(pass.tokenURI(), uri);
    }

    function testNewSeason() public {
        vm.expectEmit(true, false, false, true);
        emit NewSeason(address(this), 2);
        uint256 _seasonId = pass.newSeason(maxLevel, levelInfo);
        assertEq(pass.seasonId(), _seasonId);
        assertEq(pass.maxLevelInSeason(seasonId), maxLevel);
        for (uint256 x; x < maxLevel; x++) {
            (
                uint256 xpToCompleteLevel,
                ERC1155Reward memory freeReward,
                ERC1155Reward memory premiumReward
            ) = pass.seasonInfo(seasonId, x);
            assertEq(xpToCompleteLevel, levelInfo[x].xpToCompleteLevel);
            assert1155Reward(freeReward, levelInfo[x].freeReward);
            assert1155Reward(premiumReward, levelInfo[x].premiumReward);
        }
    }

    function testCannotCreateNewSeasonWithIncorrectDetails() public {
        vm.expectRevert(abi.encodeWithSelector(IncorrectSeasonDetails.selector, address(this)));
        pass.newSeason(0, levelInfo);

        vm.expectRevert(abi.encodeWithSelector(IncorrectSeasonDetails.selector, address(this)));
        pass.newSeason(maxLevel - 1, levelInfo);

        levelInfo[maxLevel].xpToCompleteLevel = 10;
        vm.expectRevert(abi.encodeWithSelector(IncorrectSeasonDetails.selector, address(this)));
        pass.newSeason(maxLevel, levelInfo);
    }

    function testCannotCreateNewSeasonWithoutAdmin() public {
        vm.expectRevert(revertAccessControl(mockUser, pass.DEFAULT_ADMIN_ROLE()));
        vm.prank(mockUser);
        pass.newSeason(maxLevel, levelInfo);
    }

    function testAddReward() public {
        MERC1155 newFreeLootbox = new MERC1155(uri, address(pass), mockRecipe);
        MERC1155 newPremiumLootbox = new MERC1155(uri, address(pass), mockRecipe);
        ERC1155Reward memory newFreeReward = ERC1155Reward(address(newFreeLootbox), 1, 1);
        ERC1155Reward memory newPremiumReward = ERC1155Reward(address(newPremiumLootbox), 1, 1);
        uint256 levelToTest = 1;
        pass.addReward(seasonId, levelToTest, false, newFreeReward);
        pass.addReward(seasonId, levelToTest, true, newPremiumReward);

        (, ERC1155Reward memory freeReward, ERC1155Reward memory premiumReward) = pass.seasonInfo(
            seasonId,
            levelToTest
        );
        assert1155Reward(freeReward, newFreeReward);
        assert1155Reward(premiumReward, newPremiumReward);
    }

    function testCannotAddRewardWithoutAdmin() public {
        vm.expectRevert(revertAccessControl(mockUser, pass.DEFAULT_ADMIN_ROLE()));
        vm.prank(mockUser);
        pass.addReward(seasonId, 1, false, levelInfo[0].freeReward);
    }

    function testCannotAddRewardNotGivenMinterRole() public {
        MERC1155 token = new MERC1155(uri, mockUser, mockRecipe);
        vm.expectRevert(
            abi.encodeWithSelector(TokenNotGivenMinterRole.selector, address(pass), address(token))
        );
        pass.addReward(seasonId, 1, false, ERC1155Reward(address(token), 1, 1));
    }

    function testSetXp() public {
        uint256 levelToTest = 1;
        uint256 xpToTest = 100;
        (uint256 _xp, , ) = pass.seasonInfo(seasonId, levelToTest);
        pass.setXp(seasonId, levelToTest, xpToTest);
        (_xp, , ) = pass.seasonInfo(seasonId, levelToTest);
        assertEq(_xp, xpToTest);
    }

    function testCannotSetXpWithoutAdmin() public {
        vm.expectRevert(revertAccessControl(mockUser, pass.DEFAULT_ADMIN_ROLE()));
        vm.prank(mockUser);
        pass.setXp(seasonId, 1, 1);
    }

    function testGiveXp() public {
        (uint256 _xp, ) = pass.userInfo(mockUser, seasonId);
        vm.prank(pass.oracleAddress());
        pass.giveXp(seasonId, _xp + 10, mockUser);
        (uint256 newXp, ) = pass.userInfo(mockUser, seasonId);
        assertEq(newXp, _xp + 10);
    }

    function testCannotGiveXpWithoutOracle() public {
        vm.expectRevert(revertAccessControl(address(this), ORACLE_ROLE));
        pass.giveXp(seasonId, 10, mockUser);
    }

    function testChangeOracle() public {
        address oldOracle = pass.oracleAddress();
        pass.changeOracle(address(2));
        assertEq(pass.oracleAddress(), address(2));
        assertFalse(pass.hasRole(ORACLE_ROLE, oldOracle));
        assertTrue(pass.hasRole(ORACLE_ROLE, address(2)));
    }

    function testCannotChangeOracleWithoutAdmin() public {
        vm.expectRevert(revertAccessControl(mockUser, pass.DEFAULT_ADMIN_ROLE()));
        vm.prank(mockUser);
        pass.changeOracle(address(2));
    }

    function giveXp(uint256 xp) private {
        vm.prank(defaultOracle);
        pass.giveXp(seasonId, xp, mockUser);
    }

    ///@dev level up, beyond max, normal increments
    function testLevel() public {
        //handle last level differently since at last level xp is 0 and will cause underflow
        for (uint256 x; x < maxLevel; x++) {
            assertEq(pass.level(mockUser, seasonId), x);
            (uint256 _xp, , ) = pass.seasonInfo(seasonId, x);
            giveXp(_xp - 1);
            assertEq(pass.level(mockUser, seasonId), x);
            giveXp(1);
        }
        assertEq(pass.level(mockUser, seasonId), maxLevel);
        giveXp(100);
        assertEq(pass.level(mockUser, seasonId), maxLevel);
    }

    function testIsUserPremium() public {
        assertFalse(pass.isUserPremium(mockUser, seasonId));
        //test through minting
        pass.mint(mockUser, seasonId, 1, "");
        assertTrue(pass.isUserPremium(mockUser, seasonId));
        //not claimed
        pass.burn(mockUser, seasonId, 1);
        assertFalse(pass.isUserPremium(mockUser, seasonId));
        // //minted and claimed
        pass.mint(mockUser, seasonId, 1, "");
        (uint256 _xp, , ) = pass.seasonInfo(seasonId, 0);
        giveXp(_xp);
        pass.claimReward(seasonId, mockUser, 0, true);
        assertTrue(pass.isUserPremium(mockUser, seasonId));
    }

    function testClaimReward() public {
        pass.mint(mockUser, seasonId, 2, "");
        for (uint256 x; x <= maxLevel; x++) {
            pass.claimReward(seasonId, mockUser, x, false);
            pass.claimReward(seasonId, mockUser, x, true);
            assertTrue(pass.isRewardClaimed(mockUser, seasonId, x, false));
            assertTrue(pass.isRewardClaimed(mockUser, seasonId, x, true));

            //this handles the case of it being set once
            (, bool claimedPrem) = pass.userInfo(mockUser, seasonId);
            assertTrue(claimedPrem);
            (uint256 _xp, ERC1155Reward memory freeReward, ERC1155Reward memory premReward) = pass
                .seasonInfo(seasonId, x);
            assertEq(checkERC1155Balance(freeReward, mockUser), freeReward.qty);
            assertEq(checkERC1155Balance(premReward, mockUser), premReward.qty);
            giveXp(_xp);
        }

        //check if it is burned only once
        assertEq(1, MERC1155(address(pass)).balanceOf(mockUser, seasonId));
    }

    function testCannotClaimRewardNotAtLevel() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                NotAtLevelNeededToClaimReward.selector,
                seasonId,
                mockUser,
                pass.level(mockUser, seasonId),
                2
            )
        );
        pass.claimReward(seasonId, mockUser, 2, false);
    }

    function testCannotClaimRewardAlreadyClaimed() public {
        (uint256 _xp, , ) = pass.seasonInfo(seasonId, 0);
        giveXp(_xp);
        pass.claimReward(seasonId, mockUser, 0, false);
        vm.expectRevert(abi.encodeWithSelector(RewardAlreadyClaimed.selector, seasonId, mockUser));
        pass.claimReward(seasonId, mockUser, 0, false);
    }

    function testCannotClaimRewardNoPremium() public {
        vm.expectRevert(
            abi.encodeWithSelector(NeedPremiumPassToClaimPremiumReward.selector, seasonId, mockUser)
        );
        pass.claimReward(seasonId, mockUser, 0, true);
    }
}
