// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;

codeunit 5854 "Invt. Doc. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        InventorySetup: Record "Inventory Setup";
        ReservationManagement: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        Blocked: Boolean;
        DeleteItemTracking: Boolean;
        InvtSetupRead: Boolean;
        CodeunitIsNotInitializedErr: Label 'Codeunit is not initialized correctly.';
        CannotBeGreaterErr: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1 - quantity';
        MustBeFilledErr: Label 'must be filled in when a quantity is reserved';
        MustNotBeChangedErr: Label 'must not be changed when a quantity is reserved';
        DirectionTxt: Label 'Outbound,Inbound';
        InventoryTxt: Label 'Inventory';
        SummaryTypeTxt: Label '%1, %2', Locked = true;
        SourceDoc3Txt: Label '%1 %2 %3', Locked = true;

    procedure CreateReservation(var InvtDocumentLine: Record "Invt. Document Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(CodeunitIsNotInitializedErr);

        InvtDocumentLine.TestField("Item No.");
        InvtDocumentLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        case InvtDocumentLine."Document Type" of
            "Invt. Doc. Document Type"::Shipment:
                begin
                    InvtDocumentLine.TestField("Document Date");
                    InvtDocumentLine.TestField("Location Code", FromTrackingSpecification."Location Code");
                    InvtDocumentLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                    if Abs(InvtDocumentLine."Quantity (Base)") <
                       Abs(InvtDocumentLine."Reserved Qty. Outbnd. (Base)") + Quantity
                    then
                        Error(
                          CannotBeGreaterErr,
                          Abs(InvtDocumentLine."Quantity (Base)") - Abs(InvtDocumentLine."Reserved Qty. Outbnd. (Base)"));
                    ShipmentDate := InvtDocumentLine."Document Date";
                end;
            "Invt. Doc. Document Type"::Receipt:
                begin
                    InvtDocumentLine.TestField("Document Date");
                    InvtDocumentLine.TestField("Location Code", FromTrackingSpecification."Location Code");
                    InvtDocumentLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                    if Abs(InvtDocumentLine."Quantity (Base)") <
                       Abs(InvtDocumentLine."Reserved Qty. Inbnd. (Base)") + Quantity
                    then
                        Error(
                          CannotBeGreaterErr,
                          Abs(InvtDocumentLine."Quantity (Base)") - Abs(InvtDocumentLine."Reserved Qty. Inbnd. (Base)"));
                    ExpectedReceiptDate := InvtDocumentLine."Document Date";
                end;
        end;

        CreateReservEntry.CreateReservEntryFor(
          Database::"Invt. Document Line",
          InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.", '',
          0, InvtDocumentLine."Line No.", InvtDocumentLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservationEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          InvtDocumentLine."Item No.", InvtDocumentLine."Variant Code", FromTrackingSpecification."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure FilterReservFor(var FilterReservationEntry: Record "Reservation Entry"; InvtDocumentLine: Record "Invt. Document Line")
    begin
        InvtDocumentLine.SetReservationFilters(FilterReservationEntry);
    end;

    procedure Caption(InvtDocumentLine: Record "Invt. Document Line"): Text
    begin
        exit(InvtDocumentLine.GetSourceCaption());
    end;

    procedure FindReservEntry(InvtDocumentLine: Record "Invt. Document Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        InvtDocumentLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.Find('+'));
    end;

    procedure VerifyChange(var NewInvtDocumentLine: Record "Invt. Document Line"; var OldInvtDocumentLine: Record "Invt. Document Line")
    var
        InvtDocumentLine: Record "Invt. Document Line";
        ShowErrorInbnd: Boolean;
        ShowErrorOutbnd: Boolean;
        HasErrorInbnd: Boolean;
        HasErrorOutbnd: Boolean;
        IsHandled: Boolean;
    begin
        if Blocked then
            exit;
        if NewInvtDocumentLine."Line No." = 0 then
            if not InvtDocumentLine.Get(NewInvtDocumentLine."Document Type", NewInvtDocumentLine."Document No.", NewInvtDocumentLine."Line No.") then
                exit;

        IsHandled := false;
        OnBeforeVerifyChange(NewInvtDocumentLine, OldInvtDocumentLine, IsHandled);
        if IsHandled then
            exit;

        NewInvtDocumentLine.CalcFields("Reserved Qty. Inbnd. (Base)");
        NewInvtDocumentLine.CalcFields("Reserved Qty. Outbnd. (Base)");

        ShowErrorInbnd := (NewInvtDocumentLine."Reserved Qty. Inbnd. (Base)" <> 0);
        ShowErrorOutbnd := (NewInvtDocumentLine."Reserved Qty. Outbnd. (Base)" <> 0);

        if NewInvtDocumentLine."Document Type" = NewInvtDocumentLine."Document Type"::Receipt then begin
            if NewInvtDocumentLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewInvtDocumentLine.FieldError("Document Date", MustBeFilledErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocumentLine."Document Type" = NewInvtDocumentLine."Document Type"::Shipment then begin
            if NewInvtDocumentLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewInvtDocumentLine.FieldError("Document Date", MustBeFilledErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocumentLine."Item No." <> OldInvtDocumentLine."Item No." then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewInvtDocumentLine.FieldError("Item No.", MustNotBeChangedErr);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewInvtDocumentLine."Location Code" <> OldInvtDocumentLine."Location Code" then begin
            if ShowErrorOutbnd then
                NewInvtDocumentLine.FieldError("Location Code", MustNotBeChangedErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocumentLine."Bin Code" <> OldInvtDocumentLine."Bin Code" then begin
            if ShowErrorOutbnd then
                NewInvtDocumentLine.FieldError("Bin Code", MustNotBeChangedErr);

            HasErrorOutbnd := true;
        end;

        if NewInvtDocumentLine."Variant Code" <> OldInvtDocumentLine."Variant Code" then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewInvtDocumentLine.FieldError("Variant Code", MustNotBeChangedErr);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewInvtDocumentLine."Line No." <> OldInvtDocumentLine."Line No." then begin
            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if HasErrorOutbnd then begin
            if (NewInvtDocumentLine."Item No." <> OldInvtDocumentLine."Item No.") or NewInvtDocumentLine.ReservEntryExist() then begin
                if NewInvtDocumentLine."Item No." <> OldInvtDocumentLine."Item No." then begin
                    ReservationManagement.SetReservSource(OldInvtDocumentLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewInvtDocumentLine);
                end else begin
                    ReservationManagement.SetReservSource(NewInvtDocumentLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewInvtDocumentLine."Quantity (Base)");
            end;
            AssignForPlanning(NewInvtDocumentLine);
            if (NewInvtDocumentLine."Item No." <> OldInvtDocumentLine."Item No.") or
               (NewInvtDocumentLine."Variant Code" <> OldInvtDocumentLine."Variant Code")
            then
                AssignForPlanning(OldInvtDocumentLine);
        end;

        if HasErrorInbnd then begin
            if (NewInvtDocumentLine."Item No." <> OldInvtDocumentLine."Item No.") or NewInvtDocumentLine.ReservEntryExist() then begin
                if NewInvtDocumentLine."Item No." <> OldInvtDocumentLine."Item No." then begin
                    ReservationManagement.SetReservSource(OldInvtDocumentLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewInvtDocumentLine);
                end else begin
                    ReservationManagement.SetReservSource(NewInvtDocumentLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewInvtDocumentLine."Quantity (Base)");
            end;
            AssignForPlanning(NewInvtDocumentLine);
            if (NewInvtDocumentLine."Item No." <> OldInvtDocumentLine."Item No.") or
               (NewInvtDocumentLine."Variant Code" <> OldInvtDocumentLine."Variant Code") or
               (NewInvtDocumentLine."Location Code" <> OldInvtDocumentLine."Location Code")
            then
                AssignForPlanning(OldInvtDocumentLine);
        end;
    end;

    procedure VerifyQuantity(var NewInvtDocumentLine: Record "Invt. Document Line"; var OldInvtDocumentLine: Record "Invt. Document Line")
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        if Blocked then
            exit;

        if NewInvtDocumentLine."Line No." = OldInvtDocumentLine."Line No." then
            if NewInvtDocumentLine."Quantity (Base)" = OldInvtDocumentLine."Quantity (Base)" then
                exit;
        if NewInvtDocumentLine."Line No." = 0 then
            if not InvtDocumentLine.Get(NewInvtDocumentLine."Document Type", NewInvtDocumentLine."Document No.", NewInvtDocumentLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewInvtDocumentLine);
        if NewInvtDocumentLine."Qty. per Unit of Measure" <> OldInvtDocumentLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        ReservationManagement.DeleteReservEntries(false, NewInvtDocumentLine."Quantity (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewInvtDocumentLine."Quantity (Base)");
        AssignForPlanning(NewInvtDocumentLine);
    end;

    procedure TransferInvtDocToItemJnlLine(var InvtDocumentLine: Record "Invt. Document Line"; var ItemJournalLine: Record "Item Journal Line"; ReceiptQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(InvtDocumentLine, OldReservationEntry) then
            exit;

        OldReservationEntry.LockTable();
        OldReservationEntry.FindLast();

        ItemJournalLine.TestField("Location Code", InvtDocumentLine."Location Code");
        ItemJournalLine.TestField("Item No.", InvtDocumentLine."Item No.");
        ItemJournalLine.TestField("Variant Code", InvtDocumentLine."Variant Code");

        if ReceiptQty = 0 then
            exit;

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then
            repeat
                OldReservationEntry.TestField("Item No.", InvtDocumentLine."Item No.");
                OldReservationEntry.TestField("Variant Code", InvtDocumentLine."Variant Code");
                OldReservationEntry.TestField("Location Code", InvtDocumentLine."Location Code");
                ReceiptQty :=
                  CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line",
                    ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry,
                    ReceiptQty); // qty base

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (ReceiptQty = 0);
    end;

    procedure RenameLine(var NewInvtDocumentLine: Record "Invt. Document Line"; var OldInvtDocumentLine: Record "Invt. Document Line")
    begin
        ReservationEngineMgt.RenamePointer(
            Database::"Invt. Document Line",
            0, OldInvtDocumentLine."Document No.", '', 0, OldInvtDocumentLine."Line No.",
            0, NewInvtDocumentLine."Document No.", '', 0, NewInvtDocumentLine."Line No.");
    end;

    procedure DeleteLine(var InvtDocumentLine: Record "Invt. Document Line")
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        RedStorno: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeDeleteLine(InvtDocumentLine, DeleteItemTracking, Blocked, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        InvtDocumentHeader.Get(InvtDocumentLine."Document Type", InvtDocumentLine."Document No.");
        RedStorno := InvtDocumentHeader.Correction;
        case InvtDocumentLine."Document Type" of
            InvtDocumentLine."Document Type"::Receipt:
                begin
                    ReservationManagement.SetReservSource(InvtDocumentLine);
                    if RedStorno or DeleteItemTracking then
                        ReservationManagement.SetItemTrackingHandling(1);
                    // Allow Deletion
                    ReservationManagement.DeleteReservEntries(true, 0);
                    InvtDocumentLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                end;
            InvtDocumentLine."Document Type"::Shipment:
                begin
                    ReservationManagement.SetReservSource(InvtDocumentLine);
                    if RedStorno or DeleteItemTracking then
                        ReservationManagement.SetItemTrackingHandling(1);
                    // Allow Deletion
                    ReservationManagement.DeleteReservEntries(true, 0);
                    InvtDocumentLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                end;
        end;
    end;

    procedure AssignForPlanning(var InvtDocumentLine: Record "Invt. Document Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if InvtDocumentLine."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(
              InvtDocumentLine."Item No.",
              InvtDocumentLine."Variant Code",
              InvtDocumentLine."Location Code",
              InvtDocumentLine."Document Date");
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var InvtDocumentLine: Record "Invt. Document Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        IsInbound: Boolean;
    begin
        IsInbound :=
            ((InvtDocumentLine."Document Type" = InvtDocumentLine."Document Type"::Receipt) and not InvtDocumentLine.IsCorrection()) or
            ((InvtDocumentLine."Document Type" = InvtDocumentLine."Document Type"::Shipment) and InvtDocumentLine.IsCorrection());
        InitFromInvtDocLine(TrackingSpecification, InvtDocumentLine);
        ItemTrackingLines.SetIsInvtDocumentCorrection(InvtDocumentLine.IsCorrection());
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, InvtDocumentLine."Document Date");
        ItemTrackingLines.SetInbound(IsInbound);
        ItemTrackingLines.RunModal();
    end;

    procedure CallItemTracking2(var InvtDocumentLine: Record "Invt. Document Line"; var SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        InitFromInvtDocLine(TrackingSpecification, InvtDocumentLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, InvtDocumentLine."Document Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        ItemTrackingLines.RunModal();
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; ReservEntry: Record "Reservation Entry")
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(InvtDocumentLine);
            InvtDocumentLine.Find();
            QtyPerUOM := InvtDocumentLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        SourceRecordRef.SetTable(InvtDocumentLine);
        ReservationEntry.SetSource(
          Database::"Invt. Document Line", InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.", InvtDocumentLine."Line No.", '', 0);

        ReservationEntry."Item No." := InvtDocumentLine."Item No.";
        ReservationEntry."Variant Code" := InvtDocumentLine."Variant Code";
        ReservationEntry."Location Code" := InvtDocumentLine."Location Code";
        if ReservationEntry."Source Subtype" = 0 then
            ReservationEntry."Expected Receipt Date" := InvtDocumentLine."Document Date"
        else
            ReservationEntry."Shipment Date" := InvtDocumentLine."Document Date";

        CaptionText := InvtDocumentLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit("Reservation Summary Type"::"Inventory Receipt".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        if not (EntryNo in ["Reservation Summary Type"::"Inventory Receipt".AsInteger(),
                            "Reservation Summary Type"::"Inventory Shipment".AsInteger()])
        then
            exit(false);

        GetInvtSetup();
        exit(InventorySetup."Allow Invt. Doc. Reservation");
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        if TableID <> Database::"Invt. Document Line" then
            exit(false);

        GetInvtSetup();
        exit(InventorySetup."Allow Invt. Doc. Reservation");
    end;

    local procedure GetInvtSetup()
    begin
        if InvtSetupRead then
            exit;

        InventorySetup.Get();
        InvtSetupRead := true;
    end;

    procedure DeleteLineConfirm(var InvtDocumentLine: Record "Invt. Document Line"): Boolean
    begin

        if not InvtDocumentLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(InvtDocumentLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        AvailableInvtDocumentLines: page "Available - Invt. Doc. Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableInvtDocumentLines);
            AvailableInvtDocumentLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableInvtDocumentLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Invt. Document Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Invt. Document Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Ledger Entry-Reserve", 'OnDrillDownTotalQuantityElseCase', '', false, false)]
    local procedure OnDrillDownTotalQuantityElseCase(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        CreatePick: Codeunit "Create Pick";
        AvailableItemLedgEntries: page "Available - Item Ledg. Entries";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            AvailableItemLedgEntries.SetSource(SourceRecRef, ReservEntry, Enum::"Transfer Direction".FromInteger(ReservEntry."Source Subtype"));
            if Location."Bin Mandatory" or Location."Require Pick" then
                AvailableItemLedgEntries.SetTotalAvailQty(
                    EntrySummary."Total Available Quantity" +
                    CreatePick.CheckOutBound(
                    ReservEntry."Source Type", ReservEntry."Source Subtype",
                    ReservEntry."Source ID", ReservEntry."Source Ref. No.",
                    ReservEntry."Source Prod. Order Line"))
            else
                AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
            AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
            AvailableItemLedgEntries.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(InvtDocumentLine);
            CreateReservation(InvtDocumentLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        InvtDocHeader: Record "Invt. Document Header";
    begin
        if MatchThisTable(SourceType) then begin
            InvtDocHeader.Reset();
            InvtDocHeader.SetRange("Document Type", SourceSubtype);
            InvtDocHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Invt. Receipt", InvtDocHeader);
                1:
                    PAGE.RunModal(PAGE::"Invt. Shipment", InvtDocHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(SourceType) then begin
            InvtDocumentLine.Reset();
            InvtDocumentLine.SetRange("Document Type", SourceSubtype);
            InvtDocumentLine.SetRange("Document No.", SourceID);
            InvtDocumentLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, InvtDocumentLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(InvtDocumentLine);
            InvtDocumentLine.SetReservationFilters(ReservEntry);
            CaptionText := InvtDocumentLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(InvtDocumentLine);
            InvtDocumentLine.GetRemainingQty(RemainingQty, RemainingQtyBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        InvtDocumentLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(InvtDocumentLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(InvtDocumentLine."Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(InvtDocumentLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Integer; Positive: Boolean; var TotalQuantity: Decimal)
    var
        InvtDocumentLine: Record "Invt. Document Line";
        AvailabilityFilter: Text;
    begin
        if not InvtDocumentLine.ReadPermission() then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        case DocumentType of
            0:
                InvtDocumentLine.FilterShipmentLinesForReservation(ReservationEntry, AvailabilityFilter, Positive);
            1:
                InvtDocumentLine.FilterReceiptLinesForReservation(ReservationEntry, AvailabilityFilter, Positive);
        end;

        if InvtDocumentLine.FindSet() then
            repeat
                case DocumentType of
                    0:
                        begin
                            InvtDocumentLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" -= InvtDocumentLine."Reserved Qty. Outbnd. (Base)";
                            TotalQuantity -= InvtDocumentLine."Quantity (Base)";
                        end;
                    1:
                        begin
                            InvtDocumentLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" += InvtDocumentLine."Reserved Qty. Inbnd. (Base)";
                            TotalQuantity += InvtDocumentLine."Quantity (Base)";
                        end;
                end;
            until InvtDocumentLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity > 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"Invt. Document Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(
                    StrSubstNo(SummaryTypeTxt, InvtDocumentLine.TableCaption(), SelectStr(DocumentType + 1, DirectionTxt)),
                    1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" :=
                TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if MatchThisEntry(ReservSummEntry."Entry No.") then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - EntryStartNo(), Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if ReservationEntry."Source Type" = Database::"Invt. Document Line" then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        InvtDocumentLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        InvtDocumentLine.SetRange("Document No.", ReservationEntry."Source ID");
        InvtDocumentLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"Invt. Document Lines", InvtDocumentLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterAutoReserveOneLine', '', false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean; var sender: Codeunit "Reservation Management")
    begin
        if MatchThisEntry(ReservSummEntryNo) then
            AutoInvtDocLineReserve(
                CalcReservEntry, sender, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase,
                Description, AvailabilityDate, Search, NextStep, Positive);
    end;

    local procedure AutoInvtDocLineReserve(var CalcReservEntry: Record "Reservation Entry"; var sender: Codeunit "Reservation Management"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; Positive: Boolean)
    var
        CallTrackingSpecification: Record "Tracking Specification";
        InvtDocLine: Record "Invt. Document Line";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
    begin
        case ReservSummEntryNo of
            Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger():
                InvtDocLine.FilterReceiptLinesForReservation(CalcReservEntry, sender.GetAvailabilityFilter(AvailabilityDate), Positive);
            Enum::"Reservation Summary Type"::"Inventory Shipment".AsInteger():
                InvtDocLine.FilterShipmentLinesForReservation(CalcReservEntry, sender.GetAvailabilityFilter(AvailabilityDate), Positive);
        end;

        if InvtDocLine.Find(Search) then
            repeat
                case ReservSummEntryNo of
                    Enum::"Reservation Summary Type"::"Inventory Shipment".AsInteger():
                        begin
                            InvtDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            QtyThisLine := -InvtDocLine.Quantity;
                            QtyThisLineBase := -InvtDocLine."Quantity (Base)";
                            ReservQty := -InvtDocLine."Reserved Qty. Outbnd. (Base)";
                            if Positive = (QtyThisLine < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                        end;
                    Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger():
                        begin
                            InvtDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            QtyThisLine := InvtDocLine.Quantity;
                            QtyThisLineBase := InvtDocLine."Quantity (Base)";
                            ReservQty := InvtDocLine."Reserved Qty. Inbnd. (Base)";
                            if Positive = (QtyThisLine < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                        end;
                end;
                if QtyThisLine <> 0 then
                    if Abs(QtyThisLine - ReservQty) > 0 then begin
                        if Abs(QtyThisLine - ReservQty) > Abs(RemainingQtyToReserve) then begin
                            QtyThisLine := RemainingQtyToReserve;
                            QtyThisLineBase := RemainingQtyToReserveBase;
                        end else begin
                            QtyThisLineBase := QtyThisLineBase - ReservQty;
                            QtyThisLine := Round(RemainingQtyToReserve / RemainingQtyToReserveBase * QtyThisLineBase, UOMMgt.QtyRndPrecision());
                        end;

                        sender.CopySign(RemainingQtyToReserve, QtyThisLine);
                        sender.CopySign(RemainingQtyToReserveBase, QtyThisLineBase);

                        CallTrackingSpecification.InitTrackingSpecification(
                          Database::"Invt. Document Line", ReservSummEntryNo - Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger(),
                          InvtDocLine."Document No.", '', 0, InvtDocLine."Line No.", InvtDocLine."Variant Code", InvtDocLine."Location Code", InvtDocLine."Qty. per Unit of Measure");
                        CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                        sender.CreateReservation(Description, InvtDocLine."Posting Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);

                        RemainingQtyToReserve := RemainingQtyToReserve - QtyThisLine;
                        RemainingQtyToReserveBase := RemainingQtyToReserveBase - QtyThisLineBase;
                    end;
            until (InvtDocLine.Next(NextStep) = 0) or (RemainingQtyToReserve = 0);
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Invt. Document Line" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[6] := true;  // RefNo
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text)
    begin
        if ReservationEntry."Source Type" = Database::"Invt. Document Line" then
            Description :=
                StrSubstNo(
                    SourceDoc3Txt, InventoryTxt,
                    Enum::"Invt. Doc. Document Type".FromInteger(ReservationEntry."Source Subtype"), ReservationEntry."Source ID");
    end;

    procedure InitFromInvtDocLine(var TrackingSpecification: Record "Tracking Specification"; var InvtDocLine: Record "Invt. Document Line")
    var
        QtySignFactor: Integer;
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
            InvtDocLine."Item No.", InvtDocLine.Description, InvtDocLine."Location Code", InvtDocLine."Variant Code",
            InvtDocLine."Bin Code", InvtDocLine."Qty. per Unit of Measure", InvtDocLine."Qty. Rounding Precision (Base)");
        TrackingSpecification.SetSource(
            Database::"Invt. Document Line", InvtDocLine."Document Type".AsInteger(), InvtDocLine."Document No.", InvtDocLine."Line No.", '', 0);

        QtySignFactor := 1;
        if InvtDocLine.IsCorrection() then
            QtySignFactor := -1;

        TrackingSpecification.SetQuantities(
          InvtDocLine."Quantity (Base)" * QtySignFactor, InvtDocLine.Quantity * QtySignFactor, InvtDocLine."Quantity (Base)" * QtySignFactor,
          InvtDocLine.Quantity * QtySignFactor, InvtDocLine."Quantity (Base)" * QtySignFactor, 0, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnBeforeCheckApplyFromItemEntrySourceType', '', false, false)]
    local procedure OnBeforeCheckApplyFromItemEntrySourceType(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
        if not MatchThisTable(TrackingSpecification."Source Type") then
            exit;

        if ((TrackingSpecification."Source Subtype" in [1, 3, 4, 5]) and (TrackingSpecification."Quantity (Base)" > 0)) or
            ((TrackingSpecification."Source Subtype" in [0, 2, 6]) and (TrackingSpecification."Quantity (Base)" < 0))
        then
            TrackingSpecification.FieldError("Quantity (Base)");

        IsHandled := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewInvtDocumentLine: Record "Invt. Document Line"; var OldInvtDocumentLine: Record "Invt. Document Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLine(var InvtDocumentLine: Record "Invt. Document Line"; DeleteItemTracking: Boolean; Blocked: Boolean; var IsHandled: Boolean)
    begin
    end;
}

