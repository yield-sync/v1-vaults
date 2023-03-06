# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

## `.env` example

```
PRIVATE_KEY=
INFURA_API_KEY=
ETHERSCAN_API_KEY=
OPTIMISTIC_ETHERSCAN_API_KEY=
```

## Variables, Mappings, & Functions Ordering

### Variables

#### Standard

1. Type (`address`, `bytes`, etc.)
2. Visibility (`public` | `private` | `internal` | `external`)
3. Array

#### Mapping

1. Visibility (`public` | `private` | `internal` | `external`)
2. Type (`address`, `bytes`, etc.)
3. Struct

### Function

1. Visibility (`public` | `private` | `internal` | `external`)
2. State Interaction (`pure` | `view`)
3. Restriction (`Access Control` etc. DEFAULT_ADMIN_ROLE first)
4. Complexity (Calls to inherited functions, external functions, change state)
5. Alphabetical