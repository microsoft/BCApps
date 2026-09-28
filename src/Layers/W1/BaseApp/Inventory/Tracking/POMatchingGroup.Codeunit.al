// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 5829 "PO Matching Group"
{
    Access = Public;

    var
        TempCurrentPOMatchingGroup: Record "Matched Order Line" temporary;
        TempInvoiceOrderEdgeCursor: Record "Matched Order Line" temporary;
        EmptyGuid: Guid;
        IsLoading: Boolean;
        AtLeastTwoDocumentsErr: Label 'A match must specify at least two of: invoice line, order line and receipt/shipment line.';
        LinesMustAgreeErr: Label 'The matched lines must have the same type and number.';
        InvoiceLineNotFoundErr: Label 'The purchase line to match doesn''t exist.';
        ReceiptLineNotFoundErr: Label 'The receipt/shipment line to match no longer exists.';
        InvoiceCapExceededErr: Label 'The quantity to allocate exceeds the quantity available to invoice on the purchase invoice line.';
        OrderCapExceededErr: Label 'The quantity to allocate exceeds the quantity remaining to invoice on the purchase order line.';
        ReceiptCapExceededErr: Label 'The quantity to allocate exceeds the quantity received not invoiced on the receipt/shipment line.';
        InvoiceNotInferrableErr: Label 'Could not determine a single invoice line for the receipt allocation. Specify the invoice line.';
        BudgetBelowPinnedErr: Label 'The invoice-order allocation cannot be lower than the receipt/shipment quantities already distributed for it.';
        PrepaymentNotSupportedErr: Label 'Matched order lines are not supported for prepayment lines. Order No.: %1, Line No.: %2', Comment = '%1 = Order No., %2 = Line No.';
        ItemChargeNotSupportedErr: Label 'Matched order lines are not supported for item charge lines. Order No.: %1, Line No.: %2', Comment = '%1 = Order No., %2 = Line No.';
        LinesMustShareVendorCurrencyErr: Label 'The invoice line and order line must have the same buy-from vendor, pay-to vendor and currency.';
        ReceiptNotForOrderLineErr: Label 'The receipt/shipment line does not belong to the matched order line.';
        ItemTrackingPartialErr: Label 'A receipt/shipment line with item tracking must be invoiced in full. Receipt No.: %1, Line No.: %2', Comment = '%1 = Receipt No., %2 = Receipt Line No.';
        InvoiceDocumentTypeErr: Label 'The purchase line to match must be an invoice line.';
        OrderDocumentTypeErr: Label 'The matched purchase line must be an order line.';
        LinesMustShareUnitOfMeasureErr: Label 'The invoice line and order line must have the same unit of measure.';
        NegativeAllocationErr: Label 'The quantity to allocate cannot be negative.';

    /// <summary>
    /// Adds an edge to the group if it's valid in the current context, merging in any already-persisted
    /// allocations that share a line with the edge so validations account for them.
    /// </summary>
    /// <param name="NewMatch">The desired match to add to the group</param>
    procedure AddMatch(NewMatch: Record "Matched Order Line")
    begin
        AddMatch(NewMatch, true);
    end;

    /// <summary>
    /// Revalidates the fully merged group against the current documents and persists it.
    /// </summary>
    procedure SaveMatchingGroups()
    begin
        RevalidateGroup();

        TempCurrentPOMatchingGroup.Reset();
        if TempCurrentPOMatchingGroup.FindSet() then
            repeat
                PersistRow(TempCurrentPOMatchingGroup);
            until TempCurrentPOMatchingGroup.Next() = 0;
    end;

    local procedure AddMatch(NewMatch: Record "Matched Order Line"; LoadRelatedPersistedMatches: Boolean)
    var
        HasInvoice, HasOrder, HasReceipt : Boolean;
    begin
        if LoadRelatedPersistedMatches then
            EnsureGroupLoaded(
                NewMatch."Document Line SystemId",
                NewMatch."Matched Order Line SystemId",
                NewMatch."Matched Rcpt./Shpt. Line SysId");

        HasInvoice := not IsNullGuid(NewMatch."Document Line SystemId");
        HasOrder := not IsNullGuid(NewMatch."Matched Order Line SystemId");
        HasReceipt := not IsNullGuid(NewMatch."Matched Rcpt./Shpt. Line SysId");

        if HasOrder and HasReceipt then
            AddOrderReceiptMatch(NewMatch)
        else
            if HasInvoice and HasOrder then
                AddInvoiceOrderMatch(NewMatch)
            else
                if HasInvoice and HasReceipt then
                    AddInvoiceReceiptMatch(NewMatch)
                else
                    Error(AtLeastTwoDocumentsErr);
    end;

    local procedure AddInvoiceOrderMatch(NewMatch: Record "Matched Order Line")
    begin
        OverrideBaseFromOrderLine(NewMatch);
        ValidateInvoiceOrder(NewMatch);
        InsertOrModify(NewMatch);
    end;

    local procedure AddOrderReceiptMatch(NewMatch: Record "Matched Order Line")
    begin
        if IsNullGuid(NewMatch."Document Line SystemId") then
            NewMatch."Document Line SystemId" := InferInvoiceForOrder(NewMatch."Matched Order Line SystemId");
        OverrideBaseFromOrderLine(NewMatch);
        ValidateOrderReceipt(NewMatch);
        InsertOrModify(NewMatch);
    end;

    local procedure AddInvoiceReceiptMatch(NewMatch: Record "Matched Order Line")
    var
        InvoiceOrderEdge, OrderReceiptEdge : Record "Matched Order Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OrderLine: Record "Purchase Line";
    begin
        if not PurchRcptLine.GetBySystemId(NewMatch."Matched Rcpt./Shpt. Line SysId") then
            Error(ReceiptLineNotFoundErr);

        OrderLine.Get(OrderLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");

        InvoiceOrderEdge."Document Line SystemId" := NewMatch."Document Line SystemId";
        InvoiceOrderEdge."Matched Order Line SystemId" := OrderLine.SystemId;
        InvoiceOrderEdge."Qty. to Invoice" := NewMatch."Qty. to Invoice";
        InvoiceOrderEdge."Qty. to Invoice (Base)" := NewMatch."Qty. to Invoice (Base)";
        AddInvoiceOrderMatch(InvoiceOrderEdge);

        OrderReceiptEdge."Document Line SystemId" := NewMatch."Document Line SystemId";
        OrderReceiptEdge."Matched Order Line SystemId" := OrderLine.SystemId;
        OrderReceiptEdge."Matched Rcpt./Shpt. Line SysId" := NewMatch."Matched Rcpt./Shpt. Line SysId";
        OrderReceiptEdge."Qty. to Invoice" := NewMatch."Qty. to Invoice";
        OrderReceiptEdge."Qty. to Invoice (Base)" := NewMatch."Qty. to Invoice (Base)";
        AddOrderReceiptMatch(OrderReceiptEdge);
    end;

    #region Validation
    local procedure ValidateInvoiceOrder(Match: Record "Matched Order Line")
    var
        InvoiceLine, OrderLine : Record "Purchase Line";
        AllocatedQty, AllocatedBase, PinnedQty, PinnedBase : Decimal;
    begin
        CheckAllocationNotNegative(Match);

        if not InvoiceLine.GetBySystemId(Match."Document Line SystemId") then
            Error(InvoiceLineNotFoundErr);
        if not OrderLine.GetBySystemId(Match."Matched Order Line SystemId") then
            Error(InvoiceLineNotFoundErr);

        ValidateInvoiceOrderCompatibility(InvoiceLine, OrderLine);

        // The budget must fit in what the invoice line still has to allocate (blank-receipt layer only).
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Document Line SystemId", Match."Document Line SystemId");
        TempCurrentPOMatchingGroup.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        SumExcludingSelf(Match."Document Line SystemId", Match."Matched Order Line SystemId", EmptyGuid, AllocatedQty, AllocatedBase);
        if Match."Qty. to Invoice" > InvoiceLine.Quantity - AllocatedQty then
            Error(InvoiceCapExceededErr);
        if Match."Qty. to Invoice (Base)" > InvoiceLine."Quantity (Base)" - AllocatedBase then
            Error(InvoiceCapExceededErr);

        // The budget must fit in the order line's quantity remaining to invoice (blank-receipt layer only).
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Matched Order Line SystemId", Match."Matched Order Line SystemId");
        TempCurrentPOMatchingGroup.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        SumExcludingSelf(Match."Document Line SystemId", Match."Matched Order Line SystemId", EmptyGuid, AllocatedQty, AllocatedBase);
        if Match."Qty. to Invoice" > (OrderLine.Quantity - OrderLine."Quantity Invoiced") - AllocatedQty then
            Error(OrderCapExceededErr);
        if Match."Qty. to Invoice (Base)" > (OrderLine."Quantity (Base)" - OrderLine."Qty. Invoiced (Base)") - AllocatedBase then
            Error(OrderCapExceededErr);

        // The budget cannot drop below the receipt quantities already pinned to this invoice-order pair.
        SumReceiptsForPair(Match."Document Line SystemId", Match."Matched Order Line SystemId", PinnedQty, PinnedBase);
        if (Match."Qty. to Invoice" < PinnedQty) or (Match."Qty. to Invoice (Base)" < PinnedBase) then
            Error(BudgetBelowPinnedErr);
    end;

    local procedure ValidateOrderReceipt(Match: Record "Matched Order Line")
    var
        InvoiceLine, OrderLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        BudgetQty, BudgetBase, PinnedQty, PinnedBase, ReceiptQty, ReceiptBase : Decimal;
    begin
        CheckAllocationNotNegative(Match);

        if not InvoiceLine.GetBySystemId(Match."Document Line SystemId") then
            Error(InvoiceLineNotFoundErr);
        if not OrderLine.GetBySystemId(Match."Matched Order Line SystemId") then
            Error(InvoiceLineNotFoundErr);
        if not PurchRcptLine.GetBySystemId(Match."Matched Rcpt./Shpt. Line SysId") then
            Error(ReceiptLineNotFoundErr);

        ValidateInvoiceOrderCompatibility(InvoiceLine, OrderLine);

        if (OrderLine.Type <> PurchRcptLine.Type) or (OrderLine."No." <> PurchRcptLine."No.") then
            Error(LinesMustAgreeErr);

        // The receipt must actually be a receipt of this order line, not just an agreeing line.
        if (PurchRcptLine."Order No." <> OrderLine."Document No.") or (PurchRcptLine."Order Line No." <> OrderLine."Line No.") then
            Error(ReceiptNotForOrderLineErr);

        // The amount must fit in the budget this invoice-order pair was given, net of what previous
        // receipt rows for the same pair already consumed (per-invoice, so a receipt can be split).
        BudgetQty := PairBudget(Match."Document Line SystemId", Match."Matched Order Line SystemId", BudgetBase);
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Document Line SystemId", Match."Document Line SystemId");
        TempCurrentPOMatchingGroup.SetRange("Matched Order Line SystemId", Match."Matched Order Line SystemId");
        TempCurrentPOMatchingGroup.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        SumExcludingSelf(Match."Document Line SystemId", Match."Matched Order Line SystemId", Match."Matched Rcpt./Shpt. Line SysId", PinnedQty, PinnedBase);
        if Match."Qty. to Invoice" > BudgetQty - PinnedQty then
            Error(OrderCapExceededErr);
        if Match."Qty. to Invoice (Base)" > BudgetBase - PinnedBase then
            Error(OrderCapExceededErr);

        // The amount must fit in what the receipt line still has received but not invoiced.
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Matched Rcpt./Shpt. Line SysId", Match."Matched Rcpt./Shpt. Line SysId");
        SumExcludingSelf(Match."Document Line SystemId", Match."Matched Order Line SystemId", Match."Matched Rcpt./Shpt. Line SysId", ReceiptQty, ReceiptBase);
        if Match."Qty. to Invoice" > PurchRcptLine."Qty. Rcd. Not Invoiced" - ReceiptQty then
            Error(ReceiptCapExceededErr);
        if Match."Qty. to Invoice (Base)" > (PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)") - ReceiptBase then
            Error(ReceiptCapExceededErr);

        // A receipt carrying item tracking must be invoiced in full: we can't re-specify which serials/lots go on a partial invoice.
        if ReceiptHasItemTracking(PurchRcptLine) then
            if (Match."Qty. to Invoice" <> PurchRcptLine."Qty. Rcd. Not Invoiced") or
               (Match."Qty. to Invoice (Base)" <> PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)") then
                Error(ItemTrackingPartialErr, PurchRcptLine."Document No.", PurchRcptLine."Line No.");
    end;

    local procedure CheckAllocationNotNegative(Match: Record "Matched Order Line")
    begin
        if (Match."Qty. to Invoice" < 0) or (Match."Qty. to Invoice (Base)" < 0) then
            Error(NegativeAllocationErr);
    end;

    local procedure ValidateInvoiceOrderCompatibility(InvoiceLine: Record "Purchase Line"; OrderLine: Record "Purchase Line")
    begin
        if InvoiceLine."Document Type" <> InvoiceLine."Document Type"::Invoice then
            Error(InvoiceDocumentTypeErr);
        if OrderLine."Document Type" <> OrderLine."Document Type"::Order then
            Error(OrderDocumentTypeErr);

        CheckOrderLineMatchable(OrderLine);

        if (InvoiceLine.Type <> OrderLine.Type) or (InvoiceLine."No." <> OrderLine."No.") then
            Error(LinesMustAgreeErr);
        if InvoiceLine."Unit of Measure Code" <> OrderLine."Unit of Measure Code" then
            Error(LinesMustShareUnitOfMeasureErr);
        if (InvoiceLine."Buy-from Vendor No." <> OrderLine."Buy-from Vendor No.") or
           (InvoiceLine."Pay-to Vendor No." <> OrderLine."Pay-to Vendor No.") or
           (InvoiceLine."Currency Code" <> OrderLine."Currency Code") then
            Error(LinesMustShareVendorCurrencyErr);
    end;

    local procedure RevalidateGroup()
    var
        TempSnapshot: Record "Matched Order Line" temporary;
    begin
        // Snapshot: the validators set filters to the record which we are iterating
        TempCurrentPOMatchingGroup.Reset();
        if TempCurrentPOMatchingGroup.FindSet() then
            repeat
                TempSnapshot := TempCurrentPOMatchingGroup;
                TempSnapshot.Insert();
            until TempCurrentPOMatchingGroup.Next() = 0;

        if TempSnapshot.FindSet() then
            repeat
                if IsNullGuid(TempSnapshot."Matched Rcpt./Shpt. Line SysId") then
                    ValidateInvoiceOrder(TempSnapshot)
                else
                    ValidateOrderReceipt(TempSnapshot);
            until TempSnapshot.Next() = 0;
    end;

    local procedure InferInvoiceForOrder(OrderLineSystemId: Guid): Guid
    begin
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Matched Order Line SystemId", OrderLineSystemId);
        TempCurrentPOMatchingGroup.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        if TempCurrentPOMatchingGroup.Count() <> 1 then
            Error(InvoiceNotInferrableErr);
        TempCurrentPOMatchingGroup.FindFirst();
        exit(TempCurrentPOMatchingGroup."Document Line SystemId");
    end;

    local procedure CheckOrderLineMatchable(OrderLine: Record "Purchase Line")
    begin
        if OrderLine."Prepayment %" <> 0 then
            Error(PrepaymentNotSupportedErr, OrderLine."Document No.", OrderLine."Line No.");
        if OrderLine.Type = OrderLine.Type::"Charge (Item)" then
            Error(ItemChargeNotSupportedErr, OrderLine."Document No.", OrderLine."Line No.");
    end;

    local procedure OverrideBaseFromOrderLine(var Match: Record "Matched Order Line")
    var
        OrderLine: Record "Purchase Line";
    begin
        if not OrderLine.GetBySystemId(Match."Matched Order Line SystemId") then
            Error(InvoiceLineNotFoundErr);
        Match."Qty. to Invoice (Base)" :=
            OrderLine.CalcBaseQty(Match."Qty. to Invoice", Match.FieldCaption("Qty. to Invoice"), Match.FieldCaption("Qty. to Invoice (Base)"));
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

    #region Group buffer helpers
    local procedure PairBudget(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; var BudgetBase: Decimal): Decimal
    begin
        BudgetBase := 0;
        if TempCurrentPOMatchingGroup.Get(InvoiceLineSystemId, OrderLineSystemId, EmptyGuid) then begin
            BudgetBase := TempCurrentPOMatchingGroup."Qty. to Invoice (Base)";
            exit(TempCurrentPOMatchingGroup."Qty. to Invoice");
        end;
        exit(0);
    end;

    local procedure SumReceiptsForPair(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; var PinnedQty: Decimal; var PinnedBase: Decimal)
    begin
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Document Line SystemId", InvoiceLineSystemId);
        TempCurrentPOMatchingGroup.SetRange("Matched Order Line SystemId", OrderLineSystemId);
        TempCurrentPOMatchingGroup.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        SumExcludingSelf(InvoiceLineSystemId, OrderLineSystemId, EmptyGuid, PinnedQty, PinnedBase);
    end;

    local procedure SumExcludingSelf(ExcludeInvoice: Guid; ExcludeOrder: Guid; ExcludeReceipt: Guid; var TotalQty: Decimal; var TotalBase: Decimal)
    begin
        TotalQty := 0;
        TotalBase := 0;
        if TempCurrentPOMatchingGroup.FindSet() then
            repeat
                if not ((TempCurrentPOMatchingGroup."Document Line SystemId" = ExcludeInvoice) and
                        (TempCurrentPOMatchingGroup."Matched Order Line SystemId" = ExcludeOrder) and
                        (TempCurrentPOMatchingGroup."Matched Rcpt./Shpt. Line SysId" = ExcludeReceipt)) then begin
                    TotalQty += TempCurrentPOMatchingGroup."Qty. to Invoice";
                    TotalBase += TempCurrentPOMatchingGroup."Qty. to Invoice (Base)";
                end;
            until TempCurrentPOMatchingGroup.Next() = 0;
    end;

    local procedure InsertOrModify(Match: Record "Matched Order Line")
    begin
        if TempCurrentPOMatchingGroup.Get(Match."Document Line SystemId", Match."Matched Order Line SystemId", Match."Matched Rcpt./Shpt. Line SysId") then begin
            TempCurrentPOMatchingGroup."Qty. to Invoice" := Match."Qty. to Invoice";
            TempCurrentPOMatchingGroup."Qty. to Invoice (Base)" := Match."Qty. to Invoice (Base)";
            TempCurrentPOMatchingGroup.Modify();
        end else begin
            TempCurrentPOMatchingGroup.Init();
            TempCurrentPOMatchingGroup."Document Line SystemId" := Match."Document Line SystemId";
            TempCurrentPOMatchingGroup."Matched Order Line SystemId" := Match."Matched Order Line SystemId";
            TempCurrentPOMatchingGroup."Matched Rcpt./Shpt. Line SysId" := Match."Matched Rcpt./Shpt. Line SysId";
            TempCurrentPOMatchingGroup."Qty. to Invoice" := Match."Qty. to Invoice";
            TempCurrentPOMatchingGroup."Qty. to Invoice (Base)" := Match."Qty. to Invoice (Base)";
            TempCurrentPOMatchingGroup.Insert();
        end;
    end;

    local procedure PersistRow(Src: Record "Matched Order Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
        ReceiptOnInvoice: Boolean;
    begin
        if IsNullGuid(Src."Matched Rcpt./Shpt. Line SysId") then
            ReceiptOnInvoice := ReceiptOnInvoiceForMatch(Src."Matched Order Line SystemId");

        if MatchedOrderLine.Get(Src."Document Line SystemId", Src."Matched Order Line SystemId", Src."Matched Rcpt./Shpt. Line SysId") then begin
            MatchedOrderLine."Qty. to Invoice" := Src."Qty. to Invoice";
            MatchedOrderLine."Qty. to Invoice (Base)" := Src."Qty. to Invoice (Base)";
            MatchedOrderLine."Receipt on Invoice" := ReceiptOnInvoice;
            MatchedOrderLine.Modify();
        end else begin
            MatchedOrderLine.Init();
            MatchedOrderLine."Document Line SystemId" := Src."Document Line SystemId";
            MatchedOrderLine."Matched Order Line SystemId" := Src."Matched Order Line SystemId";
            MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := Src."Matched Rcpt./Shpt. Line SysId";
            MatchedOrderLine."Qty. to Invoice" := Src."Qty. to Invoice";
            MatchedOrderLine."Qty. to Invoice (Base)" := Src."Qty. to Invoice (Base)";
            MatchedOrderLine."Receipt on Invoice" := ReceiptOnInvoice;
            MatchedOrderLine.Insert();
        end;
    end;

    local procedure ReceiptOnInvoiceForMatch(OrderLineSystemId: Guid): Boolean
    var
        OrderLine: Record "Purchase Line";
    begin
        OrderLine.GetBySystemId(OrderLineSystemId);
        exit(OrderLine."Receipt on Invoice");
    end;
    #endregion

    #region Traversal
    // The iterator walks a snapshot of the current matches to allow consumers to mutate the group without disturbing the iterator.

    /// <summary>Snapshots the invoice-order (blank-receipt) edges and positions at the first one.</summary>
    internal procedure GetInvoiceOrderEdges(): Boolean
    begin
        TempInvoiceOrderEdgeCursor.Reset();
        TempInvoiceOrderEdgeCursor.DeleteAll();
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        if TempCurrentPOMatchingGroup.FindSet() then
            repeat
                TempInvoiceOrderEdgeCursor := TempCurrentPOMatchingGroup;
                TempInvoiceOrderEdgeCursor.Insert();
            until TempCurrentPOMatchingGroup.Next() = 0;
        exit(TempInvoiceOrderEdgeCursor.FindSet());
    end;

    /// <summary>Advances to the next invoice-order edge in the snapshot.</summary>
    internal procedure NextInvoiceOrderEdge(): Boolean
    begin
        exit(TempInvoiceOrderEdgeCursor.Next() <> 0);
    end;

    /// <summary>The invoice line SystemId of the current invoice-order edge.</summary>
    internal procedure GetInvoiceLine(): Guid
    begin
        exit(TempInvoiceOrderEdgeCursor."Document Line SystemId");
    end;

    /// <summary>The order line SystemId of the current invoice-order edge.</summary>
    internal procedure GetOrderLine(): Guid
    begin
        exit(TempInvoiceOrderEdgeCursor."Matched Order Line SystemId");
    end;

    /// <summary>The quantity budgeted by the current invoice-order edge.</summary>
    internal procedure AllocatedInInvoiceOrderEdge(): Decimal
    begin
        exit(TempInvoiceOrderEdgeCursor."Qty. to Invoice");
    end;

    /// <summary>The live sum of receipt edges already pinned to the current invoice-order pair.</summary>
    internal procedure SumAllocatedInOrderReceiptEdges(): Decimal
    var
        PinnedQty, PinnedBase : Decimal;
    begin
        SumReceiptsForPair(TempInvoiceOrderEdgeCursor."Document Line SystemId", TempInvoiceOrderEdgeCursor."Matched Order Line SystemId", PinnedQty, PinnedBase);
        exit(PinnedQty);
    end;

    /// <summary>The live quantity of the receipt edge for the given (invoice, order, receipt), 0 if none.</summary>
    internal procedure GetReceiptEdgeQuantity(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; ReceiptLineSystemId: Guid): Decimal
    begin
        if TempCurrentPOMatchingGroup.Get(InvoiceLineSystemId, OrderLineSystemId, ReceiptLineSystemId) then
            exit(TempCurrentPOMatchingGroup."Qty. to Invoice");
        exit(0);
    end;

    /// <summary>The live total quantity pinned to a receipt line across all invoices in the group.</summary>
    internal procedure GetReceiptConsumedQuantity(ReceiptLineSystemId: Guid) Total: Decimal
    begin
        TempCurrentPOMatchingGroup.Reset();
        TempCurrentPOMatchingGroup.SetRange("Matched Rcpt./Shpt. Line SysId", ReceiptLineSystemId);
        if TempCurrentPOMatchingGroup.FindSet() then
            repeat
                Total += TempCurrentPOMatchingGroup."Qty. to Invoice";
            until TempCurrentPOMatchingGroup.Next() = 0;
    end;
    #endregion

    #region Group reload
    local procedure EnsureGroupLoaded(InvoiceLineSystemId: Guid; OrderLineSystemId: Guid; ReceiptLineSystemId: Guid)
    var
        TempComponent: Record "Matched Order Line" temporary;
    begin
        // Protection for future code-churns because of the recursion risk when adding the discovered edges.
        if IsLoading then begin
            Session.LogMessage('0000V7K', 'Programming error: EnsureGroupLoaded called while it was already loading', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Purchase Order Matching');
            exit;
        end;
        IsLoading := true;

        LoadNewPersistedEdges(InvoiceLineSystemId, OrderLineSystemId, ReceiptLineSystemId, TempComponent);
        if TempComponent.IsEmpty() then begin
            IsLoading := false;
            exit;
        end;

        // Add the new edges with validations starting by the invoice-order ones (to give allocations to the receipt edges)
        TempComponent.Reset();
        TempComponent.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        if TempComponent.FindSet() then
            repeat
                AddMatch(TempComponent, false);
            until TempComponent.Next() = 0;
        TempComponent.Reset();
        TempComponent.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        if TempComponent.FindSet() then
            repeat
                AddMatch(TempComponent, false);
            until TempComponent.Next() = 0;

        IsLoading := false;
    end;

    /// <summary>
    /// Given an edge, it loads it's persisted connected component (the persisted matches that involve such edge, and any connected edge
    /// as consequence) that haven't been loaded into the current "PO Matching Group".
    /// </summary>
    local procedure LoadNewPersistedEdges(SeedInvoice: Guid; SeedOrder: Guid; SeedReceipt: Guid; var TempComponent: Record "Matched Order Line" temporary)
    var
        KnownInvoice, KnownOrder, KnownReceipt : List of [Guid]; // The list of nodes to visit or that we have visited
        PendingInvoice, PendingOrder, PendingReceipt : List of [Guid]; // The list of nodes to be visited
        CurrentId: Guid;
    begin
        TempComponent.DeleteAll();
        // We compute the connected component with a BFS approach (with the variant of checking the global state of the currently loaded edges).

        // We first fill in the list of nodes to visit (which equals the nodes to be visited) with the nodes that we have in the current group
        TempCurrentPOMatchingGroup.Reset();
        if TempCurrentPOMatchingGroup.FindSet() then
            repeat
                AppendIfUnqueued(KnownInvoice, PendingInvoice, TempCurrentPOMatchingGroup."Document Line SystemId");
                AppendIfUnqueued(KnownOrder, PendingOrder, TempCurrentPOMatchingGroup."Matched Order Line SystemId");
                AppendIfUnqueued(KnownReceipt, PendingReceipt, TempCurrentPOMatchingGroup."Matched Rcpt./Shpt. Line SysId");
            until TempCurrentPOMatchingGroup.Next() = 0;
        // And also the edge to be added
        AppendIfUnqueued(KnownInvoice, PendingInvoice, SeedInvoice);
        AppendIfUnqueued(KnownOrder, PendingOrder, SeedOrder);
        AppendIfUnqueued(KnownReceipt, PendingReceipt, SeedReceipt);

        // BFS traversal
        while (PendingInvoice.Count() + PendingOrder.Count() + PendingReceipt.Count()) > 0 do begin
            while PendingInvoice.Count() > 0 do begin
                PopFirst(PendingInvoice, CurrentId);
                VisitDocumentNode(TempComponent, KnownInvoice, KnownOrder, KnownReceipt, PendingInvoice, PendingOrder, PendingReceipt, 1, CurrentId);
            end;
            while PendingOrder.Count() > 0 do begin
                PopFirst(PendingOrder, CurrentId);
                VisitDocumentNode(TempComponent, KnownInvoice, KnownOrder, KnownReceipt, PendingInvoice, PendingOrder, PendingReceipt, 2, CurrentId);
            end;
            while PendingReceipt.Count() > 0 do begin
                PopFirst(PendingReceipt, CurrentId);
                VisitDocumentNode(TempComponent, KnownInvoice, KnownOrder, KnownReceipt, PendingInvoice, PendingOrder, PendingReceipt, 3, CurrentId);
            end;
        end;
    end;

    local procedure VisitDocumentNode(var TempComponent: Record "Matched Order Line" temporary; var KnownInvoice: List of [Guid]; var KnownOrder: List of [Guid]; var KnownReceipt: List of [Guid]; var PendingInvoice: List of [Guid]; var PendingOrder: List of [Guid]; var PendingReceipt: List of [Guid]; DocFilterType: Integer; Id: Guid)
    var
        PersistedMatchedOrderLine: Record "Matched Order Line";
    begin
        if IsNullGuid(Id) then
            exit;
        case DocFilterType of
            1:
                PersistedMatchedOrderLine.SetRange("Document Line SystemId", Id);
            2:
                PersistedMatchedOrderLine.SetRange("Matched Order Line SystemId", Id);
            3:
                PersistedMatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", Id);
        end;
        if PersistedMatchedOrderLine.FindSet() then
            repeat
                if not RowAlreadyLoadedOrPendingToLoad(PersistedMatchedOrderLine, TempComponent) then begin
                    TempComponent := PersistedMatchedOrderLine;
                    TempComponent.Insert();
                end;
                AppendIfUnqueued(KnownInvoice, PendingInvoice, PersistedMatchedOrderLine."Document Line SystemId");
                AppendIfUnqueued(KnownOrder, PendingOrder, PersistedMatchedOrderLine."Matched Order Line SystemId");
                AppendIfUnqueued(KnownReceipt, PendingReceipt, PersistedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId");
            until PersistedMatchedOrderLine.Next() = 0;
    end;

    local procedure RowAlreadyLoadedOrPendingToLoad(Row: Record "Matched Order Line"; var TempComponent: Record "Matched Order Line" temporary): Boolean
    begin
        exit(
            // We don't add edges that are already in the current match
            TempCurrentPOMatchingGroup.Get(Row."Document Line SystemId", Row."Matched Order Line SystemId", Row."Matched Rcpt./Shpt. Line SysId") or
            // Neither if we already had consider them in the current load of persisted edges
            TempComponent.Get(Row."Document Line SystemId", Row."Matched Order Line SystemId", Row."Matched Rcpt./Shpt. Line SysId"));
    end;

    /// <summary>
    /// Appends the new id to both the list of known (visited+to-visit) and the list of nodes to visit
    /// </summary>
    local procedure AppendIfUnqueued(var Known: List of [Guid]; var ToVisit: List of [Guid]; Id: Guid)
    begin
        // A newly seen id is both remembered (so it is never expanded twice) and queued for expansion.
        if IsNullGuid(Id) or Known.Contains(Id) then
            exit;
        Known.Add(Id);
        ToVisit.Add(Id);
    end;

    local procedure PopFirst(var Ids: List of [Guid]; var Id: Guid)
    begin
        if Ids.Count() = 0 then begin
            Clear(Id);
            exit;
        end;
        Id := Ids.Get(1);
        Ids.RemoveAt(1);
    end;
    #endregion
}
