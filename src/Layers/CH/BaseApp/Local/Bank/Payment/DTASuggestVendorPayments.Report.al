// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Telemetry;

report 3010546 "DTA Suggest Vendor Payments"
{
    Caption = 'DTA Suggest Vendor Payments';
    Permissions = TableData "Vendor Ledger Entry" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Currency Code", "Country/Region Code", "Vendor Posting Group", Priority;

            trigger OnAfterGetRecord()
            begin
                // Filter all open Vendor Entries, positive, until Due Date
                Window.Update(1, Vendor."No.");

                PmtsPerVendor := 0;

                VendEntry.Reset();
                VendEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date", "Currency Code");
                VendEntry.SetRange("Vendor No.", "No.");
                VendEntry.SetRange(Open, true);
                VendEntry.SetRange(Positive, false);
                Vendor2.CopyFilter("Currency Code", VendEntry."Currency Code");
                VendEntry.SetRange("On Hold", '');

                // 1. Cash Disc. Payments
                if WithCashDisc then begin
                    VendEntry.SetFilter("Remaining Pmt. Disc. Possible", '<>%1', 0);
                    VendEntry.SetRange("Pmt. Disc. Tolerance Date", FromCashDiscDate, ToCashDiscDate);
                    if VendEntry.Find('-') then
                        repeat
                            WritePmtSuggestLines();
                        until VendEntry.Next() = 0;
                    VendEntry.SetRange("Pmt. Disc. Tolerance Date");
                    VendEntry.SetRange("Pmt. Discount Date", FromCashDiscDate, ToCashDiscDate);
                    if VendEntry.Find('-') then
                        repeat
                            WritePmtSuggestLines();
                        until VendEntry.Next() = 0;
                    VendEntry.SetRange("Pmt. Discount Date");  // Reset
                    VendEntry.SetRange("Remaining Pmt. Disc. Possible");
                end;

                // 2. Normal Payments
                VendEntry.SetRange("Due Date", FromDueDate, ToDueDate);
                if VendEntry.Find('-') then
                    repeat
                        WritePmtSuggestLines();
                    until VendEntry.Next() = 0;

                // CHeck, if open Credit Memos for Vendor
                if PmtsPerVendor > 0 then begin
                    CreditVendEntries.SetCurrentKey("Vendor No.", Open, Positive);
                    CreditVendEntries.SetRange("Vendor No.", "No.");
                    CreditVendEntries.SetRange(Open, true);
                    CreditVendEntries.SetRange(Positive, true);
                    if CreditVendEntries.FindFirst() then begin
                        NoOfVendorsWithCM := NoOfVendorsWithCM + 1;
                        VendWithCmTxt := CopyStr(VendWithCmTxt + Vendor."No." + ', ', 1, 250);
                    end;
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
                if NoOfLinesInserted > 0 then begin
                    if not InsertBankBalanceAccount then
                        WriteBalAccountLine(ToGlLine);
                    Message(Text011, NoOfLinesInserted, GlSetup."LCY Code", TotalAmtLCY);
                    if NoOfVendorsWithCM > 0 then
                        Message(Text013, NoOfVendorsWithCM, VendWithCmTxt)
                end else
                    Message(Text018, FromDueDate, ToDueDate);
            end;

            trigger OnPreDataItem()
            begin
                if ToDueDate = 0D then
                    Error(Text000);

                if not AutoDebitBank then begin
                    if ReqFormDebitBank."Bank Code" = '' then
                        Error(Text001);

                    DtaSetup.Get(ReqFormDebitBank."Bank Code");
                end;

                if WithCashDisc then begin
                    if (FromCashDiscDate = 0D) or (ToCashDiscDate = 0D) then
                        Error(Text002);

                    if FromCashDiscDate < WorkDate() then
                        if not
                           Confirm(Text003, false, FromCashDiscDate, WorkDate())
                        then
                            Error(Text005);
                end;

                GlSetup.Get();

                if PostDate = 0D then
                    Error(Text006);

                // Save curr. filter and clear on vendor
                Vendor.CopyFilter("Currency Code", Vendor2."Currency Code");
                Vendor.SetRange("Currency Code");

                // Filter on Prio: Set Sorting
                if Vendor.GetFilter(Priority) <> '' then
                    SetCurrentKey(Priority);

                // Prepare max. remain amt, if limited
                if MaxAmtLCY <> 0 then
                    RemainMaxAmtLCY := MaxAmtLCY;

                Window.Open(
                  Text007 +
                  Text008 +
                  Text009 +
                  Text010);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Posting Date"; PostDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date of posting for the suggested journal lines.';

                        trigger OnValidate()
                        begin
                            FromCashDiscDate := PostDate;
                            FromDueDate := PostDate;

                            if FromCashDiscDate >= ToCashDiscDate then
                                ToCashDiscDate := CalcDate('<7D>', FromCashDiscDate);

                            if FromDueDate >= ToDueDate then
                                ToDueDate := CalcDate('<7D>', FromDueDate);
                        end;
                    }
                    field("Due Date from"; FromDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due Date from';
                        ToolTip = 'Specifies the date from which the report suggests payments based on the due date.';

                        trigger OnValidate()
                        begin
                            if FromDueDate >= ToDueDate then
                                ToDueDate := CalcDate('<7D>', FromDueDate);
                        end;
                    }
                    field("Due Date to"; ToDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due Date to';
                        ToolTip = 'Specifies the date to which the report suggests payments based on the due date.';
                    }
                    field(WithCashDisc; WithCashDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Process Cash Discounts';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want cash discount payments outside the due date range.';
                    }
                    field("Cash Disc. Date from"; FromCashDiscDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Disc. Date from';
                        ToolTip = 'Specifies the date from which the report suggests payments based on the cash discount date.';

                        trigger OnValidate()
                        begin
                            if FromCashDiscDate >= ToCashDiscDate then
                                ToCashDiscDate := CalcDate('<7D>', FromCashDiscDate);
                        end;
                    }
                    field("Cash Disc. Date to"; ToCashDiscDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Disc. Date to';
                        ToolTip = 'Specifies the date to which the report suggests payments based on the cash discount date';
                    }
                    field(MaxAmtLCY; MaxAmtLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Available Amount (LCY)';
                        ToolTip = 'Specifies a maximum amount (in LCY) that is available for payments. The batch job will then create a payment suggestion on the basis of this amount and the Use Vendor Priority check box. It will only include vendor entries that can be paid fully.';
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'First Doc. No.';
                        ToolTip = 'Specifies the payment suggestion document number.';
                    }
                    field("ReqFormDebitBank.""Bank Code"""; ReqFormDebitBank."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Debit to Bank';
                        TableRelation = "DTA Setup";
                        ToolTip = 'Specifies the bank code, if this is independent of other default settings, the debit only goes to one bank. ';

                        trigger OnValidate()
                        begin
                            DtaSetup.Get(ReqFormDebitBank."Bank Code");
                            AutoDebitBank := false;
                        end;
                    }
                    field("Auto. Debit Bank"; AutoDebitBank)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Auto. Debit Bank';
                        ToolTip = 'Specifies if you want to use the debit bank that is specified in the DTA setup.';

                        trigger OnValidate()
                        begin
                            if AutoDebitBank then
                                ReqFormDebitBank."Bank Code" := '';
                        end;
                    }
                    field(InsertBankBalanceAccount; InsertBankBalanceAccount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Insert Bank Balance Account';
                        ToolTip = 'Specifies if the bank balance account will be used for each suggested line.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            NoSeries: Codeunit "No. Series";
        begin
            // Journal Name for No Serie
            GlBatchName.Get(ToGlLine."Journal Template Name", ToGlLine."Journal Batch Name");
            DocNo := NoSeries.PeekNextNo(GlBatchName."No. Series", PostDate);

            if ReqFormDebitBank."Bank Code" = '' then
                AutoDebitBank := true;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000KEF', 'DTA Local CH Functionality', 'DTA Suggest Vendor Payments report');

        Commit();
        if not VendorLedgEntryTemp.IsEmpty() then
            if Confirm(Text029) then
                PAGE.RunModal(0, VendorLedgEntryTemp);
    end;

    trigger OnPreReport()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        VendorLedgEntryTemp.DeleteAll();
        if InsertBankBalanceAccount then begin
            GenJournalBatch.Get(ToGlLine."Journal Template Name", ToGlLine."Journal Batch Name");
            GenJournalBatch.TestField("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
            GenJournalBatch.TestField("Bal. Account No.");
        end;
    end;

    var
        Text000: Label 'Please define last due date.';
        Text001: Label 'Please define debit bank.';
        Text002: Label 'Please define date range for cash discount.';
        Text003: Label 'The starting date for cash discount %1 is before the workdate %2.\\Do you want to start the batch job anyway?';
        Text005: Label 'Job cancelled.';
        Text006: Label 'Please define the posting date.';
        Text007: Label 'DTA Suggest Vendor Payment\';
        Text008: Label 'Vendor Number  #1#########\';
        Text009: Label 'No of Lines    #2#########\';
        Text010: Label 'Total Amount   #3#########\';
        Text011: Label 'Payments have been successfully suggested. %1 lines with a total of %2 %3 has been transferred to the payment journal.', Comment = 'Parameter 1 and 3 - numbers, 2 - currency code.';
        Text013: Label '%1 of the suggested vendors have open credit memos.\\Check to see if the payments should be reduced by the credit memo amounts or apply the open credit memo and invoices to each other and rerun the batch job.\\Vendors with credit memos: %2.', Comment = 'Parameters 1 and 2 - numbers.';
        Text018: Label 'Batch job processed. There are no open invoices within the defined filters that are due from %1 to %2.';
        Text021: Label 'There is no main bank defined with an empty currency code or %1.';
        Text024: Label 'For vendor %1 document %2 no debit bank is defined.';
        Text025: Label 'The balance account for bank %1 is not defined.';
        Text028: Label 'DTA balance line %1 %2 (%3)', Comment = 'Parameter 1 - bank code, 2 and 3 - currency codes.';
        Text029: Label 'There are one or more entries for which no payment suggestions have been made because the posting dates of the entries are later than the posting date in the DTA Suggest Vendor Payments batch job request window. Do you want to see the entries?';
        DtaSetup: Record "DTA Setup";
        GlSetup: Record "General Ledger Setup";
        Vendor2: Record Vendor;
        VendEntry: Record "Vendor Ledger Entry";
        VendBank: Record "Vendor Bank Account";
        GlAcc: Record "G/L Account";
        BankAccNo: Record "Bank Account";
        ToGlLine: Record "Gen. Journal Line";
        GlBatchName: Record "Gen. Journal Batch";
        GlBatchName2: Record "Gen. Journal Batch";
        CurrExch: Record "Currency Exchange Rate";
        Currency: Record Currency;
        CreditVendEntries: Record "Vendor Ledger Entry";
        ReqFormDebitBank: Record "DTA Setup";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgEntryTemp: Record "Vendor Ledger Entry" temporary;
        Window: Dialog;
        DocNo: Code[20];
        NoOfLinesInserted: Integer;
        PmtAmt: Decimal;
        TotalAmtLCY: Decimal;
        PostDate: Date;
        FromDueDate: Date;
        ToDueDate: Date;
        WithCashDisc: Boolean;
        FromCashDiscDate: Date;
        ToCashDiscDate: Date;
        MaxAmtLCY: Decimal;
        RemainMaxAmtLCY: Decimal;
        AutoDebitBank: Boolean;
        LastLineNo: Integer;
        PmtsPerVendor: Integer;
        NoOfVendorsWithCM: Integer;
        VendorLedgerEntryNo: Integer;
        VendWithCmTxt: Text[250];
        PmtLineAmount: Decimal;
        CurrencyFactor: Decimal;
        AccountCurrency: Code[10];
        PaymentCurrency: Code[10];
        BalAccDesc: Text[50];
        InsertBankBalanceAccount: Boolean;

    [Scope('OnPrem')]
    procedure DefineJournalName(_GenJnlLine: Record "Gen. Journal Line")
    begin
        ToGlLine := _GenJnlLine;
        ToGlLine.SetRange("Journal Template Name", ToGlLine."Journal Template Name");
        ToGlLine.SetRange("Journal Batch Name", ToGlLine."Journal Batch Name");
        if ToGlLine.FindLast() then
            LastLineNo := ToGlLine."Line No."
    end;

    [Scope('OnPrem')]
    procedure WritePmtSuggestLines()
    begin
        if VendEntry."Posting Date" <= PostDate then begin
            VendorLedgerEntryNo := VendEntry."Entry No.";

            ToGlLine.Init();
            ToGlLine."Journal Template Name" := ToGlLine."Journal Template Name";
            ToGlLine."Journal Batch Name" := ToGlLine."Journal Batch Name";
            LastLineNo := LastLineNo + 10000;
            ToGlLine."Line No." := LastLineNo;
            ToGlLine."Account Type" := ToGlLine."Account Type"::Vendor;
            ToGlLine."Document No." := DocNo;
            GlBatchName2.Get(ToGlLine."Journal Template Name", ToGlLine."Journal Batch Name");
            ToGlLine."Posting No. Series" := GlBatchName2."Posting No. Series";

            ToGlLine.Validate("Posting Date", PostDate);
            ToGlLine.Validate("Account No.", VendEntry."Vendor No.");
            ToGlLine.Validate("Document Type", ToGlLine."Document Type"::Payment);
            ToGlLine.Validate("Currency Code", VendEntry."Currency Code");

            ToGlLine.Description := Format(ToGlLine.Description + ', ' + VendEntry."External Document No.", -MaxStrLen(ToGlLine.Description));
            if not VendBank.Get(VendEntry."Vendor No.", VendEntry."Recipient Bank Account") then begin
                VendBank.Init();
                VendBank."Vendor No." := '';
            end;

            if InsertBankBalanceAccount then begin
                ToGlLine."Bal. Account Type" := ToGlLine."Bal. Account Type"::"Bank Account";
                ToGlLine."Bal. Account No." := GlBatchName2."Bal. Account No.";
            end;

            VendEntry.CalcFields("Remaining Amount");

            if (VendEntry."Pmt. Discount Date" >= PostDate) or
               (VendEntry."Pmt. Disc. Tolerance Date" >= PostDate)
            then
                PmtAmt := -(VendEntry."Remaining Amount" - VendEntry."Remaining Pmt. Disc. Possible")
            else
                PmtAmt := -VendEntry."Remaining Amount";

            ToGlLine."Applies-to Doc. Type" := VendEntry."Document Type";
            ToGlLine."Applies-to Doc. No." := VendEntry."Document No.";

            ToGlLine.SetJournalLineFieldsFromApplication();

            ToGlLine."Payment Fee Code" := VendBank."Payment Fee Code";

            ToGlLine.Validate(Amount, PmtAmt);
            // CHeck Max amount and reduce
            if MaxAmtLCY > 0 then begin
                if ToGlLine."Amount (LCY)" > RemainMaxAmtLCY then
                    exit;
                RemainMaxAmtLCY := RemainMaxAmtLCY - ToGlLine."Amount (LCY)";
            end;

            ToGlLine."Recipient Bank Account" := VendEntry."Recipient Bank Account";
            // Debit Bank from Vendor Bank or Vendor?
            if VendBank."Debit Bank" <> '' then
                DtaSetup.Get(VendBank."Debit Bank")
            else begin
                if not AutoDebitBank then
                    DtaSetup.Get(ReqFormDebitBank."Bank Code");
                // Get Debit Bank automatically
                if AutoDebitBank then begin
                    DtaSetup."Bank Code" := '';
                    // reset
                    DtaSetup.Reset();
                    // Bank according to Currency available? Else, main Bank in LCY
                    if not (VendEntry."Currency Code" in ['', GlSetup."LCY Code"]) then begin
                        DtaSetup.SetRange("DTA Currency Code", VendEntry."Currency Code");
                        if not DtaSetup.FindFirst() then;
                    end;
                    // Main bank with currency '' or LCY
                    if DtaSetup."Bank Code" = '' then begin
                        DtaSetup.SetFilter("DTA Currency Code", '%1|%2', '', GlSetup."LCY Code");
                        DtaSetup.SetRange("DTA Main Bank", true);
                        if not DtaSetup.FindFirst() then
                            Error(Text021, GlSetup."LCY Code");
                    end;
                end;
            end;
            // From Vendor Bank, Requestform or Autobank(Currency Code)
            ToGlLine."Debit Bank" := DtaSetup."Bank Code";

            if DtaSetup."DTA/EZAG" = DtaSetup."DTA/EZAG"::DTA then
                DtaSetup.TestField("DTA Sender Clearing");

            ToGlLine."Source Code" := 'DTA';
            ToGlLine.Clearing := DtaSetup."DTA Sender Clearing";
            ToGlLine."Due Date" := VendEntry."Due Date";
            ToGlLine.Insert();

            NoOfLinesInserted := NoOfLinesInserted + 1;
            Window.Update(2, NoOfLinesInserted);
            TotalAmtLCY := TotalAmtLCY + ToGlLine."Amount (LCY)";
            Window.Update(3, TotalAmtLCY);

            PmtsPerVendor := PmtsPerVendor + 1;

            VendorLedgerEntry2.Get(VendorLedgerEntryNo);
            VendorLedgerEntry2."On Hold" := 'DTA';
            VendorLedgerEntry2."Accepted Payment Tolerance" := 0;
            VendorLedgerEntry2.Modify();
        end else begin
            VendorLedgEntryTemp := VendEntry;
            if VendorLedgEntryTemp.Insert() then;
        end;
    end;

    [Scope('OnPrem')]
    procedure WriteBalAccountLine(_GenJnlLine: Record "Gen. Journal Line")
    var
        PmtLine: Record "Gen. Journal Line";
        BalAccLine: Record "Gen. Journal Line";
        BalAccDtaBank: Record "DTA Setup";
    begin
        // delete old bal. lines
        GlSetup.Get();

        PmtLine.SetRange("Journal Template Name", _GenJnlLine."Journal Template Name");
        PmtLine.SetRange("Journal Batch Name", _GenJnlLine."Journal Batch Name");
        PmtLine.SetRange("Source Code", 'BALANCE');
        if PmtLine.Find('-') then
            PmtLine.DeleteAll();

        // Store last Line No.
        PmtLine.SetRange("Source Code");
        if PmtLine.Find('+') then begin
            LastLineNo := PmtLine."Line No.";
            DocNo := PmtLine."Document No.";
            PostDate := PmtLine."Posting Date";
        end;

        // Filter Vend. Pmt. Records
        PmtLine.SetRange("Account Type", PmtLine."Account Type"::Vendor);
        PmtLine.SetRange("Document Type", PmtLine."Document Type"::Payment);
        PmtLine.SetFilter(Amount, '<>%1', 0);

        if PmtLine.Find('-') then
            repeat
                if not BalAccDtaBank.Get(PmtLine."Debit Bank") then
                    Error(Text024, PmtLine."Account No.", PmtLine."Document No.");

                if BalAccDtaBank."Bal. Account Type" = BalAccDtaBank."Bal. Account Type"::"G/L Account" then begin
                    if not GlAcc.Get(BalAccDtaBank."Bal. Account No.") then
                        Error(Text025, BalAccDtaBank."Bank Code");
                    AccountCurrency := GlAcc."Source Currency Code";
                end;

                if BalAccDtaBank."Bal. Account Type" = BalAccDtaBank."Bal. Account Type"::"Bank Account" then begin
                    if not BankAccNo.Get(BalAccDtaBank."Bal. Account No.") then
                        Error(Text025, BalAccDtaBank."Bank Code");
                    AccountCurrency := BankAccNo."Currency Code";
                end;

                PaymentCurrency := PmtLine."Currency Code";

                if AccountCurrency = '' then
                    AccountCurrency := GlSetup."LCY Code";

                if PaymentCurrency = '' then
                    PaymentCurrency := GlSetup."LCY Code";

                BalAccDesc := Format(StrSubstNo(Text028, BalAccDtaBank."Bank Code", AccountCurrency, PaymentCurrency),
                    -MaxStrLen(BalAccDesc));

                // Line already inserted?
                BalAccLine.SetRange("Journal Template Name", PmtLine."Journal Template Name");
                BalAccLine.SetRange("Journal Batch Name", PmtLine."Journal Batch Name");
                BalAccLine.SetRange("Account Type", BalAccDtaBank."Bal. Account Type");
                BalAccLine.SetFilter(Description, '%1', BalAccDesc);

                // Create line
                if not BalAccLine.FindFirst() then begin
                    BalAccLine.Init();
                    BalAccLine."Journal Template Name" := PmtLine."Journal Template Name";
                    BalAccLine."Journal Batch Name" := PmtLine."Journal Batch Name";
                    LastLineNo := LastLineNo + 10000;
                    BalAccLine."Line No." := LastLineNo;
                    BalAccLine."Document No." := DocNo;
                    BalAccLine."Source Code" := 'BALANCE';
                    BalAccLine."Document Type" := BalAccLine."Document Type"::Payment;
                    BalAccLine.Validate("Posting Date", PostDate);
                    BalAccLine.Validate("Account Type", BalAccDtaBank."Bal. Account Type");
                    BalAccLine.Validate("Account No.", BalAccDtaBank."Bal. Account No.");
                    BalAccLine.Description := BalAccDesc;
                    BalAccLine.Clearing := '99999';  // End of Sorting
                    BalAccLine."Posting No. Series" := GlBatchName2."Posting No. Series";
                    BalAccLine.Insert();
                end;

                if (AccountCurrency <> PaymentCurrency) and (AccountCurrency <> GlSetup."LCY Code") then begin
                    CurrencyFactor := CurrExch.ExchangeRate(PostDate, AccountCurrency);
                    PmtLineAmount := CurrExch.ExchangeAmtLCYToFCY(PostDate, AccountCurrency, PmtLine."Amount (LCY)", CurrencyFactor);
                    Currency.Get(AccountCurrency);
                    PmtLineAmount := Round(PmtLineAmount, Currency."Amount Rounding Precision");
                end else begin
                    PmtLineAmount := PmtLine.Amount;
                    BalAccLine."Currency Code" := PmtLine."Currency Code";
                end;

                BalAccLine.Amount := BalAccLine.Amount - PmtLineAmount;

                BalAccLine."Amount (LCY)" := BalAccLine."Amount (LCY)" - PmtLine."Amount (LCY)";
                BalAccLine.Validate("Amount (LCY)");  // Currency Factor calculated based on Amount and Amount LCY
                BalAccLine.Modify();

            until PmtLine.Next() = 0;
    end;
}