## MultiTransfer

- **About**: With this smart contract you can transfer ETH or ERC20 tokens to multiple addresses. Also you can send ETH and ERC20 tokens to
multiple addresses at the same time, in one transaction. All codes are written in solidity, thanks to Foundry. UnitTests are added. Coverage is used for unitTests and Slither for checking security and vulnerabilities.
MultiTransferV1 has been improved according to these tools and final code is MultiTransferV2. 

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage



### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/DeployMultiTransferV2.s.sol:DeployMultiTransferV2 --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
### Coverage Analysis 
``` shell
$ forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage
```


### Security 
``` shell
Some useful links:
https://github.com/transmissions11/solcurity
https://github.com/nascentxyz/simple-security-toolkit
https://owasp.org/www-project-smart-contract-top-10/
https://swcregistry.io/


Security is both for protocol developers and auditors. You as a smart contract developer needs to know all these tools before you even go to audit.

Audit Process:
Manual Review : Go through code & docs, Understand what the protocol should do
Using Tools

Tests: 
** Unit Test

** Fuzz Test : It is where you take random inputs and run them through your program. Once you have property defined, you throw random data at your system in order 
to berak that property. If you find something that breaks it, you know you have an edge-case that you must refactor your code to handle it. 
Foundry Echidna and consensus diligence fuzzer are most popular fuzz testing.
Note: I am working on it.

** Static Analysis: Unit and fuzz testing are dynamic testing which dynamic just means you are actually doing something. I mean we are running our code to try to break it.
In static analysis we just look at our code or by using some tools like Slither.
Slither Install:
pip3 install slither-analyzer
$ slither .
https://github.com/crytic/slither/wiki/Detector-Documentation

** Formal Verification: As I said before, Fuzz testing tries to break properties by throwing random data at your system, but Formal Verification
tries to break properties using mathematical proofs.
There are many different ways to do formal verification such as Symbolic Execution, Abstract Interpretation. 
Symbolic execution: now I am working on this. 

```