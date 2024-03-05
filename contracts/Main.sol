// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Main {
    struct UserInfo {
        string username;
        int256 latitude;
        int256 longitude; 
        uint256 energyBalance; 
        uint256 tokensBalance; 
        bool isRegistered;
    }

    address[] private userAddresses;
    mapping(address => UserInfo) public users; // Changed to public for direct access if needed
    address public admin;

    event UserRegistered(address indexed userAddress, string username, int256 latitude, int256 longitude, uint256 energyBalance, uint256 tokensBalance);
    event UserUpdated(address indexed userAddress, string username, int256 latitude, int256 longitude, uint256 energyBalance, uint256 tokensBalance);
    event UserDeleted(address indexed userAddress);

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
