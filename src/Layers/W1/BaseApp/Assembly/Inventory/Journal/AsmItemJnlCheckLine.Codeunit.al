// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 910 "Asm. Item Jnl.-Check Line"
{
    var
#if not CLEAN26
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
#endif
        WarehouseHandlingRequiredErr: Label 'Warehouse handling is required for %1 = %2, %3 = %4, %5 = %6.', Comment = '%1 %3 %5 - field captions, %2 %4 %6 - field values';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", 'OnRunOnCheckWarehouse', '', false, false)]
    local procedure OnRunOnCheckWarehouse(var ItemJournalLine: Record "Item Journal Line")
    begin
        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Assembly Consumption" then
            CheckWarehouse(ItemJournalLine);
    end;

    local procedure CheckWarehouse(ItemJnlLine: Record "Item Journal Line")
    var
        AssemblyLine: Record "Assembly Line";
        Location: Record Location;
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckWarehouse(ItemJnlLine, IsHandled);
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
            ItemJnlLine."Entry Type"::"Assembly Consumption":
                if WhseOrderHandlingRequired(ItemJnlLine, Location) then
                    if WhseValidateSourceLine.WhseLinesExist(
                         Database::"Assembly Line",
                         AssemblyLine."Document Type"::Order.AsInteger(),
                         ItemJnlLine."Order No.",
                         ItemJnlLine."Order Line No.",
                         0,
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

    local procedure WhseOrderHandlingRequired(ItemJnlLine: Record "Item Journal Line"; LocationToCheck: Record Location): Boolean
    var
        InvtPutAwayLocation: Boolean;
        InvtPickLocation: Boolean;
        WarehousePickLocation: Boolean;
    begin
        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::"Assembly Consumption":
                begin
                    InvtPutAwayLocation := not LocationToCheck."Require Receive" and LocationToCheck."Require Put-away";
                    OnAfterAssignInvtPutAwayRequired(ItemJnlLine, LocationToCheck, InvtPutAwayLocation);
#if not CLEAN26
                    ItemJnlCheckLine.RunOnAfterAssignInvtPutAwayRequired(ItemJnlLine, LocationToCheck, InvtPutAwayLocation);
#endif
                    if InvtPutAwayLocation then
                        if ItemJnlLine.Quantity < 0 then
                            exit(true);

                    InvtPickLocation := LocationToCheck."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement";
                    OnAfterAssignInvtPickRequired(ItemJnlLine, LocationToCheck, InvtPickLocation);
#if not CLEAN26
                    ItemJnlCheckLine.RunOnAfterAssignInvtPickRequired(ItemJnlLine, LocationToCheck, InvtPickLocation);
#endif
                    if InvtPickLocation then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);

                    WarehousePickLocation := LocationToCheck."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    OnAfterAssignWhsePickRequired(ItemJnlLine, LocationToCheck, WarehousePickLocation);
#if not CLEAN26
                    ItemJnlCheckLine.RunOnAfterAssignWhsePickRequired(ItemJnlLine, LocationToCheck, WarehousePickLocation);
#endif
                    if WarehousePickLocation and (ItemJnlLine."Flushing Method" = ItemJnlLine."Flushing Method"::"Pick + Backward") then
                        if ItemJnlLine.Quantity >= 0 then
                            exit(true);
                end;
        end;

        exit(false);
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
}
