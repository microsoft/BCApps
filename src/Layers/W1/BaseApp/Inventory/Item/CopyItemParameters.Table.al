// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

table 728 "Copy Item Parameters"
{
    Caption = 'Copy Item Parameters';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Source Item No."; Code[20])
        {
            Caption = 'Source Item No.';
            TableRelation = Item;
            DataClassification = SystemMetadata;
        }
        field(3; "Target Item No."; Code[20])
        {
            Caption = 'Target Item No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Target No. Series"; Code[20])
        {
            Caption = 'Target No. Series';
            DataClassification = SystemMetadata;
        }
        field(5; "Number of Copies"; Integer)
        {
            Caption = 'Number of Copies';
            DataClassification = SystemMetadata;
        }
        field(10; "General Item Information"; Boolean)
        {
            Caption = 'General Item Information';
            DataClassification = SystemMetadata;
        }
        field(11; "Units of Measure"; Boolean)
        {
            Caption = 'Units of Measure';
            DataClassification = SystemMetadata;
        }
        field(12; Dimensions; Boolean)
        {
            Caption = 'Dimensions';
            DataClassification = SystemMetadata;
        }
        field(13; Picture; Boolean)
        {
            Caption = 'Picture';
            DataClassification = SystemMetadata;
        }
        field(14; Comments; Boolean)
        {
            Caption = 'Comments';
            DataClassification = SystemMetadata;
        }
        field(15; "Sales Prices"; Boolean)
        {
            Caption = 'Sales Prices';
            DataClassification = SystemMetadata;
        }
        field(16; "Sales Line Discounts"; Boolean)
        {
            Caption = 'Sales Line Discounts';
            DataClassification = SystemMetadata;
        }
        field(17; "Purchase Prices"; Boolean)
        {
            Caption = 'Purchase Prices';
            DataClassification = SystemMetadata;
        }
        field(18; "Purchase Line Discounts"; Boolean)
        {
            Caption = 'Purchase Line Discounts';
            DataClassification = SystemMetadata;
        }
        field(19; Troubleshooting; Boolean)
        {
            Caption = 'Troubleshooting';
            DataClassification = SystemMetadata;
        }
        field(20; "Resource Skills"; Boolean)
        {
            Caption = 'Resource Skills';
            DataClassification = SystemMetadata;
        }
        field(21; "Item Variants"; Boolean)
        {
            Caption = 'Item Variants';
            DataClassification = SystemMetadata;
        }
        field(22; Translations; Boolean)
        {
            Caption = 'Translations';
            DataClassification = SystemMetadata;
        }
        field(23; "Extended Texts"; Boolean)
        {
            Caption = 'Extended Texts';
            DataClassification = SystemMetadata;
        }
        field(24; "BOM Components"; Boolean)
        {
            Caption = 'BOM Components';
            DataClassification = SystemMetadata;
        }
        field(25; "Item Vendors"; Boolean)
        {
            Caption = 'Item Vendors';
            DataClassification = SystemMetadata;
        }
        field(26; Attributes; Boolean)
        {
            Caption = 'Attributes';
            DataClassification = SystemMetadata;
        }
        field(28; "Item References"; Boolean)
        {
            Caption = 'Item References';
            DataClassification = SystemMetadata;
        }
        field(1000; "User ID"; Code[50])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
