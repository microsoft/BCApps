// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.Environment;

codeunit 9022 "Pmt. Rec. Journals Launcher"
{

    trigger OnRun()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Payment Application");
        if BankAccReconciliation.Count = 1 then
            OpenJournal(BankAccReconciliation)
        else
            OpenList();
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

    local procedure OpenList()
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone then
            PAGE.Run(PAGE::"Pmt. Rec. Journals Overview")
        else
            PAGE.Run(PAGE::"Pmt. Reconciliation Journals");
    end;

    local procedure OpenJournal(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliation.FindFirst();
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");

        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone then
            PAGE.Run(PAGE::"Pmt. Recon. Journal Overview", BankAccReconciliationLine)
        else
            PAGE.Run(PAGE::"Payment Reconciliation Journal", BankAccReconciliationLine);
    end;
}

