// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for the Deceptive Airdrop Contract.
// This defines the vulnerable `withdraw` function that the response will call.
interface IDeceptiveAirdrop {
    function withdraw(uint256 amount) external;
}

/// @title Airdrop Response Contract
/// @author Your Name
/// @notice This contract is triggered by the DeceptiveAirdropTrap. Its purpose is to
/// execute a response to rescue funds from the honeypot contract.
contract AirdropResponse {
    // --- Hardcoded Addresses ---

    // @dev The address of the deceptive airdrop contract (honeypot).
    // This MUST match the address in the DeceptiveAirdropTrap contract.
    IDeceptiveAirdrop public DECEPTIVE_AIRDROP_CONTRACT = IDeceptiveAirdrop(0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF);

    // @dev The address of the operator or a secure vault where rescued funds will be sent.
    // TODO: Replace with a real, secure address.
    address public constant OPERATOR = 0x1804c8aB1f12e6bbF3894D4044f464a4a0386071; // Example address

    /// @notice The constructor is empty as per Drosera requirements.
    constructor() {}

    /// @notice Executes the fund rescue operation.
    /// This function is intended to be called by the Drosera network with data from the trap.
    /// @param data The ABI-encoded data from the trap, containing the total token balance to rescue.
    function executeResponse(bytes calldata data) external {
        // For security, ensure this function can only be called by a trusted Drosera operator.
        // require(msg.sender == OPERATOR, "Unauthorized");

        // Decode the amount to withdraw from the response data.
        (uint256 amountToWithdraw) = abi.decode(data, (uint256));

        // Call the vulnerable `withdraw` function on the honeypot contract.
        // This assumes the response contract has been approved or has the ability to withdraw.
        DECEPTIVE_AIRDROP_CONTRACT.withdraw(amountToWithdraw);
    }
}
