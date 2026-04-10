namespace System.Threading;

using System.Environment;

codeunit 3846 "Scheduled Tasks"
{
    Access = Internal;

    var
        SetTaskReadyDifferentCompanyTasksLbl: Label 'The task is created for company %1, and will run according to its schedule. Do you want to continue?', Comment = '%1 - Company Name';
        CancelDifferentCompanyTasksLbl: Label 'The task is created for company %1. Are you sure you want to cancel it?', Comment = '%1 - Company Name';

    procedure SetTasksReady(var ScheduledTasks: Record "Scheduled Task")
    var
        JobQueue: Record "Job Queue Entry";
        ReadyTask: Boolean;
    begin
        repeat
            if ScheduledTasks.Company <> CompanyName() then
                ReadyTask := Dialog.Confirm(SetTaskReadyDifferentCompanyTasksLbl, true, ScheduledTasks.Company)
            else
                ReadyTask := true;

            if ReadyTask then begin
                JobQueue.CheckRequiredPermissions();
                JobQueue.ChangeCompany(ScheduledTasks.Company);
                JobQueue.SetRange("System Task ID", ScheduledTasks.ID);
                if JobQueue.FindFirst() then begin
                    JobQueue.Status := JobQueue.Status::Ready; // Have to be set manually, otherwise SetStatus will enqueue a new task
                    JobQueue.Modify();
                end;
                TaskScheduler.SetTaskReady(ScheduledTasks.ID);
            end;
        until ScheduledTasks.Next() = 0;
    end;

    procedure CancelTasks(var ScheduledTasks: Record "Scheduled Task")
    var
        JobQueue: Record "Job Queue Entry";
        CancelTask: Boolean;
    begin
        repeat
            if ScheduledTasks.Company <> CompanyName() then
                CancelTask := Dialog.Confirm(CancelDifferentCompanyTasksLbl, true, ScheduledTasks.Company)
            else
                CancelTask := true;

            if CancelTask then begin
                if JobQueue.HasRequiredPermissions() then begin
                    JobQueue.ChangeCompany(ScheduledTasks.Company);
                    JobQueue.SetRange("System Task ID", ScheduledTasks.ID);
                    if JobQueue.FindFirst() then
                        JobQueue.SetStatus(JobQueue.Status::"On Hold"); // Setting status on hold will cancel the task
                end;

                TaskScheduler.CancelTask(ScheduledTasks.ID); // Force cancel irregardless of Job Queue, JQ will not cancel if it's already on onhold.
            end;
        until ScheduledTasks.Next() = 0;
    end;

    procedure IsTenantSpecific(var ScheduledTask: Record "Scheduled Task"): Boolean
    begin
        exit(ScheduledTask."Tenant ID" = Database.TenantId());
    end;
}