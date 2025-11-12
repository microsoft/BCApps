// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.UOM;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

codeunit 64 "Sales-Get Shipment"
{
    TableNo = "Sales Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        SalesShptLine.SetCurrentKey("Bill-to Customer No.");
        SalesShptLine.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesShptLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        SalesShptLine.SetRange("Currency Code", SalesHeader."Currency Code");
        SalesShptLine.SetRange("Authorized for Credit Card", false);

        IsHandled := false;
        OnRunAfterFilterSalesShpLine(SalesShptLine, SalesHeader, IsHandled);
        if not IsHandled then begin
            GetShipments.SetTableView(SalesShptLine);
            GetShipments.SetSalesHeader(SalesHeader);
            GetShipments.LookupMode := true;
            if GetShipments.RunModal() <> ACTION::Cancel then;
        end;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        TempSalesLine: Record "Sales Line" temporary;
        UOMMgt: Codeunit "Unit of Measure Management";
        GetShipments: Page "Get Shipment Lines";
        LineListHasAttachments: Dictionary of [Code[20], Boolean];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
#pragma warning restore AA0470
        Text002: Label 'Creating Sales Invoice Lines\';
#pragma warning disable AA0470
        Text003: Label 'Inserted lines             #1######';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CannotCombineShptsDiffTaxLiableErr: Label 'You cannot combine shipments from orders which have different values of Tax Liable.';

    procedure CreateInvLines(var SalesShptLine2: Record "Sales Shipment Line")
    var
        Window: Dialog;
        LineCount: Integer;
        TransferLine: Boolean;
        PrepmtAmtToDeductRounding: Decimal;
        IsHandled: Boolean;
        OrderNoList: List of [Code[20]];
        TaxLiable: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateInvLines(SalesShptLine2, SalesHeader, SalesLine, SalesShptHeader, IsHandled);
        if IsHandled then
            exit;

        TempSalesLine.DeleteAll();

        SalesShptLine2.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        OnCreateInvLinesOnBeforeFind(SalesShptLine2, SalesHeader);
        if SalesShptLine2.FindSet() then begin
            SalesLine.LockTable();
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            OnCreateInvLinesOnAfterSalesShptLineSetFilters(SalesShptLine2, SalesHeader);
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            TaxLiable := SalesShptLine2."Tax Liable";
            Window.Open(Text002 + Text003);
            OnBeforeInsertLines(SalesHeader);

            repeat
                LineCount := LineCount + 1;
                Window.Update(1, LineCount);
                if SalesShptHeader."No." <> SalesShptLine2."Document No." then begin
                    SalesShptHeader.Get(SalesShptLine2."Document No.");
                    TransferLine := true;
                    if SalesShptHeader."Currency Code" <> SalesHeader."Currency Code" then begin
                        Message(
                          Text001,
                          SalesHeader.FieldCaption("Currency Code"),
                          SalesHeader.TableCaption(), SalesHeader."No.",
                          SalesShptHeader.TableCaption(), SalesShptHeader."No.");
                        TransferLine := false;
                    end;
                    if SalesShptHeader."Bill-to Customer No." <> SalesHeader."Bill-to Customer No." then begin
                        Message(
                          Text001,
                          SalesHeader.FieldCaption("Bill-to Customer No."),
                          SalesHeader.TableCaption(), SalesHeader."No.",
                          SalesShptHeader.TableCaption(), SalesShptHeader."No.");
                        TransferLine := false;
                    end;
                    if TaxLiable <> SalesShptLine2."Tax Liable" then
                        Error(CannotCombineShptsDiffTaxLiableErr);
                    OnBeforeTransferLineToSalesDoc(SalesShptHeader, SalesShptLine2, SalesHeader, TransferLine);
                end;
                InsertInvoiceLineFromShipmentLine(SalesShptLine2, TransferLine, PrepmtAmtToDeductRounding);
                OnAfterInsertLine(SalesShptLine, SalesLine, SalesShptLine2, TransferLine, SalesHeader);
                if SalesShptLine2."Order No." <> '' then
                    if not OrderNoList.Contains(SalesShptLine2."Order No.") then
                        OrderNoList.Add(SalesShptLine2."Order No.");
            until SalesShptLine2.Next() = 0;

            UpdateItemChargeLines();

            AdjustPrepmtAmtToDeductRoundingOrderLineWise(PrepmtAmtToDeductRounding, SalesHeader);

            if SalesLine.Find() then;

            OnAfterInsertLines(SalesHeader, SalesLine);
            CalcInvoiceDiscount(SalesLine);

            if TransferLine then
                AdjustPrepmtAmtToDeductRounding(SalesLine, PrepmtAmtToDeductRounding);
            CopyDocumentAttachments(OrderNoList, SalesHeader);
        end;
        OnAfterCreateInvLines(SalesShptLine2, SalesHeader, SalesLine, SalesShptHeader);
    end;

    procedure InsertInvoiceLineFromShipmentLine(var SalesShptLine2: Record "Sales Shipment Line"; TransferLine: Boolean; var PrepmtAmtToDeductRounding: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertInvoiceLineFromShipmentLine(SalesShptHeader, SalesShptLine2, SalesHeader, PrepmtAmtToDeductRounding, TransferLine, IsHandled, SalesShptLine, SalesLine);
        if IsHandled then
            exit;

        if TransferLine then begin
            SalesShptLine := SalesShptLine2;
            CheckSalesShptLineVATBusPostingGroup(SalesShptLine, SalesHeader);
            SalesShptLine.InsertInvLineFromShptLine(SalesLine);
            CalcUpdatePrepmtAmtToDeductRounding(SalesShptLine, SalesLine, PrepmtAmtToDeductRounding);
            CopyDocumentAttachments(SalesShptLine2, SalesLine);
        end;
    end;

    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalesHeader(SalesHeader, SalesHeader2, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
    end;

    procedure UpdateItemChargeLines()
    var
        SalesShipmentLineLocal: Record "Sales Shipment Line";
        SalesLineChargeItemUpdate: Record "Sales Line";
    begin
        SalesLineChargeItemUpdate.SetRange("Document Type", SalesLine."Document Type");
        SalesLineChargeItemUpdate.SetRange("Document No.", SalesLine."Document No.");
        SalesLineChargeItemUpdate.SetRange(Type, SalesLineChargeItemUpdate.Type::"Charge (Item)");
        if SalesLineChargeItemUpdate.FindSet() then
            repeat
                if SalesShipmentLineLocal.Get(
                    SalesLineChargeItemUpdate."Shipment No.", SalesLineChargeItemUpdate."Shipment Line No.")
                then
                    GetItemChargeAssgnt(SalesShipmentLineLocal, SalesLineChargeItemUpdate."Qty. to Invoice");
            until SalesLineChargeItemUpdate.Next() = 0;
    end;

    procedure GetItemChargeAssgnt(var SalesShptLine: Record "Sales Shipment Line"; QtyToInvoice: Decimal)
    var
        SalesOrderLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemChargeAssgnt(SalesShptLine, QtyToInvoice, IsHandled);
        if IsHandled then
            exit;

        if not SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.") then
            exit;

        ItemChargeAssgntSales.LockTable();
        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", SalesOrderLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesOrderLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
        if ItemChargeAssgntSales.FindFirst() then begin
            ItemChargeAssgntSales.CalcSums("Qty. to Assign");
            if ItemChargeAssgntSales."Qty. to Assign" <> 0 then
                CopyItemChargeAssgnt(
                  SalesOrderLine, SalesShptLine, ItemChargeAssgntSales."Qty. to Assign", QtyToInvoice / ItemChargeAssgntSales."Qty. to Assign");
        end;
    end;

    local procedure CopyItemChargeAssgnt(SalesOrderLine: Record "Sales Line"; SalesShptLine: Record "Sales Shipment Line"; QtyToAssign: Decimal; QtyFactor: Decimal)
    var
        SalesShptLine2: Record "Sales Shipment Line";
        SalesLine2: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        InsertChargeAssgnt: Boolean;
        IsHandled: Boolean;
        LineQtyToAssign: Decimal;
    begin
        IsHandled := false;
        OnBeforeCopyItemChargeAssgnt(SalesOrderLine, SalesShptLine, QtyToAssign, QtyFactor, IsHandled);
        if IsHandled then
            exit;

        ItemChargeAssgntSales.SetRange("Document Type", SalesOrderLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesOrderLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
        if ItemChargeAssgntSales.FindSet() then
            repeat
                if ItemChargeAssgntSales."Qty. to Assign" <> 0 then begin
                    ItemChargeAssgntSales2 := ItemChargeAssgntSales;
                    ItemChargeAssgntSales2."Qty. to Assign" :=
                      Round(QtyFactor * ItemChargeAssgntSales2."Qty. to Assign", UOMMgt.QtyRndPrecision());
                    ItemChargeAssgntSales2.Validate("Qty. to Handle", ItemChargeAssgntSales2."Qty. to Assign");
                    SalesLine2.SetRange("Shipment No.", SalesShptLine."Document No.");
                    SalesLine2.SetRange("Shipment Line No.", SalesShptLine."Line No.");
                    if SalesLine2.FindSet() then
                        repeat
                            SalesLine2.CalcFields("Qty. to Assign");
                            InsertChargeAssgnt := SalesLine2."Qty. to Assign" <> SalesLine2.Quantity;
                        until (SalesLine2.Next() = 0) or InsertChargeAssgnt;

                    if InsertChargeAssgnt then begin
                        ItemChargeAssgntSales2."Document Type" := SalesLine2."Document Type";
                        ItemChargeAssgntSales2."Document No." := SalesLine2."Document No.";
                        ItemChargeAssgntSales2."Document Line No." := SalesLine2."Line No.";
                        ItemChargeAssgntSales2."Qty. Assigned" := 0;
                        LineQtyToAssign :=
                          ItemChargeAssgntSales2."Qty. to Assign" - GetQtyAssignedInNewLine(ItemChargeAssgntSales2);
                        InsertChargeAssgnt := LineQtyToAssign <> 0;
                        if InsertChargeAssgnt then begin
                            if Abs(QtyToAssign) < Abs(LineQtyToAssign) then
                                ItemChargeAssgntSales2."Qty. to Assign" := QtyToAssign;
                            if Abs(SalesLine2.Quantity - SalesLine2."Qty. to Assign") <
                               Abs(LineQtyToAssign)
                            then
                                ItemChargeAssgntSales2."Qty. to Assign" :=
                                  SalesLine2.Quantity - SalesLine2."Qty. to Assign";
                            ItemChargeAssgntSales2.Validate("Unit Cost");

                            if ItemChargeAssgntSales2."Applies-to Doc. Type" = SalesOrderLine."Document Type" then begin
                                ItemChargeAssgntSales2."Applies-to Doc. Type" := SalesLine2."Document Type";
                                ItemChargeAssgntSales2."Applies-to Doc. No." := SalesLine2."Document No.";
                                SetShipmentLineFilters(SalesShptLine2, ItemChargeAssgntSales, SalesLine2);
                                if SalesShptLine2.FindFirst() then begin
                                    SalesLine2.SetCurrentKey("Document Type", "Shipment No.", "Shipment Line No.");
                                    SalesLine2.SetRange("Document Type", SalesOrderLine."Document Type"::Invoice);
                                    SalesLine2.SetRange("Shipment No.", SalesShptLine2."Document No.");
                                    SalesLine2.SetRange("Shipment Line No.", SalesShptLine2."Line No.");

                                    OnCopyItemChargeAssgntOnBeforeFindSalesLine2(SalesLine2, ItemChargeAssgntSales2, SalesShptLine);
                                    if SalesLine2.FindFirst() and (SalesLine2.Quantity <> 0) then
                                        ItemChargeAssgntSales2."Applies-to Doc. Line No." := SalesLine2."Line No."
                                    else
                                        InsertChargeAssgnt := false;
                                end else
                                    InsertChargeAssgnt := false;
                            end;
                        end;
                    end;

                    if InsertChargeAssgnt and (ItemChargeAssgntSales2."Qty. to Assign" <> 0) then begin
                        ItemChargeAssgntSales2.Insert();
                        QtyToAssign := QtyToAssign - ItemChargeAssgntSales2."Qty. to Assign";
                    end;
                end;
            until ItemChargeAssgntSales.Next() = 0;
    end;

    local procedure SetShipmentLineFilters(var SalesShptLine2: Record "Sales Shipment Line"; var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var SalesLine2: Record "Sales Line")
    begin
        SalesShptLine2.SetCurrentKey("Order No.", "Order Line No.");
        SalesShptLine2.SetRange("Order No.", ItemChargeAssgntSales."Applies-to Doc. No.");
        SalesShptLine2.SetRange("Order Line No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
        SalesShptLine2.SetRange(Correction, false);
        SalesShptLine2.SetFilter(Quantity, '<>0');
        if (SalesLine2."Shipment No." <> '') then
            if CheckSalesShipmentLine(SalesLine2) then
                SalesShptLine2.SetRange("Document No.", SalesLine2."Shipment No.");
    end;

    local procedure CheckSalesShipmentLine(var SalesLine2: Record "Sales Line"): Boolean
    var
        SalesShptLine2: Record "Sales Shipment Line";
    begin
        if SalesLine2."Shipment No." = '' then
            exit;
        SalesShptLine2.SetRange("Document No.", SalesLine2."Shipment No.");
        SalesShptLine2.SetRange(Type, SalesLine2.Type::Item);
        SalesShptLine2.SetFilter(Quantity, '<>0');
        if not SalesShptLine2.IsEmpty() then
            exit(true);
    end;

    local procedure GetQtyAssignedInNewLine(ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"): Decimal
    begin
        ItemChargeAssgntSales.SetRange("Document Type", ItemChargeAssgntSales."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", ItemChargeAssgntSales."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", ItemChargeAssgntSales."Document Line No.");
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Type", ItemChargeAssgntSales."Applies-to Doc. Type");
        ItemChargeAssgntSales.SetRange("Applies-to Doc. No.", ItemChargeAssgntSales."Applies-to Doc. No.");
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
        ItemChargeAssgntSales.CalcSums("Qty. to Assign");
        exit(ItemChargeAssgntSales."Qty. to Assign");
    end;

    procedure CalcInvoiceDiscount(var SalesLine: Record "Sales Line")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Calc. Inv. Discount" then begin
            SalesCalcDiscount.CalculateInvoiceDiscountOnLine(SalesLine);
            OnAfterCalcInvoiceDiscount(SalesLine);
        end;
    end;

    procedure CalcUpdatePrepmtAmtToDeductRounding(SalesShptLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; var RoundingAmount: Decimal)
    var
        SalesOrderLine: Record "Sales Line";
        Fraction: Decimal;
        FractionAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcUpdatePrepmtAmtToDeductRounding(SalesShptLine, SalesLine, RoundingAmount, IsHandled);
        if IsHandled then
            exit;

        if (SalesLine."Prepayment %" > 0) and (SalesLine."Prepayment %" < 100) and
           (SalesLine."Document Type" = SalesLine."Document Type"::Invoice)
        then begin
            SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.");
            if (SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced") <> 0 then begin
                Fraction := (SalesShptLine.Quantity - SalesShptLine."Quantity Invoiced") / (SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced");
                FractionAmount := Fraction * (SalesOrderLine."Prepmt. Amt. Inv." - SalesOrderLine."Prepmt Amt Deducted");
                RoundingAmount += SalesLine."Prepmt Amt to Deduct" - FractionAmount;
                if (SalesLine."Prepmt Amt to Deduct" - FractionAmount) <> 0 then
                    InsertTempSalesLine(SalesShptLine, SalesOrderLine, SalesLine, FractionAmount);
            end else
                RoundingAmount := 0;
        end;
    end;

    procedure AdjustPrepmtAmtToDeductRounding(var SalesLine: Record "Sales Line"; RoundingAmount: Decimal)
    begin
        if Round(RoundingAmount) <> 0 then begin
            SalesLine."Prepmt Amt to Deduct" -= Round(RoundingAmount);
            SalesLine.Modify();
        end;
    end;

    procedure CheckSalesShptLineVATBusPostingGroup(SalesShptLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesShptLineVATBusPostingGroup(SalesShptLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesShptLine.TestField("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
    end;

    procedure GetSalesOrderInvoices(var TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary; OrderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoicesByOrder: Query "Sales Invoices By Order";
    begin
        TempSalesInvoiceHeader.Reset();
        TempSalesInvoiceHeader.DeleteAll();

        SalesInvoicesByOrder.SetRange(Order_No_, OrderNo);
        SalesInvoicesByOrder.SetFilter(Quantity, '<>0');
        SalesInvoicesByOrder.Open();

        while SalesInvoicesByOrder.Read() do begin
            SalesInvoiceHeader.Get(SalesInvoicesByOrder.Document_No_);
            TempSalesInvoiceHeader := SalesInvoiceHeader;
            TempSalesInvoiceHeader.Insert();
        end;
    end;

    procedure CopyDocumentAttachments(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesLine2: Record "Sales Line")
    var
        OrderSalesLine: Record "Sales Line";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
    begin
        if (SalesShipmentLine."Order No." = '') or (SalesShipmentLine."Order Line No." = 0) then
            exit;
        if not AnyLineHasAttachments(SalesShipmentLine."Order No.") then
            exit;
        OrderSalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        OrderSalesLine.SetLoadFields("Document Type", "Document No.", "Line No.");
        if OrderSalesLine.Get(OrderSalesLine."Document Type"::Order, SalesShipmentLine."Order No.", SalesShipmentLine."Order Line No.") then
            DocumentAttachmentMgmt.CopyAttachments(OrderSalesLine, SalesLine2);
    end;

    local procedure CopyDocumentAttachments(OrderNoList: List of [Code[20]]; var SalesHeader2: Record "Sales Header")
    var
        OrderSalesHeader: Record "Sales Header";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        OrderNo: Code[20];
        Handled: Boolean;
    begin
        OnBeforeCopyDocumentAttachments(SalesHeader2, Handled, OrderNoList);
        if Handled then
            exit;
        OrderSalesHeader.ReadIsolation := IsolationLevel::ReadCommitted;
        OrderSalesHeader.SetLoadFields("Document Type", "No.");
        foreach OrderNo in OrderNoList do
            if OrderHasAttachments(OrderNo) then
                if OrderSalesHeader.Get(OrderSalesHeader."Document Type"::Order, OrderNo) then
                    DocumentAttachmentMgmt.CopyAttachments(OrderSalesHeader, SalesHeader2);
    end;

    local procedure OrderHasAttachments(DocNo: Code[20]): boolean
    begin
        exit(EntityHasAttachments(DocNo, Database::"Sales Header"));
    end;

    local procedure AnyLineHasAttachments(DocNo: Code[20]): boolean
    begin
        if not LineListHasAttachments.ContainsKey(DocNo) then
            LineListHasAttachments.Add(DocNo, EntityHasAttachments(DocNo, Database::"Sales Line"));
        exit(LineListHasAttachments.Get(DocNo));
    end;

    local procedure EntityHasAttachments(DocNo: Code[20]; TableNo: Integer): boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.ReadIsolation := IsolationLevel::ReadUncommitted;
        DocumentAttachment.SetRange("Table ID", TableNo);
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Order);
        DocumentAttachment.SetRange("No.", DocNo);
        exit(not DocumentAttachment.IsEmpty());
    end;

    local procedure InsertTempSalesLine(SalesShptLine: Record "Sales Shipment Line"; SalesOrderLine: Record "Sales Line"; SalesLine: Record "Sales Line"; FractionAmount: Decimal)
    begin
        if not TempSalesLine.Get(TempSalesLine."Document Type"::Order, SalesShptLine."Order No.", SalesShptLine."Order Line No.") then begin
            TempSalesLine := SalesOrderLine;
            TempSalesLine.Amount := SalesLine."Prepmt Amt to Deduct" - FractionAmount;
            TempSalesLine."Shipment No." := SalesShptLine."Document No.";
            TempSalesLine."Shipment Line No." := SalesShptLine."Line No.";
            TempSalesLine.Insert();
        end else begin
            TempSalesLine.Amount += SalesLine."Prepmt Amt to Deduct" - FractionAmount;
            TempSalesLine."Shipment No." := SalesShptLine."Document No.";
            TempSalesLine."Shipment Line No." := SalesShptLine."Line No.";
            TempSalesLine.Modify();
        end;
    end;

    local procedure AdjustPrepmtAmtToDeductRoundingOrderLineWise(var PrepmtAmtToDeductRounding: Decimal; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        TempSalesLine.Reset();
        if TempSalesLine.FindSet() then
            repeat
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.SetRange("Shipment No.", TempSalesLine."Shipment No.");
                SalesLine.SetRange("Shipment Line No.", TempSalesLine."Shipment Line No.");
                if SalesLine.FindFirst() then begin
                    AdjustPrepmtAmtToDeductRounding(SalesLine, TempSalesLine.Amount);
                    PrepmtAmtToDeductRounding -= TempSalesLine.Amount;
                end;
            until TempSalesLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscount(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLine(var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line"; SalesShptLine2: Record "Sales Shipment Line"; TransferLine: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcUpdatePrepmtAmtToDeductRounding(SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; var RoundingAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemChargeAssgnt(var SalesOrderLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line"; var QtyToAssign: Decimal; var QtyFactor: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateInvLines(var SalesShipmentLine2: Record "Sales Shipment Line"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvoiceLineFromShipmentLine(SalesShptHeader: Record "Sales Shipment Header"; var SalesShptLine2: Record "Sales Shipment Line"; var SalesHeader: Record "Sales Header"; var PrepmtAmtToDeductRounding: Decimal; TransferLine: Boolean; var IsHandled: Boolean; var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemChargeAssgnt(var SalesShipmentLine: Record "Sales Shipment Line"; QtyToInvoice: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesHeader(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineToSalesDoc(SalesShipmentHeader: Record "Sales Shipment Header"; SalesShipmentLine: Record "Sales Shipment Line"; var SalesHeader: Record "Sales Header"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterSalesShptLineSetFilters(var SalesShipmentLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnBeforeFind(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunAfterFilterSalesShpLine(var SalesShptLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesShptLineVATBusPostingGroup(SalesShptLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateInvLines(var SalesShipmentLine2: Record "Sales Shipment Line"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDocumentAttachments(var DestinationSalesHeader: Record "Sales Header"; var Handled: Boolean; var OrderNoList: List of [Code[20]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemChargeAssgntOnBeforeFindSalesLine2(var SalesLine2: Record "Sales Line"; var ItemChargeAssignmentSales2: Record "Item Charge Assignment (Sales)"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;
}

