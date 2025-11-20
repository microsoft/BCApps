// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 99000831 "Reservation Engine Mgt."
{
    Permissions = TableData "Item Ledger Entry" = rm,
                  TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rid;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be greater than 0.';
        Text001: Label '%1 must be less than 0.';
#pragma warning restore AA0470
        Text002: Label 'Use Cancel Reservation.';
#pragma warning disable AA0470
        Text003: Label '%1 can only be reduced.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Item: Record Item;
        TempSurplusEntry: Record "Reservation Entry" temporary;
        TempSortRec1: Record "Reservation Entry" temporary;
        TempSortRec2: Record "Reservation Entry" temporary;
        TempSortRec3: Record "Reservation Entry" temporary;
        TempSortRec4: Record "Reservation Entry" temporary;
#pragma warning disable AA0074
        Text006: Label 'Signing mismatch.';
        Text007: Label 'Renaming reservation entries...';
#pragma warning restore AA0074
        ReservMgt: Codeunit "Reservation Management";
        LostReservationQty: Decimal;
#pragma warning disable AA0470
        CannotStateItemTrackingErr: Label 'You cannot state item tracking on a demand when it is linked to a supply by %1 = %2.';
#pragma warning restore AA0470
        ReservationsModified: Boolean;

    procedure CancelReservation(ReservEntry: Record "Reservation Entry")
    var
        ReservEntry3: Record "Reservation Entry";
        DoCancel: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCancelReservation(ReservEntry, IsHandled);
        if IsHandled then
            exit;

        ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.TestField("Disallow Cancellation", false);

        ReservEntry3.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
        DoCancel := ReservEntry3.TrackingExists() or ReservEntry.TrackingExists();
        OnCancelReservationOnBeforeDoCancel(ReservEntry3, ReservEntry, DoCancel);
        if DoCancel then begin
            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
            ReservEntry.Binding := ReservEntry.Binding::" ";
            ReservEntry3."Reservation Status" := ReservEntry3."Reservation Status"::Surplus;
            ReservEntry3.Binding := ReservEntry3.Binding::" ";
            RevertDateToSourceDate(ReservEntry);
            ReservEntry.Modify();
            ReservEntry3.Delete();
            ReservEntry3."Entry No." := 0;
            RevertDateToSourceDate(ReservEntry3);
            ReservEntry3.Insert();
            TempSurplusEntry.DeleteAll();
            UpdateTempSurplusEntry(ReservEntry);
            UpdateTempSurplusEntry(ReservEntry3);
            UpdateOrderTracking(TempSurplusEntry);
            OnCancelReservationOnAfterDoCancel(ReservEntry, TempSurplusEntry);
        end else
            CloseReservEntry(ReservEntry, true, false);

        UpdateSourcePlanned(ReservEntry);

        OnAfterCancelReservation(ReservEntry3, ReservEntry);
    end;

    local procedure RevertDateToSourceDate(var ReservEntry: Record "Reservation Entry")
    begin
        OnRevertDateToSourceDate(ReservEntry);
    end;

    procedure ChangeDateFieldOnReservEntry(var ReservEntry: Record "Reservation Entry"; ExpectedReceiptDate: Date; ShipmentDate: Date)
    begin
        ReservEntry."Expected Receipt Date" := ExpectedReceiptDate;
        ReservEntry."Shipment Date" := ShipmentDate;
    end;

    procedure CloseReservEntry(ReservEntry: Record "Reservation Entry"; ReTrack: Boolean; DeleteAll: Boolean)
    var
        ReservEntry2: Record "Reservation Entry";
        SurplusReservEntry: Record "Reservation Entry";
        DummyReservEntry: Record "Reservation Entry";
        OriginalReservEntry2: Record "Reservation Entry";
        TotalQty: Decimal;
        AvailabilityDate: Date;
        SkipDeleteReservEntry: Boolean;
    begin
        OnBeforeCloseReservEntry(ReservEntry, ReTrack, DeleteAll, SkipDeleteReservEntry);
        if not SkipDeleteReservEntry then
            ReservEntry.Delete();
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Prospect then
            exit;

        ModifyActionMessage(ReservEntry);

        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then begin
            GetItem(ReservEntry."Item No.");
            ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
            OnCloseReservEntryOnAfterReservEntry2Get(ReservEntry2, ReservEntry);
            OriginalReservEntry2 := ReservEntry2;
            if (Item."Order Tracking Policy" = Item."Order Tracking Policy"::None) and
               (not TransferLineWithItemTracking(ReservEntry2)) and
               (((ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order") and ReservEntry2.Positive) or
                (ReservEntry2."Source Type" = Database::"Item Ledger Entry") or not ReservEntry2.TrackingExists())
            then
                ReservEntry2.Delete()
            else begin
                ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;

                if ReservEntry2.Positive then begin
                    AvailabilityDate := ReservEntry2."Expected Receipt Date";
                    ReservEntry2."Shipment Date" := 0D
                end else begin
                    AvailabilityDate := ReservEntry2."Shipment Date";
                    ReservEntry2."Expected Receipt Date" := 0D;
                end;
                ReservEntry2.Modify();
                ReservMgt.SetSkipUntrackedSurplus(true);
                ReservEntry2."Quantity (Base)" :=
                  ReservMgt.MatchSurplus(ReservEntry2, SurplusReservEntry, ReservEntry2."Quantity (Base)", not ReservEntry2.Positive,
                    AvailabilityDate, Item."Order Tracking Policy");
                if ReservEntry2."Quantity (Base)" = 0 then begin
                    OnCloseReservEntryOnBeforeDeleteReservEntry2(ReservEntry2, OriginalReservEntry2);
                    ReservEntry2.Delete(true);
                end else begin
                    ReservEntry2.Validate("Quantity (Base)");
                    ReservEntry2.Validate(Binding, ReservEntry2.Binding::" ");
                    if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::None then
                        ReservEntry2."Untracked Surplus" := ReservEntry2.IsResidualSurplus();
                    OnCloseReservEntryOnBeforeModifyReservEntry2(ReservEntry2, OriginalReservEntry2);
                    ReservEntry2.Modify();

                    if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then begin
                        ModifyActionMessageDating(ReservEntry2);
                        if DeleteAll then
                            ReservMgt.IssueActionMessage(ReservEntry2, false, ReservEntry)
                        else
                            ReservMgt.IssueActionMessage(ReservEntry2, false, DummyReservEntry);
                    end;
                end;
            end;
        end;

        if ReTrack then begin
            TotalQty := ReservMgt.SourceQuantity(ReservEntry, true);
            ReservMgt.AutoTrack(TotalQty);
        end;

        OnAfterCloseReservEntry(ReservEntry);
    end;

    procedure CloseSurplusTrackingEntry(ReservEntry: Record "Reservation Entry")
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry.Delete();
        GetItem(ReservEntry."Item No.");
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Prospect then
            exit;

        ModifyActionMessage(ReservEntry);
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then begin
            ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
            if not TransferLineWithItemTracking(ReservEntry2) and
               ((ReservEntry2."Source Type" = Database::"Item Ledger Entry") or not ReservEntry2.TrackingExists())
            then
                ReservEntry2.Delete()
            else begin
                ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;
                ReservEntry2.Modify();
            end;
        end;
    end;

    procedure ModifyReservEntry(ReservEntry: Record "Reservation Entry"; NewQuantity: Decimal; NewDescription: Text[100]; ModifyReserved: Boolean)
    var
        TotalQty: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeModifyReservEntry(ReservEntry, NewQuantity, NewDescription, ModifyReserved);

        IsHandled := false;
        OnBeforeModifyReservEntryOnCheckNewQuantity(ReservEntry, NewQuantity, NewDescription, ModifyReserved, IsHandled);
        if not IsHandled then begin
            ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Reservation);
            if NewQuantity * ReservEntry."Quantity (Base)" < 0 then
                if NewQuantity < 0 then
                    Error(Text000, ReservEntry.FieldCaption("Quantity (Base)"))
                else
                    Error(Text001, ReservEntry.FieldCaption("Quantity (Base)"));
            if NewQuantity = 0 then
                Error(Text002);
            if Abs(NewQuantity) > Abs(ReservEntry."Quantity (Base)") then
                Error(Text003, ReservEntry.FieldCaption("Quantity (Base)"));
        end;

        if ModifyReserved then begin
            if ReservEntry."Item No." <> Item."No." then
                GetItem(ReservEntry."Item No.");

            ReservEntry.Get(ReservEntry."Entry No.", ReservEntry.Positive); // Get existing entry
            ReservEntry.Validate("Quantity (Base)", NewQuantity);
            ReservEntry.Description := NewDescription;
            ReservEntry."Changed By" := UserId;
            OnModifyReservEntryOnBeforeExistingReservEntryModify(ReservEntry);
            ReservEntry.Modify();
            OnModifyReservEntryOnAfterExistingReservEntryModify(ReservEntry);
            if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::None then begin
                TotalQty := ReservMgt.SourceQuantity(ReservEntry, true);
                ReservMgt.AutoTrack(TotalQty);
            end;

            if ReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then begin // Get related entry
                ReservEntry.Validate("Quantity (Base)", -NewQuantity);
                ReservEntry.Description := NewDescription;
                ReservEntry."Changed By" := UserId;
                ReservEntry.Modify();
                if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::None then begin
                    TotalQty := ReservMgt.SourceQuantity(ReservEntry, true);
                    ReservMgt.AutoTrack(TotalQty);
                end;
            end;
        end;

        OnAfterModifyReservEntry(ReservEntry);
    end;

    procedure CreateForText(ReservEntry: Record "Reservation Entry"): Text[80]
    begin
        if ReservEntry.Get(ReservEntry."Entry No.", false) then
            exit(CreateText(ReservEntry));

        exit('');
    end;

    procedure CreateFromText(ReservEntry: Record "Reservation Entry"): Text[80]
    begin
        if ReservEntry.Get(ReservEntry."Entry No.", true) then
            exit(CreateText(ReservEntry));

        exit('');
    end;

    procedure CreateText(ReservEntry: Record "Reservation Entry") SourceTypeDesc: Text[80]
    begin
        OnCreateText(ReservEntry, SourceTypeDesc);
        if SourceTypeDesc <> '' then
            exit;

        SourceTypeDesc := '';
        OnAfterCreateText(ReservEntry, SourceTypeDesc);
        exit(SourceTypeDesc);
    end;

    procedure ModifyShipmentDate(var ReservEntry: Record "Reservation Entry"; NewShipmentDate: Date)
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry2 := ReservEntry;
        ReservEntry2."Shipment Date" := NewShipmentDate;
        ReservEntry2."Changed By" := UserId;
        ReservEntry2.Modify();

        if ReservEntry2.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin // Get related entry
            ReservEntry2."Shipment Date" := NewShipmentDate;
            ReservEntry2."Changed By" := UserId;
            ReservEntry2.Modify();

            ModifyActionMessageDating(ReservEntry2);
        end;

        OnAfterModifyShipmentDate(ReservEntry2, ReservEntry);
    end;

    local procedure ModifyActionMessage(ReservEntry: Record "Reservation Entry")
    begin
        GetItem(ReservEntry."Item No.");
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Surplus then begin
            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                ReservMgt.ModifyActionMessage(ReservEntry."Entry No.", 0, true); // Delete related action messages
        end else
            if ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order" then
                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                    ReservMgt.ModifyActionMessage(ReservEntry."Entry No.", 0, true); // Delete related action messages
    end;

    procedure ModifyExpectedReceiptDate(var ReservEntry: Record "Reservation Entry"; NewExpectedReceiptDate: Date)
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry2 := ReservEntry;
        ReservEntry2."Expected Receipt Date" := NewExpectedReceiptDate;
        ReservEntry2."Changed By" := UserId;
        ReservEntry2.Modify();

        ModifyActionMessageDating(ReservEntry2);

        if ReservEntry2.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin // Get related entry
            ReservEntry2."Expected Receipt Date" := NewExpectedReceiptDate;
            ReservEntry2."Changed By" := UserId;
            ReservEntry2.Modify();
        end;

        OnAfterModifyExpectedReceiptDate(ReservEntry2, ReservEntry);
    end;

    procedure InitFilterAndSortingFor(var FilterReservEntry: Record "Reservation Entry"; SetFilters: Boolean)
    begin
        FilterReservEntry.InitSortingAndFilters(SetFilters);
    end;

    procedure InitFilterAndSortingLookupFor(var FilterReservEntry: Record "Reservation Entry"; SetFilters: Boolean)
    begin
        FilterReservEntry.InitSortingAndFilters(SetFilters);
    end;

    procedure ModifyUnitOfMeasure(var ReservEntry: Record "Reservation Entry"; NewQtyPerUnitOfMeasure: Decimal)
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry.TestField("Source Type");
        ReservEntry2.Reset();
        ReservEntry2.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");

        ReservEntry2.SetSourceFilterFromReservEntry(ReservEntry);

        if ReservEntry2.FindSet() then
            if NewQtyPerUnitOfMeasure <> ReservEntry2."Qty. per Unit of Measure" then
                repeat
                    ReservEntry2.Validate("Qty. per Unit of Measure", NewQtyPerUnitOfMeasure);
                    ReservEntry2.Modify();
                until ReservEntry2.Next() = 0;
    end;

    procedure ModifyActionMessageDating(var ReservEntry: Record "Reservation Entry")
    var
        ReservEntry2: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
        DampenerPeriod: DateFormula;
        DateFormula: DateFormula;
        FirstDate: Date;
        NextEntryNo: Integer;
    begin
        if not ShouldModifyActionMessageDating(ReservEntry) then
            exit;

        if not ReservEntry.Positive then
            exit;

        GetItem(ReservEntry."Item No.");
        if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::"Tracking & Action Msg." then
            exit;

        ActionMessageEntry.SetCurrentKey(
          "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
        ActionMessageEntry.SetSourceFilterFromReservEntry(ReservEntry);
        ActionMessageEntry.SetRange(Quantity, 0);

        ReservEntry2.Copy(ReservEntry);
        ReservEntry2.SetPointerFilter();
        ReservEntry2.SetRange(
          "Reservation Status", ReservEntry2."Reservation Status"::Reservation, ReservEntry2."Reservation Status"::Tracking);
        FirstDate := ReservMgt.FindDate(ReservEntry2, 0, true);

        OnModifyActionMessageDatingOnGetDampenerPeriod(ReservEntry, DampenerPeriod);

        ActionMessageEntry.DeleteAll();

        if FirstDate = 0D then
            exit;

        Evaluate(DateFormula, StrSubstNo('%1%2', '-', Format(DampenerPeriod)));
        if CalcDate(DateFormula, FirstDate) <= ReservEntry."Expected Receipt Date" then
            exit;

        if ReservEntry."Planning Flexibility" = ReservEntry."Planning Flexibility"::None then
            exit;

        ActionMessageEntry.Reset();
        NextEntryNo := ActionMessageEntry.GetLastEntryNo() + 1;
        ActionMessageEntry.Init();
        ActionMessageEntry.TransferFromReservEntry(ReservEntry);
        ActionMessageEntry."Entry No." := NextEntryNo;
        ActionMessageEntry.Type := ActionMessageEntry.Type::Reschedule;
        ActionMessageEntry."New Date" := FirstDate;
        ActionMessageEntry."Reservation Entry" := ReservEntry2."Entry No.";
        while not ActionMessageEntry.Insert() do
            ActionMessageEntry."Entry No." += 1;
    end;

    local procedure ShouldModifyActionMessageDating(ReservationEntry: Record "Reservation Entry") Result: Boolean
    begin
        Result := ReservationEntry."Source Type" = Database::"Purchase Line";
        OnAfterShouldModifyActionMessageDating(ReservationEntry, Result);
    end;

    procedure AddItemTrackingToTempRecSet(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; ItemTrackingCode: Record "Item Tracking Code"): Decimal
    begin
        LostReservationQty := 0;
        // Late Binding
        ReservationsModified := false;
        TempReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
        // Process entry in descending order against field Reservation Status
        ModifyItemTrkgByReservStatus(
            TempReservEntry, TrackingSpecification, TempReservEntry."Reservation Status"::Prospect, QtyToAdd, QtyToAddAsBlank, ItemTrackingCode);
        ModifyItemTrkgByReservStatus(
            TempReservEntry, TrackingSpecification, TempReservEntry."Reservation Status"::Surplus, QtyToAdd, QtyToAddAsBlank, ItemTrackingCode);
        ModifyItemTrkgByReservStatus(
            TempReservEntry, TrackingSpecification, TempReservEntry."Reservation Status"::Reservation, QtyToAdd, QtyToAddAsBlank, ItemTrackingCode);
        ModifyItemTrkgByReservStatus(
            TempReservEntry, TrackingSpecification, TempReservEntry."Reservation Status"::Tracking, QtyToAdd, QtyToAddAsBlank, ItemTrackingCode);

        exit(QtyToAdd);
    end;

    local procedure ModifyItemTrkgByReservStatus(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; ReservStatus: Enum "Reservation Status"; var QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; ItemTrackingCode: Record "Item Tracking Code")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyItemTrkgByReservStatus(TempReservEntry, TrackingSpecification, ReservStatus, QtyToAdd, QtyToAddAsBlank, ItemTrackingCode, IsHandled);
        if IsHandled then
            exit;

        if QtyToAdd = 0 then
            exit;

        TempReservEntry.SetRange("Reservation Status", ReservStatus);
        if TempReservEntry.FindSet() then
            repeat
                QtyToAdd :=
                  ModifyItemTrackingOnTempRec(
                      TempReservEntry, TrackingSpecification, QtyToAdd, QtyToAddAsBlank, 0,
                      ItemTrackingCode, false, false);
            until (TempReservEntry.Next() = 0) or (QtyToAdd = 0);
    end;

    local procedure ModifyItemTrackingOnTempRec(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; LastEntryNo: Integer; ItemTrackingCode: Record "Item Tracking Code"; EntryMismatch: Boolean; CalledRecursively: Boolean): Decimal
    var
        TempReservEntryCopy: Record "Reservation Entry" temporary;
        ReservEntry1: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        TempReservEntry2: Record "Reservation Entry" temporary;
        TrackingSpecification2: Record "Tracking Specification";
        QtyToAdd2: Decimal;
        ModifyPartnerRec: Boolean;
    begin
        if not CalledRecursively then begin
            TempReservEntryCopy := TempReservEntry;

            if TempReservEntry."Reservation Status" in
               [TempReservEntry."Reservation Status"::Reservation,
                TempReservEntry."Reservation Status"::Tracking]
            then begin
                ModifyPartnerRec := true;
                ReservEntry1 := TempReservEntry;
                ReservEntry1.Get(ReservEntry1."Entry No.", not ReservEntry1.Positive);
                TempReservEntry2 := ReservEntry1;
                TrackingSpecification2 := TrackingSpecification;

                SetItemTracking2(TempReservEntry2, TrackingSpecification2);

                EntryMismatch :=
                  CheckTrackingNoMismatch(
                      TempReservEntry, TrackingSpecification, TrackingSpecification2, ItemTrackingCode);
                QtyToAdd2 := -QtyToAdd;
            end;
        end;

        ReservEntry1 := TempReservEntry;
        ReservEntry1.Get(TempReservEntry."Entry No.", TempReservEntry.Positive);
        if Abs(TempReservEntry."Quantity (Base)") > Abs(QtyToAdd) then begin // Split entry
            ReservEntry2 := TempReservEntry;
            ReservEntry2.Validate("Quantity (Base)", QtyToAdd);
            ReservEntry2.CopyTrackingFromSpec(TrackingSpecification);
            ReservEntry2."Warranty Date" := TrackingSpecification."Warranty Date";
            ReservEntry2."Expiration Date" := TrackingSpecification."Expiration Date";
            ReservEntry2."Entry No." := LastEntryNo;
            if ReservEntry2."Serial No." <> '' then
                ReservEntry2."Untracked Surplus" := false;
            OnBeforeUpdateItemTracking(ReservEntry2, TrackingSpecification);
            ReservEntry2.UpdateItemTracking();
            if EntryMismatch then begin
                if not CalledRecursively then
                    SaveLostReservQty(ReservEntry2); // Late Binding
                ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;
                if ReservEntry2."Source Type" = Database::"Item Ledger Entry" then begin
                    GetItem(ReservEntry2."Item No.");
                    if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                        ReservEntry2."Quantity (Base)" := 0;
                end;
            end else
                if not CalledRecursively then
                    ReservationsModified := ReservEntry2."Reservation Status" = ReservEntry2."Reservation Status"::Reservation;
            if not CalledRecursively then
                VerifySurplusRecord(ReservEntry2, QtyToAddAsBlank);
            if ReservEntry2."Quantity (Base)" <> 0 then begin
                ReservEntry2.Insert();
                LastEntryNo := ReservEntry2."Entry No.";
            end;

            if EntryMismatch then
                LastEntryNo := 0;

            ReservEntry1.Validate("Quantity (Base)", ReservEntry1."Quantity (Base)" - QtyToAdd);
            OnModifyItemTrackingOnTempRecOnBeforeModifyReservEntry(ReservEntry1);
            ReservEntry1.Modify();
            TempReservEntry := ReservEntry1;
            if not CalledRecursively then begin
                TempReservEntry := ReservEntry2;
                if TempReservEntry."Quantity (Base)" <> 0 then
                    TempReservEntry.Insert();
                TempReservEntry := ReservEntry1;
                TempReservEntry.Modify();
            end else
                TempReservEntry := ReservEntry1;
            QtyToAdd := 0;
            UpdateTempSurplusEntry(ReservEntry1);
            UpdateTempSurplusEntry(ReservEntry2);
        end else begin // Modify entry directly
            ReservEntry1."Qty. to Handle (Base)" := ReservEntry1."Quantity (Base)";
            ReservEntry1."Qty. to Invoice (Base)" := ReservEntry1."Quantity (Base)";
            ReservEntry1.CopyTrackingFromSpec(TrackingSpecification);
            ReservEntry1."Warranty Date" := TrackingSpecification."Warranty Date";
            ReservEntry1."Expiration Date" := TrackingSpecification."Expiration Date";
            if ReservEntry1."Serial No." <> '' then
                ReservEntry1."Untracked Surplus" := false;
            if ReservEntry1.Positive then
                ReservEntry1."Appl.-from Item Entry" := TrackingSpecification."Appl.-from Item Entry"
            else
                ReservEntry1."Appl.-to Item Entry" := TrackingSpecification."Appl.-to Item Entry";
            OnBeforeUpdateItemTracking(ReservEntry1, TrackingSpecification);
            ReservEntry1.UpdateItemTracking();
            if EntryMismatch then begin
                if not CalledRecursively then
                    SaveLostReservQty(ReservEntry1); // Late Binding
                GetItem(ReservEntry1."Item No.");
                if (ReservEntry1."Source Type" = Database::"Item Ledger Entry") and
                   (Item."Order Tracking Policy" = Item."Order Tracking Policy"::None)
                then
                    ReservEntry1.Delete()
                else begin
                    ReservEntry1."Reservation Status" := ReservEntry1."Reservation Status"::Surplus;
                    if CalledRecursively then begin
                        ReservEntry1.Delete();
                        ReservEntry1."Entry No." := LastEntryNo;
                        ReservEntry1.Insert();
                        LastEntryNo := ReservEntry1."Entry No.";
                    end else
                        ReservEntry1.Modify();
                end;
            end else begin
                if not CalledRecursively then
                    ReservationsModified := ReservEntry2."Reservation Status" = ReservEntry2."Reservation Status"::Reservation;
                ReservEntry1.Modify();
            end;
            QtyToAdd -= ReservEntry1."Quantity (Base)";
            if not CalledRecursively then begin
                if VerifySurplusRecord(ReservEntry1, QtyToAddAsBlank) then
                    ReservEntry1.Modify();
                if ReservEntry1."Quantity (Base)" = 0 then begin
                    TempReservEntry := ReservEntry1;
                    TempReservEntry.Delete();
                    ReservEntry1.Delete();
                    ReservMgt.ModifyActionMessage(ReservEntry1."Entry No.", 0, true); // Delete related Action Msg.
                end else begin
                    TempReservEntry := ReservEntry1;
                    TempReservEntry.Modify();
                end;
            end;
            UpdateTempSurplusEntry(ReservEntry1);
        end;

        if ModifyPartnerRec then
            ModifyItemTrackingOnTempRec(
                TempReservEntry2, TrackingSpecification2, QtyToAdd2, QtyToAddAsBlank, LastEntryNo,
                ItemTrackingCode, EntryMismatch, true);

        TempSurplusEntry.Reset();
        if TempSurplusEntry.FindSet() then begin
            GetItem(TempSurplusEntry."Item No.");
            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                repeat
                    UpdateActionMessages(TempSurplusEntry);
                until TempSurplusEntry.Next() = 0;
        end;

        if not CalledRecursively then
            TempReservEntry := TempReservEntryCopy;

        exit(QtyToAdd);
    end;

    local procedure VerifySurplusRecord(var ReservEntry: Record "Reservation Entry"; var QtyToAddAsBlank: Decimal) Modified: Boolean
    begin
        if ReservEntry.TrackingExists() then
            exit;
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Prospect then begin
            ReservEntry.Validate("Quantity (Base)", 0);
            exit(true);
        end;
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then
            exit;
        if QtyToAddAsBlank * ReservEntry."Quantity (Base)" < 0 then
            Error(Text006);
        if Abs(QtyToAddAsBlank) < Abs(ReservEntry."Quantity (Base)") then begin
            ReservEntry.Validate("Quantity (Base)", QtyToAddAsBlank);
            Modified := true;
        end;
        QtyToAddAsBlank -= ReservEntry."Quantity (Base)";
        exit(Modified);
    end;

    local procedure UpdateTempSurplusEntry(var ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Surplus then
            exit;
        if ReservEntry."Quantity (Base)" = 0 then
            exit;
        TempSurplusEntry := ReservEntry;
        if not TempSurplusEntry.Insert() then
            TempSurplusEntry.Modify();
    end;

    procedure CollectAffectedSurplusEntries(var TempReservEntry: Record "Reservation Entry" temporary): Boolean
    begin
        TempSurplusEntry.Reset();
        TempReservEntry.Reset();

        if not TempSurplusEntry.FindSet() then
            exit(false);

        repeat
            TempReservEntry := TempSurplusEntry;
            TempReservEntry.Insert();
        until TempSurplusEntry.Next() = 0;

        TempSurplusEntry.DeleteAll();

        exit(true);
    end;

    procedure UpdateOrderTracking(var TempReservEntry: Record "Reservation Entry" temporary)
    var
        ReservEntry: Record "Reservation Entry";
        SurplusEntry: Record "Reservation Entry";
        TempProcessedReservationEntry: Record "Reservation Entry" temporary;
        ReservationMgt: Codeunit "Reservation Management";
        AvailabilityDate: Date;
        FirstLoop: Boolean;
    begin
        FirstLoop := true;

        while TempReservEntry.FindSet() do begin
            if FirstLoop then begin
                GetItem(TempReservEntry."Item No.");
                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then begin
                    repeat
                        if (TempReservEntry."Source Type" = Database::"Item Ledger Entry") or not TempReservEntry.TrackingExists() then begin
                            ReservEntry := TempReservEntry;
                            ReservEntry.Delete();
                        end;
                    until TempReservEntry.Next() = 0;
                    exit;
                end;
                ReservationMgt.SetSkipUntrackedSurplus(true);
                FirstLoop := false;
            end;
            Clear(SurplusEntry);
            SurplusEntry.TestField("Entry No.", 0);
            TempReservEntry.TestField("Item No.", Item."No.");
            if ReservEntry.Get(TempReservEntry."Entry No.", TempReservEntry.Positive) then
                if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Surplus then
                    ReservEntry."Quantity (Base)" := ReservationMgt.MatchSurplus(ReservEntry, SurplusEntry,
                        ReservEntry."Quantity (Base)", not ReservEntry.Positive, AvailabilityDate, Item."Order Tracking Policy");
            TempReservEntry.Delete();
            if SurplusEntry."Entry No." <> 0 then begin
                if ReservEntry."Quantity (Base)" = 0 then
                    ReservEntry.Delete(true)
                else begin
                    ReservEntry.Validate("Quantity (Base)");
                    ReservEntry.Modify();
                end;
                if not TempProcessedReservationEntry.Get(SurplusEntry."Entry No.", SurplusEntry.Positive) then begin
                    TempReservEntry := SurplusEntry;
                    if not TempReservEntry.Insert() then
                        TempReservEntry.Modify();

                    TempProcessedReservationEntry := SurplusEntry;
                    TempProcessedReservationEntry.Insert();
                end;
            end;
        end;
    end;

    procedure UpdateActionMessages(SurplusEntry: Record "Reservation Entry")
    var
        DummyReservEntry: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ActionMessageEntry.Reset();
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", SurplusEntry."Entry No.");
        if not ActionMessageEntry.IsEmpty() then
            ActionMessageEntry.DeleteAll();
        if not (SurplusEntry."Reservation Status" = SurplusEntry."Reservation Status"::Surplus) then
            exit;
        ReservMgt.IssueActionMessage(SurplusEntry, false, DummyReservEntry);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    local procedure UpdateSourcePlanned(ReservEntry: Record "Reservation Entry")
    var
        SalesLine: Record "Sales Line";
    begin
        if ReservEntry."Source Type" = Database::"Sales Line" then begin
            SalesLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
            SalesLine.UpdatePlanned();
            SalesLine.Modify();
        end;
    end;

    local procedure ItemTrackingMismatch(ReservEntry: Record "Reservation Entry"; NewItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        ReservEntry2: Record "Reservation Entry";
        IsMismatch: Boolean;
    begin
        if not NewItemTrackingSetup.TrackingExists() then
            exit(false);

        if not ReservEntry.IsReservationOrTracking() then
            exit(false);

        ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);

        if ReservEntry2."Item Tracking" = ReservEntry2."Item Tracking"::None then
            exit(false);

        if (ReservEntry2."Lot No." <> '') and (NewItemTrackingSetup."Lot No." <> '') then
            if ReservEntry2."Lot No." <> NewItemTrackingSetup."Lot No." then
                exit(true);

        if (ReservEntry2."Serial No." <> '') and (NewItemTrackingSetup."Serial No." <> '') then
            if ReservEntry2."Serial No." <> NewItemTrackingSetup."Serial No." then
                exit(true);

        IsMismatch := false;
        OnAfterItemTrackingMismatch(ReservEntry2, NewItemTrackingSetup, IsMismatch);
        exit(IsMismatch);
    end;

    procedure InitRecordSet(var ReservEntry: Record "Reservation Entry"): Boolean
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(InitRecordSet(ReservEntry, DummyItemTrackingSetup));
    end;

    procedure InitRecordSet(var ReservEntry: Record "Reservation Entry"; CurrItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        IsDemand: Boolean;
        CarriesItemTracking: Boolean;
        IsHandled: Boolean;
    begin
        // Used for combining sorting of reservation entries with priorities
        if not ReservEntry.FindSet() then
            exit(false);

        IsDemand := ReservEntry."Quantity (Base)" < 0;

        TempSortRec1.Reset();
        TempSortRec2.Reset();
        TempSortRec3.Reset();
        TempSortRec4.Reset();

        TempSortRec1.DeleteAll();
        TempSortRec2.DeleteAll();
        TempSortRec3.DeleteAll();
        TempSortRec4.DeleteAll();

        repeat
            if not ItemTrackingMismatch(ReservEntry, CurrItemTrackingSetup) then begin
                TempSortRec1 := ReservEntry;
                TempSortRec1.Insert();

                IsHandled := false;
                OnInitRecordSetOnBeforeCheckItemTrackingExists(CarriesItemTracking, TempSortRec1, IsHandled);
                if not IsHandled then
                    CarriesItemTracking := TempSortRec1.TrackingExists();
                if CarriesItemTracking then begin
                    TempSortRec2 := TempSortRec1;
                    TempSortRec2.Insert();
                end;

                if TempSortRec1."Reservation Status" = TempSortRec1."Reservation Status"::Reservation then
                    if TempSortRec1."Expected Receipt Date" = 0D then // Inventory
                        if IsDemand then
                            if CarriesItemTracking then begin
                                TempSortRec4 := TempSortRec1;
                                TempSortRec4.Insert();
                                TempSortRec2.Delete();
                            end else begin
                                TempSortRec3 := TempSortRec1;
                                TempSortRec3.Insert();
                            end;
            end;
        until ReservEntry.Next() = 0;

        SetKeyAndFilters(TempSortRec1);
        SetKeyAndFilters(TempSortRec2);
        SetKeyAndFilters(TempSortRec3);
        SetKeyAndFilters(TempSortRec4);

        exit(NEXTRecord(ReservEntry) <> 0);
    end;

    procedure NEXTRecord(var ReservEntry: Record "Reservation Entry"): Integer
    var
        Found: Boolean;
    begin
        // Used for combining sorting of reservation entries with priorities
        if not TempSortRec1.FindFirst() then
            exit(0);

        if TempSortRec1."Reservation Status" = TempSortRec1."Reservation Status"::Reservation then
            if not TempSortRec4.IsEmpty() then begin // Reservations with item tracking against inventory
                TempSortRec4.FindFirst();
                TempSortRec1 := TempSortRec4;
                TempSortRec4.Delete();
                Found := true;
            end else
                if not TempSortRec3.IsEmpty() then begin // Reservations with no item tracking against inventory
                    TempSortRec3.FindFirst();
                    TempSortRec1 := TempSortRec3;
                    TempSortRec3.Delete();
                    Found := true;
                end;

        if not Found then begin
            TempSortRec2.SetRange("Reservation Status", TempSortRec1."Reservation Status");
            OnNextRecordOnAfterFilterTempSortRec2(TempSortRec2, TempSortRec1);
            if not TempSortRec2.IsEmpty() then begin // Records carrying item tracking
                TempSortRec2.FindFirst();
                TempSortRec1 := TempSortRec2;
                TempSortRec2.Delete();
            end else begin
                TempSortRec2.SetRange("Reservation Status");
                if not TempSortRec2.IsEmpty() then begin // Records carrying item tracking
                    TempSortRec2.FindFirst();
                    TempSortRec1 := TempSortRec2;
                    TempSortRec2.Delete();
                end;
            end;
        end;

        ReservEntry := TempSortRec1;
        TempSortRec1.Delete();
        exit(1);
    end;

    local procedure SetKeyAndFilters(var ReservEntry: Record "Reservation Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetKeyAndFilters(ReservEntry, IsHandled);
        if IsHandled then
            exit;

        if ReservEntry.IsEmpty() then
            exit;

        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");

        if ReservEntry.FindFirst() then
            ReservEntry.SetPointerFilter();
    end;

    procedure RenamePointer(TableID: Integer; OldSubtype: Integer; OldID: Code[20]; OldBatchName: Code[10]; OldProdOrderLine: Integer; OldRefNo: Integer; NewSubtype: Integer; NewID: Code[20]; NewBatchName: Code[10]; NewProdOrderLine: Integer; NewRefNo: Integer)
    var
        ReservEntry: Record "Reservation Entry";
        NewReservEntry: Record "Reservation Entry";
        W: Dialog;
        PointerFieldIsActive: array[6] of Boolean;
    begin
        GetActivePointerFields(TableID, PointerFieldIsActive);
        if not PointerFieldIsActive[1] then
            exit;

        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");

        if PointerFieldIsActive[3] then
            ReservEntry.SetRange("Source ID", OldID)
        else
            ReservEntry.SetRange("Source ID", '');

        if PointerFieldIsActive[6] then
            ReservEntry.SetRange("Source Ref. No.", OldRefNo)
        else
            ReservEntry.SetRange("Source Ref. No.", 0);

        ReservEntry.SetRange("Source Type", TableID);

        if PointerFieldIsActive[2] then
            ReservEntry.SetRange("Source Subtype", OldSubtype)
        else
            ReservEntry.SetRange("Source Subtype", 0);

        if PointerFieldIsActive[4] then
            ReservEntry.SetRange("Source Batch Name", OldBatchName)
        else
            ReservEntry.SetRange("Source Batch Name", '');

        if PointerFieldIsActive[5] then
            ReservEntry.SetRange("Source Prod. Order Line", OldProdOrderLine)
        else
            ReservEntry.SetRange("Source Prod. Order Line", 0);

        ReservEntry.LockTable();

        if ReservEntry.FindSet() then begin
            W.Open(Text007);
            repeat
                NewReservEntry := ReservEntry;
                if OldSubtype <> NewSubtype then
                    NewReservEntry."Source Subtype" := NewSubtype;
                if OldID <> NewID then
                    NewReservEntry."Source ID" := NewID;
                if OldBatchName <> NewBatchName then
                    NewReservEntry."Source Batch Name" := NewBatchName;
                if OldProdOrderLine <> NewProdOrderLine then
                    NewReservEntry."Source Prod. Order Line" := NewProdOrderLine;
                if OldRefNo <> NewRefNo then
                    NewReservEntry."Source Ref. No." := NewRefNo;
                ReservEntry.Delete();
                NewReservEntry.Insert();
            until ReservEntry.Next() = 0;
            W.Close();
        end;
    end;

    local procedure GetActivePointerFields(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean)
    var
        IsHandled: Boolean;
    begin
        Clear(PointerFieldIsActive);
        PointerFieldIsActive[1] := true;  // Type

        IsHandled := false;
        OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID, PointerFieldIsActive, IsHandled);
        if IsHandled then
            exit;

        case TableID of
            Database::"Item Ledger Entry":
                PointerFieldIsActive[6] := true;  // RefNo
            else
                PointerFieldIsActive[1] := false;  // Type is not used
        end;
    end;

    procedure SplitTrackingConnection(ReservEntry2: Record "Reservation Entry"; NewDate: Date)
    var
        ActionMessageEntry: Record "Action Message Entry";
        ReservEntry3: Record "Reservation Entry";
        DummyReservEntry: Record "Reservation Entry";
    begin
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", ReservEntry2."Entry No.");
        if not ActionMessageEntry.IsEmpty() then
            ActionMessageEntry.DeleteAll();

        if ReservEntry2.Positive then begin
            ReservEntry2."Expected Receipt Date" := NewDate;
            ReservEntry2."Shipment Date" := 0D;
        end else begin
            ReservEntry2."Shipment Date" := NewDate;
            ReservEntry2."Expected Receipt Date" := 0D;
        end;
        ReservEntry2."Changed By" := UserId;
        ReservEntry2."Reservation Status" := ReservEntry2."Reservation Status"::Surplus;
        ReservEntry2.Modify();

        if ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin // Get related entry
            ReservEntry3.Delete();
            ReservEntry3."Entry No." := 0;
            ReservEntry3."Reservation Status" := ReservEntry3."Reservation Status"::Surplus;
            if ReservEntry3.Positive then
                ReservEntry3."Shipment Date" := 0D
            else
                ReservEntry3."Expected Receipt Date" := 0D;
            ReservEntry3.Insert();
        end else
            Clear(ReservEntry3);

        if ReservEntry2."Quantity (Base)" <> 0 then
            ReservMgt.IssueActionMessage(ReservEntry2, false, DummyReservEntry);

        if ReservEntry3."Quantity (Base)" <> 0 then
            ReservMgt.IssueActionMessage(ReservEntry3, false, DummyReservEntry);
    end;

    local procedure SaveLostReservQty(ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation then begin
            LostReservationQty += ReservEntry."Quantity (Base)";
            ReservationsModified := true;
        end;
    end;

    procedure RetrieveLostReservQty(var LostQuantity: Decimal) ReservEntriesHaveBeenModified: Boolean
    begin
        LostQuantity := LostReservationQty;
        LostReservationQty := 0;
        ReservEntriesHaveBeenModified := ReservationsModified;
        ReservationsModified := false;
    end;

    local procedure SetItemTracking2(TempReservEntry2: Record "Reservation Entry"; var TrackingSpecification2: Record "Tracking Specification")
    var
        ShouldRaiseError: Boolean;
    begin
        if TempReservEntry2.Binding = TempReservEntry2.Binding::"Order-to-Order" then begin
            // only supply can change IT and demand must respect it

            ShouldRaiseError := TempReservEntry2.Positive and not TempReservEntry2.HasSameTrackingWithSpec(TrackingSpecification2);
            OnSetItemTracking2OnBeforeShouldRaiseCannotStateItemTrackingError(TempReservEntry2, TrackingSpecification2, ShouldRaiseError);
            if ShouldRaiseError then
                Error(CannotStateItemTrackingErr, TempReservEntry2.FieldCaption(Binding), TempReservEntry2.Binding);
        end else
            // each record brings/holds own IT
            TrackingSpecification2.CopyTrackingFromReservEntry(TempReservEntry2);

        OnAfterSetItemTracking2(TrackingSpecification2, TempReservEntry2);
    end;

    procedure ResvExistsForSalesHeader(var SalesHeader: Record "Sales Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);

        ReservEntry.SetRange("Source Type", Database::"Sales Line");
        ReservEntry.SetRange("Source Subtype", SalesHeader."Document Type");
        ReservEntry.SetRange("Source ID", SalesHeader."No.");

        exit(ResvExistsForHeader(ReservEntry));
    end;

    procedure ResvExistsForPurchHeader(var PurchHeader: Record "Purchase Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);

        ReservEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservEntry.SetRange("Source Subtype", PurchHeader."Document Type");
        ReservEntry.SetRange("Source ID", PurchHeader."No.");

        exit(ResvExistsForHeader(ReservEntry));
    end;

    procedure ResvExistsForTransHeader(var TransHeader: Record "Transfer Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);

        ReservEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservEntry.SetRange("Source ID", TransHeader."No.");

        exit(ResvExistsForHeader(ReservEntry));
    end;

    procedure ResvExistsForHeader(var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        ReservEntry.SetFilter("Source Ref. No.", '>0');
        ReservEntry.SetFilter("Expected Receipt Date", '<>%1', 0D);

        exit(not ReservEntry.IsEmpty);
    end;

    local procedure TransferLineWithItemTracking(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit((ReservEntry."Source Type" = Database::"Transfer Line") and ReservEntry.TrackingExists());
    end;

    local procedure CheckTrackingNoMismatch(ReservEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; TrackingSpecification2: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code"): Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        if ReservEntry.Positive then begin
            ItemTrackingSetup.CopyTrackingFromTrackingSpec(TrackingSpecification2);
            ItemTrackingSetup.CheckTrackingMismatch(TrackingSpecification, ItemTrackingCode);
        end else begin
            ItemTrackingSetup.CopyTrackingFromTrackingSpec(TrackingSpecification);
            ItemTrackingSetup.CheckTrackingMismatch(TrackingSpecification2, ItemTrackingCode);
        end;
        exit(ItemTrackingSetup.TrackingMismatch());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCancelReservation(ReservationEntry3: Record "Reservation Entry"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var SourceTypeText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemTrackingMismatch(ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsMismatch: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyExpectedReceiptDate(var ReservationEntry2: Record "Reservation Entry"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyShipmentDate(var ReservationEntry2: Record "Reservation Entry"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemTracking2(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCancelReservation(var ReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCloseReservEntry(var ReservEntry: Record "Reservation Entry"; var ReTrack: Boolean; DeleteAll: Boolean; var SkipDeleteReservEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyReservEntry(ReservEntry: Record "Reservation Entry"; NewQuantity: Decimal; NewDescription: Text[100]; ModifyReserved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemTracking(var ReservEntry: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelReservationOnBeforeDoCancel(ReservationEntry3: Record "Reservation Entry"; ReservationEntry: Record "Reservation Entry"; var DoCancel: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordSetOnBeforeCheckItemTrackingExists(var CarriesItemTracking: Boolean; var TempSortRec1: Record "Reservation Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyReservEntryOnAfterExistingReservEntryModify(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyReservEntryOnBeforeExistingReservEntryModify(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextRecordOnAfterFilterTempSortRec2(var TempSortReservEntry2: Record "Reservation Entry"; TempSortReservEntry1: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetActivePointerFieldsOnBeforeAssignArrayValues(TableID: Integer; var PointerFieldIsActive: array[6] of Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelReservationOnAfterDoCancel(ReservEntry: Record "Reservation Entry"; SurplusReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyItemTrackingOnTempRecOnBeforeModifyReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCloseReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseReservEntryOnAfterReservEntry2Get(var ReservEntry2: Record "Reservation Entry"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseReservEntryOnBeforeDeleteReservEntry2(var ReservEntry2: Record "Reservation Entry"; OriginalReservEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseReservEntryOnBeforeModifyReservEntry2(var ReservEntry2: Record "Reservation Entry"; OriginalReservEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetItemTracking2OnBeforeShouldRaiseCannotStateItemTrackingError(TempReservEntry2: Record "Reservation Entry"; var TrackingSpecification2: Record "Tracking Specification"; var ShouldRaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetKeyAndFilters(var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyReservEntryOnCheckNewQuantity(var ReservEntry: Record "Reservation Entry"; var NewQuantity: Decimal; NewDescription: Text[100]; var ModifyReserved: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyItemTrkgByReservStatus(var TempReservationEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; ReservStatus: Enum "Reservation Status"; var QtyToAdd: Decimal; var QtyToAddAsBlank: Decimal; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRevertDateToSourceDate(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyActionMessageDatingOnGetDampenerPeriod(ReservEntry: Record "Reservation Entry"; var DampenerPeriod: Dateformula)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldModifyActionMessageDating(ReservationEntry: Record "Reservation Entry"; var Result: Boolean)
    begin
    end;
}

