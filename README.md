# YieldSync V1 Vaults

To test the contracts run..

```shell
npx hardhat test
```

## `.env` example

```shell
PRIVATE_KEY=
INFURA_API_KEY=
ETHERSCAN_API_KEY=
OPTIMISTIC_ETHERSCAN_API_KEY=

YIELD_SYNC_GOVERNANCE_ADDRESS_MAINNET=
YIELD_SYNC_GOVERNANCE_ADDRESS_OP=
YIELD_SYNC_GOVERNANCE_ADDRESS_OP_GOERLI=
YIELD_SYNC_GOVERNANCE_ADDRESS_SEPOLIA=

YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_MAINNET=
YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_OP=
YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_OP_GOERLI=
YIELD_SYNC_V1_VAULT_ACCESS_CONTROL_SEPOLIA=

YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_MAINNET=
YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_OP=
YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_OP_GOERLI=
YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_SEPOLIA=

YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_MAINNET=
YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_OP=
YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_OP_GOERLI=
YIELD_SYNC_V1_VAULT_TRANSFER_REQUEST_PROTOCOL_SEPOLIA=
```

## Variables, Mappings, & Functions Ordering

### Put Functions that belongs to an Implimenting Interface First

The functions should follow the ordering below

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

### Verifying

```shell
npx hardhat verify --network <network-here> --constructor-args location/to/arguments.ts <contract-address-here>
```