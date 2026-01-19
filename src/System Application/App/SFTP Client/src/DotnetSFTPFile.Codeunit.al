// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

using System;

codeunit 9761 "Dotnet SFTP File" implements "ISFTP File"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

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

    procedure LastWriteTime(): DateTime
    begin
        exit(RenciSFTPFile.LastWriteTimeUtc());
    end;

    procedure SetFile(NewFile: DotNet RenciISftpFile)
    begin
        RenciSFTPFile := NewFile;
    end;
}