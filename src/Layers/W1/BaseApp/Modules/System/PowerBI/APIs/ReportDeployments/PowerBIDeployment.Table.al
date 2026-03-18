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
    Access = Internal;
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
