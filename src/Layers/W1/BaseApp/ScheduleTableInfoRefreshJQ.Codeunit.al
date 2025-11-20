// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Threading;

using System.Environment;
using System.DataAdministration;

codeunit 9035 "Schedule Table Info Refresh JQ"
{
    Access = Public;

    var
        JobQueueCategoryTxt: Label 'Table Info', Locked = true, Comment = 'Max Length 10';
        JobQueueCategoryDescTxt: Label 'Table Information Cache';
        OtherCompanyJQQst: Label 'A job queue entry already exists in company %1. Do you want to delete the entry and create a new entry in the current company, (%2)', comment = '%1 and %2 are company names';
        ActionCancelledMsg: Label 'The action was cancelled by the user.';
        JobScheduledMsg: Label 'A job queue entry that runs daily to refresh the table information cache was created.';

    procedure ScheduleTableInfoRefreshJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
        NextRunDateFormula: DateFormula;
    begin
        if FindJobQueueEntryOtherCompany(JobQueueEntry) then begin
            // other company
            if Confirm(OtherCompanyJQQst, false, JobQueueEntry.CurrentCompany(), CompanyName) then begin
                JobQueueEntry.Delete(false);
                ScheduleTableInfoRefreshJobQueue();
            end else
                Message(ActionCancelledMsg);
        end else begin
            // current company
            if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Table Information Cache") then begin
                if not JobQueueEntry.IsReadyToStart() then
                    JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
            end else begin
                Evaluate(NextRunDateFormula, '<1D>');
                CreateTableInfoRefreshJobQueueCategory();
                JobQueueEntry.ScheduleRecurrentJobQueueEntryWithRunDateFormula(
                    JobQueueEntry."Object Type to Run"::Codeunit,
                    Codeunit::"Table Information Cache",
                    BlankRecordId,
                    JobQueueCategoryTxt,
                    0, // no rerun attempts
                    NextRunDateFormula,
                    040000T); // 4am
            end;
            Message(JobScheduledMsg);
        end;
    end;

    local procedure FindJobQueueEntryOtherCompany(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        Company: Record Company;
    begin
        Company.SetFilter(Name, '<>%1', CompanyName());
        if Company.FindSet() then
            repeat
                JobQueueEntry.ChangeCompany(Company.Name);
                JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
                if JobQueueEntry.FindFirst() then
                    exit(true);
            until Company.Next() = 0;
        JobQueueEntry.ChangeCompany(CompanyName()) // reset to current company
    end;

    local procedure CreateTableInfoRefreshJobQueueCategory()
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if JobQueueCategory.Get(JobQueueCategoryTxt) then
            exit;

        JobQueueCategory.Code := JobQueueCategoryTxt;
        JobQueueCategory.Description := JobQueueCategoryDescTxt;
        JobQueueCategory.Insert();
    end;
}
