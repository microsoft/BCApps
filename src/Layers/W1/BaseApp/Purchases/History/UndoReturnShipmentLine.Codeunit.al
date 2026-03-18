// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

codeunit 5814 "Undo Return Shipment Line"
{
    Permissions = TableData "Purchase Line" = rimd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Return Shipment Line" = rimd;
    TableNo = "Return Shipment Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        IsHandled: Boolean;
        SkipTypeCheck: Boolean;
    begin
        IsHandled := false;
        SkipTypeCheck := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTypeCheck, HideDialog);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(Text000) then
                exit;

        ReturnShptLine.Copy(Rec);
        Code();
        Rec := ReturnShptLine;
    end;

    var
        ReturnShptLine: Record "Return Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        ItemsToAdjust: List of [Code[20]];
        HideDialog: Boolean;
        JobItem: Boolean;
        NextLineNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'Do you really want to undo the selected Return Shipment lines?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        Text003: Label 'Checking lines...';
        Text004: Label 'This shipment has already been invoiced. Undo Return Shipment can be applied only to posted, but not invoiced shipments.';
#pragma warning restore AA0074
        AlreadyReversedErr: Label 'This return shipment has already been reversed.';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        SalesLine: Record "Sales Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        PostedWhseShptLineFound: Boolean;
    begin
        OnBeforeCode(ReturnShptLine, UndoPostingMgt);
        Clear(ItemJnlPostLine);
        ReturnShptLine.SetFilter(Quantity, '<>0');
        ReturnShptLine.SetRange(Correction, false);
        if ReturnShptLine.IsEmpty() then
            Error(AlreadyReversedErr);
        ReturnShptLine.FindFirst();
        repeat
            if not HideDialog then
                Window.Open(Text003);
            CheckReturnShptLine(ReturnShptLine);
        until ReturnShptLine.Next() = 0;

        BindSubscription(this);
        ReturnShptLine.Find('-');
        repeat
            TempGlobalItemLedgEntry.Reset();
            if not TempGlobalItemLedgEntry.IsEmpty() then
                TempGlobalItemLedgEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty() then
                TempGlobalItemEntryRelation.DeleteAll();

            if not HideDialog then
                Window.Open(Text001);

            if ReturnShptLine.Type = ReturnShptLine.Type::Item then begin
                PostedWhseShptLineFound :=
                    WhseUndoQty.FindPostedWhseShptLine(
                        PostedWhseShptLine, DATABASE::"Return Shipment Line", ReturnShptLine."Document No.",
                        DATABASE::"Purchase Line", SalesLine."Document Type"::"Return Order".AsInteger(), ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");

                ItemShptEntryNo := PostItemJnlLine(ReturnShptLine, DocLineNo);
            end else
                DocLineNo := GetCorrectionLineNo(ReturnShptLine);

            InsertNewReturnShptLine(ReturnShptLine, ItemShptEntryNo, DocLineNo);
            OnAfterInsertNewReturnShptLine(ReturnShptLine, PostedWhseShptLine, PostedWhseShptLineFound, DocLineNo);

            if PostedWhseShptLineFound then
                WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

            UpdateOrderLine(ReturnShptLine);
            if PostedWhseShptLineFound then
                WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

            ReturnShptLine."Quantity Invoiced" := ReturnShptLine.Quantity;
            ReturnShptLine."Qty. Invoiced (Base)" := ReturnShptLine."Quantity (Base)";
            ReturnShptLine."Return Qty. Shipped Not Invd." := 0;
            ReturnShptLine.Correction := true;

            OnBeforeReturnShptLineModify(ReturnShptLine, TempWhseJnlLine);
            ReturnShptLine.Modify();
            OnAfterReturnShptLineModify(ReturnShptLine, TempWhseJnlLine, DocLineNo, UndoPostingMgt);

            if not JobItem then
                JobItem := (ReturnShptLine.Type = ReturnShptLine.Type::Item) and (ReturnShptLine."Job No." <> '');
        until ReturnShptLine.Next() = 0;
        UnbindSubscription(this);

        MakeInventoryAdjustment();

        WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);

        OnAfterCode(ReturnShptLine, UndoPostingMgt);
    end;

    local procedure CheckReturnShptLine(ReturnShptLine: Record "Return Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnShptLine(ReturnShptLine, IsHandled);
        if IsHandled then
            exit;

        if ReturnShptLine.Correction then
            Error(AlreadyReversedErr);
        if ReturnShptLine."Return Qty. Shipped Not Invd." <> ReturnShptLine.Quantity then
            Error(Text004);

        if ReturnShptLine.Type = ReturnShptLine.Type::Item then begin
            ReturnShptLine.TestProdOrder();

            UndoPostingMgt.TestReturnShptLine(ReturnShptLine);
            IsHandled := false;
            OnCheckReturnShptLineOnBeforeCollectItemLedgEntries(ReturnShptLine, IsHandled);
            if not IsHandled then begin
                UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Return Shipment Line",
                ReturnShptLine."Document No.", ReturnShptLine."Line No.", ReturnShptLine."Quantity (Base)", ReturnShptLine."Item Shpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, ReturnShptLine."Line No.");
            end;
        end;
    end;

    local procedure GetCorrectionLineNo(ReturnShptLine: Record "Return Shipment Line") Result: Integer
    var
        ReturnShptLine2: Record "Return Shipment Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(ReturnShptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReturnShptLine2.SetRange("Document No.", ReturnShptLine."Document No.");
        ReturnShptLine2."Document No." := ReturnShptLine."Document No.";
        ReturnShptLine2."Line No." := ReturnShptLine."Line No.";
        ReturnShptLine2.Find('=');

        if ReturnShptLine2.Find('>') then begin
            LineSpacing := (ReturnShptLine2."Line No." - ReturnShptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;

        exit(ReturnShptLine."Line No." + LineSpacing);
    end;

    local procedure PostItemJnlLine(ReturnShptLine: Record "Return Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        PurchLine: Record "Purchase Line";
        ReturnShptHeader: Record "Return Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemLedgEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(ReturnShptLine, DocLineNo, ItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        DocLineNo := GetCorrectionLineNo(ReturnShptLine);

        SourceCodeSetup.Get();
        ReturnShptHeader.Get(ReturnShptLine."Document No.");
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
        ItemJnlLine."Item No." := ReturnShptLine."No.";
        ItemJnlLine."Unit of Measure Code" := ReturnShptLine."Unit of Measure Code";
        ItemJnlLine."Posting Date" := ReturnShptHeader."Posting Date";
        ItemJnlLine."Document No." := ReturnShptLine."Document No.";
        ItemJnlLine."Document Line No." := DocLineNo;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Return Shipment";
        ItemJnlLine."Gen. Bus. Posting Group" := ReturnShptLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := ReturnShptLine."Gen. Prod. Posting Group";
        ItemJnlLine."Location Code" := ReturnShptLine."Location Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Purchases;
        ItemJnlLine."Shortcut Dimension 1 Code" := ReturnShptLine."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ReturnShptLine."Shortcut Dimension 2 Code";
        ItemJnlLine."Dimension Set ID" := ReturnShptLine."Dimension Set ID";
        if ReturnShptLine."Job No." = '' then begin
            ItemJnlLine.Correction := true;
            ItemJnlLine."Applies-to Entry" := ReturnShptLine."Item Shpt. Entry No.";
        end else begin
            ItemJnlLine."Job No." := ReturnShptLine."Job No.";
            ItemJnlLine."Job Task No." := ReturnShptLine."Job Task No.";
            ItemJnlLine."Job Purchase" := true;
            ItemJnlLine."Unit Cost" := ReturnShptLine."Unit Cost (LCY)";
        end;
        ItemJnlLine."Variant Code" := ReturnShptLine."Variant Code";
        ItemJnlLine."Bin Code" := ReturnShptLine."Bin Code";
        ItemJnlLine.Quantity := ReturnShptLine."Quantity (Base)";
        ItemJnlLine."Quantity (Base)" := ReturnShptLine."Quantity (Base)";
        ItemJnlLine."Document Date" := ReturnShptHeader."Document Date";
        ItemJnlLine."Unit of Measure Code" := ReturnShptLine."Unit of Measure Code";

        OnAfterCopyItemJnlLineFromReturnShpt(ItemJnlLine, ReturnShptHeader, ReturnShptLine, WhseUndoQty, ItemLedgEntryNo, TempWhseJnlLine, NextLineNo, TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        WhseUndoQty.InsertTempWhseJnlLine(
            ItemJnlLine,
            DATABASE::"Purchase Line", PurchLine."Document Type"::"Return Order".AsInteger(), ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.",
            TempWhseJnlLine."Reference Document"::"Posted Rtrn. Shipment".AsInteger(), TempWhseJnlLine, NextLineNo);

        if ReturnShptLine."Item Shpt. Entry No." <> 0 then begin
            if ReturnShptLine."Job No." <> '' then
                UndoPostingMgt.TransferSourceValues(ItemJnlLine, ReturnShptLine."Item Shpt. Entry No.");
            UndoPostingMgt.PostItemJnlLine(ItemJnlLine);
            exit(ItemJnlLine."Item Shpt. Entry No.");
        end;
        UndoPostingMgt.CollectItemLedgEntries(
            TempApplyToEntryList, DATABASE::"Return Shipment Line", ReturnShptLine."Document No.", ReturnShptLine."Line No.", ReturnShptLine."Quantity (Base)", ReturnShptLine."Item Shpt. Entry No.");

        UndoPostingMgt.PostItemJnlLineAppliedToList(
            ItemJnlLine, TempApplyToEntryList, ReturnShptLine.Quantity, ReturnShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

        exit(0); // "Item Shpt. Entry No."
    end;

    local procedure InsertNewReturnShptLine(OldReturnShptLine: Record "Return Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewReturnShptLine: Record "Return Shipment Line";
    begin
        NewReturnShptLine.Init();
        NewReturnShptLine.Copy(OldReturnShptLine);
        NewReturnShptLine."Line No." := DocLineNo;
        NewReturnShptLine."Appl.-to Item Entry" := OldReturnShptLine."Item Shpt. Entry No.";
        NewReturnShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewReturnShptLine.Quantity := -OldReturnShptLine.Quantity;
        NewReturnShptLine."Quantity (Base)" := -OldReturnShptLine."Quantity (Base)";
        NewReturnShptLine."Quantity Invoiced" := NewReturnShptLine.Quantity;
        NewReturnShptLine."Qty. Invoiced (Base)" := NewReturnShptLine."Quantity (Base)";
        NewReturnShptLine."Return Qty. Shipped Not Invd." := 0;
        NewReturnShptLine.Correction := true;
        NewReturnShptLine."Dimension Set ID" := OldReturnShptLine."Dimension Set ID";
        OnBeforeNewReturnShptLineInsert(NewReturnShptLine, OldReturnShptLine);
        NewReturnShptLine.Insert();
        OnAfterNewReturnShptLineInsert(NewReturnShptLine, OldReturnShptLine);

        InsertItemEntryRelation(TempGlobalItemEntryRelation, NewReturnShptLine);
    end;

    procedure UpdateOrderLine(ReturnShptLine: Record "Return Shipment Line")
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderLine(ReturnShptLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Get(PurchLine."Document Type"::"Return Order", ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
        OnUpdateOrderLineOnBeforeUpdatePurchLine(ReturnShptLine, PurchLine);
        UndoPostingMgt.UpdatePurchLine(PurchLine, ReturnShptLine.Quantity, ReturnShptLine."Quantity (Base)", TempGlobalItemLedgEntry);
        OnAfterUpdatePurchLine(PurchLine, ReturnShptLine);
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewReturnShptLine: Record "Return Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsReturnShptLine(NewReturnShptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtAdjmtHandler.SetJobUpdateProperties(not JobItem);
        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem', '', false, false)]
    local procedure OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(var Item2: Record Item)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if InventorySetup.UseLegacyPosting() then
            exit;

        if not ItemsToAdjust.Contains(Item2."No.") then
            ItemsToAdjust.Add(Item2."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ReturnShipmentLine: Record "Return Shipment Line"; var UndoPostingManagement: Codeunit "Undo Posting Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromReturnShpt(var ItemJournalLine: Record "Item Journal Line"; ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentLine: Record "Return Shipment Line"; var WhseUndoQty: Codeunit "Whse. Undo Quantity"; var ItemLedgEntryNo: Integer; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer; var TempGlobalItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewReturnShptLine(var ReturnShipmentLine: Record "Return Shipment Line"; PostedWhseShptLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewReturnShptLineInsert(var NewReturnShipmentLine: Record "Return Shipment Line"; OldReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLine(var PurchaseLine: Record "Purchase Line"; var ReturnShptLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnShptLineModify(var ReturnShptLine: Record "Return Shipment Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; DocLineNo: Integer; var UndoPostingManagement: Codeunit "Undo Posting Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(ReturnShptLine: Record "Return Shipment Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnShptLine(var ReturnShptLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ReturnShipmentLine: Record "Return Shipment Line"; var UndoPostingManagement: Codeunit "Undo Posting Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewReturnShptLineInsert(var NewReturnShipmentLine: Record "Return Shipment Line"; OldReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ReturnShipmentLine: Record "Return Shipment Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShptLineModify(var ReturnShptLine: Record "Return Shipment Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderLine(var ReturnShptLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOrderLineOnBeforeUpdatePurchLine(var ReturnShptLine: Record "Return Shipment Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReturnShptLineOnBeforeCollectItemLedgEntries(ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;
}

