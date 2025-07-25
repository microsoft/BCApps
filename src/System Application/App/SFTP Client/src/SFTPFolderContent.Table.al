// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

table 9760 "SFTP Folder Content"
{
    DataClassification = SystemMetadata;
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    Extensible = false;
    Caption = 'SFTP Folder Content', Locked = true;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Locked = true;
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies a unique identifier for each entry in the SFTP folder content.';
            Access = Internal;
        }
        field(2; Name; Text[2048])
        {
            Caption = 'Name', Locked = true;
            ToolTip = 'Specifies the name of the file or directory in the SFTP folder.';
            DataClassification = SystemMetadata;
        }
        field(3; "Full Name"; Text[2048])
        {
            Caption = 'Full Name', Locked = true;
            ToolTip = 'Specifies the full path of the file or directory in the SFTP folder.';
            DataClassification = SystemMetadata;
        }
        field(4; "Is Directory"; Boolean)
        {
            Caption = 'Is Directory', Locked = true;
            ToolTip = 'Specifies whether the entry is a directory (true) or a file (false).';
            DataClassification = SystemMetadata;
        }
        field(5; Length; BigInteger)
        {
            Caption = 'Length', Locked = true;
            ToolTip = 'Specifies the size in bytes.';
            DataClassification = SystemMetadata;
        }

    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}