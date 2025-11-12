// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

codeunit 9030 "Undo Transfer Shipment"
{
    Permissions = TableData "Transfer Line" = rimd,
                  TableData "Transfer Shipment Line" = rimd,
                  TableData "Item Application Entry" = rmd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Transfer Shipment Line";

    trigger OnRun()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled, HideDialog);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(ReallyUndoQst) then
                exit;

        TransShptLine.Copy(Rec);
        Code();
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := TransShptLine;
    end;

    var
        TransShptLine: Record "Transfer Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        HideDialog: Boolean;
        NextLineNo: Integer;

        ReallyUndoQst: Label 'Do you really want to undo the selected Shipment lines?';
        UndoQtyMsg: Label 'Undo quantity posting...';
        NotEnoughLineSpaceErr: Label 'There is not enough space to insert correction lines.';
        CheckingLinesMsg: Label 'Checking lines...';
        AlreadyReversedErr: Label 'This shipment has already been reversed.';
        AlreadyReceivedErr: Label 'This shipment has already been received. Undo Shipment can only be applied to posted, but not received Transfer Lines.';
        NoDerivedTransOrderLineNoErr: Label 'The Transfer Shipment Line is missing a value in the field Derived Trans. Order Line No. This is automatically populated when posting new Transfer Shipments';
        NoTransOrderLineNoErr: Label 'The Transfer Shipment Line is missing a value in the field Trans. Order Line No. This is automatically populated when posting new Transfer Shipments';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        TransferLine: Record "Transfer Line";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        Direction: Enum "Transfer Direction";
        PostedWhseShptLineFound: Boolean;
    begin
        Clear(ItemJnlPostLine);
        TransShptLine.SetCurrentKey("Item Shpt. Entry No.");
        TransShptLine.SetFilter(Quantity, '<>0');
        TransShptLine.SetRange("Correction Line", false);
        OnCodeOnAfterTransShptLineSetFilters(TransShptLine);

        if TransShptLine.IsEmpty() then
            Error(AlreadyReversedErr);
        TransShptLine.FindSet();
        repeat
            if not HideDialog then
                Window.Open(CheckingLinesMsg);
            CheckTransferShptLine(TransShptLine);
        until TransShptLine.Next() = 0;

        TransShptLine.FindSet();
        repeat
            OnCodeOnBeforeUndoLoop(TransShptLine);
            if TransShptLine."Trans. Order Line No." = 0 then
                Error(NoTransOrderLineNoErr);
            TransferLine.Get(TransShptLine."Transfer Order No.", TransShptLine."Trans. Order Line No.");
            if TransferLine."Qty. Received (Base)" > 0 then
                Error(AlreadyReceivedErr);
            if TransShptLine."Derived Trans. Order Line No." = 0 then
                Error(NoDerivedTransOrderLineNoErr);

            TempGlobalItemLedgEntry.Reset();
            if not TempGlobalItemLedgEntry.IsEmpty() then
                TempGlobalItemLedgEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty() then
                TempGlobalItemEntryRelation.DeleteAll();

            if not HideDialog then
                Window.Open(UndoQtyMsg);

            PostedWhseShptLineFound :=
             WhseUndoQty.FindPostedWhseShptLine(
                 PostedWhseShptLine, Database::"Transfer Shipment Line", TransShptLine."Document No.",
                 Database::"Transfer Line", Direction::Outbound.AsInteger(), TransShptLine."Transfer Order No.", TransShptLine."Line No.");

            // Undo derived transfer line and move tracking to current line
            UndoPostingMgt.UpdateDerivedTransferLine(TransferLine, TransShptLine);

            Clear(ItemJnlPostLine);
            ItemShptEntryNo := PostItemJnlLine(TransShptLine, DocLineNo);
            InsertNewShipmentLine(TransShptLine, ItemShptEntryNo, DocLineNo);
            OnAfterInsertNewShipmentLine(TransShptLine, PostedWhseShptLine, PostedWhseShptLineFound, DocLineNo);

            if PostedWhseShptLineFound then
                WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

            TempWhseJnlLine.SetRange("Source Line No.", TransShptLine."Line No.");
            WhseUndoQty.PostTempWhseJnlLineCache(TempWhseJnlLine, WhseJnlRegisterLine);

            OnCodeOnAfterPostTempWhseJnlLineCache(TransShptLine, ItemJnlPostLine, WhseJnlRegisterLine);

            UpdateOrderLine(TransShptLine);
            if PostedWhseShptLineFound then
                WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

            TransShptLine."Correction Line" := true;
            OnBeforeModifyTransShptLine(TransShptLine);
            TransShptLine.Modify();

        until TransShptLine.Next() = 0;

        MakeInventoryAdjustment();
        OnAfterCode(TransShptLine);
    end;

    local procedure CheckTransferShptLine(TransShptLine: Record "Transfer Shipment Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        if TransShptLine."Correction Line" then
            Error(AlreadyReversedErr);

        UndoPostingMgt.TestTransferShptLine(TransShptLine);

        UndoPostingMgt.CollectItemLedgEntries(
            TempItemLedgEntry, Database::"Transfer Shipment Line", TransShptLine."Document No.", TransShptLine."Line No.", TransShptLine."Quantity (Base)", TransShptLine."Item Shpt. Entry No.");
        UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, TransShptLine."Line No.", false);
    end;

    procedure GetCorrectionLineNo(TransferShptLine: Record "Transfer Shipment Line") Result: Integer;
    var
        TransferShptLine2: Record "Transfer Shipment Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(TransferShptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TransferShptLine2.SetRange("Document No.", TransferShptLine."Document No.");
        TransferShptLine2.SetFilter("Line No.", '>%1', TransferShptLine."Line No.");
        if TransferShptLine2.FindFirst() then begin
            LineSpacing := (TransferShptLine2."Line No." - TransferShptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(NotEnoughLineSpaceErr);
        end else
            LineSpacing := 10000;

        Result := TransferShptLine."Line No." + LineSpacing;
        OnAfterGetCorrectionLineNo(TransferShptLine, Result);
    end;

    local procedure PostItemJnlLine(TransShptLine: Record "Transfer Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        TransShptHeader: Record "Transfer Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        TempDummyItemEntryRelation: Record "Item Entry Relation" temporary;
        ItemLedgEntry: Record "Item Ledger Entry";
        Direction: Enum "Transfer Direction";
    begin
        DocLineNo := GetCorrectionLineNo(TransShptLine);

        SourceCodeSetup.Get();
        TransShptHeader.Get(TransShptLine."Document No.");

        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
        ItemJnlLine."Item No." := TransShptLine."Item No.";
        ItemJnlLine."Posting Date" := TransShptHeader."Posting Date";
        ItemJnlLine."Document No." := TransShptLine."Document No.";
        ItemJnlLine."Document Line No." := DocLineNo;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Transfer Shipment";
        ItemJnlLine."Gen. Prod. Posting Group" := TransShptLine."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := TransShptLine."Inventory Posting Group";
        ItemJnlLine."Location Code" := TransShptLine."Transfer-from Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Transfer;
        ItemJnlLine.Correction := true;
        ItemJnlLine."Variant Code" := TransShptLine."Variant Code";
        ItemJnlLine."Bin Code" := TransShptLine."Transfer-from Bin Code";
        ItemJnlLine."Document Date" := TransShptHeader."Shipment Date";
        ItemJnlLine."Unit of Measure Code" := TransShptLine."Unit of Measure Code";

        OnAfterCopyItemJnlLineFromTransShpt(ItemJnlLine, TransShptHeader, TransShptLine);

        WhseUndoQty.InsertTempWhseJnlLine(
                       ItemJnlLine,
                       Database::"Transfer Line", Direction::Outbound.AsInteger(), TransShptLine."Transfer Order No.", TransShptLine."Line No.",
                       TempWhseJnlLine."Reference Document"::"Posted T. Shipment".AsInteger(), TempWhseJnlLine, NextLineNo);

        if GetShptEntries(TransShptLine, ItemLedgEntry) then begin
            ItemLedgEntry.SetTrackingFilterBlank();
            if ItemLedgEntry.FindSet() then begin
                // First undo In-Transit item ledger entries
                ItemLedgEntry.SetRange("Location Code", TransShptHeader."In-Transit Code");
                ItemLedgEntry.FindSet();
                PostCorrectiveItemLedgEntries(ItemJnlLine, ItemLedgEntry);

                // Then undo from-location item ledger entries
                ItemLedgEntry.SetRange("Location Code", TransShptHeader."Transfer-from Code");
                ItemLedgEntry.FindSet();
                PostCorrectiveItemLedgEntries(ItemJnlLine, ItemLedgEntry);

                exit(ItemJnlLine."Item Shpt. Entry No.");
            end
            else begin
                ItemLedgEntry.ClearTrackingFilter();
                ItemLedgEntry.FindSet();
                MoveItemLedgerEntriesToTempRec(ItemLedgEntry, TempApplyToEntryList);
                // First undo In-Transit item ledger entries
                TempApplyToEntryList.SetRange("Location Code", TransShptHeader."In-Transit Code");
                TempApplyToEntryList.FindSet();
                //Pass dummy ItemEntryRelation because, these are not used for In-Transit location
                UndoPostingMgt.PostItemJnlLineAppliedToList(
                    ItemJnlLine, TempApplyToEntryList, TransShptLine.Quantity, TransShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempDummyItemEntryRelation, false);

                // Then undo from-location item ledger entries
                TempApplyToEntryList.SetRange("Location Code", TransShptHeader."Transfer-from Code");
                TempApplyToEntryList.FindSet();
                UndoPostingMgt.PostItemJnlLineAppliedToList(
                    ItemJnlLine, TempApplyToEntryList, TransShptLine.Quantity, TransShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, false);
            end;
        end;
        exit(0);
    end;

    local procedure MoveItemLedgerEntriesToTempRec(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
        if ItemLedgerEntry.FindSet() then
            repeat
                TempItemLedgerEntry.TransferFields(ItemLedgerEntry);
                TempItemLedgerEntry.Insert();
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure PostCorrectiveItemLedgEntries(var ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        OnBeforePostCorrectiveItemLedgEntries(ItemJnlLine, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        repeat
            ItemJnlLine."Applies-to Entry" := ItemLedgEntry."Entry No.";
            ItemJnlLine."Location Code" := ItemLedgEntry."Location Code";
            ItemJnlLine.Quantity := ItemLedgEntry.Quantity;
            ItemJnlLine."Quantity (Base)" := ItemLedgEntry.Quantity;
            ItemJnlLine."Invoiced Quantity" := ItemLedgEntry."Invoiced Quantity";
            ItemJnlLine."Invoiced Qty. (Base)" := ItemLedgEntry."Invoiced Quantity";
            OnPostCorrectiveItemLedgEntriesOnBeforeRun(ItemJnlLine, ItemLedgEntry);
            ItemJnlPostLine.Run(ItemJnlLine);
        until ItemLedgEntry.Next() = 0;
    end;

    local procedure InsertNewShipmentLine(OldTransShptLine: Record "Transfer Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewTransShptLine: Record "Transfer Shipment Line";
    begin
        NewTransShptLine.Init();
        NewTransShptLine.Copy(OldTransShptLine);
        NewTransShptLine."Derived Trans. Order Line No." := 0;
        NewTransShptLine."Line No." := DocLineNo;
        NewTransShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewTransShptLine.Quantity := -OldTransShptLine.Quantity;
        NewTransShptLine."Quantity (Base)" := -OldTransShptLine."Quantity (Base)";
        NewTransShptLine."Correction Line" := true;
        NewTransShptLine."Dimension Set ID" := OldTransShptLine."Dimension Set ID";
        OnBeforeInsertNewTransShptLine(NewTransShptLine, OldTransShptLine);
        NewTransShptLine.Insert();

        InsertItemEntryRelation(TempGlobalItemEntryRelation, NewTransShptLine, OldTransShptLine."Trans. Order Line No.");
    end;

    procedure UpdateOrderLine(TransShptLine: Record "Transfer Shipment Line")
    var
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderLine(TransShptLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine.Get(TransShptLine."Transfer Order No.", TransShptLine."Line No.");
        UndoPostingMgt.UpdateTransLine(
            TransferLine, TransShptLine.Quantity,
            TransShptLine."Quantity (Base)",
            TempGlobalItemLedgEntry);
        OnAfterUpdateOrderLine(TransferLine, TransShptLine);
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewTransShptLine: Record "Transfer Shipment Line"; OrderLineNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.FindFirst() then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsTransShptLine(NewTransShptLine);
                ItemEntryRelation."Order Line No." := OrderLineNo;
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure GetShptEntries(TransShptLine: Record "Transfer Shipment Line"; var ItemLedgEntry: Record "Item Ledger Entry") Found: Boolean
    begin
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Transfer Shipment");
        ItemLedgEntry.SetRange("Document No.", TransShptLine."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", TransShptLine."Line No.");
        Found := ItemLedgEntry.FindSet();

        if Found then
            repeat
                ItemJnlPostLine.MarkAppliedInboundItemEntriesForAdjustment(ItemLedgEntry."Entry No.");
            until ItemLedgEntry.Next() = 0;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup."Automatic Cost Adjustment" <> InvtSetup."Automatic Cost Adjustment"::Never then begin
            InvtAdjmtHandler.SetJobUpdateProperties(true);
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var TransferShipmentLine: Record "Transfer Shipment Line"; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterTransShptLineSetFilters(var TransShptLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeUndoLoop(var TransShptLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewShipmentLine(var TransShptLine: Record "Transfer Shipment Line"; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var TransShptLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(TransShptLine: Record "Transfer Shipment Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCorrectionLineNo(TransShptLine: Record "Transfer Shipment Line"; var Result: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderLine(var TransShptLine: Record "Transfer Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOrderLine(var TransferLine: Record "Transfer Line"; var TransShptLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewTransShptLine(var TransferShipmentLineNew: Record "Transfer Shipment Line"; TransferShipmentLineOld: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTransShptLine(var TransferShipmentLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromTransShpt(var ItemJournalLine: Record "Item Journal Line"; TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCorrectiveItemLedgEntriesOnBeforeRun(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPostTempWhseJnlLineCache(var TransferShipmentLine: Record "Transfer Shipment Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCorrectiveItemLedgEntries(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

