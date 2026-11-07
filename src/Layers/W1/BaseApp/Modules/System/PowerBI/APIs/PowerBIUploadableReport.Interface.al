namespace System.Integration.PowerBI;

interface "Power BI Uploadable Report"
{
    /// <summary>
    /// A stable key identifying this report, used to look up its tracking record.
    /// </summary>
    procedure GetReportKey(): Text[100];

    /// <summary>
    /// The human-readable name of the report.
    /// </summary>
    procedure GetReportName(): Text[100];

    /// <summary>
    /// Populates InStr with the PBIX file content for this report.
    /// </summary>
    procedure GetStream(var InStr: InStream);

    /// <summary>
    /// The version number of this report. Used to determine whether an existing deployment should be overwritten.
    /// </summary>
    procedure GetReportVersion(): Integer;

    /// <summary>
    /// Returns an upload tracker bound to this report's storage mechanism.
    /// </summary>
    procedure GetUploadTracker(var UploadTracker: Interface "Power BI Upload Tracker");

    /// <summary>
    /// Called after the report reaches DataRefreshed status.
    /// Perform any post-upload actions here (e.g. selecting the report for display in a context).
    /// The step runner transitions to Completed after this returns.
    /// </summary>
    procedure FinalizeUpload(var UploadTracker: Interface "Power BI Upload Tracker"; Context: Text[50]);

    /// <summary>
    /// Returns the Power BI dataset parameters (name → value) that this report expects to be updated after import.
    /// </summary>
    procedure GetDatasetParameters() Parameters: Dictionary of [Text, Text];

    /// <summary>
    /// Returns the ID of the Power BI workspace this report should be deployed to.
    /// An empty (null) GUID means the report is deployed to the user's "My Workspace".
    /// </summary>
    procedure GetTargetWorkspaceId() TargetWorkspaceId: Guid
    begin
        // Default implementation: deploy to "My Workspace" (null GUID).
    end;
}
