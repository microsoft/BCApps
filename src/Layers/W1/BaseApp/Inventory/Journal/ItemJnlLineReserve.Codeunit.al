// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;

codeunit 99000835 "Item Jnl. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        TempSKU: Record "Stockkeeping Unit" temporary;
        ReservationManagement: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        Blocked: Boolean;
        DeleteItemTracking: Boolean;

        Text000Err: Label 'Reserved quantity cannot be greater than %1', Comment = '%1 - quantity';
        Text002Err: Label 'must be filled in when a quantity is reserved';
        Text003Err: Label 'must not be filled in when a quantity is reserved';
        Text004Err: Label 'must not be changed when a quantity is reserved';
        Text005Err: Label 'Codeunit is not initialized correctly.';
        ItemJournalTxt: Label 'Item Journal';
        SourceDoc4Txt: Label '%1 %2 %3 %4', Locked = true;

    procedure CreateReservation(var ItemJournalLine: Record "Item Journal Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text005Err);

        ItemJournalLine.TestField("Item No.");
        ItemJournalLine.TestField("Posting Date");
        ItemJournalLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ItemJournalLine."Quantity (Base)") <
           Abs(ItemJournalLine."Reserved Qty. (Base)") + QuantityBase
        then
            Error(
              Text000Err,
              Abs(ItemJournalLine."Quantity (Base)") - Abs(ItemJournalLine."Reserved Qty. (Base)"));

        ItemJournalLine.TestField("Location Code", FromTrackingSpecification."Location Code");
        ItemJournalLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        if QuantityBase > 0 then
            ShipmentDate := ItemJournalLine."Posting Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ItemJournalLine."Posting Date";
        end;

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(ItemJournalLine, Quantity, QuantityBase, ForReservationEntry, IsHandled, FromTrackingSpecification, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                Database::"Item Journal Line",
                ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure",
                Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
            ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(ItemJournalLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure Caption(ItemJournalLine: Record "Item Journal Line") CaptionText: Text
    begin
        CaptionText := ItemJournalLine.GetSourceCaption();
    end;

    procedure FindReservEntry(ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ItemJournalLine.SetReservationFilters(ReservationEntry);
        OnFindReservEntryOnBeforeReservationEntryFindLast(ReservationEntry, ItemJournalLine);
        exit(ReservationEntry.FindLast());
    end;

    procedure ReservEntryExist(ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        exit(ItemJournalLine.ReservEntryExist());
    end;

    procedure ReservEntryExist(ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ItemJournalLine.SetReservationFilters(ReservationEntry);
        OnReservEntryExistOnBeforeReservationEntryIsEmpty(ReservationEntry, ItemJournalLine);
        exit(not ReservationEntry.IsEmpty());
    end;

    procedure VerifyChange(var NewItemJournalLine: Record "Item Journal Line"; var OldItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ShowError: Boolean;
        HasError: Boolean;
        PointerChanged, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewItemJournalLine, OldItemJournalLine, ReservationManagement, Blocked, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;
        if NewItemJournalLine."Line No." = 0 then
            if not ItemJournalLine.Get(
                 NewItemJournalLine."Journal Template Name",
                 NewItemJournalLine."Journal Batch Name",
                 NewItemJournalLine."Line No.")
            then
                exit;

        NewItemJournalLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewItemJournalLine."Reserved Qty. (Base)" <> 0;

        if NewItemJournalLine."Posting Date" = 0D then
            if ShowError then
                NewItemJournalLine.FieldError("Posting Date", Text002Err)
            else
                HasError := true;

        if NewItemJournalLine."Drop Shipment" then
            if ShowError then
                NewItemJournalLine.FieldError("Drop Shipment", Text003Err)
            else
                HasError := true;

        if NewItemJournalLine."Item No." <> OldItemJournalLine."Item No." then
            if ShowError then
                NewItemJournalLine.FieldError("Item No.", Text004Err)
            else
                HasError := true;

        if NewItemJournalLine."Entry Type" <> OldItemJournalLine."Entry Type" then
            if ShowError then
                NewItemJournalLine.FieldError("Entry Type", Text004Err)
            else
                HasError := true;

        if (NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::Transfer) and
           (NewItemJournalLine."Quantity (Base)" < 0)
        then begin
            if NewItemJournalLine."New Location Code" <> OldItemJournalLine."Location Code" then
                if ShowError then
                    NewItemJournalLine.FieldError("New Location Code", Text004Err)
                else
                    HasError := true;
            if NewItemJournalLine."New Bin Code" <> OldItemJournalLine."Bin Code" then
                if ItemTrackingManagement.GetWhseItemTrkgSetup(NewItemJournalLine."Item No.") then
                    if ShowError then
                        NewItemJournalLine.FieldError("New Bin Code", Text004Err)
                    else
                        HasError := true;
        end else begin
            if NewItemJournalLine."Location Code" <> OldItemJournalLine."Location Code" then
                if ShowError then
                    NewItemJournalLine.FieldError("Location Code", Text004Err)
                else
                    HasError := true;
            if (NewItemJournalLine."Bin Code" <> OldItemJournalLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewItemJournalLine."Item No.", NewItemJournalLine."Bin Code",
                  NewItemJournalLine."Location Code", NewItemJournalLine."Variant Code",
                  Database::"Item Journal Line", NewItemJournalLine."Entry Type".AsInteger(),
                  NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name",
                  0, NewItemJournalLine."Line No."))
            then begin
                if ShowError then
                    NewItemJournalLine.FieldError("Bin Code", Text004Err);
                HasError := true;
            end;
        end;
        if NewItemJournalLine."Variant Code" <> OldItemJournalLine."Variant Code" then
            if ShowError then
                NewItemJournalLine.FieldError("Variant Code", Text004Err)
            else
                HasError := true;
        if NewItemJournalLine."Line No." <> OldItemJournalLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewItemJournalLine, OldItemJournalLine, HasError, ShowError);

        if HasError then begin
            FindReservEntry(NewItemJournalLine, ReservationEntry);
            ReservationEntry.ClearTrackingFilter();

            PointerChanged := (NewItemJournalLine."Item No." <> OldItemJournalLine."Item No.") or
              (NewItemJournalLine."Entry Type" <> OldItemJournalLine."Entry Type");

            if PointerChanged or (not ReservationEntry.IsEmpty()) then
                if PointerChanged then begin
                    ReservationManagement.SetReservSource(OldItemJournalLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewItemJournalLine);
                end else begin
                    ReservationManagement.SetReservSource(NewItemJournalLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
        end;
    end;

    procedure VerifyQuantity(var NewItemJournalLine: Record "Item Journal Line"; var OldItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalLine: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewItemJournalLine, OldItemJournalLine, ReservationManagement, Blocked, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        if NewItemJournalLine."Line No." = OldItemJournalLine."Line No." then
            if NewItemJournalLine."Quantity (Base)" = OldItemJournalLine."Quantity (Base)" then
                exit;
        if NewItemJournalLine."Line No." = 0 then
            if not ItemJournalLine.Get(NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name", NewItemJournalLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewItemJournalLine);
        if NewItemJournalLine."Qty. per Unit of Measure" <> OldItemJournalLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewItemJournalLine."Quantity (Base)" * OldItemJournalLine."Quantity (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewItemJournalLine."Quantity (Base)");
    end;

    procedure TransferItemJnlToItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; TransferQty: Decimal; SkipInventory: Boolean): Boolean
    var
        OldReservationEntry: Record "Reservation Entry";
        OldReservationEntry2: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
        SkipThisRecord: Boolean;
        IsHandled: Boolean;
    begin
        if not ReservEntryExist(ItemJournalLine, OldReservationEntry) then
            exit(false);

        LockReservationEntry(ItemJournalLine);

        ItemLedgerEntry.TestField("Item No.", ItemJournalLine."Item No.");
        ItemLedgerEntry.TestField("Variant Code", ItemJournalLine."Variant Code");
        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then
            ItemLedgerEntry.TestField("Location Code", ItemJournalLine."New Location Code")
        else
            ItemLedgerEntry.TestField("Location Code", ItemJournalLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit(true);
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);

            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestField("Item No.", ItemJournalLine."Item No.");
                    OnTransferItemJnlToItemLedgEntryOnBeforeTestVariantCode(OldReservationEntry, ItemJournalLine, IsHandled);
                    OldReservationEntry.TestField("Variant Code", ItemJournalLine."Variant Code");

                    if SkipInventory then
                        if OldReservationEntry.IsReservationOrTracking() then begin
                            OldReservationEntry2.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                            SkipThisRecord := OldReservationEntry2."Source Type" = Database::"Item Ledger Entry";
                        end else
                            SkipThisRecord := false;

                    if not SkipThisRecord then begin
                        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then begin
                            if ItemLedgerEntry.Quantity < 0 then
                                TestOldReservEntryLocationCode(OldReservationEntry, ItemJournalLine);
                            CreateReservEntry.SetInbound(true);
                        end else
                            TestOldReservEntryLocationCode(OldReservationEntry, ItemJournalLine);

                        OnTransferItemJnlToItemLedgEntryOnBeforeTransferReservEntry(ItemLedgerEntry);
                        TransferQty :=
                          CreateReservEntry.TransferReservEntry(
                            Database::"Item Ledger Entry", 0, '', '', 0,
                            ItemLedgerEntry."Entry No.", ItemLedgerEntry."Qty. per Unit of Measure",
                            OldReservationEntry, TransferQty);
                        OnTransferItemJnlToItemLedgEntryOnAfterTransferReservEntry(OldReservationEntry2, ReservStatus, ItemLedgerEntry);
                    end else
                        if ReservStatus = ReservStatus::Tracking then begin
                            OldReservationEntry2.Delete();
                            OldReservationEntry.Delete();
                            ReservationManagement.ModifyActionMessage(OldReservationEntry."Entry No.", 0, true);
                        end;
                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end; // DO

        exit(true);
    end;

    local procedure TestOldReservEntryLocationCode(var OldReservationEntry: Record "Reservation Entry"; var ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestOldReservEntryLocationCode(OldReservationEntry, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        OldReservationEntry.TestField("Location Code", ItemJournalLine."Location Code");
    end;

    procedure RenameLine(var NewItemJournalLine: Record "Item Journal Line"; var OldItemJournalLine: Record "Item Journal Line")
    begin
        ReservationEngineMgt.RenamePointer(
            Database::"Item Journal Line",
            OldItemJournalLine."Entry Type".AsInteger(),
            OldItemJournalLine."Journal Template Name",
            OldItemJournalLine."Journal Batch Name",
            0,
            OldItemJournalLine."Line No.",
            NewItemJournalLine."Entry Type".AsInteger(),
            NewItemJournalLine."Journal Template Name",
            NewItemJournalLine."Journal Batch Name",
            0,
            NewItemJournalLine."Line No.");
    end;

    procedure DeleteLineConfirm(var ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        if not ItemJournalLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(ItemJournalLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        OnBeforeDeleteLine(ItemJournalLine, DeleteItemTracking);
        if Blocked then
            exit;

        ReservationManagement.SetReservSource(ItemJournalLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1);
        // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        ItemJournalLine.CalcFields("Reserved Qty. (Base)");
    end;

    procedure AssignForPlanning(var ItemJournalLine: Record "Item Journal Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ItemJournalLine."Item No." <> '' then begin
            PlanningAssignment.ChkAssignOne(ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code", ItemJournalLine."Posting Date");
            if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then
                PlanningAssignment.ChkAssignOne(ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."New Location Code", ItemJournalLine."Posting Date");
        end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ItemJournalLine: Record "Item Journal Line"; IsReclass: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallItemTracking(ItemJournalLine, IsReclass, IsHandled);
        if IsHandled then
            exit;

        ItemJournalLine.TestField("Item No.");
        OnCallItemTrackingOnCheckItemPosting(ItemJournalLine);

        IsHandled := false;
        OnCallItemTrackingOnBeforeCallItemJnlLineItemTracking(ItemJournalLine, IsHandled);
        if not IsHandled then begin
            InitFromItemJnlLine(TrackingSpecification, ItemJournalLine);
            if IsReclass then
                ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::Reclass);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJournalLine."Posting Date");
            ItemTrackingLines.SetInbound(ItemJournalLine.IsInbound());
            OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ItemJournalLine, ItemTrackingLines);
            ItemTrackingLines.RunModal();
        end;
    end;

    procedure CreateItemTracking(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemTrackingSetup: Record "Item Tracking Setup";
        SourceTrackingSpecification: Record "Tracking Specification";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if not ItemJournalLine.TrackingExists() then
            exit;

        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(ItemJournalLine."Item No.") then
            exit;

        if Item."Item Tracking Code" = '' then
            exit;

        if ReservEntryExist(ItemJournalLine) then
            exit;

        ItemTrackingSetup.CopyTrackingFromItemJnlLine(ItemJournalLine);
        InitFromItemJnlLine(TempTrackingSpecification, ItemJournalLine);
        TempTrackingSpecification.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);
        TempTrackingSpecification."Expiration Date" := ItemJournalLine."Expiration Date";
        TempTrackingSpecification."Warranty Date" := ItemJournalLine."Warranty Date";
        TempTrackingSpecification.Insert();

        SourceTrackingSpecification := TempTrackingSpecification;
        ItemTrackingLines.SetBlockCommit(true);
        ItemTrackingLines.RegisterItemTrackingLines(
            SourceTrackingSpecification, ItemJournalLine."Posting Date", TempTrackingSpecification);
    end;

    procedure RegisterBinContentItemTracking(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        SourceTrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if not TempTrackingSpecification.FindSet() then
            exit;

        InitFromItemJnlLine(SourceTrackingSpecification, ItemJournalLine);

        Clear(ItemTrackingLines);
        ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::Reclass);
        ItemTrackingLines.RegisterItemTrackingLines(
          SourceTrackingSpecification, ItemJournalLine."Posting Date", TempTrackingSpecification);
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        SourceRecordRef.SetTable(ItemJournalLine);
        ItemJournalLine.TestField("Drop Shipment", false);
        ItemJournalLine.TestField("Posting Date");

        ItemJournalLine.SetReservationEntry(ReservationEntry);

        CaptionText := ItemJournalLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(41);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [41, 42, 43, 44, 45]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Item Journal Line");
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Item Journal Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Item Journal Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ItemJnlLine);
            OnCreateReservationOnBeforeCreateReservation(ItemJnlLine, TrackingSpecification, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
            CreateReservation(ItemJnlLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        if MatchThisTable(SourceType) then begin
            ItemJournalLine.Reset();
            ItemJournalLine.SetRange("Journal Template Name", SourceID);
            ItemJournalLine.SetRange("Journal Batch Name", SourceBatchName);
            ItemJournalLine.SetRange("Line No.", SourceRefNo);
            ItemJournalLine.SetRange("Entry Type", SourceSubtype);
            PAGE.RunModal(PAGE::"Item Journal Lines", ItemJournalLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        if MatchThisTable(SourceType) then begin
            ItemJournalLine.Reset();
            ItemJournalLine.SetRange("Journal Template Name", SourceID);
            ItemJournalLine.SetRange("Journal Batch Name", SourceBatchName);
            ItemJournalLine.SetRange("Line No.", SourceRefNo);
            ItemJournalLine.SetRange("Entry Type", SourceSubtype);
            PAGE.Run(PAGE::"Item Journal Lines", ItemJournalLine);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Batch Name", ReservationEntry."Source Ref. No.");
        SourceRecRef.GetTable(ItemJournalLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemJournalLine."Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemJournalLine."Quantity (Base)");
        end;
        OnAfterGetSourceValue(ReservationEntry, SourceRecRef, ReturnOption);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Template Name", ReservationEntry."Source ID");
        ItemJournalLine.SetRange("Journal Batch Name", ReservationEntry."Source Batch Name");
        ItemJournalLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        ItemJournalLine.SetRange("Entry Type", ReservationEntry."Source Subtype");
        PAGE.RunModal(PAGE::"Item Journal Lines", ItemJournalLine);
    end;

    local procedure LockReservationEntry(ItemJournalLine: Record "Item Journal Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetItemData(ItemJournalLine."Item No.", '', ItemJournalLine."Location Code", ItemJournalLine."Variant Code", 0);
        TempSKU."Location Code" := ReservationEntry."Location Code";
        TempSKU."Item No." := ReservationEntry."Item No.";
        TempSKU."Variant Code" := ReservationEntry."Variant Code";
        if not TempSKU.Find() then begin
            TempSKU.Insert();
            ReservationEntry.Lock();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var ItemJournalLine: Record "Item Journal Line"; IsReclass: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLine(var ItemJournalLine: Record "Item Journal Line"; var DeleteItemTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewItemJournalLine: Record "Item Journal Line"; OldItemJournalLine: Record "Item Journal Line"; var ReservMgt: Codeunit "Reservation Management"; var Blocked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestOldReservEntryLocationCode(var OldReservEntry: Record "Reservation Entry"; var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemJnlToItemLedgEntryOnBeforeTestVariantCode(var OldReservEntry: Record "Reservation Entry"; var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemJnlToItemLedgEntryOnBeforeTransferReservEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemJnlToItemLedgEntryOnAfterTransferReservEntry(OldReservationEntry2: Record "Reservation Entry"; ReservationStatus: Enum "Reservation Status"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewItemJnlLine: Record "Item Journal Line"; OldItemJnlLine: Record "Item Journal Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var ItemJnlLine: REcord "Item Journal Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var ItemJnlLine: Record "Item Journal Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var FromTrackingSpecification: Record "Tracking Specification"; ExpectedReceiptDate: Date; var Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeCallItemJnlLineItemTracking(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnCheckItemPosting(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewItemJournalLine: Record "Item Journal Line"; OldItemJournalLine: Record "Item Journal Line"; var ReservationManagement: Codeunit "Reservation Management"; var Blocked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReservEntryExistOnBeforeReservationEntryIsEmpty(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindReservEntryOnBeforeReservationEntryFindLast(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservation(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var Description: Text[100]; var ExpectedDate: Date; var Quantity: Decimal; var QuantityBase: Decimal; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceForReservationOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;
#endif
    // codeunit Create Reserv. Entry

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnCheckSourceTypeSubtype', '', false, false)]
    local procedure CheckSourceTypeSubtype(var ReservationEntry: Record "Reservation Entry"; var IsError: Boolean)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            // Item Journal Lines with Entry Type Transfer can carry reservations during posting:
            IsError := (ReservationEntry."Source Subtype" <> 4) and (ReservationEntry."Source Ref. No." <> 0);
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Item Journal Line" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[4] := true;  // BatchName
            PointerFieldIsActive[6] := true;  // RefNo
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    begin
        if ReservationEntry."Source Type" = Database::"Item Journal Line" then
            Description :=
                StrSubstNo(
                    SourceDoc4Txt, ItemJournalTxt, Enum::"Item Ledger Entry Type".FromInteger(ReservationEntry."Source Subtype"),
                    ReservationEntry."Source ID", ReservationEntry."Source Batch Name");
    end;

    procedure InitFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
            ItemJnlLine."Item No.", ItemJnlLine.Description, ItemJnlLine."Location Code", ItemJnlLine."Variant Code",
            ItemJnlLine."Bin Code", ItemJnlLine."Qty. per Unit of Measure", ItemJnlLine."Qty. Rounding Precision (Base)");
        TrackingSpecification.SetSource(
            Database::"Item Journal Line", ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name", ItemJnlLine."Line No.",
            ItemJnlLine."Journal Batch Name", 0);
        TrackingSpecification.SetQuantities(
            ItemJnlLine."Quantity (Base)", ItemJnlLine.Quantity, ItemJnlLine."Quantity (Base)", ItemJnlLine.Quantity,
            ItemJnlLine."Quantity (Base)", 0, 0);

        OnAfterInitFromItemJnlLine(TrackingSpecification, ItemJnlLine);
#if not CLEAN25
        TrackingSpecification.RunOnAfterInitFromItemJnlLine(TrackingSpecification, ItemJnlLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnBeforeCheckApplyFromItemEntrySourceType', '', false, false)]
    local procedure OnBeforeCheckApplyFromItemEntrySourceType(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
        if not MatchThisTable(TrackingSpecification."Source Type") then
            exit;

        if ((TrackingSpecification."Source Subtype" in [0, 2, 6]) and (TrackingSpecification."Quantity (Base)" < 0)) or
            ((TrackingSpecification."Source Subtype" in [1, 3, 4, 5]) and (TrackingSpecification."Quantity (Base)" > 0))
        then
            TrackingSpecification.FieldError("Quantity (Base)");

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnUpdateSourceCost', '', false, false)]
    local procedure ReservationEntryOnUpdateSourceCost(ReservationEntry: Record "Reservation Entry"; UnitCost: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        QtyReserved: Decimal;
    begin
        if MatchThisTable(ReservationEntry."Source Type") then begin
            ItemJnlLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Batch Name", ReservationEntry."Source Ref. No.");
            if ItemJnlLine."Qty. per Unit of Measure" <> 0 then
                ItemJnlLine."Unit Cost" :=
                    Round(ItemJnlLine."Unit Cost" / ItemJnlLine."Qty. per Unit of Measure");
            if ItemJnlLine."Quantity (Base)" <> 0 then
                ItemJnlLine."Unit Cost" :=
                    Round(
                        (ItemJnlLine."Unit Cost" * (ItemJnlLine."Quantity (Base)" - QtyReserved) + UnitCost * QtyReserved) /
                         ItemJnlLine."Quantity (Base)", 0.00001);
            if ItemJnlLine."Qty. per Unit of Measure" <> 0 then
                ItemJnlLine."Unit Cost" :=
                    Round(ItemJnlLine."Unit Cost" * ItemJnlLine."Qty. per Unit of Measure");
            ItemJnlLine.Validate("Unit Cost");
            ItemJnlLine.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceValue(var ReservationEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservation(var ItemJournalLine: Record "Item Journal Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ReservationEntry: Record "Reservation Entry")
    begin
    end;

}
