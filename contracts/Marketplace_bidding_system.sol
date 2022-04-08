// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./dependencies/ERC20.sol";

import "./dependencies/IERC721Receiver.sol";
import "./dependencies/SafeMath.sol";

contract NFTCollection {

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   */
  function  balanceOf  (
    address _owner
  )
    external
    view
    returns (uint256){}

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address){}

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC721Received`
   * on `_to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    external{}

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external{}

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they mayb be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external{}


  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external{}

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external{}

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address){}

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool){}

}


contract Marketplace_bidding_system is IERC721Receiver {
    using SafeMath for uint;
    // Name of the marketplace
    string public name;

    // Index of auctions
    uint256 public index = 0;

    uint256 public commission;

    address public feeAddress;

    address public owner;

    // Structure to define auction properties
    struct Auction {
        uint256 index; // Auction Index
        address addressNFTCollection; // Address of the ERC721 NFT Collection contract
        address addressPaymentToken; // Address of the ERC20 Payment Token contract
        uint256 nftId; // NFT Id
        address creator; // Creator of the Auction
        address payable currentBidOwner; // Address of the highest bider
        uint256 currentBidPrice; // Current highest bid for the auction
        uint256 endAuction; // Timestamp for the end day&time of the auction
        uint256 bidCount; // Number of bid placed on the auction
    }

    // Array will all auctions
    Auction[] private allAuctions;

    // Public event to notify that a new auction has been created
    event NewAuction(
        uint256 index,
        address addressNFTCollection,
        address addressPaymentToken,
        uint256 nftId,
        address mintedBy,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 endAuction,
        uint256 bidCount
    );

    // Public event to notify that a new bid has been placed
    event NewBidOnAuction(uint256 auctionIndex, uint256 newBid);

    // Public event to notif that winner of an
    // auction claim for his reward
    event NFTClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that the creator of
    // an auction claimed for his money
    event TokensClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that an NFT has been refunded to the
    // creator of an auction
    event NFTRefunded(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // constructor of the contract
    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    }

      /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
     */
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function setCommission(uint _commission) public onlyOwner {
        commission = _commission;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    /**
     * Create a new auction of a specific NFT
     * @param _addressNFTCollection address of the ERC721 NFT collection contract
     * @param _addressPaymentToken address of the ERC20 payment token contract
     * @param _nftId Id of the NFT for sale
     * @param _initialBid Inital bid decided by the creator of the auction
     * @param _endAuction Timestamp with the end date and time of the auction
     */
    function createAuction(
        address _addressNFTCollection,
        address _addressPaymentToken,
        uint256 _nftId,
        uint256 _initialBid,
        uint256 _endAuction
    ) external returns (uint256) {
        //Check is addresses are valid
        require(
            isContract(_addressNFTCollection),
            "Invalid NFT Collection contract address"
        );
        require(
            isContract(_addressPaymentToken),
            "Invalid Payment Token contract address"
        );

        _endAuction = _endAuction + block.timestamp;

        // Check if the endAuction time is valid
        // require(_endAuction > block.timestamp, "Invalid end date for auction");

        // Check if the initial bid price is > 0
        require(_initialBid > 0, "Invalid initial bid price");

        // Get NFT collection contract
        NFTCollection nftCollection = NFTCollection(_addressNFTCollection);

        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the owner of this NFT
        require(
            nftCollection.ownerOf(_nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        // Make sure the owner of the NFT approved that the MarketPlace contract
        // is allowed to change ownership of the NFT
        require(
            nftCollection.getApproved(_nftId) == address(this),
            "Require NFT ownership transfer approval"
        );

        // Lock NFT in Marketplace contract
        // require(nftCollection.transferFrom(msg.sender, address(this), 0), "Failed to transfer NFT");
        nftCollection.transferFrom(msg.sender, address(this), _nftId);

        //Casting from address to address payable
        address payable currentBidOwner = payable(address(0));
        // Create new Auction object
        Auction memory newAuction = Auction({
            index: index,
            addressNFTCollection: _addressNFTCollection,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            creator: msg.sender,
            currentBidOwner: currentBidOwner,
            currentBidPrice: _initialBid,
            endAuction: _endAuction,
            bidCount: 0
        });

        //update list
        allAuctions.push(newAuction);

        // increment auction sequence
        index++;

        // Trigger event and return index of new auction
        emit NewAuction(
            index,
            _addressNFTCollection,
            _addressPaymentToken,
            _nftId,
            msg.sender,
            currentBidOwner,
            _initialBid,
            _endAuction,
            0
        );
        return index;
    }

    /**
     * Check if an auction is open
     * @param _auctionIndex Index of the auction
     */
    function isOpen(uint256 _auctionIndex) public view returns (bool) {
        Auction storage auction = allAuctions[_auctionIndex];
        if (block.timestamp >= auction.endAuction) return false;
        return true;
    }

    /**
     * Return the address of the current highest bider
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBidOwner(uint256 _auctionIndex)
        public
        view
        returns (address)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        return allAuctions[_auctionIndex].currentBidOwner;
    }

    /**
     * Return the current highest bid price
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBid(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        return allAuctions[_auctionIndex].currentBidPrice;
    }

    /**
     * Place new bid on a specific auction
     * @param _auctionIndex Index of auction
     * @param _newBid New bid price
     */
    function bid(uint256 _auctionIndex, uint256 _newBid)
        external
        returns (bool)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        Auction storage auction = allAuctions[_auctionIndex];

        // check if auction is still open
        require(isOpen(_auctionIndex), "Auction is not open");

        // check if new bid price is higher than the current one
        require(
            _newBid > auction.currentBidPrice,
            "New bid price must be higher than the current bid"
        );

        // check if new bider is not the owner
        require(
            msg.sender != auction.creator,
            "Creator of the auction cannot place new bid"
        );

        // get ERC20 token contract
        ERC20 paymentToken = ERC20(auction.addressPaymentToken);

        // new bid is better than current bid!

        // transfer token from new bider account to the marketplace account
        // to lock the tokens
        require(
            paymentToken.transferFrom(msg.sender, address(this), _newBid),
            "Tranfer of token failed"
        );

        // new bid is valid so must refund the current bid owner (if there is one!)
        if (auction.bidCount > 0) {
            paymentToken.transfer(
                auction.currentBidOwner,
                auction.currentBidPrice
            );
        }

        // update auction info
        address payable newBidOwner = payable(msg.sender);
        auction.currentBidOwner = newBidOwner;
        auction.currentBidPrice = _newBid;
        auction.bidCount++;

        // Trigger public event
        emit NewBidOnAuction(_auctionIndex, _newBid);

        return true;
    }

    /**
     * Function used by the winner of an auction
     * to withdraw his NFT.
     * When the NFT is withdrawn, the creator of the
     * auction will receive the payment tokens in his wallet
     * @param _auctionIndex Index of auction
     */
    function claimNFT(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the winner of the auction
        require(
            auction.currentBidOwner == msg.sender,
            "NFT can be claimed only by the current bid owner"
        );

        // Get NFT collection contract
        NFTCollection nftCollection = NFTCollection(
            auction.addressNFTCollection
        );
        // Transfer NFT from marketplace contract
        // to the winner address
        nftCollection.transferFrom(
                address(this),
                auction.currentBidOwner,
                _auctionIndex
            );
        // require(
        //     nftCollection.transferFrom(
        //         address(this),
        //         auction.currentBidOwner,
        //         _auctionIndex
        //     )
        // );

        // Get ERC20 Payment token contract
        ERC20 paymentToken = ERC20(auction.addressPaymentToken);
        // Transfer locked token from the marketplace
        // contract to the auction creator address
        // require(
        //     paymentToken.transfer(auction.creator, auction.currentBidPrice)
        // );

        uint fee = ((auction.currentBidPrice).mul(commission)).div(10000);
        uint amountAfterFee = (auction.currentBidPrice).sub(fee);
        // paymentToken.transfer(auction.creator, auction.currentBidPrice);
        require(paymentToken.transfer(auction.creator, amountAfterFee));
        require(paymentToken.transfer(owner, fee));

        emit NFTClaimed(_auctionIndex, auction.nftId, msg.sender);
    }

    /**
     * Function used by the creator of an auction
     * to withdraw his tokens when the auction is closed
     * When the Token are withdrawn, the winned of the
     * auction will receive the NFT in his walled
     * @param _auctionIndex Index of the auction
     */
    function claimToken(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length, "Invalid auction index"); // XXX Optimize

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the creator of the auction
        require(
            auction.creator == msg.sender,
            "Tokens can be claimed only by the creator of the auction"
        );

        // Get NFT Collection contract
        NFTCollection nftCollection = NFTCollection(
            auction.addressNFTCollection
        );
        // Transfer NFT from marketplace contract
        // to the winned of the auction
        nftCollection.transferFrom(
            address(this),
            auction.currentBidOwner,
            auction.nftId
        );

        // Get ERC20 Payment token contract
        ERC20 paymentToken = ERC20(auction.addressPaymentToken);
        // Transfer locked tokens from the market place contract
        // to the wallet of the creator of the auction

        uint fee = ((auction.currentBidPrice).mul(commission)).div(10000);
        uint amountAfterFee = (auction.currentBidPrice).sub(fee);
        // paymentToken.transfer(auction.creator, auction.currentBidPrice);
        paymentToken.transfer(auction.creator, amountAfterFee);
        paymentToken.transfer(owner, fee);

        emit TokensClaimed(_auctionIndex, auction.nftId, msg.sender);
    }

    /**
     * Function used by the creator of an auction
     * to get his NFT back in case the auction is closed
     * but there is no bider to make the NFT won't stay locked
     * in the contract
     * @param _auctionIndex Index of the auction
     */
    function refund(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the creator of the auction
        require(
            auction.creator == msg.sender,
            "Tokens can be claimed only by the creator of the auction"
        );

        require(
            auction.currentBidOwner == address(0),
            "Existing bider for this auction"
        );

        // Get NFT Collection contract
        NFTCollection nftCollection = NFTCollection(
            auction.addressNFTCollection
        );
        // Transfer NFT back from marketplace contract
        // to the creator of the auction
        nftCollection.transferFrom(
            address(this),
            auction.creator,
            auction.nftId
        );

        emit NFTRefunded(_auctionIndex, auction.nftId, msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
