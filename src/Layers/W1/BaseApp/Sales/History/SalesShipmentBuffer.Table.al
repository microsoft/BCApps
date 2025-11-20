// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;

table 7190 "Sales Shipment Buffer"
{
    Caption = 'Sales Shipment Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
            TableRelation = "Sales Invoice Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge";
        }
        field(7; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        UOMMgt: Codeunit "Unit of Measure Management";
        NextEntryNo: Integer;

    procedure GetLinesForSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ValueEntry: Record "Value Entry";
    begin
        case SalesInvoiceLine.Type of
            SalesInvoiceLine.Type::Item:
                GenerateBufferFromValueEntry(
                  ValueEntry."Document Type"::"Sales Invoice",
                  SalesInvoiceLine."Document No.",
                  SalesInvoiceLine."Line No.",
                  SalesInvoiceLine.Type,
                  SalesInvoiceLine."No.",
                  SalesInvoiceHeader."Posting Date",
                  SalesInvoiceLine."Quantity (Base)",
                  SalesInvoiceLine."Qty. per Unit of Measure");
            SalesInvoiceLine.Type::"G/L Account", SalesInvoiceLine.Type::Resource,
          SalesInvoiceLine.Type::"Charge (Item)", SalesInvoiceLine.Type::"Fixed Asset":
                GenerateBufferFromShipment(SalesInvoiceLine, SalesInvoiceHeader);
        end;
    end;

    procedure GetLinesForSalesCreditMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ValueEntry: Record "Value Entry";
    begin
        case SalesCrMemoLine.Type of
            SalesCrMemoLine.Type::Item:
                GenerateBufferFromValueEntry(
                  ValueEntry."Document Type"::"Sales Credit Memo",
                  SalesCrMemoLine."Document No.",
                  SalesCrMemoLine."Line No.",
                  SalesCrMemoLine.Type,
                  SalesCrMemoLine."No.",
                  SalesCrMemoHeader."Posting Date",
                  -SalesCrMemoLine."Quantity (Base)",
                  SalesCrMemoLine."Qty. per Unit of Measure");
            SalesCrMemoLine.Type::"G/L Account", SalesCrMemoLine.Type::Resource,
            SalesCrMemoLine.Type::"Charge (Item)", SalesCrMemoLine.Type::"Fixed Asset":
                GenerateBufferFromReceipt(SalesCrMemoLine, SalesCrMemoHeader);
        end;
    end;

    local procedure GenerateBufferFromValueEntry(ValueEntryDocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer; LineType: Enum "Sales Line Type"; ItemNo: Code[20]; PostingDate: Date; QtyBase: Decimal; QtyPerUOM: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := QtyBase;
        ValueEntry.SetRange("Document Type", ValueEntryDocType);
        ValueEntry.SetRange("Document No.", DocNo);
        ValueEntry.SetRange("Document Line No.", DocLineNo);
        ValueEntry.SetRange("Posting Date", PostingDate);
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetRange("Item No.", ItemNo);
        if ValueEntry.Find('-') then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    if QtyPerUOM <> 0 then
                        Quantity := Round(ValueEntry."Invoiced Quantity" / QtyPerUOM, UOMMgt.QtyRndPrecision())
                    else
                        Quantity := ValueEntry."Invoiced Quantity";
                    AddBufferEntry(
                      Abs(Quantity),
                      ItemLedgerEntry."Posting Date",
                      ItemLedgerEntry."Document No.",
                      DocLineNo, LineType, ItemNo);
                    TotalQuantity := TotalQuantity + ValueEntry."Invoiced Quantity";
                end;
            until (ValueEntry.Next() = 0) or (TotalQuantity = 0);
    end;

    local procedure GenerateBufferFromShipment(SalesInvoiceLine2: Record "Sales Invoice Line"; SalesInvoiceHeader2: Record "Sales Invoice Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        if SalesInvoiceHeader2."Order No." = '' then
            exit;

        TotalQuantity := 0;
        SalesInvoiceHeader.SetCurrentKey("Order No.");
        SalesInvoiceHeader.SetFilter("No.", '..%1', SalesInvoiceHeader2."No.");
        SalesInvoiceHeader.SetRange("Order No.", SalesInvoiceHeader2."Order No.");
        if SalesInvoiceHeader.FindSet() then
            repeat
                SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                SalesInvoiceLine.SetRange("Line No.", SalesInvoiceLine2."Line No.");
                SalesInvoiceLine.SetRange(Type, SalesInvoiceLine2.Type);
                SalesInvoiceLine.SetRange("No.", SalesInvoiceLine2."No.");
                SalesInvoiceLine.SetRange("Unit of Measure Code", SalesInvoiceLine2."Unit of Measure Code");
                if not SalesInvoiceLine.IsEmpty() then begin
                    SalesInvoiceLine.CalcSums(Quantity);
                    TotalQuantity += SalesInvoiceLine.Quantity;
                end;
            until SalesInvoiceHeader.Next() = 0;

        SalesShipmentLine.SetCurrentKey("Order No.", "Order Line No.", "Posting Date");
        SalesShipmentLine.SetRange("Order No.", SalesInvoiceHeader2."Order No.");
        SalesShipmentLine.SetRange("Order Line No.", SalesInvoiceLine2."Line No.");
        SalesShipmentLine.SetRange("Line No.", SalesInvoiceLine2."Line No.");
        SalesShipmentLine.SetRange(Type, SalesInvoiceLine2.Type);
        SalesShipmentLine.SetRange("No.", SalesInvoiceLine2."No.");
        SalesShipmentLine.SetRange("Unit of Measure Code", SalesInvoiceLine2."Unit of Measure Code");
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        if SalesShipmentLine.FindSet() then
            repeat
                if SalesInvoiceHeader2."Get Shipment Used" then
                    CorrectShipment(SalesShipmentLine);
                if Abs(SalesShipmentLine.Quantity) <= Abs(TotalQuantity - SalesInvoiceLine2.Quantity) then
                    TotalQuantity := TotalQuantity - SalesShipmentLine.Quantity
                else begin
                    if Abs(SalesShipmentLine.Quantity) > Abs(TotalQuantity) then
                        SalesShipmentLine.Quantity := TotalQuantity;
                    Quantity :=
                      SalesShipmentLine.Quantity - (TotalQuantity - SalesInvoiceLine2.Quantity);

                    TotalQuantity := TotalQuantity - SalesShipmentLine.Quantity;
                    SalesInvoiceLine.Quantity := SalesInvoiceLine.Quantity - Quantity;

                    if SalesShipmentHeader.Get(SalesShipmentLine."Document No.") then
                        AddBufferEntry(
                          Quantity,
                          SalesShipmentHeader."Posting Date",
                          SalesShipmentHeader."No.",
                          SalesInvoiceLine2."Line No.",
                          SalesInvoiceLine2.Type,
                          SalesInvoiceLine2."No.");
                end;
            until (SalesShipmentLine.Next() = 0) or (TotalQuantity = 0);
    end;

    local procedure GenerateBufferFromReceipt(SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        SalesCrMemoLine2: Record "Sales Cr.Memo Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        if SalesCrMemoHeader."Return Order No." = '' then
            exit;

        TotalQuantity := 0;
        SalesCrMemoHeader2.SetCurrentKey("Return Order No.");
        SalesCrMemoHeader2.SetFilter("No.", '..%1', SalesCrMemoHeader."No.");
        SalesCrMemoHeader2.SetRange("Return Order No.", SalesCrMemoHeader."Return Order No.");
        if SalesCrMemoHeader2.Find('-') then
            repeat
                SalesCrMemoLine2.SetRange("Document No.", SalesCrMemoHeader2."No.");
                SalesCrMemoLine2.SetRange("Line No.", SalesCrMemoLine."Line No.");
                SalesCrMemoLine2.SetRange(Type, SalesCrMemoLine.Type);
                SalesCrMemoLine2.SetRange("No.", SalesCrMemoLine."No.");
                SalesCrMemoLine2.SetRange("Unit of Measure Code", SalesCrMemoLine."Unit of Measure Code");
                SalesCrMemoLine2.CalcSums(Quantity);
                TotalQuantity := TotalQuantity + SalesCrMemoLine2.Quantity;
            until SalesCrMemoHeader2.Next() = 0;

        ReturnReceiptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
        ReturnReceiptLine.SetRange("Return Order No.", SalesCrMemoHeader."Return Order No.");
        ReturnReceiptLine.SetRange("Return Order Line No.", SalesCrMemoLine."Line No.");
        ReturnReceiptLine.SetRange("Line No.", SalesCrMemoLine."Line No.");
        ReturnReceiptLine.SetRange(Type, SalesCrMemoLine.Type);
        ReturnReceiptLine.SetRange("No.", SalesCrMemoLine."No.");
        ReturnReceiptLine.SetRange("Unit of Measure Code", SalesCrMemoLine."Unit of Measure Code");
        ReturnReceiptLine.SetFilter(Quantity, '<>%1', 0);

        if ReturnReceiptLine.Find('-') then
            repeat
                if SalesCrMemoHeader."Get Return Receipt Used" then
                    CorrectReceipt(ReturnReceiptLine);
                if Abs(ReturnReceiptLine.Quantity) <= Abs(TotalQuantity - SalesCrMemoLine.Quantity) then
                    TotalQuantity := TotalQuantity - ReturnReceiptLine.Quantity
                else begin
                    if Abs(ReturnReceiptLine.Quantity) > Abs(TotalQuantity) then
                        ReturnReceiptLine.Quantity := TotalQuantity;
                    Quantity :=
                      ReturnReceiptLine.Quantity - (TotalQuantity - SalesCrMemoLine.Quantity);

                    SalesCrMemoLine.Quantity := SalesCrMemoLine.Quantity - Quantity;
                    TotalQuantity := TotalQuantity - ReturnReceiptLine.Quantity;

                    if ReturnReceiptHeader.Get(ReturnReceiptLine."Document No.") then
                        AddBufferEntry(
                          Quantity,
                          ReturnReceiptHeader."Posting Date",
                          ReturnReceiptHeader."No.",
                          SalesCrMemoLine."Line No.",
                          SalesCrMemoLine.Type,
                          SalesCrMemoLine."No.");
                end;
            until (ReturnReceiptLine.Next() = 0) or (TotalQuantity = 0);
    end;

    local procedure AddBufferEntry(QtyOnShipment: Decimal; PostingDate: Date; ShipmentNo: Code[20]; DocLineNo: Integer; LineType: Enum "Sales Line Type"; ItemNo: Code[20])
    begin
        SetRange("Document No.", ShipmentNo);
        SetRange("Line No.", DocLineNo);
        SetRange("Posting Date", PostingDate);
        if FindFirst() then begin
            Quantity += QtyOnShipment;
            Modify();
            exit;
        end;

        NextEntryNo := NextEntryNo + 1;
        "Document No." := ShipmentNo;
        "Line No." := DocLineNo;
        "Entry No." := NextEntryNo;
        Type := LineType;
        "No." := ItemNo;
        Quantity := QtyOnShipment;
        "Posting Date" := PostingDate;
        Insert();
    end;

    local procedure CorrectShipment(var SalesShipmentLine: Record "Sales Shipment Line")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetCurrentKey("Shipment No.", "Shipment Line No.");
        SalesInvoiceLine.SetRange("Shipment No.", SalesShipmentLine."Document No.");
        SalesInvoiceLine.SetRange("Shipment Line No.", SalesShipmentLine."Line No.");
        SalesInvoiceLine.CalcSums(Quantity);
        SalesShipmentLine.Quantity := SalesShipmentLine.Quantity - SalesInvoiceLine.Quantity;

        OnAfterCorrectShipment(SalesInvoiceLine, SalesShipmentLine);
    end;

    local procedure CorrectReceipt(var ReturnReceiptLine: Record "Return Receipt Line")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetCurrentKey("Return Receipt No.", "Return Receipt Line No.");
        SalesCrMemoLine.SetRange("Return Receipt No.", ReturnReceiptLine."Document No.");
        SalesCrMemoLine.SetRange("Return Receipt Line No.", ReturnReceiptLine."Line No.");
        SalesCrMemoLine.CalcSums(Quantity);
        ReturnReceiptLine.Quantity := ReturnReceiptLine.Quantity - SalesCrMemoLine.Quantity;

        OnAfterCorrectReceipt(SalesCrMemoLine, ReturnReceiptLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCorrectShipment(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCorrectReceipt(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;
}

