// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "./SellersContract.sol";
// import "./BuyersContract.sol";

// contract Transactions {
//     struct SellingOfferRecord {
//         uint256 id;
//         address seller;
//         uint256 timestamp;
//         bool isActive;
//     }

//     struct BuyingOfferRecord {
//         uint256 id;
//         address buyer;
//         uint256 timestamp;
//         bool isFinalized;
//     }

//     uint256 public currentDay = block.timestamp / 1 days;

//     // Mapping from day to selling and buying offer records
//     mapping(uint256 => SellingOfferRecord[]) public dailySellingOffers;
//     mapping(uint256 => BuyingOfferRecord[]) public dailyBuyingOffers;

//     // Mapping from user address to their selling and buying offer IDs
//     mapping(address => uint256[]) public userSellingOffers;
//     mapping(address => uint256[]) public userBuyingOffers;

//     // References to the SellersContract and BuyersContract
//     SellersContract sellersContract;
//     BuyersContract buyersContract;

//     constructor(
//         address _sellersContractAddress,
//         address _buyersContractAddress
//     ) {
//         sellersContract = SellersContract(_sellersContractAddress);
//         buyersContract = BuyersContract(_buyersContractAddress);
//     }

//     // Function to add selling offers
//     function addSellingOffer(uint256 offerId, address seller) external {
//         updateCurrentDay();
//         dailySellingOffers[currentDay].push(
//             SellingOfferRecord({
//                 id: offerId,
//                 seller: seller,
//                 timestamp: block.timestamp,
//                 isActive: true
//             })
//         );
//         userSellingOffers[seller].push(offerId);
//     }

//     // Function to add buying offers
//     function addBuyingOffer(uint256 offerId, address buyer) external {
//         updateCurrentDay();
//         dailyBuyingOffers[currentDay].push(
//             BuyingOfferRecord({
//                 id: offerId,
//                 buyer: buyer,
//                 timestamp: block.timestamp,
//                 isFinalized: false
//             })
//         );
//         userBuyingOffers[buyer].push(offerId);
//     }

//     // Function to finalize buying offers
//     function finalizeBuyingOffer(uint256 offerId) external {
//         // Implementation to mark a buying offer as finalized
//     }

//     // Function to get all selling contracts created by a certain user
//     function getSellingOffersByUser(
//         address user
//     ) public view returns (SellingOfferRecord[] memory) {
//         // Implementation
//     }

//     // Function to get all buying offers created by a certain user
//     function getBuyingOffersByUser(
//         address user
//     ) public view returns (BuyingOfferRecord[] memory) {
//         // Implementation
//     }

//     // Function to get all active selling contracts
//     function getActiveSellingOffers()
//         public
//         view
//         returns (SellingOfferRecord[] memory)
//     {
//         // Implementation
//     }

//     // Utility function to handle the transition between days
//     function updateCurrentDay() internal {
//         uint256 today = block.timestamp / 1 days;
//         if (today > currentDay) {
//             currentDay = today;
//         }
//     }
// }
