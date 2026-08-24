// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 5828 "Invoiceable Receipts"
{
    Access = Internal;

    // A cursor over the posted receipt lines of a single order line that still have quantity received not
    // invoiced. It nets a receipt's remaining quantity against a "PO Matching Group" so consumers see the
    // capacity still available for covering, accounting for edges the group already holds.
    var
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;

    /// <summary>Loads the invoiceable receipts of the order line and positions at the first, returning false if none.</summary>
    internal procedure Load(OrderLine: Record "Purchase Line"): Boolean
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        TempPurchRcptLine.Reset();
        TempPurchRcptLine.DeleteAll();

        PurchRcptLine.SetRange("Order No.", OrderLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", OrderLine."Line No.");
        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        if PurchRcptLine.FindSet() then
            repeat
                TempPurchRcptLine := PurchRcptLine;
                TempPurchRcptLine.Insert();
            until PurchRcptLine.Next() = 0;

        exit(TempPurchRcptLine.FindSet());
    end;

    /// <summary>Advances to the next invoiceable receipt.</summary>
    internal procedure NextReceipt(): Boolean
    begin
        exit(TempPurchRcptLine.Next() <> 0);
    end;

    /// <summary>The current receipt line.</summary>
    internal procedure GetReceiptLine() PurchRcptLine: Record "Purch. Rcpt. Line"
    begin
        PurchRcptLine := TempPurchRcptLine;
    end;

    /// <summary>The current receipt's quantity received not invoiced, net of what the group already pinned to it.</summary>
    internal procedure ReceiptNotInvoiced(var POMatchingGroup: Codeunit "PO Matching Group"): Decimal
    begin
        exit(TempPurchRcptLine."Qty. Rcd. Not Invoiced" - POMatchingGroup.GetReceiptConsumedQuantity(TempPurchRcptLine.SystemId));
    end;
}
