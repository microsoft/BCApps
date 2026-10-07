namespace System.Threading;

using System.Environment.Configuration;

codeunit 9805 "Job Queue Start Report Base"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        RunReport(Rec."Object ID to Run", Rec);
    end;

    procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueReportRunner: Interface "Job Queue Report Runner";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunReport(ReportID, JobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        SetReportTimeOut(JobQueueEntry);

        OnBeforeRunReportInterface(ReportID, JobQueueEntry);
        JobQueueReportRunner := JobQueueEntry."Report Output Type";
        JobQueueReportRunner.RunReport(ReportID, JobQueueEntry);
        OnAfterRunReportInterface(ReportID, JobQueueEntry);
        Commit();
    end;

    local procedure SetReportTimeOut(JobQueueEntry: Record "Job Queue Entry")
    var
        ReportSettingsOverride: Record "Report Settings Override";
        TimeoutInSeconds: Integer;
    begin
        if not ReportSettingsOverride.WritePermission then
            exit;
        if JobQueueEntry."Job Timeout" = 0 then
            exit;
        ReportSettingsOverride.LockTable();
        if JobQueueEntry."Job Timeout" = 0 then
            TimeoutInSeconds := JobQueueEntry.DefaultJobTimeout() div 1000
        else
            TimeoutInSeconds := JobQueueEntry."Job Timeout" div 1000;

        if ReportSettingsOverride.Get(JobQueueEntry."Object ID to Run", CompanyName) then begin
            if ReportSettingsOverride.Timeout < TimeoutInSeconds then begin
                ReportSettingsOverride.Timeout := TimeoutInSeconds;
                ReportSettingsOverride.Modify();
            end;
        end else
            if TimeoutInSeconds > 6 * 60 * 60 then begin // Report default is 6hrs
                ReportSettingsOverride."Object ID" := JobQueueEntry."Object ID to Run";
                ReportSettingsOverride."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(ReportSettingsOverride."Company Name"));
                ReportSettingsOverride.Timeout := TimeoutInSeconds;
                ReportSettingsOverride.Insert();
            end;
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReportInterface(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunReportInterface(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}