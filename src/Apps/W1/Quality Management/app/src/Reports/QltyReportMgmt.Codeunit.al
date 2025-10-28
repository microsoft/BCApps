// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.Foundation.Reporting;
using Microsoft.QualityManagement.Document;

codeunit 20440 "Qlty. Report Mgmt."
{
    procedure PrintGeneralPurposeInspection(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Quality Management - General Purpose Inspection");
        if ReportSelections.IsEmpty() then
            Report.Run(Report::"Qlty. General Purpose Inspect.", true, true, QltyInspectionTestHeader)
        else
            ReportSelections.PrintReport(ReportSelections.Usage::"Quality Management - General Purpose Inspection", QltyInspectionTestHeader);
    end;

    procedure PrintNonConformance(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Quality Management - Non-Conformance");
        if ReportSelections.IsEmpty() then
            Report.Run(Report::"Qlty. Non-Conformance", true, true, QltyInspectionTestHeader)
        else
            ReportSelections.PrintReport(ReportSelections.Usage::"Quality Management - Non-Conformance", QltyInspectionTestHeader);
    end;

    procedure PrintCertificateOfAnalysis(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Quality Management - Certificate of Analysis");
        if ReportSelections.IsEmpty() then
            Report.Run(Report::"Qlty. Certificate of Analysis", true, true, QltyInspectionTestHeader)
        else
            ReportSelections.PrintReport(ReportSelections.Usage::"Quality Management - Certificate of Analysis", QltyInspectionTestHeader);
    end;
}
