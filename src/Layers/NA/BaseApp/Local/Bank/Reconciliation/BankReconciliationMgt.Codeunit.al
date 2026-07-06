// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Statement;

codeunit 10130 "Bank Reconciliation Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure New(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; ShareTable: Boolean)
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconciliationCard: Page "Bank Acc. Reconciliation";
    begin
        if not SelectBankAccountUsingFilter(BankAccount, BankAccReconciliation) then
            if not SelectBankAccount(BankAccount) then
                exit;

        if not BankAccount.CheckLastStatementNo() then
            exit;

        if not WarnIfOngoingBankReconciliations(BankAccount."No.") then
            exit;

        BankAccReconciliation2.InsertRec(BankAccReconciliation2."Statement Type"::"Bank Reconciliation".AsInteger(), BankAccount."No.");
        if ShareTable then
            BankAccReconciliationCard.SetSharedTempTable(BankAccReconciliation);
        BankAccReconciliationCard.SetRecord(BankAccReconciliation2);
        BankAccReconciliationCard.Run();
    end;

    procedure Edit(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; ShareTable: Boolean)
    var
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccReconciliationCard: Page "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        StatementType: Enum "Bank Acc. Rec. Stmt. Type";
    begin
        StatementType := BankAccReconciliation."Statement Type";
        BankAccountNo := BankAccReconciliation."Bank Account No.";
        StatementNo := BankAccReconciliation."Statement No.";

        if BankAccReconciliation2.Get(StatementType, BankAccountNo, StatementNo) then begin
            BankAccReconciliationCard.SetSharedTempTable(BankAccReconciliation);
            if ShareTable then
                BankAccReconciliationCard.SetRecord(BankAccReconciliation2);
            BankAccReconciliationCard.Run();
        end;

    end;

    procedure Delete(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        StatementType: Enum "Bank Acc. Rec. Stmt. Type";
    begin
        StatementType := BankAccReconciliation."Statement Type";
        BankAccountNo := BankAccReconciliation."Bank Account No.";
        StatementNo := BankAccReconciliation."Statement No.";

        if BankAccReconciliation2.Get(StatementType, BankAccountNo, StatementNo) then
            BankAccReconciliation2.Delete(true);

    end;

    procedure Refresh(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation2.GetTempCopy(BankAccReconciliation)
    end;

    procedure Post(BankAccReconciliation: Record "Bank Acc. Reconciliation"; AutoMatchCodeunitID: Integer; LocalCodeunitID: Integer)
    var
        BankAccReconciliation2: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        StatementType: Enum "Bank Acc. Rec. Stmt. Type";
    begin
        StatementType := BankAccReconciliation."Statement Type";
        BankAccountNo := BankAccReconciliation."Bank Account No.";
        StatementNo := BankAccReconciliation."Statement No.";

        if BankAccReconciliation2.Get(StatementType, BankAccountNo, StatementNo) then
            CODEUNIT.Run(AutoMatchCodeunitID, BankAccReconciliation2);

    end;

    local procedure SelectBankAccountUsingFilter(var BankAccount: Record "Bank Account"; var BankAccReconciliation: Record "Bank Acc. Reconciliation"): Boolean
    begin
        if BankAccReconciliation.GetFilter("Bank Account No.") <> '' then
            exit(BankAccount.Get(BankAccReconciliation.GetRangeMin("Bank Account No.")));
    end;

    local procedure SelectBankAccount(var BankAccount: Record "Bank Account"): Boolean
    var
        BankAccountList: Page "Bank Account List";
    begin
        BankAccountList.LookupMode := true;
        if BankAccountList.RunModal() <> ACTION::LookupOK then
            exit(false);

        BankAccountList.GetRecord(BankAccount);

        exit(true);
    end;

    local procedure WarnIfOngoingBankReconciliations(BankAccountNoCode: Code[20]): Boolean
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.SetRange("Bank Account No.", BankAccountNoCode);
        BankAccReconciliation.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        if BankAccReconciliation.IsEmpty() then
            exit(true);
        exit(Dialog.Confirm(StrSubstNo(IgnoreExistingBankAccReconciliationAndContinueQst)));
    end;

    internal procedure OpenBankStatementsPage(Notification: Notification)
    begin
        Page.Run(Page::"Bank Account Statement List");
    end;

    internal procedure OpenPostedBankDepositsPage(Notification: Notification)
    begin
        Page.Run(1696); // BankDeposits: PostedBankDepositList.Page.al
    end;

    var
        IgnoreExistingBankAccReconciliationAndContinueQst: Label 'There are ongoing reconciliations for this bank account. \\Do you want to continue?';
}
