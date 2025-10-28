// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Tracking;

/// <summary>
/// Helps with item tracking management.
/// </summary>
codeunit 20439 "Qlty. Item Tracking Mgmt."
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Whse. Item Tracking Line" = rimd;

    var
        SerialNumberAlreadyEnteredErr: Label 'Serial Number: [%1] has already been entered.', Comment = '%1 = The serial number';
        PurchaseLineLinkedProdOrderErr: Label 'You cannot define item tracking on the purchase line %2 %3 because it is linked to production order [%1].', Comment = '%1 = Production Order number,%2=the order no, %3=the item no.';
        NegativeTrackingErr: Label 'Cannot create negative tracking entries on the item %1 in the purchase document %2', Comment = '%1=the item no., %2=the purchase document no';

    /// <summary>
    /// Creates an item journal line reservation entry for the supplyed journal line.
    /// Set the tracking on the line (no modify needed) to give the tracking instruction.
    /// </summary>
    /// <param name="ItemJournalLine"></param>
    /// <param name="CreatedActualReservationEntry"></param>
    procedure CreateItemJournalLineReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var CreatedActualReservationEntry: Record "Reservation Entry")
    var
        InstructionForReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        EntryType: Integer;
        ExpirationDate: Date;
        CurrentSignFactor: Integer;
        ReservationStatus: Enum "Reservation Status";
        ReceiptDate: Date;
        Handled: Boolean;
        ShipDate: Date;
    begin
        OnBeforeCreateItemJournalLineReservationEntry(ItemJournalLine, CreatedActualReservationEntry, Handled);
        if Handled then
            exit;

        if (ItemJournalLine."Serial No." = '') and (ItemJournalLine."Lot No." = '') and (ItemJournalLine."Package No." = '') then
            exit;
        if ItemJournalLine."Quantity (Base)" = 0 then
            exit;

        if (ItemJournalLine."Quantity (Base)" > 1) and (ItemJournalLine."Serial No." <> '') then
            Error(SerialNumberAlreadyEnteredErr, ItemJournalLine."Serial No.");

        ExpirationDate := ItemJournalLine."Expiration Date";
        if ExpirationDate = 0D then
            ExpirationDate := GetExpirationDate(ItemJournalLine."Location Code", ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Lot No.", ItemJournalLine."Serial No.", ItemJournalLine."Package No.");
        if ExpirationDate <> 0D then begin
            CreateReservEntry.SetNewExpirationDate(ExpirationDate);
            InstructionForReservationEntry."Expiration Date" := ExpirationDate;
            InstructionForReservationEntry."New Expiration Date" := InstructionForReservationEntry."Expiration Date";
        end;

        EntryType := ItemJournalLine."Entry Type".AsInteger();
        ReservationStatus := ReservationStatus::Prospect;
        InstructionForReservationEntry."Serial No." := ItemJournalLine."Serial No.";
        if ItemJournalLine."New Serial No." <> '' then
            InstructionForReservationEntry."New Serial No." := ItemJournalLine."New Serial No.";

        InstructionForReservationEntry."Lot No." := ItemJournalLine."Lot No.";
        if ItemJournalLine."New Lot No." <> '' then
            InstructionForReservationEntry."New Lot No." := ItemJournalLine."New Lot No.";
        InstructionForReservationEntry."Package No." := ItemJournalLine."Package No.";
        if ItemJournalLine."New Package No." <> '' then
            InstructionForReservationEntry."New Package No." := ItemJournalLine."New Package No.";

        if ExpirationDate <> 0D then
            InstructionForReservationEntry."Expiration Date" := ExpirationDate;
        if ItemJournalLine."New Item Expiration Date" <> 0D then
            InstructionForReservationEntry."New Expiration Date" := ItemJournalLine."New Item Expiration Date"
        else
            InstructionForReservationEntry."New Expiration Date" := ExpirationDate;
        CreateReservEntry.SetNewTrackingFromItemJnlLine(ItemJournalLine);

        BindSubscription(this);
        SetItemTrackingFlag(InstructionForReservationEntry);

        if ItemJournalLine."Posting Date" = 0D then
            ItemJournalLine."Posting Date" := WorkDate();

        CreateReservEntry.SetInbound(ItemJournalLine.IsInbound());
        CreateReservEntry.CreateReservEntryFor(Database::"Item Journal Line", EntryType, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Order Line No.", ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure", ItemJournalLine.Quantity / ItemJournalLine."Qty. per Unit of Measure", ItemJournalLine."Quantity (Base)", InstructionForReservationEntry);

        InstructionForReservationEntry."Source Type" := Database::"Item Journal Line";
        InstructionForReservationEntry."Source Subtype" := EntryType;
        CurrentSignFactor := CreateReservEntry.SignFactor(InstructionForReservationEntry);
        if CurrentSignFactor < 0 then begin
            ReceiptDate := 0D;
            ShipDate := ItemJournalLine."Posting Date";
        end else begin
            ReceiptDate := ItemJournalLine."Posting Date";
            ShipDate := 0D;
        end;

        CreateReservEntry.CreateEntry(ItemJournalLine."Item No.", ItemJournalLine."Variant Code", ItemJournalLine."Location Code", ItemJournalLine.Description, ReceiptDate, ShipDate, 0, ReservationStatus);
        UnbindSubscription(this);
        CreateReservEntry.GetLastEntry(CreatedActualReservationEntry);

        CopyReservationEntryInstructions(InstructionForReservationEntry, CreatedActualReservationEntry);

        OnAfterCreateItemJournalLineReservationEntry(ItemJournalLine, CreatedActualReservationEntry);
    end;

    /// <summary>
    /// Helps work around issues in base BC where the package no.
    /// is not set and the expiration date can not fill in by default.
    /// </summary>
    /// <param name="InstructionForReservationEntry"></param>
    /// <param name="CreatedActualReservationEntry"></param>
    local procedure CopyReservationEntryInstructions(var InstructionForReservationEntry: Record "Reservation Entry"; var CreatedActualReservationEntry: Record "Reservation Entry")
    begin
        if (InstructionForReservationEntry."Expiration Date" <> 0D) and (CreatedActualReservationEntry."Expiration Date" = 0D) then
            CreatedActualReservationEntry."Expiration Date" := InstructionForReservationEntry."Expiration Date";
        if InstructionForReservationEntry."New Serial No." <> '' then
            CreatedActualReservationEntry."New Serial No." := InstructionForReservationEntry."New Serial No.";

        if InstructionForReservationEntry."New Lot No." <> '' then
            CreatedActualReservationEntry."New Lot No." := InstructionForReservationEntry."New Lot No.";
        if InstructionForReservationEntry."Package No." <> '' then
            CreatedActualReservationEntry."Package No." := InstructionForReservationEntry."Package No.";

        if InstructionForReservationEntry."New Package No." <> '' then
            CreatedActualReservationEntry."New Package No." := InstructionForReservationEntry."New Package No.";
        if InstructionForReservationEntry."New Expiration Date" <> 0D then
            CreatedActualReservationEntry."New Expiration Date" := InstructionForReservationEntry."New Expiration Date";
        CreatedActualReservationEntry.Modify();
    end;

    /// <summary>
    /// Sets the "Item Tracking" flag on the reservation entry based on the state of the lot,serial,package on the item journal line.
    /// </summary>
    /// <param name="ReservationEntry"></param>
    local procedure SetItemTrackingFlag(var ReservationEntry: Record "Reservation Entry")
    var
        HasLotNo: Boolean;
        HasSerialNo: Boolean;
        HasPackageNo: Boolean;
    begin
        if ReservationEntry."Lot No." <> '' then
            HasLotNo := true;
        if ReservationEntry."Serial No." <> '' then
            HasSerialNo := true;
        if ReservationEntry."Package No." <> '' then
            HasPackageNo := true;
        case true of
            HasLotNo and HasSerialNo and HasPackageNo:
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot and Serial and Package No.";
            HasLotNo and HasPackageNo:
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot and Package No.";
            HasPackageNo:
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Package No.";
            HasSerialNo and HasPackageNo:
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial and Package No.";
            HasLotNo and HasSerialNo:
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot and Serial No.";
            HasLotNo:
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
            HasSerialNo:
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial No.";
            else
                ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::None;
        end;
    end;

    /// <summary>
    /// Used for BindSubscription use in template selection.
    /// </summary>
    /// <param name="ItemJnlTemplate"></param>
    /// <param name="PageTemplate"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ItemJnlManagement, 'OnTemplateSelectionSetFilter', '', true, true)]
    local procedure HandleOnTemplateSelectionSetFilter(var ItemJnlTemplate: Record "Item Journal Template"; var PageTemplate: Option)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        SearchItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        if not QltyManagementSetup.ReadPermission() then
            exit;
        if not QltyManagementSetup.Get() then
            exit;

        if ItemJnlTemplate.GetFilter("Page ID") = '' then
            exit;

        if ItemJnlTemplate.Count() <= 1 then
            exit;

        case ItemJnlTemplate.GetRangeMin("Page ID") of
            Page::"Item Reclass. Journal":
                if QltyManagementSetup."Bin Move Batch Name" <> '' then begin
                    SearchItemJournalTemplate.CopyFilters(ItemJnlTemplate);
                    SearchItemJournalTemplate.SetLoadFields(Name, Type);
                    if SearchItemJournalTemplate.FindSet() then
                        repeat
                            ItemJournalBatch.SetRange("Journal Template Name", SearchItemJournalTemplate.Name);
                            ItemJournalBatch.SetRange("Template Type", SearchItemJournalTemplate.Type);
                            ItemJournalBatch.SetRange(Name, QltyManagementSetup."Bin Move Batch Name");
                            if ItemJournalBatch.Count() = 1 then begin
                                ItemJnlTemplate.SetRange(Name, SearchItemJournalTemplate.Name);
                                exit;
                            end;
                        until SearchItemJournalTemplate.Next() = 0;
                    SearchItemJournalTemplate.SetView(ItemJnlTemplate.GetView());
                end;
            Page::"Item Journal":
                if QltyManagementSetup."Adjustment Batch Name" <> '' then begin
                    SearchItemJournalTemplate.CopyFilters(ItemJnlTemplate);
                    SearchItemJournalTemplate.SetLoadFields(Name, Type);
                    if SearchItemJournalTemplate.FindSet() then
                        repeat
                            ItemJournalBatch.SetRange("Journal Template Name", SearchItemJournalTemplate.Name);
                            ItemJournalBatch.SetRange("Template Type", SearchItemJournalTemplate.Type);
                            ItemJournalBatch.SetRange(Name, QltyManagementSetup."Adjustment Batch Name");
                            if ItemJournalBatch.Count() = 1 then begin
                                ItemJnlTemplate.SetRange(Name, SearchItemJournalTemplate.Name);
                                exit;
                            end;
                        until SearchItemJournalTemplate.Next() = 0;
                    SearchItemJournalTemplate.SetView(ItemJnlTemplate.GetView());
                end;
        end;
    end;

    /// <summary>
    /// Used to help choose which template to use when multiple templates are configured for a given template type.
    /// </summary>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="WhseJnlTemplate"></param>
    /// <param name="OpenFromBatch"></param>
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnTemplateSelectionOnAfterSetFilters', '', true, true)]
    local procedure HandleOnTemplateSelectionOnAfterSetFilters(var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseJnlTemplate: Record "Warehouse Journal Template"; OpenFromBatch: Boolean)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        SearchWarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        if not QltyManagementSetup.ReadPermission() then
            exit;
        if not QltyManagementSetup.Get() then
            exit;

        if WhseJnlTemplate.GetFilter("Page ID") = '' then
            exit;

        if WhseJnlTemplate.Count() <= 1 then
            exit;

        case WhseJnlTemplate.GetRangeMin("Page ID") of
            Page::"Whse. Reclassification Journal":
                if QltyManagementSetup."Bin Whse. Move Batch Name" <> '' then begin
                    SearchWarehouseJournalTemplate.CopyFilters(WhseJnlTemplate);
                    SearchWarehouseJournalTemplate.SetLoadFields(Name, Type);
                    if SearchWarehouseJournalTemplate.FindSet() then
                        repeat
                            WarehouseJournalBatch.SetRange("Journal Template Name", SearchWarehouseJournalTemplate.Name);
                            WarehouseJournalBatch.SetRange("Template Type", SearchWarehouseJournalTemplate.Type);
                            WarehouseJournalBatch.SetRange(Name, QltyManagementSetup."Bin Whse. Move Batch Name");
                            if WarehouseJournalBatch.Count() = 1 then begin
                                WhseJnlTemplate.SetRange(Name, SearchWarehouseJournalTemplate.Name);
                                exit;
                            end;
                        until SearchWarehouseJournalTemplate.Next() = 0;
                    SearchWarehouseJournalTemplate.SetView(WhseJnlTemplate.GetView());
                end;
            Page::"Whse. Item Journal":
                if QltyManagementSetup."Whse. Adjustment Batch Name" <> '' then begin
                    SearchWarehouseJournalTemplate.CopyFilters(WhseJnlTemplate);
                    SearchWarehouseJournalTemplate.SetLoadFields(Name, Type);
                    if SearchWarehouseJournalTemplate.FindSet() then
                        repeat
                            WarehouseJournalBatch.SetRange("Journal Template Name", SearchWarehouseJournalTemplate.Name);
                            WarehouseJournalBatch.SetRange("Template Type", SearchWarehouseJournalTemplate.Type);
                            WarehouseJournalBatch.SetRange(Name, QltyManagementSetup."Whse. Adjustment Batch Name");
                            if WarehouseJournalBatch.Count() = 1 then begin
                                WhseJnlTemplate.SetRange(Name, SearchWarehouseJournalTemplate.Name);
                                exit;
                            end;
                        until SearchWarehouseJournalTemplate.Next() = 0;
                    SearchWarehouseJournalTemplate.SetView(WhseJnlTemplate.GetView());
                end;
        end;
    end;

    /// <summary>
    /// Gets the most recent expiration date for the given item,lot,serial/lot.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="LocationCode"></param>
    /// <returns></returns>   
    procedure GetExpirationDate(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; LocationCode: Code[10]) ExpirationDate: Date
    begin
        exit(GetExpirationDate(
                LocationCode,
                QltyInspectionTestHeader."Source Item No.",
                QltyInspectionTestHeader."Source Variant Code",
                QltyInspectionTestHeader."Source Lot No.",
                QltyInspectionTestHeader."Source Serial No.",
                QltyInspectionTestHeader."Source Package No."));
    end;

    local procedure GetExpirationDate(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50]) ExpirationDate: Date
    var
        Location: Record Location;
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if LocationCode <> '' then
            Location.Get(LocationCode);

        TempItemTrackingSetup."Serial No." := SerialNo;
        TempItemTrackingSetup."Lot No." := LotNo;
        TempItemTrackingSetup."Package No." := PackageNo;

        ItemTrackingManagement.GetWhseExpirationDate(ItemNo, VariantCode, Location, TempItemTrackingSetup, ExpirationDate);
    end;

    /// <summary>
    /// Returns true if the item is lot warehouse, or serial warehouse, or package warehouse tracked.
    /// </summary>
    /// <param name="ItemNo"></param>
    /// <returns></returns>
    procedure GetIsWarehouseTracked(ItemNo: Code[20]): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if GetItemTrackingCode(ItemNo, ItemTrackingCode) then
            exit(ItemTrackingCode."Lot Warehouse Tracking" or ItemTrackingCode."SN Warehouse Tracking" or ItemTrackingCode."Package Warehouse Tracking");

        exit(false);
    end;

    /// <summary>
    /// Returns true if the item tracking could be fetched or not.
    /// </summary>
    /// <param name="ItemNo"></param>
    /// <param name="ItemTrackingCode"></param>
    /// <returns></returns>
    procedure GetItemTrackingCode(ItemNo: Code[20]; var ItemTrackingCode: Record "Item Tracking Code"): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(false);

        if Item."Item Tracking Code" = '' then
            exit(false);

        exit(ItemTrackingCode.Get(Item."Item Tracking Code"));
    end;

    /// <summary>
    /// To simplify a situation where the Purchase Order Return line may have multiple associated tracking lines from the originating Purchase Receipt line, or may be based off of a receipt line with the wrong 
    /// item tracking, this deletes all Reservation Entries for the line and creates a single entry with the updated quantity.
    /// </summary>
    internal procedure DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; ReturnOrderPurchaseLine: Record "Purchase Line"; QtyToReturn: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        ExpirationDate: Date;
    begin
        ReservationEntry.SetRange("Location Code", ReturnOrderPurchaseLine."Location Code");
        ReservationEntry.SetRange("Item No.", QltyInspectionTestHeader."Source Item No.");
        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source ID", ReturnOrderPurchaseLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", ReturnOrderPurchaseLine."Line No.");
        ReservationEntry.SetRange(Positive, false);
        if QltyInspectionTestHeader."Source Variant Code" <> '' then
            ReservationEntry.SetRange("Variant Code", QltyInspectionTestHeader."Source Variant Code");
        if QltyInspectionTestHeader.IsLotTracked() then
            ReservationEntry.SetRange("Lot No.", QltyInspectionTestHeader."Source Lot No.");
        if QltyInspectionTestHeader.IsSerialTracked() then
            ReservationEntry.SetRange("Serial No.", QltyInspectionTestHeader."Source Serial No.");
        if QltyInspectionTestHeader.IsPackageTracked() then
            ReservationEntry.SetRange("Package No.", QltyInspectionTestHeader."Source Package No.");
        if ReservationEntry.FindFirst() then
            ExpirationDate := ReservationEntry."Expiration Date";

        ReservationEntry.SetRange("Variant Code");
        ReservationEntry.SetRange("Lot No.");
        ReservationEntry.SetRange("Serial No.");
        ReservationEntry.SetRange("Package No.");
        if not ReservationEntry.IsEmpty() then
            ReservationEntry.DeleteAll();
        CreatePurchaseReturnReservationEntries(ReturnOrderPurchaseLine, QltyInspectionTestHeader."Source Serial No.", QltyInspectionTestHeader."Source Lot No.", QltyInspectionTestHeader."Source Package No.", ExpirationDate, QtyToReturn);
    end;

    /// <summary>
    /// Create 
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="TransferLine"></param>
    internal procedure CreateOutboundTransferLineReservationEntries(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        InstructionForReservationEntry: Record "Reservation Entry";
        CreatedActualReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationStatus: Enum "Reservation Status";
        TransferDirection: Enum "Transfer Direction";
        CurrentSignFactor: Integer;
        ExpirationDate: Date;
        ReceiptDate: Date;
        ShipDate: Date;
    begin
        if (QltyInspectionTestHeader."Source Serial No." = '') and (QltyInspectionTestHeader."Source Lot No." = '') and (QltyInspectionTestHeader."Source Package No." = '') then
            exit;

        if TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" = 0 then
            exit;

        TransferLine.TestField("Item No.");
        TransferLine.TestField("Quantity (Base)");

        Item.Get(TransferLine."Item No.");
        Item.TestField("Item Tracking Code");

        if (TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" > 1) and (QltyInspectionTestHeader."Source Serial No." <> '') then
            Error(SerialNumberAlreadyEnteredErr, QltyInspectionTestHeader."Source Serial No.");

        ExpirationDate := TempQuantityToActQltyDispositionBuffer."New Expiration Date";
        if ExpirationDate = 0D then
            ExpirationDate := GetExpirationDate(
                TransferLine."Transfer-from Code",
                TransferLine."Item No.",
                TransferLine."Variant Code",
                QltyInspectionTestHeader."Source Lot No.",
                QltyInspectionTestHeader."Source Serial No.",
                QltyInspectionTestHeader."Source Package No.");
        if ExpirationDate <> 0D then
            CreateReservEntry.SetNewExpirationDate(ExpirationDate);

        InstructionForReservationEntry."Serial No." := QltyInspectionTestHeader."Source Serial No.";
        InstructionForReservationEntry."Lot No." := QltyInspectionTestHeader."Source Lot No.";
        InstructionForReservationEntry."Package No." := QltyInspectionTestHeader."Source Package No.";
        if ExpirationDate <> 0D then
            InstructionForReservationEntry."Expiration Date" := ExpirationDate;

        TransferDirection := TransferDirection::Outbound;
        ReservationStatus := ReservationStatus::Surplus;

        BindSubscription(this);
        SetItemTrackingFlag(InstructionForReservationEntry);
        if ExpirationDate <> 0D then
            CreateReservEntry.SetDates(0D, ExpirationDate);

        CreateReservEntry.CreateReservEntryFor(Database::"Transfer Line", TransferDirection.AsInteger(), TransferLine."Document No.", '', 0, TransferLine."Line No.", TransferLine."Qty. per Unit of Measure", TransferLine."Quantity" / TransferLine."Qty. per Unit of Measure", TransferLine."Quantity (Base)", InstructionForReservationEntry);

        InstructionForReservationEntry."Source Type" := Database::"Transfer Line";
        InstructionForReservationEntry."Source Subtype" := TransferDirection.AsInteger();
        CurrentSignFactor := CreateReservEntry.SignFactor(InstructionForReservationEntry);
        if CurrentSignFactor < 0 then begin
            ReceiptDate := 0D;
            ShipDate := WorkDate();
        end else begin
            ReceiptDate := WorkDate();
            ShipDate := 0D;
        end;

        CreateReservEntry.CreateEntry(TransferLine."Item No.", TransferLine."Variant Code", TransferLine."Transfer-from Code", TransferLine.Description, ReceiptDate, ShipDate, 0, ReservationStatus);

        UnbindSubscription(this);
        CreateReservEntry.GetLastEntry(CreatedActualReservationEntry);

        CopyReservationEntryInstructions(InstructionForReservationEntry, CreatedActualReservationEntry);
    end;

    /// <summary>
    /// Adds/Removes Purchase Return Line item tracking entries.  When used with serial numbers only one serial number can be created at a time.
    /// </summary>
    /// <param name="PurchPurchaseLine"></param>
    /// <param name="SerialNo"></param>
    /// <param name="LotNo"></param>
    /// <param name="PackageNo"></param>
    /// <param name="ExpirationDate"></param>
    /// <param name="ChangeQty"></param>
    procedure CreatePurchaseReturnReservationEntries(PurchPurchaseLine: Record "Purchase Line"; SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50]; ExpirationDate: Date; ChangeQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ReservForReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationStatus: Enum "Reservation Status";
        ExistingQuantity: Decimal;
        Handled: Boolean;
    begin
        OnBeforeCreatePurchaseReturnReservationEntries(PurchPurchaseLine, SerialNo, LotNo, PackageNo, ExpirationDate, ChangeQty, Handled);
        if Handled then
            exit;

        if ChangeQty = 0 then
            exit;

        PurchPurchaseLine.TestField(Type, PurchPurchaseLine.Type::Item);
        PurchPurchaseLine.TestField("No.");
        if PurchPurchaseLine."Prod. Order No." <> '' then
            Error(PurchaseLineLinkedProdOrderErr, PurchPurchaseLine."Prod. Order No.", PurchPurchaseLine."Document No.", PurchPurchaseLine."No.");

        PurchPurchaseLine.TestField("Quantity (Base)");

        Item.Get(PurchPurchaseLine."No.");
        Item.TestField("Item Tracking Code");

        ChangeQty := ChangeQty * PurchPurchaseLine."Qty. per Unit of Measure";

        ExistingQuantity := 0;
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange("Serial No.", SerialNo);
        ReservationEntry.SetRange("Package No.", PackageNo);
        ReservationEntry.SetRange("Location Code", PurchPurchaseLine."Location Code");
        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source ID", PurchPurchaseLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", PurchPurchaseLine."Line No.");
        ReservationEntry.SetRange(Positive, false);
        if ReservationEntry.FindSet() then begin
            repeat
                ExistingQuantity := ExistingQuantity + Abs(ReservationEntry."Qty. to Handle (Base)");
            until ReservationEntry.Next() = 0;

            ReservationEntry.DeleteAll();
        end else
            if ChangeQty < 0 then
                Error(NegativeTrackingErr, PurchPurchaseLine."No.", PurchPurchaseLine."Document No.");

        if ExistingQuantity <> 0 then
            if ChangeQty < 0 then
                ChangeQty := ExistingQuantity - Abs(ChangeQty)
            else
                ChangeQty := ChangeQty + ExistingQuantity;

        if ChangeQty = 0 then
            exit;

        if (ChangeQty > 1) and (SerialNo <> '') then
            Error(SerialNumberAlreadyEnteredErr, SerialNo);

        ReservForReservationEntry."Serial No." := SerialNo;
        ReservForReservationEntry."Lot No." := LotNo;

        CreateReservEntry.CreateReservEntryFor(Database::"Purchase Line", 5, PurchPurchaseLine."Document No.", '', 0, PurchPurchaseLine."Line No.", PurchPurchaseLine."Qty. per Unit of Measure", ChangeQty / PurchPurchaseLine."Qty. per Unit of Measure", ChangeQty, ReservForReservationEntry);

        if ExpirationDate <> 0D then
            CreateReservEntry.SetDates(0D, ExpirationDate);

        CreateReservEntry.CreateEntry(PurchPurchaseLine."No.", PurchPurchaseLine."Variant Code", PurchPurchaseLine."Location Code", PurchPurchaseLine.Description, Today, 0D, 0, ReservationStatus::Surplus);

        if PackageNo <> '' then begin
            ReservationEntry.Reset();
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
            ReservationEntry.SetRange("Lot No.", LotNo);
            ReservationEntry.SetRange("Serial No.", SerialNo);
            ReservationEntry.SetFilter("Package No.", '%1', '');
            ReservationEntry.SetRange("Location Code", PurchPurchaseLine."Location Code");
            ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
            ReservationEntry.SetRange("Source ID", PurchPurchaseLine."Document No.");
            ReservationEntry.SetRange("Source Ref. No.", PurchPurchaseLine."Line No.");
            ReservationEntry.SetRange(Positive, false);
            if ReservationEntry.FindLast() then begin
                ReservationEntry."Package No." := PackageNo;
                ReservationEntry.Modify();
            end;
        end;
    end;

    /// <summary>
    /// Creates a new warehouse journal line reservation entry
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="WarehouseJournalLine"></param>
    /// <param name="WhseItemTrackingLine"></param>
    procedure CreateWarehouseJournalLineReservationEntry(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        ExpirationDate: Date;
        Handled: Boolean;
        NextEntryNo: Integer;
    begin
        Clear(WhseItemTrackingLine);
        OnBeforeCreateWarehouseJournalLineReservationEntry(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalLine, Handled);
        if Handled then
            exit;

        ExpirationDate := 0D;
        if (QltyInspectionTestHeader."Source Lot No." <> '') or (QltyInspectionTestHeader."Source Serial No." <> '') or (QltyInspectionTestHeader."Source Package No." <> '') then
            ExpirationDate := GetExpirationDate(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

        if (QltyInspectionTestHeader."Source Serial No." = '') and (QltyInspectionTestHeader."Source Lot No." = '') and (QltyInspectionTestHeader."Source Package No." = '') then
            exit;

        if TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" = 0 then
            exit;

        if not GetIsWarehouseTracked(WarehouseJournalLine."Item No.") then
            exit;

        if (TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" > 1) and (QltyInspectionTestHeader."Source Serial No." <> '') then
            Error(SerialNumberAlreadyEnteredErr, QltyInspectionTestHeader."Source Serial No.");

        WhseItemTrackingLine.Reset();
        NextEntryNo := 1 + WhseItemTrackingLine.GetLastEntryNo();
        WhseItemTrackingLine.Init();
        WhseItemTrackingLine."Entry No." := NextEntryNo;
        WhseItemTrackingLine.Validate("Location Code", WarehouseJournalLine."Location Code");
        WhseItemTrackingLine.Validate("Source Type", Database::"Warehouse Journal Line");
        WhseItemTrackingLine.Validate("Source ID", WarehouseJournalLine."Journal Batch Name");
        WhseItemTrackingLine.Validate("Source Batch Name", WarehouseJournalLine."Journal Template Name");
        WhseItemTrackingLine.Validate("Source Ref. No.", WarehouseJournalLine."Line No.");
        WhseItemTrackingLine.Validate("Item No.", WarehouseJournalLine."Item No.");
        WhseItemTrackingLine.Validate("Variant Code", WarehouseJournalLine."Variant Code");
        WhseItemTrackingLine.Validate("Lot No.", QltyInspectionTestHeader."Source Lot No.");
        WhseItemTrackingLine.Validate("Serial No.", QltyInspectionTestHeader."Source Serial No.");

        WhseItemTrackingLine.Validate("Package No.", QltyInspectionTestHeader."Source Package No.");
        if ExpirationDate <> 0D then
            WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);

        WhseItemTrackingLine.Validate("Quantity (Base)", Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)"));
        WhseItemTrackingLine.Validate("Qty. to Handle (Base)", Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)"));
        WhseItemTrackingLine."Buffer Status2" := 0;

        if TempQuantityToActQltyDispositionBuffer."New Lot No." <> '' then
            WhseItemTrackingLine.Validate("New Lot No.", TempQuantityToActQltyDispositionBuffer."New Lot No.");
        if TempQuantityToActQltyDispositionBuffer."New Serial No." <> '' then
            WhseItemTrackingLine.Validate("New Serial No.", TempQuantityToActQltyDispositionBuffer."New Serial No.");
        if TempQuantityToActQltyDispositionBuffer."New Package No." <> '' then
            WhseItemTrackingLine.Validate("New Package No.", TempQuantityToActQltyDispositionBuffer."New Package No.");
        if TempQuantityToActQltyDispositionBuffer."New Expiration Date" <> 0D then
            WhseItemTrackingLine.Validate("New Expiration Date", TempQuantityToActQltyDispositionBuffer."New Expiration Date");
        WhseItemTrackingLine.Insert(true);

        OnAfterCreateWarehouseJournalLineReservationEntry(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalLine, WhseItemTrackingLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseReturnReservationEntries(var PurchPurchaseLine: Record "Purchase Line"; var SerialNo: Code[50]; var LotNo: Code[50]; var PackageNo: Code[50]; var ExpirationDate: Date; var ChangeQty: Decimal; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before a warehouse journal line reservation entry has been made as a result of a dispositoin.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="WhseJnlWarehouseJournalLine"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWarehouseJournalLineReservationEntry(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WhseJnlWarehouseJournalLine: Record "Warehouse Journal Line"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before the item journal line reservation entry has been made.
    /// Use this as an opportunity to replace the base behavior.
    /// </summary>
    /// <param name="ItemJournalLine"></param>
    /// <param name="CreatedActualReservationEntry"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemJournalLineReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var CreatedActualReservationEntry: Record "Reservation Entry"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after the item journal line reservation entry has been made.
    /// Use this as an opportunity to extend the base behavior.
    /// </summary>
    /// <param name="ItemJournalLine"></param>
    /// <param name="ReservationEntry"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJournalLineReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    /// <summary>
    /// Occurs after the creation of a warehouse journal line reservation entry.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempQuantityToActQltyDispositionBuffer"></param>
    /// <param name="WhseJnlWarehouseJournalLine"></param>
    /// <param name="WhseItemTrackingLine"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWarehouseJournalLineReservationEntry(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WhseJnlWarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;
}
