// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IOracle {

    function ETHPriceOfERC20(address erc20Address) external view returns(uint256);
}


