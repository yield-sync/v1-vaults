type Access = {
	admin: boolean,
	member: boolean,
}

// Vault properties
type VaultProperty = {
	voteAgainstRequired: number,
	voteForRequired: number,
	transferDelaySeconds: number,
}

type UpdateVaultProperty = [
	// voteAgainstRequired
	number,
	// voteForRequired
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
];

// Transfer Request Poll
type TransferRequestPoll = {
	latestForVoteTime: number,
	voteAgainstMembers: string[],
	voteForMembers: string[],
};

type UpdateTransferRequestPoll = [
	// latestForVoteTime
	number | bigint,
	// voteAgainstMembers
	string[],
	// voteForMembers
	string[],
];

// Transfer Request Poll
type V1BTransferRequestPoll = {
	voteCloseTime: number,
	voteAgainstMembers: string[],
	voteForMembers: string[],
};

type UpdateV1BTransferRequestPoll = [
	// latestForVoteTime
	number | bigint,
	// voteAgainstMembers
	string[],
	// voteForMembers
	string[],
];

type TransferRequestStatus = {
	readyToBeProcessed: boolean,
	approved: boolean,
	message: string,
};
