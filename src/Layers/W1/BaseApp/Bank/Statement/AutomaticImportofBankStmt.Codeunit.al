// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Reconciliation;
using System.IO;
using System.Threading;

codeunit 1415 "Automatic Import of Bank Stmt."
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        BankAccount: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        DummyBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        RecRef: RecordRef;
        LastStatementNo: Code[20];
    begin
        Rec.TestField("Record ID to Process");
        RecRef.Get(Rec."Record ID to Process");
        RecRef.SetTable(BankAccount);

        if not BankAccount."Automatic Stmt. Import Enabled" then
            exit;

        BankAccount.GetDataExchDef(DataExchDef);

        DataExch."Related Record" := BankAccount.RecordId;
        if not DataExch.ImportFileContent(DataExchDef) then
            exit;

        BankAccount.LockTable();
        LastStatementNo := BankAccount."Last Statement No.";
        BankAccReconciliation.CreateNewBankPaymentAppBatch(BankAccount."No.", BankAccReconciliation);

        if not BankAccReconciliation.ImportStatement(BankAccReconciliation, DataExch) then begin
            DeleteBankAccReconciliation(BankAccReconciliation, BankAccount, LastStatementNo);
            exit;
        end;

        if not DummyBankAccReconciliationLine.LinesExist(BankAccReconciliation) then begin
            DeleteBankAccReconciliation(BankAccReconciliation, BankAccount, LastStatementNo);
            exit;
        end;

        Commit();
        BankAccReconciliation.ProcessStatement(BankAccReconciliation);
    end;

    local procedure DeleteBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccount: Record "Bank Account"; LastStatementNo: Code[20])
    begin
        if BankAccReconciliation.GetBySystemId(BankAccReconciliation.SystemId) then
            BankAccReconciliation.Delete();
        BankAccount.Find();
        BankAccount."Last Statement No." := LastStatementNo;
        BankAccount.Modify();
        Commit();
    end;
}

