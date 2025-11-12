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
            TableRelation = Item;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"));
        }
        field(13; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(21; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(23; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(70; "Parameter Value"; Decimal)
        {
            BlankZero = true;
            Caption = 'Parameter Value';
        }
        field(71; "Untracked Quantity"; Decimal)
        {
            Caption = 'Untracked Quantity';
        }
        field(72; "Track Quantity From"; Decimal)
        {
            Caption = 'Track Quantity From';
        }
        field(73; "Track Quantity To"; Decimal)
        {
            Caption = 'Track Quantity To';
        }
        field(74; Source; Text[200])
        {
            Caption = 'Source';
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

