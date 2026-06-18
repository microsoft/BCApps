// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Enums;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99001512 "Subc. Reporting Triggers Ext"
{
    [EventSubscriber(ObjectType::Report, Report::"Detailed Calculation", OnAfterGetRecordRoutingLineOnBeforeCalcRoutingCostPerUnit, '', false, false)]
    local procedure OnAfterGetRecordRoutingLineOnBeforeCalcCost(var RoutingLine: Record "Routing Line"; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10]; StandardTaskCode: Code[10]; CalculationDate: Date; var DirectUnitCost: Decimal; var IndirectCostPct: Decimal; var OverheadRate: Decimal; var ProdUnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; var IsHandled: Boolean)
    var
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        if RoutingLine.Type <> RoutingLine.Type::"Work Center" then
            exit;

        if not WorkCenter.Get(RoutingLine."Work Center No.") then
            exit;

        if WorkCenter."Subcontractor No." = '' then
            exit;

        SubcontractorPrice."Vendor No." := WorkCenter."Subcontractor No.";
        SubcontractorPrice."Item No." := ItemNo;
        SubcontractorPrice."Standard Task Code" := StandardTaskCode;
        SubcontractorPrice."Work Center No." := WorkCenter."No.";
        SubcontractorPrice."Variant Code" := '';
        SubcontractorPrice."Unit of Measure Code" := BaseUnitOfMeasure;
        SubcontractorPrice."Starting Date" := CalculationDate;
        SubcontractorPrice."Currency Code" := '';
        SubcPriceManagement.SetRoutingPriceListCost(
            SubcontractorPrice,
            WorkCenter,
            DirectUnitCost,
            IndirectCostPct,
            OverheadRate,
            ProdUnitCost,
            UnitCostCalculation,
            1,
            1,
            1);

        IsHandled := true;
    end;
}