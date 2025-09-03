// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ITrap
/// @author Drosera.io
/// @notice Interface that all traps must implement.
interface ITrap {
    /// @notice The collect function is called by the Drosera protocol to collect data from the chain.
    /// @dev This function should be a view function and not modify state.
    /// @return data The data collected from the chain.
    function collect() external view returns (bytes memory data);

    /// @notice The shouldRespond function is called by the Drosera protocol to determine if a response should be
    /// sent.
    /// @param data The data collected from the chain by the collect function.
    /// @return should A boolean indicating if a response should be sent.
    /// @return response The response to be sent to the response contract.
    function shouldRespond(bytes[] calldata data) external view returns (bool should, bytes memory response);
}
