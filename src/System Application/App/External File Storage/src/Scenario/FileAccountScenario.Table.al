// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Temporary table used to display the tree structure in "File Scenario Setup".
/// </summary>
table 9453 "File Account Scenario"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    TableType = Temporary;

    fields
    {
        field(1; Scenario; Integer) { }
        field(2; Connector; Enum "Ext. File Storage Connector") { }
        field(3; "Account Id"; Guid) { }
        field(4; "Display Name"; Text[2048]) { }
        field(5; Default; Boolean) { }
        field(6; EntryType; Enum "File Account Entry Type") { }
        field(7; Position; Integer) { }
    }

    keys
    {
        key(PK; Scenario, "Account Id", Connector)
        {
            Clustered = true;
        }
        key(Position; Position)
        {
        }
        key(Name; "Display Name")
        {
            Description = 'Used for sorting by Display Name';
        }
    }
}