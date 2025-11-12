// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Journal;
using System.Reflection;

codeunit 99000822 "Mfg. Item Jnl.-Post Line"
{
    var
        Item: Record Item;
        Location: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        WhseJnlLine: Record "Warehouse Journal Line";
#if not CLEAN27
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
#endif
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        ACYMgt: Codeunit "Additional-Currency Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        WMSManagement: Codeunit "WMS Management";
        CannotBeLessThanZeroErr: Label 'cannot be less than zero';
        ItemTrackingSignErr: Label 'Item Tracking is signed wrongly.';
        MustNotDefineItemTrackingErr: Label 'You must not define item tracking on %1 %2.';

    // Consumption Posting

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnPostConsumption', '', true, true)]
    local procedure OnPostConsumption(
        var ItemJnlLine: Record "Item Journal Line"; GlobalItemTrackingSetup: Record "Item Tracking Setup"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary;
        var ProdOrderCompModified: Boolean; ItemLedgEntryNo: Integer; var sender: Codeunit "Item Jnl.-Post Line")
    begin
        PostConsumption(ItemJnlLine, GlobalItemTrackingSetup, TempSplitItemJnlLine, ProdOrderCompModified, ItemLedgEntryNo, sender);
    end;

    local procedure PostConsumption(var ItemJnlLine: Record "Item Journal Line"; GlobalItemTrackingSetup: Record "Item Tracking Setup"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary; var ProdOrderCompModified: Boolean; ItemLedgEntryNo: Integer; var sender: Codeunit "Item Jnl.-Post Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        MfgItemTrackingMgt: Codeunit "Mfg. Item Tracking Mgt.";
        RemQtyToPost: Decimal;
        RemQtyToPostThisLine: Decimal;
        QtyToPost: Decimal;
        UseItemTrackingApplication: Boolean;
        LastLoop: Boolean;
        EndLoop: Boolean;
        NewRemainingQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostConsumptionOnBeforeCheckOrderType(ProdOrderComp, ItemJnlLine, IsHandled);
#if not CLEAN27
        sender.RunOnPostConsumptionOnBeforeCheckOrderType(ProdOrderComp, ItemJnlLine, IsHandled);
#endif
        if not IsHandled then
            ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.", "Line No.");
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Prod. Order No.", ItemJnlLine."Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ItemJnlLine."Order Line No.");
        ProdOrderComp.SetRange("Item No.", ItemJnlLine."Item No.");
        if ItemJnlLine."Prod. Order Comp. Line No." <> 0 then
            ProdOrderComp.SetRange("Line No.", ItemJnlLine."Prod. Order Comp. Line No.");
        if ItemJnlLine."Variant Code" <> '' then
            ProdOrderComp.SetRange("Variant Code", ItemJnlLine."Variant Code");

        ProdOrderComp.LockTable();

        RemQtyToPost := ItemJnlLine.Quantity;

        OnPostConsumptionOnBeforeFindSetProdOrderComp(ProdOrderComp, ItemJnlLine);
#if not CLEAN27
        sender.RunOnPostConsumptionOnBeforeFindSetProdOrderComp(ProdOrderComp, ItemJnlLine);
#endif
        if ProdOrderComp.FindSet() then begin
            OnPostConsumptionOnAfterFindProdOrderComp(ProdOrderComp);
#if not CLEAN27
            sender.RunOnPostConsumptionOnAfterFindProdOrderComp(ProdOrderComp);
#endif
            if ItemJnlLine.TrackingExists() and not sender.GetSkipRetrieveItemTracking() then
                UseItemTrackingApplication :=
                  MfgItemTrackingMgt.RetrieveConsumpItemTracking(ItemJnlLine, TempHandlingSpecification);

            if UseItemTrackingApplication then begin
                TempHandlingSpecification.SetTrackingFilterFromItemJnlLine(ItemJnlLine);
                LastLoop := false;
            end else
                if ReservationExists(ItemJnlLine) then
                    ItemJnlLine.CheckTrackingIfRequiredNotBlank(GlobalItemTrackingSetup);

            repeat
                IsHandled := false;
                OnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(ProdOrderComp, ItemJnlLine, TempHandlingSpecification, RemQtyToPost, UseItemTrackingApplication, LastLoop, IsHandled);
#if not CLEAN27
                sender.RunOnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(ProdOrderComp, ItemJnlLine, TempHandlingSpecification, RemQtyToPost, UseItemTrackingApplication, LastLoop, IsHandled);
#endif
                if not IsHandled then
                    if UseItemTrackingApplication then begin
                        TempHandlingSpecification.SetRange("Source Ref. No.", ProdOrderComp."Line No.");
                        if LastLoop then begin
                            RemQtyToPostThisLine := ProdOrderComp."Remaining Qty. (Base)";
                            if TempHandlingSpecification.FindSet() then
                                repeat
                                    CheckItemTrackingOfComp(GlobalItemTrackingSetup, TempHandlingSpecification, ItemJnlLine);
                                    RemQtyToPostThisLine += TempHandlingSpecification."Qty. to Handle (Base)";
                                until TempHandlingSpecification.Next() = 0;
                            if RemQtyToPostThisLine * RemQtyToPost < 0 then
                                Error(ItemTrackingSignErr);
                        end else
                            if TempHandlingSpecification.FindFirst() then begin
                                RemQtyToPostThisLine := -TempHandlingSpecification."Qty. to Handle (Base)";
                                TempHandlingSpecification.Delete();
                            end else begin
                                TempHandlingSpecification.ClearTrackingFilter();
                                TempHandlingSpecification.FindFirst();
                                CheckItemTrackingOfComp(GlobalItemTrackingSetup, TempHandlingSpecification, ItemJnlLine);
                                RemQtyToPostThisLine := 0;
                            end;
                        if RemQtyToPostThisLine > RemQtyToPost then
                            RemQtyToPostThisLine := RemQtyToPost;
                    end else begin
                        RemQtyToPostThisLine := RemQtyToPost;
                        LastLoop := true;
                    end;

                QtyToPost := RemQtyToPostThisLine;
                ProdOrderComp.CalcFields("Act. Consumption (Qty)");
                NewRemainingQty := ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Act. Consumption (Qty)" - QtyToPost;
                OnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComp, NewRemainingQty, QtyToPost);
#if not CLEAN27
                sender.RunOnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComp, NewRemainingQty, QtyToPost);
#endif
                NewRemainingQty := Round(NewRemainingQty, UOMMgt.QtyRndPrecision());
                if (NewRemainingQty * ProdOrderComp."Expected Qty. (Base)") <= 0 then begin
                    QtyToPost := ProdOrderComp."Remaining Qty. (Base)";
                    ProdOrderComp."Remaining Qty. (Base)" := 0;
                end else begin
                    if (ProdOrderComp."Remaining Qty. (Base)" * ProdOrderComp."Expected Qty. (Base)") >= 0 then
                        QtyToPost := ProdOrderComp."Remaining Qty. (Base)" - NewRemainingQty
                    else
                        QtyToPost := NewRemainingQty;
                    ProdOrderComp."Remaining Qty. (Base)" := NewRemainingQty;
                end;

                IsHandled := false;
                OnPostConsumptionOnBeforeCalcRemainingQuantity(ProdOrderComp, ItemJnlLine, NewRemainingQty, QtyToPost, IsHandled, RemQtyToPost);
#if not CLEAN27
                sender.RunOnPostConsumptionOnBeforeCalcRemainingQuantity(ProdOrderComp, ItemJnlLine, NewRemainingQty, QtyToPost, IsHandled, RemQtyToPost);
