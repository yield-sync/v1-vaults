type Access = {
	admin: boolean,
	member: boolean,
}

// Vault properties
type VaultProperty = {
	againstVoteRequired: number,
	forVoteRequired: number,
	transferDelaySeconds: number,
}

type UpdateVaultProperty = [
	// againstVoteRequired
	number,
	// forVoteRequired
	number,
	// transferDelaySeconds
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

type UpdateTransferRequest = [
	// forERC20
	boolean,
	// forERC721
	boolean,
	// creator
	string,
	// to
	string,
	// token
	string,
	// amount
	number,
	// created
	number,
	// tokenId
	number,
]

// Transfer Request Poll
type TransferRequestPoll = {
	againstVoteCount: number,
	forVoteCount: number,
	latestForVoteTime: number,
	votedMembers: string[],
}

type UpdateTransferRequestPoll = [
	// againstVoteCount
	number,
	// forVoteCount
	number,
	// latestForVoteTime
	number | bigint,
	// votedMembers
	string[],
]

// Transfer Request Poll
type V1BTransferRequestPoll = {
	voteCloseTime: number,
	votedAgainstMembers: string[],
	votedForMembers: string[],
}

type UpdateV1BTransferRequestPoll = [
	// latestForVoteTime
	number | bigint,
	// votedAgainstMembers
	string[],
	// votedForMembers
	string[],
]

type TransferRequestStatus = {
	readyToBeProcessed: boolean,
	approved: boolean,
	message: string,
}

type V1BUpdateVaultProperty = [
	// againstVoteRequired
	number,
	// forVoteRequired
	number,
]
