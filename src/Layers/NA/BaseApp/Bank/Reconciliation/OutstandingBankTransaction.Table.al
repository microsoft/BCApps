// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Deposit;
using Microsoft.Bank.Ledger;

/// <summary>
/// Tracks bank transactions that remain unmatched or outstanding during bank reconciliation processes.
/// This table maintains records of bank account ledger entries and check transactions that have not been
/// cleared or matched against bank statement lines. Used for identifying discrepancies, monitoring
/// outstanding items, and generating reconciliation reports for management review.
/// </summary>
/// <remarks>
/// Key functionality includes outstanding transaction tracking across multiple transaction types,
/// age analysis for overdue items, currency handling for multi-currency bank accounts,
/// and integration with bank reconciliation workflows. Supports both automatic detection
/// of outstanding items and manual addition of reconciling items. Used extensively for
/// month-end reconciliation processes and audit trail maintenance.
/// </remarks>
table 1284 "Outstanding Bank Transaction"
{
    Caption = 'Outstanding Bank Transaction';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique entry number for the outstanding bank transaction.
        /// Provides identification and linking to source ledger entries.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Posting date of the original bank transaction.
        /// Used for chronological analysis and reconciliation matching.
        /// </summary>
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Document type of the original transaction.
        /// Indicates the nature of the business transaction creating the outstanding item.
        /// </summary>
        field(3; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,,Deposit';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,,Deposit;
        }
        /// <summary>
        /// Document number of the original transaction.
        /// Used for reference matching and transaction identification.
        /// </summary>
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Bank account number where the outstanding transaction occurred.
        /// Identifies which bank account has the unreconciled transaction.
        /// </summary>
        field(5; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
        }
        /// <summary>
        /// Description of the outstanding bank transaction.
        /// Provides context and identification for reconciliation purposes.
        /// </summary>
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Transaction amount for the outstanding bank transaction.
        /// Shows the unreconciled amount that needs to be matched with bank statements.
        /// </summary>
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'Amount';
        }
        /// <summary>
        /// Type of source ledger entry for the outstanding transaction.
        /// Determines which ledger table contains the original transaction record.
        /// </summary>
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank Account Ledger Entry,Check Ledger Entry';
            OptionMembers = "Bank Account Ledger Entry","Check Ledger Entry";
        }
        /// <summary>
        /// Indicates whether the outstanding transaction has been applied in reconciliation.
        /// Controls visibility and processing during bank reconciliation workflows.
        /// </summary>
        field(9; Applied; Boolean)
        {
            Caption = 'Applied';
        }
        /// <summary>
        /// Type of statement used for reconciliation processing.
        /// Determines the reconciliation workflow and processing logic.
        /// </summary>
        field(10; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            OptionCaption = 'Bank Reconciliation,Payment Application';
            OptionMembers = "Bank Reconciliation","Payment Application";
        }
        /// <summary>
        /// Statement number when the transaction was applied during reconciliation.
        /// Links the transaction to the specific reconciliation session.
        /// </summary>
        field(11; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
        }
        field(10010; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(10011; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
    }

    keys
    {
        key(Key1; "External Document No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
        }
    }

    fieldgroups
    {
    }

    procedure DrillDown(BankAccNo: Code[20]; TransactionType: Option; StatementType: Integer; StatementNo: Code[20])
    var
        TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary;
    begin
        CreateTempOutstandingBankTrxs(TempOutstandingBankTransaction, BankAccNo, StatementType, StatementNo);
        SetOutstandingBankTrxFilter(TempOutstandingBankTransaction, TransactionType);
        RunOustandingBankTrxsPage(TempOutstandingBankTransaction, TransactionType);
    end;

    procedure CreateTempOutstandingBankTrxs(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; BankAccNo: Code[20]; StatementType: Integer; StatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TempOutstandingBankTransactionCopy: Record "Outstanding Bank Transaction" temporary;
        RemainingAmt: Decimal;
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        TempOutstandingBankTransactionCopy.DeleteAll();
        if BankAccountLedgerEntry.FindSet() then
            repeat
                RemainingAmt := BankAccountLedgerEntry.Amount - GetAppliedAmount(BankAccountLedgerEntry."Entry No.");
                if RemainingAmt <> 0 then begin
                    TempOutstandingBankTransaction.Init();
                    CreateTheDepositHeaderLine(TempOutstandingBankTransaction, TempOutstandingBankTransactionCopy, BankAccountLedgerEntry);
                    TempOutstandingBankTransaction."Posting Date" := BankAccountLedgerEntry."Posting Date";
                    TempOutstandingBankTransaction."Document Type" := BankAccountLedgerEntry."Document Type".AsInteger();
                    TempOutstandingBankTransaction."Document No." := BankAccountLedgerEntry."Document No.";
                    TempOutstandingBankTransaction."Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
                    TempOutstandingBankTransaction.Description := BankAccountLedgerEntry.Description;
                    TempOutstandingBankTransaction.Amount := RemainingAmt;
                    TempOutstandingBankTransaction."Entry No." := BankAccountLedgerEntry."Entry No.";
                    TempOutstandingBankTransaction."Statement Type" := StatementType;
                    TempOutstandingBankTransaction."Statement No." := StatementNo;
                    BankAccountLedgerEntry.CalcFields("Check Ledger Entries");
                    if BankAccountLedgerEntry."Check Ledger Entries" > 0 then
                        TempOutstandingBankTransaction.Type := TempOutstandingBankTransaction.Type::"Check Ledger Entry"
                    else
                        TempOutstandingBankTransaction.Type := TempOutstandingBankTransaction.Type::"Bank Account Ledger Entry";
                    TempOutstandingBankTransaction.Insert();
                end;
            until BankAccountLedgerEntry.Next() = 0;
    end;

    procedure CreateTheDepositHeaderLine(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; var TempOutstandingBankTransactionCopy: Record "Outstanding Bank Transaction" temporary; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        PostedDepositHeader: Record "Posted Deposit Header";
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        PostedDepositLine.SetRange("Document Type", BankAccountLedgerEntry."Document Type");
        PostedDepositLine.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
        if PostedDepositLine.FindFirst() then begin
            PostedDepositHeader.Get(PostedDepositLine."Deposit No.");
            TempOutstandingBankTransaction.Init();
            TempOutstandingBankTransactionCopy.SetRange("External Document No.", BankAccountLedgerEntry."External Document No.");
            if not TempOutstandingBankTransactionCopy.FindFirst() then begin
                TempOutstandingBankTransaction."Posting Date" := PostedDepositHeader."Posting Date";
                TempOutstandingBankTransaction."Document No." := PostedDepositHeader."No.";
                TempOutstandingBankTransaction."Document Type" := TempOutstandingBankTransaction."Document Type"::Deposit;
                TempOutstandingBankTransaction."Bank Account No." := PostedDepositHeader."Bank Account No.";
                TempOutstandingBankTransaction.Description := PostedDepositHeader."Posting Description";
                TempOutstandingBankTransaction.Amount := PostedDepositHeader."Total Deposit Amount";
                TempOutstandingBankTransaction.Indentation := 0;
                TempOutstandingBankTransaction."Entry No." := 0;
                TempOutstandingBankTransaction."External Document No." := BankAccountLedgerEntry."External Document No.";
                TempOutstandingBankTransaction.Insert();
                TempOutstandingBankTransactionCopy.Copy(TempOutstandingBankTransaction);
                TempOutstandingBankTransactionCopy.Insert();
            end;
            TempOutstandingBankTransaction.Indentation := 1;
        end else
            TempOutstandingBankTransaction.Indentation := 0;
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if ("Bank Account No." = BankAcc."No.") or BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    local procedure SetOutstandingBankTrxFilter(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; TransactionType: Option)
    begin
        TempOutstandingBankTransaction.Reset();
        TempOutstandingBankTransaction.FilterGroup := 2;
        TempOutstandingBankTransaction.SetRange(Type, TransactionType);
        TempOutstandingBankTransaction.SetRange(Applied, false);
        TempOutstandingBankTransaction.FilterGroup := 0;
    end;

    local procedure RunOustandingBankTrxsPage(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; TransactionType: Option)
    var
        OutstandingBankTransactions: Page "Outstanding Bank Transactions";
    begin
        OutstandingBankTransactions.SetRecords(TempOutstandingBankTransaction);
        OutstandingBankTransactions.SetPageCaption(TransactionType);
        OutstandingBankTransactions.SetTableView(TempOutstandingBankTransaction);
        OutstandingBankTransactions.Run();
    end;

    procedure CopyFromBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankTransacType: Integer; StatementType: Integer; StatementNo: Code[20]; RemainingAmt: Decimal; IndentationValue: Integer)
    begin
        Init();
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Document Type" := BankAccountLedgerEntry."Document Type".AsInteger();
        "Document No." := BankAccountLedgerEntry."Document No.";
        "Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
        Description := BankAccountLedgerEntry.Description;
        Amount := RemainingAmt;
        Type := BankTransacType;
        "Statement Type" := StatementType;
        "Statement No." := StatementNo;
        Indentation := IndentationValue;
        Insert();
    end;

    procedure GetAppliedAmount(EntryNo: Integer) AppliedAmt: Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", EntryNo);
        if AppliedPaymentEntry.FindSet() then
            repeat
                AppliedAmt += AppliedPaymentEntry."Applied Amount";
            until AppliedPaymentEntry.Next() = 0;

        exit(AppliedAmt);
    end;

    procedure GetRemainingAmount(EntryNo: Integer) RemainingAmt: Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", EntryNo);
        if not AppliedPaymentEntry.FindFirst() then
            exit;

        RemainingAmt := AppliedPaymentEntry.GetRemAmt();
        exit(RemainingAmt);
    end;
}
