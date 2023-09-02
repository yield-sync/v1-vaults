// Access
type Access = {
	admin: boolean,
	member: boolean,
}

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
