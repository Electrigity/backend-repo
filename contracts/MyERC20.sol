// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MyERC20 is ERC20 {
    using Address for address;

    constructor() ERC20("EnergyToken", "EGY") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public {
        bool sent = transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}
