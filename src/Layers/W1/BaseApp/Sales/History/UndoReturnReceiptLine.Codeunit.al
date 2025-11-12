// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;

codeunit 5816 "Undo Return Receipt Line"
{
    Permissions = TableData "Sales Line" = rimd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Whse. Item Entry Relation" = rimd,
                  TableData "Return Receipt Line" = rimd;
    TableNo = "Return Receipt Line";
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

        ReturnRcptLine.Copy(Rec);
        Code();
        Rec := ReturnRcptLine;
    end;

    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        ItemsToAdjust: List of [Code[20]];
        HideDialog: Boolean;
        NextLineNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'Do you really want to undo the selected Return Receipt lines?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        Text003: Label 'Checking lines...';
        Text004: Label 'This receipt has already been invoiced. Undo Return Receipt can be applied only to posted, but not invoiced receipts.';
#pragma warning restore AA0074
        AlreadyReversedErr: Label 'This return receipt has already been reversed.';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        SalesLine: Record "Sales Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        PostedWhseRcptLineFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(ReturnRcptLine, HideDialog, IsHandled);
        if not IsHandled then begin
            Clear(ItemJnlPostLine);
            ReturnRcptLine.SetRange(Correction, false);
            ReturnRcptLine.SetFilter(Quantity, '<>0');
            if ReturnRcptLine.IsEmpty() then
                Error(AlreadyReversedErr);

            ReturnRcptLine.FindFirst();
            repeat
                if not HideDialog then
                    Window.Open(Text003);
                OnCodeOnBeforeCallCheckReturnRcptLine(ReturnRcptLine);
                CheckReturnRcptLine(ReturnRcptLine);
            until ReturnRcptLine.Next() = 0;

            BindSubscription(this);
            ReturnRcptLine.Find('-');
            repeat
                TempGlobalItemLedgEntry.Reset();
                if not TempGlobalItemLedgEntry.IsEmpty() then
                    TempGlobalItemLedgEntry.DeleteAll();
                TempGlobalItemEntryRelation.Reset();
                if not TempGlobalItemEntryRelation.IsEmpty() then
                    TempGlobalItemEntryRelation.DeleteAll();

                if not HideDialog then
                    Window.Open(Text001);

                if ReturnRcptLine.Type = ReturnRcptLine.Type::Item then begin
                    PostedWhseRcptLineFound :=
                    WhseUndoQty.FindPostedWhseRcptLine(
                        PostedWhseRcptLine,
                        DATABASE::"Return Receipt Line", ReturnRcptLine."Document No.",
                        DATABASE::"Sales Line", SalesLine."Document Type"::"Return Order".AsInteger(), ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");

                    ItemShptEntryNo := PostItemJnlLine(ReturnRcptLine, DocLineNo);
                end else
                    DocLineNo := GetCorrectionLineNo(ReturnRcptLine);

                InsertNewReceiptLine(ReturnRcptLine, ItemShptEntryNo, DocLineNo);

                IsHandled := false;
                OnAfterInsertNewReceiptLine(ReturnRcptLine, PostedWhseRcptLine, PostedWhseRcptLineFound, DocLineNo, IsHandled);
                if not IsHandled then begin
                    SalesLine.Get(SalesLine."Document Type"::"Return Order", ReturnRcptLine."Return Order No.",
                    ReturnRcptLine."Return Order Line No.");
                    if ReturnRcptLine."Item Rcpt. Entry No." > 0 then
                        if SalesLine."Appl.-from Item Entry" <> 0 then begin
                            SalesLine."Appl.-from Item Entry" := ItemShptEntryNo;
                            SalesLine.Modify();
                        end;

                    if PostedWhseRcptLineFound then
                        WhseUndoQty.UndoPostedWhseRcptLine(PostedWhseRcptLine);

                    UpdateOrderLine(ReturnRcptLine);
                    UpdateItemTrkgApplFromEntry(SalesLine);
                end;

                if PostedWhseRcptLineFound then
                    WhseUndoQty.UpdateRcptSourceDocLines(PostedWhseRcptLine);

                ReturnRcptLine."Quantity Invoiced" := ReturnRcptLine.Quantity;
                ReturnRcptLine."Qty. Invoiced (Base)" := ReturnRcptLine."Quantity (Base)";
                ReturnRcptLine."Return Qty. Rcd. Not Invd." := 0;
                ReturnRcptLine.Correction := true;

                OnBeforeReturnRcptLineModify(ReturnRcptLine, TempWhseJnlLine);
                ReturnRcptLine.Modify();
                OnAfterReturnRcptLineModify(ReturnRcptLine, TempWhseJnlLine, DocLineNo, HideDialog);
            until ReturnRcptLine.Next() = 0;
            UnbindSubscription(this);

            MakeInventoryAdjustment();

            WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);
        end;

        OnAfterCode(ReturnRcptLine);
    end;

    local procedure CheckReturnRcptLine(ReturnRcptLine: Record "Return Receipt Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnRcptLine(ReturnRcptLine, IsHandled);
        if IsHandled then
            exit;

        if ReturnRcptLine.Correction then
            Error(AlreadyReversedErr);

        IsHandled := false;
        OnCheckReturnRcptLineOnBeforeCheckReturnQtyRcdNotInvd(ReturnRcptLine, IsHandled);
        if not IsHandled then
            if ReturnRcptLine."Return Qty. Rcd. Not Invd." <> ReturnRcptLine.Quantity then
                Error(Text004);

        if ReturnRcptLine.Type = ReturnRcptLine.Type::Item then begin
            UndoPostingMgt.TestReturnRcptLine(ReturnRcptLine);
            IsHandled := false;
            OnCheckReturnRcptLineOnBeforeCollectItemLedgEntries(ReturnRcptLine, TempItemLedgEntry, IsHandled);
            if not IsHandled then begin
                UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Return Receipt Line",
                ReturnRcptLine."Document No.", ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.");
                UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, ReturnRcptLine."Line No.");
            end;
        end;
    end;

    local procedure GetCorrectionLineNo(ReturnRcptLine: Record "Return Receipt Line") Result: Integer;
    var
        ReturnRcptLine2: Record "Return Receipt Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(ReturnRcptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReturnRcptLine2.SetRange("Document No.", ReturnRcptLine."Document No.");
        ReturnRcptLine2."Document No." := ReturnRcptLine."Document No.";
        ReturnRcptLine2."Line No." := ReturnRcptLine."Line No.";
        ReturnRcptLine2.Find('=');

        if ReturnRcptLine2.Find('>') then begin
            LineSpacing := (ReturnRcptLine2."Line No." - ReturnRcptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;

        exit(ReturnRcptLine."Line No." + LineSpacing);
    end;

    local procedure PostItemJnlLine(ReturnRcptLine: Record "Return Receipt Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        SourceCodeSetup: Record "Source Code Setup";
        ReturnRcptHeader: Record "Return Receipt Header";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemLedgEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(ReturnRcptLine, DocLineNo, ItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        DocLineNo := GetCorrectionLineNo(ReturnRcptLine);

        SourceCodeSetup.Get();
        ReturnRcptHeader.Get(ReturnRcptLine."Document No.");
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Sale;
        ItemJnlLine."Item No." := ReturnRcptLine."No.";
        ItemJnlLine."Posting Date" := ReturnRcptHeader."Posting Date";
        ItemJnlLine."Document No." := ReturnRcptLine."Document No.";
        ItemJnlLine."Document Line No." := DocLineNo;
        ItemJnlLine."Gen. Bus. Posting Group" := ReturnRcptLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := ReturnRcptLine."Gen. Prod. Posting Group";
        ItemJnlLine."Location Code" := ReturnRcptLine."Location Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Sales;
        ItemJnlLine."Applies-to Entry" := ReturnRcptLine."Item Rcpt. Entry No.";
        ItemJnlLine.Correction := true;
        ItemJnlLine."Variant Code" := ReturnRcptLine."Variant Code";
        ItemJnlLine."Bin Code" := ReturnRcptLine."Bin Code";
        ItemJnlLine.Quantity := ReturnRcptLine.Quantity;
        ItemJnlLine."Quantity (Base)" := ReturnRcptLine."Quantity (Base)";
        ItemJnlLine."Unit of Measure Code" := ReturnRcptLine."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := ReturnRcptLine."Qty. per Unit of Measure";
        ItemJnlLine."Document Date" := ReturnRcptHeader."Document Date";

        IsHandled := false;
        OnAfterCopyItemJnlLineFromReturnRcpt(
            ItemJnlLine, ReturnRcptHeader, ReturnRcptLine, WhseUndoQty, ItemLedgEntryNo, TempWhseJnlLine, NextLineNo, ReturnRcptHeader,
            TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        WhseUndoQty.InsertTempWhseJnlLine(
            ItemJnlLine,
            DATABASE::"Sales Line", SalesLine."Document Type"::"Return Order".AsInteger(), ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.",
            TempWhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.".AsInteger(), TempWhseJnlLine, NextLineNo);

        if ReturnRcptLine."Item Rcpt. Entry No." <> 0 then begin
            ItemJnlPostLine.Run(ItemJnlLine);
            OnPostItemJnlLineOnAfterRunItemJnlPostLine(ItemJnlLine, ReturnRcptLine, ReturnRcptHeader, ItemJnlPostLine);
            exit(ItemJnlLine."Item Shpt. Entry No.");
        end;

        UndoPostingMgt.CollectItemLedgEntries(
            TempApplyToEntryList, DATABASE::"Return Receipt Line", ReturnRcptLine."Document No.", ReturnRcptLine."Line No.", ReturnRcptLine."Quantity (Base)", ReturnRcptLine."Item Rcpt. Entry No.");

        UndoPostingMgt.PostItemJnlLineAppliedToList(
            ItemJnlLine, TempApplyToEntryList, ReturnRcptLine.Quantity, ReturnRcptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);

        exit(0); // "Item Shpt. Entry No."
    end;

    local procedure InsertNewReceiptLine(OldReturnRcptLine: Record "Return Receipt Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewReturnRcptLine: Record "Return Receipt Line";
    begin
        NewReturnRcptLine.Init();
        NewReturnRcptLine.Copy(OldReturnRcptLine);
        NewReturnRcptLine."Line No." := DocLineNo;
        NewReturnRcptLine."Appl.-from Item Entry" := OldReturnRcptLine."Item Rcpt. Entry No.";
        NewReturnRcptLine."Item Rcpt. Entry No." := ItemShptEntryNo;
        NewReturnRcptLine.Quantity := -OldReturnRcptLine.Quantity;
        NewReturnRcptLine."Return Qty. Rcd. Not Invd." := 0;
        NewReturnRcptLine."Quantity (Base)" := -OldReturnRcptLine."Quantity (Base)";
        NewReturnRcptLine."Quantity Invoiced" := NewReturnRcptLine.Quantity;
        NewReturnRcptLine."Qty. Invoiced (Base)" := NewReturnRcptLine."Quantity (Base)";
        NewReturnRcptLine.Correction := true;
        NewReturnRcptLine."Dimension Set ID" := OldReturnRcptLine."Dimension Set ID";
        OnBeforeNewReturnRcptLineInsert(NewReturnRcptLine, OldReturnRcptLine);
        NewReturnRcptLine.Insert();
        OnAfterNewReturnRcptLineInsert(NewReturnRcptLine, OldReturnRcptLine);

        InsertItemEntryRelation(TempGlobalItemEntryRelation, NewReturnRcptLine);
    end;

    procedure UpdateOrderLine(ReturnRcptLine: Record "Return Receipt Line")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderLine(ReturnRcptLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Get(SalesLine."Document Type"::"Return Order", ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");
        OnUpdateOrderLineOnBeforeUpdateSalesLine(ReturnRcptLine, SalesLine);
        UndoPostingMgt.UpdateSalesLine(SalesLine, ReturnRcptLine.Quantity, ReturnRcptLine."Quantity (Base)", TempGlobalItemLedgEntry);
        OnAfterUpdateSalesLine(ReturnRcptLine, SalesLine);
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewReturnRcptLine: Record "Return Receipt Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsReturnRcptLine(NewReturnRcptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure UpdateItemTrkgApplFromEntry(SalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        SalesLine.SetReservationFilters(ReservationEntry);
        if ReservationEntry.FindSet() then
            repeat
                if ReservationEntry."Appl.-from Item Entry" <> 0 then
                    if ItemApplicationEntry.AppliedOutbndEntryExists(ReservationEntry."Item Ledger Entry No.", false, false) then begin
                        ReservationEntry."Appl.-from Item Entry" := ItemApplicationEntry."Outbound Item Entry No.";
                        ReservationEntry.Modify();
                    end;
            until ReservationEntry.Next() = 0;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtAdjmtHandler.SetJobUpdateProperties(true);
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
    local procedure OnBeforeCode(ReturnReceiptLine: Record "Return Receipt Line"; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromReturnRcpt(var ItemJournalLine: Record "Item Journal Line"; ReturnReceiptHeader: Record "Return Receipt Header"; ReturnReceiptLine: Record "Return Receipt Line"; var WhseUndoQty: Codeunit "Whse. Undo Quantity"; var ItemLedgEntryNo: Integer; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer; ReturnRcptHeader: Record "Return Receipt Header"; var TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var PostedWhseRcptLineFound: Boolean; DocLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewReturnRcptLineInsert(var NewReturnReceiptLine: Record "Return Receipt Line"; OldReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnRcptLineModify(var ReturnRcptLine: Record "Return Receipt Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; DocLineNo: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var ReturnRcptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnRcptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(ReturnRcptLine: Record "Return Receipt Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewReturnRcptLineInsert(var NewReturnReceiptLine: Record "Return Receipt Line"; OldReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ReturnReceiptLine: Record "Return Receipt Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnRcptLineModify(var ReturnReceiptLine: Record "Return Receipt Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderLine(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOrderLineOnBeforeUpdateSalesLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReturnRcptLineOnBeforeCheckReturnQtyRcdNotInvd(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReturnRcptLineOnBeforeCollectItemLedgEntries(var ReturnRcptLine: Record "Return Receipt Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCallCheckReturnRcptLine(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterRunItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; ReturnReceiptLine: Record "Return Receipt Line"; ReturnReceiptHeader: Record "Return Receipt Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;
}

