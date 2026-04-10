// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

table 5823 "G/L - Item Ledger Relation"
{
    Caption = 'G/L - Item Ledger Relation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            ToolTip = 'Specifies the number of the general ledger entry where cost from the associated value entry number in this record is posted.';
            NotBlank = true;
            TableRelation = "G/L Entry";
        }
        field(2; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            ToolTip = 'Specifies the number of the value entry that has its cost posted in the associated general ledger entry in this record.';
            NotBlank = true;
            TableRelation = "Value Entry";
        }
        field(3; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
            ToolTip = 'Specifies the number of the general ledger register, where the general ledger entry in this record was posted.';
            TableRelation = "G/L Register";
        }
    }

    keys
    {
        key(Key1; "G/L Entry No.", "Value Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Value Entry No.")
        {
        }
        key(Key3; "G/L Register No.")
        {
        }
    }

    fieldgroups
    {
    }
}

