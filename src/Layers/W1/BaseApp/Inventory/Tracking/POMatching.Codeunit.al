// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

codeunit 5831 "PO Matching"
{
    Access = Public;

    #region Edge factory
    // Edges are unpersisted "Matched Order Line" records

    /// <summary>Builds an invoice-to-order edge.</summary>
    internal procedure InvoiceOrderEdge(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; QtyToAllocate: Decimal; QtyToAllocateBase: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Document Line SystemId" := InvoiceLineSystemId;
        Edge."Matched Order Line SystemId" := OrderLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
        Edge."Qty. to Invoice (Base)" := QtyToAllocateBase;
    end;

    /// <summary>Builds an order-to-receipt edge; the invoice is inferred when added if the order has a single invoice edge.</summary>
    internal procedure OrderReceiptEdge(OrderLineSystemId: Guid; ReceiptLineSystemId: Guid; QtyToAllocate: Decimal; QtyToAllocateBase: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Matched Order Line SystemId" := OrderLineSystemId;
        Edge."Matched Rcpt./Shpt. Line SysId" := ReceiptLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
        Edge."Qty. to Invoice (Base)" := QtyToAllocateBase;
    end;

    /// <summary>Builds an order-to-receipt edge with an explicit invoice, used to split a receipt across several invoices.</summary>
    internal procedure InvoiceOrderReceiptEdge(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; ReceiptLineSystemId: Guid; QtyToAllocate: Decimal; QtyToAllocateBase: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Document Line SystemId" := InvoiceLineSystemId;
        Edge."Matched Order Line SystemId" := OrderLineSystemId;
        Edge."Matched Rcpt./Shpt. Line SysId" := ReceiptLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
        Edge."Qty. to Invoice (Base)" := QtyToAllocateBase;
    end;

    /// <summary>Builds an invoice-to-receipt edge; the order line is derived when added.</summary>
    internal procedure InvoiceReceiptEdge(InvoiceLineSystemId: Guid; ReceiptLineSystemId: Guid; QtyToAllocate: Decimal; QtyToAllocateBase: Decimal) Edge: Record "Matched Order Line"
    begin
        Edge."Document Line SystemId" := InvoiceLineSystemId;
        Edge."Matched Rcpt./Shpt. Line SysId" := ReceiptLineSystemId;
        Edge."Qty. to Invoice" := QtyToAllocate;
        Edge."Qty. to Invoice (Base)" := QtyToAllocateBase;
    end;
    #endregion
}
