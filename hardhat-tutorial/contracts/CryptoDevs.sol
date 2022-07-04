//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {

    string _baseTokenURI;
    uint256 public _price = 0.01 ether;
    bool public _paused;
    uint256 public maxTokenIds = 20;
    uint256 public tokenIds;
    bool public presaleStarted;
    uint256 public presaleEnded;
    IWhitelist whitelist;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 5 minutes;
    }

    function preSaleMint() public payable onlyWhenNotPaused {
        //ensure presale is ongoing and not stopped
        require(presaleStarted && block.timestamp < presaleEnded,"PreSale Not Active");
        //user must be whitelisted
        require(whitelist.whitelistedAddresses(msg.sender),"User is Not WhiteListed");
        //ensure there are NFTs to mint
        require(tokenIds<maxTokenIds,"NFTs Minted");
        //ensure cash is enough for it
        require(msg.value>=_price, "Need More Cash");
        tokenIds+=1;
        _safeMint(msg.sender,tokenIds);
    }

    function mint() public payable onlyWhenNotPaused{
        require(presaleStarted && block.timestamp >= presaleEnded,"Sale Not Active");
        require(tokenIds<maxTokenIds,"NFTs Minted");
        require(msg.value>=_price, "Need More Cash");
        tokenIds+=1;
        _safeMint(msg.sender,tokenIds);
    }

    function _baseURI() internal view override returns(string memory){
        return _baseTokenURI;
    }

    function setPaused(bool val) public onlyOwner{
        _paused = val;
    }

    function withdraw() public onlyOwner{
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to Send Ether");
    }

    receive() external payable {}
    fallback() external payable {}
}

