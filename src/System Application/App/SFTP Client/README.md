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