namespace System.Integration.PowerBI;

/// <summary>
/// Tracks the deployment of each out-of-box Power BI report per company.
/// One record per deployable report enum value.
/// The current upload status is derived from the "Power BI Deployment State" table.
/// </summary>
table 6316 "Power BI Deployment"
{
    Caption = 'Power BI Deployment';
    ReplicateData = false;
    Access = Public;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Report Id"; Enum "Power BI Deployable Report")
        {
            Caption = 'Report Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Import ID"; Guid)
        {
            Caption = 'Import ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Uploaded Report ID"; Guid)
        {
            Caption = 'Uploaded Report ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Report Embed Url"; Text[2048])
        {
            Caption = 'Report Embed Url';
            DataClassification = SystemMetadata;
        }
        field(5; "Dataset Id"; Text[200])
        {
            Caption = 'Dataset Id';
            DataClassification = SystemMetadata;
        }
        field(6; "Deployed Version"; Integer)
        {
            Caption = 'Deployed Version';
            DataClassification = SystemMetadata;
        }
        field(7; "Retry After"; DateTime)
        {
            Caption = 'Retry After';
            DataClassification = SystemMetadata;
        }
        field(8; "Uploaded Report Name"; Text[200])
        {
            Caption = 'Uploaded Report Name';
            DataClassification = SystemMetadata;
        }
        field(9; "Power BI Workspace Id"; Guid)
        {
            Caption = 'Power BI Workspace Id';
            DataClassification = SystemMetadata;
        }
        field(10; "Deployed Workspace Name"; Text[200])
        {
            Caption = 'Deployed Workspace Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Report Id")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Retrieves the latest deployment state record. Returns false if none exists.
    /// </summary>
    procedure GetLatestStateRecord(var PowerBIDeploymentState: Record "Power BI Deployment State"): Boolean
    begin
        PowerBIDeploymentState.SetRange("Report Id", Rec."Report Id");
        exit(PowerBIDeploymentState.FindLast());
    end;

    /// <summary>
    /// Retrieves the latest completed deployment state record. Returns an empty record if there's none
    /// </summary>
    procedure GetLatestCompletedState() PowerBIDeploymentState: Record "Power BI Deployment State"
    begin
        PowerBIDeploymentState.SetRange("Report Id", Rec."Report Id");
        PowerBIDeploymentState.SetRange("Status Reached", Enum::"Power BI Upload Status"::Completed);
        PowerBIDeploymentState.SetRange("Failed At", 0DT);
        if PowerBIDeploymentState.FindLast() then;
    end;

    /// <summary>
    /// Derives the current upload status from the latest Power BI Deployment State record.
    /// This is the single source of truth for deployment status.
    /// </summary>
    procedure GetUploadStatus(): Enum "Power BI Upload Status"
    var
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        if not GetLatestStateRecord(PowerBIDeploymentState) then
            exit(Enum::"Power BI Upload Status"::NotStarted);

        if PowerBIDeploymentState."Failed At" <> 0DT then
            exit(Enum::"Power BI Upload Status"::Failed);

        exit(PowerBIDeploymentState."Status Reached");
    end;

    /// <summary>
    /// Marks the latest state record as failed with the given reason.
    /// If no state record exists yet (e.g. the very first step failed before any transition),
    /// creates one with Status Reached = NotStarted so the failure is never silently lost.
    /// </summary>
    procedure FailCurrentStep(FailedReason: Text; FailedCallstack: Text)
    var
        PowerBIDeploymentState: Record "Power BI Deployment State";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        UploadFailedTelemetryMsg: Label 'Power BI report upload failed.', Locked = true;
    begin
        if not GetLatestStateRecord(PowerBIDeploymentState) then begin
            RecordStep(Enum::"Power BI Upload Status"::NotStarted);
            GetLatestStateRecord(PowerBIDeploymentState);
        end;

        if PowerBIDeploymentState."Failed At" <> 0DT then
            exit;
        PowerBIDeploymentState."Failed At" := CurrentDateTime();
        PowerBIDeploymentState.SetFailedReason(FailedReason);
        PowerBIDeploymentState.SetFailedCallstack(FailedCallstack);
        PowerBIDeploymentState.Modify();

        Session.LogMessage('0000SES', UploadFailedTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    /// <summary>
    /// Resets a deployment by deleting all state records.
    /// After this, GetUploadStatus() returns NotStarted and the aggregator
    /// will include the report as pending work for re-deployment.
    /// Used both for retrying failed deployments and for applying version updates.
    /// </summary>
    procedure ResetDeployment()
    var
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        PowerBIDeploymentState.SetRange("Report Id", Rec."Report Id");
        PowerBIDeploymentState.DeleteAll();
        Clear(Rec."Import ID");
        Clear(Rec."Retry After");
        Rec.Modify(true);
    end;

    local procedure HasNewVersionAvailable(): Boolean
    var
        DeployableReport: Interface "Power BI Deployable Report";
    begin
        if not Enum::"Power BI Deployable Report".Ordinals().Contains(Rec."Report Id".AsInteger()) then
            exit(false);

        DeployableReport := Rec."Report Id";
        exit(DeployableReport.GetVersion() > Rec."Deployed Version");
    end;

    local procedure IsDeploymentInProgress(): Boolean
    begin
        exit(not (Rec.GetUploadStatus() in [
            Enum::"Power BI Upload Status"::Completed,
            Enum::"Power BI Upload Status"::Skipped,
            Enum::"Power BI Upload Status"::PendingDeletion,
            Enum::"Power BI Upload Status"::Failed]));
    end;

    local procedure IsDeployed(): Boolean
    begin
        exit(Rec.GetUploadStatus() = Enum::"Power BI Upload Status"::Completed);
    end;

    procedure GetDeploymentStatus(): Enum "Power BI Deployment Status"
    var
        UploadStatus: Enum "Power BI Upload Status";
    begin
        if not GetDeployment(Rec."Report Id") then
            exit(Enum::"Power BI Deployment Status"::"Not Installed");

        UploadStatus := GetUploadStatus();

        if UploadStatus = Enum::"Power BI Upload Status"::Failed then
            exit(Enum::"Power BI Deployment Status"::Error);

        if IsDeploymentInProgress() then begin
            if UploadStatus = Enum::"Power BI Upload Status"::NotStarted then
                exit(Enum::"Power BI Deployment Status"::Queued);
            exit(Enum::"Power BI Deployment Status"::Installing);
        end;

        if HasNewVersionAvailable() then
            exit(Enum::"Power BI Deployment Status"::"Update Available");

        exit(Enum::"Power BI Deployment Status"::"Up to Date");
    end;

    procedure GetDeploymentOutcome(): Enum "Power BI Deployment Outcome"
    begin
        if not GetDeployment(Rec."Report Id") then
            exit(Enum::"Power BI Deployment Outcome"::"Not Deployed");

        if GetUploadStatus() = Enum::"Power BI Upload Status"::Failed then
            exit(Enum::"Power BI Deployment Outcome"::Failed);

        if IsDeploymentInProgress() then
            exit(Enum::"Power BI Deployment Outcome"::"In Progress");

        if IsDeployed() then
            exit(Enum::"Power BI Deployment Outcome"::Finished);

        exit(Enum::"Power BI Deployment Outcome"::"Not Deployed");
    end;

    local procedure GetDeployment(PowerBIDeployableReport: Enum "Power BI Deployable Report"): Boolean
    begin
        if Rec."Report Id" = PowerBIDeployableReport then
            exit(true);
        Clear(Rec);
        exit(Rec.Get(PowerBIDeployableReport));
    end;

    internal procedure QueueForDeployment(ReportId: Enum "Power BI Deployable Report")
    var
        PowerBIDeployment: Record "Power BI Deployment";
    begin
        if not PowerBIDeployment.Get(ReportId) then begin
            PowerBIDeployment.Init();
            PowerBIDeployment."Report Id" := ReportId;
            PowerBIDeployment.Insert(true);
            exit;
        end;

        PowerBIDeployment.ResetDeployment();
    end;

    /// <summary>
    /// Wipes all local deployment tracking data for the current company across every deployable report.
    /// Reports already uploaded to the Power BI workspace are not touched.
    /// </summary>
    procedure DeleteAllRecords()
    begin
        DeleteAllRecords(CompanyName());
    end;

    /// <summary>
    /// Wipes all local deployment tracking data in the specified company.
    /// Used by subscribers that need to clear records in a different company than the caller's
    /// (e.g. after Copy Company, where the subscriber runs in the source company but must wipe the target).
    /// </summary>
    procedure DeleteAllRecords(InCompany: Text[30])
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIDeploymentState: Record "Power BI Deployment State";
        PBIDeploymentEvents: Codeunit "PBI Deployment Events";
    begin
        PowerBIDeployment.ChangeCompany(InCompany);
        PowerBIDeploymentState.ChangeCompany(InCompany);
        PowerBIDeploymentState.DeleteAll();
        PowerBIDeployment.DeleteAll();

        PBIDeploymentEvents.OnAfterDeleteAllDeploymentRecords(InCompany);
    end;

    /// <summary>
    /// Creates a new state record for the given status.
    /// </summary>
    procedure RecordStep(NewStatus: Enum "Power BI Upload Status")
    var
        PowerBIDeploymentState: Record "Power BI Deployment State";
    begin
        Clear(PowerBIDeploymentState);
        PowerBIDeploymentState."Report Id" := Rec."Report Id";
        PowerBIDeploymentState."Status Reached" := NewStatus;
        PowerBIDeploymentState."Reached At" := CurrentDateTime();
        PowerBIDeploymentState.Insert(true);
    end;
}
