namespace Microsoft.Peppol;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

/// <summary>
/// Builds the remittance advice buffer (header row "Line No." = 0 plus one row per applied
/// document) from a vendor payment - either an unposted payment journal line group or a posted
/// payment Vendor Ledger Entry. The buffer is the format-agnostic input contract for remittance
/// advice serializers such as Codeunit "Export Remit. Advice PEPPOL30".
/// </summary>
codeunit 37207 "Remit. Advice Buffer Mgt."
{
    /// <summary>
    /// Builds the remittance advice buffer (header + applied-document lines) from an unposted
    /// vendor payment journal line and the other lines in the same payment group.
    /// Ports the allocation/currency/discount math from report 399 "Remittance Advice - Journal".
    /// </summary>
    procedure BuildFromJournalPayment(AnchorGenJnlLine: Record "Gen. Journal Line"; var TempBuffer: Record "Remit. Advice Buffer" temporary)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        TotalPaid: Decimal;
        TotalDiscount: Decimal;
        LineNo: Integer;
    begin
        TempBuffer.Reset();
        TempBuffer.DeleteAll();

        Vendor.Get(AnchorGenJnlLine."Account No.");

        GenJournalLine.SetRange("Journal Template Name", AnchorGenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", AnchorGenJnlLine."Journal Batch Name");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", AnchorGenJnlLine."Account No.");
        GenJournalLine.SetRange("Document No.", AnchorGenJnlLine."Document No.");
        if GenJournalLine.FindSet() then
            repeat
                BuildLinesForJournalLine(GenJournalLine, TempBuffer, LineNo, TotalPaid, TotalDiscount);
            until GenJournalLine.Next() = 0;

        TempBuffer.Init();
        TempBuffer."Line No." := 0;
        TempBuffer."Payment Document No." := AnchorGenJnlLine."Document No.";
        TempBuffer."Vendor No." := AnchorGenJnlLine."Account No.";
        TempBuffer."Payment Date" := AnchorGenJnlLine."Posting Date";
        TempBuffer."Currency Code" := AnchorGenJnlLine."Currency Code";
        TempBuffer."Total Paid Amount" := TotalPaid;
        TempBuffer."Total Discount" := TotalDiscount;
        TempBuffer."Bank Payment Type" := AnchorGenJnlLine."Bank Payment Type";
        TempBuffer."Recipient Bank Account" := AnchorGenJnlLine."Recipient Bank Account";
        TempBuffer.Insert();
    end;

    local procedure BuildLinesForJournalLine(GenJournalLine: Record "Gen. Journal Line"; var TempBuffer: Record "Remit. Advice Buffer" temporary; var LineNo: Integer; var TotalPaid: Decimal; var TotalDiscount: Decimal)
    var
        TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry3: Record "Vendor Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        AmountRoundingPrecision: Decimal;
        JnlLineRemainingAmount: Decimal;
        AppliedDebitAmounts: Decimal;
        PaidAmount: Decimal;
        PmdDiscRec: Decimal;
        PmtDiscInvCurr: Decimal;
    begin
        if not (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) then
            exit;

        // Currency rounding precision (report 399 FindAmountRounding)
        if GenJournalLine."Currency Code" = '' then begin
            Currency.Init();
            Currency.Code := '';
            Currency.InitRoundingPrecision();
        end else
            Currency.Get(GenJournalLine."Currency Code");
        AmountRoundingPrecision := Currency."Amount Rounding Precision";

        // Collect applied entries: via Applies-to ID (+ its credit-memo applications)
        if GenJournalLine."Applies-to ID" <> '' then begin
            VendLedgEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
            VendLedgEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
            VendLedgEntry.SetRange(Open, true);
            if VendLedgEntry.FindSet() then
                repeat
                    DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                    DetailedVendLedgEntry.SetRange("Initial Document Type", VendLedgEntry."Document Type");
                    DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
                    DetailedVendLedgEntry.SetRange("Document Type", DetailedVendLedgEntry."Document Type"::"Credit Memo");
                    if DetailedVendLedgEntry.FindSet() then
                        repeat
                            VendLedgEntry3.Get(DetailedVendLedgEntry."Applied Vend. Ledger Entry No.");
                            if DetailedVendLedgEntry."Vendor Ledger Entry No." <> DetailedVendLedgEntry."Applied Vend. Ledger Entry No." then
                                InsertTempAppliedEntry(VendLedgEntry3, GenJournalLine, TempAppliedVendLedgEntry, CurrExchRate, AmountRoundingPrecision, JnlLineRemainingAmount, AppliedDebitAmounts);
                        until DetailedVendLedgEntry.Next() = 0;
                    InsertTempAppliedEntry(VendLedgEntry, GenJournalLine, TempAppliedVendLedgEntry, CurrExchRate, AmountRoundingPrecision, JnlLineRemainingAmount, AppliedDebitAmounts);
                until VendLedgEntry.Next() = 0;
        end;

        // Collect applied entries: via Applies-to Doc. No./Type (+ its credit-memo applications)
        if GenJournalLine."Applies-to Doc. No." <> '' then begin
            VendLedgEntry2.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
            VendLedgEntry2.SetRange("Vendor No.", GenJournalLine."Account No.");
            VendLedgEntry2.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
            VendLedgEntry2.SetRange(Open, true);
            if VendLedgEntry2.FindSet() then
                repeat
                    DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry2."Entry No.");
                    DetailedVendLedgEntry.SetRange("Initial Document Type", VendLedgEntry2."Document Type");
                    DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
                    DetailedVendLedgEntry.SetRange("Document Type", DetailedVendLedgEntry."Document Type"::"Credit Memo");
                    if DetailedVendLedgEntry.FindSet() then
                        repeat
                            VendLedgEntry3.Get(DetailedVendLedgEntry."Applied Vend. Ledger Entry No.");
                            if DetailedVendLedgEntry."Vendor Ledger Entry No." <> DetailedVendLedgEntry."Applied Vend. Ledger Entry No." then
                                InsertTempAppliedEntry(VendLedgEntry3, GenJournalLine, TempAppliedVendLedgEntry, CurrExchRate, AmountRoundingPrecision, JnlLineRemainingAmount, AppliedDebitAmounts);
                        until DetailedVendLedgEntry.Next() = 0;
                    InsertTempAppliedEntry(VendLedgEntry2, GenJournalLine, TempAppliedVendLedgEntry, CurrExchRate, AmountRoundingPrecision, JnlLineRemainingAmount, AppliedDebitAmounts);
                until VendLedgEntry2.Next() = 0;
        end;

        // Allocation loop (report 399 PrintLoop, lines 284-386). The pool of money to allocate is
        // the journal line's own Amount plus the debit (credit-memo) applications - report 399
        // builds it from the line Amount ("Gen. Journal Line" OnAfterGetRecord), the debit
        // entries' Amount to Apply (InsertTempEntry, already accumulated into
        // JnlLineRemainingAmount by InsertTempAppliedEntry above) and AppliedDebitAmounts
        // (PrintLoop OnPreDataItem).
        JnlLineRemainingAmount += GenJournalLine.Amount + AppliedDebitAmounts;
        if TempAppliedVendLedgEntry.FindSet() then
            repeat
                TempAppliedVendLedgEntry.CalcFields("Remaining Amount", "Original Amount");

                if TempAppliedVendLedgEntry."Currency Code" <> GenJournalLine."Currency Code" then begin
                    TempAppliedVendLedgEntry."Remaining Amount" :=
                        Round(CurrExchRate.ExchangeAmtFCYToFCY(GenJournalLine."Posting Date", TempAppliedVendLedgEntry."Currency Code",
                            GenJournalLine."Currency Code", TempAppliedVendLedgEntry."Remaining Amount"), AmountRoundingPrecision);

                    TempAppliedVendLedgEntry."Amount to Apply" :=
                        Round(CurrExchRate.ExchangeAmtFCYToFCY(GenJournalLine."Posting Date", TempAppliedVendLedgEntry."Currency Code",
                            GenJournalLine."Currency Code", TempAppliedVendLedgEntry."Amount to Apply"), AmountRoundingPrecision);

                    PmtDiscInvCurr := TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                    TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                        CurrExchRate.ExchangeAmtFCYToFCY(GenJournalLine."Posting Date", TempAppliedVendLedgEntry."Currency Code",
                            GenJournalLine."Currency Code", TempAppliedVendLedgEntry."Original Pmt. Disc. Possible");
                    TempAppliedVendLedgEntry."Original Pmt. Disc. Possible" :=
                        Round(TempAppliedVendLedgEntry."Original Pmt. Disc. Possible", AmountRoundingPrecision);
                end;

                if (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Payment) and
                   (TempAppliedVendLedgEntry."Document Type" in [TempAppliedVendLedgEntry."Document Type"::Invoice, TempAppliedVendLedgEntry."Document Type"::"Credit Memo"]) and
                   (GenJournalLine."Posting Date" <= TempAppliedVendLedgEntry."Pmt. Discount Date") and
                   (Abs(TempAppliedVendLedgEntry."Remaining Amount") >= Abs(TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible"))
                then
                    PmdDiscRec := TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible"
                else
                    PmdDiscRec := 0;

                TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" - PmdDiscRec;
                TempAppliedVendLedgEntry."Amount to Apply" := TempAppliedVendLedgEntry."Amount to Apply" - PmdDiscRec;

                if TempAppliedVendLedgEntry."Remaining Amount" > 0 then begin
                    PaidAmount := -TempAppliedVendLedgEntry."Amount to Apply";
                    if TempAppliedVendLedgEntry."Amount to Apply" < 0 then
                        TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" - PaidAmount
                    else
                        TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" + PaidAmount;
                end else begin
                    if Abs(TempAppliedVendLedgEntry."Remaining Amount") > Abs(JnlLineRemainingAmount) then
                        if TempAppliedVendLedgEntry."Amount to Apply" < 0 then
                            PaidAmount := Abs(TempAppliedVendLedgEntry."Amount to Apply")
                        else
                            PaidAmount := Abs(JnlLineRemainingAmount)
                    else
                        if TempAppliedVendLedgEntry."Amount to Apply" < 0 then
                            PaidAmount := Abs(TempAppliedVendLedgEntry."Amount to Apply")
                        else
                            PaidAmount := Abs(TempAppliedVendLedgEntry."Remaining Amount");
                    TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" + PaidAmount;
                    JnlLineRemainingAmount := JnlLineRemainingAmount - PaidAmount;
                    if JnlLineRemainingAmount < 0 then begin
                        TempAppliedVendLedgEntry."Remaining Amount" := TempAppliedVendLedgEntry."Remaining Amount" + JnlLineRemainingAmount;
                        PaidAmount := PaidAmount + TempAppliedVendLedgEntry."Remaining Amount";
                        JnlLineRemainingAmount := 0;
                    end;
                end;

                if TempAppliedVendLedgEntry."Currency Code" <> GenJournalLine."Currency Code" then
                    if PmdDiscRec <> 0 then
                        PmdDiscRec := PmtDiscInvCurr;

                LineNo += 1;
                TempBuffer.Init();
                TempBuffer."Line No." := LineNo;
                TempBuffer."Applied Doc. Type" := TempAppliedVendLedgEntry."Document Type";
                TempBuffer."Our Document No." := TempAppliedVendLedgEntry."Document No.";
                TempBuffer."External Document No." := TempAppliedVendLedgEntry."External Document No.";
                TempBuffer."Document Date" := TempAppliedVendLedgEntry."Document Date";
                TempBuffer."Posting Date" := TempAppliedVendLedgEntry."Posting Date";
                TempBuffer."Line Currency Code" := TempAppliedVendLedgEntry."Currency Code";
                TempBuffer."Original Amount" := Abs(TempAppliedVendLedgEntry."Original Amount");
                TempBuffer."Remaining Amount" := Abs(TempAppliedVendLedgEntry."Remaining Amount");
                TempBuffer."Paid Amount" := PaidAmount;
                TempBuffer."Pmt. Discount Amount" := Abs(PmdDiscRec);
                TempBuffer."Vendor Ledger Entry No." := TempAppliedVendLedgEntry."Entry No.";
                TempBuffer.Insert();

                TotalPaid += PaidAmount;
                TotalDiscount += Abs(PmdDiscRec);
            until TempAppliedVendLedgEntry.Next() = 0;
    end;

    /// <summary>
    /// Inserts an applied Vendor Ledger Entry into the temp buffer used by the allocation loop,
    /// tracking debit (credit-memo) applications the same way report 399's InsertTempEntry does.
    /// </summary>
    local procedure InsertTempAppliedEntry(EntryToInsert: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary; var CurrExchRate: Record "Currency Exchange Rate"; AmountRoundingPrecision: Decimal; var JnlLineRemainingAmount: Decimal; var AppliedDebitAmounts: Decimal)
    var
        AppAmt: Decimal;
    begin
        TempAppliedVendLedgEntry := EntryToInsert;
        if TempAppliedVendLedgEntry.Insert() then begin
            TempAppliedVendLedgEntry.CalcFields("Remaining Amt. (LCY)");
            if TempAppliedVendLedgEntry."Remaining Amt. (LCY)" > 0 then begin
                JnlLineRemainingAmount += TempAppliedVendLedgEntry."Amount to Apply";
                AppAmt := TempAppliedVendLedgEntry."Remaining Amt. (LCY)";
                if GenJournalLine."Currency Code" <> '' then begin
                    AppAmt := CurrExchRate.ExchangeAmtLCYToFCY(
                        GenJournalLine."Posting Date", GenJournalLine."Currency Code", AppAmt, GenJournalLine."Currency Factor");
                    AppAmt := Round(AppAmt, AmountRoundingPrecision);
                end;
                AppliedDebitAmounts := AppliedDebitAmounts + AppAmt;
            end;
        end;
    end;

    /// <summary>
    /// Builds the remittance advice buffer (header + applied-document lines) from a posted payment
    /// Vendor Ledger Entry. Ports the allocation math from report 400 "Remittance Advice - Entries".
    /// </summary>
    procedure BuildFromPostedPayment(PaymentVendLedgEntry: Record "Vendor Ledger Entry"; var TempBuffer: Record "Remit. Advice Buffer" temporary)
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry3: Record "Vendor Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        LineAmount: Decimal;
        LineDiscount: Decimal;
        TotalPaid: Decimal;
        TotalDiscount: Decimal;
        LineNo: Integer;
    begin
        TempBuffer.Reset();
        TempBuffer.DeleteAll();

        PaymentVendLedgEntry.CalcFields(Amount, "Remaining Amount");

        FindAppliedEntries(PaymentVendLedgEntry, AppliedVendLedgEntry);
        if AppliedVendLedgEntry.FindSet() then
            repeat
                AppliedVendLedgEntry.CalcFields(Amount, "Remaining Amount");

                DetailedVendLedgEntry.Reset();
                DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", AppliedVendLedgEntry."Entry No.");
                DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
                DetailedVendLedgEntry.SetRange("Document Type", DetailedVendLedgEntry."Document Type"::Payment);
                DetailedVendLedgEntry.SetRange("Document No.", PaymentVendLedgEntry."Document No.");
                DetailedVendLedgEntry.SetRange(Unapplied, false);
                if not DetailedVendLedgEntry.IsEmpty() then begin
                    DetailedVendLedgEntry.CalcSums(Amount, "Remaining Pmt. Disc. Possible");
                    LineAmount := DetailedVendLedgEntry.Amount;

                    LineDiscount := 0;
                    if AppliedVendLedgEntry."Currency Code" <> '' then begin
                        if IsDiscountAppliedToPayment(AppliedVendLedgEntry."Entry No.", PaymentVendLedgEntry."Document No.") then
                            LineDiscount := DetailedVendLedgEntry."Remaining Pmt. Disc. Possible";
                    end else
                        LineDiscount := CurrExchRate.ExchangeAmtFCYToFCY(AppliedVendLedgEntry."Posting Date", '', AppliedVendLedgEntry."Currency Code", AppliedVendLedgEntry."Pmt. Disc. Rcd.(LCY)");

                    LineNo += 1;
                    TempBuffer.Init();
                    TempBuffer."Line No." := LineNo;
                    TempBuffer."Applied Doc. Type" := AppliedVendLedgEntry."Document Type";
                    TempBuffer."Our Document No." := AppliedVendLedgEntry."Document No.";
                    TempBuffer."External Document No." := AppliedVendLedgEntry."External Document No.";
                    TempBuffer."Document Date" := AppliedVendLedgEntry."Document Date";
                    TempBuffer."Posting Date" := AppliedVendLedgEntry."Posting Date";
                    TempBuffer."Line Currency Code" := AppliedVendLedgEntry."Currency Code";
                    TempBuffer."Original Amount" := Abs(AppliedVendLedgEntry.Amount);
                    TempBuffer."Remaining Amount" := Abs(AppliedVendLedgEntry."Remaining Amount");
                    TempBuffer."Paid Amount" := Abs(LineAmount) - Abs(LineDiscount);
                    TempBuffer."Pmt. Discount Amount" := Abs(LineDiscount);
                    TempBuffer."Vendor Ledger Entry No." := AppliedVendLedgEntry."Entry No.";
                    TempBuffer.Insert();

                    TotalPaid += TempBuffer."Paid Amount";
                    TotalDiscount += TempBuffer."Pmt. Discount Amount";

                    // Applied credit-memo cross-applications (report 400 lines 231-249)
                    DetailedVendLedgEntry.Reset();
                    DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", AppliedVendLedgEntry."Entry No.");
                    DetailedVendLedgEntry.SetRange("Initial Document Type", AppliedVendLedgEntry."Document Type");
                    DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
                    DetailedVendLedgEntry.SetRange("Document Type", DetailedVendLedgEntry."Document Type"::"Credit Memo");
                    if DetailedVendLedgEntry.FindSet() then
                        repeat
                            VendLedgEntry3.Get(DetailedVendLedgEntry."Applied Vend. Ledger Entry No.");
                            if DetailedVendLedgEntry."Vendor Ledger Entry No." <> DetailedVendLedgEntry."Applied Vend. Ledger Entry No." then begin
                                VendLedgEntry3.CalcFields(Amount, "Remaining Amount");
                                LineAmount := VendLedgEntry3.Amount - VendLedgEntry3."Remaining Amount";
                                LineDiscount := CurrExchRate.ExchangeAmtFCYToFCY(VendLedgEntry3."Posting Date", '', VendLedgEntry3."Currency Code", VendLedgEntry3."Pmt. Disc. Rcd.(LCY)");

                                LineNo += 1;
                                TempBuffer.Init();
                                TempBuffer."Line No." := LineNo;
                                TempBuffer."Applied Doc. Type" := VendLedgEntry3."Document Type";
                                TempBuffer."Our Document No." := VendLedgEntry3."Document No.";
                                TempBuffer."External Document No." := VendLedgEntry3."External Document No.";
                                TempBuffer."Document Date" := VendLedgEntry3."Document Date";
                                TempBuffer."Posting Date" := VendLedgEntry3."Posting Date";
                                TempBuffer."Line Currency Code" := VendLedgEntry3."Currency Code";
                                TempBuffer."Original Amount" := Abs(VendLedgEntry3.Amount);
                                TempBuffer."Remaining Amount" := Abs(VendLedgEntry3."Remaining Amount");
                                TempBuffer."Paid Amount" := Abs(LineAmount) - Abs(LineDiscount);
                                TempBuffer."Pmt. Discount Amount" := Abs(LineDiscount);
                                TempBuffer."Vendor Ledger Entry No." := VendLedgEntry3."Entry No.";
                                TempBuffer.Insert();

                                TotalPaid += TempBuffer."Paid Amount";
                                TotalDiscount += TempBuffer."Pmt. Discount Amount";
                            end;
                        until DetailedVendLedgEntry.Next() = 0;
                end;
            until AppliedVendLedgEntry.Next() = 0;

        TempBuffer.Init();
        TempBuffer."Line No." := 0;
        TempBuffer."Payment Document No." := PaymentVendLedgEntry."Document No.";
        TempBuffer."Vendor No." := PaymentVendLedgEntry."Vendor No.";
        TempBuffer."Payment Date" := PaymentVendLedgEntry."Posting Date";
        TempBuffer."Currency Code" := PaymentVendLedgEntry."Currency Code";
        TempBuffer."Total Paid Amount" := TotalPaid;
        TempBuffer."Total Discount" := TotalDiscount;
        TempBuffer."Recipient Bank Account" := PaymentVendLedgEntry."Recipient Bank Account";
        TempBuffer.Insert();
    end;

    /// <summary>
    /// Finds all Vendor Ledger Entries applied by/to the payment entry, both directions via
    /// "Closed by Entry No." (report 400 FindApplnEntriesDtldtLedgEntry, lines 403-441).
    /// </summary>
    local procedure FindAppliedEntries(PaymentVendLedgEntry: Record "Vendor Ledger Entry"; var AppliedVendLedgEntry: Record "Vendor Ledger Entry")
    var
        DetailedVendLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DetailedVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        EntryNo: Integer;
    begin
        AppliedVendLedgEntry.Reset();
        AppliedVendLedgEntry.SetCurrentKey("Entry No.");

        if PaymentVendLedgEntry."Closed by Entry No." <> 0 then begin
            AppliedVendLedgEntry.SetRange("Entry No.", PaymentVendLedgEntry."Closed by Entry No.");
            if AppliedVendLedgEntry.FindFirst() then
                AppliedVendLedgEntry.Mark(true);
        end;

        AppliedVendLedgEntry.SetCurrentKey("Closed by Entry No.");
        AppliedVendLedgEntry.SetRange("Closed by Entry No.", PaymentVendLedgEntry."Entry No.");
        if AppliedVendLedgEntry.FindSet() then
            repeat
                AppliedVendLedgEntry.Mark(true);
            until AppliedVendLedgEntry.Next() = 0;

        DetailedVendLedgEntry1.Reset();
        DetailedVendLedgEntry1.SetCurrentKey("Vendor Ledger Entry No.");
        DetailedVendLedgEntry1.SetRange("Vendor Ledger Entry No.", PaymentVendLedgEntry."Entry No.");
        DetailedVendLedgEntry1.SetRange(Unapplied, false);
        if DetailedVendLedgEntry1.FindSet() then
            repeat
                if DetailedVendLedgEntry1."Vendor Ledger Entry No." = DetailedVendLedgEntry1."Applied Vend. Ledger Entry No." then begin
                    DetailedVendLedgEntry2.Reset();
                    DetailedVendLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DetailedVendLedgEntry2.SetRange("Applied Vend. Ledger Entry No.", DetailedVendLedgEntry1."Applied Vend. Ledger Entry No.");
                    DetailedVendLedgEntry2.SetRange("Entry Type", DetailedVendLedgEntry2."Entry Type"::Application);
                    DetailedVendLedgEntry2.SetRange(Unapplied, false);
                    if DetailedVendLedgEntry2.FindSet() then
                        repeat
                            if DetailedVendLedgEntry2."Vendor Ledger Entry No." <> DetailedVendLedgEntry2."Applied Vend. Ledger Entry No." then begin
                                EntryNo := DetailedVendLedgEntry2."Vendor Ledger Entry No.";
                                AppliedVendLedgEntry.SetRange("Entry No.", EntryNo);
                                if AppliedVendLedgEntry.FindFirst() then
                                    AppliedVendLedgEntry.Mark(true);
                            end;
                        until DetailedVendLedgEntry2.Next() = 0;
                end else begin
                    EntryNo := DetailedVendLedgEntry1."Applied Vend. Ledger Entry No.";
                    AppliedVendLedgEntry.SetRange("Entry No.", EntryNo);
                    if AppliedVendLedgEntry.FindFirst() then
                        AppliedVendLedgEntry.Mark(true);
                end;
            until DetailedVendLedgEntry1.Next() = 0;

        AppliedVendLedgEntry.SetCurrentKey("Entry No.");
        AppliedVendLedgEntry.SetRange("Entry No.");
        AppliedVendLedgEntry.SetRange("Closed by Entry No.");
        AppliedVendLedgEntry.MarkedOnly(true);
    end;

    local procedure IsDiscountAppliedToPayment(VendLedgEntryNo: Integer; DocNo: Code[20]): Boolean
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendLedgEntry.LoadFields("Vendor Ledger Entry No.", "Entry Type", "Document Type", "Document No.", "Currency Code", Unapplied);
        DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::"Payment Discount");
        DetailedVendLedgEntry.SetRange("Document Type", DetailedVendLedgEntry."Document Type"::Payment);
        DetailedVendLedgEntry.SetRange("Document No.", DocNo);
        DetailedVendLedgEntry.SetFilter("Currency Code", '<>%1', '');
        DetailedVendLedgEntry.SetRange(Unapplied, false);
        exit(not DetailedVendLedgEntry.IsEmpty());
    end;
}
