// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Posting;
using System.Utilities;

codeunit 6974 "Cancel Posted Expense Report"
{
    Access = Internal;
    TableNo = "Posted Expense Report Header";
    Permissions = TableData "Posted Expense Report Header" = rm,
                  TableData "Posted Expense Report Line" = rm,
                  TableData "Expense Ledger Entry" = rim,
                  TableData Expense = rm;

    trigger OnRun()
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        PostedExpenseReportHeader.Get(Rec."No.");
        Cancel(PostedExpenseReportHeader);
        Rec := PostedExpenseReportHeader;
    end;

    var
        ConfirmCancelQst: Label 'Do you want to cancel posted expense report %1 ?', Comment = '%1 = Posted Expense Report No.';
        AlreadyCanceledErr: Label 'Posted expense report %1 has already been canceled.', Comment = '%1 = Posted Expense Report No.';
        CanceledSuccessMsg: Label 'Posted expense report %1 has been canceled.', Comment = '%1 = Posted Expense Report No.';

    /// <summary>
    /// Prompts the user for confirmation and cancels the posted expense report.
    /// Reverses the G/L transactions and the Expense Ledger Entry, releases the
    /// related Expense records, and marks the header status as Canceled.
    /// </summary>
    /// <param name="PostedExpenseReportHeader">The posted expense report to cancel.</param>
    procedure CancelPostedExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        PostedExpenseReportHeaderCopy: Record "Posted Expense Report Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if PostedExpenseReportHeader.Canceled then
            Error(AlreadyCanceledErr, PostedExpenseReportHeader."No.");

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmCancelQst, PostedExpenseReportHeader."No."), false) then
            exit;

        PostedExpenseReportHeaderCopy.Copy(PostedExpenseReportHeader);
        Cancel(PostedExpenseReportHeaderCopy);
        PostedExpenseReportHeader := PostedExpenseReportHeaderCopy;

        Message(CanceledSuccessMsg, PostedExpenseReportHeader."No.");
    end;

    local procedure Cancel(var PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ReversalTransactionNo: Integer;
    begin
        if PostedExpenseReportHeader.Canceled then
            Error(AlreadyCanceledErr, PostedExpenseReportHeader."No.");

        ReversalTransactionNo := ReverseGLTransaction(PostedExpenseReportHeader);

        PostedExpenseReportLine.LockTable();
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLine.SetRange(Canceled, false);
        if PostedExpenseReportLine.FindSet() then
            repeat
                ReverseExpenseLedgerEntries(PostedExpenseReportHeader, PostedExpenseReportLine, ReversalTransactionNo);
                ReverseJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine);
                ReleaseRelatedExpense(PostedExpenseReportLine);
                PostedExpenseReportLine.Canceled := true;
                PostedExpenseReportLine.Modify();
            until PostedExpenseReportLine.Next() = 0;

        PostedExpenseReportHeader.Canceled := true;
        PostedExpenseReportHeader.Modify();
    end;

    local procedure ReverseGLTransaction(PostedExpenseReportHeader: Record "Posted Expense Report Header"): Integer
    var
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange("Posting Date", PostedExpenseReportHeader."Posting Date");
        ExpenseLedgerEntry.SetRange(Reversed, false);
        if not ExpenseLedgerEntry.FindSet() then
            exit(0);

        ExpenseLedgerEntry.TestField("Transaction No.");

        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseTransaction(ExpenseLedgerEntry."Transaction No.");

        exit(GetTransactionNo(ExpenseLedgerEntry."Transaction No."));
    end;

    local procedure ReverseExpenseLedgerEntries(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; ReversalTransactionNo: Integer)
    var
        OriginalExpenseLedgerEntry: Record "Expense Ledger Entry";
        ReverseExpenseLedgerEntry: Record "Expense Ledger Entry";
    begin
        OriginalExpenseLedgerEntry.LockTable();
        OriginalExpenseLedgerEntry.SetRange("Posting Date", PostedExpenseReportHeader."Posting Date");
        OriginalExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        OriginalExpenseLedgerEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
        OriginalExpenseLedgerEntry.SetRange(Reversed, false);
        if not OriginalExpenseLedgerEntry.FindFirst() then
            exit;

        ReverseExpenseLedgerEntry.LockTable();
        ReverseExpenseLedgerEntry := OriginalExpenseLedgerEntry;
        ReverseExpenseLedgerEntry."Entry No." := ReverseExpenseLedgerEntry.GetNextEntryNo();
        ReverseExpenseLedgerEntry."Posting Date" := PostedExpenseReportHeader."Posting Date";
        ReverseExpenseLedgerEntry."Original Amount" := -OriginalExpenseLedgerEntry."Original Amount";
        ReverseExpenseLedgerEntry."Original Amt. (LCY)" := -OriginalExpenseLedgerEntry."Original Amt. (LCY)";
        ReverseExpenseLedgerEntry.Amount := -OriginalExpenseLedgerEntry.Amount;
        ReverseExpenseLedgerEntry."Amount (LCY)" := -OriginalExpenseLedgerEntry."Amount (LCY)";
        ReverseExpenseLedgerEntry."Refundable Amount" := -OriginalExpenseLedgerEntry."Refundable Amount";
        ReverseExpenseLedgerEntry."Refundable Amount (LCY)" := -OriginalExpenseLedgerEntry."Refundable Amount (LCY)";
        ReverseExpenseLedgerEntry."Non-Refundable Amount" := -OriginalExpenseLedgerEntry."Non-Refundable Amount";
        ReverseExpenseLedgerEntry."Non-Refundable Amount (LCY)" := -OriginalExpenseLedgerEntry."Non-Refundable Amount (LCY)";
        ReverseExpenseLedgerEntry."Reimbursable Amount" := -OriginalExpenseLedgerEntry."Reimbursable Amount";
        ReverseExpenseLedgerEntry."Reimbursable Amount (LCY)" := -OriginalExpenseLedgerEntry."Reimbursable Amount (LCY)";
        ReverseExpenseLedgerEntry.Reversed := true;
        ReverseExpenseLedgerEntry."Reversed Entry No." := OriginalExpenseLedgerEntry."Entry No.";
        ReverseExpenseLedgerEntry."Reversed by Entry No." := 0;
        ReverseExpenseLedgerEntry."Transaction No." := ReversalTransactionNo;
        ReverseExpenseLedgerEntry.Insert();

        OriginalExpenseLedgerEntry.Reversed := true;
        OriginalExpenseLedgerEntry."Reversed by Entry No." := ReverseExpenseLedgerEntry."Entry No.";
        OriginalExpenseLedgerEntry.Modify();
    end;

    local procedure GetTransactionNo(TransactionNo: Integer): Integer
    var
        GLEntry: Record "G/L Entry";
        ReversedGLEntry: Record "G/L Entry";
    begin
        if TransactionNo = 0 then
            exit(0);

        GLEntry.SetLoadFields("Entry No.", "Transaction No.");
        GLEntry.SetRange("Transaction No.", TransactionNo);
        if GLEntry.FindFirst() then begin
            ReversedGLEntry.SetLoadFields("Transaction No.", "Reversed Entry No.");
            ReversedGLEntry.SetRange("Reversed Entry No.", GLEntry."Entry No.");
            if ReversedGLEntry.FindFirst() then
                exit(ReversedGLEntry."Transaction No.");
        end;
    end;

    local procedure ReverseJobLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line")
    var
        OriginalJobLedgerEntry: Record "Job Ledger Entry";
        JobJournalLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        if PostedExpenseReportLine."Job Ledger Entry No." = 0 then
            exit;

        if not OriginalJobLedgerEntry.Get(PostedExpenseReportLine."Job Ledger Entry No.") then
            exit;

        JobJournalLine.Init();
        JobJournalLine."Source Code" := OriginalJobLedgerEntry."Source Code";
        JobJournalLine.Validate("Line Type", JobJournalLine."Line Type"::Billable);
        JobJournalLine.Validate("Posting Date", PostedExpenseReportHeader."Posting Date");
        JobJournalLine.Validate("Document No.", PostedExpenseReportHeader."No.");
        JobJournalLine.Validate("Job No.", OriginalJobLedgerEntry."Job No.");
        JobJournalLine.Validate("Job Task No.", OriginalJobLedgerEntry."Job Task No.");
        JobJournalLine.Validate(Type, JobJournalLine.Type::"G/L Account");
        JobJournalLine.Validate("No.", OriginalJobLedgerEntry."No.");
        JobJournalLine.Validate(Quantity, -OriginalJobLedgerEntry.Quantity);
        JobJournalLine.Validate("Unit Cost (LCY)", OriginalJobLedgerEntry."Unit Cost (LCY)");
        JobJournalLine.Validate("Unit Price (LCY)", OriginalJobLedgerEntry."Unit Price (LCY)");
        JobJournalLine.Validate("Dimension Set ID", OriginalJobLedgerEntry."Dimension Set ID");
        JobJournalLine."Expense Report No." := PostedExpenseReportHeader."No.";
        JobJournalLine."Expense Report Line No." := PostedExpenseReportLine."Line No.";
        JobJnlPostLine.RunWithCheck(JobJournalLine);
    end;

    local procedure ReleaseRelatedExpense(PostedExpenseReportLine: Record "Posted Expense Report Line")
    var
        Expense: Record Expense;
    begin
        if PostedExpenseReportLine."Expense No." = '' then
            exit;

        if not Expense.Get(PostedExpenseReportLine."Expense No.") then
            exit;

        Expense.Status := Expense.Status::Released;
        Expense."Expense Report No." := '';
        Expense."Posted Expense Report No." := '';
        Expense.Modify();
    end;
}