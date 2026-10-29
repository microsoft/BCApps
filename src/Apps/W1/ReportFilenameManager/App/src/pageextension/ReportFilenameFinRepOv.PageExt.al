// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.FinancialReports;

pageextension 8127 "Report Filename Fin. Rep. Ov." extends "Acc. Schedule Overview"
{
    // Records which financial report Open in Excel (using layout) exports, since Export Acc. Sched.
    // to Excel does not expose it. TempFinancialReport is protected, so this extension can read it.
    // SCAFFOLDING until Base Application raises a file name event in Export Acc. Sched. to Excel
    // carrying the financial report (ask 4); then this and Report Filename Excel Sub. can be removed.

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
