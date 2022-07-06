// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0;

// import "forge-std/Test.sol";
// import "../src/rewards/MERC20.sol";
// import "../src/rewards/MERC721.sol";
// import "../src/rewards/MERC1155.sol";

// contract Helper is Test {
//     string public constant uri = "ipfs://fwjhfvbdwhjfshjfdvb";
//     address public constant mockUser = address(1);
//     address public constant mockRecipe = address(2);
//     address public constant mockPass = address(3);

//     function assert1155Reward(ERC1155Reward memory first, ERC1155Reward memory second) internal {
//         assertEq(first.token, second.token);
//         assertEq(first.qty, second.qty);
//         assertEq(first.id, second.id);
//     }

//     function newERC1155Reward(
//         address pass,
//         address recipe,
//         uint256 id,
//         uint256 qty
//     ) internal returns (ERC1155Reward memory) {
//         return ERC1155Reward(address(new MERC1155(uri, pass, recipe)), id, qty);
//     }

//     function checkERC1155Balance(ERC1155Reward memory reward, address user)
//         internal
//         view
//         returns (uint256)
//     {
//         return MERC1155(reward.token).balanceOf(user, reward.id);
//     }

//     function assert721Reward(ERC721Reward memory first, ERC721Reward memory second) internal {
//         assertEq(first.token, second.token);
//         assertEq(first.id, second.id);
//     }

//     ///@dev id always stays one as we have unique addresses and we only mint one
//     function newERC721Reward(address pass, address recipe) internal returns (ERC721Reward memory) {
//         return ERC721Reward(address(new MERC721("", "", uri, pass, recipe)), 1);
//     }

//     function checkERC721Balance(ERC721Reward memory reward, address user)
//         internal
//         view
//         returns (uint256)
//     {
//         return MERC721(reward.token).balanceOf(user);
//     }

//     function assert20Reward(ERC20Reward memory first, ERC20Reward memory second) internal {
//         assertEq(first.token, second.token);
//         assertEq(first.qty, second.qty);
//     }

//     function newERC20Reward(
//         address pass,
//         address recipe,
//         uint256 qty
//     ) internal returns (ERC20Reward memory) {
//         return ERC20Reward(address(new MERC20("", "", 18, pass, recipe)), qty);
//     }

//     function checkERC20Balance(ERC20Reward memory reward, address user)
//         internal
//         view
//         returns (uint256)
//     {
//         return MERC20(reward.token).balanceOf(user);
//     }

//     function revertAccessControl(address account, bytes32 role) public pure returns (bytes memory) {
//         return
//             bytes(
//                 abi.encodePacked(
//                     "AccessControl: account ",
//                     Strings.toHexString(uint160(account), 20),
//                     " is missing role ",
//                     Strings.toHexString(uint256(role), 32)
//                 )
//             );
//     }
// }
