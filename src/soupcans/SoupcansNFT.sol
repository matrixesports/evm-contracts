// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract SoupcansNFT is ERC721, Owned, ReentrancyGuard {
    string public baseTokenURI;
    /// @dev true id mint has started
    bool public mintStart;
    /// @dev mint price
    /// @dev in wei
    uint256 public price;
    /// @dev mint id
    uint256 public mintId;
    /// @dev reserved for private auction
    uint256 public constant RESERVED_PRIVATE = 5;
    /// @dev total supply
    uint256 public constant TOTAL_SUPPLY = 1000;

    constructor(string memory _baseTokenURI) ERC721("NAME", "SYMBOL") Owned(msg.sender) {
        baseTokenURI = _baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////////////*/

    /// @notice set uri for this contract
    /// @dev only owner can call it
    /// @param _baseTokenURI new ipfs hash
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice start/stop mint
    function toggleMint(bool toggle) external onlyOwner {
        mintStart = toggle;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /// @notice mint first 5 for private auction
    function mintForAuction() public onlyOwner {
        if (mintId <= RESERVED_PRIVATE) {
            mintId++;
            _mint(msg.sender, mintId);
        }
    }

    /// @notice withdraw eth
    /// @dev only owner can call it
    function withdraw(address payable to) public onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "TRY DIFFERENT ADDRESS");
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINT
    //////////////////////////////////////////////////////////////////////*/

    /// @notice return uri for an id
    /// @return string in format ipfs://<uri>/id.json
    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat("ipfs://", baseTokenURI, "/", Strings.toString(id), ".json");
    }

    /// @notice mint called by msg.sender
    /// @dev mint must have started
    function mint() public payable nonReentrant {
        require(mintStart, "MINT HAS NOT STARTED");
        require(msg.value >= price, "MINT PRICE MORE THAN ETH SENT");
        require(mintId < TOTAL_SUPPLY, "SOLD OUT");
        mintId++;
        _mint(msg.sender, mintId);
    }

    receive() external payable {}
}
