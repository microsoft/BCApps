// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.SFTPClient;

using System.SFTPClient;

codeunit 139076 "Mock SFTP File" implements "ISFTP File"
{
    Access = Internal;

    var
        FullNameVar: Text;
        IsDirectoryVar: Boolean;
        LengthVar: BigInteger;
        LastWriteTimeVar: DateTime;

    procedure Initialize(NewFullName: Text; NewIsDirectory: Boolean; NewLength: BigInteger; NewLastWriteTime: DateTime)
    begin
        FullNameVar := NewFullName;
        IsDirectoryVar := NewIsDirectory;
        LengthVar := NewLength;
        LastWriteTimeVar := NewLastWriteTime;
    end;

    procedure MoveTo(Destination: Text): Boolean
    begin
        exit(true);
    end;

    procedure Name(): Text
    var
        LastSlashPos: Integer;
    begin
        LastSlashPos := FullNameVar.LastIndexOf('/');
        if LastSlashPos <= 0 then
            exit(FullNameVar);

        exit(FullNameVar.Substring(LastSlashPos + 1));
    end;

    procedure FullName(): Text
    begin
        exit(FullNameVar);
    end;

    procedure IsDirectory(): Boolean
    begin
        exit(IsDirectoryVar);
    end;

    procedure Length(): BigInteger
    begin
        exit(LengthVar);
    end;

    procedure LastWriteTime(): DateTime
    begin
        exit(LastWriteTimeVar);
    end;
}