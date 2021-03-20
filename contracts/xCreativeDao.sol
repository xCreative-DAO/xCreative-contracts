// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { xIERC20 } from "./interfaces/xIERC20.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
import { IOracle } from "./interfaces/IOracle.sol";


contract xCreativeDAO is IGovernance {

    address public community;
    xIERC20 public xCreative;
    IOracle public priceOracle;

    mapping(address => bool) public erc721Contracts;

    /*Goverment parameters*/
    uint256 internal _burnRate;
    uint256 internal _unwrap;

    constructor(IOracle oracle, uint256 burnRate, uint256 unwrapRate) {
        require(burnRate >= 0 && burnRate <= 100, "xCreative: Burn rate [0 - 100]");
        require(unwrapRate >= 0 && burnRate <= 100, "xCreative: Unwrap rate [0 - 100]");
        community = msg.sender;
        priceOracle = oracle;
        _burnRate = burnRate;
        _unwrap = unwrapRate;
    }

    function whitelistERC20(address xcrt) external onlyCommunity {
        require(address(xCreative) == address(0), "xCreative: ERC20 already set");
        xCreative = xIERC20(xcrt);
    }

    function whitelistERC721(address tokenAddress) external onlyCommunity {
        erc721Contracts[tokenAddress] = true;
    }

    function getTokenPrice() external override view returns(uint256 ethPrice) {
        return priceOracle.ETHPriceOfERC20(address(xCreative));
    }

    function burnTransferRate(address from, uint256 price) external override managedERC721 {
        //xCreative.burn(from, price);
    }

    //To unwrap the token the DAO asks for a fee
    function burnUnwrapRate(address from, uint256 price) external override managedERC721 {
    }

    function claimToken(address wrapId) external override {
    }

    function mint(address to, uint256 amount) external override onlyCommunity {
        xCreative.mint(to, amount);
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
