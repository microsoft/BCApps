// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using System.Utilities;

codeunit 7304 "Whse. Jnl.-Register Batch"
{
    Permissions = TableData "Warehouse Journal Batch" = rimd,
                  TableData "Warehouse Entry" = rimd,
                  TableData "Warehouse Register" = rimd;
    TableNo = "Warehouse Journal Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        WhseJnlLine.Copy(Rec);
        Code();
        Rec := WhseJnlLine;
    end;

    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseJnlLine2: Record "Warehouse Journal Line";
        WhseJnlLine3: Record "Warehouse Journal Line";
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        WMSMgt: Codeunit "WMS Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        WhseRegNo: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        LineCount: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastRegisteredDocNo: Code[20];
        SuppressCommit: Boolean;
        PhysInvtCount: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Registering lines     #3###### @4@@@@@@@@@@@@@';
#pragma warning restore AA0470
        Text005: Label 'Item tracking lines defined for the source line must account for the same quantity as you have entered.';
        Text006: Label 'Item tracking lines do not match the bin content.';
#pragma warning disable AA0470
        Text007: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = 'One or more reservation entries exist for the item with Item No. = 1000, Location Code = BLUE, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        TempHandlingSpecification: Record "Tracking Specification" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        IsHandled := false;
        OnBeforeCode(WhseJnlLine, HideDialog, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        WhseJnlLine.ReadIsolation(IsolationLevel::UpdLock);
        WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
        WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
        WhseJnlLine.SetRange("Location Code", WhseJnlLine."Location Code");
        WhseJnlTemplate.Get(WhseJnlLine."Journal Template Name");
        WhseJnlBatch.Get(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
        OnCodeOnAfterWhseJnlBatchGet(WhseJnlBatch);

        if not WhseJnlLine.Find('=><') then begin
            WhseJnlLine."Line No." := 0;
            if not SuppressCommit then
                Commit();
            exit;
        end;

        if not HideDialog then begin
            Window.Open(
              Text001 +
              Text002 +
              Text003);
            Window.Update(1, WhseJnlLine."Journal Batch Name");
        end;
        CheckItemAvailability(WhseJnlLine);

        CheckLines(TempHandlingSpecification, HideDialog);
        SequenceNoMgt.AllocateSeqNoBuffer(Database::"Warehouse Entry", NoOfRecords);

        PhysInvtCount := false;
        // Register lines
        LineCount := 0;
        LastDocNo := '';
        LastDocNo2 := '';
        LastRegisteredDocNo := '';
        WhseJnlLine.SetCurrentKey("Item No.", "Location Code", "Bin Code", "Line No.");  // to avoid deadlocks
        WhseJnlLine.FindSet();
        OnBeforeRegisterLines(WhseJnlLine, TempHandlingSpecification);

        BindSubscription(this);  // so we know if a warehouse register is created

        repeat
            if not WhseJnlLine.EmptyLine() and
               (WhseJnlBatch."No. Series" <> '') and
               (WhseJnlLine."Whse. Document No." <> LastDocNo2)
            then
                WhseJnlLine.TestField("Whse. Document No.", NoSeriesBatch.GetNextNo(WhseJnlBatch."No. Series", WhseJnlLine."Registering Date"));
            if not WhseJnlLine.EmptyLine() then
                LastDocNo2 := WhseJnlLine."Whse. Document No.";
            if WhseJnlLine."Registering No. Series" = '' then
                WhseJnlLine."Registering No. Series" := WhseJnlBatch."No. Series"
            else
                if not WhseJnlLine.EmptyLine() then
                    if WhseJnlLine."Whse. Document No." = LastDocNo then
                        WhseJnlLine."Whse. Document No." := LastRegisteredDocNo
                    else begin
                        LastDocNo := WhseJnlLine."Whse. Document No.";
                        WhseJnlLine."Whse. Document No." := NoSeriesBatch.GetNextNo(WhseJnlLine."Registering No. Series", WhseJnlLine."Registering Date");
                        LastRegisteredDocNo := WhseJnlLine."Whse. Document No.";
                    end;

            LineCount := LineCount + 1;
            if not HideDialog then begin
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            end;

            if WhseJnlLine.Quantity < 0 then
                WMSMgt.CalcCubageAndWeight(
                  WhseJnlLine."Item No.", WhseJnlLine."Unit of Measure Code", WhseJnlLine."Qty. (Absolute)", WhseJnlLine.Cubage, WhseJnlLine.Weight);

            ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, false);
            if TempWhseJnlLine2.Find('-') then
                repeat
                    OnBeforeWhseJnlRegisterLineRun(TempWhseJnlLine2, WhseJnlTemplate);
                    WhseJnlRegisterLine.Run(TempWhseJnlLine2);
                until TempWhseJnlLine2.Next() = 0;

            PostItemJnlLine();

            if IsPhysInvtCount(WhseJnlTemplate, WhseJnlLine."Phys Invt Counting Period Code", WhseJnlLine."Phys Invt Counting Period Type") then begin
                if not PhysInvtCount then begin
                    PhysInvtCountMgt.InitTempItemSKUList();
                    PhysInvtCount := true;
                end;
                PhysInvtCountMgt.AddToTempItemSKUList(WhseJnlLine."Item No.", WhseJnlLine."Location Code", WhseJnlLine."Variant Code", WhseJnlLine."Phys Invt Counting Period Type");
            end;
        until WhseJnlLine.Next() = 0;

        UnBindSubscription(this);

        WhseJnlLine.Init();
        WhseJnlLine."Line No." := WhseRegNo;
        UpdateDeleteLines();

        NoSeriesBatch.SaveState();

        if PhysInvtCount then
            PhysInvtCountMgt.UpdateItemSKUListPhysInvtCount();

        OnAfterPostJnlLines(WhseJnlBatch, WhseJnlLine, WhseRegNo, WhseJnlRegisterLine, SuppressCommit);

        if not HideDialog then
            Window.Close();
        if not SuppressCommit then
            Commit();
        Clear(WhseJnlRegisterLine);

        OnAfterCode(WhseJnlLine, WhseJnlBatch, WhseRegNo);
    end;

    local procedure PostItemJnlLine()
    var
        ItemJnlLine: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLine(ItemJnlPostLine, WhseJnlLine, WhseJnlTemplate, IsHandled);
        if IsHandled then
            exit;

        if WhseJnlLine.IsReclass(WhseJnlLine."Journal Template Name") then
            if CreateItemJnlLine(WhseJnlLine, ItemJnlLine) then
                ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        OnAfterItemJnlPostLine(WhseJnlLine);
    end;

    local procedure CheckLines(var TempTrackingSpecification: Record "Tracking Specification" temporary; HideDialog: Boolean)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        LineCount := 0;
        StartLineNo := WhseJnlLine."Line No.";
        ItemTrackingMgt.InitCollectItemTrkgInformation();
        repeat
            LineCount := LineCount + 1;
            if not HideDialog then
                Window.Update(2, LineCount);
            IsHandled := false;
            OnCheckLinesOnBeforeCheckWhseJnlLine(WhseJnlLine, IsHandled);
            if not IsHandled then
                WMSMgt.CheckWhseJnlLine(WhseJnlLine, 4, WhseJnlLine."Qty. (Absolute, Base)", false);
            if WhseJnlLine."Entry Type" in [WhseJnlLine."Entry Type"::"Positive Adjmt.", WhseJnlLine."Entry Type"::Movement] then
                UpdateTempBinContentBuffer(WhseJnlLine, WhseJnlLine."To Bin Code", true);
            if WhseJnlLine."Entry Type" in [WhseJnlLine."Entry Type"::"Negative Adjmt.", WhseJnlLine."Entry Type"::Movement] then
                UpdateTempBinContentBuffer(WhseJnlLine, WhseJnlLine."From Bin Code", false);

            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseJnlLine."Item No.", WhseItemTrackingSetup);
            OnCheckLinesOnAfterGetWhseItemTrkgSetup(WhseJnlLine, WhseItemTrackingSetup);
            if WhseItemTrackingSetup.TrackingRequired() then begin
                if WhseItemTrackingSetup."Serial No. Required" then
                    WhseJnlLine.TestField("Qty. per Unit of Measure", 1);
                if WhseJnlTemplate.Type <> WhseJnlTemplate.Type::"Physical Inventory" then
                    CreateTrackingSpecification(WhseJnlLine, TempTrackingSpecification)
                else begin
                    OnCheckWhseJnlLine(WhseJnlLine);
                    WhseJnlLine.CheckTrackingIfRequired(WhseItemTrackingSetup);
                end;
            end;
            ItemTrackingMgt.CollectItemTrkgInfWhseJnlLine(WhseJnlLine);
            OnAfterCollectTrackingInformation(WhseJnlLine);
            if WhseJnlLine.Next() = 0 then
                WhseJnlLine.Find('-');
        until WhseJnlLine."Line No." = StartLineNo;
        ItemTrackingMgt.CheckItemTrkgInfBeforePost();
        CheckIncreaseBin();
        NoOfRecords := LineCount;
    end;

    local procedure UpdateDeleteLines()
    var
        IncrBatchName: Boolean;
        SkipUpdate: Boolean;
    begin
        SkipUpdate := WhseRegNo = 0;
        OnBeforeUpdateDeleteLines(WhseJnlLine, WhseRegNo, SkipUpdate);
        if SkipUpdate then
            exit;
        // Not a recurring journal
        WhseJnlLine2.CopyFilters(WhseJnlLine);
        WhseJnlLine2.SetFilter("Item No.", '<>%1', '');
        if WhseJnlLine2.FindLast() then;
        // Remember the last line
        if WhseJnlLine.Find('-') then begin
            repeat
                ItemTrackingMgt.DeleteWhseItemTrkgLines(
                    Database::"Warehouse Journal Line", 0, WhseJnlLine."Journal Batch Name",
                    WhseJnlLine."Journal Template Name", 0, WhseJnlLine."Line No.", WhseJnlLine."Location Code", true);
            until WhseJnlLine.Next() = 0;
            WhseJnlLine.DeleteAll();
        end;

        WhseJnlLine3.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
        WhseJnlLine3.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
        WhseJnlLine3.SetRange("Location Code", WhseJnlLine."Location Code");
        if not WhseJnlLine3.FindLast() then
            IncrBatchName := IncStr(WhseJnlLine."Journal Batch Name") <> '';
        if WhseJnlTemplate."Increment Batch Name" then
            IncreaseBatchName(IncrBatchName);

        WhseJnlLine3.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
        if (WhseJnlBatch."No. Series" = '') and not WhseJnlLine3.FindLast() then begin
            WhseJnlLine3.Init();
            WhseJnlLine3."Journal Template Name" := WhseJnlLine."Journal Template Name";
            WhseJnlLine3."Journal Batch Name" := WhseJnlLine."Journal Batch Name";
            WhseJnlLine3."Location Code" := WhseJnlLine."Location Code";
            WhseJnlLine3."Line No." := 10000;
            WhseJnlLine3.Insert();
            WhseJnlLine3.SetUpNewLine(WhseJnlLine2);
            WhseJnlLine3.Modify();
        end;
    end;

    local procedure IncreaseBatchName(IncrBatchName: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncrBatchName(WhseJnlLine3, IncrBatchName, IsHandled);
        if IsHandled then
            exit;

        if IncrBatchName then begin
            WhseJnlBatch.Delete();
            WhseJnlBatch.Name := IncStr(WhseJnlLine."Journal Batch Name");
            if WhseJnlBatch.Insert() then;
            WhseJnlLine."Journal Batch Name" := WhseJnlBatch.Name;
        end;
    end;

    local procedure CreateTrackingSpecification(WhseJnlLine: Record "Warehouse Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        BinContent: Record "Bin Content";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTrackingSpecification(WhseJnlLine, TempHandlingSpecification, IsHandled);
        if IsHandled then
            exit;

        if (WhseJnlLine."Entry Type" = WhseJnlLine."Entry Type"::Movement) or
           (WhseJnlLine.Quantity < 0)
        then
            BinContent.Get(WhseJnlLine."Location Code", WhseJnlLine."From Bin Code", WhseJnlLine."Item No.",
              WhseJnlLine."Variant Code", WhseJnlLine."Unit of Measure Code");

        WhseItemTrkgLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.", "Location Code");
        WhseItemTrkgLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        WhseItemTrkgLine.SetRange("Source ID", WhseJnlLine."Journal Batch Name");
        WhseItemTrkgLine.SetRange("Source Batch Name", WhseJnlLine."Journal Template Name");
        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseJnlLine."Line No.");
        WhseItemTrkgLine.SetRange("Location Code", WhseJnlLine."Location Code");
        WhseItemTrkgLine.CalcSums("Qty. to Handle (Base)");

        if WhseItemTrkgLine."Qty. to Handle (Base)" <> Abs(WhseJnlLine."Qty. (Absolute, Base)") then
            Error(Text005);

        if WhseItemTrkgLine.Find('-') then
            repeat
                OnCreateTrackingSpecificationOnBeforeItemTrackingMgtGetWhseItemTrkgSetup(WhseJnlLine, WhseItemTrkgLine);
                ItemTrackingMgt.GetWhseItemTrkgSetup(WhseJnlLine."Item No.", WhseItemTrackingSetup);
                OnCreateTrackingSpecificationOnAfterItemTrackingMgtGetWhseItemTrkgSetup(WhseJnlLine, WhseItemTrackingSetup);
                WhseItemTrkgLine.CheckTrackingIfRequired(WhseItemTrackingSetup);
            until WhseItemTrkgLine.Next() = 0;

        if (WhseJnlLine."Entry Type" = WhseJnlLine."Entry Type"::Movement) or
           (WhseJnlLine.Quantity < 0)
        then
            if WhseItemTrkgLine.Find('-') then
                repeat
                    BinContent.SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrkgLine);
                    BinContent.CalcFields("Quantity (Base)");
                    if WhseItemTrkgLine."Quantity (Base)" > BinContent."Quantity (Base)" then
                        Error(Text006);
                until WhseItemTrkgLine.Next() = 0;

        if WhseItemTrkgLine.Find('-') then
            repeat
                OnBeforeInsertTempHandlingSpecs(WhseJnlLine, WhseItemTrkgLine);

                TempHandlingSpecification.Init();
                TempHandlingSpecification.TransferFields(WhseItemTrkgLine);
                TempHandlingSpecification."Quantity actual Handled (Base)" := WhseItemTrkgLine."Qty. to Handle (Base)";
                OnBeforeTempHandlingSpecificationInsert(TempHandlingSpecification, WhseItemTrkgLine);
                TempHandlingSpecification.Insert();

                Location.Get(WhseJnlLine."Location Code");
                if (WhseJnlLine."From Bin Code" <> '') and
                   (WhseJnlLine."From Bin Code" <> Location."Adjustment Bin Code") and
                   Location."Directed Put-away and Pick"
                then begin
                    BinContent.Get(WhseJnlLine."Location Code", WhseJnlLine."From Bin Code", WhseJnlLine."Item No.", WhseJnlLine."Variant Code", WhseJnlLine."Unit of Measure Code");
                    BinContent.SetTrackingFilterFromTrackingSpecification(TempHandlingSpecification);
                    BinContent.CheckDecreaseBinContent(WhseJnlLine."Qty. (Absolute)", WhseJnlLine."Qty. (Absolute, Base)", WhseJnlLine."Qty. (Absolute, Base)");
                end;
            until WhseItemTrkgLine.Next() = 0;
    end;

    local procedure UpdateTempBinContentBuffer(WhseJnlLine: Record "Warehouse Journal Line"; BinCode: Code[20]; Increase: Boolean)
    begin
        // Calculate cubage and weight per bin
        if not TempBinContentBuffer.Get(
            WhseJnlLine."Location Code", BinCode, '', '', '', '', '')
        then begin
            TempBinContentBuffer.Init();
            TempBinContentBuffer."Location Code" := WhseJnlLine."Location Code";
            TempBinContentBuffer."Bin Code" := BinCode;
            TempBinContentBuffer.Insert();
        end;
        if Increase then begin
            TempBinContentBuffer."Qty. to Handle (Base)" := TempBinContentBuffer."Qty. to Handle (Base)" + WhseJnlLine."Qty. (Absolute, Base)";
            TempBinContentBuffer.Cubage := TempBinContentBuffer.Cubage + WhseJnlLine.Cubage;
            TempBinContentBuffer.Weight := TempBinContentBuffer.Weight + WhseJnlLine.Weight;
        end else begin
            WMSMgt.CalcCubageAndWeight(
              WhseJnlLine."Item No.", WhseJnlLine."Unit of Measure Code", WhseJnlLine."Qty. (Absolute)", WhseJnlLine.Cubage, WhseJnlLine.Weight);
            TempBinContentBuffer."Qty. to Handle (Base)" := TempBinContentBuffer."Qty. to Handle (Base)" - WhseJnlLine."Qty. (Absolute, Base)";
            TempBinContentBuffer.Cubage := TempBinContentBuffer.Cubage - WhseJnlLine.Cubage;
            TempBinContentBuffer.Weight := TempBinContentBuffer.Weight - WhseJnlLine.Weight;
        end;
        TempBinContentBuffer.Modify();
    end;

    local procedure CheckIncreaseBin()
    var
        Bin: Record Bin;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(WhseJnlLine, TempBinContentBuffer, IsHandled);
        if IsHandled then
            exit;

        TempBinContentBuffer.SetFilter("Qty. to Handle (Base)", '>0');
        if TempBinContentBuffer.Find('-') then
            repeat
                Bin.Get(TempBinContentBuffer."Location Code", TempBinContentBuffer."Bin Code");
                Bin.CheckIncreaseBin(
                  TempBinContentBuffer."Bin Code", '', TempBinContentBuffer."Qty. to Handle (Base)", TempBinContentBuffer.Cubage, TempBinContentBuffer.Weight, TempBinContentBuffer.Cubage, TempBinContentBuffer.Weight, true, false);
            until TempBinContentBuffer.Next() = 0;
    end;

    procedure GetWhseRegNo(): Integer
    begin
        exit(WhseRegNo);
    end;

    local procedure CreateItemJnlLine(WhseJnlLine2: Record "Warehouse Journal Line"; var ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        QtyToHandleBase: Decimal;
        ShouldCreateReservEntry: Boolean;
    begin
        WhseItemTrkgLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.", "Location Code");
        WhseItemTrkgLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        WhseItemTrkgLine.SetRange("Source ID", WhseJnlLine2."Journal Batch Name");
        WhseItemTrkgLine.SetRange("Source Batch Name", WhseJnlLine2."Journal Template Name");
        WhseItemTrkgLine.SetRange("Source Ref. No.", WhseJnlLine2."Line No.");
        WhseItemTrkgLine.SetRange("Location Code", WhseJnlLine2."Location Code");

        if WhseItemTrkgLine.FindSet() then begin
            ItemJnlLine.Init();
            ItemJnlLine."Line No." := 0;
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
            repeat
                ShouldCreateReservEntry := not WhseItemTrkgLine.HasSameNewTracking() or
                    (WhseItemTrkgLine."New Expiration Date" <> WhseItemTrkgLine."Expiration Date");
                OnCreateItemJnlLineOnAfterCalcShouldCreateReservEntry(WhseJnlLine2, WhseItemTrkgLine, ShouldCreateReservEntry);
                if ShouldCreateReservEntry then begin
                    ReservEntry.CopyTrackingFromWhseItemTrackingLine(WhseItemTrkgLine);
                    CreateReservEntry.CreateReservEntryFor(
                      Database::"Item Journal Line", ItemJnlLine."Entry Type".AsInteger(), '', '', 0, WhseJnlLine2."Line No.", WhseItemTrkgLine."Qty. per Unit of Measure",
                      Abs(WhseItemTrkgLine."Qty. to Handle"), Abs(WhseItemTrkgLine."Qty. to Handle (Base)"), ReservEntry);
                    CreateReservEntry.SetNewTrackingFromNewWhseItemTrackingLine(WhseItemTrkgLine);
                    CreateReservEntry.SetDates(WhseItemTrkgLine."Warranty Date", WhseItemTrkgLine."Expiration Date");
                    CreateReservEntry.SetNewExpirationDate(WhseItemTrkgLine."New Expiration Date");
                    OnBeforeCreateReservEntry(WhseJnlLine2, WhseItemTrkgLine);
                    CreateReservEntry.CreateEntry(
                      WhseJnlLine2."Item No.", WhseJnlLine2."Variant Code", WhseJnlLine2."Location Code", WhseJnlLine2.Description, 0D, 0D, 0, ReservEntry."Reservation Status"::Prospect);
                    QtyToHandleBase += Abs(WhseItemTrkgLine."Qty. to Handle (Base)");
                end;
            until WhseItemTrkgLine.Next() = 0;

            if QtyToHandleBase <> 0 then begin
                CopyFieldsFromWhseJnlLineToItemJnlLine(WhseJnlLine2, ItemJnlLine, QtyToHandleBase);
                OnAfterCreateItemJnlLine(ItemJnlLine, WhseItemTrkgLine, WhseJnlLine2, QtyToHandleBase);
            end;
        end;

        OnCreateItemJnlLineOnBeforeExit(WhseJnlLine2, ItemJnlLine, QtyToHandleBase);
        exit(QtyToHandleBase <> 0);
    end;

    procedure CopyFieldsFromWhseJnlLineToItemJnlLine(WarehouseJournalLine: Record "Warehouse Journal Line"; var ItemJournalLine: Record "Item Journal Line"; QtyToHandleBase: Decimal)
    begin
        OnBeforeCopyFieldsFromWhseJnlLineToItemJnlLine(ItemJournalLine, WarehouseJournalLine, WhseJnlTemplate);
        ItemJournalLine."Document No." := WarehouseJournalLine."Whse. Document No.";
        ItemJournalLine.Validate("Posting Date", WarehouseJournalLine."Registering Date");
        ItemJournalLine.Validate("Item No.", WarehouseJournalLine."Item No.");
        ItemJournalLine.Validate("Variant Code", WarehouseJournalLine."Variant Code");
        ItemJournalLine.Validate("Location Code", WarehouseJournalLine."Location Code");
        ItemJournalLine.Validate("Unit of Measure Code", WarehouseJournalLine."Unit of Measure Code");
        ItemJournalLine.Validate(Quantity, Round(QtyToHandleBase / WarehouseJournalLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
        ItemJournalLine.Description := WarehouseJournalLine.Description;
        ItemJournalLine."Source Type" := ItemJournalLine."Source Type"::Item;
        ItemJournalLine."Source No." := WarehouseJournalLine."Item No.";
        ItemJournalLine."Source Code" := WarehouseJournalLine."Source Code";
        ItemJournalLine."Reason Code" := WarehouseJournalLine."Reason Code";
        ItemJournalLine."Warehouse Adjustment" := true;
        ItemJournalLine."Line No." := WarehouseJournalLine."Line No.";
    end;

    local procedure IsPhysInvtCount(WhseJnlTemplate2: Record "Warehouse Journal Template"; PhysInvtCountingPeriodCode: Code[10]; PhysInvtCountingPeriodType: Option " ",Item,SKU): Boolean
    begin
        exit(
          (WhseJnlTemplate2.Type = WhseJnlTemplate2.Type::"Physical Inventory") and
          (PhysInvtCountingPeriodType <> PhysInvtCountingPeriodType::" ") and
          (PhysInvtCountingPeriodCode <> ''));
    end;

    local procedure CheckItemAvailability(var WhseJnlLine: Record "Warehouse Journal Line")
    var
        TempSKU: Record "Stockkeeping Unit" temporary;
        WhseJnlLineToPost: Record "Warehouse Journal Line";
        ConfirmManagement: Codeunit "Confirm Management";
        WhseJnlLineQty: Decimal;
        ReservedQtyOnInventory: Decimal;
        QtyOnWarehouseEntries: Decimal;
    begin
        WhseJnlLineToPost.CopyFilters(WhseJnlLine);
        if WhseJnlLineToPost.FindSet() then
            repeat
                if not TempSKU.Get(WhseJnlLineToPost."Location Code", WhseJnlLineToPost."Item No.", WhseJnlLineToPost."Variant Code") then begin
                    InsertTempSKU(TempSKU, WhseJnlLineToPost);

                    WhseJnlLineQty := CalcRequiredQty(TempSKU, WhseJnlLine);
                    if WhseJnlLineQty < 0 then begin
                        ReservedQtyOnInventory := CalcReservedQtyOnInventory(TempSKU."Item No.", TempSKU."Location Code", TempSKU."Variant Code");
                        QtyOnWarehouseEntries := CalcQtyOnWarehouseEntry(TempSKU."Item No.", TempSKU."Location Code", TempSKU."Variant Code");
                        OnCheckItemAvailabilityOnAfterCalcQtyOnWarehouseEntry(ReservedQtyOnInventory, QtyOnWarehouseEntries, WhseJnlLineQty, TempSKU);
                        if (ReservedQtyOnInventory > 0) and ((QtyOnWarehouseEntries - ReservedQtyOnInventory) < Abs(WhseJnlLineQty)) then
                            if not ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(
                                     Text007, TempSKU.FieldCaption("Item No."), TempSKU."Item No.", TempSKU.FieldCaption("Location Code"),
                                     TempSKU."Location Code", TempSKU.FieldCaption("Variant Code"), TempSKU."Variant Code"), true)
                            then
                                Error('');
                    end;
                end;
            until WhseJnlLineToPost.Next() = 0;

        OnAfterCheckItemAvailability(WhseJnlLine);
    end;

    local procedure CalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.SetFilter("Location Filter", LocationCode);
        Item.SetFilter("Variant Filter", VariantCode);
        Item.CalcFields("Reserved Qty. on Inventory");
        exit(Item."Reserved Qty. on Inventory")
    end;

    local procedure CalcQtyOnWarehouseEntry(ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[20]): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Variant Code", VariantCode);
        WarehouseEntry.CalcSums(WarehouseEntry."Qty. (Base)");
        exit(WarehouseEntry."Qty. (Base)");
    end;

    local procedure InsertTempSKU(var TempSKU: Record "Stockkeeping Unit" temporary; WhseJnlLine: Record "Warehouse Journal Line")
    begin
        TempSKU.Init();
        TempSKU."Location Code" := WhseJnlLine."Location Code";
        TempSKU."Item No." := WhseJnlLine."Item No.";
        TempSKU."Variant Code" := WhseJnlLine."Variant Code";
        TempSKU.Insert();
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure CalcRequiredQty(TempSKU: Record "Stockkeeping Unit" temporary; var WhseJnlLineFiltered: Record "Warehouse Journal Line"): Decimal
    var
        WhseJnlLine2: Record "Warehouse Journal Line";
    begin
        WhseJnlLine2.CopyFilters(WhseJnlLineFiltered);
        WhseJnlLine2.SetRange("Item No.", TempSKU."Item No.");
        WhseJnlLine2.SetRange("Location Code", TempSKU."Location Code");
        WhseJnlLine2.SetRange("Variant Code", TempSKU."Variant Code");
        WhseJnlLine2.CalcSums("Qty. (Base)");
        exit(WhseJnlLine2."Qty. (Base)");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Line", 'OnAfterInsertWhseEntry', '', false, false)]
    local procedure OnAfterInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        if WarehouseEntry."Warehouse Register No." <> 0 then
            WhseRegNo := WarehouseEntry."Warehouse Register No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempHandlingSpecs(var WhseJnlLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemAvailability(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCollectTrackingInformation(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WarehouseJournalLine: Record "Warehouse Journal Line"; QtyToHandleBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemJnlPostLine(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJnlLines(var WhseJnlBatch: Record "Warehouse Journal Batch"; var WhseJnlLine: Record "Warehouse Journal Line"; WhseRegNo: Integer; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBin(var WarehouseJournalLine: Record "Warehouse Journal Line"; var TempBinContentBuffer: Record "Bin Content Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFieldsFromWhseJnlLineToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalTemplate: Record "Warehouse Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTrackingSpecification(WarehouseJournalLine: Record "Warehouse Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservEntry(WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrBatchName(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IncrBatchName: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalTemplate: Record "Warehouse Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterLines(var WarehouseJournalLine: Record "Warehouse Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempHandlingSpecificationInsert(var TempHandlingTrackingSpecification: Record "Tracking Specification" temporary; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDeleteLines(var WarehouseJournalLine: Record "Warehouse Journal Line"; WhseRegNo: Integer; var SkipUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseJnlRegisterLineRun(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; WarehouseJournalTemplate: Record "Warehouse Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemJnlLineOnAfterCalcShouldCreateReservEntry(WarehouseJournalLine: Record "Warehouse Journal Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var ShouldCreateReservEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailabilityOnAfterCalcQtyOnWarehouseEntry(var ReservedQtyOnInventory: Decimal; var QtyOnWarehouseEntries: Decimal; var WhseJnlLineQty: Decimal; var TempSKU: Record "Stockkeeping Unit" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLinesOnAfterGetWhseItemTrkgSetup(WhseJnlLine: Record "Warehouse Journal Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLinesOnBeforeCheckWhseJnlLine(WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterWhseJnlBatchGet(var WhseJnlBatch: Record "Warehouse Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemJnlLineOnBeforeExit(WhseJnlLine2: Record "Warehouse Journal Line"; var ItemJnlLine: Record "Item Journal Line"; var QtytoHandleBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTrackingSpecificationOnAfterItemTrackingMgtGetWhseItemTrkgSetup(WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTrackingSpecificationOnBeforeItemTrackingMgtGetWhseItemTrkgSetup(WarehouseJournalLine: Record "Warehouse Journal Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;
}

