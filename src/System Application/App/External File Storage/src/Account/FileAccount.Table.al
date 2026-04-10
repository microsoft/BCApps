// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// A common representation of a file account.
/// </summary>
table 9450 "File Account"
{
    Extensible = false;
    TableType = Temporary;
    Caption = 'External File Account';

    fields
    {
        field(1; "Account Id"; Guid) { }
        field(2; Name; Text[250]) { }
        field(4; Connector; Enum "Ext. File Storage Connector") { }
        field(5; Logo; Media)
        {
            Access = Internal;
        }
    }

    keys
    {
        key(PK; "Account Id", Connector)
        {
            Clustered = true;
        }
        key(Name; Name)
        {
            Description = 'Used for sorting';
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Logo, Name) { }
    }
}