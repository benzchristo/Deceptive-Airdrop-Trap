# Deceptive Airdrop Trap

Hello! This repository contains my proof-of-concept Drosera trap designed to detect and respond to a specific type of scam: the deceptive airdrop honeypot.

## The Scenario

The scam works like this: a malicious actor deploys a contract (the "honeypot") that promises a valuable airdrop. However, to "claim" this airdrop, a user is tricked into approving and sending a legitimate ERC-20 token to the honeypot contract. The funds accumulate in the honeypot until the scammer rugs, taking all the deposited tokens.

This Drosera trap is designed to be a reactive security measure against such a scam. It monitors the honeypot for large token deposits and, once a certain threshold is crossed, triggers an automated response to rescue the funds.

## How It Works

The system is composed of two main smart contracts and is built to integrate with the Drosera protocol.

### 1. `DeceptiveAirdropTrap.sol` (The Trap)

This is the core detection contract that implements Drosera's `ITrap` interface.

-   **`collect()`**: This function is called by a Drosera node before and after each transaction. It's a simple `view` function that checks and returns the balance of the legitimate ERC-20 token held within the honeypot contract.
-   **`shouldRespond(bytes[] calldata data)`**: After a transaction, a Drosera node passes the `before` and `after` data from the `collect()` calls to this function. The logic here is straightforward:
    1.  It decodes the token balances from the data.
    2.  It checks if the balance has increased.
    3.  If the balance has increased by more than a predefined `DEPOSIT_THRESHOLD`, it signifies that a large deposit has been made (i.e., a victim has been tricked).
    4.  When triggered, it returns `true` and passes the total accumulated balance to the response contract.

### 2. `AirdropResponse.sol` (The Response)

This contract is responsible for taking action once the trap is sprung.

-   **`executeResponse(bytes calldata data)`**: This function is called by the Drosera network when the trap signals a response. It decodes the total token balance from the data provided by the trap and immediately calls a (supposedly vulnerable) `withdraw` function on the honeypot contract to rescue all the accumulated funds.

### Hardcoded Addresses & Configuration

As per Drosera's requirements, these contracts do not use constructors or initializers for configuration. All critical addresses (like the honeypot contract, the token contract, and the secure operator wallet) are hardcoded directly into the contracts before deployment. For testing purposes, these are placeholder addresses.

## Testing the Trap

I've built the project using Foundry. The entire trap and response mechanism is fully tested to ensure it functions as expected.

### How to Run the Tests

1.  **Install Dependencies**:
    If you haven't already, you'll need to install the necessary libraries.
    ```bash
    forge install
    ```

2.  **Run the Test Suite**:
    You can run the tests using the following command:
    ```bash
    forge test
    ```

The test suite in `test/DeceptiveAirdropTrap.t.sol` simulates the entire lifecycle of an attack and response:
1.  It deploys the mock ERC-20 token and the mock honeypot contract.
2.  It deploys the `DeceptiveAirdropTrap` and `AirdropResponse` contracts.
3.  It uses `vm.store` to inject the mock contract addresses into the trap and response contracts at runtime, bypassing the hardcoded values for a controlled test environment.
4.  It simulates a "victim" approving the honeypot and calling its `claim` function, thereby depositing tokens.
5.  It checks if the trap correctly identifies the deposit and triggers a response.
6.  It simulates the Drosera network calling the `executeResponse` function.
7.  Finally, it asserts that the funds have been successfully withdrawn from the honeypot and are safely in the possession of the `AirdropResponse` contract.

This project demonstrates a simple yet effective reactive security measure that can be built with Drosera to protect users from common on-chain scams.