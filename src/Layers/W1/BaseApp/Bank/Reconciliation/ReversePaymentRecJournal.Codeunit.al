// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 386 "Reverse Payment Rec. Journal"
{
    EventSubscriberInstance = Manual;

    var
        EmptyTransactionNoErr: Label 'Entry %1 cannot be reversed because its "Transaction No." is not defined.', Comment = '%1 - The Entry No. of the transaction that cannot be reversed';
        PostedPaymentReconciliationNotSelectedErr: Label 'You must select a journal to reverse.';
        CantFindRelatedEntriesErr: Label 'Related entries not found. To unapply and reverse payments you must do it manually.';
        PaymentRecJournalAlreadyReversedErr: Label 'This payment reconciliation journal has already been reversed.';
        GLRegisterNo: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitGLRegister', '', false, false)]
    local procedure SetGLRegisterNoInPostedPaymentRecHeader(var GLRegister: Record "G/L Register"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLRegisterNo := GLRegister."No.";
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Posted Payment Recon. Hdr", 'M', InherentPermissionsScope::Both)]
    procedure SetGLRegisterNo(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr";
    begin
        if GLRegisterNo = 0 then
            exit;
        if not PostedPaymentReconHdr.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.") then
            exit;
        PostedPaymentReconHdr."G/L Register No." := GLRegisterNo;
        PostedPaymentReconHdr.Modify();
    end;

    procedure RunReversalWizard(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr")
    var
        BankAccountStatement: Record "Bank Account Statement";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PmtRecUndoStatement: Page "Pmt. Rec. Undo Statement";
        PaymentRecRelatedEntries: Page "Payment Rec. Related Entries";
        PmtRecReversalFinalize: Page "Pmt. Rec. Reversal Finalize";
        WizardState: Option UndoStatement,RelatedEntries,Finalize,Done;
        NewStatementNo: Code[20];
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        HasBankStatement: Boolean;
    begin
        if PostedPaymentReconHdr."Is Reversed" then
            Error(PaymentRecJournalAlreadyReversedErr);
        BankAccountNo := PostedPaymentReconHdr."Bank Account No.";
        StatementNo := PostedPaymentReconHdr."Statement No.";
        BankAccountStatement.SetRange("Bank Account No.", BankAccountNo);
        BankAccountStatement.SetRange("Statement No.", StatementNo);
        PostedPaymentReconHdr.CalcFields("Is Reconciled");

        // Misconfigured page caller
        if PostedPaymentReconHdr.IsEmpty() then
            Error(PostedPaymentReconciliationNotSelectedErr);

        InsertPaymentRecRelatedAndAppliedEntries(PostedPaymentReconHdr);
        RefreshRelatedEntriesReversalStatus(PostedPaymentReconHdr."Bank Account No.", PostedPaymentReconHdr."Statement No.", true);
        Commit();
        WizardState := WizardState::UndoStatement;
        repeat
            HasBankStatement := not BankAccountStatement.IsEmpty();
            Clear(PmtRecUndoStatement);
            Clear(PaymentRecRelatedEntries);
            Clear(PmtRecReversalFinalize);
            case WizardState of
                WizardState::UndoStatement:
                    begin
                        PmtRecUndoStatement.SetBankAccountStatement(BankAccountNo, StatementNo);
                        if TryOpenPmtRecUndoStatement(PmtRecUndoStatement) then begin
                            if PmtRecUndoStatement.NextSelected() then
                                WizardState := WizardState::RelatedEntries
                            else
                                exit;
                        end else
                            WizardState := WizardState::RelatedEntries;
                    end;
                WizardState::RelatedEntries:
                    begin
                        PaymentRecRelatedEntries.SetPaymentRecRelatedEntries(BankAccountNo, StatementNo);
                        if not HasBankStatement then
                            PaymentRecRelatedEntries.HideBackAction();
                        PaymentRecRelatedEntries.RunModal();
                        if PaymentRecRelatedEntries.NextSelected() then
                            WizardState := WizardState::Finalize
                        else
                            if PaymentRecRelatedEntries.BackSelected() then
                                WizardState := WizardState::UndoStatement
                            else
                                exit;
                    end;
                WizardState::Finalize:
                    begin
                        PmtRecReversalFinalize.SetPaymentRecRelatedEntries(BankAccountNo, StatementNo);
                        if not HasBankStatement then
                            PmtRecReversalFinalize.SetNoStatementMsg();
                        PmtRecReversalFinalize.RunModal();
                        if PmtRecReversalFinalize.FinalizeSelected() then begin
                            FinalizeReversal(BankAccountNo, StatementNo);
                            Commit();
                            if PmtRecReversalFinalize.CreatePaymentRecJournalSelected() then
                                NewStatementNo := CreateCopyPaymentRecJournal(PostedPaymentReconHdr);
                            CleanUpReversal(PostedPaymentReconHdr);
                            WizardState := WizardState::Done;
                        end
                        else
                            if PmtRecReversalFinalize.BackSelected() then
                                WizardState := WizardState::RelatedEntries
                            else
                                exit;
                    end;
            end;
        until WizardState = WizardState::Done;
        if NewStatementNo <> '' then begin
            BankAccReconciliationLine.FilterGroup(2);
            BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Payment Application");
            BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
            BankAccReconciliationLine.SetRange("Statement No.", NewStatementNo);
            BankAccReconciliationLine.FilterGroup(0);
            Page.Run(Page::"Payment Reconciliation Journal", BankAccReconciliationLine);
        end;
    end;

    [TryFunction]
    local procedure TryOpenPmtRecUndoStatement(var PmtRecUndoStatement: Page "Pmt. Rec. Undo Statement")
    begin
        PmtRecUndoStatement.RunModal();
    end;

    local procedure InsertPaymentRecRelatedAndAppliedEntries(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr")
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
        PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry";
        BankAccountStatement: Record "Bank Account Statement";
        GLRegister: Record "G/L Register";
    begin
        // Entries PaymentRecRelatedEntry, PmtRecAppliedToEntry are only inserted if not previously inserted
        PaymentRecRelatedEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        PaymentRecRelatedEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
        if not PaymentRecRelatedEntry.IsEmpty() then
            exit;
        PmtRecAppliedToEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        PmtRecAppliedToEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
        if not PmtRecAppliedToEntry.IsEmpty() then
            exit;

        if PostedPaymentReconHdr."Is Reconciled" then
            if BankAccountStatement.Get(PostedPaymentReconHdr."Bank Account No.", PostedPaymentReconHdr."Statement No.") then begin
                InsertRelatedAndAppliedEntries(PostedPaymentReconHdr."Bank Account No.", PostedPaymentReconHdr."Statement No.");
                PostedPaymentReconHdr."Entries found with G/L Reg." := false;
                PostedPaymentReconHdr.Modify();
                exit;
            end;
        if PostedPaymentReconHdr."G/L Register No." <> 0 then
            if GLRegister.Get(PostedPaymentReconHdr."G/L Register No.") then begin
                InsertRelatedAndAppliedEntriesOfGLRegister(GLRegister, PostedPaymentReconHdr);
                PostedPaymentReconHdr."Entries found with G/L Reg." := true;
                PostedPaymentReconHdr.Modify();
                exit;
            end;
        Error(CantFindRelatedEntriesErr);
    end;

    local procedure CreateCopyPaymentRecJournal(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr"): Code[20]
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation.TransferFields(PostedPaymentReconHdr);
        BankAccReconciliation."Statement No." := '';
        BankAccReconciliation.Validate("Statement Type", BankAccReconciliation."Statement Type"::"Payment Application");
        BankAccReconciliation.Validate("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        BankAccReconciliation.Insert(true);
        if not PostedPaymentReconHdr."Entries found with G/L Reg." then
            CopyPaymentRecJournalFromPostedPaymentReconLines(PostedPaymentReconHdr, BankAccReconciliation)
        else
            CopyPaymentRecJournalFromPaymentRecRelatedEntries(PostedPaymentReconHdr, BankAccReconciliation);

        OnAfterCreateCopyPaymentRecJournal(PostedPaymentReconHdr, BankAccReconciliation);

        exit(BankAccReconciliation."Statement No.");
    end;

    local procedure CopyPaymentRecJournalFromPaymentRecRelatedEntries(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr"; var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry";
    begin
        PaymentRecRelatedEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        PaymentRecRelatedEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
        PaymentRecRelatedEntry.SetFilter("Entry Type", '<>%1', PaymentRecRelatedEntry."Entry Type"::"Bank Account");
        if not PaymentRecRelatedEntry.FindSet() then
            exit;
        repeat
            BankAccReconciliationLine.Init();
            BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
            BankAccReconciliationLine."Statement Line No." := PaymentRecRelatedEntry."Statement Line No.";
            BankAccReconciliationLine."Bank Account No." := PaymentRecRelatedEntry."Bank Account No.";
            BankAccReconciliationLine."Statement Type" := BankAccReconciliationLine."Statement Type"::"Payment Application";
            SetBankRecLineDetailsFromPaymentRecRelatedEntry(BankAccReconciliationLine, PaymentRecRelatedEntry);
            BankAccReconciliationLine.Insert(true);
            PmtRecAppliedToEntry.Reset();
            PmtRecAppliedToEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
            PmtRecAppliedToEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
            PmtRecAppliedToEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
            if PaymentRecRelatedEntry.Reversed then
                if PmtRecAppliedToEntry.FindSet() then
                    repeat
                        CreateApplicationEntryForBankAccReconciliationLine(BankAccReconciliationLine, PmtRecAppliedToEntry);
                    until PmtRecAppliedToEntry.Next() = 0;
        until PaymentRecRelatedEntry.Next() = 0;
    end;

    local procedure SetBankRecLineDetailsFromPaymentRecRelatedEntry(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        BankAccReconciliationLine."Applied Amount" := 0;
        case PaymentRecRelatedEntry."Entry Type" of
            PaymentRecRelatedEntry."Entry Type"::Customer:
                if CustLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.") then begin
                    BankAccReconciliationLine."Account Type" := BankAccReconciliationLine."Account Type"::Customer;
                    BankAccReconciliationLine."Account No." := CustLedgerEntry."Customer No.";
                    BankAccReconciliationLine.Description := CustLedgerEntry.Description;
                    BankAccReconciliationLine."Transaction Text" := CustLedgerEntry.Description;
                    BankAccReconciliationLine."Transaction Date" := CustLedgerEntry."Posting Date";
                    BankAccReconciliationLine.Validate("Statement Amount", -CustLedgerEntry."Closed by Amount");
                end;
            PaymentRecRelatedEntry."Entry Type"::Vendor:
                if VendorLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.") then begin
                    BankAccReconciliationLine."Account Type" := BankAccReconciliationLine."Account Type"::Vendor;
                    BankAccReconciliationLine."Account No." := VendorLedgerEntry."Vendor No.";
                    BankAccReconciliationLine.Description := VendorLedgerEntry.Description;
                    BankAccReconciliationLine."Transaction Text" := VendorLedgerEntry.Description;
                    BankAccReconciliationLine."Transaction Date" := VendorLedgerEntry."Posting Date";
                    BankAccReconciliationLine.Validate("Statement Amount", -VendorLedgerEntry."Closed by Amount");
                end;
            PaymentRecRelatedEntry."Entry Type"::Employee:
                if EmployeeLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.") then begin
                    BankAccReconciliationLine."Account Type" := BankAccReconciliationLine."Account Type"::Employee;
                    BankAccReconciliationLine."Account No." := EmployeeLedgerEntry."Employee No.";
                    BankAccReconciliationLine.Description := EmployeeLedgerEntry.Description;
                    BankAccReconciliationLine."Transaction Text" := EmployeeLedgerEntry.Description;
                    BankAccReconciliationLine."Transaction Date" := EmployeeLedgerEntry."Posting Date";
                    BankAccReconciliationLine.Validate("Statement Amount", -EmployeeLedgerEntry."Closed by Amount");
                end;
        end;
    end;

    local procedure CopyPaymentRecJournalFromPostedPaymentReconLines(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr"; var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry";
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
    begin
        PostedPaymentReconLine.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        PostedPaymentReconLine.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
        if not PostedPaymentReconLine.FindSet() then
            exit;
        repeat
            BankAccReconciliationLine.Init();
            BankAccReconciliationLine.TransferFromPostedPaymentReconLine(PostedPaymentReconLine);
            BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
            BankAccReconciliationLine.Insert(true);
            OnCopyPaymentRecJournalFromPostedPaymentReconLinesOnAfterInsertBankAccReconciliationLine(PostedPaymentReconLine, BankAccReconciliationLine);
            // if unapplied create application entry for the new BankAccReconciliationLine
            PmtRecAppliedToEntry.Reset();
            PmtRecAppliedToEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
            PmtRecAppliedToEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
            PmtRecAppliedToEntry.SetRange("Statement Line No.", PostedPaymentReconLine."Statement Line No.");
            PaymentRecRelatedEntry.Reset();
            PaymentRecRelatedEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
            PaymentRecRelatedEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
            PaymentRecRelatedEntry.SetRange("Statement Line No.", PostedPaymentReconLine."Statement Line No.");
            PaymentRecRelatedEntry.SetFilter("Entry Type", '<>%1', PaymentRecRelatedEntry."Entry Type"::"Bank Account");
            if PaymentRecRelatedEntry.FindFirst() then
                if PaymentRecRelatedEntry.Reversed then
                    if PmtRecAppliedToEntry.FindSet() then
                        repeat
                            CreateApplicationEntryForBankAccReconciliationLine(BankAccReconciliationLine, PmtRecAppliedToEntry);
                        until PmtRecAppliedToEntry.Next() = 0;
        until PostedPaymentReconLine.Next() = 0;
    end;

    local procedure CleanUpReversal(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr")
    var
        PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry";
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
    begin
        // We set "Is Reversed" to true, to avoid reversing multiple times
        PostedPaymentReconHdr."Is Reversed" := true;
        PostedPaymentReconHdr.Modify();
        // We also remove the entries created for the reversal: PmtRecRelatedEntry and PaymentRecRelatedEntry
        PmtRecAppliedToEntry.Reset();
        PmtRecAppliedToEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        PmtRecAppliedToEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
        PmtRecAppliedToEntry.DeleteAll();
        PaymentRecRelatedEntry.Reset();
        PaymentRecRelatedEntry.SetRange("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        PaymentRecRelatedEntry.SetRange("Statement No.", PostedPaymentReconHdr."Statement No.");
        PaymentRecRelatedEntry.DeleteAll();
    end;

    procedure UnapplyEntry(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry"; ShowEntriesToPost: Boolean)
    begin
        case PaymentRecRelatedEntry."Entry Type" of
            PaymentRecRelatedEntry."Entry Type"::Customer:
                UnapplyCustomerEntry(PaymentRecRelatedEntry, ShowEntriesToPost);
            PaymentRecRelatedEntry."Entry Type"::Vendor:
                UnapplyVendorEntry(PaymentRecRelatedEntry, ShowEntriesToPost);
            PaymentRecRelatedEntry."Entry Type"::Employee:
                UnapplyEmployeeEntry(PaymentRecRelatedEntry, ShowEntriesToPost);
        end;
    end;

    procedure ReverseEntry(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry"; ShowEntriesToPost: Boolean)
    var
        BankAccountStatement: Record "Bank Account Statement";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        OnBeforeReverseEntry(PaymentRecRelatedEntry);
        if not ShowEntriesToPost then
            ReversalEntry.SetHideWarningDialogs()
        else
            if BankAccountStatement.Get(PaymentRecRelatedEntry."Bank Account No.", PaymentRecRelatedEntry."Statement No.") then
                ReversalEntry.SetBankAccountStatement(PaymentRecRelatedEntry."Bank Account No.", PaymentRecRelatedEntry."Statement No.");

        case PaymentRecRelatedEntry."Entry Type" of
            PaymentRecRelatedEntry."Entry Type"::Customer:
                begin
                    CustLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.");
                    ErrorIfEntryIsNotReversable(CustLedgerEntry);
                    ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");
                end;
            PaymentRecRelatedEntry."Entry Type"::Vendor:
                begin
                    VendorLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.");
                    ErrorIfEntryIsNotReversable(VendorLedgerEntry);
                    ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");
                end;
            PaymentRecRelatedEntry."Entry Type"::Employee:
                begin
                    EmployeeLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.");
                    ErrorIfEntryIsNotReversable(EmployeeLedgerEntry);
                    ReversalEntry.ReverseTransaction(EmployeeLedgerEntry."Transaction No.");
                end;
        end;
        RefreshRelatedEntryReversalStatus(PaymentRecRelatedEntry);
        OnAfterReverseEntry();
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure FinalizeReversal(BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankAccountStatement: Record "Bank Account Statement";
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
    begin
        RefreshRelatedEntriesReversalStatus(BankAccountNo, StatementNo);
        // Undoing bank statement
        if BankAccountStatement.Get(BankAccountNo, StatementNo) then
            UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement, false);
        // Unapplying entries
        PaymentRecRelatedEntry.SetRange("Bank Account No.", BankAccountNo);
        PaymentRecRelatedEntry.SetRange("Statement No.", StatementNo);
        PaymentRecRelatedEntry.SetFilter("Entry Type", '<>%1', PaymentRecRelatedEntry."Entry Type"::"Bank Account");
        PaymentRecRelatedEntry.SetRange(Unapplied, false);
        PaymentRecRelatedEntry.SetRange(ToUnapply, true);
        if PaymentRecRelatedEntry.FindSet() then
            repeat
                PaymentRecRelatedEntry.Unapplied := true;
                UnapplyEntry(PaymentRecRelatedEntry, false);
                PaymentRecRelatedEntry.Modify();
            until PaymentRecRelatedEntry.Next() = 0;
        // Reversing entries
        PaymentRecRelatedEntry.Reset();
        PaymentRecRelatedEntry.SetRange("Bank Account No.", BankAccountNo);
        PaymentRecRelatedEntry.SetRange("Statement No.", StatementNo);
        PaymentRecRelatedEntry.SetFilter("Entry Type", '<>%1', PaymentRecRelatedEntry."Entry Type"::"Bank Account");
        PaymentRecRelatedEntry.SetRange(Unapplied, true);
        PaymentRecRelatedEntry.SetRange(Reversed, false);
        PaymentRecRelatedEntry.SetRange(ToReverse, true);
        if PaymentRecRelatedEntry.FindSet() then
            repeat
                PaymentRecRelatedEntry.Reversed := true;
                ReverseEntry(PaymentRecRelatedEntry, false);
                PaymentRecRelatedEntry.Modify();
            until PaymentRecRelatedEntry.Next() = 0;
    end;

    local procedure InsertRelatedAndAppliedEntries(BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankAccountStatementLine: Record "Bank Account Statement Line";
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
    begin
        BankAccountStatementLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccountStatementLine.SetRange("Statement No.", StatementNo);
        if not BankAccountStatementLine.FindSet() then
            exit;
        repeat
            if PostedPaymentReconLine.Get(BankAccountNo, StatementNo, BankAccountStatementLine."Statement Line No.") then
                InsertRelatedAndAppliedEntries(BankAccountNo, StatementNo, BankAccountStatementLine."Statement Line No.", PostedPaymentReconLine."Account Type");
        until BankAccountStatementLine.Next() = 0;
    end;

    local procedure InsertRelatedAndAppliedEntriesOfGLRegister(var GLRegister: Record "G/L Register"; var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        StatementLineNo: Integer;
    begin
        BankAccountLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        if BankAccountLedgerEntry.FindSet() then
            repeat
                InsertBankPaymentRecRelatedEntry(BankAccountLedgerEntry, PostedPaymentReconHdr."Statement No.", -1);
            until BankAccountLedgerEntry.Next() = 0;

        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        if CustLedgerEntry.FindSet() then
            repeat
                StatementLineNo += 10000;
                InsertRelatedAndAppliedEntries(PostedPaymentReconHdr."Bank Account No.", PostedPaymentReconHdr."Statement No.", StatementLineNo, CustLedgerEntry);
            until CustLedgerEntry.Next() = 0;

        VendorLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        if VendorLedgerEntry.FindSet() then
            repeat
                StatementLineNo += 10000;
                InsertRelatedAndAppliedEntries(PostedPaymentReconHdr."Bank Account No.", PostedPaymentReconHdr."Statement No.", StatementLineNo, VendorLedgerEntry);
            until VendorLedgerEntry.Next() = 0;

        EmployeeLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        if EmployeeLedgerEntry.FindSet() then
            repeat
                StatementLineNo += 10000;
                InsertRelatedAndAppliedEntries(PostedPaymentReconHdr."Bank Account No.", PostedPaymentReconHdr."Statement No.", StatementLineNo, EmployeeLedgerEntry);
            until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure RefreshRelatedEntryReversalStatus(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry")
    begin
        RefreshRelatedEntryReversalStatus(PaymentRecRelatedEntry, false);
    end;

    local procedure RefreshRelatedEntryReversalStatus(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry"; SetDefaultValues: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        case PaymentRecRelatedEntry."Entry Type" of
            PaymentRecRelatedEntry."Entry Type"::Customer:
                begin
                    CustLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.");
                    PaymentRecRelatedEntry.Reversed := CustLedgerEntry.Reversed;
                    if PaymentRecRelatedEntry.Reversed then
                        PaymentRecRelatedEntry.Unapplied := true
                    else
                        PaymentRecRelatedEntry.Unapplied := CustEntryApplyPostedEntries.FindLastApplEntry(CustLedgerEntry."Entry No.") = 0;
                end;
            PaymentRecRelatedEntry."Entry Type"::Vendor:
                begin
                    VendorLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.");
                    PaymentRecRelatedEntry.Reversed := VendorLedgerEntry.Reversed;
                    if PaymentRecRelatedEntry.Reversed then
                        PaymentRecRelatedEntry.Unapplied := true
                    else
                        PaymentRecRelatedEntry.Unapplied := VendEntryApplyPostedEntries.FindLastApplEntry(VendorLedgerEntry."Entry No.") = 0;
                end;
            PaymentRecRelatedEntry."Entry Type"::Employee:
                begin
                    EmployeeLedgerEntry.Get(PaymentRecRelatedEntry."Entry No.");
                    PaymentRecRelatedEntry.Reversed := EmployeeLedgerEntry.Reversed;
                    if PaymentRecRelatedEntry.Reversed then
                        PaymentRecRelatedEntry.Unapplied := true
                    else
                        PaymentRecRelatedEntry.Unapplied := EmplEntryApplyPostedEntries.FindLastApplEntry(EmployeeLedgerEntry."Entry No.") = 0;
                end;
        end;
        if PaymentRecRelatedEntry.Unapplied then
            PaymentRecRelatedEntry.ToUnapply := false;
        if PaymentRecRelatedEntry.Reversed then
            PaymentRecRelatedEntry.ToReverse := false;
        if SetDefaultValues then begin
            PaymentRecRelatedEntry.ToUnapply := not PaymentRecRelatedEntry.Unapplied;
            PaymentRecRelatedEntry.ToReverse := not PaymentRecRelatedEntry.Reversed;
        end;
    end;

    local procedure RefreshRelatedEntriesReversalStatus(BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        RefreshRelatedEntriesReversalStatus(BankAccountNo, StatementNo, false)
    end;

    local procedure RefreshRelatedEntriesReversalStatus(BankAccountNo: Code[20]; StatementNo: Code[20]; SetDefaultValues: Boolean)
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
    begin
        PaymentRecRelatedEntry.SetRange("Bank Account No.", BankAccountNo);
        PaymentRecRelatedEntry.SetRange("Statement No.", StatementNo);
        if not PaymentRecRelatedEntry.FindSet() then
            exit;
        repeat
            RefreshRelatedEntryReversalStatus(PaymentRecRelatedEntry, SetDefaultValues);
            PaymentRecRelatedEntry.Modify();
        until PaymentRecRelatedEntry.Next() = 0;
    end;

    procedure ErrorIfEntryIsNotReversable(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        ErrorIfEntryIsNotReversable(CustLedgerEntry.Reversed, CustLedgerEntry.TableCaption, CustLedgerEntry."Entry No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Journal Batch Name", CustLedgerEntry."Document Type", CustLedgerEntry."Amount to Apply", CustLedgerEntry."Applies-to Doc. No.", CustLedgerEntry."Applies-to ID", CustLedgerEntry."Source Code");
    end;

    procedure ErrorIfEntryIsNotReversable(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        ErrorIfEntryIsNotReversable(VendorLedgerEntry.Reversed, VendorLedgerEntry.TableCaption, VendorLedgerEntry."Entry No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Journal Batch Name", VendorLedgerEntry."Document Type", VendorLedgerEntry."Amount to Apply", VendorLedgerEntry."Applies-to Doc. No.", VendorLedgerEntry."Applies-to ID", VendorLedgerEntry."Source Code");
    end;

    procedure ErrorIfEntryIsNotReversable(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        ErrorIfEntryIsNotReversable(EmployeeLedgerEntry.Reversed, EmployeeLedgerEntry.TableCaption, EmployeeLedgerEntry."Entry No.", EmployeeLedgerEntry."Transaction No.", EmployeeLedgerEntry."Journal Batch Name", EmployeeLedgerEntry."Document Type", EmployeeLedgerEntry."Amount to Apply", EmployeeLedgerEntry."Applies-to Doc. No.", EmployeeLedgerEntry."Applies-to ID", EmployeeLedgerEntry."Source Code");
    end;

    local procedure InsertRelatedAndAppliedEntries(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementLineNo: Integer; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
        PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry";
        DetailedEmployeeLedgerEntry1: Record "Detailed Employee Ledger Entry";
        DetailedEmployeeLedgerEntry2: Record "Detailed Employee Ledger Entry";
    begin
        // Insert the CustomerLedgerEntry to the related entries
        PaymentRecRelatedEntry."Entry No." := EmployeeLedgerEntry."Entry No.";
        PaymentRecRelatedEntry."Entry Type" := PaymentRecRelatedEntry."Entry Type"::Employee;
        PaymentRecRelatedEntry."Bank Account No." := BankAccountNo;
        PaymentRecRelatedEntry."Statement No." := StatementNo;
        PaymentRecRelatedEntry."Statement Line No." := StatementLineNo;
        PaymentRecRelatedEntry.Insert();
        // Find entries that this entry was applied to. Insert this entries into PmtRecAppliedToEntry
        // we follow the same approach as AppliedVendorEntries.Page.al
        DetailedEmployeeLedgerEntry1.SetCurrentKey("Employee Ledger Entry No.");
        DetailedEmployeeLedgerEntry1.SetRange("Employee Ledger Entry No.", EmployeeLedgerEntry."Entry No.");
        DetailedEmployeeLedgerEntry1.SetRange(Unapplied, false);
        if not DetailedEmployeeLedgerEntry1.FindSet() then
            exit;
        repeat
            DetailedEmployeeLedgerEntry2.Reset();
            DetailedEmployeeLedgerEntry2.SetCurrentKey("Applied Empl. Ledger Entry No.");
            DetailedEmployeeLedgerEntry2.SetRange("Applied Empl. Ledger Entry No.", DetailedEmployeeLedgerEntry1."Applied Empl. Ledger Entry No.");
            DetailedEmployeeLedgerEntry2.SetRange("Entry Type", DetailedEmployeeLedgerEntry2."Entry Type"::Application);
            DetailedEmployeeLedgerEntry2.SetRange(Unapplied, false);
            if DetailedEmployeeLedgerEntry2.FindSet() then
                repeat
                    if DetailedEmployeeLedgerEntry2."Employee Ledger Entry No." <> DetailedEmployeeLedgerEntry2."Applied Empl. Ledger Entry No." then begin
                        PmtRecAppliedToEntry.Init();
                        PmtRecAppliedToEntry."Entry No." := DetailedEmployeeLedgerEntry2."Employee Ledger Entry No.";
                        PmtRecAppliedToEntry.Amount := DetailedEmployeeLedgerEntry2.Amount;
                        PmtRecAppliedToEntry."Entry Type" := PmtRecAppliedToEntry."Entry Type"::Employee;
                        PmtRecAppliedToEntry."Bank Account No." := BankAccountNo;
                        PmtRecAppliedToEntry."Statement No." := StatementNo;
                        PmtRecAppliedToEntry."Statement Line No." := StatementLineNo;
                        PmtRecAppliedToEntry."Applied by Entry No." := EmployeeLedgerEntry."Entry No.";
                        PmtRecAppliedToEntry.Insert();
                    end;
                until DetailedEmployeeLedgerEntry2.Next() = 0;
        until DetailedEmployeeLedgerEntry1.Next() = 0;
    end;

    local procedure InsertRelatedAndAppliedEntries(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementLineNo: Integer; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
        PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry";
        DetailedVendorLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        // Insert the CustomerLedgerEntry to the related entries
        PaymentRecRelatedEntry."Entry No." := VendorLedgerEntry."Entry No.";
        PaymentRecRelatedEntry."Entry Type" := PaymentRecRelatedEntry."Entry Type"::Vendor;
        PaymentRecRelatedEntry."Bank Account No." := BankAccountNo;
        PaymentRecRelatedEntry."Statement No." := StatementNo;
        PaymentRecRelatedEntry."Statement Line No." := StatementLineNo;
        PaymentRecRelatedEntry.Insert();
        // Find entries that this entry was applied to. Insert this entries into PmtRecAppliedToEntry
        // we follow the same approach as AppliedVendorEntries.Page.al
        DetailedVendorLedgEntry1.SetCurrentKey("Vendor Ledger Entry No.");
        DetailedVendorLedgEntry1.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry1.SetRange(Unapplied, false);
        if not DetailedVendorLedgEntry1.FindSet() then
            exit;
        repeat
            DetailedVendorLedgEntry2.Reset();
            DetailedVendorLedgEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.");
            DetailedVendorLedgEntry2.SetRange("Applied Vend. Ledger Entry No.", DetailedVendorLedgEntry1."Applied Vend. Ledger Entry No.");
            DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::Application);
            DetailedVendorLedgEntry2.SetRange(Unapplied, false);
            if DetailedVendorLedgEntry2.FindSet() then
                repeat
                    if DetailedVendorLedgEntry2."Vendor Ledger Entry No." <> DetailedVendorLedgEntry2."Applied Vend. Ledger Entry No." then begin
                        PmtRecAppliedToEntry.Init();
                        PmtRecAppliedToEntry."Entry No." := DetailedVendorLedgEntry2."Vendor Ledger Entry No.";
                        PmtRecAppliedToEntry.Amount := DetailedVendorLedgEntry2.Amount;
                        PmtRecAppliedToEntry."Entry Type" := PmtRecAppliedToEntry."Entry Type"::Vendor;
                        PmtRecAppliedToEntry."Bank Account No." := BankAccountNo;
                        PmtRecAppliedToEntry."Statement No." := StatementNo;
                        PmtRecAppliedToEntry."Statement Line No." := StatementLineNo;
                        PmtRecAppliedToEntry."Applied by Entry No." := VendorLedgerEntry."Entry No.";
                        PmtRecAppliedToEntry.Insert();
                    end;
                until DetailedVendorLedgEntry2.Next() = 0;
        until DetailedVendorLedgEntry1.Next() = 0;
    end;

    local procedure InsertRelatedAndAppliedEntries(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementLineNo: Integer; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
        PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry";
        DetailedCustLedgEntry1: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        // Insert the CustomerLedgerEntry to the related entries
        PaymentRecRelatedEntry."Entry No." := CustLedgerEntry."Entry No.";
        PaymentRecRelatedEntry."Entry Type" := PaymentRecRelatedEntry."Entry Type"::Customer;
        PaymentRecRelatedEntry."Bank Account No." := BankAccountNo;
        PaymentRecRelatedEntry."Statement No." := StatementNo;
        PaymentRecRelatedEntry."Statement Line No." := StatementLineNo;
        PaymentRecRelatedEntry.Insert();
        // Find entries that this entry was applied to. Insert this entries into PmtRecAppliedToEntry
        // we follow the same approach as AppliedCustomerEntries.Page.al
        DetailedCustLedgEntry1.SetCurrentKey("Cust. Ledger Entry No.");
        DetailedCustLedgEntry1.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry1.SetRange(Unapplied, false);
        if not DetailedCustLedgEntry1.FindSet() then
            exit;
        repeat
            DetailedCustLedgEntry2.Reset();
            DetailedCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.");
            DetailedCustLedgEntry2.SetRange("Applied Cust. Ledger Entry No.", DetailedCustLedgEntry1."Applied Cust. Ledger Entry No.");
            DetailedCustLedgEntry2.SetRange("Entry Type", DetailedCustLedgEntry2."Entry Type"::Application);
            DetailedCustLedgEntry2.SetRange(Unapplied, false);
            if DetailedCustLedgEntry2.FindSet() then
                repeat
                    if DetailedCustLedgEntry2."Cust. Ledger Entry No." <> DetailedCustLedgEntry2."Applied Cust. Ledger Entry No." then begin
                        PmtRecAppliedToEntry.Init();
                        PmtRecAppliedToEntry."Entry No." := DetailedCustLedgEntry2."Cust. Ledger Entry No.";
                        PmtRecAppliedToEntry.Amount := DetailedCustLedgEntry2.Amount;
                        PmtRecAppliedToEntry."Entry Type" := PmtRecAppliedToEntry."Entry Type"::Customer;
                        PmtRecAppliedToEntry."Bank Account No." := BankAccountNo;
                        PmtRecAppliedToEntry."Statement No." := StatementNo;
                        PmtRecAppliedToEntry."Statement Line No." := StatementLineNo;
                        PmtRecAppliedToEntry."Applied by Entry No." := CustLedgerEntry."Entry No.";
                        PmtRecAppliedToEntry.Insert();
                    end;
                until DetailedCustLedgEntry2.Next() = 0;
        until DetailedCustLedgEntry1.Next() = 0;
    end;

    local procedure InsertBankPaymentRecRelatedEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementNo: Code[20]; StatementLineNo: Integer)
    var
        PaymentRecRelatedEntry: Record "Payment Rec. Related Entry";
    begin
        PaymentRecRelatedEntry."Entry No." := BankAccountLedgerEntry."Entry No.";
        PaymentRecRelatedEntry."Entry Type" := PaymentRecRelatedEntry."Entry Type"::"Bank Account";
        PaymentRecRelatedEntry."Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
        PaymentRecRelatedEntry."Statement No." := StatementNo;
        PaymentRecRelatedEntry."Statement Line No." := StatementLineNo;
        PaymentRecRelatedEntry.Insert();
    end;

    local procedure InsertRelatedAndAppliedEntries(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementLineNo: Integer; AccountType: Enum "Gen. Journal Account Type"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        InsertBankPaymentRecRelatedEntry(BankAccountLedgerEntry, StatementNo, StatementLineNo);
        // Find if there's any Customer, Vendor or Employee related entries for this Bank Account Ledger Entry
        case AccountType of
            AccountType::Customer:
                begin
                    CustLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
                    CustLedgerEntry.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
                    CustLedgerEntry.SetRange(Reversed, false);
                    CustLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                    CustLedgerEntry.SetRange("Customer No.", BankAccountLedgerEntry."Bal. Account No.");
                    if CustLedgerEntry.FindSet() then
                        repeat
                            InsertRelatedAndAppliedEntries(BankAccountNo, StatementNo, StatementLineNo, CustLedgerEntry);
                        until CustLedgerEntry.Next() = 0;
                end;
            AccountType::Vendor:
                begin
                    VendorLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
                    VendorLedgerEntry.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
                    VendorLedgerEntry.SetRange(Reversed, false);
                    VendorLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                    VendorLedgerEntry.SetRange("Vendor No.", BankAccountLedgerEntry."Bal. Account No.");
                    if VendorLedgerEntry.FindSet() then
                        repeat
                            InsertRelatedAndAppliedEntries(BankAccountNo, StatementNo, StatementLineNo, VendorLedgerEntry);
                        until VendorLedgerEntry.Next() = 0;
                end;
            AccountType::Employee:
                begin
                    EmployeeLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
                    EmployeeLedgerEntry.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
                    EmployeeLedgerEntry.SetRange(Reversed, false);
                    EmployeeLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
                    EmployeeLedgerEntry.SetRange("Employee No.", BankAccountLedgerEntry."Bal. Account No.");
                    if EmployeeLedgerEntry.FindSet() then
                        repeat
                            InsertRelatedAndAppliedEntries(BankAccountNo, StatementNo, StatementLineNo, EmployeeLedgerEntry);
                        until EmployeeLedgerEntry.Next() = 0;
                end;
        end;
    end;

    local procedure InsertRelatedAndAppliedEntries(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementLineNo: Integer; AccountType: Enum "Gen. Journal Account Type")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement No.", StatementNo);
        BankAccountLedgerEntry.SetRange("Statement Line No.", StatementLineNo);
        if not BankAccountLedgerEntry.FindSet() then
            exit;
        repeat
            InsertRelatedAndAppliedEntries(BankAccountNo, StatementNo, StatementLineNo, AccountType, BankAccountLedgerEntry);
        until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure CreateApplicationEntryForBankAccReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var PmtRecAppliedToEntry: Record "Pmt. Rec. Applied-to Entry")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        BankAccount: Record "Bank Account";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
    begin
        // To apply the newly created entry Bank Acc. Reconciliation Line to the one it was previously applied, 
        // we create a temporary "Payment Application Proposal" to trigger it's "Applied" OnValidate
        // which will trigger all the required side-effects.
        TempPaymentApplicationProposal.Init();
        TempPaymentApplicationProposal."Bank Account No." := BankAccReconciliationLine."Bank Account No.";
        TempPaymentApplicationProposal."Statement No." := BankAccReconciliationLine."Statement No.";
        TempPaymentApplicationProposal."Statement Line No." := BankAccReconciliationLine."Statement Line No.";
        TempPaymentApplicationProposal."Statement Type" := BankAccReconciliationLine."Statement Type";
        TempPaymentApplicationProposal."Account Type" := BankAccReconciliationLine."Account Type";
        TempPaymentApplicationProposal."Account No." := BankAccReconciliationLine."Account No.";
        TempPaymentApplicationProposal."Applies-to Entry No." := PmtRecAppliedToEntry."Entry No.";
        TempPaymentApplicationProposal."Applied Amount" := PmtRecAppliedToEntry.Amount;
        if not BankAccount.Get(BankAccReconciliationLine."Bank Account No.") then;
        case PmtRecAppliedToEntry."Entry Type" of
            PmtRecAppliedToEntry."Entry Type"::Customer:
                begin
                    if not CustLedgerEntry.Get(PmtRecAppliedToEntry."Entry No.") then;
                    TempPaymentApplicationProposal.Description := CustLedgerEntry.Description;
                    TempPaymentApplicationProposal."Posting Date" := CustLedgerEntry."Posting Date";
                    TempPaymentApplicationProposal."Due Date" := CustLedgerEntry."Due Date";
                    TempPaymentApplicationProposal."Document Type" := CustLedgerEntry."Document Type";
                    TempPaymentApplicationProposal."Document No." := CustLedgerEntry."Document No.";
                    TempPaymentApplicationProposal."External Document No." := CustLedgerEntry."External Document No.";
                    TempPaymentApplicationProposal."Currency Code" := CustLedgerEntry."Currency Code"
                end;
            PmtRecAppliedToEntry."Entry Type"::Vendor:
                begin
                    if not VendorLedgerEntry.Get(PmtRecAppliedToEntry."Entry No.") then;
                    TempPaymentApplicationProposal.Description := VendorLedgerEntry.Description;
                    TempPaymentApplicationProposal."Posting Date" := VendorLedgerEntry."Posting Date";
                    TempPaymentApplicationProposal."Due Date" := VendorLedgerEntry."Due Date";
                    TempPaymentApplicationProposal."Document Type" := VendorLedgerEntry."Document Type";
                    TempPaymentApplicationProposal."Document No." := VendorLedgerEntry."Document No.";
                    TempPaymentApplicationProposal."External Document No." := VendorLedgerEntry."External Document No.";
                    TempPaymentApplicationProposal."Currency Code" := VendorLedgerEntry."Currency Code"
                end;
            PmtRecAppliedToEntry."Entry Type"::Employee:
                begin
                    if not EmployeeLedgerEntry.Get(PmtRecAppliedToEntry."Entry No.") then;
                    TempPaymentApplicationProposal.Description := EmployeeLedgerEntry.Description;
                    TempPaymentApplicationProposal."Posting Date" := EmployeeLedgerEntry."Posting Date";
                    TempPaymentApplicationProposal."Document Type" := EmployeeLedgerEntry."Document Type";
                    TempPaymentApplicationProposal."Document No." := EmployeeLedgerEntry."Document No.";
                    TempPaymentApplicationProposal."Currency Code" := EmployeeLedgerEntry."Currency Code"
                end;
        end;
        TempPaymentApplicationProposal.Quality := 100;
        TempPaymentApplicationProposal."Match Confidence" := TempPaymentApplicationProposal."Match Confidence"::High;
        TempPaymentApplicationProposal.UpdateDefaultCalculatedFields(BankAccount, TempPaymentApplicationProposal."Applies-to Entry No.");
        TempPaymentApplicationProposal.Insert();
        TempPaymentApplicationProposal.Validate(Applied, true);
    end;

    local procedure UnapplyCustomerEntry(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry"; ShowEntriesToPost: Boolean)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        if ShowEntriesToPost then begin
            CustEntryApplyPostedEntries.UnApplyCustLedgEntry(PaymentRecRelatedEntry."Entry No.");
            RefreshRelatedEntryReversalStatus(PaymentRecRelatedEntry);
            exit;
        end;
        CustEntryApplyPostedEntries.CheckCustLedgEntryToUnapply(PaymentRecRelatedEntry."Entry No.", DetailedCustLedgEntry);
        ApplyUnapplyParameters.Init();
        ApplyUnapplyParameters."Document No." := DetailedCustLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DetailedCustLedgEntry."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetailedCustLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure UnapplyVendorEntry(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry"; ShowEntriesToPost: Boolean)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        if ShowEntriesToPost then begin
            VendEntryApplyPostedEntries.UnApplyVendLedgEntry(PaymentRecRelatedEntry."Entry No.");
            RefreshRelatedEntryReversalStatus(PaymentRecRelatedEntry);
            exit;
        end;
        VendEntryApplyPostedEntries.CheckVendorLedgerEntryToUnapply(PaymentRecRelatedEntry."Entry No.", DetailedVendorLedgEntry);
        ApplyUnapplyParameters.Init();
        ApplyUnapplyParameters."Document No." := DetailedVendorLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DetailedVendorLedgEntry."Posting Date";
        VendEntryApplyPostedEntries.PostUnApplyVendor(DetailedVendorLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure UnapplyEmployeeEntry(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry"; ShowEntriesToPost: Boolean)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        if ShowEntriesToPost then begin
            EmplEntryApplyPostedEntries.UnApplyEmplLedgEntry(PaymentRecRelatedEntry."Entry No.");
            RefreshRelatedEntryReversalStatus(PaymentRecRelatedEntry);
            exit;
        end;
        EmplEntryApplyPostedEntries.CheckEmployeeLedgerEntryToUnapply(PaymentRecRelatedEntry."Entry No.", DetailedEmployeeLedgerEntry);
        ApplyUnapplyParameters.Init();
        ApplyUnapplyParameters."Document No." := DetailedEmployeeLedgerEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DetailedEmployeeLedgerEntry."Posting Date";
        EmplEntryApplyPostedEntries.PostUnApplyEmployee(DetailedEmployeeLedgerEntry, ApplyUnapplyParameters);
    end;

    local procedure EntryIsReversable(JournalBatchName: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; AmountToApply: Decimal; AppliesToDocNo: Code[20]; AppliesToID: Code[50]; SourceCode: Code[10]): Boolean
    var
        SourceCodeSetup: Record "Source Code Setup";
        Result: Boolean;
        IsHandled: Boolean;
    begin

        IsHandled := false;
        OnBeforeEntryIsReversable(JournalBatchName, DocumentType, AmountToApply, AppliesToDocNo, AppliesToID, SourceCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SourceCodeSetup.Get() then;
        // We allow reversing entries created from normal journals, e.g.: Payment Journal, Cash Receipt, ...
        // These entries have by default a "Journal Batch Name" associated.
        // This can be used to determine whether the entry is reversible. 
        exit(
            (JournalBatchName <> '') or (
                // However, we also want to allow reversal
                // of entries created by posting Payment Reconciliation Journals, which don't
                // necesarily have a "Journal Batch Name" .
                // Entries created from Paym. Rec. Journals, are created by GenJnlPostLine.Codeunit,
                // and set the following values for those:
                (DocumentType in [DocumentType::" ", DocumentType::Payment, DocumentType::Refund]) and
                (AmountToApply = 0) and
                (AppliesToDocNo = '') and
                (AppliesToID = '') and
                // As an extra condition, we also look at the SourceCode value
                (SourceCode = SourceCodeSetup."Payment Reconciliation Journal")
            )
        );
    end;

    procedure ErrorIfEntryIsNotReversable(Reversed: Boolean; TableCaption: Text; EntryNo: Integer; TransactionNo: Integer; JournalBatchName: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; AmountToApply: Decimal; AppliesToDocNo: Code[20]; AppliesToID: Code[50]; SourceCode: Code[10])
    var
        ReversalEntry: Record "Reversal Entry";
        IsHandled: Boolean;
    begin
        if Reversed then
            ReversalEntry.AlreadyReversedEntry(TableCaption, EntryNo);
        IsHandled := false;
        OnErrorIfEntryIsNotReversableOnBeforeEntryIsReversable(IsHandled);
        if not IsHandled then
            if not EntryIsReversable(JournalBatchName, DocumentType, AmountToApply, AppliesToDocNo, AppliesToID, SourceCode) then
                ReversalEntry.TestFieldError();
        if TransactionNo = 0 then
            Error(EmptyTransactionNoErr, EntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseEntry()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReverseEntry(var PaymentRecRelatedEntry: Record "Payment Rec. Related Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorIfEntryIsNotReversableOnBeforeEntryIsReversable(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPaymentRecJournalFromPostedPaymentReconLinesOnAfterInsertBankAccReconciliationLine(var PostedPaymentReconLine: Record "Posted Payment Recon. Line"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCopyPaymentRecJournal(var PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr"; var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEntryIsReversable(JournalBatchName: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; AmountToApply: Decimal; AppliesToDocNo: Code[20]; AppliesToID: Code[50]; SourceCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
