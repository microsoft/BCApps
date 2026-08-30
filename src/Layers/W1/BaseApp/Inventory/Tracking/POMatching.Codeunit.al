// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 5831 "PO Matching"
{
    Access = Public;

    #region Edge factory
    // Edges are unpersisted "Matched Order Line" records

    /// <summary>Builds an invoice-to-order edge.</summary>
    /// <param name="InvoiceLineSystemId">SystemId of the Invoice Line.</param>
    /// <param name="OrderLineSystemId">SystemId of the Order Line.</param>
    /// <param name="QtyToAllocate">The quantity desired to allocate for the match.</param>
    /// <returns>A match that can be used in AddMatch.</returns>
    procedure InvoiceOrderEdge(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; QtyToAllocate: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Document Line SystemId" := InvoiceLineSystemId;
        Edge."Matched Order Line SystemId" := OrderLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
    end;

    /// <summary>Builds an order-to-receipt edge; the invoice is inferred when added if the order has a single invoice edge.</summary>
    /// <param name="OrderLineSystemId">SystemId of the Order Line.</param>
    /// <param name="ReceiptLineSystemId">SystemId of the Receipt Line.</param>
    /// <param name="QtyToAllocate">The quantity desired to allocate for the match.</param>
    /// <returns>A match that can be used in AddMatch.</returns>
    procedure OrderReceiptEdge(OrderLineSystemId: Guid; ReceiptLineSystemId: Guid; QtyToAllocate: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Matched Order Line SystemId" := OrderLineSystemId;
        Edge."Matched Rcpt./Shpt. Line SysId" := ReceiptLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
    end;

    /// <summary>Builds an order-to-receipt edge with an explicit invoice, used to split a receipt across several invoices.</summary>
    /// <param name="InvoiceLineSystemId">SystemId of the Invoice Line.</param>
    /// <param name="OrderLineSystemId">SystemId of the Order Line.</param>
    /// <param name="ReceiptLineSystemId">SystemId of the Receipt Line.</param>
    /// <param name="QtyToAllocate">The quantity desired to allocate for the match.</param>
    /// <returns>A match that can be used in AddMatch.</returns>
    procedure InvoiceOrderReceiptEdge(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; ReceiptLineSystemId: Guid; QtyToAllocate: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Document Line SystemId" := InvoiceLineSystemId;
        Edge."Matched Order Line SystemId" := OrderLineSystemId;
        Edge."Matched Rcpt./Shpt. Line SysId" := ReceiptLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
    end;

    /// <summary>Builds an invoice-to-receipt edge; the order line is derived when added.</summary>
    /// <param name="InvoiceLineSystemId">SystemId of the Invoice Line.</param>
    /// <param name="ReceiptLineSystemId">SystemId of the Receipt Line.</param>
    /// <param name="QtyToAllocate">The quantity desired to allocate for the match.</param>
    /// <returns>A match that can be used in AddMatch.</returns>
    procedure InvoiceReceiptEdge(InvoiceLineSystemId: Guid; ReceiptLineSystemId: Guid; QtyToAllocate: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Document Line SystemId" := InvoiceLineSystemId;
        Edge."Matched Rcpt./Shpt. Line SysId" := ReceiptLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
    end;
    #endregion

    #region Covering receipts
    /// <summary>
    /// Enriches the group by covering each invoice-order allocation with the order line's posted receipts that still have quantity received not invoiced, by adding or growing receipt edges.
    /// </summary>
    /// <param name="POMatchingGroup">The PO matches that we want to suggest receipts for. This parameter gets modified by this procedure by ading the suggested receipt matches.</param>
    procedure SuggestCoveringReceipts(var POMatchingGroup: Codeunit "PO Matching Group")
    var
        OrderLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempIntendedEdge: Record "Matched Order Line" temporary;
        InvoiceableReceipts: Codeunit "Invoiceable Receipts";
        InvoiceLineSystemId, OrderLineSystemId : Guid;
        Missing, Available, Take, NewQty : Decimal;
    begin
        if not POMatchingGroup.GetInvoiceOrderEdges() then
            exit;

        repeat
            InvoiceLineSystemId := POMatchingGroup.GetInvoiceLine();
            OrderLineSystemId := POMatchingGroup.GetOrderLine();
            OrderLine.GetBySystemId(OrderLineSystemId);
            Missing := POMatchingGroup.AllocatedInInvoiceOrderEdge() - POMatchingGroup.SumAllocatedInOrderReceiptEdges();

            if (Missing > 0) and InvoiceableReceipts.Load(OrderLine) then begin
                TempIntendedEdge.Reset();
                TempIntendedEdge.DeleteAll();
                repeat
                    PurchRcptLine := InvoiceableReceipts.GetReceiptLine();
                    Available := InvoiceableReceipts.ReceiptNotInvoiced(POMatchingGroup);
                    if ReceiptHasItemTracking(PurchRcptLine) then begin
                        // An item-tracked receipt can only be taken whole; skip it if it doesn't fit.
                        if (Available > 0) and (Available <= Missing) then
                            Take := Available
                        else
                            Take := 0;
                    end else
                        Take := MinDecimal(Missing, Available);

                    if Take > 0 then begin
                        NewQty := POMatchingGroup.GetReceiptEdgeQuantity(InvoiceLineSystemId, OrderLineSystemId, PurchRcptLine.SystemId) + Take;
                        TempIntendedEdge."Document Line SystemId" := InvoiceLineSystemId;
                        TempIntendedEdge."Matched Order Line SystemId" := OrderLineSystemId;
                        TempIntendedEdge."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
                        TempIntendedEdge."Qty. to Invoice" := NewQty;
                        TempIntendedEdge.Insert();
                        Missing -= Take;
                    end;
                until (Missing <= 0) or (not InvoiceableReceipts.NextReceipt());

                if TempIntendedEdge.FindSet() then
                    repeat
                        POMatchingGroup.AddMatch(
                            InvoiceOrderReceiptEdge(
                                TempIntendedEdge."Document Line SystemId",
                                TempIntendedEdge."Matched Order Line SystemId",
                                TempIntendedEdge."Matched Rcpt./Shpt. Line SysId",
                                TempIntendedEdge."Qty. to Invoice"));
                    until TempIntendedEdge.Next() = 0;
            end;
        until not POMatchingGroup.NextInvoiceOrderEdge();
    end;

    local procedure MinDecimal(A: Decimal; B: Decimal): Decimal
    begin
        if A < B then
            exit(A);
        exit(B);
    end;

    local procedure ReceiptHasItemTracking(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingDocMgmt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgmt.RetrieveEntriesFromShptRcpt(TempItemLedgerEntry, Database::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.", '', 0, PurchRcptLine."Line No.");
        TempItemLedgerEntry.SetFilter("Item Tracking", '<>%1', TempItemLedgerEntry."Item Tracking"::None);
        exit(not TempItemLedgerEntry.IsEmpty());
    end;
    #endregion
}
