// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.FinancialReports;

reportextension 8126 "Report Filename Exp. Excel" extends "Export Acc. Sched. to Excel"
{
    // Limits the Excel naming recorded by Report Filename Fin. Rep. Ov. to this run of report 29,
    // so a later workbook in the session is not named after it.
    // SCAFFOLDING with Report Filename Excel Sub. and Report Filename Fin. Rep. Ov., until Base
    // Application raises a file name event in report 29 carrying the financial report (ask 4).

    trigger OnPreReport()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.StartExcelExportRun();
    end;

    trigger OnPostReport()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.EndExcelExportRun();
    end;
}
