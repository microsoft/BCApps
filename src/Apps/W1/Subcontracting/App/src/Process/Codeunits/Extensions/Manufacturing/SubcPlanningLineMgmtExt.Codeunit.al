// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Routing;

codeunit 99001518 "Subc. Planning Line Mgmt Ext."
{
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
        SubcPriceManagement.ApplySubcontractorPricingToPlanningRouting(ReqLine, RoutingLine, PlanningRoutingLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterFilterLinesWithItemToPlan, '', false, false)]
    local procedure "Transfer Line_OnAfterFilterLinesWithItemToPlan"(var Sender: Record "Transfer Line"; var Item: Record Item; IsReceipt: Boolean; IsSupplyForPlanning: Boolean; var TransferLine: Record "Transfer Line")
    begin
        TransferLine.SetRange("Transfer WIP Item", false);
    end;
}