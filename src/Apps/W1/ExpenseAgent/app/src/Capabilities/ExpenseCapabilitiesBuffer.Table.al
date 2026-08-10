// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Temporary buffer feeding the Expense Capabilities API page.
/// </summary>
table 6914 "Expense Capabilities Buffer"
{
    Access = Internal;
    TableType = Temporary;
    DataClassification = SystemMetadata;
    Caption = 'Expense Capabilities Buffer';

    fields
    {
        field(1; "Capability Name"; Code[250])
        {
            Caption = 'Capability Name';
        }
        field(10; "Is Enabled"; Boolean)
        {
            Caption = 'Is Enabled';
        }
    }

    keys
    {
        key(PK; "Capability Name") { Clustered = true; }
    }
}
