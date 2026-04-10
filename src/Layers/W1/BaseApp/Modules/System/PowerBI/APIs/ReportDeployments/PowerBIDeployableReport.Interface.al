namespace System.Integration.PowerBI;

/// <summary>
/// Defines the contract for an out-of-box Power BI report that can be deployed to a user's workspace.
/// Partners extend the "Power BI Deployable Report" enum to register their own reports.
/// </summary>
interface "Power BI Deployable Report"
{
    Access = Public;

    /// <summary>
    /// The human-readable name of the report, shown in the Power BI Deployments page.
    /// </summary>
    procedure GetReportName(): Text[200];

    /// <summary>
    /// Populates InStr with the PBIX file content for this report (typically via NavApp.GetResource).
    /// </summary>
    procedure GetStream(var InStr: InStream);

    /// <summary>
    /// The version number of the embedded report. Incrementing this signals that an update is available.
    /// </summary>
    procedure GetVersion(): Integer;

    /// <summary>
    /// Returns the Power BI dataset parameters (name, value) that this report expects to be updated after import.
    /// </summary>
    procedure GetDatasetParameters() Parameters: Dictionary of [Text, Text];
}
