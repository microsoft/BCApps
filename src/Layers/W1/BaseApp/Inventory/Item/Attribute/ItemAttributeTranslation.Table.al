// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using System.Globalization;

table 7502 "Item Attribute Translation"
{
    Caption = 'Item Attribute Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Attribute ID"; Integer)
        {
            Caption = 'Attribute ID';
            NotBlank = true;
            TableRelation = "Item Attribute";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
            NotBlank = true;
            TableRelation = Language;
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the translated name of the item attribute.';
        }
    }

    keys
    {
        key(Key1; "Attribute ID", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

