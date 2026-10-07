// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Service.History;

codeunit 10603 "Serv. Report Selection Mgt. NO"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnAfterInitReportSelectionServ', '', true, true)]
    local procedure OnAfterInitReportSelectionServ()
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Invoice", Report::"Service - Invoice") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Invoice", '1', Report::"Service - Invoice (NO)");
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Credit Memo", Report::"Service - Credit Memo") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Credit Memo", '1', Report::"Service - Credit Memo (NO)");
        if ReportSelectionMgt.ReportSelectionsExist("Report Selection Usage"::"SM.Shipment", Report::"Service - Shipment") then
            ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Shipment", '1', Report::"Service - Shipment (NO)");
    end;
}