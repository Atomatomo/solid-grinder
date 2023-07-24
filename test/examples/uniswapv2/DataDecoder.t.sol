//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "@forge-std/console2.sol";
import {Test, stdError} from "@forge-std/Test.sol";

import {IAddressTable} from "@main/interfaces/IAddressTable.sol";
import {AddressTable} from "@main/AddressTable.sol";

import {UniswapV2Router02_DataEncoder} from "@main/examples/uniswapv2/UniswapV2Router02_DataEncoder.sol";
import {Mock_DataDecoder} from "@test/examples/uniswapv2/mock/Mock_DataDecoder.sol";

contract UniswapV2Router02_DataDecoderTest is Test {
    string mnemonic = "test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address alice = makeAddr("Alice");

    AddressTable table;
    UniswapV2Router02_DataEncoder encoder;
    Mock_DataDecoder decoder;

    function setUp() public {
        vm.startPrank(deployer);

        vm.deal(deployer, 1 ether);
        vm.label(deployer, "Deployer");

        table = new AddressTable();
        encoder = new UniswapV2Router02_DataEncoder(table);
        decoder = new Mock_DataDecoder(table);

        vm.label(address(table), "AddressTable");
        vm.label(address(encoder), "UniswapV2Router02_DataEncoder");
        vm.label(address(decoder), "Mock_DataDecoder");

        vm.stopPrank();
    }

    function test_constructor() external {
        vm.startPrank(deployer);

        assertEq(encoder.packedBits(0, 0), 24);
        assertEq(encoder.packedBits(0, 1), 24);
        assertEq(encoder.packedBits(0, 2), 96);
        assertEq(encoder.packedBits(0, 3), 96);

        assertEq(encoder.packedBits(1, 0), 96);
        assertEq(encoder.packedBits(1, 1), 96);
        assertEq(encoder.packedBits(1, 2), 24);
        assertEq(encoder.packedBits(1, 3), 40);

        vm.stopPrank();
    }

    function test_decode_AddLiquidityData() external {
        vm.startPrank(alice);

        address tokenA = makeAddr("tokenA");
        address tokenB = makeAddr("tokenB");
        address to = makeAddr("to");

        table.register(tokenA);
        table.register(tokenB);
        table.register(to);

        bytes memory compressedPayload = encoder.encode_AddLiquidityData(
            tokenA,
            tokenB,
            1_200 ether, // amountADesired,
            2_500 ether, // amountBDesired,
            1_000 ether, // amountAMin,
            2_000 ether, // amountBMin,
            to,
            100 // deadline
        );

        assertEq(
            compressedPayload,
            hex"000001000002000000410d586a20a4c00000000000878678326eac9000000000003635c9adc5dea000000000006c6b935b8bbd4000000000030000000064"
        );

        (
            address decodedTokenA,
            address decodedTokenB,
            uint256 decodedAmountADesired,
            uint256 decodedAmountBDesired,
            uint256 decodedAmountAMin,
            uint256 decodedAmountBMin,
            address decodedTo,
            uint256 decodedDeadline
        ) = decoder.decode_AddLiquidityData(compressedPayload);

        assertEq(decodedTokenA, tokenA);
        assertEq(decodedTokenB, tokenB);
        assertEq(decodedAmountADesired, 1_200 ether);
        assertEq(decodedAmountBDesired, 2_500 ether);
        assertEq(decodedAmountAMin, 1_000 ether);
        assertEq(decodedAmountBMin, 2_000 ether);
        assertEq(decodedTo, to);
        assertEq(decodedDeadline, 100);

        vm.stopPrank();
    }
}