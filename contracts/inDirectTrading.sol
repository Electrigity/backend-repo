// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./UserManager.sol";

contract IndirectEnergyTrading {
    UserManager userManager;

    event TradeMatched(
        uint indexed tradeId,
        address buyer,
        address seller,
        uint averagePrice
    );
    event OrderPlaced(
        uint indexed orderId,
        address user,
        uint energyAmount,
        uint price,
        bool isBuyOrder
    );
    event OrderCancelled(uint indexed orderId, address user);

    struct Order {
        address user;
        uint energyAmount;
        uint price;
        bool isBuyOrder;
    }

    struct Trade {
        address buyer;
        address seller;
        uint averagePrice;
        uint energyAmount;
    }

    uint public nextTradeId = 1;
    uint public nextOrderId = 1;
    mapping(uint => Order) public orders;
    uint[] public buyOrderIds;
    uint[] public sellOrderIds;
    Trade[] public tradeHistory;

    constructor(address userManagerAddress) {
        userManager = UserManager(userManagerAddress);
    }

    function placeOrder(
        uint _energyAmount,
        uint _price,
        bool _isBuyOrder
    ) public {
        require(
            userManager.isUserRegistered(msg.sender),
            "User must be registered."
        );
        require(_energyAmount > 0, "Energy amount must be greater than zero.");
        require(_price > 0, "Price must be greater than zero.");

        Order memory newOrder = Order({
            user: msg.sender,
            energyAmount: _energyAmount,
            price: _price,
            isBuyOrder: _isBuyOrder
        });

        orders[nextOrderId] = newOrder;
        if (_isBuyOrder) {
            buyOrderIds.push(nextOrderId);
        } else {
            sellOrderIds.push(nextOrderId);
        }

        emit OrderPlaced(
            nextOrderId,
            msg.sender,
            _energyAmount,
            _price,
            _isBuyOrder
        );
        nextOrderId++;
    }

    function cancelOrder(uint orderId) public {
        Order memory order = orders[orderId];

        removeOrder(order.isBuyOrder ? buyOrderIds : sellOrderIds, orderId);
        delete orders[orderId];

        emit OrderCancelled(orderId, msg.sender);
    }

    function matchOrders() public {
        uint[] memory filteredBuyIds = filterAndSortOrders(buyOrderIds, true);
        uint[] memory filteredSellIds = filterAndSortOrders(
            sellOrderIds,
            false
        );

        uint i = 0;
        uint j = 0;

        while (i < filteredBuyIds.length && j < filteredSellIds.length) {
            Order memory buyOrder = orders[filteredBuyIds[i]];
            Order memory sellOrder = orders[filteredSellIds[j]];

            if (buyOrder.energyAmount == sellOrder.energyAmount) {
                uint averagePrice = (buyOrder.price + sellOrder.price) / 2;
                executeTrade(buyOrder.user, sellOrder.user, averagePrice, buyOrder.energyAmount);
                removeOrder(
                    buyOrderIds,
                    findIndex(buyOrderIds, filteredBuyIds[i])
                );
                removeOrder(
                    sellOrderIds,
                    findIndex(sellOrderIds, filteredSellIds[j])
                );
                i++;
                j++;
            } else if (buyOrder.energyAmount > sellOrder.energyAmount) {
                j++;
            } else {
                i++;
            }
        }
    }

    function filterAndSortOrders(
        uint[] storage orderIds,
        bool isBuyOrder
    ) private view returns (uint[] memory) {
        uint[] memory filteredIds = new uint[](orderIds.length);
        uint count = 0;

        for (uint i = 0; i < orderIds.length; i++) {
            if (orders[orderIds[i]].energyAmount > 0) {
                filteredIds[count++] = orderIds[i];
            }
        }

        if (isBuyOrder) {
            sortOrders(filteredIds, count, true);
        } else {
            sortOrders(filteredIds, count, false);
        }

        return filteredIds;
    }

    function sortOrders(
        uint[] memory orderIds,
        uint count,
        bool descending
    ) private view {
        for (uint i = 1; i < count; i++) {
            uint key = orderIds[i];
            uint j = i - 1;

            while (
                (j >= 0) &&
                (
                    descending
                        ? orders[key].price > orders[orderIds[j]].price
                        : orders[key].price < orders[orderIds[j]].price
                )
            ) {
                orderIds[j + 1] = orderIds[j];
                if (j == 0) break;
                j--;
            }
            orderIds[j + 1] = key;
        }
    }

    function findIndex(
        uint[] storage orderIds,
        uint orderId
    ) private view returns (uint) {
        for (uint i = 0; i < orderIds.length; i++) {
            if (orderIds[i] == orderId) {
                return i;
            }
        }
        return orderIds.length;
    }
    function findOrderIndex(
        uint[] storage orderIds,
        address user
    ) private view returns (uint) {
        for (uint i = 0; i < orderIds.length; i++) {
            if (orders[orderIds[i]].user == user) {
                return i;
            }
        }
        revert("Order not found.");
    }

    function executeTrade(
        address buyer,
        address seller,
        uint averagePrice,
        uint energyAmount
    ) private {
        userManager.transferTokens(buyer, seller, averagePrice);

        userManager.updateTokenBalance(buyer, averagePrice, false);
        userManager.updateTokenBalance(seller, averagePrice, true);

        userManager.updateEnergyBalance(buyer, energyAmount, true);
        userManager.updateEnergyBalance(seller, energyAmount, false);
        tradeHistory.push(
            Trade({
                buyer: buyer,
                seller: seller,
                averagePrice: averagePrice,
                energyAmount: energyAmount
            })
        );
        emit TradeMatched(nextTradeId++, buyer, seller, averagePrice);
    }
    function getTradeHistory() public view returns (Trade[] memory) {
        return tradeHistory;
    }

    function removeOrder(uint[] storage orderList, uint orderId) private {
        orderList[orderId] = orderList[orderList.length - 1];
        orderList.pop();
    }
}
