// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

codeunit 12101 "Withholding - Contribution"
{

    trigger OnRun()
    begin
    end;

    var
        MustBePaymentOrRefundTxt: Label 'must be Payment or Refund', Comment = 'This text will be added after Document Type';
        WithholdCodeLinesNotSpecifiedErr: Label 'You have not specified any withhold code lines for withhold code %1.';
        ContributionCodeLinesNotSpecifiedErr: Label 'You have not specified any contribution code lines for code %1.';
        ContributionBracketLinesNotSpecifiedErr: Label 'You have not specified any contribution bracket lines for code %1.';
        MultiApplyErr: Label 'To calculate taxes correctly, the payment must be applied to only one document.';

    procedure PostPayments(var TempWithholdingSocSec: Record "Tmp Withholding Contribution"; GenJnlLine: Record "Gen. Journal Line"; CalledFromVendBillLine: Boolean)
    var
        WithholdCode: Record "Withhold Code";
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        ComputedSocialSec: Record "Computed Contribution";
        WithholdingTax: Record "Withholding Tax";
        SocialSecurity: Record Contributions;
        CurrencyExchRate: Record "Currency Exchange Rate";
        EntryNo: Integer;
        InsertRec: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostPayments(TempWithholdingSocSec, GenJnlLine, CalledFromVendBillLine, IsHandled);
        if IsHandled then
            exit;

        if WithholdApplicable(TempWithholdingSocSec, CalledFromVendBillLine) then begin
            if ComputedWithholdingTax.Get(TempWithholdingSocSec."Vendor No.", TempWithholdingSocSec."Document Date", TempWithholdingSocSec."Invoice No.") then begin
                ComputedWithholdingTax."External Document No." := TempWithholdingSocSec."External Document No.";

                if TempWithholdingSocSec."Currency Code" = ComputedWithholdingTax."Currency Code" then begin
                    ComputedWithholdingTax."Remaining Amount" := Abs(ComputedWithholdingTax."Remaining Amount") - TempWithholdingSocSec."Total Amount";
                    ComputedWithholdingTax."Remaining - Excluded Amount" := ComputedWithholdingTax."Remaining - Excluded Amount" -
                      TempWithholdingSocSec."Base - Excluded Amount";
                    ComputedWithholdingTax."Non Taxable Remaining Amount" := ComputedWithholdingTax."Non Taxable Remaining Amount" -
                      TempWithholdingSocSec."Non Taxable Amount By Treaty";
                end else begin
                    ComputedWithholdingTax."Remaining Amount" := Abs(ComputedWithholdingTax."Remaining Amount") -
                      CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                        ComputedWithholdingTax."Currency Code", TempWithholdingSocSec."Total Amount");
                    ComputedWithholdingTax."Remaining - Excluded Amount" := ComputedWithholdingTax."Remaining - Excluded Amount" -
                      CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                        ComputedWithholdingTax."Currency Code", TempWithholdingSocSec."Base - Excluded Amount");
                    ComputedWithholdingTax."Non Taxable Remaining Amount" := ComputedWithholdingTax."Non Taxable Remaining Amount" -
                      CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                        ComputedWithholdingTax."Currency Code", TempWithholdingSocSec."Non Taxable Amount By Treaty");
                end;
                ComputedWithholdingTax."Withholding Tax Code" := TempWithholdingSocSec."Withholding Tax Code";
                ComputedWithholdingTax."Related Date" := TempWithholdingSocSec."Related Date";
                ComputedWithholdingTax."Payment Date" := TempWithholdingSocSec."Payment Date";
                OnPostPaymentsOnBeforeComputedWithholdingTaxModify(TempWithholdingSocSec, ComputedWithholdingTax);
                ComputedWithholdingTax.Modify();
            end;

            WithholdingTax.LockTable();
            if WithholdingTax.FindLast() then
                EntryNo := WithholdingTax."Entry No." + 1
            else
                EntryNo := 1;

            WithholdingTax.Init();
            WithholdingTax."Entry No." := EntryNo;
            WithholdingTax.Month := Date2DMY(GenJnlLine."Posting Date", 2);
            WithholdingTax.Year := Date2DMY(GenJnlLine."Posting Date", 3);
            WithholdingTax."Document Date" := TempWithholdingSocSec."Document Date";
            WithholdingTax."Document No." := GenJnlLine."Document No.";
            WithholdingTax."External Document No." := TempWithholdingSocSec."External Document No.";
            WithholdingTax."Vendor No." := TempWithholdingSocSec."Vendor No.";
            WithholdingTax."Related Date" := TempWithholdingSocSec."Related Date";
            WithholdingTax."Posting Date" := GenJnlLine."Posting Date";
            WithholdingTax."Payment Date" := GenJnlLine."Posting Date";
            WithholdingTax."Withholding Tax Code" := TempWithholdingSocSec."Withholding Tax Code";
            WithholdingTax."Withholding Tax %" := TempWithholdingSocSec."Withholding Tax %";
            WithholdingTax."Non Taxable Amount %" := TempWithholdingSocSec."Non Taxable %";
            WithholdingTax.Reason := TempWithholdingSocSec.Reason;
            if TempWithholdingSocSec."Currency Code" = '' then begin
                WithholdingTax."Total Amount" := TempWithholdingSocSec."Total Amount";
                WithholdingTax."Base - Excluded Amount" := TempWithholdingSocSec."Base - Excluded Amount";
                WithholdingTax."Non Taxable Amount By Treaty" := TempWithholdingSocSec."Non Taxable Amount By Treaty";
                WithholdingTax."Non Taxable Amount" := TempWithholdingSocSec."Non Taxable Amount";
                WithholdingTax."Taxable Base" := TempWithholdingSocSec."Taxable Base";
                WithholdingTax."Withholding Tax Amount" := TempWithholdingSocSec."Withholding Tax Amount";
            end else begin
                WithholdingTax."Total Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                      GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Total Amount", GenJnlLine."Currency Factor"));

                WithholdingTax."Base - Excluded Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                      GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Base - Excluded Amount", GenJnlLine."Currency Factor"));

                WithholdingTax."Non Taxable Amount By Treaty" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                      GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Non Taxable Amount By Treaty", GenJnlLine."Currency Factor"));

                WithholdingTax."Non Taxable Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                      GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Non Taxable Amount", GenJnlLine."Currency Factor"));

                WithholdingTax."Taxable Base" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                      GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Taxable Base", GenJnlLine."Currency Factor"));
                WithholdingTax."Withholding Tax Amount" := Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                      GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Withholding Tax Amount", GenJnlLine."Currency Factor"));
            end;
            if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund then begin
                WithholdingTax."Total Amount" := -WithholdingTax."Total Amount";
                WithholdingTax."Base - Excluded Amount" := -WithholdingTax."Base - Excluded Amount";
                WithholdingTax."Non Taxable Amount By Treaty" := -WithholdingTax."Non Taxable Amount By Treaty";
                WithholdingTax."Non Taxable Amount" := -WithholdingTax."Non Taxable Amount";
                WithholdingTax."Taxable Base" := -WithholdingTax."Taxable Base";
                WithholdingTax."Withholding Tax Amount" := -WithholdingTax."Withholding Tax Amount";
            end;
            if WithholdCode.Get(TempWithholdingSocSec."Withholding Tax Code") then begin
                WithholdingTax."Source-Withholding Tax" := WithholdCode."Source-Withholding Tax";
                WithholdingTax."Recipient May Report Income" := WithholdCode."Recipient May Report Income";
                WithholdingTax."Tax Code" := WithholdCode."Tax Code";
            end;

            OnBeforeWithholdingTaxInsert(WithholdingTax, TempWithholdingSocSec, GenJnlLine);
            WithholdingTax.Insert();

            if SocialSecurityApplicable(TempWithholdingSocSec, CalledFromVendBillLine) then
                if ComputedSocialSec.Get(TempWithholdingSocSec."Vendor No.", TempWithholdingSocSec."Document Date", TempWithholdingSocSec."Invoice No.") then begin
                    ComputedSocialSec."External Document No." := TempWithholdingSocSec."External Document No.";
                    ComputedSocialSec."Social Security Code" := TempWithholdingSocSec."Social Security Code";
                    if TempWithholdingSocSec."Currency Code" = ComputedSocialSec."Currency Code" then begin
                        ComputedSocialSec."Remaining Gross Amount" :=
                          ComputedSocialSec."Remaining Gross Amount" - TempWithholdingSocSec."Gross Amount";
                        ComputedSocialSec."Remaining Soc.Sec. Non Taxable" := ComputedSocialSec."Remaining Soc.Sec. Non Taxable" -
                          TempWithholdingSocSec."Soc.Sec.Non Taxable Amount";
                        ComputedSocialSec."Remaining Free-Lance Amount" := ComputedSocialSec."Remaining Free-Lance Amount" -
                          TempWithholdingSocSec."Free-Lance Amount";
                    end else begin
                        ComputedSocialSec."Remaining Gross Amount" :=
                          ComputedSocialSec."Remaining Gross Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                            ComputedSocialSec."Currency Code", TempWithholdingSocSec."Gross Amount");
                        ComputedSocialSec."Remaining Soc.Sec. Non Taxable" :=
                          ComputedSocialSec."Remaining Soc.Sec. Non Taxable" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                            ComputedSocialSec."Currency Code", TempWithholdingSocSec."Soc.Sec.Non Taxable Amount");
                        ComputedSocialSec."Remaining Free-Lance Amount" :=
                          ComputedSocialSec."Remaining Free-Lance Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                            ComputedSocialSec."Currency Code", TempWithholdingSocSec."Free-Lance Amount");
                    end;
                    ComputedSocialSec.Modify();
                end;

            if (TempWithholdingSocSec."INAIL Code" <> '') and
               ((TempWithholdingSocSec."INAIL Payment Line" <> 0) or (TempWithholdingSocSec."INAIL Company Payment Line" <> 0))
            then
                if ComputedSocialSec.Get(TempWithholdingSocSec."Vendor No.", TempWithholdingSocSec."Document Date", TempWithholdingSocSec."Invoice No.") then begin
                    ComputedSocialSec."External Document No." := TempWithholdingSocSec."External Document No.";
                    ComputedSocialSec."INAIL Code" := TempWithholdingSocSec."INAIL Code";
                    if TempWithholdingSocSec."Currency Code" = ComputedSocialSec."Currency Code" then begin
                        ComputedSocialSec."INAIL Remaining Gross Amount" :=
                          ComputedSocialSec."INAIL Remaining Gross Amount" - TempWithholdingSocSec."INAIL Gross Amount";

                        ComputedSocialSec."INAIL Rem. Non Tax. Amount" := ComputedSocialSec."INAIL Rem. Non Tax. Amount" -
                          TempWithholdingSocSec."INAIL Non Taxable Amount";

                        ComputedSocialSec."INAIL Rem. Free-Lance Amount" := ComputedSocialSec."INAIL Rem. Free-Lance Amount" -
                          TempWithholdingSocSec."INAIL Free-Lance Amount";
                    end else begin
                        ComputedSocialSec."INAIL Remaining Gross Amount" :=
                          ComputedSocialSec."INAIL Remaining Gross Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                            ComputedSocialSec."Currency Code", TempWithholdingSocSec."INAIL Gross Amount");

                        ComputedSocialSec."INAIL Rem. Non Tax. Amount" :=
                          ComputedSocialSec."INAIL Rem. Non Tax. Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                            ComputedSocialSec."Currency Code", TempWithholdingSocSec."INAIL Non Taxable Amount");

                        ComputedSocialSec."INAIL Rem. Free-Lance Amount" :=
                          ComputedSocialSec."INAIL Rem. Free-Lance Amount" -
                          CurrencyExchRate.ExchangeAmtFCYToFCY(GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code",
                            ComputedSocialSec."Currency Code", TempWithholdingSocSec."INAIL Free-Lance Amount");
                    end;
                    ComputedSocialSec.Modify();
                end;
            InsertRec := false;
            // Insert INPS/INAIL values
            SocialSecurity.LockTable();
            if SocialSecurity.FindLast() then
                EntryNo := SocialSecurity."Entry No." + 1
            else
                EntryNo := 1;
            SocialSecurity.Init();
            SocialSecurity."Entry No." := EntryNo;

            SocialSecurity.Month := Date2DMY(GenJnlLine."Posting Date", 2);
            SocialSecurity.Year := Date2DMY(GenJnlLine."Posting Date", 3);
            SocialSecurity."Document Date" := TempWithholdingSocSec."Document Date";
            SocialSecurity."Document No." := GenJnlLine."Document No.";
            SocialSecurity."External Document No." := TempWithholdingSocSec."External Document No.";
            SocialSecurity."Vendor No." := TempWithholdingSocSec."Vendor No.";
            SocialSecurity."Related Date" := TempWithholdingSocSec."Related Date";
            SocialSecurity."Payment Date" := GenJnlLine."Posting Date";
            SocialSecurity."Posting Date" := GenJnlLine."Posting Date";
            SocialSecurity.Reported := false;

            if SocialSecurityApplicable(TempWithholdingSocSec, CalledFromVendBillLine) then begin
                InsertRec := true;
                SocialSecurity."Social Security Code" := TempWithholdingSocSec."Social Security Code";
                SocialSecurity."Social Security %" := TempWithholdingSocSec."Social Security %";
                SocialSecurity."Free-Lance Amount %" := TempWithholdingSocSec."Free-Lance %";

                if TempWithholdingSocSec."Currency Code" = '' then begin
                    SocialSecurity."Gross Amount" := TempWithholdingSocSec."Gross Amount";
                    SocialSecurity."Non Taxable Amount" := TempWithholdingSocSec."Soc.Sec.Non Taxable Amount";
                    SocialSecurity."Contribution Base" := TempWithholdingSocSec."Contribution Base";
                    SocialSecurity."Total Social Security Amount" := TempWithholdingSocSec."Total Social Security Amount";
                    SocialSecurity."Free-Lance Amount" := TempWithholdingSocSec."Free-Lance Amount";
                    SocialSecurity."Company Amount" := TempWithholdingSocSec."Company Amount";
                end else begin
                    SocialSecurity."Gross Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Gross Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."Non Taxable Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Soc.Sec.Non Taxable Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."Contribution Base" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Contribution Base", GenJnlLine."Currency Factor"));

                    SocialSecurity."Total Social Security Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Total Social Security Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."Free-Lance Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Free-Lance Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."Company Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."Company Amount", GenJnlLine."Currency Factor"));
                end;
            end;

            if (TempWithholdingSocSec."INAIL Code" <> '') and ((TempWithholdingSocSec."INAIL Payment Line" <> 0) or (TempWithholdingSocSec."INAIL Company Payment Line" <> 0)) then begin
                InsertRec := true;
                SocialSecurity."INAIL Code" := TempWithholdingSocSec."INAIL Code";
                SocialSecurity."INAIL Per Mil" := TempWithholdingSocSec."INAIL Per Mil";
                SocialSecurity."INAIL Free-Lance %" := TempWithholdingSocSec."INAIL Free-Lance %";

                if TempWithholdingSocSec."Currency Code" = '' then begin
                    SocialSecurity."INAIL Gross Amount" := TempWithholdingSocSec."INAIL Gross Amount";
                    SocialSecurity."INAIL Non Taxable Amount" := TempWithholdingSocSec."INAIL Non Taxable Amount";
                    SocialSecurity."INAIL Contribution Base" := TempWithholdingSocSec."INAIL Contribution Base";
                    SocialSecurity."INAIL Total Amount" := TempWithholdingSocSec."INAIL Total Amount";
                    SocialSecurity."INAIL Free-Lance Amount" := TempWithholdingSocSec."INAIL Free-Lance Amount";
                    SocialSecurity."INAIL Company Amount" := TempWithholdingSocSec."INAIL Company Amount";
                end else begin
                    SocialSecurity."INAIL Gross Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."INAIL Gross Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."INAIL Non Taxable Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."INAIL Non Taxable Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."INAIL Contribution Base" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."INAIL Contribution Base", GenJnlLine."Currency Factor"));
                    SocialSecurity."INAIL Total Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."INAIL Total Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."INAIL Free-Lance Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."INAIL Free-Lance Amount", GenJnlLine."Currency Factor"));

                    SocialSecurity."INAIL Company Amount" :=
                      Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date", TempWithholdingSocSec."Currency Code", TempWithholdingSocSec."INAIL Company Amount", GenJnlLine."Currency Factor"));
                end;
            end;
            if InsertRec then
                SocialSecurity.Insert();
        end;
        if not CalledFromVendBillLine then
            TempWithholdingSocSec.Delete();
    end;

    procedure CalculateWithholdingTax(var PurchHeader: Record "Purchase Header"; Recalculate: Boolean)
    var
        PurchWithSoc: Record "Purch. Withh. Contribution";
        PurchLine: Record "Purchase Line";
        TotalAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateWithholdingTax(PurchHeader, Recalculate, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::"G/L Account");
        OnCalculateWithholdingTaxOnAfterPurchLineSetFilters(PurchLine, PurchHeader);

        TotalAmount := 0;
        if PurchLine.FindSet() then
            repeat
                TotalAmount := TotalAmount + PurchLine."VAT Base Amount";
            until PurchLine.Next() = 0;

        if PurchWithSoc.Get(PurchHeader."Document Type", PurchHeader."No.") then
            if (PurchWithSoc."Total Amount" = 0) or
               Recalculate
            then begin
                OnCalculateWithholdingTaxOnRecalculate(PurchWithSoc, PurchHeader, TotalAmount);
                PurchWithSoc."Currency Code" := PurchHeader."Currency Code";
                PurchWithSoc.Validate("Total Amount", TotalAmount);
                PurchWithSoc.Modify();
            end;
    end;

    procedure CreateTmpWithhSocSec(var GenJnlLine: Record "Gen. Journal Line")
    var
        Vend: Record Vendor;
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        ComputedSocSec: Record "Computed Contribution";
        CurrencyExchRate: Record "Currency Exchange Rate";
        TmpWithholdingSocSec: Record "Tmp Withholding Contribution";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTmpWithhSocSec(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment) and
           (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund)
        then
            GenJnlLine.FieldError("Document Type", MustBePaymentOrRefundTxt);

        GenJnlLine.TestField("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.TestField("Account No.");
        GenJnlLine.TestField("System-Created Entry", false);

        TmpWithholdingSocSec.Reset();

        if not TmpWithholdingSocSec.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Line No.") then begin
            TmpWithholdingSocSec.Init();
            TmpWithholdingSocSec."Journal Template Name" := GenJnlLine."Journal Template Name";
            TmpWithholdingSocSec."Journal Batch Name" := GenJnlLine."Journal Batch Name";
            TmpWithholdingSocSec."Line No." := GenJnlLine."Line No.";
            TmpWithholdingSocSec."Document Date" := GenJnlLine."Document Date";
            if GenJnlLine."Applies-to ID" <> '' then begin
                VendorLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                VendorLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                VendorLedgerEntry.SetRange(Open, true);
                VendorLedgerEntry.SetFilter(
                    "Document Type", '%1|%2',
                    VendorLedgerEntry."Document Type"::"Credit Memo", VendorLedgerEntry."Document Type"::Invoice);
                if VendorLedgerEntry.Count() > 1 then
                    Error(MultiApplyErr);

                if VendorLedgerEntry.FindFirst() then begin
                    VendorLedgerEntry.Validate("Applies-to ID", '');
                    Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendorLedgerEntry);

                    GenJnlLine.Validate("Applies-to ID", '');
                    GenJnlLine.Validate("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
                    GenJnlLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
                    GenJnlLine.Validate("Applies-to Occurrence No.", VendorLedgerEntry."Document Occurrence");
                    GenJnlLine.Modify(true);
                end;
            end;
            TmpWithholdingSocSec."Invoice No." := GenJnlLine."Applies-to Doc. No.";
            TmpWithholdingSocSec."Vendor No." := GenJnlLine."Account No.";
            TmpWithholdingSocSec."Old Withholding Amount" := 0;
            TmpWithholdingSocSec."Old Free-Lance Amount" := 0;
            TmpWithholdingSocSec."Payment Date" := GenJnlLine."Document Date";
            TmpWithholdingSocSec."Currency Code" := GenJnlLine."Currency Code";

            ComputedWithholdingTax.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
            ComputedWithholdingTax.SetRange("Vendor No.", GenJnlLine."Account No.");
            ComputedWithholdingTax.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");

            if ComputedWithholdingTax.FindFirst() then begin
                TmpWithholdingSocSec."External Document No." := ComputedWithholdingTax."External Document No.";
                TmpWithholdingSocSec."Related Date" := ComputedWithholdingTax."Related Date";
                if ComputedWithholdingTax."Payment Date" <> 0D then
                    TmpWithholdingSocSec."Payment Date" := ComputedWithholdingTax."Payment Date";
                TmpWithholdingSocSec."Withholding Tax Code" := ComputedWithholdingTax."Withholding Tax Code";

                ComputedSocSec.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
                ComputedSocSec.SetRange("Vendor No.", GenJnlLine."Account No.");
                ComputedSocSec.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");

                if ComputedSocSec.FindFirst() then
                    TmpWithholdingSocSec."Social Security Code" := ComputedSocSec."Social Security Code";
                if ComputedSocSec.FindFirst() then
                    TmpWithholdingSocSec."INAIL Code" := ComputedSocSec."INAIL Code";
                if ComputedWithholdingTax."Currency Code" = GenJnlLine."Currency Code" then begin
                    TmpWithholdingSocSec."Total Amount" := GetRemainingWithhTaxAmount(ComputedWithholdingTax, GenJnlLine."Applies-to Occurrence No.");
                    TmpWithholdingSocSec."Base - Excluded Amount" := ComputedWithholdingTax."Remaining - Excluded Amount";
                    TmpWithholdingSocSec.Validate("Non Taxable Amount By Treaty", ComputedWithholdingTax."Non Taxable Remaining Amount");

                    if ComputedSocSec.FindFirst() then begin
                        TmpWithholdingSocSec.Validate("Gross Amount", ComputedSocSec."Remaining Gross Amount");
                        TmpWithholdingSocSec.Validate("Soc.Sec.Non Taxable Amount", ComputedSocSec."Remaining Soc.Sec. Non Taxable");
                        TmpWithholdingSocSec.Validate("Free-Lance Amount", ComputedSocSec."Remaining Free-Lance Amount");
                        TmpWithholdingSocSec.Validate("INAIL Gross Amount", ComputedSocSec."INAIL Remaining Gross Amount");
                        TmpWithholdingSocSec.Validate("INAIL Non Taxable Amount", ComputedSocSec."INAIL Rem. Non Tax. Amount");
                        TmpWithholdingSocSec.Validate("INAIL Free-Lance Amount", ComputedSocSec."INAIL Rem. Free-Lance Amount");
                    end;
                end else begin
                    TmpWithholdingSocSec."Total Amount" := CurrencyExchRate.ExchangeAmtFCYToFCY(
                        GenJnlLine."Document Date",
                        ComputedWithholdingTax."Currency Code",
                        GenJnlLine."Currency Code",
                        GetRemainingWithhTaxAmount(ComputedWithholdingTax, GenJnlLine."Applies-to Occurrence No."));

                    TmpWithholdingSocSec."Base - Excluded Amount" := CurrencyExchRate.ExchangeAmtFCYToFCY(
                        GenJnlLine."Document Date",
                        ComputedWithholdingTax."Currency Code",
                        GenJnlLine."Currency Code",
                        ComputedWithholdingTax."Remaining - Excluded Amount");

                    TmpWithholdingSocSec.Validate("Non Taxable Amount By Treaty", CurrencyExchRate.ExchangeAmtFCYToFCY(
                        GenJnlLine."Document Date",
                        ComputedWithholdingTax."Currency Code",
                        GenJnlLine."Currency Code",
                        ComputedWithholdingTax."Non Taxable Remaining Amount"));

                    if ComputedSocSec.FindFirst() then begin
                        TmpWithholdingSocSec.Validate("Gross Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                            GenJnlLine."Document Date",
                            ComputedWithholdingTax."Currency Code",
                            GenJnlLine."Currency Code",
                            ComputedSocSec."Remaining Gross Amount"));

                        TmpWithholdingSocSec.Validate("Soc.Sec.Non Taxable Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                            GenJnlLine."Document Date",
                            ComputedWithholdingTax."Currency Code",
                            GenJnlLine."Currency Code",
                            ComputedSocSec."Remaining Soc.Sec. Non Taxable"));

                        TmpWithholdingSocSec.Validate("Free-Lance Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                            GenJnlLine."Document Date",
                            ComputedWithholdingTax."Currency Code",
                            GenJnlLine."Currency Code",
                            ComputedSocSec."Remaining Free-Lance Amount"));

                        TmpWithholdingSocSec.Validate("INAIL Gross Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                            GenJnlLine."Document Date",
                            ComputedWithholdingTax."Currency Code",
                            GenJnlLine."Currency Code",
                            ComputedSocSec."INAIL Remaining Gross Amount"));

                        TmpWithholdingSocSec.Validate("INAIL Non Taxable Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                            GenJnlLine."Document Date",
                            ComputedWithholdingTax."Currency Code",
                            GenJnlLine."Currency Code",
                            ComputedSocSec."INAIL Rem. Non Tax. Amount"));

                        TmpWithholdingSocSec.Validate("INAIL Free-Lance Amount", CurrencyExchRate.ExchangeAmtFCYToFCY(
                            GenJnlLine."Document Date",
                            ComputedWithholdingTax."Currency Code",
                            GenJnlLine."Currency Code",
                            ComputedSocSec."INAIL Rem. Free-Lance Amount"));
                    end;
                end;
            end else begin
                Vend.Get(GenJnlLine."Account No.");
                TmpWithholdingSocSec."Social Security Code" := Vend."Social Security Code";
                TmpWithholdingSocSec.Validate("Withholding Tax Code", Vend."Withholding Tax Code");
                TmpWithholdingSocSec."INAIL Code" := Vend."INAIL Code";
            end;

            if ComputedWithholdingTax."WHT Amount Manual" <> 0 then
                TmpWithholdingSocSec.Validate("Withholding Tax Amount", ComputedWithholdingTax."WHT Amount Manual");

            OnBeforeTmpWithholdingSocSecInsert(TmpWithholdingSocSec, ComputedWithholdingTax, GenJnlLine);
            TmpWithholdingSocSec.Insert();
        end;

        Commit();
        PAGE.RunModal(PAGE::"Show Computed Withh. Contrib.", TmpWithholdingSocSec);
    end;

    procedure WithholdLineFilter(var WithholdCodeLine: Record "Withhold Code Line"; WithholdCode: Code[20]; ValidityDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWithholdLineFilter(WithholdCodeLine, WithholdCode, ValidityDate, IsHandled);
        if IsHandled then
            exit;

        if ValidityDate = 0D then
            ValidityDate := WorkDate();

        WithholdCodeLine.Reset();
        WithholdCodeLine.SetRange("Withhold Code", WithholdCode);
        WithholdCodeLine.SetRange("Starting Date", 0D, ValidityDate);

        if WithholdCodeLine.FindLast() then
            WithholdCodeLine.SetRange("Starting Date", WithholdCodeLine."Starting Date")
        else
            Error(WithholdCodeLinesNotSpecifiedErr, WithholdCode);
    end;

    procedure SetSocSecLineFilters(var SocSecCodeLine: Record "Contribution Code Line"; SocialSecurityCode: Code[20]; StartingDate: Date; TipoContributo: Option INPS,INAIL)
    begin
        if StartingDate = 0D then
            StartingDate := WorkDate();

        SocSecCodeLine.Reset();
        SocSecCodeLine.SetFilter("Contribution Type", '%1', TipoContributo);
        SocSecCodeLine.SetRange(Code, SocialSecurityCode);
        SocSecCodeLine.SetRange("Starting Date", 0D, StartingDate);

        if SocSecCodeLine.FindLast() then
            SocSecCodeLine.SetRange("Starting Date", SocSecCodeLine."Starting Date")
        else
            Error(ContributionCodeLinesNotSpecifiedErr, SocialSecurityCode);
    end;

    procedure SetSocSecBracketFilters(var SocSecBracketLine: Record "Contribution Bracket Line"; SocialSecurityBracketCode: Code[10]; TipoContributo: Option INPS,INAIL; "Code": Code[20])
    begin
        SocSecBracketLine.Reset();
        SocSecBracketLine.SetFilter("Contribution Type", '%1', TipoContributo);
        SocSecBracketLine.SetRange(Code, SocialSecurityBracketCode);
        if not SocSecBracketLine.FindLast() then
            Error(ContributionBracketLinesNotSpecifiedErr, SocialSecurityBracketCode, Code);
    end;

    procedure GetRemainingWithhTaxAmount(ComputedWithholdingTax: Record "Computed Withholding Tax"; AppliestoOccurrenceNo: Integer): Decimal
    var
        CreateVendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        ComputedWithholdingTax1: Record "Computed Withholding Tax";
        RemainingWithhTaxAmount: Decimal;
    begin
        if CheckForMultipleInstallment(ComputedWithholdingTax."Document No.") then
            exit(GetInstallmentAmount(ComputedWithholdingTax, AppliestoOccurrenceNo));
        // Get the Vendor Ledger Entry that generates the ComputedWithholdingTax line
        VendLedgEntry.Reset();
        VendLedgEntry.SetRange("Document No.", ComputedWithholdingTax."Document No.");
        if VendLedgEntry.FindFirst() then
            CreateVendLedgEntry := VendLedgEntry;
        VendLedgEntry.SetRange("Document No.");
        // Find applied entries;
        DtldVendLedgEntry1.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry1.SetRange("Vendor Ledger Entry No.", CreateVendLedgEntry."Entry No.");
        DtldVendLedgEntry1.SetRange(Unapplied, false);
        if DtldVendLedgEntry1.FindSet() then
            repeat
                if DtldVendLedgEntry1."Vendor Ledger Entry No." =
                   DtldVendLedgEntry1."Applied Vend. Ledger Entry No."
                then begin
                    DtldVendLedgEntry2.Init();
                    DtldVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DtldVendLedgEntry2.SetRange(
                      "Applied Vend. Ledger Entry No.", DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                    DtldVendLedgEntry2.SetRange("Entry Type", DtldVendLedgEntry2."Entry Type"::Application);
                    DtldVendLedgEntry2.SetRange(Unapplied, false);
                    if DtldVendLedgEntry2.FindSet() then
                        repeat
                            if DtldVendLedgEntry2."Vendor Ledger Entry No." <>
                               DtldVendLedgEntry2."Applied Vend. Ledger Entry No."
                            then begin
                                VendLedgEntry.SetCurrentKey("Entry No.");
                                VendLedgEntry.SetRange("Entry No.", DtldVendLedgEntry2."Vendor Ledger Entry No.");
                                if VendLedgEntry.FindFirst() then
                                    VendLedgEntry.Mark(true);
                            end;
                        until DtldVendLedgEntry2.Next() = 0;
                end else begin
                    VendLedgEntry.SetCurrentKey("Entry No.");
                    VendLedgEntry.SetRange("Entry No.", DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
                    if VendLedgEntry.FindFirst() then
                        VendLedgEntry.Mark(true);
                end;
            until DtldVendLedgEntry1.Next() = 0;

        VendLedgEntry.SetCurrentKey("Entry No.");
        VendLedgEntry.SetRange("Entry No.");

        if CreateVendLedgEntry."Closed by Entry No." <> 0 then begin
            VendLedgEntry."Entry No." := CreateVendLedgEntry."Closed by Entry No.";
            VendLedgEntry.Mark(true);
        end;

        VendLedgEntry.SetCurrentKey("Closed by Entry No.");
        VendLedgEntry.SetRange("Closed by Entry No.", CreateVendLedgEntry."Entry No.");
        if VendLedgEntry.FindSet() then
            repeat
                VendLedgEntry.Mark(true);
            until VendLedgEntry.Next() = 0;

        VendLedgEntry.SetCurrentKey("Entry No.");
        VendLedgEntry.SetRange("Closed by Entry No.");
        VendLedgEntry.MarkedOnly(true);
        OnGetRemainingWithhTaxAmountOnAfterVendLedgEntrySetFilters(VendLedgEntry, CreateVendLedgEntry, ComputedWithholdingTax, AppliestoOccurrenceNo);
        // Calculate the RemainingWithhTaxAmount by substracting amount from its applied amount
        RemainingWithhTaxAmount := Abs(ComputedWithholdingTax."Remaining Amount");
        if VendLedgEntry.FindSet() then
            repeat
                ComputedWithholdingTax1.Reset();
                ComputedWithholdingTax1.SetRange("Document No.", VendLedgEntry."Document No.");
                if ComputedWithholdingTax1.FindFirst() then
                    RemainingWithhTaxAmount -= Abs(ComputedWithholdingTax1."Remaining Amount");
            until VendLedgEntry.Next() = 0;

        exit(RemainingWithhTaxAmount);
    end;

    procedure WithholdApplicable(TempWithholdingSocSec: Record "Tmp Withholding Contribution"; CalledFromVendBillLine: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWithholdApplicable(TempWithholdingSocSec, CalledFromVendBillLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if TempWithholdingSocSec."Withholding Tax Code" = '' then
            exit(false);
        if TempWithholdingSocSec."Non Taxable %" = 100 then
            exit(true);
        if not CalledFromVendBillLine then
            exit(TempWithholdingSocSec."Payment Line-Withholding" <> 0);
        exit(true);
    end;

    procedure SocialSecurityApplicable(TempWithholdingSocSec: Record "Tmp Withholding Contribution"; CalledFromVendBillLine: Boolean): Boolean
    begin
        if not CalledFromVendBillLine then begin
            if (TempWithholdingSocSec."Social Security Code" <> '') and
               ((TempWithholdingSocSec."Payment Line-Soc. Sec." <> 0) or
                (TempWithholdingSocSec."Payment Line-Company" <> 0))
            then
                exit(true)
        end else
            if (TempWithholdingSocSec."Social Security Code" <> '') and
               (TempWithholdingSocSec."Total Social Security Amount" <> 0)
            then
                exit(true);
        exit(false)
    end;

    procedure GetCompContribRemGrossAmtForVendorInPeriod(VendorNo: Code[20]; StartDate: Date; EndDate: Date): Decimal
    var
        ComputedContribution: Record "Computed Contribution";
    begin
        ComputedContribution.SetRange("Vendor No.", VendorNo);
        ComputedContribution.SetRange("Posting Date", StartDate, EndDate);
        ComputedContribution.CalcSums("Remaining Gross Amount");
        exit(ComputedContribution."Remaining Gross Amount");
    end;

    local procedure GetInstallmentAmount(ComputedWithholdingTax: Record "Computed Withholding Tax"; AppliestoOccurrenceNo: Integer): Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        TotalPaymentAmt: Decimal;
    begin
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", ComputedWithholdingTax."Document No.");
        if VendLedgEntry.FindSet() then
            repeat
                VendLedgEntry.CalcFields(Amount);
                TotalPaymentAmt := TotalPaymentAmt + Abs(VendLedgEntry.Amount);
            until VendLedgEntry.Next() = 0;
        if TotalPaymentAmt = 0 then
            exit(0);
        VendLedgEntry.SetRange("Document Occurrence", AppliestoOccurrenceNo);
        if VendLedgEntry.FindFirst() then begin
            VendLedgEntry.CalcFields("Remaining Amount");
            if VendLedgEntry."Remaining Amount" <> 0 then
                exit(Abs(ComputedWithholdingTax."Total Amount" / TotalPaymentAmt * VendLedgEntry."Remaining Amount"));
        end;
    end;

    local procedure CheckForMultipleInstallment(DocumentNo: Code[20]): Boolean
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.SetFilter("Document Occurrence", '>%1', 1);
        exit(not VendLedgEntry.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateWithholdingTax(var PurchaseHeader: Record "Purchase Header"; Recalculate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTmpWithhSocSec(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPayments(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; GenJournalLine: Record "Gen. Journal Line"; CalledFromVendBillLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTmpWithholdingSocSecInsert(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; ComputedWithholdingTax: Record "Computed Withholding Tax"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWithholdingTaxInsert(var WithholdingTax: Record "Withholding Tax"; TmpWithholdingContribution: Record "Tmp Withholding Contribution"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWithholdApplicable(TmpWithholdingContribution: Record "Tmp Withholding Contribution"; CalledFromVendBillLine: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWithholdLineFilter(var WithholdCodeLine: Record "Withhold Code Line"; WithholdCode: Code[20]; ValidityDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWithholdingTaxOnRecalculate(var PurchWithhContribution: Record "Purch. Withh. Contribution"; PurchaseHeader: Record "Purchase Header"; var TotAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWithholdingTaxOnAfterPurchLineSetFilters(var PurchLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRemainingWithhTaxAmountOnAfterVendLedgEntrySetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; CreateVendLedgEntry: Record "Vendor Ledger Entry"; ComputedWithholdingTax: Record "Computed Withholding Tax"; AppliestoOccurrenceNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPaymentsOnBeforeComputedWithholdingTaxModify(var TempWithholdingSocSec: Record "Tmp Withholding Contribution"; var ComputedWithholdingTax: Record "Computed Withholding Tax")
    begin
    end;
}

