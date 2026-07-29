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
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
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
    local procedure SuppressCalcQtyTestFieldForNotLastOp_OnBeforeCalcQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyBase: Decimal; var NewQtyBase: Decimal; var IsHandled: Boolean)
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
    // Subscriber G: Fix the source document line quantity used by the item-tracking match check
    // for Subcontracting LastOperation Purchase Lines, instead of bypassing the check entirely.
    // LastOperation lines carry "Qty. per Unit of Measure" = 0 on the Purchase Line itself (see
    // Subscriber A above - the real value is only restored on the Warehouse Activity Line).
    // Base app's item-tracking match check (ItemTrackingManagement.RegisterNewItemTrackingLines)
    // computes the source document line's remaining quantity directly off the Purchase Line
    // (PurchLineReserve.GetSourceValue -> "Outstanding Qty. (Base)" = "Outstanding Quantity" *
    // "Qty. per Unit of Measure"), which is therefore always 0 for these lines - causing a false
    // "Cannot match item tracking" error even when the assigned tracking quantity is correct.
    // Rather than disabling the check via AllowWhseOverpick (which would also let through
    // genuine overpicking), this subscriber recalculates QtyToHandleOnSourceDocLine using the
    // item's real Qty. per Unit of Measure, so the built-in check keeps protecting against
    // actual overpicking on these lines.
    // NOTE: The registered tracking quantity itself does not depend on this value - it is
    // computed by RegisterNewItemTrackingLines from TempTrackingSpecification."Qty. to Handle
    // (Base)" (derived from the correctly split Warehouse Activity Line tracking specs), so it
    // remains correct regardless of this fix.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError, '', false, false)]
    local procedure FixSourceDocLineQtyForSubcLastOperation_OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError(var TempTrackingSpecification: Record "Tracking Specification" temporary; var QtyToHandleToNewRegister: Decimal; var QtyToHandleInItemTracking: Decimal; var QtyToHandleOnSourceDocLine: Decimal; var IsHandled: Boolean; var AllowWhseOverpick: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        if TempTrackingSpecification."Source Type" <> Database::"Purchase Line" then
            exit;
        if not PurchaseLine.Get(Enum::"Purchase Document Type".FromInteger(TempTrackingSpecification."Source Subtype"), TempTrackingSpecification."Source ID", TempTrackingSpecification."Source Ref. No.") then
            exit;
        if PurchaseLine."Subc. Purchase Line Type" <> "Subc. Purchase Line Type"::LastOperation then
            exit;

        Item.SetLoadFields("No.", "Base Unit of Measure");
        Item.Get(PurchaseLine."No.");
        QtyToHandleOnSourceDocLine :=
            PurchaseLine."Outstanding Quantity" * UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");
    end;

    // Subscriber H: Suppress the mandatory item-tracking TestField("Qty. (Base)", 1)/Serial No./
    // Lot No. checks entirely for NotLastOperation lines. A NotLastOperation line always carries
    // "Qty. (Base)" = 0 (see Subscribers B/E above - there is nothing physical to track on this
    // line, the actual output is posted against the LastOperation line instead) and, per the
    // Item Tracking Lines UI block (Subscriber elsewhere blocking "Open Item Tracking Lines" for
    // NotLastOperation purchase lines), a Serial/Lot/Package No. can never legitimately be
    // assigned to it either - so there is nothing to test. Without this,
    // WarehouseActivityLine.TestTrackingIfRequired (called from Whse.-Activity-Post.
    // CheckItemTracking) unconditionally TestFields Qty. (Base) = 1 together with Serial/Lot No.,
    // blocking posting of every NotLastOperation line for a tracking-mandatory item.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeTestTrackingIfRequired, '', false, false)]
    local procedure SuppressTrackingTestFieldForNotLastOp_OnBeforeTestTrackingIfRequired(WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" <> "Subc. Purchase Line Type"::NotLastOperation then
            exit;

        IsHandled := true;
    end;

    // Subscriber I: Skip the Bin Mandatory physical checks (TestField("Bin Code") and the related
    // capacity check) in Whse.-Activity-Post.CheckWarehouseActivityLine for NotLastOperation
    // lines. A NotLastOperation line never posts a physical Warehouse Entry (see Subscriber B
    // above), so at a Bin Mandatory location without any resolvable Default Bin Code it should
    // remain postable with a blank Bin Code, mirroring the equivalent, pre-existing bypass for
    // Transfer WIP Item lines in "Subc. Invt. Pick Ext".Codeunit.al's
    // SkipPhysicalChecksForWipItemPickLine_OnBeforeCheckWarehouseActivityLine.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforeCheckWarehouseActivityLine, '', false, false)]
    local procedure SkipPhysicalChecksForNotLastOp_OnBeforeCheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
    end;

    // Subscriber J: Redirect the item-tracking reservation lookup performed while creating the
    // Inventory Put-away line from a Subcontracting LastOperation purchase line to the linked
    // Prod. Order Line instead of the Purchase Line itself.
    //
    // Background: subcontracting purchase lines that are linked to a production order can never
    // carry item tracking of their own - the base-app guard "Mfg. Purchase Document Mgt.".
    // OnOpenItemTrackingLinesOnAfterCheck unconditionally blocks opening "Item Tracking Lines" on
    // such a purchase line, and the real subcontracting UI flow instead assigns Serial/Lot/
    // Package No. against the *Prod. Order Line*'s own output tracking ("Subc. Purchase Line
    // Ext".OpenItemTrackingOfProdOrderLine). "Create Inventory Put-away".FindReservationFromPurchaseLine
    // only ever looks for a Reservation Entry with Source Type = Purchase Line
    // (FindReservationEntry(Database::"Purchase Line", ...)), which a Prod. Order Line-based
    // tracking assignment never creates - so the resulting Warehouse Activity Line is always
    // created untracked, forcing tracking to be assigned manually on the activity line after the
    // fact (and forcing a single, unsplit line even when several lots/serials were tracked).
    //
    // This mirrors the equivalent, already-shipped extensibility point base Manufacturing uses
    // for Prod. Output/Prod. Consumption put-away lines ("Mfg. Create Inventory Put-Away".
    // FindReservationFromProdOrderLine): it calls back into the running "Create Inventory
    // Put-away" instance (received here as the extra "sender" parameter, auto-bound by the
    // platform to the codeunit instance that raised the event even though it is not part of the
    // event's own declared signature) to populate that instance's private tracking-specification
    // buffer via the internal FindReservationEntry procedure, using the Prod. Order Line as the
    // reservation source instead of the Purchase Line. As a result the activity line(s) are
    // created already tracked - and automatically split into one line per lot/serial/package,
    // exactly as if the tracking had been assigned on the purchase line itself - eliminating the
    // need to assign Serial No./Lot No./Package No. by hand on the Warehouse Activity Line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", OnBeforeFindReservationFromPurchaseLine, '', false, false)]
    local procedure RedirectReservationLookupToProdOrderLine_OnBeforeFindReservationFromPurchaseLine(var PurchLine: Record "Purchase Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean; sender: Codeunit "Create Inventory Put-away")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not PurchLine.IsSubcontractingLineWithLastOperation(ProdOrderLine) then
            exit;

        ItemTrackingMgt.GetWhseItemTrkgSetup(PurchLine."No.", WhseItemTrackingSetup);
        if WhseItemTrackingSetup.TrackingRequired() then
            ReservationFound :=
                sender.FindReservationEntry(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        IsHandled := true;
    end;
}