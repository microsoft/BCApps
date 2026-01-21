// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

table 9760 "SFTP Folder Content"
{
    DataClassification = CustomerContent;
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    Extensible = false;
    Caption = 'SFTP Folder Content';
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies a unique identifier for each entry in the SFTP folder content.';
            Access = Internal;
        }
        field(2; Name; Text[2048])
        {
            Caption = 'Name', Locked = true;
            ToolTip = 'Specifies the name of the file or directory in the SFTP folder.';
        }
        field(3; "Full Name"; Text[2048])
        {
            Caption = 'Full Name', Locked = true;
            ToolTip = 'Specifies the full path of the file or directory in the SFTP folder.';
        }
        field(4; "Is Directory"; Boolean)
        {
            Caption = 'Is Directory', Locked = true;
            ToolTip = 'Specifies whether the entry is a directory (true) or a file (false).';
        }
        field(5; Length; BigInteger)
        {
            Caption = 'Length', Locked = true;
            ToolTip = 'Specifies the size in bytes.';
        }
        field(6; "Last Write Time"; DateTime)
        {
            Caption = 'Last Write Time', Locked = true;
            ToolTip = 'Specifies the date and time when the file or directory was last modified.';
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