# README

This repository is a clone of The Standard Protocol CodeHawk contest repository. It includes additional files and minor changes aimed at developing a comprehensive Foundry test suite.

The original repository can be found at:

```
https://github.com/Cyfrin/2023-12-the-standard
```

My findings are documented in the following repository:

```
https://github.com/Renzo1/the-standard-protocol
```

&nbsp;

## Modifications Made to the Original Repository

**New Files:**

- All files inside `test/foundry/`
- contracts/MockSmartVaultManagerV5.sol
- Value flow2TS.png

**Edits to Original Files:**

- Some changes address specific bugs within the existing codebase.
- Others are minor modifications, such as changing private functions to public functions.
- All changes are documented within their respective files and functions.
- Some functions have been duplicated into two versions: the original copy and the bug-free copy.
- The codebase is restored to its default state before being uploaded to GitHub. Therefore, tests that require bug-free versions of the code may not function unless the necessary adjustments are made.
- Tests that require extra tweaks are thoroughly documented within the test files and functions, ensuring clarity and guidance.

## Unique Features of the Test Suite:

- Unit/Fuzz tests
- Integration tests
- Invariants Test setup: Handlers and Invariant (Incomplete) tests
- Dynamic token prices from Chainlink Mock contract
- Implementation of the DRY (Don't Repeat Yourself) technique in the test suite, eliminating the need to repeat setUp() configuration for each test contract
- Inclusion of additional mock interfaces required for test execution
- Overall, the test suite is easy to understand and configure, with ample comments providing guidance.

## Setup

**Requirements:**

- Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html).
- Clone the project codebase into your local workspace.
    
    ```bash
    git clone https://github.com/Renzo1/the-standard-protocol-2.git
    ```
    
- Run the following commands to install dependencies:
    
    ```bash
    npm install
    forge install
    ```
