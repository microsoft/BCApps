// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Statement;

codeunit 371 "Bank Acc. Recon. Post (Yes/No)"
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    begin
        if BankAccReconPostYesNo(Rec) then;
    end;

    var
        PostReconciliationQst: Label 'Do you want to post the Reconciliation?';
        PostPaymentsOnlyQst: Label 'Do you want to post the payments?';
        PostPaymentsAndReconcileQst: Label 'Do you want to post the payments and reconcile the bank account?';
        OpenPostedBankReconciliationQst: Label 'The reconciliation was posted for bank account %1 with statement number %2. The reconciliation was moved to the Bank Account Statement List window.\\Do you want to open the bank account statement?', Comment = '%1 = bank account no., %2 = bank account statement number';

    procedure BankAccReconPostYesNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation") Result: Boolean
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        ReversePaymentRecJournal: Codeunit "Reverse Payment Rec. Journal";
        Question: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBankAccReconPostYesNo(BankAccReconciliation, Result, IsHandled);
        if IsHandled then
            exit(Result);

        BankAccRecon.Copy(BankAccReconciliation);

        if BankAccRecon."Statement Type" = BankAccRecon."Statement Type"::"Payment Application" then begin
            if BankAccRecon."Post Payments Only" then
                Question := PostPaymentsOnlyQst
            else
                Question := PostPaymentsAndReconcileQst;
            BindSubscription(ReversePaymentRecJournal);
        end
        else
            Question := PostReconciliationQst;

        if not Confirm(Question, false) then
            exit(false);

        CODEUNIT.Run(CODEUNIT::"Bank Acc. Reconciliation Post", BankAccRecon);
        BankAccReconciliation := BankAccRecon;

        ReversePaymentRecJournal.SetGLRegisterNo(BankAccRecon);
        ShowPostedConfirmationMessage(BankAccRecon);
        exit(true);
    end;

    local procedure ShowPostedConfirmationMessage(BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        if GuiAllowed then begin
            BankAccountStatement.SetRange(BankAccountStatement."Bank Account No.", BankAccRecon."Bank Account No.");
            BankAccountStatement.SetRange(BankAccountStatement."Statement No.", BankAccRecon."Statement No.");
            if not BankAccountStatement.IsEmpty() then
                if Confirm(StrSubstNo(OpenPostedBankReconciliationQst, BankAccRecon."Bank Account No.", BankAccRecon."Statement No.")) then begin
                    Commit();
                    BankAccountStatement.Get(BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
                    Page.Run(Page::"Bank Account Statement", BankAccountStatement);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankAccReconPostYesNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var Result: Boolean; var Handled: Boolean)
    begin
    end;
}
