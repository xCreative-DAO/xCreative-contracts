// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface xIERC20 is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

