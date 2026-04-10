// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Utilities;

report 8360 "Financial Report Export Email"
{
    Caption = 'Financial Report Export Email';
    DefaultRenderingLayout = Email;

    dataset
    {
        dataitem(Root; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(GreetingTxt; GreetingTxt) { }
            column(ReportContext; ReportContext) { }
            column(AutomatedEmailTxt; AutomatedEmailTxt) { }
            column(Schedules_UrlText; SchedulesLbl) { }
            column(Schedules_Url; SchedulesUrl) { }

            dataitem(FinancialReportSchedule; "Financial Report Schedule")
            {
                column(FinancialReportName; "Financial Report Name") { }
                column(Code; Code) { }
                column(Description; Description) { }

                trigger OnAfterGetRecord()
                var
                    FinReportScheduleFiltered: Record "Financial Report Schedule";
                begin
                    ReportContext := StrSubstNo(ReportContextTxt, FinancialReportSchedule."Financial Report Name", FinancialReportSchedule.Code);
                    FinReportScheduleFiltered := FinancialReportSchedule;
                    FinReportScheduleFiltered.SetRecFilter();
                    SchedulesUrl := GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"Financial Report Schedules", FinReportScheduleFiltered, true);
                end;
            }
        }
    }

    rendering
    {
        layout(Email)
        {
            Caption = 'Financial Report Export Email (Word)';
            LayoutFile = './Finance/FinancialReports/FinancialReportExportEmail.docx';
            Summary = 'The Financial Report Export Email (Word) provides an email body layout.';
            Type = Word;
        }
    }

    var
        GreetingTxt: Label 'Hello,';
        ReportContextTxt: Label 'You are registered to receive the financial report %1 - %2. Please find the financial report attached.', Comment = '%1 = Financial Report Name, %2 = Schedule Code, %3 =  Schedule Description.';
        AutomatedEmailTxt: Label 'Scheduled financial reports are sent automatically and cannot be replied to. You can change when and how you receive financial reports:';
        SchedulesLbl: Label 'Financial Report Schedules';
        ReportContext: Text;
        SchedulesUrl: Text;
}