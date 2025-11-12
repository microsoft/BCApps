// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

codeunit 6520 "Item Tracing Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TempItemTracingBuffer: Record "Item Tracing Buffer" temporary;
        TempItemTracingHistoryBuffer: Record "Item Tracing History Buffer" temporary;
        SearchCriteria: Option "None",Lot,Serial,Both,Item,Package;
        TempLineNo: Integer;
        CurrentLevel: Integer;
        NextLineNo: Integer;
        CurrentHistoryEntryNo: Integer;

    procedure FindRecords(var TempTrackEntry: Record "Item Tracing Buffer"; var TempTrackEntry2: Record "Item Tracing Buffer"; SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text; Direction: Option Forward,Backward; ShowComponents: Option No,"Item-tracked only",All)
    begin
        DeleteTempTables(TempTrackEntry, TempTrackEntry2);
        InitSearchCriteria(SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter);
        FirstLevel(TempTrackEntry, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter, Direction, ShowComponents);
        OnFindRecordsOnBeforeInitTempTable(TempTrackEntry, Direction, ShowComponents);
        if TempLineNo > 0 then
            InitTempTable(TempTrackEntry, TempTrackEntry2);
        TempTrackEntry.Reset();
        UpdateHistory(SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter, Direction, ShowComponents);
    end;

    local procedure FirstLevel(var TempTrackEntry: Record "Item Tracing Buffer"; SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text; Direction: Option Forward,Backward; ShowComponents: Option No,"Item-tracked only",All)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        TempLineNo := 0;
        CurrentLevel := 0;

        ItemLedgEntry.Reset();
        case SearchCriteria of
            SearchCriteria::None:
                exit;
            SearchCriteria::Serial:
                if not ItemLedgEntry.SetCurrentKey("Serial No.") then
                    if ItemNoFilter <> '' then
                        ItemLedgEntry.SetCurrentKey("Item No.", "Entry No.")
                    else
                        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive,
                          "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.");
            SearchCriteria::Lot,
            SearchCriteria::Package,
            SearchCriteria::Both:
                if not ItemLedgEntry.SetCurrentKey("Lot No.") then
                    if ItemNoFilter <> '' then
                        ItemLedgEntry.SetCurrentKey("Item No.", "Entry No.")
                    else
                        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive,
                          "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.");
            SearchCriteria::Item:
                ItemLedgEntry.SetCurrentKey("Item No.", "Entry No.");
        end;
        OnFirstLevelOnAfterItemLedgEntrySetCurrentKey(ItemLedgEntry);
        ItemLedgEntry.SetFilter("Lot No.", LotNoFilter);
        ItemLedgEntry.SetFilter("Serial No.", SerialNoFilter);
        ItemLedgEntry.SetFilter("Package No.", PackageNoFilter);
        ItemLedgEntry.SetFilter("Item No.", ItemNoFilter);
        ItemLedgEntry.SetFilter("Variant Code", VariantFilter);
        if Direction = Direction::Forward then begin
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetFilter("Entry Type", '<>%1', ItemLedgEntry."Entry Type"::Consumption);
        end;


        OnFirstLevelOnAfterSetLedgerEntryFilters(ItemLedgEntry, SerialNoFilter, LotNoFilter, ItemNoFilter);

        Clear(TempItemTracingBuffer);
        TempItemTracingBuffer.DeleteAll();
        NextLineNo := 0;
        if ItemLedgEntry.FindSet() then
            repeat
                NextLineNo += 1;
                TempItemTracingBuffer."Line No." := NextLineNo;
                TempItemTracingBuffer."Item No." := ItemLedgEntry."Item No.";
                TempItemTracingBuffer.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                TempItemTracingBuffer."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
                OnFirstLevelOnBeforeInsertFirstLevelEntry(TempItemTracingBuffer, ItemLedgEntry);
                TempItemTracingBuffer.Insert();
            until ItemLedgEntry.Next() = 0;

        case SearchCriteria of
            SearchCriteria::None:
                exit;
            SearchCriteria::Serial:
                TempItemTracingBuffer.SetCurrentKey("Serial No.", "Item Ledger Entry No.");
            SearchCriteria::Lot,
            SearchCriteria::Both:
                TempItemTracingBuffer.SetCurrentKey("Lot No.", "Item Ledger Entry No.");
            SearchCriteria::Item:
                TempItemTracingBuffer.SetCurrentKey("Item No.", "Item Ledger Entry No.");
            SearchCriteria::Package:
                TempItemTracingBuffer.SetCurrentKey("Item No.", "Item Ledger Entry No.");
        end;
        OnFirstLevelOnAfterTempItemTracingBufferSetCurrentKey(TempItemTracingBuffer);

        TempItemTracingBuffer.Ascending(Direction = Direction::Forward);
        if TempItemTracingBuffer.Find('-') then
            repeat
                ItemLedgEntry.Get(TempItemTracingBuffer."Item Ledger Entry No.");
                if ItemLedgEntry.TrackingExists() then begin
                    ItemLedgEntry2 := ItemLedgEntry;

                    // Test for Reclass
                    if (Direction = Direction::Backward) and
                       (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer) and
                       not ItemLedgEntry.Positive
                    then begin
                        ItemApplnEntry.Reset();
                        ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.");
                        ItemApplnEntry.SetRange("Outbound Item Entry No.", ItemLedgEntry2."Entry No.");
                        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
                        ItemApplnEntry.SetRange("Transferred-from Entry No.", 0);
                        if ItemApplnEntry.FindFirst() then begin
                            ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgEntry2."Entry No.");
                            ItemApplnEntry.SetRange("Transferred-from Entry No.", ItemApplnEntry."Inbound Item Entry No.");
                            if ItemApplnEntry.FindFirst() then begin
                                ItemLedgEntry2.Reset();
                                if not ItemLedgEntry2.Get(ItemApplnEntry."Item Ledger Entry No.") then
                                    ItemLedgEntry2 := ItemLedgEntry;
                            end;
                        end;
                    end;

                    if SearchCriteria = SearchCriteria::Item then
                        ItemLedgEntry2.SetRange("Item No.", ItemLedgEntry."Item No.");
                    if SearchCriteria = SearchCriteria::Package then
                        ItemLedgEntry2.SetRange("Package No.", ItemLedgEntry."Package No.");

                    OnFirstLevelOnBeforeTransferData(ItemLedgEntry, ItemLedgEntry2);
                    TransferData(ItemLedgEntry2, TempTrackEntry);
                    OnFirstLevelOnAfterTransferData(TempTrackEntry);

                    if InsertRecord(TempTrackEntry, 0) then begin
                        FindComponents(ItemLedgEntry2, TempTrackEntry, Direction, ShowComponents, ItemLedgEntry2."Entry No.");
                        NextLevel(TempTrackEntry, TempTrackEntry, Direction, ShowComponents, ItemLedgEntry2."Entry No.");
                    end;
                end;
            until (TempItemTracingBuffer.Next() = 0) or (CurrentLevel > 50);
    end;

    procedure NextLevel(var TempTrackEntry: Record "Item Tracing Buffer"; TempTrackEntry2: Record "Item Tracing Buffer"; Direction: Option Forward,Backward; ShowComponents: Option No,"Item-tracked only",All; ParentID: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        TempTrackEntryBuffer: Record "Item Tracing Buffer" temporary;
        TrackNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNextLevel(TempTrackEntry, TempTrackEntry2, Direction, ShowComponents, ParentID, CurrentLevel, TempLineNo, IsHandled);
        if IsHandled then
            exit;

        if ExitLevel(TempTrackEntry) then
            exit;
        CurrentLevel += 1;

        ItemApplnEntry.Reset();
        // Test for if we have reached lowest level possible - if so exit
        if (Direction = Direction::Backward) and TempTrackEntry2.Positive then begin
            ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ItemApplnEntry.SetRange("Inbound Item Entry No.", TempTrackEntry2."Item Ledger Entry No.");
            ItemApplnEntry.SetRange("Item Ledger Entry No.", TempTrackEntry2."Item Ledger Entry No.");
            ItemApplnEntry.SetRange("Outbound Item Entry No.", 0);
            if ItemApplnEntry.Find('-') then begin
                CurrentLevel -= 1;
                exit;
            end;
            ItemApplnEntry.Reset();
        end;

        if TempTrackEntry2.Positive then begin
            ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ItemApplnEntry.SetRange("Inbound Item Entry No.", TempTrackEntry2."Item Ledger Entry No.");
        end else begin
            ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.");
            ItemApplnEntry.SetRange("Outbound Item Entry No.", TempTrackEntry2."Item Ledger Entry No.");
        end;

        if Direction = Direction::Forward then
            ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', TempTrackEntry2."Item Ledger Entry No.")
        else
            ItemApplnEntry.SetRange("Item Ledger Entry No.", TempTrackEntry2."Item Ledger Entry No.");

        ItemApplnEntry.Ascending(Direction = Direction::Forward);
        if ItemApplnEntry.Find('-') then
            repeat
                if TempTrackEntry2.Positive then
                    TrackNo := ItemApplnEntry."Outbound Item Entry No."
                else
                    TrackNo := ItemApplnEntry."Inbound Item Entry No.";

                if TrackNo <> 0 then
                    if ItemLedgEntry.Get(TrackNo) then begin
                        TransferData(ItemLedgEntry, TempTrackEntry);
                        OnNextLevelOnAfterTransferData(TempTrackEntry, TempTrackEntry2);
                        if InsertRecord(TempTrackEntry, ParentID) then begin
                            TempTrackEntryBuffer := TempTrackEntry;
                            FindComponents(ItemLedgEntry, TempTrackEntry, Direction, ShowComponents, ItemLedgEntry."Entry No.");
                            TempTrackEntry := TempTrackEntryBuffer;
                            NextLevel(TempTrackEntry, TempTrackEntry, Direction, ShowComponents, ItemLedgEntry."Entry No.");
                        end;
                    end;
            until (TrackNo = 0) or (ItemApplnEntry.Next() = 0);
        CurrentLevel -= 1;
    end;

    procedure FindComponents(var ItemLedgEntry2: Record "Item Ledger Entry"; var TempItemTracingBuffer: Record "Item Tracing Buffer" temporary; Direction: Option Forward,Backward; ShowComponents: Option No,"Item-tracked only",All; ParentID: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindComponents(ItemLedgEntry2, TempItemTracingBuffer, Direction, ShowComponents, ParentID, CurrentLevel, TempLineNo, IsHandled);
        if IsHandled then
            exit;

        if ((ItemLedgEntry2."Order Type" <> ItemLedgEntry2."Order Type"::Production) and (ItemLedgEntry2."Order Type" <> ItemLedgEntry2."Order Type"::Assembly)) or (ItemLedgEntry2."Order No." = '') then
            exit;

        if (((ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Consumption) or (ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::"Assembly Consumption")) and
            (Direction = Direction::Forward)) or
           (((ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Output) or (ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::"Assembly Output")) and
            (Direction = Direction::Backward))
        then begin
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetCurrentKey("Order Type", "Order No.");
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry2."Order Type");
            ItemLedgEntry.SetRange("Order No.", ItemLedgEntry2."Order No.");
            if ItemLedgEntry2."Order Type" = ItemLedgEntry2."Order Type"::Production then
                ItemLedgEntry.SetRange("Order Line No.", ItemLedgEntry2."Order Line No.");
            if ItemLedgEntry2."Order Type" = ItemLedgEntry2."Order Type"::Assembly then
                ItemLedgEntry.SetRange("Document No.", ItemLedgEntry2."Document No.");
            ItemLedgEntry.SetFilter("Entry No.", '<>%1', ParentID);
            if (ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Consumption) or (ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::"Assembly Consumption") then begin
                if ShowComponents <> ShowComponents::No then begin
                    ItemLedgEntry.SetFilter("Entry Type", '%1|%2', ItemLedgEntry."Entry Type"::Consumption,
                      ItemLedgEntry."Entry Type"::"Assembly Consumption");
                    if ItemLedgEntry.Find('-') then
                        repeat
                            if (ShowComponents = ShowComponents::All) or ItemLedgEntry.TrackingExists() then begin
                                CurrentLevel += 1;
                                TransferData(ItemLedgEntry, TempItemTracingBuffer);
                                OnFindComponentsOnAfterTransferData(TempItemTracingBuffer, ItemLedgEntry2, ItemLedgEntry);
                                if InsertRecord(TempItemTracingBuffer, ParentID) then
                                    NextLevel(TempItemTracingBuffer, TempItemTracingBuffer, Direction, ShowComponents, ItemLedgEntry."Entry No.");
                                CurrentLevel -= 1;
                            end;
                        until ItemLedgEntry.Next() = 0;
                end;
                ItemLedgEntry.SetFilter("Entry Type", '%1|%2', ItemLedgEntry."Entry Type"::Output,
                  ItemLedgEntry."Entry Type"::"Assembly Output");
                ItemLedgEntry.SetRange(Positive, true);
            end else begin
                if ShowComponents = ShowComponents::No then
                    exit;
                ItemLedgEntry.SetFilter("Entry Type", '%1|%2', ItemLedgEntry."Entry Type"::Consumption,
                  ItemLedgEntry."Entry Type"::"Assembly Consumption");
                ItemLedgEntry.SetRange(Positive, not ItemLedgEntry2.Positive);
            end;
            OnFindComponentsOnAfterSetFilters(ItemLedgEntry, ItemLedgEntry2);
            CurrentLevel += 1;
            if ItemLedgEntry.Find('-') then
                repeat
                    if (ShowComponents = ShowComponents::All) or ItemLedgEntry.TrackingExists() then begin
                        TransferData(ItemLedgEntry, TempItemTracingBuffer);
                        OnFindComponentsOnAfterTransferData(TempItemTracingBuffer, ItemLedgEntry2, ItemLedgEntry);
                        if InsertRecord(TempItemTracingBuffer, ParentID) then
                            NextLevel(TempItemTracingBuffer, TempItemTracingBuffer, Direction, ShowComponents, ItemLedgEntry."Entry No.");
                    end;
                until ItemLedgEntry.Next() = 0;
            CurrentLevel -= 1;
        end;
    end;

    procedure InsertRecord(var TempTrackEntry: Record "Item Tracing Buffer"; ParentID: Integer) Result: Boolean
    var
        TempTrackEntry2: Record "Item Tracing Buffer";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Job: Record Job;
        RecRef: RecordRef;
        InsertEntry: Boolean;
        Description2: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertRecord(TempTrackEntry, ParentID, Result, IsHandled);
        if not IsHandled then begin
            TempTrackEntry2 := TempTrackEntry;
            TempTrackEntry.Reset();
            TempTrackEntry.SetCurrentKey(TempTrackEntry."Item Ledger Entry No.");
            TempTrackEntry.SetRange(TempTrackEntry."Item Ledger Entry No.", TempTrackEntry."Item Ledger Entry No.");
            // Mark entry if already in search result
            TempTrackEntry2."Already Traced" := TempTrackEntry.FindFirst();

            if CurrentLevel = 1 then begin
                TempTrackEntry.SetRange("Parent Item Ledger Entry No.", ParentID);
                TempTrackEntry.SetFilter(Level, '<>%1', CurrentLevel);
            end;

            InsertEntry := true;
            if CurrentLevel <= 1 then
                InsertEntry := not TempTrackEntry.FindFirst();

            if InsertEntry then begin
                TempTrackEntry2.Reset();
                TempTrackEntry := TempTrackEntry2;
                TempLineNo += 1;
                TempTrackEntry."Line No." := TempLineNo;
                SetRecordID(TempTrackEntry);
                TempTrackEntry."Parent Item Ledger Entry No." := ParentID;
                if Format(TempTrackEntry."Record Identifier") = '' then
                    Description2 := StrSubstNo('%1 %2', TempTrackEntry."Entry Type", TempTrackEntry."Document No.")
                else begin
                    if RecRef.Get(TempTrackEntry."Record Identifier") then
                        case RecRef.Number of
                            Database::"Item Ledger Entry":
                                begin
                                    RecRef.SetTable(ItemLedgerEntry);
                                    if ItemLedgerEntry."Job No." <> '' then begin
                                        Job.Get(ItemLedgerEntry."Job No.");
                                        Description2 := Format(StrSubstNo('%1 %2', Job.TableCaption(), ItemLedgerEntry."Job No."), -50);
                                    end;
                                end;
                        end;
                    if Description2 = '' then
                        Description2 := StrSubstNo('%1 %2', RecRef.Caption, TempTrackEntry."Document No.");
                end;
                OnInsertRecordOnBeforeSetDescription(TempTrackEntry, RecRef, Description2);
                TempTrackEntry.SetDescription(Description2);
                TempTrackEntry.Insert();
                exit(true);
            end;
            exit(false);
        end;
    end;

    procedure InitTempTable(var TempTrackEntry: Record "Item Tracing Buffer"; var TempTrackEntry2: Record "Item Tracing Buffer")
    begin
        TempTrackEntry2.Reset();
        TempTrackEntry2.DeleteAll();
        TempTrackEntry.Reset();
        TempTrackEntry.SetRange(Level, 0);
        if TempTrackEntry.Find('-') then
            repeat
                TempTrackEntry2 := TempTrackEntry;
                TempTrackEntry2.Insert();
            until TempTrackEntry.Next() = 0;
    end;

    local procedure DeleteTempTables(var TempTrackEntry: Record "Item Tracing Buffer"; var TempTrackEntry2: Record "Item Tracing Buffer")
    begin
        Clear(TempTrackEntry);
        if not TempTrackEntry.IsEmpty() then
            TempTrackEntry.DeleteAll();

        Clear(TempTrackEntry2);
        if not TempTrackEntry2.IsEmpty() then
            TempTrackEntry2.DeleteAll();
    end;

    procedure ExpandAll(var TempTrackEntry: Record "Item Tracing Buffer"; var TempTrackEntry2: Record "Item Tracing Buffer")
    begin
        TempTrackEntry2.Reset();
        TempTrackEntry2.DeleteAll();
        TempTrackEntry.Reset();
        if TempTrackEntry.FindSet() then
            repeat
                TempTrackEntry2 := TempTrackEntry;
                TempTrackEntry2.Insert();
            until TempTrackEntry.Next() = 0;
    end;

    local procedure IsExpanded(ActualTrackingLine: Record "Item Tracing Buffer"; var TempTrackEntry2: Record "Item Tracing Buffer"): Boolean
    var
        xTrackEntry: Record "Item Tracing Buffer";
        Found: Boolean;
    begin
        xTrackEntry.Copy(TempTrackEntry2);
        TempTrackEntry2.Reset();
        TempTrackEntry2 := ActualTrackingLine;
        Found := (TempTrackEntry2.Next() <> 0);
        if Found then
            Found := (TempTrackEntry2.Level > ActualTrackingLine.Level);
        TempTrackEntry2.Copy(xTrackEntry);
        exit(Found);
    end;

    local procedure HasChildren(ActualTrackingLine: Record "Item Tracing Buffer"; var TempTrackEntry: Record "Item Tracing Buffer"): Boolean
    begin
        TempTrackEntry.Reset();
        TempTrackEntry := ActualTrackingLine;
        if TempTrackEntry.Next() = 0 then
            exit(false);

        exit(TempTrackEntry.Level > ActualTrackingLine.Level);
    end;

    procedure TransferData(var ItemLedgEntry: Record "Item Ledger Entry"; var TempTrackEntry: Record "Item Tracing Buffer")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ValueEntry: Record "Value Entry";
    begin
        TempTrackEntry.Init();
        TempTrackEntry."Line No." := 9999999;
        TempTrackEntry.Level := CurrentLevel;
        TempTrackEntry."Item No." := ItemLedgEntry."Item No.";
        TempTrackEntry."Item Description" := GetItemDescription(ItemLedgEntry."Item No.");
        TempTrackEntry."Posting Date" := ItemLedgEntry."Posting Date";
        TempTrackEntry."Entry Type" := ItemLedgEntry."Entry Type";
        TempTrackEntry."Source Type" := ItemLedgEntry."Source Type";
        TempTrackEntry."Source No." := ItemLedgEntry."Source No.";
        TempTrackEntry."Source Name" := '';
        case TempTrackEntry."Source Type" of
            TempTrackEntry."Source Type"::Customer:
                if Customer.Get(TempTrackEntry."Source No.") then
                    TempTrackEntry."Source Name" := Customer.Name;
            TempTrackEntry."Source Type"::Vendor:
                if Vendor.Get(TempTrackEntry."Source No.") then
                    TempTrackEntry."Source Name" := Vendor.Name;
        end;
        TempTrackEntry."Document No." := ItemLedgEntry."Document No.";
        TempTrackEntry.Description := ItemLedgEntry.Description;
        TempTrackEntry."Location Code" := ItemLedgEntry."Location Code";
        TempTrackEntry.Quantity := ItemLedgEntry.Quantity;
        TempTrackEntry."Remaining Quantity" := ItemLedgEntry."Remaining Quantity";
        TempTrackEntry.Open := ItemLedgEntry.Open;
        TempTrackEntry.Positive := ItemLedgEntry.Positive;
        TempTrackEntry."Variant Code" := ItemLedgEntry."Variant Code";
        TempTrackEntry.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
        TempTrackEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Document No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        if not ValueEntry.FindFirst() then
            Clear(ValueEntry);
        TempTrackEntry."Created by" := ValueEntry."User ID";
        TempTrackEntry."Created on" := ValueEntry."Posting Date";

        OnAfterTransferData(ItemLedgEntry, TempTrackEntry, ValueEntry);
    end;

    procedure InitSearchCriteria(SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitSearchCriteria(SearchCriteria, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, IsHandled);
        if IsHandled then
            exit;

        if (SerialNoFilter = '') and (LotNoFilter = '') and (ItemNoFilter = '') and (PackageNoFilter = '') then
            SearchCriteria := SearchCriteria::None
        else
            if LotNoFilter <> '' then begin
                if SerialNoFilter = '' then
                    SearchCriteria := SearchCriteria::Lot
                else
                    SearchCriteria := SearchCriteria::Both;
            end else
                if SerialNoFilter <> '' then
                    SearchCriteria := SearchCriteria::Serial
                else
                    if ItemNoFilter <> '' then
                        SearchCriteria := SearchCriteria::Item
                    else
                        if PackageNoFilter <> '' then
                            SearchCriteria := SearchCriteria::Package;
        OnAfterInitSearchCriteria(SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, SearchCriteria);
    end;

    procedure InitSearchParm(var ItemTracingBuffer: Record "Item Tracing Buffer"; var SerialNoFilter: Text; var LotNoFilter: Text; var PackageNoFilter: Text; var ItemNoFilter: Text; var VariantFilter: Text)
    var
        ItemTrackingEntry: Record "Item Tracing Buffer";
    begin
        ItemTrackingEntry.SetRange("Serial No.", ItemTracingBuffer."Serial No.");
        ItemTrackingEntry.SetRange("Lot No.", ItemTracingBuffer."Lot No.");
        ItemTrackingEntry.SetRange("Package No.", ItemTracingBuffer."Package No.");
        ItemTrackingEntry.SetRange("Item No.", ItemTracingBuffer."Item No.");
        ItemTrackingEntry.SetRange("Variant Code", ItemTracingBuffer."Variant Code");
        SerialNoFilter := ItemTrackingEntry.GetFilter("Serial No.");
        LotNoFilter := ItemTrackingEntry.GetFilter("Lot No.");
        PackageNoFilter := ItemTrackingEntry.GetFilter("Package No.");
        ItemNoFilter := ItemTrackingEntry.GetFilter("Item No.");
        VariantFilter := ItemTrackingEntry.GetFilter("Variant Code");

        OnAfterInitSearchParam(ItemTracingBuffer, ItemTrackingEntry);
    end;

    procedure SetRecordID(var TrackingEntry: Record "Item Tracing Buffer")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnShipHeader: Record "Return Shipment Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        TransShipHeader: Record "Transfer Shipment Header";
        TransRcptHeader: Record "Transfer Receipt Header";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetRecordID(TrackingEntry, IsHandled);
        if IsHandled then
            exit;

        Clear(RecRef);

        case TrackingEntry."Entry Type" of
            TrackingEntry."Entry Type"::Purchase:
                if not TrackingEntry.Positive then begin
                    if PurchCrMemoHeader.Get(TrackingEntry."Document No.") then begin
                        RecRef.GetTable(PurchCrMemoHeader);
                        TrackingEntry."Record Identifier" := RecRef.RecordId;
                    end else
                        if ReturnShipHeader.Get(TrackingEntry."Document No.") then begin
                            RecRef.GetTable(ReturnShipHeader);
                            TrackingEntry."Record Identifier" := RecRef.RecordId;
                        end else
                            if ItemLedgEntry.Get(TrackingEntry."Item Ledger Entry No.") then begin
                                RecRef.GetTable(ItemLedgEntry);
                                TrackingEntry."Record Identifier" := RecRef.RecordId;
                            end;
                end else
                    if PurchRcptHeader.Get(TrackingEntry."Document No.") then begin
                        RecRef.GetTable(PurchRcptHeader);
                        TrackingEntry."Record Identifier" := RecRef.RecordId;
                    end else
                        if PurchInvHeader.Get(TrackingEntry."Document No.") then begin
                            RecRef.GetTable(PurchInvHeader);
                            TrackingEntry."Record Identifier" := RecRef.RecordId;
                        end else
                            if ItemLedgEntry.Get(TrackingEntry."Item Ledger Entry No.") then begin
                                RecRef.GetTable(ItemLedgEntry);
                                TrackingEntry."Record Identifier" := RecRef.RecordId;
                            end;
            TrackingEntry."Entry Type"::Sale:
                if IsServiceDocument(TrackingEntry."Item Ledger Entry No.", ItemLedgEntry) then
                    OnSetRecordIDOnProcessServiceDocument(ItemLedgEntry, TrackingEntry)
                else
                    if TrackingEntry.Positive then begin
                        if SalesCrMemoHeader.Get(TrackingEntry."Document No.") then begin
                            RecRef.GetTable(SalesCrMemoHeader);
                            TrackingEntry."Record Identifier" := RecRef.RecordId;
                        end else
                            if ReturnRcptHeader.Get(TrackingEntry."Document No.") then begin
                                RecRef.GetTable(ReturnRcptHeader);
                                TrackingEntry."Record Identifier" := RecRef.RecordId;
                            end else
                                if ItemLedgEntry.Get(TrackingEntry."Item Ledger Entry No.") then begin
                                    RecRef.GetTable(ItemLedgEntry);
                                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                                end;
                    end else
                        if SalesShptHeader.Get(TrackingEntry."Document No.") then begin
                            RecRef.GetTable(SalesShptHeader);
                            TrackingEntry."Record Identifier" := RecRef.RecordId;
                        end else
                            if SalesInvHeader.Get(TrackingEntry."Document No.") then begin
                                RecRef.GetTable(SalesInvHeader);
                                TrackingEntry."Record Identifier" := RecRef.RecordId;
                            end else
                                if ItemLedgEntry.Get(TrackingEntry."Item Ledger Entry No.") then begin
                                    RecRef.GetTable(ItemLedgEntry);
                                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                                end;
            TrackingEntry."Entry Type"::"Positive Adjmt.",
          TrackingEntry."Entry Type"::"Negative Adjmt.":
                if ItemLedgEntry.Get(TrackingEntry."Item Ledger Entry No.") then begin
                    RecRef.GetTable(ItemLedgEntry);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end;
            TrackingEntry."Entry Type"::Transfer:
                if TransShipHeader.Get(TrackingEntry."Document No.") then begin
                    RecRef.GetTable(TransShipHeader);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end else
                    if TransRcptHeader.Get(TrackingEntry."Document No.") then begin
                        RecRef.GetTable(TransRcptHeader);
                        TrackingEntry."Record Identifier" := RecRef.RecordId;
                    end else
                        if ItemLedgEntry.Get(TrackingEntry."Item Ledger Entry No.") then begin
                            RecRef.GetTable(ItemLedgEntry);
                            TrackingEntry."Record Identifier" := RecRef.RecordId;
                        end;
        end;

        OnAfterSetRecordID(TrackingEntry, RecRef);
    end;

    procedure ShowDocument(RecID: RecordID)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ReturnShipHeader: Record "Return Shipment Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        TransShipHeader: Record "Transfer Shipment Header";
        TransRcptHeader: Record "Transfer Receipt Header";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        if Format(RecID) = '' then
            exit;

        RecRef := RecID.GetRecord();

        IsHandled := false;
        OnBeforeShowDocument(RecRef, IsHandled);
        if IsHandled then
            exit;

        case RecID.TableNo of
            Database::"Item Ledger Entry":
                begin
                    RecRef.SetTable(ItemLedgEntry);
                    PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry);
                end;
            Database::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShptHeader);
                    PAGE.RunModal(PAGE::"Posted Sales Shipment", SalesShptHeader);
                end;
            Database::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvHeader);
                    PAGE.RunModal(PAGE::"Posted Sales Invoice", SalesInvHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    PAGE.RunModal(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    RecRef.SetTable(PurchRcptHeader);
                    PAGE.RunModal(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
                end;
            Database::"Purch. Inv. Header":
                begin
                    RecRef.SetTable(PurchInvHeader);
                    PAGE.RunModal(PAGE::"Posted Purchase Invoice", PurchInvHeader);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.SetTable(PurchCrMemoHeader);
                    PAGE.RunModal(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHeader);
                end;
            Database::"Return Shipment Header":
                begin
                    RecRef.SetTable(ReturnShipHeader);
                    PAGE.RunModal(PAGE::"Posted Return Shipment", ReturnShipHeader);
                end;
            Database::"Return Receipt Header":
                begin
                    RecRef.SetTable(ReturnRcptHeader);
                    PAGE.RunModal(PAGE::"Posted Return Receipt", ReturnRcptHeader);
                end;
            Database::"Transfer Shipment Header":
                begin
                    RecRef.SetTable(TransShipHeader);
                    PAGE.RunModal(PAGE::"Posted Transfer Shipment", TransShipHeader);
                end;
            Database::"Transfer Receipt Header":
                begin
                    RecRef.SetTable(TransRcptHeader);
                    PAGE.RunModal(PAGE::"Posted Transfer Receipt", TransRcptHeader);
                end;
            else
                OnShowDocument(RecRef, RecID);
        end;
    end;

    procedure SetExpansionStatus(Rec: Record "Item Tracing Buffer"; var TempTrackEntry: Record "Item Tracing Buffer"; var TempTrackEntry2: Record "Item Tracing Buffer"; var ActualExpansionStatus: Option "Has Children",Expanded,"No Children")
    begin
        if IsExpanded(Rec, TempTrackEntry2) then
            ActualExpansionStatus := ActualExpansionStatus::Expanded
        else
            if HasChildren(Rec, TempTrackEntry) then
                ActualExpansionStatus := ActualExpansionStatus::"Has Children"
            else
                ActualExpansionStatus := ActualExpansionStatus::"No Children";
    end;

    local procedure GetItem(var Item: Record Item; ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            if not Item.Get(ItemNo) then
                Clear(Item);
    end;

    local procedure GetItemDescription(ItemNo: Code[20]): Text[100]
    var
        Item: Record Item;
    begin
        GetItem(Item, ItemNo);
        exit(Item.Description);
    end;

    local procedure GetItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("Item Tracking Code");
        if Item.Get(ItemNo) then;
        if Item."Item Tracking Code" <> '' then begin
            if not ItemTrackingCode.Get(Item."Item Tracking Code") then
                Clear(ItemTrackingCode);
        end else
            Clear(ItemTrackingCode);
    end;

    procedure IsSpecificTracking(ItemNo: Code[20]; ItemTrackingSetup: Record "Item Tracking Setup") IsSpecific: Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsSpecificTracking(ItemNo, ItemTrackingSetup, IsSpecific, IsHandled);
        if IsHandled then
            exit(IsSpecific);
        ItemTrackingCode.SetLoadFields("SN Specific Tracking", "Lot Specific Tracking", "Package Specific Tracking");
        GetItemTrackingCode(ItemTrackingCode, ItemNo);
        ItemTrackingSetup.CopyTrackingFromItemTrackingCodeSpecificTracking(ItemTrackingCode);
        exit(ItemTrackingSetup.SpecificTracking(ItemNo));
    end;

    local procedure ExitLevel(TempItemTracingBuffer: Record "Item Tracing Buffer" temporary) Result: Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExitLevel(TempItemTracingBuffer, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ItemTrackingSetup.CopyTrackingFromItemTracingBuffer(TempItemTracingBuffer);
        if not ItemTrackingSetup.TrackingExists() then
            exit(true);
        if CurrentLevel > 50 then
            exit(true);
        if not IsSpecificTracking(TempItemTracingBuffer."Item No.", ItemTrackingSetup) then
            exit(true);
        if TempItemTracingBuffer."Already Traced" then
            exit(true);

        exit(false);
    end;

    local procedure UpdateHistory(SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text; TraceMethod: Option "Origin->Usage","Usage->Origin"; ShowComponents: Option No,"Item-tracked only",All) OK: Boolean
    var
        LevelCount: Integer;
        ExtFilterExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateHistory(TempItemTracingHistoryBuffer, CurrentHistoryEntryNo, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter, TraceMethod, ShowComponents, OK, IsHandled);
        if IsHandled then
            exit(OK);

        TempItemTracingHistoryBuffer.Reset();
        TempItemTracingHistoryBuffer.SetFilter("Entry No.", '>%1', CurrentHistoryEntryNo);
        TempItemTracingHistoryBuffer.DeleteAll();
        LevelCount := 0;
        repeat
            TempItemTracingHistoryBuffer.Init();
            TempItemTracingHistoryBuffer."Entry No." := CurrentHistoryEntryNo + 1;
            TempItemTracingHistoryBuffer.Level := LevelCount;

            OnAfterInitItemTracingHistoryBuffer(TempItemTracingHistoryBuffer, ExtFilterExists);

            TempItemTracingHistoryBuffer."Serial No. Filter" := CopyStr(SerialNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Serial No. Filter"));
            TempItemTracingHistoryBuffer."Lot No. Filter" := CopyStr(LotNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Lot No. Filter"));
            TempItemTracingHistoryBuffer."Package No. Filter" := CopyStr(PackageNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Package No. Filter"));
            TempItemTracingHistoryBuffer."Item No. Filter" := CopyStr(ItemNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Item No. Filter"));
            TempItemTracingHistoryBuffer."Variant Filter" := CopyStr(VariantFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Variant Filter"));

            if TempItemTracingHistoryBuffer.Level = 0 then begin
                TempItemTracingHistoryBuffer."Trace Method" := TraceMethod;
                TempItemTracingHistoryBuffer."Show Components" := ShowComponents;
            end;
            OnBeforeItemTracingHistoryBufferInsert(TempItemTracingHistoryBuffer);
            TempItemTracingHistoryBuffer.Insert();

            LevelCount += 1;
            SerialNoFilter := DelStr(SerialNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Serial No. Filter"));
            LotNoFilter := DelStr(LotNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Lot No. Filter"));
            PackageNoFilter := DelStr(PackageNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Package No. Filter"));
            ItemNoFilter := DelStr(ItemNoFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Item No. Filter"));
            VariantFilter := DelStr(VariantFilter, 1, MaxStrLen(TempItemTracingHistoryBuffer."Variant Filter"));
        until (SerialNoFilter = '') and (LotNoFilter = '') and (ItemNoFilter = '') and (VariantFilter = '') and
              (PackageNoFilter = '') and not ExtFilterExists;
        CurrentHistoryEntryNo := TempItemTracingHistoryBuffer."Entry No.";
        OK := true;
    end;

    procedure RecallHistory(Steps: Integer; var TempTrackEntry: Record "Item Tracing Buffer"; var TempTrackEntry2: Record "Item Tracing Buffer"; var SerialNoFilter: Text; var LotNoFilter: Text; var PackageNoFilter: Text; var ItemNoFilter: Text; var VariantFilter: Text; var TraceMethod: Option "Origin->Usage","Usage->Origin"; var ShowComponents: Option No,"Item-tracked only",All): Boolean
    begin
        if not RetrieveHistoryData(CurrentHistoryEntryNo + Steps,
             SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter, TraceMethod, ShowComponents)
        then
            exit(false);
        DeleteTempTables(TempTrackEntry, TempTrackEntry2);
        InitSearchCriteria(SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter);
        FirstLevel(TempTrackEntry, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter,
          VariantFilter, TraceMethod, ShowComponents);
        if TempLineNo > 0 then
            InitTempTable(TempTrackEntry, TempTrackEntry2);
        TempTrackEntry.Reset();
        CurrentHistoryEntryNo := CurrentHistoryEntryNo + Steps;
        exit(true);
    end;

    local procedure RetrieveHistoryData(EntryNo: Integer; var SerialNoFilter: Text; var LotNoFilter: Text; var PackageNoFilter: Text; var ItemNoFilter: Text; var VariantFilter: Text; var TraceMethod: Option "Origin->Usage","Usage->Origin"; var ShowComponents: Option No,"Item-tracked only",All): Boolean
    begin
        TempItemTracingHistoryBuffer.Reset();
        TempItemTracingHistoryBuffer.SetCurrentKey("Entry No.", TempItemTracingHistoryBuffer.Level);
        TempItemTracingHistoryBuffer.SetRange("Entry No.", EntryNo);
        if not TempItemTracingHistoryBuffer.FindSet() then
            exit(false);
        repeat
            if TempItemTracingHistoryBuffer.Level = 0 then begin
                SerialNoFilter := TempItemTracingHistoryBuffer."Serial No. Filter";
                LotNoFilter := TempItemTracingHistoryBuffer."Lot No. Filter";
                PackageNoFilter := TempItemTracingHistoryBuffer."Package No. Filter";
                ItemNoFilter := TempItemTracingHistoryBuffer."Item No. Filter";
                VariantFilter := TempItemTracingHistoryBuffer."Variant Filter";
                TraceMethod := TempItemTracingHistoryBuffer."Trace Method";
                ShowComponents := TempItemTracingHistoryBuffer."Show Components";
            end else begin
                SerialNoFilter := SerialNoFilter + TempItemTracingHistoryBuffer."Serial No. Filter";
                LotNoFilter := LotNoFilter + TempItemTracingHistoryBuffer."Lot No. Filter";
                PackageNoFilter := PackageNoFilter + TempItemTracingHistoryBuffer."Package No. Filter";
                ItemNoFilter := ItemNoFilter + TempItemTracingHistoryBuffer."Item No. Filter";
                VariantFilter := VariantFilter + TempItemTracingHistoryBuffer."Variant Filter";
            end;
            OnRetrieveHistoryDataOnAfterTraceHistoryLine(TempItemTracingHistoryBuffer);
        until TempItemTracingHistoryBuffer.Next() = 0;
        exit(true);
    end;

    procedure GetHistoryStatus(var PreviousExists: Boolean; var NextExists: Boolean)
    begin
        TempItemTracingHistoryBuffer.Reset();
        TempItemTracingHistoryBuffer.SetFilter("Entry No.", '>%1', CurrentHistoryEntryNo);
        NextExists := not TempItemTracingHistoryBuffer.IsEmpty();
        TempItemTracingHistoryBuffer.SetFilter("Entry No.", '<%1', CurrentHistoryEntryNo);
        PreviousExists := not TempItemTracingHistoryBuffer.IsEmpty();
    end;

    local procedure IsServiceDocument(ItemLedgEntryNo: Integer; var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        if ItemLedgEntry.Get(ItemLedgEntryNo) then
            if ItemLedgEntry."Document Type" in [
                                    ItemLedgEntry."Document Type"::"Service Shipment", ItemLedgEntry."Document Type"::"Service Invoice",
                                    ItemLedgEntry."Document Type"::"Service Credit Memo"]
            then
                exit(true);
        exit(false);
    end;

    procedure SetVariables(NewTempLineNo: Integer; NewCurrentLevel: Integer)
    begin
        TempLineNo := NewTempLineNo;
        CurrentLevel := NewCurrentLevel;
    end;

    procedure GetVariables(var NewTempLineNo: Integer; var NewCurrentLevel: Integer)
    begin
        NewTempLineNo := TempLineNo;
        NewCurrentLevel := CurrentLevel;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemTracingHistoryBuffer(var ItemTracingHistoryBuffer: Record "Item Tracing History Buffer"; var ExtFilterExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSearchParam(var ItemTracingBuffer: Record "Item Tracing Buffer"; var ItemTracingBuffer2: Record "Item Tracing Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSearchCriteria(SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; var SearchCriteria: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferData(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempItemTracingBuffer: Record "Item Tracing Buffer" temporary; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExitLevel(TempItemTracingBuffer: Record "Item Tracing Buffer" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindComponents(var ItemLedgEntry2: Record "Item Ledger Entry"; var TempItemTracingBuffer: Record "Item Tracing Buffer" temporary; Direction: Option Forward,Backward; ShowComponents: Option No,"Item-tracked only",All; ParentID: Integer; var CurrentLevel: Integer; var TempLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRecord(var ItemTracingBuffer: Record "Item Tracing Buffer"; ParentID: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsSpecificTracking(ItemNo: Code[20]; ItemTrackingSetup: Record "Item Tracking Setup"; var IsSpecific: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemTracingHistoryBufferInsert(var ItemTracingHistoryBuffer: Record "Item Tracing History Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextLevel(var TempTrackEntry: Record "Item Tracing Buffer" temporary; var TempTrackEntry2: Record "Item Tracing Buffer" temporary; Direction: Option Forward,Backward; ShowComponents: Option No,"Item-tracked only",All; ParentID: Integer; var CurrentLevel: Integer; var TempLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocument(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRecordID(var TrackingEntry: Record "Item Tracing Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateHistory(var TempItemTracingHistoryBuffer: Record "Item Tracing History Buffer" temporary; var CurrentHistoryEntryNo: Integer; SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text; TraceMethod: Option; ShowComponents: Option; var OK: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindComponentsOnAfterSetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindComponentsOnAfterTransferData(var TempItemTracingBuffer: Record "Item Tracing Buffer" temporary; var ItemLedgerEntry2: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFirstLevelOnAfterSetLedgerEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var SerialNoFilter: Text; var LotNoFilter: Text; var ItemNoFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFirstLevelOnAfterItemLedgEntrySetCurrentKey(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFirstLevelOnAfterTempItemTracingBufferSetCurrentKey(var TempItemTracingBuffer: Record "Item Tracing Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFirstLevelOnAfterTransferData(var TempItemTracingBuffer: Record "Item Tracing Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFirstLevelOnBeforeInsertFirstLevelEntry(var ItemTracingBuffer: Record "Item Tracing Buffer"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFirstLevelOnBeforeTransferData(var ItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecordOnBeforeSetDescription(var TempTrackEntry: Record "Item Tracing Buffer"; var RecRef: RecordRef; var Description2: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextLevelOnAfterTransferData(var TempItemTracingBuffer: Record "Item Tracing Buffer" temporary; var TempItemTracingBuffer2: Record "Item Tracing Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveHistoryDataOnAfterTraceHistoryLine(var TempItemTracingHistoryBuffer: Record "Item Tracing History Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetRecordIDOnProcessServiceDocument(ItemLedgEntry: Record "Item Ledger Entry"; var TrackingEntry: Record "Item Tracing Buffer")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnSetRecordIDOnBeforeProcessServiceDocument(ItemLedgEntry: Record "Item Ledger Entry"; var TrackingEntry: Record "Item Tracing Buffer")
    begin
        OnSetRecordIDOnBeforeProcessServiceDocument(ItemLedgEntry, TrackingEntry);
    end;

    [Obsolete('Moved to codeunit Serv. Item Tracing Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetRecordIDOnBeforeProcessServiceDocument(ItemLedgEntry: Record "Item Ledger Entry"; var TrackingEntry: Record "Item Tracing Buffer")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSearchCriteria(var SearchCriteria: Option "None",Lot,Serial,Both,Item,Package; SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocument(RecRef: RecordRef; RecID: RecordId)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordsOnBeforeInitTempTable(var ItemTracingBuffer: Record "Item Tracing Buffer"; Direction: Option; ShowComponents: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRecordID(var TrackingEntry: Record "Item Tracing Buffer"; RecRef: RecordRef)
    begin
    end;
}

