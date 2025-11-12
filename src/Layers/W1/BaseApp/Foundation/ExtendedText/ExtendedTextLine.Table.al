// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;
using System.Globalization;

table 280 "Extended Text Line"
{
    Caption = 'Extended Text Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Enum "Extended Text Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if ("Table Name" = const("Standard Text")) "Standard Text"
            else
            if ("Table Name" = const("G/L Account")) "G/L Account"
            else
            if ("Table Name" = const(Item)) Item
            else
            if ("Table Name" = const(Resource)) Resource
            else
            if ("Table Name" = const("VAT Clause")) "VAT Clause";
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(4; "Text No."; Integer)
        {
            Caption = 'Text No.';
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; Text; Text[100])
        {
            Caption = 'Text';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Language Code", "Text No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ExtendedTextHeader.Get("Table Name", "No.", "Language Code", "Text No.");
    end;

    var
        ExtendedTextHeader: Record "Extended Text Header";
}

