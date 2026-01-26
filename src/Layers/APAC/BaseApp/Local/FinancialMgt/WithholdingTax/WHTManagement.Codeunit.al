// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

codeunit 28040 WHTManagement
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "G/L Register" = rimd;

    trigger OnRun()
    begin
    end;

    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCreditLine: Record "Purch. Cr. Memo Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCreditLine: Record "Sales Cr.Memo Line";
        WHTPostingSetup: Record "WHT Posting Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        TempVendLedgEntry: Record "Vendor Ledger Entry";
        TempVendLedgEntry1: Record "Vendor Ledger Entry";
        TempCustLedgEntry: Record "Cust. Ledger Entry";
        TempCustLedgEntry1: Record "Cust. Ledger Entry";
        WHTRevenueTypes: Record "WHT Revenue Types";
        SourceCodeSetup: Record "Source Code Setup";
        Vendor: Record Vendor;
        GLSetup: Record "General Ledger Setup";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        WHTBusPostGrp: Code[20];
        WHTProdPostGrp: Code[20];
        WHTRevenueType: Code[10];
        GenBusPostGrp: Code[20];
        GenProdPostGrp: Code[20];
        Dim1: Code[20];
        Dim2: Code[20];
        SourceCode: Code[10];
        ReasonCode: Code[10];
        ActualVendorNo: Code[20];
        AmountVAT: Decimal;
        Amount: Decimal;
        AbsorbBase: Decimal;
        CurrFactor: Decimal;
        AppliedAmount: Decimal;
        AppliedBase: Decimal;
        TempRemAmt: Decimal;
        TransType: Option Purchase,Sale,Settlement;
        DocType: Enum "Gen. Journal Document Type";
        PayToAccType: Option Vendor,Customer;
        BuyFromAccType: Option Vendor,Customer;
        DocDate: Date;
        CurrencyCode: Code[10];
        DocNo: Code[20];
        PayToVendCustNo: Code[20];
        BuyFromVendCustNo: Code[20];
        WHTReportLineNo: Code[10];
        ExtDocNo: Code[20];
        "Applies-toID": Code[20];
        PostingDate: Date;
        UnrealizedWHT: Boolean;
        NextWHTEntryNo: Integer;
        TType: Option Purchase,Sale;
        ApplyDocType: Enum "Gen. Journal Document Type";
        ApplyDocNo: Code[20];
        TotAmt: Decimal;
        NextEntry: Integer;
        TempRemBase: Decimal;
        Text1500000: Label 'Currency Code should be same for Payment and Invoice.';
        ExitLoop: Boolean;
        Text1500001: Label 'You cannot reprint the certificate from here. Go to reports and reprint.';
        Text1500003: Label 'The WHT posting groups are different and thus the entries cannot be apply.';
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempPurchInvLine: Record "Purch. Inv. Line";
        TempPurchCreditLine: Record "Purch. Cr. Memo Line";
        TotalInvoiceAmount: Decimal;
        TotalInvoiceAmountLCY: Decimal;
        WHTMinInvoiceAmt: Decimal;
        Text1500004: Label 'You cannot post a transaction using different WHT minimum invoice amounts on lines.';
        MissingRevenueTypeErr: Label 'The WHT Entry you are trying to process contains WHT Revenue Type `%1`. Please add this value to your WHT Revenue Types and post again.', Comment = '%1 = WHT Revenue Type';

    [Scope('OnPrem')]
    procedure ApplyVendInvoiceWHT(var VendLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line") EntryNo: Integer
    var
        Currency: Option Vendor,Customer;
        RemainingAmt: Decimal;
        PmtDiscount: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then
            if GenJnlLine."Bill-to/Pay-to No." = '' then begin
                if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then begin
                    Vendor.Get(GenJnlLine."Account No.");
                    if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                        exit;
                end;
            end else begin
                Vendor.Get(GenJnlLine."Bill-to/Pay-to No.");
                if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                    exit;
            end;

        ExitLoop := false;

        TempVendLedgEntry1.Reset();
        SetVendAppliesToFilter(TempVendLedgEntry1, GenJnlLine);
        TempVendLedgEntry1.SetFilter("Document Type", '<>%1', TempVendLedgEntry1."Document Type"::" ");
        if TempVendLedgEntry1.FindSet(true, false) then
            repeat
                TempVendLedgEntry1.CalcFields(
                  Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                  "Original Amount", "Original Amt. (LCY)");
                if TempVendLedgEntry1."Rem. Amt for WHT" = 0 then
                    TempVendLedgEntry1."Rem. Amt for WHT" := TempVendLedgEntry1."Remaining Amount";
                RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
            until TempVendLedgEntry1.Next() = 0;
        TotAmt := Abs(GenJnlLine.Amount);

        TempVendLedgEntry.Reset();
        SetVendAppliesToFilter(TempVendLedgEntry, GenJnlLine);
        TempVendLedgEntry.SetRange("Document Type", TempVendLedgEntry."Document Type"::"Credit Memo");
        if TempVendLedgEntry.FindSet() then
            repeat
                TempVendLedgEntry.CalcFields(
                  Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                  "Original Amount", "Original Amt. (LCY)");

                PmtDiscount := 0;
                if CheckPmtDisc(
                     GenJnlLine."Posting Date", TempVendLedgEntry."Pmt. Discount Date",
                     Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                     Abs(TempVendLedgEntry."Rem. Amt"),
                     Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                     Abs(TotAmt))
                then
                    PmtDiscount := TempVendLedgEntry."Original Pmt. Disc. Possible";

                GenJnlLine.Validate(Amount, -Abs(TempVendLedgEntry."Rem. Amt for WHT" - PmtDiscount));
                RemainingAmt -= TempVendLedgEntry."Rem. Amt for WHT";
                TotAmt += (TempVendLedgEntry."Rem. Amt for WHT" - PmtDiscount);

                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                NextEntry :=
                  ProcessPayment(
                    GenJnlLine, VendLedgerEntry."Transaction No.", VendLedgerEntry."Entry No.", Currency::Vendor, false);

                if ExitLoop then
                    exit(NextEntry);
            until TempVendLedgEntry.Next() = 0;

        ExitLoop := false;
        TempVendLedgEntry.Reset();
        SetVendAppliesToFilter(TempVendLedgEntry, GenJnlLine);
        TempVendLedgEntry.SetFilter("Document Type", '<>%1&<>%2',
          TempVendLedgEntry."Document Type"::"Credit Memo", TempVendLedgEntry."Document Type"::" ");
        if TempVendLedgEntry.FindSet() then
            repeat
                TempVendLedgEntry.CalcFields(
                  Amount,
                  "Amount (LCY)",
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  "Original Amount",
                  "Original Amt. (LCY)");
                if TempVendLedgEntry."Remaining Amount" = 0 then
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempVendLedgEntry."Pmt. Discount Date",
                         Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                         Abs(TempVendLedgEntry."Rem. Amt"),
                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                if (Abs(RemainingAmt) < Abs(TotAmt)) or
                   (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                then begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempVendLedgEntry."Pmt. Discount Date",
                         Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                         Abs(TempVendLedgEntry."Rem. Amt"),
                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then begin
                        if (Abs(TotAmt) < Abs(TempVendLedgEntry."Rem. Amt for WHT")) or (TempVendLedgEntry."Rem. Amt for WHT" = 0) then
                            GenJnlLine.Validate(Amount, TotAmt)
                        else
                            GenJnlLine.Validate(
                              Amount,
                              Abs(TempVendLedgEntry."Rem. Amt for WHT" - TempVendLedgEntry."Original Pmt. Disc. Possible"));

                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                        RemainingAmt :=
                          RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT" + TempVendLedgEntry."Original Pmt. Disc. Possible";
                    end else begin
                        GenJnlLine.Validate(Amount, Abs(TempVendLedgEntry."Rem. Amt for WHT"));
                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                        RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                    end;
                end else begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempVendLedgEntry."Pmt. Discount Date",
                         Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                         Abs(TempVendLedgEntry."Rem. Amt"),
                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        GenJnlLine.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                    else
                        GenJnlLine.Validate(Amount, TotAmt);
                    ExitLoop := true;
                end;

                if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                    GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;

                GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                NextEntry :=
                  ProcessPayment(
                    GenJnlLine, VendLedgerEntry."Transaction No.", VendLedgerEntry."Entry No.", Currency::Vendor, false);

                if ExitLoop then
                    exit(NextEntry);
            until TempVendLedgEntry.Next() = 0;
        exit(NextEntry);
    end;

    local procedure SetVendAppliesToFilter(var VendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Applies-to ID" <> '' then
            VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
        else begin
            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplyCustInvoiceWHT(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line") EntryNo: Integer
    var
        Currency: Option Vendor,Customer;
        RemainingAmt: Decimal;
    begin
        TotAmt := Abs(GenJnlLine.Amount);
        TempCustLedgEntry1.Reset();
        SetCustAppliesToFilter(TempCustLedgEntry1, GenJnlLine);
        if TempCustLedgEntry1.FindSet(true, false) then
            repeat
                TempCustLedgEntry1.CalcFields(
                  Amount,
                  "Amount (LCY)",
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  "Original Amount",
                  "Original Amt. (LCY)");
                if TempCustLedgEntry1."Rem. Amt for WHT" = 0 then
                    TempCustLedgEntry1."Rem. Amt for WHT" := TempCustLedgEntry1."Remaining Amount";
                RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";
                if TempCustLedgEntry1."Document Type" = TempCustLedgEntry1."Document Type"::"Credit Memo" then
                    RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";
            until TempCustLedgEntry1.Next() = 0;

        TempCustLedgEntry.Reset();
        SetCustAppliesToFilter(TempCustLedgEntry, GenJnlLine);
        TempCustLedgEntry.SetRange("Document Type", TempCustLedgEntry."Document Type"::"Credit Memo");
        if TempCustLedgEntry.FindSet() then
            repeat
                TempCustLedgEntry.CalcFields(
                  Amount,
                  "Amount (LCY)",
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  "Original Amount",
                  "Original Amt. (LCY)");
                if CheckPmtDisc(
                     GenJnlLine."Posting Date",
                     TempCustLedgEntry."Pmt. Discount Date",
                     Abs(TempCustLedgEntry."Rem. Amt for WHT"),
                     Abs(TempCustLedgEntry."Rem. Amt"),
                     Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                     Abs(TotAmt))
                then
                    TotAmt := TotAmt + Abs(TempCustLedgEntry."Original Pmt. Disc. Possible");
                if (Abs(RemainingAmt) <= Abs(TotAmt)) or
                   (Abs(TempCustLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                then begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Rem. Amt for WHT"),
                         Abs(TempCustLedgEntry."Rem. Amt"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then begin
                        GenJnlLine.Validate(
                          Amount,
                          Abs(TempCustLedgEntry."Rem. Amt for WHT" - TempCustLedgEntry."Original Pmt. Disc. Possible"));
                        if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                            TotAmt := -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT");
                        RemainingAmt :=
                          RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT" + TempCustLedgEntry."Original Pmt. Disc. Possible";
                    end else begin
                        GenJnlLine.Validate(Amount, Abs(TempCustLedgEntry."Rem. Amt for WHT"));
                        if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                            TotAmt := -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT");
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                    end;
                end else begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Rem. Amt for WHT"),
                         Abs(TempCustLedgEntry."Rem. Amt"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        GenJnlLine.Validate(Amount, Abs(TotAmt - Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                    else
                        GenJnlLine.Validate(Amount, Abs(TotAmt));
                    ExitLoop := true;
                end;
                if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                    GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                else
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        TotAmt := TotAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        ExitLoop := false;
                    end;
                GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                NextEntry :=
                  ProcessPayment(
                    GenJnlLine, CustLedgerEntry."Transaction No.", CustLedgerEntry."Entry No.", Currency::Customer, false);
                if ExitLoop then
                    exit(NextEntry);
            until TempCustLedgEntry.Next() = 0;

        ExitLoop := false;
        TempCustLedgEntry.Reset();
        SetCustAppliesToFilter(TempCustLedgEntry, GenJnlLine);
        TempCustLedgEntry.SetFilter("Document Type", '<>%1', TempCustLedgEntry."Document Type"::"Credit Memo");
        if TempCustLedgEntry.FindSet() then
            repeat
                TempCustLedgEntry.CalcFields(
                  Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amount", "Original Amt. (LCY)");
                if CheckPmtDisc(
                     GenJnlLine."Posting Date",
                     TempCustLedgEntry."Pmt. Discount Date",
                     Abs(TempCustLedgEntry."Rem. Amt for WHT"),
                     Abs(TempCustLedgEntry."Rem. Amt"),
                     Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                     Abs(TotAmt))
                then
                    TotAmt := TotAmt + Abs(TempCustLedgEntry."Original Pmt. Disc. Possible");
                if (Abs(RemainingAmt) <= Abs(TotAmt)) or
                   (Abs(TempCustLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                then begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Rem. Amt for WHT"),
                         Abs(TempCustLedgEntry."Rem. Amt"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then begin
                        RemainingAmt :=
                          RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT" + TempCustLedgEntry."Original Pmt. Disc. Possible";
                        GenJnlLine.Validate(
                          Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT" - TempCustLedgEntry."Original Pmt. Disc. Possible"));
                        if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                            TotAmt := (TotAmt - TempCustLedgEntry."Rem. Amt for WHT")
                    end else begin
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        GenJnlLine.Validate(Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT"));
                        if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                            TotAmt := (TotAmt - TempCustLedgEntry."Rem. Amt for WHT");
                    end;
                end else begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Rem. Amt for WHT"),
                         Abs(TempCustLedgEntry."Rem. Amt"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        GenJnlLine.Validate(Amount, -Abs(TotAmt - TempCustLedgEntry."Original Pmt. Disc. Possible"))
                    else
                        GenJnlLine.Validate(Amount, -Abs(TotAmt));
                    ExitLoop := true;
                end;
                if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                    GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                else
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        TotAmt := TotAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        ExitLoop := false;
                    end;
                GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                NextEntry :=
                  ProcessPayment(
                    GenJnlLine, CustLedgerEntry."Transaction No.", CustLedgerEntry."Entry No.", Currency::Customer, false);
                if ExitLoop then
                    exit(NextEntry);
            until TempCustLedgEntry.Next() = 0;
        exit(NextEntry);
    end;

    local procedure SetCustAppliesToFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Applies-to ID" <> '' then
            CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
        else begin
            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplyManualCustInvoiceWHT(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line") NextEntry: Integer
    var
        WHTEntry: Record "WHT Entry";
        Currency: Option Vendor,Customer;
    begin
        TempCustLedgEntry.Reset();
        TotAmt := Abs(GenJnlLine.Amount);
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            TempCustLedgEntry.SetRange("Document Type", TempCustLedgEntry."Document Type"::"Credit Memo");
            if TempCustLedgEntry.FindSet() then
                repeat
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", TempCustLedgEntry."Document No.");
                    WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                    if WHTEntry.FindSet() then
                        repeat
                            GenJnlLine.Validate(Amount, WHTEntry."Remaining Unrealized Amount");
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                            GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                            TotAmt := TotAmt - WHTEntry."Remaining Unrealized Amount";
                        until WHTEntry.Next() = 0;
                    CustLedgerEntry."Applies-to ID" := '';
                    CustLedgerEntry.Modify();
                until TempCustLedgEntry.Next() = 0;

            TempCustLedgEntry.Reset();
            TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            TempCustLedgEntry.SetFilter("Document Type", '<>%1', TempCustLedgEntry."Document Type"::"Credit Memo");
            if TempCustLedgEntry.FindSet() then
                repeat
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", TempCustLedgEntry."Document No.");
                    WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);
                    if WHTEntry.FindSet() then
                        repeat
                            if TotAmt > Abs(WHTEntry."Remaining Unrealized Amount") then begin
                                GenJnlLine.Validate(Amount, WHTEntry."Remaining Unrealized Amount");
                                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
                                GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                                TotAmt := TotAmt - Abs(WHTEntry."Remaining Unrealized Amount");
                                ExitLoop := false;
                            end else begin
                                GenJnlLine.Validate(Amount, -TotAmt);
                                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
                                GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                                ExitLoop := true;
                            end;
                        until WHTEntry.Next() = 0;
                    NextEntry :=
                      ProcessManualReceipt(
                        GenJnlLine, CustLedgerEntry."Transaction No.", CustLedgerEntry."Entry No.", Currency::Customer);
                    CustLedgerEntry."Applies-to ID" := '';
                    CustLedgerEntry.Modify();
                    if ExitLoop then
                        exit(NextEntry);
                until TempCustLedgEntry.Next() = 0;
        end else
            NextEntry :=
              ProcessManualReceipt(
                GenJnlLine, CustLedgerEntry."Transaction No.", CustLedgerEntry."Entry No.", Currency::Customer);
    end;

    [Scope('OnPrem')]
    procedure InsertVendInvoiceWHT(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        TempPurchLine: Record "Purchase Line";
        PrepaymentAmtDeducted: Decimal;
    begin
        PurchInvLine.Reset();
        PurchInvLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetFilter(Quantity, '<>0');
        if PurchInvLine.FindSet() then begin
            WHTBusPostGrp := PurchInvLine."WHT Business Posting Group";
            WHTProdPostGrp := PurchInvLine."WHT Product Posting Group";
            if WHTPostingSetup.Get(PurchInvLine."WHT Business Posting Group", PurchInvLine."WHT Product Posting Group") then
                WHTMinInvoiceAmt := WHTPostingSetup."WHT Minimum Invoice Amount";
            repeat
                if WHTPostingSetup.Get(PurchInvLine."WHT Business Posting Group", PurchInvLine."WHT Product Posting Group") then begin
                    if (WHTBusPostGrp <> PurchInvLine."WHT Business Posting Group") or
                       (WHTProdPostGrp <> PurchInvLine."WHT Product Posting Group")
                    then
                        if WHTMinInvoiceAmt <> WHTPostingSetup."WHT Minimum Invoice Amount" then
                            Error(Text1500004);
                    WHTBusPostGrp := PurchInvLine."WHT Business Posting Group";
                    WHTProdPostGrp := PurchInvLine."WHT Product Posting Group";
                end;
            until PurchInvLine.Next() = 0;
        end;

        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then begin
            Vendor.Get(PurchInvHeader."Pay-to Vendor No.");
            if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                exit;
            TotalInvoiceAmount := 0;
            TotalInvoiceAmountLCY := 0;
            TempPurchInvLine.Reset();
            TempPurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
            TempPurchInvLine.SetFilter(Quantity, '<>0');
            TempPurchInvLine.SetRange("Prepayment Line", false);
            if TempPurchInvLine.FindSet() then
                repeat
                    if WHTPostingSetup.Get(
                         TempPurchInvLine."WHT Business Posting Group",
                         TempPurchInvLine."WHT Product Posting Group")
                    then
                        if TempPurchInvLine."WHT Absorb Base" <> 0 then
                            TotalInvoiceAmount := TotalInvoiceAmount + TempPurchInvLine."WHT Absorb Base"
                        else
                            TotalInvoiceAmount := TotalInvoiceAmount + TempPurchInvLine.Amount
                until TempPurchInvLine.Next() = 0;

            if PurchInvHeader."Currency Code" = '' then
                TotalInvoiceAmountLCY := TotalInvoiceAmount
            else
                TotalInvoiceAmountLCY :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchInvHeader."Document Date",
                      PurchInvHeader."Currency Code",
                      TotalInvoiceAmount,
                      PurchInvHeader."Currency Factor"));

            if CheckWHTCalculationRule(TotalInvoiceAmountLCY, WHTPostingSetup) then
                exit;
        end;

        PurchInvLine.Reset();
        PurchInvLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetFilter(Quantity, '<>0');
        PurchInvLine.SetRange("Prepayment Line", false);
        if PurchInvLine.FindSet() then
            repeat
                if WHTPostingSetup.Get(PurchInvLine."WHT Business Posting Group", PurchInvLine."WHT Product Posting Group") then
                    if WHTPostingSetup."WHT %" > 0 then begin
                        DocNo := PurchInvLine."Document No.";
                        DocType := DocType::Invoice;
                        PayToAccType := PayToAccType::Vendor;
                        PayToVendCustNo := PurchInvHeader."Pay-to Vendor No.";
                        BuyFromAccType := BuyFromAccType::Vendor;
                        GenBusPostGrp := PurchInvLine."Gen. Bus. Posting Group";
                        GenProdPostGrp := PurchInvLine."Gen. Prod. Posting Group";
                        TransType := TransType::Purchase;
                        BuyFromVendCustNo := PurchInvHeader."Actual Vendor No.";
                        PostingDate := PurchInvHeader."Posting Date";
                        DocDate := PurchInvHeader."Document Date";
                        CurrencyCode := PurchInvHeader."Currency Code";
                        CurrFactor := PurchInvHeader."Currency Factor";
                        ApplyDocType := PurchInvHeader."Applies-to Doc. Type";
                        ApplyDocNo := PurchInvHeader."Applies-to Doc. No.";
                        SourceCode := PurchInvHeader."Source Code";
                        ReasonCode := PurchInvHeader."Reason Code";

                        if (WHTBusPostGrp <> PurchInvLine."WHT Business Posting Group") or
                           (WHTProdPostGrp <> PurchInvLine."WHT Product Posting Group")
                        then begin
                            if AmountVAT <> 0 then begin
                                if WHTPostingSetup."Realized WHT Type" in
                                   [WHTPostingSetup."Realized WHT Type"::Earliest,
                                    WHTPostingSetup."Realized WHT Type"::Invoice]
                                then begin
                                    TempPurchLine.Reset();
                                    TempPurchLine.SetCurrentKey("Document Type", "Document No.",
                                      "WHT Business Posting Group", "WHT Product Posting Group");
                                    TempPurchLine.SetRange("Document Type", TempPurchLine."Document Type"::Order);
                                    TempPurchLine.SetRange("Document No.", PurchInvHeader."Order No.");
                                    TempPurchLine.SetRange("WHT Business Posting Group", WHTBusPostGrp);
                                    TempPurchLine.SetRange("WHT Product Posting Group", WHTProdPostGrp);
                                    TempPurchLine.CalcSums(TempPurchLine."Prepmt. Amt. Inv.", TempPurchLine."Prepmt Amt to Deduct");
                                    PrepaymentAmtDeducted := TempPurchLine."Prepmt Amt to Deduct";
                                    AmountVAT := AmountVAT - PrepaymentAmtDeducted;
                                end;
                                InsertWHT(TType::Purchase);
                            end;
                            WHTBusPostGrp := PurchInvLine."WHT Business Posting Group";
                            WHTProdPostGrp := PurchInvLine."WHT Product Posting Group";
                            PurchInvHeader.Amount := 0;
                            AbsorbBase := 0;
                            AmountVAT := 0;
                            PurchInvHeader.Amount := PurchInvHeader.Amount + PurchInvLine.Amount;
                            AbsorbBase := AbsorbBase + PurchInvLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := AbsorbBase
                            else
                                AmountVAT := PurchInvHeader.Amount;
                        end else begin
                            WHTBusPostGrp := PurchInvLine."WHT Business Posting Group";
                            WHTProdPostGrp := PurchInvLine."WHT Product Posting Group";
                            PurchInvHeader.Amount := PurchInvHeader.Amount + PurchInvLine.Amount;
                            AbsorbBase := AbsorbBase + PurchInvLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := AbsorbBase
                            else
                                AmountVAT := PurchInvHeader.Amount;
                        end;
                        WHTBusPostGrp := PurchInvLine."WHT Business Posting Group";
                        WHTProdPostGrp := PurchInvLine."WHT Product Posting Group";
                    end;
            until PurchInvLine.Next() = 0;

        if WHTPostingSetup."Realized WHT Type" = WHTPostingSetup."Realized WHT Type"::Earliest then begin
            TempPurchLine.Reset();
            TempPurchLine.SetCurrentKey("Document Type", "Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
            TempPurchLine.SetRange("Document Type", TempPurchLine."Document Type"::Order);
            TempPurchLine.SetRange("Document No.", PurchInvHeader."Order No.");
            TempPurchLine.SetRange("WHT Business Posting Group", WHTBusPostGrp);
            TempPurchLine.SetRange("WHT Product Posting Group", WHTProdPostGrp);
            TempPurchLine.CalcSums(TempPurchLine."Prepmt. Amt. Inv.", TempPurchLine."Prepmt Amt to Deduct");
            PrepaymentAmtDeducted := TempPurchLine."Prepmt Amt to Deduct";
            if AmountVAT <> 0 then
                AmountVAT := AmountVAT - PrepaymentAmtDeducted;
        end;
        InsertWHT(TType::Purchase);
    end;

    [Scope('OnPrem')]
    procedure InsertVendCreditWHT(var PurchCreditHeader: Record "Purch. Cr. Memo Hdr."; AppliesID: Code[20])
    var
        WHTEntry: Record "WHT Entry";
    begin
        PurchCreditLine.Reset();
        PurchCreditLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        PurchCreditLine.SetRange("Document No.", PurchCreditHeader."No.");
        PurchCreditLine.SetFilter(Quantity, '<>0');
        if PurchCreditLine.FindSet() then begin
            WHTBusPostGrp := PurchCreditLine."WHT Business Posting Group";
            WHTProdPostGrp := PurchCreditLine."WHT Product Posting Group";
            if WHTPostingSetup.Get(PurchCreditLine."WHT Business Posting Group", PurchCreditLine."WHT Product Posting Group") then
                WHTMinInvoiceAmt := WHTPostingSetup."WHT Minimum Invoice Amount";
            repeat
                if WHTPostingSetup.Get(PurchCreditLine."WHT Business Posting Group", PurchCreditLine."WHT Product Posting Group") then begin
                    if (WHTBusPostGrp <> PurchCreditLine."WHT Business Posting Group") or
                       (WHTProdPostGrp <> PurchCreditLine."WHT Product Posting Group")
                    then
                        if WHTMinInvoiceAmt <> WHTPostingSetup."WHT Minimum Invoice Amount" then
                            Error(Text1500004);
                    WHTBusPostGrp := PurchCreditLine."WHT Business Posting Group";
                    WHTProdPostGrp := PurchCreditLine."WHT Product Posting Group";
                end;
            until PurchCreditLine.Next() = 0;
        end;

        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then begin
            Vendor.Get(PurchCreditHeader."Pay-to Vendor No.");
            if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                exit;
            TotalInvoiceAmount := 0;
            TotalInvoiceAmountLCY := 0;
            TempPurchCreditLine.Reset();
            TempPurchCreditLine.SetRange("Document No.", PurchCreditHeader."No.");
            TempPurchCreditLine.SetFilter(Quantity, '<>0');
            if TempPurchCreditLine.FindSet() then
                repeat
                    if WHTPostingSetup.Get(
                         TempPurchCreditLine."WHT Business Posting Group",
                         TempPurchCreditLine."WHT Product Posting Group")
                    then
                        if TempPurchCreditLine."WHT Absorb Base" <> 0 then
                            TotalInvoiceAmount := TotalInvoiceAmount + TempPurchCreditLine."WHT Absorb Base"
                        else
                            TotalInvoiceAmount := TotalInvoiceAmount + TempPurchCreditLine.Amount;
                until TempPurchCreditLine.Next() = 0;

            if PurchCreditHeader."Currency Code" = '' then
                TotalInvoiceAmountLCY := TotalInvoiceAmount
            else
                TotalInvoiceAmountLCY :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PurchCreditHeader."Document Date",
                      PurchCreditHeader."Currency Code",
                      TotalInvoiceAmount,
                      PurchCreditHeader."Currency Factor"));

            TempVendLedgEntry.Reset();
            if ((PurchCreditHeader."Applies-to Doc. Type" = PurchCreditHeader."Applies-to Doc. Type"::Invoice) and
                (PurchCreditHeader."Applies-to Doc. No." <> ''))
            then
                TempVendLedgEntry.SetRange("Document No.", PurchCreditHeader."Applies-to Doc. No.")
            else
                if AppliesID <> '' then
                    TempVendLedgEntry.SetRange("Applies-to ID", AppliesID);

            if TempVendLedgEntry.GetFilters <> '' then begin
                if TempVendLedgEntry.FindSet() then begin
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                    WHTEntry.SetRange("Document No.", TempVendLedgEntry."Document No.");
                    if not WHTEntry.FindFirst() then
                        if CheckWHTCalculationRule(TotalInvoiceAmountLCY, WHTPostingSetup) then
                            exit;
                end;
            end else
                if CheckWHTCalculationRule(TotalInvoiceAmountLCY, WHTPostingSetup) then
                    exit;
        end;

        PurchCreditLine.Reset();
        PurchCreditLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        PurchCreditLine.SetRange("Document No.", PurchCreditHeader."No.");
        PurchCreditLine.SetFilter(Quantity, '<>0');
        if PurchCreditLine.FindSet() then
            repeat
                if WHTPostingSetup.Get(PurchCreditLine."WHT Business Posting Group", PurchCreditLine."WHT Product Posting Group") then
                    if WHTPostingSetup."WHT %" > 0 then begin
                        DocNo := PurchCreditLine."Document No.";
                        DocType := DocType::"Credit Memo";
                        PayToAccType := PayToAccType::Vendor;
                        PayToVendCustNo := PurchCreditHeader."Pay-to Vendor No.";
                        BuyFromAccType := BuyFromAccType::Vendor;
                        GenBusPostGrp := PurchCreditLine."Gen. Bus. Posting Group";
                        GenProdPostGrp := PurchCreditLine."Gen. Prod. Posting Group";
                        TransType := TransType::Purchase;
                        BuyFromVendCustNo := PurchCreditHeader."Actual Vendor No.";
                        PostingDate := PurchCreditHeader."Posting Date";
                        DocDate := PurchCreditHeader."Document Date";
                        CurrencyCode := PurchCreditHeader."Currency Code";
                        CurrFactor := PurchCreditHeader."Currency Factor";
                        ApplyDocType := PurchCreditHeader."Applies-to Doc. Type";
                        ApplyDocNo := PurchCreditHeader."Applies-to Doc. No.";
                        "Applies-toID" := AppliesID;
                        SourceCode := PurchCreditHeader."Source Code";
                        ReasonCode := PurchCreditHeader."Reason Code";
                        if (WHTBusPostGrp <> PurchCreditLine."WHT Business Posting Group") or
                           (WHTProdPostGrp <> PurchCreditLine."WHT Product Posting Group")
                        then begin
                            if AmountVAT <> 0 then
                                InsertWHT(TType::Purchase);
                            WHTBusPostGrp := PurchCreditLine."WHT Business Posting Group";
                            WHTProdPostGrp := PurchCreditLine."WHT Product Posting Group";
                            PurchCreditHeader.Amount := 0;
                            AbsorbBase := 0;
                            AmountVAT := 0;
                            PurchCreditHeader.Amount := PurchCreditHeader.Amount + PurchCreditLine.Amount;
                            AbsorbBase := AbsorbBase + PurchCreditLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := -AbsorbBase
                            else
                                AmountVAT := -PurchCreditHeader.Amount;
                        end else begin
                            WHTBusPostGrp := PurchCreditLine."WHT Business Posting Group";
                            WHTProdPostGrp := PurchCreditLine."WHT Product Posting Group";
                            PurchCreditHeader.Amount := PurchCreditHeader.Amount + PurchCreditLine.Amount;
                            AbsorbBase := AbsorbBase + PurchCreditLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := -AbsorbBase
                            else
                                AmountVAT := -PurchCreditHeader.Amount;
                        end;
                        WHTBusPostGrp := PurchCreditLine."WHT Business Posting Group";
                        WHTProdPostGrp := PurchCreditLine."WHT Product Posting Group";
                    end;
            until PurchCreditLine.Next() = 0;
        InsertWHT(TType::Purchase);
    end;

    [Scope('OnPrem')]
    procedure InsertCustInvoiceWHT(var SalesInvHeader: Record "Sales Invoice Header")
    begin
        SalesInvLine.Reset();
        SalesInvLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Quantity, '<>0');
        if SalesInvLine.FindSet() then begin
            WHTBusPostGrp := SalesInvLine."WHT Business Posting Group";
            WHTProdPostGrp := SalesInvLine."WHT Product Posting Group";
            if WHTPostingSetup.Get(SalesInvLine."WHT Business Posting Group", SalesInvLine."WHT Product Posting Group") then
                WHTMinInvoiceAmt := WHTPostingSetup."WHT Minimum Invoice Amount";
            repeat
                if WHTPostingSetup.Get(SalesInvLine."WHT Business Posting Group", SalesInvLine."WHT Product Posting Group") then begin
                    if (WHTBusPostGrp <> SalesInvLine."WHT Business Posting Group") or
                       (WHTProdPostGrp <> SalesInvLine."WHT Product Posting Group")
                    then
                        if WHTMinInvoiceAmt <> WHTPostingSetup."WHT Minimum Invoice Amount" then
                            Error(Text1500004);
                    WHTBusPostGrp := SalesInvLine."WHT Business Posting Group";
                    WHTProdPostGrp := SalesInvLine."WHT Product Posting Group";
                end;
            until SalesInvLine.Next() = 0;
        end;

        SalesInvLine.Reset();
        SalesInvLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Quantity, '<>0');
        SalesInvLine.SetRange("Prepayment Line", false);
        if SalesInvLine.FindSet() then
            repeat
                if WHTPostingSetup.Get(SalesInvLine."WHT Business Posting Group", SalesInvLine."WHT Product Posting Group") then
                    if WHTPostingSetup."WHT %" > 0 then begin
                        DocNo := SalesInvLine."Document No.";
                        DocType := DocType::Invoice;
                        PayToAccType := PayToAccType::Customer;
                        PayToVendCustNo := SalesInvHeader."Bill-to Customer No.";
                        BuyFromAccType := BuyFromAccType::Customer;
                        BuyFromVendCustNo := SalesInvHeader."Sell-to Customer No.";
                        SourceCode := SalesInvHeader."Source Code";
                        ReasonCode := SalesInvHeader."Reason Code";
                        GenBusPostGrp := SalesInvLine."Gen. Bus. Posting Group";
                        GenProdPostGrp := SalesInvLine."Gen. Prod. Posting Group";
                        TransType := TransType::Sale;
                        PostingDate := SalesInvHeader."Posting Date";
                        DocDate := SalesInvHeader."Document Date";
                        CurrencyCode := SalesInvHeader."Currency Code";
                        CurrFactor := SalesInvHeader."Currency Factor";
                        ApplyDocType := SalesInvHeader."Applies-to Doc. Type";
                        ApplyDocNo := SalesInvHeader."Applies-to Doc. No.";
                        if (WHTBusPostGrp <> SalesInvLine."WHT Business Posting Group") or
                           (WHTProdPostGrp <> SalesInvLine."WHT Product Posting Group")
                        then begin
                            if AmountVAT <> 0 then
                                InsertWHT(TType::Sale);
                            WHTBusPostGrp := SalesInvLine."WHT Business Posting Group";
                            WHTProdPostGrp := SalesInvLine."WHT Product Posting Group";
                            SalesInvHeader.Amount := 0;
                            AbsorbBase := 0;
                            AmountVAT := 0;
                            SalesInvHeader.Amount := SalesInvHeader.Amount - SalesInvLine.Amount;
                            AbsorbBase := AbsorbBase - SalesInvLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := AbsorbBase
                            else
                                AmountVAT := SalesInvHeader.Amount;
                        end else begin
                            WHTBusPostGrp := SalesInvLine."WHT Business Posting Group";
                            WHTProdPostGrp := SalesInvLine."WHT Product Posting Group";
                            SalesInvHeader.Amount := SalesInvHeader.Amount - SalesInvLine.Amount;
                            AbsorbBase := AbsorbBase - SalesInvLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := AbsorbBase
                            else
                                AmountVAT := SalesInvHeader.Amount;
                        end;
                        WHTBusPostGrp := SalesInvLine."WHT Business Posting Group";
                        WHTProdPostGrp := SalesInvLine."WHT Product Posting Group";
                    end;
            until SalesInvLine.Next() = 0;
        InsertWHT(TType::Sale);
    end;

    [Scope('OnPrem')]
    procedure InsertCustCreditWHT(var SalesCreditHeader: Record "Sales Cr.Memo Header"; AppliesID: Code[20])
    begin
        SalesCreditLine.Reset();
        SalesCreditLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        SalesCreditLine.SetRange("Document No.", SalesCreditHeader."No.");
        SalesCreditLine.SetFilter(Quantity, '<>0');
        if SalesCreditLine.FindSet() then begin
            WHTBusPostGrp := SalesCreditLine."WHT Business Posting Group";
            WHTProdPostGrp := SalesCreditLine."WHT Product Posting Group";
            if WHTPostingSetup.Get(SalesCreditLine."WHT Business Posting Group", SalesCreditLine."WHT Product Posting Group") then
                WHTMinInvoiceAmt := WHTPostingSetup."WHT Minimum Invoice Amount";
            repeat
                if WHTPostingSetup.Get(SalesCreditLine."WHT Business Posting Group", SalesCreditLine."WHT Product Posting Group") then begin
                    if (WHTBusPostGrp <> SalesCreditLine."WHT Business Posting Group") or
                       (WHTProdPostGrp <> SalesCreditLine."WHT Product Posting Group")
                    then
                        if WHTMinInvoiceAmt <> WHTPostingSetup."WHT Minimum Invoice Amount" then
                            Error(Text1500004);
                    WHTBusPostGrp := SalesCreditLine."WHT Business Posting Group";
                    WHTProdPostGrp := SalesCreditLine."WHT Product Posting Group";
                end;
            until SalesCreditLine.Next() = 0;
        end;

        SalesCreditLine.Reset();
        SalesCreditLine.SetCurrentKey("Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        SalesCreditLine.SetRange("Document No.", SalesCreditHeader."No.");
        SalesCreditLine.SetFilter(Quantity, '<>0');
        if SalesCreditLine.FindSet() then
            repeat
                if WHTPostingSetup.Get(SalesCreditLine."WHT Business Posting Group", SalesCreditLine."WHT Product Posting Group") then
                    if WHTPostingSetup."WHT %" > 0 then begin
                        DocNo := SalesCreditLine."Document No.";
                        DocType := DocType::"Credit Memo";
                        PayToAccType := PayToAccType::Customer;
                        PayToVendCustNo := SalesCreditHeader."Bill-to Customer No.";
                        BuyFromAccType := BuyFromAccType::Customer;
                        BuyFromVendCustNo := SalesCreditHeader."Sell-to Customer No.";
                        SourceCode := SalesCreditHeader."Source Code";
                        ReasonCode := SalesCreditHeader."Reason Code";
                        GenBusPostGrp := SalesCreditLine."Gen. Bus. Posting Group";
                        GenProdPostGrp := SalesCreditLine."Gen. Prod. Posting Group";
                        TransType := TransType::Sale;
                        PostingDate := SalesCreditHeader."Posting Date";
                        DocDate := SalesCreditHeader."Document Date";
                        CurrencyCode := SalesCreditHeader."Currency Code";
                        CurrFactor := SalesCreditHeader."Currency Factor";
                        ApplyDocType := SalesCreditHeader."Applies-to Doc. Type";
                        ApplyDocNo := SalesCreditHeader."Applies-to Doc. No.";
                        "Applies-toID" := AppliesID;
                        if (WHTBusPostGrp <> SalesCreditLine."WHT Business Posting Group") or
                           (WHTProdPostGrp <> SalesCreditLine."WHT Product Posting Group")
                        then begin
                            if AmountVAT <> 0 then
                                InsertWHT(TType::Sale);
                            WHTBusPostGrp := SalesCreditLine."WHT Business Posting Group";
                            WHTProdPostGrp := SalesCreditLine."WHT Product Posting Group";
                            SalesCreditHeader.Amount := 0;
                            AbsorbBase := 0;
                            AmountVAT := 0;
                            SalesCreditHeader.Amount := SalesCreditHeader.Amount - SalesCreditLine.Amount;
                            AbsorbBase := AbsorbBase - SalesCreditLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := -AbsorbBase
                            else
                                AmountVAT := -SalesCreditHeader.Amount;
                        end else begin
                            WHTBusPostGrp := SalesCreditLine."WHT Business Posting Group";
                            WHTProdPostGrp := SalesCreditLine."WHT Product Posting Group";
                            SalesCreditHeader.Amount := SalesCreditHeader.Amount - SalesCreditLine.Amount;
                            AbsorbBase := AbsorbBase - SalesCreditLine."WHT Absorb Base";
                            if AbsorbBase <> 0 then
                                AmountVAT := -AbsorbBase
                            else
                                AmountVAT := -SalesCreditHeader.Amount;
                        end;
                        WHTBusPostGrp := SalesCreditLine."WHT Business Posting Group";
                        WHTProdPostGrp := SalesCreditLine."WHT Product Posting Group";
                    end;
            until SalesCreditLine.Next() = 0;
        InsertWHT(TType::Sale);
    end;

    [Scope('OnPrem')]
    procedure ProcessPayment(var GenJnlLine: Record "Gen. Journal Line"; TransactionNo: Integer; EntryNo: Integer; Source: Option Vendor,Customer; AmountWithDisc: Boolean) PaymentNo: Integer
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry2: Record "WHT Entry";
        WHTEntry3: Record "WHT Entry";
        GLSetup: Record "General Ledger Setup";
        WHTEntryTemp: Record "WHT Entry";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempWHT: Record "Temp WHT Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgEntry1: Record "Cust. Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempGenJnlTemp: Record "Gen. Journal Template";
        WHTEntry4: Record "WHT Entry";
        NoSeries: Codeunit "No. Series";
        PaymentAmount: Decimal;
        AppldAmount: Decimal;
        ExpectedAmount: Decimal;
        PaymentAmount1: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then
            if GenJnlLine."Bill-to/Pay-to No." = '' then begin
                Vendor.Get(GenJnlLine."Account No.");
                if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                    exit;
            end else begin
                Vendor.Get(GenJnlLine."Bill-to/Pay-to No.");
                if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                    exit;
            end;

        case Source of
            Source::Customer:
                begin
                    WHTEntry4.Reset();
                    WHTEntry4.SetCurrentKey("Document Type", "Document No.");
                    WHTEntry4.SetRange("Document Type", TempCustLedgEntry."Document Type");
                    WHTEntry4.SetFilter("Document No.", TempCustLedgEntry."Document No.");
                    if WHTEntry4.FindFirst() then begin
                        if Abs(GenJnlLine.Amount) < Abs(TempCustLedgEntry.Amount) then
                            PaymentAmount1 := GenJnlLine.Amount
                        else
                            PaymentAmount1 := -TempCustLedgEntry.Amount;
                        if CheckPmtDisc(
                          GenJnlLine."Posting Date",
                          TempCustLedgEntry."Pmt. Discount Date", Abs(TempCustLedgEntry."Amount to Apply"),
                          Abs(TempCustLedgEntry."Remaining Amount"), Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                          Abs(PaymentAmount1))
                        then
                            PaymentAmount1 := PaymentAmount1 - TempCustLedgEntry."Original Pmt. Disc. Possible";
                    end else
                        if (TempCustLedgEntry."Document No." = '') and (GenJnlLine.Amount <> 0) then
                            PaymentAmount1 := GenJnlLine.Amount;
                end;
            Source::Vendor:
                begin
                    WHTEntry4.Reset();
                    WHTEntry4.SetCurrentKey("Document Type", "Document No.");
                    WHTEntry4.SetRange("Document Type", TempVendLedgEntry."Document Type");
                    WHTEntry4.SetFilter("Document No.", TempVendLedgEntry."Document No.");
                    if WHTEntry4.FindFirst() then begin
                        if Abs(GenJnlLine.Amount) < Abs(TempVendLedgEntry.Amount) then
                            PaymentAmount1 := GenJnlLine.Amount
                        else
                            PaymentAmount1 := -TempVendLedgEntry.Amount;
                        if CheckPmtDisc(
                          GenJnlLine."Posting Date",
                          TempVendLedgEntry."Pmt. Discount Date", Abs(TempVendLedgEntry."Amount to Apply"),
                          Abs(TempVendLedgEntry."Remaining Amount"), Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                          Abs(PaymentAmount1))
                        then
                            PaymentAmount1 := PaymentAmount1 - TempVendLedgEntry."Original Pmt. Disc. Possible"; //xxx
                    end else
                        if (TempVendLedgEntry."Document No." = '') and (GenJnlLine.Amount <> 0) then
                            PaymentAmount1 := GenJnlLine.Amount;
                end;
        end;

        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
        case Source of
            Source::Vendor:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
            Source::Customer:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
        end;

        WHTEntry.SetRange(Closed, false);
        WHTEntry.SetRange("Transaction No.", 0);
        if GenJnlLine."Applies-to Doc. No." <> '' then
            WHTEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.")
        else
            WHTEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
        if WHTEntry.FindSet() then
            repeat
                WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                if (WHTPostingSetup."Realized WHT Type" =
                    WHTPostingSetup."Realized WHT Type"::Payment)
                then begin
                    WHTEntry3.Reset();
                    WHTEntry3 := WHTEntry;
                    case Source of
                        Source::Vendor:
                            begin
                                if GenJnlLine."Applies-to Doc. No." = '' then
                                    exit;
                                PurchCrMemoHeader.Reset();
                                PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                                PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                                if PurchCrMemoHeader.FindFirst() then begin
                                    TempRemAmt := 0;
                                    VendLedgEntry1.Reset();
                                    VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                    VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                    if VendLedgEntry1.FindFirst() then
                                        VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                    WHTEntryTemp.Reset();
                                    WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                    WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                    WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                    WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                    WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                    if WHTEntryTemp.FindFirst() then begin
                                        TempRemBase := WHTEntryTemp."Unrealized Amount";
                                        TempRemAmt := WHTEntryTemp."Unrealized Base";
                                    end;
                                end;

                                VendLedgEntry.Reset();
                                VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                                if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
                                else
                                    if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
                                        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                                if VendLedgEntry.FindFirst() then
                                    VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                                ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                                if VendLedgEntry1."Amount (LCY)" = 0 then
                                    VendLedgEntry1."Rem. Amt" := 0;
                                if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                   (Abs(PaymentAmount1) >=
                                    (Abs(VendLedgEntry."Rem. Amt" + VendLedgEntry1."Rem. Amt") -
                                     Abs(VendLedgEntry."Original Pmt. Disc. Possible"))) and
                                   (not AmountWithDisc)
                                then begin
                                    if VendLedgEntry."Remaining Amount" = 0 then begin
                                        AppldAmount :=
                                          Round(
                                            (PaymentAmount1 *
                                             (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                            ExpectedAmount);
                                        WHTEntry3."Remaining Unrealized Base" :=
                                          Round(
                                            WHTEntry."Remaining Unrealized Base" -
                                            Round(
                                              (PaymentAmount1 *
                                               (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                              ExpectedAmount));
                                        WHTEntry3."Remaining Unrealized Amount" :=
                                          Round(
                                            WHTEntry."Remaining Unrealized Amount" -
                                            Round(
                                              (PaymentAmount1 *
                                               ((WHTEntry."Unrealized Base"
                                                 * WHTEntry."WHT %" / 100) + TempRemBase)) /
                                              ExpectedAmount));
                                    end else begin
                                        AppldAmount :=
                                          Round(
                                            (PaymentAmount1 *
                                             (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                            ExpectedAmount);
                                        WHTEntry3."Remaining Unrealized Base" :=
                                          Round(
                                            WHTEntry."Remaining Unrealized Base" -
                                            Round(
                                              (PaymentAmount1 *
                                               (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                              ExpectedAmount));
                                        WHTEntry3."Remaining Unrealized Amount" :=
                                          Round(
                                            WHTEntry."Remaining Unrealized Amount" -
                                            Round(
                                              (PaymentAmount1 *
                                               (WHTEntry."Unrealized Amount" + TempRemBase)) /
                                              ExpectedAmount));
                                    end
                                end else begin
                                    AppldAmount :=
                                      Round(
                                        (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                        ExpectedAmount);
                                    WHTEntry3."Remaining Unrealized Base" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Base" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                          ExpectedAmount));
                                    WHTEntry3."Remaining Unrealized Amount" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Amount" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Amount" + TempRemBase)) /
                                          ExpectedAmount));
                                end;
                                PaymentAmount := PaymentAmount + AppldAmount;
                            end;
                        Source::Customer:
                            begin
                                SalesCrMemoHeader.Reset();
                                SalesCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                                SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
                                if SalesCrMemoHeader.FindFirst() then begin
                                    TempRemAmt := 0;
                                    CustLedgEntry1.Reset();
                                    CustLedgEntry1.SetRange("Document No.", SalesCrMemoHeader."No.");
                                    CustLedgEntry1.SetRange("Document Type", CustLedgEntry1."Document Type"::"Credit Memo");
                                    if CustLedgEntry1.FindFirst() then
                                        CustLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                    WHTEntryTemp.Reset();
                                    WHTEntryTemp.SetRange("Document No.", SalesCrMemoHeader."No.");
                                    WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                    WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
                                    WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                    WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                    if WHTEntryTemp.FindFirst() then begin
                                        TempRemBase := WHTEntryTemp."Unrealized Amount";
                                        TempRemAmt := WHTEntryTemp."Unrealized Base";
                                    end;
                                end;

                                CustLedgEntry.Reset();
                                CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                                if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
                                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice)
                                else
                                    if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
                                        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
                                if CustLedgEntry.FindFirst() then
                                    CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                                if CustLedgEntry1."Amount (LCY)" = 0 then
                                    CustLedgEntry1."Rem. Amt" := 0;
                                ExpectedAmount := -(CustLedgEntry.Amount + CustLedgEntry1.Amount);
                                if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                                   (Abs(PaymentAmount1) >= (Abs(CustLedgEntry."Rem. Amt" + CustLedgEntry1."Rem. Amt") -
                                                            Abs(CustLedgEntry."Original Pmt. Disc. Possible"))) and
                                   (not AmountWithDisc)
                                then begin
                                    AppldAmount :=
                                      Round(
                                        (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                                    WHTEntry3."Remaining Unrealized Base" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Base" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));
                                    WHTEntry3."Remaining Unrealized Amount" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Amount" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                                end else begin
                                    AppldAmount :=
                                      Round(
                                        (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                                    WHTEntry3."Remaining Unrealized Base" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Base" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));
                                    WHTEntry3."Remaining Unrealized Amount" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Amount" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                                end;
                                PaymentAmount := PaymentAmount + AppldAmount;
                            end;
                    end;
                    if (WHTEntry."Remaining Unrealized Base" = 0) and (WHTEntry."Remaining Unrealized Amount" = 0) then
                        WHTEntry3.Closed := true;
                    if GenJnlLine."Currency Code" <> WHTEntry."Currency Code" then
                        Error(Text1500000);
                    if AppldAmount = 0 then
                        exit;
                    WHTEntry2.Init();
                    WHTEntry2."Posting Date" := GenJnlLine."Document Date";
                    WHTEntry2."Entry No." := NextEntryNo();
                    WHTEntry2."Document Date" := WHTEntry."Document Date";
                    WHTEntry2."Document Type" := GenJnlLine."Document Type";
                    WHTEntry2."Document No." := WHTEntry."Document No.";
                    WHTEntry2."Gen. Bus. Posting Group" := WHTEntry."Gen. Bus. Posting Group";
                    WHTEntry2."Gen. Prod. Posting Group" := WHTEntry."Gen. Prod. Posting Group";
                    WHTEntry2."Bill-to/Pay-to No." := WHTEntry."Bill-to/Pay-to No.";
                    WHTEntry2."WHT Bus. Posting Group" := WHTEntry."WHT Bus. Posting Group";
                    WHTEntry2."WHT Prod. Posting Group" := WHTEntry."WHT Prod. Posting Group";
                    WHTEntry2."WHT Revenue Type" := WHTEntry."WHT Revenue Type";
                    WHTEntry2."Currency Code" := GenJnlLine."Currency Code";
                    WHTEntry2."Applies-to Entry No." := WHTEntry."Entry No.";
                    WHTEntry2."User ID" := UserId;
                    WHTEntry2."External Document No." := GenJnlLine."External Document No.";
                    WHTEntry2."Actual Vendor No." := GenJnlLine."Actual Vendor No.";
                    WHTEntry2."Original Document No." := GenJnlLine."Document No.";
                    WHTEntry2."Source Code" := GenJnlLine."Source Code";
                    WHTEntry2."Transaction No." := TransactionNo;
                    WHTEntry2."Unrealized WHT Entry No." := WHTEntry."Entry No.";
                    WHTEntry2."WHT %" := WHTEntry."WHT %";
                    case Source of
                        Source::Vendor:
                            begin
                                WHTEntry2.Base := Round(AppldAmount);
                                WHTEntry2.Amount := Round(WHTEntry2.Base * WHTEntry2."WHT %" / 100);
                                WHTEntry2."Payment Amount" := PaymentAmount1;
                                WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Purchase;
                                WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                WHTEntry2."WHT Report" := WHTPostingSetup."WHT Report";
                                if GenJnlLine."Certificate Printed" then begin
                                    WHTEntry2."WHT Report Line No" := GenJnlLine."WHT Report Line No.";
                                    TempWHT.SetRange("Document No.", WHTEntry2."Document No.");
                                    if TempWHT.FindFirst() then
                                        WHTEntry2."WHT Certificate No." := TempWHT."WHT Certificate No.";
                                end else begin
                                    if ((Source = Source::Vendor) and
                                        (WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice)) or
                                       ((Source = Source::Customer) and
                                        (WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo"))
                                    then
                                        if (WHTReportLineNo = '') and
                                           (WHTEntry2.Amount <> 0) and
                                           (WHTPostingSetup."WHT Report Line No. Series" <> '')
                                        then
                                            WHTReportLineNo := NoSeries.GetNextNo(WHTPostingSetup."WHT Report Line No. Series", WHTEntry2."Posting Date");
                                    WHTEntry2."WHT Report Line No" := WHTReportLineNo;
                                end;
                                TType := TType::Purchase;
                            end;
                        Source::Customer:
                            begin
                                WHTEntry2.Base := Round(AppldAmount);
                                WHTEntry2.Amount := Round(WHTEntry2.Base * WHTEntry2."WHT %" / 100);
                                WHTEntry2."Payment Amount" := PaymentAmount1;
                                WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Sale;
                                TType := TType::Sale;
                            end;
                    end;

                    if WHTEntry2."Currency Code" <> '' then begin
                        CurrFactor := GenJnlLine."Currency Factor";
                        WHTEntry2."Base (LCY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date",
                              WHTEntry2."Currency Code",
                              WHTEntry2.Base, CurrFactor));
                        WHTEntry2."Amount (LCY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date",
                              WHTEntry2."Currency Code",
                              WHTEntry2.Amount, CurrFactor));
                    end else begin
                        WHTEntry2."Amount (LCY)" := WHTEntry2.Amount;
                        WHTEntry2."Base (LCY)" := WHTEntry2.Base;
                    end;
                    if WHTEntry2."Currency Code" <> '' then begin
                        CurrFactor := GenJnlLine."Currency Factor";
                        WHTEntry2."Base (LCY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date",
                              WHTEntry2."Currency Code",
                              WHTEntry2.Base, CurrFactor));
                        WHTEntry2."Amount (LCY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date",
                              WHTEntry2."Currency Code",
                              WHTEntry2.Amount, CurrFactor));
                    end else begin
                        WHTEntry2."Amount (LCY)" := WHTEntry2.Amount;
                        WHTEntry2."Base (LCY)" := WHTEntry2.Base;
                    end;
                    if VendLedgEntry."Original Pmt. Disc. Possible" <> 0 then
                        if WHTEntry2.Base <> WHTEntry."Unrealized Base" then begin
                            if VendLedgEntry."Remaining Amount" = 0 then begin
                                WHTEntry3."Rem Unrealized Amount (LCY)" := WHTEntry2."Rem Unrealized Amount (LCY)";
                                WHTEntry3."Rem Unrealized Base (LCY)" := WHTEntry2."Rem Unrealized Base (LCY)";
                                WHTEntry3."Remaining Unrealized Amount" := WHTEntry2."Remaining Unrealized Amount";
                                WHTEntry3."Remaining Unrealized Base" := WHTEntry2."Remaining Unrealized Base";
                                WHTEntry4.Reset();
                                WHTEntry4.SetCurrentKey("Applies-to Entry No.");
                                WHTEntry4.SetFilter("Applies-to Entry No.", '=%1', WHTEntry."Entry No.");
                                WHTEntry4.CalcSums(WHTEntry4.Base);
                                WHTEntry3."Pymt. Disc. Diff. Base" := WHTEntry."Unrealized Base" - (WHTEntry4.Base + WHTEntry2.Base);
                                WHTEntry3."Pymt. Disc. Diff. Amount" := Round((WHTEntry3."Pymt. Disc. Diff. Base" * WHTEntry3."WHT %") / 100);
                                WHTEntry3."WHT Difference" :=
                                  WHTEntry3."WHT Difference" + Abs(Abs(WHTEntry3."Pymt. Disc. Diff. Amount") -
                                  Abs(WHTEntry."Unrealized Amount" - (WHTEntry4.Amount + WHTEntry2.Amount)));
                            end;
                        end else begin
                            WHTEntry3."Rem Unrealized Amount (LCY)" :=
                              WHTEntry."Rem Unrealized Amount (LCY)" - WHTEntry2."Amount (LCY)";
                            WHTEntry3."Rem Unrealized Base (LCY)" :=
                              WHTEntry."Rem Unrealized Base (LCY)" - WHTEntry2."Base (LCY)";
                        end;

                    WHTEntry2.Insert();
                    WHTEntry3.Modify();

                    AdjustWHTEntryWithWHTDifference(WHTEntry, WHTEntry2, WHTEntry3);

                    // Payment Method Code.Begin
                    if Source = Source::Customer then
                        TempGenJnlTemp.SetRange(Type, TempGenJnlTemp.Type::Sales)
                    else
                        TempGenJnlTemp.SetRange(Type, TempGenJnlTemp.Type::Purchases);
                    if TempGenJnlTemp.FindFirst() then
                        if GenJnlLine."Journal Template Name" <> TempGenJnlTemp.Name then
                            if WHTEntry2.Amount <> 0 then
                                InsertWHTPostingBuffer(WHTEntry2, GenJnlLine, 0, AmountWithDisc);
                end;
            until (WHTEntry.Next() = 0);
        if (WHTPostingSetup."Realized WHT Type" =
            WHTPostingSetup."Realized WHT Type"::Payment)
        then
            exit(WHTEntry2."Entry No." + 1);
    end;

    [Scope('OnPrem')]
    procedure ProcessManualReceipt(var GenJnlLine: Record "Gen. Journal Line"; TransactionNo: Integer; EntryNo: Integer; Source: Option Vendor,Customer) PaymentNo: Integer
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry2: Record "WHT Entry";
        WHTEntry3: Record "WHT Entry";
        PaymentAmount: Decimal;
        PaymentAmountLCY: Decimal;
        AppldAmount: Decimal;
        WHTEntryTemp: Record "WHT Entry";
        PaymentAmount1: Decimal;
        WHTAmount: Decimal;
    begin
        PaymentAmount := GenJnlLine.Amount;
        PaymentAmount1 := GenJnlLine.Amount;
        PaymentAmountLCY := GenJnlLine."Amount (LCY)";
        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
        case Source of
            Source::Vendor:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
            Source::Customer:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
        end;

        if GenJnlLine."Applies-to Doc. No." <> '' then
            WHTEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.")
        else
            WHTEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");

        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice)
        else
            if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
                WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");

        if WHTEntry.FindSet() then
            repeat
                WHTEntryTemp.Reset();
                WHTEntryTemp := WHTEntry;
                case Source of
                    Source::Vendor:
                        begin
                            if GenJnlLine."Applies-to Doc. No." = '' then
                                exit;
                            WHTEntry3.Reset();
                            WHTAmount := 0;
                            WHTEntry3.Copy(WHTEntry);
                            if WHTEntry3.FindSet() then
                                repeat
                                    WHTAmount := WHTAmount + WHTEntry3."Unrealized Amount";
                                until WHTEntry3.Next() = 0;
                            AppldAmount := -Round(GenJnlLine.Amount * WHTEntry."Unrealized Amount" / WHTAmount);

                            if AppldAmount = 0 then
                                AppliedBase := WHTEntry."Remaining Unrealized Base"
                            else
                                AppliedBase := Round(AppldAmount * 100 / WHTEntry."WHT %");

                            if WHTEntry."WHT %" <> 0 then
                                WHTEntryTemp."Remaining Unrealized Base" :=
                                  Round(WHTEntry."Remaining Unrealized Base" - Round(AppldAmount * 100 / WHTEntry."WHT %"))
                            else
                                WHTEntryTemp."Remaining Unrealized Base" := 0;
                            WHTEntryTemp."Remaining Unrealized Amount" :=
                              Round(
                                WHTEntry."Remaining Unrealized Amount" -
                                Round(AppldAmount));
                            PaymentAmount := PaymentAmount + AppldAmount;
                            TType := TType::Purchase;
                        end;
                    Source::Customer:
                        begin
                            WHTEntry3.Reset();
                            WHTAmount := 0;
                            WHTEntry3.Copy(WHTEntry);
                            if WHTEntry3.FindSet() then
                                repeat
                                    WHTAmount := WHTAmount + WHTEntry3."Unrealized Amount";
                                until WHTEntry3.Next() = 0;

                            AppldAmount := Round(GenJnlLine.Amount * WHTEntry."Unrealized Amount" / WHTAmount);

                            if AppldAmount = 0 then
                                AppliedBase := WHTEntry."Remaining Unrealized Base"
                            else
                                AppliedBase := Round(AppldAmount * 100 / WHTEntry."WHT %");

                            TType := TType::Sale;

                            if WHTEntry."WHT %" <> 0 then
                                WHTEntryTemp."Remaining Unrealized Base" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Base" -
                                    Round(
                                      AppldAmount * 100 / WHTEntry."WHT %"))
                            else
                                WHTEntryTemp."Remaining Unrealized Base" := 0;

                            WHTEntryTemp."Remaining Unrealized Amount" :=
                              Round(
                                WHTEntry."Remaining Unrealized Amount" -
                                Round(AppldAmount));
                            PaymentAmount := PaymentAmount + AppldAmount;
                        end;
                end;

                if GenJnlLine."Currency Code" <> WHTEntry."Currency Code" then
                    Error(Text1500000);
                WHTEntry2.Init();
                WHTEntry2."Posting Date" := GenJnlLine."Document Date";
                WHTEntry2."Entry No." := NextEntryNo();
                WHTEntry2."Document Date" := WHTEntry."Document Date";
                WHTEntry2."Document Type" := GenJnlLine."Document Type";
                WHTEntry2."Document No." := WHTEntry."Document No.";
                WHTEntry2."Gen. Bus. Posting Group" := WHTEntry."Gen. Bus. Posting Group";
                WHTEntry2."Gen. Prod. Posting Group" := WHTEntry."Gen. Prod. Posting Group";
                WHTEntry2."Bill-to/Pay-to No." := WHTEntry."Bill-to/Pay-to No.";
                WHTEntry2."WHT Bus. Posting Group" := WHTEntry."WHT Bus. Posting Group";
                WHTEntry2."WHT Prod. Posting Group" := WHTEntry."WHT Prod. Posting Group";
                WHTEntry2."WHT Revenue Type" := WHTEntry."WHT Revenue Type";
                WHTEntry2."Currency Code" := GenJnlLine."Currency Code";
                WHTEntry2."Applies-to Entry No." := WHTEntry."Entry No.";
                WHTEntry2."User ID" := UserId;
                WHTEntry2."External Document No." := GenJnlLine."External Document No.";
                WHTEntry2."Original Document No." := GenJnlLine."Document No.";
                WHTEntry2."Source Code" := GenJnlLine."Source Code";
                WHTEntry2."Transaction No." := TransactionNo;
                if TType = TType::Sale then
                    WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Sale
                else
                    WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Purchase;
                WHTEntry2."WHT %" := WHTEntry."WHT %";
                WHTEntry2."Unrealized WHT Entry No." := WHTEntry."Entry No.";
                WHTEntry2.Base := Round(AppliedBase);
                WHTEntry2.Amount := Round(AppldAmount);
                if WHTEntry2."Currency Code" <> '' then begin
                    CurrFactor :=
                      CurrExchRate.ExchangeRate(WHTEntry2."Posting Date", WHTEntry2."Currency Code");
                    WHTEntry2."Base (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date",
                          WHTEntry2."Currency Code",
                          WHTEntry2.Base, CurrFactor));
                    WHTEntry2."Amount (LCY)" := Round(WHTEntry2."Base (LCY)");
                end else begin
                    WHTEntry2."Amount (LCY)" := WHTEntry2.Amount;
                    WHTEntry2."Base (LCY)" := WHTEntry2.Base;
                end;
                WHTEntry2.Insert();
                WHTEntryTemp."Rem Unrealized Amount (LCY)" :=
                  WHTEntry."Rem Unrealized Amount (LCY)" - WHTEntry2."Amount (LCY)";
                WHTEntryTemp."Rem Unrealized Base (LCY)" :=
                  WHTEntry."Rem Unrealized Base (LCY)" - WHTEntry2."Base (LCY)";
                WHTEntryTemp.Modify();
                if WHTEntry2.Amount <> 0 then
                    InsertWHTPostingBuffer(WHTEntry2, GenJnlLine, 0, false);
            until (WHTEntry.Next() = 0);
        exit(WHTEntry2."Entry No." + 1);
    end;

    [Scope('OnPrem')]
    procedure InsertWHTPostingBuffer(var WHTEntryGL: Record "WHT Entry"; var GenJnlLine: Record "Gen. Journal Line"; Source: Option Payment,Refund; Oldest: Boolean)
    var
        PurchSetup: Record "General Ledger Setup";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        HighestLineNo: Integer;
    begin
        WHTPostingSetup.Get(WHTEntryGL."WHT Bus. Posting Group", WHTEntryGL."WHT Prod. Posting Group");
        PurchSetup.Get();
        GenJnlLine2 := GenJnlLine;
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if GenJnlLine2.FindLast() then
            HighestLineNo := GenJnlLine2."Line No." + 10000
        else
            HighestLineNo := 0;
        GenJnlLine3.Reset();
        GenJnlLine3 := GenJnlLine;
        GenJnlLine3.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine3.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine3."Line No." := HighestLineNo;
        if GenJnlLine3.Next() = 0 then
            GenJnlLine3."Line No." := HighestLineNo + 10000
        else begin
            while GenJnlLine3."Line No." = HighestLineNo + 1 do begin
                HighestLineNo := GenJnlLine3."Line No.";
                if GenJnlLine3.Next() = 0 then
                    GenJnlLine3."Line No." := HighestLineNo + 20000;
            end;
            GenJnlLine3."Line No." := HighestLineNo + 10000;
        end;

        GenJnlLine3.Init();
        GenJnlLine3.Validate("Posting Date", GenJnlLine."Posting Date");
        GenJnlLine3."Document Type" := GenJnlLine."Document Type";
        GenJnlLine3."Account Type" := GenJnlLine3."Account Type"::"G/L Account";
        GenJnlLine3."System-Created Entry" := true;
        GenJnlLine3."Is WHT" := true;
        if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund then begin
            if TType = TType::Purchase then
                GenJnlLine3.Validate("Account No.", WHTPostingSetup."Purch. WHT Adj. Account No.");
            if TType = TType::Sale then
                GenJnlLine3.Validate("Account No.", WHTPostingSetup."Sales WHT Adj. Account No.");
        end else begin
            if TType = TType::Purchase then
                GenJnlLine3.Validate("Account No.", WHTPostingSetup."Payable WHT Account Code");
            if TType = TType::Sale then begin
                WHTPostingSetup.TestField("Prepaid WHT Account Code");
                GenJnlLine3.Validate("Account No.", WHTPostingSetup."Prepaid WHT Account Code");
            end;
        end;
        GenJnlLine3.Validate("Currency Code", WHTEntryGL."Currency Code");
        if GLSetup."Round Amount for WHT Calc" then begin
            GenJnlLine3.Validate(Amount, RoundWHTAmount(-WHTEntryGL.Amount));
            GenJnlLine3."Amount (LCY)" := RoundWHTAmount(-WHTEntryGL."Amount (LCY)");
        end else begin
            GenJnlLine3.Validate(Amount, -WHTEntryGL.Amount);
            GenJnlLine3."Amount (LCY)" := -WHTEntryGL."Amount (LCY)";
        end;
        if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::" ") and
           (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund)
        then
            GenJnlLine3."Gen. Posting Type" := GenJnlLine."Gen. Posting Type";
        GenJnlLine3."System-Created Entry" := true; // Payment Method Code
        GLSetup.Get();
        if (Oldest = true) or GLSetup."Manual Sales WHT Calc." then begin
            if TType = TType::Purchase then begin
                case WHTPostingSetup."Bal. Payable Account Type" of
                    WHTPostingSetup."Bal. Payable Account Type"::"Bank Account":
                        GenJnlLine3."Bal. Account Type" := GenJnlLine3."Account Type"::"Bank Account";
                    WHTPostingSetup."Bal. Payable Account Type"::"G/L Account":
                        GenJnlLine3."Bal. Account Type" := GenJnlLine3."Account Type"::"G/L Account";
                end;
                WHTPostingSetup.TestField("Bal. Payable Account No.");
                GenJnlLine3.Validate("Bal. Account No.", WHTPostingSetup."Bal. Payable Account No.");
            end;

            if TType = TType::Sale then begin
                case WHTPostingSetup."Bal. Prepaid Account Type" of
                    WHTPostingSetup."Bal. Prepaid Account Type"::"Bank Account":
                        GenJnlLine3."Bal. Account Type" := GenJnlLine3."Account Type"::"Bank Account";
                    WHTPostingSetup."Bal. Prepaid Account Type"::"G/L Account":
                        GenJnlLine3."Bal. Account Type" := GenJnlLine3."Account Type"::"G/L Account";
                end;
                WHTPostingSetup.TestField("Bal. Prepaid Account No.");
                GenJnlLine3.Validate("Bal. Account No.", WHTPostingSetup."Bal. Prepaid Account No.");
            end;
        end;
        GenJnlLine3."Source Code" := GenJnlLine."Source Code";
        GenJnlLine3."Reason Code" := GenJnlLine."Reason Code";
        GenJnlLine3."Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        GenJnlLine3."Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        GenJnlLine3."Allow Zero-Amount Posting" := true;
        GenJnlLine3."WHT Business Posting Group" := WHTEntryGL."WHT Bus. Posting Group";
        GenJnlLine3."WHT Product Posting Group" := WHTEntryGL."WHT Prod. Posting Group";
        GenJnlLine3."Document Type" := GenJnlLine."Document Type";
        GenJnlLine3."Document No." := GenJnlLine."Document No.";
        GenJnlLine3."External Document No." := GenJnlLine."External Document No.";
        if Source = Source::Refund then
            GenJnlLine3."Gen. Posting Type" := GenJnlLine3."Gen. Posting Type"::" ";
        GenJnlLine3.Insert();
    end;

    [Scope('OnPrem')]
    procedure NextEntryNo(): Integer
    var
        NewWHTEntry: Record "WHT Entry";
    begin
        NewWHTEntry.Reset();
        exit(NewWHTEntry.GetLastEntryNo() + 1);
    end;

    [Scope('OnPrem')]
    procedure NextTempEntryNo(): Integer
    var
        NewWHTEntry: Record "Temp WHT Entry";
    begin
        NewWHTEntry.Reset();
        if NewWHTEntry.FindLast() then
            exit(NewWHTEntry."Entry No." + 1);

        exit(1);
    end;

    // If ScheduleInJobQueue is set to true then WHT slip (REP28040) will be printed within the background job task
    // This modification is done to support background posting of GL lines. 
    [Scope('OnPrem')]
    procedure PrintWHTSlips(var GLReg: Record "G/L Register"; ScheduleInJobQueue: Boolean)
    var
        GLEntry: Record "G/L Entry";
        WHTEntry: Record "WHT Entry";
        WHTEntry2: Record "WHT Entry";
        WHTSlipBuffer: Record "WHT Certificate Buffer";
        PurchSetup: Record "Purchases & Payables Setup";
        ReportSelection: Record "Report Selections";
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        NoSeries: Codeunit "No. Series";
        GLRegFilter: Text[250];
        StartTrans: Integer;
        EndTrans: Integer;
        x: Integer;
        PrintSlips: Integer;
        WHTSlipBuffer2: Code[20];
        WHTSlipDocument2: Code[20];
        VendorArray: array[1000] of Code[20];
        DocumentArray: array[1000] of Code[20];
        WHTSlipNo: Code[20];
        ActualVendorNo: Boolean;
    begin
        x := 0;
        GLRegFilter := GLReg.GetFilters();
        GLEntry.Reset();
        if GLReg."From Entry No." < 0 then
            GLEntry.SetRange("Entry No.", GLReg."To Entry No.", GLReg."From Entry No.")
        else
            GLEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        GLEntry.FindFirst();
        StartTrans := GLEntry."Transaction No.";
        GLEntry.FindLast();
        EndTrans := GLEntry."Transaction No.";
        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type");
        WHTEntry.SetRange("Entry No.", GLReg."From WHT Entry No.", GLReg."To WHT Entry No.");
        if not WHTEntry.FindFirst() then
            exit;
        repeat
            if WHTEntry."Transaction Type" = WHTEntry."Transaction Type"::Sale then begin
                if WHTEntry."Document Type" in [
                                                WHTEntry."Document Type"::Invoice,
                                                WHTEntry."Document Type"::Payment]
                then
                    exit;

                SalesSetup.Get();
                if not SalesSetup."Print WHT on Credit Memo" then
                    if WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo" then
                        exit;
            end;
            x := x + 1;
            if WHTEntry."Actual Vendor No." <> '' then begin
                VendorArray[x] := WHTEntry."Actual Vendor No.";
                ActualVendorNo := true;
            end else
                VendorArray[x] := WHTEntry."Bill-to/Pay-to No.";
            DocumentArray[x] := WHTEntry."Original Document No.";
        until WHTEntry.Next() = 0;

        PurchSetup.Get();
        WHTSlipBuffer.DeleteAll();
        for PrintSlips := 1 to x do begin
            WHTSlipBuffer.Init();
            WHTSlipBuffer."Line No." := PrintSlips;
            WHTSlipBuffer."Vendor No." := VendorArray[PrintSlips];
            WHTSlipBuffer."Document No." := DocumentArray[PrintSlips];
            WHTSlipBuffer.Insert();
        end;

        x := 0;
        Clear(VendorArray);
        Clear(DocumentArray);
        WHTSlipBuffer.Reset();
        WHTSlipBuffer.SetCurrentKey("Vendor No.", "Document No.");
        WHTSlipBuffer.FindSet();
        repeat
            x := x + 1;
            VendorArray[x] := WHTSlipBuffer."Vendor No.";
            DocumentArray[x] := WHTSlipBuffer."Document No.";
        until WHTSlipBuffer.Next() = 0;

        for PrintSlips := 1 to x do begin
            if (VendorArray[PrintSlips] <> WHTSlipBuffer2) or
               (DocumentArray[PrintSlips] <> WHTSlipDocument2)
            then begin
                PurchSetup.TestField("WHT Certificate No. Series");
                WHTSlipNo := NoSeries.GetNextNo(PurchSetup."WHT Certificate No. Series", WHTEntry."Posting Date");
                WHTEntry.Reset();
                WHTEntry.SetCurrentKey("Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type");
                if ActualVendorNo then
                    WHTEntry.SetRange("Actual Vendor No.", VendorArray[PrintSlips])
                else
                    WHTEntry.SetRange("Bill-to/Pay-to No.", VendorArray[PrintSlips]);
                WHTEntry.SetRange("Original Document No.", DocumentArray[PrintSlips]);
                if WHTEntry.FindSet() then
                    repeat
                        WHTRevenueTypes.Reset();
                        WHTRevenueTypes.SetRange(Code, WHTEntry."WHT Revenue Type");
                        WHTEntry2.Reset();
                        WHTEntry2 := WHTEntry;
                        if WHTRevenueTypes.FindFirst() then begin
                            WHTEntry2."WHT Certificate No." := WHTSlipNo;
                            WHTEntry2.Modify();
                        end else
                            Error(MissingRevenueTypeErr, WHTEntry."WHT Revenue Type");

                    until WHTEntry.Next() = 0;
                WHTEntry.Reset();
                WHTEntry.SetCurrentKey("Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type");
                if ActualVendorNo then
                    WHTEntry.SetRange("Actual Vendor No.", VendorArray[PrintSlips])
                else
                    WHTEntry.SetRange("Bill-to/Pay-to No.", VendorArray[PrintSlips]);
                WHTEntry.SetRange("Original Document No.", DocumentArray[PrintSlips]);
                WHTEntry.SetRange("WHT Certificate No.", WHTSlipNo);
                if WHTEntry.FindSet() then
                    ReportSelection.Reset();
                ReportSelection.SetRange(Usage, ReportSelection.Usage::"WHT Certificate");
                GeneralLedgerSetup.Get();
                if ReportSelection.FindSet() then
                    repeat
                        if ScheduleInJobQueue then
                            BatchPostingPrintMgt.SchedulePrintJobQueueEntry(WHTEntry, ReportSelection."Report ID", GeneralLedgerSetup."Report Output Type".AsInteger())
                        else
                            REPORT.Run(ReportSelection."Report ID", PurchSetup."Print Dialog", false, WHTEntry);
                    until ReportSelection.Next() = 0;
            end;
            WHTSlipBuffer2 := VendorArray[PrintSlips];
            WHTSlipDocument2 := DocumentArray[PrintSlips];
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertVendJournalWHT(var GenJnlLine: Record "Gen. Journal Line") EntryNo: Integer
    begin
        if ((GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Invoice) and
            (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::"Credit Memo") and
            (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment) and
            (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund))
        then
            exit;

        if not WHTPostingSetup.Get(
             GenJnlLine."WHT Business Posting Group", GenJnlLine."WHT Product Posting Group")
        then
            exit;

        TransType := TransType::Purchase;
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                DocType := DocType::Invoice;
            GenJnlLine."Document Type"::"Credit Memo":
                DocType := DocType::"Credit Memo";
            GenJnlLine."Document Type"::Payment:
                DocType := DocType::Payment;
            GenJnlLine."Document Type"::Refund:
                DocType := DocType::Refund;
        end;

        PostingDate := GenJnlLine."Posting Date";
        DocNo := GenJnlLine."Document No.";
        PayToAccType := PayToAccType::Vendor;
        PayToVendCustNo := GenJnlLine."Account No.";
        BuyFromAccType := BuyFromAccType::Vendor;
        BuyFromVendCustNo := GenJnlLine."Account No.";
        ActualVendorNo := GenJnlLine."Actual Vendor No.";
        ApplyDocType := GenJnlLine."Applies-to Doc. Type";
        ApplyDocNo := GenJnlLine."Applies-to Doc. No.";
        "Applies-toID" := GenJnlLine."Applies-to ID";
        WHTBusPostGrp := GenJnlLine."WHT Business Posting Group";
        WHTProdPostGrp := GenJnlLine."WHT Product Posting Group";
        WHTPostingSetup.Reset();
        WHTPostingSetup.Get(WHTBusPostGrp, WHTProdPostGrp);
        WHTRevenueType := WHTPostingSetup."Revenue Type";
        Amount := -GenJnlLine.Amount;
        if GenJnlLine."Bal. VAT %" <> 0 then
            Amount := GenJnlLine."Bal. VAT Base Amount";

        AbsorbBase := -GenJnlLine."WHT Absorb Base";
        if AbsorbBase <> 0 then
            AmountVAT := AbsorbBase
        else
            AmountVAT := Amount;
        CurrFactor := GenJnlLine."Currency Factor";
        DocDate := GenJnlLine."Document Date";
        Dim1 := GenJnlLine."Shortcut Dimension 1 Code";
        Dim2 := GenJnlLine."Shortcut Dimension 2 Code";
        ExtDocNo := GenJnlLine."External Document No.";
        CurrencyCode := GenJnlLine."Currency Code";
        SourceCode := GenJnlLine."Source Code";
        TempGenJnlLine.Reset();
        TempGenJnlLine.DeleteAll();
        TempGenJnlLine := GenJnlLine;
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then begin
            Vendor.Get(GenJnlLine."Account No.");
            if Vendor.ABN <> '' then
                exit;
            if CheckWHTCalculationRule(GenJnlLine."Amount (LCY)", WHTPostingSetup) then
                exit;
        end;
        exit(InsertWHT(TType::Purchase));
    end;

    [Scope('OnPrem')]
    procedure InsertCustJournalWHT(var GenJnlLine: Record "Gen. Journal Line") EntryNo: Integer
    begin
        SourceCodeSetup.Get();
        if GenJnlLine."Source Code" = SourceCodeSetup.Sales then
            exit;
        if ((GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Invoice) and
            (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::"Credit Memo") and
            (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment) and
            (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund))
        then
            exit;

        if not WHTPostingSetup.Get(
             GenJnlLine."WHT Business Posting Group", GenJnlLine."WHT Product Posting Group")
        then
            exit;

        TransType := TransType::Sale;
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                DocType := DocType::Invoice;
            GenJnlLine."Document Type"::"Credit Memo":
                DocType := DocType::"Credit Memo";
            GenJnlLine."Document Type"::Payment:
                DocType := DocType::Payment;
            GenJnlLine."Document Type"::Refund:
                DocType := DocType::Refund;
        end;

        PostingDate := GenJnlLine."Posting Date";
        DocNo := GenJnlLine."Document No.";
        PayToAccType := PayToAccType::Customer;
        PayToVendCustNo := GenJnlLine."Account No.";
        BuyFromAccType := BuyFromAccType::Customer;
        BuyFromVendCustNo := GenJnlLine."Account No.";
        ApplyDocType := GenJnlLine."Applies-to Doc. Type";
        ApplyDocNo := GenJnlLine."Applies-to Doc. No.";
        "Applies-toID" := GenJnlLine."Applies-to ID";
        WHTBusPostGrp := GenJnlLine."WHT Business Posting Group";
        WHTProdPostGrp := GenJnlLine."WHT Product Posting Group";
        WHTPostingSetup.Reset();
        WHTPostingSetup.Get(WHTBusPostGrp, WHTProdPostGrp);
        WHTRevenueType := WHTPostingSetup."Revenue Type";
        AbsorbBase := GenJnlLine."WHT Absorb Base";
        Amount := GenJnlLine.Amount;
        if AbsorbBase <> 0 then
            AmountVAT := AbsorbBase
        else
            AmountVAT := Amount;
        CurrFactor := GenJnlLine."Currency Factor";
        DocDate := GenJnlLine."Document Date";
        Dim1 := GenJnlLine."Shortcut Dimension 1 Code";
        Dim2 := GenJnlLine."Shortcut Dimension 2 Code";
        ExtDocNo := GenJnlLine."External Document No.";
        CurrencyCode := GenJnlLine."Currency Code";
        SourceCode := GenJnlLine."Source Code";
        exit(InsertWHT(TType::Sale));
    end;

    [Scope('OnPrem')]
    procedure InsertWHT(TransType: Option Purchase,Sale) EntryNo: Integer
    var
        WHTEntry: Record "WHT Entry";
        TempWHTEntry: Record "WHT Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        NoSeries: Codeunit "No. Series";
        TotalWHT: Decimal;
        TotalWHTBase: Decimal;
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ExpectedAmount: Decimal;
        WHTEntryTemp: Record "WHT Entry";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PaymentAmount1: Decimal;
        AppldAmount: Decimal;
        WHTEntry3: Record "WHT Entry";
        IsRefund: Boolean;
        RemainingAmt: Decimal;
        WHTPart: Decimal;
    begin
        if WHTPostingSetup.Get(WHTBusPostGrp, WHTProdPostGrp) then
            if WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::" " then begin
                UnrealizedWHT := (WHTPostingSetup."Realized WHT Type" = WHTPostingSetup."Realized WHT Type"::Payment);
                WHTEntry.Init();
                WHTEntry."Entry No." := NextEntryNo();
                WHTEntry."Gen. Bus. Posting Group" := GenBusPostGrp;
                WHTEntry."Gen. Prod. Posting Group" := GenProdPostGrp;
                WHTEntry."WHT Bus. Posting Group" := WHTBusPostGrp;
                WHTEntry."WHT Prod. Posting Group" := WHTProdPostGrp;
                WHTEntry."Posting Date" := PostingDate;
                WHTEntry."Document Date" := DocDate;
                WHTEntry."Document No." := DocNo;
                WHTEntry."WHT %" := WHTPostingSetup."WHT %";
                WHTEntry."Applies-to Doc. Type" := ApplyDocType;
                WHTEntry."Applies-to Doc. No." := ApplyDocNo;
                WHTEntry."Source Code" := SourceCode;
                WHTEntry."Reason Code" := ReasonCode;
                WHTEntry."WHT Revenue Type" := WHTPostingSetup."Revenue Type";
                WHTEntry."Document Type" := DocType;
                if TransType = TransType::Purchase then
                    WHTEntry."Transaction Type" := WHTEntry."Transaction Type"::Purchase
                else
                    WHTEntry."Transaction Type" := WHTEntry."Transaction Type"::Sale;
                WHTEntry."Actual Vendor No." := ActualVendorNo;
                WHTEntry."Source Code" := SourceCode;
                WHTEntry."Bill-to/Pay-to No." := PayToVendCustNo;
                WHTEntry."User ID" := UserId;
                WHTEntry."Currency Code" := CurrencyCode;

                // VAT for G/L entry/entries
                if UnrealizedWHT then begin
                    SetWHTEntryAmounts(WHTEntry, AbsorbBase, AmountVAT, CurrFactor);
                    if WHTEntry."Applies-to Doc. No." <> '' then begin
                        TempWHTEntry.Reset();
                        TempWHTEntry.SetRange("Document Type", WHTEntry."Applies-to Doc. Type");
                        TempWHTEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                        if TempWHTEntry.FindFirst() then begin
                            if Abs(WHTEntry."Unrealized Amount") <=
                               Abs(TempWHTEntry."Remaining Unrealized Amount")
                            then begin
                                TempWHTEntry."Remaining Unrealized Amount" :=
                                  TempWHTEntry."Remaining Unrealized Amount" + WHTEntry."Unrealized Amount";
                                TempWHTEntry."Remaining Unrealized Base" :=
                                  TempWHTEntry."Remaining Unrealized Base" + WHTEntry."Unrealized Base";
                                WHTEntry."Remaining Unrealized Amount" := 0;
                                WHTEntry."Remaining Unrealized Base" := 0;
                                WHTEntry.Closed := true;
                            end else begin
                                TempWHTEntry."Remaining Unrealized Amount" := 0;
                                TempWHTEntry."Remaining Unrealized Base" := 0;
                                WHTEntry."Remaining Unrealized Amount" :=
                                  TempWHTEntry."Remaining Unrealized Amount" + WHTEntry."Unrealized Amount";
                                WHTEntry."Remaining Unrealized Base" :=
                                  TempWHTEntry."Remaining Unrealized Base" + WHTEntry."Unrealized Base";
                            end;

                            if (TempWHTEntry."Remaining Unrealized Base" = 0) and
                               (TempWHTEntry."Remaining Unrealized Amount" = 0)
                            then
                                TempWHTEntry.Closed := true;

                            TempWHTEntry.Modify();
                            WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                        end;
                    end else
                        if "Applies-toID" <> '' then begin
                            if (TransType = TransType::Purchase) and
                               (WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo")
                            then begin
                                VendLedgerEntry1.SetRange("Applies-to ID", "Applies-toID");
                                if VendLedgerEntry1.FindSet() then
                                    repeat
                                        if FindWHTEntryForApply(
                                             TempWHTEntry, VendLedgerEntry1."Document Type", VendLedgerEntry1."Document No.",
                                             WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group")
                                        then begin
                                            VendLedgerEntry1.CalcFields("Remaining Amount");
                                            WHTPart := Abs(VendLedgerEntry1."Amount to Apply" / VendLedgerEntry1."Remaining Amount");
                                            if WHTPart >= 1 then begin
                                                if Abs(WHTEntry."Remaining Unrealized Amount") <=
                                                   Abs(TempWHTEntry."Remaining Unrealized Amount" * WHTPart)
                                                then
                                                    CalcWHTEntriesRemAmounts(TempWHTEntry, WHTEntry, WHTPart)
                                                else
                                                    CalcWHTEntriesRemAmounts(WHTEntry, TempWHTEntry, WHTPart);
                                            end else
                                                CalcWHTEntriesRemAmounts(TempWHTEntry, WHTEntry, WHTPart)
                                        end;
                                        TempWHTEntry."Applies-to Entry No." := WHTEntry."Entry No.";
                                        TempWHTEntry.Modify();
                                    until VendLedgerEntry1.Next() = 0;
                            end;

                            if TransType = TransType::Sale then begin
                                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                                CustLedgerEntry.SetRange("Document No.", WHTEntry."Document No.");
                                if CustLedgerEntry.FindFirst() then begin
                                    CustLedgerEntry1.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
                                    if CustLedgerEntry1.FindSet() then
                                        repeat
                                            TempWHTEntry.Reset();
                                            TempWHTEntry.SetRange("Document Type", CustLedgerEntry1."Document Type");
                                            TempWHTEntry.SetRange("Document No.", CustLedgerEntry1."Document No.");
                                            TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                            TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                            if TempWHTEntry.FindFirst() then begin
                                                WHTEntry."Remaining Unrealized Amount" :=
                                                  TempWHTEntry."Unrealized Amount" + WHTEntry."Unrealized Amount";
                                                WHTEntry."Remaining Unrealized Base" :=
                                                  TempWHTEntry."Unrealized Base" + WHTEntry."Unrealized Base";
                                                TempWHTEntry."Remaining Unrealized Amount" := 0;
                                                TempWHTEntry."Remaining Unrealized Base" := 0;
                                                TempWHTEntry.Closed := true;
                                                TempWHTEntry."Applies-to Entry No." := WHTEntry."Entry No.";
                                                TempWHTEntry.Modify();
                                            end;
                                        until CustLedgerEntry1.Next() = 0;

                                    if CustLedgerEntry."Closed by Entry No." <> 0 then begin
                                        CustLedgerEntry1.Reset();
                                        CustLedgerEntry1.SetRange("Entry No.", CustLedgerEntry."Closed by Entry No.");
                                        if CustLedgerEntry1.FindFirst() then begin
                                            TempWHTEntry.Reset();
                                            TempWHTEntry.SetRange("Document Type", CustLedgerEntry1."Document Type");
                                            TempWHTEntry.SetRange("Document No.", CustLedgerEntry1."Document No.");
                                            TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                            TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                            if TempWHTEntry.FindFirst() then
                                                if Abs(WHTEntry."Remaining Unrealized Amount") <=
                                                   Abs(TempWHTEntry."Remaining Unrealized Amount")
                                                then begin
                                                    TempWHTEntry."Remaining Unrealized Amount" :=
                                                      TempWHTEntry."Remaining Unrealized Amount" +
                                                      WHTEntry."Remaining Unrealized Amount";
                                                    TempWHTEntry."Remaining Unrealized Base" :=
                                                      TempWHTEntry."Remaining Unrealized Base" +
                                                      WHTEntry."Remaining Unrealized Base";
                                                    TempWHTEntry.Modify();
                                                    WHTEntry."Remaining Unrealized Amount" := 0;
                                                    WHTEntry."Remaining Unrealized Base" := 0;
                                                    WHTEntry.Closed := true;
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                                end;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                end else begin
                    if AbsorbBase <> 0 then
                        WHTEntry.Base := AbsorbBase
                    else
                        WHTEntry.Base := AmountVAT;
                    WHTEntry."Unrealized Amount" := 0;
                    WHTEntry."Unrealized Base" := 0;
                    WHTEntry."Remaining Unrealized Amount" := 0;
                    WHTEntry."Remaining Unrealized Base" := 0;
                    WHTEntry.Amount := Round(WHTEntry.Base * WHTEntry."WHT %" / 100);
                    WHTEntry."Rem Realized Amount" := WHTEntry.Amount;
                    WHTEntry."Rem Realized Base" := WHTEntry.Base;
                    WHTEntry."Original Document No." := DocNo;
                    WHTEntry."WHT Report" := WHTPostingSetup."WHT Report";
                    if ((WHTReportLineNo = '') and
                        (WHTPostingSetup."WHT Report Line No. Series" <> ''))
                    then
                        WHTEntry."WHT Report Line No" := NoSeries.GetNextNo(WHTPostingSetup."WHT Report Line No. Series", WHTEntry."Posting Date");

                    if TransType = TransType::Purchase then begin
                        if ((WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice) or
                            (WHTEntry."Document Type" = WHTEntry."Document Type"::Payment))
                        then begin
                            WHTEntry.Base := Abs(WHTEntry.Base);
                            WHTEntry.Amount := Abs(WHTEntry.Amount);
                            WHTEntry."Payment Amount" := Abs(Amount);
                            WHTEntry."Rem Realized Base" := WHTEntry.Base;
                            WHTEntry."Rem Realized Amount" := WHTEntry.Amount;
                            if (WHTPostingSetup."Realized WHT Type" =
                                WHTPostingSetup."Realized WHT Type"::Earliest)
                            then
                                if WHTEntry."Applies-to Doc. No." <> '' then begin
                                    TempWHTEntry.Reset();
                                    // TempWHTEntry.SETRANGE(Settled,FALSE);
                                    TempWHTEntry.SetRange("Document Type", WHTEntry."Applies-to Doc. Type");
                                    TempWHTEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                    if WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice then
                                        TempWHTEntry.SetRange(
                                          "Document Type",
                                          TempWHTEntry."Document Type"::Payment,
                                          TempWHTEntry."Document Type"::"Credit Memo");

                                    if WHTEntry."Document Type" = WHTEntry."Document Type"::Payment then
                                        TempWHTEntry.SetFilter(
                                          "Document Type",
                                          '%1|%2',
                                          TempWHTEntry."Document Type"::Invoice,
                                          TempWHTEntry."Document Type"::Refund);

                                    if TempWHTEntry.FindFirst() then
                                        if TempWHTEntry.Prepayment then begin
                                            PaymentAmount1 := WHTEntry.Base;
                                            WHTEntry3.Reset();
                                            WHTEntry3 := TempWHTEntry;

                                            PurchCrMemoHeader.Reset();
                                            PurchCrMemoHeader.SetRange("Applies-to Doc. No.", WHTEntry."Applies-to Doc. No.");
                                            PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                                            if PurchCrMemoHeader.FindFirst() then begin
                                                TempRemAmt := 0;
                                                VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                                VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                                if VendLedgEntry1.FindFirst() then
                                                    VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                                WHTEntryTemp.Reset();
                                                WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                if WHTEntryTemp.FindFirst() then begin
                                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                                end;
                                            end;

                                            VendLedgEntry.Reset();
                                            VendLedgEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                                            if WHTEntry."Applies-to Doc. Type" = WHTEntry."Applies-to Doc. Type"::Invoice then
                                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
                                            else
                                                if WHTEntry."Applies-to Doc. Type" = WHTEntry."Applies-to Doc. Type"::"Credit Memo" then
                                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                                            if VendLedgEntry.FindFirst() then
                                                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                                            ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                                            if VendLedgEntry1."Amount (LCY)" = 0 then
                                                VendLedgEntry1."Rem. Amt" := 0;
                                            if (WHTEntry."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                               (Abs(PaymentAmount1) >=
                                                (Abs(VendLedgEntry."Rem. Amt" + VendLedgEntry1."Rem. Amt") -
                                                 Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                                            then begin
                                                AppldAmount :=
                                                  Round(
                                                    ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                                     (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                    ExpectedAmount);
                                                WHTEntry3."Remaining Unrealized Base" :=
                                                  Round(
                                                    TempWHTEntry."Remaining Unrealized Base" -
                                                    Round(
                                                      ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                                       (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                      ExpectedAmount));
                                                WHTEntry3."Remaining Unrealized Amount" :=
                                                  Round(
                                                    TempWHTEntry."Remaining Unrealized Amount" -
                                                    Round(
                                                      ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                                       (TempWHTEntry."Unrealized Amount" + TempRemBase)) /
                                                      ExpectedAmount));
                                            end else begin
                                                AppldAmount :=
                                                  Round(
                                                    (PaymentAmount1 * (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                    ExpectedAmount);
                                                WHTEntry3."Remaining Unrealized Base" :=
                                                  Round(
                                                    TempWHTEntry."Remaining Unrealized Base" -
                                                    Round(
                                                      (PaymentAmount1 * (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                      ExpectedAmount));
                                                WHTEntry3."Remaining Unrealized Amount" :=
                                                  Round(
                                                    TempWHTEntry."Remaining Unrealized Amount" -
                                                    Round(
                                                      (PaymentAmount1 * (TempWHTEntry."Unrealized Amount" + TempRemBase)) /
                                                      ExpectedAmount));
                                            end;
                                            WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                            WHTEntry."Unrealized WHT Entry No." := TempWHTEntry."Entry No.";
                                            WHTEntry."WHT %" := TempWHTEntry."WHT %";
                                            WHTEntry.Base := Round(AppldAmount);
                                            WHTEntry.Amount := Round(WHTEntry.Base * WHTEntry."WHT %" / 100);
                                            WHTEntry."Payment Amount" := PaymentAmount1;
                                            WHTEntry."Rem Realized Base" := 0;
                                            WHTEntry."Rem Realized Amount" := 0;

                                            if CurrencyCode = '' then begin
                                                WHTEntry3."Rem Unrealized Amount (LCY)" :=
                                                  TempWHTEntry."Rem Unrealized Amount (LCY)" - WHTEntry.Amount;
                                                WHTEntry3."Rem Unrealized Base (LCY)" :=
                                                  TempWHTEntry."Rem Unrealized Base (LCY)" - WHTEntry.Base;
                                            end else begin
                                                WHTEntry3."Rem Unrealized Amount (LCY)" := TempWHTEntry."Rem Unrealized Amount (LCY)" -
                                                  Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry.Amount, CurrFactor));
                                                WHTEntry3."Rem Unrealized Base (LCY)" := TempWHTEntry."Rem Unrealized Base (LCY)" -
                                                  Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry.Base, CurrFactor));
                                            end;
                                            if (WHTEntry3."Remaining Unrealized Base" = 0) and (WHTEntry3."Remaining Unrealized Amount" = 0) then
                                                WHTEntry3.Closed := true;
                                            WHTEntry3.Modify();
                                        end else begin
                                            if WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice then begin
                                                if Abs(TempWHTEntry."Rem Realized Amount") >= Abs(WHTEntry.Amount) then begin
                                                    if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo") or
                                                        (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Refund))
                                                    then begin
                                                        TempWHTEntry."Rem Realized Base" :=
                                                          TempWHTEntry."Rem Realized Base" + WHTEntry.Base;
                                                        TempWHTEntry."Rem Realized Amount" :=
                                                          TempWHTEntry."Rem Realized Amount" + WHTEntry.Amount;
                                                    end else begin
                                                        TempWHTEntry."Rem Realized Base" :=
                                                          TempWHTEntry."Rem Realized Base" - WHTEntry.Base;
                                                        TempWHTEntry."Rem Realized Amount" :=
                                                          TempWHTEntry."Rem Realized Amount" - WHTEntry.Amount;
                                                        WHTEntry.Amount := 0;
                                                    end;

                                                    if CurrencyCode = '' then begin
                                                        TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                        TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                    end else begin
                                                        TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                          Round(
                                                            CurrExchRate.ExchangeAmtFCYToLCY(
                                                              DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount", CurrFactor));
                                                        TempWHTEntry."Rem Realized Base (LCY)" :=
                                                          Round(
                                                            CurrExchRate.ExchangeAmtFCYToLCY(
                                                              DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base", CurrFactor));
                                                    end;
                                                end else begin
                                                    if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo") or
                                                        (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Refund))
                                                    then begin
                                                        WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                        WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                    end else begin
                                                        WHTEntry.Base := WHTEntry.Base - TempWHTEntry."Rem Realized Base";
                                                        WHTEntry.Amount := WHTEntry.Amount - TempWHTEntry."Rem Realized Amount";
                                                        WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - TempWHTEntry."Rem Realized Base";
                                                        WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" - TempWHTEntry."Rem Realized Amount";
                                                    end;
                                                    TempWHTEntry."Rem Realized Base" := 0;
                                                    TempWHTEntry."Rem Realized Amount" := 0;
                                                    TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                    TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                end;
                                            end else begin
                                                TotAmt := 0;
                                                TotAmt := TempGenJnlLine.Amount;
                                                VendLedgerEntry.Reset();
                                                VendLedgerEntry.SetRange("Document No.", TempWHTEntry."Document No.");
                                                VendLedgerEntry.SetRange("Document Type", TempWHTEntry."Document Type");
                                                if VendLedgerEntry.FindFirst() then begin
                                                    TempVendLedgEntry.Reset();
                                                    TempVendLedgEntry.SetRange("Entry No.", VendLedgerEntry."Entry No.");
                                                    if TempVendLedgEntry.FindSet() then begin
                                                        TempVendLedgEntry.CalcFields(
                                                          Amount, "Amount (LCY)",
                                                          "Remaining Amount", "Remaining Amt. (LCY)");

                                                        if ((WHTEntry."Document Type" = WHTEntry."Document Type"::Payment) and
                                                            (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Invoice))
                                                        then
                                                            if CheckPmtDisc(
                                                                 TempGenJnlLine."Posting Date",
                                                                 TempVendLedgEntry."Pmt. Discount Date",
                                                                 Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                                                                 Abs(TempVendLedgEntry."Rem. Amt"),
                                                                 Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                                                 Abs(TotAmt))
                                                            then
                                                                TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                                                        if Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt) then begin
                                                            if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo") or
                                                                (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Refund))
                                                            then begin
                                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                                WHTEntry."Rem Realized Amount" :=
                                                                  WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                            end else
                                                                if CheckPmtDisc(
                                                                     TempGenJnlLine."Posting Date",
                                                                     TempVendLedgEntry."Pmt. Discount Date",
                                                                     Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                                                                     Abs(TempVendLedgEntry."Rem. Amt"),
                                                                     Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                                                     Abs(TotAmt))
                                                                then begin
                                                                    WHTEntry.Base := (WHTEntry.Base -
                                                                                      Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                                        TempVendLedgEntry."Original Pmt. Disc. Possible")) - Abs(TempWHTEntry.Amount);
                                                                    WHTEntry.Amount :=
                                                                      Round(WHTEntry.Base * WHTEntry."WHT %" / 100);
                                                                    WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" -
                                                                      Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                        TempVendLedgEntry."Original Pmt. Disc. Possible" - TempWHTEntry.Amount);
                                                                    WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" -
                                                                      Round(Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                          TempVendLedgEntry."Original Pmt. Disc. Possible" - TempWHTEntry.Amount) *
                                                                        WHTEntry."WHT %" / 100);
                                                                end else begin
                                                                    WHTEntry.Base := (WHTEntry.Base -
                                                                                      Abs(TempVendLedgEntry."Rem. Amt for WHT")) - Abs(TempWHTEntry.Amount);
                                                                    WHTEntry.Amount :=
                                                                      Round(WHTEntry.Base * WHTEntry."WHT %" / 100);
                                                                    WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" -
                                                                      Abs(TempVendLedgEntry."Rem. Amt for WHT" - TempWHTEntry.Amount);
                                                                    WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" -
                                                                      Round(Abs(TempVendLedgEntry."Rem. Amt for WHT" - TempWHTEntry.Amount) * WHTEntry."WHT %" / 100);
                                                                end;
                                                            TempWHTEntry."Rem Realized Base" := 0;
                                                            TempWHTEntry."Rem Realized Amount" := 0;
                                                            TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                        end else begin
                                                            if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo") or
                                                                (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Refund))
                                                            then begin
                                                                TempWHTEntry."Rem Realized Base" :=
                                                                  TempWHTEntry."Rem Realized Base" + WHTEntry.Base;
                                                                TempWHTEntry."Rem Realized Amount" :=
                                                                  TempWHTEntry."Rem Realized Amount" + WHTEntry.Amount;
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Base" :=
                                                                  TempWHTEntry."Rem Realized Base" - TotAmt;
                                                                TempWHTEntry."Rem Realized Amount" :=
                                                                  TempWHTEntry."Rem Realized Amount" - Round(Abs(TotAmt) * WHTEntry."WHT %" / 100);
                                                                WHTEntry.Amount := 0;
                                                            end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base", CurrFactor));
                                                            end;
                                                            TotAmt := 0;
                                                        end;
                                                    end;
                                                end;
                                            end;

                                            if (TempWHTEntry."Rem Realized Amount" = 0) and
                                               (TempWHTEntry."Rem Realized Base" = 0)
                                            then
                                                TempWHTEntry.Closed := true;
                                            TempWHTEntry.Modify();
                                        end;
                                end else
                                    if "Applies-toID" <> '' then begin
                                        if WHTEntry."Document Type" = WHTEntry."Document Type"::Payment then begin
                                            TotAmt := 0;
                                            RemainingAmt := 0;
                                            TempVendLedgEntry1.Reset();
                                            TempVendLedgEntry1.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                                            if TempVendLedgEntry1.FindSet(true, false) then
                                                repeat
                                                    TempVendLedgEntry1.CalcFields(
                                                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
                                                      "Original Amount", "Original Amt. (LCY)");
                                                    if TempVendLedgEntry1."Rem. Amt for WHT" = 0 then
                                                        TempVendLedgEntry1."Rem. Amt for WHT" := TempVendLedgEntry1."Remaining Amt. (LCY)";
                                                    RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
                                                until TempVendLedgEntry1.Next() = 0;
                                            TotAmt := Abs(TempGenJnlLine.Amount);
                                            VendLedgerEntry.Reset();
                                            VendLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                            VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Refund);
                                            if VendLedgerEntry.FindSet() then begin
                                                TotalWHTBase := WHTEntry."Rem Realized Base";
                                                TotalWHT := WHTEntry."Rem Realized Amount";
                                                repeat
                                                    TempWHTEntry.Reset();
                                                    TempWHTEntry.SetRange(Settled, false);
                                                    TempWHTEntry.SetRange("Document No.", VendLedgerEntry."Document No.");
                                                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                    if TempWHTEntry.FindFirst() then begin
                                                        if Abs(TotalWHT) > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                            WHTEntry."Rem Realized Base" :=
                                                              WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                            WHTEntry."Rem Realized Amount" :=
                                                              WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                            TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                            TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                            TempWHTEntry."Rem Realized Base" := 0;
                                                            TempWHTEntry."Rem Realized Amount" := 0;
                                                            TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                        end else
                                                            if (Abs(TotalWHT) > 0) and (Abs(TotalWHT) <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                TempWHTEntry."Rem Realized Base" :=
                                                                  TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                                TempWHTEntry."Rem Realized Amount" :=
                                                                  TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                                WHTEntry."Rem Realized Amount" := 0;
                                                                WHTEntry."Rem Realized Base" := 0;
                                                                TotalWHTBase := 0;
                                                                TotalWHT := 0;
                                                            end;

                                                        if CurrencyCode = '' then begin
                                                            TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                        end else begin
                                                            TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                            TempWHTEntry."Rem Realized Base (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                        end;
                                                        if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                            (TempWHTEntry."Rem Realized Base" = 0))
                                                        then
                                                            TempWHTEntry.Closed := true;
                                                        TempWHTEntry.Modify();
                                                    end;
                                                until VendLedgerEntry.Next() = 0;
                                                WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                            end;

                                            VendLedgerEntry.Reset();
                                            VendLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                            VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
                                            if VendLedgerEntry.FindSet() then begin
                                                TotalWHTBase := WHTEntry."Rem Realized Base";
                                                TotalWHT := WHTEntry."Rem Realized Amount";
                                                repeat
                                                    if VendLedgerEntry.Prepayment then begin
                                                        TempVendLedgEntry.Reset();
                                                        TempVendLedgEntry.SetRange("Entry No.", VendLedgerEntry."Entry No.");
                                                        if TempVendLedgEntry.FindFirst() then begin
                                                            TempVendLedgEntry.CalcFields(
                                                              Amount, "Amount (LCY)",
                                                              "Remaining Amount", "Remaining Amt. (LCY)");

                                                            if CheckPmtDisc(
                                                                 TempGenJnlLine."Posting Date",
                                                                 TempVendLedgEntry."Pmt. Discount Date",
                                                                 Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                                                                 Abs(TempVendLedgEntry."Rem. Amt"),
                                                                 Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                                                 Abs(TotAmt))
                                                            then
                                                                TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                                                            if (Abs(RemainingAmt) < Abs(TotAmt)) or
                                                               (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                                                            then begin
                                                                if CheckPmtDisc(
                                                                     TempGenJnlLine."Posting Date",
                                                                     TempVendLedgEntry."Pmt. Discount Date",
                                                                     Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                                                                     Abs(TempVendLedgEntry."Rem. Amt"),
                                                                     Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                                                     Abs(TotAmt))
                                                                then begin
                                                                    TempGenJnlLine.Validate(
                                                                      Amount,
                                                                      Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                        TempVendLedgEntry."Original Pmt. Disc. Possible"));

                                                                    if TempVendLedgEntry."Document Type" <>
                                                                       TempVendLedgEntry."Document Type"::"Credit Memo"
                                                                    then
                                                                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";

                                                                    RemainingAmt :=
                                                                      RemainingAmt -
                                                                      TempVendLedgEntry."Rem. Amt for WHT";
                                                                end else begin
                                                                    TempGenJnlLine.Validate(Amount, Abs(TempVendLedgEntry."Rem. Amt for WHT"));
                                                                    if TempVendLedgEntry."Document Type" <>
                                                                       TempVendLedgEntry."Document Type"::"Credit Memo"
                                                                    then
                                                                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                                                                    RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                                                                end;
                                                            end else begin
                                                                if CheckPmtDisc(
                                                                     TempGenJnlLine."Posting Date",
                                                                     TempVendLedgEntry."Pmt. Discount Date",
                                                                     Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                                                                     Abs(TempVendLedgEntry."Rem. Amt"),
                                                                     Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                                                     Abs(TotAmt))
                                                                then
                                                                    TempGenJnlLine.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                                                                else
                                                                    TempGenJnlLine.Validate(Amount, TotAmt);
                                                                WHTEntry.Amount := 0;
                                                                TotAmt := 0;
                                                            end;

                                                            if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                                                                TempGenJnlLine."Applies-to Doc. Type" := TempGenJnlLine."Applies-to Doc. Type"::Invoice
                                                            else begin
                                                                if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                                                                    TempGenJnlLine."Applies-to Doc. Type" := TempGenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                                                                RemainingAmt := RemainingAmt + TempVendLedgEntry."Rem. Amt for WHT";
                                                                TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                                                            end;
                                                            TempGenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                                                            PaymentAmount1 := TempGenJnlLine.Amount;

                                                            TempWHTEntry.Reset();
                                                            TempWHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
                                                            TempWHTEntry.SetRange("Transaction Type", TempWHTEntry."Transaction Type"::Purchase);
                                                            if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                                                                TempWHTEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                                                                TempWHTEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                                                            end else
                                                                TempWHTEntry.SetRange("Bill-to/Pay-to No.", TempGenJnlLine."Account No.");
                                                            if TempWHTEntry.FindSet() then
                                                                repeat
                                                                    WHTEntry3.Reset();
                                                                    WHTEntry3 := TempWHTEntry;
                                                                    PurchCrMemoHeader.Reset();
                                                                    PurchCrMemoHeader.SetRange("Applies-to Doc. No.", TempGenJnlLine."Applies-to Doc. No.");
                                                                    PurchCrMemoHeader.SetRange(
                                                                      "Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                                                                    if PurchCrMemoHeader.FindFirst() then begin
                                                                        TempRemAmt := 0;
                                                                        VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                                                        VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                                                        if VendLedgEntry1.FindFirst() then
                                                                            VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                                                        WHTEntryTemp.Reset();
                                                                        WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                                                        WHTEntryTemp.SetRange("Document Type", TempWHTEntry."Document Type"::"Credit Memo");
                                                                        WHTEntryTemp.SetRange("Transaction Type", TempWHTEntry."Transaction Type"::Purchase);
                                                                        WHTEntryTemp.SetRange("WHT Bus. Posting Group", TempWHTEntry."WHT Bus. Posting Group");
                                                                        WHTEntryTemp.SetRange("WHT Prod. Posting Group", TempWHTEntry."WHT Prod. Posting Group");
                                                                        if WHTEntryTemp.FindFirst() then begin
                                                                            TempRemBase := WHTEntryTemp."Unrealized Amount";
                                                                            TempRemAmt := WHTEntryTemp."Unrealized Base";
                                                                        end;
                                                                    end;

                                                                    VendLedgEntry.Reset();
                                                                    VendLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                                                                    if TempGenJnlLine."Applies-to Doc. Type" = TempGenJnlLine."Applies-to Doc. Type"::Invoice then
                                                                        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
                                                                    else
                                                                        if TempGenJnlLine."Applies-to Doc. Type" =
                                                                           TempGenJnlLine."Applies-to Doc. Type"::"Credit Memo"
                                                                        then
                                                                            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                                                                    if VendLedgEntry.FindFirst() then
                                                                        VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                                                                    ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                                                                    if VendLedgEntry1."Amount (LCY)" = 0 then
                                                                        VendLedgEntry1."Rem. Amt" := 0;
                                                                    if (TempGenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                                                       (Abs(PaymentAmount1) >=
                                                                        (Abs(VendLedgEntry."Rem. Amt" + VendLedgEntry1."Rem. Amt") -
                                                                         Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                                                                    then begin
                                                                        AppldAmount :=
                                                                          Round(
                                                                            ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                                                             (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                                            ExpectedAmount);
                                                                        WHTEntry3."Remaining Unrealized Base" :=
                                                                          Round(
                                                                            TempWHTEntry."Remaining Unrealized Base" -
                                                                            Round(
                                                                              ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                                                               (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                                              ExpectedAmount));
                                                                        WHTEntry3."Remaining Unrealized Amount" :=
                                                                          Round(
                                                                            TempWHTEntry."Remaining Unrealized Amount" -
                                                                            Round(
                                                                              ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                                                               (TempWHTEntry."Unrealized Amount" + TempRemBase)) /
                                                                              ExpectedAmount));
                                                                    end else begin
                                                                        AppldAmount :=
                                                                          Round(
                                                                            (PaymentAmount1 *
                                                                             (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                                            ExpectedAmount);
                                                                        WHTEntry3."Remaining Unrealized Base" :=
                                                                          Round(
                                                                            TempWHTEntry."Remaining Unrealized Base" -
                                                                            Round(
                                                                              (PaymentAmount1 * (TempWHTEntry."Unrealized Base" + TempRemAmt)) /
                                                                              ExpectedAmount));
                                                                        WHTEntry3."Remaining Unrealized Amount" :=
                                                                          Round(
                                                                            TempWHTEntry."Remaining Unrealized Amount" -
                                                                            Round(
                                                                              (PaymentAmount1 * (TempWHTEntry."Unrealized Amount" + TempRemBase)) /
                                                                              ExpectedAmount));
                                                                    end;

                                                                    InitWHTEntry(TempWHTEntry, AppldAmount, PaymentAmount1, WHTEntry3);
                                                                until TempWHTEntry.Next(-1) = 0;
                                                        end;
                                                    end else begin
                                                        TempWHTEntry.Reset();
                                                        // TempWHTEntry.SETRANGE(Settled,FALSE);
                                                        TempWHTEntry.SetRange("Document No.", VendLedgerEntry."Document No.");
                                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                        if TempWHTEntry.FindFirst() then begin
                                                            TempVendLedgEntry.Reset();
                                                            TempVendLedgEntry.SetRange("Entry No.", VendLedgerEntry."Entry No.");
                                                            if TempVendLedgEntry.FindFirst() then begin
                                                                TempVendLedgEntry.CalcFields(
                                                                  Amount, "Amount (LCY)",
                                                                  "Remaining Amount", "Remaining Amt. (LCY)");

                                                                if CheckPmtDisc(
                                                                     TempGenJnlLine."Posting Date",
                                                                     TempVendLedgEntry."Pmt. Discount Date",
                                                                     Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                                                                     Abs(TempVendLedgEntry."Rem. Amt"),
                                                                     Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                                                     Abs(TotAmt))
                                                                then
                                                                    TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                                                                if (Abs(RemainingAmt) < Abs(TotAmt)) or
                                                                   (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                                                                then begin
                                                                    if CheckPmtDisc(
                                                                         TempGenJnlLine."Posting Date",
                                                                         TempVendLedgEntry."Pmt. Discount Date",
                                                                         Abs(TempVendLedgEntry."Rem. Amt for WHT"),
                                                                         Abs(TempVendLedgEntry."Rem. Amt"),
                                                                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                                                         Abs(TotAmt))
                                                                    then begin
                                                                        if TempVendLedgEntry."Document Type" <>
                                                                           TempVendLedgEntry."Document Type"::"Credit Memo"
                                                                        then
                                                                            TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";

                                                                        RemainingAmt :=
                                                                          RemainingAmt -
                                                                          TempVendLedgEntry."Rem. Amt for WHT" +
                                                                          TempVendLedgEntry."Original Pmt. Disc. Possible";

                                                                        WHTEntry.Base := WHTEntry.Base -
                                                                          Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                            TempVendLedgEntry."Original Pmt. Disc. Possible");
                                                                        WHTEntry.Amount := WHTEntry.Amount -
                                                                          Round(Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                              TempVendLedgEntry."Original Pmt. Disc. Possible") * WHTEntry."WHT %" / 100);
                                                                        WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" -
                                                                          Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                            TempVendLedgEntry."Original Pmt. Disc. Possible");
                                                                        WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" -
                                                                          Round(Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                                                              TempVendLedgEntry."Original Pmt. Disc. Possible") * WHTEntry."WHT %" / 100);
                                                                    end else begin
                                                                        if TempVendLedgEntry."Document Type" <>
                                                                           TempVendLedgEntry."Document Type"::"Credit Memo"
                                                                        then
                                                                            TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                                                                        RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";

                                                                        WHTEntry.Base := WHTEntry.Base -
                                                                          Abs(TempVendLedgEntry."Rem. Amt for WHT");
                                                                        WHTEntry.Amount := WHTEntry.Amount -
                                                                          Round(Abs(TempVendLedgEntry."Rem. Amt for WHT") * WHTEntry."WHT %" / 100);
                                                                        WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" -
                                                                          Abs(TempVendLedgEntry."Rem. Amt for WHT");
                                                                        WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" -
                                                                          Round(Abs(TempVendLedgEntry."Rem. Amt for WHT") * WHTEntry."WHT %" / 100);
                                                                    end;
                                                                    TempWHTEntry."Rem Realized Base" := 0;
                                                                    TempWHTEntry."Rem Realized Amount" := 0;
                                                                    TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                                    TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                                end else begin
                                                                    TempWHTEntry."Rem Realized Base" :=
                                                                      TempWHTEntry."Rem Realized Base" - TotAmt;
                                                                    TempWHTEntry."Rem Realized Amount" :=
                                                                      TempWHTEntry."Rem Realized Amount" -
                                                                      Round(Abs(TotAmt) * WHTEntry."WHT %" / 100);
                                                                    WHTEntry.Amount := 0;
                                                                    TotAmt := 0;
                                                                end;
                                                            end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                            end;
                                                            if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                                (TempWHTEntry."Rem Realized Base" = 0))
                                                            then
                                                                TempWHTEntry.Closed := true;
                                                            TempWHTEntry.Modify();
                                                        end;
                                                    end;
                                                until VendLedgerEntry.Next() = 0;
                                                if TotAmt > 0 then begin
                                                    WHTEntry.Base := TotAmt;
                                                    WHTEntry.Amount := Round(TotAmt * WHTPostingSetup."WHT %" / 100);
                                                    WHTEntry."Rem Realized Amount" := WHTEntry.Amount;
                                                    WHTEntry."Rem Realized Base" := WHTEntry.Base;
                                                    WHTEntry."Entry No." := NextEntryNo();
                                                end else
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                            end;
                                        end;

                                        if WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice then begin
                                            VendLedgerEntry.Reset();
                                            VendLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                            VendLedgerEntry.SetFilter(
                                              "Document Type",
                                              '%1|%2',
                                              VendLedgerEntry."Document Type"::Payment,
                                              VendLedgerEntry."Document Type"::"Credit Memo");
                                            if VendLedgerEntry.FindSet() then begin
                                                TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                repeat
                                                    TempWHTEntry.Reset();
                                                    TempWHTEntry.SetRange(Settled, false);
                                                    TempWHTEntry.SetRange("Document No.", VendLedgerEntry."Document No.");
                                                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                    if TempWHTEntry.FindFirst() then begin
                                                        if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                            if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment then begin
                                                                WHTEntry.Base := WHTEntry.Base - Abs(TempWHTEntry."Rem Realized Base");
                                                                WHTEntry.Amount := WHTEntry.Amount - Abs(TempWHTEntry."Rem Realized Amount");
                                                            end;
                                                            WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - Abs(TempWHTEntry."Rem Realized Base");
                                                            WHTEntry."Rem Realized Amount" :=
                                                              WHTEntry."Rem Realized Amount" - Abs(TempWHTEntry."Rem Realized Amount");
                                                            WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - Abs(TempWHTEntry."Rem Realized Base");
                                                            WHTEntry."Rem Realized Amount" :=
                                                              WHTEntry."Rem Realized Amount" - Abs(TempWHTEntry."Rem Realized Amount");
                                                            TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                            TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                            TempWHTEntry."Rem Realized Base" := 0;
                                                            TempWHTEntry."Rem Realized Amount" := 0;
                                                            TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                        end else
                                                            if (TotalWHT > 0) and (TotalWHT <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo" then begin
                                                                    TempWHTEntry."Rem Realized Base" :=
                                                                      TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                                    TempWHTEntry."Rem Realized Amount" :=
                                                                      TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                                end else begin
                                                                    TempWHTEntry."Rem Realized Base" :=
                                                                      TempWHTEntry."Rem Realized Base" - TotalWHTBase;
                                                                    TempWHTEntry."Rem Realized Amount" :=
                                                                      TempWHTEntry."Rem Realized Amount" - TotalWHT;
                                                                    WHTEntry.Base := 0;
                                                                    WHTEntry.Amount := 0;
                                                                end;
                                                                WHTEntry."Rem Realized Amount" := 0;
                                                                WHTEntry."Rem Realized Base" := 0;
                                                                TotalWHTBase := 0;
                                                                TotalWHT := 0;
                                                            end;

                                                        if CurrencyCode = '' then begin
                                                            TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                        end else begin
                                                            TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                            TempWHTEntry."Rem Realized Base (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                        end;
                                                        if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                            (TempWHTEntry."Rem Realized Base" = 0))
                                                        then
                                                            TempWHTEntry.Closed := true;
                                                        TempWHTEntry.Modify();
                                                    end;
                                                until VendLedgerEntry.Next() = 0;
                                                WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                            end;
                                        end;
                                    end;
                        end;

                        // Purchase Credit Memo & Refund
                        if ((WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo") or
                            (WHTEntry."Document Type" = WHTEntry."Document Type"::Refund))
                        then begin
                            WHTEntry.Base := -Abs(WHTEntry.Base);
                            WHTEntry.Amount := -Abs(WHTEntry.Amount);
                            WHTEntry."Payment Amount" := -Abs(Amount);
                            WHTEntry."Rem Realized Base" := WHTEntry.Base;
                            WHTEntry."Rem Realized Amount" := WHTEntry.Amount;
                            if (WHTPostingSetup."Realized WHT Type" =
                                WHTPostingSetup."Realized WHT Type"::Earliest)
                            then
                                if WHTEntry."Applies-to Doc. No." <> '' then begin
                                    TempWHTEntry.Reset();
                                    // TempWHTEntry.SETRANGE(Settled,FALSE);
                                    TempWHTEntry.SetRange("Document Type", WHTEntry."Applies-to Doc. Type");
                                    TempWHTEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                    if WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo" then
                                        TempWHTEntry.SetFilter(
                                          "Document Type",
                                          '%1|%2',
                                          TempWHTEntry."Document Type"::Refund,
                                          TempWHTEntry."Document Type"::Invoice);

                                    if WHTEntry."Document Type" = WHTEntry."Document Type"::Refund then
                                        TempWHTEntry.SetFilter(
                                          "Document Type",
                                          '%1|%2',
                                          TempWHTEntry."Document Type"::"Credit Memo",
                                          TempWHTEntry."Document Type"::Payment);

                                    if TempWHTEntry.FindFirst() then begin
                                        if Abs(TempWHTEntry."Rem Realized Amount") >= Abs(WHTEntry.Amount) then begin
                                            if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Invoice) or
                                                (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment))
                                            then begin
                                                TempWHTEntry."Rem Realized Base" :=
                                                  TempWHTEntry."Rem Realized Base" + WHTEntry.Base;
                                                TempWHTEntry."Rem Realized Amount" :=
                                                  TempWHTEntry."Rem Realized Amount" + WHTEntry.Amount;
                                                WHTEntry."Rem Realized Base" := 0;
                                                WHTEntry."Rem Realized Amount" := 0;
                                            end else begin
                                                TempWHTEntry."Rem Realized Base" :=
                                                  TempWHTEntry."Rem Realized Base" - WHTEntry.Base;
                                                TempWHTEntry."Rem Realized Amount" :=
                                                  TempWHTEntry."Rem Realized Amount" - WHTEntry.Amount;
                                                WHTEntry.Amount := 0;
                                            end;

                                            if CurrencyCode = '' then begin
                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                            end else begin
                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                  Round(
                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                  Round(
                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                            end;
                                        end else begin
                                            if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Invoice) or
                                                (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment))
                                            then begin
                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                            end else begin
                                                WHTEntry.Base := WHTEntry.Base - TempWHTEntry."Rem Realized Base";
                                                WHTEntry.Amount := WHTEntry.Amount - TempWHTEntry."Rem Realized Amount";
                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - TempWHTEntry."Rem Realized Base";
                                                WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" - TempWHTEntry."Rem Realized Amount";
                                            end;
                                            TempWHTEntry."Rem Realized Base" := 0;
                                            TempWHTEntry."Rem Realized Amount" := 0;
                                            TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                            TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                        end;

                                        if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                            (TempWHTEntry."Rem Realized Base" = 0))
                                        then
                                            TempWHTEntry.Closed := true;
                                        TempWHTEntry.Modify();
                                    end
                                    else
                                        if "Applies-toID" <> '' then begin
                                            if WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo" then begin
                                                VendLedgerEntry.Reset();
                                                VendLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                                VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Refund);
                                                if VendLedgerEntry.FindSet() then begin
                                                    TotalWHTBase := WHTEntry."Rem Realized Base";
                                                    TotalWHT := WHTEntry."Rem Realized Amount";
                                                    repeat
                                                        TempWHTEntry.Reset();
                                                        TempWHTEntry.SetRange(Settled, false);
                                                        TempWHTEntry.SetRange("Document No.", VendLedgerEntry."Document No.");
                                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                        if TempWHTEntry.FindFirst() then begin
                                                            if Abs(TotalWHT) > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                                WHTEntry.Base := WHTEntry.Base + TempWHTEntry."Rem Realized Base";
                                                                WHTEntry.Amount := WHTEntry.Amount + TempWHTEntry."Rem Realized Amount";
                                                                WHTEntry."Rem Realized Base" :=
                                                                  WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                                WHTEntry."Rem Realized Amount" :=
                                                                  WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                                TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                                TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                                TempWHTEntry."Rem Realized Base" := 0;
                                                                TempWHTEntry."Rem Realized Amount" := 0;
                                                                TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                            end else
                                                                if (Abs(TotalWHT) > 0) and (Abs(TotalWHT) <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                    TempWHTEntry."Rem Realized Base" :=
                                                                      TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                                    TempWHTEntry."Rem Realized Amount" :=
                                                                      TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                                    WHTEntry.Base := 0;
                                                                    WHTEntry.Amount := 0;
                                                                    WHTEntry."Rem Realized Amount" := 0;
                                                                    WHTEntry."Rem Realized Base" := 0;
                                                                    TotalWHTBase := 0;
                                                                    TotalWHT := 0;
                                                                end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                            end;
                                                            if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                                (TempWHTEntry."Rem Realized Base" = 0))
                                                            then
                                                                TempWHTEntry.Closed := true;
                                                            TempWHTEntry.Modify();
                                                        end;
                                                    until VendLedgerEntry.Next() = 0;
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                                end;

                                                VendLedgerEntry.Reset();
                                                VendLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                                VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
                                                if VendLedgerEntry.FindSet() then begin
                                                    TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                    TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                    repeat
                                                        TempWHTEntry.Reset();
                                                        TempWHTEntry.SetRange(Settled, false);
                                                        TempWHTEntry.SetRange("Document No.", VendLedgerEntry."Document No.");
                                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                        if TempWHTEntry.FindFirst() then begin
                                                            if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                                WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                                TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                                TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                                TempWHTEntry."Rem Realized Base" := 0;
                                                                TempWHTEntry."Rem Realized Amount" := 0;
                                                                TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                            end else
                                                                if (TotalWHT > 0) and (Abs(TotalWHT) <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                    TempWHTEntry."Rem Realized Base" :=
                                                                      TempWHTEntry."Rem Realized Base" - TotalWHTBase;
                                                                    TempWHTEntry."Rem Realized Amount" :=
                                                                      TempWHTEntry."Rem Realized Amount" - TotalWHT;
                                                                    WHTEntry."Rem Realized Amount" := 0;
                                                                    WHTEntry."Rem Realized Base" := 0;
                                                                    TotalWHTBase := 0;
                                                                    TotalWHT := 0;
                                                                end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                            end;
                                                            if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                                (TempWHTEntry."Rem Realized Base" = 0))
                                                            then
                                                                TempWHTEntry.Closed := true;
                                                            TempWHTEntry.Modify();
                                                        end;
                                                    until VendLedgerEntry.Next() = 0;
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                                end;
                                            end;

                                            if WHTEntry."Document Type" = WHTEntry."Document Type"::Refund then begin
                                                VendLedgerEntry.Reset();
                                                VendLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                                VendLedgerEntry.SetFilter(
                                                  "Document Type",
                                                  '%1|%2',
                                                  VendLedgerEntry."Document Type"::Payment,
                                                  VendLedgerEntry."Document Type"::"Credit Memo");
                                                if VendLedgerEntry.FindSet() then begin
                                                    TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                    TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                    repeat
                                                        TempWHTEntry.Reset();
                                                        TempWHTEntry.SetRange(Settled, false);
                                                        TempWHTEntry.SetRange("Document No.", VendLedgerEntry."Document No.");
                                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                        if TempWHTEntry.FindFirst() then begin
                                                            if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                                if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo" then begin
                                                                    WHTEntry.Base := WHTEntry.Base + Abs(TempWHTEntry."Rem Realized Base");
                                                                    WHTEntry.Amount := WHTEntry.Amount + Abs(TempWHTEntry."Rem Realized Amount");
                                                                end;
                                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + Abs(TempWHTEntry."Rem Realized Base");
                                                                WHTEntry."Rem Realized Amount" :=
                                                                  WHTEntry."Rem Realized Amount" + Abs(TempWHTEntry."Rem Realized Amount");
                                                                TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                                TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                                TempWHTEntry."Rem Realized Base" := 0;
                                                                TempWHTEntry."Rem Realized Amount" := 0;
                                                                TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                            end else
                                                                if (TotalWHT > 0) and (TotalWHT <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                    if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment then begin
                                                                        TempWHTEntry."Rem Realized Base" :=
                                                                          TempWHTEntry."Rem Realized Base" - TotalWHTBase;
                                                                        TempWHTEntry."Rem Realized Amount" :=
                                                                          TempWHTEntry."Rem Realized Amount" - TotalWHT;
                                                                    end else begin
                                                                        TempWHTEntry."Rem Realized Base" :=
                                                                          TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                                        TempWHTEntry."Rem Realized Amount" :=
                                                                          TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                                        WHTEntry.Base := 0;
                                                                        WHTEntry.Amount := 0;
                                                                    end;
                                                                    WHTEntry."Rem Realized Amount" := 0;
                                                                    WHTEntry."Rem Realized Base" := 0;
                                                                    TotalWHTBase := 0;
                                                                    TotalWHT := 0;
                                                                end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                            end;
                                                            if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                                (TempWHTEntry."Rem Realized Base" = 0))
                                                            then
                                                                TempWHTEntry.Closed := true;
                                                            TempWHTEntry.Modify();
                                                        end;
                                                    until VendLedgerEntry.Next() = 0;
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                                end;
                                            end;
                                        end;
                                end;
                        end;
                    end;

                    if TransType = TransType::Sale then begin
                        if ((WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice) or
                            (WHTEntry."Document Type" = WHTEntry."Document Type"::Payment))
                        then begin
                            WHTEntry.Base := -Abs(WHTEntry.Base);
                            WHTEntry.Amount := -Abs(WHTEntry.Amount);
                            WHTEntry."Payment Amount" := -Abs(Amount);
                            WHTEntry."Rem Realized Base" := WHTEntry.Base;
                            WHTEntry."Rem Realized Amount" := WHTEntry.Amount;
                            if (WHTPostingSetup."Realized WHT Type" =
                                WHTPostingSetup."Realized WHT Type"::Earliest)
                            then begin
                                if WHTEntry."Applies-to Doc. No." <> '' then begin
                                    CustLedgerEntry.Reset();
                                    CustLedgerEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                                    CustLedgerEntry.SetRange("Document Type", WHTEntry."Applies-to Doc. Type");
                                    CustLedgerEntry.SetRange(Prepayment, false);
                                    if CustLedgerEntry.FindFirst() then begin
                                        TempWHTEntry.Reset();
                                        TempWHTEntry.SetRange(Settled, false);
                                        TempWHTEntry.SetRange("Document Type", WHTEntry."Applies-to Doc. Type");
                                        TempWHTEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                        if WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice then
                                            TempWHTEntry.SetFilter(
                                              "Document Type",
                                              '%1|%2',
                                              TempWHTEntry."Document Type"::Payment,
                                              TempWHTEntry."Document Type"::"Credit Memo");
                                        if WHTEntry."Document Type" = WHTEntry."Document Type"::Payment then
                                            TempWHTEntry.SetFilter(
                                              "Document Type",
                                              '%1|%2',
                                              TempWHTEntry."Document Type"::Invoice,
                                              TempWHTEntry."Document Type"::Refund);

                                        if TempWHTEntry.FindFirst() then begin
                                            if Abs(TempWHTEntry."Rem Realized Amount") >= Abs(WHTEntry.Amount) then begin
                                                if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo") or
                                                    (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Refund))
                                                then begin
                                                    TempWHTEntry."Rem Realized Base" :=
                                                      TempWHTEntry."Rem Realized Base" - WHTEntry.Base;
                                                    TempWHTEntry."Rem Realized Amount" :=
                                                      TempWHTEntry."Rem Realized Amount" - WHTEntry.Amount;
                                                    WHTEntry."Rem Realized Base" := 0;
                                                    WHTEntry."Rem Realized Amount" := 0;
                                                end else begin
                                                    TempWHTEntry."Rem Realized Base" :=
                                                      TempWHTEntry."Rem Realized Base" - WHTEntry.Base;
                                                    TempWHTEntry."Rem Realized Amount" :=
                                                      TempWHTEntry."Rem Realized Amount" - WHTEntry.Amount;
                                                    WHTEntry.Amount := 0;
                                                end;

                                                if CurrencyCode = '' then begin
                                                    TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                    TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                end else begin
                                                    TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                      Round(
                                                        CurrExchRate.ExchangeAmtFCYToLCY(
                                                          DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                    TempWHTEntry."Rem Realized Base (LCY)" :=
                                                      Round(
                                                        CurrExchRate.ExchangeAmtFCYToLCY(
                                                          DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                end;
                                            end else begin
                                                if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo") or
                                                    (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Refund))
                                                then begin
                                                    WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - TempWHTEntry."Rem Realized Base";
                                                    WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" - TempWHTEntry."Rem Realized Amount";
                                                end else begin
                                                    WHTEntry.Base := WHTEntry.Base - TempWHTEntry."Rem Realized Base";
                                                    WHTEntry.Amount := WHTEntry.Amount - TempWHTEntry."Rem Realized Amount";
                                                    WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - TempWHTEntry."Rem Realized Base";
                                                    WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" - TempWHTEntry."Rem Realized Amount";
                                                end;
                                                TempWHTEntry."Rem Realized Base" := 0;
                                                TempWHTEntry."Rem Realized Amount" := 0;
                                                TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                            end;

                                            if (TempWHTEntry."Rem Realized Amount" = 0) and
                                               (TempWHTEntry."Rem Realized Base" = 0)
                                            then
                                                TempWHTEntry.Closed := true;
                                            TempWHTEntry.Modify();
                                        end;
                                    end else
                                        WHTEntry.Amount := 0;
                                end else
                                    if "Applies-toID" <> '' then
                                        if WHTEntry."Document Type" = WHTEntry."Document Type"::Payment then begin
                                            IsRefund := false;
                                            CustLedgerEntry.Reset();
                                            CustLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Refund);
                                            if CustLedgerEntry.FindFirst() then begin
                                                TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                IsRefund := true;
                                                repeat
                                                    TempWHTEntry.Reset();
                                                    TempWHTEntry.SetRange(Settled, false);
                                                    TempWHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                                                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                    if TempWHTEntry.FindFirst() then begin
                                                        if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                            WHTEntry."Rem Realized Base" :=
                                                              WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                            WHTEntry."Rem Realized Amount" :=
                                                              WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                            TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                            TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                            TempWHTEntry."Rem Realized Base" := 0;
                                                            TempWHTEntry."Rem Realized Amount" := 0;
                                                            TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                        end else
                                                            if (TotalWHT > 0) and (Abs(TotalWHT) <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                TempWHTEntry."Rem Realized Base" :=
                                                                  TempWHTEntry."Rem Realized Base" - TotalWHTBase;
                                                                TempWHTEntry."Rem Realized Amount" :=
                                                                  TempWHTEntry."Rem Realized Amount" - TotalWHT;
                                                                WHTEntry."Rem Realized Amount" := 0;
                                                                WHTEntry."Rem Realized Base" := 0;
                                                                TotalWHTBase := 0;
                                                                TotalWHT := 0;
                                                            end;

                                                        if CurrencyCode = '' then begin
                                                            TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                        end else begin
                                                            TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                            TempWHTEntry."Rem Realized Base (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                        end;
                                                        if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                            (TempWHTEntry."Rem Realized Base" = 0))
                                                        then
                                                            TempWHTEntry.Closed := true;
                                                        TempWHTEntry.Modify();
                                                    end;
                                                until CustLedgerEntry.Next() = 0;
                                                WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                            end;

                                            CustLedgerEntry.Reset();
                                            CustLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                                            CustLedgerEntry.SetRange(Prepayment, false);
                                            if CustLedgerEntry.FindSet() then begin
                                                TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                repeat
                                                    TempWHTEntry.Reset();
                                                    TempWHTEntry.SetRange(Settled, false);
                                                    TempWHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                                                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                    if TempWHTEntry.FindFirst() then begin
                                                        if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                            WHTEntry.Base := WHTEntry.Base + TempWHTEntry."Rem Realized Base";
                                                            WHTEntry.Amount := WHTEntry.Amount + TempWHTEntry."Rem Realized Amount";
                                                            WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                            WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                            TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                            TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                            TempWHTEntry."Rem Realized Base" := 0;
                                                            TempWHTEntry."Rem Realized Amount" := 0;
                                                            TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                        end else
                                                            if (TotalWHT > 0) and (Abs(TotalWHT) <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                TempWHTEntry."Rem Realized Base" :=
                                                                  TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                                TempWHTEntry."Rem Realized Amount" :=
                                                                  TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                                WHTEntry.Base := 0;
                                                                WHTEntry.Amount := 0;
                                                                WHTEntry."Rem Realized Amount" := 0;
                                                                WHTEntry."Rem Realized Base" := 0;
                                                                TotalWHTBase := 0;
                                                                TotalWHT := 0;
                                                            end;

                                                        if CurrencyCode = '' then begin
                                                            TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                            TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                        end else begin
                                                            TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                            TempWHTEntry."Rem Realized Base (LCY)" :=
                                                              Round(
                                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                                  DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                        end;
                                                        if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                            (TempWHTEntry."Rem Realized Base" = 0))
                                                        then
                                                            TempWHTEntry.Closed := true;
                                                        TempWHTEntry.Modify();
                                                    end;
                                                until CustLedgerEntry.Next() = 0;
                                                WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                            end else
                                                if not IsRefund then
                                                    WHTEntry.Amount := 0;
                                        end;

                                if WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice then begin
                                    CustLedgerEntry.Reset();
                                    CustLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                    CustLedgerEntry.SetFilter(
                                      "Document Type",
                                      '%1|%2',
                                      CustLedgerEntry."Document Type"::Payment,
                                      CustLedgerEntry."Document Type"::"Credit Memo");
                                    if CustLedgerEntry.FindSet() then begin
                                        TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                        TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                        repeat
                                            TempWHTEntry.Reset();
                                            TempWHTEntry.SetRange(Settled, false);
                                            TempWHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                                            TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                            TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                            if TempWHTEntry.FindFirst() then begin
                                                if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                    if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment then begin
                                                        WHTEntry.Base := WHTEntry.Base + Abs(TempWHTEntry."Rem Realized Base");
                                                        WHTEntry.Amount := WHTEntry.Amount + Abs(TempWHTEntry."Rem Realized Amount");
                                                    end;
                                                    WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + Abs(TempWHTEntry."Rem Realized Base");
                                                    WHTEntry."Rem Realized Amount" :=
                                                      WHTEntry."Rem Realized Amount" + Abs(TempWHTEntry."Rem Realized Amount");
                                                    TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                    TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                    TempWHTEntry."Rem Realized Base" := 0;
                                                    TempWHTEntry."Rem Realized Amount" := 0;
                                                    TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                    TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                end else
                                                    if (TotalWHT > 0) and (TotalWHT <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                        if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo" then begin
                                                            TempWHTEntry."Rem Realized Base" :=
                                                              TempWHTEntry."Rem Realized Base" - TotalWHTBase;
                                                            TempWHTEntry."Rem Realized Amount" :=
                                                              TempWHTEntry."Rem Realized Amount" - TotalWHT;
                                                        end else begin
                                                            TempWHTEntry."Rem Realized Base" :=
                                                              TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                            TempWHTEntry."Rem Realized Amount" :=
                                                              TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                            WHTEntry.Base := 0;
                                                            WHTEntry.Amount := 0;
                                                        end;
                                                        WHTEntry."Rem Realized Amount" := 0;
                                                        WHTEntry."Rem Realized Base" := 0;
                                                        TotalWHTBase := 0;
                                                        TotalWHT := 0;
                                                    end;

                                                if CurrencyCode = '' then begin
                                                    TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                    TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                end else begin
                                                    TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                      Round(
                                                        CurrExchRate.ExchangeAmtFCYToLCY(
                                                          DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                    TempWHTEntry."Rem Realized Base (LCY)" :=
                                                      Round(
                                                        CurrExchRate.ExchangeAmtFCYToLCY(
                                                          DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                end;
                                                if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                    (TempWHTEntry."Rem Realized Base" = 0))
                                                then
                                                    TempWHTEntry.Closed := true;
                                                TempWHTEntry.Modify();
                                            end;
                                        until CustLedgerEntry.Next() = 0;
                                        WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                    end;
                                end;
                            end;
                        end;

                        // sales Credit Memo & Refund
                        if ((WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo") or
                            (WHTEntry."Document Type" = WHTEntry."Document Type"::Refund))
                        then begin
                            WHTEntry.Base := Abs(WHTEntry.Base);
                            WHTEntry.Amount := Abs(WHTEntry.Amount);
                            WHTEntry."Payment Amount" := Abs(Amount);
                            WHTEntry."Rem Realized Base" := WHTEntry.Base;
                            WHTEntry."Rem Realized Amount" := WHTEntry.Amount;
                            if (WHTPostingSetup."Realized WHT Type" =
                                WHTPostingSetup."Realized WHT Type"::Earliest)
                            then
                                if WHTEntry."Applies-to Doc. No." <> '' then begin
                                    TempWHTEntry.Reset();
                                    TempWHTEntry.SetRange(Settled, false);
                                    TempWHTEntry.SetRange("Document Type", WHTEntry."Applies-to Doc. Type");
                                    TempWHTEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                    if WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo" then
                                        TempWHTEntry.SetFilter(
                                          "Document Type",
                                          '%1|%2',
                                          TempWHTEntry."Document Type"::Refund,
                                          TempWHTEntry."Document Type"::Invoice);

                                    if WHTEntry."Document Type" = WHTEntry."Document Type"::Refund then
                                        TempWHTEntry.SetFilter(
                                          "Document Type",
                                          '%1|%2',
                                          TempWHTEntry."Document Type"::"Credit Memo",
                                          TempWHTEntry."Document Type"::Payment);

                                    if TempWHTEntry.FindFirst() then begin
                                        if Abs(TempWHTEntry."Rem Realized Amount") >= Abs(WHTEntry.Amount) then begin
                                            if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Invoice) or
                                                (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment))
                                            then begin
                                                TempWHTEntry."Rem Realized Base" :=
                                                  TempWHTEntry."Rem Realized Base" + WHTEntry.Base;
                                                TempWHTEntry."Rem Realized Amount" :=
                                                  TempWHTEntry."Rem Realized Amount" + WHTEntry.Amount;
                                                WHTEntry."Rem Realized Base" := 0;
                                                WHTEntry."Rem Realized Amount" := 0;
                                            end else begin
                                                TempWHTEntry."Rem Realized Base" :=
                                                  TempWHTEntry."Rem Realized Base" - WHTEntry.Base;
                                                TempWHTEntry."Rem Realized Amount" :=
                                                  TempWHTEntry."Rem Realized Amount" - WHTEntry.Amount;
                                                WHTEntry.Amount := 0;
                                            end;

                                            if CurrencyCode = '' then begin
                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                            end else begin
                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                  Round(
                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                  Round(
                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                            end;
                                        end else begin
                                            if ((TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Invoice) or
                                                (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment))
                                            then begin
                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                            end else begin
                                                WHTEntry.Base := WHTEntry.Base - TempWHTEntry."Rem Realized Base";
                                                WHTEntry.Amount := WHTEntry.Amount - TempWHTEntry."Rem Realized Amount";
                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - TempWHTEntry."Rem Realized Base";
                                                WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" - TempWHTEntry."Rem Realized Amount";
                                            end;
                                            TempWHTEntry."Rem Realized Base" := 0;
                                            TempWHTEntry."Rem Realized Amount" := 0;
                                            TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                            TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                        end;

                                        if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                            (TempWHTEntry."Rem Realized Base" = 0))
                                        then
                                            TempWHTEntry.Closed := true;
                                        TempWHTEntry.Modify();
                                    end
                                    else
                                        if "Applies-toID" <> '' then begin
                                            if WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo" then begin
                                                CustLedgerEntry.Reset();
                                                CustLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Refund);
                                                if CustLedgerEntry.FindSet() then begin
                                                    TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                    TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                    repeat
                                                        TempWHTEntry.Reset();
                                                        TempWHTEntry.SetRange(Settled, false);
                                                        TempWHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                        if TempWHTEntry.FindFirst() then begin
                                                            if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                                WHTEntry.Base := WHTEntry.Base - TempWHTEntry."Rem Realized Base";
                                                                WHTEntry.Amount := WHTEntry.Amount - TempWHTEntry."Rem Realized Amount";
                                                                WHTEntry."Rem Realized Base" :=
                                                                  WHTEntry."Rem Realized Base" - TempWHTEntry."Rem Realized Base";
                                                                WHTEntry."Rem Realized Amount" :=
                                                                  WHTEntry."Rem Realized Amount" - TempWHTEntry."Rem Realized Amount";
                                                                TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                                TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                                TempWHTEntry."Rem Realized Base" := 0;
                                                                TempWHTEntry."Rem Realized Amount" := 0;
                                                                TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                            end else
                                                                if (TotalWHT > 0) and (TotalWHT <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                    TempWHTEntry."Rem Realized Base" :=
                                                                      TempWHTEntry."Rem Realized Base" - TotalWHTBase;
                                                                    TempWHTEntry."Rem Realized Amount" :=
                                                                      TempWHTEntry."Rem Realized Amount" - TotalWHT;
                                                                    WHTEntry.Base := 0;
                                                                    WHTEntry.Amount := 0;
                                                                    WHTEntry."Rem Realized Amount" := 0;
                                                                    WHTEntry."Rem Realized Base" := 0;
                                                                    TotalWHTBase := 0;
                                                                    TotalWHT := 0;
                                                                end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                            end;
                                                            if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                                (TempWHTEntry."Rem Realized Base" = 0))
                                                            then
                                                                TempWHTEntry.Closed := true;
                                                            TempWHTEntry.Modify();
                                                        end;
                                                    until CustLedgerEntry.Next() = 0;
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                                end;

                                                CustLedgerEntry.Reset();
                                                CustLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                                                if CustLedgerEntry.FindSet() then begin
                                                    TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                    TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                    repeat
                                                        TempWHTEntry.Reset();
                                                        TempWHTEntry.SetRange(Settled, false);
                                                        TempWHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                        if TempWHTEntry.FindFirst() then begin
                                                            if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" + TempWHTEntry."Rem Realized Base";
                                                                WHTEntry."Rem Realized Amount" := WHTEntry."Rem Realized Amount" + TempWHTEntry."Rem Realized Amount";
                                                                TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                                TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                                TempWHTEntry."Rem Realized Base" := 0;
                                                                TempWHTEntry."Rem Realized Amount" := 0;
                                                                TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                            end else
                                                                if (TotalWHT > 0) and (TotalWHT <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                    TempWHTEntry."Rem Realized Base" :=
                                                                      TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                                    TempWHTEntry."Rem Realized Amount" :=
                                                                      TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                                    WHTEntry."Rem Realized Amount" := 0;
                                                                    WHTEntry."Rem Realized Base" := 0;
                                                                    TotalWHTBase := 0;
                                                                    TotalWHT := 0;
                                                                end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                            end;
                                                            if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                                (TempWHTEntry."Rem Realized Base" = 0))
                                                            then
                                                                TempWHTEntry.Closed := true;
                                                            TempWHTEntry.Modify();
                                                        end;
                                                    until CustLedgerEntry.Next() = 0;
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                                end;
                                            end;

                                            if WHTEntry."Document Type" = WHTEntry."Document Type"::Refund then begin
                                                CustLedgerEntry.Reset();
                                                CustLedgerEntry.SetRange("Applies-to ID", "Applies-toID");
                                                CustLedgerEntry.SetFilter(
                                                  "Document Type",
                                                  '%1|%2',
                                                  CustLedgerEntry."Document Type"::Payment,
                                                  CustLedgerEntry."Document Type"::"Credit Memo");
                                                if CustLedgerEntry.FindSet() then begin
                                                    TotalWHTBase := Abs(WHTEntry."Rem Realized Base");
                                                    TotalWHT := Abs(WHTEntry."Rem Realized Amount");
                                                    repeat
                                                        TempWHTEntry.Reset();
                                                        TempWHTEntry.SetRange(Settled, false);
                                                        TempWHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                                                        TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                        TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                        if TempWHTEntry.FindFirst() then begin
                                                            if TotalWHT > Abs(TempWHTEntry."Rem Realized Amount") then begin
                                                                if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::"Credit Memo" then begin
                                                                    WHTEntry.Base := WHTEntry.Base - Abs(TempWHTEntry."Rem Realized Base");
                                                                    WHTEntry.Amount := WHTEntry.Amount - Abs(TempWHTEntry."Rem Realized Amount");
                                                                end;
                                                                WHTEntry."Rem Realized Base" := WHTEntry."Rem Realized Base" - Abs(TempWHTEntry."Rem Realized Base");
                                                                WHTEntry."Rem Realized Amount" :=
                                                                  WHTEntry."Rem Realized Amount" - Abs(TempWHTEntry."Rem Realized Amount");
                                                                TotalWHTBase := TotalWHTBase - Abs(TempWHTEntry."Rem Realized Base");
                                                                TotalWHT := TotalWHT - Abs(TempWHTEntry."Rem Realized Amount");
                                                                TempWHTEntry."Rem Realized Base" := 0;
                                                                TempWHTEntry."Rem Realized Amount" := 0;
                                                                TempWHTEntry."Rem Realized Base (LCY)" := 0;
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := 0;
                                                            end else
                                                                if (TotalWHT > 0) and (TotalWHT <= Abs(TempWHTEntry."Rem Realized Amount")) then begin
                                                                    if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment then begin
                                                                        TempWHTEntry."Rem Realized Base" :=
                                                                          TempWHTEntry."Rem Realized Base" + TotalWHTBase;
                                                                        TempWHTEntry."Rem Realized Amount" :=
                                                                          TempWHTEntry."Rem Realized Amount" + TotalWHT;
                                                                    end else begin
                                                                        TempWHTEntry."Rem Realized Base" :=
                                                                          TempWHTEntry."Rem Realized Base" - TotalWHTBase;
                                                                        TempWHTEntry."Rem Realized Amount" :=
                                                                          TempWHTEntry."Rem Realized Amount" - TotalWHT;
                                                                        WHTEntry.Base := 0;
                                                                        WHTEntry.Amount := 0;
                                                                    end;
                                                                    WHTEntry."Rem Realized Amount" := 0;
                                                                    WHTEntry."Rem Realized Base" := 0;
                                                                    TotalWHTBase := 0;
                                                                    TotalWHT := 0;
                                                                end;

                                                            if CurrencyCode = '' then begin
                                                                TempWHTEntry."Rem Realized Base (LCY)" := TempWHTEntry."Rem Realized Base";
                                                                TempWHTEntry."Rem Realized Amount (LCY)" := TempWHTEntry."Rem Realized Amount";
                                                            end else begin
                                                                TempWHTEntry."Rem Realized Amount (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                                                                TempWHTEntry."Rem Realized Base (LCY)" :=
                                                                  Round(
                                                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                                                      DocDate, CurrencyCode, TempWHTEntry."Rem Realized Base (LCY)", CurrFactor));
                                                            end;
                                                            if ((TempWHTEntry."Rem Realized Amount" = 0) and
                                                                (TempWHTEntry."Rem Realized Base" = 0))
                                                            then
                                                                TempWHTEntry.Closed := true;
                                                            TempWHTEntry.Modify();
                                                        end;
                                                    until CustLedgerEntry.Next() = 0;
                                                    WHTEntry."Applies-to Entry No." := TempWHTEntry."Entry No.";
                                                end;
                                            end;
                                        end;
                                end;
                        end;
                    end;

                    if WHTEntry.Amount = 0 then
                        if NextWHTEntryNo = 0 then
                            exit
                        else
                            exit(NextWHTEntryNo);

                    if ((WHTEntry."Rem Realized Amount" = 0) and
                        (WHTEntry."Rem Realized Base" = 0))
                    then
                        WHTEntry.Closed := true;
                end;

                if CurrencyCode = '' then begin
                    WHTEntry."Base (LCY)" := WHTEntry.Base;
                    WHTEntry."Amount (LCY)" := WHTEntry.Amount;
                    WHTEntry."Unrealized Amount (LCY)" := WHTEntry."Unrealized Amount";
                    WHTEntry."Unrealized Base (LCY)" := WHTEntry."Unrealized Base";
                    WHTEntry."Rem Realized Base (LCY)" := WHTEntry."Rem Realized Base";
                    WHTEntry."Rem Realized Amount (LCY)" := WHTEntry."Rem Realized Amount";
                    WHTEntry."Rem Unrealized Amount (LCY)" := WHTEntry."Remaining Unrealized Amount";
                    WHTEntry."Rem Unrealized Base (LCY)" := WHTEntry."Remaining Unrealized Base";
                end else begin
                    WHTEntry."Base (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry.Base, CurrFactor));
                    WHTEntry."Amount (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry.Amount, CurrFactor));
                    WHTEntry."Unrealized Base (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry."Unrealized Base", CurrFactor));
                    WHTEntry."Rem Realized Amount (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry."Rem Realized Amount", CurrFactor));
                    WHTEntry."Rem Realized Base (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry."Rem Realized Base", CurrFactor));
                    WHTEntry."Unrealized Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          DocDate, CurrencyCode, WHTEntry."Unrealized Amount", CurrFactor));
                    WHTEntry."Rem Unrealized Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          DocDate, CurrencyCode, WHTEntry."Remaining Unrealized Amount", CurrFactor));
                    WHTEntry."Rem Unrealized Base (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          DocDate, CurrencyCode, WHTEntry."Remaining Unrealized Base", CurrFactor));
                end;

                if (WHTEntry."Applies-to Doc. No." <> '') and UnrealizedWHT then begin
                    TempWHTEntry.SetRange("Document Type", WHTEntry."Applies-to Doc. Type");
                    TempWHTEntry.SetRange("Document No.", WHTEntry."Applies-to Doc. No.");
                    TempWHTEntry.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                    TempWHTEntry.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                    if TempWHTEntry.FindFirst() then begin
                        TempWHTEntry."Rem Unrealized Amount (LCY)" :=
                          TempWHTEntry."Rem Unrealized Amount (LCY)" + WHTEntry."Unrealized Amount (LCY)";
                        TempWHTEntry."Rem Unrealized Base (LCY)" :=
                          TempWHTEntry."Rem Unrealized Base (LCY)" + WHTEntry."Unrealized Base (LCY)";
                        TempWHTEntry.Modify();
                        WHTEntry."Rem Unrealized Amount (LCY)" := 0;
                        WHTEntry."Rem Unrealized Base (LCY)" := 0;
                    end;
                end;

                if WHTPostingSetup."Realized WHT Type" = WHTPostingSetup."Realized WHT Type"::Earliest then
                    if Abs(WHTEntry.Base) < WHTPostingSetup."WHT Minimum Invoice Amount" then
                        exit;

                WHTEntry.Insert();
                NextWHTEntryNo := WHTEntry."Entry No." + 1;

                if TempWHTEntry.Prepayment then begin
                    WHTEntry3.Reset();
                    WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                    WHTEntry3.SetRange("Applies-to Entry No.", TempWHTEntry."Entry No.");
                    WHTEntry3.CalcSums(Amount, "Amount (LCY)");
                    if (Abs(Abs(WHTEntry3.Amount) - Abs(TempWHTEntry."Unrealized Amount")) < 0.1) and
                       (Abs(Abs(WHTEntry3.Amount) - Abs(TempWHTEntry."Unrealized Amount")) > 0)
                    then begin
                        WHTEntry."WHT Difference" := TempWHTEntry."Unrealized Amount" - WHTEntry3.Amount;
                        WHTEntry.Amount := WHTEntry.Amount + WHTEntry."WHT Difference";
                        WHTEntry.Modify();
                    end;
                    if (Abs(Abs(WHTEntry3."Amount (LCY)") - Abs(TempWHTEntry."Unrealized Amount (LCY)")) < 0.1) and
                       (Abs(Abs(WHTEntry3."Amount (LCY)") - Abs(TempWHTEntry."Unrealized Amount (LCY)")) > 0)
                    then begin
                        WHTEntry."Amount (LCY)" := WHTEntry."Amount (LCY)" +
                          TempWHTEntry."Unrealized Amount (LCY)" - WHTEntry3."Amount (LCY)";
                        WHTEntry.Modify();
                    end;
                end;
            end;
        exit(NextWHTEntryNo);
    end;

    procedure WHTAmountJournal(var GenJnlLine1: Record "Gen. Journal Line"; Post: Boolean) WHTAmount: Decimal
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry3: Record "WHT Entry";
        TotalWHTAmount: Decimal;
        TotalWHTAmount2: Decimal;
        TotalWHTAmount3: Decimal;
        PaymentAmount: Decimal;
        PaymentAmountLCY: Decimal;
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        WHTEntryTemp: Record "WHT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PaymentAmount1: Decimal;
        AppldAmount: Decimal;
        ExpectedAmount: Decimal;
        GenJnlLine: Record "Gen. Journal Line";
        TotalWHTAmount4: Decimal;
        WHTAmount1: Decimal;
        RemainingAmt: Decimal;
        GenJnlLineAmount: Decimal;
    begin
        GenJnlLine.Copy(GenJnlLine1);
        if (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment) and
           (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund)
        then
            exit;

        GLSetup.Get();
        if IsForeignVendor(GenJnlLine) then
            exit;

        ExitLoop := false;
        TotalWHTAmount := 0;
        TotalWHTAmount2 := 0;
        TotalWHTAmount3 := 0;
        TotalWHTAmount4 := 0;
        RemainingAmt := 0;
        TotAmt := 0;
        TempVendLedgEntry.Reset();
        TempVendLedgEntry1.Reset();
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            if GenJnlLine."Applies-to ID" <> '' then begin
                TempVendLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                TempVendLedgEntry1.SetRange(Open, true);
                TempVendLedgEntry1.SetFilter("Document Type", '<>%1', TempVendLedgEntry1."Document Type"::" ");
                if GenJnlLine."Bill-to/Pay-to No." = '' then
                    TempVendLedgEntry1.SetRange("Buy-from Vendor No.", GenJnlLine."Account No.")
                else
                    TempVendLedgEntry1.SetRange("Buy-from Vendor No.", GenJnlLine."Bill-to/Pay-to No.");
            end else
                exit(TotalWHTAmount);

            if TempVendLedgEntry1.FindSet() then
                repeat
                    TempVendLedgEntry1.CalcFields(
                      Amount, "Amount (LCY)",
                      "Remaining Amount", "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");
                    RemainingAmt := RemainingAmt + TempVendLedgEntry1."Remaining Amount";
                until TempVendLedgEntry1.Next() = 0;

            TotAmt := Abs(GenJnlLine.Amount);

            if GenJnlLine."Applies-to ID" <> '' then begin
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                if GenJnlLine."Bill-to/Pay-to No." = '' then
                    TempVendLedgEntry.SetRange("Buy-from Vendor No.", GenJnlLine."Account No.")
                else
                    TempVendLedgEntry.SetRange("Buy-from Vendor No.", GenJnlLine."Bill-to/Pay-to No.");
            end else
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");

            TempVendLedgEntry.SetRange(Open, true);
            TempVendLedgEntry.SetRange("Document Type", TempVendLedgEntry."Document Type"::"Credit Memo");
            if TempVendLedgEntry.FindSet() then
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount, "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempVendLedgEntry."Pmt. Discount Date",
                         Abs(TempVendLedgEntry."Amount to Apply"),
                         Abs(TempVendLedgEntry."Remaining Amount"),
                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        TotAmt := TotAmt - Abs(TempVendLedgEntry."Original Pmt. Disc. Possible");

                    GenJnlLine.Validate(Amount, -Abs(TempVendLedgEntry."Remaining Amount"));
                    RemainingAmt -= TempVendLedgEntry."Remaining Amount";
                    TotAmt += TempVendLedgEntry."Remaining Amount";

                    GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    PaymentAmount := GenJnlLine.Amount;
                    PaymentAmount1 := GenJnlLine.Amount;
                    PaymentAmountLCY := GenJnlLine."Amount (LCY)";
                    FilterWHTEntry(WHTEntry, GenJnlLine);

                    if WHTEntry.FindSet() then
                        repeat
                            PurchCrMemoHeader.Reset();
                            PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                            PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                            if PurchCrMemoHeader.FindFirst() then begin
                                TempRemAmt := 0;
                                VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                if VendLedgEntry1.FindFirst() then
                                    VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                WHTEntryTemp.Reset();
                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                if WHTEntryTemp.FindFirst() then begin
                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                end;
                            end;

                            VendLedgEntry.Reset();
                            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");

                            if VendLedgEntry.FindFirst() then
                                VendLedgEntry.CalcFields(Amount, "Remaining Amount");

                            ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                            if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                               (Abs(PaymentAmount1) >=
                                (Abs(VendLedgEntry."Remaining Amount" +
                                   VendLedgEntry1."Remaining Amount") -
                                 Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                            then
                                AppldAmount :=
                                  Round(
                                    ((PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                     ExpectedAmount))
                            else
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);

                            if GenJnlLine."Currency Code" <> '' then begin
                                CurrFactor :=
                                  CurrExchRate.ExchangeRate(
                                    GenJnlLine."Document Date",
                                    GenJnlLine."Currency Code");

                                WHTAmount1 := Round(AppldAmount * WHTEntry."WHT %" / 100);
                                WHTEntry3.Reset();
                                WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                                WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                                WHTEntry3.CalcSums(Amount);
                                if (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                                   (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) > 0)
                                then
                                    WHTAmount1 := WHTAmount1 + (WHTEntry."Unrealized Amount" - (WHTEntry3.Amount + WHTAmount1));

                                TotalWHTAmount4 :=
                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                      GenJnlLine."Document Date",
                                      GenJnlLine."Currency Code",
                                      // ROUND(AppldAmount * WHTEntry."WHT %" / 100),
                                      WHTAmount1,
                                      CurrFactor);

                                TotalWHTAmount4 :=
                                  CurrExchRate.ExchangeAmtLCYToFCY(
                                    GenJnlLine."Document Date",
                                    GenJnlLine."Currency Code",
                                    TotalWHTAmount4,
                                    CurrFactor);
                                TotalWHTAmount := (TotalWHTAmount + TotalWHTAmount4);
                            end else begin
                                // TotalWHTAmount := ROUND(TotalWHTAmount + AppldAmount * WHTEntry."WHT %" / 100);
                                WHTAmount1 := Round(AppldAmount * WHTEntry."WHT %" / 100);
                                WHTEntry3.Reset();
                                WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                                WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                                WHTEntry3.CalcSums(Amount);
                                if (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                                   (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) > 0)
                                then
                                    WHTAmount1 := WHTAmount1 + (WHTEntry."Unrealized Amount" - (WHTEntry3.Amount + WHTAmount1));

                                TotalWHTAmount := Round(TotalWHTAmount + WHTAmount1);
                            end;
                            TotalWHTAmount2 := TotalWHTAmount;
                        until WHTEntry.Next() = 0;

                until TempVendLedgEntry.Next() = 0;

            ExitLoop := false;
            TempVendLedgEntry.Reset();
            if GenJnlLine."Applies-to ID" <> '' then begin
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                if GenJnlLine."Bill-to/Pay-to No." = '' then
                    TempVendLedgEntry.SetRange("Buy-from Vendor No.", GenJnlLine."Account No.")
                else
                    TempVendLedgEntry.SetRange("Buy-from Vendor No.", GenJnlLine."Bill-to/Pay-to No.");
            end else
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");

            TempVendLedgEntry.SetRange(Open, true);
            TempVendLedgEntry.SetFilter("Document Type", '<>%1&<>%2',
              TempVendLedgEntry."Document Type"::"Credit Memo", TempVendLedgEntry."Document Type"::" ");
            if TempVendLedgEntry.FindSet() then begin
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempVendLedgEntry."Pmt. Discount Date",
                         Abs(TempVendLedgEntry."Amount to Apply"),
                         Abs(TempVendLedgEntry."Remaining Amount"),
                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        TotAmt := TotAmt + Abs(TempVendLedgEntry."Original Pmt. Disc. Possible");

                    UpdateAmounts(TempVendLedgEntry, GenJnlLine, RemainingAmt, TotAmt, GenJnlLineAmount, ExitLoop);

                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;

                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    PaymentAmount := GenJnlLine.Amount;
                    PaymentAmount1 := GenJnlLine.Amount;
                    PaymentAmountLCY := GenJnlLine."Amount (LCY)";
                    FilterWHTEntry(WHTEntry, GenJnlLine);
                    if WHTEntry.FindSet() then
                        repeat
                            PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                            PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                            if PurchCrMemoHeader.FindFirst() then begin
                                TempRemAmt := 0;
                                VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                if VendLedgEntry1.FindFirst() then
                                    VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                WHTEntryTemp.Reset();
                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                if WHTEntryTemp.FindFirst() then begin
                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                end;
                            end;

                            VendLedgEntry.Reset();
                            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                            if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
                            if VendLedgEntry.FindFirst() then
                                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                            ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                            if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                               (Abs(PaymentAmount1) >=
                                (Abs(VendLedgEntry."Remaining Amount" + VendLedgEntry1."Remaining Amount") -
                                 Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                            then
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 *
                                     (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                    ExpectedAmount)
                            else
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 *
                                     (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                    ExpectedAmount);

                            if GenJnlLine."Currency Code" <> '' then begin
                                CurrFactor :=
                                  CurrExchRate.ExchangeRate(
                                    GenJnlLine."Document Date",
                                    GenJnlLine."Currency Code");
                                WHTAmount1 := Round(AppldAmount * WHTEntry."WHT %" / 100);

                                TotalWHTAmount4 :=
                                    CurrExchRate.ExchangeAmtFCYToLCY(
                                      GenJnlLine."Document Date",
                                      GenJnlLine."Currency Code",
                                      WHTAmount1,
                                       CurrFactor);
                                TotalWHTAmount4 :=
                                  CurrExchRate.ExchangeAmtLCYToFCY(
                                    GenJnlLine."Document Date",
                                    GenJnlLine."Currency Code",
                                    TotalWHTAmount4,
                                    CurrFactor);
                                TotalWHTAmount := (TotalWHTAmount + TotalWHTAmount4);
                            end else begin
                                WHTAmount1 := CalcAppliedWHTAmount(TempVendLedgEntry, AppldAmount, WHTEntry."WHT %", ExitLoop);
                                TotalWHTAmount := Round(TotalWHTAmount + WHTAmount1);
                            end;
                            TotalWHTAmount2 := TotalWHTAmount;
                        until WHTEntry.Next() = 0;

                    if ExitLoop then
                        exit(TotalWHTAmount2);
                until TempVendLedgEntry.Next() = 0;

                if GenJnlLine."Currency Code" <> '' then begin
                    CurrFactor :=
                      CurrExchRate.ExchangeRate(
                        GenJnlLine."Document Date",
                        GenJnlLine."Currency Code");

                    TotalWHTAmount3 :=
                      Round(
                        TotalWHTAmount3 +
                        Round(
                          CurrExchRate.ExchangeAmtFCYToLCY(
                            GenJnlLine."Document Date",
                            GenJnlLine."Currency Code",
                            TotalWHTAmount2, CurrFactor)));
                end;
            end;
            exit(TotalWHTAmount2);
        end;
        TotAmt := Abs(GenJnlLine.Amount);
        TempVendLedgEntry.Reset();
        TempVendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        TempVendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        if TempVendLedgEntry.FindFirst() then
            if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then begin
                TempVendLedgEntry.CalcFields(
                  Amount,
                  "Amount (LCY)",
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  "Original Amount",
                  "Original Amt. (LCY)");

                if TempVendLedgEntry."Amount to Apply" = 0 then
                    TempVendLedgEntry."Amount to Apply" := -ABSMin(TempVendLedgEntry."Remaining Amount", GenJnlLine.Amount);

                if CheckPmtDisc(
                     GenJnlLine."Posting Date",
                     TempVendLedgEntry."Pmt. Discount Date",
                     Abs(TempVendLedgEntry."Amount to Apply"),
                     Abs(TempVendLedgEntry."Remaining Amount"),
                     Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                     Abs(TotAmt))
                then
                    TotAmt := TotAmt + Abs(TempVendLedgEntry."Original Pmt. Disc. Possible");

                if Abs(TempVendLedgEntry."Remaining Amount") < Abs(TotAmt) then
                    GenJnlLine.Validate(Amount, Abs(TempVendLedgEntry."Remaining Amount"))
                else
                    GenJnlLine.Validate(Amount, TotAmt);
            end else
                if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then begin
                    TempVendLedgEntry.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if TempVendLedgEntry."Amount to Apply" = 0 then
                        TempVendLedgEntry."Amount to Apply" := ABSMin(TempVendLedgEntry."Remaining Amount", GenJnlLine.Amount);

                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempVendLedgEntry."Pmt. Discount Date",
                         Abs(TempVendLedgEntry."Amount to Apply"),
                         Abs(TempVendLedgEntry."Remaining Amount"),
                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        TotAmt := TotAmt + Abs(TempVendLedgEntry."Original Pmt. Disc. Possible");

                    if Abs(TempVendLedgEntry."Remaining Amount") < Abs(TotAmt) then
                        GenJnlLine.Validate(Amount, -Abs(TempVendLedgEntry."Remaining Amount"))
                    else
                        GenJnlLine.Validate(Amount, -TotAmt);
                end;

        TotalWHTAmount := 0;
        TempRemAmt := 0;
        PaymentAmount := GenJnlLine.Amount;
        PaymentAmount1 := GenJnlLine.Amount;
        PaymentAmountLCY := GenJnlLine."Amount (LCY)";
        FilterWHTEntry(WHTEntry, GenJnlLine);
        if WHTEntry.FindSet() then begin
            repeat
                PurchCrMemoHeader.SetRange(
                  "Applies-to Doc. Type",
                  PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                if PurchCrMemoHeader.FindFirst() then begin
                    TempRemAmt := 0;
                    VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                    VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                    if VendLedgEntry1.FindFirst() then
                        VendLedgEntry1.CalcFields(Amount, "Remaining Amount", "Remaining Amt. (LCY)");
                    WHTEntryTemp.Reset();
                    WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                    WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                    WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                    WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                    WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                    if WHTEntryTemp.FindFirst() then
                        TempRemAmt := WHTEntryTemp."Unrealized Base";
                end;

                VendLedgEntry.Reset();
                VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                if VendLedgEntry.FindFirst() then
                    VendLedgEntry.CalcFields(Amount, "Remaining Amount", "Remaining Amt. (LCY)");
                ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                AppldAmount :=
                  Round(
                    (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) /
                    ExpectedAmount);

                if GenJnlLine."Currency Code" <> '' then begin
                    CurrFactor :=
                      CurrExchRate.ExchangeRate(
                        GenJnlLine."Document Date",
                        GenJnlLine."Currency Code");

                    WHTAmount1 := Round(AppldAmount * WHTEntry."WHT %" / 100);
                    WHTEntry3.Reset();
                    WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                    WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                    WHTEntry3.CalcSums(Amount);
                    if (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                       (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) > 0)
                    then
                        WHTAmount1 := WHTAmount1 + (WHTEntry."Unrealized Amount" - (WHTEntry3.Amount + WHTAmount1));


                    TotalWHTAmount4 :=
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date",
                          GenJnlLine."Currency Code",
                          WHTAmount1,
                          CurrFactor);

                    TotalWHTAmount4 :=
                      CurrExchRate.ExchangeAmtLCYToFCY(
                        GenJnlLine."Document Date",
                        GenJnlLine."Currency Code",
                        TotalWHTAmount4,
                        CurrFactor);
                    TotalWHTAmount := (TotalWHTAmount + TotalWHTAmount4);
                end else begin
                    WHTAmount1 := Round(AppldAmount * WHTEntry."WHT %" / 100);
                    WHTEntry3.Reset();
                    WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                    WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                    WHTEntry3.CalcSums(Amount);
                    TotalWHTAmount := Round(TotalWHTAmount + WHTAmount1, GLSetup."Inv. Rounding Precision (LCY)", '=');
                end;
            until WHTEntry.Next() = 0;
            exit(TotalWHTAmount);
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplyCustCalcWHT(var GenJnlLine: Record "Gen. Journal Line") WHTAmt: Decimal
    var
        Currency: Option Vendor,Customer;
        RemainingAmt: Decimal;
    begin
        AppliedAmount := Abs(GenJnlLine."Amount (LCY)");
        TotAmt := Abs(GenJnlLine.Amount);
        TempCustLedgEntry1.Reset();
        SetCustAppliesToFilter(TempCustLedgEntry1, GenJnlLine);
        if TempCustLedgEntry1.FindSet() then
            repeat
                TempCustLedgEntry1.CalcFields(
                  Amount,
                  "Amount (LCY)",
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  "Original Amount",
                  "Original Amt. (LCY)");

                RemainingAmt := RemainingAmt + TempCustLedgEntry1."Remaining Amount";

                if TempCustLedgEntry1."Document Type" =
                   TempCustLedgEntry1."Document Type"::"Credit Memo"
                then
                    RemainingAmt := RemainingAmt + TempCustLedgEntry1."Remaining Amount";
            until TempCustLedgEntry1.Next() = 0;

        TempCustLedgEntry.Reset();
        SetCustAppliesToFilter(TempCustLedgEntry, GenJnlLine);
        TempCustLedgEntry.SetRange("Document Type", TempCustLedgEntry."Document Type"::"Credit Memo");
        if TempCustLedgEntry.FindSet() then
            repeat
                TempCustLedgEntry.CalcFields(
                  Amount,
                  "Amount (LCY)",
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  "Original Amount", "Original Amt. (LCY)");

                if TempCustLedgEntry."Amount to Apply" = 0 then
                    TempCustLedgEntry."Amount to Apply" := -ABSMin(TempCustLedgEntry."Remaining Amount", GenJnlLine.Amount);

                if CheckPmtDisc(
                     GenJnlLine."Posting Date",
                     TempCustLedgEntry."Pmt. Discount Date",
                     Abs(TempCustLedgEntry."Amount to Apply"),
                     Abs(TempCustLedgEntry."Remaining Amount"),
                     Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                     Abs(TotAmt))
                then
                    TotAmt := TotAmt + Abs(TempCustLedgEntry."Original Pmt. Disc. Possible");

                if (Abs(RemainingAmt) <= Abs(TotAmt)) or
                   (Abs(TempCustLedgEntry."Remaining Amount") < Abs(TotAmt))
                then begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Amount to Apply"),
                         Abs(TempCustLedgEntry."Remaining Amount"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then begin
                        GenJnlLine.Validate(
                          Amount,
                          Abs(TempCustLedgEntry."Remaining Amount" -
                            TempCustLedgEntry."Original Pmt. Disc. Possible"));
                        if TempCustLedgEntry."Document Type" <>
                           TempCustLedgEntry."Document Type"::"Credit Memo"
                        then
                            TotAmt := -(TotAmt - TempCustLedgEntry."Remaining Amount");

                        RemainingAmt :=
                          RemainingAmt - TempCustLedgEntry."Remaining Amount" +
                          TempCustLedgEntry."Original Pmt. Disc. Possible";
                    end else begin
                        GenJnlLine.Validate(Amount, Abs(TempCustLedgEntry."Remaining Amount"));
                        if TempCustLedgEntry."Document Type" <>
                           TempCustLedgEntry."Document Type"::"Credit Memo"
                        then
                            TotAmt := -(TotAmt - TempCustLedgEntry."Remaining Amount");
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Remaining Amount";
                    end;
                end else begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Amount to Apply"),
                         Abs(TempCustLedgEntry."Remaining Amount"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        GenJnlLine.Validate(
                          Amount, TotAmt - Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"))
                    else
                        GenJnlLine.Validate(Amount, Abs(TotAmt));
                    ExitLoop := true;
                end;

                if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                    GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                else
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Remaining Amount";
                        TotAmt := TotAmt - TempCustLedgEntry."Remaining Amount";
                        ExitLoop := false;
                    end;

                GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                WHTAmt += CalcWHT(GenJnlLine, Currency::Customer);
            until (TempCustLedgEntry.Next() = 0) or ExitLoop;

        ExitLoop := false;
        TempCustLedgEntry.Reset();
        SetCustAppliesToFilter(TempCustLedgEntry, GenJnlLine);
        TempCustLedgEntry.SetFilter("Document Type", '<>%1', TempCustLedgEntry."Document Type"::"Credit Memo");
        if TempCustLedgEntry.FindSet() then
            repeat
                TempCustLedgEntry.CalcFields(
                  Amount,
                  "Amount (LCY)",
                  "Remaining Amount",
                  "Remaining Amt. (LCY)",
                  "Original Amount",
                  "Original Amt. (LCY)");

                if TempCustLedgEntry."Amount to Apply" = 0 then
                    TempCustLedgEntry."Amount to Apply" := ABSMin(TempCustLedgEntry."Remaining Amount", GenJnlLine.Amount);

                if CheckPmtDisc(
                     GenJnlLine."Posting Date",
                     TempCustLedgEntry."Pmt. Discount Date",
                     Abs(TempCustLedgEntry."Amount to Apply"),
                     Abs(TempCustLedgEntry."Remaining Amount"),
                     Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                     Abs(TotAmt))
                then
                    TotAmt := TotAmt + Abs(TempCustLedgEntry."Original Pmt. Disc. Possible");

                if (Abs(RemainingAmt) <= Abs(TotAmt)) or
                   (Abs(TempCustLedgEntry."Remaining Amount") < Abs(TotAmt))
                then begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Amount to Apply"),
                         Abs(TempCustLedgEntry."Remaining Amount"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then begin
                        RemainingAmt :=
                          RemainingAmt - TempCustLedgEntry."Remaining Amount" +
                          TempCustLedgEntry."Original Pmt. Disc. Possible";

                        GenJnlLine.Validate(
                          Amount,
                          -Abs(TempCustLedgEntry."Remaining Amount" -
                            TempCustLedgEntry."Original Pmt. Disc. Possible"));

                        if TempCustLedgEntry."Document Type" <>
                           TempCustLedgEntry."Document Type"::"Credit Memo"
                        then
                            TotAmt := (TotAmt - TempCustLedgEntry."Remaining Amount");
                    end else begin
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Remaining Amount";
                        GenJnlLine.Validate(Amount, -Abs(TempCustLedgEntry."Remaining Amount"));
                        if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                            TotAmt := (TotAmt - TempCustLedgEntry."Remaining Amount");
                    end;
                end else begin
                    if CheckPmtDisc(
                         GenJnlLine."Posting Date",
                         TempCustLedgEntry."Pmt. Discount Date",
                         Abs(TempCustLedgEntry."Amount to Apply"),
                         Abs(TempCustLedgEntry."Remaining Amount"),
                         Abs(TempCustLedgEntry."Original Pmt. Disc. Possible"),
                         Abs(TotAmt))
                    then
                        GenJnlLine.Validate(
                          Amount, -(TotAmt - Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                    else
                        GenJnlLine.Validate(Amount, -Abs(TotAmt));
                    ExitLoop := true;
                end;

                if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                    GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                else
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempCustLedgEntry."Remaining Amount";
                        TotAmt := TotAmt - TempCustLedgEntry."Remaining Amount";
                        ExitLoop := false;
                    end;
                GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                WHTAmt += CalcWHT(GenJnlLine, Currency::Customer);
            until (TempCustLedgEntry.Next() = 0) or ExitLoop;
        exit(WHTAmt);
    end;

    [Scope('OnPrem')]
    procedure CalcWHT(var GenJnlLine: Record "Gen. Journal Line"; Source: Option Vendor,Customer) PaymentNo: Decimal
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry3: Record "WHT Entry";
        PaymentAmount: Decimal;
        PaymentAmountLCY: Decimal;
        AppldAmount: Decimal;
        WHTEntryTemp: Record "WHT Entry";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        ExpectedAmount: Decimal;
        PaymentAmount1: Decimal;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgEntry1: Record "Cust. Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        WHTAmount1: Decimal;
        WHTTotAmt: Decimal;
    begin
        PaymentAmount := GenJnlLine.Amount;
        PaymentAmount1 := GenJnlLine.Amount;
        PaymentAmountLCY := GenJnlLine."Amount (LCY)";
        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);

        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");

        case Source of
            Source::Vendor:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
            Source::Customer:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
        end;

        WHTEntry.SetRange(Closed, false);
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            WHTEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            WHTEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        end else
            WHTEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
        if WHTEntry.FindSet() then begin
            repeat
                case Source of
                    Source::Vendor:
                        begin
                            if GenJnlLine."Applies-to Doc. No." = '' then
                                exit;
                            PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                            PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                            if PurchCrMemoHeader.FindFirst() then begin
                                TempRemAmt := 0;
                                VendLedgEntry1.Reset();
                                VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                if VendLedgEntry1.FindFirst() then
                                    VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                WHTEntryTemp.Reset();
                                WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                if WHTEntryTemp.FindFirst() then begin
                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                end;
                            end;

                            VendLedgEntry.Reset();
                            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                            if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
                            else
                                if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                            if VendLedgEntry.FindFirst() then
                                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                            ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                            if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                               (Abs(PaymentAmount1) >=
                                (Abs(VendLedgEntry."Remaining Amount" + VendLedgEntry1."Remaining Amount") -
                                 Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                            then
                                AppldAmount :=
                                  Round(
                                    ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                     (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount)
                            else
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);

                            PaymentAmount := PaymentAmount + AppldAmount;
                        end;
                    Source::Customer:
                        begin
                            SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
                            SalesCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                            if SalesCrMemoHeader.FindFirst() then begin
                                TempRemAmt := 0;
                                CustLedgEntry1.Reset();
                                CustLedgEntry1.SetRange("Document No.", SalesCrMemoHeader."No.");
                                CustLedgEntry1.SetRange("Document Type", CustLedgEntry1."Document Type"::"Credit Memo");
                                if CustLedgEntry1.FindFirst() then
                                    CustLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                WHTEntryTemp.Reset();
                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
                                WHTEntryTemp.SetRange("Document No.", SalesCrMemoHeader."No.");
                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                if WHTEntryTemp.FindFirst() then begin
                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                end;
                            end;

                            CustLedgEntry.Reset();
                            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                            if CustLedgEntry.FindFirst() then
                                CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                            ExpectedAmount := -(CustLedgEntry.Amount + CustLedgEntry1.Amount);
                            if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                               (Abs(PaymentAmount1) >=
                                (Abs(CustLedgEntry."Remaining Amount" + CustLedgEntry1."Remaining Amount") -
                                 Abs(CustLedgEntry."Original Pmt. Disc. Possible")))
                            then
                                AppldAmount :=
                                  Round(
                                    ((PaymentAmount1 - CustLedgEntry."Original Pmt. Disc. Possible") *
                                     (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount)
                            else
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                            PaymentAmount := PaymentAmount + AppldAmount;
                        end;
                end;

                if GenJnlLine."Currency Code" <> WHTEntry."Currency Code" then
                    Error(Text1500000);
                WHTAmount1 := Round(AppldAmount * WHTEntry."WHT %" / 100);
                WHTEntry3.Reset();
                WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                WHTEntry3.CalcSums(Amount);
                if (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                   (Abs(Abs(WHTEntry3.Amount) + Abs(WHTAmount1) - Abs(WHTEntry."Unrealized Amount")) > 0)
                then
                    WHTAmount1 := WHTAmount1 + (WHTEntry."Unrealized Amount" - (WHTEntry3.Amount + WHTAmount1));

                WHTTotAmt := Round(WHTTotAmt + WHTAmount1);
            until (WHTEntry.Next() = 0);
            exit(WHTTotAmt);
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplyTempWHTEntry(var GenJnlLine: Record "Gen. Journal Line"; Source: Option Vendor,Customer) PaymentNo: Integer
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry3: Record "Temp WHT Entry";
        WHTEntryTemp: Record "WHT Entry";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempWHTEntry: Record "Temp WHT Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgEntry1: Record "Cust. Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        WHTSlipNo: Code[10];
        ExpectedAmount: Decimal;
        PaymentAmount: Decimal;
        PaymentAmount1: Decimal;
        PaymentAmountLCY: Decimal;
        AppldAmount: Decimal;
    begin
        PaymentAmount := GenJnlLine.Amount;
        PaymentAmount1 := GenJnlLine.Amount;
        PaymentAmountLCY := GenJnlLine."Amount (LCY)";
        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
        case Source of
            Source::Vendor:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
            Source::Customer:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
        end;
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            WHTEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            WHTEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        end else
            WHTEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
        if WHTEntry.FindSet() then
            repeat
                case Source of
                    Source::Vendor:
                        begin
                            if GenJnlLine."Applies-to Doc. No." = '' then
                                exit;
                            PurchCrMemoHeader.Reset();
                            PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                            PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                            if PurchCrMemoHeader.FindFirst() then begin
                                TempRemAmt := 0;
                                VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                if VendLedgEntry1.FindFirst() then
                                    VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                WHTEntryTemp.Reset();
                                WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                if WHTEntryTemp.FindFirst() then begin
                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                end;
                            end;
                            VendLedgEntry.Reset();
                            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                            if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
                            else
                                if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");

                            if VendLedgEntry.FindFirst() then
                                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                            ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                            if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                               (Abs(PaymentAmount1) >=
                                (Abs(VendLedgEntry."Remaining Amt. (LCY)" + VendLedgEntry1."Remaining Amt. (LCY)") -
                                 Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                            then begin
                                AppldAmount :=
                                  Round(
                                    ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                     (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                                WHTEntry."Remaining Unrealized Base" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Base" -
                                    Round(
                                      ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                       (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));
                                WHTEntry."Remaining Unrealized Amount" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Amount" -
                                    Round(
                                      ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                       (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                            end else begin
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                                WHTEntry."Remaining Unrealized Base" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Base" -
                                    Round(
                                      (PaymentAmount1 *
                                       (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));
                                WHTEntry."Remaining Unrealized Amount" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Amount" -
                                    Round(
                                      (PaymentAmount1 * (WHTEntry."Unrealized Amount" + TempRemBase)) /
                                      ExpectedAmount));
                            end;
                            PaymentAmount := PaymentAmount + AppldAmount;
                        end;
                    Source::Customer:
                        begin
                            SalesCrMemoHeader.Reset();
                            SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
                            SalesCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                            if SalesCrMemoHeader.FindFirst() then begin
                                TempRemAmt := 0;
                                CustLedgEntry1.Reset();
                                CustLedgEntry1.SetRange("Document No.", SalesCrMemoHeader."No.");
                                CustLedgEntry1.SetRange("Document Type", CustLedgEntry1."Document Type"::"Credit Memo");
                                if CustLedgEntry1.FindFirst() then
                                    CustLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                WHTEntryTemp.Reset();
                                WHTEntryTemp.SetRange("Document No.", SalesCrMemoHeader."No.");
                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                if WHTEntryTemp.FindFirst() then begin
                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                end;
                            end;

                            CustLedgEntry.Reset();
                            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                            if CustLedgEntry.FindFirst() then
                                CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                            ExpectedAmount := -(CustLedgEntry.Amount + CustLedgEntry1.Amount);
                            if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                               (Abs(PaymentAmount1) >=
                                (Abs(CustLedgEntry."Remaining Amount" + CustLedgEntry1."Remaining Amt. (LCY)") -
                                 Abs(CustLedgEntry."Original Pmt. Disc. Possible")))
                            then begin
                                AppldAmount :=
                                  Round(
                                    ((PaymentAmount1 - CustLedgEntry."Original Pmt. Disc. Possible") *
                                     (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);

                                WHTEntry."Remaining Unrealized Base" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Base" -
                                    Round(
                                      ((PaymentAmount1 - CustLedgEntry."Original Pmt. Disc. Possible") *
                                       (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));

                                WHTEntry."Remaining Unrealized Amount" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Amount" -
                                    Round(
                                      ((PaymentAmount1 - CustLedgEntry."Original Pmt. Disc. Possible") *
                                       (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                            end else begin
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);

                                WHTEntry."Remaining Unrealized Base" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Base" -
                                    Round(
                                      (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));
                                WHTEntry."Remaining Unrealized Amount" :=
                                  Round(
                                    WHTEntry."Remaining Unrealized Amount" -
                                    Round(
                                      (PaymentAmount1 * (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                            end;
                            PaymentAmount := PaymentAmount + AppldAmount;
                        end;
                end;

                TempWHTEntry.Init();
                TempWHTEntry."Posting Date" := GenJnlLine."Document Date";
                TempWHTEntry."Entry No." := NextTempEntryNo();
                TempWHTEntry."Document Date" := WHTEntry."Document Date";
                TempWHTEntry."Document Type" := GenJnlLine."Document Type";
                TempWHTEntry."Document No." := WHTEntry."Document No.";
                TempWHTEntry."Gen. Bus. Posting Group" := WHTEntry."Gen. Bus. Posting Group";
                TempWHTEntry."Gen. Prod. Posting Group" := WHTEntry."Gen. Prod. Posting Group";
                TempWHTEntry."Bill-to/Pay-to No." := WHTEntry."Bill-to/Pay-to No.";
                TempWHTEntry."WHT Bus. Posting Group" := WHTEntry."WHT Bus. Posting Group";
                TempWHTEntry."WHT Prod. Posting Group" := WHTEntry."WHT Prod. Posting Group";
                TempWHTEntry."WHT Revenue Type" := WHTEntry."WHT Revenue Type";
                TempWHTEntry."Currency Code" := GenJnlLine."Currency Code";
                TempWHTEntry."Unrealized WHT Entry No." := WHTEntry."Entry No.";
                TempWHTEntry."Applies-to Entry No." := WHTEntry."Entry No.";
                TempWHTEntry."User ID" := UserId;
                TempWHTEntry."External Document No." := GenJnlLine."External Document No.";
                TempWHTEntry."Original Document No." := GenJnlLine."Document No.";
                TempWHTEntry."Source Code" := GenJnlLine."Source Code";
                TempWHTEntry."WHT %" := WHTEntry."WHT %";
                case Source of
                    Source::Vendor:
                        begin
                            TempWHTEntry.Base := Round(AppldAmount);
                            TempWHTEntry.Amount := Round(TempWHTEntry.Base * TempWHTEntry."WHT %" / 100);
                            TempWHTEntry."Transaction Type" := TempWHTEntry."Transaction Type"::Purchase;
                        end;
                    Source::Customer:
                        begin
                            TempWHTEntry.Base := Round(AppldAmount);
                            TempWHTEntry.Amount := Round(TempWHTEntry.Base * TempWHTEntry."WHT %" / 100);
                            TempWHTEntry."Transaction Type" := TempWHTEntry."Transaction Type"::Sale;
                        end;
                end;
                if TempWHTEntry."Currency Code" <> '' then begin
                    CurrFactor :=
                      CurrExchRate.ExchangeRate(
                        TempWHTEntry."Posting Date", TempWHTEntry."Currency Code");

                    TempWHTEntry."Base (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GenJnlLine."Document Date",
                          TempWHTEntry."Currency Code",
                          TempWHTEntry.Base, CurrFactor));

                    TempWHTEntry."Amount (LCY)" :=
                      Round(
                        TempWHTEntry."Base (LCY)" * TempWHTEntry."WHT %" / 100);
                end else begin
                    TempWHTEntry."Amount (LCY)" := TempWHTEntry.Amount;
                    TempWHTEntry."Base (LCY)" := TempWHTEntry.Base;
                end;

                if WHTSlipNo = '' then begin
                    PurchSetup.Get();
                    WHTSlipNo := NoSeries.GetNextNo(PurchSetup."WHT Certificate No. Series", TempWHTEntry."Posting Date");
                end;

                TempWHTEntry."WHT Certificate No." := WHTSlipNo;
                WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                TempWHTEntry."WHT Report" := WHTPostingSetup."WHT Report";

                if GenJnlLine."WHT Report Line No." <> '' then
                    TempWHTEntry."WHT Report Line No" := GenJnlLine."WHT Report Line No.";

                TempWHTEntry.Insert();
                NextWHTEntryNo := NextWHTEntryNo + 1;
                TType := TType::Purchase;
                WHTEntry3.Reset();
                WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                WHTEntry3.CalcSums(Amount, "Amount (LCY)");

                if (Abs(Abs(WHTEntry3.Amount) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                   (Abs(Abs(WHTEntry3.Amount) - Abs(WHTEntry."Unrealized Amount")) > 0)
                then begin
                    TempWHTEntry."WHT Difference" := WHTEntry."Unrealized Amount" - WHTEntry3.Amount;
                    TempWHTEntry.Amount := TempWHTEntry.Amount - TempWHTEntry."WHT Difference";
                    TempWHTEntry.Modify();
                end;

                if (Abs(Abs(WHTEntry3."Amount (LCY)") - Abs(WHTEntry."Unrealized Amount (LCY)")) < 0.1) and
                   (Abs(Abs(WHTEntry3."Amount (LCY)") - Abs(WHTEntry."Unrealized Amount (LCY)")) > 0)
                then begin
                    TempWHTEntry."Amount (LCY)" :=
                      TempWHTEntry."Amount (LCY)" - WHTEntry."Unrealized Amount (LCY)" + WHTEntry3."Amount (LCY)";
                    TempWHTEntry.Modify();
                end;
            until (WHTEntry.Next() = 0);
    end;

    [Scope('OnPrem')]
    procedure ApplyTempVendInvoiceWHT(var GenJnlLine: Record "Gen. Journal Line") EntryNo: Integer
    var
        Currency: Option Vendor,Customer;
        GenJnlLineTemp: Record "Gen. Journal Line";
        RemainingAmt: Decimal;
    begin
        GenJnlLineTemp.Copy(GenJnlLine);
        TempVendLedgEntry1.Reset();
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            TempVendLedgEntry1.SetRange(Open, true);
            TempVendLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Document No.");
            if TempVendLedgEntry1.FindSet() then
                repeat
                    TempVendLedgEntry1.CalcFields(
                      Amount, "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");
                    RemainingAmt := RemainingAmt + TempVendLedgEntry1."Remaining Amt. (LCY)";
                    if TempVendLedgEntry1."Document Type" = TempVendLedgEntry1."Document Type"::"Credit Memo" then
                        RemainingAmt := RemainingAmt + TempVendLedgEntry1."Remaining Amt. (LCY)";
                until TempVendLedgEntry1.Next() = 0;

            TotAmt := Abs(GenJnlLineTemp.Amount);
            TempVendLedgEntry.Reset();
            TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLineTemp."Document No.");
            TempVendLedgEntry.SetRange(Open, true);
            TempVendLedgEntry.SetRange("Document Type", TempVendLedgEntry."Document Type"::"Credit Memo");
            if TempVendLedgEntry.FindSet() then
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if (GenJnlLineTemp."Posting Date" < TempVendLedgEntry."Pmt. Discount Date") and
                       (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") -
                                        Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                    then
                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                    if (Abs(RemainingAmt) < Abs(TotAmt)) or
                       (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") < Abs(TotAmt))
                    then begin
                        if (GenJnlLineTemp."Posting Date" < TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            GenJnlLineTemp.Validate(
                              Amount,
                              -Abs(TempVendLedgEntry."Remaining Amt. (LCY)" +
                                TempVendLedgEntry."Original Pmt. Disc. Possible"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Remaining Amt. (LCY)";
                            RemainingAmt :=
                              RemainingAmt - TempVendLedgEntry."Remaining Amt. (LCY)" + TempVendLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLineTemp.Validate(Amount, -Abs(TempVendLedgEntry."Remaining Amt. (LCY)"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Remaining Amt. (LCY)";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Remaining Amt. (LCY)";
                        end;
                    end else begin
                        if (GenJnlLineTemp."Posting Date" < TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLineTemp.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                        else
                            GenJnlLineTemp.Validate(Amount, TotAmt);
                        ExitLoop := true;
                    end;

                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLineTemp."Applies-to Doc. Type" := GenJnlLineTemp."Applies-to Doc. Type"::Invoice
                    else begin
                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                            GenJnlLineTemp."Applies-to Doc. Type" := GenJnlLineTemp."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempVendLedgEntry."Remaining Amt. (LCY)";
                        TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                        ExitLoop := false;
                    end;

                    GenJnlLineTemp."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    NextEntry := ApplyTempWHTEntry(GenJnlLineTemp, Currency::Vendor);
                    if ExitLoop then
                        exit(NextEntry);
                until TempVendLedgEntry.Next() = 0;

            ExitLoop := false;
            TempVendLedgEntry.Reset();
            TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempVendLedgEntry.SetRange(Open, true);
            TempVendLedgEntry.SetFilter("Document Type", '<>%1', TempVendLedgEntry."Document Type"::"Credit Memo");
            if TempVendLedgEntry.FindSet() then
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");
                    if (GenJnlLineTemp."Posting Date" < TempVendLedgEntry."Pmt. Discount Date") and
                       (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") -
                                        Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                    then
                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";
                    if (Abs(RemainingAmt) < Abs(TotAmt)) or
                       (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") < Abs(TotAmt))
                    then begin
                        if (GenJnlLineTemp."Posting Date" < TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            GenJnlLineTemp.Validate(
                              Amount,
                              Abs(TempVendLedgEntry."Remaining Amt. (LCY)" -
                                TempVendLedgEntry."Original Pmt. Disc. Possible"));

                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                            RemainingAmt :=
                              RemainingAmt - TempVendLedgEntry."Remaining Amt. (LCY)" + TempVendLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLineTemp.Validate(Amount, Abs(TempVendLedgEntry."Remaining Amt. (LCY)"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Remaining Amt. (LCY)";
                        end;
                    end else begin
                        if (GenJnlLineTemp."Posting Date" < TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLineTemp.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                        else
                            GenJnlLineTemp.Validate(Amount, TotAmt);
                        ExitLoop := true;
                    end;

                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLineTemp."Applies-to Doc. Type" := GenJnlLineTemp."Applies-to Doc. Type"::Invoice
                    else begin
                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                            GenJnlLineTemp."Applies-to Doc. Type" := GenJnlLineTemp."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                        TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                    end;

                    GenJnlLineTemp."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    NextEntry := ApplyTempWHTEntry(GenJnlLineTemp, Currency::Vendor);
                    if ExitLoop then
                        exit(NextEntry);
                until TempVendLedgEntry.Next() = 0
            else
                NextEntry := ApplyTempWHTEntry(GenJnlLineTemp, Currency::Vendor);
        end else
            NextEntry := ApplyTempWHTEntry(GenJnlLineTemp, Currency::Vendor);
    end;

    [Scope('OnPrem')]
    procedure VoidCheck2(CheckLedgEntry: Record "Check Ledger Entry")
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
    end;

    [Scope('OnPrem')]
    procedure ApplyVendInvoiceWHTPosted(var VendLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; TransNo: Integer) EntryNo: Integer
    var
        Currency: Option Vendor,Customer;
        RemainingAmt: Decimal;
    begin
        TempVendLedgEntry.Reset();
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            TempVendLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempVendLedgEntry1.SetRange(Open, true);
            if TempVendLedgEntry1.FindSet(true, false) then
                repeat
                    TempVendLedgEntry1.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if TempVendLedgEntry1."Rem. Amt for WHT" = 0 then
                        TempVendLedgEntry1."Rem. Amt for WHT" := TempVendLedgEntry1."Remaining Amt. (LCY)";
                    RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
                    if TempVendLedgEntry1."Document Type" = TempVendLedgEntry1."Document Type"::"Credit Memo" then
                        RemainingAmt := RemainingAmt + TempVendLedgEntry1."Rem. Amt for WHT";
                until TempVendLedgEntry1.Next() = 0;

            TotAmt := Abs(GenJnlLine.Amount);
            if GenJnlLine."Applies-to ID" <> '' then
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
            else
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempVendLedgEntry.SetRange("Document Type", TempVendLedgEntry."Document Type"::"Credit Memo");

            if TempVendLedgEntry.FindSet() then
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                       (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt for WHT") -
                                        Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                    then
                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                    if (Abs(RemainingAmt) < Abs(TotAmt)) or
                       (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                    then begin
                        if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            GenJnlLine.Validate(
                              Amount,
                              -Abs(TempVendLedgEntry."Rem. Amt for WHT" +
                                TempVendLedgEntry."Original Pmt. Disc. Possible"));

                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt :=
                              RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT" + TempVendLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLine.Validate(Amount, -Abs(TempVendLedgEntry."Rem. Amt for WHT"));
                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt - TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        end;
                    end else begin
                        if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLine.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                        else
                            GenJnlLine.Validate(Amount, TotAmt);
                        ExitLoop := true;
                    end;

                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else begin
                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                        ExitLoop := false;
                    end;

                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    NextEntry :=
                      ProcessPaymentPosted(
                        GenJnlLine, TransNo, VendLedgerEntry."Entry No.", Currency::Vendor);

                    if ExitLoop then
                        exit(NextEntry);
                until TempVendLedgEntry.Next() = 0;

            ExitLoop := false;
            TempVendLedgEntry.Reset();
            if GenJnlLine."Applies-to ID" <> '' then
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
            else
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");

            TempVendLedgEntry.SetFilter("Document Type", '<>%1', TempVendLedgEntry."Document Type"::"Credit Memo");
            if TempVendLedgEntry.FindSet() then begin
                repeat
                    TempVendLedgEntry.CalcFields(
                      Amount, "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                       (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt for WHT") -
                                        Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                    then
                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                    if (Abs(RemainingAmt) < Abs(TotAmt)) or
                       (Abs(TempVendLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                    then begin
                        if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            GenJnlLine.Validate(
                              Amount,
                              Abs(TempVendLedgEntry."Rem. Amt for WHT" -
                                TempVendLedgEntry."Original Pmt. Disc. Possible"));

                            if TempVendLedgEntry."Document Type" <> TempVendLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt :=
                              RemainingAmt -
                              TempVendLedgEntry."Rem. Amt for WHT" +
                              TempVendLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLine.Validate(Amount, Abs(TempVendLedgEntry."Rem. Amt for WHT"));
                            if TempVendLedgEntry."Document Type" <>
                               TempVendLedgEntry."Document Type"::"Credit Memo"
                            then
                                TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Rem. Amt for WHT";
                        end;
                    end else begin
                        if (GenJnlLine."Posting Date" <= TempVendLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempVendLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempVendLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLine.Validate(Amount, TotAmt + TempVendLedgEntry."Original Pmt. Disc. Possible")
                        else
                            GenJnlLine.Validate(Amount, TotAmt);
                        ExitLoop := true;
                    end;

                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else begin
                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                        RemainingAmt := RemainingAmt + TempVendLedgEntry."Rem. Amt for WHT";
                        TotAmt := TotAmt + TempVendLedgEntry."Rem. Amt for WHT";
                        ExitLoop := false;
                    end;

                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                    NextEntry :=
                      ProcessPaymentPosted(
                        GenJnlLine, TransNo, VendLedgerEntry."Entry No.", Currency::Vendor);
                    if ExitLoop then
                        exit(NextEntry);
                until TempVendLedgEntry.Next() = 0;
                exit(NextEntry);
            end;
            exit(
              ProcessPaymentPosted(
                GenJnlLine, TransNo, VendLedgerEntry."Entry No.", Currency::Vendor));
        end;
        exit(
          ProcessPaymentPosted(
            GenJnlLine, TransNo, VendLedgerEntry."Entry No.", Currency::Vendor));
    end;

    [Scope('OnPrem')]
    procedure ApplyCustInvoiceWHTPosted(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; TransNo: Integer; AppliedEntryTransNo: Integer) EntryNo: Integer
    var
        Currency: Option Vendor,Customer;
        RemainingAmt: Decimal;
    begin
        TempCustLedgEntry1.Reset();
        TotAmt := Abs(GenJnlLine.Amount);
        if GenJnlLine."Applies-to Doc. No." = '' then begin
            if GenJnlLine."Applies-to ID" <> '' then
                TempCustLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
            else
                TempCustLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempCustLedgEntry1.SetFilter("Document No.", '<>%1', GenJnlLine."Document No.");
            if TempCustLedgEntry1.FindSet(true, false) then
                repeat
                    TempCustLedgEntry1.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount", "Original Amt. (LCY)");

                    if TempCustLedgEntry1."Rem. Amt for WHT" = 0 then
                        TempCustLedgEntry1."Rem. Amt for WHT" := TempCustLedgEntry1."Remaining Amt. (LCY)";

                    if GenJnlLine."Posting Date" <= TempCustLedgEntry1."Pmt. Discount Date" then
                        RemainingAmt :=
                          RemainingAmt +
                          TempCustLedgEntry1."Rem. Amt for WHT" -
                          TempCustLedgEntry1."Original Pmt. Disc. Possible"
                    else
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";

                    if TempCustLedgEntry1."Document Type" = TempCustLedgEntry1."Document Type"::"Credit Memo" then
                        RemainingAmt := RemainingAmt + TempCustLedgEntry1."Rem. Amt for WHT";
                until TempCustLedgEntry1.Next() = 0;

            TempCustLedgEntry.Reset();
            if GenJnlLine."Applies-to ID" <> '' then
                TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
            else
                TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempCustLedgEntry.SetRange("Document Type", TempCustLedgEntry."Document Type"::"Credit Memo");
            if TempCustLedgEntry.FindSet() then
                repeat
                    TempCustLedgEntry.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                       (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt for WHT") -
                                        Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                    then
                        TotAmt := TotAmt + TempCustLedgEntry."Original Pmt. Disc. Possible";

                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or
                       (Abs(TempCustLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                    then begin
                        if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            GenJnlLine.Validate(
                              Amount,
                              -Abs(TempCustLedgEntry."Rem. Amt for WHT" -
                                TempCustLedgEntry."Original Pmt. Disc. Possible"));

                            if TempCustLedgEntry."Document Type" <>
                               TempCustLedgEntry."Document Type"::"Credit Memo"
                            then
                                TotAmt := -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT");

                            RemainingAmt :=
                              RemainingAmt -
                              TempCustLedgEntry."Rem. Amt for WHT" +
                              TempCustLedgEntry."Original Pmt. Disc. Possible";
                        end else begin
                            GenJnlLine.Validate(Amount, Abs(TempCustLedgEntry."Rem. Amt for WHT"));
                            if TempCustLedgEntry."Document Type" <>
                               TempCustLedgEntry."Document Type"::"Credit Memo"
                            then
                                TotAmt := -(TotAmt - TempCustLedgEntry."Rem. Amt for WHT");
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                        end;
                    end else begin
                        if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLine.Validate(
                              Amount, Abs(TotAmt - TempCustLedgEntry."Original Pmt. Disc. Possible"))
                        else
                            GenJnlLine.Validate(Amount, Abs(TotAmt));
                        ExitLoop := true;
                    end;

                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else
                        if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            TotAmt := TotAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            ExitLoop := false;
                        end;
                    GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                    NextEntry :=
                      ProcessPaymentPosted(
                        GenJnlLine,
                        TempCustLedgEntry."Transaction No.",
                        CustLedgerEntry."Entry No.",
                        Currency::Customer);

                    if ExitLoop then
                        exit(NextEntry);
                until TempCustLedgEntry.Next() = 0;

            ExitLoop := false;
            TempCustLedgEntry.Reset();
            if GenJnlLine."Applies-to ID" <> '' then
                TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
            else
                TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");
            TempCustLedgEntry.SetFilter("Document Type", '<>%1', TempCustLedgEntry."Document Type"::"Credit Memo");
            TempCustLedgEntry.SetFilter("Document No.", '<>%1', GenJnlLine."Document No.");
            if TempCustLedgEntry.FindSet() then begin
                repeat
                    TempCustLedgEntry.CalcFields(
                      Amount,
                      "Amount (LCY)",
                      "Remaining Amount",
                      "Remaining Amt. (LCY)",
                      "Original Amount",
                      "Original Amt. (LCY)");

                    if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                       (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt for WHT") -
                                        Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                    then
                        TotAmt := TotAmt + TempCustLedgEntry."Original Pmt. Disc. Possible";

                    if (Abs(RemainingAmt) <= Abs(TotAmt)) or
                       (Abs(TempCustLedgEntry."Rem. Amt for WHT") < Abs(TotAmt))
                    then begin
                        if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                        then begin
                            RemainingAmt :=
                              RemainingAmt -
                              TempCustLedgEntry."Rem. Amt for WHT" +
                              TempCustLedgEntry."Original Pmt. Disc. Possible";

                            if TempCustLedgEntry."Rem. Amt for WHT" <> 0 then
                                GenJnlLine.Validate(
                                  Amount,
                                  -Abs(TempCustLedgEntry."Rem. Amt for WHT" -
                                    TempCustLedgEntry."Original Pmt. Disc. Possible"));

                            if TempCustLedgEntry."Document Type" <>
                               TempCustLedgEntry."Document Type"::"Credit Memo"
                            then
                                TotAmt := (TotAmt - TempCustLedgEntry."Rem. Amt for WHT");
                        end else begin
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            if (AppliedEntryTransNo <> 0) and (TempCustLedgEntry."Transaction No." <> AppliedEntryTransNo) then
                                GenJnlLine.Validate(Amount, 0)
                            else
                                if TempCustLedgEntry."Rem. Amt for WHT" <> 0 then
                                    GenJnlLine.Validate(Amount, -Abs(TempCustLedgEntry."Rem. Amt for WHT"));
                            if TempCustLedgEntry."Document Type" <> TempCustLedgEntry."Document Type"::"Credit Memo" then
                                TotAmt := (TotAmt - TempCustLedgEntry."Rem. Amt for WHT");
                        end;
                    end else begin
                        if (GenJnlLine."Posting Date" <= TempCustLedgEntry."Pmt. Discount Date") and
                           (Abs(TotAmt) >= (Abs(TempCustLedgEntry."Rem. Amt for WHT") -
                                            Abs(TempCustLedgEntry."Original Pmt. Disc. Possible")))
                        then
                            GenJnlLine.Validate(
                              Amount,
                              -Abs(TotAmt - TempCustLedgEntry."Original Pmt. Disc. Possible"))
                        else
                            GenJnlLine.Validate(Amount, -Abs(TotAmt));
                        ExitLoop := true;
                    end;

                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Invoice then
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                    else
                        if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::"Credit Memo" then begin
                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                            RemainingAmt := RemainingAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            TotAmt := TotAmt - TempCustLedgEntry."Rem. Amt for WHT";
                            ExitLoop := false;
                        end;

                    GenJnlLine."Applies-to Doc. No." := TempCustLedgEntry."Document No.";
                    if TempCustLedgEntry."Document Type" = TempCustLedgEntry."Document Type"::Payment then begin
                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
                        GenJnlLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
                    end;

                    NextEntry :=
                      ProcessPaymentPosted(
                        GenJnlLine, TransNo, CustLedgerEntry."Entry No.", Currency::Customer);

                    if ExitLoop then
                        exit(NextEntry);
                until TempCustLedgEntry.Next() = 0;
                exit(NextEntry);
            end;
            exit(
              ProcessPaymentPosted(
                GenJnlLine, TransNo, CustLedgerEntry."Entry No.", Currency::Customer));
        end;
        exit(
          ProcessPaymentPosted(
            GenJnlLine, TransNo, CustLedgerEntry."Entry No.", Currency::Customer));
    end;

    [Scope('OnPrem')]
    procedure ProcessPaymentPosted(var GenJnlLine: Record "Gen. Journal Line"; TransactionNo: Integer; EntryNo: Integer; Source: Option Vendor,Customer) PaymentNo: Integer
    var
        WHTEntry: Record "WHT Entry";
        WHTEntry2: Record "WHT Entry";
        WHTEntry3: Record "WHT Entry";
        WHTEntryTemp: Record "WHT Entry";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempWHT: Record "Temp WHT Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgEntry1: Record "Cust. Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        NoSeries: Codeunit "No. Series";
        PmtDiscToBeDeducted: Decimal;
        PaymentAmount: Decimal;
        PaymentAmountLCY: Decimal;
        AppldAmount: Decimal;
        ExpectedAmount: Decimal;
        PaymentAmount1: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then
            if GenJnlLine."Bill-to/Pay-to No." = '' then begin
                Vendor.Get(GenJnlLine."Account No.");
                if Vendor.ABN <> '' then
                    exit;
            end else begin
                Vendor.Get(GenJnlLine."Bill-to/Pay-to No.");
                if Vendor.ABN <> '' then
                    exit;
            end;
        PaymentAmount := GenJnlLine.Amount;
        PaymentAmount1 := GenJnlLine.Amount;
        PaymentAmountLCY := GenJnlLine."Amount (LCY)";

        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);

        if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
            WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");

        case Source of
            Source::Vendor:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
            Source::Customer:
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
        end;

        WHTEntry.SetRange(Closed, false);
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            WHTEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            WHTEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        end else
            WHTEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");

        if WHTEntry.FindSet() then
            repeat
                WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                if (WHTPostingSetup."Realized WHT Type" =
                    WHTPostingSetup."Realized WHT Type"::Payment)
                then begin
                    WHTEntry3.Reset();
                    WHTEntry3 := WHTEntry;
                    case Source of
                        Source::Vendor:
                            begin
                                if GenJnlLine."Applies-to Doc. No." = '' then
                                    exit;
                                PurchCrMemoHeader.Reset();
                                PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                                PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                                if PurchCrMemoHeader.FindFirst() then begin
                                    TempRemAmt := 0;
                                    VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                    VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                    if VendLedgEntry1.FindFirst() then
                                        VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                    WHTEntryTemp.Reset();
                                    WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                    WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                    WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                    WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                    WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                    if WHTEntryTemp.FindFirst() then begin
                                        TempRemBase := WHTEntryTemp."Unrealized Amount";
                                        TempRemAmt := WHTEntryTemp."Unrealized Base";
                                    end;
                                end;

                                VendLedgEntry.Reset();
                                VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                                if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
                                else
                                    if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
                                        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");

                                if VendLedgEntry.FindFirst() then
                                    VendLedgEntry.CalcFields(Amount, "Remaining Amount");

                                ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                                if VendLedgEntry1."Amount (LCY)" = 0 then
                                    VendLedgEntry1."Rem. Amt for WHT" := 0;
                                if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                   (Abs(PaymentAmount1) >=
                                    (Abs(VendLedgEntry."Rem. Amt for WHT" + VendLedgEntry1."Rem. Amt for WHT") -
                                     Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                                then begin
                                    AppldAmount :=
                                      Round(
                                        ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                         (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                                    WHTEntry3."Remaining Unrealized Base" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Base" -
                                        Round(
                                          ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                           (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));
                                    WHTEntry3."Remaining Unrealized Amount" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Amount" -
                                        Round(
                                          ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                           (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                                end else begin
                                    AppldAmount :=
                                      Round(
                                        (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                        ExpectedAmount);

                                    WHTEntry3."Remaining Unrealized Base" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Base" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                          ExpectedAmount));

                                    WHTEntry3."Remaining Unrealized Amount" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Amount" -
                                        Round(
                                          (PaymentAmount1 * (WHTEntry."Unrealized Amount" + TempRemBase)) /
                                          ExpectedAmount));
                                end;
                                PaymentAmount := PaymentAmount + AppldAmount;
                            end;
                        Source::Customer:
                            begin
                                SalesCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                                SalesCrMemoHeader.SetRange("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
                                if SalesCrMemoHeader.FindFirst() then begin
                                    TempRemAmt := 0;
                                    CustLedgEntry1.Reset();
                                    CustLedgEntry1.SetRange("Document Type", CustLedgEntry1."Document Type"::"Credit Memo");
                                    CustLedgEntry1.SetRange("Document No.", SalesCrMemoHeader."No.");
                                    if CustLedgEntry1.FindFirst() then
                                        CustLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                    WHTEntryTemp.Reset();
                                    WHTEntryTemp.SetRange("Document No.", SalesCrMemoHeader."No.");
                                    WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                    WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
                                    WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                    WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                    if WHTEntryTemp.FindFirst() then begin
                                        TempRemBase := WHTEntryTemp."Unrealized Amount";
                                        TempRemAmt := WHTEntryTemp."Unrealized Base";
                                    end;
                                end;

                                CustLedgEntry.Reset();
                                CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                                CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                                if CustLedgEntry.FindFirst() then
                                    CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                                if CustLedgEntry1."Amount (LCY)" = 0 then
                                    CustLedgEntry1."Rem. Amt for WHT" := 0;

                                ExpectedAmount := -(CustLedgEntry.Amount + CustLedgEntry1.Amount);
                                if (GenJnlLine."Posting Date" <= CustLedgEntry."Pmt. Discount Date") and
                                   (Abs(PaymentAmount1) >=
                                    (Abs(CustLedgEntry."Rem. Amt for WHT" + CustLedgEntry1."Rem. Amt for WHT") -
                                     Abs(CustLedgEntry."Original Pmt. Disc. Possible")))
                                then begin
                                    PmtDiscToBeDeducted := CustLedgEntry."Original Pmt. Disc. Possible" *
                                      (PaymentAmount1 / (ExpectedAmount + CustLedgEntry."Original Pmt. Disc. Possible"));
                                    AppldAmount :=
                                      Round(
                                        ((PaymentAmount1 - PmtDiscToBeDeducted) *
                                         (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                                    WHTEntry3."Remaining Unrealized Base" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Base" -
                                        Round(
                                          ((PaymentAmount1 - PmtDiscToBeDeducted) *
                                           (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));
                                    WHTEntry3."Remaining Unrealized Amount" :=
                                      Round(
                                        WHTEntry."Remaining Unrealized Amount" -
                                        Round(
                                          ((PaymentAmount1 - PmtDiscToBeDeducted) *
                                           (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                                end else begin
                                    AppldAmount :=
                                      Round(
                                        (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount);
                                    GLSetup.Get();
                                    if GLSetup."Manual Sales WHT Calc." and GenJnlLine."WHT Payment" then begin
                                        if Abs(PaymentAmount1) > Abs(WHTEntry."Unrealized Amount") then begin
                                            WHTEntry3."Remaining Unrealized Base" := 0;
                                            WHTEntry3."Remaining Unrealized Amount" := 0;
                                            WHTEntry3."Rem Unrealized Base (LCY)" := 0;
                                            WHTEntry3."Rem Unrealized Amount (LCY)" := 0;
                                        end;
                                    end else begin
                                        WHTEntry3."Remaining Unrealized Base" :=
                                          Round(
                                            WHTEntry."Remaining Unrealized Base" -
                                            Round(
                                              (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount));

                                        WHTEntry3."Remaining Unrealized Amount" :=
                                          Round(
                                            WHTEntry."Remaining Unrealized Amount" -
                                            Round(
                                              (PaymentAmount1 * (WHTEntry."Unrealized Amount" + TempRemBase)) / ExpectedAmount));
                                    end;
                                end;
                                PaymentAmount := PaymentAmount + AppldAmount;
                            end;
                    end;
                    if (WHTEntry."Remaining Unrealized Base" = 0) and
                       (WHTEntry."Remaining Unrealized Amount" = 0)
                    then
                        WHTEntry3.Closed := true;

                    if GenJnlLine."Source Currency Code" <> WHTEntry."Currency Code" then
                        Error(Text1500000);

                    GLSetup.Get();
                    if GLSetup."Manual Sales WHT Calc." and not GenJnlLine."WHT Payment" then
                        AppldAmount := 0;
                    if AppldAmount = 0 then
                        exit(WHTEntry2."Entry No.");

                    WHTEntry2.Init();
                    WHTEntry2."Posting Date" := GenJnlLine."Document Date";
                    WHTEntry2."Entry No." := NextEntryNo();
                    WHTEntry2."Document Date" := WHTEntry."Document Date";
                    WHTEntry2."Document Type" := GenJnlLine."Document Type";
                    WHTEntry2."Document No." := WHTEntry."Document No.";
                    WHTEntry2."Gen. Bus. Posting Group" := WHTEntry."Gen. Bus. Posting Group";
                    WHTEntry2."Gen. Prod. Posting Group" := WHTEntry."Gen. Prod. Posting Group";
                    WHTEntry2."Bill-to/Pay-to No." := WHTEntry."Bill-to/Pay-to No.";
                    WHTEntry2."WHT Bus. Posting Group" := WHTEntry."WHT Bus. Posting Group";
                    WHTEntry2."WHT Prod. Posting Group" := WHTEntry."WHT Prod. Posting Group";
                    WHTEntry2."WHT Revenue Type" := WHTEntry."WHT Revenue Type";
                    WHTEntry2."Unrealized WHT Entry No." := WHTEntry."Entry No.";
                    WHTEntry2."Currency Code" := GenJnlLine."Source Currency Code";
                    WHTEntry2."Applies-to Entry No." := WHTEntry."Entry No.";
                    WHTEntry2."User ID" := UserId;
                    WHTEntry2."External Document No." := GenJnlLine."External Document No.";
                    WHTEntry2."Actual Vendor No." := GenJnlLine."Actual Vendor No.";
                    WHTEntry2."Original Document No." := GenJnlLine."Document No.";
                    WHTEntry2."Source Code" := GenJnlLine."Source Code";
                    WHTEntry2."Transaction No." := TransactionNo;
                    WHTEntry2."WHT %" := WHTEntry."WHT %";
                    case Source of
                        Source::Vendor:
                            begin
                                WHTEntry2.Base := Round(AppldAmount);
                                WHTEntry2.Amount := Round(WHTEntry2.Base * WHTEntry2."WHT %" / 100);
                                WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Purchase;
                                WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                WHTEntry2."WHT Report" := WHTPostingSetup."WHT Report";
                                if GenJnlLine."Certificate Printed" then begin
                                    WHTEntry2."WHT Report Line No" := GenJnlLine."WHT Report Line No.";
                                    TempWHT.SetRange("Document No.", WHTEntry2."Document No.");
                                    if TempWHT.FindFirst() then
                                        WHTEntry2."WHT Certificate No." := TempWHT."WHT Certificate No.";
                                end else begin
                                    if ((Source = Source::Vendor) and
                                        (WHTEntry."Document Type" = WHTEntry."Document Type"::Invoice)) or
                                       ((Source = Source::Customer) and
                                        (WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo"))
                                    then
                                        if (WHTReportLineNo = '') and (WHTEntry2.Amount <> 0) and
                                           (WHTPostingSetup."WHT Report Line No. Series" <> '')
                                        then
                                            WHTReportLineNo := NoSeries.GetNextNo(WHTPostingSetup."WHT Report Line No. Series", WHTEntry2."Posting Date");

                                    WHTEntry2."WHT Report Line No" := WHTReportLineNo;
                                end;
                            end;
                        Source::Customer:
                            begin
                                GLSetup.Get();
                                if GLSetup."Manual Sales WHT Calc." and GenJnlLine."WHT Payment" then begin
                                    WHTEntry2.Amount := GenJnlLine.Amount;
                                    WHTEntry2.Base := Round((WHTEntry2.Amount * 100) / WHTEntry2."WHT %");
                                    WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Sale;
                                end else begin
                                    WHTEntry2.Base := Round(AppldAmount);
                                    WHTEntry2.Amount := Round(WHTEntry2.Base * WHTEntry2."WHT %" / 100);
                                    WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Sale;
                                end;
                            end;
                    end;

                    WHTEntry2."Payment Amount" := PaymentAmount1;
                    if WHTEntry2."Currency Code" <> '' then begin
                        CurrFactor :=
                          CurrExchRate.ExchangeRate(
                            WHTEntry2."Posting Date", WHTEntry2."Currency Code");

                        WHTEntry2."Base (LCY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date",
                              WHTEntry2."Currency Code",
                              WHTEntry2.Base, CurrFactor));

                        WHTEntry2."Amount (LCY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              GenJnlLine."Document Date",
                              WHTEntry2."Currency Code",
                              WHTEntry2.Amount, CurrFactor));
                    end else begin
                        WHTEntry2."Amount (LCY)" := WHTEntry2.Amount;
                        WHTEntry2."Base (LCY)" := WHTEntry2.Base;
                    end;

                    WHTEntry2.Insert();
                    TType := TType::Purchase;
                    WHTEntry3.Modify();

                    WHTEntry3.Reset();
                    WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                    WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                    WHTEntry3.CalcSums(Amount, "Amount (LCY)");
                    if (Abs(Abs(WHTEntry3.Amount) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                       (Abs(Abs(WHTEntry3.Amount) - Abs(WHTEntry."Unrealized Amount")) > 0)
                    then begin
                        WHTEntry2."WHT Difference" := WHTEntry."Unrealized Amount" - WHTEntry3.Amount;
                        WHTEntry2.Amount := WHTEntry2.Amount - WHTEntry2."WHT Difference";
                        WHTEntry2.Modify();
                    end;

                    if (Abs(Abs(WHTEntry3."Amount (LCY)") -
                          Abs(WHTEntry."Unrealized Amount (LCY)")) < 0.1) and
                       (Abs(Abs(WHTEntry3."Amount (LCY)") - Abs(WHTEntry."Unrealized Amount (LCY)")) > 0)
                    then begin
                        WHTEntry2."Amount (LCY)" := WHTEntry2."Amount (LCY)" -
                          WHTEntry."Unrealized Amount (LCY)" + WHTEntry3."Amount (LCY)";
                        WHTEntry2.Modify();
                    end;
                end;
            until (WHTEntry.Next() = 0);

        if (WHTPostingSetup."Realized WHT Type" =
            WHTPostingSetup."Realized WHT Type"::Payment)
        then
            exit(WHTEntry2."Entry No." + 1);
    end;

    [Scope('OnPrem')]
    procedure CheckPmtDisc(PostingDate: Date; PmtDiscDate: Date; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal; Amount4: Decimal): Boolean
    begin
        if (PostingDate <= PmtDiscDate) and
           (Amount1 >= (Amount2 - Amount3)) and
           (Amount4 >= (Amount2 - Amount3))
        then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure PreprintingWHT(var GenJournalLine: Record "Gen. Journal Line")
    var
        WHTEntry: Record "WHT Entry";
        TempWHTEntry: Record "Temp WHT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        WHTExists: Boolean;
        NoSeriesCode: Code[20];
    begin
        if GenJournalLine."Certificate Printed" then
            Error(Text1500001);
        if GenJournalLine."Document Type" <> GenJournalLine."Document Type"::Payment then
            exit;
        if GenJournalLine."Skip WHT" then
            exit;
        PurchSetup.Get();
        if GenJournalLine."Applies-to Doc. No." <> '' then begin
            WHTEntry.Reset();
            WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
            if GenJournalLine."Applies-to Doc. Type" = GenJournalLine."Applies-to Doc. Type"::Invoice then
                WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);
            if GenJournalLine."Applies-to Doc. Type" = GenJournalLine."Applies-to Doc. Type"::"Credit Memo" then
                WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
            WHTEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
            if WHTEntry.FindFirst() then begin
                WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                WHTPostingSetup.TestField("WHT Report Line No. Series");
                GenJournalLine."WHT Report Line No." := NoSeries.GetNextNo(WHTPostingSetup."WHT Report Line No. Series", GenJournalLine."Posting Date");
            end;
        end else begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetRange("Applies-to ID", GenJournalLine."Document No.");
            if VendLedgEntry.FindSet() then
                repeat
                    WHTEntry.Reset();
                    WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
                    if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice then
                        WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);
                    if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" then
                        WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                    WHTEntry.SetRange("Document No.", VendLedgEntry."Document No.");
                    if not WHTExists then
                        if WHTEntry.FindFirst() then begin
                            WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
                            WHTPostingSetup.TestField("WHT Report Line No. Series");
                            NoSeriesCode := WHTPostingSetup."WHT Report Line No. Series";
                            WHTExists := true;
                        end;
                until VendLedgEntry.Next() = 0;
            if NoSeriesCode <> '' then
                GenJournalLine."WHT Report Line No." := NoSeries.GetNextNo(NoSeriesCode, GenJournalLine."Posting Date");
        end;

        ApplyTempVendInvoiceWHT(GenJournalLine);
        TempWHTEntry.Reset();
        TempWHTEntry.SetCurrentKey("Bill-to/Pay-to No.", "Original Document No.", "WHT Revenue Type");
        TempWHTEntry.SetRange("Original Document No.", GenJournalLine."Document No.");
        if TempWHTEntry.FindFirst() then
            if TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Payment then
                REPORT.Run(REPORT::"WHT certificate preprint", PurchSetup."Print Dialog", false, TempWHTEntry);
        GenJournalLine."Certificate Printed" := true;
        GenJournalLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure CheckApplicationSalesWHT(var SalesHeader: Record "Sales Header")
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry";
        WHTEntry: Record "WHT Entry";
        SalesLine1: Record "Sales Line";
    begin
        if SalesHeader."Applies-to Doc. No." <> '' then
            TempCustLedgEntry.SetRange("Document No.", SalesHeader."Applies-to Doc. No.")
        else
            TempCustLedgEntry.SetRange("Applies-to ID", SalesHeader."Applies-to ID");

        if TempCustLedgEntry.FindSet() then
            repeat
                WHTEntry.Reset();
                WHTEntry.SetRange("Document No.", TempCustLedgEntry."Document No.");
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
                if WHTEntry.FindSet() then
                    repeat
                        SalesLine1.Reset();
                        SalesLine1.SetRange("Document No.", SalesHeader."No.");
                        SalesLine1.SetRange("Document Type", SalesHeader."Document Type");
                        SalesLine1.SetRange("WHT Business Posting Group", WHTEntry."WHT Bus. Posting Group");
                        SalesLine1.SetRange("WHT Product Posting Group", WHTEntry."WHT Prod. Posting Group");
                        if not SalesLine1.FindFirst() then
                            Error(Text1500003);
                    until WHTEntry.Next() = 0;
            until TempCustLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckApplicationPurchWHT(var PurchHeader: Record "Purchase Header")
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        PurchLine1: Record "Purchase Line";
    begin
        if PurchHeader."Applies-to Doc. No." <> '' then
            TempVendLedgEntry.SetRange("Document No.", PurchHeader."Applies-to Doc. No.")
        else
            TempVendLedgEntry.SetRange("Applies-to ID", PurchHeader."Applies-to ID");

        if TempVendLedgEntry.FindSet() then
            repeat
                WHTEntry.Reset();
                WHTEntry.SetRange("Document No.", TempVendLedgEntry."Document No.");
                WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                if WHTEntry.FindSet() then
                    repeat
                        PurchLine1.Reset();
                        PurchLine1.SetRange("Document No.", PurchHeader."No.");
                        PurchLine1.SetRange("Document Type", PurchHeader."Document Type");
                        PurchLine1.SetRange("WHT Business Posting Group", WHTEntry."WHT Bus. Posting Group");
                        PurchLine1.SetRange("WHT Product Posting Group", WHTEntry."WHT Prod. Posting Group");
                        if not PurchLine1.FindFirst() then
                            Error(Text1500003);
                    until WHTEntry.Next() = 0;
            until TempVendLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckApplicationGenSalesWHT(var GenJnlLine: Record "Gen. Journal Line")
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry";
        WHTEntry: Record "WHT Entry";
    begin
        if (GenJnlLine."Applies-to Doc. No." <> '') or
           (GenJnlLine."Applies-to ID" <> '')
        then begin
            TempCustLedgEntry.Reset();
            if GenJnlLine."Applies-to Doc. No." <> '' then
                TempCustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.")
            else
                TempCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            if TempCustLedgEntry.FindSet() then
                repeat
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", TempCustLedgEntry."Document No.");
                    WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Sale);
                    if WHTEntry.FindSet() then
                        repeat
                            GenJnlLine.SetRange("WHT Business Posting Group", WHTEntry."WHT Bus. Posting Group");
                            GenJnlLine.SetRange("WHT Product Posting Group", WHTEntry."WHT Prod. Posting Group");
                            if not GenJnlLine.FindFirst() then
                                Error(Text1500003);
                        until WHTEntry.Next() = 0;
                until TempCustLedgEntry.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckApplicationGenPurchWHT(var GenJnlLine: Record "Gen. Journal Line")
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
    begin
        if (GenJnlLine."Applies-to Doc. No." <> '') or
           (GenJnlLine."Applies-to ID" <> '')
        then begin
            TempVendLedgEntry.Reset();
            if GenJnlLine."Applies-to Doc. No." <> '' then
                TempVendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.")
            else
                TempVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            if TempVendLedgEntry.FindSet() then
                repeat
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", TempVendLedgEntry."Document No.");
                    WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                    if WHTEntry.FindSet() then
                        repeat
                            GenJnlLine.SetRange("WHT Business Posting Group", WHTEntry."WHT Bus. Posting Group");
                            GenJnlLine.SetRange("WHT Product Posting Group", WHTEntry."WHT Prod. Posting Group");
                            if not GenJnlLine.FindFirst() then
                                Error(Text1500003);
                        until WHTEntry.Next() = 0;
                until TempVendLedgEntry.Next() = 0;
        end;
    end;

    procedure CalcVendExtraWHTForEarliest(var GenJnlLine: Record "Gen. Journal Line") WHTAmount: Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        TotalWHTBase: Decimal;
        WHTBase: Decimal;
        TotalWHTAmount: Decimal;
        TotalWHTAmount2: Decimal;
        TotalWHTAmount3: Decimal;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PaymentAmount1: Decimal;
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry1: Record "Vendor Ledger Entry";
        WHTEntryTemp: Record "WHT Entry";
        AppldAmount: Decimal;
        ExpectedAmount: Decimal;
        WHTEntry3: Record "WHT Entry";
        Diff: Decimal;
        RemainingAmt: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then
            if GenJnlLine."Bill-to/Pay-to No." = '' then begin
                Vendor.Get(GenJnlLine."Account No.");
                if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                    exit;
            end else begin
                Vendor.Get(GenJnlLine."Bill-to/Pay-to No.");
                if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                    exit;
            end;

        WHTAmount := 0;
        TotalWHTBase := 0;
        WHTBase := 0;
        if WHTPostingSetup.Get(
             GenJnlLine."WHT Business Posting Group",
             GenJnlLine."WHT Product Posting Group")
        then
            if (WHTPostingSetup."Realized WHT Type" =
                WHTPostingSetup."Realized WHT Type"::Earliest)
            then
                if GenJnlLine."WHT Absorb Base" <> 0 then
                    WHTBase := Abs(GenJnlLine."WHT Absorb Base")
                else
                    WHTBase := Abs(GenJnlLine.Amount);
        TotalWHTBase := WHTBase;
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            VendorLedgerEntry.Reset();
            VendorLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment) then
                VendorLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  VendorLedgerEntry."Document Type"::Invoice);

            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund) then
                VendorLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  VendorLedgerEntry."Document Type"::"Credit Memo");

            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) then
                VendorLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  VendorLedgerEntry."Document Type"::Payment);

            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo") then
                VendorLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  VendorLedgerEntry."Document Type"::Refund);

            if VendorLedgerEntry.FindFirst() then begin
                if GenJnlLine."Currency Code" <> VendorLedgerEntry."Currency Code" then
                    Error(Text1500000);

                if VendorLedgerEntry.Prepayment then begin
                    TotalWHTAmount := 0;
                    PaymentAmount1 := GenJnlLine.Amount;
                    WHTEntry.Reset();
                    WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
                    WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                    if GenJnlLine."Applies-to Doc. No." <> '' then begin
                        WHTEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                        WHTEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                    end else
                        WHTEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
                    if WHTEntry.FindSet() then begin
                        repeat
                            PurchCrMemoHeader.SetRange(
                              "Applies-to Doc. Type",
                              PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                            PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                            if PurchCrMemoHeader.FindFirst() then begin
                                TempRemAmt := 0;
                                VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                if VendLedgEntry1.FindFirst() then
                                    VendLedgEntry1.CalcFields(Amount, "Remaining Amount");
                                WHTEntryTemp.Reset();
                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                if WHTEntryTemp.FindFirst() then
                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                            end;

                            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                            if VendLedgEntry.FindFirst() then
                                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                            ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                            if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                               (Abs(PaymentAmount1) >= (Abs(VendLedgEntry."Remaining Amount" +
                                                          VendLedgEntry1."Remaining Amount") -
                                                        Abs(VendLedgEntry."Original Pmt. Disc. Possible")))
                            then
                                AppldAmount :=
                                  Round(
                                    ((PaymentAmount1 - VendLedgEntry."Original Pmt. Disc. Possible") *
                                     (WHTEntry."Unrealized Base" + TempRemAmt)) / ExpectedAmount)
                            else
                                AppldAmount :=
                                  Round(
                                    (PaymentAmount1 * (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                    ExpectedAmount);
                            TotalWHTAmount := Round(TotalWHTAmount + AppldAmount * WHTEntry."WHT %" / 100);
                        until WHTEntry.Next() = 0;

                        WHTEntry3.Reset();
                        WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                        WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                        WHTEntry3.CalcSums(Amount, "Amount (LCY)");
                        if (Abs(Abs(WHTEntry3.Amount) + Abs(TotalWHTAmount) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                           (Abs(Abs(WHTEntry3.Amount) + Abs(TotalWHTAmount) - Abs(WHTEntry."Unrealized Amount")) > 0)
                        then begin
                            Diff := WHTEntry."Unrealized Amount" - (WHTEntry3.Amount + TotalWHTAmount);
                            TotalWHTAmount := TotalWHTAmount + Diff;
                        end;

                        exit(Round(TotalWHTAmount));
                    end
                end else begin
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
                    if WHTEntry.FindFirst() then
                        if WHTPostingSetup.Get(
                             WHTEntry."WHT Bus. Posting Group",
                             WHTEntry."WHT Prod. Posting Group")
                        then
                            if ((WHTPostingSetup."Realized WHT Type" =
                                 WHTPostingSetup."Realized WHT Type"::Earliest) and
                                (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                            then begin
                                TotAmt := 0;
                                TotAmt := GenJnlLine.Amount;
                                TempVendLedgEntry.Reset();
                                TempVendLedgEntry.SetRange("Entry No.", VendorLedgerEntry."Entry No.");
                                if TempVendLedgEntry.FindSet() then begin
                                    TempVendLedgEntry.CalcFields(
                                      Amount, "Amount (LCY)",
                                      "Remaining Amount", "Remaining Amt. (LCY)");

                                    if CheckPmtDisc(
                                         GenJnlLine."Posting Date",
                                         TempVendLedgEntry."Pmt. Discount Date",
                                         Abs(TempVendLedgEntry."Amount to Apply"),
                                         Abs(TempVendLedgEntry."Remaining Amount"),
                                         Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"),
                                         Abs(TotAmt))
                                    then
                                        TotAmt := TotAmt - TempVendLedgEntry."Original Pmt. Disc. Possible";

                                    if Abs(WHTEntry."Rem Realized Base") >= WHTBase then
                                        TotAmt := 0
                                    else
                                        TotAmt := TotAmt - Abs(WHTEntry."Rem Realized Base");
                                end;
                                WHTBase := TotAmt;
                            end;
                end;
            end;
        end else
            if GenJnlLine."Applies-to ID" <> '' then begin
                if ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) or
                    (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund))
                then begin
                    VendorLedgerEntry.Reset();
                    VendorLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    VendorLedgerEntry.SetFilter(
                      "Document Type",
                      '%1|%2',
                      VendorLedgerEntry."Document Type"::Payment,
                      VendorLedgerEntry."Document Type"::"Credit Memo");
                    if VendorLedgerEntry.FindSet() then
                        repeat
                            WHTEntry.Reset();
                            WHTEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
                            if WHTEntry.FindSet() then
                                repeat
                                    if WHTPostingSetup.Get(
                                         WHTEntry."WHT Bus. Posting Group",
                                         WHTEntry."WHT Prod. Posting Group")
                                    then
                                        if ((WHTPostingSetup."Realized WHT Type" =
                                             WHTPostingSetup."Realized WHT Type"::Earliest) and
                                            (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                                        then
                                            if TotalWHTBase > Abs(WHTEntry."Rem Realized Base") then begin
                                                TotalWHTBase := TotalWHTBase - Abs(WHTEntry."Rem Realized Base");
                                                if (((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo")) or
                                                    ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::Payment)))
                                                then
                                                    WHTBase := WHTBase - Abs(WHTEntry."Rem Realized Base");
                                            end else begin
                                                if (TotalWHTBase > 0) and (Abs(TotalWHTBase) <= Abs(WHTEntry."Rem Realized Base")) then
                                                    TotalWHTBase := TotalWHTBase - TotalWHTBase;
                                                if (((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo")) or
                                                    ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::Payment)))
                                                then
                                                    WHTBase := 0;
                                            end;
                                until WHTEntry.Next() = 0;
                        until VendorLedgerEntry.Next() = 0;
                end;

                if ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment) or
                    (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo"))
                then begin
                    TotalWHTAmount := 0;
                    TotalWHTAmount2 := 0;
                    TotalWHTAmount3 := 0;
                    RemainingAmt := 0;
                    TotAmt := 0;
                    TempVendLedgEntry1.Reset();
                    TempVendLedgEntry1.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    TempVendLedgEntry1.SetRange(Open, true);
                    if GenJnlLine."Bill-to/Pay-to No." = '' then
                        TempVendLedgEntry1.SetRange("Buy-from Vendor No.", GenJnlLine."Account No.")
                    else
                        TempVendLedgEntry1.SetRange("Buy-from Vendor No.", GenJnlLine."Bill-to/Pay-to No.");

                    if TempVendLedgEntry1.FindSet() then
                        repeat
                            TempVendLedgEntry1.CalcFields(
                              Amount, "Amount (LCY)",
                              "Remaining Amount", "Remaining Amt. (LCY)");

                            RemainingAmt := RemainingAmt + TempVendLedgEntry1."Remaining Amt. (LCY)";
                        until TempVendLedgEntry1.Next() = 0;

                    TotAmt := Abs(GenJnlLine."Amount (LCY)");
                    CurrFactor :=
                      CurrExchRate.ExchangeRate(
                        GenJnlLine."Document Date", GenJnlLine."Currency Code");

                    VendorLedgerEntry.Reset();
                    VendorLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Refund);
                    if VendorLedgerEntry.FindSet() then
                        repeat
                            WHTEntry.Reset();
                            WHTEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
                            if WHTEntry.FindSet() then
                                repeat
                                    if WHTPostingSetup.Get(
                                         WHTEntry."WHT Bus. Posting Group",
                                         WHTEntry."WHT Prod. Posting Group")
                                    then
                                        if ((WHTPostingSetup."Realized WHT Type" =
                                             WHTPostingSetup."Realized WHT Type"::Earliest) and
                                            (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                                        then
                                            if TotalWHTBase > Abs(WHTEntry."Rem Realized Base") then begin
                                                TotalWHTBase := TotalWHTBase - Abs(WHTEntry."Rem Realized Base");
                                                if GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo" then
                                                    WHTBase := WHTBase - Abs(WHTEntry."Rem Realized Base");
                                            end else
                                                if (TotalWHTBase > 0) and (Abs(TotalWHTBase) <= Abs(WHTEntry."Rem Realized Base")) then begin
                                                    TotalWHTBase := 0;
                                                    if GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo" then
                                                        WHTBase := 0;
                                                end;
                                until WHTEntry.Next() = 0;
                        until VendorLedgerEntry.Next() = 0;

                    VendorLedgerEntry.Reset();
                    VendorLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
                    if VendorLedgerEntry.FindSet() then begin
                        repeat
                            if GenJnlLine."Currency Code" <> VendorLedgerEntry."Currency Code" then
                                Error(Text1500000);

                            if VendorLedgerEntry.Prepayment then begin
                                TempVendLedgEntry.Reset();
                                TempVendLedgEntry.SetRange("Entry No.", VendorLedgerEntry."Entry No.");
                                if TempVendLedgEntry.FindSet() then begin
                                    TempVendLedgEntry.CalcFields(
                                      Amount, "Amount (LCY)",
                                      "Remaining Amount", "Remaining Amt. (LCY)");

                                    if CheckPmtDisc(
                                         GenJnlLine."Posting Date",
                                         TempVendLedgEntry."Pmt. Discount Date",
                                         CurrExchRate.ExchangeAmtFCYToLCY(
                                           GenJnlLine."Document Date",
                                           GenJnlLine."Currency Code",
                                           Abs(TempVendLedgEntry."Amount to Apply"), CurrFactor),
                                         Abs(TempVendLedgEntry."Remaining Amt. (LCY)"),
                                         CurrExchRate.ExchangeAmtFCYToLCY(
                                           GenJnlLine."Document Date",
                                           GenJnlLine."Currency Code",
                                           Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), CurrFactor),
                                         Abs(TotAmt))
                                    then
                                        TotAmt := TotAmt -
                                          CurrExchRate.ExchangeAmtFCYToLCY(
                                            GenJnlLine."Document Date",
                                            GenJnlLine."Currency Code",
                                            TempVendLedgEntry."Original Pmt. Disc. Possible", CurrFactor);

                                    if (Abs(RemainingAmt) < Abs(TotAmt)) or
                                       (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") < Abs(TotAmt))
                                    then begin
                                        if CheckPmtDisc(
                                             GenJnlLine."Posting Date",
                                             TempVendLedgEntry."Pmt. Discount Date",
                                             CurrExchRate.ExchangeAmtFCYToLCY(
                                               GenJnlLine."Document Date",
                                               GenJnlLine."Currency Code",
                                               Abs(TempVendLedgEntry."Amount to Apply"), CurrFactor),
                                             Abs(TempVendLedgEntry."Remaining Amt. (LCY)"),
                                             CurrExchRate.ExchangeAmtFCYToLCY(
                                               GenJnlLine."Document Date",
                                               GenJnlLine."Currency Code",
                                               Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), CurrFactor),
                                             Abs(TotAmt))
                                        then begin
                                            GenJnlLine.Validate(
                                              Amount,
                                              Abs(TempVendLedgEntry."Remaining Amt. (LCY)" -
                                                CurrExchRate.ExchangeAmtFCYToLCY(
                                                  GenJnlLine."Document Date",
                                                  GenJnlLine."Currency Code",
                                                  TempVendLedgEntry."Original Pmt. Disc. Possible", CurrFactor)));

                                            if TempVendLedgEntry."Document Type" <>
                                               TempVendLedgEntry."Document Type"::"Credit Memo"
                                            then
                                                TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";

                                            RemainingAmt :=
                                              RemainingAmt -
                                              TempVendLedgEntry."Remaining Amt. (LCY)";
                                        end else begin
                                            GenJnlLine.Validate(Amount, Abs(TempVendLedgEntry."Remaining Amt. (LCY)"));
                                            if TempVendLedgEntry."Document Type" <>
                                               TempVendLedgEntry."Document Type"::"Credit Memo"
                                            then
                                                TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                                            RemainingAmt := RemainingAmt - TempVendLedgEntry."Remaining Amt. (LCY)";
                                        end;
                                    end else begin
                                        if CheckPmtDisc(
                                             GenJnlLine."Posting Date",
                                             TempVendLedgEntry."Pmt. Discount Date",
                                             CurrExchRate.ExchangeAmtFCYToLCY(
                                               GenJnlLine."Document Date",
                                               GenJnlLine."Currency Code",
                                               Abs(TempVendLedgEntry."Amount to Apply"), CurrFactor),
                                             Abs(TempVendLedgEntry."Remaining Amt. (LCY)"),
                                             CurrExchRate.ExchangeAmtFCYToLCY(
                                               GenJnlLine."Document Date",
                                               GenJnlLine."Currency Code",
                                               Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), CurrFactor),
                                             Abs(TotAmt))
                                        then
                                            GenJnlLine.Validate(Amount, TotAmt +
                                              CurrExchRate.ExchangeAmtFCYToLCY(
                                                GenJnlLine."Document Date",
                                                GenJnlLine."Currency Code",
                                                TempVendLedgEntry."Original Pmt. Disc. Possible", CurrFactor))
                                        else
                                            GenJnlLine.Validate(Amount, TotAmt);
                                        TotAmt := 0;
                                    end;

                                    if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::Invoice then
                                        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice
                                    else begin
                                        if TempVendLedgEntry."Document Type" = TempVendLedgEntry."Document Type"::"Credit Memo" then
                                            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::"Credit Memo";
                                        RemainingAmt := RemainingAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                                        TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                                    end;
                                    GenJnlLine."Applies-to Doc. No." := TempVendLedgEntry."Document No.";
                                    PaymentAmount1 := GenJnlLine.Amount;
                                    WHTEntry.Reset();
                                    WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
                                    WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                    if GenJnlLine."Applies-to Doc. No." <> '' then begin
                                        WHTEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                                        WHTEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                                    end else
                                        WHTEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
                                    if WHTEntry.FindSet() then
                                        repeat
                                            PurchCrMemoHeader.Reset();
                                            PurchCrMemoHeader.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                                            PurchCrMemoHeader.SetRange("Applies-to Doc. Type", PurchCrMemoHeader."Applies-to Doc. Type"::Invoice);
                                            if PurchCrMemoHeader.FindFirst() then begin
                                                TempRemAmt := 0;
                                                VendLedgEntry1.SetRange("Document Type", VendLedgEntry1."Document Type"::"Credit Memo");
                                                VendLedgEntry1.SetRange("Document No.", PurchCrMemoHeader."No.");
                                                if VendLedgEntry1.FindFirst() then
                                                    VendLedgEntry1.CalcFields(Amount, "Remaining Amount",
                                                      "Amount (LCY)", "Remaining Amt. (LCY)");
                                                WHTEntryTemp.Reset();
                                                WHTEntryTemp.SetRange("Document Type", WHTEntry."Document Type"::"Credit Memo");
                                                WHTEntryTemp.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                                                WHTEntryTemp.SetRange("Document No.", PurchCrMemoHeader."No.");
                                                WHTEntryTemp.SetRange("WHT Bus. Posting Group", WHTEntry."WHT Bus. Posting Group");
                                                WHTEntryTemp.SetRange("WHT Prod. Posting Group", WHTEntry."WHT Prod. Posting Group");
                                                if WHTEntryTemp.FindFirst() then begin
                                                    TempRemBase := WHTEntryTemp."Unrealized Amount";
                                                    TempRemAmt := WHTEntryTemp."Unrealized Base";
                                                end;
                                            end;

                                            VendLedgEntry.Reset();
                                            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                                            if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::Invoice then
                                                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
                                            else
                                                if GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo" then
                                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                                            if VendLedgEntry.FindFirst() then
                                                VendLedgEntry.CalcFields(Amount, "Remaining Amount",
                                                  "Amount (LCY)", "Remaining Amt. (LCY)");
                                            ExpectedAmount := -(VendLedgEntry.Amount + VendLedgEntry1.Amount);
                                            if (GenJnlLine."Posting Date" <= VendLedgEntry."Pmt. Discount Date") and
                                               (Abs(PaymentAmount1) >=
                                                (Abs(VendLedgEntry."Remaining Amt. (LCY)" + VendLedgEntry1."Remaining Amt. (LCY)") -
                                                 Abs(
                                                   CurrExchRate.ExchangeAmtFCYToLCY(
                                                     GenJnlLine."Document Date",
                                                     GenJnlLine."Currency Code",
                                                     TempVendLedgEntry."Original Pmt. Disc. Possible", CurrFactor))))
                                            then
                                                AppldAmount :=
                                                  Round(
                                                    ((PaymentAmount1 -
                                                      CurrExchRate.ExchangeAmtFCYToLCY(
                                                        GenJnlLine."Document Date",
                                                        GenJnlLine."Currency Code",
                                                        TempVendLedgEntry."Original Pmt. Disc. Possible", CurrFactor)) *
                                                     (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                                    ExpectedAmount)
                                            else
                                                AppldAmount :=
                                                  Round(
                                                    (PaymentAmount1 *
                                                     (WHTEntry."Unrealized Base" + TempRemAmt)) /
                                                    ExpectedAmount);
                                            TotalWHTAmount := Round(TotalWHTAmount + AppldAmount * WHTEntry."WHT %" / 100);
                                            if GenJnlLine."Currency Code" <> '' then
                                                TotalWHTAmount2 :=
                                                  Round(
                                                    TotalWHTAmount2 +
                                                    Round(
                                                      CurrExchRate.ExchangeAmtLCYToFCY(
                                                        GenJnlLine."Document Date",
                                                        GenJnlLine."Currency Code",
                                                        AppldAmount * WHTEntry."WHT %" / 100,
                                                        CurrFactor)))
                                            else
                                                TotalWHTAmount2 := TotalWHTAmount;

                                            WHTEntry3.Reset();
                                            WHTEntry3.SetCurrentKey("Applies-to Entry No.");
                                            WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
                                            WHTEntry3.CalcSums(Amount, "Amount (LCY)");
                                            if (Abs(Abs(WHTEntry3.Amount) + Abs(TotalWHTAmount2) - Abs(WHTEntry."Unrealized Amount")) < 0.1) and
                                               (Abs(Abs(WHTEntry3.Amount) + Abs(TotalWHTAmount2) - Abs(WHTEntry."Unrealized Amount")) > 0)
                                            then begin
                                                Diff := WHTEntry."Unrealized Amount" - (WHTEntry3.Amount + TotalWHTAmount2);
                                                TotalWHTAmount2 := TotalWHTAmount2 + Diff;
                                            end;

                                        until WHTEntry.Next() = 0;
                                end;
                            end else begin
                                WHTEntry.Reset();
                                WHTEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
                                if WHTEntry.FindSet() then
                                    repeat
                                        if WHTPostingSetup.Get(
                                             WHTEntry."WHT Bus. Posting Group",
                                             WHTEntry."WHT Prod. Posting Group")
                                        then
                                            if ((WHTPostingSetup."Realized WHT Type" =
                                                 WHTPostingSetup."Realized WHT Type"::Earliest) and
                                                (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                                            then begin
                                                TempVendLedgEntry.Reset();
                                                TempVendLedgEntry.SetRange("Entry No.", VendorLedgerEntry."Entry No.");
                                                if TempVendLedgEntry.FindSet() then begin
                                                    TempVendLedgEntry.CalcFields(
                                                      Amount, "Amount (LCY)",
                                                      "Remaining Amount", "Remaining Amt. (LCY)");

                                                    if CheckPmtDisc(
                                                         GenJnlLine."Posting Date",
                                                         TempVendLedgEntry."Pmt. Discount Date",
                                                         CurrExchRate.ExchangeAmtFCYToLCY(
                                                           GenJnlLine."Document Date",
                                                           GenJnlLine."Currency Code",
                                                           Abs(TempVendLedgEntry."Amount to Apply"), CurrFactor),
                                                         Abs(TempVendLedgEntry."Remaining Amt. (LCY)"),
                                                         CurrExchRate.ExchangeAmtFCYToLCY(
                                                           GenJnlLine."Document Date",
                                                           GenJnlLine."Currency Code",
                                                           Abs(TempVendLedgEntry."Original Pmt. Disc. Possible"), CurrFactor),
                                                         Abs(TotAmt))
                                                    then
                                                        TotAmt := TotAmt -
                                                          CurrExchRate.ExchangeAmtFCYToLCY(
                                                            GenJnlLine."Document Date",
                                                            GenJnlLine."Currency Code",
                                                            TempVendLedgEntry."Original Pmt. Disc. Possible", CurrFactor);

                                                    if (Abs(RemainingAmt) < Abs(TotAmt)) or
                                                       (Abs(TempVendLedgEntry."Remaining Amt. (LCY)") < Abs(TotAmt))
                                                    then begin
                                                        if TempVendLedgEntry."Document Type" <>
                                                           TempVendLedgEntry."Document Type"::"Credit Memo"
                                                        then
                                                            TotAmt := TotAmt + TempVendLedgEntry."Remaining Amt. (LCY)";
                                                        RemainingAmt := RemainingAmt - TempVendLedgEntry."Remaining Amt. (LCY)";
                                                    end else
                                                        TotAmt := 0;
                                                end;
                                            end;
                                    until WHTEntry.Next() = 0;
                            end;
                        until VendorLedgerEntry.Next() = 0;
                        if TotAmt > 0 then begin
                            TotalWHTAmount3 := Round(TotalWHTAmount3 + TotAmt * WHTPostingSetup."WHT %" / 100);
                            if GenJnlLine."Currency Code" <> '' then
                                TotalWHTAmount2 :=
                                  Round(
                                    TotalWHTAmount2 +
                                    Round(
                                      CurrExchRate.ExchangeAmtLCYToFCY(
                                        GenJnlLine."Document Date",
                                        GenJnlLine."Currency Code",
                                        TotAmt * WHTPostingSetup."WHT %" / 100,
                                        CurrFactor)))
                            else
                                TotalWHTAmount2 := TotalWHTAmount2 + TotalWHTAmount3;
                        end else
                            WHTBase := 0;
                        if Round(TotalWHTAmount2) <> 0 then
                            exit(Round(TotalWHTAmount2));
                    end;
                end;
            end;

        WHTAmount := Round(WHTBase * WHTPostingSetup."WHT %" / 100);

        if WHTPostingSetup.Get(GenJnlLine."WHT Business Posting Group", GenJnlLine."WHT Product Posting Group") then
            if WHTPostingSetup."Realized WHT Type" = WHTPostingSetup."Realized WHT Type"::Earliest then
                if WHTBase < WHTPostingSetup."WHT Minimum Invoice Amount" then
                    WHTAmount := 0;
    end;

    [Scope('OnPrem')]
    procedure CalcCustExtraWHTForEarliest(var GenJnlLine: Record "Gen. Journal Line") WHTAmount: Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        WHTEntry: Record "WHT Entry";
        TotalWHTBase: Decimal;
        WHTBase: Decimal;
        IsRefund: Boolean;
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then
            if GenJnlLine."Bill-to/Pay-to No." = '' then begin
                Vendor.Get(GenJnlLine."Account No.");
                if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                    exit;
            end else begin
                Vendor.Get(GenJnlLine."Bill-to/Pay-to No.");
                if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
                    exit;
            end;

        WHTAmount := 0;
        TotalWHTBase := 0;
        WHTBase := 0;
        if WHTPostingSetup.Get(
             GenJnlLine."WHT Business Posting Group",
             GenJnlLine."WHT Product Posting Group")
        then
            if (WHTPostingSetup."Realized WHT Type" =
                WHTPostingSetup."Realized WHT Type"::Earliest)
            then
                if GenJnlLine."WHT Absorb Base" <> 0 then
                    WHTBase := Abs(GenJnlLine."WHT Absorb Base")
                else
                    WHTBase := Abs(GenJnlLine.Amount);
        TotalWHTBase := WHTBase;
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            CustLedgerEntry.Reset();
            CustLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment) then
                CustLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  CustLedgerEntry."Document Type"::Invoice);

            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund) then
                CustLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  CustLedgerEntry."Document Type"::"Credit Memo");

            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) then
                CustLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  CustLedgerEntry."Document Type"::Payment);

            if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo") then
                CustLedgerEntry.SetFilter(
                  "Document Type",
                  '%1',
                  CustLedgerEntry."Document Type"::Refund);

            if CustLedgerEntry.FindFirst() then
                if not CustLedgerEntry.Prepayment then begin
                    WHTEntry.Reset();
                    WHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                    if WHTEntry.FindFirst() then
                        if WHTPostingSetup.Get(
                             WHTEntry."WHT Bus. Posting Group",
                             WHTEntry."WHT Prod. Posting Group")
                        then
                            if ((WHTPostingSetup."Realized WHT Type" =
                                 WHTPostingSetup."Realized WHT Type"::Earliest) and
                                (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                            then
                                if Abs(WHTEntry."Rem Realized Base") >= WHTBase then
                                    WHTBase := 0
                                else
                                    WHTBase := WHTBase - Abs(WHTEntry."Rem Realized Base");
                end else
                    WHTBase := 0;
        end else
            if GenJnlLine."Applies-to ID" <> '' then begin
                if ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) or
                    (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund))
                then begin
                    CustLedgerEntry.Reset();
                    CustLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    CustLedgerEntry.SetFilter(
                      "Document Type",
                      '%1|%2',
                      CustLedgerEntry."Document Type"::Payment,
                      CustLedgerEntry."Document Type"::"Credit Memo");
                    if CustLedgerEntry.FindSet() then
                        repeat
                            WHTEntry.Reset();
                            WHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                            if WHTEntry.FindSet() then
                                repeat
                                    if WHTPostingSetup.Get(
                                         WHTEntry."WHT Bus. Posting Group",
                                         WHTEntry."WHT Prod. Posting Group")
                                    then
                                        if ((WHTPostingSetup."Realized WHT Type" =
                                             WHTPostingSetup."Realized WHT Type"::Earliest) and
                                            (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                                        then
                                            if TotalWHTBase > Abs(WHTEntry."Rem Realized Base") then begin
                                                TotalWHTBase := TotalWHTBase - Abs(WHTEntry."Rem Realized Base");
                                                if (((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo")) or
                                                    ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::Payment)))
                                                then
                                                    WHTBase := WHTBase - Abs(WHTEntry."Rem Realized Base");
                                            end else begin
                                                if (TotalWHTBase > 0) and (Abs(TotalWHTBase) <= Abs(WHTEntry."Rem Realized Base")) then
                                                    TotalWHTBase := TotalWHTBase - TotalWHTBase;
                                                if (((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Refund) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo")) or
                                                    ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Invoice) and
                                                     (WHTEntry."Document Type" = WHTEntry."Document Type"::Payment)))
                                                then
                                                    WHTBase := 0;
                                            end;
                                until WHTEntry.Next() = 0;
                        until CustLedgerEntry.Next() = 0;
                end;

                if ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment) or
                    (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo"))
                then begin
                    IsRefund := false;
                    CustLedgerEntry.Reset();
                    CustLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Refund);
                    if CustLedgerEntry.FindSet() then
                        repeat
                            IsRefund := true;
                            WHTEntry.Reset();
                            WHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                            if WHTEntry.FindSet() then
                                repeat
                                    if WHTPostingSetup.Get(
                                         WHTEntry."WHT Bus. Posting Group",
                                         WHTEntry."WHT Prod. Posting Group")
                                    then
                                        if ((WHTPostingSetup."Realized WHT Type" =
                                             WHTPostingSetup."Realized WHT Type"::Earliest) and
                                            (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                                        then
                                            if TotalWHTBase > Abs(WHTEntry."Rem Realized Base") then begin
                                                TotalWHTBase := TotalWHTBase - Abs(WHTEntry."Rem Realized Base");
                                                if GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo" then
                                                    WHTBase := WHTBase - Abs(WHTEntry."Rem Realized Base");
                                            end else
                                                if (TotalWHTBase > 0) and (Abs(TotalWHTBase) <= Abs(WHTEntry."Rem Realized Base")) then begin
                                                    TotalWHTBase := 0;
                                                    if GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo" then
                                                        WHTBase := 0;
                                                end;
                                until WHTEntry.Next() = 0;
                        until CustLedgerEntry.Next() = 0;

                    CustLedgerEntry.Reset();
                    CustLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                    CustLedgerEntry.SetRange(Prepayment, false);
                    if CustLedgerEntry.FindSet() then
                        repeat
                            WHTEntry.Reset();
                            WHTEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
                            if WHTEntry.FindSet() then
                                repeat
                                    if WHTPostingSetup.Get(
                                         WHTEntry."WHT Bus. Posting Group",
                                         WHTEntry."WHT Prod. Posting Group")
                                    then
                                        if ((WHTPostingSetup."Realized WHT Type" =
                                             WHTPostingSetup."Realized WHT Type"::Earliest) and
                                            (WHTEntry."WHT %" = WHTPostingSetup."WHT %"))
                                        then
                                            if TotalWHTBase > Abs(WHTEntry."Rem Realized Base") then begin
                                                TotalWHTBase := TotalWHTBase - Abs(WHTEntry."Rem Realized Base");
                                                if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment then
                                                    WHTBase := WHTBase - Abs(WHTEntry."Rem Realized Base");
                                            end else
                                                if (TotalWHTBase > 0) and (Abs(TotalWHTBase) <= Abs(WHTEntry."Rem Realized Base")) then begin
                                                    TotalWHTBase := 0;
                                                    if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment then
                                                        WHTBase := 0;
                                                end;
                                until WHTEntry.Next() = 0;
                        until CustLedgerEntry.Next() = 0
                    else
                        if not IsRefund then
                            WHTBase := 0;
                end;
            end;

        WHTAmount := Round(WHTBase * WHTPostingSetup."WHT %" / 100);
    end;

    [Scope('OnPrem')]
    procedure InsertVendPrepaymentInvoiceWHT(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then begin
            Vendor.Get(PurchInvHeader."Pay-to Vendor No.");
            if Vendor.ABN <> '' then
                exit;
        end;

        PurchLine.Reset();
        PurchLine.SetCurrentKey("Document Type", "Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");

        if PurchLine.FindSet() then
            repeat
                if PurchasePostPrepayments.PrepmtAmount(PurchLine, 0) <> 0 then
                    if WHTPostingSetup.Get(PurchLine."WHT Business Posting Group", PurchLine."WHT Product Posting Group") then
                        if WHTPostingSetup."WHT %" > 0 then begin
                            DocNo := PurchInvHeader."No.";
                            DocType := DocType::Invoice;
                            PayToAccType := PayToAccType::Vendor;
                            PayToVendCustNo := PurchInvHeader."Pay-to Vendor No.";
                            BuyFromAccType := BuyFromAccType::Vendor;
                            GenBusPostGrp := PurchLine."Gen. Bus. Posting Group";
                            GenProdPostGrp := PurchLine."Gen. Prod. Posting Group";
                            TransType := TransType::Purchase;
                            BuyFromVendCustNo := PurchInvHeader."Actual Vendor No.";
                            PostingDate := PurchInvHeader."Posting Date";
                            DocDate := PurchInvHeader."Document Date";
                            CurrencyCode := PurchInvHeader."Currency Code";
                            CurrFactor := PurchInvHeader."Currency Factor";
                            ApplyDocType := PurchInvHeader."Applies-to Doc. Type";
                            ApplyDocNo := PurchInvHeader."Applies-to Doc. No.";
                            SourceCode := PurchInvHeader."Source Code";
                            ReasonCode := PurchInvHeader."Reason Code";

                            if (WHTBusPostGrp <> PurchLine."WHT Business Posting Group") or
                               (WHTProdPostGrp <> PurchLine."WHT Product Posting Group")
                            then begin
                                if AmountVAT <> 0 then
                                    InsertPrepaymentUnrealizedWHT(TType::Purchase);
                                WHTBusPostGrp := PurchLine."WHT Business Posting Group";
                                WHTProdPostGrp := PurchLine."WHT Product Posting Group";
                                AmountVAT := 0;
                                PurchInvHeader.Amount := PurchasePostPrepayments.PrepmtAmount(PurchLine, 0);
                                AbsorbBase := PurchLine."WHT Absorb Base";
                                if AbsorbBase <> 0 then
                                    AmountVAT := AbsorbBase
                                else
                                    AmountVAT := PurchInvHeader.Amount;
                            end else begin
                                WHTBusPostGrp := PurchLine."WHT Business Posting Group";
                                WHTProdPostGrp := PurchLine."WHT Product Posting Group";
                                PurchInvHeader.Amount += PurchasePostPrepayments.PrepmtAmount(PurchLine, 0);
                                AbsorbBase += PurchLine."WHT Absorb Base";
                                if AbsorbBase <> 0 then
                                    AmountVAT := AbsorbBase
                                else
                                    AmountVAT := PurchInvHeader.Amount;
                            end;
                            WHTBusPostGrp := PurchLine."WHT Business Posting Group";
                            WHTProdPostGrp := PurchLine."WHT Product Posting Group";
                        end;
            until PurchLine.Next() = 0;
        InsertPrepaymentUnrealizedWHT(TType::Purchase);
    end;

    [Scope('OnPrem')]
    procedure InsertPrepaymentUnrealizedWHT(TransType: Option Purchase,Sale) EntryNo: Integer
    var
        WHTEntry: Record "WHT Entry";
    begin
        if WHTPostingSetup.Get(WHTBusPostGrp, WHTProdPostGrp) then
            if WHTPostingSetup."Realized WHT Type" <> WHTPostingSetup."Realized WHT Type"::" " then begin
                UnrealizedWHT := (WHTPostingSetup."Realized WHT Type" in [WHTPostingSetup."Realized WHT Type"::Earliest,
                                                                          WHTPostingSetup."Realized WHT Type"::Invoice]);
                WHTEntry.Init();
                WHTEntry."Entry No." := NextEntryNo();
                WHTEntry."Gen. Bus. Posting Group" := GenBusPostGrp;
                WHTEntry."Gen. Prod. Posting Group" := GenProdPostGrp;
                WHTEntry."WHT Bus. Posting Group" := WHTBusPostGrp;
                WHTEntry."WHT Prod. Posting Group" := WHTProdPostGrp;
                WHTEntry."Posting Date" := PostingDate;
                WHTEntry."Document Date" := DocDate;
                WHTEntry."Document No." := DocNo;
                WHTEntry."WHT %" := WHTPostingSetup."WHT %";
                WHTEntry."Applies-to Doc. Type" := ApplyDocType;
                WHTEntry."Applies-to Doc. No." := ApplyDocNo;
                WHTEntry."Source Code" := SourceCode;
                WHTEntry."Reason Code" := ReasonCode;
                WHTEntry."WHT Revenue Type" := WHTPostingSetup."Revenue Type";
                WHTEntry."Document Type" := DocType;
                if TransType = TransType::Purchase then
                    WHTEntry."Transaction Type" := WHTEntry."Transaction Type"::Purchase
                else
                    WHTEntry."Transaction Type" := WHTEntry."Transaction Type"::Sale;
                WHTEntry."Actual Vendor No." := ActualVendorNo;
                WHTEntry."Source Code" := SourceCode;
                WHTEntry."Bill-to/Pay-to No." := PayToVendCustNo;
                WHTEntry."User ID" := UserId;
                WHTEntry."Currency Code" := CurrencyCode;

                if UnrealizedWHT then begin
                    WHTEntry.Amount := 0;
                    WHTEntry.Base := 0;
                    WHTEntry.Prepayment := true;
                    if AbsorbBase <> 0 then
                        WHTEntry."Unrealized Base" := AbsorbBase
                    else
                        WHTEntry."Unrealized Base" := AmountVAT;

                    WHTEntry."Unrealized Amount" :=
                      Round(WHTEntry."Unrealized Base" * WHTEntry."WHT %" / 100);
                    WHTEntry."Remaining Unrealized Amount" := WHTEntry."Unrealized Amount";
                    WHTEntry."Remaining Unrealized Base" := WHTEntry."Unrealized Base";
                end;

                if CurrencyCode = '' then begin
                    WHTEntry."Base (LCY)" := WHTEntry.Base;
                    WHTEntry."Amount (LCY)" := WHTEntry.Amount;
                    WHTEntry."Unrealized Amount (LCY)" := WHTEntry."Unrealized Amount";
                    WHTEntry."Unrealized Base (LCY)" := WHTEntry."Unrealized Base";
                    WHTEntry."Rem Realized Base (LCY)" := WHTEntry."Rem Realized Base";
                    WHTEntry."Rem Realized Amount (LCY)" := WHTEntry."Rem Realized Amount";
                    WHTEntry."Rem Unrealized Amount (LCY)" := WHTEntry."Remaining Unrealized Amount";
                    WHTEntry."Rem Unrealized Base (LCY)" := WHTEntry."Remaining Unrealized Base";
                end else begin
                    WHTEntry."Base (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry.Base, CurrFactor));
                    WHTEntry."Amount (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry.Amount, CurrFactor));
                    WHTEntry."Unrealized Base (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry."Unrealized Base", CurrFactor));
                    WHTEntry."Rem Realized Amount (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry."Rem Realized Amount (LCY)", CurrFactor));
                    WHTEntry."Rem Realized Base (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry."Rem Realized Base (LCY)", CurrFactor));
                    WHTEntry."Unrealized Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          DocDate, CurrencyCode, WHTEntry."Unrealized Amount", CurrFactor));
                    WHTEntry."Rem Unrealized Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          DocDate, CurrencyCode, WHTEntry."Remaining Unrealized Amount", CurrFactor));
                    WHTEntry."Rem Unrealized Base (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          DocDate, CurrencyCode, WHTEntry."Remaining Unrealized Base", CurrFactor));
                end;

                WHTEntry.Insert();
                NextWHTEntryNo := WHTEntry."Entry No." + 1;
            end;
        exit(NextWHTEntryNo);
    end;

    [Scope('OnPrem')]
    procedure InitWHTEntry(TempWHTEntry: Record "WHT Entry"; AppldAmount: Decimal; PaymentAmount1: Decimal; var WHTEntry3: Record "WHT Entry")
    var
        WHTEntry2: Record "WHT Entry";
        TempWHT: Record "WHT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        WHTEntry4: Record "WHT Entry";
        NoSeries: Codeunit "No. Series";
    begin
        WHTEntry2.Init();
        WHTEntry2."Posting Date" := TempGenJnlLine."Document Date";
        WHTEntry2."Entry No." := NextEntryNo();
        WHTEntry2."Document Date" := TempWHTEntry."Document Date";
        WHTEntry2."Document Type" := TempGenJnlLine."Document Type";
        WHTEntry2."Document No." := DocNo;
        WHTEntry2."Gen. Bus. Posting Group" := TempWHTEntry."Gen. Bus. Posting Group";
        WHTEntry2."Gen. Prod. Posting Group" := TempWHTEntry."Gen. Prod. Posting Group";
        WHTEntry2."Bill-to/Pay-to No." := TempWHTEntry."Bill-to/Pay-to No.";
        WHTEntry2."WHT Bus. Posting Group" := TempWHTEntry."WHT Bus. Posting Group";
        WHTEntry2."WHT Prod. Posting Group" := TempWHTEntry."WHT Prod. Posting Group";
        WHTEntry2."WHT Revenue Type" := TempWHTEntry."WHT Revenue Type";
        WHTEntry2."Currency Code" := TempGenJnlLine."Currency Code";
        WHTEntry2."Applies-to Entry No." := TempWHTEntry."Entry No.";
        WHTEntry2."User ID" := UserId;
        WHTEntry2."External Document No." := TempGenJnlLine."External Document No.";
        WHTEntry2."Actual Vendor No." := TempGenJnlLine."Actual Vendor No.";
        WHTEntry2."Original Document No." := TempGenJnlLine."Document No.";
        WHTEntry2."Source Code" := TempGenJnlLine."Source Code";
        WHTEntry2."Unrealized WHT Entry No." := TempWHTEntry."Entry No.";
        WHTEntry2."WHT %" := TempWHTEntry."WHT %";
        VendLedgEntry.Reset();
        VendLedgEntry.SetRange("Document Type", TempGenJnlLine."Document Type");
        VendLedgEntry.SetRange("Document No.", TempGenJnlLine."Document No.");
        if VendLedgEntry.FindLast() then
            WHTEntry2."Transaction No." := VendLedgEntry."Transaction No.";
        WHTEntry2.Base := Round(AppldAmount);
        WHTEntry2.Amount := Round(WHTEntry2.Base * WHTEntry2."WHT %" / 100);
        WHTEntry2."Payment Amount" := PaymentAmount1;
        WHTEntry2."Transaction Type" := WHTEntry2."Transaction Type"::Purchase;
        WHTPostingSetup.Get(TempWHTEntry."WHT Bus. Posting Group", TempWHTEntry."WHT Prod. Posting Group");
        WHTEntry2."WHT Report" := WHTPostingSetup."WHT Report";

        if TempGenJnlLine."Certificate Printed" then begin
            WHTEntry2."WHT Report Line No" := TempGenJnlLine."WHT Report Line No.";
            TempWHT.SetRange("Document No.", TempWHTEntry."Document No.");
            if TempWHT.FindFirst() then
                WHTEntry2."WHT Certificate No." := TempWHT."WHT Certificate No.";
        end else begin
            if ((TransType = TransType::Purchase) and
                (TempWHTEntry."Document Type" = TempWHTEntry."Document Type"::Invoice))
            then
                if (WHTReportLineNo = '') and
                   (WHTEntry2.Amount <> 0) and
                   (WHTPostingSetup."WHT Report Line No. Series" <> '')
                then
                    WHTReportLineNo := NoSeries.GetNextNo(WHTPostingSetup."WHT Report Line No. Series", WHTEntry2."Posting Date");
            WHTEntry2."WHT Report Line No" := WHTReportLineNo;
        end;

        if WHTEntry2."Currency Code" <> '' then begin
            CurrFactor :=
              CurrExchRate.ExchangeRate(
                WHTEntry2."Posting Date",
                WHTEntry2."Currency Code");
            WHTEntry2."Base (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  TempGenJnlLine."Document Date",
                  WHTEntry2."Currency Code",
                  WHTEntry2.Base, CurrFactor));
            WHTEntry2."Amount (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  TempGenJnlLine."Document Date",
                  WHTEntry2."Currency Code",
                  WHTEntry2.Amount, CurrFactor));
        end else begin
            WHTEntry2."Amount (LCY)" := WHTEntry2.Amount;
            WHTEntry2."Base (LCY)" := WHTEntry2.Base;
        end;

        if CurrencyCode = '' then begin
            WHTEntry3."Rem Unrealized Amount (LCY)" -= WHTEntry2.Amount;
            WHTEntry3."Rem Unrealized Base (LCY)" -= WHTEntry2.Base;
        end else begin
            WHTEntry3."Rem Unrealized Amount (LCY)" -=
              Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry2.Amount, CurrFactor));
            WHTEntry3."Rem Unrealized Base (LCY)" -=
              Round(CurrExchRate.ExchangeAmtFCYToLCY(DocDate, CurrencyCode, WHTEntry2.Base, CurrFactor));
        end;
        WHTEntry3.Closed :=
          (WHTEntry3."Remaining Unrealized Base" = 0) and (WHTEntry3."Remaining Unrealized Amount" = 0);

        if ((WHTEntry2."Rem Realized Amount" = 0) and
            (WHTEntry2."Rem Realized Base" = 0))
        then
            WHTEntry2.Closed := true;

        WHTEntry2.Insert();
        NextWHTEntryNo := WHTEntry2."Entry No." + 1;
        WHTEntry3.Modify();

        WHTEntry4.Reset();
        WHTEntry4.SetCurrentKey("Applies-to Entry No.");
        WHTEntry4.SetRange("Applies-to Entry No.", TempWHTEntry."Entry No.");
        WHTEntry4.CalcSums(Amount, "Amount (LCY)");
        if (Abs(Abs(WHTEntry4.Amount) - Abs(TempWHTEntry."Unrealized Amount")) < 0.1) and
           (Abs(Abs(WHTEntry4.Amount) - Abs(TempWHTEntry."Unrealized Amount")) > 0)
        then begin
            WHTEntry2."WHT Difference" := TempWHTEntry."Unrealized Amount" - WHTEntry4.Amount;
            WHTEntry2.Amount := WHTEntry2.Amount + WHTEntry2."WHT Difference";
            WHTEntry2.Modify();
        end;
        if (Abs(Abs(WHTEntry4."Amount (LCY)") - Abs(TempWHTEntry."Unrealized Amount (LCY)")) < 0.1) and
           (Abs(Abs(WHTEntry4."Amount (LCY)") - Abs(TempWHTEntry."Unrealized Amount (LCY)")) > 0)
        then begin
            WHTEntry2."Amount (LCY)" := WHTEntry2."Amount (LCY)" +
              TempWHTEntry."Unrealized Amount (LCY)" - WHTEntry4."Amount (LCY)";
            WHTEntry2.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckWHTCalculationRule(TotalInvoiceAmountLCY: Decimal; WHTPostingSetup: Record "WHT Posting Setup"): Boolean
    begin
        case WHTPostingSetup."WHT Calculation Rule" of
            WHTPostingSetup."WHT Calculation Rule"::"Less than":
                if Abs(TotalInvoiceAmountLCY) < WHTPostingSetup."WHT Minimum Invoice Amount" then
                    exit(true);
            WHTPostingSetup."WHT Calculation Rule"::"Less than or equal to":
                if Abs(TotalInvoiceAmountLCY) <= WHTPostingSetup."WHT Minimum Invoice Amount" then
                    exit(true);
            WHTPostingSetup."WHT Calculation Rule"::"Equal to":
                if Abs(TotalInvoiceAmountLCY) = WHTPostingSetup."WHT Minimum Invoice Amount" then
                    exit(true);
            WHTPostingSetup."WHT Calculation Rule"::"Greater than":
                if Abs(TotalInvoiceAmountLCY) > WHTPostingSetup."WHT Minimum Invoice Amount" then
                    exit(true);
            WHTPostingSetup."WHT Calculation Rule"::"Greater than or equal to":
                if Abs(TotalInvoiceAmountLCY) >= WHTPostingSetup."WHT Minimum Invoice Amount" then
                    exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InsertVendPrepaymentCrMemoWHT(var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" then begin
            Vendor.Get(PurchCrMemoHeader."Pay-to Vendor No.");
            if Vendor.ABN <> '' then
                exit;
        end;

        PurchLine.Reset();
        PurchLine.SetCurrentKey("Document Type", "Document No.", "WHT Business Posting Group", "WHT Product Posting Group");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");

        if PurchLine.FindSet() then
            repeat
                if PurchLine."Prepmt. Line Amount" <> 0 then
                    if WHTPostingSetup.Get(PurchLine."WHT Business Posting Group", PurchLine."WHT Product Posting Group") then
                        if WHTPostingSetup."WHT %" > 0 then begin
                            DocNo := PurchCrMemoHeader."No.";
                            DocType := DocType::"Credit Memo";
                            PayToAccType := PayToAccType::Vendor;
                            PayToVendCustNo := PurchHeader."Pay-to Vendor No.";
                            BuyFromAccType := BuyFromAccType::Vendor;
                            GenBusPostGrp := PurchLine."Gen. Bus. Posting Group";
                            GenProdPostGrp := PurchLine."Gen. Prod. Posting Group";
                            TransType := TransType::Purchase;
                            BuyFromVendCustNo := PurchHeader."Actual Vendor No.";
                            PostingDate := PurchHeader."Posting Date";
                            DocDate := PurchHeader."Document Date";
                            CurrencyCode := PurchHeader."Currency Code";
                            CurrFactor := PurchHeader."Currency Factor";
                            ApplyDocType := PurchHeader."Applies-to Doc. Type";
                            ApplyDocNo := PurchHeader."Applies-to Doc. No.";
                            SourceCode := PurchCrMemoHeader."Source Code";
                            ReasonCode := PurchHeader."Reason Code";

                            if (WHTBusPostGrp <> PurchLine."WHT Business Posting Group") or
                               (WHTProdPostGrp <> PurchLine."WHT Product Posting Group")
                            then begin
                                if AmountVAT <> 0 then
                                    InsertPrepaymentUnrealizedWHT(TType::Purchase);
                                WHTBusPostGrp := PurchLine."WHT Business Posting Group";
                                WHTProdPostGrp := PurchLine."WHT Product Posting Group";
                                PurchHeader.Amount := 0;
                                AbsorbBase := 0;
                                AmountVAT := 0;
                                PurchHeader.Amount -= PurchLine."Prepmt. Line Amount";
                                AbsorbBase -= PurchLine."WHT Absorb Base";
                                if AbsorbBase <> 0 then
                                    AmountVAT := AbsorbBase
                                else
                                    AmountVAT := PurchHeader.Amount;
                            end else begin
                                WHTBusPostGrp := PurchLine."WHT Business Posting Group";
                                WHTProdPostGrp := PurchLine."WHT Product Posting Group";
                                PurchHeader.Amount -= PurchLine."Prepmt. Line Amount";
                                AbsorbBase -= PurchLine."WHT Absorb Base";
                                if AbsorbBase <> 0 then
                                    AmountVAT := AbsorbBase
                                else
                                    AmountVAT := PurchHeader.Amount;
                            end;
                            WHTBusPostGrp := PurchLine."WHT Business Posting Group";
                            WHTProdPostGrp := PurchLine."WHT Product Posting Group";
                        end;
            until PurchLine.Next() = 0;
        InsertPrepaymentUnrealizedWHT(TType::Purchase);
    end;

    [Scope('OnPrem')]
    procedure ABSMin(Decimal1: Decimal; Decimal2: Decimal): Decimal
    begin
        if Abs(Decimal1) < Abs(Decimal2) then
            exit(Decimal1);
        exit(Decimal2);
    end;

    local procedure CalcWHTEntriesRemAmounts(var WHTEntry: Record "WHT Entry"; var ClosingWHTEntry: Record "WHT Entry"; WHTPart: Decimal)
    var
        WHTBaseToApply: Decimal;
        WHTAmountToApply: Decimal;
        WHTBaseToApplyLCY: Decimal;
        WHTAmountToApplyLCY: Decimal;
    begin
        if WHTPart >= 1 then begin
            WHTEntry."Remaining Unrealized Amount" += ClosingWHTEntry."Remaining Unrealized Amount";
            WHTEntry."Remaining Unrealized Base" += ClosingWHTEntry."Remaining Unrealized Base";
            WHTEntry."Rem Unrealized Amount (LCY)" += ClosingWHTEntry."Rem Unrealized Amount (LCY)";
            WHTEntry."Rem Unrealized Base (LCY)" += ClosingWHTEntry."Rem Unrealized Base (LCY)";

            ClosingWHTEntry."Remaining Unrealized Amount" := 0;
            ClosingWHTEntry."Remaining Unrealized Base" := 0;
            ClosingWHTEntry."Rem Unrealized Amount (LCY)" := 0;
            ClosingWHTEntry."Rem Unrealized Base (LCY)" := 0;
        end else begin
            WHTBaseToApply := Round(WHTEntry."Remaining Unrealized Base" * WHTPart);
            WHTAmountToApply := Round(WHTEntry."Remaining Unrealized Amount" * WHTPart);
            WHTBaseToApplyLCY := Round(WHTEntry."Rem Unrealized Base (LCY)" * WHTPart);
            WHTAmountToApplyLCY := Round(WHTEntry."Remaining Unrealized Amount" * WHTPart);

            WHTEntry."Remaining Unrealized Amount" -= WHTAmountToApply;
            WHTEntry."Remaining Unrealized Base" -= WHTBaseToApply;
            WHTEntry."Rem Unrealized Amount (LCY)" -= WHTAmountToApplyLCY;
            WHTEntry."Rem Unrealized Base (LCY)" -= WHTBaseToApplyLCY;

            ClosingWHTEntry."Remaining Unrealized Amount" += WHTAmountToApply;
            ClosingWHTEntry."Remaining Unrealized Base" += WHTBaseToApply;
            ClosingWHTEntry."Rem Unrealized Amount (LCY)" += WHTAmountToApplyLCY;
            ClosingWHTEntry."Rem Unrealized Base (LCY)" += WHTBaseToApplyLCY;
        end;

        CloseWHTEntry(WHTEntry);
        CloseWHTEntry(ClosingWHTEntry);
    end;

    local procedure CloseWHTEntry(var WHTEntry: Record "WHT Entry")
    begin
        if (WHTEntry."Remaining Unrealized Base" = 0) and
           (WHTEntry."Remaining Unrealized Amount" = 0)
        then
            WHTEntry.Closed := true;
    end;

    local procedure FindWHTEntryForApply(var WHTEntry: Record "WHT Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; WHTBusPostingGr: Code[20]; WHTProdPostingGr: Code[20]): Boolean
    begin
        WHTEntry.Reset();
        WHTEntry.SetRange("Document Type", DocType);
        WHTEntry.SetRange("Document No.", DocNo);
        WHTEntry.SetRange("WHT Bus. Posting Group", WHTBusPostingGr);
        WHTEntry.SetRange("WHT Prod. Posting Group", WHTProdPostingGr);
        exit(WHTEntry.FindFirst());
    end;

    local procedure SetWHTEntryAmounts(var WHTEntry: Record "WHT Entry"; AbsorbBase: Decimal; AmountVAT: Decimal; CurrFactor: Decimal)
    begin
        WHTEntry.Amount := 0;
        WHTEntry.Base := 0;
        if AbsorbBase <> 0 then
            WHTEntry."Unrealized Base" := AbsorbBase
        else
            WHTEntry."Unrealized Base" := AmountVAT;
        WHTEntry."Unrealized Amount" := Round(WHTEntry."Unrealized Base" * WHTEntry."WHT %" / 100);
        WHTEntry."Unrealized Base (LCY)" :=
          Round(CurrExchRate.ExchangeAmtFCYToLCY(WHTEntry."Document Date", WHTEntry."Currency Code", WHTEntry."Unrealized Base", CurrFactor));
        WHTEntry."Unrealized Amount (LCY)" :=
          Round(CurrExchRate.ExchangeAmtFCYToLCY(WHTEntry."Document Date", WHTEntry."Currency Code", WHTEntry."Unrealized Amount", CurrFactor));
        WHTEntry."Remaining Unrealized Amount" := WHTEntry."Unrealized Amount";
        WHTEntry."Remaining Unrealized Base" := WHTEntry."Unrealized Base";
        WHTEntry."Rem Unrealized Amount (LCY)" := WHTEntry."Unrealized Amount (LCY)";
        WHTEntry."Rem Unrealized Base (LCY)" := WHTEntry."Unrealized Base (LCY)";
    end;

    local procedure IsForeignVendor(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        if not GLSetup."Enable GST (Australia)" then
            exit(false);

        if GenJnlLine."Bill-to/Pay-to No." = '' then begin
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then
                Vendor.Get(GenJnlLine."Account No.");
        end else
            if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor) or
               (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor)
            then
                Vendor.Get(GenJnlLine."Bill-to/Pay-to No.");
        if (Vendor.ABN <> '') or Vendor."Foreign Vend" then
            exit(true);

        exit(false);
    end;

    local procedure AdjustWHTEntryWithWHTDifference(WHTEntry: Record "WHT Entry"; var WHTEntry2: Record "WHT Entry"; var WHTEntry3: Record "WHT Entry")
    var
        AmountDifference: Decimal;
    begin
        WHTEntry3.Reset();
        WHTEntry3.SetCurrentKey("Applies-to Entry No.");
        WHTEntry3.SetRange("Applies-to Entry No.", WHTEntry."Entry No.");
        WHTEntry3.CalcSums(Amount, "Amount (LCY)");
        AmountDifference := Abs(WHTEntry3.Amount) - Abs(WHTEntry."Unrealized Amount");
        if (Abs(AmountDifference) < 0.1) and
           (Abs(AmountDifference) > 0)
        then begin
            WHTEntry2."WHT Difference" := WHTEntry2."WHT Difference" + Abs(WHTEntry."Unrealized Amount" - WHTEntry3.Amount);
            WHTEntry2.Modify();
        end else
            if WHTEntry2."WHT Difference" = 0 then
                if (Abs(Abs(WHTEntry3."Amount (LCY)") - Abs(WHTEntry."Unrealized Amount (LCY)")) < 0.1) and
                   (Abs(Abs(WHTEntry3."Amount (LCY)") - Abs(WHTEntry."Unrealized Amount (LCY)")) > 0)
                then begin
                    WHTEntry2."Amount (LCY)" :=
                      WHTEntry2."Amount (LCY)" + (WHTEntry."Unrealized Amount (LCY)" - WHTEntry3."Amount (LCY)");
                    WHTEntry2.Modify();
                end;
    end;

    local procedure UpdateAmounts(VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; var RemainingAmt: Decimal; var TotAmt: Decimal; var GenJnlLineAmount: Decimal; var ExitLoop: Boolean)
    begin
        if (Abs(RemainingAmt) < Abs(TotAmt)) or
           (Abs(VendorLedgerEntry."Remaining Amount") < Abs(TotAmt))
        then begin
            GenJnlLineAmount := Abs(ABSMin(VendorLedgerEntry."Remaining Amount", RemainingAmt));
            GenJournalLine.Validate(Amount, Abs(ABSMin(VendorLedgerEntry."Amount to Apply", GenJnlLineAmount)));
            TotAmt := TotAmt - Abs(GenJournalLine.Amount);
            RemainingAmt := RemainingAmt + Abs(GenJournalLine.Amount);
        end else begin
            GenJournalLine.Validate(Amount, TotAmt);
            ExitLoop := true;
        end;
    end;

    local procedure FilterWHTEntry(var WHTEntry: Record "WHT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Transaction Type", "Document No.", "Document Type", "Bill-to/Pay-to No.");
        WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
        if GenJournalLine."Applies-to Doc. No." <> '' then begin
            WHTEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
            WHTEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
        end else
            WHTEntry.SetRange("Bill-to/Pay-to No.", GenJournalLine."Account No.");
    end;

    [Scope('OnPrem')]
    procedure CalcAppliedWHTAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliedAmountWHT: Decimal; WHTPercent: Decimal; ExitLoop: Boolean): Decimal
    var
        Result: Decimal;
        EntryNo: Integer;
        TotalAmountToApply: Decimal;
        AppliedAmount: Decimal;
    begin
        if ExitLoop then begin
            // Here we can have several Vendor Ledger Entries to be applied.
            // So we need iterate through remaining entries to calculate WHT amount per entry
            EntryNo := VendorLedgerEntry."Entry No.";
            TotalAmountToApply := AppliedAmountWHT;
            repeat
                AppliedAmount := ABSMin(-VendorLedgerEntry."Amount to Apply", TotalAmountToApply);
                Result += CalcWHTAmount(AppliedAmount, WHTPercent);
                TotalAmountToApply -= AppliedAmount;
            until (VendorLedgerEntry.Next() = 0) or (TotalAmountToApply <= 0);
            VendorLedgerEntry.Get(EntryNo);
            exit(Result);
        end;

        exit(CalcWHTAmount(AppliedAmountWHT, WHTPercent));
    end;

    local procedure CalcWHTAmount(Amount: Decimal; WHTPercent: Decimal): Decimal
    begin
        exit(Round(Amount * WHTPercent / 100));
    end;

    internal procedure RoundWHTAmount(Amount: Decimal): Decimal
    begin
        exit(Round(Amount, 1, '<'));
    end;
}

