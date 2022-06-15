
// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../dependencies/ERC1155.sol";
import "../dependencies/Ownable.sol";
import "../dependencies/SafeMath.sol";
import "../dependencies/Strings.sol";
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
contract NFT_gas_free is ERC1155, Ownable {

    // string public constant name = "Moody Ape Club";
    // string public constant symbol = "MAC";

    string public constant name = "Non Fungible Token";
    string public constant symbol = "NFT";

    using SafeMath for uint256;
    using Strings for uint256;
    string private baseURI;
    uint256 public totalSupply = 0;
    uint256 public constant MAX_NFT_PUBLIC = 5000;
    uint256 private constant MAX_NFT = 10000;
    uint256 public constant maxGiveaway=100;
    uint256 public constant maxPerWalletPrivateSale=10;
    uint256 public constant maxPerWalletPresale=5;
    uint256 public nftsPresale = 2000;
    uint256 public giveawayCount;
    uint256 public privateSalePrice = 150000000000000000;  // 0.15 ETH
    uint256 public presalePrice = 180000000000000000;  // 0.18 ETH
    uint256 public NFTPrice = 200000000000000000;  // 0.2 ETH
    uint private devSup = 4 ether;
    address private devAddress = 0x72DDbDc341BBFc00Fe4F3f49695532841965bF0E;
    bool public isActive;
    bool public isPrivateSaleActive;
    bool public isPresaleActive;
    bool public canReveal;
    bytes32 public root;
    mapping(uint256 => bool) public revealedNFT;
    mapping(address => uint) public nftBalances;

    /*
     * Function to reveal a NFT
    */
    function revealNFT(uint256 _tokenId)
        public
    {
        require(canReveal, 'Reveal option is not active');
        require(_ownerOf(msg.sender, _tokenId), 'You are not the owner of this NFT');
        revealedNFT[_tokenId] = true;
    }

    /*
     * Function to validate owner
    */
    function _ownerOf(address owner, uint256 tokenId) internal view returns (bool) {
        return balanceOf(owner, tokenId) != 0;
    }

    /*
     * Function to mint NFTs
    */
    function mint(address to, uint32 count) internal {
        if (count > 1) {
            uint256[] memory ids = new uint256[](uint256(count));
            uint256[] memory amounts = new uint256[](uint256(count));

            for (uint32 i = 0; i < count; i++) {
                ids[i] = totalSupply + i;
                amounts[i] = 1;
            }

            _mintBatch(to, ids, amounts, "");
        } else {
            _mint(to, totalSupply, 1, "");
        }

        totalSupply += count;
    }

    /*
     * Function setCanReveal to activate/desactivate reveal option
    */
    function setCanReveal(
        bool _isActive
    )
        external
        onlyOwner
    {
        canReveal = _isActive;
    }

    /*
     * Function setIsActive to activate/desactivate the smart contract
    */
    function setIsActive(
        bool _isActive
    )
        external
        onlyOwner
    {
        isActive = _isActive;
    }

    /*
     * Function setPrivateSaleActive to activate/desactivate the presale
    */
    function setPrivateSaleActive(
        bool _isActive
    )
        external
        onlyOwner
    {
        isPrivateSaleActive = _isActive;
    }

    /*
     * Function setPresaleActive to activate/desactivate the presale
    */
    function setPresaleActive(
        bool _isActive
    )
        external
        onlyOwner
    {
        isPresaleActive = _isActive;
    }

    /*
     * Function to set Base URI
    */
    function setURI(
        string memory _URI
    )
        external
        onlyOwner
    {
        baseURI = _URI;
    }

    /*
     * Function to withdraw collected amount during minting by the owner
    */
    function withdraw(
        address _to
    )
        public
        onlyOwner
    {
        uint balance = address(this).balance;
        require(balance > 0, "Balance should be more then zero");

        if(balance <= devSup) {
            payable(devAddress).transfer(balance);
            devSup = devSup.sub(balance);
            return;
        } else {
            if(devSup > 0) {
                payable(devAddress).transfer(devSup);
                balance = balance.sub(devSup);
                devSup = 0;
            }

            payable(_to).transfer(balance);
        }
    }

    /*
     * Function to mint new NFTs during the public sale
     * It is payable. Amount is calculated as per (NFTPrice.mul(_numOfTokens))
    */
    function mintNFT(
        uint32 _numOfTokens
    )
        public
        payable
    {
        require(isActive, 'Contract is not active');
        require(!isPrivateSaleActive, 'Private sale still active');
        require(!isPresaleActive, 'Presale still active');
        require(totalSupply.add(_numOfTokens).sub(giveawayCount) <= MAX_NFT_PUBLIC, "Purchase would exceed max public supply of NFTs");
        require(msg.value >= NFTPrice.mul(_numOfTokens), "Ether value sent is not correct");
        mint(msg.sender,_numOfTokens);
        nftBalances[msg.sender] = nftBalances[msg.sender].add(_numOfTokens);
    }

    /*
     * Function to mint new NFTs during the private sale & presale
     * It is payable.
    */
    function mintNFTDuringPresale(
        uint32 _numOfTokens,
        bytes32[] memory _proof
    )
        public
        payable
    {
        require(isActive, 'Contract is not active');
        require(verify(_proof, bytes32(uint256(uint160(msg.sender)))), "Not whitelisted");

        if (!isPresaleActive) {
            require(isPrivateSaleActive, 'Private sale not active');
            require(msg.value >= privateSalePrice.mul(_numOfTokens), "Ether value sent is not correct");
            require(nftBalances[msg.sender].add(_numOfTokens)<= maxPerWalletPrivateSale, 'Max per wallet reached for this phase');


            mint(msg.sender,_numOfTokens);
            nftBalances[msg.sender] = nftBalances[msg.sender].add(_numOfTokens);
            return;
        }

        require(nftsPresale >= _numOfTokens, "Purchase exceeds presale supply");
        require(msg.value >= presalePrice.mul(_numOfTokens), "Ether value sent is not correct");
        require(nftBalances[msg.sender].add(_numOfTokens)<= maxPerWalletPresale, 'Max per wallet reached for this phase');

        mint(msg.sender,_numOfTokens);
        nftsPresale -= _numOfTokens;
        nftBalances[msg.sender] = nftBalances[msg.sender].add(_numOfTokens);
    }

    /*
     * Function to mint all NFTs for giveaway and partnerships
    */
    function mintByOwner(
        address _to
    )
        public
        onlyOwner
    {
        require(giveawayCount.add(1)<=maxGiveaway,"Cannot do more giveaway");
        require(totalSupply.add(1) < MAX_NFT, "Tokens number to mint cannot exceed number of MAX tokens");
        mint(_to,1);
        giveawayCount=giveawayCount.add(1);
        nftBalances[_to] = nftBalances[_to].add(1);
    }

    /*
     * Function to mint all NFTs for giveaway and partnerships
    */
    function mintMultipleByOwner(
        address[] memory _to
    )
        public
        onlyOwner
    {
        require(totalSupply.add(_to.length) < MAX_NFT, "Tokens number to mint cannot exceed number of MAX tokens");
        require(giveawayCount.add(_to.length)<=maxGiveaway,"Cannot do that much giveaway");
        for(uint256 i = 0; i < _to.length; i++){
            mint(_to[i],1);
            nftBalances[_to[i]] = nftBalances[_to[i]].add(1);
        }
        giveawayCount=giveawayCount.add(_to.length);

    }

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT_PUBLIC
    */
    function uri(
        uint256 _tokenId
    )
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_tokenId<totalSupply, "ERC1155Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    /*
     * Function to set the merkle root
    */
    function setRoot(uint256 _root) onlyOwner() public {
        root = bytes32(_root);
    }

    /*
     * Function to verify the proof
    */
    function verify(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = sha256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = sha256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
