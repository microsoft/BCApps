namespace System.Integration.PowerBI;

/// <summary>
/// Enum that lists the possible types of elements returned by API calls to Power BI, when discovering the Power BI reports.
/// </summary>
/// <remarks>
/// When displayed in a tree structure in the Web Client, the tree structure needs to be sorted by this enum. On the other hand, Web Client does not support 
/// descending sorting. So, make sure you keep this enum IDs ordered from the larger group to the smaller group.
/// See also: 1) Bug 335749; 2) Documentation at https://go.microsoft.com/fwlink/?linkid=2206170
/// </remarks>
enum 6313 "Power BI Element Type"
{
    Extensible = false;

    value(10; Workspace)
    {
        Caption = 'Workspace';
    }
    value(20; "Report")
    {
        Caption = 'Report';
    }
    value(25; "Report Visual")
    {
        Caption = 'Report Visual';
    }
    value(30; Dashboard)
    {
        Caption = 'Dashboard';
    }
    value(35; "Dashboard Tile")
    {
        Caption = 'Dashboard Tile';
    }
}