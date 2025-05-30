codeunit 50100 "SFTP Client"
{
    Access = Public;

    procedure Initialize(Hostname: Text; Port: Integer; Username: Text; Password: SecretText)
    begin
        SFTPClientImplementation.Initialize(HostName, Port, Username, Password);
    end;

    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream)
    begin
        SFTPClientImplementation.Initialize(HostName, Port, Username, PrivateKey);
    end;

    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText)
    begin
        SFTPClientImplementation.Initialize(HostName, Port, Username, PrivateKey, Passphrase);
    end;

    procedure ListFiles(Path: Text; var FileList: List of [Text]): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.ListFiles(Path, FileList));
    end;

    procedure GetFileAsStream(Path: Text; var InStream: InStream): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.GetFileAsStream(Path, InStream));
    end;

    procedure DeleteFile(Path: Text): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.DeleteFile(Path));
    end;

    procedure FileExists(Path: Text): Boolean
    begin
        exit(SFTPClientImplementation.FileExists(Path));
    end;

    procedure MoveFile(SourcePath: Text; DestinationPath: Text): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.MoveFile(SourcePath, DestinationPath));
    end;

    procedure Disconnect()
    begin
        SFTPClientImplementation.Disconnect();
    end;

    procedure PutFileStream(Path: Text; var SourceInStream: InStream): Codeunit "SFTP Operation Response"
    begin
        exit(SFTPClientImplementation.PutFileStream(Path, SourceInStream));
    end;

    var
        SFTPClientImplementation: Codeunit "SFTP Client Implementation";
}