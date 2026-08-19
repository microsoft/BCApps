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
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif

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
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(0);

#endif
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        ItemLedgerEntry.CalcSums(Quantity);

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
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
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
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(0);

#endif
        if ProdOrderComponent."Routing Link Code" = '' then
            exit(0);
        if ProdOrderComponent."Component Supply Method" <> ProdOrderComponent."Component Supply Method"::"Vendor-Supplied" then
            exit(0);

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange("Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange("Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange("Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
        PurchaseLine.CalcSums("Outstanding Qty. (Base)");
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
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;
        if ProdOrderComponent."Component Supply Method" <> ProdOrderComponent."Component Supply Method"::"Vendor-Supplied" then
            exit;

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange("Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange("Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange("Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
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
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(0);

#endif
        if ProdOrderComponent."Routing Link Code" = '' then
            exit(0);
        if ProdOrderComponent."Component Supply Method" <> ProdOrderComponent."Component Supply Method"::"Vendor-Supplied" then
            exit(0);

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange("Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange("Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange("Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
        PurchaseLine.CalcSums("Qty. Received (Base)");
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
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;
        if ProdOrderComponent."Component Supply Method" <> ProdOrderComponent."Component Supply Method"::"Vendor-Supplied" then
            exit;
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange("Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange("Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange("Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
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
