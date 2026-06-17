// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.StandardCost;

codeunit 99001514 "Subc. Calc.StandardCost Ext."
{
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432

#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", OnAfterCalcRtngLineCost, '', false, false)]
    local procedure OnAfterCalcRtngLineCost(RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal; var SLSub: Decimal)
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcPriceManagement.CalcStandardCostOnAfterCalcRtngLineCost(RoutingLine, MfgItemQtyBase, SLSub);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", OnCalcMfgItemOnBeforeCalcRtngCost, '', false, false)]
    local procedure OnCalcMfgItemOnBeforeCalcRtngCost(var Item: Record Item; Level: Integer; var LotSize: Decimal; var MfgItemQtyBase: Decimal)
    var
        SubcSessionState: Codeunit "Subc. Session State";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcSessionState.SetRecordID('OnCalcMfgItemOnBeforeCalcRtngCost', Item.RecordId());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Standard Cost", OnAfterSetProperties, '', false, false)]
    local procedure OnAfterSetProperties(var NewCalculationDate: Date; var NewCalcMultiLevel: Boolean; var NewUseAssemblyList: Boolean; var NewLogErrors: Boolean; var NewStdCostWkshName: Text[50]; var NewShowDialog: Boolean)
    var
        SubcSessionState: Codeunit "Subc. Session State";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcSessionState.SetDate('OnAfterSetProperties', NewCalculationDate);
    end;
}