// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

contract xCreativeWrapper is ERC721, IERC721Receiver, Ownable {

    event TokenWrapped(address indexed tokenAddress, uint256 indexed tokenId, address indexed to);
    event TokenUnwrapped(address indexed tokenAddress, uint256 indexed tokenId, address indexed to);

    mapping(uint256 => InnerToken) internal _innerTokens;
    IGovernance public orchestrator;

    struct InnerToken {
        address creator;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        uint256 royalties;
    }

    constructor(IGovernance _orchestrator) ERC721("xCreative", "x721") {
        orchestrator = _orchestrator;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "xCreative: can't operate token");
        InnerToken memory token = _innerTokens[tokenId];
        //burn xCreative token
        orchestrator.burnUnwrapRate(msg.sender, token.price);
        _burn(tokenId);
        ERC721(token.tokenAddress).transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "xCreative: can't operate token");
        InnerToken memory token = _innerTokens[tokenId];
        require(token.tokenId != 0, "ups");
        //burn xCreative token
        orchestrator.burnUnwrapRate(msg.sender, token.price);
        _burn(tokenId);
        ERC721(token.tokenAddress).safeTransferFrom(address(this), to, token.tokenId);
        emit TokenUnwrapped(token.tokenAddress, token.tokenId, to);
        delete _innerTokens[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "xCreative: can't operate token");
        InnerToken memory token = _innerTokens[tokenId];
        require(token.tokenId != 0, "ups");
        //burn xCreative token
        orchestrator.burnUnwrapRate(msg.sender, token.price);
        _burn(tokenId);
        ERC721(token.tokenAddress).safeTransferFrom(address(this), to, token.tokenId, _data);
        emit TokenUnwrapped(token.tokenAddress, token.tokenId, to);
        delete _innerTokens[tokenId];
    }

    function buy(uint256 tokenId, address to, uint256 newPrice) public payable {
        InnerToken memory token = _innerTokens[tokenId];
        require(token.tokenId > 0, "xCreative: Token don't exist");
        require(token.price <= msg.value, "xCreative: Price not meet");
        _innerTokens[tokenId].price = newPrice;
        address oldOwner = ownerOf(tokenId);
        //Pay seller
        address(uint160(ownerOf(tokenId))).transfer((msg.value * 80) / 100);
        //Pay creator
        address(uint160(token.creator)).transfer((msg.value * token.royalties) / 100);
        //Pay DAO
        uint256 ethDAO = address(this).balance;
        address(uint160(owner())).transfer(ethDAO);
        //Transfer NFT to new Owner
        _safeTransfer(ownerOf(tokenId), to, tokenId, "0x");
        //Pay chain of owners
        orchestrator.distribute(tokenId, ethDAO);
        //Add old Seller to chain of owners
        orchestrator.updateIndex(tokenId, oldOwner);
    }

    function getToken(uint256 wrapId) public view returns(InnerToken memory token) {
        return _innerTokens[wrapId];
    }

    function wrap(address tokenAddress, address to, uint256 tokenId, uint256 price) internal {
        require(tokenAddress != address(this), "Token is already wrap");
        uint256 wrapId = _genId(tokenAddress, tokenId);
        _innerTokens[wrapId] = InnerToken(to, tokenAddress, tokenId, price, 10);
        orchestrator.createIndex(wrapId);
        orchestrator.updateIndex(wrapId, to);
        _mint(to, wrapId);
        emit TokenWrapped(tokenAddress, tokenId, to);
        //_setTokenURI(wrapId, IERC721Metadata(tokenAddress).tokenURI(tokenId));
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "xCreative: can't operate token");
        InnerToken memory inner = _innerTokens[tokenId];
        _burn(tokenId);
        delete _innerTokens[tokenId];
        ERC721(inner.tokenAddress).approve(msg.sender, inner.tokenId);
    }

    function _genId(
        address tokenAddress,
        uint256 tokenId
    )
    pure
    internal
    returns(uint256 wrapId)
    {
        wrapId = uint256(keccak256(abi.encodePacked(tokenAddress, tokenId)));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        uint256 price = _decode(data);
        require(price > 0, "xCreative: define selling price");
        wrap(msg.sender, from, tokenId, price);
        return this.onERC721Received.selector;
    }

    function _decode(bytes memory data) internal pure returns(uint256 sellingPrice) {
        return abi.decode(data, (uint256));
    }
}
