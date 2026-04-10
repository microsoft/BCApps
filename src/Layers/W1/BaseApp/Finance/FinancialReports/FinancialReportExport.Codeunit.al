// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Azure.Identity;
using System.Threading;

codeunit 8360 "Financial Report Export"
{
    Access = Internal;
    Permissions = tabledata "Job Queue Category" = ri,
                  tabledata "Job Queue Entry" = rim;

    var
        JobQueueDescTxt: Label 'Auto-created for exporting and emailing of financial reports.';

    [EventSubscriber(ObjectType::Table, Database::"Financial Report Schedule", OnAfterInsertEvent, '', true, true)]
    local procedure FinancialReportScheduleOnAfterInsert(var Rec: Record "Financial Report Schedule"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            ScheduleJob(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Financial Report Schedule", OnAfterModifyEvent, '', true, true)]
    local procedure FinancialReportScheduleOnAfterModify(var Rec: Record "Financial Report Schedule"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            ScheduleJob(Rec);
    end;

    local procedure ScheduleJob(var FinancialReportSchedule: Record "Financial Report Schedule")
    var
        JobQueueEntry: Record "Job Queue Entry";
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        BlankRecId: RecordId;
    begin
        if FinancialReportSchedule.IsTemporary() then
            exit;
        if GetCurrentModuleExecutionContext() <> ExecutionContext::Normal then
            exit;
        if not JobQueueEntry.HasRequiredPermissions() then
            exit;
        if not TaskScheduler.CanCreateTask() then
            exit;
        if AzureADGraphUser.IsUserDelegatedAdmin() then
            exit;

        if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Financial Report Export Job") then begin
            if JobQueueEntry.IsReadyToStart() then
                exit;
            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        end else begin
            JobQueueEntry.ScheduleRecurrentJobQueueEntryWithFrequency(
                JobQueueEntry."Object Type to Run"::Codeunit,
                Codeunit::"Financial Report Export Job",
                BlankRecId,
                10);
            JobQueueEntry.Description := JobQueueDescTxt;
            JobQueueEntry.Modify();
        end;
    end;
}