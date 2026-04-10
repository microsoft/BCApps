// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

table 6508 "Value Entry Relation"
{
    Caption = 'Value Entry Relation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(11; "Source RowId"; Text[250])
        {
            Caption = 'Source RowId';
        }
    }

    keys
    {
        key(Key1; "Value Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source RowId")
        {
        }
    }

    fieldgroups
    {
    }
}

