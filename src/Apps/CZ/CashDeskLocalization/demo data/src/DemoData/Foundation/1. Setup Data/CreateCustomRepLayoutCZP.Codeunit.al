// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Foundation;

using Microsoft.Finance.CashDesk;
using Microsoft.Foundation.Reporting;
using System.Reflection;

codeunit 11774 "Create Custom Rep. Layout CZP"
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
        UpdateReportLayout(Enum::"Report Selection Usage"::"Cash Receipt CZP", '1', Report::"Receipt Cash Document CZP");
        UpdateReportLayout(Enum::"Report Selection Usage"::"Cash Withdrawal CZP", '1', Report::"Withdrawal Cash Document CZP");
        UpdateReportLayout(Enum::"Report Selection Usage"::"Posted Cash Receipt CZP", '1', Report::"Posted Rcpt. Cash Document CZP");
        UpdateReportLayout(Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP", '1', Report::"Posted Wdrl. Cash Document CZP");
    end;

    local procedure UpdateEmailBodySelections()
    begin
        AddEmailBodyLayout(Report::"Receipt Cash Document CZP", CZ11734EmailTok);
        AddEmailBodyLayout(Report::"Posted Rcpt. Cash Document CZP", CZ11736EmailTok);
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
        CZ11734EmailTok: Label 'ReceiptCashDocumentEmail.docx', Locked = true;
        CZ11736EmailTok: Label 'PostedRcptCashDocumentEmail.docx', Locked = true;
}
