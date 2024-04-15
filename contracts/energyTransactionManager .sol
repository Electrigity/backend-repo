// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./UserManager.sol";

contract EnergyTransactionManager {
    UserManager public userManager;
    address public admin;

    struct Transaction {
        uint id;
        address initiator;
        address receiver;
        uint energyAmount;
        uint price;
        uint validUntil;
        bool committed;
        string status;
        uint initialDate;
        TransactionType transactionType;
    }

    enum TransactionType {
        Buy,
        Sell
    }

    struct CombinedUserInfo {
        address userAddress;
        string username;
        uint256 EGYTokenBalance;
        uint256 energyBalance;
        int latitude;
        int longitude;
        string tradingStatus;
        uint256 buySellAmount;
        uint256 price;
        uint256 expiryDate;
    }
    uint private nextTransactionId = 1;
    mapping(uint => Transaction) public transactions;
    uint[] public pendingTransactions;
    uint[] private committedTransactions;

    event TransactionInitiated(
        uint transactionId,
        address receiver,
        TransactionType transactionType
    );
    event TransactionCommitted(
        uint transactionId,
        bool accepted,
        string status
    );

    constructor(address userManagerAddress) {
        admin = msg.sender;
        userManager = UserManager(userManagerAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this.");
        _;
    }

    function getActiveTraders()
        public
        view
        returns (CombinedUserInfo[] memory)
    {
        uint activeCount = 0;
        address[] memory userAddresses = userManager.getUserAddresses();
        for (uint i = 0; i < userAddresses.length; i++) {
            UserManager.TradingInfo memory tradingInfo = userManager
                .getTradingInfo(userAddresses[i]);
            if (isTradingActive(tradingInfo.tradingStatus)) {
                activeCount++;
            }
        }

        CombinedUserInfo[] memory activeTraders = new CombinedUserInfo[](
            activeCount
        );
        uint currentIndex = 0;
        for (uint i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            UserManager.TradingInfo memory tradingInfo = userManager
                .getTradingInfo(userAddress);
            if (isTradingActive(tradingInfo.tradingStatus)) {
                (
                    ,
                    string memory username,
                    uint256 EGYTokenBalance,
                    int latitude,
                    int longitude,
                    uint256 energyBalance,

                ) = userManager.getUserInfoAll(userAddress);
                activeTraders[currentIndex] = CombinedUserInfo({
                    userAddress: userAddress,
                    username: username,
                    EGYTokenBalance: EGYTokenBalance,
                    energyBalance: energyBalance,
                    latitude: latitude,
                    longitude: longitude,
                    tradingStatus: tradingInfo.tradingStatus,
                    buySellAmount: tradingInfo.buySellAmount,
                    price: tradingInfo.price,
                    expiryDate: tradingInfo.expiryDate
                });
                currentIndex++;
            }
        }
        return activeTraders;
    }
    function isTradingActive(string memory status) private pure returns (bool) {
        return
            keccak256(bytes(status)) == keccak256("Buying") ||
            keccak256(bytes(status)) == keccak256("Selling");
    }
    function initiateTransaction(
        address _sender,
        address receiver,
        uint _energyAmount,
        uint _price,
        uint _validUntil,
        bool isBuyTransaction
    ) public {
        require(
            userManager.isUserRegistered(_sender),
            "Initiator is not registered."
        );
        require(
            userManager.isUserRegistered(receiver),
            "Receiver is not registered."
        );
        require(
            _validUntil > block.timestamp,
            "Transaction expiration must be in the future."
        );

        if (isBuyTransaction) {
            require(
                userManager.getTokenBalance(_sender) >= _price,
                "Sender has insufficient tokens for transaction."
            );
            require(
                userManager.getEnergyBalance(receiver) >= _energyAmount,
                "Receiver does not have enough energy."
            );
        } else {
            require(
                userManager.getEnergyBalance(_sender) >= _energyAmount,
                "Sender has insufficient energy for transaction."
            );
            require(
                userManager.getTokenBalance(receiver) >= _price,
                "Receiver has insufficient tokens for transaction."
            );
        }

        uint transactionId = nextTransactionId++;
        transactions[transactionId] = Transaction(
            transactionId,
            _sender,
            receiver,
            _energyAmount,
            _price,
            _validUntil,
            false,
            "Pending",
            block.timestamp,
            isBuyTransaction ? TransactionType.Buy : TransactionType.Sell
        );
        pendingTransactions.push(transactionId);
        emit TransactionInitiated(
            transactionId,
            receiver,
            isBuyTransaction ? TransactionType.Buy : TransactionType.Sell
        );
    }

    function approveTokens(uint256 amount) public {
        userManager.approveTokens(address(this), amount);
    }

    function getUserTokenBalance(
        address userAddress
    ) public view returns (uint256) {
        return userManager.getTokenBalance(userAddress);
    }

    function commitTransaction(uint _transactionId, bool _accepted) public {
        require(
            _transactionId < nextTransactionId &&
                transactions[_transactionId].id != 0,
            "Transaction does not exist."
        );
        require(
            !transactions[_transactionId].committed,
            "Transaction already committed."
        );
        if (block.timestamp > transactions[_transactionId].validUntil) {
            transactions[_transactionId].committed = true;
            transactions[_transactionId].status = "Rejected due to expiration";
            emit TransactionCommitted(
                _transactionId,
                false,
                "Rejected due to expiration"
            );
            removePendingTransaction(_transactionId);
            return;
        }

        transactions[_transactionId].committed = true;
        transactions[_transactionId].status = _accepted
            ? "Accepted"
            : "Rejected";

        if (_accepted) {
            Transaction storage transaction = transactions[_transactionId];

            if (transaction.transactionType == TransactionType.Buy) {
                userManager.transferTokens(
                    transaction.initiator,
                    transaction.receiver,
                    transaction.price
                );
                userManager.updateTokenBalance(
                    transaction.initiator,
                    transaction.price,
                    false
                );
                userManager.updateTokenBalance(
                    transaction.receiver,
                    transaction.price,
                    true
                );
                userManager.updateEnergyBalance(
                    transaction.initiator,
                    transaction.energyAmount,
                    true
                );
                userManager.updateEnergyBalance(
                    transaction.receiver,
                    transaction.energyAmount,
                    false
                );
            } else {
                userManager.transferTokens(
                    transaction.receiver,
                    transaction.initiator,
                    transaction.price
                );
                userManager.updateTokenBalance(
                    transaction.initiator,
                    transaction.price,
                    true
                );
                userManager.updateTokenBalance(
                    transaction.receiver,
                    transaction.price,
                    false
                );
                userManager.updateEnergyBalance(
                    transaction.initiator,
                    transaction.energyAmount,
                    false
                );
                userManager.updateEnergyBalance(
                    transaction.receiver,
                    transaction.energyAmount,
                    true
                );
            }
        }
        removePendingTransaction(_transactionId);
        committedTransactions.push(_transactionId);

        userManager.resetTradingInfo(transactions[_transactionId].receiver);

        emit TransactionCommitted(
            _transactionId,
            _accepted,
            transactions[_transactionId].status
        );
    }

    function removePendingTransaction(uint _transactionId) private {
        for (uint i = 0; i < pendingTransactions.length; i++) {
            if (pendingTransactions[i] == _transactionId) {
                pendingTransactions[i] = pendingTransactions[
                    pendingTransactions.length - 1
                ];
                pendingTransactions.pop();
                break;
            }
        }
    }
    function getNumberOfNotCommittedTransactions() public view returns (uint) {
        return pendingTransactions.length;
    }

    function getAllPendingTransactions()
        public
        view
        returns (Transaction[] memory)
    {
        Transaction[] memory pendingData = new Transaction[](
            pendingTransactions.length
        );
        for (uint i = 0; i < pendingTransactions.length; i++) {
            pendingData[i] = transactions[pendingTransactions[i]];
        }
        return pendingData;
    }

    function getAllCommittedTransactions()
        public
        view
        returns (Transaction[] memory)
    {
        Transaction[] memory committedData = new Transaction[](
            committedTransactions.length
        );
        for (uint i = 0; i < committedTransactions.length; i++) {
            committedData[i] = transactions[committedTransactions[i]];
        }
        return committedData;
    }
    function getNotCommittedTransactionsCount(
        address userAddress
    ) public view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < pendingTransactions.length; i++) {
            Transaction storage transaction = transactions[
                pendingTransactions[i]
            ];
            if (transaction.receiver == userAddress && !transaction.committed) {
                count++;
            }
        }
        return count;
    }
    function getUserPendingTransactions(
        address userAddress
    ) public view returns (uint[] memory) {
        uint[] memory temp = new uint[](pendingTransactions.length);
        uint count = 0;

        for (uint i = 0; i < pendingTransactions.length; i++) {
            if (
                transactions[pendingTransactions[i]].initiator == userAddress ||
                transactions[pendingTransactions[i]].receiver == userAddress
            ) {
                temp[count] = pendingTransactions[i];
                count++;
            }
        }

        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }
    function getUserCommittedTransactions(
        address userAddress
    ) public view returns (uint[] memory) {
        uint[] memory temp = new uint[](committedTransactions.length);
        uint count = 0;

        for (uint i = 0; i < committedTransactions.length; i++) {
            Transaction storage transaction = transactions[
                committedTransactions[i]
            ];
            if (
                transaction.initiator == userAddress ||
                transaction.receiver == userAddress
            ) {
                temp[count] = committedTransactions[i];
                count++;
            }
        }

        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }

    function getAllUserTransactions(
        address userAddress
    ) public view returns (uint[] memory) {
        uint[] memory temp = new uint[](nextTransactionId - 1);
        uint count = 0;

        for (uint i = 1; i < nextTransactionId; i++) {
            if (
                transactions[i].initiator == userAddress ||
                transactions[i].receiver == userAddress
            ) {
                temp[count] = i;
                count++;
            }
        }

        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }
}
