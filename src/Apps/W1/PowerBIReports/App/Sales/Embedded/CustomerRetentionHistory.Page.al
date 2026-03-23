// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using System.Integration.PowerBI;

page 37114 "Customer Retention History"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    PageType = UserControlHost;
    Caption = 'Customer Retention History';
    AboutTitle = 'About Customer Retention History';
    AboutText = 'The Customer Retention History page provides historical insights into customer retention metrics, allowing analysis of trends over time.';

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
#pragma warning disable AA0240 // False positive
        ReportPageLbl: Label '06ff9ed41058740a1b15', Locked = true;
#pragma warning restore AA0240

    trigger OnOpenPage()
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
        SetupHelper.EnsureUserAcceptedPowerBITerms();
        ReportId := SetupHelper.GetReportIdAndEnsureSetup(CurrPage.Caption(), PowerBIReportsSetup.FieldNo("Sales Report Id"));
    end;
}

