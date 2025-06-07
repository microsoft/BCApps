namespace System.SFTPClient;

using System;

interface "ISFTP Client"
{
    Access = Internal;
    procedure SftpClient(Host: Text; Port: Integer; UserName: Text; Password: SecretText): Boolean
    procedure SftpClient(Host: Text; Port: Integer; UserName: Text; PrivateKey: InStream): Boolean
    procedure SftpClient(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText): Boolean
    procedure GetOperationException(var ExceptionType: Enum "SFTP Exception Type"; var ExceptionMessage: Text)
    procedure Disconnect()
    procedure IsConnected(): Boolean
    procedure Exists(Path: Text; var Exists: Boolean): Boolean
    procedure Delete(Path: Text): Boolean
    procedure WorkingDirectory(var Result: Text): Boolean
    procedure SetWorkingDirectory(Path: Text): Boolean
    procedure ListDirectory(Path: Text; var Result: List of [Interface "ISFTP File"]): Boolean
    procedure ReadAllBytes(Path: Text; Bytes: Dotnet Array): Boolean
    procedure WriteAllBytes(Path: Text; Bytes: Dotnet Array): Boolean
    procedure Get(Path: Text; var Result: Interface "ISFTP File"): Boolean
    procedure CreateDirectory(Path: Text): Boolean
}