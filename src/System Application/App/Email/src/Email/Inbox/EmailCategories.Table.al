// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>
/// Holds information about email categories used for tagging emails.
/// </summary>
table 8883 "Email Categories"
{
    Access = Public;
    TableType = Temporary;
    Extensible = false;
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
            Caption = 'Category Id';
            DataClassification = CustomerContent;
        }
        field(3; "Display Name"; Text[2048])
        {
            Caption = 'Display Name';
            DataClassification = CustomerContent;
        }
        field(4; Color; Text[50])
        {
            Caption = 'Color';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Ordering)
        {
            Clustered = true;
        }
        key(CategoryId; Id)
        {
        }
    }
}
