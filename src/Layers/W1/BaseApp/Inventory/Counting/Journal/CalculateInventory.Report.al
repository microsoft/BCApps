// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Utilities;

report 790 "Calculate Inventory"
{
    Caption = 'Calculate Inventory';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.") where(Type = const(Inventory), Blocked = const(false));
            RequestFilterFields = "No.", "Location Filter", "Bin Filter", "Variant Filter";
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date", "Entry No.");

                trigger OnAfterGetRecord()
                var
                    ItemVariant: Record "Item Variant";
                    ByBin: Boolean;
                    ExecuteLoop: Boolean;
                    InsertTempSKU: Boolean;
                    IsHandled: Boolean;
                begin
                    if not this.GetLocation("Location Code") then
                        CurrReport.Skip();

                    if ("Location Code" <> '') and Location."Use As In-Transit" then
                        CurrReport.Skip();

                    if "Item Ledger Entry"."Variant Code" <> '' then begin
                        ItemVariant.SetLoadFields(Blocked);
                        if ItemVariant.Get("Item Ledger Entry"."Item No.", "Item Ledger Entry"."Variant Code") and ItemVariant.Blocked then
                            CurrReport.Skip();
                    end;

                    if ColumnDim <> '' then
                        TransferDim("Dimension Set ID");

                    if not "Drop Shipment" then
                        ByBin := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";

                    IsHandled := false;
                    OnAfterGetRecordItemLedgEntryOnBeforeUpdateBuffer(Item, "Item Ledger Entry", ByBin, IsHandled);
                    if IsHandled then
                        CurrReport.Skip();

                    if not SkipCycleSKU("Location Code", "Item No.", "Variant Code") then
                        if ByBin then begin
                            if not TempSKU.Get("Location Code", "Item No.", "Variant Code") then begin
                                InsertTempSKU := false;
                                if "Variant Code" = '' then
                                    InsertTempSKU := true
                                else
                                    if ItemVariant.Get("Item No.", "Variant Code") then
                                        InsertTempSKU := true;
                                if InsertTempSKU then begin
                                    TempSKU."Item No." := "Item No.";
                                    TempSKU."Variant Code" := "Variant Code";
                                    TempSKU."Location Code" := "Location Code";
                                    TempSKU.Insert();
                                    ExecuteLoop := true;
                                end;
                            end;
                            if ExecuteLoop then begin
                                WhseEntry.SetRange("Item No.", "Item No.");
                                WhseEntry.SetRange("Location Code", "Location Code");
                                WhseEntry.SetRange("Variant Code", "Variant Code");
                                OnAfterGetRecordItemLedgEntryOnBeforeWhseEntryFind(WhseEntry, "Item Ledger Entry");
                                if WhseEntry.Find('-') then
                                    if WhseEntry."Entry No." <> OldWhseEntry."Entry No." then begin
                                        OldWhseEntry := WhseEntry;
                                        repeat
                                            WhseEntry.SetRange("Bin Code", WhseEntry."Bin Code");
                                            if not ItemBinLocationIsCalculated(WhseEntry."Bin Code") then begin
                                                WhseEntry.CalcSums("Qty. (Base)");
                                                OnItemLedgerEntryOnAfterGetRecordOnBeforeUpdateBuffer(WhseEntry);
                                                UpdateBuffer(WhseEntry."Bin Code", WhseEntry."Qty. (Base)", false);
                                            end;
                                            IsHandled := false;
                                            OnWhseEntryLoopOnBeforeFindlast(WhseEntry, IsHandled);
                                            if not IsHandled then
                                                WhseEntry.Find('+');
                                            Item.CopyFilter("Bin Filter", WhseEntry."Bin Code");
                                        until WhseEntry.Next() = 0;
                                    end;
                            end;
                        end else
                            UpdateBuffer('', Quantity, true);
                end;

                trigger OnPreDataItem()
                begin
                    WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code");
                    Item.CopyFilter("Bin Filter", WhseEntry."Bin Code");

                    if ColumnDim = '' then
                        TempDimBufIn.SetFilter("Table ID", '%1|%2', DATABASE::Item, Database::Location)
                    else
                        TempDimBufIn.SetRange("Table ID", DATABASE::"Item Ledger Entry");
                    TempDimBufIn.SetRange("Entry No.");
                    TempDimBufIn.DeleteAll();

                    OnItemLedgerEntryOnPreDataItemOnBeforeClearQuantityOnHandBuffer("Item Ledger Entry", Item);
                    if IncludeItemWithNoTransaction then
                        if not "Item Ledger Entry".Find('-') then begin
                            WhseEntry.SetRange("Item No.", Item."No.");
                            if (Item.GetFilter("Variant Filter") = '') and
                               (Item.GetFilter("Location Filter") = '') and
                               WhseEntry.IsEmpty
                            then begin
                                Clear(TempQuantityOnHandBuffer);
                                TempQuantityOnHandBuffer."Item No." := Item."No.";
                                OnItemLedgerEntryOnPreDataItemOnBeforeInsertQuantityOnHandBuffer(TempQuantityOnHandBuffer, Item);
                                TempQuantityOnHandBuffer.Insert();
                            end;
                        end;

                    OnItemLedgerEntryOnAfterPreDataItem("Item Ledger Entry", Item);
                end;
            }
            dataitem("Warehouse Entry"; "Warehouse Entry")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter");
                DataItemTableView = sorting("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type", Dedicated, "Package No.", "Bin Type Code", "SIFT Bucket No.");

                trigger OnPreDataItem()
                begin
                    if not "Item Ledger Entry".IsEmpty() then
                        CurrReport.Break(); // Skip if item has any record in Item Ledger Entry.                    
                end;

                trigger OnAfterGetRecord()
                var
                    ItemVariant: Record "Item Variant";
                begin
                    if not "Item Ledger Entry".IsEmpty() then
                        CurrReport.Break();   // Skip if item has any record in Item Ledger Entry.

                    if "Warehouse Entry"."Variant Code" <> '' then begin
                        ItemVariant.SetLoadFields(Blocked);
                        if ItemVariant.Get("Item No.", "Variant Code") and ItemVariant.Blocked then
                            CurrReport.Skip();
                    end;

                    Clear(TempQuantityOnHandBuffer);
                    TempQuantityOnHandBuffer."Item No." := "Item No.";
                    TempQuantityOnHandBuffer."Location Code" := "Location Code";
                    TempQuantityOnHandBuffer."Variant Code" := "Variant Code";

                    this.GetLocation("Location Code");
                    if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                        TempQuantityOnHandBuffer."Bin Code" := "Bin Code";

                    OnBeforeQuantityOnHandBufferFindAndInsert(TempQuantityOnHandBuffer, "Warehouse Entry");
                    if not TempQuantityOnHandBuffer.Find() then
                        TempQuantityOnHandBuffer.Insert();   // Insert a zero quantity line.
                end;
            }
            dataitem(ItemWithNoTransaction; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    if IncludeItemWithNoTransaction then
                        UpdateQuantityOnHandBuffer(Item."No.");
                end;
            }

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeItemOnAfterGetRecord(Item, IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if not HideValidationDialog then
                    Window.Update();
                TempSKU.DeleteAll();
            end;

            trigger OnPostDataItem()
            begin
                CalcPhysInvQtyAndInsertItemJnlLine();
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

                OnPreDataItemOnAfterGetItemJnlTemplateAndBatch(ItemJnlTemplate, ItemJnlBatch);

                if NextDocNo = '' then begin
                    if ItemJnlBatch."No. Series" <> '' then begin
                        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
                        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
                        if not ItemJnlLine.FindFirst() then
                            NextDocNo := NoSeriesBatch.GetNextNo(ItemJnlBatch."No. Series", PostingDate);
                        ItemJnlLine.Init();
                    end;
                    if NextDocNo = '' then
                        Error(Text001);
                end;

                NextLineNo := 0;

                if not HideValidationDialog then
                    Window.Open(Text002, "No.");

                if not SkipDim then
                    SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Calculate Inventory", '', TempSelectedDim);

                TempQuantityOnHandBuffer.Reset();
                TempQuantityOnHandBuffer.DeleteAll();

                OnAfterItemOnPreDataItem(Item, ZeroQty, IncludeItemWithNoTransaction);
            end;
        }
    }

    requestpage
    {
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the date for the posting of this batch job. By default, the working date is entered, but you can change it.';

                        trigger OnValidate()
                        begin
                            ValidatePostingDate();
                        end;
                    }
                    field(DocumentNo; NextDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ShowMandatory = DocumentNoInputMandatory;
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                    }
                    field(ItemsNotOnInventory; ZeroQty)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Items Not on Inventory.';
                        ToolTip = 'Specifies if journal lines should be created for items that are not on inventory, that is, items where the value in the Qty. (Calculated) field is 0.';

                        trigger OnValidate()
                        begin
                            if not ZeroQty then
                                IncludeItemWithNoTransaction := false;
                        end;
                    }
                    field(IncludeItemWithNoTransaction; IncludeItemWithNoTransaction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Item without Transactions';
                        ToolTip = 'Specifies if journal lines should be created for items that are not on inventory and are not used in any transactions.';

                        trigger OnValidate()
                        begin
                            if not IncludeItemWithNoTransaction then
                                exit;
                            if not ZeroQty then
                                Error(ItemNotOnInventoryErr);
                        end;
                    }
                    field(ByDimensions; ColumnDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'By Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies the dimensions that you want the batch job to consider.';

                        trigger OnAssistEdit()
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Calculate Inventory", ColumnDim);
                        end;
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
            ColumnDim := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Calculate Inventory", '');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport(ItemJnlLine, PostingDate);

        if SkipDim then
            ColumnDim := ''
        else
            DimSelectionBuf.CompareDimText(3, REPORT::"Calculate Inventory", '', ColumnDim, Text003);
        ZeroQtySave := ZeroQty;
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        DimSetEntry: Record "Dimension Set Entry";
        OldWhseEntry: Record "Warehouse Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        TempDimBufIn: Record "Dimension Buffer" temporary;
        TempDimBufOut: Record "Dimension Buffer" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        NextLineNo: Integer;
        ZeroQtySave: Boolean;
        AdjustPosQty: Boolean;
        DocumentNoInputMandatory: Boolean;
        PosQty: Decimal;
        NegQty: Decimal;
        ItemNotOnInventoryErr: Label 'Items Not on Inventory.';

#pragma warning disable AA0074
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Enter the document no.';
#pragma warning disable AA0470
        Text002: Label 'Processing items    #1##########';
#pragma warning restore AA0470
        Text003: Label 'Retain Dimensions';
#pragma warning restore AA0074

    protected var
        WhseEntry: Record "Warehouse Entry";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        TempQuantityOnHandBuffer: Record "Inventory Buffer" temporary;
        TempSKU: Record "Stockkeeping Unit" temporary;
        CycleSourceType: Option " ",Item,SKU;
        ItemTrackingSplit: Boolean;
        HideValidationDialog: Boolean;
        PhysInvtCountCode: Code[10];
        PostingDate: Date;
        NextDocNo: Code[20];
        ZeroQty: Boolean;
        IncludeItemWithNoTransaction: Boolean;
        ColumnDim: Text[250];
        SkipDim: Boolean;

    procedure SetItemJnlLine(var NewItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine := NewItemJnlLine;
    end;

    procedure ValidatePostingDate()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if not ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name") then
            exit;

        if ItemJnlBatch."No. Series" = '' then begin
            DocumentNoInputMandatory := true;
            NextDocNo := ''
        end else begin
            DocumentNoInputMandatory := false;
            NextDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", PostingDate);
        end;
    end;

    procedure InsertItemJnlLine(ItemNo: Code[20]; VariantCode2: Code[10]; DimEntryNo2: Integer; BinCode2: Code[20]; Quantity2: Decimal; PhysInvQuantity: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        Bin: Record Bin;
        DimValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
        NoBinExist: Boolean;
        ShouldInsertItemJnlLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFunctionInsertItemJnlLine(ItemNo, VariantCode2, DimEntryNo2, BinCode2, Quantity2, PhysInvQuantity, ItemJnlLine, IsHandled, Location);
        if not IsHandled then begin
            if NextLineNo = 0 then begin
                ItemJnlLine.LockTable();
                ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
                if ItemJnlLine.FindLast() then
                    NextLineNo := ItemJnlLine."Line No.";

                SourceCodeSetup.Get();
            end;
            NextLineNo := NextLineNo + 10000;
            ShouldInsertItemJnlLine := (Quantity2 <> 0) or ZeroQty;
            OnInsertItemJnlLineOnAfterCalcShouldInsertItemJnlLine(ItemNo, VariantCode2, DimEntryNo2, BinCode2, Quantity2, PhysInvQuantity, ZeroQty, ShouldInsertItemJnlLine, Location, NextLineNo);
            if ShouldInsertItemJnlLine then begin
                if (Quantity2 = 0) and Location."Bin Mandatory" and not Location."Directed Put-away and Pick"
                then
                    if not Bin.Get(Location.Code, BinCode2) then
                        NoBinExist := true;

                OnInsertItemJnlLineOnBeforeInit(ItemJnlLine);

                ItemJnlLine.Init();
                ItemJnlLine."Line No." := NextLineNo;
                ItemJnlLine.Validate("Posting Date", PostingDate);
                if PhysInvQuantity >= Quantity2 then
                    ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.")
                else
                    ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
                ItemJnlLine.Validate("Document No.", NextDocNo);

                OnInsertItemJnlLineOnBeforeValidateItemNo(ItemJnlLine);
                ItemJnlLine.Validate("Item No.", ItemNo);
                ItemJnlLine.Validate("Variant Code", VariantCode2);
                ItemJnlLine.Validate("Location Code", Location.Code);
                OnInsertItemJnlLineOnAfterValidateLocationCode(ItemNo, VariantCode2, DimEntryNo2, BinCode2, Quantity2, PhysInvQuantity, ItemJnlLine);
                if not NoBinExist then
                    ItemJnlLine.Validate("Bin Code", BinCode2)
                else
                    ItemJnlLine.Validate("Bin Code", '');
                ItemJnlLine.Validate("Source Code", SourceCodeSetup."Phys. Inventory Journal");
                ItemJnlLine."Qty. (Phys. Inventory)" := PhysInvQuantity;
                ItemJnlLine."Phys. Inventory" := true;
                ItemJnlLine.Validate("Qty. (Calculated)", Quantity2);
                ItemJnlLine."Posting No. Series" := ItemJnlBatch."Posting No. Series";
                ItemJnlLine."Reason Code" := ItemJnlBatch."Reason Code";

                ItemJnlLine."Phys Invt Counting Period Code" := PhysInvtCountCode;
                ItemJnlLine."Phys Invt Counting Period Type" := CycleSourceType;

                if Location."Bin Mandatory" then
                    ItemJnlLine."Dimension Set ID" := 0;
                ItemJnlLine."Shortcut Dimension 1 Code" := '';
                ItemJnlLine."Shortcut Dimension 2 Code" := '';

                ItemLedgEntry.Reset();
                ItemLedgEntry.SetCurrentKey("Item No.", "Entry No.");
                ItemLedgEntry.SetLoadFields("Entry No.");
                ItemLedgEntry.SetRange("Item No.", ItemNo);
                if ItemLedgEntry.FindLast() then
                    ItemJnlLine."Last Item Ledger Entry No." := ItemLedgEntry."Entry No."
                else
                    ItemJnlLine."Last Item Ledger Entry No." := 0;

                OnBeforeInsertItemJnlLine(ItemJnlLine, TempQuantityOnHandBuffer);
                ItemJnlLine.Insert(true);
                OnAfterInsertItemJnlLine(ItemJnlLine);

                if Location.Code <> '' then
                    if Location."Directed Put-away and Pick" then
                        ReserveWarehouse(ItemJnlLine);

                if ColumnDim = '' then
                    DimEntryNo2 := CreateDimFromDefault();

                if DimBufMgt.GetDimensions(DimEntryNo2, TempDimBufOut) then begin
                    TempDimSetEntry.Reset();
                    TempDimSetEntry.DeleteAll();
                    if TempDimBufOut.Find('-') then
                        repeat
                            DimValue.Get(TempDimBufOut."Dimension Code", TempDimBufOut."Dimension Value Code");
                            TempDimSetEntry."Dimension Code" := TempDimBufOut."Dimension Code";
                            TempDimSetEntry."Dimension Value Code" := TempDimBufOut."Dimension Value Code";
                            TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
                            if TempDimSetEntry.Insert() then;
                            ItemJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
                            DimMgt.UpdateGlobalDimFromDimSetID(ItemJnlLine."Dimension Set ID",
                              ItemJnlLine."Shortcut Dimension 1 Code", ItemJnlLine."Shortcut Dimension 2 Code");
                            OnInsertItemJnlLineOnAfterUpdateDimensionSetID(ItemJnlLine);
                            ItemJnlLine.Modify();
                        until TempDimBufOut.Next() = 0;
                    TempDimBufOut.DeleteAll();
                end;
            end;
        end;

        OnAfterFunctionInsertItemJnlLine(ItemNo, VariantCode2, DimEntryNo2, BinCode2, Quantity2, PhysInvQuantity, ItemJnlLine);
    end;

    local procedure InsertQuantityOnHandBuffer(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        TempQuantityOnHandBuffer.Reset();
        TempQuantityOnHandBuffer.SetRange("Item No.", ItemNo);
        TempQuantityOnHandBuffer.SetRange("Location Code", LocationCode);
        TempQuantityOnHandBuffer.SetRange("Variant Code", VariantCode);
        if not TempQuantityOnHandBuffer.FindFirst() then begin
            TempQuantityOnHandBuffer.Reset();
            TempQuantityOnHandBuffer.Init();
            TempQuantityOnHandBuffer."Item No." := ItemNo;
            TempQuantityOnHandBuffer."Location Code" := LocationCode;
            TempQuantityOnHandBuffer."Variant Code" := VariantCode;
            TempQuantityOnHandBuffer."Bin Code" := '';
            TempQuantityOnHandBuffer."Dimension Entry No." := 0;
            OnInsertQuantityOnHandBufferOnBeforeInsert(TempQuantityOnHandBuffer);
            TempQuantityOnHandBuffer.Insert(true);
        end;
    end;

    local procedure ReserveWarehouse(ItemJnlLine: Record "Item Journal Line")
    var
        ReservEntry: Record "Reservation Entry";
        WhseEntry: Record "Warehouse Entry";
        WhseEntry2: Record "Warehouse Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        EntryType: Option "Negative Adjmt.","Positive Adjmt.";
        OrderLineNo: Integer;
    begin
        WhseEntry.SetCurrentKey(
            "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code",
            "Lot No.", "Serial No.", "Entry Type");
        WhseEntry.SetRange("Item No.", ItemJnlLine."Item No.");
        WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
        WhseEntry.SetRange("Location Code", ItemJnlLine."Location Code");
        WhseEntry.SetRange("Variant Code", ItemJnlLine."Variant Code");
        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Positive Adjmt." then
            EntryType := EntryType::"Negative Adjmt.";
        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt." then
            EntryType := EntryType::"Positive Adjmt.";
        OnAfterWhseEntrySetFilters(WhseEntry, ItemJnlLine);
        WhseEntry.SetRange("Entry Type", EntryType);
        if WhseEntry.Find('-') then
            repeat
                WhseEntry.SetTrackingFilterFromWhseEntry(WhseEntry);
                WhseEntry.CalcSums("Qty. (Base)");

                WhseEntry2.SetCurrentKey(
                    "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code",
                    "Lot No.", "Serial No.", "Entry Type");
                WhseEntry2.CopyFilters(WhseEntry);
                case EntryType of
                    EntryType::"Positive Adjmt.":
                        WhseEntry2.SetRange("Entry Type", WhseEntry2."Entry Type"::"Negative Adjmt.");
                    EntryType::"Negative Adjmt.":
                        WhseEntry2.SetRange("Entry Type", WhseEntry2."Entry Type"::"Positive Adjmt.");
                end;
                OnReserveWarehouseOnAfterWhseEntry2SetFilters(ItemJnlLine, WhseEntry, WhseEntry2, EntryType);
                WhseEntry2.CalcSums("Qty. (Base)");
                if Abs(WhseEntry2."Qty. (Base)") > Abs(WhseEntry."Qty. (Base)") then
                    WhseEntry."Qty. (Base)" := 0
                else
                    WhseEntry."Qty. (Base)" := WhseEntry."Qty. (Base)" + WhseEntry2."Qty. (Base)";

                if WhseEntry."Qty. (Base)" <> 0 then begin
                    if ItemJnlLine."Order Type" = ItemJnlLine."Order Type"::Production then
                        OrderLineNo := ItemJnlLine."Order Line No.";
                    ReservEntry.CopyTrackingFromWhseEntry(WhseEntry);
                    CreateReservEntry.CreateReservEntryFor(
                        DATABASE::"Item Journal Line", ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", OrderLineNo,
                        ItemJnlLine."Line No.", ItemJnlLine."Qty. per Unit of Measure",
                        Abs(WhseEntry.Quantity), Abs(WhseEntry."Qty. (Base)"), ReservEntry);
                    if WhseEntry."Qty. (Base)" < 0 then
                        // only Date on positive adjustments
                        CreateReservEntry.SetDates(WhseEntry."Warranty Date", WhseEntry."Expiration Date");
                    CreateReservEntry.CreateEntry(
                        ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Location Code", ItemJnlLine.Description, 0D, 0D, 0, "Reservation Status"::Prospect);
                end;
                WhseEntry.Find('+');
                WhseEntry.ClearTrackingFilter();
            until WhseEntry.Next() = 0;
    end;

    procedure InitializeRequest(NewPostingDate: Date; DocNo: Code[20]; ItemsNotOnInvt: Boolean; InclItemWithNoTrans: Boolean)
    begin
        PostingDate := NewPostingDate;
        NextDocNo := DocNo;
        ZeroQty := ItemsNotOnInvt;
        IncludeItemWithNoTransaction := InclItemWithNoTrans and ZeroQty;
        if not SkipDim then
            ColumnDim := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Calculate Inventory", '');
    end;

    local procedure TransferDim(DimSetID: Integer)
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.Find('-') then
            repeat
                if TempSelectedDim.Get(
                     UserId, 3, REPORT::"Calculate Inventory", '', DimSetEntry."Dimension Code")
                then
                    InsertDim(DATABASE::"Item Ledger Entry", DimSetID, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
            until DimSetEntry.Next() = 0;
    end;

    local procedure CalcWhseQty(AdjmtBin: Code[20]; var PosQuantity: Decimal; var NegQuantity: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        WhseEntry2: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseQuantity: Decimal;
        NoWhseEntry: Boolean;
        NoWhseEntry2: Boolean;
    begin
        AdjustPosQty := false;
        ItemTrackingMgt.GetWhseItemTrkgSetup(TempQuantityOnHandBuffer."Item No.", WhseItemTrackingSetup);
        OnCalcWhseQtyOnAfterGetWhseItemTrkgSetup(TempQuantityOnHandBuffer."Location Code", WhseItemTrackingSetup);
        ItemTrackingSplit := WhseItemTrackingSetup.TrackingRequired();
        WhseEntry.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code",
          "Lot No.", "Serial No.", "Entry Type");

        WhseEntry.SetRange("Item No.", TempQuantityOnHandBuffer."Item No.");
        WhseEntry.SetRange("Location Code", TempQuantityOnHandBuffer."Location Code");
        WhseEntry.SetRange("Variant Code", TempQuantityOnHandBuffer."Variant Code");
        OnCalcWhseQtyOnAfterWhseEntrySetFilters(WhseEntry);
        WhseEntry.CalcSums("Qty. (Base)");
        WhseQuantity := WhseEntry."Qty. (Base)";
        WhseEntry.SetRange("Bin Code", AdjmtBin);

        if WhseItemTrackingSetup."Serial No. Required" then begin
            WhseEntry.SetRange("Entry Type", WhseEntry."Entry Type"::"Positive Adjmt.");
            WhseEntry.CalcSums("Qty. (Base)");
            PosQuantity := WhseQuantity - WhseEntry."Qty. (Base)";
            WhseEntry.SetRange("Entry Type", WhseEntry."Entry Type"::"Negative Adjmt.");
            WhseEntry.CalcSums("Qty. (Base)");
            NegQuantity := WhseQuantity - WhseEntry."Qty. (Base)";
            WhseEntry.SetRange("Entry Type", WhseEntry."Entry Type"::Movement);
            WhseEntry.CalcSums("Qty. (Base)");
            if WhseEntry."Qty. (Base)" <> 0 then
                if WhseEntry."Qty. (Base)" > 0 then
                    PosQuantity := PosQuantity + WhseQuantity - WhseEntry."Qty. (Base)"
                else
                    NegQuantity := NegQuantity - WhseQuantity - WhseEntry."Qty. (Base)";

            WhseEntry.SetRange("Entry Type", WhseEntry."Entry Type"::"Positive Adjmt.");
            if WhseEntry.Find('-') then
                repeat
                    WhseEntry.SetRange("Serial No.", WhseEntry."Serial No.");

                    WhseEntry2.Reset();
                    WhseEntry2.SetCurrentKey(
                      "Item No.", "Bin Code", "Location Code", "Variant Code",
                      "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");

                    WhseEntry2.CopyFilters(WhseEntry);
                    WhseEntry2.SetRange("Entry Type", WhseEntry2."Entry Type"::"Negative Adjmt.");
                    WhseEntry2.SetRange("Serial No.", WhseEntry."Serial No.");
                    if WhseEntry2.Find('-') then
                        repeat
                            PosQuantity := PosQuantity + 1;
                            NegQuantity := NegQuantity - 1;
                            NoWhseEntry := WhseEntry.Next() = 0;
                            NoWhseEntry2 := WhseEntry2.Next() = 0;
                        until NoWhseEntry2 or NoWhseEntry
                    else
                        AdjustPosQty := true;

                    if not NoWhseEntry and NoWhseEntry2 then
                        AdjustPosQty := true;

                    WhseEntry.Find('+');
                    WhseEntry.SetRange("Serial No.");
                until WhseEntry.Next() = 0;
        end else begin
            if WhseEntry.Find('-') then
                repeat
                    WhseEntry.SetRange("Lot No.", WhseEntry."Lot No.");
                    WhseEntry.SetRange("Package No.", WhseEntry."Package No.");
                    OnCalcWhseQtyOnAfterLotRequiredWhseEntrySetFilters(WhseEntry);
                    WhseEntry.CalcSums("Qty. (Base)");
                    if WhseEntry."Qty. (Base)" <> 0 then
                        if WhseEntry."Qty. (Base)" > 0 then
                            NegQuantity := NegQuantity - WhseEntry."Qty. (Base)"
                        else
                            PosQuantity := PosQuantity + WhseEntry."Qty. (Base)";
                    WhseEntry.Find('+');
                    WhseEntry.SetRange("Lot No.");
                    WhseEntry.SetRange("Package No.");
                    OnCalcWhseQtyOnAfterLotRequiredWhseEntryClearFilters(WhseEntry);
                until WhseEntry.Next() = 0;
            if PosQuantity <> WhseQuantity then
                PosQuantity := WhseQuantity - PosQuantity;
            if NegQuantity <> -WhseQuantity then
                NegQuantity := WhseQuantity + NegQuantity;
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure InitializePhysInvtCount(PhysInvtCountCode2: Code[10]; CountSourceType2: Option " ",Item,SKU)
    begin
        PhysInvtCountCode := PhysInvtCountCode2;
        CycleSourceType := CountSourceType2;
    end;

    local procedure SkipCycleSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    var
        SKU: Record "Stockkeeping Unit";
    begin
        if CycleSourceType = CycleSourceType::Item then
            if SKU.ReadPermission then
                if SKU.Get(LocationCode, ItemNo, VariantCode) then
                    exit(true);
        exit(false);
    end;

    procedure GetLocation(LocationCode: Code[10]): Boolean
    begin
        if LocationCode = '' then begin
            Clear(Location);
            exit(true);
        end;

        if Location.Code <> LocationCode then
            if not Location.Get(LocationCode) then
                exit(false);

        exit(true);
    end;

    local procedure UpdateBuffer(BinCode: Code[20]; NewQuantity: Decimal; CalledFromItemLedgerEntry: Boolean)
    var
        DimEntryNo: Integer;
    begin
        if not HasNewQuantity(NewQuantity) then
            exit;
        if BinCode = '' then begin
            if ColumnDim <> '' then
                TempDimBufIn.SetRange("Entry No.", "Item Ledger Entry"."Dimension Set ID");
            DimEntryNo := DimBufMgt.FindDimensions(TempDimBufIn);
            if DimEntryNo = 0 then
                DimEntryNo := DimBufMgt.InsertDimensions(TempDimBufIn);
        end;
        if RetrieveBuffer(BinCode, DimEntryNo) then begin
            TempQuantityOnHandBuffer.Quantity := TempQuantityOnHandBuffer.Quantity + NewQuantity;
            OnUpdateBufferOnBeforeModify(TempQuantityOnHandBuffer, CalledFromItemLedgerEntry);
            TempQuantityOnHandBuffer.Modify();
        end else begin
            TempQuantityOnHandBuffer.Quantity := NewQuantity;
            OnUpdateBufferOnBeforeInsert(TempQuantityOnHandBuffer, CalledFromItemLedgerEntry);
            TempQuantityOnHandBuffer.Insert();
        end;
    end;

    local procedure RetrieveBuffer(BinCode: Code[20]; DimEntryNo: Integer) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveBuffer(TempQuantityOnHandBuffer, "Item Ledger Entry", BinCode, DimEntryNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempQuantityOnHandBuffer.Reset();
        TempQuantityOnHandBuffer."Item No." := "Item Ledger Entry"."Item No.";
        TempQuantityOnHandBuffer."Variant Code" := "Item Ledger Entry"."Variant Code";
        TempQuantityOnHandBuffer."Location Code" := "Item Ledger Entry"."Location Code";
        TempQuantityOnHandBuffer."Dimension Entry No." := DimEntryNo;
        TempQuantityOnHandBuffer."Bin Code" := BinCode;
        OnRetrieveBufferOnBeforeFind(TempQuantityOnHandBuffer, "Item Ledger Entry");
        exit(TempQuantityOnHandBuffer.Find());
    end;

    local procedure HasNewQuantity(NewQuantity: Decimal): Boolean
    begin
        exit((NewQuantity <> 0) or ZeroQty);
    end;

    local procedure ItemBinLocationIsCalculated(BinCode: Code[20]): Boolean
    var
        IsHandled: Boolean;
        IsCalculated: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemBinLocationIsCalculated("Item Ledger Entry", IsHandled, IsCalculated, WhseEntry);
        if IsHandled then
            exit(IsCalculated);

        TempQuantityOnHandBuffer.Reset();
        TempQuantityOnHandBuffer.SetRange("Item No.", "Item Ledger Entry"."Item No.");
        TempQuantityOnHandBuffer.SetRange("Variant Code", "Item Ledger Entry"."Variant Code");
        TempQuantityOnHandBuffer.SetRange("Location Code", "Item Ledger Entry"."Location Code");
        TempQuantityOnHandBuffer.SetRange("Bin Code", BinCode);
        OnItemBinLocationIsCalculatedOnBeforeFind(TempQuantityOnHandBuffer, "Item Ledger Entry");
        exit(TempQuantityOnHandBuffer.Find('-'));
    end;

    procedure SetSkipDim(NewSkipDim: Boolean)
    begin
        SkipDim := NewSkipDim;
    end;

    procedure AddZeroQtySKU()
    var
        SKU: Record "Stockkeeping Unit";
        ShouldAddZeroQty: Boolean;
        IsHandled: Boolean;
    begin
        ShouldAddZeroQty := ZeroQty;
        OnAddZeroQtyOnAfterCalcShouldAddZeroQty(Item, ZeroQty, ShouldAddZeroQty);
        if not ShouldAddZeroQty then
            exit;

        SKU.SetCurrentKey("Item No.");
        SKU.SetRange("Item No.", Item."No.");
        Item.CopyFilter("Variant Filter", SKU."Variant Code");
        Item.CopyFilter("Location Filter", SKU."Location Code");
        OnAddZeroQtyOnAfterFilterSKU(Item, SKU);
        if SKU.Find('-') then begin
            TempQuantityOnHandBuffer.Reset();
            TempQuantityOnHandBuffer.SetRange("Item No.", Item."No.");
            IsHandled := false;
            OnAddZeroQtySKUOnBeforeInsertZeroQtySKU(Item, SKU, TempQuantityOnHandBuffer, IsHandled);
            if not IsHandled then
                repeat
                    TempQuantityOnHandBuffer.SetRange("Variant Code", SKU."Variant Code");
                    TempQuantityOnHandBuffer.SetRange("Location Code", SKU."Location Code");
                    if not TempQuantityOnHandBuffer.Find('-') then begin
                        Clear(TempQuantityOnHandBuffer);
                        TempQuantityOnHandBuffer."Item No." := SKU."Item No.";
                        TempQuantityOnHandBuffer."Variant Code" := SKU."Variant Code";
                        TempQuantityOnHandBuffer."Location Code" := SKU."Location Code";
                        OnAddZeroQtySKUOnBeforeInsertQuantityOnHandBuffer(TempQuantityOnHandBuffer, SKU, Item);
                        TempQuantityOnHandBuffer.Insert();
                    end;
                until SKU.Next() = 0;
        end;
    end;

    local procedure UpdateQuantityOnHandBuffer(ItemNo: Code[20])
    var
        Location: Record Location;
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetRange("Item No.", Item."No.");
        Item.CopyFilter("Variant Filter", ItemVariant.Code);
        Item.CopyFilter("Location Filter", Location.Code);
        Location.SetRange("Use As In-Transit", false);
        if (Item.GetFilter("Location Filter") <> '') and Location.FindSet() then
            repeat
                if (Item.GetFilter("Variant Filter") <> '') and ItemVariant.FindSet() then
                    repeat
                        InsertQuantityOnHandBuffer(ItemNo, Location.Code, ItemVariant.Code);
                    until ItemVariant.Next() = 0
                else
                    InsertQuantityOnHandBuffer(ItemNo, Location.Code, '');
            until Location.Next() = 0
        else
            if (Item.GetFilter("Variant Filter") <> '') and ItemVariant.FindSet() then
                repeat
                    InsertQuantityOnHandBuffer(ItemNo, '', ItemVariant.Code);
                until ItemVariant.Next() = 0
            else
                InsertQuantityOnHandBuffer(ItemNo, '', '');
    end;

    local procedure CalcPhysInvQtyAndInsertItemJnlLine()
    begin
        AddZeroQtySKU();

        TempQuantityOnHandBuffer.Reset();
        OnCalcPhysInvQtyAndInsertItemJnlLineOnBeforeFindset(TempQuantityOnHandBuffer);
        if TempQuantityOnHandBuffer.FindSet() then begin
            repeat
                PosQty := 0;
                NegQty := 0;

                GetLocation(TempQuantityOnHandBuffer."Location Code");
                if Location."Directed Put-away and Pick" then
                    CalcWhseQty(Location."Adjustment Bin Code", PosQty, NegQty);

                if (NegQty - TempQuantityOnHandBuffer.Quantity <> TempQuantityOnHandBuffer.Quantity - PosQty) or ItemTrackingSplit then begin
                    if PosQty = TempQuantityOnHandBuffer.Quantity then
                        PosQty := 0;
                    if (PosQty <> 0) or AdjustPosQty then
                        InsertItemJnlLine(
                          TempQuantityOnHandBuffer."Item No.", TempQuantityOnHandBuffer."Variant Code", TempQuantityOnHandBuffer."Dimension Entry No.",
                          TempQuantityOnHandBuffer."Bin Code", TempQuantityOnHandBuffer.Quantity, PosQty);

                    if NegQty = TempQuantityOnHandBuffer.Quantity then
                        NegQty := 0;
                    if NegQty <> 0 then begin
                        if ((PosQty <> 0) or AdjustPosQty) and not ItemTrackingSplit then begin
                            NegQty := NegQty - TempQuantityOnHandBuffer.Quantity;
                            TempQuantityOnHandBuffer.Quantity := 0;
                            ZeroQty := true;
                        end;
                        if NegQty = -TempQuantityOnHandBuffer.Quantity then begin
                            NegQty := 0;
                            AdjustPosQty := true;
                        end;
                        InsertItemJnlLine(
                          TempQuantityOnHandBuffer."Item No.", TempQuantityOnHandBuffer."Variant Code", TempQuantityOnHandBuffer."Dimension Entry No.",
                          TempQuantityOnHandBuffer."Bin Code", TempQuantityOnHandBuffer.Quantity, NegQty);

                        ZeroQty := ZeroQtySave;
                    end;
                end else begin
                    PosQty := 0;
                    NegQty := 0;
                end;

                OnCalcPhysInvQtyAndInsertItemJnlLineOnBeforeCheckIfInsertNeeded(TempQuantityOnHandBuffer);
                if (PosQty = 0) and (NegQty = 0) and not AdjustPosQty then
                    InsertItemJnlLine(
                      TempQuantityOnHandBuffer."Item No.", TempQuantityOnHandBuffer."Variant Code", TempQuantityOnHandBuffer."Dimension Entry No.",
                      TempQuantityOnHandBuffer."Bin Code", TempQuantityOnHandBuffer.Quantity, TempQuantityOnHandBuffer.Quantity);
            until TempQuantityOnHandBuffer.Next() = 0;
            TempQuantityOnHandBuffer.DeleteAll();
        end;
    end;

    local procedure CreateDimFromDefault() DimEntryNo: Integer
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetFilter("No.", '%1|%2', TempQuantityOnHandBuffer."Item No.", TempQuantityOnHandBuffer."Location Code");
        DefaultDimension.SetFilter("Table ID", '%1|%2', DATABASE::Item, DATABASE::Location);
        DefaultDimension.SetFilter("Dimension Value Code", '<>%1', '');
        if DefaultDimension.FindSet() then
            repeat
                InsertDim(DefaultDimension."Table ID", 0, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
            until DefaultDimension.Next() = 0;

        DimEntryNo := DimBufMgt.InsertDimensions(TempDimBufIn);

        TempDimBufIn.SetFilter("Table ID", '%1|%2', DATABASE::Item, Database::Location);
        TempDimBufIn.DeleteAll();
    end;

    local procedure InsertDim(TableID: Integer; EntryNo: Integer; DimCode: Code[20]; DimValueCode: Code[20])
    begin
        TempDimBufIn.Init();
        TempDimBufIn."Table ID" := TableID;
        TempDimBufIn."Entry No." := EntryNo;
        TempDimBufIn."Dimension Code" := DimCode;
        TempDimBufIn."Dimension Value Code" := DimValueCode;
        if TempDimBufIn.Insert() then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemLedgEntryOnBeforeUpdateBuffer(var Item: Record Item; ItemLedgEntry: Record "Item Ledger Entry"; var ByBin: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemOnPreDataItem(var Item: Record Item; ZeroQty: Boolean; IncludeItemWithNoTransaction: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseEntrySetFilters(var WarehouseEntry: Record "Warehouse Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLedgerEntryOnAfterPreDataItem(var ItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLedgerEntryOnAfterGetRecordOnBeforeUpdateBuffer(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJnlLineOnBeforeInit(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertItemJnlLineOnAfterCalcShouldInsertItemJnlLine(ItemNo: Code[20]; VariantCode2: Code[10]; DimEntryNo2: Integer; BinCode2: Code[20]; Quantity2: Decimal; PhysInvQuantity: Decimal; ZeroQty: Boolean; var ShouldInsertItemJnlLine: Boolean; Location: Record Location; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJnlLineOnAfterValidateLocationCode(ItemNo: Code[20]; VariantCode2: Code[10]; DimEntryNo2: Integer; BinCode2: Code[20]; Quantity2: Decimal; PhysInvQuantity: Decimal; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddZeroQtySKUOnBeforeInsertQuantityOnHandBuffer(var TempInventoryBuffer: Record "Inventory Buffer" temporary; StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeItemOnAfterGetRecord(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFunctionInsertItemJnlLine(ItemNo: Code[20]; VariantCode2: Code[10]; DimEntryNo2: Integer; BinCode2: Code[20]; Quantity2: Decimal; PhysInvQuantity: Decimal; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var InventoryBuffer: Record "Inventory Buffer");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRetrieveBuffer(var TempInventoryBuffer: Record "Inventory Buffer" temporary; ItemLedgerEntry: Record "Item Ledger Entry"; BinCode: Code[20]; DimEntryNo: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeQuantityOnHandBufferFindAndInsert(var InventoryBuffer: Record "Inventory Buffer"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFunctionInsertItemJnlLine(ItemNo: Code[20]; VariantCode2: Code[10]; DimEntryNo2: Integer; BinCode2: Code[20]; Quantity2: Decimal; PhysInvQuantity: Decimal; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnItemLedgerEntryOnPreDataItemOnBeforeInsertQuantityOnHandBuffer(var TempInventoryBuffer: Record "Inventory Buffer" temporary; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLedgerEntryOnPreDataItemOnBeforeClearQuantityOnHandBuffer(var ItemLedgerEntry: Record "Item Ledger Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPhysInvQtyAndInsertItemJnlLineOnBeforeCheckIfInsertNeeded(InventoryBuffer: Record "Inventory Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPhysInvQtyAndInsertItemJnlLineOnBeforeFindset(var InventoryBuffer: Record "Inventory Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcWhseQtyOnAfterLotRequiredWhseEntryClearFilters(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcWhseQtyOnAfterLotRequiredWhseEntrySetFilters(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcWhseQtyOnAfterWhseEntrySetFilters(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJnlLineOnAfterUpdateDimensionSetID(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemOnAfterGetItemJnlTemplateAndBatch(var ItemJnlTemplate: Record "Item Journal Template"; var ItemJnlBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRetrieveBufferOnBeforeFind(var InventoryBuffer: Record "Inventory Buffer"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReserveWarehouseOnAfterWhseEntry2SetFilters(var ItemJnlLine: Record "Item Journal Line"; var WhseEntry: Record "Warehouse Entry"; var WhseEntry2: Record "Warehouse Entry"; EntryType: Option)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateBufferOnBeforeInsert(var InventoryBuffer: Record "Inventory Buffer"; CalledFromItemLedgerEntry: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateBufferOnBeforeModify(var InventoryBuffer: Record "Inventory Buffer"; CalledFromItemLedgerEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var ItemJournalLine: Record "Item Journal Line"; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddZeroQtyOnAfterFilterSKU(var Item: Record Item; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddZeroQtyOnAfterCalcShouldAddZeroQty(var Item: Record Item; ZeroQty: Boolean; var ShouldAddZeroQty: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddZeroQtySKUOnBeforeInsertZeroQtySKU(var Item: Record Item; var SKU: Record "Stockkeeping Unit"; var TempInventoryBuffer: Record "Inventory Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJnlLineOnBeforeValidateItemNo(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcWhseQtyOnAfterGetWhseItemTrkgSetup(LocationCode: Code[10]; var ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemBinLocationIsCalculated(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; var IsCalculated: Boolean; var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertQuantityOnHandBufferOnBeforeInsert(var InventoryBuffer: Record "Inventory Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseEntryLoopOnBeforeFindlast(var WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemLedgEntryOnBeforeWhseEntryFind(var WarehouseEntry: Record "Warehouse Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemBinLocationIsCalculatedOnBeforeFind(var InventoryBuffer: Record "Inventory Buffer"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
}

