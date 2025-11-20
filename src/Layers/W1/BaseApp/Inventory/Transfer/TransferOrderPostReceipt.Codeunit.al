// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using System.Utilities;

codeunit 5705 "TransferOrder-Post Receipt"
{
    Permissions =
                tabledata "G/L Entry" = r,
                tabledata "Item Entry Relation" = i,
                tabledata "Transfer Receipt Header" = ri,
                tabledata "Transfer Receipt Line" = rim;
    TableNo = "Transfer Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, HideValidationDialog, SuppressCommit, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        RunWithCheck(Rec);
    end;

    internal procedure RunWithCheck(var TransferHeader2: Record "Transfer Header")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SourceCodeSetup: Record "Source Code Setup";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        ItemReg: Record "Item Register";
        InvtCommentLine: Record "Inventory Comment Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        ReservMgt: Codeunit "Reservation Management";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
        DeleteOne: Boolean;
        IsHandled: Boolean;
    begin
        ReleaseDocument(TransferHeader2);
        TransHeader := TransferHeader2;
        TransHeader.SetHideValidationDialog(HideValidationDialog);

        OnBeforeTransferOrderPostReceipt(TransHeader, SuppressCommit, PreviewMode, ItemJnlPostLine);

        TransHeader.CheckBeforePost();

        SaveAndClearPostingFromWhseRef();

        CheckDim();
        CheckLines(TransHeader, TransLine);

        WhseReceive := TempWhseRcptHeader.FindFirst();
        InvtPickPutaway := WhseReference <> 0;
        if not (WhseReceive or InvtPickPutaway) then
            CheckWarehouse(TransLine);

        WhsePosting := IsWarehousePosting(TransHeader."Transfer-to Code");

        TransHeader.CheckTransferLines(false);

        if GuiAllowed then begin
            Window.Open(
              '#1#################################\\' +
              Text003);

            Window.Update(1, StrSubstNo(Text004, TransHeader."No."));
        end;

        SourceCodeSetup.Get();
        SourceCode := SourceCodeSetup.Transfer;
        InvtSetup.Get();
        InvtSetup.TestField("Posted Transfer Rcpt. Nos.");

        TransHeader.CheckInvtPostingSetup();
        OnAfterCheckInvtPostingSetup(TransHeader, TempWhseRcptHeader, SourceCode);

        LockTables(InvtSetup.UseLegacyPosting() and InvtSetup."Automatic Cost Posting");
        // Insert receipt header
        if WhseReceive then
            PostedWhseRcptHeader.LockTable();
        TransRcptHeader.LockTable();
        InsertTransRcptHeader(TransRcptHeader, TransHeader, InvtSetup."Posted Transfer Rcpt. Nos.");

        if InvtSetup."Copy Comments Order to Rcpt." then begin
            InvtCommentLine.CopyCommentLines(
                "Inventory Comment Document Type"::"Transfer Order", TransHeader."No.",
                "Inventory Comment Document Type"::"Posted Transfer Receipt", TransRcptHeader."No.");
            RecordLinkManagement.CopyLinks(TransferHeader2, TransRcptHeader);
        end;

        if WhseReceive then begin
            WhseRcptHeader.Get(TempWhseRcptHeader."No.");
            WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, TransRcptHeader."No.", TransHeader."Posting Date");
        end;
        // Insert receipt lines
        LineCount := 0;
        if WhseReceive then
            PostedWhseRcptLine.LockTable();
        if InvtPickPutaway then
            WhseRqst.LockTable();
        TransRcptLine.LockTable();
        TransLine.SetRange(Quantity);
        TransLine.SetRange("Qty. to Receive");
        OnRunOnAfterTransLineSetFiltersForRcptLines(TransLine, TransHeader, Location, WhseReceive);

        Clear(PostponedValueEntries);
        BindSubscription(this); // Start collecting value entries for GLPosting
        if not InvtSetup.UseLegacyPosting() then
            TransLine.SetCurrentKey("Document No.", "Item No.", "Transfer-from Code", "Transfer-from Bin Code", "Line No.");
        if TransLine.FindSet() then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed then
                    Window.Update(2, LineCount);

                if (TransLine."Item No." <> '') and (TransLine."Qty. to Receive" <> 0) then begin
                    Item.Get(TransLine."Item No.");
                    IsHandled := false;
                    OnRunOnBeforeCheckItemBlocked(TransLine, Item, TransHeader, Location, WhseReceive, IsHandled);
                    if not IsHandled then
                        Item.TestField(Blocked, false);

                    if TransLine."Variant Code" <> '' then begin
                        ItemVariant.Get(TransLine."Item No.", TransLine."Variant Code");
                        CheckItemVariantNotBlocked(ItemVariant);
                    end;
                end;

                OnCheckTransLine(TransLine, TransHeader, Location, WhseReceive);

                InsertTransRcptLine(TransRcptHeader, TransRcptLine, TransLine);
                OnAfterInsertTransRcptLineOnBeforePostDeferredValue(TransLine, TransHeader, TransRcptHeader, TransRcptLine, ItemJnlPostLine);
            until TransLine.Next() = 0;
        TransLine.SetCurrentKey("Document No.", "Line No.");
        UnBindSubscription(this); // Stop collecting value entries for GLPosting
        ItemJnlPostLine.PostDeferredValueEntriesToGL(PostponedValueEntries);

        OnRunOnAfterInsertTransRcptLines(TransRcptHeader, TransLine, TransHeader, Location, WhseReceive);

        MakeInventoryAdjustment();

        if InvtSetup.UseLegacyPosting() then begin
            ValueEntry.LockTable();
            ItemLedgEntry.LockTable();
            ItemApplnEntry.LockTable();
            ItemReg.LockTable();
            if WhsePosting then
                WhseEntry.LockTable();
        end;
        TransLine.LockTable();
        TransLine.SetFilter(Quantity, '<>0');
        TransLine.SetFilter("Qty. to Receive", '<>0');
        if TransLine.Find('-') then
            repeat
                TransLine.Validate("Quantity Received", TransLine."Quantity Received" + TransLine."Qty. to Receive");
                OnRunOnBeforeUpdateWithWarehouseShipReceive(TransLine);
                TransLine.UpdateWithWarehouseShipReceive();
                ReservMgt.SetReservSource(ItemJnlLine);
                ReservMgt.SetItemTrackingHandling(1);
                // Allow deletion
                ReservMgt.DeleteReservEntries(true, 0);
                TransLine.Modify();
                OnAfterTransLineUpdateQtyReceived(TransLine, SuppressCommit, PreviewMode);
            until TransLine.Next() = 0;

        OnRunOnBeforePostUpdateDocumens(ItemJnlPostLine);

        if WhseReceive then
            WhseRcptLine.LockTable();
        TransHeader.LockTable();
        if WhseReceive then begin
            WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
            TempWhseRcptHeader.Delete();
        end;

        TransHeader."Last Receipt No." := TransRcptHeader."No.";
        OnRunWithCheckOnBeforeModifyTransferHeader(TransHeader);
        TransHeader.Modify();

        TransLine.SetRange(Quantity);
        TransLine.SetRange("Qty. to Receive");
        if not PreviewMode then
            DeleteOne := TransHeader.ShouldDeleteOneTransferOrder(TransLine);
        OnBeforeDeleteOneTransferHeader(TransHeader, DeleteOne, TransRcptHeader);
        if DeleteOne then
            TransHeader.DeleteOneTransferOrder(TransHeader, TransLine)
        else begin
            WhseTransferRelease.Release(TransHeader);
            ReserveTransLine.UpdateItemTrackingAfterPosting(TransHeader, Enum::"Transfer Direction"::Inbound);
        end;

        OnRunOnBeforeCommit(TransHeader, TransRcptHeader, PostedWhseRcptHeader, SuppressCommit, PreviewMode);
        if not (InvtPickPutaway or SuppressCommit or PreviewMode) then begin
            Commit();
            UpdateAnalysisView.UpdateAll(0, true);
            UpdateItemAnalysisView.UpdateAll(0, true);
        end;
        Clear(WhsePostRcpt);
        if GuiAllowed() then
            Window.Close();

        TransferHeader2 := TransHeader;

        OnAfterTransferOrderPostReceipt(TransferHeader2, SuppressCommit, PreviewMode, TransRcptHeader);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Warehouse handling is required for Transfer order = %1, %2 = %3.', Comment = '1%=TransLine2."Document No."; 2%=TransLine2.FIELDCAPTION("Line No."); 3%=TransLine2."Line No.");';
        Text003: Label 'Posting transfer lines     #2######';
        Text004: Label 'Transfer Order %1';
        Text005: Label 'The combination of dimensions used in transfer order %1 is blocked. %2.';
        Text006: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3.';
        Text007: Label 'The dimensions that are used in transfer order %1, line no. %2 are not valid. %3.';
