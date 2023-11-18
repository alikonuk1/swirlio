// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.20;

interface ISwirlio {
    error LENGTHS_MISMATCH();
    error ONLY_INITIATOR();
    error TRADE_CLOSED();
    error NOT_OWNER();
    error PAY_FEE();

    struct Trade {
        address initiator;
        address[] offeredNfts;
        uint256[] offeredNftsIds;
        address[] requestNfts;
        bool isOpen;
    }

    event TradeOpened(
        uint256 indexed tradeId, address[] indexed nfts, address[] indexed requestNfts
    );
    event TradeCanceled(uint256 indexed tradeId);
    event TradeAccepted(uint256 indexed tradeId);
}
