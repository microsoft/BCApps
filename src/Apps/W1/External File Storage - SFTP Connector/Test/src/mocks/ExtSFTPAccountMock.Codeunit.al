// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

codeunit 144590 "Ext. SFTP Account Mock"
{
    Access = Internal;
    SingleInstance = true;

    procedure Name(): Text[250]
    begin
        exit(AccName);
    end;

    procedure Name(Value: Text[250])
    begin
        AccName := Value;
    end;

    procedure Hostname(): Text[250]
    begin
        exit(AccHostname);
    end;

    procedure Hostname(Value: Text[250])
    begin
        AccHostname := Value;
    end;

    procedure Username(): Text[256]
    begin
        exit(AccUsername);
    end;

    procedure Username(Value: Text[256])
    begin
        AccUsername := Value;
    end;

    procedure Fingerprints(): Text[1024]
    begin
        exit(AccFingerprints);
    end;

    procedure Fingerprints(Value: Text[1024])
    begin
        AccFingerprints := Value;
    end;

    procedure Port(): Integer
    begin
        exit(AccPort);
    end;

    procedure Port(Value: Integer)
    begin
        AccPort := Value;
    end;

    procedure BaseRelativeFolderPath(): Text[250]
    begin
        exit(AccBaseRelativeFolderPath);
    end;

    procedure BaseRelativeFolderPath(Value: Text[250])
    begin
        AccBaseRelativeFolderPath := Value;
    end;

    procedure Password(): Text
    begin
        exit(AccPassword);
    end;

    procedure Password(Value: Text)
    begin
        AccPassword := Value;
    end;

    var
        AccName: Text[250];
        AccHostname: Text[250];
        AccUsername: Text[256];
        AccFingerprints: Text[1024];
        AccBaseRelativeFolderPath: Text[250];
        AccPassword: Text;
        AccPort: Integer;
}