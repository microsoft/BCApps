// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

codeunit 99001518 "Subc. Planning Line Mgmt Ext."
{
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
#if not CLEAN27
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Line Management", OnAfterTransferRtngLine, '', false, false)]
#pragma warning restore AL0432
#else
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Planning Line Management", OnAfterTransferRtngLine, '', false, false)]
#endif
    local procedure OnAfterTransferRtngLine(var ReqLine: Record "Requisition Line"; var RoutingLine: Record "Routing Line"; var PlanningRoutingLine: Record "Planning Routing Line")
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcPriceManagement.ApplySubcontractorPricingToPlanningRouting(ReqLine, RoutingLine, PlanningRoutingLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Planning Line Management", OnCreatePlanningComponentFromProdBOMOnBeforeGetPlanningParameters, '', false, false)]
    local procedure TransferComponentSupplyMethod_OnCreatePlanningComponentFromProdBOMOnBeforeGetPlanningParameters(var PlanningComponent: Record "Planning Component"; ProductionBOMLine: Record "Production BOM Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        PlanningComponent."Component Supply Method" := ProductionBOMLine."Component Supply Method";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Planning Line Management", OnTransferBOMOnBeforeUpdatePlanningComp, '', false, false)]
    local procedure IgnorePurchaseComponentsFromSubcontracting_OnTransferBOMOnBeforeUpdatePlanningComp(var ProductionBOMLine: Record "Production BOM Line"; var UpdateCondition: Boolean; var IsHandled: Boolean; var ReqQty: Decimal)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProductionBOMLine."Component Supply Method" = "Component Supply Method"::"Vendor-Supplied" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", OnAfterFilterLinesWithItemToPlan, '', false, false)]
    local procedure ProdOrderComponent_OnAfterFilterLinesWithItemToPlan(var ProdOrderComponent: Record "Prod. Order Component"; var Item: Record Item; IncludeFirmPlanned: Boolean)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderComponent.SetFilter("Component Supply Method", '<>%1', "Component Supply Method"::"Vendor-Supplied");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterFilterLinesWithItemToPlan, '', false, false)]
    local procedure TransferLine_OnAfterFilterLinesWithItemToPlan(var Sender: Record "Transfer Line"; var Item: Record Item; IsReceipt: Boolean; IsSupplyForPlanning: Boolean; var TransferLine: Record "Transfer Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        TransferLine.SetRange("Transfer WIP Item", false);
    end;
}