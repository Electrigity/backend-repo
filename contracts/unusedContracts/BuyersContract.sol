// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "./Main.sol"; // Adjust the import path as necessary
// import "./SellersContract.sol"; // Adjust the import path as necessary

// contract BuyersContract {
//     IERC20 public paymentToken;
//     SellersContract public sellersContract;
//     Main public mainContract;

//     struct BuyingContract {
//         uint256 id;
//         address buyer;
//         address seller;
//         uint256 offerId;
//         uint256 amountPurchased;
//         uint256 pricePerUnit;
//         bool finalized; // This will be set to true in the SellersContract
//     }

//     uint256 private nextBuyingContractId;
//     mapping(uint256 => BuyingContract) public buyingContracts;
//     mapping(address => uint256[]) public buyerToContracts;
//     mapping(address => uint256[]) public sellerToContracts;

//     event BuyingContractCreated(
//         uint256 indexed id,
//         address buyer,
//         address seller,
//         uint256 offerId,
//         uint256 amount,
//         uint256 pricePerUnit
//     );
//     event BuyingContractFinalized(uint256 indexed id, bool finalized);

//     constructor(
//         address _paymentTokenAddress,
//         address _sellersContractAddress,
//         address _mainContractAddress
//     ) {
//         paymentToken = IERC20(_paymentTokenAddress);
//         sellersContract = SellersContract(_sellersContractAddress);
//         mainContract = Main(_mainContractAddress);
//         nextBuyingContractId = 1;
//     }

//     function createBuyingContract(
//         address seller,
//         uint256 offerId,
//         uint256 amount,
//         uint256 pricePerUnit
//     ) public {
//         // Token transfer logic should be handled here or within the function calling this to ensure payment is secured before creating the contract
//         uint256 contractId = nextBuyingContractId++;
//         buyingContracts[contractId] = BuyingContract({
//             id: contractId,
//             buyer: msg.sender,
//             seller: seller,
//             offerId: offerId,
//             amountPurchased: amount,
//             pricePerUnit: pricePerUnit,
//             finalized: false // Initial state, to be finalized in SellersContract
//         });

//         buyerToContracts[msg.sender].push(contractId);
//         sellerToContracts[seller].push(contractId);

//         emit BuyingContractCreated(
//             contractId,
//             msg.sender,
//             seller,
//             offerId,
//             amount,
//             pricePerUnit
//         );
//     }

//     // This function is now primarily for record-keeping; actual finalization logic will be handled in SellersContract
//     function markBuyingContractAsFinalized(uint256 contractId) internal {
//         BuyingContract storage bContract = buyingContracts[contractId];
//         require(!bContract.finalized, "Contract already finalized");
//         bContract.finalized = true;
//         emit BuyingContractFinalized(contractId, true);
//     }

//     function getBuyerContracts(
//         address buyer
//     ) public view returns (uint256[] memory) {
//         return buyerToContracts[buyer];
//     }

//     function getSellerContracts(
//         address seller
//     ) public view returns (uint256[] memory) {
//         return sellerToContracts[seller];
//     }

//     // Additional helper functions for interacting with the contracts...
//     // Note: Consider including functionality for safely handling token transfers, including pre-approval checks and transferFrom calls.
// }
