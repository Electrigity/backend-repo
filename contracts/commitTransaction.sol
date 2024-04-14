// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.16;

// interface IMain {
//     function updateEnergyBalance(
//         address _userAddress,
//         uint256 _newEnergyBalance
//     ) external;

//     function getUserInfo(
//         address _userAddress
//     )
//         external
//         view
//         returns (string memory, int256, int256, uint256, uint256, bool);
// }

// contract EnergyTradingContract {
//     IMain mainContract;

//     constructor(address _mainContractAddress) {
//         mainContract = IMain(_mainContractAddress);
//     }

//     enum TransactionType {
//         Buy,
//         Sell
//     }

//     struct Transaction {
//         uint id;
//         address initiator;
//         address receiver;
//         uint energyAmount;
//         uint price;
//         uint validUntil;
//         bool committed;
//         string status;
//         TransactionType transactionType;
//     }

//     uint private nextTransactionId = 1;
//     mapping(uint => Transaction) public transactions;
//     uint[] public pendingTransactions;
//     uint[] private committedTransactions;

//     event TransactionInitiated(
//         uint transactionId,
//         address receiver,
//         TransactionType transactionType
//     );
//     event TransactionCommitted(
//         uint transactionId,
//         bool accepted,
//         string status
//     );

//     function initiateTransaction(
//         address _sender,
//         address receiver,
//         uint _energyAmount,
//         uint _price,
//         uint _validUntil,
//         bool isBuyTransaction
//     ) public {
//         uint transactionId = nextTransactionId++;
//         TransactionType transactionType = isBuyTransaction
//             ? TransactionType.Buy
//             : TransactionType.Sell;

//         transactions[transactionId] = Transaction(
//             transactionId,
//             _sender,
//             receiver,
//             _energyAmount,
//             _price,
//             _validUntil,
//             false,
//             "pending",
//             transactionType
//         );

//         pendingTransactions.push(transactionId);

//         emit TransactionInitiated(transactionId, receiver, transactionType);
//     }

//     function commitTransaction(uint _transactionId, bool _accepted) public {
//         transactions[_transactionId].committed = true;
//         transactions[_transactionId].status = _accepted
//             ? "Accepted"
//             : "Rejected";

//         committedTransactions.push(_transactionId);
//         for (uint i = 0; i < pendingTransactions.length; i++) {
//             if (pendingTransactions[i] == _transactionId) {
//                 pendingTransactions[i] = pendingTransactions[
//                     pendingTransactions.length - 1
//                 ];
//                 pendingTransactions.pop();
//                 break;
//             }
//         }
//         if (_accepted) {
//             Transaction storage transaction = transactions[_transactionId];

//             (, , , uint256 initiatorEnergyBalance, , ) = mainContract
//                 .getUserInfo(transaction.initiator);
//             (, , , uint256 receiverEnergyBalance, , ) = mainContract
//                 .getUserInfo(transaction.receiver);

//             if (transaction.transactionType == TransactionType.Buy) {
//                 initiatorEnergyBalance += transaction.energyAmount;
//                 receiverEnergyBalance -= transaction.energyAmount;
//             } else if (transaction.transactionType == TransactionType.Sell) {
//                 initiatorEnergyBalance -= transaction.energyAmount;
//                 receiverEnergyBalance += transaction.energyAmount;
//             }

//             mainContract.updateEnergyBalance(
//                 transaction.initiator,
//                 initiatorEnergyBalance
//             );
//             mainContract.updateEnergyBalance(
//                 transaction.receiver,
//                 receiverEnergyBalance
//             );
//         }

//         emit TransactionCommitted(
//             _transactionId,
//             _accepted,
//             transactions[_transactionId].status
//         );
//     }

//     function getNumberOfNotCommittedTransactions() public view returns (uint) {
//         return pendingTransactions.length;
//     }

//     function getAllPendingTransactions()
//         public
//         view
//         returns (Transaction[] memory)
//     {
//         Transaction[] memory pendingData = new Transaction[](
//             pendingTransactions.length
//         );
//         for (uint i = 0; i < pendingTransactions.length; i++) {
//             pendingData[i] = transactions[pendingTransactions[i]];
//         }
//         return pendingData;
//     }
//     function getAllCommittedTransactions()
//         public
//         view
//         returns (Transaction[] memory)
//     {
//         Transaction[] memory committedData = new Transaction[](
//             committedTransactions.length
//         );
//         for (uint i = 0; i < committedTransactions.length; i++) {
//             committedData[i] = transactions[committedTransactions[i]];
//         }
//         return committedData;
//     }
//     function retrieveUserInfo(
//         address _userAddress
//     )
//         public
//         view
//         returns (string memory, int256, int256, uint256, uint256, bool)
//     {
//         return mainContract.getUserInfo(_userAddress);
//     }
// }
