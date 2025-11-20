// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Sales.History;

codeunit 6638 "Sales-Get Return Receipts"
{
    TableNo = "Sales Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        CheckHeader(Rec);

        ReturnRcptLine.SetCurrentKey("Bill-to Customer No.");
        ReturnRcptLine.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        ReturnRcptLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
        ReturnRcptLine.SetRange("Currency Code", SalesHeader."Currency Code");
        OnRunOnAfterSetReturnRcptLineFilters(ReturnRcptLine, SalesHeader);

        IsHandled := false;
        OnRunOnBeforeGetReturnRcptLines(ReturnRcptLine, SalesHeader, IsHandled);
        if not IsHandled then begin
            GetReturnRcptLines.SetTableView(ReturnRcptLine);
            GetReturnRcptLines.LookupMode := true;
            GetReturnRcptLines.SetSalesHeader(SalesHeader);
            GetReturnRcptLines.RunModal();
        end;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        GetReturnRcptLines: Page "Get Return Receipt Lines";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CreateInvLines(var ReturnRcptLine2: Record "Return Receipt Line")
    var
        DifferentCurrencies: Boolean;
        ShouldInsertReturnRcptLine: Boolean;
        IsHandled: Boolean;
    begin
        ReturnRcptLine2.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
        OnCreateInvLinesOnAfterReturnRcptLine2SetFilters(ReturnRcptLine2, SalesHeader);
        if ReturnRcptLine2.Find('-') then begin
            SalesLine.LockTable();
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";

            IsHandled := false;
            OnCreateInvLinesOnBeforeLoopReturnRcptLines(ReturnRcptLine2, SalesLine, ReturnRcptHeader, IsHandled);
            if IsHandled then
                exit;

            repeat
                if ReturnRcptHeader."No." <> ReturnRcptLine2."Document No." then begin
                    ReturnRcptHeader.Get(ReturnRcptLine2."Document No.");
                    CheckReturnReceiptBillToCustomerNo(ReturnRcptHeader, SalesHeader, ReturnRcptLine2);
                    DifferentCurrencies := false;
                    if ReturnRcptHeader."Currency Code" <> SalesHeader."Currency Code" then begin
                        Message(Text001,
                          SalesHeader.FieldCaption("Currency Code"),
                          SalesHeader.TableCaption, SalesHeader."No.",
                          ReturnRcptHeader.TableCaption(), ReturnRcptHeader."No.");
                        DifferentCurrencies := true;
                    end;
                    OnBeforeTransferLineToSalesDoc(ReturnRcptHeader, ReturnRcptLine2, SalesHeader, DifferentCurrencies);
                end;
                ShouldInsertReturnRcptLine := not DifferentCurrencies;
                OnCreateInvLinesOnAfterCalcShouldInsertReturnRcptLine(ReturnRcptHeader, ReturnRcptLine2, SalesHeader, ShouldInsertReturnRcptLine);
                if ShouldInsertReturnRcptLine then begin
                    ReturnRcptLine := ReturnRcptLine2;
                    CheckReturnReceiptLineVATBusPostingGroup(ReturnRcptLine2, SalesHeader);
                    ReturnRcptLine.InsertInvLineFromRetRcptLine(SalesLine);
                    if ReturnRcptLine2.Type = ReturnRcptLine2.Type::"Charge (Item)" then
                        GetItemChargeAssgnt(ReturnRcptLine2, SalesLine."Qty. to Invoice");
                end;
                OnCreateInvLinesOnAfterReturnRcptLoop(ShouldInsertReturnRcptLine, ReturnRcptHeader, ReturnRcptLine2, SalesHeader, SalesLine);
            until ReturnRcptLine2.Next() = 0;
        end;

        OnAfterCreateInvLines(SalesHeader);
    end;

    local procedure CheckReturnReceiptLineVATBusPostingGroup(ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestReturnReceiptLineVATBusPostingGroup(ReturnReceiptLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        ReturnReceiptLine.TestField("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
    end;

    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSetSalesHeaderOnBeforeTestIsCreditMemo(SalesHeader, IsHandled);
        if not IsHandled then begin
            SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
            SalesHeader.TestField("Document Type", SalesHeader."Document Type"::"Credit Memo");
        end;
    end;

    local procedure CheckHeader(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckHeader(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure CheckReturnReceiptBillToCustomerNo(ReturnReceiptHeader: Record "Return Receipt Header"; SalesHeader2: Record "Sales Header"; ReturnReceiptLine: Record "Return Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnReceiptBillToCustomerNo(ReturnReceiptHeader, SalesHeader2, ReturnReceiptLine, IsHandled);
        if IsHandled then
            exit;

        ReturnReceiptHeader.TestField("Bill-to Customer No.", ReturnReceiptLine."Bill-to Customer No.");
    end;

    procedure GetItemChargeAssgnt(var ReturnRcptLine: Record "Return Receipt Line"; QtyToInv: Decimal)
    var
        SalesOrderLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        if SalesOrderLine.Get(SalesOrderLine."Document Type"::"Return Order", ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.")
            then begin
            ItemChargeAssgntSales.LockTable();
            ItemChargeAssgntSales.Reset();
            ItemChargeAssgntSales.SetRange("Document Type", SalesOrderLine."Document Type");
            ItemChargeAssgntSales.SetRange("Document No.", SalesOrderLine."Document No.");
            ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
            if ItemChargeAssgntSales.FindFirst() then begin
                ItemChargeAssgntSales.CalcSums("Qty. to Assign");
                if ItemChargeAssgntSales."Qty. to Assign" <> 0 then
                    CopyItemChargeAssgnt(
                      SalesOrderLine, ReturnRcptLine, ItemChargeAssgntSales."Qty. to Assign",
                      QtyToInv / ItemChargeAssgntSales."Qty. to Assign");
            end;
        end;
    end;

    local procedure CopyItemChargeAssgnt(SalesOrderLine: Record "Sales Line"; ReturnRcptLine: Record "Return Receipt Line"; QtyToAssign: Decimal; QtyFactor: Decimal)
    var
        ReturnRcptLine2: Record "Return Receipt Line";
        SalesLine2: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        InsertChargeAssgnt: Boolean;
    begin
        ItemChargeAssgntSales.SetRange("Document Type", SalesOrderLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesOrderLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
        if ItemChargeAssgntSales.Find('-') then
            repeat
                if ItemChargeAssgntSales."Qty. to Assign" <> 0 then begin
                    ItemChargeAssgntSales2 := ItemChargeAssgntSales;
                    ItemChargeAssgntSales2."Qty. to Assign" :=
                      Round(QtyFactor * ItemChargeAssgntSales2."Qty. to Assign", UOMMgt.QtyRndPrecision());
                    SalesLine2.SetRange("Return Receipt No.", ReturnRcptLine."Document No.");
                    SalesLine2.SetRange("Return Receipt Line No.", ReturnRcptLine."Line No.");
                    if SalesLine2.Find('-') then
                        repeat
                            SalesLine2.CalcFields("Qty. to Assign");
                            InsertChargeAssgnt := SalesLine2."Qty. to Assign" <> SalesLine2.Quantity;
                        until (SalesLine2.Next() = 0) or InsertChargeAssgnt;

                    if InsertChargeAssgnt then begin
                        ItemChargeAssgntSales2."Document Type" := SalesLine2."Document Type";
                        ItemChargeAssgntSales2."Document No." := SalesLine2."Document No.";
                        ItemChargeAssgntSales2."Document Line No." := SalesLine2."Line No.";
                        ItemChargeAssgntSales2."Qty. Assigned" := 0;
                        if Abs(QtyToAssign) < Abs(ItemChargeAssgntSales2."Qty. to Assign") then
                            ItemChargeAssgntSales2."Qty. to Assign" := QtyToAssign;
                        if Abs(SalesLine2.Quantity - SalesLine2."Qty. to Assign") <
                           Abs(ItemChargeAssgntSales2."Qty. to Assign")
                        then
                            ItemChargeAssgntSales2."Qty. to Assign" :=
                              SalesLine2.Quantity - SalesLine2."Qty. to Assign";
                        ItemChargeAssgntSales2.Validate("Unit Cost");

                        if ItemChargeAssgntSales2."Applies-to Doc. Type" = SalesOrderLine."Document Type" then begin
                            ItemChargeAssgntSales2."Applies-to Doc. Type" := SalesLine2."Document Type";
                            ItemChargeAssgntSales2."Applies-to Doc. No." := SalesLine2."Document No.";
                            ReturnRcptLine2.SetCurrentKey("Return Order No.", "Return Order Line No.");
                            ReturnRcptLine2.SetRange("Return Order No.", ItemChargeAssgntSales."Applies-to Doc. No.");
                            ReturnRcptLine2.SetRange("Return Order Line No.", ItemChargeAssgntSales."Applies-to Doc. Line No.");
                            ReturnRcptLine2.SetFilter(Quantity, '<>0');
                            if ReturnRcptLine2.FindFirst() then begin
                                SalesLine2.SetCurrentKey("Document Type", "Shipment No.", "Shipment Line No.");
                                SalesLine2.SetRange("Document Type", SalesOrderLine."Document Type"::"Credit Memo");
                                SalesLine2.SetRange("Return Receipt No.", ReturnRcptLine2."Document No.");
                                SalesLine2.SetRange("Return Receipt Line No.", ReturnRcptLine2."Line No.");
                                if SalesLine2.Find('-') and (SalesLine2.Quantity <> 0) then
                                    ItemChargeAssgntSales2."Applies-to Doc. Line No." := SalesLine2."Line No."
                                else
                                    InsertChargeAssgnt := false;
                            end else
                                InsertChargeAssgnt := false;
                        end;
                    end;

                    if InsertChargeAssgnt and (ItemChargeAssgntSales2."Qty. to Assign" <> 0) then begin
                        ItemChargeAssgntSales2.Insert();
                        QtyToAssign := QtyToAssign - ItemChargeAssgntSales2."Qty. to Assign";
                    end;
                end;
            until ItemChargeAssgntSales.Next() = 0;
    end;

    procedure GetSalesRetOrderCrMemos(var TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary; ReturnOrderNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemosByRetOrder: Query "Sales Cr. Memos By Ret. Order";
    begin
        TempSalesCrMemoHeader.Reset();
        TempSalesCrMemoHeader.DeleteAll();

        SalesCrMemosByRetOrder.SetRange(Order_No_, ReturnOrderNo);
        SalesCrMemosByRetOrder.SetFilter(Quantity, '<>0');
        SalesCrMemosByRetOrder.Open();

        while SalesCrMemosByRetOrder.Read() do begin
            SalesCrMemoHeader.Get(SalesCrMemosByRetOrder.Document_No_);
            TempSalesCrMemoHeader := SalesCrMemoHeader;
            TempSalesCrMemoHeader.Insert();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineToSalesDoc(ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line"; var SalesHeader: Record "Sales Header"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterCalcShouldInsertReturnRcptLine(var ReturnReceiptHeader: Record "Return Receipt Header"; var ReturnReceiptLine: Record "Return Receipt Line"; var SalesHeader: Record "Sales Header"; var ShouldInsertReturnRcptLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterReturnRcptLine2SetFilters(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterReturnRcptLoop(ShouldInsertReturnRcptLine: Boolean; ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetReturnRcptLineFilters(var ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestReturnReceiptLineVATBusPostingGroup(ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGetReturnRcptLines(var ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnBeforeLoopReturnRcptLines(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var ReturnReceiptHeader: Record "Return Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnReceiptBillToCustomerNo(ReturnReceiptHeader: Record "Return Receipt Header"; SalesHeader: Record "Sales Header"; var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckHeader(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSalesHeaderOnBeforeTestIsCreditMemo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

