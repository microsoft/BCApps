// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Ledger;

codeunit 6501 "Item Tracking Data Collection"
{
    Permissions = TableData "Item Entry Relation" = rd,
                  TableData "Value Entry Relation" = rd;

    trigger OnRun()
    begin
    end;

    var
        TempGlobalReservEntry: Record "Reservation Entry" temporary;
        TempGlobalAdjustEntry: Record "Reservation Entry" temporary;
        TempGlobalEntrySummary: Record "Entry Summary" temporary;
        TempGlobalChangedEntrySummary: Record "Entry Summary" temporary;
        CurrItemTrackingCode: Record "Item Tracking Code";
        TempGlobalTrackingSpec: Record "Tracking Specification" temporary;
        CurrBinCode: Code[20];
        LastSummaryEntryNo: Integer;
        LastReservEntryNo: Integer;
        FullGlobalDataSetExists: Boolean;
        SkipLot: Boolean;
        DirectTransfer: Boolean;
        HideValidationDialog: Boolean;

#pragma warning disable AA0074
        Text004: Label 'Counting records...';
#pragma warning restore AA0074
        AvailabilityWarningsMsg: Label 'The data used for availability calculation has been updated.\There are availability warnings on one or more lines.';
        NoAvailabilityWarningsMsg: Label 'The data used for availability calculation has been updated.\There are no availability warnings.';
        ListTxt: Label '%1 List', Comment = '%1 - field caption';
#pragma warning disable AA0074
        AvailabilityText: Label '%1 %2 - Availability', Comment = '%1 - tracking field caption, %2 - field value';
        Text011: Label 'Item Tracking - Select Entries';
#pragma warning restore AA0074
        PartialGlobalDataSetExists: Boolean;
#pragma warning disable AA0074
        Text013: Label 'Neutralize consumption/output';
#pragma warning restore AA0074
        LotNoBySNNotFoundErr: Label 'A lot number could not be found for serial number %1.', Comment = '%1 - serial number.';
        PackageNoBySNNotFoundErr: Label 'A package number could not be found for serial number %1.', Comment = '%1 - serial number.';

    local procedure InitItemTrackingSummaryForm(var ItemTrackingSummaryForm: Page "Item Tracking Summary"; var TempTrackingSpecification: Record "Tracking Specification" temporary; SearchForSupply: Boolean; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal)
    var
        Window: Dialog;
        IsHandled: Boolean;
    begin
        OnBeforeAssistEditTrackingNo(TempTrackingSpecification, SearchForSupply, CurrentSignFactor, LookupMode, MaxQuantity);

        Window.Open(Text004);

        IsHandled := false;
        OnAssistEditTrackingNoOnBeforeRetrieveLookupData(TempTrackingSpecification, TempGlobalEntrySummary, FullGlobalDataSetExists, IsHandled);
        if IsHandled then
            exit;

        if not FullGlobalDataSetExists then
            RetrieveLookupData(TempTrackingSpecification, true);

        TempGlobalReservEntry.Reset();
        TempGlobalEntrySummary.Reset();

        // Select the proper key on form
        TempGlobalEntrySummary.SetCurrentKey("Expiration Date");
        TempGlobalEntrySummary.SetFilter("Expiration Date", '<>%1', 0D);
        if TempGlobalEntrySummary.IsEmpty() then
            TempGlobalEntrySummary.SetTrackingKey();
        TempGlobalEntrySummary.SetRange("Expiration Date");
        ItemTrackingSummaryForm.SetTableView(TempGlobalEntrySummary);

        TempGlobalEntrySummary.SetTrackingKey();
        OnAssistEditTrackingNoOnBeforeLookupMode(TempGlobalEntrySummary, TempTrackingSpecification, ItemTrackingSummaryForm, CurrBinCode);
        case LookupMode of
            LookupMode::"Serial No.":
                AssistEditTrackingNoLookupSerialNo(TempTrackingSpecification, ItemTrackingSummaryForm);
            LookupMode::"Lot No.":
                AssistEditTrackingNoLookupLotNo(TempTrackingSpecification, ItemTrackingSummaryForm);
            else
                OnAssistEditTrackingNoOnLookupModeElseCase(
                    TempTrackingSpecification, ItemTrackingSummaryForm, TempGlobalEntrySummary, LookupMode, LookupMode);
        end;

        ItemTrackingSummaryForm.SetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode);
        OnAssistEditTrackingNoOnBeforeSetSources(TempTrackingSpecification, TempGlobalEntrySummary, MaxQuantity);
        ItemTrackingSummaryForm.SetSources(TempGlobalReservEntry, TempGlobalEntrySummary);
        ItemTrackingSummaryForm.LookupMode(SearchForSupply);
        ItemTrackingSummaryForm.SetSelectionMode(false);

        Window.Close();
    end;

    local procedure CalculateQtyAfterEditingTrackingLine(var TempTrackingSpecification: Record "Tracking Specification" temporary; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal)
    var
        AvailableQty: Decimal;
        AdjustmentQty: Decimal;
        QtyOnLine: Decimal;
        QtyHandledOnLine: Decimal;
        NewQtyOnLine: Decimal;
    begin
        if TempGlobalEntrySummary."Bin Active" then
            AvailableQty := MinValueAbs(TempGlobalEntrySummary."Bin Content", TempGlobalEntrySummary."Total Available Quantity")
        else
            AvailableQty := TempGlobalEntrySummary."Total Available Quantity";
        QtyHandledOnLine := TempTrackingSpecification."Quantity Handled (Base)";
        QtyOnLine := TempTrackingSpecification."Quantity (Base)" - QtyHandledOnLine;

        if CurrentSignFactor > 0 then begin
            AvailableQty := -AvailableQty;
            QtyHandledOnLine := -QtyHandledOnLine;
            QtyOnLine := -QtyOnLine;
        end;

        if MaxQuantity < 0 then begin
            AdjustmentQty := MaxQuantity;
            if AvailableQty < 0 then
                if AdjustmentQty > AvailableQty then
                    AdjustmentQty := AvailableQty;
            if QtyOnLine + AdjustmentQty < 0 then
                AdjustmentQty := -QtyOnLine;
        end else begin
            AdjustmentQty := AvailableQty;
            if AvailableQty < 0 then begin
                if QtyOnLine + AdjustmentQty < 0 then
                    AdjustmentQty := -QtyOnLine;
            end else
                AdjustmentQty := MinValueAbs(MaxQuantity, AvailableQty);
        end;
        if LookupMode = LookupMode::"Serial No." then
            TempTrackingSpecification.Validate("Serial No.", TempGlobalEntrySummary."Serial No.");
        TempTrackingSpecification.Validate("Lot No.", TempGlobalEntrySummary."Lot No.");
        OnAssistEditTrackingNoOnAfterAssignTrackingToSpec(TempTrackingSpecification, TempGlobalEntrySummary);

        TransferExpDateFromSummary(TempTrackingSpecification, TempGlobalEntrySummary);
        if TempTrackingSpecification.IsReclass() or DirectTransfer then
            TempTrackingSpecification.CopyNewTrackingFromTrackingSpec(TempTrackingSpecification);
        OnAssistEditTrackingNoOnAfterCopyNewTrackingFromTrackingSpec(TempTrackingSpecification, DirectTransfer);

        NewQtyOnLine := CalcNewQtyOnLine(TempTrackingSpecification, QtyOnLine, AdjustmentQty, QtyHandledOnLine);

        TempTrackingSpecification.Validate("Quantity (Base)", NewQtyOnLine);

        OnAfterAssistEditTrackingNo(TempTrackingSpecification, TempGlobalEntrySummary, CurrentSignFactor, MaxQuantity, TempGlobalReservEntry, LookupMode);
    end;

    procedure AssistEditTrackingNo(var TempTrackingSpecification: Record "Tracking Specification" temporary; SearchForSupply: Boolean; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal)
    var
        ItemTrackingSummaryForm: Page "Item Tracking Summary";

    begin
        InitItemTrackingSummaryForm(ItemTrackingSummaryForm, TempTrackingSpecification, SearchForSupply, CurrentSignFactor, LookupMode, MaxQuantity);
        OnAssistEditTrackingNoOnBeforeItemTrackingSummaryRunModal(TempTrackingSpecification);
        if ItemTrackingSummaryForm.RunModal() = ACTION::LookupOK then begin
            ItemTrackingSummaryForm.GetRecord(TempGlobalEntrySummary);
            CalculateQtyAfterEditingTrackingLine(TempTrackingSpecification, CurrentSignFactor, LookupMode, MaxQuantity);
        end;
    end;

    procedure AssistOutBoundBarcodeScannerTrackingNo(BarcodeResult: Text; var TempTrackingSpecification: Record "Tracking Specification" temporary; SearchForSupply: Boolean; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal): Boolean
    var
        ItemTrackingSummaryForm: Page "Item Tracking Summary";
    begin

        InitItemTrackingSummaryForm(ItemTrackingSummaryForm, TempTrackingSpecification, SearchForSupply, CurrentSignFactor, LookupMode, MaxQuantity);

        case LookupMode of
            LookupMode::"Serial No.":
                TempGlobalEntrySummary.SetFilter("Serial No.", BarcodeResult);
            LookupMode::"Lot No.":
                TempGlobalEntrySummary.SetFilter("Lot No.", BarcodeResult);
            LookupMode::"Package No.":
                TempGlobalEntrySummary.SetFilter("Package No.", BarcodeResult);
            else
                Error('There is no such LookupMode for the outbound scanning!');
        end;

        if not TempGlobalEntrySummary.FindSet() then
            exit(false);

        CalculateQtyAfterEditingTrackingLine(TempTrackingSpecification, CurrentSignFactor, LookupMode, MaxQuantity);
        exit(true);
    end;

    local procedure CalcNewQtyOnLine(var TempTrackingSpecification: Record "Tracking Specification" temporary; QtyOnLine: Decimal; AdjustmentQty: Decimal; QtyHandledOnLine: Decimal) NewQtyOnLine: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcNewQtyOnLine(TempTrackingSpecification, QtyOnLine, AdjustmentQty, QtyHandledOnLine, NewQtyOnLine, IsHandled);
        if IsHandled then
            exit(NewQtyOnLine);

        NewQtyOnLine := QtyOnLine + AdjustmentQty + QtyHandledOnLine;
        if TempTrackingSpecification."Serial No." <> '' then
            if Abs(NewQtyOnLine) > 1 then
                NewQtyOnLine := NewQtyOnLine / Abs(NewQtyOnLine); // Set to a signed value of 1.
    end;

    local procedure AssistEditTrackingNoLookupSerialNo(TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemTrackingSummaryPage: Page "Item Tracking Summary")
    begin
        if TempTrackingSpecification."Lot No." <> '' then
            TempGlobalEntrySummary.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
        TempGlobalEntrySummary.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
        OnAssistEditTrackingNoLookupSerialNoOnAfterSetFilters(TempGlobalEntrySummary, TempTrackingSpecification);
        if TempGlobalEntrySummary.FindFirst() then
            ItemTrackingSummaryPage.SetRecord(TempGlobalEntrySummary);
        TempGlobalEntrySummary.SetFilter("Serial No.", '<>%1', '');
        TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0);
        ItemTrackingSummaryPage.Caption := StrSubstNo(ListTxt, TempGlobalReservEntry.FieldCaption("Serial No."));
    end;

    local procedure AssistEditTrackingNoLookupLotNo(TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemTrackingSummaryPage: Page "Item Tracking Summary")
    begin
        if TempTrackingSpecification."Serial No." <> '' then
            TempGlobalEntrySummary.SetRange("Serial No.", TempTrackingSpecification."Serial No.")
        else
            TempGlobalEntrySummary.SetRange("Serial No.", '');
        TempGlobalEntrySummary.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
        OnAssistEditTrackingNoLookupLotNoOnAfterSetFilters(TempGlobalEntrySummary, TempTrackingSpecification);
        if TempGlobalEntrySummary.FindFirst() then
            ItemTrackingSummaryPage.SetRecord(TempGlobalEntrySummary);
        TempGlobalEntrySummary.SetRange("Lot No.");
        TempGlobalEntrySummary.SetRange("Non Serial Tracking", true);
        ItemTrackingSummaryPage.Caption := StrSubstNo(ListTxt, TempGlobalEntrySummary.FieldCaption("Lot No."));
        OnAfterAssistEditTrackingNoLookupLotNo(TempTrackingSpecification, ItemTrackingSummaryPage);
    end;

    procedure SelectMultipleTrackingNo(var TempTrackingSpecification: Record "Tracking Specification" temporary; MaxQuantity: Decimal; CurrentSignFactor: Integer)
    var
        TempEntrySummary: Record "Entry Summary" temporary;
        ItemTrackingSummaryForm: Page "Item Tracking Summary";
        Window: Dialog;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectMultipleTrackingNo(TempTrackingSpecification, MaxQuantity, CurrentSignFactor, FullGlobalDataSetExists, IsHandled);
        if IsHandled then
            exit;

        Clear(ItemTrackingSummaryForm);
        Window.Open(Text004);
        if not FullGlobalDataSetExists then
            RetrieveLookupData(TempTrackingSpecification, true);

        TempGlobalReservEntry.Reset();
        TempGlobalEntrySummary.Reset();

        // Swap sign if negative supply lines
        if CurrentSignFactor > 0 then
            MaxQuantity := -MaxQuantity;

        // Select the proper key
        TempGlobalEntrySummary.SetCurrentKey("Expiration Date");
        TempGlobalEntrySummary.SetFilter("Expiration Date", '<>%1', 0D);
        if TempGlobalEntrySummary.IsEmpty() then
            TempGlobalEntrySummary.SetTrackingKey();
        TempGlobalEntrySummary.SetRange("Expiration Date");

        // Initialize form
        ItemTrackingSummaryForm.Caption := Text011;
        ItemTrackingSummaryForm.SetTableView(TempGlobalEntrySummary);
        TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0); // Filter out summations
        OnSelectMultipleTrackingNoOnBeforeSetSources(TempTrackingSpecification, TempGlobalEntrySummary, MaxQuantity);
        ItemTrackingSummaryForm.SetSources(TempGlobalReservEntry, TempGlobalEntrySummary);
        ItemTrackingSummaryForm.SetSelectionMode(MaxQuantity <> 0);
        ItemTrackingSummaryForm.LookupMode(true);
        ItemTrackingSummaryForm.SetMaxQuantity(MaxQuantity);
        ItemTrackingSummaryForm.SetQtyRoundingPrecision(TempTrackingSpecification."Qty. Rounding Precision (Base)");
        ItemTrackingSummaryForm.SetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode);

        // Run preselection on form
        IsHandled := false;
        OnSelectMultipleTrackingNoOnBeforeAutoSelectTrackingNo(IsHandled);
        if not IsHandled then
            ItemTrackingSummaryForm.AutoSelectTrackingNo();

        Window.Close();

        if not HideValidationDialog then
            if not (ItemTrackingSummaryForm.RunModal() = ACTION::LookupOK) then
                exit;

        ItemTrackingSummaryForm.GetSelected(TempEntrySummary);
        if TempEntrySummary.IsEmpty() then
            exit;

        // Swap sign on the selected entries if parent is a negative supply line
        if CurrentSignFactor > 0 then // Negative supply lines
            if TempEntrySummary.Find('-') then
                repeat
                    TempEntrySummary."Selected Quantity" := -TempEntrySummary."Selected Quantity";
                    TempEntrySummary.Modify();
                until TempEntrySummary.Next() = 0;

        // Modify the item tracking lines with the selected quantities
        OnSelectMultipleTrackingNoOnBeforeAddSelectedTrackingToDataSet(TempEntrySummary, TempTrackingSpecification, CurrentSignFactor);
        AddSelectedTrackingToDataSet(TempEntrySummary, TempTrackingSpecification, CurrentSignFactor);
    end;

    procedure LookupTrackingAvailability(var TempTrackingSpecification: Record "Tracking Specification" temporary; LookupMode: Enum "Item Tracking Type")
    var
        ItemTrackingSummaryForm: Page "Item Tracking Summary";
        Window: Dialog;
    begin
        if ShouldExitLookupTrackingAvailability(TempTrackingSpecification, LookupMode) then
            exit;

        Clear(ItemTrackingSummaryForm);
        Window.Open(Text004);
        TempGlobalChangedEntrySummary.Reset();

        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TempTrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();

        TempGlobalReservEntry.Reset();

        case LookupMode of
            LookupMode::"Serial No.":
                begin
                    TempGlobalEntrySummary.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                    TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0); // Filter out summations
                    TempGlobalReservEntry.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                    ItemTrackingSummaryForm.Caption := StrSubstNo(
                        AvailabilityText, TempTrackingSpecification.FieldCaption("Serial No."), TempTrackingSpecification."Serial No.");
                end;
            LookupMode::"Lot No.":
                begin
                    TempGlobalEntrySummary.SetRange("Serial No.", '');
                    TempGlobalEntrySummary.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                    TempGlobalReservEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                    ItemTrackingSummaryForm.Caption := StrSubstNo(
                        AvailabilityText, TempTrackingSpecification.FieldCaption("Lot No."), TempTrackingSpecification."Lot No.");
                end;
            else
                OnLookupTrackingAvailabilityOnSetFiltersElseCase(
                    TempGlobalEntrySummary, TempGlobalReservEntry, TempTrackingSpecification, ItemTrackingSummaryForm, LookupMode);
        end;
        OnLookupTrackingAvailabilityOnBeforeSetSources(TempGlobalEntrySummary, TempTrackingSpecification, LookupMode);
        ItemTrackingSummaryForm.SetSources(TempGlobalReservEntry, TempGlobalEntrySummary);
        ItemTrackingSummaryForm.SetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode);
        ItemTrackingSummaryForm.LookupMode(false);
        ItemTrackingSummaryForm.SetSelectionMode(false);
        Window.Close();
        ItemTrackingSummaryForm.RunModal();
    end;

    local procedure ShouldExitLookupTrackingAvailability(TempTrackingSpecification: Record "Tracking Specification" temporary; LookupMode: Enum "Item Tracking Type"): Boolean
    var
        ShouldExit: Boolean;
    begin
        case LookupMode of
            LookupMode::"Serial No.":
                if TempTrackingSpecification."Serial No." = '' then
                    exit(true);
            LookupMode::"Lot No.":
                if TempTrackingSpecification."Lot No." = '' then
                    exit(true);
        end;

        OnAfterShouldExitLookupTrackingAvailability(TempTrackingSpecification, LookupMode, ShouldExit);
    end;

    local procedure RetrieveLookupData(var TempTrackingSpecification: Record "Tracking Specification" temporary; FullDataSet: Boolean; ReservEntryReadIsolation: IsolationLevel)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
        LotNo, PackageNo : Code[50];
    begin
        LastSummaryEntryNo := 0;
        LastReservEntryNo := 2147483647;
        TempTrackingSpecification2 := TempTrackingSpecification;
        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.DeleteAll();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.DeleteAll();

        ReservEntry.Reset();
        ReservEntry.ReadIsolation := ReservEntryReadIsolation;
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Item Tracking");
        ReservEntry.SetRange("Item No.", TempTrackingSpecification."Item No.");
        ReservEntry.SetRange("Variant Code", TempTrackingSpecification."Variant Code");
        ReservEntry.SetRange("Location Code", TempTrackingSpecification."Location Code");
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
        OnRetrieveLookupDataOnAfterReservEntrySetFilters(ReservEntry, TempTrackingSpecification);
        if ReservEntry.FindSet() then
            repeat
                TempReservEntry := ReservEntry;
                if CanIncludeReservEntryToTrackingSpec(TempReservEntry) then
                    TempReservEntry.Insert();
            until ReservEntry.Next() = 0;

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Entry No.");
        ItemLedgEntry.SetRange("Item No.", TempTrackingSpecification."Item No.");
        ItemLedgEntry.SetRange("Variant Code", TempTrackingSpecification."Variant Code");
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange("Location Code", TempTrackingSpecification."Location Code");

        OnRetrieveLookupDataOnBeforeTransferToTempRec(TempTrackingSpecification, TempReservEntry, ItemLedgEntry, FullDataSet);

        LotNo := '';
        PackageNo := '';
        if FullDataSet then begin
            TransferReservEntryToTempRec(TempReservEntry, TempTrackingSpecification);
            TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);
        end else
            if TempTrackingSpecification.FindSet() then
                repeat
                    ItemLedgEntry.ClearTrackingFilter();
                    TempReservEntry.ClearTrackingFilter();

                    if (TempTrackingSpecification."Lot No." <> '') and (TempTrackingSpecification."Lot No." <> LotNo) then begin
                        LotNo := TempTrackingSpecification."Lot No.";
                        ItemLedgEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                        TempReservEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                        TransferReservEntryToTempRec(TempReservEntry, TempTrackingSpecification);
                        TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);
                    end;

                    ItemLedgEntry.ClearTrackingFilter();
                    TempReservEntry.ClearTrackingFilter();
                    if (TempTrackingSpecification."Package No." <> '') and (TempTrackingSpecification."Package No." <> PackageNo) then begin
                        PackageNo := TempTrackingSpecification."Package No.";
                        ItemLedgEntry.SetRange("Package No.", TempTrackingSpecification."Package No.");
                        TempReservEntry.SetRange("Package No.", TempTrackingSpecification."Package No.");
                        TransferReservEntryToTempRec(TempReservEntry, TempTrackingSpecification);
                        TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);
                    end;

                    OnRetrieveLookupDataOnAfterBuildNonSerialDataSet(TempTrackingSpecification, ItemLedgEntry, TempReservEntry);

                    if (TempTrackingSpecification."Lot No." = '') and (TempTrackingSpecification."Package No." = '') and (TempTrackingSpecification."Serial No." <> '') then begin
                        ItemLedgEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                        TempReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                        TransferReservEntryToTempRec(TempReservEntry, TempTrackingSpecification);
                        TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);
                    end;
                until TempTrackingSpecification.Next() = 0;

        OnRetrieveLookupDataOnAfterTransferToTempRec(TempGlobalEntrySummary, TempTrackingSpecification, ItemLedgEntry, LastSummaryEntryNo);

        TempGlobalEntrySummary.Reset();
        UpdateCurrentPendingQty();
        TempTrackingSpecification := TempTrackingSpecification2;

        PartialGlobalDataSetExists := true;
        FullGlobalDataSetExists := FullDataSet;
        AdjustForDoubleEntriesForManufacturing();
        AdjustForDoubleEntriesForJobs();

        OnAfterRetrieveLookupData(TempTrackingSpecification, FullDataSet, TempGlobalReservEntry, TempGlobalEntrySummary);
    end;

    procedure RetrieveLookupData(var TempTrackingSpecification: Record "Tracking Specification" temporary; FullDataSet: Boolean)
    begin
        RetrieveLookupData(TempTrackingSpecification, FullDataSet, IsolationLevel::Default);
    end;

    procedure GetTempGlobalEntrySummary(var TempGlobalEntrySummary2: Record "Entry Summary" temporary)
    begin
        TempGlobalEntrySummary2.Copy(TempGlobalEntrySummary, true);
    end;

    procedure TransferItemLedgToTempRec(var ItemLedgEntry: Record "Item Ledger Entry"; var TrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        ItemLedgEntry.SetLoadFields(
          "Entry No.", "Item No.", "Variant Code", Positive, "Location Code", "Serial No.", "Lot No.", "Package No.",
          "Remaining Quantity", "Warranty Date", "Expiration Date");
        OnTransferItemLedgToTempRecOnBeforeFindSetItemLedgerEntry(ItemLedgEntry);
        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry.TrackingExists() and
                   not TempGlobalReservEntry.Get(-ItemLedgEntry."Entry No.", ItemLedgEntry.Positive)
                then begin
                    TempGlobalReservEntry.Init();
                    TempGlobalReservEntry."Entry No." := -ItemLedgEntry."Entry No.";
                    TempGlobalReservEntry."Reservation Status" := TempGlobalReservEntry."Reservation Status"::Surplus;
                    TempGlobalReservEntry.Positive := ItemLedgEntry.Positive;
                    TempGlobalReservEntry."Item No." := ItemLedgEntry."Item No.";
                    TempGlobalReservEntry."Variant Code" := ItemLedgEntry."Variant Code";
                    TempGlobalReservEntry."Location Code" := ItemLedgEntry."Location Code";
                    TempGlobalReservEntry."Quantity (Base)" := ItemLedgEntry."Remaining Quantity";
                    TempGlobalReservEntry."Source Type" := Database::"Item Ledger Entry";
                    TempGlobalReservEntry."Source Ref. No." := ItemLedgEntry."Entry No.";
                    TempGlobalReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                    if TempGlobalReservEntry.Positive then begin
                        TempGlobalReservEntry."Warranty Date" := ItemLedgEntry."Warranty Date";
                        TempGlobalReservEntry."Expiration Date" := ItemLedgEntry."Expiration Date";
                        TempGlobalReservEntry."Expected Receipt Date" := 0D
                    end else
                        TempGlobalReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);

                    IsHandled := false;
                    OnTransferItemLedgToTempRecOnBeforeInsert(TempGlobalReservEntry, ItemLedgEntry, TrackingSpecification, IsHandled);
                    if not IsHandled then begin
                        TempGlobalReservEntry.Insert();
                        CreateEntrySummary(TrackingSpecification, TempGlobalReservEntry);
                    end;
                end;
            until ItemLedgEntry.Next() = 0;
    end;

    procedure TransferReservEntryToTempRec(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        if TempReservEntry.FindSet() then
            repeat
                if not TempGlobalReservEntry.Get(TempReservEntry."Entry No.", TempReservEntry.Positive) then begin
                    TempGlobalReservEntry := TempReservEntry;
                    TempGlobalReservEntry."Transferred from Entry No." := 0;
                    IsHandled := false;
                    OnAfterTransferReservEntryToTempRec(TempGlobalReservEntry, TempReservEntry, TrackingSpecification, IsHandled);
                    if not IsHandled then begin
                        TempGlobalReservEntry.Insert();
                        CreateEntrySummary(TrackingSpecification, TempGlobalReservEntry);
                    end;
                end;
            until TempReservEntry.Next() = 0;
    end;

    local procedure CreateEntrySummary(TrackingSpecification: Record "Tracking Specification" temporary; TempReservEntry: Record "Reservation Entry" temporary)
    begin
        CreateEntrySummary2(TrackingSpecification, TempReservEntry, true);
        CreateEntrySummary2(TrackingSpecification, TempReservEntry, false);

        OnAfterCreateEntrySummary(TrackingSpecification, TempGlobalEntrySummary);
    end;

    local procedure CreateEntrySummary2(TempTrackingSpecification: Record "Tracking Specification" temporary; TempReservEntry: Record "Reservation Entry" temporary; SerialNoLookup: Boolean)
    var
        LateBindingManagement: Codeunit "Late Binding Management";
        DoInsert: Boolean;
    begin
        OnBeforeCreateEntrySummary2(TempGlobalEntrySummary, TempReservEntry, TempTrackingSpecification);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();

        if SerialNoLookup then begin
            if TempReservEntry."Serial No." = '' then
                exit;

            TempGlobalEntrySummary.SetTrackingFilterFromReservEntry(TempReservEntry);
        end else begin
            if not TempReservEntry.NonSerialTrackingExists() then
                exit;

            TempGlobalEntrySummary.SetRange("Serial No.", '');
            TempGlobalEntrySummary.SetNonSerialTrackingFilterFromReservEntry(TempReservEntry);
            if TempReservEntry."Serial No." <> '' then
                TempGlobalEntrySummary.SetRange("Table ID", 0)
            else
                TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0);
        end;
        OnCreateEntrySummary2OnAfterSetFilters(TempGlobalEntrySummary, TempReservEntry);

        // If no summary exists, create new record
        if not TempGlobalEntrySummary.FindFirst() then begin
            TempGlobalEntrySummary.Init();
            TempGlobalEntrySummary."Entry No." := LastSummaryEntryNo + 1;
            LastSummaryEntryNo := TempGlobalEntrySummary."Entry No.";

            if not SerialNoLookup and (TempReservEntry."Serial No." <> '') then
                TempGlobalEntrySummary."Table ID" := 0 // Mark as summation
            else
                TempGlobalEntrySummary."Table ID" := TempReservEntry."Source Type";
            if SerialNoLookup then
                TempGlobalEntrySummary."Serial No." := TempReservEntry."Serial No."
            else
                TempGlobalEntrySummary."Serial No." := '';
            TempGlobalEntrySummary."Lot No." := TempReservEntry."Lot No.";
            OnCreateEntrySummary2OnAfterAssignTrackingFromReservEntry(TempGlobalEntrySummary, TempReservEntry);
            TempGlobalEntrySummary."Non Serial Tracking" := TempGlobalEntrySummary.HasNonSerialTracking();
            TempGlobalEntrySummary."Bin Active" := CurrBinCode <> '';
            OnBeforeUpdateBinContent(TempGlobalEntrySummary, TempReservEntry, CurrBinCode, CurrItemTrackingCode);
            UpdateBinContent(TempGlobalEntrySummary);

            // If consumption/output fill in double entry value here:
            TempGlobalEntrySummary."Double-entry Adjustment" :=
              MaxDoubleEntryAdjustQty(TempTrackingSpecification, TempGlobalEntrySummary);

            OnCreateEntrySummary2OnAfterSetDoubleEntryAdjustment(TempGlobalEntrySummary, TempReservEntry);

            DoInsert := true;
        end;

        // Sum up values
        if TempReservEntry.Positive then begin
            TempGlobalEntrySummary."Warranty Date" := TempReservEntry."Warranty Date";
            TempGlobalEntrySummary."Expiration Date" := TempReservEntry."Expiration Date";
            OnAfterSetTempGlobalEntrySummaryExpirationDate(TempGlobalEntrySummary, TempReservEntry);
            if TempReservEntry."Entry No." < 0 then begin // The record represents an Item ledger entry
                TempGlobalEntrySummary."Non-specific Reserved Qty." +=
                  LateBindingManagement.NonSpecificReservedQtyExceptForSource(-TempReservEntry."Entry No.", TempTrackingSpecification);
                TempGlobalEntrySummary."Total Quantity" += TempReservEntry."Quantity (Base)";
            end;
            if TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Reservation then
                TempGlobalEntrySummary."Total Reserved Quantity" += TempReservEntry."Quantity (Base)";
        end else begin
            if TempReservEntry."Qty. to Handle (Base)" <> 0 then
                TempGlobalEntrySummary."Total Requested Quantity" -= TempReservEntry."Quantity (Base)";
            if TempReservEntry.HasSamePointerWithSpec(TempTrackingSpecification) then begin
                if TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Reservation then
                    TempGlobalEntrySummary."Current Reserved Quantity" -= TempReservEntry."Quantity (Base)";
                if TempReservEntry."Entry No." > 0 then // The record represents a reservation entry
                    TempGlobalEntrySummary."Current Requested Quantity" -= TempReservEntry."Quantity (Base)";
            end;
        end;

        // Update available quantity on the record
        OnCreateEntrySummary2OnBeforeInsertOrModify(TempGlobalEntrySummary, TempReservEntry, TempTrackingSpecification);

        TempGlobalEntrySummary.UpdateAvailable();
        if DoInsert then
            TempGlobalEntrySummary.Insert()
        else
            TempGlobalEntrySummary.Modify();

        OnAfterCreateEntrySummary2(TempGlobalEntrySummary, TempReservEntry);
    end;

    local procedure MinValueAbs(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Abs(Value1) < Abs(Value2) then
            exit(Value1);

        exit(Value2);
    end;

    procedure AddSelectedTrackingToDataSet(var TempEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; CurrentSignFactor: Integer)
    var
        TrackingSpecification2: Record "Tracking Specification";
        LastEntryNo: Integer;
        ChangeType: Option Insert,Modify,Delete;
    begin
        TempEntrySummary.Reset();
        TempEntrySummary.SetFilter("Selected Quantity", '<>%1', 0);
        if TempEntrySummary.IsEmpty() then
            exit;

        // To save general and pointer information
        TrackingSpecification2.Init();
        TrackingSpecification2."Item No." := TempTrackingSpecification."Item No.";
        TrackingSpecification2."Location Code" := TempTrackingSpecification."Location Code";
        TrackingSpecification2."Source Type" := TempTrackingSpecification."Source Type";
        TrackingSpecification2."Source Subtype" := TempTrackingSpecification."Source Subtype";
        TrackingSpecification2."Source ID" := TempTrackingSpecification."Source ID";
        TrackingSpecification2."Source Batch Name" := TempTrackingSpecification."Source Batch Name";
        TrackingSpecification2."Source Prod. Order Line" := TempTrackingSpecification."Source Prod. Order Line";
        TrackingSpecification2."Source Ref. No." := TempTrackingSpecification."Source Ref. No.";
        TrackingSpecification2.Positive := TempTrackingSpecification.Positive;
        TrackingSpecification2."Qty. per Unit of Measure" := TempTrackingSpecification."Qty. per Unit of Measure";
        TrackingSpecification2."Variant Code" := TempTrackingSpecification."Variant Code";

        OnAddSelectedTrackingToDataSetOnAfterInitTrackingSpecification2(TrackingSpecification2, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        LastEntryNo := TempTrackingSpecification.GetLastEntryNo();

        TempEntrySummary.FindFirst();
        repeat
            TempTrackingSpecification.SetTrackingFilterFromEntrySummary(TempEntrySummary);
            OnAddSelectedTrackingToDataSetOnAfterSetTrackingFilterFromEntrySummary(TempTrackingSpecification, TempEntrySummary);
            if TempTrackingSpecification.FindFirst() then begin
                OnAddSelectedTrackingToDataSetOnBeforeUpdateWithChange(TempEntrySummary, TempTrackingSpecification, ChangeType::Modify);
                TempTrackingSpecification.Validate("Quantity (Base)",
                  TempTrackingSpecification."Quantity (Base)" + TempEntrySummary."Selected Quantity");
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::MODIFY;
                TransferExpDateFromSummary(TempTrackingSpecification, TempEntrySummary);
                TempTrackingSpecification.Modify();
                UpdateTrackingDataSetWithChange(TempTrackingSpecification, true, CurrentSignFactor, ChangeType::Modify);
            end else begin
                TempTrackingSpecification := TrackingSpecification2;
                TempTrackingSpecification."Entry No." := LastEntryNo + 1;
                LastEntryNo := TempTrackingSpecification."Entry No.";
                TempTrackingSpecification.CopyTrackingFromEntrySummary(TempEntrySummary);
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::INSERT;
                TransferExpDateFromSummary(TempTrackingSpecification, TempEntrySummary);
                if TempTrackingSpecification.IsReclass() then
                    TempTrackingSpecification.CopyNewTrackingFromTrackingSpec(TempTrackingSpecification);
                OnAddSelectedTrackingToDataSetOnAfterCopyNewTrackingFromTrackingSpec(TempTrackingSpecification, ChangeType);
                TempTrackingSpecification.Validate("Quantity (Base)", TempEntrySummary."Selected Quantity");
                OnBeforeTempTrackingSpecificationInsert(TempTrackingSpecification, TempEntrySummary);
                TempTrackingSpecification.Insert();
                UpdateTrackingDataSetWithChange(TempTrackingSpecification, true, CurrentSignFactor, ChangeType::Insert);
            end;
        until TempEntrySummary.Next() = 0;

        TempTrackingSpecification.Reset();
    end;

    procedure TrackingAvailable(TempTrackingSpecification: Record "Tracking Specification" temporary; LookupMode: Enum "Item Tracking Type"): Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeTrackingAvailable(TempTrackingSpecification, IsHandled, LookupMode, Result);
        if IsHandled then
            exit(Result);

        CurrItemTrackingCode.TestField(Code);
        case LookupMode of
            LookupMode::"Serial No.":
                if (TempTrackingSpecification."Serial No." = '') or (not CurrItemTrackingCode."SN Specific Tracking") then
                    exit(true);
            LookupMode::"Lot No.":
                if (TempTrackingSpecification."Lot No." = '') or (not CurrItemTrackingCode."Lot Specific Tracking") then
                    exit(true);
            else begin
                IsHandled := false;
                OnTrackingAvailableOnLookupModeElseCase(TempTrackingSpecification, CurrItemTrackingCode, LookupMode, IsHandled);
                if IsHandled then
                    exit(true);
            end;
        end;

        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TempTrackingSpecification, true);

        ItemTrackingSetup.CopyTrackingFromItemTrackingCodeSpecificTracking(CurrItemTrackingCode);
        ItemTrackingSetup.CopyTrackingFromTrackingSpec(TempTrackingSpecification);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();
        TempGlobalEntrySummary.SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup);
        TempGlobalEntrySummary.CalcSums("Total Available Quantity");
        if CheckJobInPurchLine(TempTrackingSpecification) then
            exit(TempGlobalEntrySummary.FindFirst());
        exit(TempGlobalEntrySummary."Total Available Quantity" >= 0);
    end;

    procedure CheckAvailableTrackingQuantity(var TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        RetrieveLookupData(TempTrackingSpecification, false, IsolationLevel::ReadUncommitted);

        ItemTrackingSetup.CopyTrackingFromItemTrackingCodeSpecificTracking(CurrItemTrackingCode);
        ItemTrackingSetup.CopyTrackingFromTrackingSpec(TempTrackingSpecification);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();
        TempGlobalEntrySummary.SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup);
        if TempGlobalEntrySummary.IsEmpty() then
            exit(false);

        TempGlobalEntrySummary.CalcSums("Total Available Quantity");
        exit(TempGlobalEntrySummary."Total Available Quantity" >= 0);
    end;

    procedure UpdateTrackingDataSetWithChange(var TempTrackingSpecificationChanged: Record "Tracking Specification" temporary; LineIsDemand: Boolean; CurrentSignFactor: Integer; ChangeType: Option Insert,Modify,Delete)
    var
        LastEntryNo: Integer;
    begin
        if not TempTrackingSpecificationChanged.TrackingExists() then
            exit;

        LastEntryNo := UpdateTrackingGlobalChangeRec(TempTrackingSpecificationChanged, LineIsDemand, CurrentSignFactor, ChangeType);
        TempGlobalChangedEntrySummary.Get(LastEntryNo);
        UpdateTempSummaryWithChange(TempGlobalChangedEntrySummary);
    end;

    local procedure UpdateTrackingGlobalChangeRec(var TempTrackingSpecificationChanged: Record "Tracking Specification" temporary; LineIsDemand: Boolean; CurrentSignFactor: Integer; ChangeType: Option Insert,Modify,Delete): Integer
    var
        NewQuantity: Decimal;
        LastEntryNo: Integer;
    begin
        if (ChangeType = ChangeType::Delete) or not LineIsDemand then
            NewQuantity := 0
        else
            NewQuantity := TempTrackingSpecificationChanged."Quantity (Base)" - TempTrackingSpecificationChanged."Quantity Handled (Base)";

        if CurrentSignFactor > 0 then // Negative supply lines
            NewQuantity := -NewQuantity;

        TempGlobalChangedEntrySummary.Reset();
        TempGlobalChangedEntrySummary.SetTrackingKey();
        TempGlobalChangedEntrySummary.SetTrackingFilterFromSpec(TempTrackingSpecificationChanged);
        if not TempGlobalChangedEntrySummary.FindFirst() then begin
            TempGlobalChangedEntrySummary.Reset();
            LastEntryNo := TempGlobalChangedEntrySummary.GetLastEntryNo();
            TempGlobalChangedEntrySummary.Init();
            TempGlobalChangedEntrySummary."Entry No." := LastEntryNo + 1;
            TempGlobalChangedEntrySummary.CopyTrackingFromSpec(TempTrackingSpecificationChanged);
            TempGlobalChangedEntrySummary."Non Serial Tracking" := TempGlobalEntrySummary.HasNonSerialTracking();
            TempGlobalChangedEntrySummary."Current Pending Quantity" := NewQuantity;
            if TempTrackingSpecificationChanged."Serial No." <> '' then
                TempGlobalChangedEntrySummary."Table ID" := Database::"Tracking Specification"; // Not a summary line
            OnBeforeTempGlobalChangedEntrySummaryInsert(
                TempGlobalChangedEntrySummary, TempTrackingSpecificationChanged, LineIsDemand, CurrentSignFactor, ChangeType);
            TempGlobalChangedEntrySummary.Insert();
            PartialGlobalDataSetExists := false; // The partial data set does not cover the new line
        end else
            if LineIsDemand then begin
                TempGlobalChangedEntrySummary."Current Pending Quantity" := NewQuantity;
                OnBeforeTempGlobalChangedEntrySummaryModify(
                    TempGlobalChangedEntrySummary, TempTrackingSpecificationChanged, LineIsDemand, CurrentSignFactor, ChangeType);
                TempGlobalChangedEntrySummary.Modify();
            end;
        exit(TempGlobalChangedEntrySummary."Entry No.");
    end;

    local procedure UpdateCurrentPendingQty()
    var
        TempLastGlobalEntrySummary: Record "Entry Summary" temporary;
        IsHandled: Boolean;
    begin
        TempGlobalChangedEntrySummary.Reset();
        TempGlobalChangedEntrySummary.SetTrackingKey();
        if TempGlobalChangedEntrySummary.FindSet() then
            repeat
                IsHandled := false;
                OnUpdateCurrentPendingQtyOnLoop(TempGlobalChangedEntrySummary, CurrBinCode, TempGlobalEntrySummary, IsHandled);
                if not IsHandled then begin
                    if TempGlobalChangedEntrySummary.HasNonSerialTracking() then begin
                        // only last record with Lot Number updates Summary
                        if not TempGlobalChangedEntrySummary.HasSameNonSerialTracking(TempLastGlobalEntrySummary) then
                            FindLastGlobalEntrySummary(TempGlobalChangedEntrySummary, TempLastGlobalEntrySummary);
                        SkipLot := not (TempGlobalChangedEntrySummary."Entry No." = TempLastGlobalEntrySummary."Entry No.");
                    end;
                    UpdateTempSummaryWithChange(TempGlobalChangedEntrySummary);
                end;
            until TempGlobalChangedEntrySummary.Next() = 0;
    end;

    local procedure UpdateTempSummaryWithChange(var TempChangedEntrySummary: Record "Entry Summary" temporary)
    var
        LastEntryNo: Integer;
        SumOfSNPendingQuantity: Decimal;
        SumOfSNRequestedQuantity: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTempSummaryWithChange(TempChangedEntrySummary, CurrBinCode, TempGlobalEntrySummary, IsHandled);
        if IsHandled then
            exit;

        TempGlobalEntrySummary.Reset();
        LastEntryNo := TempGlobalEntrySummary.GetLastEntryNo();

        TempGlobalEntrySummary.SetTrackingKey();
        OnUpdateTempSummaryWithChangeOnAfterSetCurrentKey(TempGlobalEntrySummary, TempChangedEntrySummary);
        if TempChangedEntrySummary."Serial No." <> '' then begin
            TempGlobalEntrySummary.SetTrackingFilterFromEntrySummary(TempChangedEntrySummary);
            if TempGlobalEntrySummary.FindFirst() then begin
                TempGlobalEntrySummary."Current Pending Quantity" := TempChangedEntrySummary."Current Pending Quantity" -
                  TempGlobalEntrySummary."Current Requested Quantity";
                TempGlobalEntrySummary.UpdateAvailable();
                TempGlobalEntrySummary.Modify();
            end else begin
                TempGlobalEntrySummary := TempChangedEntrySummary;
                TempGlobalEntrySummary."Entry No." := LastEntryNo + 1;
                LastEntryNo := TempGlobalEntrySummary."Entry No.";
                TempGlobalEntrySummary."Bin Active" := CurrBinCode <> '';
                UpdateBinContent(TempGlobalEntrySummary);
                TempGlobalEntrySummary.UpdateAvailable();
                TempGlobalEntrySummary.Insert();
            end;

            if TempChangedEntrySummary.HasNonSerialTracking() and not SkipLot then begin
                TempGlobalEntrySummary.SetFilter("Serial No.", '<>%1', '');
                TempGlobalEntrySummary.SetNonSerialTrackingFilterFromEntrySummary(TempChangedEntrySummary);
                TempGlobalEntrySummary.CalcSums("Current Pending Quantity", "Current Requested Quantity");
                SumOfSNPendingQuantity := TempGlobalEntrySummary."Current Pending Quantity";
                SumOfSNRequestedQuantity := TempGlobalEntrySummary."Current Requested Quantity";
            end;
        end;

        if TempChangedEntrySummary.HasNonSerialTracking() and not SkipLot then begin
            TempGlobalEntrySummary.SetRange("Serial No.", '');
            TempGlobalEntrySummary.SetNonSerialTrackingFilterFromEntrySummary(TempChangedEntrySummary);

            if TempChangedEntrySummary."Serial No." <> '' then
                TempGlobalEntrySummary.SetRange("Table ID", 0)
            else
                TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0);

            if TempGlobalEntrySummary.FindFirst() then begin
                if TempChangedEntrySummary."Serial No." <> '' then begin
                    TempGlobalEntrySummary."Current Pending Quantity" := SumOfSNPendingQuantity;
                    TempGlobalEntrySummary."Current Requested Quantity" := SumOfSNRequestedQuantity;
                end else
                    TempGlobalEntrySummary."Current Pending Quantity" := TempChangedEntrySummary."Current Pending Quantity" -
                      TempGlobalEntrySummary."Current Requested Quantity";

                OnUpdateTempSummaryWithChangeOnAfterCalcCurrentPendingQuantity(TempChangedEntrySummary, TempGlobalEntrySummary);
                TempGlobalEntrySummary.UpdateAvailable();
                TempGlobalEntrySummary.Modify();
            end else begin
                TempGlobalEntrySummary := TempChangedEntrySummary;
                TempGlobalEntrySummary."Entry No." := LastEntryNo + 1;
                TempGlobalEntrySummary."Serial No." := '';
                if TempChangedEntrySummary."Serial No." <> '' then // Mark as summation
                    TempGlobalEntrySummary."Table ID" := 0
                else
                    TempGlobalEntrySummary."Table ID" := Database::"Tracking Specification";
                TempGlobalEntrySummary."Bin Active" := CurrBinCode <> '';
                UpdateBinContent(TempGlobalEntrySummary);
                TempGlobalEntrySummary.UpdateAvailable();
                TempGlobalEntrySummary.Insert();
            end;
        end;
    end;

    procedure GetFullGlobalDataSetExists(): Boolean
    begin
        exit(FullGlobalDataSetExists);
    end;

    procedure RefreshTrackingAvailability(var TempTrackingSpecification: Record "Tracking Specification" temporary; ShowMessage: Boolean) AvailabilityOK: Boolean
    begin
        AvailabilityOK := RefreshTrackingAvailability(TempTrackingSpecification, true, ShowMessage);
    end;

    internal procedure RefreshTrackingAvailability(var TempTrackingSpecification: Record "Tracking Specification" temporary; RecreateGlobalDataSet: Boolean; ShowMessage: Boolean) AvailabilityOK: Boolean
    var
        TrackingSpecification2: Record "Tracking Specification";
        LookupMode: Enum "Item Tracking Type";
        PreviousLotNo: Code[50];
    begin
        AvailabilityOK := true;
        if TempTrackingSpecification.Positive then
            exit;

        TrackingSpecification2.Copy(TempTrackingSpecification);
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.IsEmpty() then begin
            TempTrackingSpecification.Copy(TrackingSpecification2);
            exit;
        end;

        if RecreateGlobalDataSet then begin
            FullGlobalDataSetExists := false;
            PartialGlobalDataSetExists := false;
            RetrieveLookupData(TempTrackingSpecification, false);
        end;

        TempTrackingSpecification.SetTrackingKey();
        TempTrackingSpecification.Find('-');
        LookupMode := LookupMode::"Serial No.";
        PreviousLotNo := '';
        repeat
            if TempTrackingSpecification."Lot No." <> PreviousLotNo then begin
                PreviousLotNo := TempTrackingSpecification."Lot No.";
                LookupMode := LookupMode::"Lot No.";

                if not TrackingAvailable(TempTrackingSpecification, LookupMode) then
                    AvailabilityOK := false;

                LookupMode := LookupMode::"Serial No.";
            end;

            if not TrackingAvailable(TempTrackingSpecification, LookupMode) then
                AvailabilityOK := false;
        until TempTrackingSpecification.Next() = 0;

        if ShowMessage then
            if AvailabilityOK then
                Message(NoAvailabilityWarningsMsg)
            else
                Message(AvailabilityWarningsMsg);

        TempTrackingSpecification.Copy(TrackingSpecification2);
    end;

    procedure SetCurrentBinAndItemTrkgCode(BinCode: Code[20]; ItemTrackingCode: Record "Item Tracking Code")
    var
        xBinCode: Code[20];
    begin
        xBinCode := CurrBinCode;
        CurrBinCode := BinCode;
        CurrItemTrackingCode := ItemTrackingCode;

        if xBinCode <> BinCode then
            if PartialGlobalDataSetExists then
                RefreshBinContent(TempGlobalEntrySummary);

        OnAfterSetCurrentBinAndItemTrkgCode(xBinCode, CurrBinCode, CurrItemTrackingCode, FullGlobalDataSetExists, PartialGlobalDataSetExists);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure UpdateBinContent(var TempEntrySummary: Record "Entry Summary" temporary)
    var
        WarehouseEntry: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnUpdateBinContentOnBeforeUpdateBinContent(TempEntrySummary, CurrItemTrackingCode, IsHandled, TempGlobalReservEntry);
        if IsHandled then
            exit;

        if CurrBinCode = '' then
            exit;

        CurrItemTrackingCode.TestField(Code);

        WarehouseEntry.Reset();
        WarehouseEntry.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Variant Code",
          "Unit of Measure Code", "Lot No.", "Serial No.", "Package No.");
        WarehouseEntry.SetRange("Item No.", TempGlobalReservEntry."Item No.");
        WarehouseEntry.SetRange("Bin Code", CurrBinCode);
        WarehouseEntry.SetRange("Location Code", TempGlobalReservEntry."Location Code");
        WarehouseEntry.SetRange("Variant Code", TempGlobalReservEntry."Variant Code");
        WhseItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(CurrItemTrackingCode);
        WhseItemTrackingSetup.CopyTrackingFromEntrySummary(TempEntrySummary);
        WarehouseEntry.SetTrackingFilterFromItemTrackingSetupIfRequiredIfNotBlank(WhseItemTrackingSetup);

        IsHandled := false;
        OnUpdateBinContentOnBeforeCalcSumsQtyBase(TempEntrySummary, WarehouseEntry, IsHandled);
        if IsHandled then
            exit;

        WarehouseEntry.CalcSums("Qty. (Base)");

        TempEntrySummary."Bin Content" := WarehouseEntry."Qty. (Base)";
    end;

    local procedure RefreshBinContent(var TempEntrySummary: Record "Entry Summary" temporary)
    begin
        TempEntrySummary.Reset();
        if TempEntrySummary.FindSet() then
            repeat
                if CurrBinCode <> '' then
                    UpdateBinContent(TempEntrySummary)
                else
                    TempEntrySummary."Bin Content" := 0;
                TempEntrySummary.Modify();
            until TempEntrySummary.Next() = 0;
    end;

    local procedure TransferExpDateFromSummary(var TrackingSpecification: Record "Tracking Specification" temporary; var TempEntrySummary: Record "Entry Summary" temporary)
    begin
        // Handle Expiration Date
        if TempEntrySummary."Total Quantity" <> 0 then begin
            TrackingSpecification."Buffer Status2" := TrackingSpecification."Buffer Status2"::"ExpDate blocked";
            TrackingSpecification."Expiration Date" := TempEntrySummary."Expiration Date";
            TrackingSpecification."Warranty Date" := TempEntrySummary."Warranty Date";
            if TrackingSpecification.IsReclass() then
                TrackingSpecification."New Expiration Date" := TrackingSpecification."Expiration Date"
            else
                TrackingSpecification."New Expiration Date" := 0D;
        end else begin
            TrackingSpecification."Buffer Status2" := 0;
            TrackingSpecification."Expiration Date" := 0D;
            TrackingSpecification."New Expiration Date" := 0D;
            TrackingSpecification."Warranty Date" := 0D;
        end;

        OnAfterTransferExpDateFromSummary(TrackingSpecification, TempEntrySummary);
    end;

    local procedure AdjustForDoubleEntriesForManufacturing()
    begin
        TempGlobalAdjustEntry.Reset();
        TempGlobalAdjustEntry.DeleteAll();

        TempGlobalTrackingSpec.Reset();
        TempGlobalTrackingSpec.DeleteAll();

        // Check if there is any need to investigate:
        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Reservation Status", TempGlobalReservEntry."Reservation Status"::Prospect);
        TempGlobalReservEntry.SetRange("Source Type", Database::"Item Journal Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 5, 6); // Consumption, Output
        if TempGlobalReservEntry.IsEmpty() then  // No journal lines with consumption or output exist
            exit;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Source Type", 5406); // Database::"Prod. Order Line"
        TempGlobalReservEntry.SetRange("Source Subtype", 3); // Released order
        if TempGlobalReservEntry.FindSet() then
            repeat
                // Sum up per prod. order line per lot/sn
                SumUpTempTrkgSpec(TempGlobalTrackingSpec, TempGlobalReservEntry);
            until TempGlobalReservEntry.Next() = 0;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Source Type", 5407); // Database::"Prod. Order Component"
        TempGlobalReservEntry.SetRange("Source Subtype", 3); // Released order
        if TempGlobalReservEntry.FindSet() then
            repeat
                // Sum up per prod. order component per lot/sn
                SumUpTempTrkgSpec(TempGlobalTrackingSpec, TempGlobalReservEntry);
            until TempGlobalReservEntry.Next() = 0;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Reservation Status", TempGlobalReservEntry."Reservation Status"::Prospect);
        TempGlobalReservEntry.SetRange("Source Type", Database::"Item Journal Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 5, 6); // Consumption, Output

        if TempGlobalReservEntry.FindSet() then
            repeat
                // Sum up per Component line per lot/sn
                RelateJnlLineToTempTrkgSpec(TempGlobalReservEntry, TempGlobalTrackingSpec);
            until TempGlobalReservEntry.Next() = 0;

        InsertAdjustmentEntries();
    end;

    local procedure AdjustForDoubleEntriesForJobs()
    begin
        TempGlobalAdjustEntry.Reset();
        TempGlobalAdjustEntry.DeleteAll();

        TempGlobalTrackingSpec.Reset();
        TempGlobalTrackingSpec.DeleteAll();

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Reservation Status", TempGlobalReservEntry."Reservation Status"::Prospect);
        TempGlobalReservEntry.SetRange("Source Type", Database::"Job Journal Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 0); // Job Journal
        if TempGlobalReservEntry.IsEmpty() then  // No journal lines with reservation exists
            exit;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Source Type", Database::"Job Planning Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 2);
        if TempGlobalReservEntry.FindSet() then
            repeat
                // Sum up per job planning line per lot/sn
                SumUpTempTrkgSpec(TempGlobalTrackingSpec, TempGlobalReservEntry);
            until TempGlobalReservEntry.Next() = 0;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Reservation Status", TempGlobalReservEntry."Reservation Status"::Prospect);
        TempGlobalReservEntry.SetRange("Source Type", Database::"Job Journal Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 0);

        if TempGlobalReservEntry.FindSet() then
            repeat
                // Sum up per qty. line per lot/sn
                RelateJobJnlLineToTempTrkgSpec(TempGlobalReservEntry, TempGlobalTrackingSpec);
            until TempGlobalReservEntry.Next() = 0;

        InsertAdjustmentEntries();
    end;

    procedure SumUpTempTrkgSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TempTrackingSpecification.SetSourceFilter(
          ReservEntry."Source Type", ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.", false);
        TempTrackingSpecification.SetSourceFilter(ReservEntry."Source Batch Name", ReservEntry."Source Prod. Order Line");
        TempTrackingSpecification.SetTrackingFilterFromReservEntry(ReservEntry);
        if TempTrackingSpecification.FindFirst() then begin
            TempTrackingSpecification."Quantity (Base)" += ReservEntry."Quantity (Base)";
            OnBeforeTempTrackingSpecificationModify(TempTrackingSpecification, ReservEntry);
            TempTrackingSpecification.Modify();
        end else begin
            ItemTrackingMgt.CreateTrackingSpecification(ReservEntry, TempTrackingSpecification);
            if not ReservEntry.Positive then               // To avoid inserting existing entry when both sides of the reservation
                TempTrackingSpecification."Entry No." *= -1; // are handled.
            TempTrackingSpecification.Insert();
        end;
    end;

    procedure RelateJnlLineToTempTrkgSpec(var ReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingSetup: Record "Item Tracking Setup";
        RemainingQty: Decimal;
        AdjustQty: Decimal;
        QtyOnJnlLine: Decimal;
    begin
        // Pre-check
        ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
        ReservEntry.TestField("Source Type", Database::"Item Journal Line");
        if not (ReservEntry."Source Subtype" in [5, 6]) then
            ReservEntry.FieldError("Source Subtype");

        if not ItemJnlLine.Get(ReservEntry."Source ID",
             ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.")
        then
            exit;

        if (ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Production) or
           (ItemJnlLine."Order No." = '') or
           (ItemJnlLine."Order Line No." = 0)
        then
            exit;

        // Buffer fields are used as follows:
        // "Buffer Value1" : Summed up quantity on journal line(s)
        // "Buffer Value2" : Adjustment needed to neutralize double entries

        ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
        if FindRelatedParentTrkgSpec(ItemJnlLine, TempTrackingSpecification, ItemTrackingSetup) then begin
            RemainingQty := TempTrackingSpecification."Quantity (Base)" + TempTrackingSpecification."Buffer Value2";
            QtyOnJnlLine := ReservEntry."Quantity (Base)";
            ReservEntry."Transferred from Entry No." := Abs(TempTrackingSpecification."Entry No.");
            ReservEntry.Modify();

            if (RemainingQty <> 0) and (RemainingQty * QtyOnJnlLine > 0) then
                if Abs(QtyOnJnlLine) <= Abs(RemainingQty) then
                    AdjustQty := -QtyOnJnlLine
                else
                    AdjustQty := -RemainingQty;

            TempTrackingSpecification."Buffer Value1" += QtyOnJnlLine;
            TempTrackingSpecification."Buffer Value2" += AdjustQty;
            TempTrackingSpecification.Modify();
            AddToAdjustmentEntryDataSet(ReservEntry, AdjustQty);
        end;
    end;

    local procedure FindRelatedParentTrkgSpec(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        TempTrackingSpecification.Reset();
        OnFindRelatedParentTrkgSpecOnSetSourceFilters(ItemJnlLine, TempTrackingSpecification);
        TempTrackingSpecification.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);
        OnFindRelatedParentTrkgSpecOnAfterSetFilters(TempTrackingSpecification, ItemJnlLine);
        exit(TempTrackingSpecification.FindFirst());
    end;

    procedure RelateJobJnlLineToTempTrkgSpec(var ReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        JobJnlLine: Record "Job Journal Line";
        ItemTrackingSetup: Record "Item Tracking Setup";
        RemainingQty: Decimal;
        AdjustQty: Decimal;
        QtyOnJnlLine: Decimal;
    begin
        // Pre-check
        ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
        ReservEntry.TestField("Source Type", Database::"Job Journal Line");
        if not (ReservEntry."Source Subtype" = 0) then
            ReservEntry.FieldError("Source Subtype");

        if not JobJnlLine.Get(ReservEntry."Source ID",
             ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.")
        then
            exit;

        // Buffer fields are used as follows:
        // "Buffer Value1" : Summed up quantity on journal line(s)
        // "Buffer Value2" : Adjustment needed to neutralize double entries

        ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
        if FindRelatedJobParentTrkgSpec(JobJnlLine, TempTrackingSpecification, ItemTrackingSetup) then begin
            RemainingQty := TempTrackingSpecification."Quantity (Base)" + TempTrackingSpecification."Buffer Value2";
            QtyOnJnlLine := ReservEntry."Quantity (Base)";
            ReservEntry."Transferred from Entry No." := Abs(TempTrackingSpecification."Entry No.");
            ReservEntry.Modify();

            if (RemainingQty <> 0) and (RemainingQty * QtyOnJnlLine > 0) then
                if Abs(QtyOnJnlLine) <= Abs(RemainingQty) then
                    AdjustQty := -QtyOnJnlLine
                else
                    AdjustQty := -RemainingQty;
            TempTrackingSpecification."Buffer Value1" += QtyOnJnlLine;
            TempTrackingSpecification."Buffer Value2" += AdjustQty;
            TempTrackingSpecification.Modify();
            AddToAdjustmentEntryDataSet(ReservEntry, AdjustQty);
        end;
    end;

    local procedure FindRelatedJobParentTrkgSpec(JobJnlLine: Record "Job Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if JobPlanningLine.Get(JobJnlLine."Job No.", JobJnlLine."Job Task No.", JobJnlLine."Job Planning Line No.") then begin
            TempTrackingSpecification.Reset();
            TempTrackingSpecification.SetSourceFilter(
            Database::"Job Planning Line", 2, JobJnlLine."Job No.", JobPlanningLine."Job Contract Entry No.", false);
            TempTrackingSpecification.SetSourceFilter('', 0);
            TempTrackingSpecification.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);
            exit(TempTrackingSpecification.FindFirst());
        end;
    end;

    local procedure AddToAdjustmentEntryDataSet(var ReservEntry: Record "Reservation Entry"; AdjustQty: Decimal)
    begin
        if AdjustQty = 0 then
            exit;

        TempGlobalAdjustEntry := ReservEntry;
        TempGlobalAdjustEntry."Source Type" := -ReservEntry."Source Type";
        TempGlobalAdjustEntry.Description := CopyStr(Text013, 1, MaxStrLen(TempGlobalAdjustEntry.Description));
        TempGlobalAdjustEntry."Quantity (Base)" := AdjustQty;
        TempGlobalAdjustEntry."Entry No." := LastReservEntryNo; // Use last entry no as offset to avoid inserting existing entry
        LastReservEntryNo -= 1;
        TempGlobalAdjustEntry.Insert();
    end;

    local procedure InsertAdjustmentEntries()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        TempGlobalAdjustEntry.Reset();
        if not TempGlobalAdjustEntry.FindSet() then
            exit;

        TempTrackingSpecification.Init();
        TempTrackingSpecification.Insert();
        repeat
            CreateEntrySummary(TempTrackingSpecification, TempGlobalAdjustEntry); // TrackingSpecification is a dummy record
            TempGlobalReservEntry := TempGlobalAdjustEntry;
            TempGlobalReservEntry.Insert();
        until TempGlobalAdjustEntry.Next() = 0;
    end;

    local procedure MaxDoubleEntryAdjustQty(var TempItemTrackLineChanged: Record "Tracking Specification" temporary; var ChangedEntrySummary: Record "Entry Summary" temporary): Decimal
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        if not (TempItemTrackLineChanged."Source Type" = Database::"Item Journal Line") then
            exit;

        if not (TempItemTrackLineChanged."Source Subtype" in [5, 6]) then
            exit;

        if not ItemJnlLine.Get(TempItemTrackLineChanged."Source ID",
             TempItemTrackLineChanged."Source Batch Name", TempItemTrackLineChanged."Source Ref. No.")
        then
            exit;

        TempGlobalTrackingSpec.Reset();
        ItemTrackingSetup.CopyTrackingFromEntrySummary(ChangedEntrySummary);
        if FindRelatedParentTrkgSpec(ItemJnlLine, TempGlobalTrackingSpec, ItemTrackingSetup) then
            exit(-TempGlobalTrackingSpec."Quantity (Base)" - TempGlobalTrackingSpec."Buffer Value2");
    end;

    procedure CurrentDataSetMatches(ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10]): Boolean
    begin
        exit(
          (TempGlobalReservEntry."Item No." = ItemNo) and
          (TempGlobalReservEntry."Variant Code" = VariantCode) and
          (TempGlobalReservEntry."Location Code" = LocationCode));
    end;

    local procedure CheckJobInPurchLine(TrackingSpecification: Record "Tracking Specification"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if (TrackingSpecification."Source Type" = Database::"Purchase Line") and (TrackingSpecification."Source Subtype" = TrackingSpecification."Source Subtype"::"3") then begin
            PurchaseLine.ReadIsolation(IsolationLevel::ReadUncommitted);
            PurchaseLine.SetLoadFields("Job No.");
            if PurchaseLine.Get(TrackingSpecification."Source Subtype", TrackingSpecification."Source ID", TrackingSpecification."Source Ref. No.") then
                exit(PurchaseLine."Job No." <> '');
        end;
    end;

    procedure FindLotNoBySN(TrackingSpecification: Record "Tracking Specification"): Code[50]
    var
        LotNo: Code[50];
    begin
        if FindLotNoBySNSilent(LotNo, TrackingSpecification) then
            exit(LotNo);

        Error(LotNoBySNNotFoundErr, TrackingSpecification."Serial No.");
    end;

    procedure FindLotNoBySNSilent(var LotNo: Code[50]; TrackingSpecification: Record "Tracking Specification"): Boolean
    begin
        Clear(LotNo);
        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();
        TempGlobalEntrySummary.SetRange("Serial No.", TrackingSpecification."Serial No.");
        TempGlobalEntrySummary.SetFilter("Lot No.", '<>%1', '');
        if not TempGlobalEntrySummary.FindFirst() then
            exit(false);

        LotNo := TempGlobalEntrySummary."Lot No.";
        exit(true);
    end;

    procedure FindPackageNoBySN(TrackingSpecification: Record "Tracking Specification"): Code[50]
    var
        PackageNo: Code[50];
    begin
        if FindPackageNoBySNSilent(PackageNo, TrackingSpecification) then
            exit(PackageNo);

        Error(PackageNoBySNNotFoundErr, TrackingSpecification."Serial No.");
    end;

    procedure FindPackageNoBySNSilent(var PackageNo: Code[50]; TrackingSpecification: Record "Tracking Specification"): Boolean
    begin
        Clear(PackageNo);
        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();
        TempGlobalEntrySummary.SetRange("Serial No.", TrackingSpecification."Serial No.");
        TempGlobalEntrySummary.SetFilter("Package No.", '<>%1', '');
        if not TempGlobalEntrySummary.FindFirst() then
            exit(false);

        PackageNo := TempGlobalEntrySummary."Package No.";
        exit(true);
    end;

    procedure GetAvailableLotQty(TrackingSpecification: Record "Tracking Specification"): Decimal
    begin
        if TrackingSpecification."Lot No." = '' then
            exit(0);

        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();
        TempGlobalEntrySummary.SetRange("Lot No.", TrackingSpecification."Lot No.");
        TempGlobalEntrySummary.CalcSums("Total Available Quantity");
        exit(TempGlobalEntrySummary."Total Available Quantity");
    end;

    procedure SetSkipLot(SkipLot2: Boolean)
    begin
        // only last record with Lot Number updates Summary.
        SkipLot := SkipLot2;
    end;

    local procedure FindLastGlobalEntrySummary(var GlobalChangedEntrySummary: Record "Entry Summary"; var LastGlobalEntrySummary: Record "Entry Summary")
    var
        TempGlobalChangedEntrySummary2: Record "Entry Summary" temporary;
    begin
        TempGlobalChangedEntrySummary2 := GlobalChangedEntrySummary;
        GlobalChangedEntrySummary.SetNonSerialTrackingFilterFromEntrySummary(GlobalChangedEntrySummary);
        if GlobalChangedEntrySummary.FindLast() then
            LastGlobalEntrySummary := GlobalChangedEntrySummary;
        GlobalChangedEntrySummary.Copy(TempGlobalChangedEntrySummary2);
    end;

    procedure SetDirectTransfer(NewDirectTransfer: Boolean)
    begin
        DirectTransfer := NewDirectTransfer;
    end;

    local procedure CanIncludeReservEntryToTrackingSpec(TempReservEntry: Record "Reservation Entry" temporary) Result: Boolean
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanIncludeReservEntryToTrackingSpec(TempReservEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Prospect) and
               (TempReservEntry."Source Type" = Database::"Sales Line") and
               (TempReservEntry."Source Subtype" = 2)
        then begin
            SalesLine.SetLoadFields("Shipment No.");
            SalesLine.Get(TempReservEntry."Source Subtype", TempReservEntry."Source ID", TempReservEntry."Source Ref. No.");
            if SalesLine."Shipment No." <> '' then
                exit(false);
        end;

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEditTrackingNo(var TempTrackingSpecification: Record "Tracking Specification" temporary; var SearchForSupply: Boolean; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistEditTrackingNo(var TrackingSpecification: Record "Tracking Specification"; var TempGlobalEntrySummary: Record "Entry Summary" temporary; CurrentSignFactor: Integer; MaxQuantity: Decimal; var TempGlobalReservationEntry: Record "Reservation Entry" temporary; LookupMode: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnBeforeRetrieveLookupData(var TrackingSpecification: Record "Tracking Specification"; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var FullGlobalDataSetExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntrySummary(TrackingSpecification: Record "Tracking Specification"; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntrySummary2(var TempGlobalEntrySummary: Record "Entry Summary" temporary; var TempGlobalReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRetrieveLookupData(var TrackingSpecification: Record "Tracking Specification"; FullDataSet: Boolean; var TempGlobalReservEntry: Record "Reservation Entry" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExpDateFromSummary(var TrackingSpecification: Record "Tracking Specification"; var TempEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferReservEntryToTempRec(var GlobalReservEntry: Record "Reservation Entry"; ReservEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnBeforeSetSources(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var MaxQuantity: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNewQtyOnLine(var TempTrackingSpecification: Record "Tracking Specification" temporary; QtyOnLine: Decimal; AdjustmentQty: Decimal; QtyHandledOnLine: Decimal; var NewQtyOnLine: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanIncludeReservEntryToTrackingSpec(TempReservEntry: Record "Reservation Entry" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateEntrySummary2(var TempGlobalEntrySummary: Record "Entry Summary" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectMultipleTrackingNo(var TempTrackingSpecification: Record "Tracking Specification" temporary; MaxQuantity: Decimal; CurrentSignFactor: Integer; FullGlobalDataSetExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecificationModify(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempGlobalChangedEntrySummaryInsert(var TempGlobalChangedEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecificationChanged: Record "Tracking Specification" temporary; LineIsDemand: Boolean; CurrentSignFactor: Integer; ChangeType: Option Insert,Modify,Delete)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempGlobalChangedEntrySummaryModify(var TempGlobalChangedEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecificationChanged: Record "Tracking Specification" temporary; LineIsDemand: Boolean; CurrentSignFactor: Integer; ChangeType: Option Insert,Modify,Delete)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrackingAvailable(var TempTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean; LookupMode: Enum "Item Tracking Type"; var Result: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBinContent(var TempEntrySummary: Record "Entry Summary" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; var CurrBinCode: Code[20]; var CurrItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveLookupDataOnBeforeTransferToTempRec(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; var ItemLedgerEntry: Record "Item Ledger Entry"; var FullDataSet: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectMultipleTrackingNoOnBeforeSetSources(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var MaxQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemLedgToTempRecOnBeforeInsert(var TempGlobalReservEntry: Record "Reservation Entry" temporary; ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSelectedTrackingToDataSetOnAfterInitTrackingSpecification2(var TrackingSpecification: Record "Tracking Specification"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTrackingAvailableOnLookupModeElseCase(TempTrackingSpecification: Record "Tracking Specification" temporary; CurrItemTrackingCode: Record "Item Tracking Code"; LookupMode: Enum "Item Tracking Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRetrieveLookupDataOnAfterBuildNonSerialDataSet(var TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemLedgEntry: Record "Item Ledger Entry"; var TempReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldExitLookupTrackingAvailability(TempTrackingSpecification: Record "Tracking Specification" temporary; LookupMode: Enum "Item Tracking Type"; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnLookupModeElseCase(TempTrackingSpecification: Record "Tracking Specification"; var ItemTrackingSummaryPage: Page "Item Tracking Summary"; var TempGlobalEntrySummary: Record "Entry Summary" temporary; LookupMode: Enum "Item Tracking Entry Type"; ItemTrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupTrackingAvailabilityOnSetFiltersElseCase(var TempGlobalEntrySummary: Record "Entry Summary" temporary; var TempGlobalReservEntry: Record "Reservation Entry" temporary; TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemTrackingSummaryPage: Page "Item Tracking Summary"; LookupMode: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoLookupSerialNoOnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary" temporary; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoLookupLotNoOnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary" temporary; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnBeforeItemTrackingSummaryRunModal(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnAfterAssignTrackingToSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary; TempGlobalEntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEntrySummary2OnAfterAssignTrackingFromReservEntry(var TempGlobalEntrySummary: Record "Entry Summary" temporary; TempReservEntry: Record "Reservation Entry" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEntrySummary2OnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary"; var TempReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEntrySummary2OnAfterSetDoubleEntryAdjustment(var TempGlobalEntrySummary: Record "Entry Summary"; var TempReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEntrySummary2OnBeforeInsertOrModify(var TempGlobalEntrySummary: Record "Entry Summary" temporary; TempReservEntry: Record "Reservation Entry" temporary; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnAfterCopyNewTrackingFromTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification"; DirectTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSelectedTrackingToDataSetOnAfterCopyNewTrackingFromTrackingSpec(var TempTrackingSpecification: Record "Tracking Specification"; ChangeType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTempSummaryWithChangeOnAfterSetCurrentKey(var TempGlobalEntrySummary: Record "Entry Summary"; var ChangedEntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBinContentOnBeforeCalcSumsQtyBase(var TempEntrySummary: Record "Entry Summary"; var WarehouseEntry: Record "Warehouse Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRelatedParentTrkgSpecOnAfterSetFilters(var TempTrackingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnBeforeLookupMode(var TempGlobalEntrySummary: Record "Entry Summary"; var TempTrackingSpecification: Record "Tracking Specification"; var ItemTrackingSummaryPage: Page "Item Tracking Summary"; CurrBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveLookupDataOnAfterReservEntrySetFilters(var ReservEntry: Record "Reservation Entry"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveLookupDataOnAfterTransferToTempRec(var TempEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemLedgEntry: Record "Item Ledger Entry"; var LastSummaryEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTempSummaryWithChangeOnAfterCalcCurrentPendingQuantity(var TempChangedEntrySummary: Record "Entry Summary" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSelectedTrackingToDataSetOnBeforeUpdateWithChange(var TempEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecification: Record "Tracking Specification"; ChangeType: Option Insert,Modify,Delete)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCurrentPendingQtyOnLoop(var TempGlobalChangedEntrySummary: Record "Entry Summary" temporary; CurrBinCode: Code[20]; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTempSummaryWithChange(var TempChangedEntrySummary: Record "Entry Summary" temporary; CurrBinCode: Code[20]; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrentBinAndItemTrkgCode(xBinCode: Code[20]; BinCode: Code[20]; CurrItemTrackingCode: Record "Item Tracking Code"; var FullGlobalDataSetExists: Boolean; var PartialGlobalDataSetExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSelectedTrackingToDataSetOnAfterSetTrackingFilterFromEntrySummary(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupTrackingAvailabilityOnBeforeSetSources(var TempGlobalEntrySummary: Record "Entry Summary" temporary; TempTrackingSpecification: Record "Tracking Specification" temporary; ItemTrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBinContentOnBeforeUpdateBinContent(var TempEntrySummary: Record "Entry Summary" temporary; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean; var TempGlobalReservationEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectMultipleTrackingNoOnBeforeAutoSelectTrackingNo(var SkipAutoSelectTrackingNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectMultipleTrackingNoOnBeforeAddSelectedTrackingToDataSet(var TempEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; CurrentSignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemLedgToTempRecOnBeforeFindSetItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistEditTrackingNoLookupLotNo(TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemTrackingSummaryPage: Page "Item Tracking Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTempGlobalEntrySummaryExpirationDate(TempGlobalEntrySummary: Record "Entry Summary" temporary; TempReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnFindRelatedParentTrkgSpecOnSetSourceFilters(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;
}

