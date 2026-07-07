// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Manufacturing.Document;
codeunit 99001023 "Prod. Def. ProdOrdLine Bind"
{
    EventSubscriberInstance = Manual;

    var
        StoredProdOrder: Record "Production Order";
        StoredProdOrderLine: Record "Prod. Order Line";

    /// <summary>
    /// Stores the production order to return for temporary production order lines.
    /// Must be called before BindSubscription.
    /// </summary>
    internal procedure SetProdOrder(ProdOrder: Record "Production Order")
    begin
        StoredProdOrder := ProdOrder;
    end;

    /// <summary>
    /// Stores the production order line to return for temporary routing lines.
    /// Must be called before BindSubscription.
    /// </summary>
    internal procedure SetProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    begin
        StoredProdOrderLine := ProdOrderLine;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", 'OnBeforeGetProdOrder', '', false, false)]
    local procedure OnBeforeGetProdOrderForProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrder: Record "Production Order")
    begin
        if StoredProdOrder."No." = '' then
            exit;
        if not ProdOrderLine.IsTemporary() then
            exit;
        if ProdOrderLine.Status <> StoredProdOrder.Status then
            exit;
        if ProdOrderLine."Prod. Order No." <> StoredProdOrder."No." then
            exit;
        ProdOrder := StoredProdOrder;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", 'OnBeforeGetDefaultConsumptionBin', '', false, false)]
    local procedure OnBeforeGetDefaultConsumptionBinForProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
        if not ProdOrderComponent.IsTemporary() then
            exit;
        if StoredProdOrderLine."Prod. Order No." = '' then
            exit;
        if ProdOrderComponent.Status <> StoredProdOrderLine.Status then
            exit;
        if ProdOrderComponent."Prod. Order No." <> StoredProdOrderLine."Prod. Order No." then
            exit;
        if ProdOrderComponent."Prod. Order Line No." <> StoredProdOrderLine."Line No." then
            exit;
        IsHandled := false;
        if ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.") then
            exit;
        ProdOrderLine := StoredProdOrderLine;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", 'OnBeforeGetProdOrderNeeds', '', false, false)]
    local procedure OnBeforeGetProdOrderNeedsForProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean; var ProdOrderLine: Record "Prod. Order Line")
    begin
        if StoredProdOrderLine."Prod. Order No." = '' then
            exit;
        if not ProdOrderComponent.IsTemporary() then
            exit;
        if ProdOrderComponent.Status <> StoredProdOrderLine.Status then
            exit;
        if ProdOrderComponent."Prod. Order No." <> StoredProdOrderLine."Prod. Order No." then
            exit;
        if ProdOrderComponent."Prod. Order Line No." <> StoredProdOrderLine."Line No." then
            exit;
        ProdOrderLine := StoredProdOrderLine;
        IsHandled := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", 'OnBeforeGetProdOrderLine', '', false, false)]
    local procedure OnBeforeGetProdOrderLineForRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderLineRead: Boolean)
    begin
        if StoredProdOrderLine."Prod. Order No." = '' then
            exit;
        if ProdOrderRoutingLine."Prod. Order No." <> StoredProdOrderLine."Prod. Order No." then
            exit;
        if ProdOrderRoutingLine.Status <> StoredProdOrderLine.Status then
            exit;
        if ProdOrderRoutingLine."Routing Reference No." <> StoredProdOrderLine."Line No." then
            exit;
        ProdOrderLine := StoredProdOrderLine;
        ProdOrderLineRead := true;
    end;
}