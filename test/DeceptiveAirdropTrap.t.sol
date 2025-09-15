// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeceptiveAirdropTrap} from "../src/DeceptiveAirdropTrap.sol";
import {AirdropResponse} from "../src/AirdropResponse.sol";
import {MockDeceptiveAirdrop} from "./mocks/MockDeceptiveAirdrop.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract DeceptiveAirdropTrapTest is Test {
    DeceptiveAirdropTrap public trap;
    AirdropResponse public response;
    MockDeceptiveAirdrop public mockAirdrop;
    MockERC20 public mockToken;

    address public victim = makeAddr("victim");
    address public trapOperator = 0x1804c8aB1f12e6bbF3894D4044f464a4a0386071;

    uint256 constant VICTIM_INITIAL_BALANCE = 5000 * 1e18;
    uint256 constant DEPOSIT_AMOUNT = 1500 * 1e18;

    function setUp() public {
        // Deploy the mock token
        mockToken = new MockERC20("Mock Token", "MTKN", 18);
        mockToken._mint(victim, VICTIM_INITIAL_BALANCE);

        // Deploy the mock airdrop contract
        mockAirdrop = new MockDeceptiveAirdrop(address(mockToken));

        // Deploy the trap and response contracts
        trap = new DeceptiveAirdropTrap();
        response = new AirdropResponse(trapOperator); // Set operator as guardian

        // --- Replace hardcoded addresses in contracts ---
        // This is a common testing pattern when dealing with non-upgradeable contracts
        // with hardcoded addresses. We use `vm.store` to overwrite the storage slots.
        // Slot 0 in DeceptiveAirdropTrap is DECEPTIVE_AIRDROP_CONTRACT
        vm.store(
            address(trap),
            bytes32(uint256(0)),
            bytes32(uint256(uint160(address(mockAirdrop))))
        );
        // Slot 1 in DeceptiveAirdropTrap is LEGITIMATE_TOKEN
        vm.store(
            address(trap),
            bytes32(uint256(1)),
            bytes32(uint256(uint160(address(mockToken))))
        );
        // Slot 0 in AirdropResponse is DECEPTIVE_AIRDROP_CONTRACT
        vm.store(
            address(response),
            bytes32(uint256(0)),
            bytes32(uint256(uint160(address(mockAirdrop))))
        );
    }

    function test_Trap_ShouldTriggerAndRespond() public {
        // --- Step 1: Get the "before" state ---
        vm.prank(trapOperator);
        bytes memory dataBefore = trap.collect();
        (uint256 balanceBefore) = abi.decode(dataBefore, (uint256));
        assertEq(balanceBefore, 0, "Initial balance of honeypot should be 0");

        // --- Step 2: Victim approves and "claims" the airdrop ---
        vm.startPrank(victim);
        mockToken.approve(address(mockAirdrop), DEPOSIT_AMOUNT);
        mockAirdrop.claim(DEPOSIT_AMOUNT);
        vm.stopPrank();

        // --- Step 3: Get the "after" state ---
        vm.prank(trapOperator);
        bytes memory dataAfter = trap.collect();
        (uint256 balanceAfter) = abi.decode(dataAfter, (uint256));
        assertEq(balanceAfter, DEPOSIT_AMOUNT, "Honeypot balance should match deposit");

        // --- Step 4: Check if the trap should respond ---
        // In Drosera, data[0] is the newest snapshot.
        bytes[] memory collectedData = new bytes[](2);
        collectedData[0] = dataAfter;  // Newest
        collectedData[1] = dataBefore; // Oldest

        (bool should, bytes memory responseData) = trap.shouldRespond(collectedData);
        assertTrue(should, "Trap should have triggered");

        // --- Step 5: Execute the response ---
        // The response must be called by the guardian (trapOperator).
        vm.prank(trapOperator);
        response.executeResponse(responseData);

        // --- Step 6: Verify the outcome ---
        // Check that the funds were rescued from the honeypot
        assertEq(mockToken.balanceOf(address(mockAirdrop)), 0, "Honeypot should be empty after response");
        // Check that the operator's vault (in this case, the response contract) received the funds.
        // In a real scenario, you'd likely transfer to a secure address from within the response.
        assertEq(mockToken.balanceOf(address(response)), DEPOSIT_AMOUNT, "Response contract should have the rescued funds");
    }
}
