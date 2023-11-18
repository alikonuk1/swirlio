// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "./abstract/ReentrancyGuard.sol";
import {ISwirlio} from "./interfaces/ISwirlio.sol";

/**
 * @title swirlio
 * @author swirlio (https://github.com/alikonuk1/swirlio)
 * @author Ali Konuk - (https://github.com/alikonuk1)
 * @dev This contract is for P2P trading non-fungible tokens (NFTs)
 * @dev Please reach out to alikonuk1@protonmail.com regarding to this contract
 */
contract Swirlio is ISwirlio, ERC721Holder, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tradeId;
    mapping(uint256 => Trade) public trades;

    uint256 public fee;

    function openTrade(
        address[] calldata offerNfts,
        uint256[] calldata offerNftIds,
        address[] calldata requestNfts
    ) external {
        uint256 lNft = offerNfts.length;
        if (lNft != offerNftIds.length) {
            revert LENGTHS_MISMATCH();
        }

        uint256 newTradeId = _tradeId.current();
        trades[newTradeId] =
            Trade(msg.sender, offerNfts, offerNftIds, requestNfts, true);

        for (uint256 i = 0; i < lNft;) {
            ERC721(offerNfts[i]).safeTransferFrom(
                msg.sender, address(this), offerNftIds[i]
            );
            unchecked {
                ++i;
            }
        }

        emit TradeOpened(newTradeId, offerNfts, requestNfts);
        _tradeId.increment();
    }

    function cancelTrade(uint256 tradeId) external nonReentrant {
        address initiator = trades[tradeId].initiator;
        if (msg.sender != initiator) {
            revert ONLY_INITIATOR();
        }
        if (trades[tradeId].isOpen == false) {
            revert TRADE_CLOSED();
        }
        trades[tradeId].isOpen = false;

        uint256 lOfferedNfts = trades[tradeId].offeredNfts.length;
        // Return NFTs to the initiator
        for (uint256 i = 0; i < lOfferedNfts;) {
            ERC721(trades[tradeId].offeredNfts[i]).safeTransferFrom(
                address(this), initiator, trades[tradeId].offeredNftsIds[i]
            );
            unchecked {
                ++i;
            }
        }

        emit TradeCanceled(tradeId);
    }

    function acceptTrade(uint256 tradeId, uint256[] calldata tokenIds)
        external
        payable
        nonReentrant
    {
        require(msg.value == fee, "Incorrect fee sent!");
        if(msg.value != fee){
            revert PAY_FEE();
        }
        Trade storage trade = trades[tradeId];

        if (trade.isOpen == false) {
            revert TRADE_CLOSED();
        }
        trade.isOpen = false;

        uint256 lNft = trade.requestNfts.length;
        if (lNft != tokenIds.length) {
            revert LENGTHS_MISMATCH();
        }

        address initiator = trade.initiator;

        for (uint256 i = 0; i < lNft;) {
            if (ERC721(trade.requestNfts[i]).ownerOf(tokenIds[i]) != msg.sender) {
                revert NOT_OWNER();
            }
            ERC721(trade.requestNfts[i]).safeTransferFrom(
                msg.sender, initiator, tokenIds[i]
            );
            unchecked {
                ++i;
            }
        }

        uint256 lOfferedNfts = trade.offeredNfts.length;
        for (uint256 i = 0; i < lOfferedNfts;) {
            ERC721(trade.offeredNfts[i]).safeTransferFrom(
                address(this), msg.sender, trade.offeredNftsIds[i]
            );
            unchecked {
                ++i;
            }
        }

        emit TradeAccepted(tradeId);
    }

    function getOffers(uint256 tradeId)
        external
        view
        returns (address[] memory, uint256[] memory, address[] memory, bool)
    {
        return (
            trades[tradeId].offeredNfts,
            trades[tradeId].offeredNftsIds,
            trades[tradeId].requestNfts,
            trades[tradeId].isOpen
        );
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function withdrawFees() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

}
