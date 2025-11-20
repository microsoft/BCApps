// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;

codeunit 1253 "Change Bank Rec. Statement No."
{
    Permissions = TableData "Bank Acc. Reconciliation" = rimd,
                  TableData "Bank Acc. Reconciliation Line" = rimd,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm;
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        NewStatementNo: Code[20];
    begin
        BankAccReconciliation := Rec;

        if GetNewStatementNo(BankAccReconciliation, NewStatementNo) then begin
            ChangeStatementNo(BankAccReconciliation, NewStatementNo);
            Rec := BankAccReconciliation;
        end;
    end;

    local procedure GetNewStatementNo(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var NewStatementNo: Code[20]): Boolean
    var
        ChangeBankRecStatementNo: Page "Change Bank Rec. Statement No.";
    begin
        ChangeBankRecStatementNo.SetBankAccReconciliation(BankAccReconciliation);
        if ChangeBankRecStatementNo.RunModal() = Action::OK then begin
            NewStatementNo := ChangeBankRecStatementNo.GetNewStatementNo();
            exit(NewStatementNo <> BankAccReconciliation."Statement No.");
        end;
        exit(false);
    end;

    local procedure ChangeStatementNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; NewStatementNo: Code[20])
    var
        TempBankAccReconciliation: Record "Bank Acc. Reconciliation" temporary;
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer" temporary;
    begin
        TempBankAccReconciliation.OnInsertValidations(BankAccReconciliation."Statement Type", BankAccReconciliation."Bank Account No.", NewStatementNo);
        UpdateAppliedBankLedgerEntries(BankAccReconciliation, NewStatementNo);
        UpdateAppliedCheckLedgerEntries(BankAccReconciliation, NewStatementNo);

        MoveBankAccReconiliationToBuffers(BankAccReconciliation, TempBankAccReconciliation, TempBankAccReconciliationLine, TempBankAccRecMatchBuffer);

        CreateBankAccReconciliationWithNewStatementNo(
            BankAccReconciliation, TempBankAccReconciliation, TempBankAccReconciliationLine, TempBankAccRecMatchBuffer, NewStatementNo);
    end;

    local procedure MoveBankAccReconiliationToBuffers(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankAccReconciliation: Record "Bank Acc. Reconciliation" temporary; var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; var TempBankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer" temporary)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
    begin
        TempBankAccReconciliation.TransferFields(BankAccReconciliation);
        TempBankAccReconciliation.Insert();
        BankAccReconciliation.Delete();

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccReconciliationLine.FindSet() then
            repeat
                TempBankAccReconciliationLine.TransferFields(BankAccReconciliationLine);
                TempBankAccReconciliationLine.Insert();
            until BankAccReconciliationLine.Next() = 0;
        BankAccReconciliationLine.DeleteAll();

        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccRecMatchBuffer.FindSet() then
            repeat
                TempBankAccRecMatchBuffer.TransferFields(BankAccRecMatchBuffer);
                TempBankAccRecMatchBuffer.Insert();
            until BankAccRecMatchBuffer.Next() = 0;
        BankAccRecMatchBuffer.DeleteAll();
    end;

    local procedure CreateBankAccReconciliationWithNewStatementNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankAccReconciliation: Record "Bank Acc. Reconciliation" temporary; var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; var TempBankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer" temporary; NewStatementNo: Code[20])
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
    begin
        BankAccReconciliation.TransferFields(TempBankAccReconciliation);
        BankAccReconciliation."Statement No." := NewStatementNo;
        BankAccReconciliation.Insert();

        if TempBankAccReconciliationLine.FindSet() then
            repeat
                BankAccReconciliationLine.TransferFields(TempBankAccReconciliationLine);
                BankAccReconciliationLine."Statement No." := NewStatementNo;
                OnCreateBankAccReconciliationWithNewStatementNoOnBeforeInsertBankAccReconciliationLine(BankAccReconciliationLine, BankAccReconciliation, TempBankAccReconciliation, TempBankAccReconciliationLine, TempBankAccRecMatchBuffer, NewStatementNo);
                BankAccReconciliationLine.Insert();
            until TempBankAccReconciliationLine.Next() = 0;

        if TempBankAccRecMatchBuffer.FindSet() then
            repeat
                BankAccRecMatchBuffer.TransferFields(TempBankAccRecMatchBuffer);
                BankAccRecMatchBuffer."Statement No." := NewStatementNo;
                BankAccRecMatchBuffer.Insert();
            until TempBankAccRecMatchBuffer.Next() = 0;
    end;

    local procedure UpdateAppliedBankLedgerEntries(BankAccReconciliation: Record "Bank Acc. Reconciliation"; NewStatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetFilter("Statement Status", '%1|%2', BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status"::"Check Entry Applied");
        if not BankAccountLedgerEntry.IsEmpty() then
            BankAccountLedgerEntry.ModifyAll("Statement No.", NewStatementNo);
    end;

    local procedure UpdateAppliedCheckLedgerEntries(BankAccReconciliation: Record "Bank Acc. Reconciliation"; NewStatementNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        CheckLedgerEntry.SetFilter("Statement Status", '%1|%2', CheckLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", CheckLedgerEntry."Statement Status"::"Check Entry Applied");
        if not CheckLedgerEntry.IsEmpty() then
            CheckLedgerEntry.ModifyAll("Statement No.", NewStatementNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateBankAccReconciliationWithNewStatementNoOnBeforeInsertBankAccReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankAccReconciliation: Record "Bank Acc. Reconciliation" temporary; var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; var TempBankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer" temporary; NewStatementNo: Code[20]);
    begin
    end;
}