#endif
                if not IsHandled then
                    ProdOrderComp."Remaining Quantity" := Round(ProdOrderComp."Remaining Qty. (Base)" / ProdOrderComp."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                UpdateQtyPickedForOptionalWhsePick(ProdOrderComp, QtyToPost + ProdOrderComp."Act. Consumption (Qty)");

                if QtyToPost <> 0 then begin
                    RemQtyToPost := RemQtyToPost - QtyToPost;
                    ProdOrderComp.Modify();
                    if ProdOrderCompModified then
                        InsertConsumpEntry(
                            ItemJnlLine, ProdOrderComp, ProdOrderComp."Line No.", QtyToPost, false, ItemLedgEntryNo,
                            TempSplitItemJnlLine, sender)
                    else
                        InsertConsumpEntry(
                            ItemJnlLine, ProdOrderComp, ProdOrderComp."Line No.", QtyToPost, true, ItemLedgEntryNo,
                            TempSplitItemJnlLine, sender);
                    OnPostConsumptionOnAfterInsertEntry(ProdOrderComp);
#if not CLEAN27
                    sender.RunOnPostConsumptionOnAfterInsertEntry(ProdOrderComp);
#endif
                end;

                if UseItemTrackingApplication then begin
                    if ProdOrderComp.Next() = 0 then begin
                        EndLoop := LastLoop;
                        LastLoop := true;
                        ProdOrderComp.Find('-');
                        TempHandlingSpecification.Reset();
                    end;
                end else
                    EndLoop := ProdOrderComp.Next() = 0;

            until EndLoop or (RemQtyToPost = 0);
        end;

        OnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(ItemJnlLine, ProdOrderComp);
#if not CLEAN27
        sender.RunOnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(ItemJnlLine, ProdOrderComp);
#endif
        if RemQtyToPost <> 0 then
            InsertConsumpEntry(
                ItemJnlLine, ProdOrderComp, ItemJnlLine."Prod. Order Comp. Line No.", RemQtyToPost, false,
                ItemLedgEntryNo, TempSplitItemJnlLine, sender);

        ProdOrderCompModified := false;

        OnAfterPostConsumption(ProdOrderComp, ItemJnlLine);
#if not CLEAN27
        sender.RunOnAfterPostConsumption(ProdOrderComp, ItemJnlLine);
#endif
    end;

    local procedure CheckItemTrackingOfComp(GlobalItemTrackingSetup: Record "Item Tracking Setup"; TempHandlingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    var
        ItemTrackingSetup2: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup2 := GlobalItemTrackingSetup;
        ItemTrackingSetup2.CopyTrackingFromTrackingSpec(TempHandlingSpecification);
        ItemJnlLine.CheckTrackingIfRequired(ItemTrackingSetup2);

        OnAfterCheckItemTrackingOfComp(TempHandlingSpecification, ItemJnlLine);
#if not CLEAN27
        ItemJnlPostLine.RunOnAfterCheckItemTrackingOfComp(TempHandlingSpecification, ItemJnlLine);
#endif
    end;

    local procedure InsertConsumpEntry(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderComp: Record "Prod. Order Component"; ProdOrderCompLineNo: Integer; QtyBase: Decimal; ModifyProdOrderComp: Boolean; ItemLedgEntryNo: Integer; var TempSplitItemJnlLine: Record "Item Journal Line" temporary; var sender: Codeunit "Item Jnl.-Post Line")
    var
        PostWhseJnlLine: Boolean;
    begin
        OnBeforeInsertConsumpEntry(ProdOrderComp, QtyBase, ModifyProdOrderComp, ItemJnlLine, TempSplitItemJnlLine);
#if not CLEAN27
        sender.RunOnBeforeInsertConsumpEntry(ProdOrderComp, QtyBase, ModifyProdOrderComp, ItemJnlLine, TempSplitItemJnlLine);
#endif

        ItemJnlLine.Quantity := QtyBase;
        ItemJnlLine."Quantity (Base)" := QtyBase;
        ItemJnlLine."Invoiced Quantity" := QtyBase;
        ItemJnlLine."Invoiced Qty. (Base)" := QtyBase;
        ItemJnlLine."Prod. Order Comp. Line No." := ProdOrderCompLineNo;
        if ModifyProdOrderComp then begin
            if not sender.GetCalledFromInvtPutawayPick() then
                ProdOrderCompReserve.TransferPOCompToItemJnlLine(ProdOrderComp, ItemJnlLine, QtyBase);
            OnBeforeProdOrderCompModify(ProdOrderComp, ItemJnlLine);
#if not CLEAN27
            sender.RunOnBeforeProdOrderCompModify(ProdOrderComp, ItemJnlLine);
#endif
            ProdOrderComp.Modify();
        end;

        if ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation then begin
            GetLocation(ItemJnlLine."Location Code");
            if Location."Bin Mandatory" and (not sender.GetCalledFromInvtPutawayPick()) then
                if Item.Get(ItemJnlLine."Item No.") and Item.IsInventoriableType() then begin
                    ProdOrderWarehouseMgt.CreateWhseJnlLineFromConsumptionJournal(ItemJnlLine, WhseJnlLine);
                    WMSManagement.CheckWhseJnlLine(WhseJnlLine, 3, 0, false);
                    PostWhseJnlLine := true;
                end;
        end;

        OnInsertConsumpEntryOnBeforePostItem(ItemJnlLine, ProdOrderComp, PostWhseJnlLine, WhseJnlLine);
#if not CLEAN27
        sender.RunOnInsertConsumpEntryOnBeforePostItem(ItemJnlLine, ProdOrderComp, PostWhseJnlLine, WhseJnlLine);
#endif

        sender.PostItem(ItemJnlLine);
        if PostWhseJnlLine then
            sender.RegisterWhseJnlLine(WhseJnlLine);

        OnAfterInsertConsumpEntry(WhseJnlLine, ProdOrderComp, QtyBase, PostWhseJnlLine, ItemJnlLine, ItemLedgEntryNo);
#if not CLEAN27
        sender.RunOnAfterInsertConsumpEntry(WhseJnlLine, ProdOrderComp, QtyBase, PostWhseJnlLine, ItemJnlLine, ItemLedgEntryNo);
#endif
    end;

    local procedure ReservationExists(ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ProductionOrder: Record "Production Order";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeReservationExists(ItemJnlLine, Result, IsHandled);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeReservationExists(ItemJnlLine, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        ReservEntry.SetRange("Source ID", ItemJnlLine."Order No.");
        if ItemJnlLine."Prod. Order Comp. Line No." <> 0 then
            ReservEntry.SetRange("Source Ref. No.", ItemJnlLine."Prod. Order Comp. Line No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
        ReservEntry.SetRange("Source Subtype", ProductionOrder.Status::Released);
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", ItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure UpdateQtyPickedForOptionalWhsePick(var ProdOrderComp: Record "Prod. Order Component"; QtyPosted: Decimal)
    begin
        GetLocation(ProdOrderComp."Location Code");
        if Location."Prod. Consump. Whse. Handling" <> Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)" then
            if ProdOrderComp."Qty. Picked (Base)" < QtyPosted then
                ProdOrderComp.Validate("Qty. Picked (Base)", QtyPosted);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingOfComp(TempHandlingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCheckOrderType(var ProdOrderComponent: Record "Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeFindSetProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderCompModify(var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumpEntryOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component"; PostWhseJnlLine: Boolean; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservationExists(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterFindProdOrderComp(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertConsumpEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ProdOrderComponent: Record "Prod. Order Component"; QtyBase: Decimal; PostWhseJnlLine: Boolean; var ItemJnlLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification"; RemQtyToPost: Decimal; UseItemTrackingApplication: Boolean; LastLoop: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCalcRemainingQuantity(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var NewRemainingQty: Decimal; var QtyToPost: Decimal; var IsHandled: Boolean; var RemQtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterInsertEntry(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostConsumption(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertConsumpEntry(var ProdOrderComponent: Record "Prod. Order Component"; QtyBase: Decimal; var ModifyProdOrderComp: Boolean; var ItemJnlLine: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComponent: Record "Prod. Order Component"; var NewRemainingQuantity: Decimal; QtyToPost: Decimal)
    begin
    end;

    // Output Posting

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnPostOutput', '', true, true)]
    local procedure OnPostOutput(
        var ItemJnlLine: Record "Item Journal Line"; GlobalItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemTrackingCode: Record "Item Tracking Code";
        var GlobalItemLedgerEntry: Record "Item Ledger Entry"; var LastOperation: Boolean; var sender: Codeunit "Item Jnl.-Post Line")
    begin
        PostOutput(ItemJnlLine, GlobalItemTrackingSetup, GlobalItemTrackingCode, GlobalItemLedgerEntry, LastOperation, sender);
    end;

    local procedure PostOutput(
        var ItemJnlLine: Record "Item Journal Line"; GlobalItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemTrackingCode: Record "Item Tracking Code";
        var GlobalItemLedgerEntry: Record "Item Ledger Entry"; var LastOperation: Boolean; var sender: Codeunit "Item Jnl.-Post Line")
    var
        MfgItem: Record Item;
        MfgSKU: Record "Stockkeeping Unit";
        CapLedgEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLineSubContracting: Record "Item Journal Line";
        DirCostAmt: Decimal;
        IndirCostAmt: Decimal;
        ValuedQty: Decimal;
        MfgUnitCost: Decimal;
        ReTrack: Boolean;
        PostWhseJnlLine: Boolean;
        SkipPost: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforePostOutput(ItemJnlLine);
#if not CLEAN27
        sender.RunOnBeforePostOutput(ItemJnlLine);
#endif

        if ItemJnlLine."Stop Time" <> 0 then begin
            sender.InsertCapLedgEntry(ItemJnlLine, CapLedgEntry, ItemJnlLine."Stop Time", ItemJnlLine."Stop Time");
            SkipPost := ItemJnlLine.OnlyStopTime();
            OnPostOutputOnAfterInsertCapLedgEntry(ItemJnlLine, SkipPost);
#if not CLEAN27
            sender.RunOnPostOutputOnAfterInsertCapLedgEntry(ItemJnlLine, SkipPost);
#endif
            if SkipPost then
                exit;
        end;

        if ItemJnlLine.OutputValuePosting() then begin
            sender.PostItem(ItemJnlLine);
            exit;
        end;

        if ItemJnlLine.Subcontracting then
            ValuedQty := ItemJnlLine."Invoiced Quantity"
        else
            ValuedQty := CalcCapQty(ItemJnlLine);

        if GetItem(ItemJnlLine."Item No.", false) then
            if not sender.GetCalledFromAdjustment() then
                Item.TestField("Inventory Value Zero", false);

        if ItemJnlLine."Item Shpt. Entry No." <> 0 then
            CapLedgEntry.Get(ItemJnlLine."Item Shpt. Entry No.")
        else
            PostOutputForProdOrder(
                ItemJnlLine, ProdOrder, ProdOrderLine, CapLedgEntry, ValuedQty, LastOperation,
                GlobalItemTrackingSetup, GlobalItemTrackingCode, sender);

        sender.CalcDirAndIndirCostAmts(DirCostAmt, IndirCostAmt, ValuedQty, ItemJnlLine);

        OnPostOutputOnBeforeInsertCostValueEntries(ItemJnlLine, CapLedgEntry, ValuedQty, DirCostAmt, IndirCostAmt);
#if not CLEAN27
        sender.RunOnPostOutputOnBeforeInsertCostValueEntries(ItemJnlLine, CapLedgEntry, ValuedQty, DirCostAmt, IndirCostAmt);
#endif
        sender.InsertCapValueEntry(ItemJnlLine, CapLedgEntry, ItemJnlLine."Value Entry Type"::"Direct Cost", ValuedQty, ValuedQty, DirCostAmt);
        sender.InsertCapValueEntry(ItemJnlLine, CapLedgEntry, ItemJnlLine."Value Entry Type"::"Indirect Cost", ValuedQty, 0, IndirCostAmt);

        OnPostOutputOnAfterInsertCostValueEntries(ItemJnlLine, CapLedgEntry, sender.GetCalledFromAdjustment(), sender.GetPostToGL());
#if not CLEAN27
        sender.RunOnPostOutputOnAfterInsertCostValueEntries(ItemJnlLine, CapLedgEntry, sender.GetCalledFromAdjustment(), sender.GetPostToGL());
#endif

        if LastOperation and (ItemJnlLine."Output Quantity" <> 0) then begin
            sender.CheckItemTracking(ItemJnlLine);
            if (ItemJnlLine."Output Quantity" < 0) and not ItemJnlLine.Adjustment then begin
                if ItemJnlLine."Applies-to Entry" = 0 then
                    ItemJnlLine."Applies-to Entry" := FindOpenOutputEntryNoToApply(ItemJnlLine);
                ItemJnlLine.TestField("Applies-to Entry");
                ItemLedgerEntry.Get(ItemJnlLine."Applies-to Entry");
                ItemJnlLine.CheckTrackingEqualItemLedgEntry(ItemLedgerEntry);
            end;

            IsHandled := false;
            OnPostOutputOnBeforeGetMfgAmounts(ItemJnlLine, ProdOrder, IsHandled);
#if not CLEAN27
            sender.RunOnPostOutputOnBeforeGetMfgAmounts(ItemJnlLine, ProdOrder, IsHandled);
#endif
            if not IsHandled then begin
                MfgItem.Get(ProdOrderLine."Item No.");
                MfgItem.TestField("Gen. Prod. Posting Group");
                if ItemJnlLine.Subcontracting then
                    MfgUnitCost := ProdOrderLine."Unit Cost" / ProdOrderLine."Qty. per Unit of Measure"
                else
                    if MfgSKU.Get(ProdOrderLine."Location Code", ProdOrderLine."Item No.", ProdOrderLine."Variant Code") then
                        MfgUnitCost := MfgSKU."Unit Cost"
                    else
                        MfgUnitCost := MfgItem."Unit Cost";
                OnPostOutputOnAfterSetMfgUnitCost(ItemJnlLine, MfgUnitCost, ProdOrderLine);
#if not CLEAN27
                sender.RunOnPostOutputOnAfterSetMfgUnitCost(ItemJnlLine, MfgUnitCost, ProdOrderLine);
#endif

                ItemJnlLine.Amount := ItemJnlLine."Output Quantity" * MfgUnitCost;
                ItemJnlLine."Amount (ACY)" := ACYMgt.CalcACYAmt(ItemJnlLine.Amount, ItemJnlLine."Posting Date", false);
                OnPostOutputOnAfterUpdateAmounts(ItemJnlLine);
#if not CLEAN27
                sender.RUnOnPostOutputOnAfterUpdateAmounts(ItemJnlLine);
#endif

                ItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
                ItemJnlLine."Gen. Prod. Posting Group" := MfgItem."Gen. Prod. Posting Group";
                if ItemJnlLine."Output Quantity (Base)" * ProdOrderLine."Remaining Qty. (Base)" <= 0 then
                    ReTrack := true
                else
                    if not sender.GetCalledFromInvtPutawayPick() then
                        ProdOrderLineReserve.TransferPOLineToItemJnlLine(
                        ProdOrderLine, ItemJnlLine, ItemJnlLine."Output Quantity (Base)");
            end;

            PostWhseJnlLine := true;
            OnPostOutputOnBeforeCreateWhseJnlLine(ItemJnlLine, PostWhseJnlLine);
#if not CLEAN27
            sender.RunOnPostOutputOnBeforeCreateWhseJnlLine(ItemJnlLine, PostWhseJnlLine);
#endif
            if PostWhseJnlLine then begin
                GetLocation(ItemJnlLine."Location Code");
                if Location."Bin Mandatory" and (not sender.GetCalledFromInvtPutawayPick()) then
                    if not Item.Get(ItemJnlLine."Item No.") or Item.IsInventoriableType() then begin
                        ProdOrderWarehouseMgt.CreateWhseJnlLineFromOutputJournal(ItemJnlLine, WhseJnlLine);
                        WMSManagement.CheckWhseJnlLine(WhseJnlLine, 2, 0, false);
                    end;
            end;
            OnPostOutputOnAfterCreateWhseJnlLine(ItemJnlLine);
#if not CLEAN27
            sender.RunOnPostOutputOnAfterCreateWhseJnlLine(ItemJnlLine);
#endif

            if ItemJnlLine.Subcontracting and ItemJnlLine.Correction then
                ItemJnlLineSubContracting := ItemJnlLine;

            ItemJnlLine.Description := ProdOrderLine.Description;
            if ItemJnlLine.Subcontracting then begin
                ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::" ";
                ItemJnlLine."Document No." := ItemJnlLine."Order No.";
                ItemJnlLine."Document Line No." := 0;
                ItemJnlLine."Invoiced Quantity" := 0;
            end;

            IsHandled := false;
            OnPostOutputOnBeforePostItem(ItemJnlLine, ProdOrderLine, IsHandled);
#if not CLEAN27
            sender.RunOnPostOutputOnBeforePostItem(ItemJnlLine, ProdOrderLine, IsHandled);
#endif
            if not IsHandled then
                sender.PostItem(ItemJnlLine);

            IsHandled := false;
            OnPostOutputOnBeforeUpdateProdOrderLine(ItemJnlLine, IsHandled);
#if not CLEAN27
            sender.RunOnPostOutputOnBeforeUpdateProdOrderLine(ItemJnlLine, IsHandled);
#endif
            if not IsHandled then begin
                UpdateProdOrderLine(ItemJnlLine, ProdOrderLine, ReTrack, sender.GetItemLedgerEntryNo());
                OnPostOutputOnAfterUpdateProdOrderLine(ItemJnlLine, WhseJnlLine, GlobalItemLedgerEntry);
#if not CLEAN27
                sender.RunOnPostOutputOnAfterUpdateProdOrderLine(ItemJnlLine, WhseJnlLine, GlobalItemLedgerEntry);
#endif
            end;

            if PostWhseJnlLine then
                if Location."Bin Mandatory" and (not sender.GetCalledFromInvtPutawayPick()) then
                    sender.RegisterWhseJnlLine(WhseJnlLine);

            if ItemJnlLine.Subcontracting and ItemJnlLine.Correction then begin
                ItemJnlLine."Document Type" := ItemJnlLineSubContracting."Document Type";
                ItemJnlLine."Document No." := ItemJnlLineSubContracting."Document No.";
                ItemJnlLine."Document Line No." := ItemJnlLineSubContracting."Document Line No.";
                ItemJnlLine.Description := ItemJnlLineSubContracting.Description;
            end;
        end;

        OnAfterPostOutput(GlobalItemLedgerEntry, ProdOrderLine, ItemJnlLine);
#if not CLEAN27
        sender.RunOnAfterPostOutput(GlobalItemLedgerEntry, ProdOrderLine, ItemJnlLine);
#endif
    end;

    local procedure GetItem(ItemNo: Code[20]; ForceGetItem: Boolean): Boolean
    var
        HasGotItem: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItem(Item, ItemNo, ForceGetItem, HasGotItem, IsHandled);
        if IsHandled then
            exit(HasGotItem);

        Item.ReadIsolation(IsolationLevel::ReadUncommitted);
        if not ForceGetItem then
            exit(Item.Get(ItemNo));

        Item.Get(ItemNo);
        exit(true);
    end;

    local procedure PostOutputForProdOrder(
        var ItemJnlLine: Record "Item Journal Line"; var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line";
        var CapLedgEntry: Record "Capacity Ledger Entry"; ValuedQty: Decimal; var LastOperation: Boolean;
        GlobalItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemTrackingCode: Record "Item Tracking Code";
        var sender: Codeunit "Item Jnl.-Post Line")
    var
        MachCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ShouldFlushOperation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostOutputForProdOrder(ItemJnlLine, LastOperation, IsHandled);
#if not CLEAN27
        sender.RunOnBeforePostOutputForProdOrder(ItemJnlLine, LastOperation, IsHandled);
#endif
        if IsHandled then
            exit;

        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        GetOutputProdOrder(ItemJnlLine, ProdOrder);
        ProdOrder.TestField(Blocked, false);
        ProdOrderLine.LockTable();
        GetOutputProdOrderLine(ItemJnlLine, ProdOrderLine);

        ItemJnlLine."Inventory Posting Group" := ProdOrderLine."Inventory Posting Group";

        ProdOrderRtngLine.SetRange(Status, ProdOrderRtngLine.Status::Released);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ItemJnlLine."Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ItemJnlLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Routing No.", ItemJnlLine."Routing No.");
        OnPostOutputOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine);
#if not CLEAN27
        sender.RunOnPostOutputOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine);
#endif
        if not ProdOrderRtngLine.IsEmpty() then begin
            ItemJnlLine.TestField("Operation No.");
            ItemJnlLine.TestField("No.");

            if ItemJnlLine.Type = "Capacity Type Journal"::"Machine Center" then begin
                MachCenter.Get(ItemJnlLine."No.");
                MachCenter.TestField(Blocked, false);
            end;
            WorkCenter.Get(ItemJnlLine."Work Center No.");
            WorkCenter.TestField(Blocked, false);

            ApplyCapNeed(ItemJnlLine, ItemJnlLine."Setup Time (Base)", ItemJnlLine."Run Time (Base)");
            OnPostOutputForProdOrderOnAfterApplyCapNeed(ItemJnlLine, ValuedQty);
#if not CLEAN27
            sender.RunOnPostOutputForProdOrderOnAfterApplyCapNeed(ItemJnlLine, ValuedQty);
#endif
        end;

        if ItemJnlLine."Operation No." <> '' then
            PostOutputUpdateProdOrderRtngLine(ItemJnlLine, ProdOrderLine, LastOperation)
        else
            LastOperation := true;

        if ItemJnlLine.Subcontracting then
            sender.InsertCapLedgEntry(ItemJnlLine, CapLedgEntry, ItemJnlLine.Quantity, ItemJnlLine."Invoiced Quantity")
        else
            sender.InsertCapLedgEntry(ItemJnlLine, CapLedgEntry, ValuedQty, ValuedQty);

        ShouldFlushOperation := ItemJnlLine."Output Quantity" >= 0;
        OnBeforeCallFlushOperation(ItemJnlLine, ShouldFlushOperation);
#if not CLEAN27
        sender.RunOnBeforeCallFlushOperation(ItemJnlLine, ShouldFlushOperation);
#endif
        if ShouldFlushOperation then
            FlushOperation(
                ItemJnlLine, ProdOrder, ProdOrderLine, GlobalItemTrackingSetup, GlobalItemTrackingCode, LastOperation, sender);
    end;

    local procedure GetOutputProdOrder(var ItemJnlLine: Record "Item Journal Line"; var ProdOrder: Record "Production Order")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOutputProdOrder(ProdOrder, ItemJnlLine, IsHandled);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeGetOutputProdOrder(ProdOrder, ItemJnlLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrder.Get(ProdOrder.Status::Released, ItemJnlLine."Order No.");
    end;

    local procedure GetOutputProdOrderLine(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOutputProdOrderLine(ProdOrderLine, ItemJnlLine, IsHandled);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeGetOutputProdOrderLine(ProdOrderLine, ItemJnlLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemJnlLine."Order No.", ItemJnlLine."Order Line No.");
    end;

    local procedure GetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderRoutingLine(ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeGetProdOrderRoutingLine(ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderRoutingLine.Get(
          ProdOrderRoutingLine.Status::Released, OldItemJnlLine."Order No.",
          OldItemJnlLine."Routing Reference No.", OldItemJnlLine."Routing No.", OldItemJnlLine."Operation No.");
    end;

    local procedure PostOutputUpdateProdOrderRtngLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; var LastOperation: Boolean)
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostOutputUpdateProdOrderRtngLine(ProdOrderRtngLine, ItemJnlLine, IsHandled);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforePostOutputUpdateProdOrderRtngLine(ProdOrderRtngLine, ItemJnlLine, IsHandled);
#endif
        if IsHandled then
            exit;

        GetProdOrderRoutingLine(ProdOrderRtngLine, ItemJnlLine);
        if ItemJnlLine.Finished then
            ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::Finished
        else
            ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::"In Progress";
        LastOperation := (not NextOperationExist(ProdOrderRtngLine));
        OnPostOutputOnBeforeProdOrderRtngLineModify(ProdOrderRtngLine, ProdOrderLine, ItemJnlLine, LastOperation);
#if not CLEAN27
        ItemJnlPostLine.RunOnPostOutputOnBeforeProdOrderRtngLineModify(ProdOrderRtngLine, ProdOrderLine, ItemJnlLine, LastOperation);
#endif 
        ProdOrderRtngLine.Modify();
    end;

    local procedure NextOperationExist(var ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    begin
        OnBeforeNextOperationExist(ProdOrderRtngLine);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeNextOperationExist(ProdOrderRtngLine);
#endif
        exit(ProdOrderRtngLine."Next Operation No." <> '');
    end;

    local procedure CalcCapQty(var ItemJnlLine: Record "Item Journal Line") CapQty: Decimal
    begin
        ManufacturingSetup.Get();

        if ItemJnlLine."Unit Cost Calculation" = ItemJnlLine."Unit Cost Calculation"::Time then begin
            if ManufacturingSetup."Cost Incl. Setup" then
                CapQty := ItemJnlLine."Setup Time" + ItemJnlLine."Run Time"
            else
                CapQty := ItemJnlLine."Run Time";
        end else
            CapQty := ItemJnlLine.Quantity + ItemJnlLine."Scrap Quantity";

        OnAfterCalcCapQty(ItemJnlLine, CapQty);
#if not CLEAN27
        ItemJnlPostLine.RunOnAfterCalcCapQty(ItemJnlLine, CapQty);
#endif
    end;

    local procedure ApplyCapNeed(var ItemJnlLine: Record "Item Journal Line"; PostedSetupTime: Decimal; PostedRunTime: Decimal)
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        TypeHelper: Codeunit "Type Helper";
        TimeToAllocate: Decimal;
        PrevSetupTime: Decimal;
        PrevRunTime: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnApplyCapNeed(ItemJnlLine, PostedSetupTime, PostedRunTime, IsHandled);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeOnApplyCapNeed(ItemJnlLine, PostedSetupTime, PostedRunTime, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderCapNeed.LockTable();
        ProdOrderCapNeed.Reset();
        ProdOrderCapNeed.SetCurrentKey(
          Status, "Prod. Order No.", "Routing Reference No.", "Operation No.", Date, "Starting Time");
        ProdOrderCapNeed.SetRange(Status, ProdOrderCapNeed.Status::Released);
        ProdOrderCapNeed.SetRange("Prod. Order No.", ItemJnlLine."Order No.");
        ProdOrderCapNeed.SetRange("Requested Only", false);
        ProdOrderCapNeed.SetRange("Routing No.", ItemJnlLine."Routing No.");
        ProdOrderCapNeed.SetRange("Routing Reference No.", ItemJnlLine."Routing Reference No.");
        ProdOrderCapNeed.SetRange("Operation No.", ItemJnlLine."Operation No.");

        if ItemJnlLine.Finished then
            ProdOrderCapNeed.ModifyAll("Allocated Time", 0)
        else begin
            OnApplyCapNeedOnAfterSetFilters(ProdOrderCapNeed, ItemJnlLine);
#if not CLEAN27
            ItemJnlPostLine.RunOnApplyCapNeedOnAfterSetFilters(ProdOrderCapNeed, ItemJnlLine);
#endif
            CalcCapLedgerEntriesSetupRunTime(ItemJnlLine, PrevSetupTime, PrevRunTime);

            if PostedSetupTime <> 0 then begin
                ProdOrderCapNeed.SetRange("Time Type", ProdOrderCapNeed."Time Type"::"Setup Time");
                PostedSetupTime += PrevSetupTime;
                if ProdOrderCapNeed.FindSet() then
                    repeat
                        TimeToAllocate := TypeHelper.Minimum(ProdOrderCapNeed."Needed Time", PostedSetupTime);
                        ProdOrderCapNeed."Allocated Time" := ProdOrderCapNeed."Needed Time" - TimeToAllocate;
                        ProdOrderCapNeed.Modify();
                        PostedSetupTime -= TimeToAllocate;
                    until ProdOrderCapNeed.Next() = 0;
            end;

            if PostedRunTime <> 0 then begin
                ProdOrderCapNeed.SetRange("Time Type", ProdOrderCapNeed."Time Type"::"Run Time");
                PostedRunTime += PrevRunTime;
                if ProdOrderCapNeed.FindSet() then
                    repeat
                        TimeToAllocate := TypeHelper.Minimum(ProdOrderCapNeed."Needed Time", PostedRunTime);
                        ProdOrderCapNeed."Allocated Time" := ProdOrderCapNeed."Needed Time" - TimeToAllocate;
                        ProdOrderCapNeed.Modify();
                        PostedRunTime -= TimeToAllocate;
                    until ProdOrderCapNeed.Next() = 0;
            end;
        end;
    end;

    local procedure CalcCapLedgerEntriesSetupRunTime(var ItemJnlLine: Record "Item Journal Line"; var TotalSetupTime: Decimal; var TotalRunTime: Decimal)
    var
        CapLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgerEntry.SetCurrentKey(
          "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
        CapLedgerEntry.SetRange("Order Type", CapLedgerEntry."Order Type"::Production);
        CapLedgerEntry.SetRange("Order No.", ItemJnlLine."Order No.");
        CapLedgerEntry.SetRange("Order Line No.", ItemJnlLine."Order Line No.");
        CapLedgerEntry.SetRange("Routing No.", ItemJnlLine."Routing No.");
        CapLedgerEntry.SetRange("Routing Reference No.", ItemJnlLine."Routing Reference No.");
        CapLedgerEntry.SetRange("Operation No.", ItemJnlLine."Operation No.");
        OnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(CapLedgerEntry, ItemJnlLine);
#if not CLEAN27
        ItemJnlPostLine.RunOnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(CapLedgerEntry, ItemJnlLine);
#endif

        CapLedgerEntry.CalcSums("Setup Time", "Run Time");
        TotalSetupTime := CapLedgerEntry."Setup Time";
        TotalRunTime := CapLedgerEntry."Run Time";
    end;

    local procedure UpdateProdOrderLine(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; ReTrack: Boolean; ItemLedgEntryNo: Integer)
    var
        ReservMgt: Codeunit "Reservation Management";
    begin
        OnBeforeUpdateProdOrderLine(ProdOrderLine, ItemJnlLine, ReTrack);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeUpdateProdOrderLine(ProdOrderLine, ItemJnlLine, ReTrack);
#endif

        if ItemJnlLine."Output Quantity (Base)" > ProdOrderLine."Remaining Qty. (Base)" then
            ProdOrderLineReserve.AssignForPlanning(ProdOrderLine);
        ProdOrderLine."Finished Qty. (Base)" := ProdOrderLine."Finished Qty. (Base)" + ItemJnlLine."Output Quantity (Base)";
        ProdOrderLine."Finished Quantity" := ProdOrderLine."Finished Qty. (Base)" / ProdOrderLine."Qty. per Unit of Measure";
        if ProdOrderLine."Finished Qty. (Base)" < 0 then
            ProdOrderLine.FieldError("Finished Quantity", CannotBeLessThanZeroErr);
        ProdOrderLine."Remaining Qty. (Base)" := ProdOrderLine."Quantity (Base)" - ProdOrderLine."Finished Qty. (Base)";
        if ProdOrderLine."Remaining Qty. (Base)" < 0 then
            ProdOrderLine."Remaining Qty. (Base)" := 0;
        ProdOrderLine."Remaining Quantity" := ProdOrderLine."Remaining Qty. (Base)" / ProdOrderLine."Qty. per Unit of Measure";
        OnBeforeProdOrderLineModify(ProdOrderLine, ItemJnlLine, ItemLedgEntryNo);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeProdOrderLineModify(ProdOrderLine, ItemJnlLine, ItemLedgEntryNo);
#endif
        ProdOrderLine.Modify();

        if ReTrack then begin
            ReservMgt.SetReservSource(ProdOrderLine);
            ReservMgt.ClearSurplus();
            ReservMgt.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
        end;

        OnAfterUpdateProdOrderLine(ProdOrderLine, ReTrack, ItemJnlLine);
#if not CLEAN27
        ItemJnlPostLine.RunOnAfterUpdateProdOrderLine(ProdOrderLine, ReTrack, ItemJnlLine);
#endif
    end;

    local procedure FlushOperation(
        var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line";
        var GlobalItemTrackingSetup: Record "Item Tracking Setup"; var GlobalItemTrackingCode: Record "Item Tracking Code";
        LastOperation: Boolean; var sender: Codeunit "Item Jnl.-Post Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        ItemJnlLineSaved: Record "Item Journal Line";
        TempSplitItemJnlLineSaved: Record "Item Journal Line" temporary;
        ItemTrackingCodeSaved: Record "Item Tracking Code";
        ItemTrackingSetupSaved: Record "Item Tracking Setup";
        xCalledFromInvtPutawayPick: Boolean;
    begin
        OnBeforeFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine, LastOperation);
#if not CLEAN27
        sender.RunOnBeforeFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine, LastOperation);
#endif

        if ItemJnlLine."Operation No." = '' then
            exit;

        ItemJnlLineSaved := ItemJnlLine;
        TempSplitItemJnlLineSaved.Reset();
        TempSplitItemJnlLineSaved.DeleteAll();
        sender.SaveTempSplitItemJnlLine(TempSplitItemJnlLineSaved);
        ItemTrackingSetupSaved := GlobalItemTrackingSetup;
        ItemTrackingCodeSaved := GlobalItemTrackingCode;
        xCalledFromInvtPutawayPick := sender.GetCalledFromInvtPutawayPick();
        sender.SetCalledFromInvtPutawayPick(false);

        GetProdOrderRoutingLine(ProdOrderRoutingLine, ItemJnlLineSaved);
        OnFlushOperationOnBeforeCheckRoutingLinkCode(ProdOrder, ProdOrderLine, ProdOrderRoutingLine, ItemJnlLine, LastOperation);
#if not CLEAN27
        sender.RunOnFlushOperationOnBeforeCheckRoutingLinkCode(ProdOrder, ProdOrderLine, ProdOrderRoutingLine, ItemJnlLine, LastOperation);
#endif
        if ProdOrderRoutingLine."Routing Link Code" <> '' then begin
            ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code", "Flushing Method");
            ProdOrderComp.SetRange("Flushing Method", ProdOrderComp."Flushing Method"::Forward, ProdOrderComp."Flushing Method"::"Pick + Backward");
            ProdOrderComp.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
            ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
            ProdOrderComp.SetRange("Prod. Order No.", ItemJnlLineSaved."Order No.");
            ProdOrderComp.SetRange("Prod. Order Line No.", ItemJnlLineSaved."Order Line No.");
            OnFlushOperationOnAfterProdOrderCompSetFilters(ProdOrderComp, ItemJnlLineSaved, ProdOrderRoutingLine);
#if not CLEAN27
            sender.RunOnFlushOperationOnAfterProdOrderCompSetFilters(ProdOrderComp, ItemJnlLineSaved, ProdOrderRoutingLine);
#endif
            if ProdOrderComp.FindSet() then begin
                sender.SetSkipRetrieveItemTracking(true);
                repeat
                    PostFlushedConsumption(
                        ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, ItemJnlLineSaved, sender);
                until ProdOrderComp.Next() = 0;
                sender.SetSkipRetrieveItemTracking(false);
            end;
        end;

        ItemJnlLine := ItemJnlLineSaved;
        sender.RestoreTempSplitItemJnlLine(TempSplitItemJnlLineSaved);
        sender.SetGlobalItemTrackingCode(ItemTrackingCodeSaved);
        sender.SetGlobalItemTrackingSetup(ItemTrackingSetupSaved);
        sender.SetCalledFromInvtPutawayPick(xCalledFromInvtPutawayPick);

        OnAfterFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine);
#if not CLEAN27
        sender.RunOnAfterFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine);
#endif
    end;

    procedure PostFlushedConsumption(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var sender: Codeunit "Item Jnl.-Post Line")
    var
        CompItem: Record Item;
        TempTrackingSpecificationSaved: Record "Tracking Specification" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        OutputQtyBase: Decimal;
        QtyToPost: Decimal;
        CalcBasedOn: Option "Actual Output","Expected Output";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostFlushedConsump(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
#if not CLEAN27
        sender.RunOnBeforePostFlushedConsump(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
#endif
        if IsHandled then
            exit;

        OutputQtyBase := OldItemJnlLine."Output Quantity (Base)" + OldItemJnlLine."Scrap Quantity (Base)";

        CompItem.Get(ProdOrderComp."Item No.");
        CompItem.TestField("Rounding Precision");

        OnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, OutputQtyBase);
#if not CLEAN27
        sender.RunOnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, OutputQtyBase);
#endif
        if ProdOrderComp."Flushing Method" in
           [ProdOrderComp."Flushing Method"::Backward, ProdOrderComp."Flushing Method"::"Pick + Backward"]
        then begin
            QtyToPost :=
              MfgCostCalcMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComp, OutputQtyBase) / ProdOrderComp."Qty. per Unit of Measure";
            if (ProdOrderLine."Remaining Qty. (Base)" = OutputQtyBase) and
               (ProdOrderComp."Remaining Quantity" <> 0) and
               (Abs(Round(QtyToPost, CompItem."Rounding Precision") - ProdOrderComp."Remaining Quantity") <= CompItem."Rounding Precision") and
               (Abs(Round(QtyToPost, CompItem."Rounding Precision") - ProdOrderComp."Remaining Quantity") < 1) or
               (OutputQtyBase = Round(ProdOrderComp."Remaining Qty. (Base)", 1))
            then
                QtyToPost := ProdOrderComp."Remaining Quantity";
        end else
            QtyToPost := ProdOrderComp.GetNeededQty(CalcBasedOn::"Expected Output", true);
        QtyToPost := UOMMgt.RoundToItemRndPrecision(QtyToPost, CompItem."Rounding Precision");
        OnPostFlushedConsumpOnAfterCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, OutputQtyBase, QtyToPost, OldItemJnlLine, ProdOrderRoutingLine, CompItem);
#if not CLEAN27
        sender.RunOnPostFlushedConsumpOnAfterCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, OutputQtyBase, QtyToPost, OldItemJnlLine, ProdOrderRoutingLine, CompItem);
#endif
        if QtyToPost = 0 then
            exit;

        ManufacturingSetup.Get();
        SourceCodeSetup.Get();

        ItemJnlLine.Init();
        ItemJnlLine."Line No." := 0;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Consumption;
        ItemJnlLine.Validate("Posting Date", OldItemJnlLine."Posting Date");
        if ManufacturingSetup."Doc. No. Is Prod. Order No." then
            ItemJnlLine."Document No." := ProdOrderLine."Prod. Order No."
        else
            ItemJnlLine."Document No." := OldItemJnlLine."Document No.";
        ItemJnlLine."Source No." := ProdOrderLine."Item No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Production;
        ItemJnlLine."Order No." := ProdOrderLine."Prod. Order No.";
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJnlLine.Validate("Item No.", ProdOrderComp."Item No.");
        ItemJnlLine.Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        ItemJnlLine.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
        ItemJnlLine.Description := ProdOrderComp.Description;
        ItemJnlLine.Validate(Quantity, QtyToPost);
        ItemJnlLine.Validate("Unit Cost", ProdOrderComp."Unit Cost");
        ItemJnlLine."Location Code" := ProdOrderComp."Location Code";
        ItemJnlLine."Bin Code" := ProdOrderComp."Bin Code";
        ItemJnlLine."Variant Code" := ProdOrderComp."Variant Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Flushing;
        ItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := CompItem."Gen. Prod. Posting Group";
        OnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(ItemJnlLine, OldItemJnlLine, ProdOrderLine, ProdOrderComp, CompItem);
#if not CLEAN27
        sender.RunOnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(ItemJnlLine, OldItemJnlLine, ProdOrderLine, ProdOrderComp, CompItem);
#endif

        TempTrackingSpecificationSaved.Reset();
        TempTrackingSpecificationSaved.DeleteAll();
        sender.SaveTempTrackingSpecification(TempTrackingSpecificationSaved);

        OnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJnlLine, ProdOrderComp);
#if not CLEAN27
        sender.RunOnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJnlLine, ProdOrderComp);
#endif
        ProdOrderCompReserve.TransferPOCompToItemJnlLine(
          ProdOrderComp, ItemJnlLine, Round(QtyToPost * ProdOrderComp."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));

        OnBeforePostFlushedConsumpItemJnlLine(ItemJnlLine);
#if not CLEAN27
        sender.RunOnBeforePostFlushedConsumpItemJnlLine(ItemJnlLine);
#endif
        sender.PostFlushedConsumptionItemJnlLine(
            ItemJnlLine, GetCombinedDimSetID(ProdOrderLine."Dimension Set ID", ProdOrderComp."Dimension Set ID"));

        sender.RestoreTempTrackingSpecification(TempTrackingSpecificationSaved);

        OnAfterPostFlushedConsump(ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine);
#if not CLEAN27
        sender.RunOnAfterPostFlushedConsump(ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine);
#endif
    end;

    local procedure GetCombinedDimSetID(DimSetID1: Integer; DimSetID2: Integer): Integer
    var
        DimMgt: Codeunit DimensionManagement;
        DummyGlobalDimCode: array[2] of Code[20];
        DimID: array[10] of Integer;
    begin
        DimID[1] := DimSetID1;
        DimID[2] := DimSetID2;
        exit(DimMgt.GetCombinedDimensionSetID(DimID, DummyGlobalDimCode[1], DummyGlobalDimCode[2]));
    end;

    local procedure FindOpenOutputEntryNoToApply(ItemJournalLine: Record "Item Journal Line"): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not ItemJournalLine.TrackingExists() then
            exit(0);

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ItemJournalLine."Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", ItemJournalLine."Order Line No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", 0);
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Location Code", ItemJournalLine."Location Code");
        ItemLedgerEntry.SetTrackingFilterFromItemJournalLine(ItemJournalLine);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>=%1', -ItemJournalLine."Output Quantity (Base)");
        if not ItemLedgerEntry.IsEmpty() then
            if ItemLedgerEntry.Count = 1 then begin
                ItemLedgerEntry.FindFirst();
                exit(ItemLedgerEntry."Entry No.");
            end;

        exit(0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetOrderAdjmtPropertiesForProduction', '', true, true)]
    local procedure OnSetOrderAdjmtPropertiesForProduction(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OrderNo: Code[20]; OrderLineNo: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        GetProdOrderLine(ProdOrderLine, OrderNo, OrderLineNo);
        InventoryAdjmtEntryOrder.SetProdOrderLine(ProdOrderLine);
    end;

    local procedure GetProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; OrderNo: Code[20]; OrderLineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderLine(ProdOrderLine, OrderNo, OrderLineNo, IsHandled);
#if not CLEAN27
        ItemJnlPostLine.RunOnBeforeGetProdOrderLine(ProdOrderLine, OrderNo, OrderLineNo, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderLine.Get(ProdOrderLine.Status::Released, OrderNo, OrderLineNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnCorrectOutputValuationDateOnCheckProduction', '', true, true)]
    local procedure OnCorrectOutputValuationDateOnCheckProduction(ItemLedgerEntry: Record "Item Ledger Entry"; var ShouldExit: Boolean; var TempValueEntry: Record "Value Entry" temporary; var ValuationDate: Date; var sender: Codeunit "Item Jnl.-Post Line")
    var
        ValueEntry: Record "Value Entry";
        ProductionOrder: Record "Production Order";
        IsHandled: Boolean;
    begin
        if not (ItemLedgerEntry."Entry Type" in [ItemLedgerEntry."Entry Type"::Consumption, ItemLedgerEntry."Entry Type"::Output]) then
            exit;

        IsHandled := false;
        OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry, IsHandled);
#if not CLEAN27
        sender.RunOnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry, IsHandled);
#endif
        if not IsHandled then
            if not ProductionOrder.Get(ProductionOrder.Status::Released, ItemLedgerEntry."Order No.") then
                exit;

        ValuationDate := MaxConsumptionValuationDate(ItemLedgerEntry);

        ValueEntry.SetCurrentKey("Order Type", "Order No.");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetFilter("Valuation Date", '<%1', ValuationDate);
        ValueEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ValueEntry.SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        OnCorrectOutputValuationDateOnBeforeValueEntryFindSet(ValueEntry);
#if not CLEAN27
        sender.RunOnCorrectOutputValuationDateOnBeforeValueEntryFindSet(ValueEntry);
#endif
        if ValueEntry.FindSet() then
            repeat
                TempValueEntry := ValueEntry;
                TempValueEntry.Insert();
            until ValueEntry.Next() = 0;
    end;

    local procedure MaxConsumptionValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadCommitted);
        ValueEntry.SetCurrentKey("Item Ledger Entry Type", "Order No.", "Valuation Date");
        ValueEntry.SetLoadFields("Valuation Date");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ItemLedgerEntry."Order No.");
        ValueEntry.SetRange("Order Line No.", ItemLedgerEntry."Order Line No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Consumption);
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation);
        if ValueEntry.FindLast() then
            exit(ValueEntry."Valuation Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectOutputValuationDateOnBeforeValueEntryFindSet(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeProdOrderRtngLineModify(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var LastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsump(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; OrderNo: Code[20]; OrderLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCapLedgEntry(ItemJournalLine: Record "Item Journal Line"; var SkipPost: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostOutputOnBeforeInsertCostValueEntries(var ItemJournalLine: Record "Item Journal Line"; var CapacityLedgerEntry: Record "Capacity Ledger Entry"; var ValuedQty: Decimal; var DirCostAmt: Decimal; var IndirCostAmt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCostValueEntries(ItemJournalLine: Record "Item Journal Line"; var CapLedgEntry: Record "Capacity Ledger Entry"; CalledFromAdjustment: Boolean; PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeGetMfgAmounts(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterSetMfgUnitCost(var ItemJournalLine: Record "Item Journal Line"; var MfgUnitCost: Decimal; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateAmounts(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PostWhseJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutputForProdOrder(var ItemJnlLine: Record "Item Journal Line"; var LastOperation: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterProdOrderRtngLineSetFilters(var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallFlushOperation(var ItemJnlLine: Record "Item Journal Line"; var ShouldFlushOperation: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOutputProdOrder(var ProdOrder: Record "Production Order"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOutputProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutputUpdateProdOrderRtngLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnApplyCapNeed(var ItemJnlLine: Record "Item Journal Line"; var PostedSetupTime: Decimal; var PostedRunTime: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCapQty(var ItemJnlLine: Record "Item Journal Line"; var CapQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCapNeedOnAfterSetFilters(var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; ItemJnlLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputForProdOrderOnAfterApplyCapNeed(var ItemJnlLine: Record "Item Journal Line"; var ValuedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextOperationExist(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(var CapLedgerEntry: Record "Capacity Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; ReTrack: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; ItemJournalLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ReTrack: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFlushOperationOnBeforeCheckRoutingLinkCode(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ItemJournalLine: Record "Item Journal Line"; LastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsumpItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostFlushedConsump(var ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; var GlobalItemLedgEntry: Record "Item Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushOperationOnAfterProdOrderCompSetFilters(var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLineSaved: Record "Item Journal Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFlushOperation(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line"; LastOperation: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFlushOperation(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var OutputQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnAfterCalcQtyToPost(ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component"; ActOutputQtyBase: Decimal; var QtyToPost: Decimal; var OldItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var CompItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var OldItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component"; CompItem: record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutput(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(var Item: Record Item; ItemNo: Code[20]; ForceGetItem: Boolean; var HasGotItem: Boolean; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnCodeOnAfterCalcQtyPerUnitOfMeasure', '', true, true)]
    local procedure OnCodeOnAfterCalcQtyPerUnitOfMeasure(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine."Setup Time" := ItemJnlLine."Setup Time (Base)";
        ItemJnlLine."Run Time" := ItemJnlLine."Run Time (Base)";
        ItemJnlLine."Stop Time" := ItemJnlLine."Stop Time (Base)";
        ItemJnlLine."Output Quantity" := ItemJnlLine."Output Quantity (Base)";
        ItemJnlLine."Scrap Quantity" := ItemJnlLine."Scrap Quantity (Base)";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertCapLedgEntry', '', true, true)]
    local procedure OnBeforeInsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; LastOperation: Boolean)
    begin
        CapLedgEntry."Setup Time" := ItemJournalLine."Setup Time";
        CapLedgEntry."Run Time" := ItemJournalLine."Run Time";
        CapLedgEntry."Stop Time" := ItemJournalLine."Stop Time";
        CapLedgEntry."Output Quantity" := ItemJournalLine."Output Quantity";
        CapLedgEntry."Scrap Quantity" := ItemJournalLine."Scrap Quantity";
        CapLedgEntry."Routing No." := ItemJournalLine."Routing No.";
        CapLedgEntry."Routing Reference No." := ItemJournalLine."Routing Reference No.";
        CapLedgEntry."Operation No." := ItemJournalLine."Operation No.";
        CapLedgEntry."Stop Code" := ItemJournalLine."Stop Code";
        CapLedgEntry."Scrap Code" := ItemJournalLine."Scrap Code";
        CapLedgEntry."Work Center No." := ItemJournalLine."Work Center No.";
        CapLedgEntry."Work Center Group Code" := ItemJournalLine."Work Center Group Code";
        CapLedgEntry."Starting Time" := ItemJournalLine."Starting Time";
        CapLedgEntry."Ending Time" := ItemJournalLine."Ending Time";
        CapLedgEntry."Concurrent Capacity" := ItemJournalLine."Concurrent Capacity";
        CapLedgEntry."Work Shift Code" := ItemJournalLine."Work Shift Code";
        CapLedgEntry."Last Output Line" := LastOperation;

        if ItemJournalLine."Rev. Capacity Ledger Entry No." <> 0 then
            UpdateReversedCapacityLedgerEntry(ItemJournalLine, CapLedgEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetupTempSplitItemJnlLineOnAfterDeductNonDistr', '', true, true)]
    local procedure OnSetupTempSplitItemJnlLineOnAfterDeductNonDistr(var TempSplitItemJnlLine: Record "Item Journal Line")
    begin
        TempSplitItemJnlLine."Setup Time" := 0;
        TempSplitItemJnlLine."Run Time" := 0;
        TempSplitItemJnlLine."Stop Time" := 0;
        TempSplitItemJnlLine."Setup Time (Base)" := 0;
        TempSplitItemJnlLine."Run Time (Base)" := 0;
        TempSplitItemJnlLine."Stop Time (Base)" := 0;
        TempSplitItemJnlLine."Starting Time" := 0T;
        TempSplitItemJnlLine."Ending Time" := 0T;
        TempSplitItemJnlLine."Scrap Quantity" := 0;
        TempSplitItemJnlLine."Scrap Quantity (Base)" := 0;
        TempSplitItemJnlLine."Concurrent Capacity" := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetupSplitJnlLineOnSetDisableItemTracking', '', true, true)]
    local procedure OnSetupSplitJnlLineOnSetDisableItemTracking(var ItemJournalLine: Record "Item Journal Line"; var DisableItemTracking: Boolean)
    begin
        DisableItemTracking := not ItemJournalLine.ItemPosting();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetupSplitJnlLineOnCheckOperationNo', '', true, true)]
    local procedure OnSetupSplitJnlLineOnCheckOperationNo(var ItemJournalLine: Record "Item Journal Line")
    begin
        Error(MustNotDefineItemTrackingErr, ItemJournalLine.FieldCaption("Operation No."), ItemJournalLine."Operation No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterPrepareItem', '', true, true)]
    local procedure OnAfterPrepareItem(var ItemJnlLineToPost: Record "Item Journal Line")
    begin
        CheckItemAndItemVariantProductionBlocked(ItemJnlLineToPost);
    end;

    local procedure CheckItemAndItemVariantProductionBlocked(ItemJournalLine: Record "Item Journal Line")
    var
        OutputItem: Record Item;
    begin
        case ItemJournalLine."Entry Type" of
            ItemJournalLine."Entry Type"::Output:
                OutputItem.CheckItemAndVariantForProdBlocked(ItemJournalLine."Item No.", ItemJournalLine."Variant Code", OutputItem."Production Blocked"::Output);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterSetupTempSplitItemJnlLineSetQty', '', true, true)]
    local procedure OnAfterSetupTempSplitItemJnlLineSetQty(var TempSplitItemJnlLine: Record "Item Journal Line" temporary; ItemJournalLine: Record "Item Journal Line")
    begin
        if ItemJournalLine."Output Quantity" <> 0 then begin
            TempSplitItemJnlLine."Output Quantity (Base)" := TempSplitItemJnlLine."Quantity (Base)";
            TempSplitItemJnlLine."Output Quantity" := TempSplitItemJnlLine.Quantity;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', true, true)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    begin
        NewItemLedgEntry."Prod. Order Comp. Line No." := ItemJournalLine."Prod. Order Comp. Line No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnInsertCapValueEntryOnBeforeCapLedgEntryModify', '', true, true)]
    local procedure OnInsertCapValueEntryOnBeforeCapLedgEntryModify(var CapLedgEntry: Record "Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        if ItemJournalLine.Subcontracting then
            CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry."Output Quantity"
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterGetUpdatedAppliedQtyForConsumption', '', true, true)]
    local procedure OnAfterGetUpdatedAppliedQtyForConsumption(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; ReservationEntry2: Record "Reservation Entry"; SourceType: Integer; var AppliedQty: Decimal)
    begin
        if SourceType = Database::"Prod. Order Component" then begin
            if (ReservationEntry2."Source ID" <> ItemLedgerEntry."Order No.") then begin
                AppliedQty := 0;
                exit;
            end;

            if ReservationEntry2."Source Ref. No." <> ItemLedgerEntry."Prod. Order Comp. Line No." then begin
                AppliedQty := 0;
                exit;
            end;

            AppliedQty := -Abs(OldItemLedgerEntry."Reserved Quantity")
        end;
    end;

    local procedure UpdateReversedCapacityLedgerEntry(var ItemJnlLine: Record "Item Journal Line"; var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry")
    var
        ReversedCapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
    begin
        ReversedCapacityLedgerEntry.Get(ItemJnlLine."Rev. Capacity Ledger Entry No.");
        CapLedgEntry.Reversed := true;
        CapLedgEntry."Reversed Entry No." := ReversedCapacityLedgerEntry."Entry No.";
        CapLedgEntry.Description := ReversedCapacityLedgerEntry.Description;

        ReversedCapacityLedgerEntry.Reversed := true;
        ReversedCapacityLedgerEntry."Reversed by Entry No." := CapLedgEntry."Entry No.";
        ReversedCapacityLedgerEntry.Modify();
    end;
}