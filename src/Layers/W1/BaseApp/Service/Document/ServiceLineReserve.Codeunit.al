// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;

codeunit 99000842 "Service Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        DeleteItemTracking: Boolean;

        Text000Err: Label 'Codeunit is not initialized correctly.';
        Text001Err: Label 'Reserved quantity cannot be greater than %1', Comment = '%1 - quantity';
        Text002Err: Label 'must be filled in when a quantity is reserved';
        Text003Err: Label 'must not be changed when a quantity is reserved';
        Text004Err: Label 'must not be filled in when a quantity is reserved';
        SummaryTypeTxt: Label '%1', Locked = true;
        SourceDoc2Txt: Label '%1 %2', Locked = true;

    procedure CreateReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text000Err);

        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("No.");
        ServiceLine.TestField("Needed by Date");
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ServiceLine."Outstanding Qty. (Base)") < Abs(ServiceLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text001Err,
              Abs(ServiceLine."Outstanding Qty. (Base)") - Abs(ServiceLine."Reserved Qty. (Base)"));

        ServiceLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        ServiceLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase > 0 then
            ShipmentDate := ServiceLine."Needed by Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ServiceLine."Needed by Date";
        end;

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(ServiceLine, Quantity, QuantityBase, ForReservationEntry, IsHandled, FromTrackingSpecification, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(),
                ServiceLine."Document No.", '', 0, ServiceLine."Line No.",
                ServiceLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
            ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(ServiceLine);
    end;

    procedure CreateBindingReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(ServiceLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure Caption(ServiceLine: Record "Service Line") CaptionText: Text
    begin
        CaptionText := ServiceLine.GetSourceCaption();
    end;

    procedure FindReservEntry(ServiceLine: Record "Service Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ServiceLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure ReservQuantity(ServiceLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case ServiceLine."Document Type" of
            ServiceLine."Document Type"::Quote,
            ServiceLine."Document Type"::Order,
            ServiceLine."Document Type"::Invoice:
                begin
                    QtyToReserve := ServiceLine."Outstanding Quantity";
                    QtyToReserveBase := ServiceLine."Outstanding Qty. (Base)";
                end;
            ServiceLine."Document Type"::"Credit Memo":
                begin
                    QtyToReserve := -ServiceLine."Outstanding Quantity";
                    QtyToReserveBase := -ServiceLine."Outstanding Qty. (Base)"
                end;
        end;

        OnAfterReservQuantity(ServiceLine, QtyToReserve, QtyToReserveBase);
    end;

    procedure GetReservedQtyFromInventory(ServiceLine: Record "Service Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ServiceLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(ServiceHeader: Record "Service Header"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure VerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        ServiceLine: Record "Service Line";
        ShowError: Boolean;
        HasError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewServiceLine, OldServiceLine, IsHandled);
        if IsHandled then
            exit;

        if (NewServiceLine.Type <> NewServiceLine.Type::Item) and (OldServiceLine.Type <> OldServiceLine.Type::Item) then
            exit;

        if NewServiceLine."Line No." = 0 then
            if not ServiceLine.Get(NewServiceLine."Document Type", NewServiceLine."Document No.", NewServiceLine."Line No.") then
                exit;

        NewServiceLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewServiceLine."Reserved Qty. (Base)" <> 0;

        if NewServiceLine.Type <> OldServiceLine.Type then
            if ShowError then
                NewServiceLine.FieldError(Type, Text003Err)
            else
                HasError := true;

        if NewServiceLine."No." <> OldServiceLine."No." then
            if ShowError then
                NewServiceLine.FieldError("No.", Text003Err)
            else
                HasError := true;

        if (NewServiceLine."Needed by Date" = 0D) and (OldServiceLine."Needed by Date" <> 0D) then
            if ShowError then
                NewServiceLine.FieldError("Needed by Date", Text002Err)
            else
                HasError := true;

        if NewServiceLine."Variant Code" <> OldServiceLine."Variant Code" then
            if ShowError then
                NewServiceLine.FieldError("Variant Code", Text003Err)
            else
                HasError := true;

        if NewServiceLine."Location Code" <> OldServiceLine."Location Code" then
            if ShowError then
                NewServiceLine.FieldError("Location Code", Text003Err)
            else
                HasError := true;

        if (NewServiceLine.Type = NewServiceLine.Type::Item) and (OldServiceLine.Type = OldServiceLine.Type::Item) then
            if (NewServiceLine."Bin Code" <> OldServiceLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewServiceLine."No.", NewServiceLine."Bin Code",
                  NewServiceLine."Location Code", NewServiceLine."Variant Code",
                  DATABASE::"Service Line", NewServiceLine."Document Type".AsInteger(),
                  NewServiceLine."Document No.", '', 0, NewServiceLine."Line No."))
            then begin
                if ShowError then
                    NewServiceLine.FieldError("Bin Code", Text004Err);
                HasError := true;
            end;

        if NewServiceLine."Line No." <> OldServiceLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewServiceLine, OldServiceLine, HasError, ShowError);

        if HasError then
            if (NewServiceLine."No." <> OldServiceLine."No.") or NewServiceLine.ReservEntryExist() then begin
                if NewServiceLine."No." <> OldServiceLine."No." then begin
                    ReservationManagement.SetReservSource(OldServiceLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewServiceLine);
                end else begin
                    ReservationManagement.SetReservSource(NewServiceLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewServiceLine."Outstanding Qty. (Base)");
            end;

        if HasError or (NewServiceLine."Needed by Date" <> OldServiceLine."Needed by Date")
        then begin
            AssignForPlanning(NewServiceLine);
            if (NewServiceLine."No." <> OldServiceLine."No.") or
               (NewServiceLine."Variant Code" <> OldServiceLine."Variant Code") or
               (NewServiceLine."Location Code" <> OldServiceLine."Location Code")
            then
                AssignForPlanning(OldServiceLine);
        end;
    end;

    procedure VerifyQuantity(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        ServiceLine: Record "Service Line";
    begin
        if not (NewServiceLine."Document Type" in
                [NewServiceLine."Document Type"::Quote, NewServiceLine."Document Type"::Order])
        then
            if NewServiceLine."Shipment No." = '' then
                exit;

        if NewServiceLine.Type <> NewServiceLine.Type::Item then
            exit;
        if NewServiceLine."Line No." = OldServiceLine."Line No." then
            if NewServiceLine."Quantity (Base)" = OldServiceLine."Quantity (Base)" then
                exit;
        if NewServiceLine."Line No." = 0 then
            if not ServiceLine.Get(NewServiceLine."Document Type", NewServiceLine."Document No.", NewServiceLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewServiceLine);
        if NewServiceLine."Qty. per Unit of Measure" <> OldServiceLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewServiceLine."Outstanding Qty. (Base)" * OldServiceLine."Outstanding Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(false, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewServiceLine."Outstanding Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewServiceLine."Outstanding Qty. (Base)");
        AssignForPlanning(NewServiceLine);
    end;

    local procedure AssignForPlanning(var ServiceLine: Record "Service Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ServiceLine."Document Type" <> ServiceLine."Document Type"::Order then
            exit;
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;
        if ServiceLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code", ServiceLine."Needed by Date");
    end;

    procedure DeleteLineConfirm(var ServiceLine: Record "Service Line"): Boolean
    begin
        if not ServiceLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(ServiceLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ServiceLine: Record "Service Line")
    begin
        ReservationManagement.SetReservSource(ServiceLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        DeleteInvoiceSpecFromLine(ServiceLine);
        ServiceLine.CalcFields("Reserved Qty. (Base)");
    end;

    procedure CallItemTracking(var ServiceLine: Record "Service Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        InitFromServLine(TrackingSpecification, ServiceLine, false);
        if ((ServiceLine."Document Type" = ServiceLine."Document Type"::Invoice) and
            (ServiceLine."Shipment No." <> ''))
        then
            ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Combined Ship/Rcpt");
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ServiceLine."Needed by Date");
        ItemTrackingLines.SetInbound(ServiceLine.IsInbound());
        OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ServiceLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
    end;

    procedure TransServLineToServLine(var OldServiceLine: Record "Service Line"; var NewServiceLine: Record "Service Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
        IsHandled: Boolean;
    begin
        if not FindReservEntry(OldServiceLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewServiceLine.TestItemFields(OldServiceLine."No.", OldServiceLine."Variant Code", OldServiceLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);
            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestItemFields(OldServiceLine."No.", OldServiceLine."Variant Code", OldServiceLine."Location Code");

                    IsHandled := false;
                    OnTransServLineToServLineOnBeforeCreateReservEntry(OldReservationEntry, OldServiceLine, TransferQty, IsHandled);
                    if not IsHandled then
                        TransferQty :=
                            CreateReservEntry.TransferReservEntry(DATABASE::"Service Line",
                                NewServiceLine."Document Type".AsInteger(), NewServiceLine."Document No.", '', 0,
                                NewServiceLine."Line No.", NewServiceLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end;
    end;

    procedure RetrieveInvoiceSpecification(var ServiceLine: Record "Service Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; Consume: Boolean) OK: Boolean
    var
        SourceTrackingSpecification: Record "Tracking Specification";
    begin
        Clear(TempTrackingSpecification);
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;
        if ((ServiceLine."Document Type" = ServiceLine."Document Type"::Invoice) and
            (ServiceLine."Shipment No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(ServiceLine, TempTrackingSpecification)
        else begin
            InitFromServLine(SourceTrackingSpecification, ServiceLine, Consume);
            OK := ItemTrackingManagement.RetrieveInvoiceSpecWithService(SourceTrackingSpecification, TempTrackingSpecification, Consume);
        end;
    end;

    local procedure RetrieveInvoiceSpecification2(var ServiceLine: Record "Service Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for combined shipment:
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;
        if not FindReservEntry(ServiceLine, ReservationEntry) then
            exit;
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
            ReservationEntry.TestField("Item Ledger Entry No.");
            TrackingSpecification.Get(ReservationEntry."Item Ledger Entry No.");
            TempInvoicingTrackingSpecification := TrackingSpecification;
            TempInvoicingTrackingSpecification."Qty. to Invoice (Base)" := ReservationEntry."Qty. to Invoice (Base)";
            TempInvoicingTrackingSpecification."Qty. to Invoice" :=
              Round(ReservationEntry."Qty. to Invoice (Base)" / ReservationEntry."Qty. per Unit of Measure", UnitOfMeasureManagement.QtyRndPrecision());
            TempInvoicingTrackingSpecification."Buffer Status" := TempInvoicingTrackingSpecification."Buffer Status"::MODIFY;
            TempInvoicingTrackingSpecification.Insert();
            ReservationEntry.Delete();
        until ReservationEntry.Next() = 0;

        OK := TempInvoicingTrackingSpecification.FindFirst();
    end;

    procedure DeleteInvoiceSpecFromHeader(ServiceHeader: Record "Service Header")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromHeader(
          DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");
    end;

    local procedure DeleteInvoiceSpecFromLine(ServiceLine: Record "Service Line")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromLine(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.");
    end;

    procedure TransServLineToItemJnlLine(var ServiceLine: Record "Service Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean) Result: Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransServLineToItemJnlLine(ServiceLine, ItemJournalLine, TransferQty, CheckApplFromItemEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not FindReservEntry(ServiceLine, OldReservationEntry) then
            exit(TransferQty);

        OldReservationEntry.LockTable();
        OldReservationEntry.FindLast();

        ItemJournalLine.TestItemFields(ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJournalLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestItemFields(ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code");

                if CheckApplFromItemEntry then begin
                    OldReservationEntry.TestField("Appl.-from Item Entry");
                    CreateReservEntry.SetApplyFromEntryNo(OldReservationEntry."Appl.-from Item Entry");
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := false;
        end;
        exit(TransferQty);
    end;

    procedure UpdateItemTrackingAfterPosting(ServiceHeader: Record "Service Header")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.SetSourceFilter(DATABASE::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", -1, true);
        ReservationEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure BindToTracking(ServiceLine: Record "Service Line"; TrackingSpecification: Record "Tracking Specification"; Description: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal)
    begin
        SetBinding("Reservation Binding"::"Order-to-Order");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, Description, ExpectedDate, ReservQty, ReservQtyBase);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToPurchase(ServiceLine: Record "Service Line"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Purchases.Document."Purchase Line",
          PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToRequisition(ServiceLine: Record "Service Line"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line",
          0, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToTransfer(ServiceLine: Record "Service Line"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Inventory.Transfer."Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToProdOrder(ServiceLine: Record "Service Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Manufacturing.Document."Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure BindToTracking()', '25.0')]
    procedure BindToAssembly(ServiceLine: Record "Service Line"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::Microsoft.Assembly.Document."Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;
#endif

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ServiceLine);
            ServiceLine.Find();
            if ServiceLine.UpdatePlanned() then begin
                ServiceLine.Modify(true);
                Commit();
            end;
            QtyPerUOM := ServiceLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: record "Reservation Entry"; var CaptionText: Text)
    var
        ServiceLine: Record "Service Line";
    begin
        SourceRecordRef.SetTable(ServiceLine);
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("Needed by Date");

        ServiceLine.SetReservationEntry(ReservationEntry);

        CaptionText := ServiceLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Service Order".AsInteger() - 1);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = Enum::"Reservation Summary Type"::"Service Order".AsInteger());
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = DATABASE::"Service Line");
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
        AvailableServiceLines: page "Available - Service Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableServiceLines);
            AvailableServiceLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableServiceLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableServiceLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure ReservationOnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Service Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure ReservationOnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Service Line") and
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
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ServiceLine);
            CreateReservation(ServiceLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        if MatchThisTable(SourceType) then begin
            ServiceHeader.Reset();
            ServiceHeader.SetRange("Document Type", SourceSubtype);
            ServiceHeader.SetRange("No.", SourceID);
            if SourceSubtype = 0 then
                PAGE.RunModal(PAGE::"Service Quote", ServiceHeader)
            else
                PAGE.RunModal(PAGE::"Service Order", ServiceHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(SourceType) then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", SourceSubtype);
            ServiceLine.SetRange("Document No.", SourceID);
            ServiceLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, ServiceLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ServiceLine);
            ServiceLine.SetReservationFilters(ReservEntry);
            CaptionText := ServiceLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ServiceLine);
            ServiceLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(ServiceLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ServiceLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ServiceLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ServiceLine: Record "Service Line";
        AvailabilityFilter: Text;
    begin
        if not ServiceLine.ReadPermission then
            exit;

        ServiceLine.SetAutoCalcFields("Reserved Qty. (Base)");
        AvailabilityFilter := CalcReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ServiceLine.FindLinesForReservation(CalcReservationEntry, AvailabilityFilter, Positive);
        if ServiceLine.FindSet() then
            repeat
                TempEntrySummary."Total Reserved Quantity" -= ServiceLine."Reserved Qty. (Base)";
                TotalQuantity += ServiceLine."Outstanding Qty. (Base)";
            until ServiceLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity < 0) = Positive then begin
            TempEntrySummary."Table ID" := DATABASE::"Service Line";
            TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(SummaryTypeTxt, ServiceLine.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." = 110 then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        ServiceLine.SetRange("Document No.", ReservationEntry."Source ID");
        ServiceLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"Service Line List", ServiceLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterAutoReserveOneLine', '', false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean; var sender: Codeunit "Reservation Management")
    begin
        if MatchThisEntry(ReservSummEntryNo) then
            AutoReserveServLine(
                CalcReservEntry, sender, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase,
                Description, AvailabilityDate, Search, NextStep, Positive);
    end;

    local procedure AutoReserveServLine(CalcReservEntry: Record "Reservation Entry"; var sender: Codeunit "Reservation Management"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; Positive: Boolean)
    var
        CallTrackingSpecification: Record "Tracking Specification";
        ServiceLine: Record "Service Line";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
#if not CLEAN25
        IsReserved := false;
        sender.RunOnBeforeAutoReserveServLine(
            ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;
#endif
        IsReserved := false;
        OnBeforeAutoReserveServLine(
            ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        ServiceLine.SetAutoCalcFields("Reserved Qty. (Base)");
        ServiceLine.FindLinesForReservation(CalcReservEntry, sender.GetAvailabilityFilter(AvailabilityDate), Positive);
        if ServiceLine.Find(Search) then
            repeat
                QtyThisLine := ServiceLine."Outstanding Quantity";
                QtyThisLineBase := ServiceLine."Outstanding Qty. (Base)";
                ReservQty := ServiceLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                sender.SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, ServiceLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", '', 0, ServiceLine."Line No.",
                  ServiceLine."Variant Code", ServiceLine."Location Code", ServiceLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                sender.InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, ServiceLine."Needed by Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (ServiceLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoTrackOnCheckSourceType', '', false, false)]
    local procedure OnAutoTrackOnCheckSourceType(var ReservationEntry: Record "Reservation Entry"; var ShouldExit: Boolean)
    begin
        if ReservationEntry."Source Type" = Database::"Service Line" then
            if not (ReservationEntry."Source Subtype" in [1, 5]) then
                ShouldExit := true; // Only order, return order
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnTestItemType', '', false, false)]
    local procedure OnTestItemType(SourceRecRef: RecordRef)
    var
        ServiceLine: Record "Service Line";
    begin
        if SourceRecRef.Number = Database::"Service Line" then begin
            SourceRecRef.SetTable(ServiceLine);
            ServiceLine.TestField(Type, ServiceLine.Type::Item);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransServLineToItemJnlLine(var ServLine: Record "Service Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewServiceLine: Record "Service Line"; OldServiceLine: Record "Service Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var ServiceLine: Record "Service Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(ServiceLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransServLineToServLineOnBeforeCreateReservEntry(OldReservationEntry: Record "Reservation Entry"; OldServiceLine: Record "Service Line"; var TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var ServiceLine: Record "Service Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var FromTrackingSpecification: Record "Tracking Specification"; ExpectedReceiptDate: Date; Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservation(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveServLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceForReservationOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ServiceLine: Record "Service Line")
    begin
    end;
#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoReserveOnBeforeStopReservation', '', false, false)]
    local procedure OnAutoReserveOnBeforeStopReservation(var CalcReservEntry: Record "Reservation Entry"; var StopReservation: Boolean);
    begin
        if MatchThisTable(CalcReservEntry."Source Type") then
            StopReservation := not (CalcReservEntry."Source Subtype" = 1); // Only order
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnRevertDateToSourceDate', '', false, false)]
    local procedure OnRevertDateToSourceDate(var ReservEntry: Record "Reservation Entry")
    var
        ServiceLine: Record "Service Line";
    begin
        if ReservEntry."Source Type" = Database::"Service Line" then begin
            ServiceLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
            ReservEntry."Expected Receipt Date" := 0D;
            ReservEntry."Shipment Date" := ServiceLine."Needed by Date";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Service Line" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[6] := true;  // RefNo
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    var
        ServiceLine: Record "Service Line";
    begin
        if ReservationEntry."Source Type" = Database::"Service Line" then
            Description := StrSubstNo(SourceDoc2Txt, ServiceLine.TableCaption(), ReservationEntry."Source ID");
    end;

    procedure InitFromServLine(var TrackingSpecification: Record "Tracking Specification"; var ServiceLine: Record "Service Line"; Consume: Boolean)
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
          ServiceLine."No.", ServiceLine.Description, ServiceLine."Location Code", ServiceLine."Variant Code", ServiceLine."Bin Code",
          ServiceLine."Qty. per Unit of Measure", ServiceLine."Qty. Rounding Precision (Base)");
        TrackingSpecification.SetSource(
          Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", '', 0);

        TrackingSpecification."Quantity (Base)" := ServiceLine."Quantity (Base)";
        if Consume then begin
            TrackingSpecification."Qty. to Invoice (Base)" := ServiceLine."Qty. to Consume (Base)";
            TrackingSpecification."Qty. to Invoice" := ServiceLine."Qty. to Consume";
            TrackingSpecification."Quantity Invoiced (Base)" := ServiceLine."Qty. Consumed (Base)";
        end else begin
            TrackingSpecification."Qty. to Invoice (Base)" := ServiceLine."Qty. to Invoice (Base)";
            TrackingSpecification."Qty. to Invoice" := ServiceLine."Qty. to Invoice";
            TrackingSpecification."Quantity Invoiced (Base)" := ServiceLine."Qty. Invoiced (Base)";
        end;

        if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then begin
            TrackingSpecification."Qty. to Handle" := ServiceLine."Qty. to Invoice";
            TrackingSpecification."Qty. to Handle (Base)" := ServiceLine."Qty. to Invoice (Base)";
            TrackingSpecification."Quantity Handled (Base)" := ServiceLine."Qty. Invoiced (Base)";
        end else begin
            TrackingSpecification."Qty. to Handle" := ServiceLine."Qty. to Ship";
            TrackingSpecification."Qty. to Handle (Base)" := ServiceLine."Qty. to Ship (Base)";
            TrackingSpecification."Quantity Handled (Base)" := ServiceLine."Qty. Shipped (Base)";
        end;

        OnAfterInitFromServLine(TrackingSpecification, ServiceLine);
#if not CLEAN25
        TrackingSpecification.RunOnAfterInitFromServLine(TrackingSpecification, ServiceLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromServLine(var TrackingSpecification: Record "Tracking Specification"; ServiceLine: Record "Service Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnBeforeCheckApplyFromItemEntrySourceType', '', false, false)]
    local procedure OnBeforeCheckApplyFromItemEntrySourceType(var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
        if not MatchThisTable(TrackingSpecification."Source Type") then
            exit;

        if ((TrackingSpecification."Source Subtype" in [3]) and (TrackingSpecification."Quantity (Base)" < 0)) or
            ((TrackingSpecification."Source Subtype" in [1, 2]) and (TrackingSpecification."Quantity (Base)" > 0))
        then
            TrackingSpecification.FieldError("Quantity (Base)");

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSummEntryNo', '', false, false)]
    local procedure OnBeforeSummEntryNo(ReservationEntry: Record "Reservation Entry"; var ReturnValue: Integer)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ReturnValue := Enum::"Reservation Summary Type"::"Service Order".AsInteger();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnUpdateSourceCost', '', false, false)]
    local procedure ReservationEntryOnUpdateSourceCost(ReservationEntry: Record "Reservation Entry"; UnitCost: Decimal)
    var
        ServiceLine: Record "Service Line";
        QtyToReserveNonBase: Decimal;
        QtyToReserve: Decimal;
        QtyReservedNonBase: Decimal;
        QtyReserved: Decimal;
    begin
        if MatchThisTable(ReservationEntry."Source Type") then begin
            ServiceLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
            ServiceLine.GetReservationQty(QtyReservedNonBase, QtyReserved, QtyToReserveNonBase, QtyToReserve);
            if ServiceLine."Qty. per Unit of Measure" <> 0 then
                ServiceLine."Unit Cost (LCY)" :=
                    Round(ServiceLine."Unit Cost (LCY)" / ServiceLine."Qty. per Unit of Measure");
            if ServiceLine."Quantity (Base)" <> 0 then
                ServiceLine."Unit Cost (LCY)" :=
                    Round(
                        (ServiceLine."Unit Cost (LCY)" * (ServiceLine."Quantity (Base)" - QtyReserved) + UnitCost * QtyReserved) / ServiceLine."Quantity (Base)", 0.00001);
            if ServiceLine."Qty. per Unit of Measure" <> 0 then
                ServiceLine."Unit Cost (LCY)" :=
                    Round(ServiceLine."Unit Cost (LCY)" * ServiceLine."Qty. per Unit of Measure");
            ServiceLine.Validate("Unit Cost (LCY)");
            ServiceLine.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnReserveBindingOrder', '', false, false)]
    local procedure OnReserveBindingOrder(var RequisitionLine: Record "Requisition Line"; TrackingSpecification: Record "Tracking Specification"; SourceDescription: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal; UpdateReserve: Boolean)
    begin
        if RequisitionLine."Demand Type" = Database::"Service Line" then
            ServiceLineBindToTracking(RequisitionLine, TrackingSpecification, SourceDescription, ExpectedDate, ReservQty, ReservQtyBase, UpdateReserve);
    end;

    local procedure ServiceLineBindToTracking(RequisitionLine: Record "Requisition Line"; TrackingSpecification: Record "Tracking Specification"; Description: Text[100]; ExpectedDate: Date; ReservQty: Decimal; ReservQtyBase: Decimal; UpdateReserve: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.");
        BindToTracking(ServiceLine, TrackingSpecification, Description, ExpectedDate, ReservQty, ReservQtyBase);
        if UpdateReserve then
            if ServiceLine.Reserve = ServiceLine.Reserve::Never then begin
                ServiceLine.Reserve := ServiceLine.Reserve::Optional;
                ServiceLine.Modify();
            end;
    end;

    // Codeunit "Req. Wksh.-Make Order"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnReserveBindingOrderToPurch', '', false, false)]
    local procedure OnReserveBindingOrderToPurch(var RequisitionLine: Record "Requisition Line"; var PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        ServiceLine: Record "Service Line";
        TrackingSpecification: Record "Tracking Specification";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        case RequisitionLine."Demand Type" of
            Database::"Service Line":
                begin
                    ServiceLine.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.");
                    TrackingSpecification.InitTrackingSpecification(
                        DATABASE::"Purchase Line",
                        PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
                        PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
                    ServiceLineReserve.BindToTracking(
                        ServiceLine, TrackingSpecification, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
                    if ServiceLine.Reserve = ServiceLine.Reserve::Never then begin
                        ServiceLine.Reserve := ServiceLine.Reserve::Optional;
                        ServiceLine.Modify();
                    end;
                end;
        end;
    end;

    // Codeunit OrderTrackingManagement

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OrderTrackingManagementOnSetSourceRecord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    var
        ServiceLine: Record "Service Line";
        SourceRecRef: RecordRef;
    begin
        SourceRecRef.GetTable(SourceRecordVar);
        if MatchThisTable(SourceRecRef.Number) then begin
            ServiceLine := SourceRecordVar;
            SetServiceLine(ServiceLine, ReservationEntry, ItemLedgerEntry2);
        end;
    end;

    local procedure SetServiceLine(var ServiceLine: Record "Service Line"; var ReservEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ServShptLine: Record Microsoft.Service.History."Service Shipment Line";
    begin
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ReservEntry."Source Type" := DATABASE::"Service Line";

        ReservEntry.InitSortingAndFilters(false);
        ServiceLine.SetReservationFilters(ReservEntry);

        if ServiceLine."Qty. Shipped (Base)" <> 0 then begin
            ServShptLine.SetCurrentKey("Order No.", "Order Line No.");
            ServShptLine.SetRange("Order No.", ServiceLine."Document No.");
            ServShptLine.SetRange("Order Line No.", ServiceLine."Line No.");
            if ServShptLine.Find('-') then
                repeat
                    if ItemLedgerEntry.Get(ServShptLine."Item Shpt. Entry No.") then
                        ItemLedgerEntry.Mark(true);
                until ServShptLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnInsertOrderTrackingEntry', '', false, false)]
    local procedure OnInsertOrderTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry")
    var
        ServiceLine: Record "Service Line";
    begin
        if OrderTrackingEntry."For Type" = DATABASE::"Service Line" then
            if ServiceLine.Get(OrderTrackingEntry."For Subtype", OrderTrackingEntry."For ID", OrderTrackingEntry."For Ref. No.") then begin
                OrderTrackingEntry."Starting Date" := ServiceLine."Needed by Date";
                OrderTrackingEntry."Ending Date" := ServiceLine."Needed by Date";
            end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Reservation", 'OnCarryOutReservationOtherDemandType', '', false, false)]
    local procedure OnCarryOutReservationOtherDemandType(var ReservationWkshLine: Record "Reservation Wksh. Line"; DemandType: Enum "Reservation Demand Type")
    begin
        case DemandType of
            DemandType::"Service Orders":
                ReservationWkshLine.SetRange("Source Type", Database::"Service Line");
        end;
    end;

    procedure ServiceInvLineCheck(ServiceLine: Record "Service Line"; ForceRequest: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
    begin
        if not FindReservEntry(ServiceLine, ReservationEntry) then
            exit;
        if ReservationCheckDateConfl.DateConflict(ServiceLine."Needed by Date", ForceRequest, ReservationEntry) then
            if ForceRequest then
                ReservationCheckDateConfl.IssueError(ServiceLine."Needed by Date");
        ReservationCheckDateConfl.UpdateDate(ReservationEntry, ServiceLine."Needed by Date");
        ReservationManagement.SetReservSource(ServiceLine);
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(ServiceLine."Outstanding Qty. (Base)");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnGetSourceShipmentDate', '', false, false)]
    local procedure OnGetSourceShipmentDate(var TrackingSpecification: Record "Tracking Specification"; var ShipmentDate: Date);
    var
        ServiceLine: Record "Service Line";
    begin
        if TrackingSpecification."Source Type" = Database::"Service Line" then begin
            ServiceLine.Get(TrackingSpecification."Source Subtype", TrackingSpecification."Source ID", TrackingSpecification."Source Ref. No.");
            ShipmentDate := ServiceLine."Needed by Date";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterSetValueArrayForReservation', '', false, false)]
    local procedure OnAfterSetValueArrayForReservation(var ValueArray: array[30] of Integer; var ArrayCounter: Integer)
    begin
        ArrayCounter += 1;
        ValueArray[ArrayCounter] := Enum::"Reservation Summary Type"::"Service Order".AsInteger();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterSetValueArrayForOrderTracking', '', false, false)]
    local procedure OnAfterSetValueArrayForOrderTracking(var ValueArray: array[30] of Integer; var ArrayCounter: Integer)
    begin
        ArrayCounter += 1;
        ValueArray[ArrayCounter] := Enum::"Reservation Summary Type"::"Service Order".AsInteger();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnSetSourceForServiceLine', '', false, false)]
    local procedure OnSetSourceForServiceLine(SourceRecRef: RecordRef; var CalcReservEntry: Record "Reservation Entry"; var EntryIsPositive: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        if not MatchThisTable(SourceRecRef.Number) then
            exit;

        SourceRecRef.SetTable(ServiceLine);
        ServiceLine.SetReservationEntry(CalcReservEntry);
        OnSetServLineOnBeforeUpdateReservation(CalcReservEntry, ServiceLine);
#if not CLEAN26
        ReservationManagement.RunOnSetServLineOnBeforeUpdateReservation(CalcReservEntry, ServiceLine);
#endif
        EntryIsPositive := (CreateReservEntry.SignFactor(CalcReservEntry) * ServiceLine."Outstanding Qty. (Base)") <= 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetServLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
}
