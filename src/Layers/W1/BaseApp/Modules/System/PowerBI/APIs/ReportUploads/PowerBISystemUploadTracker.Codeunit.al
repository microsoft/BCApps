namespace System.Integration.PowerBI;

/// <summary>
/// Wraps the existing Power BI Report Uploads table (6307) behind the Power BI Upload Tracker interface.
/// Used by system table reports and customer reports.
/// </summary>
codeunit 6322 "Power BI System Upload Tracker" implements "Power BI Upload Tracker"
{
    Access = Internal;

    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        CurrentDatasetId: Text;
        GPEnabled: Boolean;
        NoProgressOnUploadTelemetryMsg: Label 'Upload was not modified.', Locked = true;

    internal procedure SetGPEnabled(NewGPEnabled: Boolean)
    begin
        GPEnabled := NewGPEnabled;
    end;

    procedure Load(ReportKey: Text[100])
    var
        BlobId: Guid;
    begin
        Evaluate(BlobId, ReportKey);

        Clear(PowerBIReportUploads);

        if PowerBIReportUploads.Get(BlobId, UserSecurityId()) then
            exit;

        PowerBIReportUploads.Init();
        PowerBIReportUploads."User ID" := UserSecurityId();
        PowerBIReportUploads."PBIX BLOB ID" := BlobId;
        PowerBIReportUploads.IsGP := GPEnabled;
        PowerBIReportUploads.Insert(true);
    end;

    procedure Reset()
    begin
        Clear(PowerBIReportUploads."Retry After");
    end;

    procedure GetStatus(): Enum "Power BI Upload Status"
    begin
        exit(PowerBIReportUploads."Report Upload Status");
    end;

    procedure TransitionTo(NewStatus: Enum "Power BI Upload Status")
    begin
        PowerBIReportUploads.Validate("Report Upload Status", NewStatus);
    end;

    procedure Fail(ErrorMessage: Text; ErrorCallStack: Text)
    begin
        PowerBIReportUploads.Validate("Report Upload Status", Enum::"Power BI Upload Status"::Failed);
    end;

    procedure SetImportId(ImportId: Guid)
    begin
        PowerBIReportUploads."Import ID" := ImportId;
    end;

    procedure GetImportId(): Guid
    begin
        exit(PowerBIReportUploads."Import ID");
    end;

    procedure SetImportResult(UploadedReportId: Guid; EmbedUrl: Text[2048]; DatasetId: Text)
    begin
        PowerBIReportUploads."Uploaded Report ID" := UploadedReportId;
        PowerBIReportUploads."Report Embed Url" := EmbedUrl;
        CurrentDatasetId := DatasetId;
    end;

    procedure GetUploadedReportId(): Guid
    begin
        exit(PowerBIReportUploads."Uploaded Report ID");
    end;

    procedure GetEmbedUrl(): Text[2048]
    begin
        exit(PowerBIReportUploads."Report Embed Url");
    end;

    procedure GetDatasetId(): Text
    begin
        // Not persisted in the existing table; held in memory for the duration of a single JQ run.
        exit(CurrentDatasetId);
    end;

    procedure ShouldOverwrite(IncomingVersion: Integer): Boolean
    begin
        exit(IncomingVersion > PowerBIReportUploads."Deployed Version");
    end;

    procedure ScheduleRetry(RetryAfter: DateTime)
    begin
        PowerBIReportUploads.Validate("Retry After", RetryAfter);
    end;

    procedure HasScheduledRetry(): Boolean
    begin
        exit(PowerBIReportUploads."Retry After" <> 0DT);
    end;

    procedure Save()
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
    begin
        if not PowerBIReportUploads.Modify(true) then
            Session.LogMessage('0000KWS', NoProgressOnUploadTelemetryMsg, Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;
}
