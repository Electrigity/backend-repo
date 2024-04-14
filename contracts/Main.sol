// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Main {
    struct UserInfo {
        string username;
        int256 latitude;
        int256 longitude; 
        uint256 energyBalance; 
        uint256 tokensBalance; 
        bool isRegistered;
    }

    struct TradingInfo {
        uint256 userId; // Foreign key to the user's ID
        string tradingStatus;
        uint256 buySellAmount;
        uint256 price;
        uint256 expiryDate; // Represented as a Unix timestamp
    }

     address[] private userAddresses;
    mapping(address => UserInfo) public users; 
    mapping(address => TradingInfo) public tradingInfos; // New mapping for TradingInfo
    address public admin;

    event UserRegistered(address indexed userAddress, string username, int256 latitude, int256 longitude, uint256 energyBalance, uint256 tokensBalance);
    event UserUpdated(address indexed userAddress, string username, int256 latitude, int256 longitude, uint256 energyBalance, uint256 tokensBalance);
    event UserDeleted(address indexed userAddress);

    event SellingTradingInfoUpdated(
    address indexed userAddress,
    string tradingStatus,
    uint256 expiryDate,
    uint256 buySellAmount,
    uint256 price
);

event BuyingTradingInfoUpdated(
    address indexed userAddress,
    string tradingStatus,
    uint256 expiryDate
);



    constructor() {
        admin = msg.sender; // The creator of the contract is the admin
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this.");
        _;
    }

    modifier notRegistered() {
        require(!users[msg.sender].isRegistered, "User already registered.");
        _;
    }

    function registerUser(string memory _username, int256 _latitude, int256 _longitude, uint256 _energyBalance, uint256 _tokensBalance) public notRegistered {
        UserInfo storage newUser = users[msg.sender];
        newUser.username = _username;
        newUser.latitude = _latitude;
        newUser.longitude = _longitude;
        newUser.energyBalance = _energyBalance;
        newUser.tokensBalance = _tokensBalance;
        newUser.isRegistered = true;

        userAddresses.push(msg.sender);
        emit UserRegistered(msg.sender, _username, _latitude, _longitude, _energyBalance, _tokensBalance);
        initializeTradingInfo(msg.sender);
    }

     function initializeTradingInfo(address userAddress) internal {
        TradingInfo storage newTradingInfo = tradingInfos[userAddress];
        newTradingInfo.userId = uint256(uint160(userAddress)); // Simple conversion from address to uint256
        newTradingInfo.tradingStatus = "NotTrading";
        newTradingInfo.buySellAmount = 0;
        newTradingInfo.price = 0;
        newTradingInfo.expiryDate = 0; // Set to 0 to indicate uninitialized
    }

    function getTradingInfoByUserId(uint256 userId) public view returns (TradingInfo memory) {
        address userAddress = address(uint160(userId));
        require(users[userAddress].isRegistered, "User is not registered.");

        return tradingInfos[userAddress];
    }

    function updateSellerUserInfo(
        uint256 userId, 
        string memory _tradingStatus, 
        uint256 _expiryDate, 
        uint256 _buySellAmount, 
        uint256 _price
    ) 
        public 
    {
        address userAddress = address(uint160(userId));
        require(users[userAddress].isRegistered, "User is not registered.");

        TradingInfo storage userTradingInfo = tradingInfos[userAddress];
        userTradingInfo.tradingStatus = _tradingStatus;
        userTradingInfo.expiryDate = _expiryDate;
        userTradingInfo.buySellAmount = _buySellAmount;
        userTradingInfo.price = _price;

        // Emit an event if necessary, for example:
        emit SellingTradingInfoUpdated(userAddress, _tradingStatus, _expiryDate, _buySellAmount, _price);
    }


    function updateBuyerUserInfo(
        uint256 userId, 
        string memory _tradingStatus, 
        uint256 _expiryDate
    ) 
        public 
    {
        address userAddress = address(uint160(userId));
        require(users[userAddress].isRegistered, "User is not registered.");

        TradingInfo storage userTradingInfo = tradingInfos[userAddress];
        userTradingInfo.tradingStatus = _tradingStatus;
        userTradingInfo.expiryDate = _expiryDate;

        // Emit an event if necessary, for example:
        emit BuyingTradingInfoUpdated(userAddress, _tradingStatus, _expiryDate);
    }



    function updateUser(string memory _username, int256 _latitude, int256 _longitude, uint256 _energyBalance, uint256 _tokensBalance) public {
        require(users[msg.sender].isRegistered, "User is not registered.");

        UserInfo storage user = users[msg.sender];
        user.username = _username;
        user.latitude = _latitude;
        user.longitude = _longitude;
        user.energyBalance = _energyBalance;
        user.tokensBalance = _tokensBalance;

        emit UserUpdated(msg.sender, _username, _latitude, _longitude, _energyBalance, _tokensBalance);
    }

    function deleteUser(address _userAddress) public onlyAdmin {
        require(users[_userAddress].isRegistered, "User is not registered.");

        delete users[_userAddress];
        emit UserDeleted(_userAddress);

        // Remove address from userAddresses array
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _userAddress) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }
    }

    function getUserInfo(address _userAddress) public view returns (UserInfo memory userInfo) {
        require(users[_userAddress].isRegistered, "User is not registered.");
        return users[_userAddress];
    }


    function getAllUsersInfo() public view returns (UserInfo[] memory) {
        UserInfo[] memory infos = new UserInfo[](userAddresses.length);
        for (uint i = 0; i < userAddresses.length; i++) {
            address userAddr = userAddresses[i];
            infos[i] = users[userAddr];
        }
        return infos;
    }
    
    // Helper function to check if the user is registered
    function isUserRegistered(address _userAddress) public view returns (bool) {
        return users[_userAddress].isRegistered;
    }

    // Helper function to get the list of user addresses (only accessible by admin)
    function getUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }
}
