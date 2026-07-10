// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Journal;

codeunit 1021 "Job Jnl.-Post"
{
    TableNo = "Job Journal Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        JobJnlLine.Copy(Rec);
        Code();
        Rec.Copy(JobJnlLine);
    end;

    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];
        HideDialog: Boolean;
        SuppressCommit: Boolean;
        PreviewMode: Boolean;

#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals.';
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
#pragma warning disable AA0470
        Text005: Label 'You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        JobJnlPostBatch: Codeunit "Job Jnl.-Post Batch";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        IsHandled: Boolean;
    begin
        OnBeforeCode(JobJnlLine, HideDialog, SuppressCommit);

        JobJnlTemplate.Get(JobJnlLine."Journal Template Name");
        JobJnlTemplate.TestField("Force Posting Report", false);
        if JobJnlTemplate.Recurring and (JobJnlLine.GetFilter("Posting Date") <> '') then
            JobJnlLine.FieldError("Posting Date", Text000);

        IsHandled := false;
        OnCodeOnBeforeConfirm(JobJnlLine, IsHandled);
        if not PreviewMode then
            if not IsHandled then
                if not Confirm(Text001) then
                    exit;

        OnCodeOnAfterConfirm(JobJnlLine);

        TempJnlBatchName := JobJnlLine."Journal Batch Name";

        JobJnlPostBatch.SetSuppressCommit(SuppressCommit or PreviewMode);
        JobJnlPostBatch.Run(JobJnlLine);

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        if not HideDialog then
            if JobJnlLine."Line No." = 0 then
                Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
            else
                if TempJnlBatchName = JobJnlLine."Journal Batch Name" then
                    Message(Text003)
                else
                    Message(
                        Text004 +
                        Text005,
                        JobJnlLine."Journal Batch Name");

        if not JobJnlLine.Find('=><') or (TempJnlBatchName <> JobJnlLine."Journal Batch Name") then begin
            JobJnlLine.Reset();
            JobJnlLine.FilterGroup(2);
            JobJnlLine.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
            JobJnlLine.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
            JobJnlLine.FilterGroup(0);
            JobJnlLine."Line No." := 1;
        end;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    internal procedure Preview(var JobJournalLine: Record "Job Journal Line")
    var
        JobJnlPost: Codeunit "Job Jnl.-Post";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(JobJnlPost);
        GenJnlPostPreview.Preview(JobJnlPost, JobJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        JobJournalLine: Record "Job Journal Line";
        JobJnlPost: Codeunit "Job Jnl.-Post";
    begin
        JobJournalLine.Copy(RecVar);
        JobJnlPost.SetPreviewMode(true);
        Result := JobJnlPost.Run(JobJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var JobJnlLine: Record "Job Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterConfirm(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeConfirm(JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

