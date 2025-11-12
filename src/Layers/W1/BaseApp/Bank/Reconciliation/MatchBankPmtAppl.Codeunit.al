// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.IO;

codeunit 1254 "Match Bank Pmt. Appl."
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    var
        MatchBankPayments: Codeunit "Match Bank Payments";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Statement Type" <> Rec."Statement Type"::"Payment Application" then
            exit;

        BankAccReconciliationLine.FilterBankRecLines(Rec);
        if BankAccReconciliationLine.FindFirst() then begin
            MatchBankPayments.SetApplyEntries(true);
            MatchBankPayments.Run(BankAccReconciliationLine);
        end;
        OnAfterMatchBankPayments(Rec);
    end;

    procedure MatchNoOverwriteOfManualOrAccepted(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        MatchBankPayments: Codeunit "Match Bank Payments";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMatchNoOverwriteOfManualOrAccepted(BankAccReconciliation, IsHandled);
        if not IsHandled then begin
            BankAccReconciliationLine.FilterBankRecLines(BankAccReconciliation);
            if BankAccReconciliationLine.FindFirst() then begin
                MatchBankPayments.SetApplyEntries(true);
                MatchBankPayments.MatchNoOverwriteOfManualOrAccepted(BankAccReconciliationLine);
            end;
        end;
        OnAfterMatchBankPayments(BankAccReconciliation);
    end;

    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatchBankPayments(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatchNoOverwriteOfManualOrAccepted(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Table Processing Rule", 'OnDoesTableHaveCustomRuleInRapidStart', '', false, false)]
    local procedure CheckBankAccRecOnDoesTableHaveCustomRuleInRapidStart(TableID: Integer; var Result: Boolean)
    begin
        if TableID = DATABASE::"Bank Acc. Reconciliation" then
            Result := true;
    end;
}

