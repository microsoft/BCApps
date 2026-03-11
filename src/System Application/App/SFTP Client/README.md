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

You must always add the fingerprint of the server you want to connect to, before connecting.

Example for uploading a file via SFTP:
```al
local procedure UploadMyFirstFile()
var
    SFTPClient: Codeunit "SFTP Client";
    InStream: InStream;
    ClearTextPassword: Text;
    Password: SecretText;
    SHA256FingerPrint: Text;
begin
    SHA256FingerPrint := 'g3e54QTeJsKxMAo4EyZi+/WSGAnfxI2DkCD69g4bhsw='; 
    SFTPClient.AddFingerPrintSHA256(SHA256FingerPrint);
    ClearTextPassword := 'password'; // Please dont hardcode credentials
    Password := ClearTextPassword;
    SFTPClient.Initialize('example.com', 22, 'username', Password); // Please dont hardcode credentials
    UploadIntoStream('', InStream);
    SFTPClient.PutFileStream('data.txt', InStream);
    SFTPClient.Disconnect();
end;
```

## Why is there no Copy-File function?
SSH.NET does not support it since it's not part of the specification for SFTP.
If you still want a copy-file functionality, then you have to download it to BC and upload it under a different name.

## Debug connection
Since SSH supports many different encryptions, key exchange methods, public key authentication and etc., a page is included for debugging purposes. 
The page has ID 9760. It cannot be found via the Search Functionality, but only via `?page=9760` in the URL of the client.