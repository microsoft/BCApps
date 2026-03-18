namespace System.Integration.PowerBI;

/// <summary>
/// Represents the high-level deployment status of a deployable Power BI report,
/// as shown in the Power BI Report Deployments page.
/// </summary>
enum 6317 "Power BI Deployment Status"
{
    Extensible = false;
    Access = Internal;

    value(0; "Not Installed")
    {
        Caption = 'Not installed';
    }
    value(1; Queued)
    {
        Caption = 'Queued';
    }
    value(2; Installing)
    {
        Caption = 'Installing';
    }
    value(3; "Up to Date")
    {
        Caption = 'Up to date';
    }
    value(4; "Update Available")
    {
        Caption = 'Update available';
    }
    value(5; Error)
    {
        Caption = 'Error';
    }
}
