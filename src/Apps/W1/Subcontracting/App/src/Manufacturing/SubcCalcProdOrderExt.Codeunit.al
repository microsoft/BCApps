// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

codeunit 99001517 "Subc. Calc. Prod. Order Ext."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Prod. Order", OnAfterTransferRoutingLine, '', false, false)]
    local procedure OnAfterTransferRoutingLine(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.UpdateLinkedComponentsAfterRoutingTransfer(ProdOrderLine, RoutingLine, ProdOrderRoutingLine);

        SubcPriceManagement.ApplySubcontractorPricingToProdOrderRouting(ProdOrderLine, RoutingLine, ProdOrderRoutingLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate Prod. Order", OnAfterTransferBOMComponent, '', false, false)]
    local procedure OnAfterTransferBOMComponent(var ProdOrderLine: Record "Prod. Order Line"; var ProductionBOMLine: Record "Production BOM Line"; var ProdOrderComponent: Record "Prod. Order Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
        TransferSubcontractingFieldsBOMComponent(ProductionBOMLine, ProdOrderComponent);
    end;

    local procedure TransferSubcontractingFieldsBOMComponent(var ProductionBOMLine: Record "Production BOM Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
        ProdOrderComponent."Orig. Location Code" := ProdOrderComponent."Location Code";
        ProdOrderComponent."Orig. Bin Code" := ProdOrderComponent."Bin Code";
        ProdOrderComponent."Subcontracting Type" := ProductionBOMLine."Subcontracting Type";

        OnAfterTransferSubcontractingFieldsBOMComponent(ProductionBOMLine, ProdOrderComponent);
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterTransferSubcontractingFieldsBOMComponent(var ProductionBOMLine: Record "Production BOM Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;
}