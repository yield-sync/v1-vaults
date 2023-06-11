// npx hardhat verify --network < network > --constructor-args scripts/arguments.ts < contract address here >
module.exports = [
	// _YieldSyncV1VaultAccessControl
	"0x0000000000000000000000000000000000000000",
	// Admins
	["0x0000000000000000000000000000000000000000"],
	// Members
	["0x0000000000000000000000000000000000000000"],
	// Signature Manager
	"0x0000000000000000000000000000000000000000",
	// Against votes
	1,
	// For votes
	1,
	// Transfer Votes
	0
]
