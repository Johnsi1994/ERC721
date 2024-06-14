// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {CamelNFT} from "../src/CamelNFT.sol";

contract CamelNFTTest is Test {
    CamelNFT public camel;

    address public user1 = address(1);
    address public user2 = address(0x221A744e381C2dae12A78Cfad9d62d44520206E7);

    bytes32 public root = 0xa227c212774054b137652b6c5e5c4f4005cf1bac08ad642915731cad6a3cd3cd;
    bytes32[] public correctProof = [
        bytes32(0x5650b7ee07ce7ec5db0c2ea671b034e7e96821480fd56feb9c24396300bbb1d9),
        bytes32(0x3678fd8056c00b25cbadd86d0ea1a848cd455c3c727ae1250a6d8e8fed2c6b51)
    ];
    bytes32[] public wrongProof = [bytes32("")];

    string public url1 = "ipfs://1";
    string public url2 = "ipfs://2";
    string public url3 = "ipfs://3";

    function setUp() public {
        camel = new CamelNFT();
    }

    function testMintContractPause() public {
        string[] memory urls = new string[](1);
        urls[0] = url1;

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        hoax(user1, 1 ether);
        camel.publicMint{value: 0.01 ether}(1, urls);
    }

    function testMintInsufficientFunds() public {
        string[] memory urls = new string[](1);
        urls[0] = url1;

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
        string[] memory urls = new string[](1);
        urls[0] = url1;

        camel.unpause();

        deal(user1, 1 ether);
        vm.startPrank(user1);

        // try to mint 0
        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Invalid mint amount!"));
        camel.publicMint{value: 0.01 ether}(0, urls);

        // try to mint over maxMintAmountPerTx(2)
        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Invalid mint amount!"));
        camel.publicMint{value: 0.03 ether}(3, urls);

        vm.stopPrank();
    }

    function testMaxSupplyExceed() public {
        string[] memory urls = new string[](1);
        urls[0] = url1;

        camel.unpause();

        // set _currentTokenId as 8 to mock max supply exceeded
        // Use command "forge inspect CamelNFT storage-layout" to find _currentTokenId is at slot 11
        vm.store(address(camel), bytes32(uint256(11)), bytes32(uint256(8)));

        hoax(user1, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(CamelNFT.ErrorLog.selector, "Max supply exceeded!"));
        camel.publicMint{value: 0.01 ether}(1, urls);
    }

    function testPublicMint() public {
        camel.unpause();

        string[] memory urls = new string[](1);
        urls[0] = url1;

        vm.expectEmit(false, false, false, true);
        emit CamelNFT.MintSuccess(user1, 1);

        hoax(user1, 1 ether);
        camel.publicMint{value: 0.01 ether}(1, urls);

        assertEq(camel.balanceOf(user1), 1);
    }
}
