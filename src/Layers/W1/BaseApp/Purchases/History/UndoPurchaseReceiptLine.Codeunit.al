// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;

codeunit 5813 "Undo Purchase Receipt Line"
{
    Permissions = TableData "Purchase Line" = rimd,
                  TableData "Purch. Rcpt. Line" = rimd,
                  TableData "Item Entry Relation" = ri,
                  TableData "Whse. Item Entry Relation" = rimd;
    TableNo = "Purch. Rcpt. Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        SkipTypeCheck: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTypeCheck, HideDialog);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(Text000) then
                exit;

        PurchRcptLine.Copy(Rec);
        Code();
        Rec := PurchRcptLine;
    end;

    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemsToAdjust: List of [Code[20]];
        HideDialog: Boolean;
        JobItem: Boolean;
        NextLineNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'Do you really want to undo the selected Receipt lines?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        Text003: Label 'Checking lines...';
        Text004: Label 'This receipt has already been invoiced. Undo Receipt can be applied only to posted, but not invoiced receipts.';
#pragma warning restore AA0074
        NoLinesForCorrectionErr: Label 'There is no lines with quantity to process.';
        AlreadyReversedErr: Label 'This receipt has already been reversed.';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        PurchLine: Record "Purchase Line";
        Window: Dialog;
        ItemRcptEntryNo: Integer;
        DocLineNo: Integer;
        PostedWhseRcptLineFound: Boolean;
    begin
        OnBeforeCode(PurchRcptLine, UndoPostingMgt);

        CheckPurchRcptLines(PurchRcptLine, Window);

        BindSubscription(this);
        PurchRcptLine.Find('-');
        OnCodeOnBeforeLoopPurchRcptLine(PurchRcptLine);
        repeat
            TempGlobalItemLedgEntry.Reset();
            if not TempGlobalItemLedgEntry.IsEmpty() then
                TempGlobalItemLedgEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty() then
                TempGlobalItemEntryRelation.DeleteAll();

            if not HideDialog then
                Window.Open(Text001);

            if PurchRcptLine.Type = PurchRcptLine.Type::Item then begin
                PostedWhseRcptLineFound :=
                WhseUndoQty.FindPostedWhseRcptLine(
                    PostedWhseRcptLine,
                    DATABASE::"Purch. Rcpt. Line",
                    PurchRcptLine."Document No.",
                    DATABASE::"Purchase Line",
                    PurchLine."Document Type"::Order.AsInteger(),
                    PurchRcptLine."Order No.",
                    PurchRcptLine."Order Line No.");

                ItemRcptEntryNo := PostItemJnlLine(PurchRcptLine, DocLineNo);
            end else
                DocLineNo := GetCorrectionLineNo(PurchRcptLine);

            InsertNewReceiptLine(PurchRcptLine, ItemRcptEntryNo, DocLineNo);
            OnAfterInsertNewReceiptLine(PurchRcptLine, PostedWhseRcptLine, PostedWhseRcptLineFound, DocLineNo, PostedWhseRcptLine);

            if PostedWhseRcptLineFound then
                WhseUndoQty.UndoPostedWhseRcptLine(PostedWhseRcptLine);

            UpdateOrderLine(PurchRcptLine);
            if PostedWhseRcptLineFound then
                WhseUndoQty.UpdateRcptSourceDocLines(PostedWhseRcptLine);

            if (PurchRcptLine."Blanket Order No." <> '') and (PurchRcptLine."Blanket Order Line No." <> 0) then
                UpdateBlanketOrder(PurchRcptLine);

            PurchRcptLine."Quantity Invoiced" := PurchRcptLine.Quantity;
            PurchRcptLine."Qty. Invoiced (Base)" := PurchRcptLine."Quantity (Base)";
            PurchRcptLine."Qty. Rcd. Not Invoiced" := 0;
            PurchRcptLine.Correction := true;

            OnBeforePurchRcptLineModify(PurchRcptLine, TempWhseJnlLine);
            PurchRcptLine.Modify();
            OnAfterPurchRcptLineModify(PurchRcptLine, TempWhseJnlLine, DocLineNo, UndoPostingMgt);

            if not JobItem then
                JobItem := (PurchRcptLine.Type = PurchRcptLine.Type::Item) and (PurchRcptLine."Job No." <> '');
        until PurchRcptLine.Next() = 0;
        UnbindSubscription(this);

        OnCodeOnBeforeMakeInventoryAdjustment(PurchLine, PurchRcptLine);
        MakeInventoryAdjustment();

        WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);

        OnAfterCode(PurchRcptLine, UndoPostingMgt);
    end;

    local procedure CheckPurchRcptLines(var PurchRcptLine: Record "Purch. Rcpt. Line"; var Window: Dialog)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchRcptLines(PurchRcptLine, Window, IsHandled);
        if IsHandled then
            exit;

        PurchRcptLine.SetFilter(Quantity, '<>0');
        PurchRcptLine.SetRange(Correction, false);
        OnCheckPurchRcptLinesAfterPurchRcptLineSetFilters(PurchRcptLine);
        if PurchRcptLine.IsEmpty() then
            Error(NoLinesForCorrectionErr);

        PurchRcptLine.FindFirst();
        repeat
            if not HideDialog then
                Window.Open(Text003);
            CheckPurchRcptLine(PurchRcptLine);
        until PurchRcptLine.Next() = 0;
    end;

    local procedure CheckPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchRcptLine(PurchRcptLine, IsHandled, TempItemLedgEntry);
        if IsHandled then
            exit;

        if PurchRcptLine.Correction then
            Error(AlreadyReversedErr);
        if PurchRcptLine."Qty. Rcd. Not Invoiced" <> PurchRcptLine.Quantity then begin
            if PurchRcptLine.IsProdOrder() then
                Error(Text004);
            if HasInvoicedNotReturnedQuantity(PurchRcptLine) then
                Error(Text004);
        end;
        if PurchRcptLine.Type = PurchRcptLine.Type::Item then begin
            CheckPurchRcptLineFields(PurchRcptLine);
            UndoPostingMgt.TestPurchRcptLine(PurchRcptLine);
            IsHandled := false;
            OnCheckPurchRcptLineOnBeforeCollectItemLedgEntries(PurchRcptLine, TempItemLedgEntry, IsHandled);
            if not IsHandled then
                if PurchRcptLine.IsProdOrder() then begin
                    if UndoPostingMgt.CollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine(TempItemLedgEntry, PurchRcptLine) then
                        UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, PurchRcptLine."Line No.", PurchRcptLine."Qty. Rcd. Not Invoiced" <> PurchRcptLine.Quantity);
                end else begin
                    UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Purch. Rcpt. Line",
                      PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."Quantity (Base)", PurchRcptLine."Item Rcpt. Entry No.");
                    UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, PurchRcptLine."Line No.", PurchRcptLine."Qty. Rcd. Not Invoiced" <> PurchRcptLine.Quantity);
                end;
        end;
    end;

    local procedure GetCorrectionLineNo(PurchRcptLine: Record "Purch. Rcpt. Line") Result: Integer
    var
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(PurchRcptLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        PurchRcptLine2.SetRange("Document No.", PurchRcptLine."Document No.");
        PurchRcptLine2."Document No." := PurchRcptLine."Document No.";
        PurchRcptLine2."Line No." := PurchRcptLine."Line No.";
        PurchRcptLine2.Find('=');

        if PurchRcptLine2.Find('>') then begin
            LineSpacing := (PurchRcptLine2."Line No." - PurchRcptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;
        exit(PurchRcptLine."Line No." + LineSpacing);
    end;

    local procedure PostItemJnlLine(PurchRcptLine: Record "Purch. Rcpt. Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToEntryList: Record "Item Ledger Entry" temporary;
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemLedgEntryNo: Integer;
        ItemRcptEntryNo: Integer;
        ItemShptEntryNo: Integer;
        IsHandled: Boolean;
        NewDocLineNo: Integer;
        ItemRcptEntryNoFilled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(PurchRcptLine, DocLineNo, ItemLedgEntryNo, IsHandled, NewDocLineNo, TempWhseJnlLine);
        if NewDocLineNo > DocLineNo then
            DocLineNo := NewDocLineNo;
        if IsHandled then
            exit(ItemLedgEntryNo);

        if NewDocLineNo = 0 then
            DocLineNo := GetCorrectionLineNo(PurchRcptLine);

        SourceCodeSetup.Get();
        PurchRcptHeader.Get(PurchRcptLine."Document No.");
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
        ItemJnlLine."Item No." := PurchRcptLine."No.";
        ItemJnlLine."Posting Date" := PurchRcptHeader."Posting Date";
        ItemJnlLine."Document No." := PurchRcptLine."Document No.";
        ItemJnlLine."Document Line No." := DocLineNo;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Receipt";
        ItemJnlLine."Gen. Bus. Posting Group" := PurchRcptLine."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := PurchRcptLine."Gen. Prod. Posting Group";
        ItemJnlLine."Location Code" := PurchRcptLine."Location Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Purchases;
        ItemJnlLine."Variant Code" := PurchRcptLine."Variant Code";
        ItemJnlLine."Bin Code" := PurchRcptLine."Bin Code";
        ItemJnlLine."Unit of Measure Code" := PurchRcptLine."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := PurchRcptLine."Qty. per Unit of Measure";
        ItemJnlLine."Document Date" := PurchRcptHeader."Document Date";
        ItemJnlLine."Shortcut Dimension 1 Code" := PurchRcptLine."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := PurchRcptLine."Shortcut Dimension 2 Code";
        ItemJnlLine."Dimension Set ID" := PurchRcptLine."Dimension Set ID";

        if PurchRcptLine."Job No." = '' then begin
            ItemJnlLine.Correction := true;
            ItemJnlLine."Applies-to Entry" := PurchRcptLine."Item Rcpt. Entry No.";
        end else begin
            ItemJnlLine."Job No." := PurchRcptLine."Job No.";
            ItemJnlLine."Job Task No." := PurchRcptLine."Job Task No.";
            ItemJnlLine."Job Purchase" := true;
            ItemJnlLine."Unit Cost" := PurchRcptLine."Unit Cost (LCY)";
        end;

        ItemJnlLine.Quantity := -(PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced");
        ItemJnlLine."Quantity (Base)" := -(PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)");

        ItemRcptEntryNoFilled := PurchRcptLine."Item Rcpt. Entry No." <> 0;

        if PurchRcptLine.IsProdOrder() then
            OnUpdateItemJnlLineProdOrderSubcontracting(ItemJnlLine, PurchRcptLine, TempApplyToEntryList, ItemRcptEntryNoFilled);

        IsHandled := false;
        OnAfterCopyItemJnlLineFromPurchRcpt(ItemJnlLine, PurchRcptHeader, PurchRcptLine, WhseUndoQty, ItemLedgEntryNo, NextLineNo, TempWhseJnlLine, TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        WhseUndoQty.InsertTempWhseJnlLine(ItemJnlLine,
          DATABASE::"Purchase Line", PurchLine."Document Type"::Order.AsInteger(), PurchRcptLine."Order No.", PurchRcptLine."Order Line No.",
          TempWhseJnlLine."Reference Document"::"Posted Rcpt.".AsInteger(), TempWhseJnlLine, NextLineNo);
        OnPostItemJnlLineOnAfterInsertTempWhseJnlLine(PurchRcptLine, ItemJnlLine, TempWhseJnlLine, NextLineNo);

        if ItemRcptEntryNoFilled then begin
            if PurchRcptLine."Job No." <> '' then
                UndoPostingMgt.TransferSourceValues(ItemJnlLine, PurchRcptLine."Item Rcpt. Entry No.");

            IsHandled := false;
            OnPostItemJnlLineOnBeforeUndoPosting(ItemJnlLine, PurchRcptHeader, PurchRcptLine, SourceCodeSetup, IsHandled);
            if IsHandled then
                exit(ItemJnlLine."Item Shpt. Entry No.");

            UndoPostingMgt.PostItemJnlLine(ItemJnlLine);

            IsHandled := false;
            OnPostItemJnlLineOnBeforeUndoValuePostingWithJob(PurchRcptHeader, PurchRcptLine, ItemJnlLine, IsHandled);
            if not IsHandled then
                if PurchRcptLine."Job No." <> '' then begin
                    Item.Get(PurchRcptLine."No.");
                    if Item.Type = Item.Type::Inventory then begin
                        ItemLedgerEntry.Get(PurchRcptLine."Item Rcpt. Entry No.");
                        if ItemLedgerEntry.Positive then begin
                            ItemRcptEntryNo := PurchRcptLine."Item Rcpt. Entry No.";
                            ItemShptEntryNo := ItemJnlLine."Item Shpt. Entry No.";
                        end else begin
                            ItemApplicationEntry.GetInboundEntriesTheOutbndEntryAppliedTo(PurchRcptLine."Item Rcpt. Entry No.");
                            ItemRcptEntryNo := ItemApplicationEntry."Inbound Item Entry No.";
                            ItemApplicationEntry.GetOutboundEntriesAppliedToTheInboundEntry(ItemJnlLine."Item Shpt. Entry No.");
                            ItemShptEntryNo := ItemApplicationEntry."Outbound Item Entry No.";
                        end;
                        UndoPostingMgt.FindItemReceiptApplication(ItemApplicationEntry, ItemRcptEntryNo);
                        ItemJnlPostLine.UndoValuePostingWithJob(
                          ItemRcptEntryNo, ItemApplicationEntry."Outbound Item Entry No.");
                        IsHandled := false;
                        OnPostItemJournalInboundItemEntryPostingWithJob(ItemJnlLine, ItemApplicationEntry, IsHandled);
                        if not IsHandled then begin
                            UndoPostingMgt.FindItemShipmentApplication(ItemApplicationEntry, ItemShptEntryNo);
                            ItemJnlPostLine.UndoValuePostingWithJob(
                              ItemApplicationEntry."Inbound Item Entry No.", ItemShptEntryNo);
                        end;
                        Clear(UndoPostingMgt);
                        UndoPostingMgt.ReapplyJobConsumption(ItemRcptEntryNo);
                    end;
                end;

            exit(ItemShptEntryNo);
        end;

        if not PurchRcptLine.IsProdOrder() then
            UndoPostingMgt.CollectItemLedgEntries(
              TempApplyToEntryList, DATABASE::"Purch. Rcpt. Line", PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."Quantity (Base)", PurchRcptLine."Item Rcpt. Entry No.");

        if PurchRcptLine.IsProdOrder() then //When subcontracting base value is 0, value required for UndoPostingMgt.PostItemJnlLineAppliedToList call
            PurchRcptLine."Quantity (Base)" := UOMMgt.CalcBaseQty(PurchRcptLine."No.", '', PurchRcptLine."Unit of Measure Code", PurchRcptLine.Quantity, PurchRcptLine."Qty. per Unit of Measure", 0);

        IsHandled := false;
        OnPostItemJnlLineOnAfterCollectItemLedgEntries(PurchRcptHeader, PurchRcptLine, SourceCodeSetup, IsHandled);
        if IsHandled then
            exit(0);
        // "Item Shpt. Entry No."
        if PurchRcptLine."Job No." <> '' then
            ReapplyJobConsumptionFromApplyToEntryList(PurchRcptHeader, PurchRcptLine, ItemJnlLine, TempApplyToEntryList);

        if ItemJnlLine.Subcontracting and (TempApplyToEntryList.Count() = 0) then  //if no output posted
            UndoPostingMgt.PostItemJnlLine(ItemJnlLine)
        else
            UndoPostingMgt.PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToEntryList,
              PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced", PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, PurchRcptLine."Qty. Rcd. Not Invoiced" <> PurchRcptLine.Quantity);

        exit(0); // "Item Shpt. Entry No."
    end;

    local procedure ReapplyJobConsumptionFromApplyToEntryList(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchRcptLine: Record "Purch. Rcpt. Line"; ItemJnlLine: Record "Item Journal Line"; var TempApplyToEntryList: Record "Item Ledger Entry" temporary)
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ShowAppliedEntries: Codeunit "Show Applied Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReapplyJobConsumptionFromApplyToEntryList(PurchRcptHeader, PurchRcptLine, ItemJnlLine, TempApplyToEntryList, IsHandled);
        if IsHandled then
            exit;

        if TempApplyToEntryList.FindSet() then
            repeat
                //negative purchase receipt linked with job
                if (TempApplyToEntryList."Entry Type" = TempApplyToEntryList."Entry Type"::Purchase) and (TempApplyToEntryList."Document Type" = TempApplyToEntryList."Document Type"::"Purchase Receipt") and (TempApplyToEntryList.Quantity < 0) and (TempApplyToEntryList."Job No." <> '') then begin
                    ShowAppliedEntries.FindAppliedEntries(TempApplyToEntryList, TempItemLedgerEntry);
                    TempItemLedgerEntry.FindSet();
                    repeat
                        UndoPostingMgt.ReapplyJobConsumption(TempItemLedgerEntry."Entry No.");
                    until TempItemLedgerEntry.Next() = 0;
                end else
                    UndoPostingMgt.ReapplyJobConsumption(TempApplyToEntryList."Entry No.");
            until TempApplyToEntryList.Next() = 0;
    end;

    local procedure InsertNewReceiptLine(OldPurchRcptLine: Record "Purch. Rcpt. Line"; ItemRcptEntryNo: Integer; DocLineNo: Integer)
    var
        NewPurchRcptLine: Record "Purch. Rcpt. Line";
        SkipInsertItemEntryRelation: Boolean;
    begin
        NewPurchRcptLine.Init();
        NewPurchRcptLine.Copy(OldPurchRcptLine);
        NewPurchRcptLine."Line No." := DocLineNo;
        NewPurchRcptLine."Appl.-to Item Entry" := OldPurchRcptLine."Item Rcpt. Entry No.";
        NewPurchRcptLine."Item Rcpt. Entry No." := ItemRcptEntryNo;
        NewPurchRcptLine.Quantity := -OldPurchRcptLine.Quantity;
        NewPurchRcptLine."Quantity (Base)" := -OldPurchRcptLine."Quantity (Base)";
        NewPurchRcptLine."Quantity Invoiced" := NewPurchRcptLine.Quantity;
        NewPurchRcptLine."Qty. Invoiced (Base)" := NewPurchRcptLine."Quantity (Base)";
        NewPurchRcptLine."Qty. Rcd. Not Invoiced" := 0;
        NewPurchRcptLine.Correction := true;
        NewPurchRcptLine."Dimension Set ID" := OldPurchRcptLine."Dimension Set ID";
        OnBeforeNewPurchRcptLineInsert(NewPurchRcptLine, OldPurchRcptLine);
        NewPurchRcptLine.Insert();
        SkipInsertItemEntryRelation := false;
        OnAfterNewPurchRcptLineInsert(NewPurchRcptLine, OldPurchRcptLine, TempGlobalItemEntryRelation, SkipInsertItemEntryRelation);
        if not SkipInsertItemEntryRelation then
            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewPurchRcptLine);
    end;

    procedure UpdateOrderLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderLine(PurchRcptLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Get(PurchLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
        OnUpdateOrderLineOnBeforeUpdatePurchLine(PurchRcptLine, PurchLine);
        UndoPostingMgt.UpdatePurchLine(PurchLine, PurchRcptLine.Quantity - PurchRcptLine."Quantity Invoiced", PurchRcptLine."Quantity (Base)" - PurchRcptLine."Qty. Invoiced (Base)", TempGlobalItemLedgEntry);
        UndoPostingMgt.UpdatePurchaseLineOverRcptQty(PurchLine, PurchRcptLine."Over-Receipt Quantity");
        OnAfterUpdateOrderLine(PurchRcptLine, PurchLine);
    end;

    procedure UpdateBlanketOrder(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        BlanketOrderPurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBlanketOrder(PurchRcptLine, IsHandled);
        if IsHandled then
            exit;

        if BlanketOrderPurchaseLine.Get(
            BlanketOrderPurchaseLine."Document Type"::"Blanket Order", PurchRcptLine."Blanket Order No.", PurchRcptLine."Blanket Order Line No.")
        then begin
            BlanketOrderPurchaseLine.TestField(Type, PurchRcptLine.Type);
            BlanketOrderPurchaseLine.TestField("No.", PurchRcptLine."No.");
            BlanketOrderPurchaseLine.TestField("Buy-from Vendor No.", PurchRcptLine."Buy-from Vendor No.");

            if BlanketOrderPurchaseLine."Qty. per Unit of Measure" = PurchRcptLine."Qty. per Unit of Measure" then
                BlanketOrderPurchaseLine."Quantity Received" := BlanketOrderPurchaseLine."Quantity Received" - PurchRcptLine.Quantity
            else
                BlanketOrderPurchaseLine."Quantity Received" :=
                  BlanketOrderPurchaseLine."Quantity Received" -
                  Round(
                    PurchRcptLine."Qty. per Unit of Measure" / BlanketOrderPurchaseLine."Qty. per Unit of Measure" * PurchRcptLine.Quantity, UOMMgt.QtyRndPrecision());

            BlanketOrderPurchaseLine."Qty. Received (Base)" := BlanketOrderPurchaseLine."Qty. Received (Base)" - PurchRcptLine."Quantity (Base)";
            OnBeforeBlanketOrderInitOutstanding(BlanketOrderPurchaseLine, PurchRcptLine);
            BlanketOrderPurchaseLine.InitOutstanding();
            BlanketOrderPurchaseLine.Modify();
        end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewPurchRcptLine: Record "Purch. Rcpt. Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsPurchRcptLine(NewPurchRcptLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    procedure HasInvoicedNotReturnedQuantity(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnedInvoicedItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        InvoicedQuantity: Decimal;
        ReturnedInvoicedQuantity: Decimal;
    begin
        if PurchRcptLine.Type = PurchRcptLine.Type::Item then begin
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Purchase");
            ItemLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
            ItemLedgerEntry.SetRange("Document Line No.", PurchRcptLine."Line No.");
            ItemLedgerEntry.SetLoadFields("Invoiced Quantity", "Entry No.");
            ItemLedgerEntry.FindSet();
            repeat
                InvoicedQuantity += ItemLedgerEntry."Invoiced Quantity";
                if ItemApplicationEntry.AppliedOutbndEntryExists(ItemLedgerEntry."Entry No.", false, false) then
                    repeat
                        if ItemApplicationEntry."Item Ledger Entry No." = ItemApplicationEntry."Outbound Item Entry No." then begin
                            ReturnedInvoicedItemLedgerEntry.Get(ItemApplicationEntry."Item Ledger Entry No.");
                            if IsCancelled(ReturnedInvoicedItemLedgerEntry) then
                                ReturnedInvoicedQuantity += ReturnedInvoicedItemLedgerEntry."Invoiced Quantity";
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until ItemLedgerEntry.Next() = 0;
            exit(InvoicedQuantity + ReturnedInvoicedQuantity <> 0);
        end else begin
            PurchInvLine.SetRange("Order No.", PurchRcptLine."Order No.");
            PurchInvLine.SetRange("Order Line No.", PurchRcptLine."Order Line No.");
            if PurchInvLine.FindSet() then
                repeat
                    PurchInvHeader.Get(PurchInvLine."Document No.");
                    PurchInvHeader.CalcFields(Cancelled);
                    if not PurchInvHeader.Cancelled then
                        exit(true);
                until PurchInvLine.Next() = 0;

            exit(false);
        end;
    end;

    local procedure IsCancelled(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        CancelledDocument: Record "Cancelled Document";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                begin
                    ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    if ReturnShipmentHeader."Applies-to Doc. Type" = ReturnShipmentHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Purch. Inv. Header", ReturnShipmentHeader."Applies-to Doc. No."));
                end;
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                begin
                    PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.");
                    if PurchCrMemoHdr."Applies-to Doc. Type" = PurchCrMemoHdr."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Purch. Inv. Header", PurchCrMemoHdr."Applies-to Doc. No."));
                end;
        end;

        exit(false);
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtAdjmtHandler.SetJobUpdateProperties(not JobItem);
        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust);
    end;

    local procedure CheckPurchRcptLineFields(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchRcptLineFields(PurchRcptLine, IsHandled);
        if IsHandled then
            exit;

        PurchRcptLine.TestField("Sales Order No.", '');
        PurchRcptLine.TestField("Sales Order Line No.", 0);
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
    local procedure OnAfterCode(var PurchRcptLine: Record "Purch. Rcpt. Line"; var UndoPostingManagement: Codeunit "Undo Posting Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchRcpt(var ItemJournalLine: Record "Item Journal Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var WhseUndoQty: Codeunit "Whse. Undo Quantity"; var ItemLedgEntryNo: Integer; var NextLineNo: Integer; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempGlobalItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var PostedWhseRcptLineFound: Boolean; DocLineNo: Integer; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewPurchRcptLineInsert(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line"; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var SkipInsertItemEntryRelation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchRcptLineModify(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; DocLineNo: Integer; var UndoPostingManagement: Codeunit "Undo Posting Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOrderLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderInitOutstanding(var BlanketOrderPurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var PurchRcptLine: Record "Purch. Rcpt. Line"; var UndoPostingManagement: Codeunit "Undo Posting Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchRcptLines(var PurchRcptLine: Record "Purch. Rcpt. Line"; var Window: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(PurchRcptLine: Record "Purch. Rcpt. Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewPurchRcptLineInsert(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean; var NewDocLineNo: Integer; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptLineModify(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReapplyJobConsumptionFromApplyToEntryList(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchRcptLine: Record "Purch. Rcpt. Line"; ItemJnlLine: Record "Item Journal Line"; var TempApplyToEntryList: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBlanketOrder(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJournalInboundItemEntryPostingWithJob(var ItemJournalLine: Record "Item Journal Line"; ItemApplicationEntry: Record "Item Application Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterCollectItemLedgEntries(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; SourceCodeSetup: Record "Source Code Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterInsertTempWhseJnlLine(PurchRcptLine: Record "Purch. Rcpt. Line"; var ItemJnlLine: Record "Item Journal Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeUndoPosting(var ItemJournalLine: Record "Item Journal Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"; SourceCodeSetup: Record "Source Code Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeUndoValuePostingWithJob(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchRcptLine: Record "Purch. Rcpt. Line"; var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOrderLineOnBeforeUpdatePurchLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchRcptLinesAfterPurchRcptLineSetFilters(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchRcptLineOnBeforeCollectItemLedgEntries(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeLoopPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchRcptLineFields(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeMakeInventoryAdjustment(var PurchaseLine: Record "Purchase Line"; var PurchaseReceiptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemJnlLineProdOrderSubcontracting(var ItemJnlLine: Record "Item Journal Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempOutputItemLedgerEntry: Record "Item Ledger Entry" temporary; var OneLinePostingUndo: Boolean)
    begin
    end;

}

