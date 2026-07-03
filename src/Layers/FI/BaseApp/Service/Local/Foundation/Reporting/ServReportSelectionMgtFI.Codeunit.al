// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Reports;

codeunit 13461 "Serv. Report Selection Mgt. FI"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnAfterInitReportSelectionServ', '', true, true)]
    local procedure OnAfterInitReportSelectionServ()
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Quote", Report::"Service Quote") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Quote", '1', Report::"Service Quote (FI)");
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Order", Report::"Service Order") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Order", '1', Report::"Service Order (FI)");
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Invoice", Report::"Service - Invoice") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Invoice", '1', Report::"Service - Invoice (FI)");
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Contract Quote", Report::"Service Contract Quote") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Contract Quote", '1', Report::"Service Contract Quote (FI)");
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Contract", Report::"Service Contract") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Contract", '1', Report::"Service Contract (FI)");
    end;
}