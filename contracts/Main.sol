// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Main {
    struct UserInfo {
        string username;
        string location; 
        uint256 energyBalance; 
        uint256 tokensBalance; 
        bool isRegistered;
    }

    mapping(address => UserInfo) public users;

    event UserRegistered(address userAddress, string username, string location, uint256 energyBalance, uint256 tokensBalance);
    event UserUpdated(address userAddress, string username, string location, uint256 energyBalance, uint256 tokensBalance);

    function registerOrUpdate(string memory _username, string memory _location, uint256 _energyBalance, uint256 _tokensBalance) public {
        UserInfo storage user = users[msg.sender];

        user.username = _username;
        user.location = _location;
        user.energyBalance = _energyBalance;
        user.tokensBalance = _tokensBalance;
        user.isRegistered = true;

        if (!user.isRegistered) {
            // If user is registering for the first time
            emit UserRegistered(msg.sender, _username, _location, _energyBalance, _tokensBalance);
        } else {
            // If user is updating their information
            emit UserUpdated(msg.sender, _username, _location, _energyBalance, _tokensBalance);
        }
    }

    function isUserRegistered(address _user) public view returns (bool) {
        return users[_user].isRegistered;
    }

    function getUserInfo(address _user) public view returns (string memory username, string memory location, uint256 energyBalance, uint256 tokensBalance) {
        require(users[_user].isRegistered, "User is not registered.");
        UserInfo storage user = users[_user];
        return (user.username, user.location, user.energyBalance, user.tokensBalance);
    }
}
