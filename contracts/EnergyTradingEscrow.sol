// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MyERC20.sol";

contract EnergyTradingPlatform {
    MyERC20 public token;

    struct UserInfo {
        address userAddress;
        string username;
        uint256 EGYTokenBalance;
        int256 latitude;
        int256 longitude;
        uint256 energyBalance;
        bool isRegistered;
    }

    struct Transaction {
        uint id;
        address initiator;
        address receiver;
        uint energyAmount;
        uint price;
        uint validUntil;
        bool committed;
        string status;
        TransactionType transactionType;
    }

    enum TransactionType {
        Buy,
        Sell
    }

    address[] private userAddresses;
    mapping(address => UserInfo) public users;
    address public admin;
    uint private nextTransactionId = 1;
    mapping(uint => Transaction) public transactions;
    uint[] public pendingTransactions;
    uint[] private committedTransactions;

    event UserRegistered(
        address indexed userAddress,
        string username,
        int256 latitude,
        int256 longitude,
        uint256 energyBalance
    );
    event UserUpdated(
        address indexed userAddress,
        string username,
        int256 latitude,
        int256 longitude,
        uint256 energyBalance
    );
    event UserDeleted(address indexed userAddress);
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

    constructor(address tokenAddress) {
        admin = msg.sender;
        token = MyERC20(tokenAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this.");
        _;
    }

    modifier notRegistered() {
        require(!users[msg.sender].isRegistered, "User already registered.");
        _;
    }
    function registerUser(
        string memory _username,
        int256 _latitude,
        int256 _longitude,
        uint256 _energyBalance
    ) public notRegistered {
        UserInfo storage newUser = users[msg.sender];
        newUser.userAddress = msg.sender;
        newUser.username = _username;
        newUser.latitude = _latitude;
        newUser.longitude = _longitude;
        newUser.energyBalance = _energyBalance;
        newUser.isRegistered = true;
        newUser.EGYTokenBalance = 20 * (10 ** uint256(token.decimals()));
        userAddresses.push(msg.sender);

        token.mint(msg.sender, newUser.EGYTokenBalance);

        emit UserRegistered(
            msg.sender,
            _username,
            _latitude,
            _longitude,
            _energyBalance
        );
    }

    function updateUser(
        string memory _username,
        int256 _latitude,
        int256 _longitude,
        uint256 _energyBalance
    ) public {
        require(users[msg.sender].isRegistered, "User is not registered.");
        UserInfo storage user = users[msg.sender];
        user.username = _username;
        user.latitude = _latitude;
        user.longitude = _longitude;
        user.energyBalance = _energyBalance;
        emit UserUpdated(
            msg.sender,
            _username,
            _latitude,
            _longitude,
            _energyBalance
        );
    }

    function deleteUser(address _userAddress) public onlyAdmin {
        require(users[_userAddress].isRegistered, "User is not registered.");

        bool isUserFound = false;
        for (uint i = 0; i < userAddresses.length; ++i) {
            if (userAddresses[i] == _userAddress) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                isUserFound = true;
                break;
            }
        }
        require(isUserFound, "User address not found.");
        delete users[_userAddress];

        emit UserDeleted(_userAddress);
    }

    function initiateTransaction(
        address _sender,
        address receiver,
        uint _energyAmount,
        uint _price,
        uint _validUntil,
        bool isBuyTransaction
    ) public {
        require(users[_sender].isRegistered, "Initiator is not registered.");
        require(users[receiver].isRegistered, "Receiver is not registered.");
        require(
            _validUntil > block.timestamp,
            "Transaction expiration must be in the future."
        );

        if (isBuyTransaction) {
            require(
                token.balanceOf(_sender) >= _price,
                "Sender has insufficient tokens for transaction."
            );

            require(
                users[receiver].energyBalance >= _energyAmount,
                "Receiver does not have enough energy."
            );
        } else {
            require(
                users[_sender].energyBalance >= _energyAmount,
                "Sender has insufficient energy for transaction."
            );
            require(
                token.balanceOf(receiver) >= _price,
                "Sender has insufficient tokens for transaction."
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
        token.approve(address(this), amount);
    }

    function getUserTokenBalance(
        address userAddress
    ) public view returns (uint256) {
        return token.balanceOf(userAddress);
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
        removePendingTransaction(_transactionId);
        committedTransactions.push(_transactionId);

        if (_accepted) {
            Transaction storage transaction = transactions[_transactionId];

            if (transaction.transactionType == TransactionType.Buy) {
                require(
                    token.balanceOf(transaction.initiator) >= transaction.price,
                    "Initiator has insufficient EGY tokens."
                );
                require(
                    users[transaction.receiver].energyBalance >=
                        transaction.energyAmount,
                    "Receiver does not have enough energy."
                );
                token.transferFrom(
                    transaction.initiator,
                    transaction.receiver,
                    transaction.price
                );
                users[transaction.initiator].EGYTokenBalance -= transaction
                    .price;
                users[transaction.receiver].EGYTokenBalance += transaction
                    .price;

                users[transaction.initiator].energyBalance += transaction
                    .energyAmount;
                users[transaction.receiver].energyBalance -= transaction
                    .energyAmount;
            } else if (transaction.transactionType == TransactionType.Sell) {
                require(
                    token.balanceOf(transaction.receiver) >= transaction.price,
                    "Receiver has insufficient EGY tokens."
                );
                require(
                    users[transaction.initiator].energyBalance >=
                        transaction.energyAmount,
                    "Initiator does not have enough energy."
                );
                token.transferFrom(
                    transaction.receiver,
                    transaction.initiator,
                    transaction.price
                );
                users[transaction.initiator].EGYTokenBalance += transaction
                    .price;
                users[transaction.receiver].EGYTokenBalance -= transaction
                    .price;
                users[transaction.initiator].energyBalance -= transaction
                    .energyAmount;
                users[transaction.receiver].energyBalance += transaction
                    .energyAmount;
            }
        }

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

    function getUserInfo(
        address _userAddress
    ) public view returns (UserInfo memory userInfo) {
        require(users[_userAddress].isRegistered, "User is not registered.");
        return users[_userAddress];
    }

    function getAllUsersInfo() public view returns (UserInfo[] memory) {
        UserInfo[] memory infos = new UserInfo[](userAddresses.length);
        for (uint i = 0; i < userAddresses.length; i++) {
            infos[i] = users[userAddresses[i]];
        }
        return infos;
    }

    function isUserRegistered(address _userAddress) public view returns (bool) {
        return users[_userAddress].isRegistered;
    }

    function getUserAddresses() public view returns (address[] memory) {
        return userAddresses;
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
            if (
                transaction.initiator == userAddress && !transaction.committed
            ) {
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

    function updateEnergyBalance(
        address _userAddress,
        uint256 _newEnergyBalance
    ) public {
        require(users[_userAddress].isRegistered, "User is not registered.");
        users[_userAddress].energyBalance = _newEnergyBalance;
    }
}
