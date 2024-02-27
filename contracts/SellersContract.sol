// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Main.sol"; // Ensure this path matches your project structure
import "./BuyersContract.sol"; // Ensure this path matches your project structure

contract SellersContract {
    Main mainContract;
    IERC20 paymentToken;
    BuyersContract buyersContract;

    struct SellingOffer {
        uint256 id;
        address seller;
        uint256 amount;
        uint256 pricePerUnit;
        uint256 datePlaced;
        string location;
        bool isActive;
    }

    mapping(uint256 => SellingOffer) public sellingOffers;
    uint256 private nextOfferId;

    event OfferCreated(
        uint256 indexed id,
        address indexed seller,
        uint256 amount,
        uint256 pricePerUnit,
        uint256 datePlaced,
        string location
    );
    event OfferCancelled(uint256 indexed id);
    event OfferUpdated(
        uint256 indexed id,
        uint256 remainingAmount,
        bool isActive
    );
    event OfferCompleted(uint256 indexed id);

    constructor(
        address _mainContractAddress,
        address _paymentTokenAddress,
        address _buyersContractAddress
    ) {
        mainContract = Main(_mainContractAddress);
        paymentToken = IERC20(_paymentTokenAddress);
        buyersContract = BuyersContract(_buyersContractAddress);
        nextOfferId = 1;
    }

    function createSellingOffer(uint256 _amount) public {
        (, , uint256 energyBalance, , ) = mainContract.getUserInfo(msg.sender);
        require(_amount <= energyBalance, "Insufficient energy balance");

        (, string memory location, , , ) = mainContract.getUserInfo(msg.sender);
        uint256 pricePerUnit = calculatePricePerUnit(_amount);

        uint256 offerId = nextOfferId++;
        sellingOffers[offerId] = SellingOffer({
            id: offerId,
            seller: msg.sender,
            amount: _amount,
            pricePerUnit: pricePerUnit,
            datePlaced: block.timestamp,
            location: location,
            isActive: true
        });

        emit OfferCreated(
            offerId,
            msg.sender,
            _amount,
            pricePerUnit,
            block.timestamp,
            location
        );
    }

    function cancelSellingOffer(uint256 _offerId) public {
        require(
            sellingOffers[_offerId].seller != address(0),
            "Offer does not exist"
        );
        require(
            sellingOffers[_offerId].seller == msg.sender,
            "Only the seller can cancel this offer"
        );
        require(sellingOffers[_offerId].isActive, "Offer is already inactive");

        sellingOffers[_offerId].isActive = false;
        emit OfferCancelled(_offerId);
    }

    function updateRemainingEnergy(
        uint256 offerId,
        uint256 purchasedAmount,
        uint256 buyingContractId
    ) public {
        SellingOffer storage offer = sellingOffers[offerId];
        require(offer.isActive, "Offer is not active");
        require(purchasedAmount <= offer.amount, "Not enough energy available");
        // Ensure the seller is calling this function or a designated administrator
        require(
            msg.sender == offer.seller || msg.sender == address(this),
            "Unauthorized"
        );

        // Simulate transferring funds to the seller and updating energy balances
        uint256 totalCost = purchasedAmount * offer.pricePerUnit;
        require(
            paymentToken.transferFrom(
                buyersContract.getBuyer(buyingContractId),
                offer.seller,
                totalCost
            ),
            "Payment transfer failed"
        );

        // Assuming the Main contract has functions to securely update energy balances
        mainContract.decreaseEnergyBalance(offer.seller, purchasedAmount);
        mainContract.increaseEnergyBalance(
            buyersContract.getBuyer(buyingContractId),
            purchasedAmount
        );

        offer.amount -= purchasedAmount;
        if (offer.amount == 0) {
            offer.isActive = false;
            emit OfferCompleted(offerId);
        } else {
            emit OfferUpdated(offerId, offer.amount, offer.isActive);
        }

        // Assuming BuyersContract has a public function to finalize a buying contract
        buyersContract.finalizeBuyingContract(buyingContractId);
    }

    function calculatePricePerUnit(
        uint256 _amount
    ) private pure returns (uint256) {
        // Placeholder for actual pricing logic
        return 1; // Example fixed price per unit
    }

    // Additional helper functions and event declarations as needed...

    // The below functions are placeholders for the required functionality. Implement them as per your project's needs.
    function getOfferDetails(
        uint256 offerId
    )
        public
        view
        returns (
            uint256 id,
            address seller,
            uint256 amount,
            uint256 pricePerUnit,
            uint256 datePlaced,
            string memory location,
            bool isActive
        )
    {
        require(offerId < nextOfferId, "Invalid offer ID");
        SellingOffer storage offer = sellingOffers[offerId];
        return (
            offer.id,
            offer.seller,
            offer.amount,
            offer.pricePerUnit,
            offer.datePlaced,
            offer.location,
            offer.isActive
        );
    }

    function getUserInfo(
        address user
    )
        public
        view
        returns (
            string memory username,
            string memory location,
            uint256 energyBalance,
            uint256 tokenBalance,
            bool isRegistered
        )
    {
        // Assuming the Main contract has a function `getUserDetails` that returns the necessary information
        return mainContract.getUserDetails(user);
    }
}
