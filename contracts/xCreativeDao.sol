// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
import { IOracle } from "./interfaces/IOracle.sol";


contract DAO is IGovernance {

    address public community;
    IERC20 public xCreative;
    IOracle public priceOracle;

    mapping(address => bool) public erc721Contracts;

    /*Goverment parameters*/
    uint256 internal _burnRate;
    uint256 internal _unwrap;

    constructor(IERC20 xcrt, IOracle oracle, uint256 burnRate, uint256 unwrapRate) {
        require(burnRate >= 0 && burnRate <= 100, "xCreative: Burn rate [0 - 100]");
        require(unwrapRate >= 0 && burnRate <= 100, "xCreative: Unwrap rate [0 - 100]");
        community = msg.sender;
        xCreative = xcrt;
        priceOracle = oracle;
        _burnRate = burnRate;
        _unwrap = unwrapRate;
    }

    function whitelistERC721(address tokenAddress) external onlyCommunity {
        erc721Contracts[tokenAddress] = true;
    }

    function getTokenPrice() external override view returns(uint256 ethPrice) {
        return priceOracle.ETHPriceOfERC20(address(xCreative));
    }

    function burnTransferRate(address from, uint256 price) external override managedERC721 {
        xCreative.burn(from, price 
    }

    //To unwrap the token the DAO asks for a fee
    function burnUnwrapRate(address from, uint256 price) external override managedERC721 {
    }

    function claimToken(address wrapId) external override {
    }

    modifier managedERC721() {
        require(erc721Contracts[msg.sender], "xDAO: not managed contract");
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == community, "xDAO: not community call");
        _;
    }
}
