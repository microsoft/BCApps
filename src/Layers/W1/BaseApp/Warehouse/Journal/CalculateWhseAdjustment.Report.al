// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Utilities;

report 7315 "Calculate Whse. Adjustment"
{
    Caption = 'Calculate Warehouse Adjustment';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Location Filter", "Variant Filter";
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                var
                    AdjmtBin: Record Bin;
                    ReservationEntry: Record "Reservation Entry";
                    WhseItemTrackingSetup: Record "Item Tracking Setup";
                    SNLotNumbersByBin: Query "Lot Numbers by Bin";
                begin
                    Location.Reset();
                    Item.CopyFilter("Location Filter", Location.Code);
                    Location.SetRange("Directed Put-away and Pick", true);
                    if Location.FindSet() then
                        repeat
                            AdjmtBin.Get(Location.Code, Location."Adjustment Bin Code");

                            SNLotNumbersByBin.SetRange(Location_Code, Location.Code);
                            SNLotNumbersByBin.SetRange(Zone_Code, AdjmtBin."Zone Code");
                            SNLotNumbersByBin.SetRange(Bin_Code, AdjmtBin.Code);
                            SNLotNumbersByBin.SetRange(Item_No, Item."No.");
                            SNLotNumbersByBin.SetFilter(Variant_Code, Item.GetFilter("Variant Filter"));
                            SNLotNumbersByBin.SetFilter(Lot_No, Item.GetFilter("Lot No. Filter"));
                            SNLotNumbersByBin.SetFilter(Serial_No, Item.GetFilter("Serial No. Filter"));
                            SNLotNumbersByBin.SetFilter(Package_No, Item.GetFilter("Package No. Filter"));
                            OnAfterGetRecordItemOnAfterSNLotNumbersByBinSetFilters(SNLotNumbersByBin, Item);
                            SNLotNumbersByBin.Open();

                            while SNLotNumbersByBin.Read() do begin
                                TempAdjmtBinContentBuffer.Init();
                                TempAdjmtBinContentBuffer."Item No." := SNLotNumbersByBin.Item_No;
                                TempAdjmtBinContentBuffer."Variant Code" := SNLotNumbersByBin.Variant_Code;
                                TempAdjmtBinContentBuffer."Location Code" := SNLotNumbersByBin.Location_Code;
                                TempAdjmtBinContentBuffer."Bin Code" := SNLotNumbersByBin.Bin_Code;
                                TempAdjmtBinContentBuffer."Unit of Measure Code" := SNLotNumbersByBin.Unit_of_Measure_Code;
                                TempAdjmtBinContentBuffer."Base Unit of Measure" := Item."Base Unit of Measure";
                                TempAdjmtBinContentBuffer."Lot No." := SNLotNumbersByBin.Lot_No;
                                TempAdjmtBinContentBuffer."Serial No." := SNLotNumbersByBin.Serial_No;
                                TempAdjmtBinContentBuffer."Package No." := SNLotNumbersByBin.Package_No;
                                TempAdjmtBinContentBuffer."Qty. to Handle (Base)" := SNLotNumbersByBin.Sum_Qty_Base;
                                OnBeforeAdjmtBinQuantityBufferInsert(TempAdjmtBinContentBuffer, WhseEntry, SNLotNumbersByBin);
                                TempAdjmtBinContentBuffer.Insert();
                            end;
                        until Location.Next() = 0;

                    TempAdjmtBinContentBuffer.Reset();
                    ReservationEntry.Reset();
                    ReservationEntry.SetCurrentKey("Source ID");
                    ItemJnlLine.Reset();
                    ItemJnlLine.SetCurrentKey("Item No.");
                    if TempAdjmtBinContentBuffer.FindSet() then
                        repeat
                            ItemJnlLine.Reset();
                            ItemJnlLine.SetCurrentKey("Item No.");
                            ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
                            ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
                            ItemJnlLine.SetRange("Item No.", TempAdjmtBinContentBuffer."Item No.");
                            ItemJnlLine.SetRange("Location Code", TempAdjmtBinContentBuffer."Location Code");
                            ItemJnlLine.SetRange("Unit of Measure Code", TempAdjmtBinContentBuffer."Unit of Measure Code");
                            ItemJnlLine.SetRange("Warehouse Adjustment", true);
                            OnAfterGetRecordItemOnAfterItemJnlLineSetFilters(ItemJnlLine, TempAdjmtBinContentBuffer);
                            if ItemJnlLine.FindSet() then
                                repeat
                                    ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
                                    ReservationEntry.SetRange("Source ID", ItemJnlLine."Journal Template Name");
                                    ReservationEntry.SetRange("Source Batch Name", ItemJnlLine."Journal Batch Name");
                                    ReservationEntry.SetRange("Source Ref. No.", ItemJnlLine."Line No.");
                                    WhseItemTrackingSetup.CopyTrackingFromBinContentBuffer(TempAdjmtBinContentBuffer);
                                    ReservationEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
                                    OnAfterGetRecordItemOnAfterReservationEntrySetFilters(TempAdjmtBinContentBuffer, ReservationEntry);
                                    ReservationEntry.CalcSums("Qty. to Handle (Base)");
                                    if ReservationEntry."Qty. to Handle (Base)" <> 0 then begin
                                        TempAdjmtBinContentBuffer."Qty. to Handle (Base)" += ReservationEntry."Qty. to Handle (Base)";
                                        OnBeforeAdjmtBinQuantityBufferModify(TempAdjmtBinContentBuffer, ReservationEntry);
                                        TempAdjmtBinContentBuffer.Modify();
                                        OnAfterGetRecordItemOnAfterAdjmtBinContentBufferModify(TempAdjmtBinContentBuffer, ItemJnlLine, ReservationEntry);
                                    end;
                                    OnAfterGetRecordItemOnBeforeNextItemJournalLine(TempAdjmtBinContentBuffer, ItemJnlLine, ReservationEntry);
                                until ItemJnlLine.Next() = 0;
                        until TempAdjmtBinContentBuffer.Next() = 0;
                end;

                trigger OnPostDataItem()
                var
                    QtyInUOM: Decimal;
                begin
                    TempAdjmtBinContentBuffer.Reset();
                    if TempAdjmtBinContentBuffer.FindSet() then
                        repeat
                            TempAdjmtBinContentBuffer.SetRange("Location Code", TempAdjmtBinContentBuffer."Location Code");
                            TempAdjmtBinContentBuffer.SetRange("Variant Code", TempAdjmtBinContentBuffer."Variant Code");
                            TempAdjmtBinContentBuffer.SetRange("Unit of Measure Code", TempAdjmtBinContentBuffer."Unit of Measure Code");
                            TempAdjmtBinContentBuffer.SetFilter("Qty. to Handle (Base)", '>0');
                            OnPostDataItemOnAfterAdjmtBinContentBufferSetFilters(TempAdjmtBinContentBuffer);

                            TempAdjmtBinContentBuffer.CalcSums("Qty. to Handle (Base)");
                            QtyInUOM :=
                                UOMMgt.CalcQtyFromBase(
                                    TempAdjmtBinContentBuffer."Item No.", TempAdjmtBinContentBuffer."Variant Code", TempAdjmtBinContentBuffer."Unit of Measure Code", -TempAdjmtBinContentBuffer."Qty. to Handle (Base)",
                                    UOMMgt.GetQtyPerUnitOfMeasure(Item, TempAdjmtBinContentBuffer."Unit of Measure Code"));
                            if QtyInUOM <> 0 then
                                InsertItemJnlLine(TempAdjmtBinContentBuffer, QtyInUOM, -TempAdjmtBinContentBuffer."Qty. to Handle (Base)", TempAdjmtBinContentBuffer."Unit of Measure Code", 1);

                            TempAdjmtBinContentBuffer.SetFilter("Qty. to Handle (Base)", '<0');
                            TempAdjmtBinContentBuffer.CalcSums("Qty. to Handle (Base)");
                            QtyInUOM :=
                                UOMMgt.CalcQtyFromBase(TempAdjmtBinContentBuffer."Item No.", TempAdjmtBinContentBuffer."Variant Code", TempAdjmtBinContentBuffer."Unit of Measure Code", -TempAdjmtBinContentBuffer."Qty. to Handle (Base)",
                                    UOMMgt.GetQtyPerUnitOfMeasure(Item, TempAdjmtBinContentBuffer."Unit of Measure Code"));
                            if QtyInUOM <> 0 then
                                InsertItemJnlLine(TempAdjmtBinContentBuffer, QtyInUOM, -TempAdjmtBinContentBuffer."Qty. to Handle (Base)", TempAdjmtBinContentBuffer."Unit of Measure Code", 0);
                            // rounding residue
                            TempAdjmtBinContentBuffer.SetRange("Qty. to Handle (Base)");
                            TempAdjmtBinContentBuffer.CalcSums("Qty. to Handle (Base)");
                            QtyInUOM :=
                                UOMMgt.CalcQtyFromBase(
                                    TempAdjmtBinContentBuffer."Item No.", TempAdjmtBinContentBuffer."Variant Code", TempAdjmtBinContentBuffer."Unit of Measure Code", -TempAdjmtBinContentBuffer."Qty. to Handle (Base)",
                                    UOMMgt.GetQtyPerUnitOfMeasure(Item, TempAdjmtBinContentBuffer."Unit of Measure Code"));
                            if (QtyInUOM = 0) and (TempAdjmtBinContentBuffer."Qty. to Handle (Base)" > 0) then
                                InsertItemJnlLine(TempAdjmtBinContentBuffer, -TempAdjmtBinContentBuffer."Qty. to Handle (Base)", -TempAdjmtBinContentBuffer."Qty. to Handle (Base)", TempAdjmtBinContentBuffer."Base Unit of Measure", 1);

                            TempAdjmtBinContentBuffer.FindLast();
                            TempAdjmtBinContentBuffer.SetRange("Location Code");
                            TempAdjmtBinContentBuffer.SetRange("Variant Code");
                            TempAdjmtBinContentBuffer.SetRange("Unit of Measure Code");
                            OnPostDataItemOnAfterAdjmtBinContentBufferClearFilters(TempAdjmtBinContentBuffer);
                        until TempAdjmtBinContentBuffer.Next() = 0;
                    TempAdjmtBinContentBuffer.Reset();
                    TempAdjmtBinContentBuffer.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    Clear(Location);
                    WhseEntry.Reset();
                    WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code");
                    WhseEntry.SetRange("Item No.", Item."No.");
                    Item.CopyFilter("Variant Filter", WhseEntry."Variant Code");
                    WhseEntry.SetTrackingFilterFromItemFilters(Item);

                    if WhseEntry.IsEmpty() then
                        CurrReport.Break();

                    FillProspectReservationEntryBuffer(Item, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

                    TempAdjmtBinContentBuffer.Reset();
                    TempAdjmtBinContentBuffer.DeleteAll();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not HideValidationDialog then
                    Window.Update();
            end;

            trigger OnPostDataItem()
            begin
                if not HideValidationDialog then
                    Window.Close();
            end;

            trigger OnPreDataItem()
            var
                ItemJnlTemplate: Record "Item Journal Template";
                ItemJnlBatch: Record "Item Journal Batch";
            begin
                if PostingDate = 0D then
                    Error(Text000);

                ItemJnlTemplate.Get(ItemJnlLine."Journal Template Name");
                ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
                if NextDocNo = '' then begin
                    if ItemJnlBatch."No. Series" <> '' then begin
                        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
                        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
                        if not ItemJnlLine.Find('-') then
                            NextDocNo := NoSeriesBatch.GetNextNo(ItemJnlBatch."No. Series", PostingDate);
                        ItemJnlLine.Init();
                    end;
                    if NextDocNo = '' then
                        Error(Text001);
                end;

                NextLineNo := 0;

                if not HideValidationDialog then
                    Window.Open(Text002, "No.");
            end;
        }
    }

    requestpage
    {
        Caption = 'Calculate Inventory';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date for the posting of this batch job. The program automatically enters the work date in this field, but you can change it.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            ValidatePostingDate();
                        end;
                    }
                    field(NextDocNo; NextDocNo)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies a manually entered document number that will be entered in the Document No. field, on the journal lines created by the batch job.';
                        ShowMandatory = DocumentNoInputMandatory;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();
            ValidatePostingDate();
        end;
    }

    labels
    {
    }

    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        WhseEntry: Record "Warehouse Entry";
        Location: Record Location;
        SourceCodeSetup: Record "Source Code Setup";
        TempAdjmtBinContentBuffer: Record "Bin Content Buffer" temporary;
        TempReservationEntryBuffer: Record "Reservation Entry" temporary;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        PostingDate: Date;
        NextDocNo: Code[20];
        NextLineNo: Integer;
        DocumentNoInputMandatory: Boolean;
