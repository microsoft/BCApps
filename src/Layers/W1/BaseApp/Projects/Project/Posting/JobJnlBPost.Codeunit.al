// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Posting;

using Microsoft.Projects.Project.Journal;

codeunit 1023 "Job Jnl.-B.Post"
{
    TableNo = "Job Journal Batch";

    trigger OnRun()
    begin
        JobJnlBatch.Copy(Rec);
        Code();
        Rec.Copy(JobJnlBatch);
    end;

    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostbatch: Codeunit "Job Jnl.-Post Batch";
        JnlWithErrors: Boolean;
        IsHandled: Boolean;
#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        JobJnlTemplate.Get(JobJnlBatch."Journal Template Name");
        JobJnlTemplate.TestField("Force Posting Report", false);

        IsHandled := false;
        OnCodeOnBeforeConfirm(IsHandled, JobJnlBatch, JobJnlTemplate);
        if not IsHandled then
            if not Confirm(Text000) then
                exit;

        JobJnlBatch.Find('-');
        repeat
            JobJnlLine."Journal Template Name" := JobJnlBatch."Journal Template Name";
            JobJnlLine."Journal Batch Name" := JobJnlBatch.Name;
            JobJnlLine."Line No." := 1;
            OnCodeOnBeforeJobJnlPostBatchRun(JobJnlLine, JobJnlBatch);
            Clear(JobJnlPostbatch);
            if JobJnlPostbatch.Run(JobJnlLine) then
                JobJnlBatch.Mark(false)
            else begin
                JobJnlBatch.Mark(true);
                JnlWithErrors := true;
            end;
        until JobJnlBatch.Next() = 0;

        if not JnlWithErrors then
            Message(Text001)
        else
            Message(
                Text002 +
                Text003);

        if not JobJnlBatch.Find('=><') then begin
            JobJnlBatch.Reset();
            JobJnlBatch.FilterGroup(2);
            JobJnlBatch.SetRange("Journal Template Name", JobJnlBatch."Journal Template Name");
            JobJnlBatch.FilterGroup(0);
            JobJnlBatch.Name := '';
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeJobJnlPostBatchRun(var JobJournalLine: Record "Job Journal Line"; var JobJournalBatch: Record "Job Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeConfirm(var IsHandled: Boolean; JobJournalBatch: Record "Job Journal Batch"; JobJournalTemplate: Record "Job Journal Template")
    begin
    end;
}

