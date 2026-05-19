// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 99001562 "Subc. Comp. Factbox Mgmt."
{
    /// <summary>
    /// Returns the total consumption quantity posted for the given production order component via its linked routing operation.
    /// </summary>
    /// <param name="ProdOrderComponent">The production order component to sum consumption entries for.</param>
    /// <returns>The absolute sum of consumption item ledger entry quantities for the component.</returns>
    procedure GetConsumptionQtyFromProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        ItemLedgerEntry.SetCurrentKey(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order No.", ItemLedgerEntry."Order Line No.", ItemLedgerEntry."Entry Type", ItemLedgerEntry."Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Operation No.", ProdOrderRoutingLine."Operation No.");
        ItemLedgerEntry.CalcSums(ItemLedgerEntry.Quantity);

        exit(Abs(ItemLedgerEntry.Quantity));
    end;

    /// <summary>
    /// Opens the Item Ledger Entries page filtered to consumption entries for the given production order component.
    /// </summary>
    /// <param name="ProdOrderComponent">The production order component to show consumption entries for.</param>
    procedure ShowConsumptionQtyFromProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        ItemLedgerEntry.SetCurrentKey(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order No.", ItemLedgerEntry."Order Line No.", ItemLedgerEntry."Entry Type", ItemLedgerEntry."Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Operation No.", ProdOrderRoutingLine."Operation No.");
        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
    end;

    /// <summary>
    /// Returns the total outstanding base quantity on subcontracting purchase lines for the given production order component.
    /// </summary>
    /// <param name="ProdOrderComponent">The production order component to calculate outstanding quantity for.</param>
    /// <returns>The sum of Outstanding Qty. (Base) on matching purchase lines, or 0 if not a purchase subcontracting component.</returns>
    procedure GetPurchOrderOutstandingQtyBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit(0);
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit(0);

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        PurchaseLine.CalcSums(PurchaseLine."Outstanding Qty. (Base)");
        exit(PurchaseLine."Outstanding Qty. (Base)");
    end;

    /// <summary>
    /// Opens the Purchase Lines page filtered to outstanding subcontracting purchase lines for the given production order component.
    /// </summary>
    /// <param name="ProdOrderComponent">The production order component to filter purchase lines by.</param>
    procedure ShowPurchOrderOutstandingQtyBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit;

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    /// <summary>
    /// Returns the total received base quantity on subcontracting purchase lines for the given production order component.
    /// </summary>
    /// <param name="ProdOrderComponent">The production order component to calculate received quantity for.</param>
    /// <returns>The sum of Qty. Received (Base) on matching purchase lines, or 0 if not a purchase subcontracting component.</returns>
    procedure GetPurchOrderQtyReceivedBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit(0);
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit(0);

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        PurchaseLine.CalcSums(PurchaseLine."Qty. Received (Base)");
        exit(PurchaseLine."Qty. Received (Base)");
    end;

    /// <summary>
    /// Opens the Purchase Lines page filtered to subcontracting purchase lines for the given production order component to show received quantities.
    /// </summary>
    /// <param name="ProdOrderComponent">The production order component to filter purchase lines by.</param>
    procedure ShowPurchOrderQtyReceivedBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit;
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    local procedure GetProdOrderRtngLineFromProdOrderComp(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.") then
            exit;

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        if ProdOrderRoutingLine.IsEmpty() then
            exit;

        ProdOrderRoutingLine.FindFirst();
    end;
}
