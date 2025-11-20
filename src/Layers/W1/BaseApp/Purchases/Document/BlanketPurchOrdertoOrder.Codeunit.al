// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

codeunit 97 "Blanket Purch. Order to Order"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        Vend: Record Vendor;
        PurchCommentLine: Record "Purch. Comment Line";
        PrepmtMgt: Codeunit "Prepayment Mgt.";
        RecordLinkManagement: Codeunit "Record Link Management";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        ShouldRedistributeInvoiceAmount: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeRun(Rec, SkipCommit);

        Rec.TestField("Document Type", Rec."Document Type"::"Blanket Order");
        ShouldRedistributeInvoiceAmount := PurchCalcDiscByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        Vend.Get(Rec."Buy-from Vendor No.");
        Vend.CheckBlockedVendOnDocs(Vend, false);

        Rec.ValidatePurchaserOnPurchHeader(Rec, true, false);

        Rec.CheckForBlockedLines();

        IsHandled := false;
        OnRunOnBeforeQtyToReceiveIsZero(Rec, IsHandled, Vend);
        if not IsHandled then
            if Rec.QtyToReceiveIsZero() then
                Error(Text002);

        PurchSetup.Get();

        CreatePurchHeader(Rec, Vend."Prepayment %");

        PurchBlanketOrderLine.Reset();
        PurchBlanketOrderLine.SetRange("Document Type", Rec."Document Type");
        PurchBlanketOrderLine.SetRange("Document No.", Rec."No.");
        OnRunOnAfterPurchBlanketOrderLineSetFilters(PurchBlanketOrderLine);
        if PurchBlanketOrderLine.FindSet() then
            repeat
                IsHandled := false;
                OnRunOnBeforePurchBlanketOrderLineLoop(Rec, PurchBlanketOrderLine, IsHandled);
                if not IsHandled then
                    if (PurchBlanketOrderLine.Type = PurchBlanketOrderLine.Type::" ") or
                       (PurchBlanketOrderLine."Qty. to Receive" <> 0)
                    then begin
                        CalcQuantityOnOrders();

                        CheckBlanketOrderLineQuantity();

                        PurchOrderLine := PurchBlanketOrderLine;
                        OnRunOnAfterInitPurchOrderLineFromBlanketOrderLine(PurchOrderLine, PurchBlanketOrderLine);
                        ResetQuantityFields(PurchOrderLine);
                        PurchOrderLine."Document Type" := PurchOrderHeader."Document Type";
                        PurchOrderLine."Document No." := PurchOrderHeader."No.";
                        PurchOrderLine."Blanket Order No." := Rec."No.";
                        PurchOrderLine."Blanket Order Line No." := PurchBlanketOrderLine."Line No.";

                        if (PurchOrderLine."No." <> '') and (PurchOrderLine.Type <> PurchOrderLine.Type::" ") then begin
                            PurchOrderLine.Amount := 0;
                            PurchOrderLine."Amount Including VAT" := 0;
                            PurchOrderLineValidateQuantity(PurchOrderLine, PurchBlanketOrderLine);
                            if PurchBlanketOrderLine."Expected Receipt Date" <> 0D then
                                PurchOrderLine.Validate("Expected Receipt Date", PurchBlanketOrderLine."Expected Receipt Date")
                            else
                                PurchOrderLine.Validate("Order Date", PurchOrderHeader."Order Date");
                            UpdatePurchOrderLineDirectUnitCost();
                            PurchOrderLineValidateLineDiscountPct(PurchOrderLine, PurchBlanketOrderLine);
                            if PurchOrderLine.Quantity <> 0 then
                                PurchOrderLine.Validate("Inv. Discount Amount", PurchBlanketOrderLine."Inv. Discount Amount");
                            PurchBlanketOrderLine.CalcFields("Reserved Qty. (Base)");
                            OnRunOnAfterCalcReservedQtyBase(Rec, PurchBlanketOrderLine, PurchOrderHeader, PurchOrderLine);
                            if PurchBlanketOrderLine."Reserved Qty. (Base)" <> 0 then
                                PurchLineReserve.TransferPurchLineToPurchLine(
                                  PurchBlanketOrderLine, PurchOrderLine, -PurchBlanketOrderLine."Qty. to Receive (Base)");
                        end;

                        if Vend."Prepayment %" <> 0 then
                            PurchOrderLine."Prepayment %" := Vend."Prepayment %";
                        PrepmtMgt.SetPurchPrepaymentPct(PurchOrderLine, PurchOrderHeader."Posting Date");
                        PurchOrderLine.Validate("Prepayment %");

                        PurchOrderLine."Shortcut Dimension 1 Code" := PurchBlanketOrderLine."Shortcut Dimension 1 Code";
                        PurchOrderLine."Shortcut Dimension 2 Code" := PurchBlanketOrderLine."Shortcut Dimension 2 Code";
                        PurchOrderLine."Dimension Set ID" := PurchBlanketOrderLine."Dimension Set ID";
                        PurchOrderLine.DefaultDeferralCode();
                        if IsPurchOrderLineToBeInserted(PurchOrderLine) then begin
                            OnBeforeInsertPurchOrderLine(PurchOrderLine, PurchOrderHeader, PurchBlanketOrderLine, Rec);
                            PurchOrderLine.Insert();
                            OnAfterPurchOrderLineInsert(PurchOrderLine, PurchBlanketOrderLine);
                        end;

                        OnRunOnBeforeCheckModifyPurchBlanketOrderLine(PurchOrderLine, PurchBlanketOrderLine, PurchLine);
                        if PurchBlanketOrderLine."Qty. to Receive" <> 0 then begin
                            PurchBlanketOrderLine.Validate("Qty. to Receive", 0);
                            PurchBlanketOrderLine.Modify();
                        end;

                        OnRunOnAfterPurchBlanketOrderLineLoop(PurchOrderLine, PurchLine, PurchBlanketOrderLine);
                    end;
            until PurchBlanketOrderLine.Next() = 0;

        OnAfterInsertAllPurchOrderLines(Rec, PurchOrderHeader, SkipCommit);

        if PurchSetup."Default Posting Date" = PurchSetup."Default Posting Date"::"No Date" then begin
            PurchOrderHeader."Posting Date" := 0D;
            PurchOrderHeader.Modify();
        end;

        if PurchSetup."Copy Comments Blanket to Order" then begin
            PurchCommentLine.CopyComments(
                PurchCommentLine."Document Type"::"Blanket Order".AsInteger(),
                PurchOrderHeader."Document Type".AsInteger(), Rec."No.", PurchOrderHeader."No.");
            RecordLinkManagement.CopyLinks(Rec, PurchOrderHeader);
        end;

        if not (ShouldRedistributeInvoiceAmount or PurchSetup."Calc. Inv. Discount") then
            PurchCalcDiscByType.ResetRecalculateInvoiceDisc(PurchOrderHeader);

        OnRunOnBeforeCommit(Rec, PurchOrderHeader);
        if not SkipCommit then
            Commit();

        OnAfterRun(Rec, PurchOrderHeader);
    end;

    var
        PurchBlanketOrderLine: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchLine: Record "Purchase Line";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        QuantityOnOrders: Decimal;
        SkipCommit: Boolean;

        QuantityCheckErr: Label '%1 of %2 %3 in %4 %5 cannot be more than %6.\%7\%8 - %9 = %6.', Comment = '%1: FIELDCAPTION("Qty. to Receive (Base)"); %2: Field(Type); %3: Field(No.); %4: FIELDCAPTION("Line No."); %5: Field(Line No.); %6: Decimal Qty Difference; %7: Text001; %8: Field(Outstanding Qty. (Base)); %9: Decimal Quantity On Orders';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 - Unposted %1 = Possible %2';
