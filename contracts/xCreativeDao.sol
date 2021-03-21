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
    mapping(uint256 => uint32) internal _idxTokenId; 
    uint32 internal _idx;

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
        xCreative.approve(xcrtx, type(uint256).max);
    }

    function whitelistERC721(address tokenAddress) external onlyOwner {
        erc721Contracts[tokenAddress] = true;
    }

    function getTokenPrice() external override view returns(uint256 ethPrice) {
        return priceOracle.ETHPriceOfERC20(address(xCreative));
    }

    function distribute(uint256 tokenId, uint256 amount) public override {

        uint256 distributeAmount = this.getTokenPrice() * amount;
        (uint256 actualCashAmount,) = _ida.calculateDistribution(
            _xCRTx,
            address(this), 1,
            amount);

            xCreative.mint(address(this), actualCashAmount);
            _xCRTx.upgrade(actualCashAmount);
            _host.callAgreement(
                _ida,
                abi.encodeWithSelector(
                    _ida.distribute.selector,
                    _xCRTx,
                    _idxTokenId[tokenId],
                    actualCashAmount,
                    new bytes(0)
                ),
                new bytes(0)
            );
    }

    function createIndex(uint256 tokenId) external override managedERC721 {
        if(_idxTokenId[tokenId] == 0) {
            _idx++;
            _host.callAgreement(
                _ida,
                abi.encodeWithSelector(
                    _ida.createIndex.selector,
                    _xCRTx,
                    _idx,
                    new bytes(0)
                ),
                new bytes(0)
            );
            _idxTokenId[tokenId] = _idx;
        }
    }

    function updateIndex(uint256 tokenId, address to) external override managedERC721 {

        xCreative.mint(address(this), 1 ether);
        _xCRTx.upgrade(1 ether);

        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.updateSubscription.selector,
                _xCRTx,
                _idxTokenId[tokenId],
                to,
                uint128(1),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function burnTransferRate(address from, address to, uint256 price, uint256 tokenId) external override managedERC721 {
        uint256 burnAmount = ((this.getTokenPrice() * price) * _transferRate) / 100;
        xCreative.burn(from, burnAmount);
        _host.callAgreement(
            _ida,
            abi.encodeWithSelector(
                _ida.updateSubscription.selector,
                _xCRTx,
                _idxTokenId[tokenId],
                to,
                uint128(burnAmount),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    //To unwrap the token the DAO asks for a fee
    function burnUnwrapRate(address from, uint256 price) external override managedERC721 {
        uint256 burnAmount = ((this.getTokenPrice() * price) * _unwrap) / 100;
        xCreative.burn(from, burnAmount);
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
