namespace System.Threading;

using System.Environment;
using System.Security.AccessControl;
using System.Telemetry;

codeunit 455 "Job Queue User Handler"
{
    var
        JobQueueRescheduledTxt: Label 'Job queue entry rescheduled on login: %1', Comment = '%1 - Job Queue Entry ID', Locked = true;

    trigger OnRun()
    begin
        RescheduleJobQueueEntries();
    end;

    local procedure RescheduleJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Company: Record Company;
        NeedsRescheduling: Boolean;
    begin
        Company.SetLoadFields("Evaluation Company");
        if Company.Get(CompanyName()) then;

        JobQueueEntry.SetFilter(Status, '%1|%2|%3', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process", JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        if not Company."Evaluation Company" then  // because demo data is usually created by other users, e.g. a Microsoft machine agent.
            JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange(Scheduled, false);
        if JobQueueEntry.FindSet(true) then
            repeat
                if JobQueueEntry.Status = JobQueueEntry.Status::"On Hold with Inactivity Timeout" then
                    NeedsRescheduling := JobQueueEntry.DoesJobNeedToBeRun()
                else
                    NeedsRescheduling := JobShouldBeRescheduled(JobQueueEntry);
                if NeedsRescheduling then
                    Reschedule(JobQueueEntry);
            until JobQueueEntry.Next() = 0;
    end;

    local procedure Reschedule(var JobQueueEntry: Record "Job Queue Entry")
    var
        Telemetry: Codeunit Telemetry;
        JobQueueTelemetry: Codeunit "Job Queue Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        if TaskScheduler.TaskExists(JobQueueEntry."System Task ID") then
            if TaskScheduler.SetTaskReady(JobQueueEntry."System Task ID", JobQueueEntry."Earliest Start Date/Time") then begin
                JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                JobQueueEntry.Modify();
                Dimensions.Add('JobQueueRescheduledNewTask', Format(false, 9));
            end else begin
                JobQueueEntry.Restart();
                Dimensions.Add('JobQueueRescheduledNewTask', Format(true, 9));
            end
        else begin
            JobQueueEntry."System Task ID" := JobQueueEntry.ScheduleTask();
            JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry.Modify();
            Dimensions.Add('JobQueueRescheduledNewTask', Format(true, 9));
        end;
        JobQueueTelemetry.SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        Telemetry.LogMessage('0000I49', StrSubstNo(JobQueueRescheduledTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions)
    end;

    local procedure JobShouldBeRescheduled(var JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        User: Record User;
        IsHandled: Boolean;
    begin
        User.SetRange("User Security ID", UserSecurityId());
        if User.IsEmpty() then
            exit(false);
        IsHandled := false;
        OnBeforeJobShouldBeRescheduled(JobQueueEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);
        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyClose', '', false, false)]
    local procedure RescheduleJobQueueEntriesOnCompanyOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        [SecurityFiltering(SecurityFilter::Ignored)]
        JobQueueEntry2: Record "Job Queue Entry";
        ScheduledTask: Record "Scheduled Task";
        User: Record User;
    begin
        if not GuiAllowed then
            exit;
        if not (JobQueueEntry2.WritePermission() and JobQueueEntry.ReadPermission()) then
            exit;
        if not JobQueueEntry.HasRequiredPermissions() then
            exit;
        if not TaskScheduler.CanCreateTask() then
            exit;
        User.SetLoadFields("License Type");
        if not User.Get(UserSecurityId()) then
            exit;
        if User."License Type" = User."License Type"::"Limited User" then
            exit;

        ScheduledTask.SetRange("Run Codeunit", Codeunit::"Job Queue User Handler");
        ScheduledTask.SetRange(Company, CompanyName());
        ScheduledTask.SetRange("User ID", UserSecurityId());
        ScheduledTask.SetRange("Is Ready", true);
        if ScheduledTask.IsEmpty() then
            TaskScheduler.CreateTask(Codeunit::"Job Queue User Handler", 0, true, CompanyName, CurrentDateTime + 15000); // Add 15s
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobShouldBeRescheduled(var JobQueueEntry: Record "Job Queue Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

