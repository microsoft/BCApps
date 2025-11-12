// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;
using Microsoft.Purchases.History;
using Microsoft.Foundation.Navigate;

codeunit 99000834 "Purch. Line-Reserve"
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
        Blocked: Boolean;
        ApplySpecificItemTracking: Boolean;
        OverruleItemTracking: Boolean;
        DeleteItemTracking: Boolean;

        Text000Err: Label 'Reserved quantity cannot be greater than %1', Comment = '%1 - quantity';
        Text001Err: Label 'must be filled in when a quantity is reserved';
        Text002Err: Label 'must not be filled in when a quantity is reserved';
        Text003Err: Label 'must not be changed when a quantity is reserved';
        Text004Err: Label 'Codeunit is not initialized correctly.';
        PurchaseTxt: Label 'Purchase';
        SummaryTypeTxt: Label '%1, %2', Locked = true;
        SourceDoc3Txt: Label '%1 %2 %3', Locked = true;

    procedure CreateReservation(var PurchaseLine: Record "Purchase Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004Err);

        OnBeforeCreateReservation(PurchaseLine);
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.");
        PurchaseLine.TestField("Expected Receipt Date");
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        if Abs(PurchaseLine."Outstanding Qty. (Base)") < Abs(PurchaseLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000Err,
              Abs(PurchaseLine."Outstanding Qty. (Base)") - Abs(PurchaseLine."Reserved Qty. (Base)"));

        PurchaseLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        PurchaseLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then
            SignFactor := -1
        else
            SignFactor := 1;

        if QuantityBase * SignFactor < 0 then
            ShipmentDate := PurchaseLine."Expected Receipt Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := PurchaseLine."Expected Receipt Date";
        end;

        if PurchaseLine."Planning Flexibility" <> PurchaseLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(PurchaseLine."Planning Flexibility");

        IsHandled := false;
        OnCreateReservationOnBeforeCreateReservEntry(PurchaseLine, Quantity, QuantityBase, ForReservationEntry, IsHandled, FromTrackingSpecification, ExpectedReceiptDate, Description, ShipmentDate);
        if not IsHandled then begin
            CreateReservEntry.CreateReservEntryFor(
                Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(),
                PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.", PurchaseLine."Qty. per Unit of Measure",
                Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
          PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;

        OnAfterCreateReservation(PurchaseLine);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure ReservQuantity(PurchaseLine: Record "Purchase Line") QtyToReserve: Decimal
    begin
        case PurchaseLine."Document Type" of
            PurchaseLine."Document Type"::Quote,
          PurchaseLine."Document Type"::Order,
          PurchaseLine."Document Type"::Invoice,
          PurchaseLine."Document Type"::"Blanket Order":
                QtyToReserve := -PurchaseLine."Outstanding Qty. (Base)";
            PurchaseLine."Document Type"::"Return Order",
          PurchaseLine."Document Type"::"Credit Memo":
                QtyToReserve := PurchaseLine."Outstanding Qty. (Base)";
        end;

        OnAfterReservQuantity(PurchaseLine, QtyToReserve);
    end;

    procedure Caption(PurchaseLine: Record "Purchase Line") CaptionText: Text
    begin
        CaptionText := PurchaseLine.GetSourceCaption();
    end;

    procedure FindReservEntry(PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        PurchaseLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure GetReservedQtyFromInventory(PurchaseLine: Record "Purchase Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        PurchaseLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(PurchaseHeader: Record "Purchase Header"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;


    procedure ReservEntryExist(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit(PurchaseLine.ReservEntryExist());
    end;

    procedure VerifyChange(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line")
    var
        PurchaseLine: Record "Purchase Line";
        ShowError: Boolean;
        HasError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChange(NewPurchaseLine, OldPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if (NewPurchaseLine.Type <> NewPurchaseLine.Type::Item) and (OldPurchaseLine.Type <> OldPurchaseLine.Type::Item) then
            exit;
        if Blocked then
            exit;
        if NewPurchaseLine."Line No." = 0 then
            if not PurchaseLine.Get(
                 NewPurchaseLine."Document Type",
                 NewPurchaseLine."Document No.",
                 NewPurchaseLine."Line No.")
            then
                exit;

        NewPurchaseLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewPurchaseLine."Reserved Qty. (Base)" <> 0;

        if (NewPurchaseLine."Expected Receipt Date" = 0D) and (OldPurchaseLine."Expected Receipt Date" <> 0D) then
            if ShowError then
                NewPurchaseLine.FieldError("Expected Receipt Date", Text001Err)
            else
                HasError := true;

        if NewPurchaseLine."Sales Order No." <> '' then
            if ShowError then
                NewPurchaseLine.FieldError("Sales Order No.", Text002Err)
            else
                HasError := NewPurchaseLine."Sales Order No." <> OldPurchaseLine."Sales Order No.";

        if NewPurchaseLine."Sales Order Line No." <> 0 then
            if ShowError then
                NewPurchaseLine.FieldError(
                  "Sales Order Line No.", Text002Err)
            else
                HasError := NewPurchaseLine."Sales Order Line No." <> OldPurchaseLine."Sales Order Line No.";

        if NewPurchaseLine."Drop Shipment" <> OldPurchaseLine."Drop Shipment" then
            if ShowError and NewPurchaseLine."Drop Shipment" then
                NewPurchaseLine.FieldError("Drop Shipment", Text002Err)
            else
                HasError := true;

        if NewPurchaseLine."No." <> OldPurchaseLine."No." then
            if ShowError then
                NewPurchaseLine.FieldError("No.", Text003Err)
            else
                HasError := true;

        IsHandled := false;
        OnVerifyChangeOnBeforeTestVariantCode(NewPurchaseLine, OldPurchaseLine, IsHandled);
        if not IsHandled then
            if NewPurchaseLine."Variant Code" <> OldPurchaseLine."Variant Code" then
                if ShowError then
                    NewPurchaseLine.FieldError("Variant Code", Text003Err)
                else
                    HasError := true;

        if NewPurchaseLine."Location Code" <> OldPurchaseLine."Location Code" then
            if ShowError then
                NewPurchaseLine.FieldError("Location Code", Text003Err)
            else
                HasError := true;

        VerifyPurchLine(NewPurchaseLine, OldPurchaseLine, HasError);

        OnVerifyChangeOnBeforeHasError(NewPurchaseLine, OldPurchaseLine, HasError, ShowError);

        if HasError then
            if (NewPurchaseLine."No." <> OldPurchaseLine."No.") or NewPurchaseLine.ReservEntryExist() then begin
                if (NewPurchaseLine."No." <> OldPurchaseLine."No.") or (NewPurchaseLine.Type <> OldPurchaseLine.Type) then begin
                    ReservationManagement.SetReservSource(OldPurchaseLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewPurchaseLine);
                end else begin
                    ReservationManagement.SetReservSource(NewPurchaseLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewPurchaseLine."Outstanding Qty. (Base)");
            end;

        if HasError or (NewPurchaseLine."Expected Receipt Date" <> OldPurchaseLine."Expected Receipt Date") then begin
            AssignForPlanning(NewPurchaseLine);
            if (NewPurchaseLine."No." <> OldPurchaseLine."No.") or
               (NewPurchaseLine."Variant Code" <> OldPurchaseLine."Variant Code") or
               (NewPurchaseLine."Location Code" <> OldPurchaseLine."Location Code")
            then
                AssignForPlanning(OldPurchaseLine);
        end;
    end;

    procedure VerifyQuantity(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line")
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if Blocked then
            exit;

        IsHandled := false;
        OnBeforeVerifyQuantity(NewPurchaseLine, IsHandled, OldPurchaseLine);
        if IsHandled then
            exit;

        if NewPurchaseLine.Type <> NewPurchaseLine.Type::Item then
            exit;
        if NewPurchaseLine."Document Type" = OldPurchaseLine."Document Type" then
            if NewPurchaseLine."Line No." = OldPurchaseLine."Line No." then
                if NewPurchaseLine."Quantity (Base)" = OldPurchaseLine."Quantity (Base)" then
                    exit;
        if NewPurchaseLine."Line No." = 0 then
            if not PurchaseLine.Get(NewPurchaseLine."Document Type", NewPurchaseLine."Document No.", NewPurchaseLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewPurchaseLine);
        if NewPurchaseLine."Qty. per Unit of Measure" <> OldPurchaseLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewPurchaseLine."Outstanding Qty. (Base)" * OldPurchaseLine."Outstanding Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewPurchaseLine."Outstanding Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewPurchaseLine."Outstanding Qty. (Base)");
        AssignForPlanning(NewPurchaseLine);
    end;

    procedure UpdatePlanningFlexibility(var PurchaseLine: Record "Purchase Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(PurchaseLine, ReservationEntry) then
            ReservationEntry.ModifyAll("Planning Flexibility", PurchaseLine."Planning Flexibility");
    end;

    procedure TransferPurchLineToItemJnlLine(var PurchaseLine: Record "Purchase Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplToItemEntry: Boolean) Result: Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        NotFullyReserved: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPurchLineToItemJnlLine(PurchaseLine, ItemJournalLine, TransferQty, CheckApplToItemEntry, Result, IsHandled);
        if IsHandled then
            exit;

        if not FindReservEntry(PurchaseLine, OldReservationEntry) then
            exit(TransferQty);

        OldReservationEntry.LockTable();
        OldReservationEntry.FindLast();
        // Handle Item Tracking on drop shipment:
        Clear(CreateReservEntry);
        if ApplySpecificItemTracking and (ItemJournalLine."Applies-to Entry" <> 0) then
            CreateReservEntry.SetItemLedgEntryNo(ItemJournalLine."Applies-to Entry");

        if OverruleItemTracking then
            if ItemJournalLine.TrackingExists() then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(ItemJournalLine);
                CreateReservEntry.SetOverruleItemTracking(true);
                // Try to match against Item Tracking on the purchase order line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(ItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    exit(TransferQty);
            end;

        ItemJournalLine.TestItemFields(PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJournalLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        OnTransferPurchLineToItemJnlLineOnBeforeInitRecordSet(OldReservationEntry);
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestItemFields(PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code");

                if CheckApplToItemEntry then begin
                    if OldReservationEntry."Reservation Status" = OldReservationEntry."Reservation Status"::Reservation then begin
                        OppositeReservationEntry.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                        if OppositeReservationEntry."Source Type" <> Database::"Item Ledger Entry" then
                            NotFullyReserved := true;
                    end else
                        NotFullyReserved := true;

                    if OldReservationEntry."Item Tracking" <> OldReservationEntry."Item Tracking"::None then begin
                        OldReservationEntry.TestField("Appl.-to Item Entry");
                        CreateReservEntry.SetApplyToEntryNo(OldReservationEntry."Appl.-to Item Entry");
                        CheckApplToItemEntry := false;
                    end;
                end;

                TransferPurchLineToItemJnlLineReservEntry(PurchaseLine, ItemJournalLine, OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplToItemEntry := CheckApplToItemEntry and NotFullyReserved;
        end;
        exit(TransferQty);
    end;

    local procedure TransferPurchLineToItemJnlLineReservEntry(PurchaseLine: Record "Purchase Line"; ItemJournalLine: Record "Item Journal Line"; OldReservationEntry: Record "Reservation Entry"; var TransferQty: Decimal);
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPurchLineToItemJnlLineReservEntry(OldReservationEntry, PurchaseLine, ItemJournalLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TransferQty :=
            CreateReservEntry.TransferReservEntry(
                Database::"Item Journal Line",
                ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);
    end;

    procedure TransferPurchLineToPurchLine(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        if not FindReservEntry(OldPurchaseLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewPurchaseLine.TestItemFields(OldPurchaseLine."No.", OldPurchaseLine."Variant Code", OldPurchaseLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);
            OnTransferPurchLineToPurchLineOnAfterOldReservEntrySetFilters(OldPurchaseLine, NewPurchaseLine);
            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestItemFields(OldPurchaseLine."No.", OldPurchaseLine."Variant Code", OldPurchaseLine."Location Code");

                    TransferQty :=
                        CreateReservEntry.TransferReservEntry(
                            Database::"Purchase Line",
                            NewPurchaseLine."Document Type".AsInteger(), NewPurchaseLine."Document No.", '', 0, NewPurchaseLine."Line No.",
                            NewPurchaseLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end; // DO
    end;

    procedure DeleteLineConfirm(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if not PurchaseLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(PurchaseLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteLine(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        ReservationManagement.SetReservSource(PurchaseLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        DeleteInvoiceSpecFromLine(PurchaseLine);
        ReservationManagement.ClearActionMessageReferences();
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(PurchaseLine);
    end;

    local procedure AssignForPlanning(var PurchaseLine: Record "Purchase Line")
    var
        PlanningAssignment: Record "Planning Assignment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignForPlanning(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            exit;
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;
        if PurchaseLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Location Code", WorkDate());
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var PurchaseLine: Record "Purchase Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        ShouldProcessDropShipment: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallItemTracking(PurchaseLine, IsHandled);
        if not IsHandled then begin
            InitFromPurchLine(TrackingSpecification, PurchaseLine);
            if ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice) and
                (PurchaseLine."Receipt No." <> '')) or
            ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo") and
                (PurchaseLine."Return Shipment No." <> ''))
            then
                ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Combined Ship/Rcpt");
            ShouldProcessDropShipment := PurchaseLine."Drop Shipment";
            OnCallItemTrackingOnAfterCalcShouldProcessDropShipment(PurchaseLine, ShouldProcessDropShipment, ItemTrackingLines);
            if ShouldProcessDropShipment then begin
                ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::"Drop Shipment");
                if PurchaseLine."Sales Order No." <> '' then
                    ItemTrackingLines.SetSecondSourceRowID(
                        ItemTrackingManagement.ComposeRowID(
                            Database::"Sales Line", 1, PurchaseLine."Sales Order No.", '', 0, PurchaseLine."Sales Order Line No."));
            end;
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, PurchaseLine."Expected Receipt Date");
            ItemTrackingLines.SetInbound(PurchaseLine.IsInbound());
            OnCallItemTrackingOnBeforeItemTrackingFormRunModal(PurchaseLine, ItemTrackingLines);
            RunItemTrackingLinesPage(ItemTrackingLines);
        end;
    end;

    procedure CallItemTracking(var PurchaseLine: Record "Purchase Line"; SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        InitFromPurchLine(TrackingSpecification, PurchaseLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, PurchaseLine."Expected Receipt Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        OnCallItemTrackingOnBeforeItemTrackingFormRunModal(PurchaseLine, ItemTrackingLines);
        RunItemTrackingLinesPage(ItemTrackingLines);
    end;

    local procedure RunItemTrackingLinesPage(var ItemTrackingLines: Page "Item Tracking Lines")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunItemTrackingLinesPage(ItemTrackingLines, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingLines.RunModal();
    end;

    procedure RetrieveInvoiceSpecification(var PurchaseLine: Record "Purchase Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        SourceTrackingSpecification: Record "Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification(PurchaseLine, IsHandled, OK, TempInvoicingTrackingSpecification);
        if IsHandled then
            exit;

        Clear(TempInvoicingTrackingSpecification);
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;
        if ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice) and
            (PurchaseLine."Receipt No." <> '')) or
           ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo") and
            (PurchaseLine."Return Shipment No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(PurchaseLine, TempInvoicingTrackingSpecification)
        else begin
            InitFromPurchLine(SourceTrackingSpecification, PurchaseLine);
            OK := ItemTrackingManagement.RetrieveInvoiceSpecification(SourceTrackingSpecification, TempInvoicingTrackingSpecification);
        end;
    end;

    procedure RetrieveInvoiceSpecification2(var PurchaseLine: Record "Purchase Line"; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveInvoiceSpecification2(PurchaseLine, IsHandled);
        if IsHandled then
            exit;
        // Used for combined receipt/return:
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;
        if not FindReservEntry(PurchaseLine, ReservationEntry) then
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
            OnRetrieveInvoiceSpecification2OnBeforeInsert(TempInvoicingTrackingSpecification, ReservationEntry);
            TempInvoicingTrackingSpecification.Insert();
            ReservationEntry.Delete();
        until ReservationEntry.Next() = 0;

        OK := TempInvoicingTrackingSpecification.FindFirst();
    end;

    procedure DeleteInvoiceSpecFromHeader(PurchaseHeader: Record "Purchase Header")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromHeader(
          Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");
    end;

    procedure DeleteInvoiceSpecFromLine(PurchaseLine: Record "Purchase Line")
    begin
        ItemTrackingManagement.DeleteInvoiceSpecFromLine(
          Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    procedure UpdateItemTrackingAfterPosting(PurchaseHeader: Record "Purchase Header")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.SetSourceFilter(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", -1, true);
        ReservationEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);

        OnAfterUpdateItemTrackingAfterPosting(PurchaseHeader);
    end;

    procedure SetApplySpecificItemTracking(ApplySpecific: Boolean)
    begin
        ApplySpecificItemTracking := ApplySpecific;
    end;

    procedure SetOverruleItemTracking(Overrule: Boolean)
    begin
        OverruleItemTracking := Overrule;
    end;

    local procedure VerifyPurchLine(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var HasError: Boolean)
    begin
        if (NewPurchaseLine.Type = NewPurchaseLine.Type::Item) and (OldPurchaseLine.Type = OldPurchaseLine.Type::Item) then
            if (NewPurchaseLine."Bin Code" <> OldPurchaseLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewPurchaseLine."No.", NewPurchaseLine."Bin Code",
                  NewPurchaseLine."Location Code", NewPurchaseLine."Variant Code",
                  Database::"Purchase Line", NewPurchaseLine."Document Type".AsInteger(),
                  NewPurchaseLine."Document No.", '', 0, NewPurchaseLine."Line No."))
            then
                HasError := true;
        if NewPurchaseLine."Line No." <> OldPurchaseLine."Line No." then
            HasError := true;

        if NewPurchaseLine.Type <> OldPurchaseLine.Type then
            HasError := true;
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PurchaseLine);
            PurchaseLine.Find();
            QtyPerUOM := PurchaseLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SourceRecordRef.SetTable(PurchaseLine);
        PurchaseLine.TestField("Job No.", '');
        PurchaseLine.TestField("Drop Shipment", false);
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("Expected Receipt Date");

        PurchaseLine.SetReservationEntry(ReservationEntry);

        CaptionText := PurchaseLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Purchase Quote".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Purchase Quote".AsInteger() ..
                         Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Purchase Line");
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
        AvailablePurchaseLines: page "Available - Purchase Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailablePurchaseLines);
            AvailablePurchaseLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailablePurchaseLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailablePurchaseLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure ReservationOnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Purchase Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure ReservationOnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Purchase Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Ledger Entry-Reserve", 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure ItemLedgerEntryOnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary" temporary; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal; var IsHandled: Boolean; sender: Codeunit "Item Ledger Entry-Reserve")
    var
        PurchaseLine: Record "Purchase Line";
        CheckOutbound: Boolean;
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(PurchaseLine);
            CheckOutbound := Location."Bin Mandatory" or Location."Require Pick" and (PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order");
            sender.DrillDownTotalQuantity(SourceRecRef, EntrySummary, ReservEntry, MaxQtyToReserve, CheckOutbound, false);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(PurchaseLine);
            CreateReservation(PurchaseLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PurchHeader: Record "Purchase Header";
    begin
        if MatchThisTable(SourceType) then begin
            PurchHeader.Reset();
            PurchHeader.SetRange("Document Type", SourceSubtype);
            PurchHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Purchase Quote", PurchHeader);
                1:
                    PAGE.RunModal(PAGE::"Purchase Order", PurchHeader);
                2:
                    PAGE.RunModal(PAGE::"Purchase Invoice", PurchHeader);
                3:
                    PAGE.RunModal(PAGE::"Purchase Credit Memo", PurchHeader);
                5:
                    PAGE.RunModal(PAGE::"Purchase Return Order", PurchHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceType) then begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", SourceSubtype);
            PurchaseLine.SetRange("Document No.", SourceID);
            PurchaseLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"Purchase Lines", PurchaseLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PurchaseLine);
            PurchaseLine.SetReservationFilters(ReservEntry);
            CaptionText := PurchaseLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(PurchaseLine);
            PurchaseLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(PurchaseLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(PurchaseLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(PurchaseLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewPurchLine: Record "Purchase Line"; OldPurchLine: Record "Purchase Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Enum "Purchase Document Type"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        AvailabilityFilter: Text;
    begin
        if not PurchaseLine.ReadPermission then
            exit;

        PurchaseLine.SetAutoCalcFields("Reserved Qty. (Base)");
        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        PurchaseLine.FilterLinesForReservation(ReservationEntry, DocumentType, AvailabilityFilter, Positive);
        if PurchaseLine.FindSet() then
            repeat
                OnUpdateStatisticsOnBeforeCheckSpecialOrder(PurchaseLine);
                if not PurchaseLine."Special Order" then begin
                    TempEntrySummary."Total Reserved Quantity" += PurchaseLine."Reserved Qty. (Base)";
                    TotalQuantity += PurchaseLine."Outstanding Qty. (Base)";
                end;
            until PurchaseLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (Positive = (TotalQuantity > 0)) and (DocumentType <> PurchaseLine."Document Type"::"Return Order") or
                (Positive = (TotalQuantity < 0)) and (DocumentType = PurchaseLine."Document Type"::"Return Order")
        then begin
            TempEntrySummary."Table ID" := Database::"Purchase Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo(SummaryTypeTxt, PurchaseLine.TableCaption(), PurchaseLine."Document Type"), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            if DocumentType = PurchaseLine."Document Type"::"Return Order" then
                TempEntrySummary."Total Quantity" := -TotalQuantity
            else
                TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [Enum::"Reservation Summary Type"::"Purchase Order".AsInteger(),
                                           Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger()]
        then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Enum::"Purchase Document Type".FromInteger(ReservSummEntry."Entry No." - 11), Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        PurchaseLine.SetRange("Document No.", ReservationEntry."Source ID");
        PurchaseLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(PAGE::"Purchase Lines", PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterAutoReserveOneLine', '', false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean; var sender: Codeunit "Reservation Management")
    begin
        if MatchThisEntry(ReservSummEntryNo) then
            AutoReservePurchLine(
                CalcReservEntry, sender, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase,
                Description, AvailabilityDate, Search, NextStep, Positive);
    end;

    local procedure AutoReservePurchLine(var CalcReservEntry: Record "Reservation Entry"; var sender: Codeunit "Reservation Management"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; Positive: Boolean)
    var
        CallTrackingSpecification: Record "Tracking Specification";
        PurchLine: Record "Purchase Line";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
#if not CLEAN25
        IsReserved := false;
        sender.RunOnBeforeAutoReservePurchLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;
#endif
        IsReserved := false;
        OnBeforeAutoReservePurchLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        PurchLine.SetAutoCalcFields("Reserved Qty. (Base)");
        PurchLine.FilterLinesForReservation(
          CalcReservEntry, Enum::"Purchase Document Type".FromInteger(ReservSummEntryNo - Enum::"Reservation Summary Type"::"Purchase Quote".AsInteger()),
          sender.GetAvailabilityFilter(AvailabilityDate), Positive);
        if PurchLine.Find(Search) then
            repeat
                if not PurchLine."Special Order" then begin
                    QtyThisLine := PurchLine."Outstanding Quantity";
                    QtyThisLineBase := PurchLine."Outstanding Qty. (Base)";
                end;
                if ReservSummEntryNo = Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger() then
                    ReservQty := -PurchLine."Reserved Qty. (Base)"
                else
                    ReservQty := PurchLine."Reserved Qty. (Base)";
                if (Positive = (QtyThisLineBase < 0)) and (ReservSummEntryNo <> Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger()) or
                   (Positive = (QtyThisLineBase > 0)) and (ReservSummEntryNo = Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger())
                then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                OnAutoReservePurchLineOnBeforeSetQtyToReserveDownToTrackedQuantity(
                    PurchLine, CalcReservEntry, ReservQty, QtyThisLine, QtyThisLineBase);
                sender.SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, PurchLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                    Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", '', 0, PurchLine."Line No.",
                    PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                sender.InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, PurchLine."Expected Receipt Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (PurchLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);

        OnAfterAutoReservePurchLine(PurchLine, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateItemTrackingAfterPosting(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPurchLineToItemJnlLine(var PurchaseLine: Record "Purchase Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplToItemEntry: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPurchLineToItemJnlLineReservEntry(var OldReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line"; ItemJnlLine: Record "Item Journal Line"; var TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunItemTrackingLinesPage(var ItemTrackingLines: Page "Item Tracking Lines"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; OldPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPurchLineToPurchLineOnAfterOldReservEntrySetFilters(var OldPurchLine: record "Purchase Line"; var NewPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPurchLineToItemJnlLineOnBeforeInitRecordSet(var OldReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeTestVariantCode(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingFormRunModal(var PurchLine: Record "Purchase Line"; var ItemTrackingForm: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveInvoiceSpecification2OnBeforeInsert(var TempInvoicingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStatisticsOnBeforeCheckSpecialOrder(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignForPlanning(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRetrieveInvoiceSpecification(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var OK: Boolean; var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveInvoiceSpecification2(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var PurchLine: Record "Purchase Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var FromTrackingSpecification: Record "Tracking Specification"; ExpectedReceiptDate: Date; var Description: Text[100]; ShipmentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnAfterCalcShouldProcessDropShipment(var PurchLine: Record "Purchase Line"; var ShouldProcessDropShipment: Boolean; var ItemTrackingLinesPage: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReservation(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(PurchaseLine: Record "Purchase Line"; var QtyToReserve: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChange(var NewPurchaseLine: Record "Purchase Line"; var OldPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReservePurchLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; var Search: Text[1]; var NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReservePurchLineOnBeforeSetQtyToReserveDownToTrackedQuantity(PurchLine: Record "Purchase Line"; CalcReservEntry: Record "Reservation Entry"; var ReservQty: Decimal; var QtyThisLine: Decimal; var QtyThisLineBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReservePurchLine(var PurchLine: Record "Purchase Line"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoReserveOnBeforeStopReservation', '', false, false)]
    local procedure OnAutoReserveOnBeforeStopReservation(var CalcReservEntry: Record "Reservation Entry"; var StopReservation: Boolean; SourceRecRef: RecordRef);
    begin
        if MatchThisTable(CalcReservEntry."Source Type") then
            StopReservation := not (CalcReservEntry."Source Subtype" in [1, 5]);  // Only order and return order
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAutoTrackOnCheckSourceType', '', false, false)]
    local procedure OnAutoTrackOnCheckSourceType(var ReservationEntry: Record "Reservation Entry"; var ShouldExit: Boolean)
    begin
        if ReservationEntry."Source Type" = Database::"Purchase Line" then
            if not (ReservationEntry."Source Subtype" in [1, 5]) then
                ShouldExit := true; // Only order, return order
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnTestItemType', '', false, false)]
    local procedure OnTestItemType(SourceRecRef: RecordRef)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if SourceRecRef.Number = Database::"Purchase Line" then begin
            SourceRecRef.SetTable(PurchaseLine);
            PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnIssueActionMessageOnSetSourceTypeFromSKU', '', false, false)]
    local procedure OnIssueActionMessageOnSetSourceTypeFromSKU(var ActionMessageEntry: Record "Action Message Entry"; SKU: Record "Stockkeeping Unit")
    begin
        if SKU."Replenishment System" = SKU."Replenishment System"::Purchase then
            ActionMessageEntry."Source Type" := Database::"Purchase Line";
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceForReservationOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line")
    begin
    end;
#endif
    // codeunit Create Reserv. Entry

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnCheckSourceTypeSubtype', '', false, false)]
    local procedure CheckSourceTypeSubtype(var ReservationEntry: Record "Reservation Entry"; var IsError: Boolean)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            IsError := not (ReservationEntry."Source Subtype" in [1, 5]);
    end;

    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnRevertDateToSourceDate', '', false, false)]
    local procedure OnRevertDateToSourceDate(var ReservEntry: Record "Reservation Entry")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if ReservEntry."Source Type" = Database::"Purchase Line" then begin
            PurchaseLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
            if ReservEntry.Positive then begin
                ReservEntry."Expected Receipt Date" := PurchaseLine."Expected Receipt Date";
                ReservEntry."Shipment Date" := 0D;
            end else
                ReservEntry."Expected Receipt Date" := 0D;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnGetActivePointerFieldsOnBeforeAssignArrayValues', '', false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
        if TableID = Database::"Purchase Line" then begin
            PointerFieldIsActive[1] := true;  // Type
            PointerFieldIsActive[2] := true;  // SubType
            PointerFieldIsActive[3] := true;  // ID
            PointerFieldIsActive[6] := true;  // RefNo
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    begin
        if ReservationEntry."Source Type" = Database::"Purchase Line" then
            Description :=
                StrSubstNo(
                    SourceDoc3Txt, PurchaseTxt,
                    Enum::"Purchase Document Type".FromInteger(ReservationEntry."Source Subtype"), ReservationEntry."Source ID");
    end;

    procedure InitFromPurchLine(var TransactionSpecification: Record "Tracking Specification"; PurchLine: Record "Purchase Line")
    begin
        TransactionSpecification.Init();
        TransactionSpecification.SetItemData(
          PurchLine."No.", PurchLine.Description, PurchLine."Location Code", PurchLine."Variant Code", PurchLine."Bin Code",
          PurchLine."Qty. per Unit of Measure", PurchLine."Qty. Rounding Precision (Base)");
        TransactionSpecification.SetSource(
          Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.", '', 0);
        if PurchLine.IsCreditDocType() then
            TransactionSpecification.SetQuantities(
              PurchLine."Quantity (Base)", PurchLine."Return Qty. to Ship", PurchLine."Return Qty. to Ship (Base)",
              PurchLine."Qty. to Invoice", PurchLine."Qty. to Invoice (Base)", PurchLine."Return Qty. Shipped (Base)",
              PurchLine."Qty. Invoiced (Base)")
        else
            TransactionSpecification.SetQuantities(
              PurchLine."Quantity (Base)", PurchLine."Qty. to Receive", PurchLine."Qty. to Receive (Base)",
              PurchLine."Qty. to Invoice", PurchLine."Qty. to Invoice (Base)", PurchLine."Qty. Received (Base)",
              PurchLine."Qty. Invoiced (Base)");

        OnAfterInitFromPurchLine(TransactionSpecification, PurchLine);
#if not CLEAN25
        TransactionSpecification.RunOnAfterInitFromPurchLine(TransactionSpecification, PurchLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchLine(var TrackingSpecification: Record "Tracking Specification"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSummEntryNo', '', false, false)]
    local procedure OnBeforeSummEntryNo(ReservationEntry: Record "Reservation Entry"; var ReturnValue: Integer)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ReturnValue := Enum::"Reservation Summary Type"::"Purchase Quote".AsInteger() + ReservationEntry."Source Subtype";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnUpdateSourceCost', '', false, false)]
    local procedure ReservationEntryOnUpdateSourceCost(ReservationEntry: Record "Reservation Entry"; UnitCost: Decimal)
    var
        PurchLine: Record "Purchase Line";
        QtyReserved: Decimal;
    begin
        if MatchThisTable(ReservationEntry."Source Type") then begin
            PurchLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
            if PurchLine."Qty. per Unit of Measure" <> 0 then
                PurchLine."Unit Cost (LCY)" :=
                    Round(PurchLine."Unit Cost (LCY)" / PurchLine."Qty. per Unit of Measure");
            if PurchLine."Quantity (Base)" <> 0 then
                PurchLine."Unit Cost (LCY)" :=
                    Round(
                    (PurchLine."Unit Cost (LCY)" *
                        (PurchLine."Quantity (Base)" - QtyReserved) +
                        UnitCost * QtyReserved) / PurchLine."Quantity (Base)", 0.00001);
            if PurchLine."Qty. per Unit of Measure" <> 0 then
                PurchLine."Unit Cost (LCY)" :=
                    Round(PurchLine."Unit Cost (LCY)" * PurchLine."Qty. per Unit of Measure");
            PurchLine.Validate("Unit Cost (LCY)");
            PurchLine.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OrderTrackingManagementOnSetSourceRecord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text; var ItemLedgerEntry2: Record "Item Ledger Entry")
    var
        PurchaseLine: Record "Purchase Line";
        SourceRecRef: RecordRef;
    begin
        SourceRecRef.GetTable(SourceRecordVar);
        if MatchThisTable(SourceRecRef.Number) then begin
            PurchaseLine := SourceRecordVar;
            SetPurchaseLine(PurchaseLine, ReservationEntry, ItemLedgerEntry2);
        end;
    end;

    local procedure SetPurchaseLine(var PurchaseLine: Record "Purchase Line"; var ReservEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        ReservEntry.InitSortingAndFilters(false);
        PurchaseLine.SetReservationFilters(ReservEntry);

        if PurchaseLine."Qty. Received (Base)" <> 0 then begin
            PurchRcptLine.SetCurrentKey("Order No.", "Order Line No.");
            PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
            PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
            if PurchRcptLine.Find('-') then
                repeat
                    if ItemLedgerEntry.Get(PurchRcptLine."Item Rcpt. Entry No.") then
                        ItemLedgerEntry.Mark(true);
                until PurchRcptLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, 'OnInsertOrderTrackingEntry', '', false, false)]
    local procedure OnInsertOrderTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if OrderTrackingEntry."For Type" = DATABASE::"Purchase Line" then
            if PurchaseLine.Get(OrderTrackingEntry."For Subtype", OrderTrackingEntry."For ID", OrderTrackingEntry."For Ref. No.") then begin
                OrderTrackingEntry."Starting Date" := PurchaseLine."Expected Receipt Date";
                OrderTrackingEntry."Ending Date" := PurchaseLine."Expected Receipt Date";
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnGetSourceShipmentDate', '', false, false)]
    local procedure OnGetSourceShipmentDate(var TrackingSpecification: Record "Tracking Specification"; var ShipmentDate: Date);
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if TrackingSpecification."Source Type" = Database::"Purchase Line" then begin
            PurchaseLine.Get(TrackingSpecification."Source Subtype", TrackingSpecification."Source ID", TrackingSpecification."Source Ref. No.");
            ShipmentDate := PurchaseLine."Expected Receipt Date";
        end;
    end;
}
