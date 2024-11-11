// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OllieCoin} from "../src/OllieCoin.sol";
import {RewardCoin} from "../src/RewardCoin.sol";

contract CounterTest is Test {
    OllieCoin public ollieCoin;
    RewardCoin public rewardCoin;

    address public ollie = address(0xabcd);
    address public user1 = address(0x1111);
    address public user2 = address(0x2222);
    address public user3 = address(0x3333);


    function setUp() public {
        vm.label(ollie, "Ollie");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(user3, "User3");
    }

    function test_distributions() public {
        vm.startPrank(ollie);

        // Deploy contracts
        rewardCoin = new RewardCoin();
        ollieCoin = new OllieCoin(address(rewardCoin));
        rewardCoin.approve(address(ollieCoin), UINT256_MAX);
        assertTrue(ollieCoin.owner() == ollie);
        assertTrue(rewardCoin.owner() == ollie);

        // Initial miniting
        ollieCoin.mint(user1, 100 ether);
        ollieCoin.mint(user2, 100 ether);
        ollieCoin.mint(user3, 100 ether);
        rewardCoin.mint(ollie, 900 ether);

        // First distribution
        console.log("1a) Do first distribution");
        ollieCoin.distribute(rewardCoin, 300 ether);
        console.log("--------------------");
        console.log("  Owed Rewards:");
        console.log("  User1: ", ollieCoin.owed(user1)/1 ether);
        console.log("  User2: ", ollieCoin.owed(user2)/1 ether);
        console.log("  User3: ", ollieCoin.owed(user3)/1 ether);
        console.log("--------------------");
        console.log("  Zero expected for all, as no checkpointing has occured");

        vm.stopPrank();
        
        vm.startPrank(user1);
        console.log("\n  1b) Transfer from user1 to user2");
        ollieCoin.transfer(user2, 100 ether);
		vm.stopPrank();

        console.log("--------------------");
        console.log("  Owed Rewards:");
        console.log("  User1: ", ollieCoin.owed(user1)/1 ether);
        console.log("  User2: ", ollieCoin.owed(user2)/1 ether);
        console.log("  User3: ", ollieCoin.owed(user3)/1 ether);
        console.log("--------------------");
        console.log("  Zero expected for user3. No token interaction, so no checkpointing has occured.\n    Transferring from user1 to user2 checkpoints for both users, hence owed amount is updated for those");

        assertEq(rewardCoin.balanceOf(user1), 0);
		assertEq(rewardCoin.balanceOf(user2), 0);
		assertEq(rewardCoin.balanceOf(user3), 0);

        // Second distribution
        vm.startPrank(ollie);
        console.log("\n  2a) Do second distribution and user2 transfers to user3");
        ollieCoin.distribute(rewardCoin, 300 ether);
        vm.stopPrank();
    
		assertEq(rewardCoin.balanceOf(user1), 0);
		assertEq(rewardCoin.balanceOf(user2), 0);
		assertEq(rewardCoin.balanceOf(user3), 0);

        vm.startPrank(user2);
        ollieCoin.transfer(user3, 200 ether);
        console.log("--------------------");
        console.log("  Owed Rewards:");
        console.log("  User1: ", ollieCoin.owed(user1)/1 ether);
        console.log("  User2: ", ollieCoin.owed(user2)/1 ether);
        console.log("  User3: ", ollieCoin.owed(user3)/1 ether);
        console.log("--------------------");
        console.log("  Transfer from user2 to user3 checkpoints for those users, so owed amount is updated.\n    No checkpointing occurs for user1 (and no increase in owed amount anyway)");

        console.log("\n  2b) Users 1 and 2 claim");
        ollieCoin.claim();
        vm.stopPrank();
        
        vm.startPrank(user1);
        ollieCoin.claim();
        vm.stopPrank();
        console.log("--------------------");
        console.log("  Owed Rewards:");
        console.log("  User1: ", ollieCoin.owed(user1)/1 ether);
        console.log("  User2: ", ollieCoin.owed(user2)/1 ether);
        console.log("  User3: ", ollieCoin.owed(user3)/1 ether);
        console.log("  RewardCoin Balances:");
        console.log("  User1: ", rewardCoin.balanceOf(user1)/1 ether);
        console.log("  User2: ", rewardCoin.balanceOf(user2)/1 ether);
        console.log("  User3: ", rewardCoin.balanceOf(user3)/1 ether);
        console.log("--------------------");
        console.log("  Update owed rewards to zero, and transfer rewards to users. User3 still owed 200 as they haven't claimed yet");
        
        assertEq(rewardCoin.balanceOf(user1), 100 ether);
		assertEq(rewardCoin.balanceOf(user2), 300 ether);
		assertEq(rewardCoin.balanceOf(user3), 0);

        // Third distribution
        vm.startPrank(ollie);
        console.log("\n  3) Do third distribution and everyone claims");
        ollieCoin.distribute(rewardCoin, 300 ether);
        vm.stopPrank();
        
        vm.startPrank(user1);
        ollieCoin.claim();
        vm.stopPrank();
        
        vm.startPrank(user2);
        ollieCoin.claim();
        vm.stopPrank();
        
        vm.startPrank(user3);
        ollieCoin.claim();
        vm.stopPrank();

        console.log("--------------------");
        console.log("  Owed Rewards:");
        console.log("  User1: ", ollieCoin.owed(user1)/1 ether);
        console.log("  User2: ", ollieCoin.owed(user2)/1 ether);
        console.log("  User3: ", ollieCoin.owed(user3)/1 ether);
        console.log("  RewardCoin Balances:");
        console.log("  User1: ", rewardCoin.balanceOf(user1)/1 ether);
        console.log("  User2: ", rewardCoin.balanceOf(user2)/1 ether);
        console.log("  User3: ", rewardCoin.balanceOf(user3)/1 ether);
        console.log("--------------------");
        console.log("  Update owed rewards to zero, and transfer rewards to users. Pressing claim checkpoints for that user");
    
        // Assert final reward balances
		assertEq(rewardCoin.balanceOf(user1), 100 ether);
		assertEq(rewardCoin.balanceOf(user2), 300 ether);
		assertEq(rewardCoin.balanceOf(user3), 500 ether);

        // Assert final ollieCoin balances
		assertEq(ollieCoin.balanceOf(user1), 0 ether);
		assertEq(ollieCoin.balanceOf(user2), 0 ether);
		assertEq(ollieCoin.balanceOf(user3), 300 ether);
    }
}
