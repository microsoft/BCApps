// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using System.Environment.Configuration;

codeunit 1295 "Get Bank Stmt. Line Candidates"
{
    TableNo = "Payment Application Proposal";

    trigger OnRun()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconLine.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.", Rec."Statement Line No.");

        TransferExistingAppliedPmtEntries(Rec, BankAccReconLine);

        TransferCandidatestoAppliedPmtEntries(Rec, BankAccReconLine);
    end;

    local procedure CreatePaymentApplicationProposalFromAppliedPmtEntry(var AppliedPmtEntry: Record "Applied Payment Entry"; var PaymentApplicationProposal: Record "Payment Application Proposal")
    begin
        if AppliedPmtEntry.FindSet() then
            repeat
                PaymentApplicationProposal.CreateFromAppliedPaymentEntry(AppliedPmtEntry);
            until AppliedPmtEntry.Next() = 0;
    end;

    local procedure GetCandidateRanking(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        BankAccReconLine.SetRecFilter();
        MatchBankPayments.SetApplyEntries(false);
        MatchBankPayments.Run(BankAccReconLine);
        MatchBankPayments.GetBankStatementMatchingBuffer(TempBankStmtMatchingBuffer);

        BankPmtApplSettings.GetOrInsert();
        if not BankPmtApplSettings."Cust. Ledger Entries Matching" then
            MatchBankPayments.GetCustomerLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);

        if not BankPmtApplSettings."Vendor Ledger Entries Matching" then
            MatchBankPayments.GetVendorLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);

        if not BankPmtApplSettings."Empl. Ledger Entries Matching" then
            MatchBankPayments.GetEmployeeLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);

        if not BankPmtApplSettings."Bank Ledger Entries Matching" then
            MatchBankPayments.GetBankLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);
    end;

    local procedure GetLedgerEntries(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    var
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        MatchBankPayments.GetLedgerEntriesAsMatchingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine);
        TempBankStmtMatchingBuffer.Reset();
    end;

    local procedure TransferExistingAppliedPmtEntries(var PaymentApplicationProposal: Record "Payment Application Proposal"; BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        ExistingAppliedPmtEntry: Record "Applied Payment Entry";
    begin
        ExistingAppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
        CreatePaymentApplicationProposalFromAppliedPmtEntry(ExistingAppliedPmtEntry, PaymentApplicationProposal);
    end;


    procedure ShowDisableAutomaticSuggestionsNotification()
    var
        MyNotifications: Record "My Notifications";
        DisableAutomaticSuggestionsNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetDisableAutomaticSuggestionsNotificationId()) then
            exit;

        DisableAutomaticSuggestionsNotification.Id := GetDisableAutomaticSuggestionsNotificationId();
        DisableAutomaticSuggestionsNotification.Recall();
        DisableAutomaticSuggestionsNotification.Message := DisableAutomaticSuggestionsNotificationMsg;
        DisableAutomaticSuggestionsNotification.AddAction(DisableAutomaticSuggestionsTxt, Codeunit::"Get Bank Stmt. Line Candidates", 'DisableAutomaticNotificationAction');
        DisableAutomaticSuggestionsNotification.AddAction(DontShowAgainTxt, Codeunit::"Get Bank Stmt. Line Candidates", 'DisableAutomaticNotificationAction');
        DisableAutomaticSuggestionsNotification.Send();
    end;

    procedure DisableAutomaticNotificationAction(DisableAutomaticSuggestionsNotification: Notification)
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Apply Man. Disable Suggestions" := true;
        BankPmtApplSettings.Modify();
    end;

    procedure DontShowAgainDisableAutomaticNotificationAction()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetDisableAutomaticSuggestionsNotificationId()) then
            MyNotifications.InsertDefault(GetDisableAutomaticSuggestionsNotificationId(), DisableAutomaticSuggestionsNotificationNameTxt, DisableAutomaticSuggestionsNotificationDescriptionTxt, false);
    end;

    local procedure GetDisableAutomaticSuggestionsNotificationId(): Guid
    begin
        exit('2d9bef44-ca94-4e70-91c7-b3393beaffc3');
    end;

    local procedure TransferCandidatestoAppliedPmtEntries(var PaymentApplicationProposal: Record "Payment Application Proposal"; BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        BankAccount: Record "Bank Account";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        Handled: Boolean;
    begin
        OnBeforeTransferCandidatestoAppliedPmtEntries(BankAccReconLine, TempBankStmtMatchingBuffer, Handled);
        if not Handled then begin
            BankPmtApplSettings.GetOrInsert();
            if BankPmtApplSettings."Apply Man. Disable Suggestions" and (not ForceSuggestEntries) then
                GetLedgerEntries(BankAccReconLine, TempBankStmtMatchingBuffer)
            else
                GetCandidateRanking(BankAccReconLine, TempBankStmtMatchingBuffer);
        end;

        BankAccount.Get(BankAccReconLine."Bank Account No.");

        PaymentApplicationProposal.Reset();
        TempBankStmtMatchingBuffer.Reset();
        TempBankStmtMatchingBuffer.SetRange("One to Many Match", false);
        if TempBankStmtMatchingBuffer.FindSet() then
            repeat
                PaymentApplicationProposal.CreateFromBankStmtMacthingBuffer(TempBankStmtMatchingBuffer, BankAccReconLine, BankAccount);
                if not PaymentApplicationProposal.Insert(true) then begin
                    PaymentApplicationProposal.Find();
                    PaymentApplicationProposal."Match Confidence" :=
                        Enum::"Bank Rec. Match Confidence".FromInteger(BankPmtApplRule.GetMatchConfidence(PaymentApplicationProposal.Quality));
                    PaymentApplicationProposal.Modify(true);
                end;
            until TempBankStmtMatchingBuffer.Next() = 0;
    end;

    procedure SetSuggestEntries(SuggestEntries: boolean)
    begin
        ForceSuggestEntries := SuggestEntries;
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeTransferCandidatestoAppliedPmtEntries(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var Handled: Boolean)
    begin
    end;

    var
        DisableAutomaticSuggestionsNotificationMsg: Label 'Sorting the list based on the match probability is causing this page to open slowly. For faster performance, you can turn off autosuggestions, and then use the Suggest Entries action on the Payment Application page instead.';
        DisableAutomaticSuggestionsTxt: Label 'Turn Off Automatic Suggestions';
        DisableAutomaticSuggestionsNotificationNameTxt: Label 'Payment Reconciliation - Disable Automatic Suggestions';
        DisableAutomaticSuggestionsNotificationDescriptionTxt: Label 'This notification is used when the Payment Application page is opening slowly. It can be used to turn off automatic suggestions, which will help the page open more quickly.';
        DontShowAgainTxt: Label 'Do not show again';
        ForceSuggestEntries: Boolean;
}

