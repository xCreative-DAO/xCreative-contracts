// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { xIERC20 } from "./interfaces/xIERC20.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";

contract xCreative is ERC20, xIERC20 {

    IGovernance public orchestrator;

    constructor(IGovernance _orchestrator) ERC20("xCreative", "XCRT") {
        orchestrator = _orchestrator;
        _setupDecimals(0);
    }

    function mint(address account, uint256 amount) public override {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public override {
        _burn(account, amount);
    }
}
