// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./dependencies/Ownable.sol";
import "./dependencies/Address.sol";
import "./dependencies/SafeMath.sol";
import "./dependencies/EnumerableSet.sol";
import "./dependencies/IERC20.sol";

// Modern ERC721 Token interface
interface IERC721 {
    function transferFrom(address from, address to, uint tokenId) external;
    function mint(address to, uint256 count) external;
    function totalSupply() external view returns(uint256);
}

contract NFT_Market is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;
    
    uint256 public totalSales;
    address private _trustedNftAddress;
    uint private _maxToMint;
    uint private _mintFee;
    uint private _maxPerTransaction;

    address public admin = 0x72DDbDc341BBFc00Fe4F3f49695532841965bF0E;

    constructor (address trustedNftAddress, uint maxToMint, uint mintFee, uint maxPerTransaction) {
        _trustedNftAddress = trustedNftAddress;
        _maxToMint = maxToMint;
        _mintFee = mintFee;
        _maxPerTransaction = maxPerTransaction;
    }


    function getTrustedNftAddress() public view returns (address) {
        return _trustedNftAddress;
    }

    function getMaxToMint() public view returns (uint) {
        return _maxToMint;
    }

    function getMintFee() public view returns (uint) {
        return _mintFee;
    }

    function getMaxPerTransaction() public view returns (uint) {
        return _maxPerTransaction;
    }

    function setAdmin(address _admin) public  {
        require (_msgSender() == admin || _msgSender() == owner(), "Only admin or owner");
        admin = _admin;
    }

    function setMintNativeFee(uint mintFee) public {
        require (_msgSender() == admin || _msgSender() == owner(), "Only admin or owner");
        _mintFee = mintFee;
    }

    function setMaxPerTransaction(uint _max) public  {
        require (_msgSender() == admin || _msgSender() == owner(), "Only admin or owner");

        _maxPerTransaction = _max;
    }


    // =========== Start Smart Contract Setup ==============


    uint public maxFree = 0;

    // ============ End Smart Contract Setup ================


    function totalSupply() public view returns (uint256){
      return IERC721(getTrustedNftAddress()).totalSupply();
    }

    function canMintFree(uint256 count) public view returns (bool) {
      uint256 totalMinted = IERC721(getTrustedNftAddress()).totalSupply();
      return totalMinted.add(count) < maxFree;
    }
    
    function mint(uint256 count) external payable {
        // owner can mint without fee
        // other users need to pay a fixed fee in token
        uint256 totalMinted = IERC721(getTrustedNftAddress()).totalSupply();
        require (count < getMaxPerTransaction(), "Max to mint reached");
        require (totalMinted.add(count) <= getMaxToMint(), "Max supply reached");

        address _owner = owner();
        if (totalMinted.add(count) > maxFree) {
            require(msg.value >= getMintFee().mul(count), "Insufficient fees");
            (bool success, ) = _owner.call{ value: msg.value }("");
            require(success, "Address: unable to send value, recipient may have reverted");
            totalSales = totalSales.add(msg.value);
        }
        IERC721(getTrustedNftAddress()).mint(_msgSender(), count);

    }

    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);

    // ERC721 Interface Support Function
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns(bytes4) {
        require(_msgSender() == getTrustedNftAddress());
        emit ERC721Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

}