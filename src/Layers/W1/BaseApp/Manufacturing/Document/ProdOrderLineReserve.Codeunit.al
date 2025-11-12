// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;

codeunit 99000837 "Prod. Order Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Prod. Order Line" = rimd,
                  TableData "Prod. Order Component" = rimd,
                  TableData "Action Message Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";
        Blocked: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Reserved quantity cannot be greater than %1';
#pragma warning restore AA0470
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';
#pragma warning disable AA0470
        Text006: Label 'The %1 %2 %3 has item tracking. Do you want to delete it anyway?';
        Text007: Label 'The %1 %2 %3 has components with item tracking. Do you want to delete it anyway?';
        Text008: Label 'The %1 %2 %3 and its components have item tracking. Do you want to delete them anyway?';
        Text010: Label 'Firm Planned %1';
        Text011: Label 'Released %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DeleteProdOrderLineWithItemReservQst: Label '%1 production order %2 has item reservation. Do you want to delete it anyway?', Comment = '%1 = Status, %2 = Prod. Order No.';
        SourceDoc3Txt: Label '%1 %2 %3', Locked = true;

    procedure CreateReservation(var ProdOrderLine: Record "Prod. Order Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004);

        ProdOrderLine.TestField("Item No.");
        ProdOrderLine.TestField("Due Date");

        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ProdOrderLine."Remaining Qty. (Base)") < Abs(ProdOrderLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ProdOrderLine."Remaining Qty. (Base)") - Abs(ProdOrderLine."Reserved Qty. (Base)"));

        ProdOrderLine.TestField("Location Code", FromTrackingSpecification."Location Code");
        ProdOrderLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        if QuantityBase < 0 then
            ShipmentDate := ProdOrderLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ProdOrderLine."Due Date";
        end;

        if ProdOrderLine."Planning Flexibility" <> ProdOrderLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(ProdOrderLine."Planning Flexibility");

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(ProdOrderLine, Quantity, QuantityBase, ForReservationEntry, FromTrackingSpecification, IsHandled, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(),
                ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
                ProdOrderLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
            ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure Caption(ProdOrderLine: Record "Prod. Order Line") CaptionText: Text
    begin
        CaptionText := ProdOrderLine.GetSourceCaption();
    end;

    procedure FindReservEntry(ProdOrderLine: Record "Prod. Order Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ProdOrderLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure VerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if NewProdOrderLine.Status = NewProdOrderLine.Status::Finished then
            exit;
        if Blocked then
            exit;
        if NewProdOrderLine."Line No." = 0 then
            if not ProdOrderLine.Get(
                 NewProdOrderLine.Status,
                 NewProdOrderLine."Prod. Order No.",
                 NewProdOrderLine."Line No.")
            then
                exit;

        NewProdOrderLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewProdOrderLine."Reserved Qty. (Base)" <> 0;

        if NewProdOrderLine."Due Date" = 0D then
            if ShowError then
                NewProdOrderLine.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewProdOrderLine."Item No." <> OldProdOrderLine."Item No." then
            if ShowError then
                NewProdOrderLine.FieldError("Item No.", Text003)
            else
                HasError := true;
        if NewProdOrderLine."Location Code" <> OldProdOrderLine."Location Code" then
            if ShowError then
                NewProdOrderLine.FieldError("Location Code", Text003)
            else
                HasError := true;
        if NewProdOrderLine."Variant Code" <> OldProdOrderLine."Variant Code" then
            if ShowError then
                NewProdOrderLine.FieldError("Variant Code", Text003)
            else
                HasError := true;
        if NewProdOrderLine."Line No." <> OldProdOrderLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewProdOrderLine, OldProdOrderLine, HasError, ShowError);

        if HasError then
            if (NewProdOrderLine."Item No." <> OldProdOrderLine."Item No.") or NewProdOrderLine.ReservEntryExist() then begin
                if NewProdOrderLine."Item No." <> OldProdOrderLine."Item No." then begin
                    ReservationManagement.SetReservSource(OldProdOrderLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewProdOrderLine);
                end else begin
                    ReservationManagement.SetReservSource(NewProdOrderLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewProdOrderLine."Remaining Qty. (Base)");
            end;

        if HasError or (NewProdOrderLine."Due Date" <> OldProdOrderLine."Due Date")
        then begin
            AssignForPlanning(NewProdOrderLine);
            if (NewProdOrderLine."Item No." <> OldProdOrderLine."Item No.") or
               (NewProdOrderLine."Variant Code" <> OldProdOrderLine."Variant Code") or
               (NewProdOrderLine."Location Code" <> OldProdOrderLine."Location Code")
            then
                AssignForPlanning(OldProdOrderLine);
        end;
    end;

    procedure VerifyQuantity(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if Blocked then
            exit;

        if NewProdOrderLine.Status = NewProdOrderLine.Status::Finished then
            exit;
        if NewProdOrderLine."Line No." = OldProdOrderLine."Line No." then
            if NewProdOrderLine."Quantity (Base)" = OldProdOrderLine."Quantity (Base)" then
                exit;
        if NewProdOrderLine."Line No." = 0 then
            if not ProdOrderLine.Get(NewProdOrderLine.Status, NewProdOrderLine."Prod. Order No.", NewProdOrderLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewProdOrderLine);
        if NewProdOrderLine."Qty. per Unit of Measure" <> OldProdOrderLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        ReservationManagement.DeleteReservEntries(false, NewProdOrderLine."Remaining Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewProdOrderLine."Remaining Qty. (Base)");
        AssignForPlanning(NewProdOrderLine);
    end;

    procedure UpdatePlanningFlexibility(var ProdOrderLine: Record "Prod. Order Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(ProdOrderLine, ReservationEntry) then
            ReservationEntry.ModifyAll("Planning Flexibility", ProdOrderLine."Planning Flexibility");
    end;

    procedure TransferPOLineToPOLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewProdOrderLine: Record "Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        OnBeforeTransferPOLineToPOLine(OldProdOrderLine, NewProdOrderLine);

        if not FindReservEntry(OldProdOrderLine, OldReservationEntry) then
            exit;

        if NeedUpdateReservationStatusForProdOrderLine(OldReservationEntry."Source Type", NewProdOrderLine.Status.AsInteger(), OldReservationEntry."Reservation Status") then
            if OldReservationEntry."Source Subtype" = OldReservationEntry."Source Subtype"::"1" then begin
                OldReservationEntry."Reservation Status" := OldReservationEntry."Reservation Status"::Surplus;
                OldReservationEntry.Modify();
            end;

        OldReservationEntry.Lock();

        NewProdOrderLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        OldReservationEntry.TransferReservations(
            OldReservationEntry, OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code",
            TransferAll, TransferQty, NewProdOrderLine."Qty. per Unit of Measure",
            Database::"Prod. Order Line", NewProdOrderLine.Status.AsInteger(), NewProdOrderLine."Prod. Order No.", '', NewProdOrderLine."Line No.", 0);
    end;

    procedure TransferPOLineToItemJnlLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        IsHandled: Boolean;
    begin
        if not FindReservEntry(OldProdOrderLine, OldReservationEntry) then
            exit;

        OnTransferPOLineToItemJnlLineOnBeforeHandleItemTrackingOutput(OldProdOrderLine, NewItemJournalLine, OldReservationEntry, IsHandled);
        if IsHandled then
            exit;

        // Handle Item Tracking on output:
        Clear(CreateReservEntry);
        SetTrackingFilterFromItemJnlLine(OldReservationEntry, NewItemJournalLine, ItemTrackingFilterIsSet);

        IsHandled := false;
        OnTransferPOLineToItemJnlLineOnBeforeTestItemJnlLineFields(NewItemJournalLine, OldProdOrderLine, IsHandled);
        if not IsHandled then
            NewItemJournalLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then
            repeat
                SetNewTrackingFromItemJnlLine(NewItemJournalLine, OldReservationEntry);
                OldReservationEntry.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

                TransferPOLineToItemJnlLineReservEntry(OldProdOrderLine, NewItemJournalLine, OldReservationEntry, TransferQty);

                EndLoop := TransferQty = 0;
                if not EndLoop then
                    if ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0 then
                        if ItemTrackingFilterIsSet then begin
                            OldReservationEntry.ClearTrackingFilter();
                            ItemTrackingFilterIsSet := false;
                            EndLoop := not ReservationEngineMgt.InitRecordSet(OldReservationEntry);
                        end else
                            EndLoop := true;
            until EndLoop;
    end;


    local procedure SetNewTrackingFromItemJnlLine(var NewItemJournalLine: Record "Item Journal Line"; OldReservationEntry: Record "Reservation Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNewTrackingFromItemJnlLine(CreateReservEntry, NewItemJournalLine, OldReservationEntry, IsHandled);
        if IsHandled then
            exit;

        if NewItemJournalLine.TrackingExists() then
            CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJournalLine);
    end;

    local procedure SetTrackingFilterFromItemJnlLine(var OldReservationEntry: Record "Reservation Entry"; var NewItemJournalLine: Record "Item Journal Line"; var ItemTrackingFilterIsSet: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackingFilterFromItemJnlLine(OldReservationEntry, NewItemJournalLine, ItemTrackingFilterIsSet, IsHandled);
        if IsHandled then
            exit;

        if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::Output then
            if NewItemJournalLine.TrackingExists() then begin
                // Try to match against Item Tracking on the prod. order line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(NewItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    OldReservationEntry.ClearTrackingFilter()
                else
                    ItemTrackingFilterIsSet := true;
            end;
    end;

    local procedure TransferPOLineToItemJnlLineReservEntry(ProdOrderLine: Record "Prod. Order Line"; ItemJournalLine: Record "Item Journal Line"; OldReservationEntry: Record "Reservation Entry"; var TransferQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPOLineToItemJnlLineReservEntry(OldReservationEntry, ProdOrderLine, ItemJournalLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TransferQty :=
            CreateReservEntry.TransferReservEntry(
                DATABASE::"Item Journal Line",
                ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", 0,
                ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);
    end;

    procedure DeleteLineConfirm(var ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
        ConfirmMessage: Text[250];
        HasItemTracking: Option "None",Line,Components,"Line and Components";
    begin
        ProdOrderLine.SetReservationFilters(ReservationEntry);

        ReservationEntry.SetFilter("Item Tracking", '<> %1', ReservationEntry."Item Tracking"::None);
        if not ReservationEntry.IsEmpty() then
            HasItemTracking := HasItemTracking::Line;

        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        ReservationEntry.SetFilter("Source Ref. No.", ' > %1', 0);
        if not ReservationEntry.IsEmpty() then
            if HasItemTracking = HasItemTracking::Line then
                HasItemTracking := HasItemTracking::"Line and Components"
            else
                HasItemTracking := HasItemTracking::Components;

        if HasItemTracking = HasItemTracking::None then
            exit(true);

        case HasItemTracking of
            HasItemTracking::Line:
                ConfirmMessage := Text006;
            HasItemTracking::Components:
                ConfirmMessage := Text007;
            HasItemTracking::"Line and Components":
                ConfirmMessage := Text008;
        end;

        if not Confirm(ConfirmMessage, false, ProdOrderLine.Status, ProdOrderLine.TableCaption(), ProdOrderLine."Line No.") then
            exit(false);

        ReservationEntry.SetFilter(ReservationEntry."Source Type", '%1|%2', Database::"Prod. Order Line", Database::"Prod. Order Component");
        ReservationEntry.SetRange(ReservationEntry."Source Ref. No.");
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry2 := ReservationEntry;
                ReservationEntry2.ClearItemTrackingFields();
                ReservationEntry2.Modify();
                OnDeleteLineConfirmOnAfterReservEntry2Modify(ReservationEntry);
            until ReservationEntry.Next() = 0;

        exit(true);
    end;

    procedure DeleteLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        if Blocked then
            exit;

        ReservationManagement.SetReservSource(ProdOrderLine);
        ReservationManagement.DeleteReservEntries(true, 0);
        OnDeleteLineOnAfterDeleteReservEntries(ProdOrderLine);
        ReservationManagement.ClearActionMessageReferences();
        ProdOrderLine.CalcFields(ProdOrderLine."Reserved Qty. (Base)");
        AssignForPlanning(ProdOrderLine);
    end;

    procedure AssignForPlanning(var ProdOrderLine: Record "Prod. Order Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ProdOrderLine.Status = ProdOrderLine.Status::Simulated then
            exit;
        if ProdOrderLine."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code", WorkDate());
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ProdOrderLine: Record "Prod. Order Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        MfgItemTrackingMgt: Codeunit "Mfg. Item Tracking Mgt.";
        ItemTrackingLines: Page "Item Tracking Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallItemTracking(ProdOrderLine, IsHandled);
        if not IsHandled then
            if ProdOrderLine.Status = ProdOrderLine.Status::Finished then
                MfgItemTrackingMgt.ShowItemTrackingForProdOrderComp(
                    Database::"Prod. Order Line", ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0)
            else begin
                ProdOrderLine.TestField("Item No.");
                InitFromProdOrderLine(TrackingSpecification, ProdOrderLine);
                ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderLine."Due Date");
                ItemTrackingLines.SetInbound(ProdOrderLine.IsInbound());
                OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ProdOrderLine, ItemTrackingLines);
                ItemTrackingLines.RunModal();
            end;

        OnAfterCallItemTracking(ProdOrderLine);
    end;

    procedure UpdateItemTrackingAfterPosting(ProdOrderLine: Record "Prod. Order Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservationEntry.SetSourceFilter(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", -1, true);
        ReservationEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderLine);
            ProdOrderLine.Find();
            QtyPerUOM := ProdOrderLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SourceRecordRef.SetTable(ProdOrderLine);
        ProdOrderLine.TestField("Due Date");

        ProdOrderLine.SetReservationEntry(ReservationEntry);

        CaptionText := ProdOrderLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger(),
                         Enum::"Reservation Summary Type"::"Planned Production Order".AsInteger(),
                         Enum::"Reservation Summary Type"::"Firm Planned Production Order".AsInteger(),
                         Enum::"Reservation Summary Type"::"Released Production Order".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Prod. Order Line");
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure ReservationOnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure ReservationOnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        AvailableProdOrderLines: page "Available - Prod. Order Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableProdOrderLines);
            AvailableProdOrderLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableProdOrderLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableProdOrderLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure ReservationOnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Prod. Order Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure ReservationOnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Prod. Order Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Ledger Entry-Reserve", 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary" temporary; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal; var IsHandled: Boolean; sender: Codeunit "Item Ledger Entry-Reserve")
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            sender.DrillDownTotalQuantity(SourceRecRef, EntrySummary, ReservEntry, MaxQtyToReserve);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ProdOrderLine);
            CreateReservation(ProdOrderLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        if MatchThisTable(SourceType) then begin
            ProdOrder.Reset();
            ProdOrder.SetRange(Status, SourceSubtype);
            ProdOrder.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Simulated Production Order", ProdOrder);
                1:
                    PAGE.RunModal(PAGE::"Planned Production Order", ProdOrder);
                2:
                    PAGE.RunModal(PAGE::"Firm Planned Prod. Order", ProdOrder);
                3:
                    PAGE.RunModal(PAGE::"Released Production Order", ProdOrder);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceProdOrderLine: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(SourceType) then begin
            ProdOrderLine.Reset();
            ProdOrderLine.SetRange(Status, SourceSubtype);
            ProdOrderLine.SetRange("Prod. Order No.", SourceID);
            ProdOrderLine.SetRange("Line No.", SourceProdOrderLine);
            PAGE.Run(0, ProdOrderLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderLine);
            ProdOrderLine.SetReservationFilters(ReservEntry);
            CaptionText := ProdOrderLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ProdOrderLine);
            ProdOrderLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Prod. Order Line");
        SourceRecordRef.GetTable(ProdOrderLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ProdOrderLine."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ProdOrderLine."Quantity (Base)");
        end;
        OnAfterGetSourceValue(ReservationEntry, SourceRecordRef, ReturnOption);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Status: Enum "Production Order Status"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        AvailabilityFilter: Text;
    begin
        if not ProdOrderLine.ReadPermission then
            exit;

        ProdOrderLine.SetAutoCalcFields("Reserved Qty. (Base)");
        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ProdOrderLine.FilterLinesForReservation(ReservationEntry, Status.AsInteger(), AvailabilityFilter, Positive);
        if ProdOrderLine.FindSet() then
            repeat
                TempEntrySummary."Total Reserved Quantity" += ProdOrderLine."Reserved Qty. (Base)";
                TotalQuantity += ProdOrderLine."Remaining Qty. (Base)";
            until ProdOrderLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity > 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"Prod. Order Line";
            if Status = ProdOrderLine.Status::"Firm Planned" then
                TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(Text010, ProdOrderLine.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"))
            else
                TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(Text011, ProdOrderLine.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal; ReservationSummaryType: Integer)
    begin
        if ReservationSummaryType = Enum::"Reservation Summary Type"::"Item Tracking Line".AsInteger() then
            exit;

        if ReservSummEntry."Entry No." in [Enum::"Reservation Summary Type"::"Firm Planned Production Order".AsInteger(),
                                           Enum::"Reservation Summary Type"::"Released Production Order".AsInteger()] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Enum::"Production Order Status".FromInteger(ReservSummEntry."Entry No." - 61), Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ReservationEntry."Source Subtype");
        ProdOrderLine.SetRange("Prod. Order No.", ReservationEntry."Source ID");
        ProdOrderLine.SetRange("Line No.", ReservationEntry."Source Prod. Order Line");
        PAGE.RunModal(Page::"Prod. Order Line List", ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterAutoReserveOneLine', '', false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean; var sender: Codeunit "Reservation Management")
    begin
        if MatchThisEntry(ReservSummEntryNo) then
            AutoReserveProdOrderLine(
                CalcReservEntry, sender, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase,
                Description, AvailabilityDate, Search, NextStep, Positive);
    end;

    local procedure AutoReserveProdOrderLine(var CalcReservEntry: Record "Reservation Entry"; var sender: Codeunit "Reservation Management"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; Positive: Boolean)
    var
        CallTrackingSpecification: Record "Tracking Specification";
        ProdOrderLine: Record "Prod. Order Line";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
#if not CLEAN25
        IsReserved := false;
        sender.RunOnBeforeAutoReserveProdOrderLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;
#endif
        IsReserved := false;
        OnBeforeAutoReserveProdOrderLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        ProdOrderLine.SetAutoCalcFields("Reserved Qty. (Base)");
        ProdOrderLine.FilterLinesForReservation(
            CalcReservEntry, ReservSummEntryNo - Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger(),
            sender.GetAvailabilityFilter(AvailabilityDate), Positive);
        if ProdOrderLine.Find(Search) then
            repeat
                QtyThisLine := ProdOrderLine."Remaining Quantity";
                QtyThisLineBase := ProdOrderLine."Remaining Qty. (Base)";
                ReservQty := ProdOrderLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase < 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                sender.SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, ProdOrderLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                    Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
                    ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                sender.InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, ProdOrderLine."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (ProdOrderLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallItemTracking(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOLineToPOLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTrackingFilterFromItemJnlLine(OldReservEntry: Record "Reservation Entry"; var NewItemJnlLine: Record "Item Journal Line"; var ItemTrackingFilterIsSet: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNewTrackingFromItemJnlLine(var CreateReservEntry: Codeunit "Create Reserv. Entry"; var NewItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOLineToItemJnlLineReservEntry(OldReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line"; ItemJnlLine: Record "Item Journal Line"; var TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnAfterDeleteReservEntries(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOLineToItemJnlLineOnBeforeHandleItemTrackingOutput(var OldProdOrderLine: Record "Prod. Order Line"; var NewItemJnlLine: Record "Item Journal Line"; var OldReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOLineToItemJnlLineOnBeforeTestItemJnlLineFields(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewProdOrderLine: Record "Prod. Order Line"; OldProdOrderLine: Record "Prod. Order Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var ProdOrderLine: Record "Prod. Order Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineConfirmOnAfterReservEntry2Modify(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveProdOrderLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var ProdOrderLine: Record "Prod. Order Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ReservationEntry: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean; ExpectedReceiptDate: Date; Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoReserveOnBeforeStopReservation', '', false, false)]
    local procedure OnAutoReserveOnBeforeStopReservation(var CalcReservEntry: Record "Reservation Entry"; var StopReservation: Boolean; SourceRecRef: RecordRef);
    begin
        if MatchThisTable(CalcReservEntry."Source Type") then
            StopReservation := CalcReservEntry."Source Subtype" < 2; // Not simulated or planned
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceForReservationOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;
#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoTrackOnCheckSourceType', '', false, false)]
    local procedure OnAutoTrackOnCheckSourceType(var ReservationEntry: Record "Reservation Entry"; var ShouldExit: Boolean)
    begin
        if ReservationEntry."Source Type" = Database::"Prod. Order Line" then
            if ReservationEntry."Source Subtype" = 0 then
                ShouldExit := true; // Not simulation
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnIssueActionMessageOnSetSourceTypeFromSKU', '', false, false)]
    local procedure OnIssueActionMessageOnSetSourceTypeFromSKU(var ActionMessageEntry: Record "Action Message Entry"; SKU: Record "Stockkeeping Unit")
    begin
        if SKU.IsMfgSKU() then
            ActionMessageEntry."Source Type" := Database::"Prod. Order Line";
    end;

    // codeunit Create Reserv. Entry

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnCheckSourceTypeSubtype', '', false, false)]
    local procedure CheckSourceTypeSubtype(var ReservationEntry: Record "Reservation Entry"; var IsError: Boolean)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            IsError :=
                (ReservationEntry."Source Subtype" = 4) or
                ((ReservationEntry."Source Subtype" = 1) and (ReservationEntry.Binding = ReservationEntry.Binding::" "));
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnRevertDateToSourceDate', '', false, false)]
    local procedure OnRevertDateToSourceDate(var ReservEntry: Record "Reservation Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ReservEntry."Source Type" = Database::"Prod. Order Line" then begin
            ProdOrderLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line");
            ReservEntry."Expected Receipt Date" := ProdOrderLine."Due Date";
            ReservEntry."Shipment Date" := 0D;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Prod. Order Line" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[5] := true;  // ProdOrderLine
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ReservationEntry."Source Type" = Database::"Prod. Order Line" then
            Description :=
                StrSubstNo(SourceDoc3Txt, ProdOrderLine.TableCaption(),
                Enum::"Production Order Status".FromInteger(ReservationEntry."Source Subtype"), ReservationEntry."Source ID");
    end;

    procedure InitFromProdOrderLine(var TrackingSpecification: Record "Tracking Specification"; var ProdOrderLine: Record "Prod. Order Line")
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
            ProdOrderLine."Item No.", ProdOrderLine.Description, ProdOrderLine."Location Code", ProdOrderLine."Variant Code", '',
            ProdOrderLine."Qty. per Unit of Measure", ProdOrderLine."Qty. Rounding Precision (Base)");
        TrackingSpecification.SetSource(
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, '', ProdOrderLine."Line No.");
        TrackingSpecification.SetQuantities(
            ProdOrderLine."Quantity (Base)", ProdOrderLine."Remaining Quantity", ProdOrderLine."Remaining Qty. (Base)",
            ProdOrderLine."Remaining Quantity", ProdOrderLine."Remaining Qty. (Base)", ProdOrderLine."Finished Qty. (Base)",
            ProdOrderLine."Finished Qty. (Base)");

        OnAfterInitFromProdOrderLine(TrackingSpecification, ProdOrderLine);
#if not CLEAN25
        TrackingSpecification.RunOnAfterInitFromProdOrderLine(TrackingSpecification, ProdOrderLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdOrderLine(var TrackingSpecification: Record "Tracking Specification"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSummEntryNo', '', false, false)]
    local procedure OnBeforeSummEntryNo(ReservationEntry: Record "Reservation Entry"; var ReturnValue: Integer)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ReturnValue := Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger() + ReservationEntry."Source Subtype";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnUpdateSourceCost', '', false, false)]
    local procedure ReservationEntryOnUpdateSourceCost(ReservationEntry: Record "Reservation Entry"; UnitCost: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        QtyReserved: Decimal;
    begin
        if MatchThisTable(ReservationEntry."Source Type") then begin
            ProdOrderLine.Get(
                ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Prod. Order Line");
            if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                ProdOrderLine."Unit Cost" :=
                    Round(ProdOrderLine."Unit Cost" / ProdOrderLine."Qty. per Unit of Measure");
            if ProdOrderLine."Quantity (Base)" <> 0 then
                ProdOrderLine."Unit Cost" :=
                    Round(
                        (ProdOrderLine."Unit Cost" * (ProdOrderLine."Quantity (Base)" - QtyReserved) + UnitCost * QtyReserved) /
                         ProdOrderLine."Quantity (Base)", 0.00001);
            if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                ProdOrderLine."Unit Cost" :=
                    Round(ProdOrderLine."Unit Cost" * ProdOrderLine."Qty. per Unit of Measure");
            ProdOrderLine.Validate("Unit Cost");
            ProdOrderLine.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OrderTrackingManagementOnSetSourceRecord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
        SourceRecRef: RecordRef;
    begin
        SourceRecRef.GetTable(SourceRecordVar);
        if MatchThisTable(SourceRecRef.Number) then begin
            ProdOrderLine := SourceRecordVar;
            SetProdOrderLine(ProdOrderLine, ReservationEntry, ItemLedgerEntry2);
        end;
    end;

    local procedure SetProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var ReservEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ReservEntry.InitSortingAndFilters(false);
        ProdOrderLine.SetReservationFilters(ReservEntry);

        if ProdOrderLine."Finished Quantity" <> 0 then begin
            ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
            ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
            ItemLedgerEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
            ItemLedgerEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
            ItemLedgerEntry.SetRange("Item No.", ProdOrderLine."Item No.");
            if ItemLedgerEntry.Find('-') then
                repeat
                    ItemLedgerEntry.Mark(true);
                until ItemLedgerEntry.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnInsertOrderTrackingEntry', '', false, false)]
    local procedure OnInsertOrderTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if OrderTrackingEntry."For Type" = DATABASE::"Prod. Order Line" then
            if ProdOrderLine.Get(OrderTrackingEntry."For Subtype", OrderTrackingEntry."For ID", OrderTrackingEntry."For Prod. Order Line") then
                OrderTrackingEntry."Starting Date" := ProdOrderLine."Starting Date";
        OrderTrackingEntry."Ending Date" := ProdOrderLine."Ending Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnDrillOrdersUpCaseElse', '', false, false)]
    local procedure OnDrillOrdersUpCaseElse(var ReservationEntry3: Record "Reservation Entry"; var ReservationEntry2: Record "Reservation Entry"; SearchUp: Boolean; var ContinueDrillUp: Boolean; var IncludePlanningFilter: Boolean)
    begin
        case ReservationEntry3."Source Type" of
            DATABASE::"Prod. Order Line":
                FiltersForTrackingFromProdOrderLine(ReservationEntry3, ReservationEntry2);
            DATABASE::"Prod. Order Component":
                FiltersForTrackingFromProdOrderComponents(ReservationEntry3, ReservationEntry2);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnDerivePlanningFilterOnSetRequisitionLineFilters', '', false, false)]
    local procedure OnDerivePlanningFilterOnSetRequisitionLineFilters(var ToReservEntry: Record "Reservation Entry"; FilterReqLine: Record "Requisition Line"; var OK: Boolean);
    begin
        case FilterReqLine."Ref. Order Type" of
            FilterReqLine."Ref. Order Type"::"Prod. Order":
                begin
                    ToReservEntry.SetSourceFilter(
                        DATABASE::"Prod. Order Line", FilterReqLine."Ref. Order Status".AsInteger(), FilterReqLine."Ref. Order No.", -1, true);
                    ToReservEntry.SetRange("Source Prod. Order Line", FilterReqLine."Ref. Line No.");
                    OK := ToReservEntry.Find('-');
                end;
        end;
    end;

    local procedure FiltersForTrackingFromProdOrderLine(FromReservationEntry: Record "Reservation Entry"; var ToReservationEntry: Record "Reservation Entry")
    begin
        ToReservationEntry.Reset();
        ToReservationEntry.SetSourceFilter(DATABASE::"Prod. Order Component", FromReservationEntry."Source Subtype", FromReservationEntry."Source ID", -1, true);
        ToReservationEntry.SetSourceFilter(FromReservationEntry."Source Batch Name", FromReservationEntry."Source Ref. No.");
    end;

    local procedure FiltersForTrackingFromProdOrderComponents(FromReservationEntry: Record "Reservation Entry"; var ToReservationEntry: Record "Reservation Entry")
    begin
        ToReservationEntry.Reset();
        ToReservationEntry.SetSourceFilter(DATABASE::"Prod. Order Line", FromReservationEntry."Source Subtype", FromReservationEntry."Source ID", -1, true);
        ToReservationEntry.SetSourceFilter(FromReservationEntry."Source Batch Name", FromReservationEntry."Source Prod. Order Line");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnDerivePlanningFilterOnSetToReservationFilter', '', false, false)]
    local procedure OnDerivePlanningFilterOnSetToReservationFilter(var ToReservEntry: Record "Reservation Entry"; FilterPlanningComponent: Record "Planning Component")
    begin
        case FilterPlanningComponent."Ref. Order Type" of
            FilterPlanningComponent."Ref. Order Type"::"Prod. Order":
                ToReservEntry.SetSourceFilter(
                    DATABASE::"Prod. Order Component", FilterPlanningComponent."Ref. Order Status".AsInteger(),
                    FilterPlanningComponent."Ref. Order No.", FilterPlanningComponent."Line No.", true);
        end;
    end;

    // Inventory Profile

    procedure TransferInventoryProfileFromProdOrderLine(var InventoryProfile: Record "Inventory Profile"; var ProdOrderLine: Record "Prod. Order Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        InventoryProfile.SetSource(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, '', ProdOrderLine."Line No.");
        InventoryProfile."Item No." := ProdOrderLine."Item No.";
        InventoryProfile."Variant Code" := ProdOrderLine."Variant Code";
        InventoryProfile."Location Code" := ProdOrderLine."Location Code";
        InventoryProfile."Bin Code" := ProdOrderLine."Bin Code";
        InventoryProfile."Due Date" := ProdOrderLine."Due Date";
        InventoryProfile."Starting Date" := ProdOrderLine."Starting Date";
        InventoryProfile."Planning Flexibility" := ProdOrderLine."Planning Flexibility";
        InventoryProfile."Planning Level Code" := ProdOrderLine."Planning Level Code";
        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        ProdOrderLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        InventoryProfile."Untracked Quantity" := ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile."Min. Quantity" := ProdOrderLine."Reserved Qty. (Base)" - AutoReservedQty;
        InventoryProfile.Quantity := ProdOrderLine.Quantity;
        InventoryProfile."Remaining Quantity" := ProdOrderLine."Remaining Quantity";
        InventoryProfile."Finished Quantity" := ProdOrderLine."Finished Quantity";
        InventoryProfile."Quantity (Base)" := ProdOrderLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := ProdOrderLine."Remaining Qty. (Base)";
        InventoryProfile."Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" >= 0;

        OnAfterTransferInventoryProfileFromProdOrderLine(InventoryProfile, ProdOrderLine);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromProdOrderLine(InventoryProfile, ProdOrderLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromProdOrderLine(var InventoryProfile: Record "Inventory Profile"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Prod. Order Line" then begin
            ReservationEntry.SetSource(
                Database::"Prod. Order Line", InventoryProfile."Source Order Status", InventoryProfile."Source ID", 0, '',
                InventoryProfile."Source Prod. Order Line");
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Prod. Order Line" then
            case InventoryProfile."Source Order Status" of
                // Simulated,Planned,Firm Planned,Released,Finished
                3:
                    InventoryProfile."Order Priority" := 400;
                // Released
                2:
                    InventoryProfile."Order Priority" := 410;
                // Firm Planned
                1:
                    InventoryProfile."Order Priority" := 420;
            // Planned
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnSetSourceForProdOrderLine', '', false, false)]
    local procedure OnSetSourceForProdOrderLine(SourceRecRef: RecordRef; var CalcReservEntry: Record "Reservation Entry"; var EntryIsPositive: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not MatchThisTable(SourceRecRef.Number) then
            exit;

        SourceRecRef.SetTable(ProdOrderLine);
        ProdOrderLine.SetReservationEntry(CalcReservEntry);
        OnSetProdOrderLineOnBeforeUpdateReservation(CalcReservEntry, ProdOrderLine);
#if not CLEAN26
        ReservationManagement.RunOnSetProdOrderLineOnBeforeUpdateReservation(CalcReservEntry, ProdOrderLine);
#endif
        EntryIsPositive := (ProdOrderLine."Remaining Qty. (Base)" < 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetProdOrderLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetDocumentReservationDeleteQstOnElseCase', '', false, false)]
    local procedure OnGetDocumentReservationDeleteQstOnElseCase(RecRef: RecordRef; FldRef: FieldRef; DocType: Integer; var Question: Text; DocNo: Code[20]; var IsHandled: Boolean)
    begin
        case RecRef.Number of
            Database::"Prod. Order Line":
                begin
                    Question := StrSubstNo(DeleteProdOrderLineWithItemReservQst, SelectStr(DocType + 1, FldRef.OptionCaption), DocNo);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetDefaultDampenerPeriod', '', false, false)]
    local procedure OnGetDefaultDampenerPeriod(var DampenerPeriod: DateFormula)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        DampenerPeriod := InventorySetup."Default Dampener Period";
    end;

    local procedure NeedUpdateReservationStatusForProdOrderLine(SourceType: Integer; SourceSubtype: Option; ReservationStatus: Enum "Reservation Status"): Boolean
    begin
        if (SourceType <> Database::"Prod. Order Line") or (SourceSubtype <> 3) or (ReservationStatus <> ReservationStatus::Prospect) then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)")
    begin
    end;

    procedure TransferPlanningLineToPOLine(var OldRequisitionLine: Record "Requisition Line"; var NewProdOrderLine: Record "Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPlanningLineToPOLine(OldRequisitionLine, NewProdOrderLine, TransferQty, TransferAll, IsHandled);
#if not CLEAN27
        ReqLineReserve.RunOnBeforeTransferPlanningLineToPOLine(OldRequisitionLine, NewProdOrderLine, TransferQty, TransferAll, IsHandled);
#endif
        if IsHandled then
            exit;

        if not ReqLineReserve.FindReservEntry(OldRequisitionLine, OldReservationEntry) then
            exit;

        IsHandled := false;
        OnTransferPlanningLineToPOLineOnBeforeCheckFields(OldRequisitionLine, NewProdOrderLine, TransferQty, TransferAll, IsHandled);
#if not CLEAN27
        ReqLineReserve.RunOnTransferPlanningLineToPOLineOnBeforeCheckFields(OldRequisitionLine, NewProdOrderLine, TransferQty, TransferAll, IsHandled);
#endif
        if not IsHandled then begin
            NewProdOrderLine.TestField("Item No.", OldRequisitionLine."No.");
            NewProdOrderLine.TestField("Variant Code", OldRequisitionLine."Variant Code");
            NewProdOrderLine.TestField("Location Code", OldRequisitionLine."Location Code");
        end;

        OnTransferReqLineToPOLineOnBeforeTransfer(OldReservationEntry, OldRequisitionLine, NewProdOrderLine);
#if not CLEAN27
        ReqLineReserve.RunOnTransferReqLineToPOLineOnBeforeTransfer(OldReservationEntry, OldRequisitionLine, NewProdOrderLine);
#endif

        OldReservationEntry.TransferReservations(
            OldReservationEntry, OldRequisitionLine."No.", OldRequisitionLine."Variant Code", OldRequisitionLine."Location Code",
            TransferAll, TransferQty, NewProdOrderLine."Qty. per Unit of Measure",
            Database::"Prod. Order Line", NewProdOrderLine.Status.AsInteger(), NewProdOrderLine."Prod. Order No.", '', NewProdOrderLine."Line No.", 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPlanningLineToPOLine(var OldRequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record "Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPlanningLineToPOLineOnBeforeCheckFields(var OldRequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record "Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToPOLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Line-Reserve", 'OnSetReservationSourceFilterByRefOrderType', '', false, false)]
    local procedure OnSetReservationSourceFilterByRefOrderType(var RequisitionLine: Record "Requisition Line"; var ReservationEntry: Record "Reservation Entry")
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                begin
                    ReservationEntry.SetSourceFilter(Database::"Prod. Order Line", RequisitionLine."Ref. Order Status".AsInteger(), RequisitionLine."Ref. Order No.", -1, true);
                    ReservationEntry.SetRange("Source Prod. Order Line", RequisitionLine."Ref. Line No.");
                end;
        end;
    end;
}