#pragma warning restore AA0470
        Text002: Label 'There is nothing to create.';
#pragma warning restore AA0074

    local procedure CalcQuantityOnOrders()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQuantityOnOrders(PurchBlanketOrderLine, QuantityOnOrders, IsHandled);
        if IsHandled then
            exit;

        PurchLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
        PurchLine.SetRange("Blanket Order No.", PurchBlanketOrderLine."Document No.");
        PurchLine.SetRange("Blanket Order Line No.", PurchBlanketOrderLine."Line No.");
        OnCalcQuantityOnOrdersOnAfterPurchLineSetFilters(PurchLine);
        QuantityOnOrders := 0;
        if PurchLine.FindSet() then
            repeat
                if (PurchLine."Document Type" = PurchLine."Document Type"::"Return Order") or
                   ((PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo") and
                    (PurchLine."Return Shipment No." = ''))
                then
                    QuantityOnOrders := QuantityOnOrders - PurchLine."Outstanding Qty. (Base)"
                else
                    if (PurchLine."Document Type" = PurchLine."Document Type"::Order) or
                       ((PurchLine."Document Type" = PurchLine."Document Type"::Invoice) and
                        (PurchLine."Receipt No." = ''))
                    then
                        QuantityOnOrders := QuantityOnOrders + PurchLine."Outstanding Qty. (Base)";
            until PurchLine.Next() = 0;
    end;

    local procedure UpdatePurchOrderLineDirectUnitCost()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchOrderLineDirectUnitCost(PurchOrderLine, PurchBlanketOrderLine, PurchOrderHeader, IsHandled);
        if IsHandled then
            exit;

        PurchOrderLine.Validate("Direct Unit Cost", PurchBlanketOrderLine."Direct Unit Cost");
    end;

    local procedure CheckBlanketOrderLineQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlanketOrderLineQuantity(PurchBlanketOrderLine, QuantityOnOrders, IsHandled);
        if IsHandled then
            exit;

        if (Abs(PurchBlanketOrderLine."Qty. to Receive (Base)" + QuantityOnOrders +
            PurchBlanketOrderLine."Qty. Received (Base)") >
            Abs(PurchBlanketOrderLine."Quantity (Base)")) or
           (PurchBlanketOrderLine."Quantity (Base)" * PurchBlanketOrderLine."Outstanding Qty. (Base)" < 0)
        then
            Error(
              QuantityCheckErr,
              PurchBlanketOrderLine.FieldCaption("Qty. to Receive (Base)"),
              PurchBlanketOrderLine.Type, PurchBlanketOrderLine."No.",
              PurchBlanketOrderLine.FieldCaption("Line No."), PurchBlanketOrderLine."Line No.",
              PurchBlanketOrderLine."Outstanding Qty. (Base)" - QuantityOnOrders,
              StrSubstNo(
                Text001,
                PurchBlanketOrderLine.FieldCaption("Outstanding Qty. (Base)"),
                PurchBlanketOrderLine.FieldCaption("Qty. to Receive (Base)")),
              PurchBlanketOrderLine."Outstanding Qty. (Base)", QuantityOnOrders);
    end;

    local procedure CreatePurchHeader(PurchHeader: Record "Purchase Header"; PrepmtPercent: Decimal)
    var
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePurchHeader(PurchHeader, PrepmtPercent, IsHandled, PurchOrderHeader);
        if IsHandled then
            exit;

        PurchOrderHeader := PurchHeader;
        PurchOrderHeader."Document Type" := PurchOrderHeader."Document Type"::Order;
        PurchOrderHeader."No. Printed" := 0;
        PurchOrderHeader.Status := PurchOrderHeader.Status::Open;
        PurchOrderHeader."No." := '';
        OnCreatePurchHeaderOnBeforePurchOrderHeaderInitRecord(PurchOrderHeader, PurchHeader);
        PurchOrderHeader.InitRecord();
        PurchOrderLine.LockTable();
        OnBeforeInsertPurchOrderHeader(PurchOrderHeader, PurchHeader);
        StandardCodesMgt.SetSkipRecurringLines(true);
        PurchOrderHeader.SetStandardCodesMgt(StandardCodesMgt);
        PurchOrderHeader.Insert(true);
        OnCreatePurchHeaderOnAfterPurchOrderHeaderInsert(PurchHeader, PurchOrderHeader);

        if PurchHeader."Order Date" = 0D then
            PurchOrderHeader."Order Date" := WorkDate()
        else
            PurchOrderHeader."Order Date" := PurchHeader."Order Date";
        if PurchHeader."Posting Date" <> 0D then
            PurchOrderHeader."Posting Date" := PurchHeader."Posting Date";
        if PurchOrderHeader."Posting Date" = 0D then
            PurchOrderHeader."Posting Date" := WorkDate();

        PurchOrderHeader.InitFromPurchHeader(PurchHeader);
        PurchOrderHeader.Validate("Posting Date");

        PurchOrderHeader."Prepayment %" := PrepmtPercent;
        OnBeforePurchOrderHeaderModify(PurchOrderHeader, PurchHeader);
        PurchOrderHeader.Modify();
    end;

    local procedure PurchOrderLineValidateQuantity(var PurchaseOrderLine: Record "Purchase Line"; BlanketOrderPurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchOrderLineValidateQuantity(PurchaseOrderLine, BlanketOrderPurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchaseOrderLine.Validate(Quantity, BlanketOrderPurchLine."Qty. to Receive");
    end;

    local procedure PurchOrderLineValidateLineDiscountPct(var PurchaseOrderLine: Record "Purchase Line"; BlanketOrderPurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchOrderLineValidateLineDiscountPct(PurchaseOrderLine, BlanketOrderPurchLine, PurchOrderHeader, IsHandled);
        if IsHandled then
            exit;

        PurchOrderLine.Validate("Line Discount %", PurchBlanketOrderLine."Line Discount %");
    end;

    local procedure ResetQuantityFields(var TempPurchLine: Record "Purchase Line")
    begin
        TempPurchLine.Quantity := 0;
        TempPurchLine."Quantity (Base)" := 0;
        TempPurchLine."Qty. Rcd. Not Invoiced" := 0;
        TempPurchLine."Quantity Received" := 0;
        TempPurchLine."Quantity Invoiced" := 0;
        TempPurchLine."Qty. Rcd. Not Invoiced (Base)" := 0;
        TempPurchLine."Qty. Received (Base)" := 0;
        TempPurchLine."Qty. Invoiced (Base)" := 0;

        OnAfterResetQuantityFields(TempPurchLine);
    end;

    procedure GetPurchOrderHeader(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader := PurchOrderHeader;
    end;

    local procedure IsPurchOrderLineToBeInserted(PurchOrderLine: Record "Purchase Line") Result: Boolean
    var
        AttachedToPurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsPurchOrderLineToBeInserted(PurchOrderHeader, PurchOrderLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not PurchOrderLine.IsExtendedText() then
            exit(true);
        exit(
          AttachedToPurchaseLine.Get(
            PurchOrderLine."Document Type", PurchOrderLine."Document No.", PurchOrderLine."Attached to Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchOrderLineInsert(var PurchaseLine: Record "Purchase Line"; var BlanketOrderPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var PurchaseHeader: Record "Purchase Header"; var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetQuantityFields(var TempPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var PurchaseHeader: Record "Purchase Header"; var SkipCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQuantityOnOrders(var PurchBlanketOrderLine: Record "Purchase Line"; var QuantityOnOrders: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlanketOrderLineQuantity(var PurchBlanketOrderLine: Record "Purchase Line"; QuantityOnOrders: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; PrepmtPercent: Decimal; var IsHandled: Boolean; var OrderPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchOrderHeader(var PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; var BlanketOrderPurchLine: Record "Purchase Line"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsPurchOrderLineToBeInserted(var PurchaseHader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchOrderLineDirectUnitCost(var PurchOrderLine: Record "Purchase Line"; PurchBlanketOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllPurchOrderLines(BlanketOrderPurchHeader: Record "Purchase Header"; OrderPurchHeader: Record "Purchase Header"; var SkipCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderHeaderModify(var PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineValidateQuantity(var PurchOrderLine: Record "Purchase Line"; BlanketOrderPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineValidateLineDiscountPct(var PurchaseOrderLine: Record "Purchase Line"; BlanketOrderPurchaseLine: Record "Purchase Line"; PurchaseOrderHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQuantityOnOrdersOnAfterPurchLineSetFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchHeaderOnBeforePurchOrderHeaderInitRecord(var PurchOrderHeader: Record "Purchase Header"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterPurchBlanketOrderLineLoop(var PurchOrderLine: Record "Purchase Line"; var PurchLine: Record "Purchase Line"; var PurchBlanketOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterPurchBlanketOrderLineSetFilters(var PurchBlanketOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInitPurchOrderLineFromBlanketOrderLine(var PurchaseOrderLine: Record "Purchase Line"; var BlanketOrderPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCalcReservedQtyBase(var PurchaseBlanketOrder: Record "Purchase Header"; var PurchaseBlanketOrderLine: Record "Purchase Line"; PurchaseOrder: Record "Purchase Header"; var PurchaseOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCheckModifyPurchBlanketOrderLine(var PurchOrderLine: Record "Purchase Line"; var PurchBlanketOrderLine: Record "Purchase Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchHeaderOnAfterPurchOrderHeaderInsert(PurchHeader: Record "Purchase Header"; var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCommit(var PurchaseHeader: Record "Purchase Header"; var PurchHeaderOrder: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePurchBlanketOrderLineLoop(var PurchaseHeader: Record "Purchase Header"; PurchLineBlanketOrder: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeQtyToReceiveIsZero(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var Vendor: Record "Vendor")
    begin
    end;
}

