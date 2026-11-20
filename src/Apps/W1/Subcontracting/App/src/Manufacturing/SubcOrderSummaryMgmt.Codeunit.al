// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 20580 "Subc. Order Summary Mgmt."
{
    Access = Internal;

    procedure GetRoutingCount(ProductionOrder: Record "Production Order"): Integer
    var
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        if not CanRead(ProductionOrder) then
            exit(0);
        FilterRouting(ProductionOrder, RoutingLine);
        exit(RoutingLine.Count());
    end;

    procedure GetPurchaseQuantity(ProductionOrder: Record "Production Order"; var HasOpenLine: Boolean) Quantity: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        HasOpenLine := false;
        if not CanRead(ProductionOrder) then
            exit(0);
        FilterPurchase(ProductionOrder, PurchaseLine);
        PurchaseLine.SetLoadFields(PurchaseLine.Quantity, PurchaseLine."Quantity Invoiced");
        if PurchaseLine.FindSet() then
            repeat
                Quantity += PurchaseLine.Quantity;
                HasOpenLine := HasOpenLine or (PurchaseLine.Quantity <> PurchaseLine."Quantity Invoiced");
            until PurchaseLine.Next() = 0;
    end;

    procedure GetReceiptQuantity(ProductionOrder: Record "Production Order"): Decimal
    var
        ReceiptLine: Record "Purch. Rcpt. Line";
    begin
        if not CanRead(ProductionOrder) then
            exit(0);
        FilterReceipt(ProductionOrder, ReceiptLine);
        ReceiptLine.CalcSums(Quantity);
        exit(ReceiptLine.Quantity);
    end;

    procedure GetInvoiceQuantity(ProductionOrder: Record "Production Order"): Decimal
    var
        InvoiceLine: Record "Purch. Inv. Line";
    begin
        if not CanRead(ProductionOrder) then
            exit(0);
        FilterInvoice(ProductionOrder, InvoiceLine);
        InvoiceLine.CalcSums(Quantity);
        exit(InvoiceLine.Quantity);
    end;

    procedure GetWIPQuantity(ProductionOrder: Record "Production Order"; InTransit: Boolean): Decimal
    var
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        if not CanRead(ProductionOrder) then
            exit(0);
        FilterWIP(ProductionOrder, InTransit, WIPEntry);
        WIPEntry.CalcSums("Quantity (Base)");
        exit(WIPEntry."Quantity (Base)");
    end;

    procedure GetTransferCount(ProductionOrder: Record "Production Order"; ReturnOrder: Boolean): Integer
    var
        TransferLine: Record "Transfer Line";
    begin
        if not CanRead(ProductionOrder) then
            exit(0);
        FilterTransfer(ProductionOrder, ReturnOrder, TransferLine);
        exit(TransferLine.Count());
    end;

    procedure IsFullyInvoiced(ProductionOrder: Record "Production Order"): Boolean
    var
        HasOpenLine: Boolean;
    begin
        if not CanRead(ProductionOrder) then
            exit(false);
        GetPurchaseQuantity(ProductionOrder, HasOpenLine);
        exit((GetReceiptQuantity(ProductionOrder) = GetInvoiceQuantity(ProductionOrder)) and not HasOpenLine);
    end;

    procedure ShowRouting(ProductionOrder: Record "Production Order")
    var
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        if not CanRead(ProductionOrder) then
            exit;
        FilterRouting(ProductionOrder, RoutingLine);
        Page.Run(Page::"Prod. Order Routing", RoutingLine);
    end;

    procedure ShowPurchase(ProductionOrder: Record "Production Order")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not CanRead(ProductionOrder) then
            exit;
        FilterPurchase(ProductionOrder, PurchaseLine);
        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    procedure ShowReceipts(ProductionOrder: Record "Production Order")
    var
        ReceiptLine: Record "Purch. Rcpt. Line";
        ReceiptLines: Page "Purch. Receipt Lines";
    begin
        if not CanRead(ProductionOrder) then
            exit;
        FilterReceipt(ProductionOrder, ReceiptLine);
        ReceiptLines.SetTableView(ReceiptLine);
        ReceiptLines.SetSummaryDetail();
        ReceiptLines.Run();
    end;

    procedure ShowInvoices(ProductionOrder: Record "Production Order")
    var
        InvoiceLine: Record "Purch. Inv. Line";
    begin
        if not CanRead(ProductionOrder) then
            exit;
        FilterInvoice(ProductionOrder, InvoiceLine);
        Page.Run(Page::"Subc. Summary Invoice Lines", InvoiceLine);
    end;

    procedure ShowWIP(ProductionOrder: Record "Production Order"; InTransit: Boolean)
    var
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        if not CanRead(ProductionOrder) then
            exit;
        FilterWIP(ProductionOrder, InTransit, WIPEntry);
        Page.Run(Page::"Subc. WIP Ledger Entries", WIPEntry);
    end;

    procedure ShowTransfers(ProductionOrder: Record "Production Order"; ReturnOrder: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        if not CanRead(ProductionOrder) then
            exit;
        FilterTransfer(ProductionOrder, ReturnOrder, TransferLine);
        Page.Run(Page::"Transfer Lines", TransferLine);
    end;

    procedure CanRead(ProductionOrder: Record "Production Order"): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Subc. Application Area Mgmt.";
    begin
        if ProductionOrder."No." = '' then
            exit(false);
        exit(ApplicationAreaMgmt.IsSubcontractingApplicationAreaEnabled());
    end;

    local procedure FilterRouting(ProductionOrder: Record "Production Order"; var RoutingLine: Record "Prod. Order Routing Line")
    begin
        RoutingLine.Reset();
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RoutingLine.SetRange(Subcontracting, true);
    end;

    local procedure FilterPurchase(ProductionOrder: Record "Production Order"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
    end;

    local procedure FilterReceipt(ProductionOrder: Record "Production Order"; var ReceiptLine: Record "Purch. Rcpt. Line")
    begin
        ReceiptLine.Reset();
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
    end;

    local procedure FilterInvoice(ProductionOrder: Record "Production Order"; var InvoiceLine: Record "Purch. Inv. Line")
    begin
        InvoiceLine.Reset();
        InvoiceLine.SetRange("Prod. Order No.", ProductionOrder."No.");
    end;

    local procedure FilterWIP(ProductionOrder: Record "Production Order"; InTransit: Boolean; var WIPEntry: Record "Subcontractor WIP Ledger Entry")
    begin
        WIPEntry.Reset();
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntry.SetRange("In Transit", InTransit);
    end;

    local procedure FilterTransfer(ProductionOrder: Record "Production Order"; ReturnOrder: Boolean; var TransferLine: Record "Transfer Line")
    begin
        TransferLine.Reset();
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetRange("Subc. Return Order", ReturnOrder);
    end;
}
