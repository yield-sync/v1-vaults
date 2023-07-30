// Vault properties
type VaultProperty = {
	againstVoteRequired: number,
	forVoteRequired: number,
	transferDelaySeconds: number,
}

type UpdateVaultProperty = [
	number,
	number,
	number,
]

// Open transfer request ids
type OpenTransferRequestIds = number[]

// Transfer Request
type TransferRequest = {
	forERC20: boolean,
	forERC721: boolean,
	creator: string,
	to: string,
	token: string,
	amount: number,
	created: number,
	tokenId: number,
}

type UpdatedTransferRequest = [
	boolean,
	boolean,
	string,
	string,
	string,
	number,
	number,
	number,
]

// Transfer Request Poll
type TransferRequestPoll = {
	againstVoteCount: number,
	forVoteCount: number,
	latestForVoteTime: number,
	votedMembers: string[],
}

type UpdatedTransferRequestPoll = [
	number,
	number,
	nusmber,
	string[],
]
