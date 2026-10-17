// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
reportextension 50110 "Report Filename Acc. Schedule" extends "Account Schedule"
{
    // Report 25's request page, where the last of what names a financial report is settled.
    //
    // Cancel. The print actions record which financial report is about to run before the request
    // page opens, because that is the last point at which anything knows - and an administrator
    // can still close that page without running anything. Without the clear below, a cancelled
    // print would leave a financial report recorded, and the next thing rendered through report 25
    // would be named after a report nobody printed.
    //
    // Closed to run. The page closes before the name is decided (measured on 15 September), and at
    // that moment an extension CAN read what it needs, which was once recorded here as impossible:
    // the chosen financial report is a protected variable, and GetFilters is public and hands over
    // the report's own date filter. Measured on 28 September with probe codeunit 50105. So the
    // financial report actually running and the period it runs for are recorded here, by Report
    // Filename Fin. Rep. Sub.
    //
    // Starting Date and Ending Date themselves are not readable - they are private variables - so
    // their validation is only noted, and the date filter they are validated into is what is read.
    //
    // This stays in the shipped app. Base Application could make it unnecessary - Financial Report
    // Mgt.Print forgetting the financial report after AccountSchedule.Run() returns, and report 25
    // passing its financial report and its period into the render as its request page closes - but
    // that is a simplification rather than something the app is missing; see Report Filename Fin.
    // Rep. Sub.

    requestpage
    {
        layout
        {
            modify(StartDate)
            {
                trigger OnAfterValidate()
                begin
                    FinRepSub.NotePeriodDatesValidated();
                end;
            }
            modify(EndDate)
            {
                trigger OnAfterValidate()
                begin
                    FinRepSub.NotePeriodDatesValidated();
                end;
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            AccScheduleLine: Record "Acc. Schedule Line";
            ReportFilenameContext: Codeunit "Report Filename Context";
        begin
            if CloseAction = Action::Cancel then begin
                ReportFilenameContext.ClearRunSubject();
                exit(true);
            end;

            // The report's own date filter, not the data item's: the data item keeps a filter
            // from an earlier run until OnPreReport sets it again (measured), while GetFilters
            // returns what this page has settled.
            GetFilters(AccScheduleLine);
            FinRepSub.RecordRequestPageClosed(FinancialReportName, ColumnLayoutName, AccScheduleLine.GetFilter("Date Filter"));
            exit(true);
        end;
    }

    var
        FinRepSub: Codeunit "Report Filename Fin. Rep. Sub.";
}
