// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/// @title Mock Deceptive Airdrop Contract
/// @notice This is a mock contract that simulates a honeypot airdrop scam.
/// It requires users to send tokens to "claim" an airdrop, but the real purpose
/// is to collect those tokens. It includes a vulnerable withdraw function.
contract MockDeceptiveAirdrop {
    IERC20 public immutable legitimateToken;
    address public owner;

    event Claimed(address indexed user, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(address _legitimateToken) {
        legitimateToken = IERC20(_legitimateToken);
        owner = msg.sender;
    }

    /// @notice Simulates the deceptive claim function. The user must first approve
    /// this contract to spend their tokens. This function then pulls the tokens.
    function claim(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        // The honeypot pulls the specified amount of tokens from the user.
        legitimateToken.transferFrom(msg.sender, address(this), amount);
        emit Claimed(msg.sender, amount);
    }

    /// @notice A vulnerable withdraw function. This allows an external contract (the AirdropResponse)
    /// to rescue the funds accumulated in this contract.
    /// In a real-world scenario, this might be an overlooked feature or a bug.
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        legitimateToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // --- Helper function to allow the owner to withdraw ---
    // This is for cleanup or if the response mechanism fails.
    function ownerWithdraw(uint256 amount) external {
        require(msg.sender == owner, "Not the owner");
        legitimateToken.transfer(owner, amount);
    }
}
