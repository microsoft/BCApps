namespace Microsoft.PowerBIReports;

using System.Integration.PowerBI;

page 8102 "Rev. by Salesperson Power BI"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    PageType = UserControlHost;
    Caption = 'Revenue by Salesperson';
    AboutTitle = 'About Revenue by Salesperson';
    AboutText = 'The Revenue by Salesperson report breaks down subscription performance by Salesperson, highlighting metrics such as Monthly Recurring Revenue, Monthly Recurring Cost, Monthly Net Profit Amount and Churn.';

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
        ReportPageLbl: Label '926fa2c13070086cb999', Locked = true;

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

