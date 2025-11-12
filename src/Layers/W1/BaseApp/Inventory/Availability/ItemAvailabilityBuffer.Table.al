// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

table 925 "Item Availability Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;

        }
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            DataClassification = SystemMetadata;
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = SystemMetadata;
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(10; "Gross Requirement"; Decimal)
        {
            Caption = 'Gross Requirement';
            DataClassification = SystemMetadata;
        }
        field(11; "Scheduled Receipt"; Decimal)
        {
            Caption = 'Scheduled Receipt';
            DataClassification = SystemMetadata;
        }
        field(12; "Planned Order Receipt"; Decimal)
        {
            Caption = 'Planned Order Receipt';
            DataClassification = SystemMetadata;
        }
        field(13; "Projected Available Balance"; Decimal)
        {
            Caption = 'Projected Available Balance';
            DataClassification = SystemMetadata;
        }
        field(14; Inventory; Decimal)
        {
            Caption = 'Inventory';
            DataClassification = SystemMetadata;
        }
        field(15; "Qty. on Purch. Order"; Decimal)
        {
            Caption = 'Qty. on Purch. Order';
            DataClassification = SystemMetadata;
        }
        field(16; "Qty. on Sales Order"; Decimal)
        {
            Caption = 'Qty. on Sales Order';
            DataClassification = SystemMetadata;
        }
        field(17; "Qty. on Service Order"; Decimal)
        {
            Caption = 'Qty. on Service Order';
            DataClassification = SystemMetadata;
        }
        field(18; "Qty. on Job Order"; Decimal)
        {
            Caption = 'Qty. on Job Order';
            DataClassification = SystemMetadata;
        }
        field(19; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            Caption = 'Trans. Ord. Shipment (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(20; "Qty. in Transit"; Decimal)
        {
            Caption = 'Qty. in Transit';
            DataClassification = SystemMetadata;
        }
        field(21; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            Caption = 'Trans. Ord. Receipt (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(22; "Qty. on Asm. Comp. Lines"; Decimal)
        {
            Caption = 'Qty. on Asm. Comp. Lines';
            DataClassification = SystemMetadata;
        }
        field(23; "Qty. on Assembly Order"; Decimal)
        {
            Caption = 'Qty. on Assembly Order';
            DataClassification = SystemMetadata;
        }
        field(24; "Expected Inventory"; Decimal)
        {
            Caption = 'Expected Inventory';
            DataClassification = SystemMetadata;
        }
        field(25; "Available Inventory"; Decimal)
        {
            Caption = 'Available Inventory';
            DataClassification = SystemMetadata;
        }
        field(26; "Scheduled Receipt (Qty.)"; Decimal)
        {
            Caption = 'Scheduled Receipt (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(27; "Scheduled Issue (Qty.)"; Decimal)
        {
            Caption = 'Scheduled Issue (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(28; "Planned Order Releases"; Decimal)
        {
            Caption = 'Planned Order Releases';
            DataClassification = SystemMetadata;
        }
        field(29; "Net Change"; Decimal)
        {
            Caption = 'Net Change';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}
