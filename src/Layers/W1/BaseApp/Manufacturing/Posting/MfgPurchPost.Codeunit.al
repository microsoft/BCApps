// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 99000890 "Mfg. Purch.-Post"
{
#if not CLEAN27
    var
        PurchPost: Codeunit "Purch.-Post";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterCheckPurchRcptLine', '', true, true)]
    local procedure OnAfterCheckPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line")
    begin
        PurchRcptLine.TestField("Prod. Order No.", PurchaseLine."Prod. Order No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnPostItemJnlLineOnCopyProdOrder', '', true, true)]
    local procedure OnPostItemJnlLineOnCopyProdOrder(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; QtyToBeReceived: Decimal; QtyToBeInvoiced: Decimal; SuppressCommit: Boolean)
    begin
        if PurchaseLine.IsProdOrder() then
            PostItemJnlLineCopyProdOrder(PurchaseLine, ItemJournalLine, PurchRcptHeader, QtyToBeReceived, QtyToBeInvoiced, SuppressCommit);
    end;

    local procedure PostItemJnlLineCopyProdOrder(PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; QtyToBeReceived: Decimal; QtyToBeInvoiced: Decimal; SuppressCommit: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLineCopyProdOrder(PurchLine, ItemJnlLine, QtyToBeReceived, QtyToBeInvoiced, SuppressCommit, IsHandled);
#if not CLEAN27
        PurchPost.RunOnBeforePostItemJnlLineCopyProdOrder(PurchLine, ItemJnlLine, QtyToBeReceived, QtyToBeInvoiced, SuppressCommit, IsHandled);
#endif
        if IsHandled then
            exit;

        ItemJnlLine.Subcontracting := true;
        ItemJnlLine."Quantity (Base)" := CalcBaseQty(PurchLine."No.", PurchLine."Unit of Measure Code", QtyToBeReceived, PurchLine."Qty. Rounding Precision (Base)");
        ItemJnlLine."Invoiced Qty. (Base)" := CalcBaseQty(PurchLine."No.", PurchLine."Unit of Measure Code", QtyToBeInvoiced, PurchLine."Qty. Rounding Precision (Base)");
        ItemJnlLine."Unit Cost" := PurchLine."Unit Cost (LCY)";
        ItemJnlLine."Unit Cost (ACY)" := PurchLine."Unit Cost";
        ItemJnlLine."Output Quantity (Base)" := ItemJnlLine."Quantity (Base)";
        ItemJnlLine."Output Quantity" := QtyToBeReceived;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Output;
        ItemJnlLine.Type := ItemJnlLine.Type::"Work Center";
        ItemJnlLine."No." := PurchLine."Work Center No.";
        ItemJnlLine."Routing No." := PurchLine."Routing No.";
        ItemJnlLine."Routing Reference No." := PurchLine."Routing Reference No.";
        ItemJnlLine."Operation No." := PurchLine."Operation No.";
        ItemJnlLine."Work Center No." := PurchLine."Work Center No.";
        ItemJnlLine."Unit Cost Calculation" := ItemJnlLine."Unit Cost Calculation"::Units;
        if PurchLine.Finished then
            ItemJnlLine.Finished := PurchLine.Finished;

        OnAfterPostItemJnlLineCopyProdOrder(ItemJnlLine, PurchLine, PurchRcptHeader, QtyToBeReceived, SuppressCommit, QtyToBeInvoiced);
#if not CLEAN27
        OnAfterPostItemJnlLineCopyProdOrder(ItemJnlLine, PurchLine, PurchRcptHeader, QtyToBeReceived, SuppressCommit, QtyToBeInvoiced);
#endif
    end;

    local procedure CalcBaseQty(ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; QtyRoundingPrecision: Decimal): Decimal
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Item.Get(ItemNo);
        exit(UOMMgt.CalcBaseQty(ItemNo, '', UOMCode, Qty, UOMMgt.GetQtyPerUnitOfMeasure(Item, UOMCode), QtyRoundingPrecision));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostItemJnlLineCopyProdOrder(PurchLine: Record "Purchase Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeReceived: Decimal; QtyToBeInvoiced: Decimal; CommitIsSupressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLineCopyProdOrder(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; QtyToBeReceived: Decimal; CommitIsSupressed: Boolean; QtyToBeInvoiced: Decimal)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterCheckFieldsOnReturnShipmentLine', '', true, true)]
    local procedure OnAfterCheckFieldsOnReturnShipmentLine(ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line")
    begin
        ReturnShipmentLine.TestField("Prod. Order No.", PurchaseLine."Prod. Order No.");
    end;

}