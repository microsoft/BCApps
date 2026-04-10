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
            ToolTip = 'Specifies the type of period that item availability is shown for.';
            DataClassification = SystemMetadata;
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies the first period that item availability is shown for.';
            DataClassification = SystemMetadata;
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(10; "Gross Requirement"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Requirement';
            ToolTip = 'Specifies the sum of the total demand for the item. The gross requirement consists of independent demand (which include sales orders, service orders, transfer orders, and, if specified on the page, demand forecasts) and dependent demand (which include production order components for planned, firm planned, and released production orders and requisition and planning worksheets lines).';
            DataClassification = SystemMetadata;
        }
        field(11; "Scheduled Receipt"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Scheduled Receipt';
            ToolTip = 'Specifies the sum of items from replenishment orders.';
            DataClassification = SystemMetadata;
        }
        field(12; "Planned Order Receipt"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Planned Order Receipt';
            ToolTip = 'Specifies the item''s availability figures for the planned order receipt.';
            DataClassification = SystemMetadata;
        }
        field(13; "Projected Available Balance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Projected Available Balance';
            ToolTip = 'Specifies the item''s availability. This quantity includes all known supply and demand but does not include anticipated demand from demand forecasts or blanket sales orders or suggested supplies from planning or requisition worksheets.';
            DataClassification = SystemMetadata;
        }
        field(14; Inventory; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Inventory';
            ToolTip = 'Specifies the inventory level of an item.';
            DataClassification = SystemMetadata;
        }
        field(15; "Qty. on Purch. Order"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Purch. Order';
            DataClassification = SystemMetadata;
        }
        field(16; "Qty. on Sales Order"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Sales Order';
            DataClassification = SystemMetadata;
        }
        field(17; "Qty. on Service Order"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Service Order';
            DataClassification = SystemMetadata;
        }
        field(18; "Qty. on Job Order"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Job Order';
            DataClassification = SystemMetadata;
        }
        field(19; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Trans. Ord. Shipment (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(20; "Qty. in Transit"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. in Transit';
            DataClassification = SystemMetadata;
        }
        field(21; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Trans. Ord. Receipt (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(22; "Qty. on Asm. Comp. Lines"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Asm. Comp. Lines';
            DataClassification = SystemMetadata;
        }
        field(23; "Qty. on Assembly Order"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Assembly Order';
            DataClassification = SystemMetadata;
        }
        field(24; "Expected Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Expected Inventory';
            ToolTip = 'Specifies how many units of the assembly component are expected to be available for the current assembly order on the due date.';
            DataClassification = SystemMetadata;
        }
        field(25; "Available Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Available Inventory';
            ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
            DataClassification = SystemMetadata;
        }
        field(26; "Scheduled Receipt (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Scheduled Receipt (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(27; "Scheduled Issue (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Scheduled Issue (Qty.)';
            DataClassification = SystemMetadata;
        }
        field(28; "Planned Order Releases"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Planned Order Releases';
            ToolTip = 'Specifies the sum of items from replenishment order proposals, which include planned production orders and planning or requisition worksheets lines, that are calculated according to the starting date in the planning worksheet and production order or the order date in the requisition worksheet. This sum is not included in the projected available inventory. However, it indicates which quantities should be converted from planned to scheduled receipts.';
            DataClassification = SystemMetadata;
        }
        field(29; "Net Change"; Decimal)
        {
            AutoFormatType = 0;
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
