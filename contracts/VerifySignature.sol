// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

<<<<<<< HEAD
/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract VerifySignature {
	///
	function splitSignature(bytes memory sig)
		internal
		pure
		returns (bytes32 r, bytes32 s, uint8 v)
	{
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }


	///
    function getMessageHash(string memory _message)
=======

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract VerifySignature {
	///
	function getMessageHash(string memory _message)
>>>>>>> 8b5b20a61f1368c051dbcb1b3de18aa3f3b15912
		public
		pure
		returns (bytes32)
	{
<<<<<<< HEAD
        return keccak256(abi.encodePacked(_message));
    }

    
	///
    function getEthSignedMessageHash(bytes32 _messageHash)
=======
		return keccak256(abi.encodePacked(_message));
	}


	///
	function ECDSA_toEthSignedMessageHash(bytes32 _messageHash)
>>>>>>> 8b5b20a61f1368c051dbcb1b3de18aa3f3b15912
		public
		pure
		returns (bytes32)
	{
<<<<<<< HEAD
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

	///
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
=======
		return ECDSA.toEthSignedMessageHash(_messageHash);
	}

	///
	function ECDSA_toTypedDataHash (bytes32 _domainSeparator, bytes32 _structHash)
		public
		pure
		returns (bytes32)
	{
		return ECDSA.toTypedDataHash(_domainSeparator, _structHash);
	}

	///
	function ECDSA_recover(bytes32 _ethSignedMessageHash, bytes memory _signature)
>>>>>>> 8b5b20a61f1368c051dbcb1b3de18aa3f3b15912
		public
		pure
		returns (address)
	{
<<<<<<< HEAD
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

	///
	function verify(address _signer, string memory _message, bytes memory signature)
=======
		return ECDSA.recover(_ethSignedMessageHash, _signature);
	}

	///
	function verify(address _signer, string memory _message, bytes memory _signature)
>>>>>>> 8b5b20a61f1368c051dbcb1b3de18aa3f3b15912
		public
		pure
		returns (bool)
	{
<<<<<<< HEAD
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
}
=======
		bytes32 messageHash = keccak256(abi.encodePacked(_message));
		bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

		return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
	}
}
>>>>>>> 8b5b20a61f1368c051dbcb1b3de18aa3f3b15912
