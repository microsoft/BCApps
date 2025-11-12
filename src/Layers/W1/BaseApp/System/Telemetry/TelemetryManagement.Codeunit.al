namespace System.Telemetry;

using System.Environment;
using System.Environment.Configuration;
using System.Threading;

codeunit 1350 "Telemetry Management"
{
    var
        TelemetryJobCreatedTxt: Label 'A daily job for sending telemetry is created.', Locked = true;
        DailyTelemetryCategoryTxt: Label 'AL Daily Telemetry Job.', Locked = true;

    trigger OnRun()
    begin
        OnSendDailyTelemetry();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure ScheduleDailyTelemetryAfterCompanyOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        [SecurityFiltering(SecurityFilter::Ignored)]
        JobQueueEntry2: Record "Job Queue Entry";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;
        if not (Session.CurrentClientType() in [ClientType::Web, ClientType::Desktop, ClientType::Tablet, ClientType::Phone]) then
            exit;
        if not TaskScheduler.CanCreateTask() then
            exit;
        if not (JobQueueEntry.ReadPermission() and JobQueueEntry2.WritePermission()) then
            exit;
        if not JobQueueEntry.HasRequiredPermissions() then
            exit;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Telemetry Management");
        JobQueueEntry.SetRange("Recurring Job", true);
        if JobQueueEntry.FindFirst() then begin
            if JobQueueEntry.Status in [JobQueueEntry.Status::"On Hold", JobQueueEntry.Status::Error] then
                JobQueueEntry.Restart();
            exit;
        end;

        JobQueueEntry.InitRecurringJob(24 * 60); // one day
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Telemetry Management";
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today() + 1, 0T);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);

        Session.LogMessage('0000ADZ', TelemetryJobCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DailyTelemetryCategoryTxt);
    end;

#pragma warning disable AS0101
    [IntegrationEvent(false, false, true)]
    local procedure OnSendDailyTelemetry()
    begin
    end;
#pragma warning restore AS0101
}

