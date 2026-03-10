// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Reflection;

/// <summary>
/// This codeunit's responsibility is to help find inventory availability.
/// </summary>
codeunit 20445 "Qlty. Inventory Availability"
{
    var
        ThereIsNoSourceItemErr: Label 'There is no item or insufficient tracking defined on the inspection %1. Unable to perform the inventory related transaction. Please update the inspection with the item details and then try again.', Locked = true;
        SampleSizeZeroErr: Label 'Using the sample size for inspection %1 was requested, however the sample size for the inspection is zero. You can change this by using a different quantity instruction, or by navigating to the inspection and setting the sample size.', Comment = '%1=the inspection', Locked = true;
        NoSamplesToMoveErr: Label 'No samples meet the condition specified.', Locked = true;
        SerialQuantityGreaterThanOneErr: Label '%1 (%2) cannot be greater than 1 when New Serial No. is requested.', Comment = '%1=quantity behavior, %2=quantity';
        ZeroQuantityErr: Label 'Unable to use the disposition %1 on the inspection %2 for the item %3 because the quantity is zero.', Comment = '%1=the inspection, %2=the inspection, %3=the item';
        SupplyFromLocationCodeNameLbl: Label 'Supply-from Location Code', Locked = true;
        FromLocationCodeNameLbl: Label 'From Location Code', Locked = true;
        LocationCodeNameLbl: Label 'Location Code', Locked = true;
        FromProductionBinCodeNameLbl: Label 'From-Production Bin Code', Locked = true;
        FromBinCodeNameLbl: Label 'From Bin Code', Locked = true;
        TransferFromBinCodeNameLbl: Label 'Transfer-From Bin Code', Locked = true;
        BinCodeNameLbl: Label 'Bin Code', Locked = true;
        ReturnQtyToReceiveBaseNameLbl: Label 'Return Qty. to Receive (Base)', Locked = true;
        QtyToShipBaseNameLbl: Label 'Qty. to Ship (Base)', Locked = true;
        QtyToReceiveBaseNameLbl: Label 'Qty. to Receive (Base)', Locked = true;
        QtyToReceiveNameLbl: Label 'Qty. to Receive', Locked = true;
        QtyToHandleBaseNameLbl: Label 'Qty. to Handle (Base)', Locked = true;
        QuantityToHandleNameLbl: Label 'Quantity to Handle', Locked = true;

    /// <summary>
    /// GetCurrentLocationOfTrackedInventory gets the current location of the Item+Item tracking defined on the inspection.
    /// If multiple locations/bins are determined then those multiple locations/bins are supplied in TempBinContent
    /// </summary>
    /// <param name="QltyInspectionHeader">Record "Qlty. Inspection Header".</param>
    /// <param name="TempBinContent">Temporary var Record "Bin Content".   Multiple bin locations could be available.</param>
    /// <returns>Return variable of type Boolean.</returns>
    internal procedure GetCurrentLocationOfTrackedInventory(QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempBinContent: Record "Bin Content" temporary): Boolean
    begin
        if (QltyInspectionHeader."Source Lot No." = '') and (QltyInspectionHeader."Source Serial No." = '') and (QltyInspectionHeader."Source Package No." = '') then
            exit(false);

        if not InspectionHasSufficientItemDetails(QltyInspectionHeader, false, false, false, false) then
            exit(false);

        Clear(TempBinContent);
        TempBinContent.DeleteAll();

        ProcessBinMandatoryLocations(QltyInspectionHeader, TempBinContent);

        ProcessNonBinMandatoryLocations(QltyInspectionHeader, TempBinContent);

        TempBinContent.Reset();

        exit(not TempBinContent.IsEmpty());
    end;

    local procedure ProcessBinMandatoryLocations(QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempBinContent: Record "Bin Content" temporary)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Item No.", QltyInspectionHeader."Source Item No.");
        BinContent.SetRange("Variant Code", QltyInspectionHeader."Source Variant Code");
        if QltyInspectionHeader."Source Lot No." <> '' then
            BinContent.SetRange("Lot No. Filter", QltyInspectionHeader."Source Lot No.");
        if QltyInspectionHeader."Source Serial No." <> '' then
            BinContent.SetRange("Serial No. Filter", QltyInspectionHeader."Source Serial No.");
        if QltyInspectionHeader."Source Package No." <> '' then
            BinContent.SetRange("Package No. Filter", QltyInspectionHeader."Source Package No.");
        BinContent.SetAutoCalcFields("Quantity (Base)");
        if BinContent.FindSet() then
            repeat
                if BinContent."Quantity (Base)" > 0 then
                    if not TempBinContent.Get(BinContent."Location Code", BinContent."Bin Code", BinContent."Item No.", BinContent."Variant Code", BinContent."Unit of Measure Code") then begin
                        TempBinContent.Init();
                        TempBinContent := BinContent;
                        TempBinContent."Min. Qty." := BinContent."Quantity (Base)";
                        TempBinContent.Insert();
                    end;
            until BinContent.Next() = 0;
    end;

    local procedure ProcessNonBinMandatoryLocations(QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempBinContent: Record "Bin Content" temporary)
    var
        QltyItemLedgerByLocationQuery: Query "Qlty. Item Ledger By Location";
    begin
        if QltyInspectionHeader."Source Item No." = '' then
            exit;

        QltyItemLedgerByLocationQuery.SetRange(Location_Bin_Mandatory, false);

        QltyItemLedgerByLocationQuery.SetFilter(Item_Ledger_Entry_Item_No, QltyInspectionHeader."Source Item No.");
        if QltyInspectionHeader."Source Variant Code" <> '' then
            QltyItemLedgerByLocationQuery.SetFilter(Item_Ledger_Entry_Variant_Code, QltyInspectionHeader."Source Variant Code");
        if QltyInspectionHeader."Source Lot No." <> '' then
            QltyItemLedgerByLocationQuery.SetFilter(Item_Ledger_Entry_Lot_No, QltyInspectionHeader."Source Lot No.");
        if QltyInspectionHeader."Source Serial No." <> '' then
            QltyItemLedgerByLocationQuery.SetFilter(Item_Ledger_Entry_Serial_No, QltyInspectionHeader."Source Serial No.");
        if QltyInspectionHeader."Source Package No." <> '' then
            QltyItemLedgerByLocationQuery.SetFilter(Item_Ledger_Entry_Package_No, QltyInspectionHeader."Source Package No.");

        if QltyItemLedgerByLocationQuery.Open() then begin
            while QltyItemLedgerByLocationQuery.Read() do
                if not TempBinContent.Get(QltyItemLedgerByLocationQuery.Location_Code, '', '', '', '') then begin
                    TempBinContent.Init();
                    TempBinContent."Location Code" := QltyItemLedgerByLocationQuery.Location_Code;
                    TempBinContent."Bin Code" := '';
                    TempBinContent."Item No." := '';
                    TempBinContent."Variant Code" := '';
                    TempBinContent."Unit of Measure Code" := '';
                    TempBinContent."Min. Qty." := QltyItemLedgerByLocationQuery.Item_Ledger_Entry_Sum_Quantity;
                    TempBinContent.Insert();
                end;

            QltyItemLedgerByLocationQuery.Close();
        end;
    end;

    internal procedure GetFromDetailsFromInspectionSource(QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempToMoveBinContent: Record "Bin Content" temporary)
    var
        RecordRefToSearch: RecordRef;
        NullForComparison: RecordId;
        RecordIdentificationToUse: RecordId;
        LocationCode: Code[10];
        BinCode: Code[20];
        QuantityBaseValue: Decimal;
        OfRecordIds: List of [RecordId];
    begin
        LocationCode := '';
        BinCode := '';

        if QltyInspectionHeader."Source RecordId" <> NullForComparison then
            OfRecordIds.Add(QltyInspectionHeader."Source RecordId");

        if (QltyInspectionHeader."Source RecordId 2" <> NullForComparison) and (not OfRecordIds.Contains(QltyInspectionHeader."Source RecordId 2")) then
            OfRecordIds.Add(QltyInspectionHeader."Source RecordId 2");

        if (QltyInspectionHeader."Source RecordId 3" <> NullForComparison) and (not OfRecordIds.Contains(QltyInspectionHeader."Source RecordId 3")) then
            OfRecordIds.Add(QltyInspectionHeader."Source RecordId 3");

        if (QltyInspectionHeader."Trigger RecordId" <> NullForComparison) and (not OfRecordIds.Contains(QltyInspectionHeader."Trigger RecordId")) then
            OfRecordIds.Add(QltyInspectionHeader."Trigger RecordId");

        if QltyInspectionHeader."Source Quantity (Base)" <> 0 then
            QuantityBaseValue := QltyInspectionHeader."Source Quantity (Base)";

        foreach RecordIdentificationToUse in OfRecordIds do begin
            Clear(RecordRefToSearch);
            RecordRefToSearch := RecordIdentificationToUse.GetRecord();
            RecordRefToSearch.SetRecFilter();
            if RecordRefToSearch.FindFirst() then begin
                LocationCode := QltyInspectionHeader."Location Code";
                GetFromLocationAndBinBasedOnNamingConventions(RecordRefToSearch, LocationCode, BinCode, QuantityBaseValue);
                if LocationCode <> '' then begin
                    TempToMoveBinContent.Reset();
                    TempToMoveBinContent.SetRange("Location Code", LocationCode);
                    if BinCode <> '' then
                        TempToMoveBinContent.SetRange("Bin Code", BinCode);
                    if not TempToMoveBinContent.FindFirst() then begin
                        TempToMoveBinContent.Init();
                        TempToMoveBinContent."Location Code" := LocationCode;
                        TempToMoveBinContent."Bin Code" := BinCode;
                        TempToMoveBinContent."Min. Qty." := QuantityBaseValue;
                        TempToMoveBinContent.Insert(false);
                    end;
                end;
            end;
        end;

        TempToMoveBinContent.Reset();
        if TempToMoveBinContent.IsEmpty() then begin
            TempToMoveBinContent.Init();
            TempToMoveBinContent."Location Code" := QltyInspectionHeader."Location Code";
            TempToMoveBinContent."Min. Qty." := QuantityBaseValue;
            TempToMoveBinContent.Insert(false);
        end;
    end;

    local procedure GetFromLocationAndBinBasedOnNamingConventions(var RecordRef: RecordRef; var LocationCode: Code[10]; var BinCode: Code[20]; var QuantityBase: Decimal)
    var
        Location: Record Location;
        CurrentField: Record Field;
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
    begin
        case RecordRef.Number() of
            Database::"Item Ledger Entry":
                begin
                    RecordRef.SetTable(ItemLedgerEntry);
                    QltyItemTrackingMgmt.GetItemTrackingCode(ItemLedgerEntry."Item No.", ItemTrackingCode);
                    if WarehouseEntry.ReadPermission() then begin
                        WarehouseEntry.SetRange("Location Code", ItemLedgerEntry."Location Code");
                        WarehouseEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");

                        if ItemLedgerEntry."Lot No." <> '' then
                            if ItemTrackingCode."Lot Warehouse Tracking" then
                                WarehouseEntry.SetRange("Lot No.", ItemLedgerEntry."Lot No.");
                        if ItemLedgerEntry."Serial No." <> '' then
                            if ItemTrackingCode."SN Warehouse Tracking" then
                                WarehouseEntry.SetRange("Serial No.", ItemLedgerEntry."Serial No.");
                        if ItemLedgerEntry."Package No." <> '' then
                            if ItemTrackingCode."Package Warehouse Tracking" then
                                WarehouseEntry.SetRange("Package No.", ItemLedgerEntry."Package No.");

                        WarehouseEntry.SetRange("Source No.", ItemLedgerEntry."Document No.");
                        WarehouseEntry.SetRange("Registering Date", ItemLedgerEntry."Posting Date");
                        WarehouseEntry.SetRange("Quantity", ItemLedgerEntry."Quantity");

                        if not WarehouseEntry.IsEmpty() then
                            if Location.Get(ItemLedgerEntry."Location Code") then
                                if Location."Adjustment Bin Code" <> '' then begin
                                    WarehouseEntry.SetFilter("Bin Code", '<>%1', Location."Adjustment Bin Code");
                                    if WarehouseEntry.IsEmpty() then
                                        WarehouseEntry.SetRange("Source No.", '');
                                end;
                        if WarehouseEntry.FindLast() then begin
                            LocationCode := ItemLedgerEntry."Location Code";
                            BinCode := WarehouseEntry."Bin Code";
                        end;
                    end;
                end;
        end;

        CurrentField.SetRange(TableNo, RecordRef.Number());
        if LocationCode = '' then begin
            CurrentField.SetRange(FieldName, SupplyFromLocationCodeNameLbl);
            if CurrentField.FindFirst() then
                LocationCode := CopyStr(Format(RecordRef.Field(CurrentField."No.").Value()), 1, MaxStrLen(LocationCode));
        end;
        if LocationCode = '' then begin
            CurrentField.SetRange(FieldName, FromLocationCodeNameLbl);
            if CurrentField.FindFirst() then
                LocationCode := CopyStr(Format(RecordRef.Field(CurrentField."No.").Value()), 1, MaxStrLen(LocationCode));
        end;
        if LocationCode = '' then begin
            CurrentField.SetRange(FieldName, LocationCodeNameLbl);
            if CurrentField.FindFirst() then
                LocationCode := CopyStr(Format(RecordRef.Field(CurrentField."No.").Value()), 1, MaxStrLen(LocationCode));
        end;

        if BinCode = '' then begin
            CurrentField.SetRange(FieldName, FromProductionBinCodeNameLbl);
            if CurrentField.FindFirst() then
                BinCode := CopyStr(Format(RecordRef.Field(CurrentField."No.").Value()), 1, MaxStrLen(BinCode));
        end;
        if BinCode = '' then begin
            CurrentField.SetRange(FieldName, FromBinCodeNameLbl);
            if CurrentField.FindFirst() then
                BinCode := CopyStr(Format(RecordRef.Field(CurrentField."No.").Value()), 1, MaxStrLen(BinCode));
        end;
        if BinCode = '' then begin
            CurrentField.SetRange(FieldName, TransferFromBinCodeNameLbl);
            if CurrentField.FindFirst() then
                BinCode := CopyStr(Format(RecordRef.Field(CurrentField."No.").Value()), 1, MaxStrLen(BinCode));
        end;
        if BinCode = '' then begin
            CurrentField.SetRange(FieldName, BinCodeNameLbl);
            if CurrentField.FindFirst() then
                BinCode := CopyStr(Format(RecordRef.Field(CurrentField."No.").Value()), 1, MaxStrLen(BinCode));
        end;

        if QuantityBase = 0 then begin
            CurrentField.SetRange(FieldName, ReturnQtyToReceiveBaseNameLbl);
            if CurrentField.FindFirst() then
                if Evaluate(QuantityBase, Format(RecordRef.Field(CurrentField."No.").Value())) then;
        end;
        if QuantityBase = 0 then begin
            CurrentField.SetRange(FieldName, QtyToShipBaseNameLbl);
            if CurrentField.FindFirst() then
                if Evaluate(QuantityBase, Format(RecordRef.Field(CurrentField."No.").Value())) then;
        end;
        if QuantityBase = 0 then begin
            CurrentField.SetRange(FieldName, QtyToReceiveBaseNameLbl);
            if CurrentField.FindFirst() then
                if Evaluate(QuantityBase, Format(RecordRef.Field(CurrentField."No.").Value())) then;
        end;
        if QuantityBase = 0 then begin
            CurrentField.SetRange(FieldName, QtyToReceiveNameLbl);
            if CurrentField.FindFirst() then
                if Evaluate(QuantityBase, Format(RecordRef.Field(CurrentField."No.").Value())) then;
        end;
        if QuantityBase = 0 then begin
            CurrentField.SetRange(FieldName, QtyToHandleBaseNameLbl);
            if CurrentField.FindFirst() then
                if Evaluate(QuantityBase, Format(RecordRef.Field(CurrentField."No.").Value())) then;
        end;
        if QuantityBase = 0 then begin
            CurrentField.SetRange(FieldName, QuantityToHandleNameLbl);
            if CurrentField.FindFirst() then
                if Evaluate(QuantityBase, Format(RecordRef.Field(CurrentField."No.").Value())) then;
        end;
    end;

    local procedure CheckIfShouldSkipBinContent(var TempExistingBinContent: Record "Bin Content" temporary; var TempCopyBinContent: Record "Bin Content" temporary; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; MultipleBins: Boolean; BinMandatory: Boolean): Boolean
    begin
        if MultipleBins and BinMandatory and (QltyQuantityBehavior <> QltyQuantityBehavior::"Item Tracked Quantity") and (TempExistingBinContent."Bin Code" = '') then begin
            TempCopyBinContent.SetFilter("Bin Code", '<>%1', '');
            TempCopyBinContent.SetRange("Location Code", TempExistingBinContent."Location Code");
            exit(not TempCopyBinContent.IsEmpty());
        end;
    end;

    local procedure InspectionHasSufficientItemDetails(QltyInspectionHeader: Record "Qlty. Inspection Header"; CurrentError: Boolean; CheckLot: Boolean; CheckSerial: Boolean; CheckPackage: Boolean): Boolean
    begin
        if (QltyInspectionHeader."Source Item No." = '') or
           (CheckLot and (QltyInspectionHeader."Source Lot No." = '')) or
           (CheckSerial and (QltyInspectionHeader."Source Serial No." = '')) or
           (CheckPackage and (QltyInspectionHeader."Source Package No." = ''))
        then begin
            if CurrentError then
                Error(ThereIsNoSourceItemErr, QltyInspectionHeader.GetFriendlyIdentifier());
            exit(false);
        end;

        exit(true);
    end;

    local procedure GetQuantityToHandleFromInspection(QltyInspectionHeader: Record "Qlty. Inspection Header"; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSpecificQuantity: Decimal; TempExistingInventoryBinContent: Record "Bin Content" temporary) ResultQuantity: Decimal
    begin
        if OptionalSpecificQuantity = 0 then
            OptionalSpecificQuantity := QltyInspectionHeader."Source Quantity (Base)";

        if QltyQuantityBehavior = QltyQuantityBehavior::"Item Tracked Quantity" then
            ResultQuantity := TempExistingInventoryBinContent."Min. Qty.";
        if ResultQuantity = 0 then
            ResultQuantity := TempExistingInventoryBinContent."Min. Qty.";

        if QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity" then
            ResultQuantity := OptionalSpecificQuantity;
        if QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity" then begin
            ResultQuantity := QltyInspectionHeader."Sample Size";
            if QltyInspectionHeader."Sample Size" = 0 then
                Error(SampleSizeZeroErr, QltyInspectionHeader."No.");
        end;

        if QltyQuantityBehavior in [QltyQuantityBehavior::"Failed Quantity", QltyQuantityBehavior::"Passed Quantity"] then
            ResultQuantity := GetPassOrFailSamplesCount(QltyInspectionHeader, QltyQuantityBehavior);
    end;

    /// <summary>
    /// Looks at sampling tests to determine number of passed or failed samples. This can exceed the sample size to allow for oversampling.
    /// Pass Conditions: the samples must have passed all sampling test measurements
    /// Fail Conditions: One or more fail results for a sample designates it as failed.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="QuantityBehavior"></param>
    /// <returns>either the pass quantity or fail quantity.</returns>
    internal procedure GetPassOrFailSamplesCount(var QltyInspectionHeader: Record "Qlty. Inspection Header"; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior") PassOrFailQuantity: Decimal
    begin
        case QltyQuantityBehavior of
            QltyQuantityBehavior::"Passed Quantity":
                PassOrFailQuantity := QltyInspectionHeader."Pass Quantity";
            QltyQuantityBehavior::"Failed Quantity":
                PassOrFailQuantity := QltyInspectionHeader."Fail Quantity";
        end;

        if PassOrFailQuantity <= 0 then
            Error(NoSamplesToMoveErr);
    end;

    /// <summary>
    /// Populates the quantity buffer in TempQuantityQltyDispositionBuffer.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="TempQuantityQltyDispositionBuffer">The result.</param>
    /// <returns></returns>
    internal procedure PopulateQuantityBuffer(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TempQuantityQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary)
    var
        Location: Record Location;
        TempExistingInventoryCopyBinContent: Record "Bin Content" temporary;
        TempExistingInventoryBinContent: Record "Bin Content" temporary;
        MultipleBins: Boolean;
        SkipBinContent: Boolean;
        IsHandled: Boolean;
        BufferEntryCounter: Integer;
    begin
        TempQuantityQltyDispositionBuffer.Reset();
        TempQuantityQltyDispositionBuffer.DeleteAll();

        OnBeforePopulateBinContentBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityQltyDispositionBuffer, TempExistingInventoryBinContent, IsHandled);
        if IsHandled then
            exit;

        if TempInstructionQltyDispositionBuffer."Quantity Behavior" = TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity" then
            GetCurrentLocationOfTrackedInventory(QltyInspectionHeader, TempExistingInventoryBinContent)
        else
            GetFromDetailsFromInspectionSource(QltyInspectionHeader, TempExistingInventoryBinContent);

        TempExistingInventoryBinContent.Reset();
        if TempInstructionQltyDispositionBuffer."Location Filter" <> '' then
            TempExistingInventoryBinContent.SetFilter("Location Code", TempInstructionQltyDispositionBuffer."Location Filter");

        if TempInstructionQltyDispositionBuffer."Bin Filter" <> '' then
            TempExistingInventoryBinContent.SetFilter("Bin Code", TempInstructionQltyDispositionBuffer."Bin Filter");

        if TempExistingInventoryBinContent.FindSet() then begin
            MultipleBins := TempExistingInventoryBinContent.Count() > 1;
            if MultipleBins and (TempInstructionQltyDispositionBuffer."Quantity Behavior" <> TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity") then begin
                repeat
                    TempExistingInventoryCopyBinContent := TempExistingInventoryBinContent;
                    TempExistingInventoryCopyBinContent.Insert();
                until TempExistingInventoryBinContent.Next() = 0;
                TempExistingInventoryBinContent.FindSet();
            end;

            repeat
                SkipBinContent := false;
                if TempExistingInventoryBinContent."Location Code" <> '' then
                    if Location.Get(TempExistingInventoryBinContent."Location Code") then begin
                        SkipBinContent := Location."Use As In-Transit";
                        if not SkipBinContent then
                            SkipBinContent := CheckIfShouldSkipBinContent(
                                TempExistingInventoryBinContent,
                                TempExistingInventoryCopyBinContent,
                                TempInstructionQltyDispositionBuffer."Quantity Behavior",
                                MultipleBins,
                                Location."Bin Mandatory");
                    end;

                if not SkipBinContent then begin
                    BufferEntryCounter += 1;
                    TempQuantityQltyDispositionBuffer := TempInstructionQltyDispositionBuffer;
                    TempQuantityQltyDispositionBuffer."Buffer Entry No." := BufferEntryCounter;
                    TempQuantityQltyDispositionBuffer."Location Filter" := TempExistingInventoryBinContent."Location Code";
                    TempQuantityQltyDispositionBuffer."Bin Filter" := TempExistingInventoryBinContent."Bin Code";
                    TempQuantityQltyDispositionBuffer."Qty. To Handle (Base)" := GetQuantityToHandleFromInspection(
                        QltyInspectionHeader,
                        TempInstructionQltyDispositionBuffer."Quantity Behavior",
                        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)",
                        TempExistingInventoryBinContent);

                    if TempQuantityQltyDispositionBuffer."Qty. To Handle (Base)" = 0 then
                        Error(ZeroQuantityErr, TempInstructionQltyDispositionBuffer."Disposition Action", QltyInspectionHeader."No.", QltyInspectionHeader."Source Item No.");

                    if (TempQuantityQltyDispositionBuffer."New Serial No." <> '') and (TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" > 1) then
                        Error(SerialQuantityGreaterThanOneErr, TempInstructionQltyDispositionBuffer."Entry Behavior", TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)");

                    TempQuantityQltyDispositionBuffer.Insert(false);
                end;
            until TempExistingInventoryBinContent.Next() = 0;
        end;

        OnAfterPopulateBinContentBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityQltyDispositionBuffer, TempExistingInventoryBinContent);
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePopulateBinContentBuffer(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TempQuantityQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TempExistingInventoryBinContent: Record "Bin Content" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPopulateBinContentBuffer(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TempQuantityQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TempExistingInventoryBinContent: Record "Bin Content" temporary)
    begin
    end;
}
