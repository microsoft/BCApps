// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

codeunit 28070 TaxInvoiceManagement
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Purch. Inv. Header" = rimd,
                  TableData "Purch. Cr. Memo Hdr." = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text030: Label 'Are you sure you wish to post the Tax Invoice(s)?';
        Text031: Label 'Are you sure you wish to post and print the Tax Invoice(s)?';
        Text032: Label 'Tax Invoice already posted for Invoice %1.';
        Text033: Label 'Tax Invoice(s) %1 posted successfully.';
        Text034: Label 'Tax Invoice(s) %1 posted and printed successfully.';
        Text040: Label 'Are you sure you wish to post the Tax Credit Memo(s)?';
        Text041: Label 'Are you sure you wish to post and print the Tax Credit Memo(s)?';
        Text042: Label 'Tax Credit Memo already posted for Credit Memo %1.';
        Text043: Label 'Tax Credit Memo(s) %1 posted successfully.';
        Text044: Label 'Tax Credit Memo(s) %1 posted and printed successfully.';
        Text050: Label 'Sales Invoice No. #1########\Document No.      #2########';
        Text053: Label 'Tax Invoice(s) posted successfully.';
        Text054: Label 'Tax Invoice(s) posted and printed successfully.';
        Text055: Label 'Tax Invoice(s) already posted.';
        CannotAssignNewOnDateErr: Label 'You cannot assign new numbers from the number series %1 on %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';
        CannotAssignNewBeforeDateErr: Label 'You cannot assign new numbers from the number series %1 on a date before %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignGreaterErr: Label 'You cannot assign numbers greater than %1 from the number series %2.', Comment = '%1=Last No.,%2=No. Series Code';
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
        PurchTaxInvoiceHeader: Record "Purch. Tax Inv. Header";
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
        PurchTaxCrMemoHeader: Record "Purch. Tax Cr. Memo Hdr.";
        PurchSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        TempVendLedgEntry: Record "Vendor Ledger Entry";
        TempVendLedgEntry1: Record "Vendor Ledger Entry";
        TempCustLedgEntry: Record "Cust. Ledger Entry";
        TempCustLedgEntry1: Record "Cust. Ledger Entry";
        WHTAmount: Decimal;
        TotAmt: Decimal;
        Payment1: Decimal;
        Payment2: Decimal;
        ExpectedAmount: Decimal;
        RemainingAmt: Decimal;
        VATCrMemoAmt: Decimal;
        VATCrMemoBase: Decimal;
        GenLineAmount: Decimal;
        TotWHTAmount: Decimal;
        WHTUsed1: Boolean;
        InvNo: Code[20];
        LastTaxInvoice: Code[20];
        WarningNoSeriesCode: Code[20];

    [Scope('OnPrem')]
    procedure ApplyVendInvoiceWHT(var VendLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
        TempPurchTaxInvLine: Record "Purch. Tax Inv. Line";
    begin
        TempVendLedgEntry.Reset();
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            TempVendLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Document No.");
            if TempVendLedgEntry1.Find('-') then
                repeat
                    TempVendLedgEntry1.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if TempVendLedgEntry1."Rem. Amt for WHT" = 0 then
                        TempVendLedgEntry1."Rem. Amt for WHT" := TempVendLedgEntry1."Remaining Amt. (LCY)";
                    RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
                    if TempVendLedgEntry1."Document Type" = TempVendLedgEntry1."Document Type"::"Credit Memo" then
                        RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
                until TempVendLedgEntry1.Next() = 0;
            TotAmt := Abs(GenJnlLine.Amount);
            TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempVendLedgEntry.SetRange("Document Type", TempVendLedgEntry."Document Type"::"Credit Memo");
            if TempVendLedgEntry.Find('-') then
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if CheckPmtDisc(GenJnlLine."Posting Date", TempVendLedgEntry."Pmt. Discount Date", Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                         Abs(TempVendLedgEntry."Rem. Amt"), Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                    then
                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";
                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt)) then begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempVendLedgEntry."Pmt. Discount Date", Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                             Abs(TempVendLedgEntry."Rem. Amt"), Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then begin
                            GenJnlLine.Validate(
                              Amount, -Abs(TempVendLedgEntry."Rem. Amt for WHT" + TempVendLedgEntry."Original Pmt. Disc. Possible"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT" + TempVendLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLine.Validate(Amount, -Abs(TempVendLedgEntry."Rem. Amt for WHT"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        end;
                    end else begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempVendLedgEntry."Pmt. Discount Date", Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                             Abs(TempVendLedgEntry."Rem. Amt"), Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then
                            GenJnlLine.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                        else
                            GenJnlLine.Validate(Amount, TotAmt);
                        TotAmt := -1;
                    end;
                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else begin
                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                    end;
                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    TaxInvoicePurchase(GenJnlLine, false);
                    GenJnlLine."WHT Payment" := true;
                    VendLedgerEntry."Applies-to ID" := '';
                    VendLedgerEntry.Modify();
                until (TempVendLedgEntry.Next() = 0) or (TotAmt = -1);

            TempVendLedgEntry.Reset();
            TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempVendLedgEntry.SetFilter("Document Type", '<>%1', TempVendLedgEntry."Document Type"::"Credit Memo");
            if TempVendLedgEntry.Find('-') then
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if CheckPmtDisc(GenJnlLine."Posting Date", TempVendLedgEntry."Pmt. Discount Date", Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                         Abs(TempVendLedgEntry."Rem. Amt"), Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                    then
                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";
                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt)) then begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempVendLedgEntry."Pmt. Discount Date", Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                             Abs(TempVendLedgEntry."Rem. Amt"), Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then begin
                            GenJnlLine.Validate(
                              Amount, Abs(TempVendLedgEntry."Rem. Amt for WHT" - TempVendLedgEntry."Original Pmt. Disc. Possible"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT" + TempVendLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLine.Validate(Amount, Abs(TempVendLedgEntry."Rem. Amt for WHT"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        end;
                    end else begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempVendLedgEntry."Pmt. Discount Date", Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                             Abs(TempVendLedgEntry."Rem. Amt"), Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then
                            GenJnlLine.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                        else
                            GenJnlLine.Validate(Amount, TotAmt);
                        TotAmt := -1;
                    end;

                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else begin
                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt + TempVendLedgEntry."Rem. Amt for WHT";
                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                    end;
                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    TaxInvoicePurchase(GenJnlLine, false);
                    GenJnlLine."WHT Payment" := true;
                    VendLedgerEntry."Applies-to ID" := '';
                    VendLedgerEntry.Modify();
                until (TempVendLedgEntry.Next() = 0) or (TotAmt = -1);
        end else
            TaxInvoicePurchase(GenJnlLine, false);
        if InvNo <> '' then begin
            TempPurchTaxInvLine.SetRange("Document No.", InvNo);
            if not TempPurchTaxInvLine.FindFirst() then
                if PurchTaxInvHeader.Get(InvNo) then begin
                    PurchTaxInvHeader.Delete();
                    PurchSetup.Get();
                    if CheckTaxableNoSeries(VendLedgerEntry."Vendor No.", 0) then
                        ReverseGetNextNo(PurchSetup."Posted Non Tax Invoice Nos.", PurchTaxInvHeader."Posting Date")
                    else
                        ReverseGetNextNo(PurchSetup."Posted Tax Invoice Nos.", PurchTaxInvHeader."Posting Date");
                end;
        end;
        PurchTaxInvHeader.SetRange("Posting Description", GenJnlLine."Document No.");
        if PurchTaxInvHeader.FindFirst() then
            BuildTaxPostBuffer(PurchTaxInvHeader."No.", PurchTaxInvHeader."Posting Description", 0);
    end;

    [Scope('OnPrem')]
    procedure ApplyCustInvoiceWHT(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        SalesTaxInvHeader: Record "Sales Tax Invoice Header";
        TempSalesTaxInvLine: Record "Sales Tax Invoice Line";
        WHTEntry: Record "WHT Entry";
    begin
        TempCustLedgEntry.Reset();
        WHTUsed1 := false;
        TotAmt := Abs(GenJnlLine.Amount);
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            if GenJnlLine."Applies-to ID" <> '' then
                if GenJnlLine."Document No." = GenJnlLine."Applies-to ID" then
                    TempCustLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Document No.")
                else
                    TempCustLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            if TempCustLedgEntry1.Find('-') then
                repeat
                    TempCustLedgEntry1.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if TempCustLedgEntry1."Rem. Amt for WHT" = 0 then
                        TempCustLedgEntry1."Rem. Amt for WHT" := TempCustLedgEntry1."Remaining Amt. (LCY)";
                    if GenJnlLine."Posting Date" <= TempCustLedgEntry1."Pmt. Discount Date" then
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT" - TempCustLedgEntry1."Original Pmt. Disc. Possible"
                    else
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";

                    if TempCustLedgEntry1."Document Type" = TempCustLedgEntry1."Document Type"::"Credit Memo" then
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";
                until TempCustLedgEntry1.Next() = 0;

            TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempCustLedgEntry.SetRange("Document Type", TempCustLedgEntry."Document Type"::"Credit Memo");
            if TempCustLedgEntry.Find('-') then
                repeat
                    TempCustLedgEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if CheckPmtDisc(GenJnlLine."Posting Date", TempCustLedgEntry."Pmt. Discount Date", Abs(TempCustLedgEntry."Rem. Amt for WHT")
                         ,
                         Abs(TempCustLedgEntry."Rem. Amt"), Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                    then
                        TotAmt := TotAmt + TempCustLedgEntry."Original Pmt. Disc. Possible";
                    GLSetup.Get();
                    WHTAmount := 0;
                    if GLSetup."Manual Sales WHT Calc." then begin
                        WHTEntry.Reset();
                        WHTEntry.SetRange("Document No.", TempCustLedgEntry."Document No.");
                        WHTEntry.SetFilter("Applies-to Entry No.", '%1', 0);
                        if WHTEntry.Find('-') then
                            repeat
                                WHTAmount := WHTAmount + WHTEntry."Unrealized Amount";
                            until WHTEntry.Next() = 0;
                    end;
                    if Abs(TempCustLedgEntry."Rem. Amt for WHT") <= Abs(TempCustLedgEntry."Rem. Amt") then
                        WHTAmount := 0;
                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or (Abs(TempCustLedgEntry."Rem. Amt for WHT") < Abs(TotAmt)) then begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempCustLedgEntry."Pmt. Discount Date", Abs(TempCustLedgEntry."Rem. Amt for WHT")
                             ,
                             Abs(TempCustLedgEntry."Rem. Amt"), Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then begin
                            if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt :=
                                  -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT" + TempCustLedgEntry."Original Pmt. Disc. Possible" - WHTAmount);

                            GenJnlLine.Validate(Amount,
                              -Abs(TempCustLedgEntry."Rem. Amt for WHT" - TempCustLedgEntry."Original Pmt. Disc. Possible") + Abs(WHTAmount));
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT"
                              + TempCustLedgEntry."Original Pmt. Disc. Possible" - WHTAmount;
                        end else begin
                            if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT" - WHTAmount);

                            GenJnlLine.Validate(Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT") + Abs(WHTAmount));
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT" - WHTAmount;
                        end;
                    end else begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempCustLedgEntry."Pmt. Discount Date", Abs(TempCustLedgEntry."Rem. Amt for WHT")
                             ,
                             Abs(TempCustLedgEntry."Rem. Amt"), Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then
                            GenJnlLine.Validate(Amount, Abs(TotAmt - TempCustLedgEntry."Original Pmt. Disc. Possible") - Abs(WHTAmount))
                        else
                            GenJnlLine.Validate(Amount, Abs(TotAmt) - Abs(WHTAmount));
                        TotAmt := -1;
                    end;
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else
                        if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            TotAmt := TotAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        end;
                    GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                    TaxInvoiceSales(GenJnlLine, WHTUsed1, false);
                    WHTUsed1 := true;
                    CustLedgerEntry."Applies-to ID" := '';
                    CustLedgerEntry.Modify();
                until (TempCustLedgEntry.Next() = 0) or (TotAmt = -1);

            TempCustLedgEntry.Reset();
            if GenJnlLine."Document No." = GenJnlLine."Applies-to ID" then
                TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.")
            else
                TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            TempCustLedgEntry.SetFilter("Document Type", '<>%1', TempCustLedgEntry."Document Type"::"Credit Memo");
            if TempCustLedgEntry.Find('-') then
                repeat
                    TempCustLedgEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if CheckPmtDisc(GenJnlLine."Posting Date", TempCustLedgEntry."Pmt. Discount Date", Abs(TempCustLedgEntry."Rem. Amt for WHT"),
                         Abs(TempCustLedgEntry."Rem. Amt"), Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                    then
                        TotAmt := TotAmt + TempCustLedgEntry."Original Pmt. Disc. Possible";
                    GLSetup.Get();
                    WHTAmount := 0;
                    if GLSetup."Manual Sales WHT Calc." then begin
                        WHTEntry.Reset();
                        WHTEntry.SetRange("Document No.", TempCustLedgEntry."Document No.");
                        WHTEntry.SetFilter("Applies-to Entry No.", '%1', 0);
                        if WHTEntry.Find('-') then
                            repeat
                                WHTAmount := WHTAmount + WHTEntry."Unrealized Amount";
                            until WHTEntry.Next() = 0;
                    end;
                    if Abs(TempCustLedgEntry."Rem. Amt for WHT") <= Abs(TempCustLedgEntry."Rem. Amt") then
                        WHTAmount := 0;

                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or (Abs(TempCustLedgEntry."Rem. Amt for WHT") < Abs(TotAmt)) then begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempCustLedgEntry."Pmt. Discount Date", Abs(TempCustLedgEntry."Rem. Amt for WHT")
                             ,
                             Abs(TempCustLedgEntry."Rem. Amt"), Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then begin
                            GenJnlLine.Validate(
                              Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT" - TempCustLedgEntry."Original Pmt. Disc. Possible"));
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT" + TempCustLedgEntry."Original Pmt. Disc. Possible";
                            if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := (TotAmt - TempCustLedgEntry."Rem. Amt for WHT" - WHTAmount);
                        end else begin
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT" - WHTAmount;
                            GenJnlLine.Validate(Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT") + Abs(WHTAmount));
                            if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := (TotAmt - TempCustLedgEntry."Rem. Amt for WHT" - WHTAmount);
                        end;
                    end else begin
                        if CheckPmtDisc(
                             GenJnlLine."Posting Date", TempCustLedgEntry."Pmt. Discount Date", Abs(TempCustLedgEntry."Rem. Amt for WHT")
                             ,
                             Abs(TempCustLedgEntry."Rem. Amt"), Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"), Abs(TotAmt))
                        then
                            GenJnlLine.Validate(Amount, -Abs(TotAmt - TempCustLedgEntry."Original Pmt. Disc. Possible") + Abs(WHTAmount))
                        else
                            GenJnlLine.Validate(Amount, -Abs(TotAmt) + Abs(WHTAmount));
                        TotAmt := -1;
                    end;
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else
                        if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            TotAmt := TotAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        end;
                    GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                    TaxInvoiceSales(GenJnlLine, WHTUsed1, false);
                    WHTUsed1 := true;
                    CustLedgerEntry."Applies-to ID" := '';
                    CustLedgerEntry.Modify();
                until (TempCustLedgEntry.Next() = 0) or (TotAmt = -1);
        end else
            TaxInvoiceSales(GenJnlLine, WHTUsed1, false);
        if InvNo <> '' then begin
            TempSalesTaxInvLine.SetRange("Document No.", InvNo);
            if not TempSalesTaxInvLine.FindFirst() then
                if SalesTaxInvHeader.Get(InvNo) then begin
                    SalesTaxInvHeader.Delete();
                    SalesSetup.Get();
                    if CheckTaxableNoSeries(CustLedgerEntry."Customer No.", 1) then
                        ReverseGetNextNo(SalesSetup."Posted Non Tax Invoice Nos.", SalesTaxInvHeader."Posting Date")
                    else
                        ReverseGetNextNo(SalesSetup."Posted Tax Invoice Nos.", SalesTaxInvHeader."Posting Date");
                end;
        end;
        SalesTaxInvHeader.SetRange("Posting Description", GenJnlLine."Document No.");
        if SalesTaxInvHeader.FindFirst() then
            BuildTaxPostBuffer(SalesTaxInvHeader."No.", SalesTaxInvHeader."Posting Description", 1);
    end;

    [Scope('OnPrem')]
    procedure ApplyVendCreditWHT(var VendLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        PurchTaxCrMemoHeader: Record "Purch. Tax Cr. Memo Hdr.";
        TempPurchTaxCrMemoLine: Record "Purch. Tax Cr. Memo Line";
    begin
        TempVendLedgEntry.Reset();
        WHTUsed1 := false;
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            TempVendLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Document No.");
            if TempVendLedgEntry1.Find('-') then
                repeat
                    TempVendLedgEntry1.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if TempVendLedgEntry1."Rem. Amt for WHT" = 0 then
                        TempVendLedgEntry1."Rem. Amt for WHT" := TempVendLedgEntry1."Remaining Amt. (LCY)";
                    RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
                    if TempVendLedgEntry1."Document Type" = TempVendLedgEntry1."Document Type"::"Credit Memo" then
                        RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
                until TempVendLedgEntry1.Next() = 0;
            TotAmt := Abs(GenJnlLine.Amount);
            TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempVendLedgEntry.SetRange("Document Type", TempVendLedgEntry."Document Type"::"Credit Memo");
            if TempVendLedgEntry.Find('-') then
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if Abs(TempVendLedgEntry."Rem. Amt for WHT") >= (Abs(TempVendLedgEntry."Rem. Amt") - Abs(
                                                                       TempVendLedgEntry."Original Pmt. Disc. Possible"))
                    then
                        if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt") - Abs(
                                              TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";
                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt)) then begin
                        if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt") - Abs(
                                              TempVendLedgEntry."Original Pmt. Disc. Possible"))) and
                           (Abs(TempVendLedgEntry."Rem. Amt for WHT") >= (Abs(TempVendLedgEntry."Rem. Amt") - Abs(
                                                                            TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            GenJnlLine.Validate(
                              Amount, -Abs(TempVendLedgEntry."Rem. Amt for WHT" + TempVendLedgEntry."Original Pmt. Disc. Possible"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT" + TempVendLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLine.Validate(Amount, -Abs(TempVendLedgEntry."Rem. Amt for WHT"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        end;
                    end else begin
                        if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt") - Abs(
                                              TempVendLedgEntry."Original Pmt. Disc. Possible"))) and
                           (Abs(TempVendLedgEntry."Rem. Amt for WHT") >= (Abs(TempVendLedgEntry."Rem. Amt") - Abs(
                                                                            TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLine.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                        else
                            GenJnlLine.Validate(Amount, TotAmt);
                        TotAmt := -1;
                    end;
                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else begin
                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                    end;
                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    TaxInvoicePurchaseCrMemo(GenJnlLine, WHTUsed1, false);
                    WHTUsed1 := true;
                    VendLedgerEntry."Applies-to ID" := '';
                    VendLedgerEntry.Modify();
                until (TempVendLedgEntry.Next() = 0) or (TotAmt = -1);
        end else
            TaxInvoicePurchaseCrMemo(GenJnlLine, WHTUsed1, false);
        if InvNo <> '' then begin
            TempPurchTaxCrMemoLine.SetRange("Document No.", InvNo);
            if not TempPurchTaxCrMemoLine.FindFirst() then
                if PurchTaxCrMemoHeader.Get(InvNo) then begin
                    PurchTaxCrMemoHeader.Delete();
                    PurchSetup.Get();
                    if CheckTaxableNoSeries(VendLedgerEntry."Vendor No.", 0) then
                        ReverseGetNextNo(PurchSetup."Posted Non Tax Credit Memo Nos", PurchTaxCrMemoHeader."Posting Date")
                    else
                        ReverseGetNextNo(PurchSetup."Posted Tax Credit Memo Nos", PurchTaxCrMemoHeader."Posting Date");
                end;
        end;
        PurchTaxCrMemoHeader.SetRange("Posting Description", GenJnlLine."Document No.");
        if PurchTaxCrMemoHeader.FindFirst() then
            BuildTaxPostBuffer(PurchTaxCrMemoHeader."No.", PurchTaxCrMemoHeader."Posting Description", 2);
    end;

    [Scope('OnPrem')]
    procedure ApplyCustCreditWHT(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
        TempSalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
    begin
        TempCustLedgEntry.Reset();
        WHTUsed1 := false;
        TotAmt := Abs(GenJnlLine.Amount);
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            TempCustLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Document No.");
            if TempCustLedgEntry1.Find('-') then
                repeat
                    TempCustLedgEntry1.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if TempCustLedgEntry1."Rem. Amt for WHT" = 0 then
                        TempCustLedgEntry1."Rem. Amt for WHT" := TempCustLedgEntry1."Remaining Amt. (LCY)";
                    if GenJnlLine."Posting Date" <= TempCustLedgEntry1."Pmt. Discount Date" then
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT" - TempCustLedgEntry1."Original Pmt. Disc. Possible"
                    else
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";

                    if TempCustLedgEntry1."Document Type" = TempCustLedgEntry1."Document Type"::"Credit Memo" then
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";
                until TempCustLedgEntry1.Next() = 0;

            TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempCustLedgEntry.SetRange("Document Type", TempCustLedgEntry."Document Type"::"Credit Memo");
            if TempCustLedgEntry.Find('-') then
                repeat
                    TempCustLedgEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    if (Abs(TempCustLedgEntry."Rem. Amt for WHT") >= (Abs(TempCustLedgEntry."Rem. Amt") - Abs(
                                                                        TempCustLedgEntry."Original Pmt. Disc. Possible")))
                    then
                        if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt") - Abs(
                                              TempCustLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            TotAmt := TotAmt + TempCustLedgEntry."Original Pmt. Disc. Possible";
                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or (Abs(TempCustLedgEntry."Rem. Amt for WHT") < Abs(TotAmt)) then begin
                        if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt") - Abs(
                                              TempCustLedgEntry."Original Pmt. Disc. Possible"))) and
                           (Abs(TempCustLedgEntry."Rem. Amt for WHT") >= (Abs(TempCustLedgEntry."Rem. Amt") - Abs(
                                                                            TempCustLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT" + TempCustLedgEntry."Original Pmt. Disc. Possible");

                            GenJnlLine.Validate(
                              Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT" - TempCustLedgEntry."Original Pmt. Disc. Possible"));
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT" + TempCustLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT");

                            GenJnlLine.Validate(Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT"));
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        end;
                    end else begin
                        if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt") - Abs(
                                              TempCustLedgEntry."Original Pmt. Disc. Possible"))) and
                           (Abs(TempCustLedgEntry."Rem. Amt for WHT") >= (Abs(TempCustLedgEntry."Rem. Amt") - Abs(
                                                                            TempCustLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLine.Validate(Amount, Abs(TotAmt - TempCustLedgEntry."Original Pmt. Disc. Possible"))
                        else
                            GenJnlLine.Validate(Amount, Abs(TotAmt));
                        TotAmt := -1;
                    end;
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else
                        if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            TotAmt := TotAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        end;
                    GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                    TaxInvoiceSalesCrMemo(GenJnlLine, WHTUsed1, false);
                    WHTUsed1 := true;
                    CustLedgerEntry."Applies-to ID" := '';
                    CustLedgerEntry.Modify();
                until (TempCustLedgEntry.Next() = 0) or (TotAmt = -1);
        end else
            TaxInvoiceSalesCrMemo(GenJnlLine, WHTUsed1, false);
        if InvNo <> '' then begin
            TempSalesTaxCrMemoLine.SetRange("Document No.", InvNo);
            if not TempSalesTaxCrMemoLine.FindFirst() then
                if SalesTaxCrMemoHeader.Get(InvNo) then begin
                    SalesTaxCrMemoHeader.Delete();
                    SalesSetup.Get();
                    if CheckTaxableNoSeries(CustLedgerEntry."Customer No.", 1) then
                        ReverseGetNextNo(SalesSetup."Posted Non Tax Credit Memo Nos", SalesTaxCrMemoHeader."Posting Date")
                    else
                        ReverseGetNextNo(SalesSetup."Posted Tax Credit Memo Nos", SalesTaxCrMemoHeader."Posting Date");
                end;
        end;
        SalesTaxCrMemoHeader.SetRange("Posting Description", GenJnlLine."Document No.");
        if SalesTaxCrMemoHeader.FindFirst() then
            BuildTaxPostBuffer(SalesTaxCrMemoHeader."No.", SalesTaxCrMemoHeader."Posting Description", 3);
    end;

    [Scope('OnPrem')]
    procedure SalesTaxInvPost(SalesInvHeader: Record "Sales Invoice Header") TaxInvNo: Code[20]
    var
        SalesTaxInvHeader: Record "Sales Tax Invoice Header";
        SalesInvHeader2: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesTaxInvLine: Record "Sales Tax Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempSalesTaxInvLine: Record "Sales Tax Invoice Line";
    begin
        SalesInvHeader2.Reset();
        SalesInvHeader2.SetRange("No.", SalesInvHeader."No.");
        SalesInvHeader2.FindFirst();
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.Find('-');
        SalesTaxInvHeader.Init();
        SalesTaxInvHeader.TransferFields(SalesInvHeader2);
        SalesTaxInvHeader."No." := '';
        SalesTaxInvHeader."Posting Date" := WorkDate();
        SalesTaxInvHeader.Insert(true);
        repeat
            SalesTaxInvLine.Init();
            if VATPostingSetup.Get(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group") then
                if VATPostingSetup."Unrealized VAT Type" = VATPostingSetup."Unrealized VAT Type"::" " then begin
                    SalesTaxInvLine.TransferFieldsFrom(SalesInvLine);
                    SalesTaxInvLine."Document No." := SalesTaxInvHeader."No.";
                    SalesTaxInvLine."External Document No." := SalesInvHeader."No.";
                    SalesTaxInvLine."Paid Amount Incl. VAT" := SalesTaxInvLine."Amount Including VAT";
                    SalesTaxInvLine."Paid VAT" := SalesTaxInvLine."Amount Including VAT" - SalesTaxInvLine."VAT Base Amount";
                    SalesTaxInvLine.Insert();
                end;
        until SalesInvLine.Next() = 0;
        TempSalesTaxInvLine.Reset();
        TempSalesTaxInvLine.SetRange("Document No.", SalesTaxInvHeader."No.");
        if not TempSalesTaxInvLine.FindFirst() then begin
            SalesTaxInvHeader.Delete();
            SalesSetup.Get();
            if CheckTaxableNoSeries(SalesInvHeader."Sell-to Customer No.", 1) then
                ReverseGetNextNo(SalesSetup."Posted Non Tax Invoice Nos.", SalesTaxInvHeader."Posting Date")
            else
                ReverseGetNextNo(SalesSetup."Posted Tax Invoice Nos.", SalesTaxInvHeader."Posting Date");
        end else begin
            BuildTaxPostBuffer(SalesTaxInvHeader."No.", SalesTaxInvHeader."Posting Description", 1);
            SalesInvHeader2."Printed Tax Document" := true;
            SalesInvHeader2.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure PurchTaxInvPost(PurchInvHeader: Record "Purch. Inv. Header") TaxInvNo: Code[20]
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
        PurchInvHeader2: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchTaxInvLine: Record "Purch. Tax Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempPurchTaxInvLine: Record "Purch. Tax Inv. Line";
    begin
        PurchInvHeader2.Reset();
        PurchInvHeader2.SetRange("No.", PurchInvHeader."No.");
        PurchInvHeader2.FindFirst();
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.Find('-');
        PurchTaxInvHeader.Init();
        PurchTaxInvHeader.TransferFieldsFrom(PurchInvHeader2);
        PurchTaxInvHeader."No." := '';
        PurchTaxInvHeader."Posting Date" := WorkDate();
        PurchTaxInvHeader.Insert(true);
        repeat
            if VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group") then
                if VATPostingSetup."Unrealized VAT Type" = VATPostingSetup."Unrealized VAT Type"::" " then begin
                    PurchTaxInvLine.Init();
                    PurchTaxInvLine.TransferFieldsFrom(PurchInvLine);
                    PurchTaxInvLine."Document No." := PurchTaxInvHeader."No.";
                    PurchTaxInvLine."Paid Amount Incl. VAT" := PurchTaxInvLine."Amount Including VAT";
                    PurchTaxInvLine."Paid VAT" := PurchTaxInvLine."Amount Including VAT" - PurchTaxInvLine."VAT Base Amount";
                    PurchTaxInvLine."External Document No." := PurchInvHeader."No.";
                    PurchTaxInvLine.Insert();
                end;
        until PurchInvLine.Next() = 0;
        TempPurchTaxInvLine.Reset();
        TempPurchTaxInvLine.SetRange("Document No.", PurchTaxInvHeader."No.");
        if not TempPurchTaxInvLine.FindFirst() then begin
            PurchTaxInvHeader.Delete();
            PurchSetup.Get();
            if CheckTaxableNoSeries(PurchInvHeader."Buy-from Vendor No.", 0) then
                ReverseGetNextNo(PurchSetup."Posted Non Tax Invoice Nos.", PurchTaxInvHeader."Posting Date")
            else
                ReverseGetNextNo(PurchSetup."Posted Tax Invoice Nos.", PurchTaxInvHeader."Posting Date");
        end else begin
            BuildTaxPostBuffer(PurchTaxInvHeader."No.", PurchTaxInvHeader."Posting Description", 0);
            PurchInvHeader2."Printed Tax Document" := true;
            PurchInvHeader2.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SalesTaxCrMemoPost(SalesCrMemoHeader: Record "Sales Cr.Memo Header") TaxInvNo: Code[20]
    var
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
        SalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempSalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
    begin
        SalesCrMemoHeader2.Reset();
        SalesCrMemoHeader2.SetRange("No.", SalesCrMemoHeader."No.");
        SalesCrMemoHeader2.FindFirst();
        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.Find('-');
        SalesTaxCrMemoHeader.Init();
        SalesTaxCrMemoHeader.TransferFieldsFrom(SalesCrMemoHeader2);
        SalesTaxCrMemoHeader."No." := '';
        SalesTaxCrMemoHeader."Posting Date" := WorkDate();
        SalesTaxCrMemoHeader.Insert(true);
        repeat
            SalesTaxCrMemoLine.Init();
            if VATPostingSetup.Get(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group") then
                if VATPostingSetup."Unrealized VAT Type" = VATPostingSetup."Unrealized VAT Type"::" " then begin
                    SalesTaxCrMemoLine.TransferFieldsFrom(SalesCrMemoLine);
                    SalesTaxCrMemoLine."Document No." := SalesTaxCrMemoHeader."No.";
                    SalesTaxCrMemoLine."Paid Amount Incl. VAT" := SalesTaxCrMemoLine."Amount Including VAT";
                    SalesTaxCrMemoLine."Paid VAT" := SalesTaxCrMemoLine."Amount Including VAT" - SalesTaxCrMemoLine."VAT Base Amount";
                    SalesTaxCrMemoLine."External Document No." := SalesCrMemoHeader."No.";
                    SalesTaxCrMemoLine.Insert();
                end;
        until SalesCrMemoLine.Next() = 0;
        TempSalesTaxCrMemoLine.Reset();
        TempSalesTaxCrMemoLine.SetRange("Document No.", SalesTaxCrMemoHeader."No.");
        if not TempSalesTaxCrMemoLine.FindFirst() then begin
            SalesTaxCrMemoHeader.Delete();
            SalesSetup.Get();
            if CheckTaxableNoSeries(SalesCrMemoHeader."Sell-to Customer No.", 1) then
                ReverseGetNextNo(SalesSetup."Posted Non Tax Credit Memo Nos", SalesTaxCrMemoHeader."Posting Date")
            else
                ReverseGetNextNo(SalesSetup."Posted Tax Credit Memo Nos", SalesTaxCrMemoHeader."Posting Date");
        end else begin
            BuildTaxPostBuffer(SalesTaxCrMemoHeader."No.", SalesTaxCrMemoHeader."Posting Description", 3);
            SalesCrMemoHeader2."Printed Tax Document" := true;
            SalesCrMemoHeader2.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure PurchTaxCrMemoPost(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.") TaxInvNo: Code[20]
    var
        PurchTaxCrMemoHeader: Record "Purch. Tax Cr. Memo Hdr.";
        PurchCrMemoHeader2: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchTaxCrMemoLine: Record "Purch. Tax Cr. Memo Line";
        VatPostingSetup: Record "VAT Posting Setup";
        TempPurchTaxCrMemoLine: Record "Purch. Tax Cr. Memo Line";
    begin
        PurchCrMemoHeader2.Reset();
        PurchCrMemoHeader2.SetRange("No.", PurchCrMemoHeader."No.");
        PurchCrMemoHeader2.FindFirst();
        PurchCrMemoLine.Reset();
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeader."No.");
        PurchCrMemoLine.Find('-');
        PurchTaxCrMemoHeader.Init();
        PurchTaxCrMemoHeader.TransferFieldsFrom(PurchCrMemoHeader2);
        PurchTaxCrMemoHeader."No." := '';
        PurchTaxCrMemoHeader."Posting Date" := WorkDate();
        PurchTaxCrMemoHeader.Insert(true);
        repeat
            PurchTaxCrMemoLine.Init();
            if VatPostingSetup.Get(PurchCrMemoLine."VAT Bus. Posting Group", PurchCrMemoLine."VAT Prod. Posting Group") then
                if VatPostingSetup."Unrealized VAT Type" = VatPostingSetup."Unrealized VAT Type"::" " then begin
                    PurchTaxCrMemoLine.TransferFieldsFrom(PurchCrMemoLine);
                    PurchTaxCrMemoLine."Document No." := PurchTaxCrMemoHeader."No.";
                    PurchTaxCrMemoLine."External Document No." := PurchCrMemoHeader."No.";
                    PurchTaxCrMemoLine.Insert();
                end;
        until PurchCrMemoLine.Next() = 0;
        TempPurchTaxCrMemoLine.Reset();
        TempPurchTaxCrMemoLine.SetRange("Document No.", PurchTaxCrMemoHeader."No.");
        if not TempPurchTaxCrMemoLine.FindFirst() then begin
            PurchTaxCrMemoHeader.Delete();
            PurchSetup.Get();
            if CheckTaxableNoSeries(PurchCrMemoHeader."Buy-from Vendor No.", 0) then
                ReverseGetNextNo(PurchSetup."Posted Non Tax Credit Memo Nos", PurchTaxCrMemoHeader."Posting Date")
            else
                ReverseGetNextNo(PurchSetup."Posted Tax Credit Memo Nos", PurchTaxCrMemoHeader."Posting Date");
        end else begin
            BuildTaxPostBuffer(PurchTaxCrMemoHeader."No.", PurchTaxCrMemoHeader."Posting Description", 2);
            PurchCrMemoHeader2."Printed Tax Document" := true;
            PurchCrMemoHeader2.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SalesTaxInvPosted(SalesInvHeader: Record "Sales Invoice Header"; Print: Boolean) TaxInvNo: Code[20]
    var
        SalesTaxInvHeader: Record "Sales Tax Invoice Header";
        ReportSelection: Record "Report Selections";
        SalesSetup: Record "Sales & Receivables Setup";
        TaxInvoiceNo: Code[20];
    begin
        if SalesInvHeader."Posted Tax Document" then
            Error(Text032, SalesInvHeader."No.");
        if Print then
            if not Confirm(Text031) then
                exit;
        if not Print then
            if not Confirm(Text030) then
                exit;
        TaxInvoiceNo := SalesTaxInvPost(SalesInvHeader);
        SalesInvHeader."Posted Tax Document" := true;
        if Print then begin
            SalesTaxInvoiceHeader.Get(TaxInvoiceNo);
            ReportSelection.Reset();
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.TaxInvoice");
            if ReportSelection.Find('-') then
                repeat
                    REPORT.Run(ReportSelection."Report ID", SalesSetup."Print Dialog", false, SalesTaxInvHeader);
                until ReportSelection.Next() = 0;
            SalesInvHeader."Printed Tax Document" := true;
            Message(Text034, TaxInvoiceNo);
        end else
            Message(Text033, TaxInvoiceNo);
        SalesInvHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure PurchTaxInvPosted(PurchInvHeader: Record "Purch. Inv. Header"; Print: Boolean) TaxInvNo: Code[20]
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
        ReportSelection: Record "Report Selections";
        PurchSetup: Record "Purchases & Payables Setup";
        TaxInvoiceNo: Code[20];
    begin
        if PurchInvHeader."Posted Tax Document" then
            Error(Text032, PurchInvHeader."No.");
        if Print then
            if not Confirm(Text031) then
                exit;
        if not Print then
            if not Confirm(Text030) then
                exit;
        TaxInvoiceNo := PurchTaxInvPost(PurchInvHeader);
        PurchInvHeader."Posted Tax Document" := true;
        if Print then begin
            PurchTaxInvoiceHeader.Get(TaxInvoiceNo);
            ReportSelection.Reset();
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.TaxInvoice");
            if ReportSelection.Find('-') then
                repeat
                    REPORT.Run(ReportSelection."Report ID", PurchSetup."Print Dialog", false, PurchTaxInvHeader);
                until ReportSelection.Next() = 0;
            PurchInvHeader."Printed Tax Document" := true;
            Message(Text034, TaxInvoiceNo);
        end else
            Message(Text033, TaxInvoiceNo);
        PurchInvHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure SalesTaxCrMemoPosted(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; Print: Boolean) TaxInvNo: Code[20]
    var
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
        ReportSelection: Record "Report Selections";
        SalesSetup: Record "Sales & Receivables Setup";
        TaxInvoiceNo: Code[20];
    begin
        if SalesCrMemoHeader."Posted Tax Document" then
            Error(Text042, SalesCrMemoHeader."No.");
        if Print then
            if not Confirm(Text041) then
                exit;
        if not Print then
            if not Confirm(Text040) then
                exit;
        TaxInvoiceNo := SalesTaxCrMemoPost(SalesCrMemoHeader);
        SalesCrMemoHeader."Posted Tax Document" := true;
        if Print then begin
            SalesTaxCrMemoHeader.Get(TaxInvoiceNo);
            ReportSelection.Reset();
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.TaxCreditMemo");
            if ReportSelection.Find('-') then
                repeat
                    REPORT.Run(ReportSelection."Report ID", SalesSetup."Print Dialog", false, SalesTaxCrMemoHeader);
                until ReportSelection.Next() = 0;
            SalesCrMemoHeader."Printed Tax Document" := true;
            Message(Text044, TaxInvoiceNo);
        end else
            Message(Text043, TaxInvoiceNo);
        SalesCrMemoHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure PurchTaxCrMemoPosted(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; Print: Boolean) TaxInvNo: Code[20]
    var
        PurchTaxCrMemoHeader: Record "Purch. Tax Cr. Memo Hdr.";
        ReportSelection: Record "Report Selections";
        PurchSetup: Record "Purchases & Payables Setup";
        TaxInvoiceNo: Code[20];
    begin
        if PurchCrMemoHeader."Posted Tax Document" then
            Error(Text042, PurchCrMemoHeader."No.");
        if Print then
            if not Confirm(Text041) then
                exit;
        if not Print then
            if not Confirm(Text040) then
                exit;
        TaxInvoiceNo := PurchTaxCrMemoPost(PurchCrMemoHeader);
        PurchCrMemoHeader."Posted Tax Document" := true;
        if Print then begin
            SalesTaxCrMemoHeader.Get(TaxInvoiceNo);
            ReportSelection.Reset();
            ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.TaxCreditMemo");
            if ReportSelection.Find('-') then
                repeat
                    REPORT.Run(ReportSelection."Report ID", PurchSetup."Print Dialog", false, PurchTaxCrMemoHeader);
                until ReportSelection.Next() = 0;
            PurchCrMemoHeader."Printed Tax Document" := true;
            Message(Text044, TaxInvoiceNo);
        end else
            Message(Text043, TaxInvoiceNo);
        PurchCrMemoHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure TaxInvoiceSales(var GenJnlLine: Record "Gen. Journal Line"; WHTUsed: Boolean; AmountWithDisc: Boolean)
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry1: Record "WHT Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesTaxInvHeader: Record "Sales Tax Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesTaxInvLine: Record "Sales Tax Invoice Line";
        LineNo: Integer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry1: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        WHTAmount1: Decimal;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LineNo := 10000;
        WHTAmount := 0;
        CustLedgEntry1.Reset();
        if GenJnlLine."WHT Payment" then
            exit;
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then begin
            if not SalesCrMemoHeader.Get(GenJnlLine."Applies-to Doc. No.") then
                exit;
            if not SalesCrMemoHeader."Tax Document Marked" then
                exit;
            if not WHTUsed then begin
                SalesTaxInvHeader.Init();
                SalesTaxInvHeader.TransferFields(SalesCrMemoHeader);
                SalesTaxInvLine."External Document No." := SalesCrMemoHeader."No.";
                SalesTaxInvHeader."Posting Description" := GenJnlLine."Document No.";
                SalesTaxInvHeader."No." := '';
                SalesTaxInvHeader.Insert(true);
            end;
            SalesCrMemoLine.Reset();
            SalesCrMemoLine.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if SalesCrMemoLine.Find('-') then
                repeat
                    WHTAmount := 0;
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
                    WHTEntry.SetFilter("Applies-to Entry No.", '%1', 0);
                    if WHTEntry.Find('-') then
                        repeat
                            WHTAmount := WHTAmount + WHTEntry."Unrealized Amount";
                        until WHTEntry.Next() = 0;
                    Payment1 := 0;
                    Payment2 := 0;
                    CustLedgEntry.Reset();
                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
                    CustLedgEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
                    if CustLedgEntry.FindFirst() then
                        CustLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");

                    SalesTaxInvHeader.SetRange("Posting Description", GenJnlLine."Document No.");
                    if SalesTaxInvHeader.FindFirst() then begin
                        SalesTaxInvLine.SetRange("Document No.", SalesTaxInvHeader."No.");
                        if SalesTaxInvLine.FindLast() then
                            LineNo := SalesTaxInvLine."Line No." + 10000;
                    end;
                    if LineNo = 0 then
                        LineNo := 10000;
                    SalesTaxInvLine.Init();
                    if VATPostingSetup.Get(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group") then
                        if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then begin
                            SalesTaxInvLine.TransferFieldsFrom(SalesCrMemoLine);
                            SalesTaxInvLine."Line No." := LineNo;
                            SalesTaxInvLine."Document No." := SalesTaxInvHeader."No.";
                            SalesTaxInvLine."Unit Price" := -SalesTaxInvLine."Unit Price";
                            SalesTaxInvLine."Line Amount" := -SalesTaxInvLine."Line Amount";
                            SalesTaxInvLine.Amount := -SalesTaxInvLine.Amount;
                            SalesTaxInvLine."Amount Including VAT" := -SalesTaxInvLine."Amount Including VAT";
                            SalesTaxInvLine."VAT Base Amount" := -SalesTaxInvLine."VAT Base Amount";
                            SalesTaxInvLine."External Document No." := SalesCrMemoHeader."No.";
                            GLSetup.Get();
                            if GLSetup."Manual Sales WHT Calc." then begin
                                if not GenJnlLine."WHT Payment" then begin
                                    ExpectedAmount := CustLedgEntry.Amount + WHTAmount;
                                    if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                                       ((Abs(GenJnlLine.Amount) + Abs(WHTAmount)) >= (Abs(CustLedgEntry."Rem. Amt" + CustLedgEntry1."Rem. Amt") -
                                                                                      Abs(CustLedgEntry."Original Pmt. Disc. Possible"))) and
                                       (not AmountWithDisc)
                                    then
                                        GenLineAmount := GenJnlLine.Amount - CustLedgEntry."Original Pmt. Disc. Possible" + WHTAmount
                                    else
                                        GenLineAmount := GenJnlLine.Amount + WHTAmount;
                                    if Abs(GenJnlLine.Amount) < Abs(CustLedgEntry.Amount) then
                                        GenLineAmount := GenLineAmount - WHTAmount;
                                    SalesTaxInvLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                        SalesCrMemoLine."Amount Including VAT" / ExpectedAmount);
                                    SalesTaxInvLine."Paid VAT" := Round(Abs(GenLineAmount)
                                        * (SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine."VAT Base Amount")
                                        / ExpectedAmount);
                                    TotWHTAmount := TotWHTAmount + WHTAmount;
                                end;
                            end else begin
                                if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                                   (Abs(GenJnlLine.Amount) >= (Abs(CustLedgEntry."Rem. Amt" + CustLedgEntry1."Rem. Amt") - Abs(
                                                                 CustLedgEntry."Original Pmt. Disc. Possible"))) and (not AmountWithDisc)
                                then
                                    GenLineAmount := GenJnlLine.Amount - CustLedgEntry."Original Pmt. Disc. Possible"
                                else
                                    GenLineAmount := GenJnlLine.Amount;
                                ExpectedAmount := CustLedgEntry.Amount;
                                SalesTaxInvLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                    SalesCrMemoLine."Amount Including VAT" / ExpectedAmount);
                                SalesTaxInvLine."Paid VAT" := Round(Abs(GenLineAmount)
                                    * (SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine."VAT Base Amount")
                                    / ExpectedAmount);
                            end;
                            if (GenJnlLine."Currency Code" <> WHTEntry."Currency Code") and (WHTAmount <> 0) then
                                Error('');
                            if SalesTaxInvLine."Paid VAT" <> 0 then
                                SalesTaxInvLine.Insert();
                            LineNo := LineNo + 10000;
                        end;
                until SalesCrMemoLine.Next() = 0;
            SalesCrMemoHeader."Posted Tax Document" := true;
            SalesCrMemoHeader.Modify();
        end else begin
            if not SalesInvHeader.Get(GenJnlLine."Applies-to Doc. No.") then
                exit;
            if not SalesInvHeader."Tax Document Marked" then
                exit;
            if not WHTUsed then begin
                SalesTaxInvHeader.Init();
                SalesTaxInvHeader.TransferFields(SalesInvHeader);
                SalesTaxInvLine."External Document No." := SalesInvHeader."No.";
                SalesTaxInvHeader."Posting Description" := GenJnlLine."Document No.";
                SalesTaxInvHeader."No." := '';
                SalesTaxInvHeader.Insert(true);
            end;
            SalesInvoiceLine.Reset();
            SalesInvoiceLine.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if SalesInvoiceLine.Find('-') then
                repeat
                    WHTAmount := 0;
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
                    WHTEntry.SetFilter("Applies-to Entry No.", '%1', 0);
                    if WHTEntry.Find('-') then
                        repeat
                            WHTAmount := WHTAmount + WHTEntry."Unrealized Amount";
                        until WHTEntry.Next() = 0;
                    Payment1 := 0;
                    Payment2 := 0;
                    CustLedgEntry.Reset();
                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                    CustLedgEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
                    if CustLedgEntry.FindFirst() then begin
                        CustLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");
                        SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
                        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceLine."Document No.");
                        if SalesCrMemoHeader.FindFirst() then begin
                            CustLedgEntry1.SetRange("Document Type", CustLedgEntry1."Document Type"::"Credit Memo");
                            CustLedgEntry1.SetRange("Document No.", SalesCrMemoHeader."No.");
                            if CustLedgEntry1.FindFirst() then
                                CustLedgEntry1.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");
                            WHTAmount1 := 0;
                            WHTEntry1.Reset();
                            WHTEntry1.SetRange("Document No.", SalesCrMemoHeader."No.");
                            WHTEntry1.SetFilter("Applies-to Entry No.", '%1', 0);
                            if WHTEntry1.Find('-') then
                                repeat
                                    WHTAmount1 := WHTAmount1 + WHTEntry1."Unrealized Amount";
                                until WHTEntry1.Next() = 0;
                            WHTAmount := WHTAmount + WHTAmount1;
                        end;
                        SalesTaxInvHeader.SetRange("Posting Description", GenJnlLine."Document No.");
                        if SalesTaxInvHeader.FindFirst() then begin
                            SalesTaxInvLine.SetRange("Document No.", SalesTaxInvHeader."No.");
                            if SalesTaxInvLine.FindLast() then
                                LineNo := SalesTaxInvLine."Line No." + 10000;
                        end;
                        if LineNo = 0 then
                            LineNo := 10000;
                        SalesTaxInvLine.Init();
                        if VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group") then
                            if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then begin
                                SalesTaxInvLine.TransferFieldsFrom(SalesInvoiceLine);
                                SalesTaxInvLine."Line No." := LineNo;
                                SalesTaxInvLine."Document No." := SalesTaxInvHeader."No.";
                                SalesTaxInvLine."External Document No." := SalesInvHeader."No.";
                                SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                                SalesCrMemoLine.SetRange(Type, SalesInvoiceLine.Type);
                                SalesCrMemoLine.SetRange("No.", SalesInvoiceLine."No.");
                                if SalesCrMemoLine.Find('-') then begin
                                    VATCrMemoAmt := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine."VAT Base Amount";
                                    VATCrMemoBase := SalesCrMemoLine."Amount Including VAT";
                                end;
                                GLSetup.Get();
                                if GLSetup."Manual Sales WHT Calc." then begin
                                    if not GenJnlLine."WHT Payment" then begin
                                        if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                                           ((Abs(GenJnlLine.Amount) + Abs(WHTAmount)) >= (Abs(CustLedgEntry."Rem. Amt" + CustLedgEntry1."Rem. Amt") -
                                                                                          Abs(CustLedgEntry."Original Pmt. Disc. Possible"))) and
                                           (not AmountWithDisc)
                                        then
                                            GenLineAmount := GenJnlLine.Amount - CustLedgEntry."Original Pmt. Disc. Possible"
                                        else
                                            GenLineAmount := GenJnlLine.Amount;
                                        TotWHTAmount := TotWHTAmount + WHTAmount;
                                        ExpectedAmount := CustLedgEntry.Amount + CustLedgEntry1.Amount;
                                        if Abs(GenJnlLine.Amount) < Abs(CustLedgEntry.Amount + CustLedgEntry1.Amount) then
                                            ExpectedAmount := ExpectedAmount + WHTAmount;

                                        SalesTaxInvLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                            (SalesInvoiceLine."Amount Including VAT" - VATCrMemoAmt) / ExpectedAmount);
                                        SalesTaxInvLine."Paid VAT" := Round(Abs(GenLineAmount)
                                            * (SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine."VAT Base Amount" - VATCrMemoAmt)
                                            / ExpectedAmount);
                                    end;
                                end else begin
                                    if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                                       ((Abs(GenJnlLine.Amount) + Abs(WHTAmount)) >= (Abs(CustLedgEntry."Rem. Amt" + CustLedgEntry1."Rem. Amt") -
                                                                                      Abs(CustLedgEntry."Original Pmt. Disc. Possible"))) and
                                       (not AmountWithDisc)
                                    then
                                        GenLineAmount := GenJnlLine.Amount - CustLedgEntry."Original Pmt. Disc. Possible"
                                    else
                                        GenLineAmount := GenJnlLine.Amount;
                                    ExpectedAmount := CustLedgEntry.Amount + CustLedgEntry1.Amount;
                                    SalesTaxInvLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                        (SalesInvoiceLine."Amount Including VAT" - VATCrMemoBase) / ExpectedAmount);
                                    SalesTaxInvLine."Paid VAT" := Round(Abs(GenLineAmount)
                                        * (SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine."VAT Base Amount" - VATCrMemoAmt)
                                        / ExpectedAmount);
                                end;
                                if (GenJnlLine."Currency Code" <> WHTEntry."Currency Code") and (WHTAmount <> 0) then
                                    Error('');
                                if SalesTaxInvLine."Paid VAT" <> 0 then
                                    SalesTaxInvLine.Insert();
                                LineNo := LineNo + 10000;
                            end;
                    end;
                until SalesInvoiceLine.Next() = 0;
            InvNo := SalesTaxInvHeader."No.";
            SalesInvHeader."Printed Tax Document" := true;
            SalesInvHeader."Posted Tax Document" := true;
            SalesInvHeader.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure TaxInvoiceSalesCrMemo(var GenJnlLine: Record "Gen. Journal Line"; WHTUsed: Boolean; AmountWithDisc: Boolean)
    var
        WHTEntry: Record "WHT Entry";
        SalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
        LineNo: Integer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry1: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LineNo := 10000;
        WHTAmount := 0;
        CustLedgEntry1.Reset();
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then begin
            if not SalesCrMemoHeader.Get(GenJnlLine."Applies-to Doc. No.") then
                exit;
            if not SalesCrMemoHeader."Tax Document Marked" then
                exit;
            if not WHTUsed then begin
                SalesTaxCrMemoHeader.Init();
                SalesTaxCrMemoHeader.TransferFieldsFrom(SalesCrMemoHeader);
                SalesTaxCrMemoLine."External Document No." := SalesCrMemoHeader."No.";
                SalesTaxCrMemoHeader."Posting Description" := GenJnlLine."Document No.";
                SalesTaxCrMemoHeader."No." := '';
                SalesTaxCrMemoHeader.Insert(true);
            end;
            SalesCrMemoLine.Reset();
            SalesCrMemoLine.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if SalesCrMemoLine.Find('-') then
                repeat
                    WHTAmount := 0;
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
                    WHTEntry.SetFilter("Applies-to Entry No.", '<>%1', 0);
                    if WHTEntry.Find('-') then
                        repeat
                            WHTAmount := WHTAmount + WHTEntry.Amount;
                        until WHTEntry.Next() = 0;
                    Payment1 := 0;
                    Payment2 := 0;

                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
                    CustLedgEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
                    if CustLedgEntry.FindFirst() then
                        CustLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");

                    SalesTaxCrMemoHeader.SetRange("Posting Description", GenJnlLine."Document No.");
                    if SalesTaxCrMemoHeader.FindFirst() then begin
                        SalesTaxCrMemoLine.SetRange("Document No.", SalesTaxCrMemoHeader."No.");
                        if SalesTaxCrMemoLine.FindLast() then
                            LineNo := SalesTaxCrMemoLine."Line No." + 10000;
                    end;
                    if LineNo = 0 then
                        LineNo := 10000;

                    SalesTaxCrMemoLine.Init();
                    if VATPostingSetup.Get(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group") then
                        if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then begin
                            SalesTaxCrMemoLine.TransferFieldsFrom(SalesCrMemoLine);
                            SalesTaxCrMemoLine."Line No." := LineNo;
                            SalesTaxCrMemoLine."Document No." := SalesTaxCrMemoHeader."No.";
                            SalesTaxCrMemoLine."External Document No." := SalesCrMemoHeader."No.";
                            GLSetup.Get();
                            if GLSetup."Manual Sales WHT Calc." then begin
                                if GenJnlLine."WHT Payment" then begin
                                    if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and (not AmountWithDisc) then
                                        ExpectedAmount := CustLedgEntry.Amount - WHTAmount - CustLedgEntry."Original Pmt. Disc. Possible"
                                    else
                                        ExpectedAmount := CustLedgEntry.Amount - WHTAmount;
                                    SalesTaxCrMemoLine."Paid Amount Incl. VAT" := Round(Abs(GenJnlLine.Amount) *
                                        SalesCrMemoLine."Amount Including VAT" / ExpectedAmount);
                                    SalesTaxCrMemoLine."Paid VAT" := Round(Abs(GenJnlLine.Amount)
                                        * (SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine."VAT Base Amount")
                                        / ExpectedAmount);
                                end;
                            end else begin
                                if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and (not AmountWithDisc) then
                                    ExpectedAmount := CustLedgEntry.Amount - CustLedgEntry."Original Pmt. Disc. Possible"
                                else
                                    ExpectedAmount := CustLedgEntry.Amount;
                                SalesTaxCrMemoLine."Paid Amount Incl. VAT" := Round(Abs(GenJnlLine.Amount) *
                                    SalesCrMemoLine."Amount Including VAT" / ExpectedAmount);
                                SalesTaxCrMemoLine."Paid VAT" := Round(Abs(GenJnlLine.Amount)
                                    * (SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine."VAT Base Amount")
                                    / ExpectedAmount);
                            end;
                            if (GenJnlLine."Currency Code" <> WHTEntry."Currency Code") and (WHTAmount <> 0) then
                                Error('');
                            if SalesTaxCrMemoLine."Paid VAT" <> 0 then
                                SalesTaxCrMemoLine.Insert();
                            LineNo := LineNo + 10000;
                        end;
                until SalesCrMemoLine.Next() = 0;
        end;
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then begin
            InvNo := SalesTaxCrMemoHeader."No.";
            SalesCrMemoHeader."Printed Tax Document" := true;
            SalesCrMemoHeader."Posted Tax Document" := true;
            SalesCrMemoHeader.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure TaxInvoicePurchase(var GenJnlLine: Record "Gen. Journal Line"; AmountWithDisc: Boolean)
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry1: Record "WHT Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
        PurchInvoiceLine: Record "Purch. Inv. Line";
        PurchTaxInvLine: Record "Purch. Tax Inv. Line";
        LineNo: Integer;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        WHTAmount1: Decimal;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        WHTAmount := 0;
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then begin
            if not PurchCrMemoHeader.Get(GenJnlLine."Applies-to Doc. No.") then
                exit;
            if not PurchCrMemoHeader."Posted Tax Document" then
                exit;
            if not GenJnlLine."WHT Payment" then begin
                PurchTaxInvHeader.Init();
                PurchTaxInvHeader.TransferFields(PurchCrMemoHeader);
                PurchTaxInvHeader."Posting Date" := GenJnlLine."Posting Date";
                PurchTaxInvHeader."Posting Description" := GenJnlLine."Document No.";
                PurchTaxInvLine."External Document No." := PurchCrMemoHeader."No.";
                PurchTaxInvHeader."No." := '';
                PurchTaxInvHeader.Insert(true);
            end;
            PurchCrMemoLine.Reset();
            PurchCrMemoLine.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if PurchCrMemoLine.Find('-') then
                repeat
                    WHTAmount := 0;
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", PurchCrMemoLine."Document No.");
                    WHTEntry.SetRange("Applies-to Entry No.", 0);
                    if WHTEntry.Find('-') then
                        repeat
                            WHTAmount := WHTAmount + WHTEntry.Amount;
                        until WHTEntry.Next() = 0;
                    Payment1 := 0;
                    Payment2 := 0;

                    PurchTaxInvHeader.SetRange("Posting Description", GenJnlLine."Document No.");
                    if PurchTaxInvHeader.FindFirst() then begin
                        PurchTaxInvLine.SetRange("Document No.", PurchTaxInvHeader."No.");
                        if PurchTaxInvLine.FindLast() then
                            LineNo := PurchTaxInvLine."Line No." + 10000;
                    end;
                    if LineNo = 0 then
                        LineNo := 10000;
                    VendLedgEntry.Reset();
                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                    VendLedgEntry.SetRange("Document No.", PurchCrMemoLine."Document No.");
                    if VendLedgEntry.FindFirst() then begin
                        VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");

                        PurchTaxInvLine.Init();
                        if VATPostingSetup.Get(PurchCrMemoLine."VAT Bus. Posting Group", PurchCrMemoLine."VAT Prod. Posting Group") then
                            if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then begin
                                PurchTaxInvLine.TransferFieldsFrom(PurchCrMemoLine);
                                PurchTaxInvLine."Line No." := LineNo;
                                PurchTaxInvLine."Document No." := PurchTaxInvHeader."No.";
                                PurchTaxInvLine.Amount := -PurchTaxInvLine.Amount;
                                PurchTaxInvLine."Amount Including VAT" := -PurchTaxInvLine."Amount Including VAT";
                                PurchTaxInvLine."Direct Unit Cost" := -PurchTaxInvLine."Direct Unit Cost";
                                PurchTaxInvLine."Unit Cost (LCY)" := -PurchTaxInvLine."Unit Cost (LCY)";
                                PurchTaxInvLine."Line Amount" := -PurchTaxInvLine."Line Amount";
                                PurchTaxInvLine."VAT Base Amount" := -PurchTaxInvLine."VAT Base Amount";
                                PurchTaxInvLine."External Document No." := PurchCrMemoHeader."No.";
                                if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                   (Abs(GenJnlLine.Amount) >= (Abs(VendLedgEntry."Rem. Amt") -
                                                               Abs(VendLedgEntry."Original Pmt. Disc. Possible"))) and (not AmountWithDisc)
                                then
                                    GenLineAmount := GenJnlLine.Amount + VendLedgEntry."Original Pmt. Disc. Possible"
                                else
                                    GenLineAmount := GenJnlLine.Amount;
                                ExpectedAmount := -VendLedgEntry.Amount;
                                PurchTaxInvLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                    PurchCrMemoLine."Amount Including VAT" / ExpectedAmount);
                                PurchTaxInvLine."Paid VAT" := Round(Abs(GenLineAmount)
                                    * (PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine."VAT Base Amount")
                                    / ExpectedAmount);
                                if PurchTaxInvLine."Paid VAT" <> 0 then
                                    PurchTaxInvLine.Insert();
                                LineNo := LineNo + 10000;
                            end;
                    end;
                until PurchCrMemoLine.Next() = 0;
        end else begin
            if not PurchInvHeader.Get(GenJnlLine."Applies-to Doc. No.") then
                exit;
            if not PurchInvHeader."Posted Tax Document" then
                exit;
            if not GenJnlLine."WHT Payment" then begin
                PurchTaxInvHeader.Init();
                PurchTaxInvHeader.TransferFieldsFrom(PurchInvHeader);
                PurchTaxInvHeader."Posting Date" := GenJnlLine."Posting Date";
                PurchTaxInvHeader."Posting Description" := GenJnlLine."Document No.";
                PurchTaxInvLine."External Document No." := PurchInvHeader."No.";
                PurchTaxInvHeader."No." := '';
                PurchTaxInvHeader.Insert(true);
            end;
            PurchInvoiceLine.Reset();
            PurchInvoiceLine.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if PurchInvoiceLine.Find('-') then
                repeat
                    WHTAmount := 0;
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", PurchInvoiceLine."Document No.");
                    WHTEntry.SetRange("Applies-to Entry No.", 0);
                    if WHTEntry.Find('-') then
                        repeat
                            WHTAmount := WHTAmount + WHTEntry.Amount;
                        until WHTEntry.Next() = 0;
                    Payment1 := 0;
                    Payment2 := 0;

                    PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                    PurchCrMemoHeader.SetRange("Applies-to Doc. No.", PurchInvoiceLine."Document No.");
                    if PurchCrMemoHeader.FindFirst() then begin
                        VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                        VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                        if VendLedgEntry1.FindFirst() then
                            VendLedgEntry1.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");

                        WHTAmount1 := 0;
                        WHTEntry1.Reset();
                        WHTEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                        WHTEntry1.SetRange("Applies-to Entry No.", 0);
                        if WHTEntry1.Find('-') then
                            repeat
                                WHTAmount1 := WHTAmount1 + WHTEntry1.Amount;
                            until WHTEntry1.Next() = 0;
                        WHTAmount := WHTAmount + WHTAmount1;
                    end;
                    PurchTaxInvHeader.SetRange("Posting Description", GenJnlLine."Document No.");
                    if PurchTaxInvHeader.FindFirst() then begin
                        PurchTaxInvLine.SetRange("Document No.", PurchTaxInvHeader."No.");
                        if PurchTaxInvLine.FindLast() then
                            LineNo := PurchTaxInvLine."Line No." + 10000;
                    end;
                    if LineNo = 0 then
                        LineNo := 10000;
                    VendLedgEntry.Reset();
                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
                    VendLedgEntry.SetRange("Document No.", PurchInvoiceLine."Document No.");
                    if VendLedgEntry.FindFirst() then begin
                        VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");
                        PurchTaxInvLine.Init();
                        if VATPostingSetup.Get(PurchInvoiceLine."VAT Bus. Posting Group", PurchInvoiceLine."VAT Prod. Posting Group") then
                            if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then begin
                                PurchTaxInvLine.TransferFieldsFrom(PurchInvoiceLine);
                                PurchTaxInvLine."Line No." := LineNo;
                                PurchTaxInvLine."Document No." := PurchTaxInvHeader."No.";
                                PurchTaxInvLine."External Document No." := PurchInvHeader."No.";
                                if VendLedgEntry1."Amount (LCY)" = 0 then
                                    VendLedgEntry1."Rem. Amt" := 0;
                                if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                   (Abs(GenJnlLine.Amount) >= (Abs(VendLedgEntry."Rem. Amt" + VendLedgEntry1."Rem. Amt") -
                                                               Abs(VendLedgEntry."Original Pmt. Disc. Possible"))) and (not AmountWithDisc)
                                then
                                    GenLineAmount := GenJnlLine.Amount - VendLedgEntry."Original Pmt. Disc. Possible"
                                else
                                    GenLineAmount := GenJnlLine.Amount;
                                ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                                PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHeader."No.");
                                PurchCrMemoLine.SetRange(Type, PurchInvoiceLine.Type);
                                PurchCrMemoLine.SetRange("No.", PurchInvoiceLine."No.");
                                if PurchCrMemoLine.Find('-') then begin
                                    PurchTaxInvLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                        (PurchInvoiceLine."Amount Including VAT" - PurchCrMemoLine."Amount Including VAT") / ExpectedAmount);
                                    PurchTaxInvLine."Paid VAT" := Round(Abs(GenLineAmount)
                                        *
                                        (PurchInvoiceLine."Amount Including VAT" -
                                         PurchInvoiceLine."VAT Base Amount" - PurchCrMemoLine."Amount Including VAT" +
                                         PurchCrMemoLine."VAT Base Amount") / ExpectedAmount);
                                end else begin
                                    PurchTaxInvLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                        PurchInvoiceLine."Amount Including VAT" / ExpectedAmount);
                                    PurchTaxInvLine."Paid VAT" := Round(Abs(GenLineAmount)
                                        * (PurchInvoiceLine."Amount Including VAT" - PurchInvoiceLine."VAT Base Amount")
                                        / ExpectedAmount);
                                end;
                                if (GenJnlLine."Currency Code" <> WHTEntry."Currency Code") and (WHTAmount <> 0) then
                                    Error('');
                                if PurchTaxInvLine."Paid VAT" <> 0 then
                                    PurchTaxInvLine.Insert();
                                LineNo := LineNo + 10000;
                            end;
                    end;
                until PurchInvoiceLine.Next() = 0;
            InvNo := PurchTaxInvHeader."No.";
            PurchInvHeader."Printed Tax Document" := true;
            PurchInvHeader.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure TaxInvoicePurchaseCrMemo(var GenJnlLine: Record "Gen. Journal Line"; WHTUsed: Boolean; AmountWithDisc: Boolean)
    var
        PurchTaxCrMemoHeader: Record "Purch. Tax Cr. Memo Hdr.";
        PurchTaxCrMemoLine: Record "Purch. Tax Cr. Memo Line";
        LineNo: Integer;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        WHTAmount1: Decimal;
        VATPostingSetup: Record "VAT Posting Setup";
        TempWHTEntry: Record "WHT Entry";
    begin
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then begin
            if not PurchCrMemoHeader.Get(GenJnlLine."Applies-to Doc. No.") then
                exit;
            if not PurchCrMemoHeader."Posted Tax Document" then
                exit;
            if GenJnlLine."WHT Payment" then
                exit;
            if not WHTUsed then begin
                PurchTaxCrMemoHeader.Init();
                PurchTaxCrMemoHeader.TransferFieldsFrom(PurchCrMemoHeader);
                PurchTaxCrMemoHeader."Posting Date" := GenJnlLine."Posting Date";
                PurchTaxCrMemoHeader."Posting Description" := GenJnlLine."Document No.";
                PurchTaxCrMemoLine."External Document No." := PurchCrMemoHeader."No.";
                PurchTaxCrMemoHeader."No." := '';
                PurchTaxCrMemoHeader.Insert(true);
            end;
            PurchCrMemoLine.Reset();
            PurchCrMemoLine.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if PurchCrMemoLine.Find('-') then
                repeat
                    Payment1 := 0;
                    Payment2 := 0;

                    PurchTaxCrMemoHeader.SetRange("Posting Description", GenJnlLine."Document No.");
                    if PurchTaxCrMemoHeader.FindFirst() then begin
                        PurchTaxCrMemoLine.Reset();
                        PurchTaxCrMemoLine.SetRange("Document No.", PurchTaxCrMemoHeader."No.");
                        if PurchTaxCrMemoLine.FindLast() then
                            LineNo := PurchTaxCrMemoLine."Line No." + 10000;
                    end;
                    if LineNo = 0 then
                        LineNo := 10000;
                    VendLedgEntry.Reset();
                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                    VendLedgEntry.SetRange("Document No.", PurchCrMemoLine."Document No.");
                    if VendLedgEntry.FindFirst() then begin
                        VendLedgEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)", Amount, "Remaining Amount");

                        PurchTaxCrMemoLine.Init();
                        if VATPostingSetup.Get(PurchCrMemoLine."VAT Bus. Posting Group", PurchCrMemoLine."VAT Prod. Posting Group") then
                            if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then begin
                                PurchTaxCrMemoLine.TransferFieldsFrom(PurchCrMemoLine);
                                PurchTaxCrMemoLine."Line No." := LineNo;
                                PurchTaxCrMemoLine."Document No." := PurchTaxCrMemoHeader."No.";
                                PurchTaxCrMemoLine."External Document No." := PurchCrMemoHeader."No.";
                                WHTAmount := 0;
                                WHTAmount1 := 0;
                                TempWHTEntry.Reset();
                                TempWHTEntry.SetRange("Document No.", PurchCrMemoHeader."No.");
                                TempWHTEntry.SetFilter("Applies-to Entry No.", '%1', 0);
                                if TempWHTEntry.Find('-') then
                                    repeat
                                        WHTAmount1 := WHTAmount1 + TempWHTEntry."Unrealized Amount (LCY)";
                                    until TempWHTEntry.Next() = 0;
                                WHTAmount := WHTAmount - WHTAmount1;

                                GLSetup.Get();
                                if GLSetup."Manual Sales WHT Calc." then begin
                                    if not GenJnlLine."WHT Payment" then begin
                                        if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                           ((Abs(GenJnlLine.Amount) + Abs(WHTAmount)) >= (Abs(VendLedgEntry."Rem. Amt") -
                                                                                          Abs(VendLedgEntry."Original Pmt. Disc. Possible"))) and
                                           (not AmountWithDisc)
                                        then
                                            GenLineAmount := GenJnlLine.Amount - VendLedgEntry."Original Pmt. Disc. Possible"
                                        else
                                            GenLineAmount := GenJnlLine.Amount;
                                        ExpectedAmount := -VendLedgEntry.Amount + WHTAmount;
                                    end;
                                end else begin
                                    if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                       (Abs(GenJnlLine.Amount) >= (Abs(VendLedgEntry."Rem. Amt") -
                                                                   Abs(VendLedgEntry."Original Pmt. Disc. Possible"))) and (not AmountWithDisc)
                                    then
                                        GenLineAmount := GenJnlLine.Amount - VendLedgEntry."Original Pmt. Disc. Possible"
                                    else
                                        GenLineAmount := GenJnlLine.Amount;
                                    ExpectedAmount := -VendLedgEntry.Amount;
                                end;
                                PurchTaxCrMemoLine."Paid Amount Incl. VAT" := Round(Abs(GenLineAmount) *
                                    PurchCrMemoLine."Amount Including VAT" / ExpectedAmount);
                                PurchTaxCrMemoLine."Paid VAT" := Round(Abs(GenLineAmount)
                                    * (PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine."VAT Base Amount")
                                    / ExpectedAmount);

                                if PurchTaxCrMemoLine."Paid VAT" <> 0 then
                                    PurchTaxCrMemoLine.Insert();
                                LineNo := LineNo + 10000;
                            end;
                    end;
                until PurchCrMemoLine.Next() = 0;
        end;
        InvNo := PurchTaxCrMemoHeader."No.";
        PurchCrMemoHeader."Printed Tax Document" := true;
        PurchCrMemoHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure GroupSalesTaxInvPosted(var SalesInvHeader: Record "Sales Invoice Header"; Print: Boolean)
    var
        Window: Dialog;
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvHeader2: Record "Sales Invoice Header";
        SalesTaxInvHeader: Record "Sales Tax Invoice Header";
        SalesTaxInvHeader2: Record "Sales Tax Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesTaxInvLine: Record "Sales Tax Invoice Line";
        ReportSelection: Record "Report Selections";
        LineNumber: Integer;
        TaxDocBufferBuild: Record "Tax Document Buffer Build";
        TaxDocBuffer: Record "Tax Document Buffer";
        TaxDocBuffer2: Record "Tax Document Buffer";
        TempSalesTaxInvLine: Record "Sales Tax Invoice Line";
    begin
        SalesSetup.Get();
        if Print then
            if not Confirm(Text031) then
                exit;
        if not Print then
            if not Confirm(Text030) then
                exit;
        if SalesInvHeader."Posted Tax Document" then
            exit;
        Window.Open(Text050);

        if SalesInvHeader.Find('-') then
            if SalesInvHeader."Tax Document Marked" then
                Error(Text055);

        SalesInvHeader2.Reset();
        SalesInvHeader2.SetCurrentKey(
          "Printed Tax Document", "Bill-to Customer No.", "Currency Code", "Payment Discount %", "Posted Tax Document",
          "Tax Document Marked");
        SalesInvHeader2.CopyFilters(SalesInvHeader);

        TaxDocBufferBuild.LockTable();
        TaxDocBufferBuild.DeleteAll();
        TaxDocBuffer.LockTable();
        TaxDocBuffer.DeleteAll();
        if not SalesInvHeader2.Find('-') then
            exit;
        repeat
            TaxDocBufferBuild.Init();
            TaxDocBufferBuild."Document No." := SalesInvHeader2."No.";
            TaxDocBufferBuild."Bill-to Customer No." := SalesInvHeader2."Bill-to Customer No.";
            TaxDocBufferBuild."Currency Code" := SalesInvHeader2."Currency Code";
            TaxDocBufferBuild."Payment Discount %" := SalesInvHeader2."Payment Discount %";
            TaxDocBufferBuild.Insert();
        until SalesInvHeader2.Next() = 0;

        TaxDocBufferBuild.Reset();
        TaxDocBufferBuild.SetCurrentKey("Bill-to Customer No.", "Currency Code", "Payment Discount %");
        TaxDocBufferBuild.Find('-');
        repeat
            if not TaxDocBuffer2.Get(
                 TaxDocBufferBuild."Bill-to Customer No.", TaxDocBufferBuild."Currency Code", TaxDocBufferBuild."Payment Discount %")
            then begin
                TaxDocBuffer.Init();
                TaxDocBuffer."Bill-to Customer No." := TaxDocBufferBuild."Bill-to Customer No.";
                TaxDocBuffer."Currency Code" := TaxDocBufferBuild."Currency Code";
                TaxDocBuffer."Payment Discount %" := TaxDocBufferBuild."Payment Discount %";
                TaxDocBuffer.Insert();
            end;
        until TaxDocBufferBuild.Next() = 0;

        TaxDocBuffer.Find('-');
        repeat
            TaxDocBufferBuild.Reset();
            TaxDocBufferBuild.SetRange("Bill-to Customer No.", TaxDocBuffer."Bill-to Customer No.");
            TaxDocBufferBuild.SetRange("Currency Code", TaxDocBuffer."Currency Code");
            TaxDocBufferBuild.SetRange("Payment Discount %", TaxDocBuffer."Payment Discount %");
            TaxDocBufferBuild.Find('-');
            SalesInvHeader2.Get(TaxDocBufferBuild."Document No.");
            SalesTaxInvHeader.Reset();
            SalesTaxInvHeader.Init();
            SalesTaxInvHeader.TransferFields(SalesInvHeader2);
            SalesTaxInvHeader."No." := '';
            SalesTaxInvHeader.Insert(true);
            SalesTaxInvHeader."Posting Date" := WorkDate();
            SalesTaxInvHeader.Modify();
            SalesTaxInvLine.Init();
            LineNumber := 10000;
            Window.Update(1, TaxDocBuffer."Bill-to Customer No.");
            Window.Update(2, SalesInvHeader2."No.");
            repeat
                SalesInvLine.Reset();
                SalesInvLine.SetRange("Document No.", TaxDocBufferBuild."Document No.");
                SalesInvLine.Find('-');
                repeat
                    SalesTaxInvLine.TransferFieldsFrom(SalesInvLine);
                    SalesTaxInvLine."Paid Amount Incl. VAT" := SalesTaxInvLine."Amount Including VAT";
                    SalesTaxInvLine."Paid VAT" := SalesTaxInvLine."Amount Including VAT" - SalesTaxInvLine."VAT Base Amount";
                    SalesTaxInvLine."Line No." := LineNumber;
                    SalesTaxInvLine."Document No." := SalesTaxInvHeader."No.";
                    SalesTaxInvLine."External Document No." := TaxDocBufferBuild."Document No.";
                    SalesTaxInvLine.Insert();
                    LineNumber := LineNumber + 10000;
                until SalesInvLine.Next() = 0;
            until TaxDocBufferBuild.Next() = 0;
            TempSalesTaxInvLine.SetRange("Document No.", SalesTaxInvHeader."No.");
            if not TempSalesTaxInvLine.FindFirst() then begin
                SalesTaxInvHeader.Delete();
                SalesSetup.Get();
                if CheckTaxableNoSeries(SalesInvHeader."Sell-to Customer No.", 1) then
                    ReverseGetNextNo(SalesSetup."Posted Non Tax Invoice Nos.", SalesTaxInvHeader."Posting Date")
                else
                    ReverseGetNextNo(SalesSetup."Posted Tax Invoice Nos.", SalesTaxInvHeader."Posting Date");
            end;
            if Print then begin
                SalesTaxInvHeader2.Reset();
                SalesTaxInvHeader2.SetRange("No.", SalesTaxInvHeader."No.");
                SalesTaxInvHeader2.FindFirst();
                ReportSelection.Reset();
                ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.TaxInvoice");
                if ReportSelection.Find('-') then
                    repeat
                        REPORT.Run(ReportSelection."Report ID", SalesSetup."Print Dialog", false, SalesTaxInvHeader2);
                    until ReportSelection.Next() = 0;
            end;
            TaxDocBufferBuild.Find('-');
            repeat
                SalesInvHeader2.Get(TaxDocBufferBuild."Document No.");
                SalesInvHeader2."Posted Tax Document" := true;
                if Print then
                    SalesInvHeader2."Printed Tax Document" := true;
                SalesInvHeader2.Modify();
            until TaxDocBufferBuild.Next() = 0;
        until TaxDocBuffer.Next() = 0;
        if Print then
            Message(Text054)
        else
            Message(Text053);
    end;

    [Scope('OnPrem')]
    procedure BuildTaxPostBuffer(SourceNo: Code[20]; OrigNo: Text[30]; Type: Option "Purchase Invoice","Sales Invoice","Purchase Credit Memo","Sales Credit Memo")
    var
        TaxPostBuffer: Record "Tax Posting Buffer";
    begin
        TaxPostBuffer.DeleteAll();
        TaxPostBuffer.Init();
        TaxPostBuffer."Tax Invoice No." := SourceNo;
        TaxPostBuffer."Invoice No." := OrigNo;
        case Type of
            Type::"Purchase Invoice":
                TaxPostBuffer.Type := TaxPostBuffer.Type::"Purchase Invoice";
            Type::"Sales Invoice":
                TaxPostBuffer.Type := TaxPostBuffer.Type::"Sales Invoice";
            Type::"Purchase Credit Memo":
                TaxPostBuffer.Type := TaxPostBuffer.Type::"Purchase Credit Memo";
            Type::"Sales Credit Memo":
                TaxPostBuffer.Type := TaxPostBuffer.Type::"Sales Credit Memo";
        end;
        TaxPostBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure PrintTaxInvoices(ScheduleInJobQueue: Boolean)
    var
        TaxInvBuffer: Record "Tax Posting Buffer";
        ReportSelection: Record "Report Selections";
        PurchSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
    begin
        GLSetup.Get();
        if not GLSetup."Print Tax Invoices on Posting" then
            exit;
        PurchSetup.Get();
        SalesSetup.Get();
        LastTaxInvoice := '';
        Commit();
        TaxInvBuffer.Reset();
        TaxInvBuffer.SetRange(Type, TaxInvBuffer.Type::"Purchase Invoice");
        if TaxInvBuffer.Find('-') then
            repeat
                if TaxInvBuffer."Tax Invoice No." <> LastTaxInvoice then begin
                    PurchTaxInvoiceHeader.Reset();
                    PurchTaxInvoiceHeader.SetRange("No.", TaxInvBuffer."Tax Invoice No.");
                    if PurchTaxInvoiceHeader.FindFirst() then begin
                        ReportSelection.Reset();
                        ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.TaxInvoice");
                        if ReportSelection.Find('-') then
                            repeat
                                if ScheduleInJobQueue then
                                    BatchPostingPrintMgt.SchedulePrintJobQueueEntry(PurchTaxInvoiceHeader, ReportSelection."Report ID", GLSetup."Report Output Type".AsInteger())
                                else
                                    REPORT.Run(ReportSelection."Report ID", PurchSetup."Print Dialog", false, PurchTaxInvoiceHeader);
                            until ReportSelection.Next() = 0;
                    end;
                end;
                LastTaxInvoice := TaxInvBuffer."Tax Invoice No.";
            until TaxInvBuffer.Next() = 0;

        LastTaxInvoice := '';
        TaxInvBuffer.Reset();
        TaxInvBuffer.SetRange(Type, TaxInvBuffer.Type::"Sales Invoice");
        if TaxInvBuffer.Find('-') then
            repeat
                if TaxInvBuffer."Tax Invoice No." <> LastTaxInvoice then begin
                    SalesTaxInvoiceHeader.Reset();
                    SalesTaxInvoiceHeader.SetRange("No.", TaxInvBuffer."Tax Invoice No.");
                    if SalesTaxInvoiceHeader.FindFirst() then begin
                        ReportSelection.Reset();
                        ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.TaxInvoice");
                        if ReportSelection.Find('-') then
                            repeat
                                if ScheduleInJobQueue then
                                    BatchPostingPrintMgt.SchedulePrintJobQueueEntry(SalesTaxInvoiceHeader, ReportSelection."Report ID", GLSetup."Report Output Type".AsInteger())
                                else
                                    REPORT.Run(ReportSelection."Report ID", SalesSetup."Print Dialog", false, SalesTaxInvoiceHeader);
                            until ReportSelection.Next() = 0;
                    end;
                end;
                LastTaxInvoice := TaxInvBuffer."Tax Invoice No.";
            until TaxInvBuffer.Next() = 0;

        LastTaxInvoice := '';
        TaxInvBuffer.Reset();
        TaxInvBuffer.SetRange(Type, TaxInvBuffer.Type::"Purchase Credit Memo");
        if TaxInvBuffer.Find('-') then
            repeat
                if TaxInvBuffer."Tax Invoice No." <> LastTaxInvoice then begin
                    PurchTaxCrMemoHeader.Reset();
                    PurchTaxCrMemoHeader.SetRange("No.", TaxInvBuffer."Tax Invoice No.");
                    if PurchTaxCrMemoHeader.FindFirst() then begin
                        ReportSelection.Reset();
                        ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.TaxCreditMemo");
                        if ReportSelection.Find('-') then
                            repeat
                                if ScheduleInJobQueue then
                                    BatchPostingPrintMgt.SchedulePrintJobQueueEntry(PurchTaxCrMemoHeader, ReportSelection."Report ID", GLSetup."Report Output Type".AsInteger())
                                else
                                    REPORT.Run(ReportSelection."Report ID", PurchSetup."Print Dialog", false, PurchTaxCrMemoHeader);
                            until ReportSelection.Next() = 0;
                    end;
                end;
                LastTaxInvoice := TaxInvBuffer."Tax Invoice No.";
            until TaxInvBuffer.Next() = 0;

        LastTaxInvoice := '';
        TaxInvBuffer.Reset();
        TaxInvBuffer.SetRange(Type, TaxInvBuffer.Type::"Sales Credit Memo");
        if TaxInvBuffer.Find('-') then
            repeat
                if TaxInvBuffer."Tax Invoice No." <> LastTaxInvoice then begin
                    SalesTaxCrMemoHeader.Reset();
                    SalesTaxCrMemoHeader.SetRange("No.", TaxInvBuffer."Tax Invoice No.");
                    if SalesTaxCrMemoHeader.FindFirst() then begin
                        ReportSelection.Reset();
                        ReportSelection.SetRange(Usage, ReportSelection.Usage::"S.TaxCreditMemo");
                        if ReportSelection.Find('-') then
                            repeat
                                if ScheduleInJobQueue then
                                    BatchPostingPrintMgt.SchedulePrintJobQueueEntry(SalesTaxCrMemoHeader, ReportSelection."Report ID", GLSetup."Report Output Type".AsInteger())
                                else
                                    REPORT.Run(ReportSelection."Report ID", SalesSetup."Print Dialog", false, SalesTaxCrMemoHeader);
                            until ReportSelection.Next() = 0;
                    end;
                end;
                LastTaxInvoice := TaxInvBuffer."Tax Invoice No.";
            until TaxInvBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckPmtDisc(PostingDate: Date; PmtDiscDate: Date; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal; Amount4: Decimal): Boolean
    begin
        if (PostingDate <= PmtDiscDate) and (Amount1 >= (Amount2 - Amount3)) and (Amount4 >= (Amount2 - Amount3)) then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CheckTaxableNoSeries("No.": Code[20]; "Vend/Cust": Option Vendor,Customer): Boolean
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        case "Vend/Cust" of
            "Vend/Cust"::Vendor:
                begin
                    Vendor.Reset();
                    Vendor.SetFilter("No.", "No.");
                    if Vendor.FindFirst() then
                        VendorPostingGroup.SetFilter(Code, Vendor."Vendor Posting Group");
                    if VendorPostingGroup.FindFirst() then
                        exit(VendorPostingGroup."Non-Taxable");
                end;
            "Vend/Cust"::Customer:
                begin
                    Customer.Reset();
                    Customer.SetFilter("No.", "No.");
                    if Customer.FindFirst() then
                        CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
                    if CustomerPostingGroup.FindFirst() then
                        exit(CustomerPostingGroup."Non-Taxable");
                end;
        end;
    end;

    local procedure ReverseGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        if SeriesDate = 0D then
            SeriesDate := WorkDate();

        NoSeriesLine.LockTable();
        NoSeries.Get(NoSeriesCode);
        if not NoSeriesCodeunit.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, SeriesDate, false) then begin
            NoSeriesLine.SetRange("Starting Date");
            if NoSeriesLine.Find('-') then
                Error(CannotAssignNewOnDateErr, NoSeriesCode, SeriesDate);
            Error(CannotAssignNewErr, NoSeriesCode);
        end;
        NoSeriesLine.TestField(Implementation, "No. Series Implementation"::Normal);

        if NoSeries."Date Order" and (SeriesDate < NoSeriesLine."Last Date Used") then
            Error(CannotAssignNewBeforeDateErr, NoSeries.Code, NoSeriesLine."Last Date Used");
        NoSeriesLine."Last Date Used" := SeriesDate;
        if NoSeriesLine."Last No. Used" = '' then begin
            NoSeriesLine.TestField("Starting No.");
            NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
        end else
            NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used", -NoSeriesLine."Increment-by No.");

        if (NoSeriesLine."Ending No." <> '') and (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.") then
            Error(CannotAssignGreaterErr, NoSeriesLine."Ending No.", NoSeriesCode);

        if (NoSeriesLine."Ending No." <> '') and (NoSeriesLine."Warning No." <> '') and (NoSeriesLine."Last No. Used" >= NoSeriesLine."Warning No.") and (NoSeriesCode <> WarningNoSeriesCode) then begin
            WarningNoSeriesCode := NoSeriesCode;
            Message(CannotAssignGreaterErr, NoSeriesLine."Ending No.", NoSeriesCode);
        end;
        NoSeriesLine.Validate(Open);

        NoSeriesLine.Modify();
        exit(NoSeriesLine."Last No. Used");
    end;
}

