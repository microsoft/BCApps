// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
reportextension 50111 "Report Filename Exp. Excel" extends "Export Acc. Sched. to Excel"
{
    // Bounds the Excel naming to report 29's own run.
    //
    // Open in Excel on a financial report's overview records which financial report report 29 is
    // about to export, just before the action runs it (Report Filename Fin. Rep. Ov.). What it records
    // must name that workbook and nothing else - not a workbook downloaded later in the session after
    // the export failed half way, and not one report 29 writes when it is started from somewhere that
    // recorded nothing. So the workbook is named only while report 29 runs, started by that action:
    // it starts here, and ends here or wherever anything else is rendered (Report Filename Context).
    //
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
