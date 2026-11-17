// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.FinancialReports;

reportextension 8125 "Report Filename Acc. Schedule" extends "Account Schedule"
{
    // Records the financial report and period from report 25's request page, which closes before
    // the file name is decided. Cancel clears what the print action recorded, so a cancelled print
    // cannot name the next report 25 output.
    // Starting Date and Ending Date are private, so only their validation is noted and the date
    // filter they set is read instead.

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

            // The report's filter variables (GetFilters), not the data item's: OnPreReport is
            // where the data item's filters are set from them (InitAccSched).
            GetFilters(AccScheduleLine);
            FinRepSub.RecordRequestPageClosed(FinancialReportName, ColumnLayoutName, AccScheduleLine.GetFilter("Date Filter"));
            exit(true);
        end;
    }

    var
        FinRepSub: Codeunit "Report Filename Fin. Rep. Sub.";
}
