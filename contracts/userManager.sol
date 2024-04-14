// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MyERC20.sol";

contract UserManager {
    MyERC20 public token;

    struct UserInfo {
        address userAddress;
        string username;
        uint256 EGYTokenBalance;
        int latitude;
        int longitude;
        uint256 energyBalance;
        bool isRegistered;
    }
    struct TradingInfo {
        address userAddress;
        string tradingStatus;
        uint256 buySellAmount;
        uint256 price;
        uint256 expiryDate;
    }

    address[] private userAddresses;
    mapping(address => UserInfo) public users;
    address public admin;
    mapping(address => TradingInfo) public tradingInfos;

    event UserRegistered(
        address indexed userAddress,
        string username,
        int latitude,
        int longitude,
        uint256 energyBalance
    );
    event UserUpdated(
        address indexed userAddress,
        string username,
        int latitude,
        int longitude,
        uint256 energyBalance
    );
    event UserDeleted(address indexed userAddress);

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
        int _latitude,
        int _longitude,
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
        initializeTradingInfo(msg.sender);
    }

    function updateUser(
        string memory _username,
        int _latitude,
        int _longitude,
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

    function getUserInfoAll(
        address user
    )
        public
        view
        returns (
            address userAddress,
            string memory username,
            uint256 EGYTokenBalance,
            int latitude,
            int longitude,
            uint256 energyBalance,
            bool isRegistered
        )
    {
        UserInfo storage info = users[user];
        return (
            info.userAddress,
            info.username,
            info.EGYTokenBalance,
            info.latitude,
            info.longitude,
            info.energyBalance,
            info.isRegistered
        );
    }

    function getUserTokenBalance(
        address userAddress
    ) public view returns (uint256) {
        return token.balanceOf(userAddress);
    }
    function initializeTradingInfo(address userAddress) internal {
        TradingInfo storage newTradingInfo = tradingInfos[userAddress];
        newTradingInfo.userAddress = userAddress;
        newTradingInfo.tradingStatus = "NotTrading";
        newTradingInfo.buySellAmount = 0;
        newTradingInfo.price = 0;
        newTradingInfo.expiryDate = 0;
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
    function updateEnergyBalance(
        address _userAddress,
        uint256 _newEnergyBalance
    ) public {
        require(users[_userAddress].isRegistered, "User is not registered.");
        users[_userAddress].energyBalance = _newEnergyBalance;
    }

    function getEnergyBalance(address user) public view returns (uint256) {
        return users[user].energyBalance;
    }
    function approveTokens(address spender, uint256 amount) public {
        require(
            msg.sender == admin,
            "Only admin can approve tokens for spending."
        );
        token.approve(spender, amount);
    }

    function getTokenBalance(address user) public view returns (uint256) {
        return token.balanceOf(user);
    }
    function transferTokens(address from, address to, uint256 amount) public {
        require(
            isUserRegistered(from) && isUserRegistered(to),
            "Both parties must be registered"
        );
        token.transferFrom(from, to, amount);
    }

    function updateEnergyBalance(
        address user,
        uint256 amount,
        bool increase
    ) public {
        require(isUserRegistered(user), "User must be registered");
        if (increase) {
            users[user].energyBalance += amount;
        } else {
            users[user].energyBalance -= amount;
        }
    }

    function updateTokenBalance(
        address user,
        uint256 amount,
        bool increase
    ) public {
        if (increase) {
            users[user].EGYTokenBalance += amount;
        } else {
            users[user].EGYTokenBalance -= amount;
        }
    }
}
