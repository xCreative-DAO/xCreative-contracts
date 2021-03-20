// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IGovernance {

    function getTokenPrice() external view returns(uint256 ethPrice);
    function claimToken(address wrapId) external;
    function burnUnwrapRate(address from, uint256 price) external;
    function burnTransferRate(address from, address to, uint256 price, uint256 tokenId) external;
    function mint(address to, uint256 amount) external;
    function createIndex(address to, uint256 tokenId) external;

}
