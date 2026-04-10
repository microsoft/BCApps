// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using System.Globalization;

table 30 "Item Translation"
{
    Caption = 'Item Translation';
    DataCaptionFields = "Item No.", "Variant Code", "Language Code", Description;
    LookupPageID = "Item Translations";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number of the item on the card.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
            NotBlank = true;
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the item description to use when this language code is selected.';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies more information about the item.';
        }
        field(5400; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

