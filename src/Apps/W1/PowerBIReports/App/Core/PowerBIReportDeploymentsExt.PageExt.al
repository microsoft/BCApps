namespace Microsoft.PowerBIReports;

using System.Integration.PowerBI;

pageextension 36965 "PBI Report Deployments Ext." extends "Power BI Report Deployments"
{
    actions
    {
        addlast(NavigateActions)
        {
            action(PowerBIReportsSetup)
            {
                ApplicationArea = All;
                Caption = 'Power BI Reports Setup';
                Image = Setup;
                RunObject = page "PowerBI Reports Setup";
                ToolTip = 'Opens the Power BI Reports Setup page.';
            }
        }
        addlast(Category_Category2)
        {
            actionref(PowerBIReportsSetup_Promoted; PowerBIReportsSetup)
            {
            }
        }
    }
}
