// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Purchases.Document;

table 5818 "Detailed Matched Order Line"
{
    Caption = 'Detailed Matched Order Line';
    DataClassification = CustomerContent;
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Editable = false;
            ToolTip = 'Specifies the line number of the invoice/credit memo line.';
        }
        field(2; Type; Enum "Purchase Line Type")
        {
            Editable = false;
            ToolTip = 'Specifies the invoice/credit memo line type.';
        }
        field(3; "No."; Code[20])
        {
            Editable = false;
            ToolTip = 'Specifies the number of the involved entry or record.';
        }
        field(4; Description; Text[100])
        {
            Editable = false;
            ToolTip = 'Specifies a description of the entry of the product.';
        }
        field(5; "Description 2"; Text[50])
        {
            Editable = false;
            ToolTip = 'Specifies information in addition to the description.';
        }
        field(6; Quantity; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Specifies the quantity from the matched order or receipt/shipment line.';
        }
        field(7; "Qty. Rcd. Not Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Quantity Received Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Specifies the quantity received but not yet invoiced from the matched order or receipt/shipment line.';
        }
        field(8; "Qty. to Invoice"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Quantity to Invoice';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity to invoice from the matched order or receipt/shipment line.';
        }
        field(9; "Qty. to Invoice (Base)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Quantity to Invoice (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Specifies the base quantity to invoice from the matched order or receipt/shipment line.';
        }
        field(10; "Qty. Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Specifies the quantity invoiced from the matched purchase order or receipt/shipment line.';
        }
        field(11; "Qty. Invoiced (Base)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Quantity Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Specifies the base quantity invoiced from the matched purchase order or receipt/shipment line.';
        }
        field(50; "Receipt on Invoice"; Boolean)
        {
            Caption = 'Receipt on Invoice';
            Editable = false;
            ToolTip = 'Specifies whether the receipt is posted automatically with the invoice.';
        }
        field(100; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
            ToolTip = 'Specifies the number of the order.';
        }
        field(101; "Order Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Order Line No.';
            Editable = false;
            ToolTip = 'Specifies the line number of the order.';
        }
        field(200; "Receipt/Shipment No."; Code[20])
        {
            Caption = 'Receipt/Shipment No.';
            Editable = false;
            ToolTip = 'Specifies the number of the receipt or shipment.';
        }
        field(201; "Receipt/Shipment Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Receipt/Shipment Line No.';
            Editable = false;
            ToolTip = 'Specifies the line number of the receipt or shipment.';
        }
        field(220; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            Editable = false;
            ToolTip = 'Specifies the vendor''s reference.';
        }
        field(221; "Vendor Order No."; Code[35])
        {
            Caption = 'Vendor Order No.';
            ToolTip = 'Specifies the vendor''s order number.';
            Editable = false;
        }
        field(222; "Vendor Shipment No."; Code[35])
        {
            Caption = 'Vendor Shipment No.';
            Editable = false;
            ToolTip = 'Specifies the vendor''s shipment number.';
        }
        field(223; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            Editable = false;
            ToolTip = 'Specifies the vendor''s invoice number.';
        }
        field(224; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';
            Editable = false;
            ToolTip = 'Specifies the vendor''s credit memo number.';
        }
        field(1000; Indentation; Integer)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1001; HasSubLines; Boolean)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1002; "Line"; Text[250])
        {
            Editable = false;
        }
        field(1003; "Document Line SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1004; "Matched Order Line SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1005; "Matched Rcpt./Shpt. Line SysId"; Guid)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Line No.", "Order No.", "Order Line No.", "Receipt/Shipment No.", "Receipt/Shipment Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        MatchedOrderLine: Record "Matched Order Line";
        MatchedOrderLineMgmt: Codeunit "Matched Order Line Mgmt.";
    begin
        MatchedOrderLine.SetRange("Document Line SystemId", Rec."Document Line SystemId");
        if not IsNullGuid(Rec."Matched Order Line SystemId") then
            MatchedOrderLine.SetRange("Matched Order Line SystemId", Rec."Matched Order Line SystemId");
        if not IsNullGuid(Rec."Matched Rcpt./Shpt. Line SysId") then
            MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", Rec."Matched Rcpt./Shpt. Line SysId");
        MatchedOrderLine.DeleteAll(true);

        MatchedOrderLineMgmt.UpdateQtyOnParentLines(Rec, false, -"Qty. to Invoice", -"Qty. to Invoice (Base)");
        MatchedOrderLineMgmt.UpdateQtyOnParentLines(Rec, true, -"Qty. to Invoice", -"Qty. to Invoice (Base)");
    end;
}