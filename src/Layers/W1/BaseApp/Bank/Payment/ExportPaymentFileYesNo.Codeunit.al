// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Requisition;

/// <summary>
/// Codeunit 1209 "Export Payment File (Yes/No)" provides user confirmation for payment file export.
/// Validates journal line requirements, checks bank account setup, and prompts user confirmation
/// before proceeding with payment file export operations.
/// </summary>
/// <remarks>
/// Table No: Gen. Journal Line. Validates batch balancing account setup and document numbers.
/// Integrates with bank account payment export codeunits. Provides extensibility through
/// OnBeforeOnRun and OnAfterOnRun events for custom export logic.
/// </remarks>
codeunit 1209 "Export Payment File (Yes/No)"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Rec.FindSet() then
            Error(NothingToExportErr);
        Rec.SetRange("Journal Template Name", Rec."Journal Template Name");
        Rec.SetRange("Journal Batch Name", Rec."Journal Batch Name");

        GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        GenJnlBatch.TestField("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.TestField("Bal. Account No.");

        Rec.CheckDocNoOnLines();
        if Rec.IsExportedToPaymentFile() then
            if not Confirm(ExportAgainQst) then
                exit;
        BankAcc.Get(GenJnlBatch."Bal. Account No.");
        CODEUNIT.Run(BankAcc.GetPaymentExportCodeunitID(), Rec);

        OnAfterOnRun(Rec, GenJnlBatch, BankAcc);
    end;

    var
        ExportAgainQst: Label 'One or more of the selected lines have already been exported. Do you want to export again?';
        NothingToExportErr: Label 'There is nothing to export.';

    /// <summary>
    /// Integration event raised after completing the payment file export process.
    /// Enables custom logic to execute after successful export operations.
    /// </summary>
    /// <param name="GenJournalLine">General journal lines that were exported</param>
    /// <param name="GenJnlBatch">General journal batch used for export</param>
    /// <param name="BankAccount">Bank account used for payment export</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; BankAccount: Record "Bank Account")
    begin
    end;

    /// <summary>
    /// Integration event raised before starting the payment file export process.
    /// Enables custom validation or alternative export handling.
    /// </summary>
    /// <param name="GenJournalLine">General journal lines to be exported</param>
    /// <param name="IsHandled">Set to true to skip standard export processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeGetDirectCost', '', false, false)]
    local procedure OnBeforeGetDirectCost()
    begin
    end;
}

