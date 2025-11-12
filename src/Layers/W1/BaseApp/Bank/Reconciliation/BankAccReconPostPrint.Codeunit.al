// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Statement;
using Microsoft.Foundation.Reporting;

codeunit 372 "Bank Acc. Recon. Post+Print"
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);

        BankAccRecon.Copy(Rec);

        if not Confirm(PostAndPrintReconciliationQst, false) then
            exit;

        CODEUNIT.Run(CODEUNIT::"Bank Acc. Reconciliation Post", BankAccRecon);
        Rec := BankAccRecon;
        Commit();

        if BankAccStmt.Get(Rec."Bank Account No.", Rec."Statement No.") then
            DocPrint.PrintBankAccStmt(BankAccStmt);
    end;

    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccStmt: Record "Bank Account Statement";
        DocPrint: Codeunit "Document-Print";
        PostAndPrintReconciliationQst: Label 'Do you want to post and print the Reconciliation?';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;
}

