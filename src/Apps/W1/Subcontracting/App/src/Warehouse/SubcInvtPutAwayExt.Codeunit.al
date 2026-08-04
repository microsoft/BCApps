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
    // Last-operation lines need the item's quantity per unit of measure for base-quantity calculation.
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

    // Only last-operation lines create physical warehouse entries during inventory put-away posting.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforePostWhseJnlLine, '', false, false)]
    local procedure SkipWhseJnlForNotLastOp_OnBeforePostWhseJnlLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
        if WarehouseActivityLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    // Warehouse put-away posting creates the required per-bin entries for subcontracting output.
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

    // Non-last-operation and WIP transfer lines intentionally retain zero base quantities.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeCalcQty, '', false, false)]
    local procedure SuppressCalcQtyTestFieldForNotLastOp_OnBeforeCalcQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyBase: Decimal; var NewQtyBase: Decimal; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
        if WarehouseActivityLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    // Last-operation lines retain the standard quantity-balance validation.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeValidateQuantityIsBalanced, '', false, false)]
    local procedure "Warehouse Activity Line_OnBeforeValidateQuantityIsBalanced"(var WhseActivLine: Record "Warehouse Activity Line"; xWhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
        if WhseActivLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
        if WhseActivLine."Transfer WIP Item" then
            IsHandled := true;
    end;
    // Preserve subcontracting source attributes for downstream warehouse posting rules.
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
    // Use the item's unit conversion when validating tracking against a last-operation source line.
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

    // Non-physical subcontracting lines do not represent trackable output.
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeTestTrackingIfRequired, '', false, false)]
    local procedure SuppressTrackingTestFieldForNotLastOp_OnBeforeTestTrackingIfRequired(WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
        if (WarehouseActivityLine."Subc. Purchase Line Type" <> "Subc. Purchase Line Type"::NotLastOperation) and
           not WarehouseActivityLine."Transfer WIP Item"
        then
            exit;

        IsHandled := true;
    end;

    // Non-last-operation lines do not require bin or capacity validation.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforeCheckWarehouseActivityLine, '', false, false)]
    local procedure SkipPhysicalChecksForNotLastOp_OnBeforeCheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
    end;

    // Last-operation tracking is stored on the linked production order line.
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