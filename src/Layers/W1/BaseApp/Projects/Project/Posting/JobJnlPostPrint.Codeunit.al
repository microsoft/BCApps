// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;

codeunit 1022 "Job Jnl.-Post+Print"
{
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        JobJnlLine.Copy(Rec);
        Code();
        Rec.Copy(JobJnlLine);
    end;

    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";
        JobReg: Record "Job Register";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];

#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals.';
        Text001: Label 'Do you want to post the journal lines and print the posting report?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
#pragma warning disable AA0470
        Text005: Label 'You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        JobJnlTemplate.Get(JobJnlLine."Journal Template Name");
        JobJnlTemplate.TestField("Posting Report ID");
        if JobJnlTemplate.Recurring and (JobJnlLine.GetFilter("Posting Date") <> '') then
            JobJnlLine.FieldError("Posting Date", Text000);

        HideDialog := false;
        OnBeforePostJournalBatch(JobJnlLine, HideDialog);
        if not HideDialog then
            if not Confirm(Text001) then
                exit;

        TempJnlBatchName := JobJnlLine."Journal Batch Name";

        CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post Batch", JobJnlLine);

        if JobReg.Get(JobJnlLine."Line No.") then begin
            JobReg.SetRecFilter();
            IsHandled := false;
            OnBeforePrintJobReg(JobReg, IsHandled);
            if not IsHandled then
                REPORT.Run(JobJnlTemplate."Posting Report ID", false, false, JobReg);
        end;

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var JobJournalLine: Record "Job Journal Line"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintJobReg(var JobRegister: Record "Job Register"; var IsHandled: Boolean)
    begin
    end;
}

