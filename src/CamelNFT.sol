// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CamelNFT is ERC721URIStorage, Pausable, Ownable {
    bool public presale = false;

    uint256 public price;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 private _currentTokenId;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    event MintSuccess(address, uint256);
    event SetMerkleRoot(bytes32);
    event SetPresaleStart();
    event SetPresaleEnd();

    error ErrorLog(string);

    constructor() ERC721("Camel LoLo", "CLO") Ownable(msg.sender) {
        price = 0.01 ether;
        maxSupply = 8;
        maxMintAmountPerTx = 2;
        _currentTokenId = 0;
        pause();
    }

    modifier mintCompliance(uint256 _mintAmount, string[] calldata urls) {
        if (msg.value < price * _mintAmount) {
            revert ErrorLog("Insufficient funds!");
        }
        if (_mintAmount != urls.length) {
            revert ErrorLog("Url numbers not match mint amount!");
        }
        if (_mintAmount <= 0 || _mintAmount > maxMintAmountPerTx) {
            revert ErrorLog("Invalid mint amount!");
        }
        if (_currentTokenId + _mintAmount > maxSupply) {
            revert ErrorLog("Max supply exceeded!");
        }
        _;
    }

    function publicMint(uint256 _mintAmount, string[] calldata urls)
        public
        payable
        whenNotPaused
        mintCompliance(_mintAmount, urls)
    {
        _mintLoop(_mintAmount, urls);
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount, string[] calldata urls)
        public
        payable
        mintCompliance(_mintAmount, urls)
    {
        if (!presale) {
            revert ErrorLog("Presale not active!");
        }
        if (whitelistClaimed[msg.sender]) {
            revert ErrorLog("Address already claimed!");
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert ErrorLog("Invalid proof!");
        }

        whitelistClaimed[msg.sender] = true;
        _mintLoop(_mintAmount, urls);
    }

    function _mintLoop(uint256 _mintAmount, string[] calldata urls) private {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _currentTokenId++;
            _safeMint(msg.sender, _currentTokenId);
            _setTokenURI(_currentTokenId, urls[i]);
        }
        emit MintSuccess(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit SetMerkleRoot(newRoot);
    }

    function presaleStart() external onlyOwner {
        presale = true;
        emit SetPresaleStart();
    }

    function presaleEnd() external onlyOwner {
        presale = false;
        emit SetPresaleEnd();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert ErrorLog("Withdraw failed!");
        }
    }

    // Just because you never know
    receive() external payable {}
}
