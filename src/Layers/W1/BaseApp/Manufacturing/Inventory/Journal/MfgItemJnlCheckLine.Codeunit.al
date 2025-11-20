// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Request;

codeunit 99000760 "Mfg. Item Jnl. Check Line"
{
    var
#if not CLEAN27
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
#endif
        CannotPostTheseLinesErr: Label 'You cannot post these lines because you have not entered a quantity on one or more of the lines. ';
        WarehouseHandlingRequiredErr: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.', Comment = '%1 %3 %5 - field captions, %2 %4 %6 - field values';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", 'OnCheckDimensionsOnAfterSetTableValues', '', false, false)]
    local procedure OnCheckDimensionsOnAfterSetTableValues(ItemJournalLine: Record "Item Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
        TableID[3] := Database::"Work Center";
        No[3] := ItemJournalLine."Work Center No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", 'OnRunOnCheckWarehouse', '', false, false)]
    local procedure OnRunOnCheckWarehouse(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        IsHandled: Boolean;
        ShouldCheckItemNo: Boolean;
    begin
        if (ItemJournalLine."Entry Type" in [ItemJournalLine."Entry Type"::Consumption, ItemJournalLine."Entry Type"::Output]) and
           not (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::Revaluation) and
           not ItemJournalLine.OnlyStopTime()
        then begin
            ItemJournalLine.TestField("Source No.", ErrorInfo.Create());
            ItemJournalLine.TestField("Order Type", ItemJournalLine."Order Type"::Production, ErrorInfo.Create());
            ShouldCheckItemNo := not CalledFromAdjustment and (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Output);
            OnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine, ProdOrderLine, CalledFromAdjustment, ShouldCheckItemNo);
#if not CLEAN26
            ItemJnlCheckLine.RunOnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine, ProdOrderLine, CalledFromAdjustment, ShouldCheckItemNo);
