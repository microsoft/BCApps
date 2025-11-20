// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Ledger;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.UOM;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Purchases.Document;

codeunit 1032 "Job Planning Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";

        Text000Err: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1 - qualtity';
        Text002Err: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Planning Date"';
        Text004Err: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';
        Text005Err: Label 'Codeunit is not initialized correctly.';
        InvalidLineTypeErr: Label 'must be %1 or %2', Comment = '%1 and %2 are line type options, fx. Budget or Billable';
        SummaryTypeTxt: Label '%1, %2', Locked = true;
        SourceDoc2Txt: Label '%1 %2', Locked = true;
        NonInvReserveTypeErr: Label 'Non-inventory and service items cannot be reserved.';

    procedure CreateReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        PlanningDate: Date;
        SignFactor: Integer;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text005Err);

        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.TestField("No.");
        JobPlanningLine.TestField("Planning Date");

        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        CheckReservedQtyBase(JobPlanningLine, QuantityBase);

        JobPlanningLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        JobPlanningLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        SignFactor := -1;

        if QuantityBase * SignFactor < 0 then
            PlanningDate := JobPlanningLine."Planning Date"
        else begin
            PlanningDate := ExpectedReceiptDate;
            ExpectedReceiptDate := JobPlanningLine."Planning Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(),
          JobPlanningLine."Job No.", '', 0, JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code",
          Description, ExpectedReceiptDate, PlanningDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateBindingReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(JobPlanningLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    local procedure CheckReservedQtyBase(JobPlanningLine: Record "Job Planning Line"; QuantityBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReservedQtyBase(JobPlanningLine, IsHandled, QuantityBase);
        if IsHandled then
            exit;

        if Abs(JobPlanningLine."Remaining Qty. (Base)") < Abs(JobPlanningLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000Err,
              Abs(JobPlanningLine."Remaining Qty. (Base)") - Abs(JobPlanningLine."Reserved Qty. (Base)"));
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure CallItemTracking(var JobPlanningLine: Record "Job Planning Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // Throw error if "Type" != "Item" or "Line Type" != "Budget" or "Budget and Billable"
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        if not (JobPlanningLine."Line Type" in [Enum::"Job Planning Line Line Type"::"Both Budget and Billable", Enum::"Job Planning Line Line Type"::Budget]) then
            JobPlanningLine.FieldError("Line Type", StrSubstNo(InvalidLineTypeErr, Enum::"Job Planning Line Line Type"::Budget, Enum::"Job Planning Line Line Type"::"Both Budget and Billable"));

        if JobPlanningLine.Status = JobPlanningLine.Status::Completed then
            ItemTrackingDocManagement.ShowItemTrackingForJobPlanningLine(Database::"Job Planning Line", JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.")
        else begin
            JobPlanningLine.TestField("No.");
            InitFromJobPlanningLine(TrackingSpecification, JobPlanningLine);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, JobPlanningLine."Planning Due Date");
            ItemTrackingLines.SetInbound(JobPlanningLine.IsInbound());
            ItemTrackingLines.RunModal();
        end;
    end;

    procedure ReservQuantity(JobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case JobPlanningLine.Status of
            JobPlanningLine.Status::Planning,
            JobPlanningLine.Status::Quote,
            JobPlanningLine.Status::Order,
            JobPlanningLine.Status::Completed:
                begin
                    QtyToReserve := JobPlanningLine."Remaining Qty.";
                    QtyToReserveBase := JobPlanningLine."Remaining Qty. (Base)";
                end;
        end;

        OnAfterReservQuantity(JobPlanningLine, QtyToReserve, QtyToReserveBase);
    end;

    procedure Caption(JobPlanningLine: Record "Job Planning Line") CaptionText: Text
    begin
        CaptionText := JobPlanningLine.GetSourceCaption();
    end;

    procedure FindReservEntry(JobPlanningLine: Record "Job Planning Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        JobPlanningLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure GetReservedQtyFromInventory(JobPlanningLine: Record "Job Planning Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        JobPlanningLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(Job: Record Job): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(Database::"Job Planning Line", Job.Status.AsInteger(), Job."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure VerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        ReservationEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewJobPlanningLine.Type <> NewJobPlanningLine.Type::Item) and (OldJobPlanningLine.Type <> OldJobPlanningLine.Type::Item) then
            exit;
        if NewJobPlanningLine."Job Contract Entry No." = 0 then begin
            JobPlanningLine.SetLoadFields("Job No.", "Job Task No.", "Line No.");
            if not JobPlanningLine.Get(NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Task No.", NewJobPlanningLine."Line No.") then
                exit;
        end;

        NewJobPlanningLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewJobPlanningLine."Reserved Qty. (Base)" <> 0;

        if NewJobPlanningLine."Usage Link" <> OldJobPlanningLine."Usage Link" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Usage Link", Text004Err);
            HasError := true;
        end;

        if (NewJobPlanningLine."Planning Date" = 0D) and (OldJobPlanningLine."Planning Date" <> 0D) then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Planning Date", Text002Err);
            HasError := true;
        end;

        if NewJobPlanningLine."No." <> OldJobPlanningLine."No." then begin
            if ShowError then
                NewJobPlanningLine.FieldError("No.", Text004Err);
            HasError := true;
        end;

        if NewJobPlanningLine."Variant Code" <> OldJobPlanningLine."Variant Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Variant Code", Text004Err);
            HasError := true;
        end;

        if NewJobPlanningLine."Location Code" <> OldJobPlanningLine."Location Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Location Code", Text004Err);
            HasError := true;
        end;

        if NewJobPlanningLine."Line No." <> OldJobPlanningLine."Line No." then
            HasError := true;

        if NewJobPlanningLine.Type <> OldJobPlanningLine.Type then begin
            if ShowError then
                NewJobPlanningLine.FieldError(Type, Text004Err);
            HasError := true;
        end;

        VerifyBinInJobPlanningLine(NewJobPlanningLine, OldJobPlanningLine, HasError);

        OnVerifyChangeOnBeforeHasErrorCheck(NewJobPlanningLine, OldJobPlanningLine, HasError, ShowError);

        if HasError then
            if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or
               FindReservEntry(NewJobPlanningLine, ReservationEntry)
            then begin
                if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or (NewJobPlanningLine.Type <> OldJobPlanningLine.Type) then begin
                    ReservationManagement.SetReservSource(OldJobPlanningLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewJobPlanningLine);
                end else begin
                    ReservationManagement.SetReservSource(NewJobPlanningLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewJobPlanningLine."Remaining Qty. (Base)");
            end;

        if HasError or (NewJobPlanningLine."Planning Date" <> OldJobPlanningLine."Planning Date")
        then begin
            AssignForPlanning(NewJobPlanningLine);
            if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or
               (NewJobPlanningLine."Variant Code" <> OldJobPlanningLine."Variant Code") or
               (NewJobPlanningLine."Location Code" <> OldJobPlanningLine."Location Code")
            then
                AssignForPlanning(OldJobPlanningLine);
        end;
    end;

    local procedure VerifyBinInJobPlanningLine(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; var HasError: Boolean)
    begin
        if (NewJobPlanningLine.Type = NewJobPlanningLine.Type::Item) and (OldJobPlanningLine.Type = OldJobPlanningLine.Type::Item) then
            if (NewJobPlanningLine."Bin Code" <> OldJobPlanningLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewJobPlanningLine."No.", NewJobPlanningLine."Bin Code",
                  NewJobPlanningLine."Location Code", NewJobPlanningLine."Variant Code",
                  Database::"Job Planning Line", NewJobPlanningLine.Status.AsInteger(),
                  NewJobPlanningLine."Job No.", '', 0,
                  NewJobPlanningLine."Job Contract Entry No."))
            then
                HasError := true;
    end;

    procedure VerifyQuantity(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewJobPlanningLine, OldJobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        if NewJobPlanningLine.Type <> NewJobPlanningLine.Type::Item then
            exit;
        if NewJobPlanningLine.Status = OldJobPlanningLine.Status then
            if NewJobPlanningLine."Line No." = OldJobPlanningLine."Line No." then
                if NewJobPlanningLine."Quantity (Base)" = OldJobPlanningLine."Quantity (Base)" then
                    exit;
        if NewJobPlanningLine."Line No." = 0 then begin
            JobPlanningLine.SetLoadFields("Job No.", "Job Task No.", "Line No.");
            if not JobPlanningLine.Get(NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Task No.", NewJobPlanningLine."Line No.") then
                exit;
        end;
        ReservationManagement.SetReservSource(NewJobPlanningLine);
        if NewJobPlanningLine."Qty. per Unit of Measure" <> OldJobPlanningLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewJobPlanningLine."Remaining Qty. (Base)" * OldJobPlanningLine."Remaining Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewJobPlanningLine."Remaining Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewJobPlanningLine."Remaining Qty. (Base)");
        AssignForPlanning(NewJobPlanningLine);
    end;

    procedure TransferJobLineToItemJnlLine(var JobPlanningLine: Record "Job Planning Line"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal): Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
    begin
        if not FindReservEntry(JobPlanningLine, OldReservationEntry) then
            exit(TransferQty);

        //exclude reservations if negative adjustment from PO posting
        if (NewItemJournalLine."Document Type" = NewItemJournalLine."Document Type"::"Purchase Receipt")
           and (NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::"Negative Adjmt.") then begin
            UpdateReservationsWhenPostingJobPlaningLineNegativeAdjFromPO(JobPlanningLine, NewItemJournalLine, OldReservationEntry);

            OldReservationEntry.SetFilter("Reservation Status", '<>%1', OldReservationEntry."Reservation Status"::Reservation);
            if OldReservationEntry.IsEmpty then
                exit(TransferQty);
        end;

        // Store initial values
        OldReservationEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservationEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservationEntry.LockTable();
        OldReservationEntry.FindLast();

        // Handle Item Tracking on job planning line:
        Clear(CreateReservEntry);
        if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::"Negative Adjmt." then
            if NewItemJournalLine.TrackingExists() then begin
                // Try to match against Item Tracking on the job planning line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(NewItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    OldReservationEntry.ClearTrackingFilter()
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJournalLine.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

        if TransferQty = 0 then
            exit;

        ItemTrackingSetup.CopyTrackingFromItemJnlLine(NewItemJournalLine);
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry, ItemTrackingSetup) then
            repeat
                OldReservationEntry.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

                if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::"Negative Adjmt." then
                    // Set the tracking for the item journal inside the loop as it is cleared within TransferReservEntry
                    CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJournalLine);

                TransferQty :=
                  CreateReservEntry.TransferReservEntry(Database::"Item Journal Line",
                    NewItemJournalLine."Entry Type".AsInteger(), NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name", 0,
                    NewItemJournalLine."Line No.", NewItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

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

        // Handle remaining transfer quantity
        if TransferQty <> 0 then begin
            TrackedQty -= (xTransferQty - TransferQty);
            UnTrackedQty := JobPlanningLine."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservationManagement.SetReservSource(JobPlanningLine);
                ReservationManagement.DeleteReservEntries(false, JobPlanningLine."Remaining Qty. (Base)");
            end;
        end;
        exit(TransferQty);
    end;

    local procedure UpdateReservationsWhenPostingJobPlaningLineNegativeAdjFromPO(var JobPlanningLine: Record "Job Planning Line"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        NewReserveQtyBase: Decimal;
        NewReservationEntryQtyBase: Decimal;
        NewReservationEntryQty: Decimal;
    begin
        if not ((ItemJournalLine."Document Type" = ItemJournalLine."Document Type"::"Purchase Receipt") and (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Negative Adjmt.")) then
            exit;

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        if ReservationEntry.IsEmpty then
            exit;

        NewReserveQtyBase := JobPlanningLine."Remaining Qty. (Base)";
        ReservationEntry.FindSet();

        if NewReserveQtyBase <= 0 then begin
            repeat
                ReservationEngineMgt.CloseReservEntry(ReservationEntry, false, false);
            until ReservationEntry.Next() = 0;
            exit;
        end;

        repeat
            TempReservationEntry.Init();
            TempReservationEntry := ReservationEntry;
            TempReservationEntry.Insert();
        until ReservationEntry.Next() = 0;

        TempReservationEntry.Reset();
        TempReservationEntry.FindSet();
        repeat
            if NewReserveQtyBase >= -TempReservationEntry."Quantity (Base)" then
                NewReserveQtyBase += TempReservationEntry."Quantity (Base)"
            else
                if NewReserveQtyBase = 0 then
                    ReservationEngineMgt.CloseReservEntry(TempReservationEntry, false, false)
                else begin
                    NewReservationEntryQtyBase := NewReserveQtyBase;
                    NewReserveQtyBase := 0;
                    NewReservationEntryQty := UnitOfMeasureManagement.CalcQtyFromBase(NewReservationEntryQtyBase, TempReservationEntry."Qty. per Unit of Measure");
                    CreateReservEntry.CreateRemainingReservEntry(TempReservationEntry, NewReservationEntryQty, NewReservationEntryQtyBase);
                    ReservationEngineMgt.CloseReservEntry(TempReservationEntry, false, false);
                end;
        until TempReservationEntry.Next() = 0;
    end;

    procedure DeleteLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        DeleteLineInternal(JobPlanningLine, true);
    end;

    internal procedure DeleteLineInternal(var JobPlanningLine: Record "Job Planning Line"; ConfirmFirst: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationManagement.SetReservSource(JobPlanningLine);

        ReservationEntry.InitSortingAndFilters(false);
        JobPlanningLine.SetReservationFilters(ReservationEntry);
        if not ReservationEntry.IsEmpty() then
            if ConfirmFirst then begin
                if ReservationManagement.DeleteItemTrackingConfirm() then
                    ReservationManagement.SetItemTrackingHandling(1);
            end else
                ReservationManagement.SetItemTrackingHandling(1);
        ReservationManagement.DeleteReservEntries(true, 0);
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(JobPlanningLine);
    end;

    local procedure AssignForPlanning(var JobPlanningLine: Record "Job Planning Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if JobPlanningLine.Status <> JobPlanningLine.Status::Order then
            exit;
        if JobPlanningLine.Type <> JobPlanningLine.Type::Item then
            exit;
        if JobPlanningLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(
                JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code", JobPlanningLine."Planning Date");
    end;

    procedure BindToTracking(JobPlanningLine: Record "Job Planning Line"; TrackingSpecification: Record "Tracking Specification"; Description: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal)
    begin
        SetBinding("Reservation Binding"::"Order-to-Order");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, Description, ExpectedDate, ReservQty, ReservQtyBase);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToPurchase(JobPlanningLine: Record "Job Planning Line"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Purchases.Document."Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToRequisition(JobPlanningLine: Record "Job Planning Line"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::"Requisition Line",
          0, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToTransfer(JobPlanningLine: Record "Job Planning Line"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Inventory.Transfer."Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToProdOrder(JobPlanningLine: Record "Job Planning Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBindToProdOrder(JobPlanningLine, ProdOrderLine, ReservQty, ReservQtyBase, IsHandled);
        if IsHandled then
            exit;

        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Manufacturing.Document."Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToAssembly(JobPlanningLine: Record "Job Planning Line"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Assembly.Document."Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;
#endif

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.Find();
            if JobPlanningLine.UpdatePlanned() then begin
                JobPlanningLine.Modify(true);
                Commit();
            end;
            QtyPerUOM := JobPlanningLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        SourceRecordRef.SetTable(JobPlanningLine);
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.TestField("Planning Date");

        JobPlanningLine.SetReservationEntry(ReservationEntry);

        CaptionText := JobPlanningLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Job Planning Planned".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = Enum::"Reservation Summary Type"::"Job Planning Order".AsInteger());
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit((TableID = Database::"Job Planning Line") or (TableID = Database::Job)); //for warehouse pick: Database::Job
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
        AvailableJobPlanningLines: Page "Available - Job Planning Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableJobPlanningLines);
            AvailableJobPlanningLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableJobPlanningLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableJobPlanningLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Job Planning Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure ReservationOnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Job Planning Line") and
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
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(JobPlanningLine);
            CreateReservation(JobPlanningLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceID: Code[20])
    var
        Job: Record Job;
    begin
        if MatchThisTable(SourceType) then begin
            Job.Reset();
            Job.SetRange("No.", SourceID);
            Page.RunModal(Page::"Job Card", Job)
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceRefNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(SourceType) then begin
            JobPlanningLine.Reset();
            JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
            JobPlanningLine.SetRange("Job Contract Entry No.", SourceRefNo);
            Page.Run(0, JobPlanningLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.SetReservationFilters(ReservEntry);
            CaptionText := JobPlanningLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", ReservationEntry."Source Ref. No.");
        JobPlanningLine.FindFirst();
        SourceRecordRef.GetTable(JobPlanningLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(JobPlanningLine."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(JobPlanningLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; LineType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        AvailabilityFilter: Text;
    begin
        if not JobPlanningLine.ReadPermission() then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        JobPlanningLine.FilterLinesForReservation(ReservationEntry, LineType, AvailabilityFilter, Positive);
        JobPlanningLine.SetLoadFields("Remaining Qty. (Base)", "Reserved Qty. (Base)", Status);
        JobPlanningLine.SetAutoCalcFields("Reserved Qty. (Base)");
        if JobPlanningLine.FindSet() then
            repeat
                TempEntrySummary."Total Reserved Quantity" -= JobPlanningLine."Reserved Qty. (Base)";
                TotalQuantity += JobPlanningLine."Remaining Qty. (Base)";
            until JobPlanningLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity < 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"Job Planning Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo(SummaryTypeTxt, JobPlanningLine.TableCaption(), JobPlanningLine.Status), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if MatchThisEntry(ReservSummEntry."Entry No.") then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 131, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange(Status, ReservationEntry."Source Subtype");
        JobPlanningLine.SetRange("Job No.", ReservationEntry."Source ID");
        JobPlanningLine.SetRange("Job Contract Entry No.", ReservationEntry."Source Ref. No.");
        Page.RunModal(Page::"Job Planning Lines", JobPlanningLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterAutoReserveOneLine', '', false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean; var sender: Codeunit "Reservation Management")
    begin
        if MatchThisEntry(ReservSummEntryNo) then
            AutoReserveJobPlanningLine(
                CalcReservEntry, sender, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase,
                Description, AvailabilityDate, Search, NextStep, Positive);
    end;

    local procedure AutoReserveJobPlanningLine(var CalcReservEntry: Record "Reservation Entry"; var sender: Codeunit "Reservation Management"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; Positive: Boolean)
    var
        CallTrackingSpecification: Record "Tracking Specification";
        JobPlanningLine: Record "Job Planning Line";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
#if not CLEAN25
        IsReserved := false;
        sender.RunOnBeforeAutoReserveJobPlanningLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;
#endif
        IsReserved := false;
        OnBeforeAutoReserveJobPlanningLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        CheckItemType(CalcReservEntry);
        JobPlanningLine.SetAutoCalcFields("Reserved Qty. (Base)");
        JobPlanningLine.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 131, sender.GetAvailabilityFilter(AvailabilityDate), Positive);
        if JobPlanningLine.Find(Search) then
            repeat
                QtyThisLine := JobPlanningLine."Remaining Qty.";
                QtyThisLineBase := JobPlanningLine."Remaining Qty. (Base)";
                ReservQty := JobPlanningLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", '',
                  0, JobPlanningLine."Job Contract Entry No.",
                  JobPlanningLine."Variant Code", JobPlanningLine."Location Code", JobPlanningLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                sender.InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, JobPlanningLine."Planning Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (JobPlanningLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure CheckItemType(CalcReservEntry: Record "Reservation Entry")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if (CalcReservEntry."Source Type" <> Database::"Purchase Line") or (CalcReservEntry."Source Subtype" <> CalcReservEntry."Source Subtype"::"1") then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", CalcReservEntry."Source ID");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", CalcReservEntry."Item No.");
        PurchaseLine.SetRange("Special Order", false);
        if PurchaseLine.FindFirst() then
            if PurchaseLine.IsNonInventoriableItem() then
                Error(NonInvReserveTypeErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(JobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedQtyBase(JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; var QuantityBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasErrorCheck(NewJobPlanningLine: Record "Job Planning Line"; OldJobPlanningLine: Record "Job Planning Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Use procedure BindToTracking()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeBindToProdOrder(JobPlanningLine: Record "Job Planning Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveJobPlanningLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoReserveOnBeforeStopReservation', '', false, false)]
    local procedure OnAutoReserveOnBeforeStopReservation(var CalcReservEntry: Record "Reservation Entry"; var StopReservation: Boolean; SourceRecRef: RecordRef);
    begin
        if MatchThisTable(CalcReservEntry."Source Type") then
            StopReservation := CalcReservEntry."Source Subtype" <> 2;
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceForReservationOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;
#endif
    // codeunit Create Reserv. Entry

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnCheckSourceTypeSubtype', '', false, false)]
    local procedure CheckSourceTypeSubtype(var ReservationEntry: Record "Reservation Entry"; var IsError: Boolean)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            IsError := ReservationEntry."Source Subtype" <> 2;
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Job Planning Line" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[6] := true;  // RefNo
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    var
        Job: Record Job;
    begin
        if ReservationEntry."Source Type" = Database::"Job Planning Line" then
            Description := StrSubstNo(SourceDoc2Txt, Job.TableCaption(), ReservationEntry."Source ID");
    end;

    procedure InitFromJobPlanningLine(var TransactionSpecification: Record "Tracking Specification"; var JobPlanningLine: Record "Job Planning Line")
    begin
        TransactionSpecification.Init();
        TransactionSpecification.SetItemData(
            JobPlanningLine."No.", JobPlanningLine.Description, JobPlanningLine."Location Code", JobPlanningLine."Variant Code",
            JobPlanningLine."Bin Code", JobPlanningLine."Qty. per Unit of Measure", JobPlanningLine."Qty. Rounding Precision (Base)");
        TransactionSpecification.SetSource(
            Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", '', 0);
        TransactionSpecification.SetQuantities(
            JobPlanningLine."Remaining Qty. (Base)", JobPlanningLine."Remaining Qty.", JobPlanningLine."Remaining Qty. (Base)",
            JobPlanningLine."Remaining Qty.", JobPlanningLine."Remaining Qty. (Base)",
            JobPlanningLine."Quantity" - JobPlanningLine."Remaining Qty.",
            JobPlanningLine."Quantity (Base)" - JobPlanningLine."Remaining Qty. (Base)");

        OnAfterInitFromJobPlanningLine(TransactionSpecification, JobPlanningLine);
#if not CLEAN25
        TransactionSpecification.RunOnAfterInitFromJobPlanningLine(TransactionSpecification, JobPlanningLine);
#endif
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnTestItemType', '', false, false)]
    local procedure OnTestItemType(SourceRecRef: RecordRef)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if SourceRecRef.Number = Database::"Job Planning Line" then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobPlanningLine(var TrackingSpecification: Record "Tracking Specification"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnReserveBindingOrder', '', false, false)]
    local procedure OnReserveBindingOrder(var RequisitionLine: Record "Requisition Line"; TrackingSpecification: Record "Tracking Specification"; SourceDescription: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal; UpdateReserve: Boolean)
    begin
        if RequisitionLine."Demand Type" = Database::"Job Planning Line" then
            JobPlanningLineBindToTracking(RequisitionLine, TrackingSpecification, SourceDescription, ExpectedDate, ReservQty, ReservQtyBase, UpdateReserve);
    end;

    local procedure JobPlanningLineBindToTracking(RequisitionLine: Record "Requisition Line"; TrackingSpecification: Record "Tracking Specification"; Description: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal; UpdateReserve: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job Contract Entry No.", RequisitionLine."Demand Line No.");
        JobPlanningLine.FindFirst();
        BindToTracking(JobPlanningLine, TrackingSpecification, Description, ExpectedDate, ReservQty, ReservQtyBase);
        if UpdateReserve then
            if JobPlanningLine.Reserve = JobPlanningLine.Reserve::Never then begin
                JobPlanningLine.Reserve := JobPlanningLine.Reserve::Optional;
                JobPlanningLine.Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OrderTrackingManagementOnSetSourceRecord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    var
        JobPlanningLine: Record "Job Planning Line";
        SourceRecRef: RecordRef;
    begin
        SourceRecRef.GetTable(SourceRecordVar);
        if MatchThisTable(SourceRecRef.Number) then begin
            JobPlanningLine := SourceRecordVar;
            SetJobPlanningLine(JobPlanningLine, ReservationEntry, ItemLedgerEntry2);
        end;
    end;

    local procedure SetJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var ReservEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        JobUsageLink: Record "Job Usage Link";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        ReservEntry."Source Type" := Database::"Job Planning Line";

        ReservEntry.InitSortingAndFilters(false);
        JobPlanningLine.SetReservationFilters(ReservEntry);

        if JobPlanningLine."Qty. Posted" <> 0 then begin
            JobUsageLink.SetRange("Job No.", JobPlanningLine."Job No.");
            JobUsageLink.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
            JobUsageLink.SetRange("Line No.", JobPlanningLine."Line No.");
            JobUsageLink.SetLoadFields("Entry No.");
            if JobUsageLink.Find('-') then
                repeat
                    JobLedgerEntry.SetLoadFields("Ledger Entry No.");
                    JobLedgerEntry.Get(JobUsageLink."Entry No.");
                    if ItemLedgerEntry.Get(JobLedgerEntry."Ledger Entry No.") then
                        ItemLedgerEntry.Mark(true);
                until JobUsageLink.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnInsertOrderTrackingEntry', '', false, false)]
    local procedure OnInsertOrderTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if OrderTrackingEntry."For Type" = Database::"Job Planning Line" then begin
            JobPlanningLine.SetRange("Job No.", OrderTrackingEntry."For ID");
            JobPlanningLine.SetRange(Status, OrderTrackingEntry."For Subtype");
            JobPlanningLine.SetRange("Job Contract Entry No.", OrderTrackingEntry."For Ref. No.");
            JobPlanningLine.SetLoadFields("Planning Date");
            if JobPlanningLine.FindFirst() then begin
                OrderTrackingEntry."Starting Date" := JobPlanningLine."Planning Date";
                OrderTrackingEntry."Ending Date" := JobPlanningLine."Planning Date";
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnGetSourceShipmentDate', '', false, false)]
    local procedure OnGetSourceShipmentDate(var TrackingSpecification: Record "Tracking Specification"; var ShipmentDate: Date);
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if TrackingSpecification."Source Type" = Database::"Job Planning Line" then begin
            JobPlanningLine.SetRange(Status, TrackingSpecification."Source Subtype");
            JobPlanningLine.SetRange("Job No.", TrackingSpecification."Source ID");
            JobPlanningLine.SetRange("Job Contract Entry No.", TrackingSpecification."Source Ref. No.");
            JobPlanningLine.SetLoadFields("Planning Date");
            JobPlanningLine.FindFirst();
            ShipmentDate := JobPlanningLine."Planning Date";
        end;
    end;
}
