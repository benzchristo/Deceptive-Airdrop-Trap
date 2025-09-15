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
    // --- State Variables ---

    // @dev The address of the deceptive airdrop contract (honeypot).
    IDeceptiveAirdrop public DECEPTIVE_AIRDROP_CONTRACT = IDeceptiveAirdrop(0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF);

    // @dev The trusted Drosera operator that is authorized to call executeResponse.
    address public immutable guardian;

    /// @notice Sets the guardian address upon deployment.
    constructor(address _guardian) {
        guardian = _guardian;
    }

    /// @notice Executes the fund rescue operation.
    /// This function can only be called by the trusted guardian (Drosera operator).
    /// @param data The ABI-encoded data from the trap, containing the total token balance to rescue.
    function executeResponse(bytes calldata data) external {
        // Ensure this function can only be called by the trusted Drosera operator.
        require(msg.sender == guardian, "AirdropResponse: Unauthorized caller");

        // Decode the amount to withdraw from the response data.
        (uint256 amountToWithdraw) = abi.decode(data, (uint256));

        // Call the vulnerable `withdraw` function on the honeypot contract.
        // This assumes the response contract has been approved or has the ability to withdraw.
        DECEPTIVE_AIRDROP_CONTRACT.withdraw(amountToWithdraw);
    }
}
