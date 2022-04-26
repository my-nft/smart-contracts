// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../dependencies/Context.sol";
import "../dependencies/AccessControl.sol";
import "../dependencies/ERC721A.sol";
import "../dependencies/ERC721Pausable.sol";
import "../dependencies/IERC721Receiver.sol";
import "../dependencies/Address.sol";
import "../dependencies/SafeMath.sol";
/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */

contract NonFungibleToken is Context, AccessControl, ERC721A, ERC721Pausable {

    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    address public owner;
    address payable public admin = payable(0xFdf9851EE0F375F513098Da24b9F60629EC57624);
    uint256 public fee = 1e17;

    bool public whitelistingEnabled = false;
    bool public mintingEnabled = false;
    bool public freezeMetadata = false;

    uint256 private _maxPerWallet = 100;
    uint256 public numberOfWhitelisted;


    uint256 private _revealsCount = 0;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(string memory name, string memory symbol, string memory _baseURI, uint256 maxPerWallet) public ERC721A(name, symbol) payable {
        require(msg.value >= fee, "NonFungibleToken: must pay required fees");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _setBaseURI(_baseURI);
        _maxPerWallet = maxPerWallet;
        owner = msg.sender;
    }


    function getMaxPerWallet() public view returns (uint256) {
        return _maxPerWallet;
    }

    function setMaxPerWallet(uint256 maxPerWallet) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have DEFAULT_ADMIN_ROLE");
        _maxPerWallet = maxPerWallet;
    }

    function setFreezeMetadata() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have DEFAULT_ADMIN_ROLE");
        require(! freezeMetadata, "NonFungibleToken: already frozen !");

        freezeMetadata = true;
    }

    function setURI(string memory _baseURI) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have admin role");
        require(! freezeMetadata, "Metadata frozen !");
        require((_revealsCount < 2), "You cannot make more than three reveals");
        _setBaseURI(_baseURI);
        _revealsCount +=1;
    }
    
    function setOwner(address _owner) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have admin role");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MINTER_ROLE, _owner);
        owner = _owner;
    }

    function toggleMinting(bool _bool) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have admin role to mint");
        mintingEnabled = _bool;

    }

    function toggleWhitelisting(bool _toggle) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have admin role");
        whitelistingEnabled = _toggle;

    }



    function whitelist(address[] memory _beneficiaries) external {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have admin role");
      for (uint256 i = 0; i < _beneficiaries.length; i++) {
        if (! whitelists[_beneficiaries[i]]){
            numberOfWhitelisted = numberOfWhitelisted + 1;
        }
        whitelists[_beneficiaries[i]] = true;
      }
    }

    function removeFromWhitelist(address[] memory _beneficiaries) external {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have admin role");
      for (uint256 i = 0; i < _beneficiaries.length; i++) {

        if (whitelists[_beneficiaries[i]]){
            numberOfWhitelisted = numberOfWhitelisted.sub(1);
        }
        whitelists[_beneficiaries[i]] = false;
      }
    }  

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI(), "contract-metadata.json"));
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "NonFungibleToken: must have minter role to mint");
        require(whitelists[to] || ! whitelistingEnabled, "User not whitelisted !");

        require(mintingEnabled, "Minting not enabled !");
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _safeMint(to, 1);
        require(balanceOf(to) <= getMaxPerWallet(), "Max NFTs reached by wallet");
    }
    function mint(address to, uint256 quantity) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "NonFungibleToken: must have minter role to mint");
        require(whitelists[to] || ! whitelistingEnabled, "User not whitelisted !");

        require(mintingEnabled, "Minting not enabled !");
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _safeMint(to, quantity);
        require(balanceOf(to) <= getMaxPerWallet(), "Max NFTs reached by wallet");
    }
    function batchMint(address[] memory _beneficiaries) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NonFungibleToken: must have admin role");
        for (uint256 i = 0; i < _beneficiaries.length; i++) {       
          mint(_beneficiaries[i]);                                  
        }                                                           
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721A, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}