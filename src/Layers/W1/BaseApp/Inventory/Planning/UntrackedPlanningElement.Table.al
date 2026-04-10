// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;

table 99000855 "Untracked Planning Element"
{
    Caption = 'Untracked Planning Element';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            Editable = false;
            TableRelation = "Req. Wksh. Template";
        }
        field(2; "Worksheet Batch Name"; Code[10])
        {
            Caption = 'Worksheet Batch Name';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Worksheet Template Name"));
        }
        field(3; "Worksheet Line No."; Integer)
        {
            Caption = 'Worksheet Line No.';
            TableRelation = "Requisition Line"."Line No." where("Worksheet Template Name" = field("Worksheet Template Name"),
                                                                 "Journal Batch Name" = field("Worksheet Batch Name"));
        }
        field(4; "Track Line No."; Integer)
        {
            Caption = 'Track Line No.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item in the requisition line for which untracked planning surplus exists.';
            TableRelation = Item;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"));
        }
        field(13; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location code in the requisition line associated with the untracked planning surplus.';
            TableRelation = Location;
        }
        field(21; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(23; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
            ToolTip = 'Specifies the identification code for the source of the untracked planning quantity.';
        }
        field(70; "Parameter Value"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Parameter Value';
            ToolTip = 'Specifies the value of this planning parameter.';
        }
        field(71; "Untracked Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Untracked Quantity';
            ToolTip = 'Specifies how much this planning parameter contributed to the total surplus quantity.';
        }
        field(72; "Track Quantity From"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Track Quantity From';
            ToolTip = 'Specifies how much the total surplus quantity is, including the quantity from this entry.';
        }
        field(73; "Track Quantity To"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Track Quantity To';
            ToolTip = 'Specifies what the surplus quantity would be without the quantity from this entry.';
        }
        field(74; Source; Text[200])
        {
            Caption = 'Source';
            ToolTip = 'Specifies what the source of this untracked surplus quantity is.';
        }
        field(75; "Warning Level"; Option)
        {
            Caption = 'Warning Level';
            OptionCaption = ',Emergency,Exception,Attention';
            OptionMembers = ,Emergency,Exception,Attention;
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Track Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

