// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

table 5817 "Matched Order Line"
{
    Caption = 'Matched Order Line';

    fields
    {
        field(1; "Document Line SystemId"; Guid)
        {
            Caption = 'Document Line SystemId';
            DataClassification = SystemMetadata;
        }
        field(2; "Matched Order Line SystemId"; Guid)
        {
            Caption = 'Matched Order Line SystemId';
            DataClassification = SystemMetadata;
        }
        field(3; "Matched Rcpt./Shpt. Line SysId"; Guid)
        {
            Caption = 'Matched Receipt/Shipment Line SystemId';
            DataClassification = SystemMetadata;
        }
        field(4; "Qty. to Invoice"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity to Invoice';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity to invoice from the matched order or receipt/shipment line.';
        }
        field(5; "Qty. to Invoice (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity to Invoice (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the base quantity to invoice from the matched order or receipt/shipment line.';
        }
        field(6; "Receipt on Invoice"; Boolean)
        {
            Caption = 'Receipt on Invoice';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the receipt is posted automatically with the invoice.';
        }
    }

    keys
    {
        key(Key1; "Document Line SystemId", "Matched Order Line SystemId", "Matched Rcpt./Shpt. Line SysId")
        {
            Clustered = true;
            SumIndexFields = "Qty. to Invoice", "Qty. to Invoice (Base)";
        }
        key(Key2; "Matched Order Line SystemId", "Document Line SystemId", "Matched Rcpt./Shpt. Line SysId")
        {
        }
    }
}