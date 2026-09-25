// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// Admin entry point for the Email Inbox duplicate cleanup mitigation.
// </summary>
page 3325 "PA Email Storage Cleanup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    Extensible = false;
    SourceTable = "PA Email Cleanup Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Payables Agent Email Storage Cleanup';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Affected)
            {
                Caption = 'Status';

                field(DuplicateGroups; DuplicateGroupCount)
                {
                    ApplicationArea = All;
                    Caption = 'Affected emails';
                    Editable = false;
                    ToolTip = 'Specifies how many distinct emails currently have more than one copy stored in the Email Inbox.';
                    StyleExpr = AffectedStyle;
                }
                field(RedundantRows; RedundantRowCount)
                {
                    ApplicationArea = All;
                    Caption = 'Redundant copies to delete';
                    Editable = false;
                    ToolTip = 'Specifies how many Email Inbox rows the cleanup would delete. The oldest copy of each email is always kept.';
                    StyleExpr = AffectedStyle;
                }
                field(SkippedRows; SkippedRowCount)
                {
                    ApplicationArea = All;
                    Caption = 'Copies to skip (not cleaned)';
                    Editable = false;
                    ToolTip = 'Specifies how many redundant copies would be skipped because their email message is shared with another inbox row, or has been sent or queued to send. These need manual review.';
                }
                field(LastScannedAt; LastScannedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Last checked';
                    Editable = false;
                    ToolTip = 'Specifies when the affected-email figures above were last calculated.';
                }
            }
            group(Configuration)
            {
                Caption = 'Cleanup configuration';

                field(CommitBatchSize; Rec."Commit Batch Size")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many Email Inbox rows are deleted before the deletions are committed. Smaller batches keep transactions and locks short on large inboxes; rows deleted before an interruption stay deleted.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field(StartingDateTime; Rec."Starting Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the earliest date and time the background cleanup is allowed to start. Leave blank to start as soon as the job queue picks it up.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group(Background)
            {
                Caption = 'Background cleanup';

                field(ScheduleStatus; ScheduleStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Schedule status';
                    Editable = false;
                    StyleExpr = ScheduleStyle;
                    ToolTip = 'Specifies the live state of the background cleanup, read from its Job Queue entry.';
                }
                field(ScheduledAt; ScheduledAt)
                {
                    ApplicationArea = All;
                    Caption = 'Next run';
                    Editable = false;
                    ToolTip = 'Specifies the earliest start time the job queue will honour for the scheduled cleanup.';
                }
                field(BackgroundError; BackgroundError)
                {
                    ApplicationArea = All;
                    Caption = 'Last background error';
                    Editable = false;
                    Style = Unfavorable;
                    Visible = BackgroundError <> '';
                    ToolTip = 'Specifies the error reported by the last background cleanup run, if it failed. Open the background job for the full Job Queue log.';
                }
                field(LastRunAt; Rec."Last Run At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the cleanup last deleted rows.';
                }
                field(LastDeletedCount; Rec."Last Deleted Count")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how many redundant copies the last run deleted.';
                }
                field(LastSkippedCount; Rec."Last Skipped Count")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how many copies the last run skipped because they were shared, sent, queued, or could not be deleted.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CheckNow)
            {
                ApplicationArea = All;
                Caption = 'Check for duplicates';
                Image = Refresh;
                ToolTip = 'Recalculate how many emails are affected and how many redundant copies would be deleted.';

                trigger OnAction()
                begin
                    RefreshStatistics();
                end;
            }
            action(ViewDuplicates)
            {
                ApplicationArea = All;
                Caption = 'View affected emails';
                Image = ViewDetails;
                ToolTip = 'Open the list of affected emails with the number of stored copies of each.';

                trigger OnAction()
                var
                    EmailDuplicates: Page "PA Email Duplicates";
                begin
                    EmailDuplicates.RunModal();
                    RefreshStatistics();
                end;
            }
            action(ActivateSchedule)
            {
                ApplicationArea = All;
                Caption = 'Activate scheduled cleanup';
                Image = Timesheet;
                ToolTip = 'Queue the background cleanup using the configuration above. It keeps the oldest copy of each email and deletes the rest. This cannot be undone.';

                trigger OnAction()
                var
                    Scheduler: Codeunit "PA Email Cleanup Scheduler";
                    ConfirmQst: Label 'Activate the background cleanup?\\It deletes the redundant Email Inbox copies, keeping the oldest copy of each email, and cascades into their email messages, attachments and media. This cannot be undone.';
                    DoneMsg: Label 'The background cleanup has been scheduled.';
                begin
                    if not Confirm(ConfirmQst, false) then
                        exit;
                    CurrPage.SaveRecord();
                    Scheduler.Activate(Rec."Starting Date/Time");
                    RefreshScheduleState();
                    Message(DoneMsg);
                end;
            }
            action(RunNow)
            {
                ApplicationArea = All;
                Caption = 'Clean up now';
                Image = Delete;
                ToolTip = 'Queue a one-off cleanup to start immediately, independent of the recurring schedule. It keeps the oldest copy of each email and deletes the rest. This cannot be undone.';

                trigger OnAction()
                var
                    Scheduler: Codeunit "PA Email Cleanup Scheduler";
                    ConfirmQst: Label 'Start a one-off cleanup now?\\It deletes the redundant Email Inbox copies, keeping the oldest copy of each email. This cannot be undone.';
                    DoneMsg: Label 'A one-off cleanup has been queued and will start shortly.';
                begin
                    if not Confirm(ConfirmQst, false) then
                        exit;
                    Scheduler.Activate(CurrentDateTime());
                    RefreshScheduleState();
                    Message(DoneMsg);
                end;
            }
            action(CancelSchedule)
            {
                ApplicationArea = All;
                Caption = 'Cancel scheduled cleanup';
                Image = Cancel;
                ToolTip = 'Remove the scheduled background cleanup job. Rows already deleted stay deleted.';

                trigger OnAction()
                var
                    Scheduler: Codeunit "PA Email Cleanup Scheduler";
                    ConfirmQst: Label 'Cancel the scheduled background cleanup?';
                    DoneMsg: Label 'The scheduled background cleanup has been cancelled.';
                begin
                    if not Confirm(ConfirmQst, false) then
                        exit;
                    Scheduler.CancelCleanupJob();
                    RefreshScheduleState();
                    Message(DoneMsg);
                end;
            }
            action(OpenJobQueueEntry)
            {
                ApplicationArea = All;
                Caption = 'Open background job';
                Image = JobListSetup;
                ToolTip = 'Open the Job Queue Entry of the background cleanup for diagnostics.';

                trigger OnAction()
                var
                    Scheduler: Codeunit "PA Email Cleanup Scheduler";
                begin
                    Scheduler.OpenJobQueueCard();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(CheckNow_Promoted; CheckNow) { }
                actionref(ViewDuplicates_Promoted; ViewDuplicates) { }
                actionref(ActivateSchedule_Promoted; ActivateSchedule) { }
                actionref(RunNow_Promoted; RunNow) { }
                actionref(CancelSchedule_Promoted; CancelSchedule) { }
            }
        }
    }

    var
        DuplicateGroupCount: Integer;
        RedundantRowCount: Integer;
        SkippedRowCount: Integer;
        LastScannedAt: DateTime;
        AffectedStyle: Text;
        ScheduleStatusText: Text;
        ScheduleStyle: Text;
        ScheduledAt: DateTime;
        BackgroundError: Text;

    trigger OnOpenPage()
    begin
        Rec.GetSingleton();
        if Rec."Commit Batch Size" < 1 then
            Rec."Commit Batch Size" := Rec.DefaultCommitBatchSize();
        RefreshScheduleState();
    end;

    local procedure RefreshStatistics()
    var
        Cleanup: Codeunit "PA Email Cleanup";
    begin
        Cleanup.GetDuplicateStatistics(DuplicateGroupCount, RedundantRowCount, SkippedRowCount);
        LastScannedAt := CurrentDateTime();
        if RedundantRowCount > 0 then
            AffectedStyle := 'Attention'
        else
            AffectedStyle := 'Favorable';

        CurrPage.Update(false);
    end;

    local procedure RefreshScheduleState()
    var
        Scheduler: Codeunit "PA Email Cleanup Scheduler";
    begin
        ScheduleStatusText := Scheduler.GetStatusText();
        ScheduledAt := Scheduler.GetScheduledAt();
        BackgroundError := Scheduler.GetLastError();
        if Scheduler.IsRunning() then
            ScheduleStyle := 'Attention'
        else
            if Scheduler.IsScheduled() then
                ScheduleStyle := 'Favorable'
            else
                ScheduleStyle := 'Subordinate';

        CurrPage.Update(false);
    end;
}
