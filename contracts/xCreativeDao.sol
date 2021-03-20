// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { xIERC20 } from "./interfaces/xIERC20.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {
    IInstantDistributionAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import {
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {
    ISuperfluid
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

contract xCreativeDAO is IGovernance, Ownable {

    address public community;
    xIERC20 public xCreative;
    ISuperToken private _xCRTx;
    IOracle public priceOracle;
    ISuperfluid private _host;
    IInstantDistributionAgreementV1 private _ida;

    mapping(address => bool) public erc721Contracts;
    mapping (uint256 => mapping(address => bool)) public valueChain;

    //uint32 public constant INDEX_ID = 0;

    /*Goverment parameters*/
    uint256 internal _transferRate;
    uint256 internal _unwrap;

    constructor(
        IOracle oracle,
        ISuperfluid host,
        IInstantDistributionAgreementV1 ida,
        uint256 transferRate,
        uint256 unwrapRate
    )
    {
        require(transferRate >= 0 && transferRate <= 100, "xCreative: Transfer rate [0 - 100]");
        require(unwrapRate >= 0 && unwrapRate <= 100, "xCreative: Unwrap rate [0 - 100]");
        priceOracle = oracle;
        _host = host;
        _ida = ida;
        _transferRate = transferRate;
        _unwrap = unwrapRate;
    }

    function whitelistERC20(address xcrtx) external onlyOwner {
        require(address(xCreative) == address(0), "xCreative: ERC20 already set");
        _xCRTx = ISuperToken(xcrtx);
        xCreative = xIERC20(_xCRTx.getUnderlyingToken());
    }

    function whitelistERC721(address tokenAddress) external onlyOwner {
        erc721Contracts[tokenAddress] = true;
    }

    function getTokenPrice() external override view returns(uint256 ethPrice) {
        return priceOracle.ETHPriceOfERC20(address(xCreative));
    }

    function distributeChain(uint256 tokenId, uint256 amount) public {
         (uint256 actualCashAmount,) = _ida.calculateDistribution(
            _xCRTx,
            address(this),
            uint32(tokenId),
            amount);

        _xCRTx.transferFrom(owner(), address(this), actualCashAmount);

        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.distribute.selector,
                _xCRTx,
                uint32(tokenId),
                actualCashAmount,
                new bytes(0) // placeholder ctx
            ),
            new bytes(0) // user data
        );
    }

    function createIndex(address to, uint256 tokenId) external override managedERC721 {
        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.createIndex.selector,
                _xCRTx,
                uint32(tokenId),
                new bytes(0) // placeholder ctx
            ),
            new bytes(0) // user data
        );

        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.updateSubscription.selector,
                _xCRTx,
                tokenId,
                to,
                uint128(10 ether),
                new bytes(0) // placeholder ctx
            ),
            new bytes(0) // user data
        );
    }

    function burnTransferRate(address from, address to, uint256 price, uint256 tokenId) external override managedERC721 {
        xCreative.burn(from, (price * _transferRate) / 100);

        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.updateSubscription.selector,
                _xCRTx,
                tokenId,
                to,
                uint128(10 ether),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    //To unwrap the token the DAO asks for a fee
    function burnUnwrapRate(address from, uint256 price) external override managedERC721 {
        xCreative.burn(from, (price * _unwrap) / 100);
    }

    function claimToken(address wrapId) external override {
    }

    function mint(address to, uint256 amount) external override onlyOwner {
        xCreative.mint(to, amount);
    }

    modifier managedERC721() {
        require(erc721Contracts[msg.sender], "xDAO: not managed contract");
        _;
    }
}
