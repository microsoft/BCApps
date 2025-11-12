// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.UOM;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;

codeunit 74 "Purch.-Get Receipt"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    begin
        CheckHeader(Rec);

        PurchRcptLine.SetCurrentKey("Pay-to Vendor No.");
        PurchRcptLine.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        PurchRcptLine.SetRange("Currency Code", PurchHeader."Currency Code");

        OnAfterPurchRcptLineSetFilters(PurchRcptLine, PurchHeader);

        GetReceipts.SetTableView(PurchRcptLine);
        GetReceipts.LookupMode := true;
        GetReceipts.SetPurchHeader(PurchHeader);
        GetReceipts.RunModal();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        GetReceipts: Page "Get Receipt Lines";
        LineListHasAttachments: Dictionary of [Code[20], Boolean];

    procedure CreateInvLines(var PurchRcptLine2: Record "Purch. Rcpt. Line")
    var
        TransferLine: Boolean;
        PrepmtAmtToDeductRounding: Decimal;
        IsHandled: Boolean;
        ShowDifferentPayToVendMsg: Boolean;
        OrderNoList: List of [Code[20]];
    begin
        IsHandled := false;
        OnBeforeCreateInvLines(PurchRcptLine2, TransferLine, IsHandled);
        if not IsHandled then begin
            TempPurchaseLine.DeleteAll();

            PurchRcptLine2.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
            OnCreateInvLinesOnBeforeFind(PurchRcptLine2, PurchHeader);
            if PurchRcptLine2.Find('-') then begin
                PurchLine.LockTable();
                PurchLine.SetRange("Document Type", PurchHeader."Document Type");
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                PurchLine."Document Type" := PurchHeader."Document Type";
                PurchLine."Document No." := PurchHeader."No.";

                OnBeforeInsertLines(PurchHeader, PurchLine);

                repeat
                    IsHandled := false;
                    OnCreateInvLinesOnBeforeInsertLineIteration(PurchRcptLine2, PurchRcptHeader, PurchHeader, PurchLine, TransferLine, IsHandled);
                    if not IsHandled then
                        if PurchRcptHeader."No." <> PurchRcptLine2."Document No." then begin
                            PurchRcptHeader.Get(PurchRcptLine2."Document No.");
                            TransferLine := true;
                            if PurchRcptHeader."Currency Code" <> PurchHeader."Currency Code" then begin
                                Message(
                                  Text000,
                                  PurchHeader.FieldCaption("Currency Code"),
                                  PurchHeader.TableCaption(), PurchHeader."No.",
                                  PurchRcptHeader.TableCaption(), PurchRcptHeader."No.");
                                TransferLine := false;
                            end;
                            ShowDifferentPayToVendMsg := PurchRcptHeader."Pay-to Vendor No." <> PurchHeader."Pay-to Vendor No.";
                            OnCreateInvLinesOnAfterCalcShowNotSameVendorsMessage(PurchHeader, PurchRcptHeader, TransferLine, ShowDifferentPayToVendMsg);
                            if ShowDifferentPayToVendMsg then begin
                                Message(
                                  Text000,
                                  PurchHeader.FieldCaption("Pay-to Vendor No."),
                                  PurchHeader.TableCaption(), PurchHeader."No.",
                                  PurchRcptHeader.TableCaption(), PurchRcptHeader."No.");
                                TransferLine := false;
                            end;
                            OnBeforeTransferLineToPurchaseDoc(PurchRcptHeader, PurchRcptLine2, PurchHeader, TransferLine);
                        end;
                    InsertInvoiceLineFromReceiptLine(PurchRcptLine2, TransferLine, PrepmtAmtToDeductRounding);
                    if PurchRcptLine2."Order No." <> '' then
                        if not OrderNoList.Contains(PurchRcptLine2."Order No.") then
                            OrderNoList.Add(PurchRcptLine2."Order No.");
                until PurchRcptLine2.Next() = 0;

                UpdateItemChargeLines();

                AdjustPrepmtAmtToDeductRoundingOrderLineWise(PrepmtAmtToDeductRounding, PurchHeader);

                if PurchLine.Find() then;

                OnAfterInsertLines(PurchHeader);

                CalcInvoiceDiscount(PurchLine);
                OnAfterCalcInvoiceDiscount(PurchHeader);

                if TransferLine then
                    AdjustPrepmtAmtToDeductRounding(PurchLine, PrepmtAmtToDeductRounding);
                CopyDocumentAttachments(OrderNoList, PurchHeader);
            end;
        end;

        OnAfterCreateInvLines(PurchHeader, PurchLine);
    end;

    local procedure CheckHeader(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckHeader(PurchHeader, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        PurchHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Invoice);
        PurchHeader.TestStatusOpen();
    end;

    local procedure InsertInvoiceLineFromReceiptLine(var PurchRcptLine2: Record "Purch. Rcpt. Line"; TransferLine: Boolean; var PrepmtAmtToDeductRounding: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertInvoiceLineFromReceiptLine(PurchRcptHeader, PurchRcptLine2, PurchHeader, TransferLine, PrepmtAmtToDeductRounding, IsHandled);
        if IsHandled then
            exit;

        if TransferLine then begin
            PurchRcptLine := PurchRcptLine2;
            CheckPurchRcptLineVATBusPostingGroup(PurchRcptLine, PurchHeader);
            OnInsertInvoiceLineFromReceiptLineOnBeforeInsertInvLine(PurchRcptLine, PurchLine);
            PurchRcptLine.InsertInvLineFromRcptLine(PurchLine);
            OnInsertInvoiceLineFromRcptLineOnBeforeCalcUpdatePrepmtAmt(PurchRcptLine);
            CalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine, PurchLine, PrepmtAmtToDeductRounding);
            CopyDocumentAttachments(PurchRcptLine, PurchLine);
        end;
        OnAfterInsertInvoiceLineFromReceiptLine(PurchRcptLine, PurchLine, PurchRcptLine2, TransferLine);
    end;

    procedure SetPurchHeader(var PurchHeader2: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPurchHeader(PurchHeader, PurchHeader2, IsHandled);
        if IsHandled then
            exit;

        PurchHeader.Get(PurchHeader2."Document Type", PurchHeader2."No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Invoice);
    end;

    local procedure UpdateItemChargeLines()
    var
        PurchRcptLineLocal: Record "Purch. Rcpt. Line";
        PurchaseLineChargeItemUpdate: Record "Purchase Line";
    begin
        PurchaseLineChargeItemUpdate.SetRange("Document Type", PurchLine."Document Type");
        PurchaseLineChargeItemUpdate.SetRange("Document No.", PurchLine."Document No.");
        PurchaseLineChargeItemUpdate.SetRange(Type, PurchaseLineChargeItemUpdate.Type::"Charge (Item)");
        if PurchaseLineChargeItemUpdate.FindSet() then
            repeat
                if PurchRcptLineLocal.Get(
                    PurchaseLineChargeItemUpdate."Receipt No.", PurchaseLineChargeItemUpdate."Receipt Line No.")
                then
                    GetItemChargeAssgnt(PurchRcptLineLocal, PurchaseLineChargeItemUpdate."Qty. to Invoice");
            until PurchaseLineChargeItemUpdate.Next() = 0;

        if PurchLine.Find() then;
    end;

    procedure GetItemChargeAssgnt(var PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToInvoice: Decimal)
    var
        PurchOrderLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemChargeAssgnt(PurchRcptLine, QtyToInvoice, IsHandled);
        if IsHandled then
            exit;

        if not PurchOrderLine.Get(PurchOrderLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.") then
            exit;

        ItemChargeAssgntPurch.LockTable();
        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", PurchOrderLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchOrderLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", PurchOrderLine."Line No.");
        if ItemChargeAssgntPurch.FindFirst() then begin
            ItemChargeAssgntPurch.CalcSums("Qty. to Assign");
            if ItemChargeAssgntPurch."Qty. to Assign" <> 0 then
                CopyItemChargeAssgnt(
                  PurchOrderLine, PurchRcptLine, ItemChargeAssgntPurch."Qty. to Assign", QtyToInvoice / ItemChargeAssgntPurch."Qty. to Assign");
        end;
    end;

    local procedure CopyItemChargeAssgnt(PurchOrderLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToAssign: Decimal; QtyFactor: Decimal)
    var
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchLine2: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        InsertChargeAssgnt: Boolean;
        LineQtyToAssign: Decimal;
    begin
        ItemChargeAssgntPurch.SetRange("Document Type", PurchOrderLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchOrderLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", PurchOrderLine."Line No.");
        if ItemChargeAssgntPurch.Find('-') then
            repeat
                if ItemChargeAssgntPurch."Qty. to Assign" <> 0 then begin
                    ItemChargeAssgntPurch2 := ItemChargeAssgntPurch;
                    ItemChargeAssgntPurch2."Qty. to Assign" :=
                      Round(QtyFactor * ItemChargeAssgntPurch2."Qty. to Assign", UOMMgt.QtyRndPrecision());
                    ItemChargeAssgntPurch2.Validate("Qty. to Handle", ItemChargeAssgntPurch2."Qty. to Assign");
                    PurchLine2.SetRange("Receipt No.", PurchRcptLine."Document No.");
                    PurchLine2.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
                    if PurchLine2.Find('-') then
                        repeat
                            PurchLine2.CalcFields("Qty. to Assign");
                            InsertChargeAssgnt := PurchLine2."Qty. to Assign" <> PurchLine2.Quantity;
                        until (PurchLine2.Next() = 0) or InsertChargeAssgnt;

                    if InsertChargeAssgnt then begin
                        ItemChargeAssgntPurch2."Document Type" := PurchLine2."Document Type";
                        ItemChargeAssgntPurch2."Document No." := PurchLine2."Document No.";
                        ItemChargeAssgntPurch2."Document Line No." := PurchLine2."Line No.";
                        ItemChargeAssgntPurch2."Qty. Assigned" := 0;
                        LineQtyToAssign :=
                          ItemChargeAssgntPurch2."Qty. to Assign" - GetQtyAssignedInNewLine(ItemChargeAssgntPurch2);
                        InsertChargeAssgnt := LineQtyToAssign <> 0;
                        if InsertChargeAssgnt then begin
                            if Abs(QtyToAssign) < Abs(LineQtyToAssign) then
                                ItemChargeAssgntPurch2."Qty. to Assign" := QtyToAssign;
                            if Abs(PurchLine2.Quantity - PurchLine2."Qty. to Assign") <
                               Abs(LineQtyToAssign)
                            then
                                ItemChargeAssgntPurch2."Qty. to Assign" :=
                                  PurchLine2.Quantity - PurchLine2."Qty. to Assign";
                            ItemChargeAssgntPurch2.Validate("Unit Cost");

                            if ItemChargeAssgntPurch2."Applies-to Doc. Type" = PurchOrderLine."Document Type" then begin
                                ItemChargeAssgntPurch2."Applies-to Doc. Type" := PurchLine2."Document Type";
                                ItemChargeAssgntPurch2."Applies-to Doc. No." := PurchLine2."Document No.";
                                SetReceiptPurchLineFilters(PurchRcptLine2, ItemChargeAssgntPurch, PurchLine2);
                                if PurchRcptLine2.FindFirst() then begin
                                    PurchLine2.SetCurrentKey("Document Type", "Receipt No.", "Receipt Line No.");
                                    PurchLine2.SetRange("Document Type", PurchLine2."Document Type"::Invoice);
                                    PurchLine2.SetRange("Receipt No.", PurchRcptLine2."Document No.");
                                    PurchLine2.SetRange("Receipt Line No.", PurchRcptLine2."Line No.");
                                    OnCopyItemChargeAssgntOnBeforeFindPurchLine2(PurchLine2, ItemChargeAssgntPurch2, PurchRcptLine);
                                    if PurchLine2.Find('-') and (PurchLine2.Quantity <> 0) then begin
                                        OnCopyItemChargeAssgntOnAfterFindPurchLine2(PurchLine2, ItemChargeAssgntPurch2);
                                        ItemChargeAssgntPurch2."Applies-to Doc. Line No." := PurchLine2."Line No.";
                                    end else
                                        InsertChargeAssgnt := false;
                                end else
                                    InsertChargeAssgnt := false;
                            end;
                        end;
                    end;

                    if InsertChargeAssgnt and (ItemChargeAssgntPurch2."Qty. to Assign" <> 0) then begin
                        ItemChargeAssgntPurch2.Insert();
                        QtyToAssign := QtyToAssign - ItemChargeAssgntPurch2."Qty. to Assign";
                    end;
                end;
            until ItemChargeAssgntPurch.Next() = 0;
    end;

    local procedure SetReceiptPurchLineFilters(var PurchRcptLine2: Record "Purch. Rcpt. Line"; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var PurchLine2: Record "Purchase Line")
    begin
        PurchRcptLine2.SetCurrentKey("Order No.", "Order Line No.");
        PurchRcptLine2.SetRange("Order No.", ItemChargeAssgntPurch."Applies-to Doc. No.");
        PurchRcptLine2.SetRange("Order Line No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
        PurchRcptLine2.SetRange(Correction, false);
        PurchRcptLine2.SetFilter(Quantity, '<>0');
        if (PurchLine2."Receipt No." <> '') then
            if CheckPurchRcptLine(PurchLine2) then
                PurchRcptLine2.SetRange("Document No.", PurchLine2."Receipt No.");
    end;

    local procedure CheckPurchRcptLine(var PurchLine2: Record "Purchase Line"): Boolean
    var
        PurchRcptLine2: Record "Purch. Rcpt. Line";
    begin
        if PurchLine2."Receipt No." = '' then
            exit;
        PurchRcptLine2.SetRange("Document No.", PurchLine2."Receipt No.");
        PurchRcptLine2.SetRange(Type, PurchRcptLine2.Type::Item);
        PurchRcptLine2.SetFilter(Quantity, '<>0');
        if not PurchRcptLine2.IsEmpty() then
            exit(true);
    end;

    local procedure GetQtyAssignedInNewLine(ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"): Decimal
    begin
        ItemChargeAssgntPurch.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. Type");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
        ItemChargeAssgntPurch.CalcSums("Qty. to Assign");
        exit(ItemChargeAssgntPurch."Qty. to Assign");
    end;

    local procedure CalcInvoiceDiscount(var PurchLine: Record "Purchase Line")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        PurchSetup.Get();
        if PurchSetup."Calc. Inv. Discount" then
            PurchCalcDiscount.CalculateInvoiceDiscountOnLine(PurchLine);
    end;

    local procedure CalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; var RoundingAmount: Decimal)
    var
        PurchOrderLine: Record "Purchase Line";
        Fraction: Decimal;
        FractionAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine, PurchaseLine, RoundingAmount, IsHandled);
        if IsHandled then
            exit;

        if (PurchaseLine."Prepayment %" > 0) and (PurchaseLine."Prepayment %" < 100) and
           (PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice)
        then begin
            PurchOrderLine.Get(PurchOrderLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
            if (PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced") <> 0 then begin
                Fraction := (PurchRcptline.Quantity - PurchRcptLine."Quantity Invoiced") / (PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced");
                FractionAmount := Fraction * (PurchOrderLine."Prepmt. Amt. Inv." - PurchOrderLine."Prepmt Amt Deducted");
                RoundingAmount += PurchaseLine."Prepmt Amt to Deduct" - FractionAmount;
                if (PurchaseLine."Prepmt Amt to Deduct" - FractionAmount) <> 0 then
                    InsertTempPurchaseLine(PurchRcptLine, PurchOrderLine, PurchaseLine, FractionAmount);
            end else
                RoundingAmount := 0;
        end;
    end;

    local procedure AdjustPrepmtAmtToDeductRounding(var PurchaseLine: Record "Purchase Line"; RoundingAmount: Decimal)
    begin
        if Round(RoundingAmount) <> 0 then begin
            PurchaseLine."Prepmt Amt to Deduct" -= Round(RoundingAmount);
            PurchaseLine.Modify();
        end;
    end;

    local procedure CheckPurchRcptLineVATBusPostingGroup(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchRcptLineVATBusPostingGroup(PurchRcptLine, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchRcptLine.TestField("VAT Bus. Posting Group", PurchHeader."VAT Bus. Posting Group");
    end;

    procedure GetPurchOrderInvoices(var TempPurchInvHeader: Record "Purch. Inv. Header" temporary; OrderNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvoicesByOrder: Query "Purchase Invoices By Order";
    begin
        TempPurchInvHeader.Reset();
        TempPurchInvHeader.DeleteAll();

        PurchInvoicesByOrder.SetRange(Order_No_, OrderNo);
        PurchInvoicesByOrder.SetFilter(Quantity, '<>0');
        PurchInvoicesByOrder.Open();

        while PurchInvoicesByOrder.Read() do begin
            PurchInvHeader.Get(PurchInvoicesByOrder.Document_No_);
            TempPurchInvHeader := PurchInvHeader;
            TempPurchInvHeader.Insert();
        end;
    end;

    local procedure CopyDocumentAttachments(var PurchRcptLine2: Record "Purch. Rcpt. Line"; var PurchaseLine: Record "Purchase Line")
    var
        OrderPurchaseLine: Record "Purchase Line";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
    begin
        if (PurchRcptLine2."Order No." = '') or (PurchRcptLine2."Order Line No." = 0) then
            exit;
        if not AnyLineHasAttachments(PurchRcptLine2."Order No.") then
            exit;
        OrderPurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        OrderPurchaseLine.SetLoadFields("Document Type", "Document No.", "Line No.");
        if OrderPurchaseLine.Get(OrderPurchaseLine."Document Type"::Order, PurchRcptLine2."Order No.", PurchRcptLine2."Order Line No.") then
            DocumentAttachmentMgmt.CopyAttachments(OrderPurchaseLine, PurchaseLine);
    end;

    local procedure CopyDocumentAttachments(OrderNoList: List of [Code[20]]; var PurchaseHeader: Record "Purchase Header")
    var
        OrderPurchaseHeader: Record "Purchase Header";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        OrderNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDocumentAttachments(OrderNoList, PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        OrderPurchaseHeader.ReadIsolation := IsolationLevel::ReadCommitted;
        OrderPurchaseHeader.SetLoadFields("Document Type", "No.");
        foreach OrderNo in OrderNoList do
            if OrderHasAttachments(OrderNo) then
                if OrderPurchaseHeader.Get(OrderPurchaseHeader."Document Type"::Order, OrderNo) then
                    DocumentAttachmentMgmt.CopyAttachments(OrderPurchaseHeader, PurchaseHeader);
    end;

    local procedure OrderHasAttachments(DocNo: Code[20]): boolean
    begin
        exit(EntityHasAttachments(DocNo, Database::"Purchase Header"));
    end;

    local procedure AnyLineHasAttachments(DocNo: Code[20]): boolean
    begin
        if not LineListHasAttachments.ContainsKey(DocNo) then
            LineListHasAttachments.Add(DocNo, EntityHasAttachments(DocNo, Database::"Purchase Line"));
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

    local procedure InsertTempPurchaseLine(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchOrderLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; FractionAmount: Decimal)
    begin
        if not TempPurchaseLine.Get(TempPurchaseLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.") then begin
            TempPurchaseLine := PurchOrderLine;
            TempPurchaseLine.Amount := PurchaseLine."Prepmt Amt to Deduct" - FractionAmount;
            TempPurchaseLine."Receipt No." := PurchRcptLine."Document No.";
            TempPurchaseLine."Receipt Line No." := PurchRcptLine."Line No.";
            TempPurchaseLine.Insert();
        end else begin
            TempPurchaseLine.Amount += PurchaseLine."Prepmt Amt to Deduct" - FractionAmount;
            TempPurchaseLine."Receipt No." := PurchRcptLine."Document No.";
            TempPurchaseLine."Receipt Line No." := PurchRcptLine."Line No.";
            TempPurchaseLine.Modify();
        end;
    end;

    local procedure AdjustPrepmtAmtToDeductRoundingOrderLineWise(var PrepmtAmtToDeductRounding: Decimal; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        TempPurchaseLine.Reset();
        if TempPurchaseLine.FindSet() then
            repeat
                PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                PurchaseLine.SetRange("Receipt No.", TempPurchaseLine."Receipt No.");
                PurchaseLine.SetRange("Receipt Line No.", TempPurchaseLine."Receipt Line No.");
                if PurchaseLine.FindFirst() then begin
                    AdjustPrepmtAmtToDeductRounding(PurchaseLine, TempPurchaseLine.Amount);
                    PrepmtAmtToDeductRounding -= TempPurchaseLine.Amount;
                end;
            until TempPurchaseLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscount(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertLines(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceLineFromReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line"; PurchRcptLine2: Record "Purch. Rcpt. Line"; TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptLineSetFilters(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcUpdatePrepmtAmtToDeductRounding(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; var RoundingAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInvLines(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TransferLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLines(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckHeader(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvoiceLineFromReceiptLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine2: Record "Purch. Rcpt. Line"; PurchHeader: Record "Purchase Header"; TransferLine: Boolean; var PrepmtAmtToDeductRounding: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemChargeAssgnt(var PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToInvoice: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPurchHeader(var PurchHeader: Record "Purchase Header"; PurchHeader2: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineToPurchaseDoc(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseHeader: Record "Purchase Header"; var TransferLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnBeforeFind(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterCalcShowNotSameVendorsMessage(PurchHeader: Record "Purchase Header"; PurchRcptHeader: Record "Purch. Rcpt. Header"; var TransferLine: Boolean; var ShowDifferentPayToVendMsg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchRcptLineVATBusPostingGroup(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvoiceLineFromRcptLineOnBeforeCalcUpdatePrepmtAmt(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvoiceLineFromReceiptLineOnBeforeInsertInvLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemChargeAssgntOnAfterFindPurchLine2(var PurchLine2: Record "Purchase Line"; var ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemChargeAssgntOnBeforeFindPurchLine2(var PurchLine2: Record "Purchase Line"; var ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDocumentAttachments(var OrderNoList: List of [Code[20]]; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnBeforeInsertLineIteration(var PurchRcptLine2: Record "Purch. Rcpt. Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TransferLine: Boolean; var IsHandled: Boolean)
    begin
    end;
}

