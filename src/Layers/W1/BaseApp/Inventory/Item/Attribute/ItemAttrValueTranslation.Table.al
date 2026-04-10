// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using System.Globalization;

table 7503 "Item Attr. Value Translation"
{
    Caption = 'Item Attr. Value Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Attribute ID"; Integer)
        {
            Caption = 'Attribute ID';
            NotBlank = true;
        }
        field(2; ID; Integer)
        {
            Caption = 'ID';
            NotBlank = true;
        }
        field(4; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
            NotBlank = true;
            TableRelation = Language;
        }
        field(5; Name; Text[250])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the translated name of the item attribute value.';
        }
    }

    keys
    {
        key(Key1; "Attribute ID", ID, "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

