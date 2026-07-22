// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Activity;

codeunit 99001572 "Subc. Invt. Put-away Ext"
{
    // Subscriber A: Set Subc. Purchase Line Type and fix Qty. per Unit of Measure on the
    // Warehouse Activity Line before it is inserted. For LastOperation lines the purchase line
    // carries Qty. per Unit of Measure = 0 (set by SubcCalculateSubcontracts), which would
    // result in Qty. (Base) = 0 on the activity line. This subscriber restores the real
    // value from the item so that base quantities are calculated correctly.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", OnBeforeNewWhseActivLineInsertFromPurchase, '', false, false)]
    local procedure SetSubcLineTypeAndQtyPerUoM_OnBeforeNewWhseActivLineInsertFromPurchase(var WarehouseActivityLine: Record "Warehouse Activity Line"; PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::None then
            exit;

        WarehouseActivityLine."Subc. Purchase Line Type" := PurchaseLine."Subc. Purchase Line Type";

        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::LastOperation then begin
            Item.SetLoadFields("No.", "Base Unit of Measure");
            Item.Get(PurchaseLine."No.");
            WarehouseActivityLine."Qty. per Unit of Measure" :=
                UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");
        end;
    end;

    // Subscriber B: Skip warehouse journal posting for NotLastOperation and Transfer WIP Item
    // lines on Inventory Put-away documents. Only relevant for Bin Mandatory locations.
    // Analogous to SkipPostWhseJnlLineForSubcontracting_OnBeforePostWhseJnlLine in
    // SubcWhsePostReceiptExt for the two-step warehouse receipt path.
    // NOTE: LastOperation lines must NOT be skipped here - this is the mechanism that creates
    // the correct, per-bin Warehouse Entries (one per split Warehouse Activity Line) when the
    // put-away quantity has been split across multiple bins. Skipping it for LastOperation would
    // remove the only correct source of bin-level Warehouse Entries.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforePostWhseJnlLine, '', false, false)]
    local procedure SkipWhseJnlForNotLastOp_OnBeforePostWhseJnlLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
        if WarehouseActivityLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    // Subscriber F: Suppress the automatic Warehouse Journal Line creation that
    // Mfg. Item Jnl.-Post Line performs for every Output posting at a Bin Mandatory location
    // (see OnPostOutputOnBeforeCreateWhseJnlLine). For subcontracting LastOperation lines posted
    // through a warehouse put-away flow (Invt. Put-away or Warehouse Receipt + Put-away), the
    // correct per-bin Warehouse Entries are already created explicitly by the warehouse posting
    // codeunits (WhseActivityPost.PostWhseJnlLine / Whse.-Post Receipt.PostWhseJnlLine).
    // Without this suppression, the automatic (aggregated, single-bin, full-quantity) entry is
    // created IN ADDITION to the correct split-bin entries, doubling the posted quantity.
    // Locations that are Bin Mandatory but do NOT require put-away (i.e. the purchase order is
    // posted directly, without any warehouse document) must keep relying on this automatic
    // mechanism, since no other bin posting exists for them - hence the Require Put-away check.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Item Jnl.-Post Line", OnPostOutputOnBeforeCreateWhseJnlLine, '', false, false)]
    local procedure SuppressAutoWhseJnlForSubcOutput_OnPostOutputOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PostWhseJnlLine: Boolean)
    var
        Location: Record Location;
    begin
        if not ItemJournalLine.Subcontracting then
            exit;
        if not Location.Get(ItemJournalLine."Location Code") then
            exit;
        if Location."Require Put-away" then
            PostWhseJnlLine := false;
    end;

    // Subscriber D: Suppress the error in UndoPostingManagement that prevents undoing a
    // purchase receipt line when a Posted Invt. Put-away Line exists for it - but ONLY when the
    // location is NOT Bin Mandatory.
    //
    // Background: WhseActivityPost.CreateWhseJnlLine sets the Warehouse Entry's "Source Type" to
    // the POSTED source document (Database::"Purch. Rcpt. Header"), not to Database::"Purchase
    // Line". Undo Purchase Receipt Line's reversal search (WhseUndoQty.InsertTempWhseJnlLine)
    // filters Warehouse Entry by Source Type = Database::"Purchase Line" - a mismatch that means
    // it NEVER finds these entries, so it can never create the matching reversal Warehouse
    // Journal Line. This is a general, pre-existing base app limitation of the one-step
    // Inventory Put-away flow (not specific to subcontracting): Undo Receipt cannot properly
    // reverse bin content that was created this way.
    //
    // For Bin Mandatory locations, WhseActivityPost.PostWhseActivityLine actually creates
    // Warehouse Entries (bin content), so allowing Undo Receipt here would leave orphaned,
    // un-reversed bin content - exactly what the base app's block is designed to prevent (see
    // the existing, still-valid test UndoPurchaseReceiptFailsWhenPutAwayRegistered for the
    // two-step flow). Therefore the block must remain active in that case.
    //
    // For locations that are NOT Bin Mandatory, no Warehouse Entry is ever created for the
    // Invt. Put-away line (PostWhseJnlLine is only called "if Location.Bin Mandatory"), so there
    // is nothing that could be left dangling - suppressing the block here is safe.
    //
    // NOTE on parameter mapping: UndoPostingManagement.TestPurchRcptLine calls TestAllTransactions
    // with UndoType/UndoID/UndoLineNo identifying the Purch. Rcpt. Line being undone, and
    // SourceType/SourceSubtype/SourceID/SourceRefNo identifying the ORIGINATING Purchase Line
    // (Database::"Purchase Line", Order, Order No., Order Line No.) - NOT the Purch. Rcpt. Line
    // itself. The Purchase Line must therefore be looked up via SourceID/SourceRefNo.
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Posting Management", OnBeforeTestPostedInvtPutAwayLine, '', false, false)]
    // local procedure SkipUndoBlockForSubc_OnBeforeTestPostedInvtPutAwayLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean; UndoType: Integer; UndoID: Code[20])
    // var
    //     PurchLine: Record "Purchase Line";
    //     Location: Record Location;
    // begin
    //     if SourceType <> Database::"Purchase Line" then
    //         exit;
    //     if SourceSubtype <> "Purchase Document Type"::Order.AsInteger() then
    //         exit;
    //     if UndoType <> Database::"Purch. Rcpt. Line" then
    //         exit;
    //     if not PurchLine.Get("Purchase Document Type"::Order, SourceID, SourceRefNo) then
    //         exit;
    //     if PurchLine."Prod. Order No." = '' then
    //         exit;
    //     if not Location.Get(PurchLine."Location Code") then
    //         exit;
    //     if not Location."Bin Mandatory" then
    //         IsHandled := true;
    // end;

    // Subscriber E: Suppress TestField("Qty. per Unit of Measure") in WarehouseActivityLine.CalcQty
    // for NotLastOperation and Transfer WIP Item lines where Qty. per Unit of Measure is
    // intentionally 0. Returns 0 (QtyBase * 0) which is the correct result for these lines.
    // NOTE: Must NOT be suppressed for LastOperation - that line now carries the real
    // Qty. per Unit of Measure (see Subscriber A), so CalcQty must perform the normal
    // division; skipping it here would return the wrong (unconverted) quantity.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeCalcQty, '', false, false)]
    local procedure SuppressCalcQtyTestFieldForNotLastOp_OnBeforeCalcQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyBase: Decimal; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
        if WarehouseActivityLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    // NOTE: Must NOT be suppressed for LastOperation - that line carries a real,
    // non-zero Qty. per Unit of Measure, so the balance check is meaningful and correct there.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeValidateQuantityIsBalanced, '', false, false)]
    local procedure "Warehouse Activity Line_OnBeforeValidateQuantityIsBalanced"(var WhseActivLine: Record "Warehouse Activity Line"; xWhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
        if WhseActivLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
        if WhseActivLine."Transfer WIP Item" then
            IsHandled := true;
    end;


    // Propagates the Subc. Purchase Line Type / Transfer WIP Item flags from the originating
    // Purchase Line or Transfer Line onto the new Warehouse Activity Line. This is required for
    // Transfer Line sources (WIP Item transfers between subcontracting locations) since, unlike
    // Purchase Line, there is no dedicated OnBeforeNewWhseActivLineInsertFromTransfer subscriber
    // here - without this, "Transfer WIP Item" would never be set on the activity line, and
    // Subscribers B/E (which both check WarehouseActivityLine."Transfer WIP Item") would never
    // fire, causing CalcQty's TestField("Qty. per Unit of Measure") to fail (that field is 0 for
    // WIP Item transfer lines, analogous to NotLastOperation purchase lines - see
    // SubcTransferLineExt.OnValidateUnitofMeasureCodeOnBeforeValidateQuantity).
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnAfterSetSource, '', false, false)]
    local procedure "Warehouse Activity Line_OnAfterSetSource"(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        PurchLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
    begin
        case WarehouseActivityLine."Source Type" of
            Database::"Purchase Line":
                begin
                    if WarehouseActivityLine."Source Subtype" <> "Purchase Document Type"::Order.AsInteger() then
                        exit;
                    if not PurchLine.Get("Purchase Document Type"::Order, WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.") then
                        exit;
                    WarehouseActivityLine."Subc. Purchase Line Type" := PurchLine."Subc. Purchase Line Type";
                    WarehouseActivityLine."Transfer WIP Item" := PurchLine."Transfer WIP Item";
                end;
            Database::"Transfer Line":
                begin
                    if not TransferLine.Get(WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.") then
                        exit;
                    WarehouseActivityLine."Transfer WIP Item" := TransferLine."Transfer WIP Item";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", OnAfterInitWarehouseActivityLine, '', false, false)]
    local procedure "Create Inventory Put-away_OnAfterInitWarehouseActivityLine"(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        Item: Record Item;
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::LastOperation then begin
            Item.SetLoadFields("Base Unit of Measure");
            Item.Get(WarehouseActivityLine."Item No.");

            WarehouseActivityLine."Qty. per Unit of Measure" := UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, WarehouseActivityLine."Unit of Measure Code");
        end;
    end;


    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", OnRaiseOnBeforeNewWhseActivLineInsertFromEvent, '', false, false)]
    // local procedure "Create Inventory Put-away_OnRaiseOnBeforeNewWhseActivLineInsertFromEvent"(var WarehouseActivityLine: Record "Warehouse Activity Line"; RecordVariant: Variant; RecordRefToCheck: RecordRef)
    // var
    //     PurchLine: Record "Purchase Line";
    //     DataTypeManagement: Codeunit "Data Type Management";
    //     RecRef: RecordRef;
    // begin
    //     if not DataTypeManagement.GetRecordRef(RecordVariant, RecRef) then
    //         exit;
    //     RecRef.SetTable(PurchLine);
    //     case RecRef.Number of
    //         Database::"Purchase Line":
    //             begin
    //                 WarehouseActivityLine."Subc. Purchase Line Type" := PurchLine."Subc. Purchase Line Type";
    //                 WarehouseActivityLine."Transfer WIP Item" := PurchLine."Transfer WIP Item";
    //             end;
    //     end;
    // end;
}
