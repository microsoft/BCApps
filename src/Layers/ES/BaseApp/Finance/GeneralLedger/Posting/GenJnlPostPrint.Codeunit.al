// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

/// <summary>
/// Handles posting of general journal lines with integrated document printing capabilities.
/// Combines journal posting functionality with automatic printing of posted documents and reports.
/// </summary>
/// <remarks>
/// Supports both immediate posting with printing and job queue scheduling with print flags.
/// Integrates with posting preview, error handling, and configurable report printing.
/// </remarks>
codeunit 232 "Gen. Jnl.-Post+Print"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GenJnlLine.Copy(Rec);
        Code();
        Rec.Copy(GenJnlLine);

        OnAfterOnRun(Rec);
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlPostviaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        GenJnlsScheduled: Boolean;
        TempJnlBatchName: Code[10];
        GLReg2: Record "G/L Register";

        JournalsScheduledMsg: Label 'Journal lines have been scheduled for posting.';
#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the report(s)?';
        Text003: Label 'The journal lines were successfully posted.';
#pragma warning disable AA0470
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        if GenJnlTemplate."Force Posting Report" or
           (GenJnlTemplate."Cust. Receipt Report ID" = 0) and (GenJnlTemplate."Vendor Receipt Report ID" = 0)
        then
            GenJnlTemplate.TestField("Posting Report ID");
        if GenJnlTemplate.Recurring and (GenJnlLine.GetFilter("Posting Date") <> '') then
            GenJnlLine.FieldError("Posting Date", Text000);

        OnBeforePostJournalBatch(GenJnlLine, HideDialog);

        if not HideDialog then begin
            if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                exit;
            if not GenJnlPostBatch.ConfirmPostingUnvoidableChecks(GenJnlLine."Journal Batch Name", GenJnlLine."Journal Template Name") then
                exit;
        end;

        TempJnlBatchName := GenJnlLine."Journal Batch Name";

        IsHandled := false;
        OnAfterConfirmPostJournalBatch(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Post & Print with Job Queue" then begin
            // Add job queue entry for each document no.
            GenJnlLine.SetCurrentKey("Document No.");
            while GenJnlLine.FindFirst() do begin
                GenJnlsScheduled := true;
                GenJnlLine."Print Posted Documents" := true;
                GenJnlLine.Modify();
                GenJnlPostviaJobQueue.EnqueueGenJrnlLineWithUI(GenJnlLine, false);
                GenJnlLine.SetFilter("Document No.", '>%1', GenJnlLine."Document No.");
            end;

            if GenJnlsScheduled then
                Message(JournalsScheduledMsg);
        end else begin
            if GLReg2.FindFirst() then begin
                GLReg2.LockTable();
                GLReg2.FindLast();
            end;

            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
            OnAfterPostJournalBatch(GenJnlLine);

            PrintJournal();

            if not HideDialog then
                if GenJnlLine."Line No." = 0 then
                    Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
                else begin
                    IsHandled := false;
                    OnCodeOnBeforeLinesSuccessfullyPostedMessage(GenJnlLine, IsHandled);
                    if not IsHandled then
                        if TempJnlBatchName = GenJnlLine."Journal Batch Name" then
                            Message(Text003)
                        else
                            Message(Text004, GenJnlLine."Journal Batch Name");
                end;
        end;

        if not GenJnlLine.Find('=><') or (TempJnlBatchName <> GenJnlLine."Journal Batch Name") or GeneralLedgerSetup."Post & Print with Job Queue" then begin
            GenJnlLine.Reset();
            GenJnlLine.FilterGroup(2);
            GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
            OnGenJnlLineSetFilter(GenJnlLine);
            GenJnlLine.FilterGroup(0);
            GenJnlLine."Line No." := 1;
        end;
    end;

    local procedure PrintJournal()
    var
        GLReg: Record "G/L Register";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintJournalBatch(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GLReg2.SetRange("No.", GLReg2."No." + 1, GenJnlLine."Line No.");
        if GLReg.Get(GenJnlLine."Line No.") then begin
            if GenJnlTemplate."Cust. Receipt Report ID" <> 0 then begin
                CustLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
                REPORT.Run(GenJnlTemplate."Cust. Receipt Report ID", false, false, CustLedgEntry);
            end;
            if GenJnlTemplate."Vendor Receipt Report ID" <> 0 then begin
                VendLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
                REPORT.Run(GenJnlTemplate."Vendor Receipt Report ID", false, false, VendLedgEntry);
            end;
            if GenJnlTemplate."Posting Report ID" <> 0 then begin
                GLReg.SetRecFilter();
                OnBeforeGLRegPostingReportPrint(GenJnlTemplate."Posting Report ID", false, false, GLReg, IsHandled);
                if not IsHandled then
                    REPORT.Run(GenJnlTemplate."Posting Report ID", false, false, GLReg2);
            end;
        end;
    end;

    /// <summary>
    /// Integration event raised after successfully posting journal batch operations.
    /// Enables post-processing or cleanup after journal lines have been posted.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that was posted</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    /// <summary>
    /// Integration event raised after confirming journal batch posting with the user.
    /// Enables modification of confirmation behavior or additional validation after user confirmation.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record to be posted</param>
    /// <param name="IsHandled">Set to true to handle confirmation processing externally</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPostJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before starting journal batch posting operations.
    /// Enables custom validation, preprocessing, or dialog suppression before posting begins.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record to be posted</param>
    /// <param name="HideDialog">Set to true to suppress confirmation dialogs during posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLRegPostingReportPrint(var ReportID: Integer; ReqWindow: Boolean; SystemPrinter: Boolean; var GLRegister: Record "G/L Register"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised when applying filters to journal lines during posting operations.
    /// Enables customization of journal line filtering logic or addition of custom filter criteria.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record being filtered for posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnGenJnlLineSetFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying successful posting messages to the user.
    /// Enables customization or suppression of standard posting success notifications.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that was successfully posted</param>
    /// <param name="IsHandled">Set to true to suppress standard success messages</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeLinesSuccessfullyPostedMessage(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after completing the OnRun trigger processing.
    /// Enables final cleanup or logging operations after journal posting and printing completion.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that was processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before printing journal batch reports.
    /// Enables custom print handling or suppression of standard journal batch printing.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record being printed</param>
    /// <param name="IsHandled">Set to true to handle printing externally and skip standard printing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

