// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>Holds information about the filters for retrieving emails.</summary>
table 8884 "Email Folders"
{
    Access = Public;
    TableType = Temporary;
    DataClassification = CustomerContent;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; Ordering; Integer)
        {
            Caption = 'Ordering';
            DataClassification = SystemMetadata;
        }
        field(2; Id; Text[2048])
        {
            Caption = 'Folder Id';
            DataClassification = CustomerContent;
        }
        field(3; "Folder Name"; Text[2048])
        {
            Caption = 'Folder Name';
            DataClassification = CustomerContent;
        }
        field(4; "Has Children"; Boolean)
        {
            Caption = 'Has Children';
            DataClassification = SystemMetadata;
        }
        field(5; "Parent Folder Id"; Text[2048])
        {
            Caption = 'Parent Folder Id';
            DataClassification = SystemMetadata;
        }
        field(6; Indent; Integer)
        {
            Caption = 'Indent';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Ordering)
        {
            Clustered = true;
        }
    }
}