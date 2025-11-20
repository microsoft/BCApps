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
            NotBlank = true;
            TableRelation = "G/L Entry";
        }
        field(2; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            NotBlank = true;
            TableRelation = "Value Entry";
        }
        field(3; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
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

