type TransferRequest = {
	forERC20: boolean;
	forERC721: boolean;
	creator: string;
	to: string;
	token: string;
	amount: number;
	created: number;
	tokenId: number;
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
