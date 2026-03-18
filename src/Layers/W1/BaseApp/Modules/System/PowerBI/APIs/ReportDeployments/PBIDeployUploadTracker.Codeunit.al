namespace System.Integration.PowerBI;

/// <summary>
/// Implements the Power BI Upload Tracker interface backed by the Power BI Deployment
/// and Power BI Deployment State tables. Used for enum-based deployable reports.
/// The current upload status is derived from the state records, not stored on the deployment table.
/// </summary>
codeunit 6349 "PBI Deploy. Upload Tracker" implements "Power BI Upload Tracker"
{
    Access = Internal;

    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        CurrentReportId: Enum "Power BI Deployable Report";
        CurrentStatus: Enum "Power BI Upload Status";
        IncomingVersion: Integer;
        InvalidDeployableReportKeyErr: Label 'Deployable report was configured with an incorrect ReportKey';
        NoProgressOnDeploymentTelemetryMsg: Label 'Deployment was not modified.', Locked = true;
        TransitionToFailStateWithoutUsingFailMsg: Label 'Transition to a failed state directly, without calling the Fail procedure.', Locked = true;

    procedure Load(ReportKey: Text[100])
    var
        DeployableReport: Interface "Power BI Deployable Report";
    begin
        if not GetDeployableReportFromReportKey(ReportKey, CurrentReportId) then
            Error(InvalidDeployableReportKeyErr); // Only possible if a deployable report was scheduled and at the time of running the JQ the deployable is no longer available (extension uninstalled)

        DeployableReport := CurrentReportId;
        IncomingVersion := DeployableReport.GetVersion();

        Clear(PowerBIDeployment);
        // The deployment record is created to signal that a deployment is required; it must already exist at this point.
        PowerBIDeployment.Get(CurrentReportId);
        CurrentStatus := PowerBIDeployment.GetUploadStatus();
    end;

    procedure Reset()
    var
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        Clear(PowerBIDeployment."Retry After");
        // If re-uploading a completed or failed report (e.g. version upgrade), reset for new cycle
        if CurrentStatus in [
            Enum::"Power BI Upload Status"::Completed,
            Enum::"Power BI Upload Status"::Failed]
        then begin
            PowerBIDeploymentState.SetRange("Report Id", CurrentReportId);
            PowerBIDeploymentState.DeleteAll();
            CurrentStatus := Enum::"Power BI Upload Status"::NotStarted;
        end;
    end;

    procedure GetStatus(): Enum "Power BI Upload Status"
    begin
        exit(CurrentStatus);
    end;

    procedure TransitionTo(NewStatus: Enum "Power BI Upload Status")
    begin
        if NewStatus = Enum::"Power BI Upload Status"::Failed then begin
            Session.LogMessage('0000SEQ', TransitionToFailStateWithoutUsingFailMsg, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            Fail('', '');
            exit;
        end;

        PowerBIDeployment.RecordStep(NewStatus);
        CurrentStatus := NewStatus;
    end;

    procedure Fail(ErrorMessage: Text; ErrorCallStack: Text)
    begin
        PowerBIDeployment.FailCurrentStep(ErrorMessage, ErrorCallStack);
        CurrentStatus := Enum::"Power BI Upload Status"::Failed;
    end;

    procedure SetImportId(ImportId: Guid)
    begin
        PowerBIDeployment."Import ID" := ImportId;
    end;

    procedure GetImportId(): Guid
    begin
        exit(PowerBIDeployment."Import ID");
    end;

    procedure SetImportResult(UploadedReportId: Guid; EmbedUrl: Text[2048]; DatasetId: Text)
    begin
        PowerBIDeployment."Uploaded Report ID" := UploadedReportId;
        PowerBIDeployment."Report Embed Url" := EmbedUrl;
        PowerBIDeployment."Dataset Id" := CopyStr(DatasetId, 1, MaxStrLen(PowerBIDeployment."Dataset Id"));
    end;

    procedure GetUploadedReportId(): Guid
    begin
        exit(PowerBIDeployment."Uploaded Report ID");
    end;

    procedure GetEmbedUrl(): Text[2048]
    begin
        exit(PowerBIDeployment."Report Embed Url");
    end;

    procedure GetDatasetId(): Text
    begin
        exit(PowerBIDeployment."Dataset Id");
    end;

    procedure ShouldOverwrite(IncomingReportVersion: Integer): Boolean
    begin
        exit(IncomingReportVersion > PowerBIDeployment."Deployed Version");
    end;

    procedure ScheduleRetry(RetryAfter: DateTime)
    begin
        PowerBIDeployment.Validate("Retry After", RetryAfter);
    end;

    procedure HasScheduledRetry(): Boolean
    begin
        exit(PowerBIDeployment."Retry After" <> 0DT);
    end;

    procedure Save()
    begin
        if CurrentStatus = Enum::"Power BI Upload Status"::Completed then
            PowerBIDeployment."Deployed Version" := IncomingVersion;

        if not PowerBIDeployment.Modify(true) then
            Session.LogMessage('0000SER', NoProgressOnDeploymentTelemetryMsg, Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    [TryFunction]
    internal procedure GetDeployableReportFromReportKey(ReportKey: Text[100]; var DeployableReportType: Enum "Power BI Deployable Report")
    var
        OrdinalValue: Integer;
    begin
        Evaluate(OrdinalValue, ReportKey);
        DeployableReportType := Enum::"Power BI Deployable Report".FromInteger(OrdinalValue);
    end;
}
