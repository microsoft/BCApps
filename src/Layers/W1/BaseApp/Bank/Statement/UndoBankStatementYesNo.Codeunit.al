// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;

codeunit 1340 "Undo Bank Statement (Yes/No)"
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm,
                  TableData "Bank Acc. Reconciliation" = ri,
                  TableData "Bank Acc. Reconciliation Line" = ri,
                  TableData "Bank Account Statement" = rd,
                  TableData "Bank Account Statement Line" = rd;
    TableNo = "Bank Account Statement";

    trigger OnRun()
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.Copy(Rec);
        Code(BankAccountStatement);
        Rec := BankAccountStatement;
    end;

    var
        UndoBankStatementQst: Label 'Do you want to reverse this bank statement and automatically create a new bank reconciliation with the same information?';

    local procedure Code(var BankAccountStatement: Record "Bank Account Statement")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        StatementNo: Code[20];
    begin
        if not Confirm(UndoBankStatementQst) then
            exit;

        StatementNo := UndoBankAccountStatement(BankAccountStatement);

        BankAccReconciliation.Get(
            BankAccReconciliation."Statement Type"::"Bank Reconciliation",
            BankAccountStatement."Bank Account No.",
            StatementNo);
        Page.Run(Page::"Bank Acc. Reconciliation", BankAccReconciliation);
    end;

    procedure UndoBankAccountStatement(BankAccountStatement: Record "Bank Account Statement"): Code[20]
    begin
        exit(UndoBankAccountStatement(BankAccountStatement, true));
    end;

    procedure UndoBankAccountStatement(BankAccountStatement: Record "Bank Account Statement"; CreateBankRec: Boolean): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatementLine: Record "Bank Account Statement Line";
    begin
        BankAccount.Get(BankAccountStatement."Bank Account No.");
        BankAccount."Balance Last Statement" := BankAccountStatement."Balance Last Statement";
        OnUndoBankAccountStatementOnBeforeBankAccountModify(BankAccount);
        BankAccount.Modify();

        if CreateBankRec then begin
            BankAccReconciliation.Init();
            BankAccReconciliation.TransferFields(BankAccountStatement);
            BankAccReconciliation."Statement No." := '';
            BankAccReconciliation.Validate("Bank Account No.");
            BankAccReconciliation.Validate("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
            OnUndoBankAccountStatementOnBeforeBankAccReconciliationInsert(BankAccReconciliation);
            BankAccReconciliation.Insert(true);
        end;

        BankAccountStatementLine.SetRange("Bank Account No.", BankAccountStatement."Bank Account No.");
        BankAccountStatementLine.SetRange("Statement No.", BankAccountStatement."Statement No.");
        if BankAccountStatementLine.FindSet() then
            repeat
                if CreateBankRec then begin
                    BankAccReconciliationLine.Init();
                    BankAccReconciliationLine.TransferFields(BankAccountStatementLine);
                    BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
                    BankAccReconciliationLine.Validate("Statement Type", BankAccReconciliationLine."Statement Type"::"Bank Reconciliation");
                    OnUndoBankAccountStatementOnBeforeBankAccReconciliationLineInsert(BankAccReconciliationLine);
                    BankAccReconciliationLine.Insert();
                    OnUndoBankAccountStatementOnAfterBankAccReconciliationLineInsert(BankAccountStatementLine, BankAccReconciliationLine);
                end;

                UndoBankAccountLedgerEntries(BankAccountStatementLine, BankAccReconciliation."Statement No.", CreateBankRec);
            until BankAccountStatementLine.Next() = 0;

        BankAccountStatementLine.DeleteAll();
        BankAccountStatement.Delete();

        exit(BankAccReconciliation."Statement No.");
    end;

    local procedure UndoBankAccountLedgerEntries(BankAccountStatementLine: Record "Bank Account Statement Line"; NewStatementNo: Code[20]; CreateBankRec: Boolean)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // When posting a bank reconciliation, the related BLEs have the 
        // match stored in their Statement No., Statement Line No.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountStatementLine."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccountStatementLine."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", BankAccountStatementLine."Statement Line No.");
        if BankAccountLedgerEntry.FindFirst() then
            repeat
                // This removes and sets the new status for these entries
                UndoBankAccountLedgerEntry(BankAccountLedgerEntry, BankAccountStatementLine, NewStatementNo, CreateBankRec);
            until BankAccountLedgerEntry.Next() = 0;
        // When posting a bank reconciliation with ManyToOne matches, the
        // BLEs have the right Statement No. but Statement Line No. set to -1
        // Therefore the above filters won't properly revert them.
        RestoreManyToOneMatchesForNewBankReconciliation(BankAccountStatementLine, NewStatementNo, CreateBankRec);
    end;

    local procedure RestoreManyToOneMatchesForNewBankReconciliation(var BankAccountStatementLine: Record "Bank Account Statement Line"; NewStatementNo: Code[20]; CreateBankRec: Boolean)
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // When undoing a bank statement posted from the page "Bank Acc. Reconciliation"
        // the many to one matches are stored in "Bank Acc. Rec. Match Buffer" table,
        // and they are kept even after posted.
        // We update these buffer entries to point to the new Bank Reconciliation
        BankAccountStatementLine.FilterManyToOneMatches(BankAccRecMatchBuffer);
        if BankAccRecMatchBuffer.FindFirst() then begin
            BankAccountLedgerEntry.Reset();
            BankAccountLedgerEntry.SetRange("Entry No.", BankAccRecMatchBuffer."Ledger Entry No.");
            if BankAccountLedgerEntry.FindFirst() then
                UndoBankAccountLedgerEntry(BankAccountLedgerEntry, BankAccountStatementLine, NewStatementNo, CreateBankRec);

            if CreateBankRec then begin
                BankAccRecMatchBuffer.Rename(NewStatementNo,
                                            BankAccRecMatchBuffer."Statement Line No.",
                                            BankAccRecMatchBuffer."Bank Account No.",
                                            BankAccRecMatchBuffer."Match ID");
                BankAccRecMatchBuffer."Is Processed" := false;
                BankAccRecMatchBuffer.Modify();
            end;
        end;
    end;

    local procedure UndoBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankAccountStatementLine: Record "Bank Account Statement Line"; NewStatementNo: Code[20]; CreateBankRec: Boolean)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        if CheckLedgerEntry.FindSet(true) then begin
            repeat
                CheckLedgerEntry."Statement Status" := GetNewStatementStatus(BankAccountStatementLine);
                if CheckLedgerEntry."Statement Status" = CheckLedgerEntry."Statement Status"::"Check Entry Applied" then
                    CheckLedgerEntry."Statement No." := NewStatementNo
                else begin
                    CheckLedgerEntry."Statement No." := NewStatementNo;
                    CheckLedgerEntry."Statement Line No." := BankAccountStatementLine."Statement Line No.";
                end;
                if not CreateBankRec then begin
                    CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::Open;
                    CheckLedgerEntry."Statement No." := '';
                    CheckLedgerEntry."Statement Line No." := 0;
                end;
                CheckLedgerEntry.Open := true;
                OnUndoBankAccountLedgerEntryOnBeforeCheckLedgerEntryModify(CheckLedgerEntry);
                CheckLedgerEntry.Modify();
            until CheckLedgerEntry.Next() = 0;

            BankAccountLedgerEntry."Statement Status" := GetNewStatementStatus(BankAccountStatementLine);
            if BankAccountLedgerEntry."Statement Status" = BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied" then
                BankAccountLedgerEntry."Statement No." := NewStatementNo
            else begin
                BankAccountLedgerEntry."Statement No." := '';
                BankAccountLedgerEntry."Statement Line No." := 0;
            end;
        end else begin
            BankAccountLedgerEntry."Statement No." := NewStatementNo;
            BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied";
        end;
        if not CreateBankRec then begin
            BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::Open;
            BankAccountLedgerEntry."Statement No." := '';
            BankAccountLedgerEntry."Statement Line No." := 0;
        end;

        BankAccountLedgerEntry."Remaining Amount" := BankAccountLedgerEntry.Amount;
        BankAccountLedgerEntry.Open := true;
        OnUndoBankAccountLedgerEntryOnBeforeBankAccountLedgerEntryModify(BankAccountLedgerEntry);
        BankAccountLedgerEntry.Modify();
    end;

    local procedure GetNewStatementStatus(BankAccountStatementLine: Record "Bank Account Statement Line") StatementStatus: Option Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed
    begin
        case BankAccountStatementLine.Type of
            BankAccountStatementLine.Type::"Bank Account Ledger Entry":
                exit(StatementStatus::"Bank Acc. Entry Applied");
            BankAccountStatementLine.Type::"Check Ledger Entry":
                exit(StatementStatus::"Check Entry Applied");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoBankAccountStatementOnBeforeBankAccountModify(var BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoBankAccountStatementOnBeforeBankAccReconciliationInsert(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoBankAccountStatementOnBeforeBankAccReconciliationLineInsert(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoBankAccountLedgerEntryOnBeforeBankAccountLedgerEntryModify(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoBankAccountLedgerEntryOnBeforeCheckLedgerEntryModify(var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoBankAccountStatementOnAfterBankAccReconciliationLineInsert(var BankAccountStatementLine: Record "Bank Account Statement Line"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;
}
