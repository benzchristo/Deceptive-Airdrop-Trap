// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @title Deceptive Airdrop Trap
/// @author Your Name
/// @notice This trap monitors a deceptive airdrop contract that acts as a honeypot.
/// It triggers a response when a user deposits a significant amount of a specific ERC20 token.
contract DeceptiveAirdropTrap is ITrap {
    // --- Hardcoded Addresses & Configuration ---

    // @dev The address of the deceptive airdrop contract (honeypot).
    // TODO: Replace with the actual address of the deployed mock or real contract.
    address public DECEPTIVE_AIRDROP_CONTRACT = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;

    // @dev The address of the legitimate ERC20 token being targeted by the honeypot.
    // TODO: Replace with the actual address of the deployed mock or real token.
    IERC20 public LEGITIMATE_TOKEN = IERC20(0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF);

    // @dev The threshold of token accumulation in the honeypot that triggers a response.
    // This is set to 1000 tokens, assuming 18 decimals.
    uint256 public constant DEPOSIT_THRESHOLD = 1000 * 1e18;

    // @dev A simple whitelist mapping. Only whitelisted addresses can operate the trap.
    mapping(address => bool) public whitelist;

    // --- Trap Logic ---

    /// @notice The constructor is empty as per Drosera requirements.
    /// Whitelist management must be handled externally or hardcoded.
    constructor() {
        // For testing, we can whitelist a default address.
        // In a real scenario, this might be managed by a DAO or multisig.
        whitelist[0x1804c8aB1f12e6bbF3894D4044f464a4a0386071] = true; // Example address
    }

    /// @notice Restricts function access to whitelisted operators.
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    /// @notice Collects the balance of the legitimate token held by the honeypot contract.
    /// @return data The ABI-encoded token balance.
    function collect() external view override onlyWhitelisted returns (bytes memory data) {
        uint256 honeypotBalance = LEGITIMATE_TOKEN.balanceOf(DECEPTIVE_AIRDROP_CONTRACT);
        return abi.encode(honeypotBalance);
    }

    /// @notice Determines if the amount of tokens deposited into the honeypot
    /// between two states has crossed the defined threshold.
    /// @param data An array of collected data points (balances). We expect at least two.
    /// @return should A boolean indicating if a response should be sent.
    /// @return response The data to be sent to the response contract.
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, "");
        }

        // Decode the balance from the pre-transaction state and post-transaction state.
        uint256 balanceBefore = abi.decode(data[0], (uint256));
        uint256 balanceAfter = abi.decode(data[data.length - 1], (uint256));

        // Check if the balance has increased.
        if (balanceAfter <= balanceBefore) {
            return (false, "");
        }

        uint256 balanceIncrease = balanceAfter - balanceBefore;

        // If the increase is significant enough, trigger a response.
        bool triggered = balanceIncrease >= DEPOSIT_THRESHOLD;

        if (triggered) {
            // Encode the necessary information for the response contract.
            // In this case, we pass the total amount accumulated to be rescued.
            bytes memory responseData = abi.encode(balanceAfter);
            return (true, responseData);
        }

        return (false, "");
    }
}
