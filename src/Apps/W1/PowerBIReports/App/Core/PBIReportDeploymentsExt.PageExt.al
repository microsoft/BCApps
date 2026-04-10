namespace Microsoft.PowerBIReports;

using System.Integration.PowerBI;

pageextension 36965 "PBI Report Deployments Ext." extends "Power BI Report Deployments"
{
    layout
    {
        addafter(ReportName)
        {
            field(SetupConfigured; IsSetupConfigured)
            {
                ApplicationArea = All;
                Caption = 'Linked in Setup';
                ToolTip = 'Specifies whether a Power BI report has been configured for this app in the Power BI Reports Setup.';
                Editable = false;
            }
        }
    }

    actions
    {
        addlast(NavigateActions)
        {
            action(OpenPowerBIReportsSetup)
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
            actionref(PowerBIReportsSetup_Promoted; OpenPowerBIReportsSetup)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsSetupConfigured := GetIsSetupConfigured();
    end;

    var
        IsSetupConfigured: Boolean;

    local procedure GetIsSetupConfigured(): Boolean
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        SetupHelper: Codeunit "Power BI Report Setup";
        RecRef: RecordRef;
        FldRef: FieldRef;
        ReportSetup: Interface "PBI Report Setup";
    begin
        if not PowerBIReportsSetup.Get() then
            exit(false);

        if not SetupHelper.FindReportSetup(Rec."Report Id", ReportSetup) then
            exit(false);

        RecRef.GetTable(PowerBIReportsSetup);
        FldRef := RecRef.Field(ReportSetup.GetSetupReportIdFieldNo());
        exit(not IsNullGuid(FldRef.Value()));
    end;
}
