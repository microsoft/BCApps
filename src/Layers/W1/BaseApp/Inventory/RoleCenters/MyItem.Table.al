// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Ledger;
using System.Security.AccessControl;

table 9152 "My Item"
{
    Caption = 'My Item';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item numbers that are displayed in the My Item Cue on the Role Center.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            begin
                SetItemFields();
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item.';
            Editable = false;
        }
        field(4; "Unit Price"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Unit Price';
            ToolTip = 'Specifies the item''s unit price.';
            Editable = false;
        }
        field(5; Inventory; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No.")));
            Caption = 'Inventory';
            ToolTip = 'Specifies the inventory quantities of my items.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User ID", "Item No.")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
        key(Key3; "Unit Price")
        {
        }
    }

    fieldgroups
    {
    }

    local procedure SetItemFields()
    var
        Item: Record Item;
    begin
        Item.SetLoadFields(Description, "Unit Price");
        if Item.Get("Item No.") then begin
            Description := Item.Description;
            "Unit Price" := Item."Unit Price";
        end;
    end;
}

