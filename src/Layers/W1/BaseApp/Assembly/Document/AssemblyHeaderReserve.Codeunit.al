// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Requisition;

codeunit 925 "Assembly Header-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationManagement: Codeunit "Reservation Management";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        DeleteItemTracking: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Reserved quantity cannot be greater than %1.';
#pragma warning restore AA0470
        Text001: Label 'Codeunit is not initialized correctly.';
        Text002: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Due Date"';
        Text003: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';
#pragma warning restore AA0074
        SummaryTypeTxt: Label '%1, %2', Locked = true;
        SourceDoc3Txt: Label '%1 %2 %3', Locked = true;

    procedure CreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReservation(AssemblyHeader, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry, FromTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text001);

        AssemblyHeader.TestField("Item No.");
        AssemblyHeader.TestField("Due Date");

        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        if Abs(AssemblyHeader."Remaining Quantity (Base)") < Abs(AssemblyHeader."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(AssemblyHeader."Remaining Quantity (Base)") - Abs(AssemblyHeader."Reserved Qty. (Base)"));

        AssemblyHeader.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        AssemblyHeader.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase * SignFactor(AssemblyHeader) < 0 then
            ShipmentDate := AssemblyHeader."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := AssemblyHeader."Due Date";
        end;

        if AssemblyHeader."Planning Flexibility" <> AssemblyHeader."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(AssemblyHeader."Planning Flexibility");

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(AssemblyHeader, Quantity, QuantityBase, ForReservEntry, FromTrackingSpecification, IsHandled, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
              Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(),
              AssemblyHeader."No.", '', 0, 0, AssemblyHeader."Qty. per Unit of Measure",
              Quantity, QuantityBase, ForReservEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(AssemblyHeader, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    local procedure SignFactor(AssemblyHeader: Record "Assembly Header"): Integer
    begin
        if AssemblyHeader."Document Type".AsInteger() in [2, 3, 5] then
            Error(Text001);

        exit(1);
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure SetDisallowCancellation(DisallowCancellation: Boolean)
    begin
        CreateReservEntry.SetDisallowCancellation(DisallowCancellation);
    end;

    procedure FilterReservFor(var FilterReservationEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.SetReservationFilters(FilterReservationEntry);
    end;

    procedure FindReservEntry(AssemblyHeader: Record "Assembly Header"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        AssemblyHeader.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    local procedure AssignForPlanning(var AssemblyHeader: Record "Assembly Header")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if AssemblyHeader."Document Type" <> AssemblyHeader."Document Type"::Order then
            exit;

        if AssemblyHeader."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code", WorkDate());
    end;

    procedure UpdatePlanningFlexibility(var AssemblyHeader: Record "Assembly Header")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(AssemblyHeader, ReservationEntry) then
            ReservationEntry.ModifyAll("Planning Flexibility", AssemblyHeader."Planning Flexibility");
    end;

    procedure ReservEntryExist(AssemblyHeader: Record "Assembly Header"): Boolean
    begin
        exit(AssemblyHeader.ReservEntryExist());
    end;

    procedure DeleteLine(var AssemblyHeader: Record "Assembly Header")
    begin
        OnBeforeDeleteLine(AssemblyHeader);

        ReservationManagement.SetReservSource(AssemblyHeader);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        ReservationManagement.ClearActionMessageReferences();
        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(AssemblyHeader);
    end;

    procedure VerifyChange(var NewAssemblyHeader: Record "Assembly Header"; var OldAssemblyHeader: Record "Assembly Header")
    var
        ReservationEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        NewAssemblyHeader.CalcFields("Reserved Qty. (Base)");
        ShowError := NewAssemblyHeader."Reserved Qty. (Base)" <> 0;

        if NewAssemblyHeader."Due Date" = 0D then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Due Date", Text002);
            HasError := true;
        end;

        if NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No." then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Item No.", Text003);
            HasError := true;
        end;

        if NewAssemblyHeader."Location Code" <> OldAssemblyHeader."Location Code" then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Location Code", Text003);
            HasError := true;
        end;

        if NewAssemblyHeader."Variant Code" <> OldAssemblyHeader."Variant Code" then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Variant Code", Text003);
            HasError := true;
        end;

        OnVerifyChangeOnBeforeHasError(NewAssemblyHeader, OldAssemblyHeader, HasError, ShowError);

        if HasError then
            if (NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No.") or
               FindReservEntry(NewAssemblyHeader, ReservationEntry)
            then begin
                if NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No." then begin
                    ReservationManagement.SetReservSource(OldAssemblyHeader);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewAssemblyHeader);
                end else begin
                    ReservationManagement.SetReservSource(NewAssemblyHeader);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewAssemblyHeader."Remaining Quantity (Base)");
            end;

        if HasError or (NewAssemblyHeader."Due Date" <> OldAssemblyHeader."Due Date") then begin
            AssignForPlanning(NewAssemblyHeader);
            if (NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No.") or
               (NewAssemblyHeader."Variant Code" <> OldAssemblyHeader."Variant Code") or
               (NewAssemblyHeader."Location Code" <> OldAssemblyHeader."Location Code")
            then
                AssignForPlanning(OldAssemblyHeader);
        end;
    end;

    procedure VerifyQuantity(var NewAssemblyHeader: Record "Assembly Header"; var OldAssemblyHeader: Record "Assembly Header")
    begin
        if NewAssemblyHeader."Quantity (Base)" = OldAssemblyHeader."Quantity (Base)" then
            exit;

        ReservationManagement.SetReservSource(NewAssemblyHeader);
        if NewAssemblyHeader."Qty. per Unit of Measure" <> OldAssemblyHeader."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        OnVerifyQuantityOnBeforeDeleteReservationEntries(NewAssemblyHeader, OldAssemblyHeader);
        ReservationManagement.DeleteReservEntries(false, NewAssemblyHeader."Remaining Quantity (Base)");
        ReservationManagement.ClearSurplus();
        OnVerifyQuantityOnBeforeAutoTrack(NewAssemblyHeader);
        ReservationManagement.AutoTrack(NewAssemblyHeader."Remaining Quantity (Base)");
        AssignForPlanning(NewAssemblyHeader);
    end;

    procedure Caption(AssemblyHeader: Record "Assembly Header") CaptionText: Text
    begin
        CaptionText := AssemblyHeader.GetSourceCaption();
    end;

    procedure CallItemTracking(var AssemblyHeader: Record "Assembly Header")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallItemTracking(AssemblyHeader, IsHandled);
        if not IsHandled then begin
            InitFromAsmHeader(TrackingSpecification, AssemblyHeader);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, AssemblyHeader."Due Date");
            ItemTrackingLines.SetInbound(AssemblyHeader.IsInbound());
            OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(AssemblyHeader, ItemTrackingLines);
            ItemTrackingLines.RunModal();
        end;
    end;

    procedure DeleteLineConfirm(var AssemblyHeader: Record "Assembly Header"): Boolean
    begin
        if not AssemblyHeader.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(AssemblyHeader);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure UpdateItemTrackingAfterPosting(AssemblyHeader: Record "Assembly Header")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.InitSortingAndFilters(false);
        ReservationEntry.SetSourceFilter(
          Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", -1, false);
        ReservationEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure TransferAsmHeaderToItemJnlLine(var AssemblyHeader: Record "Assembly Header"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplToItemEntry: Boolean): Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        OldReservationEntry2: Record "Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(AssemblyHeader, OldReservationEntry) then
            exit(TransferQty);
        AssemblyHeader.CalcFields("Assemble to Order");

        ItemJournalLine.TestItemFields(AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code");

        OldReservationEntry.LockTable();
        OldReservationEntry.FindLast();

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestItemFields(AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code");
                if CheckApplToItemEntry and
                   (OldReservationEntry."Reservation Status" = OldReservationEntry."Reservation Status"::Reservation)
                then begin
                    OldReservationEntry2.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                    OldReservationEntry2.TestField("Source Type", Database::"Item Ledger Entry");
                end;

                if AssemblyHeader."Assemble to Order" and
                   (OldReservationEntry.Binding = OldReservationEntry.Binding::"Order-to-Order")
                then begin
                    OldReservationEntry2.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                    if Abs(OldReservationEntry2."Qty. to Handle (Base)") < Abs(OldReservationEntry."Qty. to Handle (Base)") then begin
                        OldReservationEntry."Qty. to Handle (Base)" := Abs(OldReservationEntry2."Qty. to Handle (Base)");
                        OldReservationEntry."Qty. to Invoice (Base)" := Abs(OldReservationEntry2."Qty. to Invoice (Base)");
                    end;
                end;

                OnTransferAsmHeaderToItemJnlLineOnBeforeTransferReservationEntry(AssemblyHeader, ItemJournalLine, OldReservationEntry);

                TransferQty := CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line",
                    ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplToItemEntry := false;
        end;
        exit(TransferQty);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(AssemblyHeader);
            AssemblyHeader.Find();
            QtyPerUOM := AssemblyHeader.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        SourceRecordRef.SetTable(AssemblyHeader);
        AssemblyHeader.TestField("Due Date");

        AssemblyHeader.SetReservationEntry(ReservationEntry);

        CaptionText := AssemblyHeader.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Assembly Quote Header".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Assembly Quote Header".AsInteger(),
                         Enum::"Reservation Summary Type"::"Assembly Order Header".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Assembly Header");
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
        AvailableAssemblyHeaders: page "Available - Assembly Headers";
    begin
        if EntrySummary."Entry No." in [141, 142] then begin
            Clear(AvailableAssemblyHeaders);
            AvailableAssemblyHeaders.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableAssemblyHeaders.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableAssemblyHeaders.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure ReservationOnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Assembly Header");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure ReservationOnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Assembly Header") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
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
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(AssemblyHeader);
            CreateReservation(AssemblyHeader, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceType) then begin
            AssemblyHeader.Reset();
            AssemblyHeader.SetRange("Document Type", SourceSubtype);
            AssemblyHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    ;
                1:
                    PAGE.RunModal(PAGE::"Assembly Order", AssemblyHeader);
                5:
                    ;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceType) then begin
            AssemblyHeader.Reset();
            AssemblyHeader.SetRange("Document Type", SourceSubtype);
            AssemblyHeader.SetRange("No.", SourceID);
            PAGE.Run(PAGE::"Assembly Orders", AssemblyHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(AssemblyHeader);
            AssemblyHeader.SetReservationFilters(ReservEntry);
            CaptionText := AssemblyHeader.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(AssemblyHeader);
            AssemblyHeader.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID");
        SourceRecordRef.GetTable(AssemblyHeader);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(AssemblyHeader."Remaining Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(AssemblyHeader."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
        AvailabilityFilter: Text;
    begin
        if not AssemblyHeader.ReadPermission then
            exit;

        AssemblyHeader.SetAutoCalcFields("Reserved Qty. (Base)");
        AvailabilityFilter := CalcReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        AssemblyHeader.FilterLinesForReservation(CalcReservationEntry, DocumentType, AvailabilityFilter, Positive);
        if AssemblyHeader.FindSet() then
            repeat
                TempEntrySummary."Total Reserved Quantity" += AssemblyHeader."Reserved Qty. (Base)";
                TotalQuantity += AssemblyHeader."Remaining Quantity (Base)";
            until AssemblyHeader.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity > 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"Assembly Header";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo(SummaryTypeTxt, AssemblyHeader.TableCaption(), AssemblyHeader."Document Type"),
                1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [141, 142] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 141, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.SetRange("Document Type", ReservationEntry."Source Subtype");
        AssemblyHeader.SetRange("No.", ReservationEntry."Source ID");
        PAGE.RunModal(Page::"Assembly List", AssemblyHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterAutoReserveOneLine', '', false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean; var sender: Codeunit "Reservation Management")
    begin
        if MatchThisEntry(ReservSummEntryNo) then
            AutoReserveAssemblyHeader(
                CalcReservEntry, sender, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase,
                Description, AvailabilityDate, Search, NextStep, Positive);
    end;

    local procedure AutoReserveAssemblyHeader(var CalcReservEntry: Record "Reservation Entry"; var sender: Codeunit "Reservation Management"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; Positive: Boolean)
    var
        CallTrackingSpecification: Record "Tracking Specification";
        AssemblyHeader: Record "Assembly Header";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
#if not CLEAN25
        IsReserved := false;
        sender.RunOnBeforeAutoReserveAssemblyHeader(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;
#endif
        IsReserved := false;
        OnBeforeAutoReserveAssemblyHeader(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        AssemblyHeader.SetAutoCalcFields("Reserved Qty. (Base)");
        AssemblyHeader.FilterLinesForReservation(
            CalcReservEntry, ReservSummEntryNo - Enum::"Reservation Summary Type"::"Assembly Quote Header".AsInteger(),
            sender.GetAvailabilityFilter(AvailabilityDate), Positive);
        if AssemblyHeader.Find(Search) then
            repeat
                QtyThisLine := AssemblyHeader."Remaining Quantity";
                QtyThisLineBase := AssemblyHeader."Remaining Quantity (Base)";
                ReservQty := AssemblyHeader."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase < 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                sender.SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, AssemblyHeader.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
                  AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                sender.InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, AssemblyHeader."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (AssemblyHeader.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewAssemblyHeader: Record "Assembly Header"; OldAssemblyHeader: Record "Assembly Header"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var AssemblyHeader: Record "Assembly Header"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLine(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry"; FromTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveAssemblyHeader(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var AssemblyHeader: Record "Assembly Header"; var Quantity: Decimal; var QuantityBase: Decimal; var ReservationEntry: Record "Reservation Entry"; var FromTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean; ExpectedReceiptDate: Date; Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoReserveOnBeforeStopReservation', '', false, false)]
    local procedure OnAutoReserveOnBeforeStopReservation(var CalcReservEntry: Record "Reservation Entry"; var StopReservation: Boolean; SourceRecRef: RecordRef);
    begin
        if MatchThisTable(CalcReservEntry."Source Type") then
            StopReservation := not (CalcReservEntry."Source Subtype" = 1); // Only Assembly Order
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnIssueActionMessageOnSetSourceTypeFromSKU', '', false, false)]
    local procedure OnIssueActionMessageOnSetSourceTypeFromSKU(var ActionMessageEntry: Record "Action Message Entry"; SKU: Record "Stockkeeping Unit")
    begin
        if SKU."Replenishment System" = SKU."Replenishment System"::Assembly then
            ActionMessageEntry."Source Type" := Database::"Assembly Header";
    end;

    // codeunit Create Reserv. Entry

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnCheckSourceTypeSubtype', '', false, false)]
    local procedure CheckSourceTypeSubtype(var ReservationEntry: Record "Reservation Entry"; var IsError: Boolean)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            IsError := not (ReservationEntry."Source Subtype" = 1); // Only Assembly Order supported
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Assembly Header" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if ReservationEntry."Source Type" = Database::"Assembly Header" then
            Description :=
                StrSubstNo(
                    SourceDoc3Txt, AssemblyHeader.TableCaption(),
                    Enum::"Assembly Document Type".FromInteger(ReservationEntry."Source Subtype"), ReservationEntry."Source ID");
    end;

    procedure InitFromAsmHeader(var TrackingSpecification: Record "Tracking Specification"; var AsmHeader: Record "Assembly Header")
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
            AsmHeader."Item No.", AsmHeader.Description, AsmHeader."Location Code", AsmHeader."Variant Code", AsmHeader."Bin Code",
            AsmHeader."Qty. per Unit of Measure", AsmHeader."Qty. Rounding Precision (Base)");
        TrackingSpecification.SetSource(
            Database::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", 0, '', 0);
        TrackingSpecification.SetQuantities(
            AsmHeader."Quantity (Base)", AsmHeader."Quantity to Assemble", AsmHeader."Quantity to Assemble (Base)",
            AsmHeader."Quantity to Assemble", AsmHeader."Quantity to Assemble (Base)",
            AsmHeader."Assembled Quantity (Base)", AsmHeader."Assembled Quantity (Base)");

        OnAfterInitFromAsmHeader(TrackingSpecification, AsmHeader);
#if not CLEAN25
        TrackingSpecification.RunOnAfterInitFromAsmHeader(TrackingSpecification, AsmHeader);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromAsmHeader(var TrackingSpecification: Record "Tracking Specification"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSummEntryNo', '', false, false)]
    local procedure OnBeforeSummEntryNo(ReservationEntry: Record "Reservation Entry"; var ReturnValue: Integer)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ReturnValue := Enum::"Reservation Summary Type"::"Assembly Quote Header".AsInteger() + ReservationEntry."Source Subtype";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OrderTrackingManagementOnSetSourceRrcord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text; var ItemLedgerEntry2: Record "Item Ledger Entry")
    var
        AssemblyHeader: Record "Assembly Header";
        SourceRecRef: RecordRef;
    begin
        SourceRecRef.GetTable(SourceRecordVar);
        if MatchThisTable(SourceRecRef.Number) then begin
            AssemblyHeader := SourceRecordVar;
            SetAssemblyHeader(AssemblyHeader, ReservationEntry, ItemLedgerEntry2);
        end;
    end;

    local procedure SetAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; var ReservEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ReservEntry.InitSortingAndFilters(false);
        AssemblyHeader.SetReservationFilters(ReservEntry);

        if AssemblyHeader."Assembled Quantity (Base)" <> 0 then begin
            ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.");
            ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Assembly);
            ItemLedgerEntry.SetRange("Order No.", AssemblyHeader."No.");
            ItemLedgerEntry.SetRange("Order Line No.", 0);
            if ItemLedgerEntry.Find('-') then
                repeat
                    ItemLedgerEntry.Mark(true);
                until ItemLedgerEntry.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnInsertOrderTrackingEntry', '', false, false)]
    local procedure OnInsertOrderTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if OrderTrackingEntry."For Type" = DATABASE::"Assembly Header" then
            if AssemblyHeader.Get(OrderTrackingEntry."For Subtype", OrderTrackingEntry."For ID") then begin
                OrderTrackingEntry."Starting Date" := AssemblyHeader."Due Date";
                OrderTrackingEntry."Ending Date" := AssemblyHeader."Due Date";
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnSetSourceForAssemblyHeader', '', false, false)]
    local procedure OnSetSourceForAssemblyHeader(SourceRecRef: RecordRef; var CalcReservEntry: Record "Reservation Entry"; var EntryIsPositive: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if not MatchThisTable(SourceRecRef.Number) then
            exit;

        SourceRecRef.SetTable(AssemblyHeader);
        AssemblyHeader.SetReservationEntry(CalcReservEntry);
        OnSetAssemblyHeaderOnBeforeUpdateReservation(CalcReservEntry, AssemblyHeader);
#if not CLEAN26
        ReservationManagement.RunOnSetAssemblyHeaderOnBeforeUpdateReservation(CalcReservEntry, AssemblyHeader);
#endif
        EntryIsPositive := ((CreateReservEntry.SignFactor(CalcReservEntry) * AssemblyHeader."Remaining Quantity (Base)") < 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAssemblyHeaderOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyQuantityOnBeforeDeleteReservationEntries(var NewAssemblyHeader: Record "Assembly Header"; OldAssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyQuantityOnBeforeAutoTrack(var NewAssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferAsmHeaderToItemJnlLineOnBeforeTransferReservationEntry(var AssemblyHeader: Record "Assembly Header"; var ItemJournalLine: Record "Item Journal Line"; var OldReservationEntry: Record "Reservation Entry")
    begin
    end;

    procedure TransferPlanningLineToAsmHdr(var OldRequisitionLine: Record "Requisition Line"; var NewAssemblyHeader: Record "Assembly Header"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
    begin
        if not ReqLineReserve.FindReservEntry(OldRequisitionLine, OldReservationEntry) then
            exit;

        NewAssemblyHeader.TestField("Item No.", OldRequisitionLine."No.");
        NewAssemblyHeader.TestField("Variant Code", OldRequisitionLine."Variant Code");
        NewAssemblyHeader.TestField("Location Code", OldRequisitionLine."Location Code");

        OnTransferReqLineToAsmHdrOnBeforeTransfer(OldReservationEntry, OldRequisitionLine, NewAssemblyHeader);
#if not CLEAN27
        ReqLineReserve.RunOnTransferReqLineToAsmHdrOnBeforeTransfer(OldReservationEntry, OldRequisitionLine, NewAssemblyHeader);
#endif

        OldReservationEntry.TransferReservations(
            OldReservationEntry, OldRequisitionLine."No.", OldRequisitionLine."Variant Code", OldRequisitionLine."Location Code",
            TransferAll, TransferQty, NewAssemblyHeader."Qty. per Unit of Measure",
            Database::"Assembly Header", NewAssemblyHeader."Document Type".AsInteger(), NewAssemblyHeader."No.", '', 0, 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToAsmHdrOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Line-Reserve", 'OnSetReservationSourceFilterByRefOrderType', '', false, false)]
    local procedure OnSetReservationSourceFilterByRefOrderType(var RequisitionLine: Record "Requisition Line"; var ReservationEntry: Record "Reservation Entry")
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Assembly:
                ReservationEntry.SetSourceFilter(Database::"Assembly Header", 1, RequisitionLine."Ref. Order No.", 0, true);
        end;
    end;
}
