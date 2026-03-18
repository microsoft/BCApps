namespace System.Integration.PowerBI;

interface "Power BI Upload Tracker"
{
    /// <summary>
    /// Loads or creates a tracking record for the given report and current user.
    /// </summary>
    procedure Load(ReportKey: Text[100]);

    /// <summary>
    /// Clears retry timestamps and resets completed/failed state for a new upload cycle.
    /// Must be called after Load.
    /// </summary>
    procedure Reset();

    /// <summary>
    /// Returns the current upload status.
    /// </summary>
    procedure GetStatus(): Enum "Power BI Upload Status";

    /// <summary>
    /// Advances the upload to the given status.
    /// </summary>
    procedure TransitionTo(NewStatus: Enum "Power BI Upload Status");

    /// <summary>
    /// Stores the import ID returned by Power BI after starting an import.
    /// </summary>
    procedure SetImportId(ImportId: Guid);

    /// <summary>
    /// Returns the import ID for polling import progress.
    /// </summary>
    procedure GetImportId(): Guid;

    /// <summary>
    /// Stores the result of a completed import: report ID, embed URL, and dataset ID.
    /// </summary>
    procedure SetImportResult(UploadedReportId: Guid; EmbedUrl: Text[2048]; DatasetId: Text);

    /// <summary>
    /// Returns the Power BI report ID after import.
    /// </summary>
    procedure GetUploadedReportId(): Guid;

    /// <summary>
    /// Returns the report embed URL after import.
    /// </summary>
    procedure GetEmbedUrl(): Text[2048];

    /// <summary>
    /// Returns the dataset ID after import.
    /// </summary>
    procedure GetDatasetId(): Text;

    /// <summary>
    /// Returns true if the incoming version is newer than the deployed version, meaning the report should be overwritten in Power BI.
    /// </summary>
    procedure ShouldOverwrite(IncomingVersion: Integer): Boolean;

    /// <summary>
    /// Records that a retry should be attempted after the given time.
    /// </summary>
    procedure ScheduleRetry(RetryAfter: DateTime);

    /// <summary>
    /// Returns true if a retry has been scheduled (i.e. the step deferred work to a later attempt).
    /// </summary>
    procedure HasScheduledRetry(): Boolean;

    /// <summary>
    /// Records that the upload has failed with the given error message and callstack.
    /// Implementations may persist the error details and emit telemetry.
    /// </summary>
    procedure Fail(ErrorMessage: Text; ErrorCallStack: Text);

    /// <summary>
    /// Persists any pending changes to the underlying table(s).
    /// </summary>
    procedure Save();
}
