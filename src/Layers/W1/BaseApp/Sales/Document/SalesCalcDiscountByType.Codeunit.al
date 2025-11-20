// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;

codeunit 56 "Sales - Calc Discount By Type"
{
    TableNo = "Sales Line";

    trigger OnRun()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesLine.Copy(Rec);

        if SalesHeader.Get(Rec."Document Type", Rec."Document No.") then begin
            ApplyDefaultInvoiceDiscount(SalesHeader."Invoice Discount Value", SalesHeader);
            // on new order might be no line
            if Rec.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then;
        end;
    end;

    var
        InvDiscBaseAmountIsZeroErr: Label 'Cannot apply an invoice discount because the document does not include lines where the Allow Invoice Disc. field is selected. To add a discount, specify a line discount in the Line Discount % field for the relevant lines, or add a line of type Item where the Allow Invoice Disc. field is selected.';
        CalcInvoiceDiscountOnSalesLine: Boolean;

    procedure ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount: Decimal; var SalesHeader: Record "Sales Header")
    begin
        ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount, SalesHeader, false);
    end;

    internal procedure ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount: Decimal; var SalesHeader: Record "Sales Header"; ModifyBeforeApplying: Boolean)
    var
        IsHandled: Boolean;
    begin
        if not ShouldRedistributeInvoiceDiscountAmount(SalesHeader) then
            exit;

        IsHandled := false;
        OnBeforeApplyDefaultInvoiceDiscount(SalesHeader, IsHandled, InvoiceDiscountAmount);
        if not IsHandled then begin
            if ModifyBeforeApplying then
                SalesHeader.Modify();

            if SalesHeader."Invoice Discount Calculation" = SalesHeader."Invoice Discount Calculation"::Amount then
                ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader)
            else
                ApplyInvDiscBasedOnPct(SalesHeader);
        end;

        ResetRecalculateInvoiceDisc(SalesHeader);
    end;

    procedure ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount: Decimal; var SalesHeader: Record "Sales Header")
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
        InvDiscBaseAmount: Decimal;
    begin
        OnBeforeApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        SalesSetup.Get();
        DiscountNotificationMgt.NotifyAboutMissingSetup(
            SalesSetup.RecordId, SalesHeader."Gen. Bus. Posting Group",
            SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Line Discounts");

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, TempVATAmountLine);

        InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, SalesHeader."Currency Code");

        if (InvDiscBaseAmount = 0) and (InvoiceDiscountAmount > 0) then
            Error(InvDiscBaseAmountIsZeroErr);

        TempVATAmountLine.SetInvoiceDiscountAmount(InvoiceDiscountAmount, SalesHeader."Currency Code",
          SalesHeader."Prices Including VAT", SalesHeader."VAT Base Discount %");

        SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, TempVATAmountLine);

        SalesHeader."Invoice Discount Calculation" := SalesHeader."Invoice Discount Calculation"::Amount;
        SalesHeader."Invoice Discount Value" := InvoiceDiscountAmount;

        ResetRecalculateInvoiceDisc(SalesHeader);

        SalesHeader.Modify();
    end;

    local procedure ApplyInvDiscBasedOnPct(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        if SalesLine.FindFirst() then begin
            if CalcInvoiceDiscountOnSalesLine then
                SalesCalcDiscount.CalculateInvoiceDiscountOnLine(SalesLine)
            else
                CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        end;
    end;

    procedure GetCustInvoiceDiscountPct(SalesLine: Record "Sales Line"): Decimal
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountValue: Decimal;
        AmountIncludingVATDiscountAllowed: Decimal;
        AmountDiscountAllowed: Decimal;
        SkipCustInvDiscCheck: Boolean;
    begin
        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit(0);

        SalesHeader.CalcFields("Invoice Discount Amount");
        if SalesHeader."Invoice Discount Amount" = 0 then
            exit(0);

        case SalesHeader."Invoice Discount Calculation" of
            SalesHeader."Invoice Discount Calculation"::"%":
                begin
                    SkipCustInvDiscCheck := false;
                    OnGetCustInvoiceDiscountPctOnCaseInvDiscCalcPercent(SkipCustInvDiscCheck);
                    if not SkipCustInvDiscCheck then
                        // Only if CustInvDisc table is empty header is not updated
                        if not CustInvDiscRecExists(SalesHeader."Invoice Disc. Code") then
                            exit(0);

                    exit(SalesHeader."Invoice Discount Value");
                end;
            SalesHeader."Invoice Discount Calculation"::None,
            SalesHeader."Invoice Discount Calculation"::Amount:
                begin
                    InvoiceDiscountValue := SalesHeader."Invoice Discount Amount";

                    CalcAmountWithDiscountAllowed(SalesHeader, AmountIncludingVATDiscountAllowed, AmountDiscountAllowed);

                    if AmountDiscountAllowed + InvoiceDiscountValue = 0 then
                        exit(0);

                    if SalesHeader."Prices Including VAT" then
                        exit(Round(InvoiceDiscountValue / (AmountIncludingVATDiscountAllowed + InvoiceDiscountValue) * 100, 0.01));

                    exit(Round(InvoiceDiscountValue / AmountDiscountAllowed * 100, 0.01));
                end;
        end;

        exit(0);
    end;

    procedure ShouldRedistributeInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"): Boolean
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IsHandled: Boolean;
        ShouldRedistributeInvDiscAmt: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldRedistributeInvoiceDiscountAmount(SalesHeader, IsHandled);
        if IsHandled then
            exit(true);

        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        if not SalesHeader."Recalculate Invoice Disc." then
            exit(false);

        case SalesHeader."Invoice Discount Calculation" of
            SalesHeader."Invoice Discount Calculation"::Amount:
                exit(SalesHeader."Invoice Discount Value" <> 0);
            SalesHeader."Invoice Discount Calculation"::"%":
                begin
                    if not InvoiceDiscServiceChargeIsAllowed(SalesHeader."Invoice Disc. Code") then
                        exit(false);
                    exit(true);
                end;
            SalesHeader."Invoice Discount Calculation"::None:
                begin
                    if not InvoiceDiscServiceChargeIsAllowed(SalesHeader."Invoice Disc. Code") then
                        exit(false);

                    if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                        exit(true);

                    ShouldRedistributeInvDiscAmt := not InvoiceDiscIsAllowed(SalesHeader."Invoice Disc. Code");
                    OnShouldRedistributeInvoiceDiscountAmountOnCaseInvDiscCalculationNone(SalesHeader, ShouldRedistributeInvDiscAmt);
                    exit(ShouldRedistributeInvDiscAmt);
                end;
            else
                exit(true);
        end;
    end;

    procedure ResetRecalculateInvoiceDisc(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.LockTable(); // ModifyAll would previously trigger LockTable if there are subscribers
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Recalculate Invoice Disc.", true);
        SalesLine.ModifyAll("Recalculate Invoice Disc.", false);

        OnAfterResetRecalculateInvoiceDisc(SalesHeader);
    end;

    procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(not CustInvDisc.IsEmpty);
    end;

    procedure InvoiceDiscIsAllowed(InvDiscCode: Code[20]): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if not SalesReceivablesSetup."Calc. Inv. Discount" then
            exit(true);

        exit(not CustInvDiscRecExists(InvDiscCode));
    end;

    local procedure CalcAmountWithDiscountAllowed(SalesHeader: Record "Sales Header"; var AmountIncludingVATDiscountAllowed: Decimal; var AmountDiscountAllowed: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Allow Invoice Disc.", true);
        SalesLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");
        AmountIncludingVATDiscountAllowed := SalesLine."Amount Including VAT";
        AmountDiscountAllowed := SalesLine.Amount + SalesLine."Inv. Discount Amount";
    end;

    local procedure InvoiceDiscServiceChargeIsAllowed(InvDiscCode: Code[20]): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if not SalesReceivablesSetup."Calc. Inv. Discount" then
            if CustInvDiscServiceChargeExists(InvDiscCode) then
                exit(false);
        exit(true);
    end;

    local procedure CustInvDiscServiceChargeExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        CustInvDisc.SetFilter("Service Charge", '<>%1', 0);
        exit(not CustInvDisc.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var SalesHeader: Record "Sales Header")
    begin
    end;

    procedure CalcInvoiceDiscOnLine(CalcInvoiceDiscountOnLine: Boolean)
    begin
        CalcInvoiceDiscountOnSalesLine := CalcInvoiceDiscountOnLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyDefaultInvoiceDiscount(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; InvoiceDiscountAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyInvDiscBasedOnAmt(InvoiceDiscountAmount: Decimal; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldRedistributeInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustInvoiceDiscountPctOnCaseInvDiscCalcPercent(var SkipCustInvDiscCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShouldRedistributeInvoiceDiscountAmountOnCaseInvDiscCalculationNone(SalesHeader: Record "Sales Header"; var ShouldRedistributeInvDiscAmt: Boolean)
    begin
    end;
}