#pragma warning disable AA0074
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Enter the document no.';
#pragma warning disable AA0470
        Text002: Label 'Processing items    #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure SetItemJnlLine(var NewItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine := NewItemJnlLine;
    end;

    local procedure ValidatePostingDate()
    var
        NoSeries: Codeunit "No. Series";
    begin
        ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
        if ItemJnlBatch."No. Series" = '' then begin
            DocumentNoInputMandatory := true;
            NextDocNo := '';
        end else begin
            DocumentNoInputMandatory := false;
            NextDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", PostingDate);
        end;
    end;

    local procedure InsertItemJnlLine(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; Quantity2: Decimal; QuantityBase2: Decimal; UOM2: Code[10]; EntryType2: Option "Negative Adjmt.","Positive Adjmt.")
    var
        IsHandled: Boolean;
    begin
        OnBeforeFunctionInsertItemJnlLine(
          TempBinContentBuffer."Item No.", TempBinContentBuffer."Variant Code", TempBinContentBuffer."Location Code",
          Quantity2, QuantityBase2, UOM2, EntryType2);

        if NextLineNo = 0 then begin
            ItemJnlLine.LockTable();
            ItemJnlLine.Reset();
            ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
            ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
            if ItemJnlLine.Find('+') then
                NextLineNo := ItemJnlLine."Line No.";

            SourceCodeSetup.Get();
        end;
        NextLineNo := NextLineNo + 10000;

        if QuantityBase2 <> 0 then begin
            ItemJnlLine.Init();
            ItemJnlLine."Line No." := NextLineNo;
            ItemJnlLine.Validate("Posting Date", PostingDate);
            if QuantityBase2 > 0 then
                ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.")
            else begin
                ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
                Quantity2 := -Quantity2;
                QuantityBase2 := -QuantityBase2;
            end;

            IsHandled := false;
            OnInsertItemLineOnBeforeValidateFields(ItemJnlLine, ItemJnlBatch, SourceCodeSetup, IsHandled, TempBinContentBuffer, NextDocNo, UOM2);
            if not IsHandled then begin
                ItemJnlLine.Validate("Document No.", NextDocNo);
                ItemJnlLine.Validate("Item No.", TempBinContentBuffer."Item No.");
                ItemJnlLine.Validate("Variant Code", TempBinContentBuffer."Variant Code");
                ItemJnlLine.Validate("Location Code", TempBinContentBuffer."Location Code");
                ItemJnlLine.Validate("Source Code", SourceCodeSetup."Item Journal");
                ItemJnlLine.Validate("Unit of Measure Code", UOM2);
            end;
            ItemJnlLine."Posting No. Series" := ItemJnlBatch."Posting No. Series";
            ItemJnlLine.Validate(Quantity, Quantity2);
            ItemJnlLine."Quantity (Base)" := QuantityBase2;
            ItemJnlLine."Invoiced Qty. (Base)" := QuantityBase2;
            ItemJnlLine."Warehouse Adjustment" := true;
            OnInsertItemJnlLineOnBeforeInsert(ItemJnlLine, TempAdjmtBinContentBuffer);
            ItemJnlLine.Insert(true);
            OnAfterInsertItemJnlLine(ItemJnlLine);

            CreateReservationEntry(ItemJnlLine, TempBinContentBuffer, EntryType2, UOM2);
        end;

        OnAfterFunctionInsertItemJnlLine(
          TempBinContentBuffer."Item No.", TempBinContentBuffer."Variant Code", TempBinContentBuffer."Location Code",
          Quantity2, QuantityBase2, UOM2, EntryType2, ItemJnlLine);
    end;

    procedure InitializeRequest(NewPostingDate: Date; DocNo: Code[20])
    begin
        PostingDate := NewPostingDate;
        NextDocNo := DocNo;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure FillProspectReservationEntryBuffer(var Item: Record Item; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        TempReservationEntryBuffer.Reset();
        TempReservationEntryBuffer.DeleteAll();
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source ID", JournalTemplateName);
        ReservationEntry.SetRange("Source Batch Name", JournalBatchName);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetFilter("Variant Code", Item."Variant Filter");

        if ReservationEntry.FindSet() then
            repeat
                TempReservationEntryBuffer := ReservationEntry;
                TempReservationEntryBuffer.Insert();
            until ReservationEntry.Next() = 0;
    end;

    local procedure CreateReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var TempBinContentBuffer: Record "Bin Content Buffer" temporary; EntryType: Option "Negative Adjmt.","Positive Adjmt."; UOMCode: Code[10])
    var
        ReservEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseEntry2: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        OrderLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReservationEntry(ItemJnlLine, TempBinContentBuffer, EntryType, UOMCode, IsHandled);
        if IsHandled then
            exit;

        TempBinContentBuffer.FindSet();
        repeat
            WarehouseEntry.SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");
            WarehouseEntry.SetRange("Item No.", TempBinContentBuffer."Item No.");
            WarehouseEntry.SetRange("Bin Code", TempBinContentBuffer."Bin Code");
            WarehouseEntry.SetRange("Location Code", TempBinContentBuffer."Location Code");
            WarehouseEntry.SetRange("Variant Code", TempBinContentBuffer."Variant Code");
            WarehouseEntry.SetRange("Unit of Measure Code", UOMCode);
            WarehouseEntry.SetTrackingFilterFromBinContentBuffer(TempBinContentBuffer);
            WarehouseEntry.SetFilter("Entry Type", '%1|%2', EntryType, WarehouseEntry."Entry Type"::Movement);
            OnCreateReservationEntryOnAfterWarehouseEntrySetFilters(WarehouseEntry, TempBinContentBuffer);
            if not WarehouseEntry.FindFirst() then
                exit;

            TempReservationEntryBuffer.Reset();
            WarehouseEntry.CalcSums("Qty. (Base)", Quantity);
            WhseItemTrackingSetup.CopyTrackingFromWhseEntry(WarehouseEntry);
            UpdateWarehouseEntryQtyByReservationEntryBuffer(WarehouseEntry, WhseItemTrackingSetup);

            WarehouseEntry2.CopyFilters(WarehouseEntry);
            case EntryType of
                EntryType::"Positive Adjmt.":
                    WarehouseEntry2.SetRange("Entry Type", WarehouseEntry2."Entry Type"::"Negative Adjmt.");
                EntryType::"Negative Adjmt.":
                    WarehouseEntry2.SetRange("Entry Type", WarehouseEntry2."Entry Type"::"Positive Adjmt.");
            end;
            WarehouseEntry2.CalcSums("Qty. (Base)", Quantity);
            UpdateWarehouseEntryQtyByReservationEntryBuffer(WarehouseEntry2, WhseItemTrackingSetup);

            if Abs(WarehouseEntry2."Qty. (Base)") > Abs(WarehouseEntry."Qty. (Base)") then begin
                WarehouseEntry."Qty. (Base)" := 0;
                WarehouseEntry.Quantity := 0;
            end else begin
                WarehouseEntry."Qty. (Base)" += WarehouseEntry2."Qty. (Base)";
                WarehouseEntry.Quantity += WarehouseEntry2.Quantity;
            end;

            if WarehouseEntry."Qty. (Base)" <> 0 then begin
                if ItemJournalLine."Order Type" = ItemJournalLine."Order Type"::Production then
                    OrderLineNo := ItemJournalLine."Order Line No.";

                OnBeforeCreateReservEntryFor(ItemJournalLine, WarehouseEntry);

                ReservEntry.CopyTrackingFromWhseEntry(WarehouseEntry);
                CreateReservEntry.CreateReservEntryFor(
                  Database::"Item Journal Line", ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                  ItemJournalLine."Journal Batch Name", OrderLineNo, ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure",
                  Abs(WarehouseEntry.Quantity), Abs(WarehouseEntry."Qty. (Base)"), ReservEntry);

                if WarehouseEntry."Qty. (Base)" < 0 then
                    CreateReservEntry.SetDates(WarehouseEntry."Warranty Date", WarehouseEntry."Expiration Date");

                OnCreateReservationEntryOnBeforeCreateReservEntryCreateEntry(ItemJournalLine);

                CreateReservEntry.CreateEntry(
                  ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code", ItemJournalLine.Description,
                  0D, 0D, 0, "Reservation Status"::Prospect);
            end;
        until TempBinContentBuffer.Next() = 0;
    end;

    local procedure UpdateWarehouseEntryQtyByReservationEntryBuffer(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WarehouseEntry."Qty. (Base)" = 0 then
            exit;

        TempReservationEntryBuffer.SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
        TempReservationEntryBuffer.SetRange(Positive, WarehouseEntry."Qty. (Base)" < 0);
        OnUpdateWarehouseEntryQtyByReservationEntryBufferOnAfterTempReservationEntryBufferSetFilters(TempReservationEntryBuffer, WarehouseEntry);
        TempReservationEntryBuffer.CalcSums("Quantity (Base)", Quantity);

        WarehouseEntry."Qty. (Base)" += TempReservationEntryBuffer."Quantity (Base)";
        WarehouseEntry.Quantity += TempReservationEntryBuffer.Quantity;

        OnAfterUpdateWarehouseEntryQtyByReservationEntryBuffer(WarehouseEntry, TempReservationEntryBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFunctionInsertItemJnlLine(ItemNo: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10]; Quantity2: Decimal; QuantityBase2: Decimal; UOM2: Code[10]; EntryType2: Option "Negative Adjmt.","Positive Adjmt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFunctionInsertItemJnlLine(ItemNo: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10]; Quantity2: Decimal; QuantityBase2: Decimal; UOM2: Code[10]; EntryType2: Option "Negative Adjmt.","Positive Adjmt."; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWarehouseEntryQtyByReservationEntryBuffer(var WarehouseEntry: Record "Warehouse Entry"; var TempReservationEntryBuffer: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnAfterSNLotNumbersByBinSetFilters(var SNLotNumbersByBin: Query "Lot Numbers by Bin"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnAfterReservationEntrySetFilters(var TempAdjmtBinContentBuffer: Record "Bin Content Buffer" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnAfterItemJnlLineSetFilters(var ItemJournalLine: Record "Item Journal Line"; BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnAfterAdjmtBinContentBufferModify(BinContentBuffer: Record "Bin Content Buffer"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjmtBinQuantityBufferInsert(var BinContentBuffer: Record "Bin Content Buffer"; WarehouseEntry: Record "Warehouse Entry"; var SNLotNumbersByBin: Query "Lot Numbers by Bin")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjmtBinQuantityBufferModify(var BinContentBuffer: Record "Bin Content Buffer"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservEntryFor(var ItemJournalLine: Record "Item Journal Line"; var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var TempBinContentBuffer: Record "Bin Content Buffer" temporary; EntryType: Option; UOMCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationEntryOnBeforeCreateReservEntryCreateEntry(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationEntryOnAfterWarehouseEntrySetFilters(var WarehouseEntry: Record "Warehouse Entry"; var TempBinContentBuffer: Record "Bin Content Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJnlLineOnBeforeInsert(var ItemJournalLine: Record "Item Journal Line"; TempBinContentBuffer: Record "Bin Content Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLineOnBeforeValidateFields(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; SourceCodeSetup: Record "Source Code Setup"; var IsHandled: Boolean; var TempBinContentBuffer: Record "Bin Content Buffer" temporary; NextDocNo: Code[20]; UOM2: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemOnAfterAdjmtBinContentBufferSetFilters(var TempBinContentBuffer: Record "Bin Content Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemOnAfterAdjmtBinContentBufferClearFilters(var TempBinContentBuffer: Record "Bin Content Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWarehouseEntryQtyByReservationEntryBufferOnAfterTempReservationEntryBufferSetFilters(var TempReservationEntryBuffer: Record "Reservation Entry" temporary; var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnBeforeNextItemJournalLine(var TempAdjmtBinContentBuffer: Record "Bin Content Buffer" temporary; var ItemJnlLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;
}

