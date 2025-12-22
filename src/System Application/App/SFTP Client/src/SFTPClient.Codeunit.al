// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

codeunit 9762 "SFTP Client"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Adds a SHA256 fingerprint to the list of accepted host key fingerprints.
    /// </summary>
    /// <param name="Fingerprint"></param>
    procedure AddFingerprintSHA256(Fingerprint: Text)
    begin
        SFTPClientImplementation.AddFingerPrintSHA256(Fingerprint);
    end;

    /// <summary>
    /// Adds an MD5 fingerprint to the list of accepted host key fingerprints.
    /// </summary>
    /// <param name="Fingerprint"></param>
    procedure AddFingerprintMD5(Fingerprint: Text)
    begin
        SFTPClientImplementation.AddFingerPrintMD5(Fingerprint);
    end;

    /// <summary>
    /// Initializes the SFTP client with the specified parameters. The client is connected to the server.
    /// </summary>
    /// <param name="Hostname">Hostname of the SFTP server</param>
    /// <param name="Port">Port of the SFTP server</param>
    /// <param name="Username">Username for the connection</param>
    /// <param name="Password">Password for the connection</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure Initialize(Hostname: Text; Port: Integer; Username: Text; Password: SecretText): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.Initialize(HostName, Port, Username, Password));
    end;

    /// <summary>
    /// Initializes the SFTP client with the specified parameters. The client is connected to the server.
    /// The private key is used for authentication.
    /// </summary>
    /// <param name="HostName">Hostname of the SFTP server</param>
    /// <param name="Port">Port of the SFTP server</param>
    /// <param name="Username">Username for the connection</param>
    /// <param name="PrivateKey">Private Key for the connection</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.Initialize(HostName, Port, Username, PrivateKey));
    end;

    /// <summary>
    /// Initializes the SFTP client with the specified parameters. The client is connected to the server.
    /// The private key is used for authentication and a passphrase is required to decrypt the private key.
    /// </summary>
    /// <param name="HostName">Hostname of the SFTP server</param>
    /// <param name="Port">Port of the SFTP server</param>
    /// <param name="Username">Username for the connection</param>
    /// <param name="PrivateKey">Private Key for the connection</param>
    /// <param name="Passphrase">Passphrase to decrypt the private key</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.Initialize(HostName, Port, Username, PrivateKey, Passphrase));
    end;

    /// <summary>
    /// Lists the files in the specified path on the SFTP server.
    /// The result is returned as a list of SFTP File interfaces.
    /// </summary>
    /// <param name="Path">The path to request</param>
    /// <param name="FileList">A list that will be populated with ISFTP File interfaces</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure ListFiles(Path: Text; var FileList: List of [Interface "ISFTP File"]): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.ListFiles(Path, FileList));
    end;

    /// <summary>
    /// Lists the files in the specified path on the SFTP server.
    /// The result is returned as a record of type "SFTP Folder Content".
    /// </summary>
    /// <param name="Path">The path to request</param>
    /// <param name="FileList">A record that will be populated with file information</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure ListFiles(Path: Text; var FileList: Record "SFTP Folder Content"): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.ListFiles(Path, FileList));
    end;

    /// <summary>
    /// Downloads a file from the SFTP server and returns it as an InStream.
    /// </summary>
    /// <param name="Path">Path to the file</param>
    /// <param name="InStream">An InStream that will be populated with the file content</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure GetFileAsStream(Path: Text; var InStream: InStream): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.GetFileAsStream(Path, InStream));
    end;

    /// <summary>
    /// Deletes a file on the SFTP server.
    /// </summary>
    /// <param name="Path">Path to the file</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure DeleteFile(Path: Text): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.DeleteFile(Path));
    end;

    /// <summary>
    /// Tests if a file exists on the SFTP server.
    /// </summary>
    /// <param name="Path">Path of the file</param>
    /// <param name="Result">Output parameter that will be set to True if the file exists, False otherwise</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure FileExists(Path: Text; var Result: Boolean): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.FileExists(Path, Result));
    end;

    /// <summary>
    /// Moves a file from one path to another on the SFTP server.
    /// </summary>
    /// <param name="SourcePath">Source path of the file</param>
    /// <param name="DestinationPath">Destination path of the file</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure MoveFile(SourcePath: Text; DestinationPath: Text): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.MoveFile(SourcePath, DestinationPath));
    end;

    /// <summary>
    /// Disconnects the SFTP client from the server.
    /// This method should be called when the client is no longer needed.
    /// </summary>
    procedure Disconnect()
    begin
        SFTPClientImplementation.Disconnect();
    end;

    /// <summary>
    /// Uploads a file to the SFTP server from an InStream.
    /// </summary>
    /// <param name="Path">The destination path to upload the file to</param>
    /// <param name="SourceInStream">The stream of data to upload</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure PutFileStream(Path: Text; var SourceInStream: InStream): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.PutFileStream(Path, SourceInStream));
    end;

    /// <summary>
    /// Returns the working directory of the SFTP client.
    /// This is the directory that the client is currently working in.
    /// </summary>
    /// <param name="Result">Output parameter that will be set to the current working directory path</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure GetWorkingDirectory(var Result: Text): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.GetWorkingDirectory(Result));
    end;

    /// <summary>
    /// Sets the working directory of the SFTP client.
    /// This is the directory that the client will work in for subsequent operations.
    /// </summary>
    /// <param name="Path">The new working path of the client</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure SetWorkingDirectory(Path: Text): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.SetWorkingDirectory(Path));
    end;

    /// <summary>
    /// Checks if the SFTP client is connected to the server.
    /// This method can be used to verify the connection status before performing operations.
    /// </summary>
    /// <returns>True if the client is connected, False if the client is disconnected</returns>
    procedure IsConnected(): Boolean
    begin
        exit(SFTPClientImplementation.IsConnected());
    end;

    /// <summary>
    /// Creates a new directory on the SFTP server.
    /// </summary>
    /// <param name="Path">Path of the directory to create</param>
    /// <returns>A response codeunit containing success/failure status and error information if applicable</returns>
    procedure CreateDirectory(Path: Text): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.CreateDirectory(Path));
    end;

    var
        SFTPClientImplementation: Codeunit "SFTP Client Implementation";
}