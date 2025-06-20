# SFTP Client for Business Central
Provides an API that lets you connect directly to SFTP servers from Business Central.

Please note that there is a difference between [SFTP](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol), [FTP](https://en.wikipedia.org/wiki/File_Transfer_Protocol) and [FTPS](https://en.wikipedia.org/wiki/FTPS).

This component uses [SSH.NET](https://github.com/sshnet/SSH.NET) to connect to SFTP servers.

## Main components
### Codeunit "SFTP Client"
This codeunit exposes the different functions available to the user.
The authentication methods are as follow:
- Username/Password
- Username/Private Key (Without passphrase)
- Username/Private Key (With passphrase)

Please note that the connection is stateful. That means, when you have created a connection, you should always use `SFTPClient.Disconnect()` when finished.

## Why is there no Copy-File function?
SSH.NET does not support it since it's not part of the specification for SFTP.
If you still want a copy-file functionality, then you have to download it to BC and upload it under a different name.

## Debug connection
Since SSH supports many different encryptions, key exchange methods, public key authentication, etc. a page is included for debugging purposes. 
The page has ID XXX. It cannot be found via the Search Functionality, but only via `?page=XXX` in the URL of the client.