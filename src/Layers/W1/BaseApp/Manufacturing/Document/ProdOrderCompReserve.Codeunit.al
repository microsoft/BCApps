// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Item;

codeunit 99000838 "Prod. Order Comp.-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
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
        DeleteItemTracking: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Reserved quantity cannot be greater than %1';
#pragma warning restore AA0470
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';
#pragma warning disable AA0470
        Text010: Label 'Firm Planned %1';
        Text011: Label 'Released %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SourceDoc3Txt: Label '%1 %2 %3', Locked = true;

    procedure CreateReservation(ProdOrderComponent: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004);

        ProdOrderComponent.TestField("Item No.");
        ProdOrderComponent.TestField("Due Date");
        ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
        if Abs(ProdOrderComponent."Remaining Qty. (Base)") < Abs(ProdOrderComponent."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ProdOrderComponent."Remaining Qty. (Base)") - Abs(ProdOrderComponent."Reserved Qty. (Base)"));

        ProdOrderComponent.TestField("Location Code", FromTrackingSpecification."Location Code");
        ProdOrderComponent.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        if QuantityBase > 0 then
            ShipmentDate := ProdOrderComponent."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ProdOrderComponent."Due Date";
        end;

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(ProdOrderComponent, Quantity, QuantityBase, ForReservationEntry, FromTrackingSpecification, IsHandled, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(),
                ProdOrderComponent."Prod. Order No.", '', ProdOrderComponent."Prod. Order Line No.",
                ProdOrderComponent."Line No.", ProdOrderComponent."Qty. per Unit of Measure",
                Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
            ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateBindingReservation(ProdOrderComponent: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(ProdOrderComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure Caption(ProdOrderComponent: Record "Prod. Order Component") CaptionText: Text
    begin
        CaptionText := ProdOrderComponent.GetSourceCaption();
    end;

    procedure FindReservEntry(ProdOrderComponent: Record "Prod. Order Component"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ProdOrderComponent.SetReservationFilters(ReservationEntry);
        if not ReservationEntry.IsEmpty() then
            exit(ReservationEntry.FindLast());
    end;

    procedure GetReservedQtyFromInventory(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ProdOrderComponent.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(ProductionOrder: Record "Production Order"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(
          Database::"Prod. Order Component", ProductionOrder.Status.AsInteger(), ProductionOrder."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure ReservEntryExist(ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEngineMgt.InitFilterAndSortingLookupFor(ReservationEntry, false);
        ProdOrderComponent.SetReservationFilters(ReservationEntry);
        exit(not ReservationEntry.IsEmpty);
    end;

    procedure VerifyChange(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if NewProdOrderComponent.Status = NewProdOrderComponent.Status::Finished then
            exit;
        if Blocked then
            exit;
        if NewProdOrderComponent."Line No." = 0 then
            if not ProdOrderComponent.Get(
                 NewProdOrderComponent.Status,
                 NewProdOrderComponent."Prod. Order No.",
                 NewProdOrderComponent."Prod. Order Line No.",
                 NewProdOrderComponent."Line No.")
            then
                exit;

        NewProdOrderComponent.CalcFields("Reserved Qty. (Base)");
        ShowError := NewProdOrderComponent."Reserved Qty. (Base)" <> 0;

        if NewProdOrderComponent."Due Date" = 0D then
            if ShowError then
                NewProdOrderComponent.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No." then
            if ShowError then
                NewProdOrderComponent.FieldError("Item No.", Text003)
            else
                HasError := true;
        if NewProdOrderComponent."Location Code" <> OldProdOrderComponent."Location Code" then
            if ShowError then
                NewProdOrderComponent.FieldError("Location Code", Text003)
            else
                HasError := true;
        if (NewProdOrderComponent."Bin Code" <> OldProdOrderComponent."Bin Code") and
           (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
              NewProdOrderComponent."Item No.", NewProdOrderComponent."Bin Code",
              NewProdOrderComponent."Location Code", NewProdOrderComponent."Variant Code",
              Database::"Prod. Order Component", NewProdOrderComponent.Status.AsInteger(),
              NewProdOrderComponent."Prod. Order No.", '', NewProdOrderComponent."Prod. Order Line No.",
              NewProdOrderComponent."Line No."))
        then begin
            if ShowError then
                NewProdOrderComponent.FieldError("Bin Code", Text003);
            HasError := true;
        end;
        if NewProdOrderComponent."Variant Code" <> OldProdOrderComponent."Variant Code" then
            if ShowError then
                NewProdOrderComponent.FieldError("Variant Code", Text003)
            else
                HasError := true;
        if NewProdOrderComponent."Line No." <> OldProdOrderComponent."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewProdOrderComponent, OldProdOrderComponent, HasError, ShowError);

        if HasError then
            if (NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No.") or NewProdOrderComponent.ReservEntryExist() then begin
                if NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No." then begin
                    ReservationManagement.SetReservSource(OldProdOrderComponent);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewProdOrderComponent);
                end else begin
                    ReservationManagement.SetReservSource(NewProdOrderComponent);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewProdOrderComponent."Remaining Qty. (Base)");
            end;

        if HasError or (NewProdOrderComponent."Due Date" <> OldProdOrderComponent."Due Date") then begin
            AssignForPlanning(NewProdOrderComponent);
            if (NewProdOrderComponent."Item No." <> OldProdOrderComponent."Item No.") or
               (NewProdOrderComponent."Variant Code" <> OldProdOrderComponent."Variant Code") or
               (NewProdOrderComponent."Location Code" <> OldProdOrderComponent."Location Code")
            then
                AssignForPlanning(OldProdOrderComponent);
        end;
    end;

    procedure VerifyQuantity(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewProdOrderComponent, OldProdOrderComponent, ReservationManagement, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        if NewProdOrderComponent.Status = NewProdOrderComponent.Status::Finished then
            exit;
        if NewProdOrderComponent."Line No." = OldProdOrderComponent."Line No." then
            if NewProdOrderComponent."Remaining Qty. (Base)" = OldProdOrderComponent."Remaining Qty. (Base)" then
                exit;
        if NewProdOrderComponent."Line No." = 0 then
            if not ProdOrderComponent.Get(NewProdOrderComponent.Status, NewProdOrderComponent."Prod. Order No.", NewProdOrderComponent."Prod. Order Line No.", NewProdOrderComponent."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewProdOrderComponent);
        if NewProdOrderComponent."Qty. per Unit of Measure" <> OldProdOrderComponent."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewProdOrderComponent."Remaining Qty. (Base)" * OldProdOrderComponent."Remaining Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewProdOrderComponent."Remaining Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewProdOrderComponent."Remaining Qty. (Base)");
        AssignForPlanning(NewProdOrderComponent);
    end;

    procedure TransferPOCompToPOComp(var OldProdOrderComponent: Record "Prod. Order Component"; var NewProdOrderComponent: Record "Prod. Order Component"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        OnBeforeTransferPOCompToPOComp(OldProdOrderComponent, NewProdOrderComponent);

        if not FindReservEntry(OldProdOrderComponent, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewProdOrderComponent.TestItemFields(OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code");

        OldReservationEntry.TransferReservations(
            OldReservationEntry, OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code",
            TransferAll, TransferQty, NewProdOrderComponent."Qty. per Unit of Measure",
            Database::"Prod. Order Component", NewProdOrderComponent.Status.AsInteger(), NewProdOrderComponent."Prod. Order No.", '',
            NewProdOrderComponent."Prod. Order Line No.", NewProdOrderComponent."Line No.");
    end;

    procedure TransferPOCompToItemJnlLine(var OldProdOrderComponent: Record "Prod. Order Component"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal)
    begin
        TransferPOCompToItemJnlLineCheckILE(OldProdOrderComponent, NewItemJournalLine, TransferQty, false);
    end;

    procedure TransferPOCompToItemJnlLineCheckILE(var OldProdOrderComponent: Record "Prod. Order Component"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
        IsHandled: Boolean;
    begin
        if not FindReservEntry(OldProdOrderComponent, OldReservationEntry) then
            exit;

        IsHandled := false;
        OnBeforeTransferPOCompToItemJnlLineCheckILE(OldProdOrderComponent, NewItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if CheckApplFromItemEntry then
            if OppositeReservationEntry.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive) then
                if OppositeReservationEntry."Source Type" <> Database::"Item Ledger Entry" then
                    exit;

        // Store initial values
        OldReservationEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservationEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservationEntry.LockTable();
        OldReservationEntry.FindLast();

        // Handle Item Tracking on consumption:
        Clear(CreateReservEntry);
        if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::Consumption then
            if NewItemJournalLine.TrackingExists() then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJournalLine);
                // Try to match against Item Tracking on the prod. order line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(NewItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    OldReservationEntry.ClearTrackingFilter()
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJournalLine.TestItemFields(OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code");

        OnTransferPOCompToItemJnlLineCheckILEOnBeforeCheckTransferQty(OldProdOrderComponent, NewItemJournalLine, OldReservationEntry, TransferQty, TrackedQty);

        if TransferQty = 0 then
            exit;

        ItemTrackingSetup.CopyTrackingFromItemJnlLine(NewItemJournalLine);
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry, ItemTrackingSetup) then
            repeat
                OldReservationEntry.TestItemFields(OldProdOrderComponent."Item No.", OldProdOrderComponent."Variant Code", OldProdOrderComponent."Location Code");

                OnTransferPOCompToItemJnlLineCheckILEOnBeforeTransferReservEntry(NewItemJournalLine, OldReservationEntry);

                TransferQty := CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line",
                    NewItemJournalLine."Entry Type".AsInteger(), NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name", 0,
                    NewItemJournalLine."Line No.", NewItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                OnTransferPOCompToItemJnlLineCheckILEOnAfterTransferReservEntry(NewItemJournalLine, OldReservationEntry);

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
            UnTrackedQty := OldProdOrderComponent."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservationManagement.SetReservSource(OldProdOrderComponent);
                ReservationManagement.DeleteReservEntries(false, OldProdOrderComponent."Remaining Qty. (Base)");
            end;
        end;
    end;

    procedure DeleteLineConfirm(var ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(ProdOrderComponent, ReservationEntry) then
            exit(true);

        ReservationManagement.SetReservSource(ProdOrderComponent);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ProdOrderComponent: Record "Prod. Order Component")
    begin
        if Blocked then
            exit;

        Clear(ReservationManagement);
        ReservationManagement.SetReservSource(ProdOrderComponent);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1);
        // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        OnDeleteLineOnAfterDeleteReservEntries(ProdOrderComponent);
        ProdOrderComponent.CalcFields(ProdOrderComponent."Reserved Qty. (Base)");
        AssignForPlanning(ProdOrderComponent);
    end;

    local procedure AssignForPlanning(var ProdOrderComponent: Record "Prod. Order Component")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ProdOrderComponent.Status = ProdOrderComponent.Status::Simulated then
            exit;
        if ProdOrderComponent."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Location Code", ProdOrderComponent."Due Date");
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ProdOrderComponent: Record "Prod. Order Component")
    var
        TrackingSpecification: Record "Tracking Specification";
        MfgItemTrackingMgt: Codeunit "Mfg. Item Tracking Mgt.";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if ProdOrderComponent.Status = ProdOrderComponent.Status::Finished then
            MfgItemTrackingMgt.ShowItemTrackingForProdOrderComp(
                Database::"Prod. Order Component", ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.")
        else begin
            ProdOrderComponent.TestField("Item No.");
            InitFromProdOrderComp(TrackingSpecification, ProdOrderComponent);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderComponent."Due Date");
            ItemTrackingLines.SetInbound(ProdOrderComponent.IsInbound());
            OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ProdOrderComponent, ItemTrackingLines);
            ItemTrackingLines.RunModal();
        end;

        OnAfterCallItemTracking(ProdOrderComponent);
    end;

    procedure UpdateItemTrackingAfterPosting(ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservationEntry.SetSourceFilter(
            Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Line No.", true);
        ReservationEntry.SetSourceFilter('', ProdOrderComponent."Prod. Order Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure BindToTracking(ProdOrderComponent: Record "Prod. Order Component"; TrackingSpecification: Record "Tracking Specification"; Description: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal)
    begin
        SetBinding("Reservation Binding"::"Order-to-Order");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, Description, ExpectedDate, ReservQty, ReservQtyBase);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToPurchase(ProdOrderComponent: Record "Prod. Order Component"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::Microsoft.Purchases.Document."Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToProdOrder(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
            ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToRequisition(ProdOrderComponent: Record "Prod. Order Component"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
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
        CreateBindingReservation(ProdOrderComponent, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToAssembly(ProdOrderComponent: Record "Prod. Order Component"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::Microsoft.Assembly.Document."Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToTransfer(ProdOrderComponent: Record "Prod. Order Component"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          Database::Microsoft.Inventory.Transfer."Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComponent, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;
#endif

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderComponent);
            ProdOrderComponent.Find();
            QtyPerUOM := ProdOrderComponent.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SourceRecordRef.SetTable(ProdOrderComponent);
        ProdOrderComponent.TestField("Due Date");

        ProdOrderComponent.SetReservationEntry(ReservationEntry);

        CaptionText := ProdOrderComponent.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger(),
                         Enum::"Reservation Summary Type"::"Planned Prod. Order Comp.".AsInteger(),
                         Enum::"Reservation Summary Type"::"Firm Planned Prod. Order Comp.".AsInteger(),
                         Enum::"Reservation Summary Type"::"Released Prod. Order Comp.".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Prod. Order Component");
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
        AvailableProdOrderComp: page "Available - Prod. Order Comp.";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableProdOrderComp);
            AvailableProdOrderComp.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableProdOrderComp.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableProdOrderComp.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure ReservationOnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Prod. Order Component");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure ReservationOnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Prod. Order Component") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Ledger Entry-Reserve", 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary" temporary; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal; var IsHandled: Boolean; sender: Codeunit "Item Ledger Entry-Reserve")
    var
        CheckOutbound: Boolean;
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            CheckOutbound := Location."Bin Mandatory" or Location."Require Pick";
            sender.DrillDownTotalQuantity(SourceRecRef, EntrySummary, ReservEntry, MaxQtyToReserve, CheckOutbound, true);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ProdOrderComp);
            CreateReservation(ProdOrderComp, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
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
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(SourceType) then begin
            ProdOrderComp.Reset();
            ProdOrderComp.SetRange(Status, SourceSubtype);
            ProdOrderComp.SetRange("Prod. Order No.", SourceID);
            ProdOrderComp.SetRange("Prod. Order Line No.", SourceProdOrderLine);
            ProdOrderComp.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, ProdOrderComp);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderComp);
            ProdOrderComp.SetReservationFilters(ReservEntry);
            CaptionText := ProdOrderComp.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ProdOrderComp);
            ProdOrderComp.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
        ReturnValue: Decimal;
    begin
        IsHandled := false;
        OnBeforeGetSourceValue(ReservationEntry, SourceRecordRef, ReturnOption, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);


        ProdOrderComponent.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(ProdOrderComponent);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ProdOrderComponent."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ProdOrderComponent."Expected Qty. (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Status: Enum "Production Order Status"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        AvailabilityFilter: Text;
    begin
        if not ProdOrderComponent.ReadPermission then
            exit;

        ProdOrderComponent.SetAutoCalcFields("Reserved Qty. (Base)");
        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ProdOrderComponent.FilterLinesForReservation(ReservationEntry, Status.AsInteger(), AvailabilityFilter, Positive);
        if ProdOrderComponent.FindSet() then
            repeat
                TempEntrySummary."Total Reserved Quantity" -= ProdOrderComponent."Reserved Qty. (Base)";
                TotalQuantity += ProdOrderComponent."Remaining Qty. (Base)";
            until ProdOrderComponent.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity < 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"Prod. Order Component";
            if Status = ProdOrderComponent.Status::"Firm Planned" then
                TempEntrySummary."Summary Type" :=
                    CopyStr(StrSubstNo(Text010, ProdOrderComponent.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"))
            else
                TempEntrySummary."Summary Type" :=
                    CopyStr(StrSubstNo(Text011, ProdOrderComponent.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [Enum::"Reservation Summary Type"::"Firm Planned Prod. Order Comp.".AsInteger(),
                                           Enum::"Reservation Summary Type"::"Released Prod. Order Comp.".AsInteger()]
        then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Enum::"Production Order Status".FromInteger(ReservSummEntry."Entry No." - 71), Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange(Status, ReservationEntry."Source Subtype");
        ProdOrderComponent.SetRange("Prod. Order No.", ReservationEntry."Source ID");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ReservationEntry."Source Prod. Order Line");
        ProdOrderComponent.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(0, ProdOrderComponent);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterAutoReserveOneLine', '', false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean; var sender: Codeunit "Reservation Management")
    begin
        if MatchThisEntry(ReservSummEntryNo) then
            AutoReserveProdOrderComp(
                CalcReservEntry, sender, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase,
                Description, AvailabilityDate, Search, NextStep, Positive);
    end;

    local procedure AutoReserveProdOrderComp(var CalcReservEntry: Record "Reservation Entry"; var sender: Codeunit "Reservation Management"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; Positive: Boolean)
    var
        CallTrackingSpecification: Record "Tracking Specification";
        ProdOrderComp: Record "Prod. Order Component";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
#if not CLEAN25
        IsReserved := false;
        sender.RunOnBeforeAutoReserveProdOrderComp(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;
#endif
        IsReserved := false;
        OnBeforeAutoReserveProdOrderComp(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        ProdOrderComp.SetAutoCalcFields("Reserved Qty. (Base)");
        ProdOrderComp.FilterLinesForReservation(
            CalcReservEntry, ReservSummEntryNo - Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger(),
            sender.GetAvailabilityFilter(AvailabilityDate), Positive);
        if ProdOrderComp.Find(Search) then
            repeat
                QtyThisLine := ProdOrderComp."Remaining Quantity";
                QtyThisLineBase := ProdOrderComp."Remaining Qty. (Base)";
                ReservQty := ProdOrderComp."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                sender.SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, ProdOrderComp.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                    Database::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", '',
                    ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.",
                    ProdOrderComp."Variant Code", ProdOrderComp."Location Code", ProdOrderComp."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                sender.InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, ProdOrderComp."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (ProdOrderComp.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallItemTracking(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOCompToPOComp(var OldProdOrderComp: Record "Prod. Order Component"; var NewProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOCompToItemJnlLineCheckILE(var ProdOrderComp: Record "Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewProdOrderComponent: Record "Prod. Order Component"; OldProdOrderComponent: Record "Prod. Order Component"; var ReservationManagement: Codeunit "Reservation Management"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnAfterDeleteReservEntries(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewProdOrderComp: Record "Prod. Order Component"; OldProdOrderComp: Record "Prod. Order Component"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOCompToItemJnlLineCheckILEOnAfterTransferReservEntry(NewItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOCompToItemJnlLineCheckILEOnBeforeCheckTransferQty(var OldProdOrderComponent: Record "Prod. Order Component"; var NewItemJournalLine: Record "Item Journal Line"; var OldReservationEntry: Record "Reservation Entry"; var TransferQty: Decimal; var TrackedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOCompToItemJnlLineCheckILEOnBeforeTransferReservEntry(NewItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"; var ReturnValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var ProdOrderComponent: Record "Prod. Order Component"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveProdOrderComp(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceForReservationOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ProdOrderComp: Record "Prod. Order Component")
    begin
    end;
#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoReserveOnBeforeStopReservation', '', false, false)]
    local procedure OnAutoReserveOnBeforeStopReservation(var CalcReservEntry: Record "Reservation Entry"; var StopReservation: Boolean; SourceRecRef: RecordRef);
    begin
        if MatchThisTable(CalcReservEntry."Source Type") then
            StopReservation := CalcReservEntry."Source Subtype" < 2; // Not simulated or planned
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoTrackOnCheckSourceType', '', false, false)]
    local procedure OnAutoTrackOnCheckSourceType(var ReservationEntry: Record "Reservation Entry"; var ShouldExit: Boolean)
    begin
        if ReservationEntry."Source Type" = Database::"Prod. Order Component" then
            if ReservationEntry."Source Subtype" = 0 then
                ShouldExit := true; // Not simulation
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
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ReservEntry."Source Type" = Database::"Prod. Order Component" then begin
            ProdOrderComponent.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
            ReservEntry."Expected Receipt Date" := 0D;
            ReservEntry."Shipment Date" := ProdOrderComponent."Due Date";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Prod. Order Component" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[5] := true;  // ProdOrderLine
            PointerFieldIsActive[6] := true;  // RefNo
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ReservationEntry."Source Type" = Database::"Prod. Order Component" then
            Description :=
                StrSubstNo(SourceDoc3Txt, ProdOrderComponent.TableCaption(),
                Enum::"Production Order Status".FromInteger(ReservationEntry."Source Subtype"), ReservationEntry."Source ID");
    end;

    procedure InitFromProdOrderComp(var TrackingSpecification: Record "Tracking Specification"; var ProdOrderComp: Record "Prod. Order Component")
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
            ProdOrderComp."Item No.", ProdOrderComp.Description, ProdOrderComp."Location Code", ProdOrderComp."Variant Code",
            ProdOrderComp."Bin Code", ProdOrderComp."Qty. per Unit of Measure", ProdOrderComp."Qty. Rounding Precision (Base)");
        TrackingSpecification.SetSource(
            Database::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp."Line No.", '',
            ProdOrderComp."Prod. Order Line No.");
        TrackingSpecification.SetQuantities(
            ProdOrderComp."Remaining Qty. (Base)", ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)",
            ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)",
            ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Remaining Qty. (Base)",
            ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Remaining Qty. (Base)");

        OnAfterInitFromProdOrderComp(TrackingSpecification, ProdOrderComp);
#if not CLEAN25
        TrackingSpecification.RunOnAfterInitFromProdOrderComp(TrackingSpecification, ProdOrderComp);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromProdOrderComp(var TrackingSpecification: Record "Tracking Specification"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSummEntryNo', '', false, false)]
    local procedure OnBeforeSummEntryNo(ReservationEntry: Record "Reservation Entry"; var ReturnValue: Integer)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ReturnValue := Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger() + ReservationEntry."Source Subtype";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnUpdateSourceCost', '', false, false)]
    local procedure ReservationEntryOnUpdateSourceCost(ReservationEntry: Record "Reservation Entry"; UnitCost: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        QtyToReserveNonBase: Decimal;
        QtyToReserve: Decimal;
        QtyReservedNonBase: Decimal;
        QtyReserved: Decimal;
    begin
        if MatchThisTable(ReservationEntry."Source Type") then begin
            ProdOrderComp.Get(
                ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Prod. Order Line",
                ReservationEntry."Source Ref. No.");
            ProdOrderComp.GetReservationQty(QtyReservedNonBase, QtyReserved, QtyToReserveNonBase, QtyToReserve);
            if ProdOrderComp."Qty. per Unit of Measure" <> 0 then
                ProdOrderComp."Unit Cost" :=
                    Round(ProdOrderComp."Unit Cost" / ProdOrderComp."Qty. per Unit of Measure");
            if ProdOrderComp."Expected Qty. (Base)" <> 0 then
                ProdOrderComp."Unit Cost" :=
                    Round(
                        (ProdOrderComp."Unit Cost" * (ProdOrderComp."Expected Qty. (Base)" - QtyReserved) + UnitCost * QtyReserved) /
                         ProdOrderComp."Expected Qty. (Base)", 0.00001);
            if ProdOrderComp."Qty. per Unit of Measure" <> 0 then
                ProdOrderComp."Unit Cost" :=
                    Round(ProdOrderComp."Unit Cost" * ProdOrderComp."Qty. per Unit of Measure");
            ProdOrderComp.Validate("Unit Cost");
            ProdOrderComp.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnReserveBindingOrder', '', false, false)]
    local procedure OnReserveBindingOrder(var RequisitionLine: Record "Requisition Line"; TrackingSpecification: Record "Tracking Specification"; SourceDescription: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal)
    begin
        if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then
            ProdOrderCompBindToTracking(RequisitionLine, TrackingSpecification, SourceDescription, ExpectedDate, ReservQty, ReservQtyBase);
    end;

    local procedure ProdOrderCompBindToTracking(RequisitionLine: Record "Requisition Line"; TrackingSpecification: Record "Tracking Specification"; SourceDescription: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.", RequisitionLine."Demand Ref. No.");
        BindToTracking(ProdOrderComponent, TrackingSpecification, SourceDescription, ExpectedDate, ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OrderTrackingManagementOnSetSourceRecord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    var
        ProdOrderComp: Record "Prod. Order Component";
        SourceRecRef: RecordRef;
    begin
        SourceRecRef.GetTable(SourceRecordVar);
        if MatchThisTable(SourceRecRef.Number) then begin
            ProdOrderComp := SourceRecordVar;
            SetProdOrderComp(ProdOrderComp, ReservationEntry, ItemLedgerEntry2);
        end;
    end;

    local procedure SetProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; var ReservEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ReservEntry.InitSortingAndFilters(false);
        ProdOrderComp.SetReservationFilters(ReservEntry);

        if (ProdOrderComp."Remaining Quantity" <> ProdOrderComp."Expected Quantity") and
           (ProdOrderComp.Status in [ProdOrderComp.Status::Released, ProdOrderComp.Status::Finished])
        then begin
            ProdOrderLine.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");

            ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
            ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
            ItemLedgerEntry.SetRange("Order No.", ProdOrderComp."Prod. Order No.");
            ItemLedgerEntry.SetRange("Order Line No.", ProdOrderComp."Prod. Order Line No.");
            ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            ItemLedgerEntry.SetRange("Item No.", ProdOrderComp."Item No.");
            if ItemLedgerEntry.Find('-') then
                repeat
                    ItemLedgerEntry.Mark(true);
                until ItemLedgerEntry.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnInsertOrderTrackingEntry', '', false, false)]
    local procedure OnInsertOrderTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry")
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if OrderTrackingEntry."For Type" = DATABASE::"Prod. Order Component" then
            if ProdOrderComp.Get(OrderTrackingEntry."For Subtype", OrderTrackingEntry."For ID", OrderTrackingEntry."For Prod. Order Line", OrderTrackingEntry."For Ref. No.") then begin
                OrderTrackingEntry."Starting Date" := ProdOrderComp."Due Date";
                if ProdOrderLine.Get(OrderTrackingEntry."For Subtype", OrderTrackingEntry."For ID", OrderTrackingEntry."For Prod. Order Line") then
                    OrderTrackingEntry."Ending Date" := ProdOrderLine."Ending Date";
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var ProdOrderComponent: Record "Prod. Order Component"; var Quantity: Decimal; var QuantityBase: Decimal; var ReservationEntry: Record "Reservation Entry"; var FromTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean; ExpectedReceiptDate: Date; Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnGetSourceShipmentDate', '', false, false)]
    local procedure OnGetSourceShipmentDate(var TrackingSpecification: Record "Tracking Specification"; var ShipmentDate: Date);
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if TrackingSpecification."Source Type" = Database::"Prod. Order Component" then begin
            ProdOrderComponent.Get(
                TrackingSpecification."Source Subtype", TrackingSpecification."Source ID",
                TrackingSpecification."Source Prod. Order Line", TrackingSpecification."Source Ref. No.");
            ShipmentDate := ProdOrderComponent."Due Date";
        end;
    end;

    procedure TransferPlanningCompToPOComp(var OldPlanningComponent: Record "Planning Component"; var NewProdOrderComponent: Record "Prod. Order Component"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
    begin
        if not PlngComponentReserve.FindReservEntry(OldPlanningComponent, OldReservationEntry) then
            exit;

        NewProdOrderComponent.TestItemFields(
          OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

        PlngComponentReserve.TransferReservations(
          OldPlanningComponent, OldReservationEntry, TransferAll, TransferQty, NewProdOrderComponent."Qty. per Unit of Measure",
          DATABASE::"Prod. Order Component", NewProdOrderComponent.Status.AsInteger(), NewProdOrderComponent."Prod. Order No.",
          '', NewProdOrderComponent."Prod. Order Line No.", NewProdOrderComponent."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Plng. Component-Reserve", 'OnUpdateDerivedTrackingOnAfterSetReservationEntryFilters', '', false, false)]
    local procedure OnUpdateDerivedTrackingOnAfterSetReservationEntryFilters(var ReservationEntry: Record "Reservation Entry"; PlanningComponent: Record "Planning Component")
    begin
        case PlanningComponent."Ref. Order Type" of
            PlanningComponent."Ref. Order Type"::"Prod. Order":
                ReservationEntry.SetSourceFilter(
                    DATABASE::"Prod. Order Component", PlanningComponent."Ref. Order Status".AsInteger(),
                    PlanningComponent."Ref. Order No.", PlanningComponent."Line No.", false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnSetSourceForProdOrderComp', '', false, false)]
    local procedure OnSetSourceForProdOrderComp(SourceRecRef: RecordRef; var CalcReservEntry: Record "Reservation Entry"; var EntryIsPositive: Boolean)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if not MatchThisTable(SourceRecRef.Number) then
            exit;

        SourceRecRef.SetTable(ProdOrderComp);
        ProdOrderComp.SetReservationEntry(CalcReservEntry);
        OnSetProdOrderCompOnBeforeUpdateReservation(CalcReservEntry, ProdOrderComp);
#if not CLEAN26
        ReservationManagement.RunOnSetProdOrderCompOnBeforeUpdateReservation(CalcReservEntry, ProdOrderComp);
#endif
        EntryIsPositive := ProdOrderComp."Remaining Qty. (Base)" > 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetProdOrderCompOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnReserveBindingOrderToPurch', '', false, false)]
    local procedure OnReserveBindingOrderToPurch(var RequisitionLine: Record "Requisition Line"; var PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        TrackingSpecification: Record "Tracking Specification";
    begin
        case RequisitionLine."Demand Type" of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComp.Get(
                      RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.", RequisitionLine."Demand Ref. No.");
                    TrackingSpecification.InitTrackingSpecification(
                        Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
                        PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
                    BindToTracking(
                        ProdOrderComp, TrackingSpecification, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnInitPurchOrderLineOnBeforeUpdateQuantity', '', false, false)]
    local procedure OnInitPurchOrderLineOnBeforeUpdateQuantity(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
        PurchOrderLine."Prod. Order No." := RequisitionLine."Prod. Order No.";
        PurchOrderLine."Prod. Order Line No." := RequisitionLine."Prod. Order Line No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Line-Reserve", 'OnAfterDeleteLine', '', false, false)]
    local procedure OnAfterDeleteLine(var RequisitionLine: Record "Requisition Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
        QtyTracked: Decimal;
    begin
        if (RequisitionLine."Action Message" = RequisitionLine."Action Message"::Cancel) and
           (RequisitionLine."Planning Line Origin" = RequisitionLine."Planning Line Origin"::Planning) and
           (RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::"Prod. Order")
        then begin
            ProdOrderComponent.SetAutoCalcFields("Reserved Qty. (Base)");
            ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.");
            ProdOrderComponent.SetRange(Status, RequisitionLine."Ref. Order Status");
            ProdOrderComponent.SetRange("Prod. Order No.", RequisitionLine."Ref. Order No.");
            ProdOrderComponent.SetRange("Prod. Order Line No.", RequisitionLine."Ref. Line No.");
            if ProdOrderComponent.FindSet() then
                repeat
                    QtyTracked := ProdOrderComponent."Reserved Qty. (Base)";
                    ReservationEntry.Reset();
                    ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
                    ProdOrderComponent.SetReservationFilters(ReservationEntry);
                    ReservationEntry.SetFilter("Reservation Status", '<>%1', ReservationEntry."Reservation Status"::Reservation);
                    if ReservationEntry.FindSet() then
                        repeat
                            QtyTracked := QtyTracked - ReservationEntry."Quantity (Base)";
                        until ReservationEntry.Next() = 0;
                    ReservationManagement.SetReservSource(ProdOrderComponent);
                    ReservationManagement.DeleteReservEntries(QtyTracked = 0, QtyTracked);
                    ReservationManagement.AutoTrack(ProdOrderComponent."Remaining Qty. (Base)");
                until ProdOrderComponent.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcResQtyOnProdOrderComp', '', false, false)]
    local procedure OnCalcResQtyOnProdOrderComp(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("Res. Qty. on Prod. Order Comp.");
        Result := Item."Res. Qty. on Prod. Order Comp.";
    end;
}
