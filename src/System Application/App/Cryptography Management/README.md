Provides helper functions for encryption and hashing. 

Encryption is always turned on for online versions, and you cannot turn it off.

Use this module to do the following:
- Encrypt plain text into encrypted value.
- Decrypt encrypted text into plain text.
- Check if encryption is enabled.
- Check whether the encryption key is present, which only works if encryption is enabled.
- Get the recommended question to activate encryption.
- Generate a hash from a string or a stream based on the provided hash algorithm.
- Generate a keyed hash or a keyed base64 encoded hash from a string based on provided hash algorithm and key.
- Generate a base64 encoded hash or a keyed base64 encoded hash from a string based on provided hash algorithm.

Advanced Encryption Standard functionality:
- Initialize a new instance of the RijndaelManaged class with default values.
- Initialize a new instance of the RijndaelManaged class providing the encryption key.
- Initializes a new instance of the RijndaelManaged class providing the encryption key and block size.
- Initializes a new instance of the RijndaelManaged class providing the encryption key, block size and cipher mode.
- Initializes a new instance of the RijndaelManaged class providing the encryption key, block size, cipher mode and padding mode.
- Set a new block size value for the RijndaelManaged class.
- Set a new cipher mode value for the RijndaelManaged class.
- Set a new padding mode value for the RijndaelManaged class.
- Set the key and vector for the RijndaelManaged class.
- Determine whether the specified key size is valid for the current algorithm.
- Specify the key sizes, in bits, that are supported by the symmetric algorithm.
- Specify the block sizes, in bits, that are supported by the symmetric algorithm.
- Get the key and vector from the RijndaelManaged class.
- Return plain text as an encrypted value.
- Return encrypted text as plain text.

For on-premises versions, you can also use this module to do the following:
- Turn on or turn off encryption.
- Publish an event that allows subscription when turning encryption on or off.


