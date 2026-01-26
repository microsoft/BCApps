// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Finance.SalesTax;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Reports;

codeunit 10749 "Serv. Document Print NA"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnInitReportUsage', '', false, false)]
    local procedure InitReportSelection(ReportUsage: Integer)
    begin
        case "Report Selection Usage".FromInteger(ReportUsage) of
            "Report Selection Usage"::"SM.Quote":
                ReplaceReportSelection(Report::"Service Quote", Report::"Service Quote-Sales Tax");
            "Report Selection Usage"::"SM.Order":
                ReplaceReportSelection(Report::"Service Order", Report::"Service Order-Sales Tax");
            "Report Selection Usage"::"SM.Invoice":
                ReplaceReportSelection(Report::"Service - Invoice", Report::"Service Invoice-Sales Tax");
            "Report Selection Usage"::"SM.Credit Memo":
                ReplaceReportSelection(Report::"Service - Credit Memo", Report::"Service Credit Memo-Sales Tax");
            "Report Selection Usage"::"SM.Test":
                ReplaceReportSelection(Report::"Service Document - Test", Report::"Service Document - Test NA");
        end;
    end;

    local procedure ReplaceReportSelection(OldReportID: Integer; NewReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
        ReportSelections2: Record "Report Selections";
    begin
        ReportSelections.SetRange("Report ID", OldReportID);
        if ReportSelections.FindSet() then
            repeat
                ReportSelections2 := ReportSelections;
                ReportSelections2."Report ID" := NewReportID;
                ReportSelections2.Modify();
            until ReportSelections.Next() = 0;
    end;
}