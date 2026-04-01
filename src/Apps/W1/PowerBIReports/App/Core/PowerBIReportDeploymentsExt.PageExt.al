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

    trigger OnAfterGetRecord()
    begin
        IsSetupConfigured := GetIsSetupConfigured();
    end;

    var
        IsSetupConfigured: Boolean;

    local procedure GetIsSetupConfigured(): Boolean
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
        if not PowerBIReportsSetup.Get() then
            exit(false);

        case Rec."Report Id" of
            Enum::"Power BI Deployable Report"::"Finance App":
                exit(not IsNullGuid(PowerBIReportsSetup."Finance Report Id"));
            Enum::"Power BI Deployable Report"::"Sales App":
                exit(not IsNullGuid(PowerBIReportsSetup."Sales Report Id"));
            Enum::"Power BI Deployable Report"::"Purchases App":
                exit(not IsNullGuid(PowerBIReportsSetup."Purchases Report Id"));
            Enum::"Power BI Deployable Report"::"Inventory App":
                exit(not IsNullGuid(PowerBIReportsSetup."Inventory Report Id"));
            Enum::"Power BI Deployable Report"::"Inventory Valuation App":
                exit(not IsNullGuid(PowerBIReportsSetup."Inventory Val. Report Id"));
            Enum::"Power BI Deployable Report"::"Manufacturing App":
                exit(not IsNullGuid(PowerBIReportsSetup."Manufacturing Report Id"));
            Enum::"Power BI Deployable Report"::"Projects App":
                exit(not IsNullGuid(PowerBIReportsSetup."Projects Report Id"));
        end;

        exit(false);
    end;
}
