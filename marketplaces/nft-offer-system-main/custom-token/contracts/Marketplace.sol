pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC2981.sol";
import "./Token.sol";
/**
 * @title NFT Marketplace with ERC-2981 support
 * @notice Defines a marketplace to bid on and sell NFTs.
 *         Sends royalties to rightsholder on each sale if applicable.
 */

 // Modern ERC20 Token interface
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// // Modern ERC721 Token interface
// interface Token {
//     function safeTransferFrom(address from, address to, uint tokenId) external;
//     function mint(address to) external;
//     function totalSupply() external returns (uint256) ;
// }
contract Marketplace {

    struct BuyOffer {
        address buyer;
        uint256 price;
        uint256 createTime;
    }

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // Store the address of the contract of the NFT to trade. Can be changed in
    // constructor or with a call to setTokenContractAddress.
    address public _tokenContractAddress = address(0);
    address public _customTokenContractAddress = address(0);
    // Store all active buy offers and maps them to their respective token ids
    mapping(uint256 => BuyOffer) public activeBuyOffers;
    // Token contract
    Token token;
    IERC20 customToken;
    // Escrow for buy offers
    mapping(address => mapping(uint256 => uint256)) public buyOffersEscrow;

    // Events
    event NewBuyOffer(uint256 tokenId, address buyer, uint256 value);
    event BuyOfferWithdrawn(uint256 tokenId, address buyer);
    event RoyaltiesPaid(uint256 tokenId, uint value);
    event Sale(uint256 tokenId, address seller, address buyer, uint256 value);

    constructor(address tokenContractAddress, address customTokenContractAddress) {
        _tokenContractAddress = tokenContractAddress;
        token = Token(_tokenContractAddress);

        _customTokenContractAddress = customTokenContractAddress;
        customToken = IERC20(_customTokenContractAddress);
    }

    /// @notice Makes a buy offer for a token. The token does not need to have
    ///         been put up for sale. A buy offer can not be withdrawn or
    ///         replaced for 24 hours. Amount of the offer is put in escrow
    ///         until the offer is withdrawn or superceded
    /// @param tokenId - id of the token to buy
    function makeBuyOffer(uint256 tokenId, uint256 price)
    external tokenOwnerForbidden(tokenId)
    {
        // Reject the offer if item is already available for purchase at a
        // lower or identical price
        // if (activeSellOffers[tokenId].minPrice != 0) {
        // require((msg.value > activeSellOffers[tokenId].minPrice),
        //     "Sell order at this price or lower exists");
        // }
        // Only process the offer if it is higher than the previous one or the
        // previous one has expired
        customToken.transferFrom(msg.sender, address(this), price);
        // require(customToken.transferFrom(msg.sender, address(this), price), "Could not transfer affer amount to Marketplace!");
        require(activeBuyOffers[tokenId].createTime <
                (block.timestamp - 1 days) || price >
                activeBuyOffers[tokenId].price,
                "Previous buy offer higher or not expired");
        address previousBuyOfferOwner = activeBuyOffers[tokenId].buyer;
        uint256 refundBuyOfferAmount = buyOffersEscrow[previousBuyOfferOwner]
        [tokenId];
        // Refund the owner of the previous buy offer
        buyOffersEscrow[previousBuyOfferOwner][tokenId] = 0;
        if (refundBuyOfferAmount > 0) {
            payable(previousBuyOfferOwner).call{value: refundBuyOfferAmount}('');
        }
        // Create a new buy offer
        activeBuyOffers[tokenId] = BuyOffer({buyer : msg.sender,
                                             price : price,
                                             createTime : block.timestamp});
        // Create record of funds deposited for this offer
        buyOffersEscrow[msg.sender][tokenId] = price;
        // Broadcast the buy offer
        emit NewBuyOffer(tokenId, msg.sender, price);
    }

    /// @notice Withdraws a buy offer. Can only be withdrawn a day after being
    ///         posted
    /// @param tokenId - id of the token whose buy order to remove
    function withdrawBuyOffer(uint256 tokenId)
    external lastBuyOfferExpired(tokenId) {
        require(activeBuyOffers[tokenId].buyer == msg.sender,
            "Not buyer");
        uint256 refundBuyOfferAmount = buyOffersEscrow[msg.sender][tokenId];
        // Set the buyer balance to 0 before refund
        buyOffersEscrow[msg.sender][tokenId] = 0;
        // Remove the current buy offer
        delete(activeBuyOffers[tokenId]);
        // Refund the current buy offer if it is non-zero
        if (refundBuyOfferAmount > 0) {
             // customToken.transferFrom(address(this), msg.sender, refundBuyOfferAmount);
             customToken.transfer(msg.sender, refundBuyOfferAmount);
           // IERC20(trustedFeeTokenAddress).transferFrom(address(this), msg.sender, refundBuyOfferAmount);

           // msg.sender.call{value: refundBuyOfferAmount}('');
        }
        // Broadcast offer withdrawal
        emit BuyOfferWithdrawn(tokenId, msg.sender);
    }

    /// @notice Lets a token owner accept the current buy offer
    ///         (even without a sell offer)
    /// @param tokenId - id of the token whose buy order to accept
    function acceptBuyOffer(uint256 tokenId)
    external isMarketable(tokenId) tokenOwnerOnly(tokenId) {
        address currentBuyer = activeBuyOffers[tokenId].buyer;
        require(currentBuyer != address(0),
            "No buy offer");
        uint256 saleValue = activeBuyOffers[tokenId].price;
        uint256 netSaleValue = saleValue;
        // Pay royalties if applicable
        // if (_checkRoyalties(_tokenContractAddress)) {
        //     netSaleValue = _deduceRoyalties(tokenId, saleValue);
        // }
        // Delete the current sell offer whether it exists or not
        // delete (activeSellOffers[tokenId]);
        // Delete the buy offer that was accepted
        delete (activeBuyOffers[tokenId]);
        // Withdraw buyer's balance
        buyOffersEscrow[currentBuyer][tokenId] = 0;
        // Transfer funds to the seller
        // customToken.transferFrom(address(this), msg.sender, netSaleValue);
        customToken.transfer(msg.sender, netSaleValue);
        //msg.sender.call{value: netSaleValue}('');
        // And token to the buyer
        token.safeTransferFrom(
            msg.sender,
            currentBuyer,
            tokenId
        );
        // Broadcast the sale
        emit Sale(tokenId,
            msg.sender,
            currentBuyer,
            saleValue);
    }

    function acceptBuyOffer2(uint256 tokenId)
    external isMarketable(tokenId) tokenOwnerOnly(tokenId) {
        address currentBuyer = activeBuyOffers[tokenId].buyer;
        require(currentBuyer != address(0),
            "No buy offer");
        uint256 saleValue = activeBuyOffers[tokenId].price;
        uint256 netSaleValue = saleValue;

        // Delete the buy offer that was accepted
        delete (activeBuyOffers[tokenId]);
        // Withdraw buyer's balance
        buyOffersEscrow[currentBuyer][tokenId] = 0;
        // Transfer funds to the seller
        // customToken.transferFrom(address(this), msg.sender, netSaleValue);
        customToken.transferFrom(address(this), msg.sender, netSaleValue);
        //msg.sender.call{value: netSaleValue}('');
        // And token to the buyer
        token.safeTransferFrom(
            msg.sender,
            currentBuyer,
            tokenId
        );
        // Broadcast the sale
        emit Sale(tokenId,
            msg.sender,
            currentBuyer,
            saleValue);
    }


    modifier isMarketable(uint256 tokenId) {
        require(token.getApproved(tokenId) == address(this),
            "Not approved");
        _;
    }
    modifier tokenOwnerForbidden(uint256 tokenId) {
        require(token.ownerOf(tokenId) != msg.sender,
            "Token owner not allowed");
        _;
    }

    modifier tokenOwnerOnly(uint256 tokenId) {
        require(token.ownerOf(tokenId) == msg.sender,
            "Not token owner");
        _;
    }

    modifier lastBuyOfferExpired(uint256 tokenId) {
        require(
            activeBuyOffers[tokenId].createTime < (block.timestamp - 1 days),
            "Buy offer not expired");
        _;
    }
}