#endif
            if ShouldCheckItemNo then
                if CheckFindProdOrderLine(ProdOrderLine, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.") then begin
                    ItemJournalLine.TestField("Item No.", ProdOrderLine."Item No.", ErrorInfo.Create());
                    OnAfterCheckFindProdOrderLine(ItemJournalLine, ProdOrderLine);
#if not CLEAN26
                    ItemJnlCheckLine.RunOnAfterCheckFindProdOrderLine(ItemJournalLine, ProdOrderLine);
#endif
                end;

            if ItemJournalLine.Subcontracting then begin
                IsHandled := false;
                OnBeforeCheckSubcontracting(ItemJournalLine, IsHandled);
#if not CLEAN26
                ItemJnlCheckLine.RunOnBeforeCheckSubcontracting(ItemJournalLine, IsHandled);
#endif
                if not IsHandled then begin
                    WorkCenter.Get(ItemJournalLine."Work Center No.");
                    WorkCenter.TestField("Subcontractor No.", ErrorInfo.Create());
                end;
            end;
            if not CalledFromInvtPutawayPick then
                CheckWarehouse(ItemJournalLine);
        end;
    end;

    local procedure CheckFindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; LineNo: Integer): Boolean
    begin
        ProdOrderLine.SetFilter(Status, '>=%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Line No.", LineNo);
        exit(ProdOrderLine.FindFirst());
    end;

    local procedure CheckWarehouse(ItemJnlLine: Record "Item Journal Line")
    var
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(ItemJnlLine, IsHandled);
#if not CLEAN26
        ItemJnlCheckLine.RunOnBeforeCheckWarehouse(ItemJnlLine, IsHandled);
#endif
        if IsHandled then
            exit;

        if (ItemJnlLine.Quantity = 0) or
           (ItemJnlLine."Item Charge No." <> '') or
           (ItemJnlLine."Value Entry Type" in
            [ItemJnlLine."Value Entry Type"::Revaluation, ItemJnlLine."Value Entry Type"::Rounding]) or
           ItemJnlLine.Adjustment
        then
            exit;

        if Location.Get(ItemJnlLine."Location Code") then
            if Location."Directed Put-away and Pick" then
                exit;

        case ItemJnlLine."Entry Type" of // Need to check if the item and location require warehouse handling
            ItemJnlLine."Entry Type"::Output:
                if WhseOrderHandlingRequired(ItemJnlLine, Location) and CheckWarehouseLastOutputOperation(ItemJnlLine) then begin
                    if (ItemJnlLine.Quantity < 0) and (ItemJnlLine."Applies-to Entry" = 0) then begin
                        ReservationEntry.InitSortingAndFilters(false);
                        ItemJnlLine.SetReservationFilters(ReservationEntry);
                        ReservationEntry.ClearTrackingFilter();
                        if ReservationEntry.FindSet() then
                            repeat
                                if ReservationEntry."Appl.-to Item Entry" = 0 then
                                    ShowError := true;
                            until (ReservationEntry.Next() = 0) or ShowError
                        else
                            ShowError := CheckWarehouseLastOutputOperation(ItemJnlLine);
                    end;

                    if WhseValidateSourceLine.WhseLinesExist(
                         Database::"Prod. Order Line", 3, ItemJnlLine."Order No.", ItemJnlLine."Order Line No.", 0, ItemJnlLine.Quantity)
                    then
                        ShowError := true;
                end;
            ItemJnlLine."Entry Type"::Consumption:
                if WhseOrderHandlingRequired(ItemJnlLine, Location) then
                    if WhseValidateSourceLine.WhseLinesExist(
                         Database::"Prod. Order Component",
                         3,
                         ItemJnlLine."Order No.",
                         ItemJnlLine."Order Line No.",
                         ItemJnlLine."Prod. Order Comp. Line No.",
                         ItemJnlLine.Quantity)
                    then
                        ShowError := true;
        end;
        if ShowError then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        WarehouseHandlingRequiredErr,
                        ItemJnlLine.FieldCaption("Entry Type"),
                        ItemJnlLine."Entry Type",
                        ItemJnlLine.FieldCaption("Order No."),
                        ItemJnlLine."Order No.",
                        ItemJnlLine.FieldCaption("Order Line No."),
                        ItemJnlLine."Order Line No."),
                    true));
    end;

    local procedure CheckWarehouseLastOutputOperation(ItemJnlLine: Record "Item Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouseLastOutputOperation(ItemJnlLine, Result, IsHandled);
#if not CLEAN26
        ItemJnlCheckLine.RunOnBeforeCheckWarehouseLastOutputOperation(ItemJnlLine, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        Result := ItemJnlLine.LastOutputOperation(ItemJnlLine);
    end;

    local procedure WhseOrderHandlingRequired(ItemJnlLine: Record "Item Journal Line"; LocationToCheck: Record Location): Boolean
    var
        InvtPutAwayLocation: Boolean;
        InvtPickLocation: Boolean;
        WarehousePickLocation: Boolean;
    begin
        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Output:
                begin
                    InvtPutAwayLocation := LocationToCheck."Prod. Output Whse. Handling" = Enum::"Prod. Output Whse. Handling"::"Inventory Put-away";
                    OnAfterAssignInvtPutAwayRequired(ItemJnlLine, LocationToCheck, InvtPutAwayLocation);
                    if InvtPutAwayLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);

                    InvtPickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
                    OnAfterAssignInvtPickRequired(ItemJnlLine, LocationToCheck, InvtPickLocation);
                    if InvtPickLocation then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);

                    WarehousePickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    OnAfterAssignWhsePickRequired(ItemJnlLine, LocationToCheck, WarehousePickLocation);
                    if WarehousePickLocation and (ItemJnlLine."Flushing Method" = ItemJnlLine."Flushing Method"::"Pick + Backward") then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);
                end;
            ItemJnlLine."Entry Type"::Consumption:
                begin
                    InvtPutAwayLocation := LocationToCheck."Prod. Output Whse. Handling" = Enum::"Prod. Output Whse. Handling"::"Inventory Put-away";
                    OnAfterAssignInvtPutAwayRequired(ItemJnlLine, LocationToCheck, InvtPutAwayLocation);
                    if InvtPutAwayLocation then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);

                    InvtPickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
                    OnAfterAssignInvtPickRequired(ItemJnlLine, LocationToCheck, InvtPickLocation);
                    if InvtPickLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);

                    WarehousePickLocation := LocationToCheck."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    OnAfterAssignWhsePickRequired(ItemJnlLine, LocationToCheck, WarehousePickLocation);
                    if WarehousePickLocation and (ItemJnlLine."Flushing Method" = ItemJnlLine."Flushing Method"::"Pick + Backward") then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);
                end;
        end;

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", 'OnCheckOutputFields', '', false, false)]
    local procedure OnCheckOutputFields(var ItemJournalLine: Record "Item Journal Line")
    begin
        if not ItemJournalLine.IsEntryTypeOutput() then begin
            ItemJournalLine.TestField("Run Time", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Setup Time", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Stop Time", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Output Quantity", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Scrap Quantity", 0, ErrorInfo.Create());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", 'OnCheckEmptyQuantity', '', false, false)]
    local procedure OnCheckEmptyQuantity(ItemJournalLine: Record "Item Journal Line");
    begin
        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Output then begin
            if (ItemJournalLine."Output Quantity (Base)" = 0) and (ItemJournalLine."Scrap Quantity (Base)" = 0) and
               ItemJournalLine.TimeIsEmpty() and (ItemJournalLine."Invoiced Qty. (Base)" = 0)
            then
                Error(ErrorInfo.Create(CannotPostTheseLinesErr, true))
        end else
            if (ItemJournalLine."Quantity (Base)" = 0) and (ItemJournalLine."Invoiced Qty. (Base)" = 0) then
                Error(ErrorInfo.Create(CannotPostTheseLinesErr, true));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", 'OnCheckBinsOnCheckForEntryTypeOutput', '', false, false)]
    local procedure OnCheckBinsOnCheckForEntryTypeOutput(var ItemJournalLine: Record "Item Journal Line"; var ShouldExit: Boolean)
    begin
        ShouldExit := ItemJournalLine.IsEntryTypeOutput() and not ItemJournalLine.LastOutputOperation(ItemJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; CalledFromAdjustment: Boolean; var ShouldCheckItemNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPutAwayRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var InvtPutAwayLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPickRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var InvtPickLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignWhsePickRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var WhsePickLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFindProdOrderLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSubcontracting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouseLastOutputOperation(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

