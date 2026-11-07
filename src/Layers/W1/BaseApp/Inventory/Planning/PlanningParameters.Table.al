// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;

table 99000865 "Planning Parameters"
{
    Caption = 'Planning Component';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reordering Policy"; Enum "Reordering Policy")
        {
            Caption = 'Reordering Policy';
            DataClassification = SystemMetadata;
        }
        field(2; "Include Inventory"; Boolean)
        {
            Caption = 'Include Inventory';
            DataClassification = SystemMetadata;
        }
        field(3; "Time Bucket Enabled"; Boolean)
        {
            Caption = 'Time Bucket Enabled';
            DataClassification = SystemMetadata;
        }
        field(4; "Safety Lead Time Enabled"; Boolean)
        {
            Caption = 'Safety Lead Time Enabled';
            DataClassification = SystemMetadata;
        }
        field(5; "Safety Stock Qty Enabled"; Boolean)
        {
            Caption = 'Safety Stock Qty Enabled';
            DataClassification = SystemMetadata;
        }
        field(6; "Reorder Point Enabled"; Boolean)
        {
            Caption = 'Reorder Point Enabled';
            DataClassification = SystemMetadata;
        }
        field(7; "Reorder Quantity Enabled"; Boolean)
        {
            Caption = 'Reorder Quantity Enabled';
            DataClassification = SystemMetadata;
        }
        field(8; "Maximum Inventory Enabled"; Boolean)
        {
            Caption = 'Maximum Inventory Enabled';
            DataClassification = SystemMetadata;
        }
        field(9; "Minimum Order Qty Enabled"; Boolean)
        {
            Caption = 'Minimum Order Qty Enabled';
            DataClassification = SystemMetadata;
        }
        field(10; "Maximum Order Qty Enabled"; Boolean)
        {
            Caption = 'Maximum Order Qty Enabled';
            DataClassification = SystemMetadata;
        }
        field(11; "Order Multiple Enabled"; Boolean)
        {
            Caption = 'Order Multiple Enabled';
            DataClassification = SystemMetadata;
        }
        field(12; "Include Inventory Enabled"; Boolean)
        {
            Caption = 'Include Inventory Enabled';
            DataClassification = SystemMetadata;
        }
        field(13; "Rescheduling Period Enabled"; Boolean)
        {
            Caption = 'Rescheduling Period Enabled';
            DataClassification = SystemMetadata;
        }
        field(14; "Lot Accum. Period Enabled"; Boolean)
        {
            Caption = 'Lot Accumulation Period Enabled';
            DataClassification = SystemMetadata;
        }
        field(15; "Dampener Period Enabled"; Boolean)
        {
            Caption = 'Dampener Period Enabled';
            DataClassification = SystemMetadata;
        }
        field(16; "Dampener Quantity Enabled"; Boolean)
        {
            Caption = 'Dampener Quantity Enabled';
            DataClassification = SystemMetadata;
        }
        field(17; "Overflow Level Enabled"; Boolean)
        {
            Caption = 'Overflow Level Enabled';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Reordering Policy")
        {
            Clustered = true;
        }
    }
}

