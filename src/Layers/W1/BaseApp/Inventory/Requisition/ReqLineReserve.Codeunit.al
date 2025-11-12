// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 99000833 "Req. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rmd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationManagement: Codeunit "Reservation Management";
        Blocked: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Reserved quantity cannot be greater than %1', Comment = '%1 - quantity';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be filled in when a quantity is reserved';
        Text004: Label 'must not be changed when a quantity is reserved';
        Text005: Label 'Codeunit is not initialized correctly.';
#pragma warning restore AA0074
        SourceDoc3Txt: Label '%1 %2 %3', Locked = true;

    procedure CreateReservation(var ReqLine: Record "Requisition Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text005);

        ReqLine.TestField(Type, ReqLine.Type::Item);
        ReqLine.TestField("No.");
        ReqLine.TestField("Due Date");
        ReqLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ReqLine."Quantity (Base)") < Abs(ReqLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ReqLine."Quantity (Base)") - Abs(ReqLine."Reserved Qty. (Base)"));

        ReqLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        ReqLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase < 0 then
            ShipmentDate := ReqLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ReqLine."Due Date";
        end;

        if ReqLine."Planning Flexibility" <> ReqLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(ReqLine."Planning Flexibility");

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(ReqLine, Quantity, QuantityBase, ForReservEntry, IsHandled, FromTrackingSpecification, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
            Database::"Requisition Line", 0,
            ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
            ReqLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
          ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(ReqLine);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure Caption(RequisitionLine: Record "Requisition Line") CaptionText: Text
    begin
        CaptionText := RequisitionLine.GetSourceCaption();
    end;

    procedure FindReservEntry(RequisitionLine: Record "Requisition Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        RequisitionLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure VerifyChange(var NewRequisitionLine: Record "Requisition Line"; var OldRequisitionLine: Record "Requisition Line")
    var
        RequisitionLine: Record "Requisition Line";
        ShowError: Boolean;
        HasError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewRequisitionLine, OldRequisitionLine, IsHandled);
        if IsHandled then
            exit;

        if (NewRequisitionLine.Type <> NewRequisitionLine.Type::Item) and (OldRequisitionLine.Type <> OldRequisitionLine.Type::Item) then
            exit;
        if Blocked then
            exit;
        if NewRequisitionLine."Line No." = 0 then
            if not RequisitionLine.Get(NewRequisitionLine."Worksheet Template Name", NewRequisitionLine."Journal Batch Name", NewRequisitionLine."Line No.")
            then
                exit;

        NewRequisitionLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewRequisitionLine."Reserved Qty. (Base)" <> 0;

        if NewRequisitionLine."Due Date" = 0D then
            if ShowError then
                NewRequisitionLine.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewRequisitionLine."Sales Order No." <> '' then
            if ShowError then
                NewRequisitionLine.FieldError("Sales Order No.", Text003)
            else
                HasError := true;

        if NewRequisitionLine."Sales Order Line No." <> 0 then
            if ShowError then
                NewRequisitionLine.FieldError("Sales Order Line No.", Text003)
            else
                HasError := true;

        CheckSellToCustomerNo(NewRequisitionLine, OldRequisitionLine, ShowError, HasError);

        if NewRequisitionLine."Variant Code" <> OldRequisitionLine."Variant Code" then
            if ShowError then
                NewRequisitionLine.FieldError("Variant Code", Text004)
            else
                HasError := true;

        if NewRequisitionLine."No." <> OldRequisitionLine."No." then
            if ShowError then
                NewRequisitionLine.FieldError("No.", Text004)
            else
                HasError := true;

        if NewRequisitionLine."Location Code" <> OldRequisitionLine."Location Code" then
            if ShowError then
                NewRequisitionLine.FieldError("Location Code", Text004)
            else
                HasError := true;

        VerifyBinInReqLine(NewRequisitionLine, OldRequisitionLine, HasError);

        OnVerifyChangeOnBeforeHasError(NewRequisitionLine, OldRequisitionLine, HasError, ShowError);

        if HasError then
            if (NewRequisitionLine."No." <> OldRequisitionLine."No.") or NewRequisitionLine.ReservEntryExist() then begin
                if NewRequisitionLine."No." <> OldRequisitionLine."No." then begin
                    ReservationManagement.SetReservSource(OldRequisitionLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewRequisitionLine);
                end else begin
                    ReservationManagement.SetReservSource(NewRequisitionLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewRequisitionLine."Quantity (Base)");
            end;

        if HasError or (NewRequisitionLine."Due Date" <> OldRequisitionLine."Due Date") then begin
            AssignForPlanning(NewRequisitionLine);
            if (NewRequisitionLine."No." <> OldRequisitionLine."No.") or
               (NewRequisitionLine."Variant Code" <> OldRequisitionLine."Variant Code") or
               (NewRequisitionLine."Location Code" <> OldRequisitionLine."Location Code")
            then
                AssignForPlanning(OldRequisitionLine);
        end;
    end;

    local procedure CheckSellToCustomerNo(var NewRequisitionLine: Record "Requisition Line"; var OldRequisitionLine: Record "Requisition Line"; ShowError: Boolean; var HasError: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSellToCustomerNo(NewRequisitionLine, OldRequisitionLine, ShowError, HasError, IsHandled);
        if IsHandled then
            exit;

        if NewRequisitionLine."Sell-to Customer No." <> '' then
            if ShowError then
                NewRequisitionLine.FieldError("Sell-to Customer No.", Text003)
            else
                HasError := true;
    end;

    procedure VerifyQuantity(var NewRequisitionLine: Record "Requisition Line"; var OldRequisitionLine: Record "Requisition Line")
    var
        RequisitionLine: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewRequisitionLine, OldRequisitionLine, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        if NewRequisitionLine."Line No." = OldRequisitionLine."Line No." then
            if NewRequisitionLine."Quantity (Base)" = OldRequisitionLine."Quantity (Base)" then
                exit;
        if NewRequisitionLine."Line No." = 0 then
            if not RequisitionLine.Get(NewRequisitionLine."Worksheet Template Name", NewRequisitionLine."Journal Batch Name", NewRequisitionLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewRequisitionLine);
        if NewRequisitionLine."Qty. per Unit of Measure" <> OldRequisitionLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewRequisitionLine."Quantity (Base)" * OldRequisitionLine."Quantity (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewRequisitionLine."Quantity (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewRequisitionLine."Quantity (Base)");
        AssignForPlanning(NewRequisitionLine);
    end;

    procedure UpdatePlanningFlexibility(var RequisitionLine: Record "Requisition Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(RequisitionLine, ReservationEntry) then
            ReservationEntry.ModifyAll("Planning Flexibility", RequisitionLine."Planning Flexibility");
    end;

    procedure TransferReqLineToReqLine(var OldRequisitionLine: Record "Requisition Line"; var NewRequisitionLine: Record "Requisition Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldRequisitionLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewRequisitionLine.TestField("No.", OldRequisitionLine."No.");
        NewRequisitionLine.TestField("Variant Code", OldRequisitionLine."Variant Code");
        NewRequisitionLine.TestField("Location Code", OldRequisitionLine."Location Code");

        OnTransferReqLineToReqLineOnBeforeTransfer(OldReservationEntry, OldRequisitionLine, NewRequisitionLine);

        if TransferAll then begin
            OldReservationEntry.SetRange("Source Subtype", 0);
            OldReservationEntry.TransferReservations(
              OldReservationEntry, OldRequisitionLine."No.", OldRequisitionLine."Variant Code", OldRequisitionLine."Location Code",
              TransferAll, TransferQty, NewRequisitionLine."Qty. per Unit of Measure",
              Database::"Requisition Line", 0, NewRequisitionLine."Worksheet Template Name", NewRequisitionLine."Journal Batch Name", 0, NewRequisitionLine."Line No.");

            if OldRequisitionLine."Ref. Order Type" <> OldRequisitionLine."Ref. Order Type"::Transfer then
                exit;

            if NewRequisitionLine."Order Promising ID" <> '' then begin
                OldReservationEntry.SetSourceFilter(
                  Database::"Sales Line", NewRequisitionLine."Order Promising Line No.", NewRequisitionLine."Order Promising ID",
                  NewRequisitionLine."Order Promising Line ID", false);
                OldReservationEntry.SetRange("Source Batch Name", '');
            end;
            OldReservationEntry.SetRange("Source Subtype", 1);
            if OldReservationEntry.FindSet() then begin
                OldReservationEntry.TestField("Qty. per Unit of Measure", NewRequisitionLine."Qty. per Unit of Measure");
                repeat
                    OldReservationEntry.TestField("Item No.", OldRequisitionLine."No.");
                    OldReservationEntry.TestField("Variant Code", OldRequisitionLine."Variant Code");
                    if NewRequisitionLine."Order Promising ID" = '' then
                        OldReservationEntry.TestField("Location Code", OldRequisitionLine."Transfer-from Code");

                    NewReservationEntry := OldReservationEntry;
                    NewReservationEntry."Source ID" := NewRequisitionLine."Worksheet Template Name";
                    NewReservationEntry."Source Batch Name" := NewRequisitionLine."Journal Batch Name";
                    NewReservationEntry."Source Prod. Order Line" := 0;
                    NewReservationEntry."Source Ref. No." := NewRequisitionLine."Line No.";

                    NewReservationEntry.UpdateActionMessageEntries(OldReservationEntry);
                until OldReservationEntry.Next() = 0;
            end;
        end else
            OldReservationEntry.TransferReservations(
              OldReservationEntry, OldRequisitionLine."No.", OldRequisitionLine."Variant Code", OldRequisitionLine."Location Code",
              TransferAll, TransferQty, NewRequisitionLine."Qty. per Unit of Measure",
              Database::"Requisition Line", 0, NewRequisitionLine."Worksheet Template Name", NewRequisitionLine."Journal Batch Name", 0, NewRequisitionLine."Line No.");
    end;

    procedure TransferReqLineToPurchLine(var OldRequisitionLine: Record "Requisition Line"; var PurchaseLine: Record "Purchase Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldRequisitionLine, OldReservationEntry) then
            exit;

        PurchaseLine.TestField("No.", OldRequisitionLine."No.");
        PurchaseLine.TestField("Variant Code", OldRequisitionLine."Variant Code");
        PurchaseLine.TestField("Location Code", OldRequisitionLine."Location Code");

        OnTransferReqLineToPurchLineOnBeforeTransfer(OldReservationEntry, OldRequisitionLine, PurchaseLine);

        OldReservationEntry.TransferReservations(
          OldReservationEntry, OldRequisitionLine."No.", OldRequisitionLine."Variant Code", OldRequisitionLine."Location Code",
          TransferAll, TransferQty, PurchaseLine."Qty. per Unit of Measure",
          Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.");
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit ProdOrderLineReserve', '27.0')]
    procedure TransferPlanningLineToPOLine(var OldRequisitionLine: Record "Requisition Line"; var NewProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        ProdOrderLineReserve: Codeunit Microsoft.Manufacturing.Document."Prod. Order Line-Reserve";
    begin
        ProdOrderLineReserve.TransferPlanningLineToPOLine(OldRequisitionLine, NewProdOrderLine, TransferQty, TransferAll);
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit AssemblyHeaderReserve', '27.0')]
    procedure TransferPlanningLineToAsmHdr(var OldRequisitionLine: Record "Requisition Line"; var NewAssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; TransferQty: Decimal; TransferAll: Boolean)
    var
        AssemblyHeaderReserve: Codeunit Microsoft.Assembly.Document."Assembly Header-Reserve";
    begin
        AssemblyHeaderReserve.TransferPlanningLineToAsmHdr(OldRequisitionLine, NewAssemblyHeader, TransferQty, TransferAll);
    end;
#endif

    procedure TransferReqLineToTransLine(var RequisitionLine: Record "Requisition Line"; var TransferLine: Record "Transfer Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
        OrigTransferQty: Decimal;
        ReservStatus: Enum "Reservation Status";
        Direction: Enum "Transfer Direction";
        Subtype: Enum "Transfer Direction";
    begin
        if not FindReservEntry(RequisitionLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        TransferLine.TestField("Item No.", RequisitionLine."No.");
        TransferLine.TestField("Variant Code", RequisitionLine."Variant Code");
        TransferLine.TestField("Transfer-to Code", RequisitionLine."Location Code");
        TransferLine.TestField("Transfer-from Code", RequisitionLine."Transfer-from Code");

        if TransferAll then begin
            OldReservationEntry.FindSet();
            OldReservationEntry.TestField("Qty. per Unit of Measure", TransferLine."Qty. per Unit of Measure");

            repeat
                // Swap 0/1 (outbound/inbound)
                if OldReservationEntry."Source Subtype" = 0 then
                    Direction := Direction::Inbound
                else
                    Direction := Direction::Outbound;
                if (Direction = Direction::Inbound) or (OldReservationEntry."Source Type" <> Database::"Transfer Line") then
                    OldReservationEntry.TestItemFields(RequisitionLine."No.", RequisitionLine."Variant Code", RequisitionLine."Location Code")
                else
                    OldReservationEntry.TestItemFields(RequisitionLine."No.", RequisitionLine."Variant Code", RequisitionLine."Transfer-from Code");

                NewReservationEntry := OldReservationEntry;
                if Direction = Direction::Inbound then
                    NewReservationEntry.SetSource(
                      Database::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", '', TransferLine."Derived From Line No.")
                else
                    NewReservationEntry.SetSource(
                      Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", '', TransferLine."Derived From Line No.");

                NewReservationEntry.UpdateActionMessageEntries(OldReservationEntry);
            until (OldReservationEntry.Next() = 0);
        end else begin
            OrigTransferQty := TransferQty;

            for Subtype := Subtype::Outbound to Subtype::Inbound do begin
                OldReservationEntry.SetRange("Source Subtype", Subtype);
                TransferQty := OrigTransferQty;
                if TransferQty = 0 then
                    exit;

                for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
                    OldReservationEntry.SetRange("Reservation Status", ReservStatus);

                    if OldReservationEntry.FindSet() then
                        repeat
                            // Swap outbound/inbound
                            if OldReservationEntry.GetTransferDirection() = Direction::Outbound then
                                Direction := Direction::Inbound
                            else
                                Direction := Direction::Outbound;
                            OldReservationEntry.TestField("Item No.", RequisitionLine."No.");
                            OldReservationEntry.TestField("Variant Code", RequisitionLine."Variant Code");
                            if Direction = Direction::Inbound then
                                OldReservationEntry.TestField("Location Code", RequisitionLine."Location Code")
                            else
                                OldReservationEntry.TestField("Location Code", RequisitionLine."Transfer-from Code");

                            TransferQty :=
                                CreateReservEntry.TransferReservEntry(
                                    Database::"Transfer Line",
                                    Direction.AsInteger(), TransferLine."Document No.", '', TransferLine."Derived From Line No.",
                                    TransferLine."Line No.", TransferLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                        until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
                end;
            end;
        end;
    end;

    local procedure AssignForPlanning(var RequisitionLine: Record "Requisition Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if RequisitionLine.Type <> RequisitionLine.Type::Item then
            exit;
        if RequisitionLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(RequisitionLine."No.", RequisitionLine."Variant Code", RequisitionLine."Location Code", WorkDate());
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure DeleteLine(var RequisitionLine: Record "Requisition Line")
    var
        ShouldExitForBlocked: Boolean;
    begin
        ShouldExitForBlocked := Blocked;
        OnDeleteLineOnAfterCalcShouldExitForBlocked(RequisitionLine, ShouldExitForBlocked);
        if ShouldExitForBlocked then
            exit;

        ReservationManagement.SetReservSource(RequisitionLine);
        ReservationManagement.SetItemTrackingHandling(1);

        // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        RequisitionLine.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(RequisitionLine);

        // Retracking of components:
        OnAfterDeleteLine(RequisitionLine);
    end;

    procedure UpdateDerivedTracking(var RequisitionLine: Record "Requisition Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ActionMessageEntry.SetCurrentKey("Reservation Entry");

        ReservationEntry.SetFilter("Expected Receipt Date", '<>%1', RequisitionLine."Due Date");
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Purchase:
                ReservationEntry.SetSourceFilter(Database::"Purchase Line", 1, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.", true);
            RequisitionLine."Ref. Order Type"::Transfer:
                ReservationEntry.SetSourceFilter(Database::"Transfer Line", 1, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.", true);
            else
                OnSetReservationSourceFilterByRefOrderType(RequisitionLine, ReservationEntry);
        end;

        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry2 := ReservationEntry;
                ReservationEntry2."Expected Receipt Date" := RequisitionLine."Due Date";
                ReservationEntry2.Modify();
                if ReservationEntry2.Get(ReservationEntry2."Entry No.", not ReservationEntry2.Positive) then begin
                    ReservationEntry2."Expected Receipt Date" := RequisitionLine."Due Date";
                    ReservationEntry2.Modify();
                end;
                ActionMessageEntry.SetRange("Reservation Entry", ReservationEntry."Entry No.");
                ActionMessageEntry.DeleteAll();
            until ReservationEntry.Next() = 0;
    end;

    procedure CallItemTracking(var RequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        InitFromReqLine(TrackingSpecification, RequisitionLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, RequisitionLine."Due Date");
        ItemTrackingLines.RunModal();
    end;

    local procedure VerifyBinInReqLine(var NewRequisitionLine: Record "Requisition Line"; var OldRequisitionLine: Record "Requisition Line"; var HasError: Boolean)
    begin
        if (NewRequisitionLine.Type = NewRequisitionLine.Type::Item) and (OldRequisitionLine.Type = OldRequisitionLine.Type::Item) then
            if (NewRequisitionLine."Bin Code" <> OldRequisitionLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewRequisitionLine."No.", NewRequisitionLine."Bin Code",
                  NewRequisitionLine."Location Code", NewRequisitionLine."Variant Code",
                  Database::"Requisition Line", 0,
                  NewRequisitionLine."Worksheet Template Name", NewRequisitionLine."Journal Batch Name", 0,
                  NewRequisitionLine."Line No."))
            then
                HasError := true;

        if NewRequisitionLine."Line No." <> OldRequisitionLine."Line No." then
            HasError := true;
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ReqLine: Record "Requisition Line";
    begin
        if SourceRecRef.Number = Database::"Requisition Line" then begin
            SourceRecRef.SetTable(ReqLine);
            ReqLine.Find();
            QtyPerUOM := ReqLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SourceRecordRef.SetTable(RequisitionLine);
        RequisitionLine.TestField("Sales Order No.", '');
        RequisitionLine.TestField("Sales Order Line No.", 0);
        RequisitionLine.TestField("Sell-to Customer No.", '');
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        RequisitionLine.TestField("Due Date");

        RequisitionLine.SetReservationEntry(ReservationEntry);

        CaptionText := RequisitionLine.GetSourceCaption();
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = Enum::"Reservation Summary Type"::"Requisition Line".AsInteger());
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Requisition Line");
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
        AvailableRequisitionLines: page "Available - Requisition Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableRequisitionLines);
            AvailableRequisitionLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableRequisitionLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure ReservationOnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Requisition Line");
            FilterReservEntry.SetRange("Source Subtype", 0);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure ReservationOnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Requisition Line") and
                (FilterReservEntry."Source Subtype" = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Ledger Entry-Reserve", 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure ItemLedgerEntryOnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary" temporary; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal; var IsHandled: Boolean; sender: Codeunit "Item Ledger Entry-Reserve")
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            sender.DrillDownTotalQuantity(SourceRecRef, EntrySummary, ReservEntry, MaxQtyToReserve);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ReqLine);
            CreateReservation(ReqLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(SourceType) then begin
            ReqLine.Reset();
            ReqLine.SetRange("Worksheet Template Name", SourceID);
            ReqLine.SetRange("Journal Batch Name", SourceBatchName);
            ReqLine.SetRange("Line No.", SourceRefNo);
            PAGE.RunModal(PAGE::"Requisition Lines", ReqLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(SourceType) then begin
            ReqLine.Reset();
            ReqLine.SetRange("Worksheet Template Name", SourceID);
            ReqLine.SetRange("Journal Batch Name", SourceBatchName);
            ReqLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"Requisition Lines", ReqLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ReqLine);
            ReqLine.SetReservationFilters(ReservEntry);
            CaptionText := ReqLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ReqLine);
            ReqLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Batch Name", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(RequisitionLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(RequisitionLine."Net Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(RequisitionLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        case ReservationEntry."Source Type" of
            Database::"Requisition Line":
                ShowRequisitionLines(ReservationEntry);
            Database::"Planning Component":
                ShowPlanningComponentLines(ReservationEntry);
        end;
    end;

    local procedure ShowRequisitionLines(var ReservationEntry: Record "Reservation Entry")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", ReservationEntry."Source ID");
        RequisitionLine.SetRange("Journal Batch Name", ReservationEntry."Source Batch Name");
        RequisitionLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(PAGE::"Requisition Lines", RequisitionLine);
    end;

    local procedure ShowPlanningComponentLines(var ReservationEntry: Record "Reservation Entry")
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.Reset();
        PlanningComponent.SetRange("Worksheet Template Name", ReservationEntry."Source ID");
        PlanningComponent.SetRange("Worksheet Batch Name", ReservationEntry."Source Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", ReservationEntry."Source Prod. Order Line");
        PlanningComponent.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(0, PlanningComponent);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSellToCustomerNo(var NewReqLine: Record "Requisition Line"; var OldReqLine: Record "Requisition Line"; ShowError: Boolean; var HasError: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewReqLine: Record "Requisition Line"; var OldReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnTransferReqLineToAsmHdrOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        OnTransferReqLineToAsmHdrOnBeforeTransfer(OldReservEntry, OldReqLine, AssemblyHeader);
    end;

    [Obsolete('Moved to codeunit AssemblyHeaderReserve', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToAsmHdrOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToPurchLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnTransferReqLineToPOLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnTransferReqLineToPOLineOnBeforeTransfer(OldReservEntry, OldReqLine, ProdOrderLine);
    end;

    [Obsolete('Moved to codeunit ProdOrderLineReserve', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToPOLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToReqLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var NewReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewReqLine: Record "Requisition Line"; OldReqLine: Record "Requisition Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewReqLine: Record "Requisition Line"; var OldReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var ReqLine: Record "Requisition Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var FromTrackingSpecification: Record "Tracking Specification"; ExpectedReceiptDate: Date; Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservation(var RequisitionLine: Record "Requisition Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeTransferPlanningLineToPOLine(var OldRequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeTransferPlanningLineToPOLine(OldRequisitionLine, ProdOrderLine, TransferQty, TransferAll, IsHandled);
    end;

    [Obsolete('Moved to codeunit ProdOrderLineReserve', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPlanningLineToPOLine(var OldRequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferPlanningLineToPOLineOnBeforeCheckFields(var OldRequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean; var IsHandled: Boolean)
    begin
        OnTransferPlanningLineToPOLineOnBeforeCheckFields(OldRequisitionLine, ProdOrderLine, TransferQty, TransferAll, IsHandled);
    end;

    [Obsolete('Moved to codeunit ProdOrderLineReserve', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferPlanningLineToPOLineOnBeforeCheckFields(var OldRequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnAfterCalcShouldExitForBlocked(var RequisitionLine: Record "Requisition Line"; var ShouldExitForBlocked: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Event is not used', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceForReservationOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ReqLine: Record "Requisition Line")
    begin
    end;
#endif

    // codeunit Create Reserv. Entry

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnCheckSourceTypeSubtype', '', false, false)]
    local procedure CheckSourceTypeSubtype(var ReservationEntry: Record "Reservation Entry"; var IsError: Boolean)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            IsError := ReservationEntry.Binding = ReservationEntry.Binding::" ";
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Requisition Line" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[4] := true;  // BatchName
            PointerFieldIsActive[6] := true;  // RefNo
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        if ReservationEntry."Source Type" = Database::"Requisition Line" then
            Description :=
                StrSubstNo(SourceDoc3Txt, RequisitionLine.TableCaption(), ReservationEntry."Source ID", ReservationEntry."Source Batch Name");
    end;

    procedure InitFromReqLine(var TrackingSpecification: Record "Tracking Specification"; ReqLine: Record "Requisition Line")
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
          ReqLine."No.", ReqLine.Description, ReqLine."Location Code", ReqLine."Variant Code", '', ReqLine."Qty. per Unit of Measure", ReqLine."Qty. Rounding Precision (Base)");
        TrackingSpecification.SetSource(
          Database::"Requisition Line", 0, ReqLine."Worksheet Template Name", ReqLine."Line No.", ReqLine."Journal Batch Name", 0);
        TrackingSpecification.SetQuantities(
          ReqLine."Quantity (Base)", ReqLine.Quantity, ReqLine."Quantity (Base)", ReqLine.Quantity, ReqLine."Quantity (Base)", 0, 0);

        OnAfterInitFromReqLine(TrackingSpecification, ReqLine);
#if not CLEAN25
        TrackingSpecification.RunOnAfterInitFromReqLine(TrackingSpecification, ReqLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromReqLine(var TrackingSpecification: Record "Tracking Specification"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnUpdateSourceCost', '', false, false)]
    local procedure ReservationEntryOnUpdateSourceCost(ReservationEntry: Record "Reservation Entry"; UnitCost: Decimal)
    var
        ReqLine: Record "Requisition Line";
        QtyToReserveNonBase: Decimal;
        QtyToReserve: Decimal;
        QtyReservedNonBase: Decimal;
        QtyReserved: Decimal;
    begin
        if MatchThisTable(ReservationEntry."Source Type") then begin
            ReqLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Batch Name", ReservationEntry."Source Ref. No.");
            ReqLine.GetReservationQty(QtyReservedNonBase, QtyReserved, QtyToReserveNonBase, QtyToReserve);
            if ReqLine."Qty. per Unit of Measure" <> 0 then
                ReqLine."Direct Unit Cost" :=
                    Round(ReqLine."Direct Unit Cost" / ReqLine."Qty. per Unit of Measure");
            if ReqLine."Quantity (Base)" <> 0 then
                ReqLine."Direct Unit Cost" :=
                    Round(
                        (ReqLine."Direct Unit Cost" * (ReqLine."Quantity (Base)" - QtyReserved) + UnitCost * QtyReserved) /
                         ReqLine."Quantity (Base)", 0.00001);
            if ReqLine."Qty. per Unit of Measure" <> 0 then
                ReqLine."Direct Unit Cost" :=
                    Round(ReqLine."Direct Unit Cost" * ReqLine."Qty. per Unit of Measure");
            ReqLine.Validate("Direct Unit Cost");
            ReqLine.Modify();
        end;
    end;

    // Inventory Profile

    procedure TransferInventoryProfileFromRequisitionLine(var InventoryProfile: Record "Inventory Profile"; var RequisitionLine: Record "Requisition Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        InventoryProfile.SetSource(
          Database::"Requisition Line", 0, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.",
          RequisitionLine."Journal Batch Name", 0);
        InventoryProfile."Item No." := RequisitionLine."No.";
        InventoryProfile."Variant Code" := RequisitionLine."Variant Code";
        InventoryProfile."Location Code" := RequisitionLine."Location Code";
        InventoryProfile."Bin Code" := RequisitionLine."Bin Code";
        RequisitionLine.CalcFields("Reserved Qty. (Base)");
        RequisitionLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        InventoryProfile."Untracked Quantity" := RequisitionLine."Quantity (Base)" - RequisitionLine."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile."Min. Quantity" := RequisitionLine."Reserved Qty. (Base)" - AutoReservedQty;
        InventoryProfile.Quantity := RequisitionLine.Quantity;
        InventoryProfile."Finished Quantity" := 0;
        InventoryProfile."Remaining Quantity" := RequisitionLine.Quantity;
        InventoryProfile."Quantity (Base)" := RequisitionLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := RequisitionLine."Quantity (Base)";
        InventoryProfile."Unit of Measure Code" := RequisitionLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := RequisitionLine."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" >= 0;
        InventoryProfile."Due Date" := RequisitionLine."Due Date";
        InventoryProfile."Planning Flexibility" := RequisitionLine."Planning Flexibility";

        OnAfterTransferInventoryProfileFromRequisitionLine(InventoryProfile, RequisitionLine);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromRequisitionLine(InventoryProfile, RequisitionLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromRequisitionLine(var InventoryProfile: record "Inventory Profile"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Requisition Line" then begin
            ReservationEntry.SetSource(
                Database::"Requisition Line", InventoryProfile."Source Order Status", InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", InventoryProfile."Source Batch Name", 0);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Requisition Line" then
            InventoryProfile."Order Priority" := 600;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Requisition Line" then
            InventoryProfile."Order Priority" := 300;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReservationSourceFilterByRefOrderType(var RequisitionLine: Record "Requisition Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;
}
