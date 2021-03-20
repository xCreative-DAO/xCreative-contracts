// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Mock721 is ERC721 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory name, string memory symbol) ERC721 (name, symbol)  public {
    }

    function mint(address to, string memory tokenURI) public returns(uint256 tokenId) {
        _tokenIds.increment();
        tokenId = _tokenIds.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function batchMint(address to, string[] memory tokensURI) public {
        for(uint256 i = 0; i < tokensURI.length; i++) {
            mint(to, tokensURI[i]);
        }
    }
}