#pragma warning restore AA0470
        Text008: Label 'Base Qty. to Receive must be 0.';
#pragma warning restore AA0074
        InvtSetup: Record "Inventory Setup";
        TransRcptHeader: Record "Transfer Receipt Header";
        TransRcptLine: Record "Transfer Receipt Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        NewLocation: Record Location;
        WhseRqst: Record "Warehouse Request";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary;
        WhseRcptLine: Record "Warehouse Receipt Line";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        WhseEntry: Record "Warehouse Entry";
        TempItemEntryRelation2: Record "Item Entry Relation" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        WhsePostRcpt: Codeunit "Whse.-Post Receipt";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        PostponedValueEntries: List of [Integer];
        ItemsToAdjust: List of [Code[20]];
        SourceCode: Code[10];
        WhsePosting: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        WhseReceive: Boolean;
        InvtPickPutaway: Boolean;
        SuppressCommit: Boolean;
        CalledBy: Integer;
        HideValidationDialog: Boolean;
        PreviewMode: Boolean;

    local procedure PostItemJnlLine(var TransLine3: Record "Transfer Line"; TransRcptHeader2: Record "Transfer Receipt Header"; TransRcptLine2: Record "Transfer Receipt Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforePostItemJnlLine(TransRcptHeader2, IsHandled, TransRcptLine2);
        if IsHandled then
            exit;

        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := TransRcptHeader2."Posting Date";
        ItemJnlLine."Document Date" := TransRcptHeader2."Posting Date";
        ItemJnlLine."Document No." := TransRcptHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Transfer Receipt";
        ItemJnlLine."Document Line No." := TransRcptLine2."Line No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
        ItemJnlLine."Order No." := TransRcptHeader2."Transfer Order No.";
        ItemJnlLine."Order Line No." := TransLine3."Line No.";
        ItemJnlLine."External Document No." := TransRcptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Item No." := TransRcptLine2."Item No.";
        ItemJnlLine.Description := TransRcptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := TransRcptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."New Shortcut Dimension 1 Code" := TransRcptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := TransRcptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."New Shortcut Dimension 2 Code" := TransRcptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Dimension Set ID" := TransRcptLine2."Dimension Set ID";
        ItemJnlLine."New Dimension Set ID" := TransRcptLine2."Dimension Set ID";
        ItemJnlLine."Location Code" := TransHeader."In-Transit Code";
        ItemJnlLine."New Location Code" := TransRcptHeader2."Transfer-to Code";
        ItemJnlLine.Quantity := TransRcptLine2.Quantity;
        ItemJnlLine."Invoiced Quantity" := TransRcptLine2.Quantity;
        ItemJnlLine."Quantity (Base)" := TransRcptLine2."Quantity (Base)";
        ItemJnlLine."Invoiced Qty. (Base)" := TransRcptLine2."Quantity (Base)";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Prod. Posting Group" := TransRcptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := TransRcptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := TransRcptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := TransRcptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := TransRcptLine2."Variant Code";
        ItemJnlLine."New Bin Code" := TransLine."Transfer-To Bin Code";
        ItemJnlLine."Item Category Code" := TransLine."Item Category Code";
        if TransHeader."In-Transit Code" <> '' then begin
            if NewLocation.Code <> TransHeader."In-Transit Code" then
                NewLocation.Get(TransHeader."In-Transit Code");
            ItemJnlLine."Country/Region Code" := NewLocation."Country/Region Code";
        end;
        ItemJnlLine."Transaction Type" := TransRcptHeader2."Transaction Type";
        ItemJnlLine."Transport Method" := TransRcptHeader2."Transport Method";
        ItemJnlLine."Entry/Exit Point" := TransRcptHeader2."Entry/Exit Point";
        ItemJnlLine.Area := TransRcptHeader2.Area;
        ItemJnlLine."Transaction Specification" := TransRcptHeader2."Transaction Specification";
        ItemJnlLine."Shpt. Method Code" := TransRcptHeader2."Shipment Method Code";
        ItemJnlLine."Direct Transfer" := TransLine."Direct Transfer";
        OnPostItemJnlLineOnBeforeWriteDownDerivedLines(ItemJnlLine, TransLine3, TransRcptHeader2, TransRcptLine2);
        WriteDownDerivedLines(TransLine3);
        ItemJnlPostLine.SetPostponeReservationHandling(true);

        OnBeforePostItemJournalLine(ItemJnlLine, TransLine3, TransRcptHeader2, TransRcptLine2, SuppressCommit, PreviewMode, TransLine, PostedWhseRcptHeader);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        OnAfterPostItemJnlLine(ItemJnlLine, TransLine3, TransRcptHeader2, TransRcptLine2, ItemJnlPostLine);
    end;

    local procedure CheckItemVariantNotBlocked(var ItemVariant: Record "Item Variant")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemVariantNotBlocked(TransLine, ItemVariant, Transheader, Location, WhseReceive, IsHandled);
        if IsHandled then
            exit;

        ItemVariant.TestField(Blocked, false);
    end;

    local procedure CheckDim()
    begin
        TransLine."Line No." := 0;
        CheckDimComb(TransHeader, TransLine);
        CheckDimValuePosting(TransHeader, TransLine);

        TransLine.SetRange("Document No.", TransHeader."No.");
        if TransLine.FindFirst() then begin
            CheckDimComb(TransHeader, TransLine);
            CheckDimValuePosting(TransHeader, TransLine);
        end;
    end;

    local procedure CheckDimComb(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimComb(TransferHeader, TransferLine, IsHandled);
        if IsHandled then
            exit;

        if TransferLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(TransferHeader."Dimension Set ID") then
                Error(
                  Text005,
                  TransHeader."No.", DimMgt.GetDimCombErr());
        if TransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(TransferLine."Dimension Set ID") then
                Error(
                  Text006,
                  TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimCombErr());

        OnAfterCheckDimComb(TransferHeader, TransferLine);
    end;

    local procedure CheckDimValuePosting(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeCheckDimValuePosting(TransferHeader, TransferLine, IsHandled);
        if IsHandled then
            exit;

        TableIDArr[1] := DATABASE::Item;
        NumberArr[1] := TransferLine."Item No.";
        TableIDArr[2] := DATABASE::Location;
        NumberArr[2] := TransferLine."Transfer-to Code";
        if TransferLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferHeader."Dimension Set ID") then
                Error(
                  Text007,
                  TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr());

        if TransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, TransferLine."Dimension Set ID") then
                Error(
                  Text007,
                  TransHeader."No.", TransferLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure SaveAndClearPostingFromWhseRef()
    begin
        WhseReference := TransHeader."Posting from Whse. Ref.";
        TransHeader."Posting from Whse. Ref." := 0;

        OnAfterSaveAndClearPostingFromWhseRef(TransHeader, Location);
    end;

    local procedure WriteDownDerivedLines(var TransLine3: Record "Transfer Line")
    var
        TransLine4: Record "Transfer Line";
        T337: Record "Reservation Entry";
        TempDerivedSpecification: Record "Tracking Specification" temporary;
        TransShptLine: Record "Transfer Shipment Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        QtyToReceive: Decimal;
        BaseQtyToReceive: Decimal;
        TrackingSpecificationExists: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeWriteDownDerivedLines(TransLine3, SuppressCommit, PreviewMode, TransLine4, T337, TempDerivedSpecification, IsHandled);
        if IsHandled then
            exit;

        TransLine4.SetRange("Document No.", TransLine3."Document No.");
        TransLine4.SetRange("Derived From Line No.", TransLine3."Line No.");
        if TransLine4.Find('-') then begin
            QtyToReceive := TransLine3."Qty. to Receive";
            BaseQtyToReceive := TransLine3."Qty. to Receive (Base)";

            T337.SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
            T337.SetRange("Source ID", TransLine3."Document No.");
            T337.SetRange("Source Ref. No.");
            T337.SetRange("Source Type", DATABASE::"Transfer Line");
            T337.SetRange("Source Subtype", 1);
            T337.SetRange("Source Batch Name", '');
            T337.SetRange("Source Prod. Order Line", TransLine3."Line No.");
            T337.SetFilter("Qty. to Handle (Base)", '<>0');

            TrackingSpecificationExists :=
              ItemTrackingMgt.SumUpItemTracking(T337, TempDerivedSpecification, true, false);

            repeat
                if TrackingSpecificationExists then begin
                    TempDerivedSpecification.SetRange("Source Ref. No.", TransLine4."Line No.");
                    if TempDerivedSpecification.FindFirst() then begin
                        TransLine4."Qty. to Receive (Base)" := TempDerivedSpecification."Qty. to Handle (Base)";
                        TransLine4."Qty. to Receive" := TempDerivedSpecification."Qty. to Handle";
                    end else begin
                        TransLine4."Qty. to Receive (Base)" := 0;
                        TransLine4."Qty. to Receive" := 0;
                    end;
                end;
                OnWriteDownDerivedLinesOnAfterAssignTracking(TransLine4, TempDerivedSpecification, TrackingSpecificationExists);
                if TransLine4."Qty. to Receive (Base)" <= BaseQtyToReceive then begin
                    ReserveTransLine.TransferTransferToItemJnlLine(
                      TransLine4, ItemJnlLine, TransLine4."Qty. to Receive (Base)", Enum::"Transfer Direction"::Inbound);
                    TransLine4."Quantity (Base)" :=
                      TransLine4."Quantity (Base)" - TransLine4."Qty. to Receive (Base)";
                    TransLine4.Quantity :=
                      TransLine4.Quantity - TransLine4."Qty. to Receive";
                    BaseQtyToReceive := BaseQtyToReceive - TransLine4."Qty. to Receive (Base)";
                    QtyToReceive := QtyToReceive - TransLine4."Qty. to Receive";
                end else begin
                    ReserveTransLine.TransferTransferToItemJnlLine(
                      TransLine4, ItemJnlLine, BaseQtyToReceive, Enum::"Transfer Direction"::Inbound);
                    TransLine4.Quantity := TransLine4.Quantity - QtyToReceive;
                    TransLine4."Quantity (Base)" := TransLine4."Quantity (Base)" - BaseQtyToReceive;
                    BaseQtyToReceive := 0;
                    QtyToReceive := 0;
                end;
                if TransLine4."Quantity (Base)" = 0 then begin
                    // Update any TransShptLines pointing to this derived line before deleting
                    TransShptLine.SetRange("Transfer Order No.", TransLine4."Document No.");
                    TransShptLine.SetRange("Derived Trans. Order Line No.", TransLine4."Line No.");
                    if not TransShptLine.IsEmpty() then
                        TransShptLine.ModifyAll("Derived Trans. Order Line No.", 0);
                    TransLine4.Delete()
                end else begin
                    TransLine4."Qty. to Ship" := TransLine4.Quantity;
                    TransLine4."Qty. to Ship (Base)" := TransLine4."Quantity (Base)";
                    TransLine4."Qty. to Receive" := TransLine4.Quantity;
                    TransLine4."Qty. to Receive (Base)" := TransLine4."Quantity (Base)";
                    TransLine4.ResetPostedQty();
                    TransLine4."Outstanding Quantity" := TransLine4.Quantity;
                    TransLine4."Outstanding Qty. (Base)" := TransLine4."Quantity (Base)";

                    OnWriteDownDerivedLinesOnBeforeTransLineModify(TransLine4, TransLine3);
                    TransLine4.Modify();
                end;
            until (TransLine4.Next() = 0) or (BaseQtyToReceive = 0);
        end;

        if BaseQtyToReceive <> 0 then
            Error(Text008);
    end;

    local procedure InsertRcptEntryRelation(var TransRcptLine: Record "Transfer Receipt Line") Result: Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertRcptEntryRelation(TransRcptLine, ItemJnlLine, ItemJnlPostLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempItemEntryRelation2.Reset();
        TempItemEntryRelation2.DeleteAll();

        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then begin
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsTransRcptLine(TransRcptLine);
                    ItemEntryRelation.Insert();
                    TempItemEntryRelation2 := TempItemEntryRelation;
                    TempItemEntryRelation2.Insert();
                until TempItemEntryRelation.Next() = 0;
                exit(0);
            end;
        end else
            exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure InsertTransRcptHeader(var TransRcptHeader: Record "Transfer Receipt Header"; TransHeader: Record "Transfer Header"; NoSeries: Code[20])
    var
        NoSeriesCodeunit: Codeunit "No. Series";
        Handled: Boolean;
    begin
        OnBeforeInsertTransRcptHeader(TransRcptHeader, TransHeader, SuppressCommit, PreviewMode, Handled);
        if Handled then
            exit;

        TransRcptHeader.Init();
        TransRcptHeader.CopyFromTransferHeader(TransHeader);
        TransRcptHeader."No. Series" := NoSeries;
        OnInsertTransRcptHeaderOnBeforeGetNextNo(TransRcptHeader, TransHeader);
        if TransRcptHeader."No." = '' then
            TransRcptHeader."No." := NoSeriesCodeunit.GetNextNo(TransRcptHeader."No. Series", TransHeader."Posting Date");
        OnBeforeTransRcptHeaderInsert(TransRcptHeader, TransHeader);
        TransRcptHeader.Insert();

        OnAfterInsertTransRcptHeader(TransRcptHeader, TransHeader);
    end;

    local procedure InsertTransRcptLine(TransferReceiptHeader: Record "Transfer Receipt Header"; var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
        ShouldRunPosting: Boolean;
    begin
        TransRcptLine.Init();
        TransRcptLine."Document No." := TransferReceiptHeader."No.";
        TransRcptLine.CopyFromTransferLine(TransLine);
        IsHandled := false;
        OnBeforeInsertTransRcptLine(TransRcptLine, TransLine, SuppressCommit, PreviewMode, IsHandled, TransferReceiptHeader);
        if IsHandled then
            exit;

        TransRcptLine.Insert();
        OnAfterInsertTransRcptLine(TransRcptLine, TransLine, SuppressCommit, PreviewMode, TransferReceiptHeader);

        if TransLine."Qty. to Receive" > 0 then begin
            OriginalQuantity := TransLine."Qty. to Receive";
            OriginalQuantityBase := TransLine."Qty. to Receive (Base)";
            PostItemJnlLine(TransLine, TransRcptHeader, TransRcptLine);
            TransRcptLine."Item Rcpt. Entry No." := InsertRcptEntryRelation(TransRcptLine);
            TransRcptLine.Modify();
            SaveTempWhseSplitSpec(TransLine);
            if WhseReceive then begin
                WhseRcptLine.SetCurrentKey(
                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
                WhseRcptLine.SetRange("Source Type", DATABASE::"Transfer Line");
                WhseRcptLine.SetRange("Source No.", TransLine."Document No.");
                WhseRcptLine.SetRange("Source Line No.", TransLine."Line No.");
                OnInsertTransRcptLineOnAfterWhseRcptLineSetFilters(TransLine, TransRcptLine, WhseRcptLine);
                if WhseRcptLine.FindFirst() then
                    CreatePostedRcptLineFromWhseRcptLine(TransRcptLine);
            end;
            ShouldRunPosting := WhsePosting;
            OnInsertTransRcptLineOnBeforePostWhseJnlLine(TransRcptLine, TransLine, SuppressCommit, PreviewMode, WhsePosting, ShouldRunPosting);
            if ShouldRunPosting then
                PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempWhseSplitSpecification);
            OnAfterTransRcptLineModify(TransRcptLine, TransLine, SuppressCommit, PreviewMode);
        end;
    end;

    local procedure CreatePostedRcptLineFromWhseRcptLine(var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostedRcptLineFromWhseRcptLine(TransferReceiptLine, WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification, IsHandled, WhsePostRcpt, TempItemEntryRelation2);
        if IsHandled then
            exit;

        WhseRcptLine.TestField("Qty. to Receive", TransferReceiptLine.Quantity);
        WhsePostRcpt.SetItemEntryRelation(PostedWhseRcptHeader, PostedWhseRcptLine, TempItemEntryRelation2);
        WhsePostRcpt.CreatePostedRcptLine(
          WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
    end;

    local procedure CheckLines(TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLines(TransHeader, TransLine, IsHandled);
        if IsHandled then
            exit;

        TransLine.Reset();
        TransLine.SetRange("Document No.", TransHeader."No.");
        TransLine.SetRange("Derived From Line No.", 0);
        TransLine.SetFilter(Quantity, '<>0');
        TransLine.SetFilter("Qty. to Receive", '<>0');
        if not TransLine.Find('-') then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    local procedure CheckWarehouse(var TransLine: Record "Transfer Line")
    var
        TransLine2: Record "Transfer Line";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(TransLine, IsHandled);
        if IsHandled then
            exit;

        TransLine2.Copy(TransLine);
        if TransLine2.Find('-') then
            repeat
                GetLocation(TransLine2."Transfer-to Code");
                if Location."Require Receive" or Location."Require Put-away" then begin
                    if Location."Bin Mandatory" then
                        ShowError := true
                    else
                        if WhseValidateSourceLine.WhseLinesExist(
                             DATABASE::"Transfer Line",
                             1,// In
                             TransLine2."Document No.",
                             TransLine2."Line No.",
                             0,
                             TransLine2.Quantity)
                        then
                            ShowError := true;

                    if ShowError then
                        Error(
                          Text002,
                          TransLine2."Document No.",
                          TransLine2.FieldCaption("Line No."),
                          TransLine2."Line No.");
                end;
            until TransLine2.Next() = 0;
    end;

    local procedure SaveTempWhseSplitSpec(TransLine: Record "Transfer Line")
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveTempWhseSplitSpec(TransLine, ItemJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        TempWhseSplitSpecification.Reset();
        TempWhseSplitSpecification.DeleteAll();
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) then
            if TempHandlingSpecification.Find('-') then
                repeat
                    TempWhseSplitSpecification := TempHandlingSpecification;
                    TempWhseSplitSpecification."Entry No." := TempHandlingSpecification."Transfer Item Entry No.";
                    TempWhseSplitSpecification."Source Type" := DATABASE::"Transfer Line";
                    TempWhseSplitSpecification."Source Subtype" := 1;
                    TempWhseSplitSpecification."Source ID" := TransLine."Document No.";
                    TempWhseSplitSpecification."Source Ref. No." := TransLine."Line No.";
                    TempWhseSplitSpecification.Insert();
                until TempHandlingSpecification.Next() = 0;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure IsWarehousePosting(LocationCode: Code[10]): Boolean
    begin
        GetLocation(LocationCode);
        if Location."Bin Mandatory" and not (WhseReceive or InvtPickPutaway) then
            exit(true);
        exit(false);
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WMSMgmt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.Quantity := OriginalQuantity;
        ItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
        GetLocation(ItemJnlLine."New Location Code");
        if Location."Bin Mandatory" then
            if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 1, WhseJnlLine, true) then begin
                WMSMgmt.SetTransferLine(TransLine, WhseJnlLine, 1, TransRcptHeader."No.");
                OnPostWhseJnlLineOnBeforeSplitWhseJnlLine();
                ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, true);
                if TempWhseJnlLine2.Find('-') then
                    repeat
                        WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, true);
                        WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
                    until TempWhseJnlLine2.Next() = 0;
            end;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "Warehouse Receipt Header")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.Insert();
    end;

    local procedure LockTables(AutoCostPosting: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        if AutoCostPosting then begin
            GLEntry.LockTable();
            GLEntry.GetLastEntryNo();
        end;
    end;

    local procedure ReleaseDocument(var TransferHeader: Record "Transfer Header")
    var
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
    begin
        OnBeforeReleaseDocument(TransferHeader);

        if TransferHeader.Status = TransferHeader.Status::Open then begin
            ReleaseTransferDocument.Release(TransferHeader);
            TransferHeader.Status := TransferHeader.Status::Open;
            TransferHeader.Modify();
            if not (SuppressCommit or PreviewMode) then
                Commit();
            TransferHeader.Status := TransferHeader.Status::Released;
        end;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetCalledBy(NewCalledBy: Integer)
    begin
        CalledBy := NewCalledBy;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforePostValueEntryToGL', '', false, false)]
    local procedure OnBeforePostValueEntryToGL(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
        if InvtSetup.UseLegacyPosting() then
            exit;
        PostponedValueEntries.Add(ValueEntry."Entry No.");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem', '', false, false)]
    local procedure OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(var Item2: Record Item)
    begin
        if InvtSetup.UseLegacyPosting() then
            exit;

        if not ItemsToAdjust.Contains(Item2."No.") then
            ItemsToAdjust.Add(Item2."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferReceiptHeader: Record "Transfer Receipt Header"; TransferReceiptLine: Record "Transfer Receipt Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; TransLine: Record "Transfer Line"; PostedWhseRcptHeader: Record "Posted Whse. Receipt Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTransferOrderPostReceipt(var TransferHeader: Record "Transfer Header"; var CommitIsSuppressed: Boolean; PreviewMode: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveAndClearPostingFromWhseRef(var TransferHeader: Record "Transfer Header"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostReceipt(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineUpdateQtyReceived(var TransferLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransRcptLineModify(var TransferReceiptLine: Record "Transfer Receipt Line"; TransferLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimComb(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLines(TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedRcptLineFromWhseRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; var WhseRcptLine: Record "Warehouse Receipt Line"; var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean; var WhsePostReceipt: Codeunit "Whse.-Post Receipt"; var TempItemEntryRelation2: Record "Item Entry Relation" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var TransferHeader2: Record "Transfer Header"; var HideValidationDialog: Boolean; SuppressCommit: Boolean; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransRcptHeader(var TransRcptHeader: Record "Transfer Receipt Header"; TransHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var IsHandled: Boolean; TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRcptEntryRelation(var TransRcptLine: Record "Transfer Receipt Line"; var ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransRcptHeaderInsert(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOneTransferHeader(TransferHeader: Record "Transfer Header"; var DeleteOne: Boolean; TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var TransferReceiptHeader: Record "Transfer Receipt Header"; var IsHandled: Boolean; TransferReceiptLine: Record "Transfer Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseDocument(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveTempWhseSplitSpec(TransLine: Record "Transfer Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckInvtPostingSetup(var TransferHeader: Record "Transfer Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTransLine(TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWriteDownDerivedLinesOnBeforeTransLineModify(var TransferLine: Record "Transfer Line"; SourceTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransRcptHeader(var TransRcptHeader: Record "Transfer Receipt Header"; var TransHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransRcptHeaderOnBeforeGetNextNo(var TransRcptHeader: Record "Transfer Receipt Header"; TransHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransRcptLineOnBeforePostWhseJnlLine(var TransRcptLine: Record "Transfer Receipt Line"; var TransLine: Record "Transfer Line"; SuppressCommit: Boolean; PreviewMode: Boolean; var WhsePosting: Boolean; var ShouldRunPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnBeforeSplitWhseJnlLine()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCommit(var TransHeader: Record "Transfer Header"; var TransRcptHeader: Record "Transfer Receipt Header"; PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var SuppressCommit: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDimComb(TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(ItemJnlLine: Record "Item Journal Line"; var TransLine3: Record "Transfer Line"; var TransRcptHeader2: Record "Transfer Receipt Header"; var TransRcptLine2: Record "Transfer Receipt Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterTransLineSetFiltersForRcptLines(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInsertTransRcptLines(TransRcptHeader: Record "Transfer Receipt Header"; TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePostUpdateDocumens(var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransRcptLineOnAfterWhseRcptLineSetFilters(var TransferLine: Record "Transfer Line"; var TransferRcptLine: Record "Transfer Receipt Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCheckItemBlocked(TransLine: Record "Transfer Line"; Item: Record Item; TransHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemVariantNotBlocked(TransLine: Record "Transfer Line"; ItemVariant: Record "Item Variant"; TransHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeUpdateWithWarehouseShipReceive(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunWithCheckOnBeforeModifyTransferHeader(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeWriteDownDerivedLines(var ItemJournalLine: Record "Item Journal Line"; var TransferLine: Record "Transfer Line"; var TransferReceiptHeader: Record "Transfer Receipt Header"; var TransferReceiptLine: Record "Transfer Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWriteDownDerivedLinesOnAfterAssignTracking(var TransferLine: Record "Transfer Line"; var TrackingSpecification: Record "Tracking Specification"; TrackingSpecificationExists: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWriteDownDerivedLines(var TransferLine: Record "Transfer Line"; SuppressCommit: Boolean; PreviewMode: Boolean; var TransferLine2: Record "Transfer Line"; var ReservationLine: Record "Reservation Entry"; var TempDerivedSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransRcptLineOnBeforePostDeferredValue(var TransLine: Record "Transfer Line"; TransHeader: Record "Transfer Header"; TransRcptHeader: Record "Transfer Receipt Header"; TransRcptLine: Record "Transfer Receipt Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
    end;
}