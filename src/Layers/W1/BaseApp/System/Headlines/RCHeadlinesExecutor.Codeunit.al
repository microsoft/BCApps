namespace System.Visualization;

using System.Threading;

codeunit 1441 "RC Headlines Executor"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        RCHeadlinesUserData: Record "RC Headlines User Data";
        RoleCenterPageID: Integer;
    begin
        Evaluate(RoleCenterPageID, Rec."Parameter String");
        RCHeadlinesUserData.Get(UserSecurityId(), RoleCenterPageID);
        WorkDate := RCHeadlinesUserData."User workdate";
        OnComputeHeadlines(RoleCenterPageID);
    end;


    procedure ScheduleTask(RoleCenterPageID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
        Tomorrow: Date;
    begin
        if not JobQueueEntry.ReadPermission() then
            exit;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"RC Headlines Executor");
        JobQueueEntry.SetRange("Parameter String", Format(RoleCenterPageID));
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::"In Process", JobQueueEntry.Status::Ready);
        if not JobQueueEntry.IsEmpty() then
            exit;

        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Error, JobQueueEntry.Status::"On Hold");
        if JobQueueEntry.FindFirst() then begin
            // restart the job tomorrow
            Tomorrow := CalcDate('<+1d>');
            JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Tomorrow, Time());
        end else begin
            // create a new job
            JobQueueEntry.Init();
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := Codeunit::"RC Headlines Executor";
            JobQueueEntry."Parameter String" := Format(RoleCenterPageID);
        end;

        if TaskSchedulerAvailable() then
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry)
        else
            OnTaskSchedulerUnavailable(JobQueueEntry);
    end;

    local procedure TaskSchedulerAvailable(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not JobQueueEntry.WritePermission() then
            exit(false);

        if not JobQueueEntry.HasRequiredPermissions() then
            exit(false);

        if not TaskScheduler.CanCreateTask() then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnComputeHeadlines(RoleCenterPageID: Integer)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnTaskSchedulerUnavailable(JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

