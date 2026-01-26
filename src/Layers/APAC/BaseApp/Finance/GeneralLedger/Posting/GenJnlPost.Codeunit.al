// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.NoSeries;
using System.Utilities;

/// <summary>
/// Handles posting of individual general journal lines with integrated validation and job queue support.
/// Provides core posting functionality with error handling, preview capabilities, and extensibility events.
/// </summary>
/// <remarks>
/// Supports both immediate posting and job queue scheduling based on General Ledger Setup configuration.
/// Integrates with posting preview, fixed asset validation, and extensible posting workflows.
/// </remarks>
codeunit 231 "Gen. Jnl.-Post"
{
    EventSubscriberInstance = Manual;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        GenJnlLine.Copy(Rec);
        Code(GenJnlLine);
        Rec.Copy(GenJnlLine);

        OnAfterOnRun(Rec);
    end;

    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        JournalsScheduledMsg: Label 'Journal lines have been scheduled for posting.';
#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
#pragma warning disable AA0470
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
        Text005: Label 'Using %1 for Declining Balance can result in misleading numbers for subsequent years. You should manually check the postings and correct them if necessary. Do you want to continue?';
        Text006: Label '%1 in %2 must not be equal to %3 in %4.', Comment = 'Source Code in Genenral Journal Template must not be equal to Job G/L WIP in Source Code Setup.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GenJnlsScheduled: Boolean;
        PreviewMode: Boolean;

    local procedure "Code"(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        FALedgEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlPostviaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        ConfirmManagement: Codeunit "Confirm Management";
        TempJnlBatchName: Code[10];
        HideDialog: Boolean;
        PrintWHT: Boolean;
        IsHandled: Boolean;
        ShouldExit: Boolean;
    begin
        HideDialog := false;
        OnBeforeCode(GenJnlLine, HideDialog);

        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        if GenJnlTemplate.Type = GenJnlTemplate.Type::Jobs then begin
            SourceCodeSetup.Get();
            if GenJnlTemplate."Source Code" = SourceCodeSetup."Job G/L WIP" then
                Error(Text006, GenJnlTemplate.FieldCaption("Source Code"), GenJnlTemplate.TableCaption(),
                  SourceCodeSetup.FieldCaption("Job G/L WIP"), SourceCodeSetup.TableCaption());
        end;
        GenJnlTemplate.TestField("Force Posting Report", false);
        if GenJnlTemplate.Recurring and (GenJnlLine.GetFilter(GenJnlLine."Posting Date") <> '') then
            GenJnlLine.FieldError("Posting Date", Text000);

        OnCodeOnAfterCheckTemplate(GenJnlLine);

        IsHandled := false;
        ShouldExit := false;
        OnCodeOnBeforeConfirmPostJournalLinesResponse(GenJnlLine, IsHandled, ShouldExit);
        if ShouldExit then
            exit;

        if not IsHandled then
            if not (PreviewMode or HideDialog) then
                if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                    exit;

        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then begin
            FALedgEntry.SetRange("FA No.", GenJnlLine."Account No.");
            FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
            if not FALedgEntry.IsEmpty() and GenJnlLine."Depr. Acquisition Cost" and not HideDialog then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text005, GenJnlLine.FieldCaption(GenJnlLine."Depr. Acquisition Cost")), true) then
                    exit;
        end;

        if not HideDialog then
            if not GenJnlPostBatch.ConfirmPostingUnvoidableChecks(GenJnlLine."Journal Batch Name", GenJnlLine."Journal Template Name") then
                exit;

        OnCodeOnAfterConfirmPostingUnvoidableChecks(GenJnlLine);

        TempJnlBatchName := GenJnlLine."Journal Batch Name";

        GeneralLedgerSetup.Get();
        GenJnlPostBatch.SetPreviewMode(PreviewMode);
        if GenJnlLine."Certificate Printed" then
            PrintWHT := true;
        if GeneralLedgerSetup."Post with Job Queue" and not PreviewMode then begin
            // Add job queue entry for each document no.
            GenJnlLine.SetCurrentKey("Document No.");
            while GenJnlLine.FindFirst() do begin
                GenJnlsScheduled := true;
                GenJnlPostviaJobQueue.EnqueueGenJrnlLineWithUI(GenJnlLine, false);
                GenJnlLine.SetFilter("Document No.", '>%1', GenJnlLine."Document No.");
            end;

            if GenJnlsScheduled then
                Message(JournalsScheduledMsg);
        end else begin
            IsHandled := false;
            OnBeforeGenJnlPostBatchRun(GenJnlLine, IsHandled, GenJnlPostBatch);
            if IsHandled then
                exit;

            GenJnlPostBatch.Run(GenJnlLine);

            OnCodeOnAfterGenJnlPostBatchRun(GenJnlLine);

            if PreviewMode then
                exit;

            Commit();
            BatchPostingPrintMgt.PrintOtherDocuments(GenJnlLine, PrintWHT, false);

            ShowPostResultMessage(GenJnlLine, TempJnlBatchName);
        end;

        if not GenJnlLine.Find('=><') or (TempJnlBatchName <> GenJnlLine."Journal Batch Name") or GeneralLedgerSetup."Post with Job Queue" then begin
            GenJnlLine.Reset();
            GenJnlLine.FilterGroup(2);
            GenJnlLine.SetRange(GenJnlLine."Journal Template Name", GenJnlLine."Journal Template Name");
            GenJnlLine.SetRange(GenJnlLine."Journal Batch Name", GenJnlLine."Journal Batch Name");
            OnGenJnlLineSetFilter(GenJnlLine);
            GenJnlLine.FilterGroup(0);
            GenJnlLine."Line No." := 1;
        end;
    end;

    local procedure ShowPostResultMessage(var GenJnlLine: Record "Gen. Journal Line"; TempJnlBatchName: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPostResultMessage(GenJnlLine, TempJnlBatchName, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = GenJnlLine."Journal Batch Name" then
                Message(Text003)
            else
                Message(Text004, GenJnlLine."Journal Batch Name");
    end;

    /// <summary>
    /// Initiates posting preview for general journal lines without committing transactions.
    /// Creates preview entries for analysis and validation before actual posting operations.
    /// </summary>
    /// <param name="GenJournalLineSource">Journal line record to preview for posting</param>
    procedure Preview(var GenJournalLineSource: Record "Gen. Journal Line")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    begin
        BindSubscription(GenJnlPost);
        GenJnlPostPreview.Preview(GenJnlPost, GenJournalLineSource);
    end;

    /// <summary>
    /// Integration event raised before starting journal line posting operations.
    /// Enables custom validation, preprocessing, or dialog suppression before posting begins.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that will be posted</param>
    /// <param name="HideDialog">Set to true to suppress confirmation dialogs during posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var GenJournalLine: Record "Gen. Journal Line"; var HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before executing the Gen. Jnl.-Post Batch codeunit.
    /// Enables custom posting logic or complete override of standard batch posting functionality.
    /// </summary>
    /// <param name="GenJnlLine">Journal line record being processed for posting</param>
    /// <param name="IsHandled">Set to true to skip standard Gen. Jnl.-Post Batch execution</param>
    /// <param name="GenJnlPostBatch">Reference to the Gen. Jnl.-Post Batch codeunit instance</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostBatchRun(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch")
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying posting result messages to the user.
    /// Enables customization of success messages or suppression of standard posting notifications.
    /// </summary>
    /// <param name="GenJnlLine">Journal line record that was posted</param>
    /// <param name="TempJnlBatchName">Original journal batch name before posting operations</param>
    /// <param name="IsHandled">Set to true to suppress standard posting result messages</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostResultMessage(var GenJnlLine: Record "Gen. Journal Line"; TempJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after successful execution of the Gen. Jnl.-Post Batch codeunit.
    /// Enables post-processing operations or custom cleanup after posting completion.
    /// </summary>
    /// <param name="GenJnlLine">Journal line record that was processed during posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGenJnlPostBatchRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after journal template validation but before posting confirmation.
    /// Enables additional template-specific validation or preprocessing logic.
    /// </summary>
    /// <param name="GenJnlLine">Journal line record with validated template</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheckTemplate(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    begin
        GenJnlPost := Subscriber;
        GenJournalLine.Copy(RecVar);
        PreviewMode := true;
        Result := GenJnlPost.Run(GenJournalLine);
    end;

    /// <summary>
    /// Integration event raised when setting filter criteria for general journal line processing.
    /// Enables custom filtering logic for journal line selection and validation workflows.
    /// </summary>
    /// <param name="GenJournalLine">General journal line record for filter application</param>
    [IntegrationEvent(false, false)]
    local procedure OnGenJnlLineSetFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before confirming posting of journal lines with the user.
    /// Enables custom confirmation logic or automatic approval of posting operations.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record to be posted</param>
    /// <param name="IsHandled">Set to true to skip standard confirmation dialog</param>
    /// <param name="ShouldExit">Set to true to exit posting without proceeding</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeConfirmPostJournalLinesResponse(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var ShouldExit: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after completing the OnRun trigger processing.
    /// Enables final cleanup or logging operations after journal line posting completion.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that was processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after confirming unvoidable posting checks but before actual posting.
    /// Enables final validation or preprocessing after user confirmations are complete.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record ready for posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterConfirmPostingUnvoidableChecks(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

