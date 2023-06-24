// npx hardhat verify --network < network > --constructor-args scripts/arguments.ts < contract address here >
module.exports = [
	// _YieldSyncV1VaultAccessControl
	"0x0A1Bd6B7769458f346Fe2eA10a9795Cd32376DEA",
	// Admins
	["0x1f0B2EC2D4e7E0fFf93684A30Bb90A0b075D409C"],
	// Members
	["0x1f0B2EC2D4e7E0fFf93684A30Bb90A0b075D409C"],
	// Signature Manager
	"0x0000000000000000000000000000000000000000",
	// Against votes
	1,
	// For votes
	1,
	// Transfer delay
	0
]
