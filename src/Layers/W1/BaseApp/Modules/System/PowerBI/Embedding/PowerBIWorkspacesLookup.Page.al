namespace System.Integration.PowerBI;

/// <summary>
/// Lookup page used to pick the Power BI workspace that deployable reports are deployed to.
/// It only lists workspaces the user can write to, plus the "My Workspace" option (represented by a null ID).
/// </summary>
page 6328 "Power BI Workspaces Lookup"
{
    Caption = 'Power BI Workspaces';
    PageType = List;
    SourceTable = "Power BI Selection Element";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Workspaces)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the Power BI workspace. My Workspace deploys the reports to the current user''s personal workspace.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            Initialize();
    end;

    /// <summary>
    /// Initializes the page by populating the source record with the workspaces the user can deploy to.
    /// </summary>
    procedure Initialize()
    var
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
    begin
        PowerBIWorkspaceMgt.GetWritableWorkspaces(Rec);
    end;
}
