# YieldSync V1 Vaults

## Get Started

```shell
npm install
```

## Automated Testing

```shell
npx hardhat test
```

## `.env` example

```shell
# Wallet Private Key
PRIVATE_KEY=

# API keys
INFURA_API_KEY=
ETHERSCAN_API_KEY=
OPTIMISTIC_ETHERSCAN_API_KEY=

# Governance Addresses
YIELD_SYNC_GOVERNANCE_ADDRESS_MAINNET=
YIELD_SYNC_GOVERNANCE_ADDRESS_OP=
YIELD_SYNC_GOVERNANCE_ADDRESS_OP_GOERLI=
YIELD_SYNC_GOVERNANCE_ADDRESS_SEPOLIA=

# Deployed Registry
YIELD_SYNC_V1_VAULT_REGISTRY_MAINNET=
YIELD_SYNC_V1_VAULT_REGISTRY_OP=
YIELD_SYNC_V1_VAULT_REGISTRY_OP_GOERLI=
YIELD_SYNC_V1_VAULT_REGISTRY_SEPOLIA=

# Deployed Factory
YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_MAINNET=
YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_OP=
YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_OP_GOERLI=
YIELD_SYNC_V1_VAULT_FACTORY_ADDRESS_SEPOLIA=

# Deployed Yield Sync V1 B Transfer Request Protocol
YIELD_SYNC_V1_A_TRANSFER_REQUEST_PROTOCOL_MAINNET=
YIELD_SYNC_V1_A_TRANSFER_REQUEST_PROTOCOL_OP=
YIELD_SYNC_V1_A_TRANSFER_REQUEST_PROTOCOL_OP_GOERLI=
YIELD_SYNC_V1_A_TRANSFER_REQUEST_PROTOCOL_SEPOLIA=

# Deployed Yield Sync V1 B Transfer Request Protocol
YIELD_SYNC_V1_B_TRANSFER_REQUEST_PROTOCOL_MAINNET=
YIELD_SYNC_V1_B_TRANSFER_REQUEST_PROTOCOL_OP=
YIELD_SYNC_V1_B_TRANSFER_REQUEST_PROTOCOL_OP_GOERLI=
YIELD_SYNC_V1_B_TRANSFER_REQUEST_PROTOCOL_SEPOLIA=
```

## Smart Contract Layout & Ordering

### Variables

1. Type (`address`, `bytes`, etc.)
	2. Visibility (`public` | `private` | `internal` | `external`)
		3. Array

### Mapping

1. Visibility (`public` | `private` | `internal` | `external`)
	2. Type (`address`, `bytes`, etc.)
		3. Struct

### Function

1. Interface Implementation
	2. Visibility (`public` | `private` | `internal` | `external`)
		3. State Interaction (`pure` | `view`)
			4. Restriction (`Access Control` etc. DEFAULT_ADMIN_ROLE first)
				5. Complexity (Calls to inherited functions, external functions, change state)
					6. Alphabetical