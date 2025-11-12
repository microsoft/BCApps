// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Ledger;

table 94 "Inventory Posting Group"
{
    Caption = 'Inventory Posting Group';
    LookupPageID = "Inventory Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        CheckGroupUsage();
    end;

    var
        YouCannotDeleteErr: Label 'You cannot delete %1.', Comment = '%1 = Code';

    local procedure CheckGroupUsage()
    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        Item.SetRange("Inventory Posting Group", Code);
        if not Item.IsEmpty() then
            Error(YouCannotDeleteErr, Code);

        ValueEntry.SetRange("Inventory Posting Group", Code);
        if not ValueEntry.IsEmpty() then
            Error(YouCannotDeleteErr, Code);
    end;
}

