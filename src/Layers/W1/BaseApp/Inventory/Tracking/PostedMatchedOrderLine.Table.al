// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

table 5819 "Posted Matched Order Line"
{
    Caption = 'Posted Matched Order Line';

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
        field(4; "Qty. Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. Invoiced by this Invoice';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity invoiced by this posted invoice line from the matched order or receipt/shipment line.';
        }
        field(5; "Qty. Invoiced (Base)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. Invoiced (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the base quantity invoiced by this posted invoice line from the matched order or receipt/shipment line.';
        }
        field(6; "Receipt on Invoice"; Boolean)
        {
            Caption = 'Receipt on Invoice';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Document Line SystemId", "Matched Order Line SystemId", "Matched Rcpt./Shpt. Line SysId")
        {
            Clustered = true;
        }
        key(Key2; "Matched Order Line SystemId", "Document Line SystemId", "Matched Rcpt./Shpt. Line SysId")
        {
        }
    }
}