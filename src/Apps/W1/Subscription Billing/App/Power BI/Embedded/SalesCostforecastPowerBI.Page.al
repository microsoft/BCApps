namespace Microsoft.PowerBIReports;

using System.Integration.PowerBI;

page 8108 "Sales Cost forecast Power BI"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    PageType = UserControlHost;
    Caption = 'Sales and Cost forecast';
    AboutTitle = 'About Sales and Cost forecast';
    AboutText = 'The Sales and Cost forecast report provides the forecast of Monthly Recurring Revenue and Monthly Recurring Cost for the future months and years. This report provides detailed insights into which salespersons and customers are driving future subscription performance.';

    layout
    {
        area(Content)
        {
            usercontrol(PowerBIAddin; PowerBIManagement)
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    SetupHelper.InitializeEmbeddedAddin(CurrPage.PowerBIAddin, ReportId, ReportPageLbl);
                end;

                trigger ReportLoaded(ReportFilters: Text; ActivePageName: Text; ActivePageFilters: Text; CorrelationId: Text)
                begin
                    SetupHelper.LogReportLoaded(CorrelationId);
                end;

                trigger ErrorOccurred(Operation: Text; ErrorText: Text)
                begin
                    SetupHelper.LogError(Operation, ErrorText);
                    SetupHelper.ShowPowerBIErrorNotification(Operation, ErrorText);
                end;
            }
        }
    }

    var
        SetupHelper: Codeunit "Power BI Report Setup";
        ReportId: Guid;
        ReportPageLbl: Label 'c9cd438d95e60a070e76', Locked = true;

    trigger OnOpenPage()
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
        SetupHelper.EnsureUserAcceptedPowerBITerms();
#if not CLEAN28
#pragma warning disable AL0801
#endif
        ReportId := SetupHelper.GetReportIdAndEnsureSetup(CurrPage.Caption(), PowerBIReportsSetup.FieldNo("Subscription Billing Report Id"));
#if not CLEAN28
#pragma warning restore AL0801
#endif
    end;
}

