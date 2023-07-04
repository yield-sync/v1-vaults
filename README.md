# YieldSync V1 Vaults

To test the contracts run..

```shell
npx hardhat test
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