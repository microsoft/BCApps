namespace System.Integration.PowerBI;

using System.Environment;
using System.Threading;

/// <summary>
/// Encapsulates the logic to deploy and/or delete default Power BI reports. Should be run in background.
/// </summary>
codeunit 6325 "Power BI Report Synchronizer"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ReportAggregator: Codeunit "Power BI Report Aggregator";
        UploadStepRunner: Codeunit "Power BI Upload Step Runner";
        Report: Interface "Power BI Uploadable Report";
        UploadTracker: Interface "Power BI Upload Tracker";
        CurrentStatus: Enum "Power BI Upload Status";
        CustomDimensions: Dictionary of [Text, Text];
        ProgressDialog: Dialog;
        PageId: Text[50];
        IsLastAttempt: Boolean;
        StepIterations: Integer;
        CurrentReportNo: Integer;
        TotalReports: Integer;
        LastErrorText: Text;
    begin
        if not CanSynchronizeReports() then
            exit;
        PageId := CopyStr(Rec."Parameter String", 1, MaxStrLen(PageId));

        IsLastAttempt := Rec."No. of Attempts to Run" >= Rec."Maximum No. of Attempts to Run";

        DeleteMarkedDefaultReports();

        if ReportAggregator.LoadAllPending(PageId) then begin
            Session.LogMessage('0000G1W', StrSubstNo(ReportUploadStartingMsg, ReportAggregator.PendingCount()), Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

            TotalReports := ReportAggregator.PendingCount();
            if GuiAllowed() then
                ProgressDialog.Open(UploadProgressMsg, CurrentReportNo, TotalReports);

            while ReportAggregator.Next(Report) do begin
                CurrentReportNo += 1;
                if GuiAllowed() then
                    ProgressDialog.Update();

                Report.GetUploadTracker(UploadTracker);
                UploadTracker.Load(Report.GetReportKey());
                UploadTracker.Reset();

                Session.LogMessage('0000DZ1', StrSubstNo(UploadingReportTelemetryMsg, Report.GetReportKey()), Verbosity::Normal,
                    DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

                StepIterations := 0;
                repeat
                    StepIterations += 1;
                    if StepIterations > 20 then begin
                        UploadTracker.Fail('Upload exceeded maximum number of steps.', '');
                        UploadTracker.Save();
                        break;
                    end;

                    UploadStepRunner.Configure(Report, UploadTracker, PageId);
                    Commit();
                    ClearLastError();

                    if not UploadStepRunner.Run() then begin
                        LastErrorText := GetLastErrorText();
                        Clear(CustomDimensions);
                        CustomDimensions.Add('Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                        CustomDimensions.Add('ReportKey', Report.GetReportKey());
                        CustomDimensions.Add('CurrentStatus', Format(UploadTracker.GetStatus()));
                        Session.LogMessage('0000SEP', UploadStepFailedTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);

                        UploadTracker.Load(Report.GetReportKey());
                        UploadTracker.Fail(LastErrorText, GetLastErrorCallStack());
                        UploadTracker.Save();
                        break;
                    end;

                    CurrentStatus := UploadTracker.GetStatus();
                until (CurrentStatus in [Enum::"Power BI Upload Status"::Completed, Enum::"Power BI Upload Status"::Failed]) or UploadTracker.HasScheduledRetry();

                if IsLastAttempt then
                    if not (UploadTracker.GetStatus() in [Enum::"Power BI Upload Status"::Completed, Enum::"Power BI Upload Status"::Failed]) then begin
                        UploadTracker.Fail('The report upload did not complete within the maximum number of attempts.', '');
                        UploadTracker.Save();
                    end;

            end;

            if GuiAllowed() then
                ProgressDialog.Close();
        end;

        Commit(); // Persist information on which synchronization steps were performed

        if UserNeedsToSynchronize(PageId) then
            Error(StillNeedToSynchronizeErr); // This will reschedule the job queue
    end;

    local procedure DeleteMarkedDefaultReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
    begin
        // Deletes a batch of default reports that have been marked for deletion for the current user. Reports are
        // deleted from the user's Power BI workspace first, and then removed from the uploads table if that was
        // successful.
        // Should only be called as part of a background session to reduce perf impact.

        if GetReportsToDelete(PowerBIReportUploads) then
            if PowerBIReportUploads.FindSet() then
                repeat
                    PowerBICustomerReports.Reset();
                    PowerBICustomerReports.SetFilter(Id, PowerBIReportUploads."PBIX BLOB ID");
                    repeat
                        if PowerBICustomerReports.Id = PowerBIReportUploads."PBIX BLOB ID" then
                            PowerBICustomerReports.Delete();
                    until PowerBICustomerReports.Next() = 0;
                    PowerBIReportUploads.Delete();
                until PowerBIReportUploads.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UserNeedsToSynchronize(Context: Text[50]): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ReportAggregator: Codeunit "Power BI Report Aggregator";
    begin
        if not CanSynchronizeReports() then
            exit(false);

        // Upload
        if ReportAggregator.LoadAllPending(Context) then
            exit(true);

        // Delete
        if GetReportsToDelete(PowerBIReportUploads) then
            exit(true);

        exit(false)
    end;

    local procedure GetReportsToDelete(var PowerBIReportUploads: Record "Power BI Report Uploads"): Boolean
    begin
        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetRange("User ID", UserSecurityId());
        PowerBIReportUploads.SetRange("Report Upload Status", PowerBIReportUploads."Report Upload Status"::PendingDeletion);

        exit(PowerBIReportUploads.FindSet());
    end;

    internal procedure CanSynchronizeReports(): Boolean
    begin
        exit(EnvironmentInformation.IsSaaSInfrastructure());
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        StillNeedToSynchronizeErr: Label 'The synchronization of your Power BI reports did not complete. We will retry automatically, and this typically fixes the issue.';
        ReportUploadStartingMsg: Label 'Starting to upload %1 Power BI Reports.', Locked = true;
        UploadingReportTelemetryMsg: Label 'Uploading report with internal blob ID: %1.', Locked = true;
        UploadStepFailedTelemetryMsg: Label 'Upload step runner failed for a Power BI report.', Locked = true;
        UploadProgressMsg: Label 'Uploading Power BI report #1 of #2...', Comment = '#1 is the current report number being uploaded, #2 is the total number of reports to upload.';
}
