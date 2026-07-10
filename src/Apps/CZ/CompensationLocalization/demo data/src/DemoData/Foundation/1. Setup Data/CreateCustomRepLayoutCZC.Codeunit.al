// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Foundation;

using Microsoft.Finance.Compensations;
using Microsoft.Foundation.Reporting;
using System.Reflection;

codeunit 11767 "Create Custom Rep. Layout CZC"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnRun()
    begin
        UpdateReportSelections();
        UpdateEmailBodySelections();
    end;

    local procedure UpdateReportSelections()
    begin
        UpdateReportLayout(Enum::"Report Selection Usage"::"Compensation CZC", '1', Report::"Compensation CZC");
        UpdateReportLayout(Enum::"Report Selection Usage"::"Posted Compensation CZC", '1', Report::"Posted Compensation CZC");
    end;

    local procedure UpdateEmailBodySelections()
    begin
        AddEmailBodyLayout(Report::"Compensation CZC", CZ31270EmailTok);
        AddEmailBodyLayout(Report::"Posted Compensation CZC", CZ31271EmailTok);
    end;

    local procedure UpdateReportLayout(Usage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(Usage, Sequence) then
            exit;

        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Modify(true);
    end;

    local procedure AddEmailBodyLayout(ReportID: Integer; ReportLayoutName: Text[250])
    var
        ReportSelections: Record "Report Selections";
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange(Name, ReportLayoutName);
        if ReportLayoutList.IsEmpty() then
            exit;

        ReportSelections.SetRange("Report ID", ReportID);
        if ReportSelections.FindFirst() then begin
            ReportSelections.Validate("Use for Email Body", true);
            ReportSelections.Validate("Email Body Layout Name", CopyStr(ReportLayoutName, 1, MaxStrLen(ReportSelections."Email Body Layout Name")));
            ReportSelections.Modify(true);
        end;
    end;

    var
        CZ31270EmailTok: Label 'CompensationEmail.docx', Locked = true;
        CZ31271EmailTok: Label 'PostedCompensationEmail.docx', Locked = true;
}
