//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Auction is Ownable, ERC721, ERC721Enumerable {

    error Auction__notStarted();
    error Auction__auctionEnded();
    error Auction__overSupply();
    error Auction__insufficientValue();
    error Auction__withDrawFailed();


    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public constant AUCTION_START_PRICE = 1 ether;
    uint256 public constant AUCTION_FLOOR_PRICE = 0.01 ether;
    uint256 public constant AUCTION_INTERVAL = 10 minutes;
    uint256 public constant AUCTION_STEP = (AUCTION_START_PRICE - AUCTION_FLOOR_PRICE) / (AUCTION_DURATION / AUCTION_INTERVAL);

    uint256 public auctionStartTime;

    constructor() Ownable(msg.sender) ERC721("Auction", "AUC") {
        auctionStartTime = block.timestamp;
    }

    /**
     * @dev Set the auction start time
     */
    function setAuctionStartTime(uint256 _auctionStartTime) external onlyOwner {
        auctionStartTime = _auctionStartTime;
    }

    /**
     * @dev Get the auction current price
     */
    function getAuctionPrice() public view returns (uint256) {
    
        if(block.timestamp <= auctionStartTime){
            return AUCTION_START_PRICE;
        }else if (block.timestamp >= auctionStartTime + AUCTION_DURATION) {
            return AUCTION_FLOOR_PRICE;
        }else {
            uint256 price = AUCTION_START_PRICE - AUCTION_STEP * (block.timestamp - auctionStartTime) / AUCTION_INTERVAL;
            if (price < AUCTION_FLOOR_PRICE) {
                return AUCTION_FLOOR_PRICE;
            }
        }
    }

    /**
     * @dev Mint the NFT after the auction
     */
    function mint(uint256 quantity) external payable {
        //check the auction time
        if(block.timestamp < auctionStartTime ) {
            revert Auction__notStarted();
        }

        if(MAX_SUPPLY <= totalSupply() + quantity) {
            revert Auction__overSupply();
        }

        uint256 totalCost = getAuctionPrice() * quantity;
        if(msg.value < totalCost) {
           revert Auction__insufficientValue();
        } 

        //mint the NFT by using the ERC721 mint function
        for(uint256 i = 0; i < quantity; i++) {
            _mint(msg.sender, totalSupply() + i);
        } 

    }

    function withDraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if(!success){
            revert Auction__withDrawFailed();
        }
    }

}