namespace System.SFTPClient;

codeunit 50104 "Dotnet SFTP File" implements "ISFTP File"
{
    Access = Internal;

    var
        RenciSFTPFile: DotNet RenciISftpFile;
        LastOperationSuccessful: Boolean;

    procedure MoveTo(Destination: Text): Boolean
    begin
        LastOperationSuccessful := InternalMoveTo(Destination);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalMoveTo(Destination: Text)
    begin
        RenciSFTPFile.MoveTo(Destination);
    end;

    procedure Name(): Text
    begin
        exit(RenciSFTPFile.Name());
    end;

    procedure FullName(): Text
    begin
        exit(RenciSFTPFile.FullName());
    end;

    procedure IsDirectory(): Boolean
    begin
        exit(RenciSFTPFile.IsDirectory);
    end;

    procedure Length(): BigInteger
    begin
        exit(RenciSFTPFile.Length());
    end;

    procedure SetFile(NewFile: DotNet RenciISftpFile)
    begin
        RenciSFTPFile := NewFile;
    end;
}