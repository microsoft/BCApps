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
using Microsoft.QualityManagement.Setup;
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
    /// Creates a reservation entry from the item-tracking values on an item journal line.
    /// Set the tracking on the line (no modify needed) to give the tracking instruction.
    /// </summary>
    /// <param name="ItemJournalLine">The item journal line supplying source, quantity, dates, and tracking values.</param>
    /// <param name="CreatedActualReservationEntry">The created reservation entry.</param>
    internal procedure CreateItemJournalLineReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var CreatedActualReservationEntry: Record "Reservation Entry")
    var
        InstructionForReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        EntryType: Integer;
        ExpirationDate: Date;
        CurrentSignFactor: Integer;
        ReservationStatus: Enum "Reservation Status";
        ReceiptDate: Date;
        IsHandled: Boolean;
        ShipDate: Date;
    begin
        OnBeforeCreateItemJournalLineReservationEntry(ItemJournalLine, CreatedActualReservationEntry, IsHandled);
        if IsHandled then
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

        InstructionForReservationEntry."Lot No." := ItemJournalLine."Lot No.";
        if ItemJournalLine."New Lot No." <> '' then
            InstructionForReservationEntry."New Lot No." := ItemJournalLine."New Lot No.";

        InstructionForReservationEntry."Serial No." := ItemJournalLine."Serial No.";
        if ItemJournalLine."New Serial No." <> '' then
            InstructionForReservationEntry."New Serial No." := ItemJournalLine."New Serial No.";

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

        CopyReservationEntryItemTracking(InstructionForReservationEntry, CreatedActualReservationEntry);

        OnAfterCreateItemJournalLineReservationEntry(ItemJournalLine, CreatedActualReservationEntry);
    end;

    /// <summary>
    /// Copies expiration and new item-tracking values to a created reservation entry.
    /// </summary>
    /// <param name="InstructionForReservationEntry">The reservation instruction supplying tracking values.</param>
    /// <param name="CreatedActualReservationEntry">The reservation entry to update.</param>
    local procedure CopyReservationEntryItemTracking(var InstructionForReservationEntry: Record "Reservation Entry"; var CreatedActualReservationEntry: Record "Reservation Entry")
    begin
        if (InstructionForReservationEntry."Expiration Date" <> 0D) and (CreatedActualReservationEntry."Expiration Date" = 0D) then
            CreatedActualReservationEntry."Expiration Date" := InstructionForReservationEntry."Expiration Date";

        if InstructionForReservationEntry."New Lot No." <> '' then
            CreatedActualReservationEntry."New Lot No." := InstructionForReservationEntry."New Lot No.";

        if InstructionForReservationEntry."New Serial No." <> '' then
            CreatedActualReservationEntry."New Serial No." := InstructionForReservationEntry."New Serial No.";

        if InstructionForReservationEntry."New Package No." <> '' then
            CreatedActualReservationEntry."New Package No." := InstructionForReservationEntry."New Package No.";

        if InstructionForReservationEntry."New Expiration Date" <> 0D then
            CreatedActualReservationEntry."New Expiration Date" := InstructionForReservationEntry."New Expiration Date";
        CreatedActualReservationEntry.Modify();
    end;

    /// <summary>
    /// Sets the "Item Tracking" flag on the reservation entry based on the state of the item tracking on the item journal line.
    /// </summary>
    /// <param name="ReservationEntry">The reservation entry whose item-tracking flag is set.</param>
    local procedure SetItemTrackingFlag(var ReservationEntry: Record "Reservation Entry")
    var
        ItemTrackingEntryType: Enum "Item Tracking Entry Type";
    begin
        ItemTrackingEntryType := ReservationEntry.GetItemTrackingEntryType();
        ReservationEntry."Item Tracking" := ItemTrackingEntryType;
    end;

    /// <summary>
    /// Restricts item journal template selection to the template containing the configured quality management batch.
    /// </summary>
    /// <param name="ItemJnlTemplate">The item journal templates whose filters can be narrowed.</param>
    /// <param name="PageTemplate">The page template option supplied by item journal management.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ItemJnlManagement, 'OnTemplateSelectionSetFilter', '', true, true)]
    local procedure HandleOnTemplateSelectionSetFilter(var ItemJnlTemplate: Record "Item Journal Template"; var PageTemplate: Option)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        SearchItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if ItemJnlTemplate.GetFilter("Page ID") = '' then
            exit;

        if ItemJnlTemplate.Count() <= 1 then
            exit;

        case ItemJnlTemplate.GetRangeMin("Page ID") of
            Page::"Item Reclass. Journal":
                if QltyManagementSetup."Item Reclass. Batch Name" <> '' then begin
                    SearchItemJournalTemplate.CopyFilters(ItemJnlTemplate);
                    SearchItemJournalTemplate.SetLoadFields(Name, Type);
                    if SearchItemJournalTemplate.FindSet() then
                        repeat
                            ItemJournalBatch.SetRange("Journal Template Name", SearchItemJournalTemplate.Name);
                            ItemJournalBatch.SetRange("Template Type", SearchItemJournalTemplate.Type);
                            ItemJournalBatch.SetRange(Name, QltyManagementSetup."Item Reclass. Batch Name");
                            if ItemJournalBatch.Count() = 1 then begin
                                ItemJnlTemplate.SetRange(Name, SearchItemJournalTemplate.Name);
                                exit;
                            end;
                        until SearchItemJournalTemplate.Next() = 0;
                    SearchItemJournalTemplate.SetView(ItemJnlTemplate.GetView());
                end;
            Page::"Item Journal":
                if QltyManagementSetup."Item Journal Batch Name" <> '' then begin
                    SearchItemJournalTemplate.CopyFilters(ItemJnlTemplate);
                    SearchItemJournalTemplate.SetLoadFields(Name, Type);
                    if SearchItemJournalTemplate.FindSet() then
                        repeat
                            ItemJournalBatch.SetRange("Journal Template Name", SearchItemJournalTemplate.Name);
                            ItemJournalBatch.SetRange("Template Type", SearchItemJournalTemplate.Type);
                            ItemJournalBatch.SetRange(Name, QltyManagementSetup."Item Journal Batch Name");
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
    /// Restricts warehouse journal template selection to the template containing the configured quality management batch.
    /// </summary>
    /// <param name="WarehouseJournalLine">The warehouse journal line supplied by template selection.</param>
    /// <param name="WhseJnlTemplate">The warehouse journal templates whose filters can be narrowed.</param>
    /// <param name="OpenFromBatch">Indicates whether template selection was opened from a batch.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Management Setup", 'R', InherentPermissionsScope::Permissions)]
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnTemplateSelectionOnAfterSetFilters', '', true, true)]
    local procedure HandleOnTemplateSelectionOnAfterSetFilters(var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseJnlTemplate: Record "Warehouse Journal Template"; OpenFromBatch: Boolean)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        SearchWarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if WhseJnlTemplate.GetFilter("Page ID") = '' then
            exit;

        if WhseJnlTemplate.Count() <= 1 then
            exit;

        case WhseJnlTemplate.GetRangeMin("Page ID") of
            Page::"Whse. Reclassification Journal":
                if QltyManagementSetup."Whse. Reclass. Batch Name" <> '' then begin
                    SearchWarehouseJournalTemplate.CopyFilters(WhseJnlTemplate);
                    SearchWarehouseJournalTemplate.SetLoadFields(Name, Type);
                    if SearchWarehouseJournalTemplate.FindSet() then
                        repeat
                            WarehouseJournalBatch.SetRange("Journal Template Name", SearchWarehouseJournalTemplate.Name);
                            WarehouseJournalBatch.SetRange("Template Type", SearchWarehouseJournalTemplate.Type);
                            WarehouseJournalBatch.SetRange(Name, QltyManagementSetup."Whse. Reclass. Batch Name");
                            if WarehouseJournalBatch.Count() = 1 then begin
                                WhseJnlTemplate.SetRange(Name, SearchWarehouseJournalTemplate.Name);
                                exit;
                            end;
                        until SearchWarehouseJournalTemplate.Next() = 0;
                    SearchWarehouseJournalTemplate.SetView(WhseJnlTemplate.GetView());
                end;
            Page::"Whse. Item Journal":
                if QltyManagementSetup."Whse. Item Journal Batch Name" <> '' then begin
                    SearchWarehouseJournalTemplate.CopyFilters(WhseJnlTemplate);
                    SearchWarehouseJournalTemplate.SetLoadFields(Name, Type);
                    if SearchWarehouseJournalTemplate.FindSet() then
                        repeat
                            WarehouseJournalBatch.SetRange("Journal Template Name", SearchWarehouseJournalTemplate.Name);
                            WarehouseJournalBatch.SetRange("Template Type", SearchWarehouseJournalTemplate.Type);
                            WarehouseJournalBatch.SetRange(Name, QltyManagementSetup."Whse. Item Journal Batch Name");
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
    /// Gets the warehouse expiration date for the item-tracking values on an inspection at a location.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection supplying item, variant, and tracking values.</param>
    /// <param name="LocationCode">The location at which to resolve the expiration date.</param>
    /// <returns>The warehouse expiration date, or zero date when none is available.</returns>
    internal procedure GetExpirationDate(QltyInspectionHeader: Record "Qlty. Inspection Header"; LocationCode: Code[10]) ExpirationDate: Date
    begin
        exit(GetExpirationDate(
                LocationCode,
                QltyInspectionHeader."Source Item No.",
                QltyInspectionHeader."Source Variant Code",
                QltyInspectionHeader."Source Lot No.",
                QltyInspectionHeader."Source Serial No.",
                QltyInspectionHeader."Source Package No."));
    end;

    /// <summary>
    /// Gets the warehouse expiration date for specified item, location, and item-tracking values.
    /// </summary>
    /// <param name="LocationCode">The location at which to resolve the expiration date.</param>
    /// <param name="ItemNo">The item number.</param>
    /// <param name="VariantCode">The item variant code.</param>
    /// <param name="LotNo">The lot number.</param>
    /// <param name="SerialNo">The serial number.</param>
    /// <param name="PackageNo">The package number.</param>
    /// <returns>The warehouse expiration date, or zero date when none is available.</returns>
    local procedure GetExpirationDate(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50]) ExpirationDate: Date
    var
        Location: Record Location;
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if LocationCode <> '' then
            Location.Get(LocationCode);

        TempItemTrackingSetup."Lot No." := LotNo;
        TempItemTrackingSetup."Serial No." := SerialNo;
        TempItemTrackingSetup."Package No." := PackageNo;

        ItemTrackingManagement.GetWhseExpirationDate(ItemNo, VariantCode, Location, TempItemTrackingSetup, ExpirationDate);
    end;

    /// <summary>
    /// Determines whether an item uses lot, serial, or package warehouse tracking.
    /// </summary>
    /// <param name="ItemNo">The item number to inspect.</param>
    /// <returns>True if any warehouse tracking type is enabled; otherwise, false.</returns>
    internal procedure GetIsWarehouseTracked(ItemNo: Code[20]): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if GetItemTrackingCode(ItemNo, ItemTrackingCode) then
            exit(ItemTrackingCode."Lot Warehouse Tracking" or ItemTrackingCode."SN Warehouse Tracking" or ItemTrackingCode."Package Warehouse Tracking");

        exit(false);
    end;

    /// <summary>
    /// Gets the item tracking code assigned to an item.
    /// </summary>
    /// <param name="ItemNo">The item number whose tracking code is requested.</param>
    /// <param name="ItemTrackingCode">The assigned item tracking code record.</param>
    /// <returns>True if the item has an existing item tracking code; otherwise, false.</returns>
    internal procedure GetItemTrackingCode(ItemNo: Code[20]; var ItemTrackingCode: Record "Item Tracking Code"): Boolean
    var
        Item: Record Item;
    begin
        if ItemNo = '' then
            exit(false);

        if not Item.Get(ItemNo) then
            exit(false);

        if Item."Item Tracking Code" = '' then
            exit(false);

        exit(ItemTrackingCode.Get(Item."Item Tracking Code"));
    end;

    /// <summary>
    /// Replaces all reservation entries for a purchase return line with one entry using the inspection tracking values and requested quantity.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection supplying item and item-tracking values.</param>
    /// <param name="ReturnOrderPurchaseLine">The purchase return line whose reservation entries are replaced.</param>
    /// <param name="QtyToReturn">The quantity for the replacement reservation entry.</param>
    internal procedure DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader: Record "Qlty. Inspection Header"; ReturnOrderPurchaseLine: Record "Purchase Line"; QtyToReturn: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        ExpirationDate: Date;
    begin
        TempItemTrackingSetup."Lot No. Required" := true;
        TempItemTrackingSetup."Serial No. Required" := true;
        TempItemTrackingSetup."Package No. Required" := true;
        QltyInspectionHeader.IsItemTrackingUsed(TempItemTrackingSetup);

        ReservationEntry.SetRange("Location Code", ReturnOrderPurchaseLine."Location Code");
        ReservationEntry.SetRange("Item No.", QltyInspectionHeader."Source Item No.");
        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source ID", ReturnOrderPurchaseLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", ReturnOrderPurchaseLine."Line No.");
        ReservationEntry.SetRange(Positive, false);
        if QltyInspectionHeader."Source Variant Code" <> '' then
            ReservationEntry.SetRange("Variant Code", QltyInspectionHeader."Source Variant Code");
        if TempItemTrackingSetup."Lot No. Required" then
            ReservationEntry.SetRange("Lot No.", QltyInspectionHeader."Source Lot No.");
        if TempItemTrackingSetup."Serial No. Required" then
            ReservationEntry.SetRange("Serial No.", QltyInspectionHeader."Source Serial No.");
        if TempItemTrackingSetup."Package No. Required" then
            ReservationEntry.SetRange("Package No.", QltyInspectionHeader."Source Package No.");
        if ReservationEntry.FindFirst() then
            ExpirationDate := ReservationEntry."Expiration Date";

        ReservationEntry.SetRange("Variant Code");
        ReservationEntry.SetRange("Lot No.");
        ReservationEntry.SetRange("Serial No.");
        ReservationEntry.SetRange("Package No.");
        if not ReservationEntry.IsEmpty() then
            ReservationEntry.DeleteAll();
        CreatePurchaseReturnReservationEntries(ReturnOrderPurchaseLine, QltyInspectionHeader."Source Serial No.", QltyInspectionHeader."Source Lot No.", QltyInspectionHeader."Source Package No.", ExpirationDate, QtyToReturn);
    end;

    /// <summary>
    /// Creates an outbound surplus reservation entry for a transfer line from inspection tracking values.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection supplying item-tracking values.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The disposition instruction supplying quantity and expiration date.</param>
    /// <param name="TransferLine">The outbound transfer line for which tracking is created.</param>
    internal procedure CreateOutboundTransferLineReservationEntries(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferLine: Record "Transfer Line")
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
        if (QltyInspectionHeader."Source Serial No." = '') and (QltyInspectionHeader."Source Lot No." = '') and (QltyInspectionHeader."Source Package No." = '') then
            exit;

        if TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" = 0 then
            exit;

        TransferLine.TestField("Item No.");
        TransferLine.TestField("Quantity (Base)");

        Item.Get(TransferLine."Item No.");
        Item.TestField("Item Tracking Code");

        if (TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" > 1) and (QltyInspectionHeader."Source Serial No." <> '') then
            Error(SerialNumberAlreadyEnteredErr, QltyInspectionHeader."Source Serial No.");

        ExpirationDate := TempQuantityToActQltyDispositionBuffer."New Expiration Date";
        if ExpirationDate = 0D then
            ExpirationDate := GetExpirationDate(
                TransferLine."Transfer-from Code",
                TransferLine."Item No.",
                TransferLine."Variant Code",
                QltyInspectionHeader."Source Lot No.",
                QltyInspectionHeader."Source Serial No.",
                QltyInspectionHeader."Source Package No.");
        if ExpirationDate <> 0D then
            CreateReservEntry.SetNewExpirationDate(ExpirationDate);

        InstructionForReservationEntry."Lot No." := QltyInspectionHeader."Source Lot No.";
        InstructionForReservationEntry."Serial No." := QltyInspectionHeader."Source Serial No.";
        InstructionForReservationEntry."Package No." := QltyInspectionHeader."Source Package No.";
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

        CopyReservationEntryItemTracking(InstructionForReservationEntry, CreatedActualReservationEntry);
    end;

    /// <summary>
    /// Adds, reduces, or replaces surplus item-tracking entries for a purchase return line.
    /// </summary>
    /// <param name="PurchPurchaseLine">The purchase return line whose tracking quantity is changed.</param>
    /// <param name="SerialNo">The serial number for the tracking entry.</param>
    /// <param name="LotNo">The lot number for the tracking entry.</param>
    /// <param name="PackageNo">The package number for the tracking entry.</param>
    /// <param name="ExpirationDate">The expiration date for the tracking entry.</param>
    /// <param name="ChangeQty">The quantity change in the line's unit of measure.</param>
    internal procedure CreatePurchaseReturnReservationEntries(PurchPurchaseLine: Record "Purchase Line"; SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50]; ExpirationDate: Date; ChangeQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ReservForReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationStatus: Enum "Reservation Status";
        ExistingQuantity: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCreatePurchaseReturnReservationEntries(PurchPurchaseLine, SerialNo, LotNo, PackageNo, ExpirationDate, ChangeQty, IsHandled);
        if IsHandled then
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

        ReservForReservationEntry."Lot No." := LotNo;
        ReservForReservationEntry."Serial No." := SerialNo;
        ReservForReservationEntry."Package No." := PackageNo;

        CreateReservEntry.CreateReservEntryFor(Database::"Purchase Line", 5, PurchPurchaseLine."Document No.", '', 0, PurchPurchaseLine."Line No.", PurchPurchaseLine."Qty. per Unit of Measure", ChangeQty / PurchPurchaseLine."Qty. per Unit of Measure", ChangeQty, ReservForReservationEntry);

        if ExpirationDate <> 0D then
            CreateReservEntry.SetDates(0D, ExpirationDate);

        CreateReservEntry.CreateEntry(PurchPurchaseLine."No.", PurchPurchaseLine."Variant Code", PurchPurchaseLine."Location Code", PurchPurchaseLine.Description, Today, 0D, 0, ReservationStatus::Surplus);
    end;

    /// <summary>
    /// Creates a warehouse item-tracking line for a disposition warehouse journal line.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection supplying current item-tracking values.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The disposition instruction supplying quantity and new tracking values.</param>
    /// <param name="WarehouseJournalLine">The warehouse journal line to associate with the tracking line.</param>
    /// <param name="WhseItemTrackingLine">The created warehouse item-tracking line.</param>
    internal procedure CreateWarehouseJournalLineReservationEntry(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        ExpirationDate: Date;
        IsHandled: Boolean;
        NextEntryNo: Integer;
    begin
        Clear(WhseItemTrackingLine);
        OnBeforeCreateWarehouseJournalLineReservationEntry(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalLine, IsHandled);
        if IsHandled then
            exit;

        ExpirationDate := 0D;
        if (QltyInspectionHeader."Source Lot No." <> '') or (QltyInspectionHeader."Source Serial No." <> '') or (QltyInspectionHeader."Source Package No." <> '') then
            ExpirationDate := GetExpirationDate(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

        if (QltyInspectionHeader."Source Lot No." = '') and (QltyInspectionHeader."Source Serial No." = '') and (QltyInspectionHeader."Source Package No." = '') then
            exit;

        if TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" = 0 then
            exit;

        if not GetIsWarehouseTracked(WarehouseJournalLine."Item No.") then
            exit;

        if (TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" > 1) and (QltyInspectionHeader."Source Serial No." <> '') then
            Error(SerialNumberAlreadyEnteredErr, QltyInspectionHeader."Source Serial No.");

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
        WhseItemTrackingLine.Validate("Lot No.", QltyInspectionHeader."Source Lot No.");
        WhseItemTrackingLine.Validate("Serial No.", QltyInspectionHeader."Source Serial No.");
        WhseItemTrackingLine.Validate("Package No.", QltyInspectionHeader."Source Package No.");
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

        OnAfterCreateWarehouseJournalLineReservationEntry(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalLine, WhseItemTrackingLine);
    end;

    /// <summary>
    /// Notifies subscribers before purchase return reservation entries are changed and permits replacement of the standard behavior.
    /// </summary>
    /// <param name="PurchPurchaseLine">The purchase return line being updated.</param>
    /// <param name="SerialNo">The serial number for the tracking entry.</param>
    /// <param name="LotNo">The lot number for the tracking entry.</param>
    /// <param name="PackageNo">The package number for the tracking entry.</param>
    /// <param name="ExpirationDate">The expiration date for the tracking entry.</param>
    /// <param name="ChangeQty">The requested quantity change.</param>
    /// <param name="IsHandled">Set to true to skip the standard behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseReturnReservationEntries(var PurchPurchaseLine: Record "Purchase Line"; var SerialNo: Code[50]; var LotNo: Code[50]; var PackageNo: Code[50]; var ExpirationDate: Date; var ChangeQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers before a warehouse item-tracking line is created and permits replacement of the standard behavior.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection supplying item-tracking values.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The disposition instruction being applied.</param>
    /// <param name="WhseJnlWarehouseJournalLine">The warehouse journal line receiving tracking.</param>
    /// <param name="IsHandled">Set to true to skip the standard behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWarehouseJournalLineReservationEntry(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WhseJnlWarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers before an item journal reservation entry is created and permits replacement of the standard behavior.
    /// </summary>
    /// <param name="ItemJournalLine">The item journal line receiving tracking.</param>
    /// <param name="CreatedActualReservationEntry">The reservation entry that subscribers can populate.</param>
    /// <param name="IsHandled">Set to true to skip the standard behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemJournalLineReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var CreatedActualReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Notifies subscribers after an item journal reservation entry is created.
    /// </summary>
    /// <param name="ItemJournalLine">The item journal line associated with the tracking entry.</param>
    /// <param name="ReservationEntry">The created reservation entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJournalLineReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    /// <summary>
    /// Notifies subscribers after a warehouse item-tracking line is created.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection supplying item-tracking values.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The applied disposition instruction.</param>
    /// <param name="WhseJnlWarehouseJournalLine">The warehouse journal line associated with the tracking line.</param>
    /// <param name="WhseItemTrackingLine">The created warehouse item-tracking line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWarehouseJournalLineReservationEntry(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WhseJnlWarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;
}
