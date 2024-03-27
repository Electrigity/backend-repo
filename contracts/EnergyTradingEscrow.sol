// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EnergyTradingPlatform {
    struct UserInfo {
        string username;
        int256 latitude;
        int256 longitude;
        uint256 energyBalance;
        uint256 tokensBalance;
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
        uint256 energyBalance,
        uint256 tokensBalance
    );
    event UserUpdated(
        address indexed userAddress,
        string username,
        int256 latitude,
        int256 longitude,
        uint256 energyBalance,
        uint256 tokensBalance
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

    constructor() {
        admin = msg.sender;
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
        uint256 _energyBalance,
        uint256 _tokensBalance
    ) public notRegistered {
        UserInfo storage newUser = users[msg.sender];
        newUser.username = _username;
        newUser.latitude = _latitude;
        newUser.longitude = _longitude;
        newUser.energyBalance = _energyBalance;
        newUser.tokensBalance = _tokensBalance;
        newUser.isRegistered = true;

        userAddresses.push(msg.sender);
        emit UserRegistered(
            msg.sender,
            _username,
            _latitude,
            _longitude,
            _energyBalance,
            _tokensBalance
        );
    }

    function updateUser(
        string memory _username,
        int256 _latitude,
        int256 _longitude,
        uint256 _energyBalance,
        uint256 _tokensBalance
    ) public {
        require(users[msg.sender].isRegistered, "User is not registered.");
        UserInfo storage user = users[msg.sender];
        user.username = _username;
        user.latitude = _latitude;
        user.longitude = _longitude;
        user.energyBalance = _energyBalance;
        user.tokensBalance = _tokensBalance;
        emit UserUpdated(
            msg.sender,
            _username,
            _latitude,
            _longitude,
            _energyBalance,
            _tokensBalance
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
                users[_sender].tokensBalance >= _price,
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
                users[receiver].tokensBalance >= _price,
                "Receiver has insufficient tokens to buy energy."
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
                users[transaction.initiator].tokensBalance -= transaction.price;
                users[transaction.receiver].tokensBalance += transaction.price;

                users[transaction.initiator].energyBalance += transaction
                    .energyAmount;
                users[transaction.receiver].energyBalance -= transaction
                    .energyAmount;
            } else if (transaction.transactionType == TransactionType.Sell) {
                users[transaction.initiator].tokensBalance += transaction.price;
                users[transaction.receiver].tokensBalance -= transaction.price;

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

    function updateEnergyBalance(
        address _userAddress,
        uint256 _newEnergyBalance
    ) public {
        require(users[_userAddress].isRegistered, "User is not registered.");
        users[_userAddress].energyBalance = _newEnergyBalance;
    }
}
