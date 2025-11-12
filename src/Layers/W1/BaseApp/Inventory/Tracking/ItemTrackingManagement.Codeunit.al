// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

codeunit 6500 "Item Tracking Management"
{
    Permissions = TableData "Item Entry Relation" = rd,
                  TableData "Value Entry Relation" = rd,
                  TableData "Whse. Item Tracking Line" = rimd,
                  TableData "Tracking Specification" = rd;

    trigger OnRun()
    var
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TempSourceTrackingSpecification.TestField("Source Type");
        ItemTrackingLines.RegisterItemTrackingLines(TempSourceTrackingSpecification, DueDate, TempTrackingSpecification);
    end;

    var
        TempSourceTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempGlobalWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        CachedItem: Record Item;
        CachedItemTrackingCode: Record "Item Tracking Code";
        ConfirmManagement: Codeunit "Confirm Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceProdOrderLineForFilter: Integer;
        DueDate: Date;
        Registering: Boolean;
        IsConsume: Boolean;
        IsPick: Boolean;
        DeleteReservationEntries: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'No information exists for %1 %2.';
        Text005: Label 'Warehouse item tracking is not enabled for %1 %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'Synchronization cancelled.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'There are multiple expiration dates registered for lot %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TrackingNoInfoAlreadyExistsErr: Label '%1 already exists for %2 %3. Do you want to overwrite the existing information?', Comment = '%1 - tracking info table caption, %2 - tracking field caption, %3 - tracking field value';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text011: Label '%1 must not be %2.';
        Text012: Label 'Only one expiration date is allowed per lot number.\%1 currently has two different expiration dates: %2 and %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CannotMatchItemTrackingErr: Label 'Cannot match item tracking.\Document No.: %1, Line No.: %2, Item: %3 %4', Comment = '%1 - source document no., %2 - source document line no., %3 - item no., %4 - item description';
        QtyToInvoiceDoesNotMatchItemTrackingErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';

    procedure SetPointerFilter(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetSourceFilter(TrackingSpecification."Source Type", TrackingSpecification."Source Subtype", TrackingSpecification."Source ID", TrackingSpecification."Source Ref. No.", true);
        TrackingSpecification.SetSourceFilter(TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line");
    end;

    procedure LookupTrackingNoInfo(ItemNo: Code[20]; VariantCode: Code[20]; ItemTrackingType: Enum "Item Tracking Type"; ItemTrackingNo: Code[50])
    var
        LotNoInfo: Record "Lot No. Information";
        SerialNoInfo: Record "Serial No. Information";
        PackageNoInfo: Record "Package No. Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupTrackingNoInfo(ItemNo, VariantCode, ItemTrackingType, ItemTrackingNo, IsHandled);
        if IsHandled then
            exit;

        case ItemTrackingType of
            ItemTrackingType::"Serial No.":
                begin
                    if not SerialNoInfo.Get(ItemNo, VariantCode, ItemTrackingNo) then
                        Error(Text003, SerialNoInfo.FieldCaption("Serial No."), ItemTrackingNo);
                    SerialNoInfo.SetRecFilter();
                    PAGE.RunModal(0, SerialNoInfo);
                end;
            ItemTrackingType::"Lot No.":
                begin
                    if not LotNoInfo.Get(ItemNo, VariantCode, ItemTrackingNo) then
                        Error(Text003, LotNoInfo.FieldCaption("Lot No."), ItemTrackingNo);
                    LotNoInfo.SetRecFilter();
                    PAGE.RunModal(0, LotNoInfo);
                end;
            ItemTrackingType::"Package No.":
                begin
                    if not PackageNoInfo.Get(ItemNo, VariantCode, ItemTrackingNo) then
                        Error(Text003, PackageNoInfo.FieldCaption("Package No."), ItemTrackingNo);
                    PackageNoInfo.SetRecFilter();
                    PAGE.RunModal(0, PackageNoInfo);
                end;
        end;
    end;

    procedure CreateTrackingSpecification(var FromReservEntry: Record "Reservation Entry"; var ToTrackingSpecification: Record "Tracking Specification")
    begin
        ToTrackingSpecification.Init();
        ToTrackingSpecification.TransferFields(FromReservEntry);
        ToTrackingSpecification."Qty. to Handle (Base)" := 0;
        ToTrackingSpecification."Qty. to Invoice (Base)" := 0;
        ToTrackingSpecification."Quantity Handled (Base)" := FromReservEntry."Qty. to Handle (Base)";
        ToTrackingSpecification."Quantity Invoiced (Base)" := FromReservEntry."Qty. to Invoice (Base)";

        OnAfterCreateTrackingSpecification(ToTrackingSpecification, FromReservEntry);
    end;


    procedure GetItemTrackingSetup(var ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean; var ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        Clear(ItemTrackingSetup);

        if ItemTrackingCode.Code = '' then begin
            Clear(ItemTrackingCode);
            exit;
        end;
        ItemTrackingCode.Get(ItemTrackingCode.Code);

        if EntryType = EntryType::Transfer then begin
            ItemTrackingSetup."Lot No. Info Required" :=
                ItemTrackingCode."Lot Info. Outbound Must Exist" or ItemTrackingCode."Lot Info. Inbound Must Exist";
            ItemTrackingSetup."Serial No. Info Required" :=
                ItemTrackingCode."SN Info. Outbound Must Exist" or ItemTrackingCode."SN Info. Inbound Must Exist";
        end else begin
            ItemTrackingSetup."Serial No. Info Required" :=
                (Inbound and ItemTrackingCode."SN Info. Inbound Must Exist") or (not Inbound and ItemTrackingCode."SN Info. Outbound Must Exist");
            ItemTrackingSetup."Lot No. Info Required" :=
                (Inbound and ItemTrackingCode."Lot Info. Inbound Must Exist") or (not Inbound and ItemTrackingCode."Lot Info. Outbound Must Exist");
        end;

        if ItemTrackingCode."SN Specific Tracking" then
            ItemTrackingSetup."Serial No. Required" := true
        else
            case EntryType of
                EntryType::Purchase:
                    if Inbound then
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Purchase Inbound Tracking"
                    else
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Purchase Outbound Tracking";
                EntryType::Sale:
                    if Inbound then
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Sales Inbound Tracking"
                    else
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Sales Outbound Tracking";
                EntryType::"Positive Adjmt.":
                    if Inbound then
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking"
                    else
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking";
                EntryType::"Negative Adjmt.":
                    if Inbound then
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking"
                    else
                        ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking";
                EntryType::Transfer:
                    ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Transfer Tracking";
                else
                    OnGetItemTrackingSetupOnSetSerialNoRequired(ItemTrackingSetup, ItemTrackingCode, EntryType, Inbound);
            end;

        if ItemTrackingCode."Lot Specific Tracking" then
            ItemTrackingSetup."Lot No. Required" := true
        else
            case EntryType of
                EntryType::Purchase:
                    if Inbound then
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Purchase Inbound Tracking"
                    else
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Purchase Outbound Tracking";
                EntryType::Sale:
                    if Inbound then
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Sales Inbound Tracking"
                    else
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Sales Outbound Tracking";
                EntryType::"Positive Adjmt.":
                    if Inbound then
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking"
                    else
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking";
                EntryType::"Negative Adjmt.":
                    if Inbound then
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking"
                    else
                        ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking";
                EntryType::Transfer:
                    ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Transfer Tracking";
                else
                    OnGetItemTrackingSetupOnSetLotNoRequired(ItemTrackingSetup, ItemTrackingCode, EntryType, Inbound);
            end;

        if ItemTrackingCode."Package Specific Tracking" then
            ItemTrackingSetup."Package No. Required" := true
        else
            case EntryType of
                EntryType::Purchase:
                    if Inbound then
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Purchase Inb. Tracking"
                    else
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Purch. Outb. Tracking";
                EntryType::Sale:
                    if Inbound then
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Sales Inbound Tracking"
                    else
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Sales Outb. Tracking";
                EntryType::"Positive Adjmt.":
                    if Inbound then
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Pos. Inb. Tracking"
                    else
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Pos. Outb. Tracking";
                EntryType::"Negative Adjmt.":
                    if Inbound then
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Neg. Inb. Tracking"
                    else
                        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Neg. Outb. Tracking";
                EntryType::Transfer:
                    ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Transfer Tracking";
                else
                    OnGetItemTrackingSetupOnSetPackageNoRequired(ItemTrackingSetup, ItemTrackingCode, EntryType, Inbound);
            end;

        if EntryType = EntryType::Transfer then
            ItemTrackingSetup."Package No. Info Required" :=
                ItemTrackingCode."Package Info. Outb. Must Exist" or ItemTrackingCode."Package Info. Inb. Must Exist"
        else
            ItemTrackingSetup."Package No. Info Required" :=
                (Inbound and ItemTrackingCode."Package Info. Inb. Must Exist") or (not Inbound and ItemTrackingCode."Package Info. Outb. Must Exist");

        // Obsoleted
        OnAfterGetItemTrackingSettings(ItemTrackingCode);

        OnAfterGetItemTrackingSetup(ItemTrackingCode, ItemTrackingSetup, EntryType, Inbound);
    end;

    procedure RetrieveInvoiceSpecification(SourceSpecification: Record "Tracking Specification"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TempTrackingSpecSummedUp: Record "Tracking Specification" temporary;
        IsHandled: Boolean;
    begin
        OK := false;
        TempInvoicingSpecification.Reset();
        TempInvoicingSpecification.DeleteAll();

        ReservEntry.SetSourceFilter(
          SourceSpecification."Source Type", SourceSpecification."Source Subtype", SourceSpecification."Source ID",
          SourceSpecification."Source Ref. No.", true);
        ReservEntry.SetSourceFilter(SourceSpecification."Source Batch Name", SourceSpecification."Source Prod. Order Line");
        ReservEntry.SetFilter("Reservation Status", '<>%1', ReservEntry."Reservation Status"::Prospect);
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
        SumUpItemTracking(ReservEntry, TempTrackingSpecSummedUp, false, true);

        // TrackingSpecification contains information about lines that should be invoiced:
        TrackingSpecification.SetSourceFilter(
          SourceSpecification."Source Type", SourceSpecification."Source Subtype", SourceSpecification."Source ID",
          SourceSpecification."Source Ref. No.", true);
        TrackingSpecification.SetSourceFilter(
          SourceSpecification."Source Batch Name", SourceSpecification."Source Prod. Order Line");
        OnRetrieveInvoiceSpecificationOnAfterTrackingSpecificationSetFilters(SourceSpecification, TrackingSpecification);

        IsHandled := false;
        OnRetrieveInvoiceSpecificationOnBeforeFindTrackingSpecification(
            TempInvoicingSpecification, TempTrackingSpecSummedUp, TrackingSpecification, SourceSpecification, OK, IsHandled);
        if not IsHandled then
            if TrackingSpecification.FindSet() then
                repeat
                    TrackingSpecification.TestField("Qty. to Handle (Base)", 0);
                    TrackingSpecification.TestField("Qty. to Handle", 0);
                    if not TrackingSpecification.Correction then begin
                        TempInvoicingSpecification := TrackingSpecification;
                        TempInvoicingSpecification."Qty. to Invoice" :=
                        Round(TempInvoicingSpecification."Qty. to Invoice (Base)" /
                            SourceSpecification."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                        TempInvoicingSpecification.Insert();
                        OK := true;

                        TempTrackingSpecSummedUp.SetTrackingFilterFromSpec(TempInvoicingSpecification);
                        if TempTrackingSpecSummedUp.FindFirst() then begin
                            TempTrackingSpecSummedUp."Qty. to Invoice (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                            OnBeforeTempTrackingSpecSummedUpModify(TempTrackingSpecSummedUp, TempInvoicingSpecification);
                            TempTrackingSpecSummedUp.Modify();
                        end else begin
                            TempTrackingSpecSummedUp := TempInvoicingSpecification;
                            TempTrackingSpecSummedUp.Insert();
                        end;
                    end;
                until TrackingSpecification.Next() = 0;

        if not IsConsume and (SourceSpecification."Qty. to Invoice (Base)" <> 0) then
            CheckQtyToInvoiceMatchItemTracking(
              TempTrackingSpecSummedUp, TempInvoicingSpecification,
              SourceSpecification."Qty. to Invoice (Base)", SourceSpecification."Qty. per Unit of Measure");

        TempInvoicingSpecification.SetFilter("Qty. to Invoice (Base)", '<>0');
        if not TempInvoicingSpecification.FindFirst() then
            TempInvoicingSpecification.Init();
    end;

    procedure RetrieveInvoiceSpecWithService(SourceSpecification: Record "Tracking Specification"; var TempInvoicingSpecification: Record "Tracking Specification" temporary; Consume: Boolean) OK: Boolean
    begin
        IsConsume := Consume;
        OK := RetrieveInvoiceSpecification(SourceSpecification, TempInvoicingSpecification);
    end;

    procedure RetrieveItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        exit(RetrieveItemTrackingFromReservEntry(ItemJnlLine, ReservEntry, TempHandlingSpecification));
    end;

    procedure RetrieveItemTrackingFromReservEntry(ItemJnlLine: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"; var TempTrackingSpec: Record "Tracking Specification" temporary): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveItemTrackingFromReservEntry(ItemJnlLine, ReservEntry, TempTrackingSpec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ItemJnlLine.SetReservEntrySourceFilters(ReservEntry, true);

        OnAfterReserveEntryFilter(ItemJnlLine, ReservEntry);
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        ReservEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        OnRetrieveItemTrackingFromReservEntryFilter(ReservEntry, ItemJnlLine);
        if SumUpItemTracking(ReservEntry, TempTrackingSpec, false, true) then begin
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            if not ReservEntry.IsEmpty() then
                ReservEntry.DeleteAll();
            OnRetrieveItemTrackingFromReservEntryOnAfterDeleteReservEntries(TempTrackingSpec, ItemJnlLine, ReservEntry);
            exit(true);
        end;
        exit(false);
    end;

#if not CLEAN26
    [Obsolete('Moved to codeunit Mfg. Item Tracking Mgt.', '26.0')]
    procedure RetrieveConsumpItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        MfgItemTrackingMgt: Codeunit "Mfg. Item Tracking Mgt.";
    begin
        exit(MfgItemTrackingMgt.RetrieveConsumpItemTracking(ItemJnlLine, TempHandlingSpecification));
    end;
#endif

    procedure SumUpItemTracking(var ReservEntry: Record "Reservation Entry"; var TempHandlingSpecification: Record "Tracking Specification" temporary; SumPerLine: Boolean; SumPerTracking: Boolean): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        NextEntryNo: Integer;
        ExpDate: Date;
        EntriesExist: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSumUpItemTracking(ReservEntry, TempHandlingSpecification, SumPerLine, SumPerTracking, IsHandled);
        if IsHandled then begin
            TempHandlingSpecification.Reset();
            exit(TempHandlingSpecification.FindFirst());
        end;

        // Sum up Item Tracking in a temporary table (to defragment the ReservEntry records)
        TempHandlingSpecification.Reset();
        TempHandlingSpecification.DeleteAll();
        if SumPerTracking then
            TempHandlingSpecification.SetTrackingKey();

        if ReservEntry.FindSet() then begin
            GetItemTrackingCode(ReservEntry."Item No.", ItemTrackingCode);
            repeat
                if ReservEntry.TrackingExists() or (ReservEntry.IsReclass() and ReservEntry.NewTrackingExists()) then begin
                    if SumPerLine then
                        TempHandlingSpecification.SetRange("Source Ref. No.", ReservEntry."Source Ref. No."); // Sum up line per line
                    if SumPerTracking then begin
                        TempHandlingSpecification.SetTrackingFilterFromReservEntry(ReservEntry);
                        TempHandlingSpecification.SetNewTrackingFilterFromNewReservEntry(ReservEntry);
                    end;
                    OnBeforeFindTempHandlingSpecification(TempHandlingSpecification, ReservEntry);
                    if TempHandlingSpecification.FindFirst() then begin
                        TempHandlingSpecification."Quantity (Base)" += ReservEntry."Quantity (Base)";
                        TempHandlingSpecification."Qty. to Handle (Base)" += ReservEntry."Qty. to Handle (Base)";
                        TempHandlingSpecification."Qty. to Invoice (Base)" += ReservEntry."Qty. to Invoice (Base)";
                        TempHandlingSpecification."Quantity Invoiced (Base)" += ReservEntry."Quantity Invoiced (Base)";
                        TempHandlingSpecification."Qty. to Handle" :=
                          TempHandlingSpecification."Qty. to Handle (Base)" / ReservEntry."Qty. per Unit of Measure";
                        TempHandlingSpecification."Qty. to Invoice" :=
                          TempHandlingSpecification."Qty. to Invoice (Base)" / ReservEntry."Qty. per Unit of Measure";
                        if not ReservEntry.IsReservationOrTracking() then // Late Binding
                            TempHandlingSpecification."Buffer Value1" += TempHandlingSpecification."Qty. to Handle (Base)";
                        OnSumUpItemTrackingOnBeforeTempHandlingSpecificationModify(TempHandlingSpecification, ReservEntry);
                        TempHandlingSpecification.Modify();
                    end else begin
                        TempHandlingSpecification.Init();
                        TempHandlingSpecification.TransferFields(ReservEntry);
                        NextEntryNo += 1;
                        TempHandlingSpecification."Entry No." := NextEntryNo;
                        TempHandlingSpecification."Qty. to Handle" :=
                          TempHandlingSpecification."Qty. to Handle (Base)" / ReservEntry."Qty. per Unit of Measure";
                        TempHandlingSpecification."Qty. to Invoice" :=
                          TempHandlingSpecification."Qty. to Invoice (Base)" / ReservEntry."Qty. per Unit of Measure";
                        if not ReservEntry.IsReservationOrTracking() then // Late Binding
                            TempHandlingSpecification."Buffer Value1" += TempHandlingSpecification."Qty. to Handle (Base)";

                        if ItemTrackingCode."Use Expiration Dates" then begin
                            ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
                            ExpDate :=
                                ExistingExpirationDate(
                                    ReservEntry."Item No.", ReservEntry."Variant Code", ItemTrackingSetup, false, EntriesExist);
                            if EntriesExist then
                                TempHandlingSpecification."Expiration Date" := ExpDate;
                        end;
                        OnBeforeTempHandlingSpecificationInsert(TempHandlingSpecification, ReservEntry, ItemTrackingCode, EntriesExist);
                        TempHandlingSpecification.Insert();
                    end;
                end;
            until ReservEntry.Next() = 0;
        end;

        TempHandlingSpecification.Reset();
        exit(TempHandlingSpecification.FindFirst())
    end;

    procedure SumUpItemTrackingOnlyInventoryOrATO(var ReservationEntry: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification"; SumPerLine: Boolean; SumPerLotSN: Boolean): Boolean
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        QtyBase: Decimal;
    begin
        if ReservationEntry.FindSet() then
            repeat
                if (ReservationEntry."Reservation Status" <> ReservationEntry."Reservation Status"::Reservation) or
                   IsResEntryReservedAgainstInventory(ReservationEntry)
                then begin
                    TempReservationEntry := ReservationEntry;
                    TempReservationEntry.Insert();

                    QtyBase := TempReservationEntry."Quantity (Base)";
                    TempReservationEntry.SetSourceFilterFromReservEntry(ReservationEntry);
                    TempReservationEntry.SetTrackingFilterFromReservEntry(ReservationEntry);
                    TempReservationEntry.CalcSums("Quantity (Base)");
                    if TempReservationEntry."Quantity (Base)" > 0 then begin
                        TempReservationEntry.Validate("Quantity (Base)", QtyBase - TempReservationEntry."Quantity (Base)");
                        TempReservationEntry.Modify();
                    end;
                end;
            until ReservationEntry.Next() = 0;

        TempReservationEntry.Reset();
        exit(SumUpItemTracking(TempReservationEntry, TrackingSpecification, SumPerLine, SumPerLotSN));
    end;

    local procedure IsResEntryReservedAgainstInventory(ReservationEntry: Record "Reservation Entry") Result: Boolean
    var
        ReservationEntry2: Record "Reservation Entry";
    begin
        if (ReservationEntry."Reservation Status" <> ReservationEntry."Reservation Status"::Reservation) or
           ReservationEntry.Positive
        then
            exit(false);

        ReservationEntry2.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        if ReservationEntry2."Source Type" = Database::"Item Ledger Entry" then
            exit(true);

        OnAfterIsResEntryReservedAgainstInventory(ReservationEntry, Result);
    end;

    procedure DecomposeRowID(IDtext: Text[250]; var StrArray: array[6] of Text[100])
    var
        Len: Integer;
        Pos: Integer;
        ArrayIndex: Integer;
        "Count": Integer;
        Char: Text[1];
        NoWriteSinceLastNext: Boolean;
        Write: Boolean;
        Next: Boolean;
    begin
        for ArrayIndex := 1 to 6 do
            StrArray[ArrayIndex] := '';
        Len := StrLen(IDtext);
        Pos := 1;
        ArrayIndex := 1;

        while not (Pos > Len) do begin
            Char := CopyStr(IDtext, Pos, 1);
            if Char = '"' then begin
                Write := false;
                Count += 1;
            end else begin
                if Count = 0 then
                    Write := true
                else begin
                    if Count mod 2 = 1 then begin
                        Next := (Char = ';');
                        Count -= 1;
                    end else
                        if NoWriteSinceLastNext and (Char = ';') then begin
                            Count -= 2;
                            Next := true;
                        end;
                    Count /= 2;
                    while Count > 0 do begin
                        StrArray[ArrayIndex] += '"';
                        Count -= 1;
                    end;
                    Write := not Next;
                end;
                NoWriteSinceLastNext := Next;
            end;

            if Next then begin
                ArrayIndex += 1;
                Next := false
            end;

            if Write then
                StrArray[ArrayIndex] += Char;
            Pos += 1;
        end;
    end;

    procedure ComposeRowID(Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer): Text[250]
    var
        StrArray: array[2] of Text[100];
        Pos: Integer;
        Len: Integer;
        T: Integer;
    begin
        StrArray[1] := ID;
        StrArray[2] := BatchName;
        for T := 1 to 2 do
            if StrPos(StrArray[T], '"') > 0 then begin
                Len := StrLen(StrArray[T]);
                Pos := 1;
                repeat
                    if CopyStr(StrArray[T], Pos, 1) = '"' then begin
                        StrArray[T] := InsStr(StrArray[T], '"', Pos + 1);
                        Len += 1;
                        Pos += 1;
                    end;
                    Pos += 1;
                until Pos > Len;
            end;
        exit(StrSubstNo('"%1";"%2";"%3";"%4";"%5";"%6"', Type, Subtype, StrArray[1], StrArray[2], ProdOrderLine, RefNo));
    end;

    procedure CopyItemTracking(FromRowID: Text[250]; ToRowID: Text[250]; SwapSign: Boolean)
    begin
        CopyItemTracking(FromRowID, ToRowID, SwapSign, false);
    end;

    procedure CopyItemTracking(FromRowID: Text[250]; ToRowID: Text[250]; SwapSign: Boolean; SkipReservation: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetPointer(FromRowID);
        ReservEntry.SetPointerFilter();
        CopyItemTracking3(ReservEntry, ToRowID, SwapSign, SkipReservation);
    end;

    local procedure CopyItemTracking3(var ReservEntry: Record "Reservation Entry"; ToRowID: Text[250]; SwapSign: Boolean; SkipReservation: Boolean)
    var
        ReservEntry1: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
    begin
        OnBeforeCopyItemTracking3(ReservEntry, ToRowID, SwapSign, SkipReservation);

        if SkipReservation then
            ReservEntry.SetFilter("Reservation Status", '<>%1', ReservEntry."Reservation Status"::Reservation);

        // Skip lines where Qty. to Handle (Base) = 0 because they cause errors while posting 
        if ReservEntry."Source Type" = Database::"Job Planning Line" then
            ReservEntry.SetFilter("Qty. to Handle (Base)", '<> 0');

        if ReservEntry.FindSet() then begin
            repeat
                if ReservEntry.TrackingExists() then begin
                    TempReservEntry := ReservEntry;
                    TempReservEntry."Reservation Status" := TempReservEntry."Reservation Status"::Prospect;
                    TempReservEntry.SetPointer(ToRowID);
                    if SwapSign then begin
                        TempReservEntry."Quantity (Base)" := -TempReservEntry."Quantity (Base)";
                        TempReservEntry.Quantity := -TempReservEntry.Quantity;
                        TempReservEntry."Qty. to Handle (Base)" := -TempReservEntry."Qty. to Handle (Base)";
                        TempReservEntry."Qty. to Invoice (Base)" := -TempReservEntry."Qty. to Invoice (Base)";
                        TempReservEntry."Quantity Invoiced (Base)" := -TempReservEntry."Quantity Invoiced (Base)";
                        TempReservEntry.Positive := TempReservEntry."Quantity (Base)" > 0;
                        TempReservEntry.ClearApplFromToItemEntry();
                        OnCopyItemTracking3OnAfterSwapSign(TempReservEntry, ReservEntry);
                    end;
                    TempReservEntry.Insert();
                    OnCopyItemTracking3OnAfterTempReservEntryInsert(TempReservEntry, ReservEntry);
                end;
            until ReservEntry.Next() = 0;

            ModifyTempReservEntrySetIfTransfer(TempReservEntry);

            if TempReservEntry.FindSet() then begin
                ReservEntry1.Reset();
                repeat
                    ReservEntry1 := TempReservEntry;
                    ReservEntry1."Entry No." := 0;
                    OnCopyItemTracking3OnBeforeReservEntry1Insert(ReservEntry1);
                    ReservEntry1.Insert();
                until TempReservEntry.Next() = 0;
            end;
        end;
    end;

    procedure CopyHandledItemTrkgToInvLine(FromSalesLine: Record "Sales Line"; ToSalesInvLine: Record "Sales Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyHandledItemTrkgToInvLine(FromSalesLine, ToSalesInvLine, IsHandled);
        if IsHandled then
            exit;

        // Used for combined shipment/returns:
        if FromSalesLine.Type <> FromSalesLine.Type::Item then
            exit;

        case ToSalesInvLine."Document Type" of
            ToSalesInvLine."Document Type"::Invoice:
                begin
                    ItemEntryRelation.SetSourceFilter(
                      Database::"Sales Shipment Line", 0, ToSalesInvLine."Shipment No.", ToSalesInvLine."Shipment Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            ToSalesInvLine."Document Type"::"Credit Memo":
                begin
                    ItemEntryRelation.SetSourceFilter(
                      Database::"Return Receipt Line", 0, ToSalesInvLine."Return Receipt No.", ToSalesInvLine."Return Receipt Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            else
                ToSalesInvLine.FieldError("Document Type", Format(ToSalesInvLine."Document Type"));
        end;

        OnCopyHandledItemTrkgToInvLineOnBeforeInsertProspectReservEntry(ToSalesInvLine);

        InsertProspectReservEntryFromItemEntryRelationAndSourceData(
          ItemEntryRelation, ToSalesInvLine."Document Type".AsInteger(), ToSalesInvLine."Document No.", ToSalesInvLine."Line No.");

        OnAfterCopyHandledItemTrkgToInvLine(FromSalesLine, ToSalesInvLine);
    end;

    procedure CopyHandledItemTrkgToInvLine(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line")
    begin
        CopyHandledItemTrkgToPurchLine(FromPurchLine, ToPurchLine, false);
    end;

    procedure CopyHandledItemTrkgToPurchLineWithLineQty(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line")
    begin
        CopyHandledItemTrkgToPurchLine(FromPurchLine, ToPurchLine, true);
    end;

    local procedure CopyHandledItemTrkgToPurchLine(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line"; CheckLineQty: Boolean)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TrackingSpecification: Record "Tracking Specification";
        QtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyHandledItemTrkgToPurchLine(FromPurchLine, ToPurchLine, CheckLineQty, IsHandled);
        if IsHandled then
            exit;

        // Used for combined receipts/returns:
        if FromPurchLine.Type <> FromPurchLine.Type::Item then
            exit;

        case ToPurchLine."Document Type" of
            ToPurchLine."Document Type"::Invoice:
                begin
                    ItemEntryRelation.SetSourceFilter(
                      Database::"Purch. Rcpt. Line", 0, ToPurchLine."Receipt No.", ToPurchLine."Receipt Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            ToPurchLine."Document Type"::"Credit Memo":
                begin
                    ItemEntryRelation.SetSourceFilter(
                      Database::"Return Shipment Line", 0, ToPurchLine."Return Shipment No.", ToPurchLine."Return Shipment Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            else
                ToPurchLine.FieldError("Document Type", Format(ToPurchLine."Document Type"));
        end;

        OnCopyHandledItemTrkgToPurchLineOnAfterFilterItemEntryRelation(ItemEntryRelation, FromPurchLine, ToPurchLine);

        if not ItemEntryRelation.FindSet() then
            exit;

        repeat
            TrackingSpecification.Get(ItemEntryRelation."Item Entry No.");
            QtyBase := TrackingSpecification."Quantity (Base)" - TrackingSpecification."Quantity Invoiced (Base)";
            if CheckLineQty and (QtyBase > ToPurchLine.Quantity) then
                QtyBase := ToPurchLine.Quantity;
            InsertReservEntryFromTrackingSpec(
              TrackingSpecification, ToPurchLine."Document Type".AsInteger(), ToPurchLine."Document No.", ToPurchLine."Line No.", QtyBase);
        until ItemEntryRelation.Next() = 0;
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Item Tracking Mgt.', '25.0')]
    procedure CopyHandledItemTrkgToServLine(FromServLine: Record Microsoft.Service.Document."Service Line"; ToServLine: Record Microsoft.Service.Document."Service Line")
    var
        ServItemTrackingMgt: Codeunit "Serv. Item Tracking Mgt.";
    begin
        ServitemTrackingMgt.CopyHandledItemTrkgToServLine(FromServLine, ToServLine);
    end;
#endif

    procedure CollectItemEntryRelation(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; TotalQty: Decimal) Result: Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemEntryRelation: Record "Item Entry Relation";
        Quantity: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCollectItemEntryRelation(TempItemLedgEntry, SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo, TotalQty, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Quantity := 0;
        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();
        ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ItemEntryRelation.SetSourceFilter2(SourceBatchName, SourceProdOrderLine);
        if ItemEntryRelation.FindSet() then
            repeat
                ItemLedgEntry.Get(ItemEntryRelation."Item Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                TempItemLedgEntry.Insert();
                Quantity := Quantity + ItemLedgEntry.Quantity;
            until ItemEntryRelation.Next() = 0;
        exit(Quantity = TotalQty);
    end;

    procedure IsOrderNetworkEntity(Type: Integer; Subtype: Integer): Boolean
    var
        IsNetworkEntity: Boolean;
    begin
        case Type of
            Database::"Sales Line":
                exit(Subtype in [1, 5]);
            Database::"Purchase Line":
                exit(Subtype in [1, 5]);
            ProdOrderLineID():
                exit(Subtype in [2, 3]);
            ProdOrderCompID():
                exit(Subtype in [2, 3]);
            AssemblyHeaderID():
                exit(Subtype in [1]);
            AssemblyLineID():
                exit(Subtype in [1]);
            Database::"Job Planning Line":
                exit(Subtype in [2]);
            Database::"Transfer Line":
                exit(true);
            else begin
                OnIsOrderNetworkEntity(Type, Subtype, IsNetworkEntity);
                exit(IsNetworkEntity);
            end;
        end;
    end;

    procedure DeleteItemEntryRelation(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; DeleteAllDocLines: Boolean)
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, true);
        if DeleteAllDocLines then
            ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, true)
        else
            ItemEntryRelation.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ItemEntryRelation.SetSourceFilter2(SourceBatchName, SourceProdOrderLine);
        if not ItemEntryRelation.IsEmpty() then
            ItemEntryRelation.DeleteAll();
    end;

    procedure DeleteValueEntryRelation(RowID: Text[100])
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        ValueEntryRelation.SetCurrentKey("Source RowId");
        ValueEntryRelation.SetRange("Source RowId", RowID);
        if not ValueEntryRelation.IsEmpty() then
            ValueEntryRelation.DeleteAll();
    end;

    procedure FindInInventory(ItemNo: Code[20]; VariantCode: Code[20]; SerialNo: Code[50]): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Serial No.", "Item No.", Open, "Variant Code", Positive);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetRange(Positive, true);
        if SerialNo <> '' then
            ItemLedgerEntry.SetRange("Serial No.", SerialNo);

        OnFindInInventoryOnAfterItemLedgerEntrySetFilters(ItemLedgerEntry);

        exit(not ItemLedgerEntry.IsEmpty());
    end;

    procedure SplitWhseJnlLine(TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseJnlLine2: Record "Warehouse Journal Line" temporary; var TempWhseSplitTrackingSpec: Record "Tracking Specification" temporary; ToTransfer: Boolean)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        NonDistrQtyBase: Decimal;
        NonDistrCubage: Decimal;
        NonDistrWeight: Decimal;
        SplitFactor: Decimal;
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        TempWhseJnlLine2.DeleteAll();

        GetWhseItemTrkgSetup(TempWhseJnlLine."Item No.", WhseItemTrackingSetup);

        IsHandled := false;
        OnSplitWhseJnlLineOnAfterCheckWhseItemTrkgSetup(
            TempWhseJnlLine, TempWhseSplitTrackingSpec, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required",
            TempWhseJnlLine2, IsHandled);
        if not IsHandled then
            if not WhseItemTrackingSetup.TrackingRequired() then begin
                TempWhseJnlLine2 := TempWhseJnlLine;
                TempWhseJnlLine2.Insert();
                OnAfterSplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2);
                exit;
            end;

        LineNo := TempWhseJnlLine."Line No.";
        TempWhseSplitTrackingSpec.Reset();
        case TempWhseJnlLine."Source Type" of
            Database::"Item Journal Line",
            Database::"Job Journal Line":
                TempWhseSplitTrackingSpec.SetSourceFilter(
                    TempWhseJnlLine."Source Type", -1, TempWhseJnlLine."Journal Template Name", TempWhseJnlLine."Source Line No.", true);
            0:
                // Whse. journal line
                TempWhseSplitTrackingSpec.SetSourceFilter(
                    Database::"Warehouse Journal Line", -1, TempWhseJnlLine."Journal Batch Name", TempWhseJnlLine."Line No.", true);
            else
                TempWhseSplitTrackingSpec.SetSourceFilter(
                    TempWhseJnlLine."Source Type", -1, TempWhseJnlLine."Source No.", TempWhseJnlLine."Source Line No.", true);
        end;
        TempWhseSplitTrackingSpec.SetFilter("Quantity actual Handled (Base)", '<>%1', 0);
        OnSplitWhseJnlLineOnAfterSetFilters(TempWhseSplitTrackingSpec, TempWhseJnlLine);
        NonDistrQtyBase := TempWhseJnlLine."Qty. (Absolute, Base)";
        NonDistrCubage := TempWhseJnlLine.Cubage;
        NonDistrWeight := TempWhseJnlLine.Weight;
        if TempWhseSplitTrackingSpec.FindSet() then
            repeat
                LineNo += 10000;
                TempWhseJnlLine2 := TempWhseJnlLine;
                TempWhseJnlLine2."Line No." := LineNo;

                if TempWhseSplitTrackingSpec."Serial No." <> '' then begin
                    IsHandled := false;
                    OnSplitWhseJnlLineOnBeforeCheckSerialNo(TempWhseSplitTrackingSpec, IsHandled);
                    if not IsHandled then
                        if Abs(TempWhseSplitTrackingSpec."Quantity (Base)") <> 1 then
                            TempWhseSplitTrackingSpec.FieldError("Quantity (Base)");
                end;

                if ToTransfer then begin
                    WhseItemTrackingSetup.CopyTrackingFromNewTrackingSpec(TempWhseSplitTrackingSpec);
                    TempWhseJnlLine2.CopyTrackingFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
                    if TempWhseSplitTrackingSpec."New Expiration Date" <> 0D then
                        TempWhseJnlLine2."Expiration Date" := TempWhseSplitTrackingSpec."New Expiration Date";
                end else begin
                    WhseItemTrackingSetup.CopyTrackingFromTrackingSpec(TempWhseSplitTrackingSpec);
                    TempWhseJnlLine2.CopyTrackingFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
                    TempWhseJnlLine2."Expiration Date" := TempWhseSplitTrackingSpec."Expiration Date";
                end;
                OnSplitWhseJnlLineOnAfterCopyTrackingByToTransfer(TempWhseSplitTrackingSpec, TempWhseJnlLine2, ToTransfer);
                WhseItemTrackingSetup.CopyTrackingFromNewTrackingSpec(TempWhseSplitTrackingSpec);
                TempWhseJnlLine2.CopyNewTrackingFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
                TempWhseJnlLine2."New Expiration Date" := TempWhseSplitTrackingSpec."New Expiration Date";
                TempWhseJnlLine2."Warranty Date" := TempWhseSplitTrackingSpec."Warranty Date";
                TempWhseJnlLine2."Qty. (Absolute, Base)" := Abs(TempWhseSplitTrackingSpec."Quantity (Base)");
                TempWhseJnlLine2."Qty. (Absolute)" :=
                  Round(
                    TempWhseJnlLine2."Qty. (Absolute, Base)" / TempWhseJnlLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                if TempWhseJnlLine.Quantity > 0 then begin
                    TempWhseJnlLine2."Qty. (Base)" := TempWhseJnlLine2."Qty. (Absolute, Base)";
                    TempWhseJnlLine2.Quantity := TempWhseJnlLine2."Qty. (Absolute)";
                end else begin
                    TempWhseJnlLine2."Qty. (Base)" := -TempWhseJnlLine2."Qty. (Absolute, Base)";
                    TempWhseJnlLine2.Quantity := -TempWhseJnlLine2."Qty. (Absolute)";
                end;
                SplitFactor := Abs(TempWhseSplitTrackingSpec."Quantity (Base)") / NonDistrQtyBase;
                if SplitFactor < 1 then begin
                    TempWhseJnlLine2.Cubage := Round(NonDistrCubage * SplitFactor, UOMMgt.QtyRndPrecision());
                    TempWhseJnlLine2.Weight := Round(NonDistrWeight * SplitFactor, UOMMgt.QtyRndPrecision());
                    NonDistrQtyBase -= TempWhseSplitTrackingSpec."Quantity (Base)";
                    NonDistrCubage -= TempWhseJnlLine2.Cubage;
                    NonDistrWeight -= TempWhseJnlLine2.Weight;
                end else begin
                    // the last record
                    TempWhseJnlLine2.Cubage := NonDistrCubage;
                    TempWhseJnlLine2.Weight := NonDistrWeight;
                end;
                OnBeforeTempWhseJnlLine2Insert(
                    TempWhseJnlLine2, TempWhseJnlLine, TempWhseSplitTrackingSpec, ToTransfer,
                    WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required");
                TempWhseJnlLine2.Insert();
            until TempWhseSplitTrackingSpec.Next() = 0
        else begin
            TempWhseJnlLine2 := TempWhseJnlLine;
            OnBeforeTempWhseJnlLine2Insert(
              TempWhseJnlLine2, TempWhseJnlLine, TempWhseSplitTrackingSpec, ToTransfer, false, false);
            TempWhseJnlLine2.Insert();
        end;

        OnAfterSplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2);
    end;

    procedure SplitPostedWhseRcptLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary)
    var
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemLedgEntry: Record "Item Ledger Entry";
        LineNo: Integer;
        CrossDockQty: Decimal;
        CrossDockQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitPostedWhseReceiptLine(PostedWhseRcptLine, TempPostedWhseRcptLine, IsHandled);
        if IsHandled then
            exit;

        TempPostedWhseRcptLine.Reset();
        TempPostedWhseRcptLine.DeleteAll();

        if not GetWhseItemTrkgSetup(PostedWhseRcptLine."Item No.", WhseItemTrackingSetup) then begin
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            TempPostedWhseRcptLine.Insert();
            OnAfterSplitPostedWhseReceiptLine(PostedWhseRcptLine, TempPostedWhseRcptLine);
            exit;
        end;

        WhseItemEntryRelation.Reset();
        WhseItemEntryRelation.SetSourceFilter(
          Database::"Posted Whse. Receipt Line", 0, PostedWhseRcptLine."No.", PostedWhseRcptLine."Line No.", true);
        if WhseItemEntryRelation.FindSet() then
            repeat
                ItemLedgEntry.Get(WhseItemEntryRelation."Item Entry No.");
                TempPostedWhseRcptLine.SetTrackingFilterFromItemLedgEntry(ItemLedgEntry);
                TempPostedWhseRcptLine.SetRange("Warranty Date", ItemLedgEntry."Warranty Date");
                TempPostedWhseRcptLine.SetRange("Expiration Date", ItemLedgEntry."Expiration Date");
                OnTempPostedWhseRcptLineSetFilters(TempPostedWhseRcptLine, ItemLedgEntry, WhseItemEntryRelation);
                if TempPostedWhseRcptLine.FindFirst() then begin
                    TempPostedWhseRcptLine."Qty. (Base)" += ItemLedgEntry.Quantity;
                    TempPostedWhseRcptLine.Quantity :=
                      Round(
                        TempPostedWhseRcptLine."Qty. (Base)" / TempPostedWhseRcptLine."Qty. per Unit of Measure",
                        UOMMgt.QtyRndPrecision());
                    OnBeforeModifySplitPostedWhseRcptLine(
                      TempPostedWhseRcptLine, PostedWhseRcptLine, WhseItemEntryRelation, ItemLedgEntry);
                    TempPostedWhseRcptLine.Modify();

                    CrossDockQty := CrossDockQty - TempPostedWhseRcptLine."Qty. Cross-Docked";
                    CrossDockQtyBase := CrossDockQtyBase - TempPostedWhseRcptLine."Qty. Cross-Docked (Base)";
                end else begin
                    LineNo += 10000;
                    TempPostedWhseRcptLine.Reset();
                    TempPostedWhseRcptLine := PostedWhseRcptLine;
                    TempPostedWhseRcptLine."Line No." := LineNo;
                    TempPostedWhseRcptLine.CopyTrackingFromWhseItemEntryRelation(WhseItemEntryRelation);
                    TempPostedWhseRcptLine."Warranty Date" := ItemLedgEntry."Warranty Date";
                    TempPostedWhseRcptLine."Expiration Date" := ItemLedgEntry."Expiration Date";
                    TempPostedWhseRcptLine."Qty. (Base)" := ItemLedgEntry.Quantity;
                    TempPostedWhseRcptLine.Quantity :=
                      Round(
                        TempPostedWhseRcptLine."Qty. (Base)" / TempPostedWhseRcptLine."Qty. per Unit of Measure",
                        UOMMgt.QtyRndPrecision());
                    OnBeforeInsertSplitPostedWhseRcptLine(
                      TempPostedWhseRcptLine, PostedWhseRcptLine, WhseItemEntryRelation, ItemLedgEntry);
                    TempPostedWhseRcptLine.Insert();
                end;

                if WhseItemTrackingSetup."Serial No. Required" then begin
                    if CrossDockQty < PostedWhseRcptLine."Qty. Cross-Docked" then begin
                        TempPostedWhseRcptLine."Qty. Cross-Docked" := TempPostedWhseRcptLine.Quantity;
                        TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" := TempPostedWhseRcptLine."Qty. (Base)";
                    end else begin
                        TempPostedWhseRcptLine."Qty. Cross-Docked" := 0;
                        TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" := 0;
                    end;
                    CrossDockQty := CrossDockQty + TempPostedWhseRcptLine.Quantity;
                end else
                    if PostedWhseRcptLine."Qty. Cross-Docked" > 0 then begin
                        if TempPostedWhseRcptLine.Quantity <=
                           PostedWhseRcptLine."Qty. Cross-Docked" - CrossDockQty
                        then begin
                            TempPostedWhseRcptLine."Qty. Cross-Docked" := TempPostedWhseRcptLine.Quantity;
                            TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" := TempPostedWhseRcptLine."Qty. (Base)";
                        end else begin
                            TempPostedWhseRcptLine."Qty. Cross-Docked" := PostedWhseRcptLine."Qty. Cross-Docked" - CrossDockQty;
                            TempPostedWhseRcptLine."Qty. Cross-Docked (Base)" :=
                              PostedWhseRcptLine."Qty. Cross-Docked (Base)" - CrossDockQtyBase;
                        end;
                        CrossDockQty := CrossDockQty + TempPostedWhseRcptLine."Qty. Cross-Docked";
                        CrossDockQtyBase := CrossDockQtyBase + TempPostedWhseRcptLine."Qty. Cross-Docked (Base)";
                        if CrossDockQty >= PostedWhseRcptLine."Qty. Cross-Docked" then begin
                            PostedWhseRcptLine."Qty. Cross-Docked" := 0;
                            PostedWhseRcptLine."Qty. Cross-Docked (Base)" := 0;
                        end;
                    end;
                TempPostedWhseRcptLine.Modify();
            until WhseItemEntryRelation.Next() = 0
        else begin
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            TempPostedWhseRcptLine.Insert();
        end;

        OnAfterSplitPostedWhseReceiptLine(PostedWhseRcptLine, TempPostedWhseRcptLine);
    end;

    procedure SplitInternalPutAwayLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitInternalPutAwayLine(PostedWhseRcptLine, TempPostedWhseRcptLine, IsHandled);
        if IsHandled then
            exit;

        TempPostedWhseRcptLine.DeleteAll();

        if not GetWhseItemTrkgSetup(PostedWhseRcptLine."Item No.") then begin
            TempPostedWhseRcptLine := PostedWhseRcptLine;
            TempPostedWhseRcptLine.Insert();
            exit;
        end;

        WhseItemTrackingLine.Reset();
        WhseItemTrackingLine.SetSourceFilter(
          Database::"Whse. Internal Put-away Line", 0, PostedWhseRcptLine."No.", PostedWhseRcptLine."Line No.", true);
        WhseItemTrackingLine.SetSourceFilter('', 0);
        WhseItemTrackingLine.SetFilter("Qty. to Handle (Base)", '<>0');
        if WhseItemTrackingLine.FindSet() then
            repeat
                LineNo += 10000;
                TempPostedWhseRcptLine := PostedWhseRcptLine;
                TempPostedWhseRcptLine."Line No." := LineNo;
                TempPostedWhseRcptLine.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
                TempPostedWhseRcptLine."Warranty Date" := WhseItemTrackingLine."Warranty Date";
                TempPostedWhseRcptLine."Expiration Date" := WhseItemTrackingLine."Expiration Date";
                TempPostedWhseRcptLine."Qty. (Base)" := WhseItemTrackingLine."Qty. to Handle (Base)";
                TempPostedWhseRcptLine.Quantity :=
                  Round(
                    TempPostedWhseRcptLine."Qty. (Base)" / TempPostedWhseRcptLine."Qty. per Unit of Measure",
                    UOMMgt.QtyRndPrecision());
                OnBeforeInsertSplitInternalPutAwayLine(TempPostedWhseRcptLine, PostedWhseRcptLine, WhseItemTrackingLine);
                TempPostedWhseRcptLine.Insert();
            until WhseItemTrackingLine.Next() = 0
        else begin
            IsHandled := false;
            OnSplitInternalPutAwayLineOnNotFindWhseItemTrackingLine(PostedWhseRcptLine, TempPostedWhseRcptLine, IsHandled);
            if not IsHandled then begin
                TempPostedWhseRcptLine := PostedWhseRcptLine;
                TempPostedWhseRcptLine.Insert();
            end;
        end
    end;

    procedure DeleteWhseItemTrkgLines(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10]; RelatedToLine: Boolean)
    begin
        DeleteWhseItemTrkgLinesWithRunDeleteTrigger(
          SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo, LocationCode, RelatedToLine, false);
    end;

    procedure DeleteWhseItemTrkgLinesWithRunDeleteTrigger(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10]; RelatedToLine: Boolean; RunDeleteTrigger: Boolean)
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrkgLine.Reset();
        WhseItemTrkgLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, true);
        if RelatedToLine then begin
            WhseItemTrkgLine.SetSourceFilter(SourceBatchName, SourceProdOrderLine);
            WhseItemTrkgLine.SetRange("Source Ref. No.", SourceRefNo);
            WhseItemTrkgLine.SetRange("Location Code", LocationCode);
        end;

        if WhseItemTrkgLine.FindSet() then
            repeat
                // If the item tracking information was added through a pick registration, the reservation entry needs to
                // be modified/deleted as well in order to remove this item tracking information again.
                if DeleteReservationEntries and
                   WhseItemTrkgLine."Created by Whse. Activity Line" and
                   (WhseItemTrkgLine."Source Type" = Database::"Warehouse Shipment Line")
                then
                    RemoveItemTrkgFromReservEntry(WhseItemTrkgLine);
                WhseItemTrkgLine.Delete(RunDeleteTrigger);
            until WhseItemTrkgLine.Next() = 0;
    end;

    local procedure RemoveItemTrkgFromReservEntry(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        ReservEntry: Record "Reservation Entry";
        OriginalReservEntry: Record "Reservation Entry";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", WhseItemTrackingLine."Source ID");
        WarehouseShipmentLine.SetRange("Line No.", WhseItemTrackingLine."Source Ref. No.");
        if not WarehouseShipmentLine.FindFirst() then
            exit;

        ReservEntry.SetSourceFilter(
          WarehouseShipmentLine."Source Type", WarehouseShipmentLine."Source Subtype",
          WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.", true);
        ReservEntry.SetTrackingFilterFromWhseSpec(WhseItemTrackingLine);
        if ReservEntry.FindSet() then
            repeat
                OriginalReservEntry := ReservEntry;
                case ReservEntry."Reservation Status" of
                    ReservEntry."Reservation Status"::Surplus:
                        ReservEntry.Delete(true);
                    else begin
                        ReservEntry.ClearItemTrackingFields();
                        ReservEntry.Modify(true);
                    end;
                end;
                OnRemoveItemTrkgFromReservEntryOnAfterReservEntryLoop(ReservEntry, OriginalReservEntry);
            until ReservEntry.Next() = 0;
    end;

    local procedure RemoveUntrackedSurplus(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item Tracking", ReservationEntry."Item Tracking"::None);
        ReservationEntry.SetRange("Untracked Surplus", true);
        ReservationEntry.DeleteAll(true);
    end;

    procedure SetDeleteReservationEntries(DeleteEntries: Boolean)
    begin
        DeleteReservationEntries := DeleteEntries;
    end;

    procedure InitTrackingSpecification(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        WhseManagement: Codeunit "Whse. Management";
        SourceType: Integer;
        IsHandled: Boolean;
    begin
        SourceType := WhseManagement.GetSourceType(WhseWkshLine);

        case WhseWkshLine."Whse. Document Type" of
            "Warehouse Worksheet Document Type"::Receipt:
                begin
                    PostedWhseReceiptLine.SetRange("No.", WhseWkshLine."Whse. Document No.");
                    PostedWhseReceiptLine.SetRange("Line No.", WhseWkshLine."Whse. Document Line No.");
                    if PostedWhseReceiptLine.FindFirst() then
                        InsertWhseItemTrkgLines(PostedWhseReceiptLine, SourceType);
                end;
            else
                OnInitTrackingSpecificationByDocumentType(WhseWkshLine, SourceType);
        end;

        if SourceType = ProdOrderCompID() then begin
            WhseItemTrackingLine.SetSourceFilter(SourceType, WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Subline No.", true);
            WhseItemTrackingLine.SetRange("Source Prod. Order Line", WhseWkshLine."Source Line No.");
        end else
            WhseItemTrackingLine.SetSourceFilter(SourceType, -1, WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", true);

        WhseItemTrackingLine.LockTable();
        IsHandled := false;
        OnInitTrackingSpecificationOnBeforeCalcWhseItemTrackingLines(WhseWkshLine, WhseItemTrackingLine, IsHandled);
        if WhseItemTrackingLine.FindSet() and not IsHandled then begin
            repeat
                CalcWhseItemTrkgLine(WhseItemTrackingLine);
                WhseItemTrackingLine.Modify();
                if SourceType in [ProdOrderCompID(), AssemblyLineID(), Database::Job] then begin
                    TempWhseItemTrackingLine := WhseItemTrackingLine;
                    TempWhseItemTrackingLine.Insert();
                end;
            until WhseItemTrackingLine.Next() = 0;
            if not TempWhseItemTrackingLine.IsEmpty() then
                CheckWhseItemTrkg(TempWhseItemTrackingLine, WhseWkshLine);
        end else
            case SourceType of
                Database::"Posted Whse. Receipt Line":
                    CreateWhseItemTrackingForReceipt(WhseWkshLine);
                Database::"Warehouse Shipment Line":
                    CreateWhseItemTrackingBatch(WhseWkshLine);
                ProdOrderCompID():
                    CreateWhseItemTrackingBatch(WhseWkshLine);
                AssemblyLineID(),
                Database::Job:
                    CreateWhseItemTrackingBatch(WhseWkshLine);
                else
                    OnInitTrackingSpecificationOnCreateNew(WhseWkshLine, SourceType);
            end;
    end;

    local procedure CreateWhseItemTrackingForReceipt(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        WhseItemTrackingLine.Reset();
        EntryNo := WhseItemTrackingLine.GetLastEntryNo();

        WhseItemEntryRelation.SetSourceFilter(
          Database::"Posted Whse. Receipt Line", 0, WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", true);
        if WhseItemEntryRelation.FindSet() then
            repeat
                WhseItemTrackingLine.Init();
                EntryNo += 1;
                WhseItemTrackingLine."Entry No." := EntryNo;
                WhseItemTrackingLine."Item No." := WhseWkshLine."Item No.";
                WhseItemTrackingLine."Variant Code" := WhseWkshLine."Variant Code";
                WhseItemTrackingLine."Location Code" := WhseWkshLine."Location Code";
                WhseItemTrackingLine.Description := WhseWkshLine.Description;
                WhseItemTrackingLine."Qty. per Unit of Measure" := WhseWkshLine."Qty. per From Unit of Measure";
                WhseItemTrackingLine.SetSource(
                  Database::"Posted Whse. Receipt Line", 0, WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", '', 0);
                ItemLedgEntry.Get(WhseItemEntryRelation."Item Entry No.");
                WhseItemTrackingLine.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                WhseItemTrackingLine."Quantity (Base)" := ItemLedgEntry.Quantity;
                if WhseWkshLine."Qty. (Base)" = WhseWkshLine."Qty. to Handle (Base)" then
                    WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
                WhseItemTrackingLine."Qty. to Handle" :=
                  Round(
                    WhseItemTrackingLine."Qty. to Handle (Base)" / WhseItemTrackingLine."Qty. per Unit of Measure",
                    UOMMgt.QtyRndPrecision());
                OnBeforeCreateWhseItemTrkgForReceipt(WhseItemTrackingLine, WhseWkshLine, ItemLedgEntry);
                WhseItemTrackingLine.Insert();
            until WhseItemEntryRelation.Next() = 0;
    end;

    local procedure CreateWhseItemTrackingBatch(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        SourceReservEntry: Record "Reservation Entry";
        WhseManagement: Codeunit "Whse. Management";
        SourceType: Integer;
        IsHandled: Boolean;
    begin
        SourceType := WhseManagement.GetSourceType(WhseWkshLine);

        case SourceType of
            ProdOrderCompID():
                begin
                    SourceReservEntry.SetSourceFilter(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Subline No.", true);
                    SourceReservEntry.SetSourceFilter('', WhseWkshLine."Source Line No.");
                end;
            Database::Job:
                begin
                    SourceReservEntry.SetSourceFilter(Database::"Job Planning Line", 2, WhseWkshLine."Source No.", WhseWkshLine."Source Line No.", true);
                    SourceReservEntry.SetSourceFilter('', 0);
                end;
            else begin
                SourceReservEntry.SetSourceFilter(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Line No.", true);
                SourceReservEntry.SetSourceFilter('', 0);
            end;
        end;

        IsHandled := false;
        OnCreateWhseItemTrackingBatchOnBeforeCreateWhseItemTrackingLines(WhseWkshLine, SourceReservEntry, SourceType, IsHandled);
        if not IsHandled then
            if SourceReservEntry.FindSet() then
                repeat
                    CreateWhseItemTrkgForResEntry(SourceReservEntry, WhseWkshLine);
                until SourceReservEntry.Next() = 0;
    end;

    procedure CreateWhseItemTrkgForResEntry(SourceReservEntry: Record "Reservation Entry"; WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseManagement: Codeunit "Whse. Management";
        EntryNo: Integer;
        SourceType: Integer;
    begin
        if not ((SourceReservEntry."Reservation Status" <> SourceReservEntry."Reservation Status"::Reservation) or
                IsResEntryReservedAgainstInventory(SourceReservEntry))
        then
            exit;

        if not SourceReservEntry.TrackingExists() then
            exit;

        SourceType := WhseManagement.GetSourceType(WhseWkshLine);

        EntryNo := WhseItemTrackingLine.GetLastEntryNo();

        WhseItemTrackingLine.Init();

        case SourceType of
            Database::"Posted Whse. Receipt Line":
                WhseItemTrackingLine.SetSource(
                  Database::"Posted Whse. Receipt Line", 0, WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", '', 0);
            Database::"Warehouse Shipment Line":
                WhseItemTrackingLine.SetSource(
                  Database::"Warehouse Shipment Line", 0, WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", '', 0);
            AssemblyLineID():
                WhseItemTrackingLine.SetSource(
                  AssemblyLineID(), WhseWkshLine."Source Subtype", WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", '', 0);
            ProdOrderCompID():
                WhseItemTrackingLine.SetSource(
                  WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Subline No.", '', WhseWkshLine."Source Line No.");
            Database::Job, Database::"Job Planning Line":
                WhseItemTrackingLine.SetSource(
                  Database::"Job Planning Line", 2, WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", '', 0);
        end;

        WhseItemTrackingLine."Entry No." := EntryNo + 1;
        WhseItemTrackingLine."Item No." := SourceReservEntry."Item No.";
        WhseItemTrackingLine."Variant Code" := SourceReservEntry."Variant Code";
        WhseItemTrackingLine."Location Code" := SourceReservEntry."Location Code";
        WhseItemTrackingLine.Description := SourceReservEntry.Description;
        WhseItemTrackingLine."Qty. per Unit of Measure" := SourceReservEntry."Qty. per Unit of Measure";
        WhseItemTrackingLine.CopyTrackingFromReservEntry(SourceReservEntry);
        WhseItemTrackingLine."Quantity (Base)" := -SourceReservEntry."Quantity (Base)";

        if Abs(WhseWkshLine."Qty. Handled (Base)") > Abs(WhseItemTrackingLine."Quantity (Base)") then
            WhseWkshLine."Qty. Handled (Base)" := WhseItemTrackingLine."Quantity (Base)";

        if WhseWkshLine."Qty. Handled (Base)" <> 0 then begin
            WhseItemTrackingLine."Quantity Handled (Base)" := WhseWkshLine."Qty. Handled (Base)";
            WhseItemTrackingLine."Qty. Registered (Base)" := WhseWkshLine."Qty. Handled (Base)";
        end else
            if WhseWkshLine."Qty. (Base)" = WhseWkshLine."Qty. to Handle (Base)" then begin
                WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
                WhseItemTrackingLine."Qty. to Handle" := -SourceReservEntry.Quantity;
            end;
        OnBeforeCreateWhseItemTrkgForResEntry(WhseItemTrackingLine, SourceReservEntry, WhseWkshLine);
        WhseItemTrackingLine.Insert();
    end;

    procedure CalcWhseItemTrkgLine(var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SourceReservEntry: Record "Reservation Entry";
        WhseActivQtyBase: Decimal;
    begin
        case WhseItemTrkgLine."Source Type" of
            Database::"Posted Whse. Receipt Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Receipt;
            Database::"Whse. Internal Put-away Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::"Internal Put-away";
            Database::"Warehouse Shipment Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Shipment;
            Database::"Whse. Internal Pick Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::"Internal Pick";
            AssemblyLineID():
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Assembly;
            Database::Job:
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::Job;
            Database::"Whse. Worksheet Line":
                WhseItemTrkgLine."Source Type Filter" := WhseItemTrkgLine."Source Type Filter"::"Movement Worksheet";
            else
                OnCalcWhseItemTrkgLineOnSetSourceTypeFilter(WhseItemTrkgLine);
        end;
        WhseItemTrkgLine.CalcFields("Put-away Qty. (Base)", "Pick Qty. (Base)");
        OnCalcWhseItemTrkgLineOnAfterCalcBaseQuantities(WhseItemTrkgLine);

        if WhseItemTrkgLine."Source Type" <> ProdOrderCompID() then begin
            if WhseItemTrkgLine."Put-away Qty. (Base)" > 0 then
                WhseActivQtyBase := WhseItemTrkgLine."Put-away Qty. (Base)";
            if WhseItemTrkgLine."Pick Qty. (Base)" > 0 then
                WhseActivQtyBase := WhseItemTrkgLine."Pick Qty. (Base)";
        end else begin
            WhseActivQtyBase := GetPutAwayQtyOrPickQtyBaseForProdOrder(WhseItemTrkgLine, "Warehouse Action Type"::Place);
            if WhseActivQtyBase <= 0 then
                WhseActivQtyBase := GetPutAwayQtyOrPickQtyBaseForProdOrder(WhseItemTrkgLine, "Warehouse Action Type"::Take);
            if WhseActivQtyBase < 0 then
                WhseActivQtyBase := 0;
        end;

        if not Registering then
            WhseItemTrkgLine.Validate("Quantity Handled (Base)",
              WhseActivQtyBase + WhseItemTrkgLine."Qty. Registered (Base)")
        else
            WhseItemTrkgLine.Validate("Quantity Handled (Base)",
              WhseItemTrkgLine."Qty. Registered (Base)");

        GetItemTrackingCode(WhseItemTrkgLine."Item No.", ItemTrackingCode);

        if (ItemTrackingCode."Lot Specific Tracking") or (ItemTrackingCode."Package Specific Tracking") then begin
            SourceReservEntry.SetSourceFilter(WhseItemTrkgLine."Source Type", WhseItemTrkgLine."Source Subtype", WhseItemTrkgLine."Source ID", WhseItemTrkgLine."Source Ref. No.", true);
            SourceReservEntry.SetSourceFilter('', WhseItemTrkgLine."Source Prod. Order Line");
            if ItemTrackingCode."Lot Specific Tracking" then
                SourceReservEntry.SetRange("Lot No.", WhseItemTrkgLine."Lot No.");
            if ItemTrackingCode."Package Specific Tracking" then
                SourceReservEntry.SetRange("Package No.", WhseItemTrkgLine."Package No.");
            if SourceReservEntry.FindFirst() then
                if Abs(SourceReservEntry."Quantity (Base)") > WhseItemTrkgLine."Quantity Handled (Base)" then
                    WhseItemTrkgLine.Validate("Quantity (Base)", Abs(SourceReservEntry."Quantity (Base)"));
        end;

        if WhseItemTrkgLine."Quantity (Base)" >= WhseItemTrkgLine."Quantity Handled (Base)" then
            WhseItemTrkgLine.Validate("Qty. to Handle (Base)",
              WhseItemTrkgLine."Quantity (Base)" - WhseItemTrkgLine."Quantity Handled (Base)");
    end;

    procedure InitItemTrackingForTempWhseWorksheetLine(WhseDocType: Enum "Warehouse Worksheet Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitItemTrackingForTempWhseWorksheetLine(WhseDocNo, WhseDocLineNo, IsHandled);
        if IsHandled then
            exit;

        InitWhseWorksheetLine(
            WhseWkshLine, WhseDocType, WhseDocNo, WhseDocLineNo,
            SourceType, SourceSubtype, SourceNo, SourceLineNo, SourceSublineNo);
        InitTrackingSpecification(WhseWkshLine);
    end;

    procedure InitWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseDocType: Enum "Warehouse Worksheet Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    begin
        WhseWorksheetLine.Init();
        WhseWorksheetLine."Whse. Document Type" := WhseDocType;
        WhseWorksheetLine."Whse. Document No." := WhseDocNo;
        WhseWorksheetLine."Whse. Document Line No." := WhseDocLineNo;
        WhseWorksheetLine."Source Type" := SourceType;
        WhseWorksheetLine."Source Subtype" := SourceSubtype;
        WhseWorksheetLine."Source No." := SourceNo;
        WhseWorksheetLine."Source Line No." := SourceLineNo;
        WhseWorksheetLine."Source Subline No." := SourceSublineNo;

        OnAfterInitWhseWorksheetLine(WhseWorksheetLine, WhseDocType, SourceSubtype, SourceNo, SourceLineNo, SourceSublineNo);
    end;

    procedure UpdateWhseItemTrkgLines(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        if TempWhseItemTrackingLine.FindSet() then
            repeat
                WhseItemTrackingLine.SetTrackingKey();
                WhseItemTrackingLine.SetTrackingFilterFromSpec(TempWhseItemTrackingLine);
                WhseItemTrackingLine.SetSourceFilter(
                  TempWhseItemTrackingLine."Source Type", TempWhseItemTrackingLine."Source Subtype", TempWhseItemTrackingLine."Source ID",
                  TempWhseItemTrackingLine."Source Ref. No.", false);
                WhseItemTrackingLine.SetSourceFilter(
                  TempWhseItemTrackingLine."Source Batch Name", TempWhseItemTrackingLine."Source Prod. Order Line");
                WhseItemTrackingLine.LockTable();
                if WhseItemTrackingLine.FindFirst() then begin
                    CalcWhseItemTrkgLine(WhseItemTrackingLine);
                    WhseItemTrackingLine.Modify();
                end;
            until TempWhseItemTrackingLine.Next() = 0
    end;

    local procedure InsertWhseItemTrkgLines(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer)
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
        ItemLedgEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
        QtyHandledBase: Decimal;
        RemQtyHandledBase: Decimal;
    begin
        EntryNo := WhseItemTrkgLine.GetLastEntryNo() + 1;
        QtyHandledBase := 0;

        WhseItemEntryRelation.Reset();
        WhseItemEntryRelation.SetSourceFilter(SourceType, 0, PostedWhseReceiptLine."No.", PostedWhseReceiptLine."Line No.", true);
        if WhseItemEntryRelation.FindSet() then begin
            WhseItemTrkgLine.SetSourceFilter(SourceType, 0, PostedWhseReceiptLine."No.", PostedWhseReceiptLine."Line No.", false);
            WhseItemTrkgLine.DeleteAll();
            WhseItemTrkgLine.Init();
            WhseItemTrkgLine.SetTrackingKey();
            repeat
                OnBeforeInsertWhseItemTrkgLinesLoop(PostedWhseReceiptLine, WhseItemEntryRelation, WhseItemTrkgLine);
                WhseItemTrkgLine.SetTrackingFilterFromRelation(WhseItemEntryRelation);
                ItemLedgEntry.Get(WhseItemEntryRelation."Item Entry No.");
                if not WhseItemTrkgLine.HasSameTrackingWithItemEntryRelation(WhseItemEntryRelation) then
                    RemQtyHandledBase := RegisteredPutAwayQtyBase(PostedWhseReceiptLine, WhseItemEntryRelation)
                else
                    RemQtyHandledBase -= QtyHandledBase;
                QtyHandledBase := RemQtyHandledBase;
                if QtyHandledBase > ItemLedgEntry.Quantity then
                    QtyHandledBase := ItemLedgEntry.Quantity;

                if not WhseItemTrkgLine.FindFirst() then begin
                    WhseItemTrkgLine.Init();
                    WhseItemTrkgLine."Entry No." := EntryNo;
                    EntryNo := EntryNo + 1;

                    WhseItemTrkgLine."Item No." := ItemLedgEntry."Item No.";
                    WhseItemTrkgLine."Location Code" := ItemLedgEntry."Location Code";
                    WhseItemTrkgLine.Description := ItemLedgEntry.Description;
                    WhseItemTrkgLine.SetSource(
                      WhseItemEntryRelation."Source Type", WhseItemEntryRelation."Source Subtype", WhseItemEntryRelation."Source ID",
                      WhseItemEntryRelation."Source Ref. No.", WhseItemEntryRelation."Source Batch Name",
                      WhseItemEntryRelation."Source Prod. Order Line");
                    WhseItemTrkgLine.CopyTrackingFromRelation(WhseItemEntryRelation);
                    WhseItemTrkgLine."Warranty Date" := ItemLedgEntry."Warranty Date";
                    WhseItemTrkgLine."Expiration Date" := ItemLedgEntry."Expiration Date";
                    WhseItemTrkgLine."Qty. per Unit of Measure" := ItemLedgEntry."Qty. per Unit of Measure";
                    WhseItemTrkgLine."Quantity Handled (Base)" := QtyHandledBase;
                    WhseItemTrkgLine."Qty. Registered (Base)" := QtyHandledBase;
                    WhseItemTrkgLine.Validate("Quantity (Base)", ItemLedgEntry.Quantity);
                    OnBeforeInsertWhseItemTrkgLines(WhseItemTrkgLine, PostedWhseReceiptLine, WhseItemEntryRelation, ItemLedgEntry);
                    WhseItemTrkgLine.Insert();
                end else begin
                    WhseItemTrkgLine."Quantity Handled (Base)" += QtyHandledBase;
                    WhseItemTrkgLine."Qty. Registered (Base)" += QtyHandledBase;
                    WhseItemTrkgLine.Validate("Quantity (Base)", WhseItemTrkgLine."Quantity (Base)" + ItemLedgEntry.Quantity);
                    OnBeforeModifyWhseItemTrkgLines(WhseItemTrkgLine, PostedWhseReceiptLine, WhseItemEntryRelation, ItemLedgEntry);
                    WhseItemTrkgLine.Modify();
                end;
                OnAfterInsertWhseItemTrkgLinesLoop(PostedWhseReceiptLine, WhseItemEntryRelation, WhseItemTrkgLine);
            until WhseItemEntryRelation.Next() = 0;
        end;
    end;

    local procedure RegisteredPutAwayQtyBase(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"): Decimal
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.Reset();
        RegisteredWhseActivityLine.SetSourceFilter(PostedWhseReceiptLine."Source Type", PostedWhseReceiptLine."Source Subtype", PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.", -1, true);
        RegisteredWhseActivityLine.SetTrackingFilterFromRelation(WhseItemEntryRelation);
        RegisteredWhseActivityLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Take);
        RegisteredWhseActivityLine.CalcSums("Qty. (Base)");

        exit(RegisteredWhseActivityLine."Qty. (Base)");
    end;

    procedure ItemTrkgIsManagedByWhse(Type: Integer; Subtype: Integer; ID: Code[20]; ProdOrderLine: Integer; RefNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]) Result: Boolean
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemTrkgIsManagedByWhse(Type, Subtype, ID, ProdOrderLine, RefNo, LocationCode, ItemNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ItemTrkgTypeIsManagedByWhse(Type) then
            exit(false);

        if not (Location.RequirePicking(LocationCode) or Location.RequirePutaway(LocationCode)) then
            exit(false);

        if not GetWhseItemTrkgSetup(ItemNo) then
            exit(false);

        if Location.RequireShipment(LocationCode) then begin
            WhseShipmentLine.SetSourceFilter(Type, Subtype, ID, RefNo, true);
            if not WhseShipmentLine.IsEmpty() then
                if Location.RequirePicking(LocationCode) then
                    exit(true);
        end;

        if Type in [ProdOrderCompID(), ProdOrderLineID()] then begin
            WhseWkshLine.SetSourceFilter(Type, Subtype, ID, ProdOrderLine, true);
            WhseWkshLine.SetRange("Source Subline No.", RefNo);
        end else
            WhseWkshLine.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        if WhseWkshLine.FindFirst() then
            if WhseWkshTemplate.Get(WhseWkshLine."Worksheet Template Name") then
                if WhseWkshTemplate.Type = WhseWkshTemplate.Type::Pick then
                    exit(true);

        if Type in [ProdOrderCompID(), ProdOrderLineID()] then
            WhseActivLine.SetSourceFilter(Type, Subtype, ID, ProdOrderLine, RefNo, true)
        else
            WhseActivLine.SetSourceFilter(Type, Subtype, ID, RefNo, 0, true);
        if WhseActivLine.FindFirst() then
            if WhseActivLine."Activity Type" in [WhseActivLine."Activity Type"::Pick,
                                                 WhseActivLine."Activity Type"::"Invt. Put-away",
                                                 WhseActivLine."Activity Type"::"Invt. Pick"]
            then
                exit(true);

        exit(false);
    end;

    local procedure ItemTrkgTypeIsManagedByWhse(Type: Integer) TypeIsManagedByWhse: Boolean
    begin
        TypeIsManagedByWhse := Type in [Database::"Sales Line",
                         Database::"Purchase Line",
                         Database::"Transfer Line",
                         AssemblyHeaderID(),
                         AssemblyLineID(),
                         ProdOrderLineID(),
                         ProdOrderCompID(),
                         Database::Job];

        OnAfterItemTrkgTypeIsManagedByWhse(Type, TypeIsManagedByWhse);
    end;

    procedure GetWhseItemTrkgSetup(ItemNo: Code[20]): Boolean;
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        exit(WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure GetWhseItemTrkgSetup(ItemNo: Code[20]; var WhseItemTrackingSetup: Record "Item Tracking Setup") Result: Boolean;
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Clear(WhseItemTrackingSetup);
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
        if Item."Item Tracking Code" <> '' then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            WhseItemTrackingSetup.Code := ItemTrackingCode.Code;
            WhseItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(ItemTrackingCode);
            OnAfterGetWhseItemTrkgSetupOnAfterItemTrackingCodeGet(ItemTrackingCode, WhseItemTrackingSetup);
        end;
        exit(WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure CheckWhseItemTrkgSetup(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if not GetWhseItemTrkgSetup(ItemNo) then
            Error(Text005, Item.FieldCaption("No."), ItemNo);
    end;

    procedure SetGlobalParameters(SourceSpecification2: Record "Tracking Specification" temporary; var TempTrackingSpecification2: Record "Tracking Specification" temporary; DueDate2: Date)
    begin
        TempSourceTrackingSpecification := SourceSpecification2;
        DueDate := DueDate2;
        if TempTrackingSpecification2.FindSet() then
            repeat
                TempTrackingSpecification := TempTrackingSpecification2;
                TempTrackingSpecification.Insert();
            until TempTrackingSpecification2.Next() = 0;
    end;

    procedure AdjustQuantityRounding(NonDistrQuantity: Decimal; var QtyToBeHandled: Decimal; NonDistrQuantityBase: Decimal; QtyToBeHandledBase: Decimal)
    var
        FloatingFactor: Decimal;
    begin
        // Used by CU80/90 for handling rounding differences during invoicing

        FloatingFactor := QtyToBeHandledBase / NonDistrQuantityBase;

        if FloatingFactor < 1 then
            QtyToBeHandled := Round(FloatingFactor * NonDistrQuantity, UOMMgt.QtyRndPrecision())
        else
            QtyToBeHandled := NonDistrQuantity;
    end;

    procedure SynchronizeItemTrackingByPtrs(FromReservEntry: Record "Reservation Entry"; ToReservEntry: Record "Reservation Entry")
    var
        FromRowID: Text[250];
        ToRowID: Text[250];
    begin
        FromRowID := ComposeRowID(
            FromReservEntry."Source Type", FromReservEntry."Source Subtype", FromReservEntry."Source ID",
            FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line", FromReservEntry."Source Ref. No.");
        ToRowID := ComposeRowID(
            ToReservEntry."Source Type", ToReservEntry."Source Subtype", ToReservEntry."Source ID",
            ToReservEntry."Source Batch Name", ToReservEntry."Source Prod. Order Line", ToReservEntry."Source Ref. No.");
        SynchronizeItemTracking(FromRowID, ToRowID, '');
    end;

    procedure SynchronizeItemTracking(FromRowID: Text[250]; ToRowID: Text[250]; DialogText: Text[250])
    var
        ReservEntry1: Record "Reservation Entry";
    begin
        // Used for syncronizing between orders linked via Drop Shipment
        ReservEntry1.SetPointer(FromRowID);
        ReservEntry1.SetPointerFilter();
        SynchronizeItemTracking2(ReservEntry1, ToRowID, DialogText);

        OnAfterSynchronizeItemTracking(ReservEntry1, ToRowID);
    end;

    procedure SynchronizeItemTracking2(var FromReservEntry: Record "Reservation Entry"; ToRowID: Text[250]; DialogText: Text[250])
    var
        ReservEntry2: Record "Reservation Entry";
        TempTrkgSpec1: Record "Tracking Specification" temporary;
        TempTrkgSpec2: Record "Tracking Specification" temporary;
        TempTrkgSpec3: Record "Tracking Specification" temporary;
        TempSourceSpec: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingLines: Page "Item Tracking Lines";
        AvailabilityDate: Date;
        LastEntryNo: Integer;
        SignFactor1: Integer;
        SignFactor2: Integer;
        SecondSourceRowID: Text[250];
        ShouldInsertTrkgSpec: Boolean;
    begin
        // Used for synchronizing between orders linked via Drop Shipment and for
        // synchronizing between invt. pick/put-away and parent line.
        ReservEntry2.SetPointer(ToRowID);
        SignFactor1 := CreateReservEntry.SignFactor(FromReservEntry);
        SignFactor2 := CreateReservEntry.SignFactor(ReservEntry2);
        ReservEntry2.SetPointerFilter();

        if ReservEntry2.IsEmpty() then begin
            if FromReservEntry.IsEmpty() then
                exit;
            if DialogText <> '' then
                if not ConfirmManagement.GetResponseOrDefault(DialogText, true) then begin
                    Message(Text006);
                    exit;
                end;
            CopyItemTracking3(FromReservEntry, ToRowID, SignFactor1 <> SignFactor2, false);

            // Copy to inbound part of transfer.
            if IsReservedFromTransferShipment(FromReservEntry) then begin
                SecondSourceRowID :=
                  ItemTrackingMgt.ComposeRowID(FromReservEntry."Source Type",
                    1, FromReservEntry."Source ID",
                    FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line",
                    FromReservEntry."Source Ref. No.");
                if ToRowID <> SecondSourceRowID then // Avoid copying to the line itself
                    CopyItemTracking(ToRowID, SecondSourceRowID, true);
            end;
        end else begin
            if IsReservedFromTransferShipment(FromReservEntry) then
                SynchronizeItemTrkgTransfer(ReservEntry2);    // synchronize transfer

            if SumUpItemTracking(ReservEntry2, TempTrkgSpec2, false, true) then
                TempSourceSpec := TempTrkgSpec2 // TempSourceSpec is used for conveying source information to Form6510.
            else
                TempSourceSpec.TransferFields(ReservEntry2);

            if ReservEntry2."Quantity (Base)" > 0 then
                AvailabilityDate := ReservEntry2."Expected Receipt Date"
            else
                AvailabilityDate := ReservEntry2."Shipment Date";

            SumUpItemTracking(FromReservEntry, TempTrkgSpec1, false, true);

            TempTrkgSpec1.Reset();
            TempTrkgSpec2.Reset();
            TempTrkgSpec1.SetTrackingKey();
            TempTrkgSpec2.SetTrackingKey();
            if TempTrkgSpec1.FindSet() then
                repeat
                    TempTrkgSpec2.SetTrackingFilterFromSpec(TempTrkgSpec1);
                    if TempTrkgSpec2.FindFirst() then begin
                        ShouldInsertTrkgSpec := TempTrkgSpec2."Quantity (Base)" * SignFactor2 <> TempTrkgSpec1."Quantity (Base)" * SignFactor1;
                        OnSynchronizeItemTracking2OnAfterCalcShouldInsertTrkgSpec(TempTrkgSpec1, TempTrkgSpec2, TempTrkgSpec3, SignFactor1, SignFactor2, ShouldInsertTrkgSpec);
                        if ShouldInsertTrkgSpec then begin
                            TempTrkgSpec3 := TempTrkgSpec2;
                            OnSynchronizeItemTracking2OnAfterSyncBothTrackingSpec(TempTrkgSpec3, TempTrkgSpec2, TempSourceSpec, TempTrkgSpec1);
                            TempTrkgSpec3.Validate("Quantity (Base)",
                              (TempTrkgSpec1."Quantity (Base)" * SignFactor1 - TempTrkgSpec2."Quantity (Base)" * SignFactor2));
                            TempTrkgSpec3."Entry No." := LastEntryNo + 1;
                            TempTrkgSpec3.Insert();
                        end;
                        OnSynchronizeItemTracking2OnBeforeDeleteSyncedTrackingSpec(
                            TempTrkgSpec3, TempTrkgSpec1, TempTrkgSpec2, SignFactor1, SignFactor2, LastEntryNo);
                        TempTrkgSpec2.Delete();
                    end else begin
                        TempTrkgSpec3 := TempTrkgSpec1;
                        OnSynchronizeItemTracking2OnAfterAssignNewTrackingSpec(TempTrkgSpec3, TempTrkgSpec1, TempSourceSpec);
                        TempTrkgSpec3.Validate("Quantity (Base)", TempTrkgSpec1."Quantity (Base)" * SignFactor1);
                        TempTrkgSpec3."Entry No." := LastEntryNo + 1;
                        TempTrkgSpec3.Insert();
                    end;
                    LastEntryNo := TempTrkgSpec3."Entry No.";
                    TempTrkgSpec1.Delete();
                until TempTrkgSpec1.Next() = 0;

            TempTrkgSpec2.Reset();

            if TempTrkgSpec2.FindSet() then
                repeat
                    TempTrkgSpec3 := TempTrkgSpec2;
                    TempTrkgSpec3.Validate("Quantity (Base)", -TempTrkgSpec2."Quantity (Base)" * SignFactor2);
                    TempTrkgSpec3."Entry No." := LastEntryNo + 1;
                    TempTrkgSpec3.Insert();
                    LastEntryNo := TempTrkgSpec3."Entry No.";
                until TempTrkgSpec2.Next() = 0;

            TempTrkgSpec3.Reset();

            if not TempTrkgSpec3.IsEmpty() then begin
                if DialogText <> '' then
                    if not ConfirmManagement.GetResponseOrDefault(DialogText, true) then begin
                        Message(Text006);
                        exit;
                    end;
                TempSourceSpec."Quantity (Base)" := ReservMgt.GetSourceRecordValue(ReservEntry2, false, 1);
                if TempTrkgSpec3."Source Type" = Database::"Transfer Line" then begin
                    TempTrkgSpec3.ModifyAll("Location Code", ReservEntry2."Location Code");
                    ItemTrackingLines.SetRunMode("Item Tracking Run Mode"::Transfer);
                end else
                    if FromReservEntry."Source Type" <> ReservEntry2."Source Type" then begin // If different it is drop shipment
                        RemoveUntrackedSurplus(FromReservEntry);
                        RemoveUntrackedSurplus(ReservEntry2);
                        ItemTrackingLines.SetRunMode("Item Tracking Run Mode"::"Drop Shipment");
                    end;
                OnSynchronizeItemTracking2OnBeforeRegisterItemTrackingLines(ItemTrackingLines, TempSourceSpec, TempTrkgSpec3, FromReservEntry, ReservEntry2);
                ItemTrackingLines.RegisterItemTrackingLines(TempSourceSpec, AvailabilityDate, TempTrkgSpec3);
            end;
        end;

        OnAfterSynchronizeItemTracking2(FromReservEntry, ReservEntry2);
    end;

    procedure SetRegistering(Registering2: Boolean)
    begin
        Registering := Registering2;
    end;

    local procedure ModifyTempReservEntrySetIfTransfer(var TempReservEntry: Record "Reservation Entry" temporary)
    var
        TransLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyTempReservEntrySetIfTransfer(TempReservEntry, IsHandled);
        if IsHandled then
            exit;

        if TempReservEntry."Source Type" = Database::"Transfer Line" then begin
            TransLine.Get(TempReservEntry."Source ID", TempReservEntry."Source Ref. No.");
            TempReservEntry.ModifyAll("Reservation Status", TempReservEntry."Reservation Status"::Surplus);
            if TempReservEntry."Source Subtype" = 0 then begin
                TempReservEntry.ModifyAll("Location Code", TransLine."Transfer-from Code");
                TempReservEntry.ModifyAll("Expected Receipt Date", 0D);
                TempReservEntry.ModifyAll("Shipment Date", TransLine."Shipment Date");
            end else begin
                TempReservEntry.ModifyAll("Location Code", TransLine."Transfer-to Code");
                TempReservEntry.ModifyAll("Expected Receipt Date", TransLine."Receipt Date");
                TempReservEntry.ModifyAll("Shipment Date", 0D);
            end;
        end;
    end;

    procedure SynchronizeWhseItemTracking(var TempTrackingSpecification: Record "Tracking Specification" temporary; RegPickNo: Code[20]; Deletion: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        RegisteredWhseActLine: Record "Registered Whse. Activity Line";
        Qty: Decimal;
        ZeroQtyToHandle: Boolean;
    begin
        OnBeforeSynchronizeWhseItemTracking(TempTrackingSpecification, RegPickNo, Deletion);

        if TempTrackingSpecification.FindSet() then
            repeat
                if TempTrackingSpecification.Correction then begin
                    if IsPick then begin
                        ZeroQtyToHandle := false;
                        Qty := -TempTrackingSpecification."Qty. to Handle (Base)";
                        if RegPickNo <> '' then begin
                            RegisteredWhseActLine.SetRange("Activity Type", RegisteredWhseActLine."Activity Type"::Pick);
                            if TempTrackingSpecification."Source Type" = ProdOrderCompID() then
                                RegisteredWhseActLine.SetSourceFilter(
                                    TempTrackingSpecification."Source Type", TempTrackingSpecification."Source Subtype",
                                    TempTrackingSpecification."Source ID", TempTrackingSpecification."Source Prod. Order Line", TempTrackingSpecification."Source Ref. No.", true)
                            else
                                RegisteredWhseActLine.SetSourceFilter(
                                    TempTrackingSpecification."Source Type", TempTrackingSpecification."Source Subtype",
                                    TempTrackingSpecification."Source ID", TempTrackingSpecification."Source Ref. No.", -1, true);
                            RegisteredWhseActLine.SetTrackingFilterFromSpec(TempTrackingSpecification);
                            RegisteredWhseActLine.SetFilter("No.", '<> %1', RegPickNo);
                            if not RegisteredWhseActLine.FindFirst() then
                                ZeroQtyToHandle := true
                            else
                                if RegisteredWhseActLine."Whse. Document Type" = RegisteredWhseActLine."Whse. Document Type"::Shipment then begin
                                    ZeroQtyToHandle := true;
                                    Qty :=
                                        -(TempTrackingSpecification."Qty. to Handle (Base)" +
                                            CalcQtyBaseRegistered(RegisteredWhseActLine) -
                                            CalcQtyBaseShipped(RegisteredWhseActLine));
                                end;
                        end;

                        ReservEntry.SetSourceFilter(
                          TempTrackingSpecification."Source Type", TempTrackingSpecification."Source Subtype",
                          TempTrackingSpecification."Source ID", TempTrackingSpecification."Source Ref. No.", true);
                        ReservEntry.SetSourceFilter('', TempTrackingSpecification."Source Prod. Order Line");
                        ReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                        if ReservEntry.FindSet(true) then
                            repeat
                                if ZeroQtyToHandle then begin
                                    ReservEntry."Qty. to Handle (Base)" := 0;
                                    ReservEntry."Qty. to Invoice (Base)" := 0;
                                    ReservEntry.Modify();
                                    OnSynchronizeWhseItemTrackingOnAfterZeroQtyToHandleLoop(TempTrackingSpecification);
                                end;
                            until ReservEntry.Next() = 0;

                        if ReservEntry.FindSet(true) then
                            repeat
                                if RegPickNo <> '' then begin
                                    ReservEntry."Qty. to Handle (Base)" += Qty;
                                    ReservEntry."Qty. to Invoice (Base)" += Qty;
                                end else
                                    if not Deletion then begin
                                        ReservEntry."Qty. to Handle (Base)" := Qty;
                                        ReservEntry."Qty. to Invoice (Base)" := Qty;
                                    end;
                                if Abs(ReservEntry."Qty. to Handle (Base)") > Abs(ReservEntry."Quantity (Base)") then begin
                                    Qty := ReservEntry."Qty. to Handle (Base)" - ReservEntry."Quantity (Base)";
                                    ReservEntry."Qty. to Handle (Base)" := ReservEntry."Quantity (Base)";
                                    ReservEntry."Qty. to Invoice (Base)" := ReservEntry."Quantity (Base)";
                                end else
                                    Qty := 0;
                                OnSynchronizeWhseItemTrackingOnbeforeReservEntryModify(ReservEntry, TempTrackingSpecification, RegPickNo, Deletion);
                                ReservEntry.Modify();

                                if IsReservedFromTransferShipment(ReservEntry) then
                                    UpdateItemTrackingInTransferReceipt(ReservEntry);
                            until (ReservEntry.Next() = 0) or (Qty = 0);
                        OnSynchronizeWhseItemTrackingOnAfterUpdateReservEntryForPick(TempTrackingSpecification);
                    end;
                    TempTrackingSpecification.Delete();
                end;
                OnSynchronizeWhseItemTrackingOnAfterTempTrackingSpecificationLoop(TempTrackingSpecification, RegPickNo, Deletion);
            until TempTrackingSpecification.Next() = 0;

        RegisterNewItemTrackingLines(TempTrackingSpecification, true);
    end;

    local procedure CheckWhseItemTrkg(var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line"; WhseWkshLine: Record "Whse. Worksheet Line")
    var
        SourceReservEntry: Record "Reservation Entry";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
        Checked: Boolean;
    begin
        OnBeforeCheckWhseItemTrkg(TempWhseItemTrkgLine, WhseWkshLine, Checked);
        if Checked then
            exit;

        EntryNo := WhseItemTrackingLine.GetLastEntryNo();

        if WhseWkshLine."Source Type" = ProdOrderCompID() then begin
            SourceReservEntry.SetSourceFilter(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Subline No.", true);
            SourceReservEntry.SetSourceFilter('', WhseWkshLine."Source Line No.");
        end else begin
            SourceReservEntry.SetSourceFilter(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Line No.", true);
            SourceReservEntry.SetSourceFilter('', 0);
        end;
        if SourceReservEntry.FindSet() then
            repeat
                if SourceReservEntry.TrackingExists() then begin
                    if WhseWkshLine."Source Type" = ProdOrderCompID() then begin
                        TempWhseItemTrkgLine.SetSourceFilter(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Subline No.", true);
                        TempWhseItemTrkgLine.SetRange("Source Prod. Order Line", WhseWkshLine."Source Line No.");
                    end else begin
                        TempWhseItemTrkgLine.SetSourceFilter(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Line No.", true);
                        TempWhseItemTrkgLine.SetRange("Source Prod. Order Line", 0);
                    end;
                    TempWhseItemTrkgLine.SetTrackingFilterFromReservEntry(SourceReservEntry);

                    if TempWhseItemTrkgLine.FindFirst() then
                        TempWhseItemTrkgLine.Delete()
                    else begin
                        WhseItemTrackingLine.Init();
                        EntryNo += 1;
                        WhseItemTrackingLine."Entry No." := EntryNo;
                        WhseItemTrackingLine."Item No." := SourceReservEntry."Item No.";
                        WhseItemTrackingLine."Variant Code" := SourceReservEntry."Variant Code";
                        WhseItemTrackingLine."Location Code" := SourceReservEntry."Location Code";
                        WhseItemTrackingLine.Description := SourceReservEntry.Description;
                        WhseItemTrackingLine."Qty. per Unit of Measure" := SourceReservEntry."Qty. per Unit of Measure";
                        if WhseWkshLine."Source Type" = ProdOrderCompID() then
                            WhseItemTrackingLine.SetSource(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Subline No.", '', WhseWkshLine."Source Line No.")
                        else
                            WhseItemTrackingLine.SetSource(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.", WhseWkshLine."Source Line No.", '', 0);
                        WhseItemTrackingLine.CopyTrackingFromReservEntry(SourceReservEntry);
                        WhseItemTrackingLine."Quantity (Base)" := -SourceReservEntry."Quantity (Base)";
                        if WhseWkshLine."Qty. (Base)" = WhseWkshLine."Qty. to Handle (Base)" then
                            WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
                        WhseItemTrackingLine."Qty. to Handle" :=
                          Round(
                            WhseItemTrackingLine."Qty. to Handle (Base)" / WhseItemTrackingLine."Qty. per Unit of Measure",
                            UOMMgt.QtyRndPrecision());
                        OnBeforeWhseItemTrackingLineInsert(WhseItemTrackingLine, SourceReservEntry);
                        WhseItemTrackingLine.Insert();
                    end;
                end;
            until SourceReservEntry.Next() = 0;

        TempWhseItemTrkgLine.Reset();
        if TempWhseItemTrkgLine.FindSet() then
            repeat
                if TempWhseItemTrkgLine.TrackingExists() and (TempWhseItemTrkgLine."Quantity Handled (Base)" = 0) then begin
                    WhseItemTrackingLine.Get(TempWhseItemTrkgLine."Entry No.");
                    WhseItemTrackingLine.Delete();
                end;
            until TempWhseItemTrkgLine.Next() = 0;
    end;

    procedure CopyLotNoInformation(LotNoInfo: Record "Lot No. Information"; NewLotNo: Code[50])
    var
        NewLotNoInfo: Record "Lot No. Information";
        ItemTrackingComment: Record "Item Tracking Comment";
    begin
        if NewLotNoInfo.Get(LotNoInfo."Item No.", LotNoInfo."Variant Code", NewLotNo) then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   TrackingNoInfoAlreadyExistsErr, LotNoInfo.TableCaption(), LotNoInfo.FieldCaption("Lot No."), NewLotNo), true)
            then
                Error('');
            NewLotNoInfo.TransferFields(LotNoInfo, false);
            NewLotNoInfo.Modify();
        end else begin
            NewLotNoInfo := LotNoInfo;
            NewLotNoInfo."Lot No." := NewLotNo;
            OnCopyLotNoInformationOnBeforeNewLotNoInfoInsert(NewLotNoInfo, LotNoInfo);
            NewLotNoInfo.Insert();
        end;

        ItemTrackingComment.CopyComments(
          "Item Tracking Comment Type"::"Lot No.",
          LotNoInfo."Item No.", LotNoInfo."Variant Code", LotNoInfo."Lot No.", NewLotNo);
    end;

    procedure CopySerialNoInformation(SerialNoInfo: Record "Serial No. Information"; NewSerialNo: Code[50])
    var
        NewSerialNoInfo: Record "Serial No. Information";
        ItemTrackingComment: Record "Item Tracking Comment";
    begin
        if NewSerialNoInfo.Get(SerialNoInfo."Item No.", SerialNoInfo."Variant Code", NewSerialNo) then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   TrackingNoInfoAlreadyExistsErr, SerialNoInfo.TableCaption(), SerialNoInfo.FieldCaption("Serial No."), NewSerialNo), true)
            then
                Error('');
            NewSerialNoInfo.TransferFields(SerialNoInfo, false);
            NewSerialNoInfo.Modify();
        end else begin
            NewSerialNoInfo := SerialNoInfo;
            NewSerialNoInfo."Serial No." := NewSerialNo;
            NewSerialNoInfo.Insert();
        end;

        ItemTrackingComment.CopyComments(
          "Item Tracking Comment Type"::"Serial No.",
          SerialNoInfo."Item No.", SerialNoInfo."Variant Code", SerialNoInfo."Serial No.", NewSerialNo);
    end;

    procedure FindLastItemLedgerEntry(ItemNo: Code[20]; VariantCode: Code[20]; ItemTrackingSetup: Record "Item Tracking Setup"; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        IsHandled: Boolean;
        EntryFound: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLastItemLedgerEntry(ItemNo, VariantCode, ItemTrackingSetup, ItemLedgEntry, EntryFound, IsHandled);
        if IsHandled then
            exit(EntryFound);

        if ItemLedgEntry.GetFilters() <> '' then
            ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.", "Package No.");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Variant Code", VariantCode);
        ItemLedgEntry.SetRange(Positive, true);
        if (ItemTrackingSetup."Lot No." <> '') or (ItemTrackingSetup."Package No." <> '') then begin
            if ItemTrackingSetup."Lot No." <> '' then
                ItemLedgEntry.SetRange("Lot No.", ItemTrackingSetup."Lot No.");
            if ItemTrackingSetup."Package No." <> '' then
                ItemLedgEntry.SetRange("Package No.", ItemTrackingSetup."Package No.");
        end else
            if ItemTrackingSetup."Serial No." <> '' then
                ItemLedgEntry.SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        EntryFound := ItemLedgEntry.FindLast();
        exit(EntryFound);
    end;

    procedure WhseItemTrackingLineExists(TemplateName: Code[10]; BatchName: Code[10]; LocationCode: Code[10]; LineNo: Integer; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"): Boolean
    begin
        WhseItemTrackingLine.Reset();
        WhseItemTrackingLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.", "Location Code");
        WhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        WhseItemTrackingLine.SetRange("Source Subtype", 0);
        WhseItemTrackingLine.SetRange("Source Batch Name", TemplateName);
        WhseItemTrackingLine.SetRange("Source ID", BatchName);
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        if LineNo <> 0 then
            WhseItemTrackingLine.SetRange("Source Ref. No.", LineNo);
        WhseItemTrackingLine.SetRange("Source Prod. Order Line", 0);

        exit(not WhseItemTrackingLine.IsEmpty());
    end;

    procedure ExistingExpirationDate(ItemNo: Code[20]; VariantCode: Code[20]; ItemTrackingSetup: Record "Item Tracking Setup"; TestMultiple: Boolean; var EntriesExist: Boolean) ExpiryDate: Date
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTracingMgt: Codeunit "Item Tracing Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExistingExpirationDate(
            ItemNo, VariantCode, ItemTrackingSetup."Lot No.", ItemTrackingSetup."Serial No.",
            TestMultiple, EntriesExist, ExpiryDate, IsHandled, ItemLedgEntry);
        if IsHandled then
            exit(ExpiryDate);

        ItemLedgEntry.SetLoadFields("Expiration Date");
        if not FindLastItemLedgerEntry(ItemNo, VariantCode, ItemTrackingSetup, ItemLedgEntry) then begin
            EntriesExist := false;
            exit;
        end;

        EntriesExist := true;
        ExpiryDate := ItemLedgEntry."Expiration Date";

        if TestMultiple and ItemTracingMgt.IsSpecificTracking(ItemNo, ItemTrackingSetup) then begin
            ItemLedgEntry.SetFilter("Expiration Date", '<>%1', ItemLedgEntry."Expiration Date");
            ItemLedgEntry.SetRange(Open, true);
            if not ItemLedgEntry.IsEmpty() then
                Error(Text007, ItemTrackingSetup."Lot No.");
        end;
    end;

    procedure ExistingExpirationDate(WarehouseActivityLine: Record "Warehouse Activity Line"; TestMultiple: Boolean; var EntriesExist: Boolean) ExpiryDate: Date
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.CopyTrackingFromWhseActivityLine(WarehouseActivityLine);
        exit(
            ExistingExpirationDate(
                WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", ItemTrackingSetup, TestMultiple, EntriesExist));
    end;

    procedure ExistingExpirationDate(TrackingSpecification: Record "Tracking Specification"; TestMultiple: Boolean; var EntriesExist: Boolean) ExpiryDate: Date
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.CopyTrackingFromTrackingSpec(TrackingSpecification);
        exit(
            ExistingExpirationDate(
                TrackingSpecification."Item No.", TrackingSpecification."Variant Code", ItemTrackingSetup, TestMultiple, EntriesExist));
    end;

    procedure ExistingExpirationDate(ItemLedgerEntry: Record "Item Ledger Entry"; TestMultiple: Boolean; var EntriesExist: Boolean) ExpiryDate: Date
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgerEntry);
        exit(
            ExistingExpirationDate(
                ItemLedgerEntry."Item No.", ItemLedgerEntry."Variant Code", ItemTrackingSetup, TestMultiple, EntriesExist));
    end;

    procedure ExistingExpirationDateAndQty(ItemNo: Code[20]; VariantCode: Code[20]; ItemTrackingSetup: Record "Item Tracking Setup"; var SumOfEntries: Decimal) ExpDate: Date
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExistingExpirationDateAndQty(ItemNo, VariantCode, ItemTrackingSetup."Lot No.", ItemTrackingSetup."Serial No.", SumOfEntries, ExpDate, IsHandled);
        if IsHandled then
            exit;

        ItemLedgEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        SumOfEntries := 0;
        ItemLedgEntry.SetLoadFields("Expiration Date");
        if not FindLastItemLedgerEntry(ItemNo, VariantCode, ItemTrackingSetup, ItemLedgEntry) then
            exit;

        ExpDate := ItemLedgEntry."Expiration Date";
        ItemLedgEntry.CalcSums("Remaining Quantity");
        SumOfEntries := ItemLedgEntry."Remaining Quantity";
    end;

    procedure ExistingWarrantyDate(ItemNo: Code[20]; VariantCode: Code[20]; ItemTrackingSetup: Record "Item Tracking Setup"; var EntriesExist: Boolean) WarrantyDate: Date
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetLoadFields("Warranty Date");
        if not FindLastItemLedgerEntry(ItemNo, VariantCode, ItemTrackingSetup, ItemLedgEntry) then
            exit;

        EntriesExist := true;
        WarrantyDate := ItemLedgEntry."Warranty Date";
    end;

    procedure WhseExistingExpirationDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; WhseItemTrackingSetup: Record "Item Tracking Setup"; var EntriesExist: Boolean) ExpDate: Date
    var
        WhseEntry: Record "Warehouse Entry";
        SumOfEntries: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseExistingExpirationDate(
            ItemNo, VariantCode, Location, WhseItemTrackingSetup."Lot No.", WhseItemTrackingSetup."Serial No.", EntriesExist, ExpDate, IsHandled);
        if IsHandled then
            exit;

        ExpDate := 0D;
        SumOfEntries := 0;

        if Location."Adjustment Bin Code" = '' then
            exit;

        WhseEntry.SetLoadFields("Expiration Date", "Qty. (Base)");
        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
        WhseEntry.SetRange("Location Code", Location.Code);
        WhseEntry.SetRange("Variant Code", VariantCode);
        if WhseItemTrackingSetup."Lot No." <> '' then
            WhseEntry.SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
        else
            if WhseItemTrackingSetup."Serial No." <> '' then
                WhseEntry.SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
        if WhseEntry.IsEmpty() then
            exit;

        if WhseEntry.FindSet() then
            repeat
                SumOfEntries += WhseEntry."Qty. (Base)";
                if (WhseEntry."Expiration Date" <> 0D) and ((WhseEntry."Expiration Date" < ExpDate) or (ExpDate = 0D)) then
                    ExpDate := WhseEntry."Expiration Date";
            until WhseEntry.Next() = 0;

        EntriesExist := SumOfEntries < 0;
    end;

    local procedure WhseExistingWarrantyDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; ItemTrackingSetup: Record "Item Tracking Setup"; var EntriesExist: Boolean) WarrantyDate: Date
    var
        WhseEntry: Record "Warehouse Entry";
        SumOfEntries: Decimal;
    begin
        WarrantyDate := 0D;
        SumOfEntries := 0;

        if Location."Adjustment Bin Code" = '' then
            exit;

        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
        WhseEntry.SetRange("Location Code", Location.Code);
        WhseEntry.SetRange("Variant Code", VariantCode);
        if ItemTrackingSetup."Lot No." <> '' then
            WhseEntry.SetRange("Lot No.", ItemTrackingSetup."Lot No.")
        else
            if ItemTrackingSetup."Serial No." <> '' then
                WhseEntry.SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        if WhseEntry.IsEmpty() then
            exit;

        if WhseEntry.FindSet() then
            repeat
                SumOfEntries += WhseEntry."Qty. (Base)";
                if (WhseEntry."Warranty Date" <> 0D) and ((WhseEntry."Warranty Date" < WarrantyDate) or (WarrantyDate = 0D)) then
                    WarrantyDate := WhseEntry."Warranty Date";
            until WhseEntry.Next() = 0;

        EntriesExist := SumOfEntries < 0;
    end;

    procedure GetWhseExpirationDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; ItemTrackingSetup: Record "Item Tracking Setup"; var ExpiryDate: Date) ExpiryDateFound: Boolean
    var
        EntriesExist: Boolean;
    begin
        ExpiryDate := ExistingExpirationDate(ItemNo, VariantCode, ItemTrackingSetup, false, EntriesExist);
        if EntriesExist and (ExpiryDate <> 0D) then
            exit(true);

        ExpiryDate := WhseExistingExpirationDate(ItemNo, VariantCode, Location, ItemTrackingSetup, EntriesExist);
        if EntriesExist and (ExpiryDate <> 0D) then
            exit(true);

        ExpiryDate := 0D;
        ExpiryDateFound := false;

        OnAfterGetWhseExpirationDate(
            ItemNo, VariantCode, Location, ItemTrackingSetup."Lot No.", ItemTrackingSetup."Serial No.",
            ExpiryDate, ExpiryDateFound);
    end;

    procedure GetWhseWarrantyDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; ItemTrackingSetup: Record "Item Tracking Setup"; var Warrantydate: Date): Boolean
    var
        EntriesExist: Boolean;
    begin
        WarrantyDate := ExistingWarrantyDate(ItemNo, VariantCode, ItemTrackingSetup, EntriesExist);
        if EntriesExist then
            exit(true);

        WarrantyDate := WhseExistingWarrantyDate(ItemNo, VariantCode, Location, ItemTrackingSetup, EntriesExist);
        if EntriesExist then
            exit(true);

        WarrantyDate := 0D;
        exit(false);
    end;

    procedure SumNewLotOnTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary): Decimal
    var
        SaveTrackingSpecification: Record "Tracking Specification";
        SumLot: Decimal;
    begin
        SumLot := 0;
        SaveTrackingSpecification := TempTrackingSpecification;
        TempTrackingSpecification.SetRange("New Lot No.", TempTrackingSpecification."New Lot No.");
        if TempTrackingSpecification.FindSet() then
            repeat
                SumLot += TempTrackingSpecification."Quantity (Base)";
            until TempTrackingSpecification.Next() = 0;
        TempTrackingSpecification := SaveTrackingSpecification;
        TempTrackingSpecification.SetRange("New Lot No.");
        exit(SumLot);
    end;

    procedure TestExpDateOnTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestExpDateOnTrackingSpec(TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit;

        if (TempTrackingSpecification."Lot No." = '') or (TempTrackingSpecification."Serial No." = '') then
            exit;
        TempTrackingSpecification.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
        TempTrackingSpecification.SetFilter("Expiration Date", '<>%1', TempTrackingSpecification."Expiration Date");
        if not TempTrackingSpecification.IsEmpty() then
            Error(Text007, TempTrackingSpecification."Lot No.");
        TempTrackingSpecification.SetRange("Lot No.");
        TempTrackingSpecification.SetRange("Expiration Date");
    end;

    procedure TestExpDateOnTrackingSpecNew(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestExpDateOnTrackingSpecNew(TempTrackingSpecification, IsHandled);
        if not IsHandled then
            if TempTrackingSpecification."New Lot No." = '' then
                exit;

        TempTrackingSpecification.SetRange("New Lot No.", TempTrackingSpecification."New Lot No.");
        TempTrackingSpecification.SetFilter("New Expiration Date", '<>%1', TempTrackingSpecification."New Expiration Date");
        if not TempTrackingSpecification.IsEmpty() then
            Error(Text007, TempTrackingSpecification."New Lot No.");
        TempTrackingSpecification.SetRange("New Lot No.");
        TempTrackingSpecification.SetRange("New Expiration Date");

        OnAfterTestExpDateOnTrackingSpecNew(TempTrackingSpecification);
    end;

    procedure CalcQtyBaseRegistered(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"): Decimal
    var
        RegisteredWhseActivityLineForCalcBaseQty: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLineForCalcBaseQty.CopyFilters(RegisteredWhseActivityLine);
        RegisteredWhseActivityLineForCalcBaseQty.SetFilter("Action Type", '%1|%2', RegisteredWhseActivityLineForCalcBaseQty."Action Type"::" ", RegisteredWhseActivityLineForCalcBaseQty."Action Type"::Place);
        RegisteredWhseActivityLineForCalcBaseQty.CalcSums("Qty. (Base)");
        exit(RegisteredWhseActivityLineForCalcBaseQty."Qty. (Base)");
    end;

    procedure CopyItemLedgEntryTrkgToSalesLn(var TempItemLedgEntryBuf: Record "Item Ledger Entry" temporary; ToSalesLine: Record "Sales Line"; FillExactCostRevLink: Boolean; var MissingExCostRevLink: Boolean; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; FromShptOrRcpt: Boolean)
    var
        TempReservEntry: Record "Reservation Entry" temporary;
        ReservEntry: Record "Reservation Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        TotalCostLCY: Decimal;
        ItemLedgEntryQty: Decimal;
        QtyBase: Decimal;
        SignFactor: Integer;
        LinkThisEntry: Boolean;
        EntriesExist: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyItemLedgEntryTrkgToSalesLn(TempItemLedgEntryBuf, ToSalesLine, IsHandled);
        if IsHandled then
            exit;

        if (ToSalesLine.Type <> ToSalesLine.Type::Item) or (ToSalesLine.Quantity = 0) then
            exit;

        if FillExactCostRevLink then
            FillExactCostRevLink := not ToSalesLine.IsShipment();

        OnCopyItemLedgEntryTrkgToSalesLnOnBeforeTempItemLedgEntryBufFindSet(
            TempItemLedgEntryBuf, ToSalesLine, FillExactCostRevLink, MissingExCostRevLink, FromPricesInclVAT, ToPricesInclVAT, FromShptOrRcpt);
        if TempItemLedgEntryBuf.FindSet() then begin
            if TempItemLedgEntryBuf.Quantity / ToSalesLine.Quantity < 0 then
                SignFactor := 1
            else
                SignFactor := -1;
            if ToSalesLine.IsCreditDocType() then
                SignFactor := -SignFactor;

            ReservMgt.SetReservSource(ToSalesLine);
            ReservMgt.DeleteReservEntries(true, 0);

            repeat
                LinkThisEntry := TempItemLedgEntryBuf."Entry No." > 0;

                if FillExactCostRevLink then
                    QtyBase := GetQtyBaseFromShippedQtyNotReturned(TempItemLedgEntryBuf."Shipped Qty. Not Returned", SignFactor, ToSalesLine)
                else
                    QtyBase := TempItemLedgEntryBuf.Quantity * SignFactor;

                if FillExactCostRevLink then
                    if not LinkThisEntry then
                        MissingExCostRevLink := true
                    else
                        if not MissingExCostRevLink then begin
                            TempItemLedgEntryBuf.CalcFields(TempItemLedgEntryBuf."Cost Amount (Actual)", TempItemLedgEntryBuf."Cost Amount (Expected)");
                            TotalCostLCY := TotalCostLCY + TempItemLedgEntryBuf."Cost Amount (Expected)" + TempItemLedgEntryBuf."Cost Amount (Actual)";
                            ItemLedgEntryQty := ItemLedgEntryQty - TempItemLedgEntryBuf.Quantity;
                        end;

                InsertReservEntryForSalesLine(
                  ReservEntry, TempItemLedgEntryBuf, ToSalesLine, QtyBase, FillExactCostRevLink and LinkThisEntry, EntriesExist);

                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until TempItemLedgEntryBuf.Next() = 0;
            ReservEngineMgt.UpdateOrderTracking(TempReservEntry);

            if FillExactCostRevLink and not MissingExCostRevLink then begin
                ToSalesLine.Validate(
                  "Unit Cost (LCY)", Abs(TotalCostLCY / ItemLedgEntryQty) * ToSalesLine."Qty. per Unit of Measure");
                if not FromShptOrRcpt then
                    CopyDocMgt.CalculateRevSalesLineAmount(ToSalesLine, ItemLedgEntryQty, FromPricesInclVAT, ToPricesInclVAT);
                OnCopyItemLedgEntryTrkgToSalesLnOnbeforeToSalesLineInsert(ToSalesLine, TempItemLedgEntryBuf);
                ToSalesLine.Modify();
            end;
        end;
    end;

    procedure CopyItemLedgEntryTrkgToPurchLn(var ItemLedgEntryBuf: Record "Item Ledger Entry"; ToPurchLine: Record "Purchase Line"; FillExactCostRevLink: Boolean; var MissingExCostRevLink: Boolean; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; FromShptOrRcpt: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        TotalCostLCY: Decimal;
        ItemLedgEntryQty: Decimal;
        QtyBase: Decimal;
        SignFactor: Integer;
        LinkThisEntry: Boolean;
        EntriesExist: Boolean;
        AppliedToItemEntry: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyItemLedgEntryTrkgToPurchLn(ItemLedgEntryBuf, ToPurchLine, IsHandled);
        if IsHandled then
            exit;

        if (ToPurchLine.Type <> ToPurchLine.Type::Item) or (ToPurchLine.Quantity = 0) then
            exit;

        if FillExactCostRevLink then
            FillExactCostRevLink := ToPurchLine.Signed(ToPurchLine."Quantity (Base)") < 0;

        if FillExactCostRevLink then
            if (ToPurchLine."Document Type" in [ToPurchLine."Document Type"::Invoice, ToPurchLine."Document Type"::"Credit Memo"]) and
               (ToPurchLine."Job No." <> '')
            then
                FillExactCostRevLink := false;

        if ItemLedgEntryBuf.FindSet() then begin
            if ItemLedgEntryBuf.Quantity / ToPurchLine.Quantity > 0 then
                SignFactor := 1
            else
                SignFactor := -1;
            if ToPurchLine."Document Type" in
               [ToPurchLine."Document Type"::"Return Order", ToPurchLine."Document Type"::"Credit Memo"]
            then
                SignFactor := -SignFactor;

            if ToPurchLine."Expected Receipt Date" = 0D then
                ToPurchLine."Expected Receipt Date" := WorkDate();
            ToPurchLine."Outstanding Qty. (Base)" := ToPurchLine."Quantity (Base)";
            ReservMgt.SetReservSource(ToPurchLine);
            ReservMgt.DeleteReservEntries(true, 0);

            repeat
                LinkThisEntry := ItemLedgEntryBuf."Entry No." > 0;

                if FillExactCostRevLink then
                    if not LinkThisEntry then
                        MissingExCostRevLink := true
                    else
                        if not MissingExCostRevLink then begin
                            ItemLedgEntryBuf.CalcFields(ItemLedgEntryBuf."Cost Amount (Actual)", ItemLedgEntryBuf."Cost Amount (Expected)");
                            TotalCostLCY := TotalCostLCY + ItemLedgEntryBuf."Cost Amount (Expected)" + ItemLedgEntryBuf."Cost Amount (Actual)";
                            ItemLedgEntryQty := ItemLedgEntryQty - ItemLedgEntryBuf.Quantity;
                        end;

                if LinkThisEntry and (ItemLedgEntryBuf."Lot No." = '') and (ItemLedgEntryBuf."Package No." = '') then
                    // The check for Lot No = '' is to avoid changing the remaining quantity for partly sold Lots
                    // because this will cause undefined quantities in the item tracking
                    ItemLedgEntryBuf."Remaining Quantity" := ItemLedgEntryBuf.Quantity;
                if ToPurchLine."Job No." = '' then
                    QtyBase := ItemLedgEntryBuf."Remaining Quantity" * SignFactor
                else begin
                    ItemLedgEntry.Get(ItemLedgEntryBuf."Entry No.");
                    QtyBase := Abs(ItemLedgEntry.Quantity) * SignFactor;
                end;

                AppliedToItemEntry :=
                    FillExactCostRevLink and LinkThisEntry and
                    not (ToPurchLine.IsCreditDocType() and (ToPurchLine."Job No." <> ''));

                InsertReservEntryForPurchLine(
                  ItemLedgEntryBuf, ToPurchLine, QtyBase, AppliedToItemEntry, EntriesExist);
            until ItemLedgEntryBuf.Next() = 0;

            if FillExactCostRevLink and not MissingExCostRevLink then begin
                ToPurchLine.Validate(
                  "Unit Cost (LCY)",
                  Abs(TotalCostLCY / ItemLedgEntryQty) * ToPurchLine."Qty. per Unit of Measure");
                if not FromShptOrRcpt then
                    CopyDocMgt.CalculateRevPurchLineAmount(
                      ToPurchLine, ItemLedgEntryQty, FromPricesInclVAT, ToPricesInclVAT);

                ToPurchLine.Modify();
            end;
        end;
    end;

    procedure CopyItemLedgEntryTrkgToTransferLine(var ItemLedgEntryBuf: Record "Item Ledger Entry"; ToTransferLine: Record "Transfer Line")
    var
        ReservEntry: Record "Reservation Entry";
        ToReservEntry: Record "Reservation Entry";
        QtyBase: Decimal;
        SignFactor: Integer;
        EntriesExist: Boolean;
    begin
        if ToTransferLine.Quantity = 0 then
            exit;

        SignFactor := -1;

        if ItemLedgEntryBuf.FindSet() then
            repeat
                QtyBase := ItemLedgEntryBuf."Remaining Quantity" * SignFactor;
                InsertReservEntryToOutboundTransferLine(ReservEntry, ItemLedgEntryBuf, ToTransferLine, QtyBase, EntriesExist);
            until ItemLedgEntryBuf.Next() = 0;

        // push item tracking to the inbound transfer
        ToReservEntry := ReservEntry;
        ToReservEntry."Source Subtype" := 1;
        SynchronizeItemTrackingByPtrs(ReservEntry, ToReservEntry);
    end;

    procedure SynchronizeWhseActivItemTrkg(WhseActivLine: Record "Warehouse Activity Line")
    begin
        SynchronizeWhseActivItemTrkg(WhseActivLine, false);
    end;

    internal procedure SynchronizeWhseActivItemTrkg(WhseActivLine: Record "Warehouse Activity Line"; BlockCommit: Boolean)
    var
        TempTrackingSpec: Record "Tracking Specification" temporary;
        TempReservEntry: Record "Reservation Entry" temporary;
        ReservEntry: Record "Reservation Entry";
        xReservEntry: Record "Reservation Entry";
        ReservEntryBindingCheck: Record "Reservation Entry";
        UntrackedReservEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text[250];
        IsTransferReceipt: Boolean;
        IsATOPosting: Boolean;
        IsBindingOrderToOrder: Boolean;
    begin
        // Used for carrying the item tracking from the invt. pick/put-away to the parent line.
        WhseActivLine.Reset();
        WhseActivLine.SetSourceFilter(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", true);
        WhseActivLine.SetRange("Assemble to Order", WhseActivLine."Assemble to Order");
        if WhseActivLine.FindSet() then begin
            // Transfer receipt needs special treatment:
            IsTransferReceipt := (WhseActivLine."Source Type" = Database::"Transfer Line") and (WhseActivLine."Source Subtype" = 1);
            IsATOPosting := (WhseActivLine."Source Type" = Database::"Sales Line") and WhseActivLine."Assemble to Order";
            if (WhseActivLine."Source Type" in [ProdOrderLineID(), ProdOrderCompID()]) or IsTransferReceipt then
                ToRowID :=
                  ItemTrackingMgt.ComposeRowID(
                    WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", '', WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.")
            else
                if IsATOPosting then
                    OnSynchronizeWhseActivItemTrkgAssembly(WhseActivLine, ToRowID)
                else
                    if WhseActivLine."Source Type" in [Database::Job, Database::"Job Planning Line"] then
                        ToRowID :=
                          ItemTrackingMgt.ComposeRowID(Database::"Job Planning Line", 2, WhseActivLine."Source No.", '', 0, WhseActivLine."Source Line No.")
                    else
                        ToRowID :=
                          ItemTrackingMgt.ComposeRowID(
                            WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", '', WhseActivLine."Source Subline No.", WhseActivLine."Source Line No.");
            OnSynchronizeWhseActivItemTrkgOnAfterSetToRowID(WhseActivLine, ToRowID);
            TempReservEntry.SetPointer(ToRowID);
            SignFactor := WhseActivitySignFactor(WhseActivLine);
            ReservEntryBindingCheck.SetPointer(ToRowID);
            ReservEntryBindingCheck.SetPointerFilter();
            repeat
                if WhseActivLine.TrackingExists() then begin
                    TempReservEntry."Entry No." += 1;
                    TempReservEntry.Positive := SignFactor > 0;
                    TempReservEntry."Item No." := WhseActivLine."Item No.";
                    TempReservEntry."Location Code" := WhseActivLine."Location Code";
                    TempReservEntry.Description := WhseActivLine.Description;
                    TempReservEntry."Variant Code" := WhseActivLine."Variant Code";
                    TempReservEntry."Quantity (Base)" := WhseActivLine."Qty. Outstanding (Base)" * SignFactor;
                    TempReservEntry.Quantity := WhseActivLine."Qty. Outstanding" * SignFactor;
                    TempReservEntry."Qty. to Handle (Base)" := WhseActivLine."Qty. to Handle (Base)" * SignFactor;
                    TempReservEntry."Qty. to Invoice (Base)" := WhseActivLine."Qty. to Handle (Base)" * SignFactor;
                    TempReservEntry."Qty. per Unit of Measure" := WhseActivLine."Qty. per Unit of Measure";
                    TempReservEntry.CopyTrackingFromWhseActivLine(WhseActivLine);
                    OnSyncActivItemTrkgOnBeforeInsertTempReservEntry(TempReservEntry, WhseActivLine);
                    TempReservEntry.Insert();

                    if not IsBindingOrderToOrder then begin
                        ReservEntryBindingCheck.SetTrackingFilterFromWhseActivityLine(WhseActivLine);
                        ReservEntryBindingCheck.SetRange(Binding, ReservEntryBindingCheck.Binding::"Order-to-Order");
                        IsBindingOrderToOrder := not ReservEntryBindingCheck.IsEmpty();
                    end;
                end;
            until WhseActivLine.Next() = 0;

            if TempReservEntry.IsEmpty() then
                exit;
        end;

        SumUpItemTracking(TempReservEntry, TempTrackingSpec, false, true);
        SynchronizeWhseActivItemTrackingReservation(WhseActivLine, IsTransferReceipt);

        if TempTrackingSpec.FindSet() then
            repeat
                ReservEntry.SetSourceFilter(
                  TempTrackingSpec."Source Type", TempTrackingSpec."Source Subtype",
                  TempTrackingSpec."Source ID", TempTrackingSpec."Source Ref. No.", true);
                ReservEntry.SetSourceFilter('', TempTrackingSpec."Source Prod. Order Line");
                ReservEntry.SetTrackingFilterFromSpec(TempTrackingSpec);
                if IsTransferReceipt then
                    ReservEntry.SetRange("Source Ref. No.");
                if ReservEntry.FindSet() then begin
                    repeat
                        xReservEntry.TransferFields(ReservEntry);
                        if Abs(TempTrackingSpec."Qty. to Handle (Base)") > Abs(ReservEntry."Quantity (Base)") then
                            ReservEntry.Validate("Qty. to Handle (Base)", ReservEntry."Quantity (Base)")
                        else
                            ReservEntry.Validate("Qty. to Handle (Base)", TempTrackingSpec."Qty. to Handle (Base)");

                        if Abs(TempTrackingSpec."Qty. to Invoice (Base)") > Abs(ReservEntry."Quantity (Base)") then
                            ReservEntry.Validate("Qty. to Invoice (Base)", ReservEntry."Quantity (Base)")
                        else
                            ReservEntry.Validate("Qty. to Invoice (Base)", TempTrackingSpec."Qty. to Invoice (Base)");

                        TempTrackingSpec."Qty. to Handle (Base)" -= ReservEntry."Qty. to Handle (Base)";
                        TempTrackingSpec."Qty. to Invoice (Base)" -= ReservEntry."Qty. to Invoice (Base)";
                        OnSyncActivItemTrkgOnBeforeTempTrackingSpecModify(TempTrackingSpec, ReservEntry);
                        TempTrackingSpec.Modify();

                        WhseActivLine.Reset();
                        WhseActivLine.SetSourceFilter(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", true);
                        WhseActivLine.SetTrackingFilterFromReservEntry(ReservEntry);
                        if WhseActivLine.FindFirst() then
                            ReservEntry."Expiration Date" := WhseActivLine."Expiration Date";
                        OnSynchronizeWhseActivItemTrkgOnAfterSetExpirationDate(WhseActivLine, ReservEntry);

                        if (xReservEntry."Qty. to Handle (Base)" <> ReservEntry."Qty. to Handle (Base)") or (xReservEntry."Qty. to Invoice (Base)" <> ReservEntry."Qty. to Invoice (Base)") or (xReservEntry."Expiration Date" <> ReservEntry."Expiration Date") then
                            ReservEntry.Modify();

                        if IsReservedFromTransferShipment(ReservEntry) then
                            UpdateItemTrackingInTransferReceipt(ReservEntry);
                    until ReservEntry.Next() = 0;

                    if (TempTrackingSpec."Qty. to Handle (Base)" = 0) and (TempTrackingSpec."Qty. to Invoice (Base)" = 0) then
                        TempTrackingSpec.Delete();
                end
                else begin
                    UntrackedReservEntry.SetSourceFilter(
                        TempTrackingSpec."Source Type", TempTrackingSpec."Source Subtype",
                        TempTrackingSpec."Source ID", TempTrackingSpec."Source Ref. No.", true);
                    UntrackedReservEntry.SetSourceFilter('', TempTrackingSpec."Source Prod. Order Line");
                    RemoveUntrackedSurplus(UntrackedReservEntry);
                end;
            until TempTrackingSpec.Next() = 0;

        if TempTrackingSpec.FindSet() then
            repeat
                TempTrackingSpec."Quantity (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                TempTrackingSpec."Qty. to Handle (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                TempTrackingSpec."Qty. to Invoice (Base)" := Abs(TempTrackingSpec."Qty. to Invoice (Base)");
                OnSynchronizeWhseActivItemTrkgOnAfterAssignAbsQty(TempTrackingSpec);
                TempTrackingSpec.Modify();
                if (WhseActivLine."Activity Type" in [WhseActivLine."Activity Type"::Pick, WhseActivLine."Activity Type"::"Invt. Pick"]) and
                   (WhseActivLine."Action Type" <> WhseActivLine."Action Type"::Place) then
                    CheckItemTrackingBeforeRegisterNewLines(TempTrackingSpec);
            until TempTrackingSpec.Next() = 0;

        RegisterNewItemTrackingLines(TempTrackingSpec, BlockCommit);
    end;

    local procedure CheckItemTrackingBeforeRegisterNewLines(var TempTrackingSpecificationToCheck: Record "Tracking Specification" temporary)
    var
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
    begin
        if (TempTrackingSpecificationToCheck."Lot No." = '') and (TempTrackingSpecificationToCheck."Serial No." = '') then
            exit;
        TempWarehouseActivityLine.Init();
        TempWarehouseActivityLine."Item No." := TempTrackingSpecificationToCheck."Item No.";
        TempWarehouseActivityLine."Variant Code" := TempTrackingSpecificationToCheck."Variant Code";
        TempWarehouseActivityLine."Location Code" := TempTrackingSpecificationToCheck."Location Code";
        TempWarehouseActivityLine."Bin Code" := TempTrackingSpecificationToCheck."Bin Code";
        TempWarehouseActivityLine."Lot No." := TempTrackingSpecificationToCheck."Lot No.";
        TempWarehouseActivityLine."Serial No." := TempTrackingSpecificationToCheck."Serial No.";
        TempWarehouseActivityLine."Expiration Date" := TempTrackingSpecificationToCheck."Expiration Date";
        TempWarehouseActivityLine."Qty. (Base)" := TempTrackingSpecificationToCheck."Qty. to Handle (Base)";
        TempWarehouseActivityLine."Qty. to Handle (Base)" := TempTrackingSpecificationToCheck."Qty. to Handle (Base)";
        TempWarehouseActivityLine."Source Type" := TempTrackingSpecificationToCheck."Source Type";
        TempWarehouseActivityLine."Source Subtype" := TempTrackingSpecificationToCheck."Source Subtype";
        TempWarehouseActivityLine."Source No." := TempTrackingSpecificationToCheck."Source ID";
        TempWarehouseActivityLine."Source Line No." := TempTrackingSpecificationToCheck."Source Ref. No.";
        TempWarehouseActivityLine."Source Subline No." := TempTrackingSpecificationToCheck."Source Prod. Order Line";
        if TempTrackingSpecificationToCheck."Lot No." <> '' then
            TempWarehouseActivityLine.CheckReservedItemTrkg(Enum::"Item Tracking Type"::"Lot No.", TempWarehouseActivityLine."Lot No.");
        if TempTrackingSpecificationToCheck."Serial No." <> '' then
            TempWarehouseActivityLine.CheckReservedItemTrkg(Enum::"Item Tracking Type"::"Serial No.", TempWarehouseActivityLine."Serial No.");
    end;

    local procedure RegisterNewItemTrackingLines(var TempTrackingSpec: Record "Tracking Specification" temporary; ItemTrackingLinesBlockCommit: Boolean)
    var
        TrackingSpec: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ItemTrackingLines: Page "Item Tracking Lines";
        QtyToHandleInItemTracking: Decimal;
        QtyToHandleOnSourceDocLine: Decimal;
        QtyToHandleToNewRegister: Decimal;
        AllowWhseOverpick: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeRegisterNewItemTrackingLines(TempTrackingSpec);

        TempTrackingSpec.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");

        if TempTrackingSpec.FindSet() then
            repeat
                TempTrackingSpec.SetSourceFilter(
                  TempTrackingSpec."Source Type", TempTrackingSpec."Source Subtype",
                  TempTrackingSpec."Source ID", TempTrackingSpec."Source Ref. No.", false);
                TempTrackingSpec.SetRange("Source Prod. Order Line", TempTrackingSpec."Source Prod. Order Line");

                TrackingSpec := TempTrackingSpec;
                TempTrackingSpec.CalcSums("Qty. to Handle (Base)");

                QtyToHandleToNewRegister := TempTrackingSpec."Qty. to Handle (Base)";
                ReservEntry.TransferFields(TempTrackingSpec);

                if ReservEntry."Source Type" = ProdOrderCompID() then
                    SourceProdOrderLineForFilter := ReservEntry."Source Prod. Order Line";

                QtyToHandleInItemTracking :=
                  Abs(CalcQtyToHandleForTrackedQtyOnDocumentLine(
                      ReservEntry."Source Type", ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No."));
                QtyToHandleOnSourceDocLine := ReservMgt.GetSourceRecordValue(ReservEntry, false, 0);

                IsHandled := false;
                AllowWhseOverpick := false;
                OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError(
                    TempTrackingSpec, QtyToHandleToNewRegister, QtyToHandleInItemTracking, QtyToHandleOnSourceDocLine, IsHandled, AllowWhseOverpick);
                if not IsHandled then
                    if not AllowWhseOverpick then
                        if QtyToHandleToNewRegister + QtyToHandleInItemTracking > Abs(QtyToHandleOnSourceDocLine) then
                            Error(CannotMatchItemTrackingErr,
                                TempTrackingSpec."Source ID", TempTrackingSpec."Source Ref. No.",
                                TempTrackingSpec."Item No.", TempTrackingSpec.Description);

                TrackingSpec."Quantity (Base)" :=
                  TempTrackingSpec."Qty. to Handle (Base)" + Abs(ItemTrkgQtyPostedOnSource(TrackingSpec));

                OnBeforeRegisterItemTrackingLinesLoop(TrackingSpec, TempTrackingSpec);

                Clear(ItemTrackingLines);
                OnRegisterNewItemTrackingLinesOnAfterClearItemTrackingLines(ItemTrackingLines);
                ItemTrackingLines.SetCalledFromSynchWhseItemTrkg(true);
                ItemTrackingLines.SetBlockCommit(ItemTrackingLinesBlockCommit);
                if QtyToHandleOnSourceDocLine < 0 then
                    ItemTrackingLines.SetSignFactor(-1);
                OnRegisterNewItemTrackingLinesOnBeforeRegisterItemTrackingLines(TempTrackingSpecification, ItemTrackingLines);
                ItemTrackingLines.RegisterItemTrackingLines(TrackingSpec, TrackingSpec."Creation Date", TempTrackingSpec);
                TempTrackingSpec.ClearSourceFilter();
            until TempTrackingSpec.Next() = 0;

        TempTrackingSpec.SetCurrentKey("Entry No.");
    end;

    local procedure WhseActivitySignFactor(WhseActivityLine: Record "Warehouse Activity Line"): Integer
    begin
        if WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::"Invt. Pick" then begin
            if WhseActivityLine."Assemble to Order" then
                exit(1);
            exit(-1);
        end;
        if WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::"Invt. Put-away" then
            exit(1);

        Error(Text011, WhseActivityLine.FieldCaption("Activity Type"), WhseActivityLine."Activity Type");
    end;

    procedure RetrieveAppliedExpirationDate(var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        OnBeforeRetrieveAppliedExpirationDate(TempItemLedgEntry);

        if TempItemLedgEntry.Positive then
            exit;

        ItemApplnEntry.Reset();
        ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
        ItemApplnEntry.SetRange("Outbound Item Entry No.", TempItemLedgEntry."Entry No.");
        ItemApplnEntry.SetRange("Item Ledger Entry No.", TempItemLedgEntry."Entry No.");
        if ItemApplnEntry.FindFirst() then begin
            ItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");
            TempItemLedgEntry."Expiration Date" := ItemLedgEntry."Expiration Date";
        end;

        OnAfterRetrieveAppliedExpirationDate(TempItemLedgEntry, ItemApplnEntry);
    end;

    local procedure ItemTrkgQtyPostedOnSource(SourceTrackingSpec: Record "Tracking Specification") Qty: Decimal
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TransferLine: Record "Transfer Line";
    begin
        TrackingSpecification.SetSourceFilter(SourceTrackingSpec."Source Type", SourceTrackingSpec."Source Subtype", SourceTrackingSpec."Source ID", SourceTrackingSpec."Source Ref. No.", true);
        TrackingSpecification.SetSourceFilter(SourceTrackingSpec."Source Batch Name", SourceTrackingSpec."Source Prod. Order Line");
        if not TrackingSpecification.IsEmpty() then begin
            TrackingSpecification.FindSet();
            repeat
                Qty += TrackingSpecification."Quantity (Base)";
            until TrackingSpecification.Next() = 0;
        end;

        ReservEntry.SetSourceFilter(SourceTrackingSpec."Source Type", SourceTrackingSpec."Source Subtype", SourceTrackingSpec."Source ID", SourceTrackingSpec."Source Ref. No.", false);
        ReservEntry.SetSourceFilter('', SourceTrackingSpec."Source Prod. Order Line");
        ReservEntry.CalcSums("Quantity (Base)");
        Qty += ReservEntry."Quantity (Base)";

        if SourceTrackingSpec."Source Type" = Database::"Transfer Line" then begin
            TransferLine.Get(SourceTrackingSpec."Source ID", SourceTrackingSpec."Source Ref. No.");
            Qty -= TransferLine."Qty. Shipped (Base)";
        end;
    end;

    local procedure UpdateItemTrackingInTransferReceipt(FromReservEntry: Record "Reservation Entry")
    var
        ToReservEntry: Record "Reservation Entry";
        ToRowID: Text[250];
    begin
        ToRowID := ComposeRowID(
            Database::"Transfer Line", 1, FromReservEntry."Source ID",
            FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line", FromReservEntry."Source Ref. No.");
        ToReservEntry.SetPointer(ToRowID);
        ToReservEntry.SetPointerFilter();
        ToReservEntry.SetTrackingFilterFromReservEntry(FromReservEntry);
        SynchronizeItemTrkgTransfer(ToReservEntry);
    end;

    local procedure SynchronizeItemTrkgTransfer(var ReservEntry: Record "Reservation Entry")
    var
        FromReservEntry: Record "Reservation Entry";
        ToReservEntry: Record "Reservation Entry";
        TempToReservEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        FromReservEntry.Copy(ReservEntry);
        FromReservEntry.SetRange("Source Subtype", 0);

        ToReservEntry.Copy(ReservEntry);
        ToReservEntry.SetRange("Source Subtype", 1);
        if ToReservEntry.FindSet() then
            repeat
                TempToReservEntry := ToReservEntry;
                TempToReservEntry."Qty. to Handle (Base)" := 0;
                TempToReservEntry."Qty. to Invoice (Base)" := 0;
                TempToReservEntry.Insert();
            until ToReservEntry.Next() = 0;
        if TempToReservEntry.IsEmpty() then
            exit;

        SumUpItemTracking(FromReservEntry, TempTrackingSpecification, false, true);
        TempTrackingSpecification.Reset();
        TempTrackingSpecification.SetFilter("Qty. to Handle (Base)", '<%1', 0);
        if TempTrackingSpecification.FindSet() then
            repeat
                ToReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                OnSynchronizeItemTrkgTransferOnBeforeToReservEntryModifyAll(ToReservEntry, TempTrackingSpecification);
                ToReservEntry.ModifyAll("Qty. to Handle (Base)", 0);
                ToReservEntry.ModifyAll("Qty. to Invoice (Base)", 0);
                TempTrackingSpecification."Qty. to Handle (Base)" *= -1;
                TempToReservEntry.SetCurrentKey(
                  "Item No.", "Variant Code", "Location Code", "Item Tracking", "Reservation Status", "Lot No.", "Serial No.");
                TempToReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                OnSynchronizeItemTrkgTransferOnAfterTempToReservEntrySetFilters(TempToReservEntry, TempTrackingSpecification);
                if TempToReservEntry.FindSet() then
                    repeat
                        if TempToReservEntry."Quantity (Base)" < TempTrackingSpecification."Qty. to Handle (Base)" then begin
                            TempToReservEntry."Qty. to Handle (Base)" := TempToReservEntry."Quantity (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" -= TempToReservEntry."Quantity (Base)";
                            TempToReservEntry."Qty. to Invoice (Base)" := TempToReservEntry."Quantity (Base)";
                        end else begin
                            TempToReservEntry."Qty. to Handle (Base)" := TempTrackingSpecification."Qty. to Handle (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                            TempToReservEntry."Qty. to Invoice (Base)" := TempTrackingSpecification."Qty. to Handle (Base)";
                        end;

                        ToReservEntry.Get(TempToReservEntry."Entry No.", TempToReservEntry.Positive);
                        ToReservEntry."Qty. to Handle (Base)" := TempToReservEntry."Qty. to Handle (Base)";
                        ToReservEntry."Qty. to Invoice (Base)" := TempToReservEntry."Qty. to Handle (Base)";
                        ToReservEntry.Modify();
                    until (TempToReservEntry.Next() = 0) or (TempTrackingSpecification."Qty. to Handle (Base)" = 0);
                ReservEntry.Get(ToReservEntry."Entry No.", ToReservEntry.Positive);

            until TempTrackingSpecification.Next() = 0;
    end;

    procedure InitCollectItemTrkgInformation()
    begin
        TempGlobalWhseItemTrkgLine.DeleteAll();
    end;

    procedure CollectItemTrkgInfWhseJnlLine(WhseJnlLine: Record "Warehouse Journal Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetSourceFilter(
            Database::"Warehouse Journal Line", -1, WhseJnlLine."Journal Batch Name", WhseJnlLine."Line No.", true);
        WhseItemTrackingLine.SetSourceFilter(WhseJnlLine."Journal Template Name", -1);
        WhseItemTrackingLine.SetRange("Location Code", WhseJnlLine."Location Code");
        WhseItemTrackingLine.SetRange("Item No.", WhseJnlLine."Item No.");
        WhseItemTrackingLine.SetRange("Variant Code", WhseJnlLine."Variant Code");
        WhseItemTrackingLine.SetRange("Qty. per Unit of Measure", WhseJnlLine."Qty. per Unit of Measure");
        OnCollectItemTrkgInfWhseJnlLineOnAfterSetFilters(WhseItemTrackingLine, WhseJnlLine);
        if WhseItemTrackingLine.FindSet() then
            repeat
                Clear(TempGlobalWhseItemTrkgLine);
                TempGlobalWhseItemTrkgLine := WhseItemTrackingLine;
                if TempGlobalWhseItemTrkgLine.Insert() then;
            until WhseItemTrackingLine.Next() = 0;
    end;

    procedure CheckItemTrkgInfBeforePost()
    var
        TempLotNoInfo: Record "Lot No. Information" temporary;
        CheckExpDate: Date;
        ErrorFound: Boolean;
        EndLoop: Boolean;
        ErrMsgTxt: Text[160];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrkgInfBeforePost(TempGlobalWhseItemTrkgLine, IsHandled);
        if IsHandled then
            exit;

        // Check for different expiration dates within one Lot no.
        if TempGlobalWhseItemTrkgLine.Find('-') then begin
            TempLotNoInfo.DeleteAll();
            repeat
                if TempGlobalWhseItemTrkgLine."New Lot No." <> '' then begin
                    Clear(TempLotNoInfo);
                    TempLotNoInfo."Item No." := TempGlobalWhseItemTrkgLine."Item No.";
                    TempLotNoInfo."Variant Code" := TempGlobalWhseItemTrkgLine."Variant Code";
                    TempLotNoInfo."Lot No." := TempGlobalWhseItemTrkgLine."New Lot No.";
                    OnCheckItemTrkgInfBeforePostOnBeforeTempItemLotInfoInsert(TempLotNoInfo, TempGlobalWhseItemTrkgLine);
                    if TempLotNoInfo.Insert() then;
                end;
            until TempGlobalWhseItemTrkgLine.Next() = 0;

            if TempLotNoInfo.Find('-') then
                repeat
                    ErrorFound := false;
                    EndLoop := false;
                    if TempGlobalWhseItemTrkgLine.Find('-') then begin
                        CheckExpDate := 0D;
                        repeat
                            if (TempGlobalWhseItemTrkgLine."Item No." = TempLotNoInfo."Item No.") and
                               (TempGlobalWhseItemTrkgLine."Variant Code" = TempLotNoInfo."Variant Code") and
                               (TempGlobalWhseItemTrkgLine."New Lot No." = TempLotNoInfo."Lot No.")
                            then
                                if CheckExpDate = 0D then
                                    CheckExpDate := TempGlobalWhseItemTrkgLine."New Expiration Date"
                                else
                                    if TempGlobalWhseItemTrkgLine."New Expiration Date" <> CheckExpDate then begin
                                        ErrorFound := true;
                                        ErrMsgTxt :=
                                          StrSubstNo(Text012,
                                            TempGlobalWhseItemTrkgLine."Lot No.",
                                            TempGlobalWhseItemTrkgLine."New Expiration Date",
                                            CheckExpDate);
                                    end;
                            if not ErrorFound then
                                if TempGlobalWhseItemTrkgLine.Next() = 0 then
                                    EndLoop := true;
                        until EndLoop or ErrorFound;
                    end;
                until (TempLotNoInfo.Next() = 0) or ErrorFound;
            if ErrorFound then
                Error(ErrMsgTxt);
        end;
    end;

    procedure SetPick(IsPick2: Boolean)
    begin
        IsPick := IsPick2;
    end;

    procedure StrictExpirationPosting(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(ItemNo);
        if Item."Item Tracking Code" = '' then
            exit(false);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        exit(ItemTrackingCode."Strict Expiration Posting");
    end;

    procedure WhseItemTrkgLineExists(SourceId: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrkgLine.SetSourceFilter(SourceType, SourceSubtype, SourceId, SourceRefNo, true);
        WhseItemTrkgLine.SetSourceFilter(SourceBatchName, SourceProdOrderLine);
        WhseItemTrkgLine.SetRange("Location Code", LocationCode);
        WhseItemTrkgLine.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);
        OnWhseItemTrkgLineExistsOnBeforeExit(WhseItemTrkgLine);
        exit(not WhseItemTrkgLine.IsEmpty());
    end;

    procedure CalcWhseItemTrkgLineQtyBase(SourceType: Integer; SourceSubtype: Integer; SourceId: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetSourceFilter(SourceType, SourceSubtype, SourceId, SourceRefNo, true);
        WhseItemTrackingLine.SetSourceFilter(SourceBatchName, SourceProdOrderLine);
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        WhseItemTrackingLine.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);
        WhseItemTrackingLine.CalcSums("Quantity (Base)");
        exit(WhseItemTrackingLine."Quantity (Base)");
    end;

    procedure InsertProspectReservEntryFromItemEntryRelationAndSourceData(var ItemEntryRelation: Record "Item Entry Relation"; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        TrackingSpecification: Record "Tracking Specification";
        QtyBase: Decimal;
    begin
        if not ItemEntryRelation.FindSet() then
            exit;

        repeat
            TrackingSpecification.Get(ItemEntryRelation."Item Entry No.");
            QtyBase := TrackingSpecification."Quantity (Base)" - TrackingSpecification."Quantity Invoiced (Base)";
            InsertReservEntryFromTrackingSpec(
              TrackingSpecification, SourceSubtype, SourceID, SourceRefNo, QtyBase);
        until ItemEntryRelation.Next() = 0;
    end;

    procedure UpdateQuantities(WhseWorksheetLine: Record "Whse. Worksheet Line"; var TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line"; var SourceQuantityArray: array[2] of Decimal; var UndefinedQtyArray: array[2] of Decimal; SourceType: Integer): Boolean
    begin
        SourceQuantityArray[1] := Abs(WhseWorksheetLine."Qty. (Base)");
        SourceQuantityArray[2] := Abs(WhseWorksheetLine."Qty. to Handle (Base)");
        exit(CalculateSums(WhseWorksheetLine, TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray, SourceType));
    end;

    procedure CalculateSums(WhseWorksheetLine: Record "Whse. Worksheet Line"; var TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceQuantityArray: array[2] of Decimal; var UndefinedQtyArray: array[2] of Decimal; SourceType: Integer): Boolean
    begin
        TotalWhseItemTrackingLine.SetRange(TotalWhseItemTrackingLine."Location Code", WhseWorksheetLine."Location Code");
        case SourceType of
            Database::"Posted Whse. Receipt Line",
          Database::"Warehouse Shipment Line",
          Database::"Whse. Internal Put-away Line",
          Database::"Whse. Internal Pick Line",
          AssemblyLineID(),
          Database::Job,
          Database::"Internal Movement Line":
                TotalWhseItemTrackingLine.SetSourceFilter(
                  SourceType, -1, WhseWorksheetLine."Whse. Document No.", WhseWorksheetLine."Whse. Document Line No.", true);
            ProdOrderCompID():
                begin
                    TotalWhseItemTrackingLine.SetSourceFilter(
                      SourceType, WhseWorksheetLine."Source Subtype", WhseWorksheetLine."Source No.", WhseWorksheetLine."Source Subline No.",
                      true);
                    TotalWhseItemTrackingLine.SetRange(TotalWhseItemTrackingLine."Source Prod. Order Line", WhseWorksheetLine."Source Line No.");
                end;
            Database::"Whse. Worksheet Line",
            Database::"Warehouse Journal Line":
                begin
                    TotalWhseItemTrackingLine.SetSourceFilter(SourceType, -1, WhseWorksheetLine.Name, WhseWorksheetLine."Line No.", true);
                    TotalWhseItemTrackingLine.SetRange("Source Batch Name", WhseWorksheetLine."Worksheet Template Name");
                end;
        end;
        TotalWhseItemTrackingLine.CalcSums(TotalWhseItemTrackingLine."Quantity (Base)", TotalWhseItemTrackingLine."Qty. to Handle (Base)");
        exit(UpdateUndefinedQty(TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray));
    end;

    procedure UpdateUndefinedQty(TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceQuantityArray: array[2] of Decimal; var UndefinedQtyArray: array[2] of Decimal): Boolean
    begin
        UndefinedQtyArray[1] := SourceQuantityArray[1] - TotalWhseItemTrackingLine."Quantity (Base)";
        UndefinedQtyArray[2] := SourceQuantityArray[2] - TotalWhseItemTrackingLine."Qty. to Handle (Base)";
        exit(not (Abs(SourceQuantityArray[1]) < Abs(TotalWhseItemTrackingLine."Quantity (Base)")));
    end;

    local procedure InsertReservEntryForSalesLine(var ReservEntry: Record "Reservation Entry"; ItemLedgEntryBuf: Record "Item Ledger Entry"; SalesLine: Record "Sales Line"; QtyBase: Decimal; AppliedFromItemEntry: Boolean; var EntriesExist: Boolean)
    begin
        if QtyBase = 0 then
            exit;

        OnInsertReservEntryForSalesLineOnBeforeInitReservEntry(ItemLedgEntryBuf, SalesLine);
        InitReservEntry(ReservEntry, ItemLedgEntryBuf, QtyBase, SalesLine."Shipment Date", EntriesExist);
        ReservEntry.SetSource(
          Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", '', 0);
        if SalesLine."Document Type" in [SalesLine."Document Type"::Order, SalesLine."Document Type"::"Return Order"] then
            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus
        else
            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Prospect;
        if AppliedFromItemEntry then
            ReservEntry."Appl.-from Item Entry" := ItemLedgEntryBuf."Entry No.";
        ReservEntry.Description := SalesLine.Description;
        OnCopyItemLedgEntryTrkgToDocLine(ItemLedgEntryBuf, ReservEntry);
        ReservEntry.UpdateItemTracking();
        OnBeforeInsertReservEntryForSalesLine(ReservEntry, SalesLine, ItemLedgEntryBuf);
        ReservEntry.Insert();
        OnAfterInsertReservEntryForSalesLine(ReservEntry, SalesLine);
    end;

    local procedure InsertReservEntryForPurchLine(ItemLedgEntryBuf: Record "Item Ledger Entry"; PurchaseLine: Record "Purchase Line"; QtyBase: Decimal; AppliedToItemEntry: Boolean; var EntriesExist: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if QtyBase = 0 then
            exit;

        InitReservEntry(
            ReservEntry, ItemLedgEntryBuf, QtyBase, PurchaseLine."Expected Receipt Date", EntriesExist);
        ReservEntry.SetSource(
            Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.",
            PurchaseLine."Line No.", '', 0);
        if PurchaseLine."Document Type" in [PurchaseLine."Document Type"::Order, PurchaseLine."Document Type"::"Return Order"] then
            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus
        else
            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Prospect;
        if AppliedToItemEntry then
            ReservEntry."Appl.-to Item Entry" := ItemLedgEntryBuf."Entry No.";
        ReservEntry.Description := PurchaseLine.Description;
        OnCopyItemLedgEntryTrkgToDocLine(ItemLedgEntryBuf, ReservEntry);
        ReservEntry.UpdateItemTracking();
        OnBeforeInsertReservEntryForPurchLine(ReservEntry, PurchaseLine, ItemLedgEntryBuf);
        ReservEntry.Insert();
        OnAfterInsertReservEntryForPurchLine(ReservEntry, PurchaseLine);
    end;

    local procedure InsertReservEntryToOutboundTransferLine(var ReservEntry: Record "Reservation Entry"; ItemLedgEntryBuf: Record "Item Ledger Entry"; TransferLine: Record "Transfer Line"; QtyBase: Decimal; var EntriesExist: Boolean)
    begin
        if not ItemLedgEntryBuf.TrackingExists() or (QtyBase = 0) then
            exit;

        Clear(ReservEntry);
        InitReservEntry(ReservEntry, ItemLedgEntryBuf, QtyBase, TransferLine."Shipment Date", EntriesExist);
        ReservEntry.SetSource(Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", '', 0);
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
        ReservEntry.Description := TransferLine.Description;
        ReservEntry.UpdateItemTracking();
        OnInsertReservEntryToOutboundTransferLineOnBeforeReservationEntryInsert(ReservEntry, ItemLedgEntryBuf, TransferLine, QtyBase, EntriesExist);
        ReservEntry.Insert();
    end;

    procedure InsertReservEntryFromTrackingSpec(TrackingSpecification: Record "Tracking Specification"; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; QtyBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if QtyBase = 0 then
            exit;

        ReservEntry.Init();
        ReservEntry.TransferFields(TrackingSpecification);
        ReservEntry."Source Subtype" := SourceSubtype;
        ReservEntry."Source ID" := SourceID;
        ReservEntry."Source Ref. No." := SourceRefNo;
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Prospect;
        ReservEntry."Quantity Invoiced (Base)" := 0;
        ReservEntry.Validate(ReservEntry."Quantity (Base)", QtyBase);
        ReservEntry.Positive := (ReservEntry."Quantity (Base)" > 0);
        ReservEntry."Entry No." := 0;
        ReservEntry."Item Tracking" := ReservEntry.GetItemTrackingEntryType();
        OnInsertReservationEntryFromTrackingSpecOnBeforeInsert(ReservEntry, TrackingSpecification);
        ReservEntry.Insert();
    end;

    local procedure InitReservEntry(var ReservEntry: Record "Reservation Entry"; ItemLedgEntryBuf: Record "Item Ledger Entry"; QtyBase: Decimal; Date: Date; var EntriesExist: Boolean)
    begin
        ReservEntry.Init();
        ReservEntry."Item No." := ItemLedgEntryBuf."Item No.";
        ReservEntry."Location Code" := ItemLedgEntryBuf."Location Code";
        ReservEntry."Variant Code" := ItemLedgEntryBuf."Variant Code";
        ReservEntry."Qty. per Unit of Measure" := ItemLedgEntryBuf."Qty. per Unit of Measure";
        OnInitReservEntryOnBeforeCopyTrackingFromItemLedgEntry(ReservEntry, ItemLedgEntryBuf, EntriesExist);
        ReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgEntryBuf);
        ReservEntry."Quantity Invoiced (Base)" := 0;
        ReservEntry.Validate(ReservEntry."Quantity (Base)", QtyBase);
        ReservEntry.Positive := (ReservEntry."Quantity (Base)" > 0);
        ReservEntry."Entry No." := 0;
        if ReservEntry.Positive then begin
            ReservEntry."Warranty Date" := ItemLedgEntryBuf."Warranty Date";
            ReservEntry."Expiration Date" := ExistingExpirationDate(ItemLedgEntryBuf, false, EntriesExist);
            ReservEntry."Expected Receipt Date" := Date;
        end else
            ReservEntry."Shipment Date" := Date;
        ReservEntry."Creation Date" := WorkDate();
        ReservEntry."Created By" := UserId;

        OnAfterInitReservEntry(ReservEntry, ItemLedgEntryBuf);
    end;

    procedure DeleteInvoiceSpecFromHeader(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20])
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.SetSourceFilter(SourceType, SourceSubtype, SourceID, -1, false);
        TrackingSpecification.SetSourceFilter('', 0);
        TrackingSpecification.DeleteAll();
    end;

    procedure DeleteInvoiceSpecFromLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, false);
        TrackingSpecification.SetSourceFilter('', 0);
        TrackingSpecification.DeleteAll();
    end;

    local procedure IsReservedFromTransferShipment(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit((ReservEntry."Source Type" = Database::"Transfer Line") and (ReservEntry."Source Subtype" = 0));
    end;

    procedure ItemTrackingExistsOnDocumentLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer): Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        TrackingSpecification.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        TrackingSpecification.SetSourceFilter('', 0);
        TrackingSpecification.SetRange(Correction, false);
        ReservEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);

        OnItemTrackingExistsOnDocumentLineOnBeforeExit(TrackingSpecification, ReservEntry);
        if not TrackingSpecification.IsEmpty() then
            exit(true);
        exit(not ReservEntry.IsEmpty());
    end;

    procedure CalcQtyToHandleForTrackedQtyOnDocumentLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer) Result: Decimal
    var
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyToHandleForTrackedQtyOnDocumentLine(ReservEntry, IsHandled, SourceType, SourceSubtype, SourceID, SourceRefNo, Result);
        if IsHandled then
            exit(Result);

        ReservEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if SourceType = ProdOrderCompID() then
            ReservEntry.SetSourceFilter('', SourceProdOrderLineForFilter)
        else
            ReservEntry.SetSourceFilter('', 0);
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
        OnCalcQtyToHandleForTrackedQtyOnDocumentLineOnAfterReservEntrySetFilters(ReservEntry);
        ReservEntry.CalcSums("Qty. to Handle (Base)");
        exit(ReservEntry."Qty. to Handle (Base)");
    end;

    local procedure CheckQtyToInvoiceMatchItemTracking(var TempTrackingSpecSummedUp: Record "Tracking Specification" temporary; var TempTrackingSpecNotInvoiced: Record "Tracking Specification" temporary; QtyToInvoiceOnDocLine: Decimal; QtyPerUoM: Decimal)
    var
        NoOfLotsOrSerials: Integer;
        Sign: Integer;
        QtyToInvOnLineAndTrkgDiff: Decimal;
    begin
        TempTrackingSpecSummedUp.Reset();
        TempTrackingSpecSummedUp.SetFilter("Qty. to Invoice (Base)", '<>%1', 0);
        OnCheckQtyToInvoiceMatchItemTrackingOnAfterTempTrackingSpecSummedUpSetFilters(TempTrackingSpecSummedUp);
        NoOfLotsOrSerials := TempTrackingSpecSummedUp.Count();
        if NoOfLotsOrSerials = 0 then
            exit;

        TempTrackingSpecSummedUp.CalcSums("Qty. to Invoice (Base)");
        QtyToInvOnLineAndTrkgDiff := Abs(QtyToInvoiceOnDocLine) - Abs(TempTrackingSpecSummedUp."Qty. to Invoice (Base)");
        if QtyToInvOnLineAndTrkgDiff = 0 then
            exit;

        if ((NoOfLotsOrSerials > 1) and (QtyToInvOnLineAndTrkgDiff <> 0)) or
           ((NoOfLotsOrSerials = 1) and (QtyToInvOnLineAndTrkgDiff > 0))
        then
            Error(QtyToInvoiceDoesNotMatchItemTrackingErr);

        if TempTrackingSpecNotInvoiced.IsEmpty() then
            exit;

        if NoOfLotsOrSerials = 1 then begin
            QtyToInvoiceOnDocLine := Abs(QtyToInvoiceOnDocLine);
            TempTrackingSpecNotInvoiced.CalcSums("Qty. to Invoice (Base)");
            if QtyToInvoiceOnDocLine < Abs(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)") then begin
                TempTrackingSpecNotInvoiced.FindSet();
                repeat
                    if QtyToInvoiceOnDocLine >= Abs(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)") then
                        QtyToInvoiceOnDocLine -= Abs(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)")
                    else begin
                        Sign := 1;
                        if TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)" < 0 then
                            Sign := -1;

                        TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)" := QtyToInvoiceOnDocLine * Sign;
                        TempTrackingSpecNotInvoiced."Qty. to Invoice" :=
                          Round(TempTrackingSpecNotInvoiced."Qty. to Invoice (Base)" / QtyPerUoM, UOMMgt.QtyRndPrecision());
                        TempTrackingSpecNotInvoiced.Modify();

                        QtyToInvoiceOnDocLine := 0;
                    end;
                until TempTrackingSpecNotInvoiced.Next() = 0;
            end;
        end;
    end;

    local procedure GetItemTrackingCode(ItemNo: Code[20]; var ItemTrackingCode: Record "Item Tracking Code")
    begin
        if CachedItem."No." <> ItemNo then begin
            // searching for a new item, clear the cached item
            Clear(CachedItem);

            // get the item from the database
            if CachedItem.Get(ItemNo) then begin
                if CachedItem."Item Tracking Code" <> CachedItemTrackingCode.Code then
                    Clear(CachedItemTrackingCode); // item tracking code changed, clear the cached tracking code

                if CachedItem."Item Tracking Code" <> '' then
                    // item tracking code changed to something not empty, so get the new item tracking code from the database
                    CachedItemTrackingCode.Get(CachedItem."Item Tracking Code");
            end else
                Clear(CachedItemTrackingCode); // can't find the item, so clear the cached tracking code as well
        end;

        ItemTrackingCode := CachedItemTrackingCode;
    end;

    local procedure GetPutAwayQtyOrPickQtyBaseForProdOrder(
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        ActionType: Enum "Warehouse Action Type"): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Whse. Document Type", WhseItemTrkgLine."Source Type Filter");
        WarehouseActivityLine.SetRange("Whse. Document No.", WhseItemTrkgLine."Source ID");
        WarehouseActivityLine.Setrange("Whse. Document Line No.", WhseItemTrkgLine."Source Prod. Order Line");
        WarehouseActivityLine.SetRange("Source Subline No.", WhseItemTrkgLine."Source Ref. No.");
        WarehouseActivityLine.SetRange("Serial No.", WhseItemTrkgLine."Serial No.");
        WarehouseActivityLine.SetRange("Lot No.", WhseItemTrkgLine."Lot No.");
        WarehouseActivityLine.SetRange("Package No.", WhseItemTrkgLine."Package No.");
        WarehouseActivityLine.SetRange("Item No.", WhseItemTrkgLine."Item No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    [Scope('OnPrem')]
    procedure CopyExpirationDateForLot(var TrackingSpecification: Record "Tracking Specification")
    var
        CurrTrackingSpec: Record "Tracking Specification";
    begin
        if TrackingSpecification."Lot No." = '' then
            exit;

        CurrTrackingSpec.Copy(TrackingSpecification);

        TrackingSpecification.SetFilter(TrackingSpecification."Entry No.", '<>%1', TrackingSpecification."Entry No.");
        TrackingSpecification.SetRange(TrackingSpecification."Item No.", TrackingSpecification."Item No.");
        TrackingSpecification.SetRange(TrackingSpecification."Variant Code", TrackingSpecification."Variant Code");
        TrackingSpecification.SetRange(TrackingSpecification."Lot No.", TrackingSpecification."Lot No.");
        TrackingSpecification.SetRange(TrackingSpecification."Buffer Status", 0);
        if TrackingSpecification.FindFirst() then
            CurrTrackingSpec."Expiration Date" := TrackingSpecification."Expiration Date";

        TrackingSpecification.Copy(CurrTrackingSpec);
    end;

    [Scope('OnPrem')]
    procedure UpdateExpirationDateForLot(var TrackingSpecification: Record "Tracking Specification")
    var
        CurrTrackingSpec: Record "Tracking Specification";
    begin
        if TrackingSpecification."Lot No." = '' then
            exit;

        CurrTrackingSpec.Copy(TrackingSpecification);

        TrackingSpecification.SetFilter("Entry No.", '<>%1', TrackingSpecification."Entry No.");
        TrackingSpecification.SetRange("Item No.", TrackingSpecification."Item No.");
        TrackingSpecification.SetRange("Variant Code", TrackingSpecification."Variant Code");
        TrackingSpecification.SetRange("Lot No.", TrackingSpecification."Lot No.");
        TrackingSpecification.SetFilter("Expiration Date", '<>%1', TrackingSpecification."Expiration Date");
        TrackingSpecification.SetRange("Buffer Status", 0);
        TrackingSpecification.ModifyAll("Expiration Date", CurrTrackingSpec."Expiration Date");

        TrackingSpecification.Copy(CurrTrackingSpec);
    end;

    procedure CreateSerialNoInformation(TrackingSpecification: Record "Tracking Specification")
    var
        SerialNoInfo: Record "Serial No. Information";
        SerialNumber: Code[50];
    begin
        if TrackingSpecification."New Serial No." <> '' then
            SerialNumber := TrackingSpecification."New Serial No."
        else
            if TrackingSpecification."Serial No." <> '' then
                SerialNumber := TrackingSpecification."Serial No.";

        if SerialNumber <> '' then
            if not SerialNoInfo.Get(TrackingSpecification."Item No.", TrackingSpecification."Variant Code", SerialNumber) then begin
                SerialNoInfo.Init();
                SerialNoInfo.Validate("Item No.", TrackingSpecification."Item No.");
                SerialNoInfo.Validate("Variant Code", TrackingSpecification."Variant Code");
                SerialNoInfo.Validate("Serial No.", SerialNumber);
                SerialNoInfo.Insert(true);
                OnAfterCreateSNInformation(SerialNoInfo, TrackingSpecification);
            end;
    end;

    procedure CreateLotNoInformation(TrackingSpecification: Record "Tracking Specification")
    var
        LotNoInfo: Record "Lot No. Information";
        LotNumbers: List of [Code[50]];
        LotNumber: Code[50];
    begin
        if TrackingSpecification."Lot No." <> '' then
            LotNumbers.Add(TrackingSpecification."Lot No.");

        if TrackingSpecification."New Lot No." <> '' then
            LotNumbers.Add(TrackingSpecification."New Lot No.");

        foreach LotNumber in LotNumbers do
            if not LotNoInfo.Get(TrackingSpecification."Item No.", TrackingSpecification."Variant Code", LotNumber) then begin
                LotNoInfo.Init();
                LotNoInfo.Validate("Item No.", TrackingSpecification."Item No.");
                LotNoInfo.Validate("Variant Code", TrackingSpecification."Variant Code");
                LotNoInfo.Validate("Lot No.", LotNumber);
                LotNoInfo.Insert(true);
                OnAfterCreateLotInformation(LotNoInfo, TrackingSpecification);
            end;
    end;

    local procedure GetQtyBaseFromShippedQtyNotReturned(ShippedQtyNotReturned: Decimal; SignFactor: Integer; ToSalesLine: Record "Sales Line") Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetQtyBaseFromShippedQtyNotReturned(ShippedQtyNotReturned, ToSalesLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ShippedQtyNotReturned * SignFactor;
    end;

    local procedure SynchronizeWhseActivItemTrackingReservation(WhseActivLine: Record "Warehouse Activity Line"; IsTransferReceipt: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if not (WhseActivLine."Source Type" = ProdOrderLineID()) and (WhseActivLine."Source Subtype" = 3) then
            exit;

        ReservEntry.SetSourceFilter(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", 0, true);
        ReservEntry.SetSourceFilter('', WhseActivLine."Source Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        if IsTransferReceipt then
            ReservEntry.SetRange("Source Ref. No.");
        if ReservEntry.FindSet() then
            repeat
                WhseActivLine.Reset();
                WhseActivLine.SetSourceFilter(
                    WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.",
                    WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", true);
                WhseActivLine.SetTrackingFilterFromReservEntry(ReservEntry);
                if WhseActivLine.IsEmpty() then begin
                    ReservEntry.Validate("Qty. to Handle (Base)", 0);
                    ReservEntry.Validate("Qty. to Invoice (Base)", 0);
                    ReservEntry.Modify(true);
                end;
            until ReservEntry.Next() = 0;
    end;

    local procedure AssemblyHeaderID(): Integer
    begin
        exit(900);
    end;

    local procedure AssemblyLineID(): Integer
    begin
        exit(901);
    end;

    local procedure ProdOrderLineID(): Integer
    begin
        exit(5406);
    end;

    local procedure ProdOrderCompID(): Integer
    begin
        exit(5407);
    end;

    local procedure CalcQtyBaseShipped(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"): Decimal
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if (RegisteredWhseActivityLine."Whse. Document No." = '') or (RegisteredWhseActivityLine."Whse. Document Line No." = 0) then
            exit(0);

        WarehouseShipmentLine.SetLoadFields("Qty. Shipped (Base)");
        if WarehouseShipmentLine.Get(RegisteredWhseActivityLine."Whse. Document No.", RegisteredWhseActivityLine."Whse. Document Line No.") then
            exit(WarehouseShipmentLine."Qty. Shipped (Base)");

        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyHandledItemTrkgToInvLine(FromSalesLine: Record "Sales Line"; var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemLedgEntryTrkgToPurchLn(var ItemLedgerEntryBuffer: Record "Item Ledger Entry"; ToPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemLedgEntryTrkgToSalesLn(var TempItemLedgerEntryBuffer: Record "Item Ledger Entry" temporary; ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestExpDateOnTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPostedWhseReceiptLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseExpirationDate(ItemNo: Code[20]; VariantCode: Code[20]; Location: Record Location; LotNo: Code[50]; SerialNo: Code[50]; var ExpDate: Date; var ExpDateFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertReservEntryForPurchLine(var ReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertReservEntryForSalesLine(var ReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertWhseItemTrkgLinesLoop(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemTrkgTypeIsManagedByWhse(Type: Integer; var TypeIsManagedByWhse: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRetrieveAppliedExpirationDate(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSynchronizeItemTracking(var ReservationEntry: Record "Reservation Entry"; ToRowID: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyToHandleForTrackedQtyOnDocumentLine(var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean; SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseItemTrkg(var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary; WhseWkshLine: Record "Whse. Worksheet Line"; var Checked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrkgInfBeforePost(var TempGlobalWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseItemTrkgForReceipt(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWkshLine: Record "Whse. Worksheet Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseItemTrkgForResEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceReservEntry: Record "Reservation Entry"; WhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExistingExpirationDate(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; TestMultiple: Boolean; var EntriesExist: Boolean; var ExpDate: Date; var IsHandled: Boolean; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExistingExpirationDateAndQty(ItemNo: Code[20]; Variant: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; SumOfEntries: Decimal; var ExpDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTempHandlingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitItemTrackingForTempWhseWorksheetLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemTrkgIsManagedByWhse(Type: Integer; Subtype: Integer; ID: Code[20]; ProdOrderLine: Integer; RefNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReservEntryForPurchLine(var ReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReservEntryForSalesLine(var ReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSplitPostedWhseRcptLine(var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSplitInternalPutAwayLine(var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySplitPostedWhseRcptLine(var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterNewItemTrackingLines(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

#if not CLEAN26
    internal procedure RunOnBeforeRetrieveSubcontrItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeRetrieveSubcontrItemTracking(ItemJnlLine, TempHandlingSpecification, Result, IsHandled);
    end;

    [Obsolete('Moved to codeunit Mfg. Item Tracking Mgt.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveSubcontrItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSumUpItemTracking(var ReservEntry: Record "Reservation Entry"; var TempHandlingSpecification: Record "Tracking Specification" temporary; var SumPerLine: Boolean; var SumPerTracking: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecSummedUpModify(var TempTrackingSpecSummedUp: Record "Tracking Specification" temporary; var TempInvoicingTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseJnlLine2Insert(var TempWhseJnlLineTo: Record "Warehouse Journal Line" temporary; TempWhseJnlLineFrom: Record "Warehouse Journal Line" temporary; var TempSplitTrackingSpec: Record "Tracking Specification" temporary; TransferTo: Boolean; WhseSNRequired: Boolean; WhseLNRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempHandlingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservationEntry: Record "Reservation Entry"; var ItemTrackingCode: Record "Item Tracking Code"; var EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseExistingExpirationDate(ItemNo: Code[20]; Variant: Code[20]; Location: Record Location; LotNo: Code[50]; SerialNo: Code[50]; var EntriesExist: Boolean; var ExpDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseItemTrackingLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcWhseItemTrkgLineOnAfterCalcBaseQuantities(var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyToHandleForTrackedQtyOnDocumentLineOnAfterReservEntrySetFilters(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyHandledItemTrkgToInvLineOnBeforeInsertProspectReservEntry(var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyLotNoInformationOnBeforeNewLotNoInfoInsert(var NewLotNoInfo: Record "Lot No. Information"; LotNoInfo: Record "Lot No. Information")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncActivItemTrkgOnBeforeInsertTempReservEntry(var TempReservEntry: Record "Reservation Entry" temporary; WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncActivItemTrkgOnBeforeTempTrackingSpecModify(var TrackingSpecification: Record "Tracking Specification"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupTrackingNoInfo(ItemNo: Code[20]; Variant: Code[20]; ItemTrackingType: Enum "Item Tracking Type"; ItemTrackingNo: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseItemTrkgLines(var WhseItemTrkgLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyWhseItemTrkgLines(var WhseItemTrkgLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterItemTrackingLinesLoop(var TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveAppliedExpirationDate(var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseItemTrkgLinesLoop(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemTracking3OnAfterSwapSign(var TempReservEntry: Record "Reservation Entry" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemTracking3OnAfterTempReservEntryInsert(var TempReservEntry: Record "Reservation Entry" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrkgInfBeforePostOnBeforeTempItemLotInfoInsert(var TempLotNoInfo: Record "Lot No. Information" temporary; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckQtyToInvoiceMatchItemTrackingOnAfterTempTrackingSpecSummedUpSetFilters(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemLedgEntryTrkgToDocLine(var ItemLedgerEntry: Record "Item Ledger Entry"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemLedgEntryTrkgToSalesLnOnBeforeTempItemLedgEntryBufFindSet(var TempItemLedgEntryBuf: Record "Item Ledger Entry" temporary; ToSalesLine: Record "Sales Line"; FillExactCostRevLink: Boolean; var MissingExCostRevLink: Boolean; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; FromShptOrRcpt: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemLedgEntryTrkgToSalesLnOnbeforeToSalesLineInsert(var ToSalesLine: Record "Sales Line"; var TempItemLedgEntryBuf: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseItemTrackingBatchOnBeforeCreateWhseItemTrackingLines(WhseWkshLine: Record "Whse. Worksheet Line"; var SourceReservEntry: Record "Reservation Entry"; SourceType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsOrderNetworkEntity(Type: Integer; Subtype: Integer; var IsNetworkEntity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReservEntryOnBeforeCopyTrackingFromItemLedgEntry(var ReservEntry: Record "Reservation Entry"; var ItemLedgEntryBuf: Record "Item Ledger Entry"; var EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTrackingSpecificationOnBeforeCalcWhseItemTrackingLines(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReservationEntryFromTrackingSpecOnBeforeInsert(var ReservEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemTrackingSettings(var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemTrackingSetup(var ItemTrackingCode: Record "Item Tracking Code"; var ItemTrackingSetup: Record "Item Tracking Setup"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReservEntry(var ReservEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReserveEntryFilter(ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitInternalPutAwayLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveItemTrackingFromReservEntryFilter(var ReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveItemTrackingFromReservEntryOnAfterDeleteReservEntries(var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemJnlLine: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

#if not CLEAN26
    internal procedure RunOnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(var TempHandlingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
        OnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(TempHandlingSpecification, ReservationEntry);
    end;

    [Obsolete('Moved to codeunit Mfg. Item Tracking Mgt.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(var TempHandlingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnRetrieveConsumpItemTrackingOnAfterSetFilters(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        OnRetrieveConsumpItemTrackingOnAfterSetFilters(ReservationEntry, ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit Mfg. Item Tracking Mgt.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnRetrieveConsumpItemTrackingOnAfterSetFilters(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSynchronizeItemTracking2(FromReservEntry: Record "Reservation Entry"; ReservEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseJnlLine2: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitPostedWhseReceiptLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseActivItemTrkgOnAfterSetExpirationDate(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseActivItemTrkgOnAfterSetToRowID(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ToRowID: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTempPostedWhseRcptLineSetFilters(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; ItemLedgerEntry: Record "Item Ledger Entry"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
    end;

#if not CLEAN26
    internal procedure RunOnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
        OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine, IsLastOperation);
    end;

    [Obsolete('Moved to codeunit Mfg. Item Tracking Mgt.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSplitWhseJnlLineOnAfterCheckWhseItemTrkgSetup(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseSplitTrackingSpec: Record "Tracking Specification" temporary; var WhseSNRequired: Boolean; var WhseLNRequired: Boolean; var TempWhseJnlLine2: Record "Warehouse Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitWhseJnlLineOnBeforeCheckSerialNo(var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseItemTrkgSetupOnAfterItemTrackingCodeGet(var ItemTrackingCode: Record "Item Tracking Code"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitWhseJnlLineOnAfterSetFilters(var TempWhseSplitTrackingSpec: Record "Tracking Specification" temporary; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCollectItemEntryRelation(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; TotalQty: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemTracking3(var ReservEntry: Record "Reservation Entry"; ToRowID: Text[250]; SwapSign: Boolean; SkipReservation: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCopyHandledItemTrkgToInvLine(FromSalesLine: Record "Sales Line"; var ToSalesInvLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterNewItemTrackingLinesOnAfterClearItemTrackingLines(var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterNewItemTrackingLinesOnBeforeRegisterItemTrackingLines(var TempTrackingSpecification: Record "Tracking Specification"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitWhseJnlLineOnAfterCopyTrackingByToTransfer(var TempWhseSplitTrackingSpec: Record "Tracking Specification"; var TempWhseJnlLine2: Record "Warehouse Journal Line"; ToTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectItemTrkgInfWhseJnlLineOnAfterSetFilters(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSNInformation(var SerialNoInfo: Record "Serial No. Information"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLotInformation(var LotNoInfo: Record "Lot No. Information"; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseActivItemTrkgOnAfterAssignAbsQty(var TempTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWhseItemTrkgSetup(ItemNo: Code[20]; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLastItemLedgerEntry(ItemNo: Code[20]; VariantCode: Code[20]; ItemTrackingSetup: Record "Item Tracking Setup"; var ItemLedgEntry: Record "Item Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetQtyBaseFromShippedQtyNotReturned(ShippedQtyNotReturned: Decimal; ToSalesLine: Record "Sales Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempReservEntrySetIfTransfer(var TempReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReservEntryForSalesLineOnBeforeInitReservEntry(var ItemLedgEntryBuf: Record "Item Ledger Entry"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveItemTrkgFromReservEntryOnAfterReservEntryLoop(var ReservEntry: Record "Reservation Entry"; OriginalReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronizeWhseItemTracking(var TempTrackingSpecification: Record "Tracking Specification" temporary; RegPickNo: Code[20]; Deletion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseItemTrackingOnAfterTempTrackingSpecificationLoop(var TempTrackingSpecification: Record "Tracking Specification" temporary; RegPickNo: Code[20]; Deletion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseItemTrackingOnBeforeReservEntryModify(var ReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary; RegPickNo: Code[20]; Deletion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseItemTrackingOnAfterZeroQtyToHandleLoop(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseItemTrackingOnAfterUpdateReservEntryForPick(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeItemTracking2OnAfterCalcShouldInsertTrkgSpec(var TempTrkgSpec1: Record "Tracking Specification" temporary; var TempTrkgSpec2: Record "Tracking Specification" temporary; var TempTrkgSpec3: Record "Tracking Specification" temporary; SignFactor1: Integer; SignFactor2: Integer; var ShouldInsertTrkgSpec: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeItemTracking2OnAfterSyncBothTrackingSpec(var TempTrkgSpec3: Record "Tracking Specification" temporary; TempTrkgSpec2: Record "Tracking Specification" temporary; TempSourceSpec: Record "Tracking Specification" temporary; var TempTrkgSpec1: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeItemTracking2OnAfterAssignNewTrackingSpec(var TempTrkgSpec3: Record "Tracking Specification" temporary; TempTrkgSpec1: Record "Tracking Specification" temporary; TempSourceSpec: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeItemTracking2OnBeforeDeleteSyncedTrackingSpec(var TempTrkgSpec3: Record "Tracking Specification" temporary; TempTrkgSpec1: Record "Tracking Specification" temporary; TempTrkgSpec2: Record "Tracking Specification" temporary; SignFactor1: Integer; SignFactor2: Integer; var LastEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeItemTrkgTransferOnAfterTempToReservEntrySetFilters(var TempToReservEntry: Record "Reservation Entry" temporary; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeItemTrkgTransferOnBeforeToReservEntryModifyAll(var ToReservEntry: Record "Reservation Entry"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackingExistsOnDocumentLineOnBeforeExit(var TrackingSpecification: Record "Tracking Specification"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestExpDateOnTrackingSpecNew(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestExpDateOnTrackingSpecNew(var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseItemTrkgLineExistsOnBeforeExit(var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumUpItemTrackingOnBeforeTempHandlingSpecificationModify(var TempHandlingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyHandledItemTrkgToPurchLineOnAfterFilterItemEntryRelation(var ItemEntryRelation: Record "Item Entry Relation"; var FromPurchLine: Record "Purchase Line"; var ToPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveInvoiceSpecificationOnBeforeFindTrackingSpecification(var TempInvoicingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecSummedUp: Record "Tracking Specification" temporary; TrackingSpecification: Record "Tracking Specification"; SourceSpecification: Record "Tracking Specification"; var OK: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCopyHandledItemTrkgToPurchLine(FromPurchLine: Record "Purchase Line"; var ToPurchLine: Record "Purchase Line"; CheckLineQty: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopyItemTracking3OnBeforeReservEntry1Insert(var ReservEntry1: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveInvoiceSpecificationOnAfterTrackingSpecificationSetFilters(SourceSpecification: Record "Tracking Specification"; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitInternalPutAwayLineOnNotFindWhseItemTrackingLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError(var TempTrackingSpecification: Record "Tracking Specification" temporary; var QtyToHandleToNewRegister: Decimal; var QtyToHandleInItemTracking: Decimal; var QtyToHandleOnSourceDocLine: Decimal; var IsHandled: Boolean; var AllowWhseOverpick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeItemTracking2OnBeforeRegisterItemTrackingLines(var ItemTrackingLines: Page "Item Tracking Lines"; var TempSourceSpec: Record "Tracking Specification" temporary; var TempTrkgSpec3: Record "Tracking Specification" temporary; var FromReservEntry: Record "Reservation Entry"; ReservEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindInInventoryOnAfterItemLedgerEntrySetFilters(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReservEntryToOutboundTransferLineOnBeforeReservationEntryInsert(var ReservationEntry: Record "Reservation Entry"; var ItemLedgerEntryBuf: Record "Item Ledger Entry"; var TransferLine: Record "Transfer Line"; QtyBase: Decimal; var EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseDocType: Enum "Warehouse Worksheet Document Type"; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsResEntryReservedAgainstInventory(ReservationEntry: Record "Reservation Entry"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveItemTrackingFromReservEntry(ItemJnlLine: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"; var TempTrackingSpec: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSynchronizeWhseActivItemTrkgAssembly(var WhseActivLine: Record "Warehouse Activity Line"; var ToRowID: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTrackingSpecificationByDocumentType(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTrackingSpecificationOnCreateNew(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcWhseItemTrkgLineOnSetSourceTypeFilter(var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnGetItemTrackingSetupOnSetSerialNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnGetItemTrackingSetupOnSetLotNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnGetItemTrackingSetupOnSetPackageNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
    end;
}