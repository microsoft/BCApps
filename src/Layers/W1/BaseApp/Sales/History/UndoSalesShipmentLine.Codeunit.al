// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Posting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

/// <summary>
/// Reverses posted sales shipment lines by creating corrective inventory and ledger entries.
/// </summary>
codeunit 5815 "Undo Sales Shipment Line"
{
    Permissions = TableData "Sales Line" = rimd,
                  TableData "Sales Shipment Line" = rimd,
                  TableData "Item Application Entry" = rmd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Sales Shipment Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        IsHandled: Boolean;
        SkipTypeCheck: Boolean;
    begin
        IsHandled := false;
        SkipTypeCheck := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTypeCheck, UndoSalesShptLineParams."Hide Dialog");
        if IsHandled then
            exit;

        if not UndoSalesShptLineParams."Hide Dialog" then
            if not Confirm(HandleConfirmMessage(Rec)) then
                exit;

        SalesShipmentLine.Copy(Rec);
        Code();
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := SalesShipmentLine;
    end;

    var
        SalesShipmentLine: Record "Sales Shipment Line";
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        TempGlobalItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        UndoSalesShptLineParams: Record "Undo Sales Shpt. Line Params";
        UndoPostingManagement: Codeunit "Undo Posting Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseUndoQuantity: Codeunit "Whse. Undo Quantity";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        AssemblyPost: Codeunit "Assembly-Post";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        ItemsToAdjust: List of [Code[20]];
        ATOWindowDialog: Dialog;
        NextLineNo: Integer;

#pragma warning disable AA0074
        UndoShipmentLinesQst: Label 'Do you really want to undo the selected Shipment lines?';
        Text001: Label 'Undo quantity posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
        Text003: Label 'Checking lines...';
        Text005: Label 'This shipment has already been invoiced. Undo Shipment can be applied only to posted, but not invoiced shipments.';
#pragma warning disable AA0470
        Text055: Label '#1#################################\\Checking Undo Assembly #2###########.';
        Text056: Label '#1#################################\\Posting Undo Assembly #2###########.';
        Text057: Label '#1#################################\\Finalizing Undo Assembly #2###########.';
#pragma warning restore AA0470
        Text059: Label '%1 %2 %3', Comment = '%1 = SalesShipmentLine."Document No.". %2 = SalesShipmentLine.FIELDCAPTION("Line No."). %3 = SalesShipmentLine."Line No.". This is used in a progress window.';
