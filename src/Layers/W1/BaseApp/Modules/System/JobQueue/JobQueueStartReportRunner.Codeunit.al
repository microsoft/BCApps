namespace System.Threading;

codeunit 9812 "Job Queue Start Report Runner" implements "Job Queue Report Runner"
{
    procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        RecRef: RecordRef;
        RunOnRec: Boolean;
        ShouldModifyNotifyOnSuccess: Boolean;
        OriginalReportOutputType: Enum "Job Queue Report Output Type";
    begin
        RunOnRec := RecRef.Get(JobQueueEntry."Record ID to Process");
        if RunOnRec then
            RecRef.SetRecFilter();

        if RunOnRec then
            REPORT.Execute(ReportID, JobQueueEntry.GetReportParameters(), RecRef)
        else
            REPORT.Execute(ReportID, JobQueueEntry.GetReportParameters());

        ShouldModifyNotifyOnSuccess := JobQueueEntry."Notify On Success" = false;
        OriginalReportOutputType := JobQueueEntry."Report Output Type";
        OnAfterExecuteReport(ReportID, JobQueueEntry, ShouldModifyNotifyOnSuccess);
#if not CLEAN27 // Backwards compatibility
        if JobQueueEntry."Report Output Type" <> OriginalReportOutputType then
            exit; // Any change in report output type is handed in event subscriber
#endif

        if ShouldModifyNotifyOnSuccess then begin
            JobQueueEntry."Notify On Success" := true;
            JobQueueEntry.Modify();
        end;

        OnAfterRunReport(ReportID, JobQueueEntry);
    end;

    /// <summary>
    /// Event triggered before executing a report.
    /// Please note that this procedure does not support changing the report output type.
    /// </summary>
    /// <param name="ReportID">The ID of the report that was executed.</param>
    /// <param name="JobQueueEntry">The job queue entry that is being executed.</param>
    /// <param name="ShouldModifyNotifyOnSuccess">Set to true if the Notify On Success field should be modified to true.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterExecuteReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var ShouldModifyNotifyOnSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}