// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.CashFlow;

using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.CashFlow.Worksheet;
using Microsoft.Foundation.Enums;

codeunit 6493 "Serv. CashFlow Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"Cash Flow Availability Lines", 'OnAfterCalcLine', '', false, false)]
    local procedure OnAfterCalcLine(var CashFlowAvailabilityBuffer: Record "Cash Flow Availability Buffer"; var CashFlowForecast: Record "Cash Flow Forecast"; RoundingFactor: Option)
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        CashFlowAvailabilityBuffer."Service Orders" :=
            MatrixMgt.RoundAmount(
                CashFlowForecast.CalcSourceTypeAmount("Cash Flow Source Type"::"Service Orders"),
                "Analysis Rounding Factor".FromInteger(RoundingFactor));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Flow Worksheet Line", 'OnCalculateCFAmountAndCFDateOnAfterAssignApplyCFPaymentTerm', '', false, false)]
    local procedure OnCalculateCFAmountAndCFDateOnAfterAssignApplyCFPaymentTerm(CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var ApplyCFPaymentTerm: Boolean)
    begin
        if CashFlowWorksheetLine."Source Type" = CashFlowWorksheetLine."Source Type"::"Service Orders" then
            ApplyCFPaymentTerm := true;
    end;
}
