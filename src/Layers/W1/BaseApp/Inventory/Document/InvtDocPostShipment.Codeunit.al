// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using Microsoft.Warehouse.Journal;
using System.Utilities;

codeunit 5851 "Invt. Doc.-Post Shipment"
{
    Permissions = TableData "Item Entry Relation" = ri,
                  TableData "Value Entry Relation" = ri,
                  TableData "Invt. Shipment Header" = rimd,
                  TableData "Invt. Shipment Line" = rimd,
                  tabledata "G/L Entry" = r;
    TableNo = "Invt. Document Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SourceCodeSetup: Record "Source Code Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        NoSeries: Codeunit "No. Series";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
        HideProgressWindow: Boolean;
        SuppressCommit: Boolean;
    begin
        OnBeforeOnRun(Rec, SuppressCommit, HideProgressWindow);

        Rec.TestField("Document Type", Rec."Document Type"::Shipment);

        InvtDocHeader := Rec;
        InvtDocHeader.SetHideValidationDialog(HideValidationDialog);

        CheckInvtDocumentHeaderMandatoryFields(InvtDocHeader);

        CheckDim();

        SetInvtDocumentLineFiltersFromDocument(InvtDocLine, InvtDocHeader);
        if not InvtDocLine.Find('-') then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        OnRunOnAfterCheckLocation(Rec);

        if not HideProgressWindow then begin
            Window.Open('#1#################################\\' + PostingLinesMsg);

            Window.Update(1, StrSubstNo(PostingDocumentTxt, InvtDocHeader."No."));
        end;

        SourceCodeSetup.Get();
        SourceCode := SourceCodeSetup."Invt. Shipment";
        InvtSetup.Get();
        InvtSetup.TestField("Posted Invt. Shipment Nos.");
        InventoryPostingSetup.SetRange("Location Code", InvtDocHeader."Location Code");
        if InventoryPostingSetup.IsEmpty() then
            error(InventoryPostingSetupMissingErr, InvtDocHeader."Location Code");

        if InvtDocHeader.Status = InvtDocHeader.Status::Open then begin
            CODEUNIT.Run(CODEUNIT::"Release Invt. Document", InvtDocHeader);
            InvtDocHeader.Status := InvtDocHeader.Status::Open;
            if not InvtSetup.UseLegacyPosting() then
                if InvtDocHeader."No. Series" <> InvtDocHeader."Posting No. Series" then
                    if InvtDocHeader."Posting No." = '' then
                        InvtDocHeader."Posting No." := NoSeries.GetNextNo(InvtDocHeader."Posting No. Series", InvtDocHeader."Posting Date");
            InvtDocHeader.Modify();
            if not (SuppressCommit or PreviewMode) then
                Commit();
            InvtDocHeader.Status := InvtDocHeader.Status::Released;
            OnRunOnAfterSetStatusReleased(InvtDocHeader, InvtDocLine, SuppressCommit);
        end;

        InvtDocHeader.TestField(Status, InvtDocHeader.Status::Released);

        if InvtSetup.UseLegacyPosting() and InvtSetup."Automatic Cost Posting" then begin
            GLEntry.LockTable();
            GLEntry.GetLastEntryNo();
        end;
        // Insert shipment header
        InvtShptHeader.LockTable();
        InvtShptHeader.Init();
        OnRunOnAfterInvtShptHeaderInit(InvtShptHeader, InvtDocHeader);
        InvtShptHeader."Location Code" := InvtDocHeader."Location Code";
        InvtShptHeader."Posting Date" := InvtDocHeader."Posting Date";
        InvtShptHeader."Document Date" := InvtDocHeader."Document Date";
        InvtShptHeader."Salesperson Code" := InvtDocHeader."Salesperson/Purchaser Code";
        InvtShptHeader."Shortcut Dimension 1 Code" := InvtDocHeader."Shortcut Dimension 1 Code";
        InvtShptHeader."Shortcut Dimension 2 Code" := InvtDocHeader."Shortcut Dimension 2 Code";
        InvtShptHeader."Shipment No." := InvtDocHeader."No.";
        InvtShptHeader."External Document No." := InvtDocHeader."External Document No.";
        InvtShptHeader."Gen. Bus. Posting Group" := InvtDocHeader."Gen. Bus. Posting Group";
        if InvtDocHeader."No. Series" = InvtDocHeader."Posting No. Series" then
            InvtShptHeader."No." := InvtDocHeader."No."
        else begin
            if InvtDocHeader."Posting No." = '' then
                InvtDocHeader."Posting No." := NoSeries.GetNextNo(InvtDocHeader."Posting No. Series", InvtDocHeader."Posting Date");
            InvtShptHeader."No." := InvtDocHeader."Posting No.";
        end;
        InvtShptHeader."No. Series" := InvtDocHeader."Posting No. Series";
        InvtShptHeader."Posting Description" := InvtDocHeader."Posting Description";
        InvtShptHeader.Correction := InvtDocHeader.Correction;
        InvtShptHeader."Dimension Set ID" := InvtDocHeader."Dimension Set ID";
        OnRunOnBeforeInvtShptHeaderInsert(InvtShptHeader, InvtDocHeader);
        InvtShptHeader.Insert();
        OnRunOnAfterInvtShptHeaderInsert(InvtShptHeader, InvtDocHeader);

        if InvtSetup."Copy Comments to Invt. Doc." then begin
            CopyCommentLines(
                Enum::"Inventory Comment Document Type"::"Inventory Shipment",
                Enum::"Inventory Comment Document Type"::"Posted Inventory Shipment",
                InvtDocHeader."No.", InvtShptHeader."No.");
            RecordLinkManagement.CopyLinks(InvtDocHeader, InvtShptHeader);
        end;
        // Insert shipment lines
        LineCount := 0;
        InvtShptLine.LockTable();
        InvtDocLine.SetRange(Quantity);
        OnRunOnBeforeInvtDocLineFind(InvtDocLine, InvtDocHeader);
        Clear(PostponedValueEntries);
        BindSubscription(this); // Start collecting value entries for GLPosting
        if not InvtSetup.UseLegacyPosting() then
            InvtDocLine.SetCurrentKey("Document Type", "Document No.", "Item No.", "Location Code", "Line No.");
        if InvtDocLine.Find('-') then
            repeat
                LineCount := LineCount + 1;
                if not HideProgressWindow then
                    Window.Update(2, LineCount);

                if InvtDocLine."Item No." <> '' then begin
                    Item.Get(InvtDocLine."Item No.");
                    Item.TestField(Blocked, false);

                    if InvtDocLine."Variant Code" <> '' then begin
                        ItemVariant.SetLoadFields(Blocked);
                        ItemVariant.Get(InvtDocLine."Item No.", InvtDocLine."Variant Code");
                        ItemVariant.TestField(Blocked, false);
                    end;
                end;

                InvtShptLine.Init();
                OnRunOnAfterInvtShptLineInit(InvtShptLine, InvtDocLine, InvtShptHeader, InvtDocHeader);
                InvtShptLine."Document No." := InvtShptHeader."No.";
                InvtShptLine."Posting Date" := InvtShptHeader."Posting Date";
                InvtShptLine."Document Date" := InvtShptHeader."Document Date";
                InvtShptLine."Line No." := InvtDocLine."Line No.";
                InvtShptLine."Item No." := InvtDocLine."Item No.";
                InvtShptLine.Description := InvtDocLine.Description;
                InvtShptLine.Quantity := InvtDocLine.Quantity;
                InvtShptLine."Unit Amount" := InvtDocLine."Unit Amount";
                InvtShptLine."Unit Cost" := InvtDocLine."Unit Cost";
                InvtShptLine.Amount := InvtDocLine.Amount;
                InvtShptLine."Indirect Cost %" := InvtDocLine."Indirect Cost %";
                InvtShptLine."Unit of Measure Code" := InvtDocLine."Unit of Measure Code";
                InvtShptLine."Shortcut Dimension 1 Code" := InvtDocLine."Shortcut Dimension 1 Code";
                InvtShptLine."Shortcut Dimension 2 Code" := InvtDocLine."Shortcut Dimension 2 Code";
                InvtShptLine."Gen. Bus. Posting Group" := InvtDocLine."Gen. Bus. Posting Group";
                InvtShptLine."Gen. Prod. Posting Group" := InvtDocLine."Gen. Prod. Posting Group";
                InvtShptLine."Inventory Posting Group" := InvtDocLine."Inventory Posting Group";
                InvtShptLine."Quantity (Base)" := InvtDocLine."Quantity (Base)";
                InvtShptLine."Qty. per Unit of Measure" := InvtDocLine."Qty. per Unit of Measure";
                InvtShptLine."Qty. Rounding Precision" := InvtDocLine."Qty. Rounding Precision";
                InvtShptLine."Qty. Rounding Precision (Base)" := InvtDocLine."Qty. Rounding Precision (Base)";
                InvtShptLine."Unit of Measure Code" := InvtDocLine."Unit of Measure Code";
                InvtShptLine."Gross Weight" := InvtDocLine."Gross Weight";
                InvtShptLine."Net Weight" := InvtDocLine."Net Weight";
                InvtShptLine."Unit Volume" := InvtDocLine."Unit Volume";
                InvtShptLine."Variant Code" := InvtDocLine."Variant Code";
                InvtShptLine."Units per Parcel" := InvtDocLine."Units per Parcel";
                InvtShptLine."Location Code" := InvtDocLine."Location Code";
                InvtShptLine."Shipment No." := InvtDocLine."Document No.";
                InvtShptLine."Bin Code" := InvtDocLine."Bin Code";
                InvtShptLine."Item Category Code" := InvtDocLine."Item Category Code";
                InvtShptLine."FA No." := InvtDocLine."FA No.";
                InvtShptLine."Depreciation Book Code" := InvtDocLine."Depreciation Book Code";
                InvtShptLine."Applies-to Entry" := InvtDocLine."Applies-to Entry";
                InvtShptLine."Applies-from Entry" := InvtDocLine."Applies-from Entry";
                InvtShptLine."Reason Code" := InvtDocLine."Reason Code";
                InvtShptLine."Item Reference No." := InvtDocLine."Item Reference No.";
                InvtShptLine."Item Reference Unit of Measure" := InvtDocLine."Item Reference Unit of Measure";
                InvtShptLine."Item Reference Type" := InvtDocLine."Item Reference Type";
                InvtShptLine."Item Reference Type No." := InvtDocLine."Item Reference Type No.";
                InvtShptLine."Source Code" := SourceCode;
                InvtShptLine."Dimension Set ID" := InvtDocLine."Dimension Set ID";
                OnRunOnBeforeInvtShptLineInsert(InvtShptLine, InvtDocLine, InvtShptHeader, InvtDocHeader);
                InvtShptLine.Insert();
                OnRunOnAfterInvtShptLineInsert(InvtShptLine, InvtDocLine, InvtShptHeader, InvtDocHeader);

                PostItemJnlLine(InvtShptHeader, InvtShptLine);
                ItemJnlPostLine.CollectValueEntryRelation(TempValueEntryRelation, InvtShptLine.RowID1());
            until InvtDocLine.Next() = 0;
        InvtDocLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        UnBindSubscription(this); // Stop collecting value entries for GLPosting
        ItemJnlPostLine.PostDeferredValueEntriesToGL(PostponedValueEntries);

        OnRunOnAfterInvtDocPost(InvtDocHeader, InvtDocLine);

        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust);

        InvtDocHeader.LockTable();

        if not PreviewMode then
            InvtDocHeader.Delete(true);

        InsertValueEntryRelation();
        OnRunOnBeforeCommitPostInvtShptDoc(InvtDocHeader, InvtDocLine, InvtShptHeader, InvtShptLine, ItemJnlLine, SuppressCommit);
        if not (SuppressCommit or PreviewMode) then
            Commit();
        OnRunOnAfterCommitPostInvtShptDoc(InvtDocHeader, InvtDocLine, InvtShptHeader, InvtShptLine, ItemJnlLine, SuppressCommit);
        if not HideProgressWindow then
            Window.Close();

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
        Rec := InvtDocHeader;

        OnAfterOnRun(Rec, InvtDocHeader, InvtDocLine, InvtShptHeader, InvtShptLine);
    end;

    var
        InvtShptHeader: Record "Invt. Shipment Header";
        InvtShptLine: Record "Invt. Shipment Line";
        InvtDocHeader: Record "Invt. Document Header";
        InvtDocLine: Record "Invt. Document Line";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        GLEntry: Record "G/L Entry";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        ReserveInvtDocLine: Codeunit "Invt. Doc. Line-Reserve";
        PostponedValueEntries: List of [Integer];
        ItemsToAdjust: List of [Code[20]];
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        PreviewMode: Boolean;
        PostingLinesMsg: Label 'Posting item shipment lines     #2######', Comment = '#2 - line counter';
        PostingDocumentTxt: Label 'Item Shipment %1', Comment = '%1 - document number';
        DimCombBlockedErr: Label 'The combination of dimensions used in item shipment %1 is blocked. %2', Comment = '%1 - document number, %2 - error message';
        DimCombLineBlockedErr: Label 'The combination of dimensions used in item shipment %1, line no. %2 is blocked. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        DimInvalidErr: Label 'The dimensions used in item shipment %1, line no. %2 are invalid. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        InventoryPostingSetupMissingErr: Label 'Inventory posting setup missing for location code %1.', Comment = '%1 - location code';

    local procedure CheckInvtDocumentHeaderMandatoryFields(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
        OnBeforeCheckInvtDocumentHeaderMandatoryFields(InvtDocumentHeader);

        InvtDocumentHeader.TestField("No.");
        InvtDocumentHeader.TestField("Posting Date");

        OnAfterCheckInvtDocumentHeaderMandatoryFields(InvtDocumentHeader);
    end;

    local procedure SetInvtDocumentLineFiltersFromDocument(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
        InvtDocumentLine.Reset();
        InvtDocumentLine.SetRange("Document Type", InvtDocumentHeader."Document Type");
        InvtDocumentLine.SetRange("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.SetFilter(Quantity, '>0');

        OnAfterSetInvtDocumentLineFiltersFromDocument(InvtDocumentLine, InvtDocumentHeader);
    end;

    local procedure PostItemJnlLine(InvtShptHeader2: Record "Invt. Shipment Header"; InvtShptLine2: Record "Invt. Shipment Line")
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(InvtShptHeader2, InvtShptLine2, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.Init();
        OnPostItemJnlLineOnAfterItemJnlLineInit(ItemJnlLine, InvtShptHeader2, InvtShptLine2);
        ItemJnlLine."Posting Date" := InvtShptHeader2."Posting Date";
        ItemJnlLine."Document Date" := InvtShptHeader2."Document Date";
        ItemJnlLine."Document No." := InvtShptHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Inventory Shipment";
        ItemJnlLine."Document Line No." := InvtShptLine2."Line No.";
        ItemJnlLine."External Document No." := InvtShptHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
        ItemJnlLine."Item No." := InvtShptLine2."Item No.";
        ItemJnlLine.Description := InvtShptLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := InvtShptLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := InvtShptLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Location Code" := InvtShptHeader2."Location Code";

        FillItemJournalLineQtyFromInvtShipmentLine(ItemJnlLine, InvtShptLine2, InvtShptHeader2);

        ItemJnlLine."Unit Amount" := InvtShptLine2."Unit Amount";
        ItemJnlLine."Unit Cost" := InvtShptLine2."Unit Cost";
        ItemJnlLine."Indirect Cost %" := InvtShptLine2."Indirect Cost %";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Gen. Bus. Posting Group" := InvtShptLine2."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := InvtShptLine2."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := InvtShptLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := InvtShptLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := InvtShptLine2."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := InvtShptLine2."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := InvtShptLine2."Qty. Rounding Precision (Base)";
        ItemJnlLine."Variant Code" := InvtShptLine2."Variant Code";
        ItemJnlLine."Item Category Code" := InvtShptLine2."Item Category Code";
        ItemJnlLine."Applies-to Entry" := InvtShptLine2."Applies-to Entry";
        ItemJnlLine."Applies-from Entry" := InvtShptLine2."Applies-from Entry";

        ItemJnlLine."Bin Code" := InvtShptLine2."Bin Code";
        ItemJnlLine."Dimension Set ID" := InvtShptLine2."Dimension Set ID";
        ItemJnlLine."Reason Code" := InvtShptLine2."Reason Code";

        OnPostItemJnlLineOnBeforeTransferInvtDocToItemJnlLine(InvtDocLine, ItemJnlLine, InvtShptHeader2, InvtShptLine2);
        ReserveInvtDocLine.TransferInvtDocToItemJnlLine(InvtDocLine, ItemJnlLine, ItemJnlLine.Quantity);

        OriginalQuantity := ItemJnlLine.Quantity;
        OriginalQuantityBase := ItemJnlLine."Quantity (Base)";
        OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(ItemJnlLine, InvtShptHeader2, InvtShptLine2, OriginalQuantity, OriginalQuantityBase);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification);
        PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification);

        OnAfterPostItemJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, InvtShptHeader2, InvtShptLine2);
    end;

    local procedure FillItemJournalLineQtyFromInvtShipmentLine(var ItemJournalLine: Record "Item Journal Line"; InvtShipmentLine: Record "Invt. Shipment Line"; InvtShipmentHeader: Record "Invt. Shipment Header")
    var
        Sign: Integer;
    begin
        if InvtShipmentHeader.Correction then
            Sign := -1
        else
            Sign := 1;

        ItemJournalLine.Quantity := Sign * InvtShipmentLine.Quantity;
        ItemJournalLine."Invoiced Quantity" := Sign * InvtShipmentLine.Quantity;
        ItemJournalLine."Quantity (Base)" := Sign * InvtShipmentLine."Quantity (Base)";
        ItemJournalLine."Invoiced Qty. (Base)" := Sign * InvtShipmentLine."Quantity (Base)";
        ItemJournalLine.Amount := Sign * InvtShipmentLine.Amount;

        OnAfterFillItemJournalLineQtyFromInvtShipmentLine(ItemJournalLine, InvtShipmentLine, InvtShipmentHeader);
    end;

    local procedure CopyCommentLines(FromDocumentType: Enum "Inventory Comment Document Type"; ToDocumentType: Enum "Inventory Comment Document Type"; FromNumber: Code[20]; ToNumber: Code[20])
    var
        InvtCommentLine: Record "Inventory Comment Line";
        InvtCommentLine2: Record "Inventory Comment Line";
    begin
        InvtCommentLine.SetRange("Document Type", FromDocumentType);
        InvtCommentLine.SetRange("No.", FromNumber);
        if InvtCommentLine.Find('-') then
            repeat
                InvtCommentLine2 := InvtCommentLine;
                InvtCommentLine2."Document Type" := ToDocumentType;
                InvtCommentLine2."No." := ToNumber;
                InvtCommentLine2.Insert();
            until InvtCommentLine.Next() = 0;
    end;

    local procedure CheckDim()
    begin
        InvtDocLine."Line No." := 0;
        CheckDimComb(InvtDocHeader, InvtDocLine);
        CheckDimValuePosting(InvtDocHeader, InvtDocLine);

        InvtDocLine.SetRange("Document Type", InvtDocHeader."Document Type");
        InvtDocLine.SetRange("Document No.", InvtDocHeader."No.");
        if InvtDocLine.FindFirst() then begin
            CheckDimComb(InvtDocHeader, InvtDocLine);
            CheckDimValuePosting(InvtDocHeader, InvtDocLine);
        end;
    end;

    local procedure CheckDimComb(InvtDocHeader: Record "Invt. Document Header"; InvtDocLine: Record "Invt. Document Line")
    begin
        if InvtDocLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(InvtDocHeader."Dimension Set ID") then
                Error(DimCombBlockedErr, InvtDocHeader."No.", DimMgt.GetDimCombErr());
        if InvtDocLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(InvtDocLine."Dimension Set ID") then
                Error(DimCombLineBlockedErr, InvtDocHeader."No.", InvtDocLine."Line No.", DimMgt.GetDimCombErr());
    end;

    local procedure CheckDimValuePosting(InvtDocHeader: Record "Invt. Document Header"; InvtDocLine: Record "Invt. Document Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DATABASE::Item;
        NumberArr[1] := InvtDocLine."Item No.";
        if InvtDocLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, InvtDocHeader."Dimension Set ID") then
                Error(DimInvalidErr, InvtDocHeader."No.", InvtDocLine."Line No.", DimMgt.GetDimValuePostingErr());

        if InvtDocLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, InvtDocLine."Dimension Set ID") then
                Error(DimInvalidErr, InvtDocHeader."No.", InvtDocLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure InsertValueEntryRelation()
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        TempValueEntryRelation.Reset();
        if TempValueEntryRelation.Find('-') then begin
            repeat
                ValueEntryRelation := TempValueEntryRelation;
                ValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0;
            TempValueEntryRelation.DeleteAll();
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification);
        ItemJnlLine.Quantity := OriginalQuantity;
        ItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
        GetLocation(ItemJnlLine."Location Code");
        if Location."Bin Mandatory" then
            if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 0, WhseJnlLine, false) then begin
                WhseJnlLine."Source Type" := DATABASE::"Item Journal Line";
                ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, false);
                if TempWhseJnlLine2.FindSet() then
                    repeat
                        WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, false);
                        WhseJnlPostLine.Run(TempWhseJnlLine2);
                    until TempWhseJnlLine2.Next() = 0;
            end;
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
    local procedure OnAfterCheckInvtDocumentHeaderMandatoryFields(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInvtDocumentLineFiltersFromDocument(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItemJnlLine(ItemJournalLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; TrackingSpecification: Record "Tracking Specification"; InvtShipmentHeader: Record "Invt. Shipment Header"; InvtShipmentLine: Record "Invt. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var InvtDocumentHeader: Record "Invt. Document Header"; InvtDocumentHeader2: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; InvtShipmentHeader: Record "Invt. Shipment Header"; InvtShipmentLine: Record "Invt. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillItemJournalLineQtyFromInvtShipmentLine(var ItemJournalLine: Record "Item Journal Line"; InvtShipmentLine: Record "Invt. Shipment Line"; InvtShipmentHeader: Record "Invt. Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var InvtDocumentHeader: Record "Invt. Document Header"; var SuppressCommit: Boolean; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLine(ItemJournalLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvtDocumentHeaderMandatoryFields(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(InvtShipmenttHeader: Record "Invt. Shipment Header"; InvtShipmentLine: Record "Invt. Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetStatusReleased(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnAfterItemJnlLineInit(var ItemJournalLine: Record "Item Journal Line"; InvtShipmentHeader: Record "Invt. Shipment Header"; InvtShipmentLine: Record "Invt. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeTransferInvtDocToItemJnlLine(var InvtDocumentLine: Record "Invt. Document Line"; var ItemJournalLine: Record "Item Journal Line"; InvtShipmentHeader: Record "Invt. Shipment Header"; InvtShipmentLine: Record "Invt. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtShptHeaderInit(var InvtShipmentHeader: Record "Invt. Shipment Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtShptHeaderInsert(var InvtShipmentHeader: Record "Invt. Shipment Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtShptLineInit(var InvtShipmentLine: Record "Invt. Shipment Line"; InvtDocumentLine: Record "Invt. Document Line"; var InvtShipmentHeader: Record "Invt. Shipment Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCommitPostInvtShptDoc(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; InvtShipmentHeader: Record "Invt. Shipment Header"; InvtShipmentLine: Record "Invt. Shipment Line"; ItemJournalLine: Record "Item Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtShptLineInsert(var InvtShipmentLine: Record "Invt. Shipment Line"; InvtDocumentLine: Record "Invt. Document Line"; var InvtShipmentHeader: Record "Invt. Shipment Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtDocLineFind(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterInvtDocPost(InvtDocumentHeader: Record "Invt. Document Header"; InvtDocumentLine: Record "Invt. Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCommitPostInvtShptDoc(var InvtDocumentHeader: Record "Invt. Document Header"; var InvtDocumentLine: Record "Invt. Document Line"; InvtShipmentHeader: Record "Invt. Shipment Header"; InvtShipmentLine: Record "Invt. Shipment Line"; ItemJournalLine: Record "Item Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck(var ItemJnlLine: Record "Item Journal Line"; InvtShptHeader2: Record "Invt. Shipment Header"; InvtShptLine2: Record "Invt. Shipment Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtShptHeaderInsert(var InvtShptHeader: Record "Invt. Shipment Header"; InvtDocHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInvtShptLineInsert(var InvtShptLine: Record "Invt. Shipment Line"; InvtDocLine: Record "Invt. Document Line"; var InvtShipmentHeader: Record "Invt. Shipment Header"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCheckLocation(var InvtDocumentHeader: Record "Invt. Document Header")
    begin
    end;
}

