// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";


contract xCreative is ERC20 {

    IGovernance public orchestrator;

    constructor(IGovernance orchestrator) ERC20("xCreative", "XCRT") {
        orchestrator = orchestrator;
    }

    function mint(address account, uint256 amount) public onlyDAO {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyDAO {
        burn(account, amount);
    }

    modifier onlyDAO {
        require(msg.sender == address(orchestrator), "xCreative: not DAO");
        _;
    }
}
