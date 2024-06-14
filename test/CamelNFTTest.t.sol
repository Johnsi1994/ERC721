// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {CamelNFT} from "../src/CamelNFT.sol";

contract CamelNFTTest is Test {
    CamelNFT public camel;

    address public user1 = address(1);
    address public user2 = address(0x221A744e381C2dae12A78Cfad9d62d44520206E7);

    function setUp() public {
        camel = new CamelNFT();
    }

    function testMintContractPause() public {
        string[] memory urls = new string[](1);

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        hoax(user1, 1 ether);
        camel.publicMint{value: 0.01 ether}(1, urls);
    }

    function testMintInsufficientFunds() public {
        string[] memory urls = new string[](1);

        camel.unpause();

        deal(user1, 1 ether);
        vm.startPrank(user1);

        // mint without sending value
        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Insufficient funds!"));
        camel.publicMint(1, urls);

        // mint Insufficient funds, try to mint 2 NFTs but only send value for one
        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Insufficient funds!"));
        camel.publicMint{value: 0.01 ether}(2, urls);

        vm.stopPrank();
    }

    function testMintUrlNotMatchAmount() public {
        string[] memory urls = new string[](0);

        camel.unpause();

        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Url numbers not match mint amount!"));

        hoax(user1, 1 ether);
        camel.publicMint{value: 0.01 ether}(1, urls);
    }

    function testMintInvalidAmount() public {
        camel.unpause();

        deal(user1, 1 ether);
        vm.startPrank(user1);

        // try to mint 0
        string[] memory urls0 = new string[](0);
        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Invalid mint amount!"));
        camel.publicMint{value: 0.01 ether}(0, urls0);

        // try to mint over maxMintAmountPerTx(2)
        string[] memory urls3 = new string[](3);
        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Invalid mint amount!"));
        camel.publicMint{value: 0.03 ether}(3, urls3);

        vm.stopPrank();
    }

    function testMaxSupplyExceed() public {
        string[] memory urls = new string[](1);

        camel.unpause();

        // set _currentTokenId as 8 to mock max supply exceeded
        // Use command "forge inspect CamelNFT storage-layout" to find _currentTokenId is at slot 11
        vm.store(address(camel), bytes32(uint256(11)), bytes32(uint256(8)));

        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Max supply exceeded!"));

        hoax(user1, 1 ether);
        camel.publicMint{value: 0.01 ether}(1, urls);
    }

    function testPublicMint() public {
        camel.unpause();

        string[] memory urls = new string[](1);

        vm.expectEmit(false, false, false, true);
        emit CamelNFT.MintSuccess(user1, 1);

        hoax(user1, 1 ether);
        camel.publicMint{value: 0.01 ether}(1, urls);

        assertEq(camel.balanceOf(user1), 1);
    }

    function testPresaleNotStart() public {
        bytes32[] memory proof = new bytes32[](1);
        string[] memory urls = new string[](1);

        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Presale not active!"));

        hoax(user2, 1 ether);
        camel.whitelistMint{value: 0.01 ether}(proof, 1, urls);
    }

    function testWhitelistAlreadyMint() public {
        // when store a value to a map, first need to compute the slot keccak256(abi.encode(key, map_slot))
        bytes32 slot = keccak256(abi.encode(user2, uint256(13)));
        // the value of the map is boolean, 'true' can be convert to bytes32(uint256(1))
        bytes32 value = bytes32(uint256(1));
        // store the value to the slot
        vm.store(address(camel), slot, value);

        // make sure we update user2 as already claimed
        assertEq(camel.whitelistClaimed(user2), true);

        camel.presaleStart();
        bytes32[] memory proof = new bytes32[](1);
        string[] memory urls = new string[](1);

        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Address already claimed!"));

        hoax(user2, 1 ether);
        camel.whitelistMint{value: 0.01 ether}(proof, 1, urls);
    }

    function testInvalidProof() public {
        camel.presaleStart();

        string[] memory urls = new string[](1);
        bytes32[] memory wrongProof = new bytes32[](1);

        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Invalid proof!"));

        hoax(user2, 1 ether);
        camel.whitelistMint{value: 0.01 ether}(wrongProof, 1, urls);
    }

    function testWhitelistMint() public {
        camel.setMerkleRoot(0x87282e120e9e8a3be7f6b0689f998286bc08612b39312eb6f496df566f67ee27);

        camel.presaleStart();

        string[] memory urls = new string[](2);
        bytes32[] memory correctProof = new bytes32[](2);
        correctProof[0] = 0x3963b18307cdc73cdab54d496ebe5bb98b6419de683e22b808a8c149eb6ab95e;
        correctProof[1] = 0x9faad5d61d27830de0396c42d8305716149d94d4060e01d4cb0d174f5e1cce23;

        hoax(user2, 1 ether);
        camel.whitelistMint{value: 0.02 ether}(correctProof, 2, urls);

        assertEq(camel.balanceOf(user2), 2);
    }
}
