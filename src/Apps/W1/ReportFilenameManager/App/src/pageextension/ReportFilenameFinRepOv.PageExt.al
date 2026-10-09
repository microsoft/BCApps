// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
pageextension 50112 "Report Filename Fin. Rep. Ov." extends "Acc. Schedule Overview"
{
    // A financial report's workbook, opened from its overview, is the same financial report as the
    // PDF printed from there, and is named by the same pattern. Open in Excel runs Export Acc.
    // Sched. to Excel, a processing-only report no pattern can name, and nothing that report raises
    // says which financial report it is exporting: that lives in a report variable. The overview
    // knows (TempFinancialReport is protected), so it is recorded here, just before the action.
    //
    // SCAFFOLDING, until Base Application raises a file name event where Export Acc. Sched. to
    // Excel downloads the workbook, carrying the financial report - the application ask on the Jira
    // case. With that event this page extension and Report Filename Excel Sub. are not needed.

    actions
    {
        modify(ExportToExcel)
        {
            trigger OnBeforeAction()
            var
                ReportFilenameFinRepSub: Codeunit "Report Filename Fin. Rep. Sub.";
            begin
                ReportFilenameFinRepSub.RecordExcelExport(TempFinancialReport.Name, TempFinancialReport."Financial Report Column Group",
                    TempFinancialReport."Financial Report Row Group" <> '', Rec.GetFilter("Date Filter"));
            end;

            trigger OnAfterAction()
            var
                ReportFilenameFinRepSub: Codeunit "Report Filename Fin. Rep. Sub.";
            begin
                ReportFilenameFinRepSub.ClearExcelExport();
            end;
        }
    }
}