#pragma warning restore AA0074
        AlreadyReversedErr: Label 'This shipment has already been reversed.';
        NoLinesToReverseErr: Label 'There are no lines with quantity to reverse.';
        InvoiceCancelledQst: Label 'The quantity to undo might differ from the original shipment because the invoice was cancelled. Do you want to proceed with the undo?';

    /// <summary>
    /// Sets whether the confirmation dialog should be hidden when undoing sales shipment lines.
    /// </summary>
    /// <param name="NewHideDialog">Specifies whether to hide the confirmation dialog.</param>
    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        UndoSalesShptLineParams."Hide Dialog" := NewHideDialog;
    end;

    /// <summary>
    /// Sets the parameters for the undo sales shipment line operation.
    /// </summary>
    /// <param name="NewUndoSalesShptLineParams">Specifies the parameters to use for the undo operation.</param>
    procedure SetParameters(var NewUndoSalesShptLineParams: Record "Undo Sales Shpt. Line Params")
    begin
        UndoSalesShptLineParams := NewUndoSalesShptLineParams;
    end;

    local procedure "Code"()
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        SalesLine: Record "Sales Line";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        WindowDialog: Dialog;
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        PostedWhseShptLineFound: Boolean;
        IsHandled: Boolean;
    begin
        Clear(ItemJnlPostLine);
        SalesShipmentLine.SetCurrentKey("Item Shpt. Entry No.");
        SalesShipmentLine.SetFilter(Quantity, '<>0');
        SalesShipmentLine.SetRange(Correction, false);
        OnCodeOnAfterSalesShptLineSetFilters(SalesShipmentLine, UndoSalesShptLineParams."Hide Dialog");
        if SalesShipmentLine.IsEmpty() then
            Error(NoLinesToReverseErr);
        SalesShipmentLine.FindFirst();
        repeat
            if not UndoSalesShptLineParams."Hide Dialog" then
                WindowDialog.Open(Text003);
            CheckSalesShptLine(SalesShipmentLine);
        until SalesShipmentLine.Next() = 0;

        OnAfterCheckSalesShipmentLines(SalesShipmentLine, UndoSalesShptLineParams);

        BindSubscription(this);
        SalesShipmentLine.Find('-');
        repeat
            OnCodeOnBeforeUndoLoop(SalesShipmentLine);
            TempGlobalItemLedgerEntry.Reset();
            if not TempGlobalItemLedgerEntry.IsEmpty() then
                TempGlobalItemLedgerEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty() then
                TempGlobalItemEntryRelation.DeleteAll();

            if not UndoSalesShptLineParams."Hide Dialog" then
                WindowDialog.Open(Text001);

            IsHandled := false;
            OnCodeOnBeforeProcessItemShptEntry(ItemShptEntryNo, DocLineNo, SalesShipmentLine, IsHandled);
            if not IsHandled then
                if SalesShipmentLine.Type = SalesShipmentLine.Type::Item then begin
                    PostedWhseShptLineFound :=
                    WhseUndoQuantity.FindPostedWhseShptLine(
                        PostedWhseShipmentLine, DATABASE::"Sales Shipment Line", SalesShipmentLine."Document No.",
                        DATABASE::"Sales Line", SalesLine."Document Type"::Order.AsInteger(), SalesShipmentLine."Order No.", SalesShipmentLine."Order Line No.");

                    Clear(ItemJnlPostLine);
                    ItemShptEntryNo := PostItemJnlLine(SalesShipmentLine, DocLineNo);
                end else
                    DocLineNo := GetCorrectionLineNo(SalesShipmentLine);

            InsertNewShipmentLine(SalesShipmentLine, ItemShptEntryNo, DocLineNo);
            OnAfterInsertNewShipmentLine(SalesShipmentLine, PostedWhseShipmentLine, PostedWhseShptLineFound, DocLineNo, ItemShptEntryNo);

            if PostedWhseShptLineFound then
                WhseUndoQuantity.UndoPostedWhseShptLine(PostedWhseShipmentLine);

            TempWarehouseJournalLine.SetRange("Source Line No.", SalesShipmentLine."Line No.");
            WhseUndoQuantity.PostTempWhseJnlLineCache(TempWarehouseJournalLine, WhseJnlRegisterLine);

            UndoPostATO(SalesShipmentLine, WhseJnlRegisterLine);

            UpdateOrderLine(SalesShipmentLine);
            if PostedWhseShptLineFound then
                WhseUndoQuantity.UpdateShptSourceDocLines(PostedWhseShipmentLine);

            if (SalesShipmentLine."Blanket Order No." <> '') and (SalesShipmentLine."Blanket Order Line No." <> 0) then
                UpdateBlanketOrder(SalesShipmentLine);

            OnBeforeDeleteRelatedItems(SalesShipmentLine, UndoSalesShptLineParams);

            SalesShipmentLine."Quantity Invoiced" := SalesShipmentLine.Quantity;
            SalesShipmentLine."Qty. Invoiced (Base)" := SalesShipmentLine."Quantity (Base)";
            SalesShipmentLine."Qty. Shipped Not Invoiced" := 0;
            SalesShipmentLine.Correction := true;

            OnBeforeSalesShptLineModify(SalesShipmentLine);
            SalesShipmentLine.Modify();
            OnAfterSalesShptLineModify(SalesShipmentLine, DocLineNo, UndoSalesShptLineParams."Hide Dialog");

            UndoFinalizePostATO(SalesShipmentLine);
        until SalesShipmentLine.Next() = 0;
        UnbindSubscription(this);

        MakeInventoryAdjustment();

        OnAfterCode(SalesShipmentLine);
    end;

    local procedure RemoveDropShipmentApplicationWithPurchase(SalesShptLine: Record "Sales Shipment Line"; NewSalesShptLine: Record "Sales Shipment Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchItemLedgerEntryToUndo: Integer;
    begin
        if not SalesShptLine."Drop Shipment" then
            exit;

        if ItemLedgerEntry.Get(SalesShptLine."Item Shpt. Entry No.") then begin
            PurchItemLedgerEntryToUndo := ItemLedgerEntry."Applies-to Entry";
            UnApplyDropShipment(ItemLedgerEntry, NewSalesShptLine, SalesShptLine);
        end else begin
            ApplyFilterForItemTracking(ItemLedgerEntry, SalesShptLine);

            if ItemLedgerEntry.FindSet() then
                repeat
                    if PurchItemLedgerEntryToUndo = 0 then
                        PurchItemLedgerEntryToUndo := ItemLedgerEntry."Applies-to Entry";

                    UnApplyDropShipment(ItemLedgerEntry, NewSalesShptLine, SalesShptLine);
                until ItemLedgerEntry.Next() = 0;
        end;

        UndoPurchaseReceiptLineForDropShipment(PurchItemLedgerEntryToUndo);
    end;

    local procedure ApplyFilterForItemTracking(var ItemLedgerEntry: Record "Item Ledger Entry"; SalesShptLine: Record "Sales Shipment Line")
    begin
        ItemLedgerEntry.SetLoadFields("Entry No.", "Document Type", "Document No.", "Document Line No.", "Applies-to Entry", "Drop Shipment", "Lot No.", "Serial No.");
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Document No.", SalesShptLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", SalesShptLine."Line No.");
        ItemLedgerEntry.SetRange("Drop Shipment", true);
    end;

    local procedure UnApplyDropShipment(ItemLedgerEntry: Record "Item Ledger Entry"; NewSalesShptLine: Record "Sales Shipment Line"; SalesShptLine: Record "Sales Shipment Line")
    var
        ItemApplicationEntry: Record "Item Application Entry";
        RelevantUndoShipmentLedgerEntryNo: Integer;
    begin
        RelevantUndoShipmentLedgerEntryNo := FindRelevantNewSalesShptLedgerEntryNo(SalesShptLine, NewSalesShptLine, ItemLedgerEntry);

        ItemApplicationEntry.SetBaseLoadFields();
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplicationEntry.SetRange("Cost Application", true);
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Applies-to Entry");
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplicationEntry.FindFirst();

        ItemJnlPostLine.UnApplyDropShipment(ItemApplicationEntry, RelevantUndoShipmentLedgerEntryNo);
    end;

    local procedure FindRelevantNewSalesShptLedgerEntryNo(SalesShptLine: Record "Sales Shipment Line"; NewSalesShptLine: Record "Sales Shipment Line"; ItemLedgerEntry: Record "Item Ledger Entry"): Integer
    var
        UndoReceiptLedgerEntry: Record "Item Ledger Entry";
    begin
        SalesShptLine := SalesShptLine;
        if NewSalesShptLine."Item Shpt. Entry No." <> 0 then
            exit(NewSalesShptLine."Item Shpt. Entry No.");

        UndoReceiptLedgerEntry.SetLoadFields("Entry No.", "Document Type", "Lot No.", "Serial No.", "Drop Shipment", "Applies-to Entry");
        if UndoReceiptLedgerEntry.Get(ItemLedgerEntry."Applies-to Entry") then begin
            UndoReceiptLedgerEntry.TestField("Document Type", UndoReceiptLedgerEntry."Document Type"::"Purchase Receipt");
            UndoReceiptLedgerEntry.TestField("Lot No.", ItemLedgerEntry."Lot No.");
            UndoReceiptLedgerEntry.TestField("Serial No.", ItemLedgerEntry."Serial No.");
            UndoReceiptLedgerEntry.TestField("Drop Shipment", true);

            exit(UndoReceiptLedgerEntry."Entry No.");
        end;

        exit(0);
    end;

    local procedure UndoPurchaseReceiptLineForDropShipment(ReceiptItemLedgerEntryNo: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseReceiptLine: Record "Purch. Rcpt. Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        ItemLedgerEntry.Get(ReceiptItemLedgerEntryNo);
        ItemLedgerEntry.TestField("Drop Shipment", true);

        PurchaseReceiptLine.SetRange("Document No.", ItemLedgerEntry."Document No.");
        PurchaseReceiptLine.SetRange("Line No.", ItemLedgerEntry."Document Line No.");

        if (ItemLedgerEntry."Lot No." = '') and (ItemLedgerEntry."Serial No." = '') then
            PurchaseReceiptLine.SetRange("Item Rcpt. Entry No.", ItemLedgerEntry."Entry No.");

        PurchaseReceiptLine.FindFirst();

        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchaseReceiptLine)
    end;

    local procedure CheckSalesShptLine(SalesShipmentLine2: Record "Sales Shipment Line")
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        IsHandled: Boolean;
        SkipTestFields: Boolean;
        SkipUndoPosting: Boolean;
        SkipUndoInitPostATO: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesShptLine(SalesShipmentLine2, IsHandled, SkipTestFields, SkipUndoPosting, SkipUndoInitPostATO);
        if not IsHandled then begin
            if not SkipTestFields then begin
                if SalesShipmentLine2.Correction then
                    Error(AlreadyReversedErr);

                IsHandled := false;
                OnCheckSalesShptLineOnBeforeHasInvoicedNotReturnedQuantity(SalesShipmentLine2, IsHandled);
                if not IsHandled then
                    if SalesShipmentLine2."Qty. Shipped Not Invoiced" <> SalesShipmentLine2.Quantity then
                        if HasInvoicedNotReturnedQuantity(SalesShipmentLine2) then
                            Error(Text005);
            end;
            if SalesShipmentLine2.Type = SalesShipmentLine2.Type::Item then begin
                if not SkipUndoPosting then begin
                    UndoPostingManagement.TestSalesShptLine(SalesShipmentLine2);

                    IsHandled := false;
                    OnCheckSalesShptLineOnBeforeCollectItemLedgEntries(SalesShipmentLine2, TempItemLedgerEntry, IsHandled);
                    if not IsHandled then
                        UndoPostingManagement.CollectItemLedgEntries(
                            TempItemLedgerEntry, DATABASE::"Sales Shipment Line", SalesShipmentLine2."Document No.", SalesShipmentLine2."Line No.", SalesShipmentLine2."Quantity (Base)", SalesShipmentLine2."Item Shpt. Entry No.");
                    UndoPostingManagement.CheckItemLedgEntries(TempItemLedgerEntry, SalesShipmentLine2."Line No.", SalesShipmentLine2."Qty. Shipped Not Invoiced" <> SalesShipmentLine2.Quantity);
                end;
                if not SkipUndoInitPostATO then
                    UndoInitPostATO(SalesShipmentLine2);
            end;
        end;

        OnAfterCheckSalesShptLine(SalesShipmentLine2, TempItemLedgerEntry);
    end;

    /// <summary>
    /// Gets the line number to use for the correction line when undoing a sales shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine2">Specifies the sales shipment line being undone.</param>
    /// <returns>The line number for the correction line.</returns>
    procedure GetCorrectionLineNo(SalesShipmentLine2: Record "Sales Shipment Line") Result: Integer;
    var
        SalesShipmentLine3: Record "Sales Shipment Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCorrectionLineNo(SalesShipmentLine2, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesShipmentLine3.SetRange("Document No.", SalesShipmentLine2."Document No.");
        SalesShipmentLine3."Document No." := SalesShipmentLine2."Document No.";
        SalesShipmentLine3."Line No." := SalesShipmentLine2."Line No.";
        SalesShipmentLine3.Find('=');
        if SalesShipmentLine3.Find('>') then begin
            LineSpacing := (SalesShipmentLine3."Line No." - SalesShipmentLine2."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;

        Result := SalesShipmentLine2."Line No." + LineSpacing;
        OnAfterGetCorrectionLineNo(SalesShipmentLine2, Result);
    end;

    local procedure PostItemJnlLine(SalesShipmentLine2: Record "Sales Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        TempApplyToItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemLedgerEntryNotInvoiced: Record "Item Ledger Entry";
        ItemLedgEntryNo: Integer;
        RemQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(
            SalesShipmentLine2, DocLineNo, ItemLedgEntryNo, IsHandled, TempGlobalItemLedgerEntry, TempGlobalItemEntryRelation, TempWarehouseJournalLine, NextLineNo);
        if IsHandled then
            exit(ItemLedgEntryNo);

        DocLineNo := GetCorrectionLineNo(SalesShipmentLine2);

        SourceCodeSetup.Get();
        SalesShipmentHeader.Get(SalesShipmentLine2."Document No.");

        ItemJournalLine.Init();
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Sale;
        ItemJournalLine."Item No." := SalesShipmentLine2."No.";
        ItemJournalLine."Posting Date" := SalesShipmentHeader."Posting Date";
        ItemJournalLine."Document No." := SalesShipmentLine2."Document No.";
        ItemJournalLine."Document Line No." := DocLineNo;
        ItemJournalLine."Document Type" := ItemJournalLine."Document Type"::"Sales Shipment";
        ItemJournalLine."Gen. Bus. Posting Group" := SalesShipmentLine2."Gen. Bus. Posting Group";
        ItemJournalLine."Gen. Prod. Posting Group" := SalesShipmentLine2."Gen. Prod. Posting Group";
        ItemJournalLine."Location Code" := SalesShipmentLine2."Location Code";
        ItemJournalLine."Source Code" := SourceCodeSetup.Sales;
        ItemJournalLine.Correction := true;
        ItemJournalLine."Variant Code" := SalesShipmentLine2."Variant Code";
        ItemJournalLine."Bin Code" := SalesShipmentLine2."Bin Code";
        ItemJournalLine."Document Date" := SalesShipmentHeader."Document Date";
        ItemJournalLine."Unit of Measure Code" := SalesShipmentLine2."Unit of Measure Code";

        OnAfterCopyItemJnlLineFromSalesShpt(ItemJournalLine, SalesShipmentHeader, SalesShipmentLine2, TempWarehouseJournalLine, WhseUndoQuantity, ItemLedgEntryNo, NextLineNo, TempGlobalItemLedgerEntry, TempGlobalItemEntryRelation, IsHandled);
        if IsHandled then
            exit(ItemLedgEntryNo);

        UndoPostingManagement.CollectItemLedgEntries(
            TempApplyToItemLedgerEntry, DATABASE::"Sales Shipment Line", SalesShipmentLine2."Document No.", SalesShipmentLine2."Line No.", SalesShipmentLine2."Quantity (Base)", SalesShipmentLine2."Item Shpt. Entry No.");

        if (SalesShipmentLine2."Qty. Shipped Not Invoiced" = SalesShipmentLine2.Quantity) or
           not UndoPostingManagement.AreAllItemEntriesCompletelyInvoiced(TempApplyToItemLedgerEntry)
        then
            WhseUndoQuantity.InsertTempWhseJnlLine(
                ItemJournalLine,
                DATABASE::"Sales Line", SalesLine."Document Type"::Order.AsInteger(), SalesShipmentLine2."Order No.", SalesShipmentLine2."Order Line No.",
                TempWarehouseJournalLine."Reference Document"::"Posted Shipment".AsInteger(), TempWarehouseJournalLine, NextLineNo);
        OnPostItemJnlLineOnAfterInsertTempWhseJnlLine(SalesShipmentLine2, ItemJournalLine, TempWarehouseJournalLine, NextLineNo);

        if GetInvoicedShptEntries(SalesShipmentLine2, ItemLedgerEntryNotInvoiced) then begin
            RemQtyBase := -(SalesShipmentLine2."Quantity (Base)" - SalesShipmentLine2."Qty. Invoiced (Base)");
            OnPostItemJnlLineOnAfterCalcRemQtyBase(RemQtyBase, ItemJournalLine, SalesShipmentLine2, ItemLedgerEntryNotInvoiced);
            repeat
                ItemJournalLine."Applies-to Entry" := ItemLedgerEntryNotInvoiced."Entry No.";
                ItemJournalLine.Quantity := ItemLedgerEntryNotInvoiced.Quantity;
                ItemJournalLine."Quantity (Base)" := ItemLedgerEntryNotInvoiced.Quantity;
                IsHandled := false;
                OnPostItemJnlLineOnBeforeRunItemJnlPostLine(ItemJournalLine, ItemLedgerEntryNotInvoiced, SalesShipmentLine2, SalesShipmentHeader, IsHandled);
                if not IsHandled then
                    ItemJnlPostLine.Run(ItemJournalLine);
                OnPostItemJnlLineOnAfterRunItemJnlPostLine(ItemJournalLine, SalesShipmentLine2, SalesShipmentHeader, ItemJnlPostLine);
                RemQtyBase -= ItemJournalLine.Quantity;
                if ItemLedgerEntryNotInvoiced.Next() = 0 then;
            until (RemQtyBase = 0);
            OnItemJnlPostLineOnAfterGetInvoicedShptEntriesOnBeforeExit(ItemJournalLine, SalesShipmentLine2);
            exit(ItemJournalLine."Item Shpt. Entry No.");
        end;

        UndoPostingManagement.PostItemJnlLineAppliedToList(
            ItemJournalLine, TempApplyToItemLedgerEntry, SalesShipmentLine2.Quantity - SalesShipmentLine2."Quantity Invoiced", SalesShipmentLine2."Quantity (Base)" - SalesShipmentLine2."Qty. Invoiced (Base)", TempGlobalItemLedgerEntry, TempGlobalItemEntryRelation, SalesShipmentLine2."Qty. Shipped Not Invoiced" <> SalesShipmentLine2.Quantity);

        OnAfterPostItemJnlLine(ItemJournalLine, SalesShipmentLine2);
        exit(0); // "Item Shpt. Entry No."
    end;

    local procedure InsertNewShipmentLine(OldSalesShipmentLine: Record "Sales Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewSalesShipmentLine: Record "Sales Shipment Line";
    begin
        NewSalesShipmentLine.Init();
        NewSalesShipmentLine.Copy(OldSalesShipmentLine);
        NewSalesShipmentLine."Line No." := DocLineNo;
        NewSalesShipmentLine."Appl.-from Item Entry" := OldSalesShipmentLine."Item Shpt. Entry No.";
        NewSalesShipmentLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewSalesShipmentLine.Quantity := -OldSalesShipmentLine.Quantity;
        NewSalesShipmentLine."Qty. Shipped Not Invoiced" := 0;
        NewSalesShipmentLine."Quantity (Base)" := -OldSalesShipmentLine."Quantity (Base)";
        NewSalesShipmentLine."Quantity Invoiced" := NewSalesShipmentLine.Quantity;
        NewSalesShipmentLine."Qty. Invoiced (Base)" := NewSalesShipmentLine."Quantity (Base)";
        NewSalesShipmentLine.Correction := true;
        NewSalesShipmentLine."Dimension Set ID" := OldSalesShipmentLine."Dimension Set ID";
        OnBeforeNewSalesShptLineInsert(NewSalesShipmentLine, OldSalesShipmentLine);
        NewSalesShipmentLine.Insert();
        OnAfterNewSalesShptLineInsert(NewSalesShipmentLine, OldSalesShipmentLine);

        RemoveDropShipmentApplicationWithPurchase(OldSalesShipmentLine, NewSalesShipmentLine);
        InsertItemEntryRelation(TempGlobalItemEntryRelation, NewSalesShipmentLine);
    end;

    /// <summary>
    /// Updates the related sales order line after undoing a sales shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine2">Specifies the sales shipment line that was undone.</param>
    procedure UpdateOrderLine(SalesShipmentLine2: Record "Sales Shipment Line")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderLine(SalesShipmentLine2, IsHandled, TempGlobalItemLedgerEntry);
        if IsHandled then
            exit;

        SalesLine.Get(SalesLine."Document Type"::Order, SalesShipmentLine2."Order No.", SalesShipmentLine2."Order Line No.");
        OnUpdateOrderLineOnBeforeUpdateSalesLine(SalesShipmentLine2, SalesLine);
        UndoPostingManagement.UpdateSalesLine(
            SalesLine, SalesShipmentLine2.Quantity - SalesShipmentLine2."Quantity Invoiced",
            SalesShipmentLine2."Quantity (Base)" - SalesShipmentLine2."Qty. Invoiced (Base)", TempGlobalItemLedgerEntry);
        OnAfterUpdateSalesLine(SalesLine, SalesShipmentLine2);
    end;

    /// <summary>
    /// Updates the related blanket sales order line after undoing a sales shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine2">Specifies the sales shipment line that was undone.</param>
    procedure UpdateBlanketOrder(SalesShipmentLine2: Record "Sales Shipment Line")
    var
        BlanketOrderSalesLine: Record "Sales Line";
        xBlanketOrderSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBlanketOrder(SalesShipmentLine2, IsHandled);
        if IsHandled then
            exit;

        if BlanketOrderSalesLine.Get(
                 BlanketOrderSalesLine."Document Type"::"Blanket Order", SalesShipmentLine2."Blanket Order No.", SalesShipmentLine2."Blanket Order Line No.")
        then begin
            BlanketOrderSalesLine.TestField(Type, SalesShipmentLine2.Type);
            BlanketOrderSalesLine.TestField("No.", SalesShipmentLine2."No.");
            BlanketOrderSalesLine.TestField("Sell-to Customer No.", SalesShipmentLine2."Sell-to Customer No.");
            xBlanketOrderSalesLine := BlanketOrderSalesLine;

            if BlanketOrderSalesLine."Qty. per Unit of Measure" = SalesShipmentLine2."Qty. per Unit of Measure" then
                BlanketOrderSalesLine."Quantity Shipped" := BlanketOrderSalesLine."Quantity Shipped" - SalesShipmentLine2.Quantity
            else
                BlanketOrderSalesLine."Quantity Shipped" :=
                  BlanketOrderSalesLine."Quantity Shipped" -
                  Round(
                    SalesShipmentLine2."Qty. per Unit of Measure" / BlanketOrderSalesLine."Qty. per Unit of Measure" * SalesShipmentLine2.Quantity,
                    UnitOfMeasureManagement.QtyRndPrecision());

            BlanketOrderSalesLine."Qty. Shipped (Base)" := BlanketOrderSalesLine."Qty. Shipped (Base)" - SalesShipmentLine2."Quantity (Base)";
            OnBeforeBlanketOrderInitOutstanding(BlanketOrderSalesLine, SalesShipmentLine2);
            BlanketOrderSalesLine.InitOutstanding();
            BlanketOrderSalesLine.Modify();

            AssemblyPost.UpdateBlanketATO(xBlanketOrderSalesLine, BlanketOrderSalesLine);
        end;
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewSalesShipmentLine: Record "Sales Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsSalesShptLine(NewSalesShipmentLine);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure UndoInitPostATO(var SalesShipmentLine2: Record "Sales Shipment Line")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        if SalesShipmentLine2.AsmToShipmentExists(PostedAssemblyHeader) then begin
            OpenATOProgressWindow(Text055, SalesShipmentLine2, PostedAssemblyHeader);
            AssemblyPost.UndoInitPostATO(PostedAssemblyHeader);
            ATOWindowDialog.Close();
        end;
    end;

    local procedure UndoPostATO(var SalesShipmentLine2: Record "Sales Shipment Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        if SalesShipmentLine2.AsmToShipmentExists(PostedAssemblyHeader) then begin
            OpenATOProgressWindow(Text056, SalesShipmentLine2, PostedAssemblyHeader);
            AssemblyPost.UndoPostATO(PostedAssemblyHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
            ATOWindowDialog.Close();
        end;
    end;

    local procedure UndoFinalizePostATO(var SalesShipmentLine2: Record "Sales Shipment Line")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        if SalesShipmentLine2.AsmToShipmentExists(PostedAssemblyHeader) then begin
            OpenATOProgressWindow(Text057, SalesShipmentLine2, PostedAssemblyHeader);
            AssemblyPost.UndoFinalizePostATO(PostedAssemblyHeader);
            SynchronizeATO(SalesShipmentLine2);
            ATOWindowDialog.Close();
        end;
    end;

    local procedure SynchronizeATO(var SalesShipmentLine2: Record "Sales Shipment Line")
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        SalesLine.Get(Enum::"Sales Document Type"::Order, SalesShipmentLine2."Order No.", SalesShipmentLine2."Order Line No.");

        if SalesLine.AsmToOrderExists(AssemblyHeader) and (AssemblyHeader.Status = AssemblyHeader.Status::Released) then begin
            AssemblyHeader.Status := AssemblyHeader.Status::Open;
            AssemblyHeader.Modify();
            SalesLine.AutoAsmToOrder();
            AssemblyHeader.Status := AssemblyHeader.Status::Released;
            AssemblyHeader.Modify();
        end else
            SalesLine.AutoAsmToOrder();

        OnSynchronizeATOOnBeforeModify(SalesLine);
        SalesLine.Modify(true);
    end;

    local procedure OpenATOProgressWindow(State: Text[250]; SalesShipmentLine2: Record "Sales Shipment Line"; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
        ATOWindowDialog.Open(State);
        ATOWindowDialog.Update(1,
          StrSubstNo(Text059,
            SalesShipmentLine2."Document No.", SalesShipmentLine2.FieldCaption("Line No."), SalesShipmentLine2."Line No."));
        ATOWindowDialog.Update(2, PostedAssemblyHeader."No.");
    end;

    /// <summary>
    /// Gets the item ledger entries for shipments that have been invoiced but not completely invoiced.
    /// </summary>
    /// <param name="SalesShipmentLine2">Specifies the sales shipment line to search for.</param>
    /// <param name="ItemLedgerEntry">Returns the item ledger entries found.</param>
    /// <returns>True if any item ledger entries were found, otherwise false.</returns>
    procedure GetInvoicedShptEntries(SalesShipmentLine2: Record "Sales Shipment Line"; var ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    begin
        ItemLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Document No.", SalesShipmentLine2."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", SalesShipmentLine2."Line No.");
        ItemLedgerEntry.SetTrackingFilterBlank();
        ItemLedgerEntry.SetRange("Completely Invoiced", false);
        OnGetInvoicedShptEntriesOnAfterSetFilters(ItemLedgerEntry, SalesShipmentLine);
        exit(ItemLedgerEntry.FindSet());
    end;

    local procedure HasInvoicedNotReturnedQuantity(SalesShipmentLine2: Record "Sales Shipment Line"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnedInvoicedItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        InvoicedQuantity: Decimal;
        ReturnedInvoicedQuantity: Decimal;
    begin
        if SalesShipmentLine2.Type = SalesShipmentLine2.Type::Item then begin
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
            ItemLedgerEntry.SetRange("Document No.", SalesShipmentLine2."Document No.");
            ItemLedgerEntry.SetRange("Document Line No.", SalesShipmentLine2."Line No.");
            ItemLedgerEntry.FindSet();
            repeat
                InvoicedQuantity += ItemLedgerEntry."Invoiced Quantity";
                if ItemApplicationEntry.AppliedInbndEntryExists(ItemLedgerEntry."Entry No.", false) then
                    repeat
                        if ItemApplicationEntry."Item Ledger Entry No." = ItemApplicationEntry."Inbound Item Entry No." then begin
                            ReturnedInvoicedItemLedgerEntry.Get(ItemApplicationEntry."Item Ledger Entry No.");
                            if IsCancelled(ReturnedInvoicedItemLedgerEntry) then
                                ReturnedInvoicedQuantity += ReturnedInvoicedItemLedgerEntry."Invoiced Quantity";
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until ItemLedgerEntry.Next() = 0;
            exit(InvoicedQuantity + ReturnedInvoicedQuantity <> 0);
        end else begin
            SalesInvoiceLine.SetRange("Order No.", SalesShipmentLine2."Order No.");
            SalesInvoiceLine.SetRange("Order Line No.", SalesShipmentLine2."Order Line No.");
            if SalesInvoiceLine.FindSet() then
                repeat
                    SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
                    if not IsSalesInvoiceCancelled(SalesInvoiceHeader) then
                        exit(true);
                until SalesInvoiceLine.Next() = 0;

            exit(false);
        end;
    end;

    local procedure IsCancelled(ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        CancelledDocument: Record "Cancelled Document";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                begin
                    ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.");
                    if ReturnReceiptHeader."Applies-to Doc. Type" = ReturnReceiptHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Sales Invoice Header", ReturnReceiptHeader."Applies-to Doc. No."));
                end;
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                begin
                    SalesCrMemoHeader.Get(ItemLedgerEntry."Document No.");
                    if SalesCrMemoHeader."Applies-to Doc. Type" = SalesCrMemoHeader."Applies-to Doc. Type"::Invoice then
                        exit(CancelledDocument.Get(Database::"Sales Invoice Header", SalesCrMemoHeader."Applies-to Doc. No."));
                end;
        end;

        exit(false);
    end;

    local procedure IsSalesInvoiceCancelled(var SalesInvoiceHeader: Record "Sales Invoice Header") Result: Boolean
    begin
        SalesInvoiceHeader.CalcFields(Cancelled);
        Result := SalesInvoiceHeader.Cancelled;

        OnAfterIsSalesInvoiceCancelled(SalesInvoiceHeader, Result);
    end;

    local procedure MakeInventoryAdjustment()
    var
        InventoryAdjustmentHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InventoryAdjustmentHandler.SetJobUpdateProperties(true);
        InventoryAdjustmentHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust);
    end;

    local procedure IsCancelledSalesInvoice(OrderNo: Code[20]): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.SetRange(Cancelled, true);
        exit(not SalesInvoiceHeader.IsEmpty());
    end;

    local procedure HandleConfirmMessage(SalesShipmentLine2: Record "Sales Shipment Line"): Text
    begin
        if IsCancelledSalesInvoice(SalesShipmentLine2."Order No.") then
            exit(InvoiceCancelledQst);

        exit(UndoShipmentLinesQst);
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

    /// <summary>
    /// Raised after the undo sales shipment line process is completed.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line that was undone.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised after copying the item journal line from the sales shipment during the undo process.
    /// </summary>
    /// <param name="ItemJournalLine">The item journal line being created.</param>
    /// <param name="SalesShipmentHeader">The sales shipment header.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="TempWhseJnlLine">Temporary warehouse journal line.</param>
    /// <param name="WhseUndoQty">The warehouse undo quantity codeunit.</param>
    /// <param name="ItemLedgEntryNo">The item ledger entry number.</param>
    /// <param name="NextLineNo">The next line number.</param>
    /// <param name="TempGlobalItemLedgerEntry">Temporary item ledger entry.</param>
    /// <param name="TempGlobalItemEntryRelation">Temporary item entry relation.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesShpt(var ItemJournalLine: Record "Item Journal Line"; SalesShipmentHeader: Record "Sales Shipment Header"; SalesShipmentLine: Record "Sales Shipment Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var WhseUndoQty: Codeunit "Whse. Undo Quantity"; var ItemLedgEntryNo: Integer; var NextLineNo: Integer; var TempGlobalItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after validating that the sales shipment line can be undone.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line being validated.</param>
    /// <param name="TempItemLedgEntry">Temporary item ledger entries associated with the line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesShptLine(var SalesShptLine: Record "Sales Shipment Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    /// <summary>
    /// Raised after inserting a new correction sales shipment line during the undo process.
    /// </summary>
    /// <param name="NewSalesShipmentLine">The newly created correction shipment line.</param>
    /// <param name="OldSalesShipmentLine">The original shipment line being undone.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterNewSalesShptLineInsert(var NewSalesShipmentLine: Record "Sales Shipment Line"; OldSalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised after modifying the original sales shipment line during the undo process.
    /// </summary>
    /// <param name="SalesShptLine">The modified sales shipment line.</param>
    /// <param name="DocLineNo">The document line number of the correction line.</param>
    /// <param name="HideDialog">Indicates whether dialog messages are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesShptLineModify(var SalesShptLine: Record "Sales Shipment Line"; DocLineNo: Integer; HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after calculating the correction line number for the undo shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="Result">The calculated correction line number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCorrectionLineNo(SalesShipmentLine: Record "Sales Shipment Line"; var Result: Integer)
    begin
    end;

    /// <summary>
    /// Raised after updating the related sales order line during the undo shipment process.
    /// </summary>
    /// <param name="SalesLine">The updated sales order line.</param>
    /// <param name="SalesShptLine">The sales shipment line being undone.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var SalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised before initializing outstanding quantities on the blanket order line during undo.
    /// </summary>
    /// <param name="BlanketOrderSalesLine">The blanket order line being updated.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderInitOutstanding(var BlanketOrderSalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised before calculating the correction line number for the undo shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="Result">The correction line number to use.</param>
    /// <param name="IsHandled">Set to true to skip default line number calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCorrectionLineNo(SalesShipmentLine: Record "Sales Shipment Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before validating that the sales shipment line can be undone.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line to validate.</param>
    /// <param name="IsHandled">Set to true to skip default validation.</param>
    /// <param name="SkipTestFields">Set to true to skip field validations.</param>
    /// <param name="SkipUndoPosting">Set to true to skip undo posting validations.</param>
    /// <param name="SkipUndoInitPostATO">Set to true to skip assemble-to-order initialization.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesShptLine(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var SkipTestFields: Boolean; var SkipUndoPosting: Boolean; var SkipUndoInitPostATO: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after inserting a new correction shipment line during the undo process.
    /// </summary>
    /// <param name="SalesShipmentLine">The original sales shipment line.</param>
    /// <param name="PostedWhseShipmentLine">The posted warehouse shipment line if applicable.</param>
    /// <param name="PostedWhseShptLineFound">Indicates whether a posted warehouse shipment line was found.</param>
    /// <param name="DocLineNo">The correction document line number.</param>
    /// <param name="ItemShptEntryNo">The item shipment entry number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNewShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var PostedWhseShptLineFound: Boolean; DocLineNo: Integer; ItemShptEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised before the undo sales shipment line process begins.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line to undo.</param>
    /// <param name="IsHandled">Set to true to skip default undo processing.</param>
    /// <param name="SkipTypeCheck">Set to true to skip line type validation.</param>
    /// <param name="HideDialog">Indicates whether dialog messages should be hidden.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean; var HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a new correction sales shipment line during the undo process.
    /// </summary>
    /// <param name="NewSalesShipmentLine">The correction shipment line to be inserted.</param>
    /// <param name="OldSalesShipmentLine">The original shipment line being undone.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewSalesShptLineInsert(var NewSalesShipmentLine: Record "Sales Shipment Line"; OldSalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised before posting the item journal line during the undo shipment process.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="DocLineNo">The document line number for the correction.</param>
    /// <param name="ItemLedgEntryNo">The item ledger entry number.</param>
    /// <param name="IsHandled">Set to true to skip default item journal posting.</param>
    /// <param name="TempGlobalItemLedgEntry">Temporary item ledger entry.</param>
    /// <param name="TempGlobalItemEntryRelation">Temporary item entry relation.</param>
    /// <param name="TempWhseJnlLine">Temporary warehouse journal line.</param>
    /// <param name="NextLineNo">The next line number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var SalesShipmentLine: Record "Sales Shipment Line"; var DocLineNo: Integer; var ItemLedgEntryNo: Integer; var IsHandled: Boolean; var TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary; var TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised before modifying the original sales shipment line during the undo process.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptLineModify(var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised before updating the blanket order line during the undo shipment process.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line being undone.</param>
    /// <param name="IsHandled">Set to true to skip default blanket order update.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBlanketOrder(var SalesShptLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating the sales order line during the undo shipment process.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line being undone.</param>
    /// <param name="IsHandled">Set to true to skip default order line update.</param>
    /// <param name="TempGlobalItemLedgEntry">Temporary item ledger entries.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderLine(var SalesShptLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    /// <summary>
    /// Raised before starting the undo loop for each sales shipment line.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line about to be processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeUndoLoop(var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised after setting filters on the sales shipment lines to process.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line with applied filters.</param>
    /// <param name="HideDialog">Indicates whether dialog messages should be hidden.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterSalesShptLineSetFilters(var SalesShptLine: Record "Sales Shipment Line"; HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after inserting a temporary warehouse journal line during item journal posting.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line being undone.</param>
    /// <param name="ItemJnlLine">The item journal line being posted.</param>
    /// <param name="TempWhseJnlLine">Temporary warehouse journal line.</param>
    /// <param name="NextLineNo">The next line number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterInsertTempWhseJnlLine(SalesShptLine: Record "Sales Shipment Line"; var ItemJnlLine: Record "Item Journal Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised after running the item journal post line during the undo shipment process.
    /// </summary>
    /// <param name="ItemJnlLine">The posted item journal line.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="SalesShipmentHeader">The sales shipment header.</param>
    /// <param name="ItemJnlPostLine">The item journal post line codeunit.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterRunItemJnlPostLine(var ItemJnlLine: Record "Item Journal Line"; var SalesShipmentLine: Record "Sales Shipment Line"; var SalesShipmentHeader: Record "Sales Shipment Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Raised before running the item journal post line during the undo shipment process.
    /// </summary>
    /// <param name="ItemJnlLine">The item journal line to be posted.</param>
    /// <param name="ItemLedgEntryNotInvoiced">The item ledger entry not invoiced.</param>
    /// <param name="SalesShptLine">The sales shipment line being undone.</param>
    /// <param name="SalesShptHeader">The sales shipment header.</param>
    /// <param name="IsHandled">Set to true to skip default posting.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeRunItemJnlPostLine(var ItemJnlLine: Record "Item Journal Line"; ItemLedgEntryNotInvoiced: Record "Item Ledger Entry"; SalesShptLine: Record "Sales Shipment Line"; SalesShptHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating the sales order line quantities during the undo process.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="SalesLine">The sales order line to be updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateOrderLineOnBeforeUpdateSalesLine(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after determining whether the related sales invoice was cancelled.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header being checked.</param>
    /// <param name="Result">The result indicating whether the invoice was cancelled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsSalesInvoiceCancelled(var SalesInvoiceHeader: Record "Sales Invoice Header"; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before collecting item ledger entries during shipment line validation.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line being validated.</param>
    /// <param name="TempItemLedgEntry">Temporary item ledger entries to collect.</param>
    /// <param name="IsHandled">Set to true to skip default collection.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesShptLineOnBeforeCollectItemLedgEntries(SalesShptLine: Record "Sales Shipment Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking whether the line has invoiced but not returned quantity.
    /// </summary>
    /// <param name="SalesShptLine">The sales shipment line being checked.</param>
    /// <param name="IsHandled">Set to true to skip default quantity check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesShptLineOnBeforeHasInvoicedNotReturnedQuantity(SalesShptLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before modifying the sales line during assemble-to-order synchronization.
    /// </summary>
    /// <param name="SalesLine">The sales line to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeATOOnBeforeModify(var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after posting the item journal line during the undo shipment process.
    /// </summary>
    /// <param name="ItemJournalLine">The posted item journal line.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised after processing invoiced shipment entries before exiting the posting routine.
    /// </summary>
    /// <param name="ItemJournalLine">The item journal line being processed.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostLineOnAfterGetInvoicedShptEntriesOnBeforeExit(var ItemJournalLine: Record "Item Journal Line"; var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised after calculating the remaining base quantity during item journal posting.
    /// </summary>
    /// <param name="RemQtyBase">The calculated remaining base quantity.</param>
    /// <param name="ItemJournalLine">The item journal line being processed.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="ItemLedgerEntryNotInvoiced">The item ledger entry not invoiced.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterCalcRemQtyBase(var RemQtyBase: Decimal; var ItemJournalLine: Record "Item Journal Line"; var SalesShipmentLine: Record "Sales Shipment Line"; var ItemLedgerEntryNotInvoiced: Record "Item Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after setting filters to retrieve invoiced shipment entries.
    /// </summary>
    /// <param name="ItemLedgerEntry">The item ledger entry with applied filters.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetInvoicedShptEntriesOnAfterSetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised before processing item shipment entries during the undo process.
    /// </summary>
    /// <param name="ItemShptEntryNo">The item shipment entry number.</param>
    /// <param name="DocLineNo">The document line number.</param>
    /// <param name="SalesShipmentLine">The sales shipment line being processed.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeProcessItemShptEntry(var ItemShptEntryNo: Integer; var DocLineNo: Integer; var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after validating all sales shipment lines before starting the undo process.
    /// </summary>
    /// <param name="SalesShipmentLine">The validated sales shipment lines.</param>
    /// <param name="UndoSalesShptLineParams">The undo parameters being used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesShipmentLines(var SalesShipmentLine: Record "Sales Shipment Line"; var UndoSalesShptLineParams: Record "Undo Sales Shpt. Line Params")
    begin
    end;

    /// <summary>
    /// Raised before deleting related items during the undo shipment process.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line being undone.</param>
    /// <param name="UndoSalesShptLineParams">The undo parameters being used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelatedItems(var SalesShipmentLine: Record "Sales Shipment Line"; UndoSalesShptLineParams: Record "Undo Sales Shpt. Line Params")
    begin
    end;
}
