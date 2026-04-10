// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

table 729 "Copy Item Buffer"
{
    Caption = 'Copy Item Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Source Item No."; Code[20])
        {
            Caption = 'Source Item No.';
            ToolTip = 'Specifies the number of the item that you want to copy the data from.';
            TableRelation = Item;
            DataClassification = SystemMetadata;
        }
        field(3; "Target Item No."; Code[20])
        {
            Caption = 'Target Item No.';
            ToolTip = 'Specifies the number of the new item that you want to copy the data to. \\To generate the new item number from a number series, fill in the Target No. Series field instead.';
            DataClassification = SystemMetadata;
        }
        field(4; "Target No. Series"; Code[20])
        {
            Caption = 'Target No. Series';
            ToolTip = 'Specifies the number series that is used to assign a number to the new item.';
            DataClassification = SystemMetadata;
        }
        field(5; "Number of Copies"; Integer)
        {
            Caption = 'Number of Copies';
            ToolTip = 'Specifies the number of new items that you want to create.';
            DataClassification = SystemMetadata;
        }
        field(10; "General Item Information"; Boolean)
        {
            Caption = 'General Item Information';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(11; "Units of Measure"; Boolean)
        {
            Caption = 'Units of Measure';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(12; Dimensions; Boolean)
        {
            Caption = 'Dimensions';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(13; Picture; Boolean)
        {
            Caption = 'Picture';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(14; Comments; Boolean)
        {
            Caption = 'Comments';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(15; "Sales Prices"; Boolean)
        {
            Caption = 'Sales Prices';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(16; "Sales Line Discounts"; Boolean)
        {
            Caption = 'Sales Line Discounts';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(17; "Purchase Prices"; Boolean)
        {
            Caption = 'Purchase Prices';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(18; "Purchase Line Discounts"; Boolean)
        {
            Caption = 'Purchase Line Discounts';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(19; Troubleshooting; Boolean)
        {
            Caption = 'Troubleshooting';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(20; "Resource Skills"; Boolean)
        {
            Caption = 'Resource Skills';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(21; "Item Variants"; Boolean)
        {
            Caption = 'Item Variants';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(22; Translations; Boolean)
        {
            Caption = 'Translations';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(23; "Extended Texts"; Boolean)
        {
            Caption = 'Extended Texts';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(24; "BOM Components"; Boolean)
        {
            Caption = 'Assembly BOM Components';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(25; "Item Vendors"; Boolean)
        {
            Caption = 'Item Vendors';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(26; Attributes; Boolean)
        {
            Caption = 'Attributes';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(28; "Item References"; Boolean)
        {
            Caption = 'Item References';
            ToolTip = 'Specifies if the selected data type is also copied to the new item.';
            DataClassification = SystemMetadata;
        }
        field(100; "Show Created Items"; Boolean)
        {
            Caption = 'Show Created Items';
            ToolTip = 'Specifies if the copied items are showed after they are created.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
