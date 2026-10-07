// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

codeunit 70 "Purch.-Calc.Discount"
{
    Permissions = tabledata "Purchase Header" = rm,
                  tabledata "Purchase Line" = rm;
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        TempPurchHeader: Record "Purchase Header";
        TempPurchLine: Record "Purchase Line";
    begin
        PurchLine.Copy(Rec);

        TempPurchHeader.Get(Rec."Document Type", Rec."Document No.");
        OnOnRunOnBeforeUpdateHeader(TempPurchHeader, Rec);
        UpdateHeader := true;
        CalculateInvoiceDiscount(TempPurchHeader, TempPurchLine);

        if Rec.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Service Charge';
#pragma warning restore AA0074
        PurchLine: Record "Purchase Line";
        VendInvDisc: Record "Vendor Invoice Disc.";
        VendPostingGr: Record "Vendor Posting Group";
        Currency: Record Currency;
        InvDiscBase: Decimal;
        ChargeBase: Decimal;
        CurrencyDate: Date;
        UpdateHeader: Boolean;

    procedure CalculateInvoiceDiscount(var PurchHeader: Record "Purchase Header"; var PurchLine2: Record "Purchase Line")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        TempServiceChargeLine: Record "Purchase Line" temporary;
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        IsHandled: Boolean;
    begin
        PurchSetup.Get();

        IsHandled := false;
        OnBeforeCalcPurchaseDiscount(PurchHeader, IsHandled, PurchLine2, UpdateHeader, PurchLine);
        if IsHandled then
            exit;

        PurchLine.LockTable();
        PurchHeader.TestField("Vendor Posting Group");
        VendPostingGr.Get(PurchHeader."Vendor Posting Group");

        PurchLine2.Reset();
        PurchLine2.SetRange("Document Type", PurchLine."Document Type");
        PurchLine2.SetRange("Document No.", PurchLine."Document No.");
        PurchLine2.SetFilter(Type, '<>0');
        PurchLine2.SetRange("System-Created Entry", true);
        PurchLine2.SetRange(Type, PurchLine2.Type::"G/L Account");
        PurchLine2.SetRange("No.", VendPostingGr."Service Charge Acc.");
        PurchLine2.SetLoadFields("Unit Cost", "Receipt No.", "Qty. Rcd. Not Invoiced (Base)");
        if PurchLine2.FindSet(true) then
            repeat
                PurchLine2."Direct Unit Cost" := 0;
                PurchLine2.Modify();
                TempServiceChargeLine := PurchLine2;
                TempServiceChargeLine.Insert();
            until PurchLine2.Next() = 0;

        PurchLine2.Reset();
        PurchLine2.SetLoadFields();
        PurchLine2.SetRange("Document Type", PurchLine."Document Type");
        PurchLine2.SetRange("Document No.", PurchLine."Document No.");
        PurchLine2.SetFilter(Type, '<>0');
        OnCalculateInvoiceDiscountOnBeforeFindForCalcVATAmountLines(PurchHeader, PurchLine2, UpdateHeader);
        if PurchLine2.FindFirst() then;
        PurchLine2.CalcVATAmountLines(0, PurchHeader, PurchLine2, TempVATAmountLine);
        InvDiscBase :=
          TempVATAmountLine.GetTotalInvDiscBaseAmount(
            PurchHeader."Prices Including VAT", PurchHeader."Currency Code");
        ChargeBase :=
          TempVATAmountLine.GetTotalLineAmount(
            PurchHeader."Prices Including VAT", PurchHeader."Currency Code");

        if UpdateHeader then
            PurchHeader.Modify();

        if PurchHeader."Posting Date" = 0D then
            CurrencyDate := WorkDate()
        else
            CurrencyDate := PurchHeader."Posting Date";

        GetVendInvDisc(PurchHeader, ChargeBase);

        OnCalculateInvoiceDiscountOnBeforeCheckVendInvDiscServiceCharge(VendInvDisc, PurchHeader, CurrencyDate, ChargeBase);
        if VendInvDisc."Service Charge" <> 0 then begin
            OnCalculateInvoiceDiscountOnBeforeCurrencyInitialize(VendPostingGr);
            Currency.Initialize(PurchHeader."Currency Code");
            if not UpdateHeader then
                PurchLine2.SetPurchHeader(PurchHeader);
            if not TempServiceChargeLine.IsEmpty() then begin
                TempServiceChargeLine.FindLast();
                PurchLine2.Get(PurchLine."Document Type", PurchLine."Document No.", TempServiceChargeLine."Line No.");
                if PurchHeader."Prices Including VAT" then
                    PurchLine2.Validate(
                      "Direct Unit Cost",
                      Round(
                        (1 + PurchLine2."VAT %" / 100) * VendInvDisc."Service Charge",
                        Currency."Unit-Amount Rounding Precision"))
                else
                    PurchLine2.Validate("Direct Unit Cost", VendInvDisc."Service Charge");
                PurchLine2.Modify();
            end else begin
                PurchLine2.Reset();
                PurchLine2.SetRange("Document Type", PurchLine."Document Type");
                PurchLine2.SetRange("Document No.", PurchLine."Document No.");
                PurchLine2.FindLast();
                PurchLine2.Init();
                if not UpdateHeader then
                    PurchLine2.SetPurchHeader(PurchHeader);
                PurchLine2."Line No." := PurchLine2."Line No." + 10000;
                PurchLine2.Type := PurchLine2.Type::"G/L Account";
                PurchLine2.Validate("No.", VendPostingGr.GetServiceChargeAccount());
                PurchLine2.Description := Text000;
                PurchLine2.Validate(Quantity, 1);
                OnCalculateInvoiceDiscountOnAfterPurchLine2ValidateQuantity(PurchHeader, PurchLine2, VendInvDisc);
                if PurchLine2."Document Type" in
                   [PurchLine2."Document Type"::"Return Order", PurchLine2."Document Type"::"Credit Memo"]
                then
                    PurchLine2.Validate("Return Qty. to Ship", PurchLine2.Quantity)
                else
                    PurchLine2.Validate("Qty. to Receive", PurchLine2.Quantity);
                if PurchHeader."Prices Including VAT" then
                    PurchLine2.Validate(
                      "Direct Unit Cost",
                      Round(
                        (1 + PurchLine2."VAT %" / 100) * VendInvDisc."Service Charge",
                        Currency."Unit-Amount Rounding Precision"))
                else
                    PurchLine2.Validate("Direct Unit Cost", VendInvDisc."Service Charge");
                PurchLine2."System-Created Entry" := true;
                OnCalculateInvoiceDiscountOnbeforePurchLineInsert(PurchLine2, PurchHeader);
                PurchLine2.Insert();
            end;
            PurchLine2.CalcVATAmountLines(0, PurchHeader, PurchLine2, TempVATAmountLine);
        end else
            if TempServiceChargeLine.FindSet(false) then
                repeat
                    if (TempServiceChargeLine."Receipt No." = '') and (TempServiceChargeLine."Qty. Rcd. Not Invoiced (Base)" = 0) then begin
                        PurchLine2 := TempServiceChargeLine;
                        IsHandled := false;
                        OnCalculateInvoiceDiscountOnBeforeDeletePurchaseLine(UpdateHeader, PurchLine2, IsHandled);
                        if not IsHandled then
                            PurchLine2.Delete(true);
                    end;
                until TempServiceChargeLine.Next() = 0;

        if VendInvDiscRecExists(PurchHeader."Invoice Disc. Code") then begin
            if InvDiscBase <> ChargeBase then
                GetVendInvDisc(PurchHeader, InvDiscBase);

            DiscountNotificationMgt.NotifyAboutMissingSetup(
              PurchSetup.RecordId, PurchHeader."Gen. Bus. Posting Group", PurchLine2."Gen. Prod. Posting Group",
              PurchSetup."Discount Posting", PurchSetup."Discount Posting"::"Line Discounts");

            PurchHeader."Invoice Discount Calculation" := PurchHeader."Invoice Discount Calculation"::"%";
            PurchHeader."Invoice Discount Value" := VendInvDisc."Discount %";
            if UpdateHeader then
                PurchHeader.Modify();

            TempVATAmountLine.SetInvoiceDiscountPercent(
              VendInvDisc."Discount %", PurchHeader."Currency Code",
              PurchHeader."Prices Including VAT", PurchSetup."Calc. Inv. Disc. per VAT ID",
              PurchHeader."VAT Base Discount %");

            PurchLine2.UpdateVATOnLines(0, PurchHeader, PurchLine2, TempVATAmountLine);
            UpdatePrepmtLineAmount(PurchHeader);
        end;

        PurchCalcDiscByType.ResetRecalculateInvoiceDisc(PurchHeader);
        OnAfterCalcPurchaseDiscount(PurchHeader);
    end;

    local procedure GetVendInvDisc(var PurchHeader: Record "Purchase Header"; BaseAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVendInvDisc(PurchHeader, CurrencyDate, ChargeBase, InvDiscBase, BaseAmount, IsHandled, VendInvDisc);
        if IsHandled then
            exit;

        VendInvDisc.GetRec(PurchHeader."Invoice Disc. Code", PurchHeader."Currency Code", CurrencyDate, BaseAmount);
    end;

    local procedure VendInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        VendInvDisc.SetRange(Code, InvDiscCode);
        exit(VendInvDisc.FindFirst());
    end;

    procedure CalculateIncDiscForHeader(var PurchHeader: Record "Purchase Header")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        IsHandled: Boolean;
    begin
        PurchSetup.Get();
        if not PurchSetup."Calc. Inv. Discount" then
            exit;

        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        UpdateHeader := true;
        IsHandled := false;
        OnCalculateIncDiscForHeaderOnBeforeCalculateInvoiceDiscount(PurchHeader, PurchLine, UpdateHeader, IsHandled);
        if not IsHandled then
            CalculateInvoiceDiscount(PurchHeader, PurchLine);
    end;

    procedure CalculateInvoiceDiscountOnLine(var PurchLineToUpdate: Record "Purchase Line")
    var
        PurchHeaderTemp: Record "Purchase Header";
    begin
        PurchLine.Copy(PurchLineToUpdate);

        PurchHeaderTemp.Get(PurchLine."Document Type", PurchLine."Document No.");
        UpdateHeader := false;
        CalculateInvoiceDiscount(PurchHeaderTemp, PurchLine);

        if PurchLineToUpdate.Get(PurchLineToUpdate."Document Type", PurchLineToUpdate."Document No.", PurchLineToUpdate."Line No.") then;
    end;

    local procedure UpdatePrepmtLineAmount(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if (PurchaseHeader."Invoice Discount Calculation" = PurchaseHeader."Invoice Discount Calculation"::"%") and
           (PurchaseHeader."Prepayment %" > 0) and (PurchaseHeader."Invoice Discount Value" > 0) and
           (PurchaseHeader."Invoice Discount Value" + PurchaseHeader."Prepayment %" >= 100)
        then begin
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            PurchaseLine.SetLoadFields(Type, Quantity, "Direct Unit Cost", "Qty. to Invoice", "Prepayment %", "Prepmt. Line Amount", Amount);
            if PurchaseLine.FindSet(true) then
                repeat
                    if not PurchaseLine.ZeroAmountLine(0) and (PurchaseLine."Prepayment %" = PurchaseHeader."Prepayment %") then begin
                        PurchaseLine."Prepmt. Line Amount" := PurchaseLine.Amount;
                        PurchaseLine.Modify();
                    end;
                until PurchaseLine.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPurchaseDiscount(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line"; UpdateHeader: Boolean; var GlobalPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPurchaseDiscount(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendInvDisc(var PurchaseHeader: Record "Purchase Header"; CurrencyDate: Date; ChargeBase: Decimal; InvDiscBase: Decimal; BaseAmount: Decimal; var IsHandled: Boolean; var VendInvDisc: Record "Vendor Invoice Disc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnAfterPurchLine2ValidateQuantity(var PurchHeader: Record "Purchase Header"; var PurchLine2: Record "Purchase Line"; var VendInvDisc: Record "Vendor Invoice Disc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeCurrencyInitialize(var VendorPostingGroup: record "Vendor Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeCheckVendInvDiscServiceCharge(var VendorInvoiceDisc: Record "Vendor Invoice Disc."; var PurchaseHeader: Record "Purchase Header"; CurrencyDate: Date; ChargeBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnbeforePurchLineInsert(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateIncDiscForHeaderOnBeforeCalculateInvoiceDiscount(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; UpdateHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeFindForCalcVATAmountLines(var PurchHeader: Record "Purchase Header"; var PurchLine2: Record "Purchase Line"; UpdateHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInvoiceDiscountOnBeforeDeletePurchaseLine(UpdateHeader: Boolean; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnBeforeUpdateHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;
}
