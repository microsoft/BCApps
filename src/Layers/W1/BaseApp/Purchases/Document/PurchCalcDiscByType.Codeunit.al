// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Environment.Configuration;

codeunit 66 "Purch - Calc Disc. By Type"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Copy(Rec);

        if PurchHeader.Get(Rec."Document Type", Rec."Document No.") then begin
            ApplyDefaultInvoiceDiscount(PurchHeader."Invoice Discount Value", PurchHeader);
            // on new order might be no line
            if Rec.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then;
        end;
    end;

    var
        InvDiscBaseAmountIsZeroErr: Label 'Cannot apply an invoice discount because the document does not include lines where the Allow Invoice Disc. field is selected. To add a discount, specify a line discount in the Line Discount % field for the relevant lines, or add a line of type Item where the Allow Invoice Disc. field is selected.';

    procedure ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount: Decimal; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        if not ShouldRedistributeInvoiceDiscountAmount(PurchHeader) then
            exit;

        IsHandled := false;
        OnBeforeApplyDefaultInvoiceDiscount(PurchHeader, IsHandled, InvoiceDiscountAmount);
        if not IsHandled then
            if PurchHeader."Invoice Discount Calculation" = PurchHeader."Invoice Discount Calculation"::Amount then
                ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchHeader)
            else
                ApplyInvDiscBasedOnPct(PurchHeader);

        ResetRecalculateInvoiceDisc(PurchHeader);
    end;

    procedure ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount: Decimal; var PurchHeader: Record "Purchase Header")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        InvDiscBaseAmount: Decimal;
    begin
        PurchSetup.Get();
        DiscountNotificationMgt.NotifyAboutMissingSetup(
            PurchSetup.RecordId, PurchHeader."Gen. Bus. Posting Group",
            PurchSetup."Discount Posting", PurchSetup."Discount Posting"::"Line Discounts");

        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");

        PurchLine.CalcVATAmountLines(0, PurchHeader, PurchLine, TempVATAmountLine);

        InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, PurchHeader."Currency Code");

        if (InvDiscBaseAmount = 0) and (InvoiceDiscountAmount > 0) then
            Error(InvDiscBaseAmountIsZeroErr);

        TempVATAmountLine.SetInvoiceDiscountAmount(InvoiceDiscountAmount, PurchHeader."Currency Code",
          PurchHeader."Prices Including VAT", PurchHeader."VAT Base Discount %");

        PurchLine.UpdateVATOnLines(0, PurchHeader, PurchLine, TempVATAmountLine);

        PurchHeader."Invoice Discount Calculation" := PurchHeader."Invoice Discount Calculation"::Amount;
        PurchHeader."Invoice Discount Value" := InvoiceDiscountAmount;

        ResetRecalculateInvoiceDisc(PurchHeader);

        PurchHeader.Modify();
    end;

    local procedure ApplyInvDiscBasedOnPct(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        if PurchLine.FindFirst() then begin
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
            PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        end;
    end;

    procedure GetVendInvoiceDiscountPct(PurchLine: Record "Purchase Line"): Decimal
    var
        PurchHeader: Record "Purchase Header";
        InvoiceDiscountValue: Decimal;
        AmountIncludingVATDiscountAllowed: Decimal;
        AmountDiscountAllowed: Decimal;
    begin
        if not PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.") then
            exit(0);

        PurchHeader.CalcFields("Invoice Discount Amount");
        if PurchHeader."Invoice Discount Amount" = 0 then
            exit(0);

        case PurchHeader."Invoice Discount Calculation" of
            PurchHeader."Invoice Discount Calculation"::"%":
                begin
                    // Only if VendorInvDisc table is empty header is not updated
                    if not VendorInvDiscRecExists(PurchHeader."Invoice Disc. Code") then
                        exit(0);

                    exit(PurchHeader."Invoice Discount Value");
                end;
            PurchHeader."Invoice Discount Calculation"::None,
            PurchHeader."Invoice Discount Calculation"::Amount:
                begin
                    InvoiceDiscountValue := PurchHeader."Invoice Discount Amount";

                    CalcAmountWithDiscountAllowed(PurchHeader, AmountIncludingVATDiscountAllowed, AmountDiscountAllowed);

                    if AmountDiscountAllowed + InvoiceDiscountValue = 0 then
                        exit(0);

                    if PurchHeader."Prices Including VAT" then
                        exit(Round(InvoiceDiscountValue / (AmountIncludingVATDiscountAllowed + InvoiceDiscountValue) * 100, 0.01));

                    exit(Round(InvoiceDiscountValue / AmountDiscountAllowed * 100, 0.01));
                end;
        end;

        exit(0);
    end;

    procedure ShouldRedistributeInvoiceDiscountAmount(PurchHeader: Record "Purchase Header"): Boolean
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldRedistributeInvoiceDiscountAmount(PurchHeader, IsHandled);
        if IsHandled then
            exit(true);

        PurchHeader.CalcFields("Recalculate Invoice Disc.");
        if not PurchHeader."Recalculate Invoice Disc." then
            exit(false);

        if (PurchHeader."Invoice Discount Calculation" = PurchHeader."Invoice Discount Calculation"::Amount) and
           (PurchHeader."Invoice Discount Value" = 0)
        then
            exit(false);

        PurchPayablesSetup.Get();
        if (not ApplicationAreaMgmtFacade.IsFoundationEnabled() and
            (not PurchPayablesSetup."Calc. Inv. Discount" and
             (PurchHeader."Invoice Discount Calculation" = PurchHeader."Invoice Discount Calculation"::None)))
        then
            exit(false);

        exit(true);
    end;

    procedure ResetRecalculateInvoiceDisc(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetLoadFields("Recalculate Invoice Disc.");  // ModifyAll may result in a FindSet loop.
        OnResetRecalculateInvoiceDiscOnAfterSetLoadFields(PurchLine);
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Recalculate Invoice Disc.", true);
        PurchLine.ModifyAll("Recalculate Invoice Disc.", false);

        OnAfterResetRecalculateInvoiceDisc(PurchHeader);
    end;

    local procedure VendorInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        VendorInvoiceDisc.SetRange(Code, InvDiscCode);
        exit(not VendorInvoiceDisc.IsEmpty);
    end;

    procedure InvoiceDiscIsAllowed(InvDiscCode: Code[20]) Result: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        if not PurchasesPayablesSetup."Calc. Inv. Discount" then
            Result := true
        else
            Result := not VendorInvDiscRecExists(InvDiscCode);
        OnAfterInvoiceDiscIsAllowed(InvDiscCode, Result);
    end;

    local procedure CalcAmountWithDiscountAllowed(PurchHeader: Record "Purchase Header"; var AmountIncludingVATDiscountAllowed: Decimal; var AmountDiscountAllowed: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Allow Invoice Disc.", true);
        PurchLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");
        AmountIncludingVATDiscountAllowed := PurchLine."Amount Including VAT";
        AmountDiscountAllowed := PurchLine.Amount + PurchLine."Inv. Discount Amount";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInvoiceDiscIsAllowed(InvDiscCode: Code[20]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyDefaultInvoiceDiscount(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; InvoiceDiscountAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldRedistributeInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResetRecalculateInvoiceDiscOnAfterSetLoadFields(var PurchaseLine: Record "Purchase Line")
    begin
    end;
}

