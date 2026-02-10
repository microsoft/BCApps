// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement.TestLibraries;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;

codeunit 139941 "Qlty. Pur. Order Generator"
{
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";

    /// <summary>
    /// Creates a Purchase Order and one purchase line for the provided item. Adds item tracking for the purchase line if necessary.
    /// </summary>
    /// <param name="Qty">quantity of item on purchase line</param>
    /// <param name="Location">location for purchase</param>
    /// <param name="Item">item to be purchased</param>
    /// <param name="Vendor">vendor for purchase</param>
    /// <param name="OutOrderPurchaseHeader">the created purchase order</param>
    /// <param name="OutPurchaseLine">the created purchase line</param>
    /// <param name="OutOptionalReservationEntry">the last reservation entry created for the line if the item is tracked</param>
    internal procedure CreatePurchaseOrder(Qty: Decimal; Location: Record Location; Item: Record Item; Vendor: Record Vendor; OptionalVariant: Code[10]; var OutOrderPurchaseHeader: Record "Purchase Header"; var OutPurchaseLine: Record "Purchase Line"; var OutOptionalReservationEntry: Record "Reservation Entry")
    begin
        LibraryPurchase.CreatePurchaseOrderWithLocation(OutOrderPurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(OutPurchaseLine, OutOrderPurchaseHeader, OutPurchaseLine.Type::Item, Item."No.", Qty);
        OutPurchaseLine."Location Code" := Location.Code;
        if OptionalVariant <> '' then
            OutPurchaseLine.Validate("Variant Code", OptionalVariant);
        OutPurchaseLine."Buy-from Vendor No." := OutOrderPurchaseHeader."Buy-from Vendor No.";
        OutPurchaseLine.Modify(true);
        if Item."Item Tracking Code" <> '' then
            AddTrackingForPurchaseLine(OutPurchaseLine, Item, OutOptionalReservationEntry);
    end;
    /// <summary>
    /// Creates a Purchase Order and one purchase line for the provided item. Adds item tracking for the purchase line if necessary.
    /// </summary>
    /// <param name="Qty">quantity of item on purchase line</param>
    /// <param name="Location">location for purchase</param>
    /// <param name="Item">item to be purchased</param>
    /// <param name="OutOrderPurchaseHeader">the created purchase order</param>
    /// <param name="OutPurchaseLine">the created purchase line</param>
    internal procedure CreatePurchaseOrder(Qty: Decimal; Location: Record Location; Item: Record Item; var OutOrderPurchaseHeader: Record "Purchase Header"; var OutPurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(Qty, Location, Item, Vendor, '', OutOrderPurchaseHeader, OutPurchaseLine, ReservationEntry);
    end;

    /// <summary>
    /// Creates a Purchase Order and one purchase line for the provided item. Adds item tracking for the purchase line if necessary.
    /// </summary>
    /// <param name="Qty">quantity of item on purchase line</param>
    /// <param name="Location">location for purchase</param>
    /// <param name="Item">item to be purchased</param>
    /// <param name="OutOrderPurchaseHeader">the created purchase order</param>
    /// <param name="OutPurchaseLine">the created purchase line</param>
    /// <param name="OutReservationEntry">the last reservation entry created for the line if the item is tracked</param>
    internal procedure CreatePurchaseOrder(Qty: Decimal; Location: Record Location; Item: Record Item; var OutOrderPurchaseHeader: Record "Purchase Header"; var OutPurchaseLine: Record "Purchase Line"; var OutReservationEntry: Record "Reservation Entry")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(Qty, Location, Item, Vendor, '', OutOrderPurchaseHeader, OutPurchaseLine, OutReservationEntry);
    end;

    /// <summary>
    /// Creates reservation entries for a tracked item on the purchase line.
    /// </summary>
    /// <param name="PurchaseLine">purchase line</param>
    /// <param name="Item">tracked item</param>
    /// <param name="OutReservationEntry">last created reservation entry</param>
    internal procedure AddTrackingForPurchaseLine(PurchaseLine: Record "Purchase Line"; Item: Record Item; var OutReservationEntry: Record "Reservation Entry")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        InventorySetup: Record "Inventory Setup";
        NoSeries: Codeunit "No. Series";
        LotNo: Code[20];
        SerialNo: Code[20];
        PackageNo: Code[20];
        Counter: Integer;
    begin
        Item.TestField("Item Tracking Code");
        ItemTrackingCode.Get(Item."Item Tracking Code");
        if ItemTrackingCode."Package Specific Tracking" then
            if InventorySetup.Get() then
                PackageNo := NoSeries.GetNextNo(InventorySetup."Package Nos.");
        if Item."Lot Nos." <> '' then
            LotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        if Item."Serial Nos." <> '' then begin
            Counter := 0;
            while Counter < PurchaseLine."Quantity (Base)" do begin
                SerialNo := NoSeries.GetNextNo(Item."Serial Nos.");
                LibraryItemTracking.CreatePurchOrderItemTracking(OutReservationEntry, PurchaseLine, SerialNo, LotNo, PackageNo, 1);
                Counter += 1;
            end;
        end else
            LibraryItemTracking.CreatePurchOrderItemTracking(OutReservationEntry, PurchaseLine, SerialNo, LotNo, PackageNo, PurchaseLine."Quantity (Base)");
    end;

    /// <summary>
    /// Receives the created purchase order with a single purchase line.
    /// </summary>
    /// <param name="Location">location of purchase order</param>
    /// <param name="OrderPurchaseHeader">purchase order to be received</param>
    /// <param name="PurchaseLine">purchase line to be received</param>
    internal procedure ReceivePurchaseOrder(Location: Record Location; var OrderPurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        ReceivePurchaseLine(PurchaseLine, PurchaseLine."Outstanding Quantity");
    end;

    internal procedure ReceivePurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    var
        WhseWarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhseWarehouseReceiptLine: Record "Warehouse Receipt Line";
        PutAwayWarehouseActivityLine: Record "Warehouse Activity Line";
        PutAwayWarehouseActivityHeader: Record "Warehouse Activity Header";
        Location: Record Location;
        OrderPurchaseHeader: Record "Purchase Header";
    begin
        Location.Get(PurchaseLine."Location Code");
        OrderPurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        if OrderPurchaseHeader.Status = OrderPurchaseHeader.Status::Released then
            LibraryPurchase.ReopenPurchaseDocument(OrderPurchaseHeader);

        if not Location."Require Receive" then
            PurchaseLine.Validate("Qty. to Receive", QtyToReceive);

        if OrderPurchaseHeader.Status = OrderPurchaseHeader.Status::Open then
            LibraryPurchase.ReleasePurchaseDocument(OrderPurchaseHeader);

        if Location.RequireReceive(Location.Code) then begin
            LibraryWarehouse.CreateWhseReceiptFromPO(OrderPurchaseHeader);
            WhseWarehouseReceiptLine.SetRange("Source Document", WhseWarehouseReceiptLine."Source Document"::"Purchase Order");
            WhseWarehouseReceiptLine.SetRange("Item No.", PurchaseLine."No.");
            WhseWarehouseReceiptLine.SetRange("Source No.", OrderPurchaseHeader."No.");
            WhseWarehouseReceiptLine.FindFirst();
            WhseWarehouseReceiptHeader.Get(WhseWarehouseReceiptLine."No.");
            if QtyToReceive = 0 then
                LibraryWarehouse.AutofillQtyToRecvWhseReceipt(WhseWarehouseReceiptHeader)
            else
                WhseWarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
            WhseWarehouseReceiptLine.Modify();
            LibraryWarehouse.PostWhseReceipt(WhseWarehouseReceiptHeader);
        end;
        if Location.RequireReceive(Location.Code) and Location.RequirePutaway(Location.Code) then begin
            PutAwayWarehouseActivityLine.SetRange("Activity Type", PutAwayWarehouseActivityLine."Activity Type"::"Put-away");
            PutAwayWarehouseActivityLine.SetRange("Item No.", PurchaseLine."No.");
            PutAwayWarehouseActivityLine.SetRange("Source No.", OrderPurchaseHeader."No.");
            PutAwayWarehouseActivityLine.FindFirst();
            PutAwayWarehouseActivityHeader.Get(PutAwayWarehouseActivityHeader.Type::"Put-away", PutAwayWarehouseActivityLine."No.");
            LibraryWarehouse.AutoFillQtyHandleWhseActivity(PutAwayWarehouseActivityHeader);
            LibraryWarehouse.RegisterWhseActivity(PutAwayWarehouseActivityHeader);
        end;
        if not Location.RequireReceive(Location.Code) and Location.RequirePutaway(Location.Code) then begin
            LibraryWarehouse.CreateInvtPutPickPurchaseOrder(OrderPurchaseHeader);
            PutAwayWarehouseActivityHeader.SetRange(Type, PutAwayWarehouseActivityHeader.Type::"Invt. Put-away");
            PutAwayWarehouseActivityHeader.SetRange("Source Document", PutAwayWarehouseActivityHeader."Source Document"::"Purchase Order");
            PutAwayWarehouseActivityHeader.SetRange("Source No.", OrderPurchaseHeader."No.");
            PutAwayWarehouseActivityHeader.FindFirst();
            LibraryWarehouse.AutoFillQtyInventoryActivity(PutAwayWarehouseActivityHeader);
            LibraryWarehouse.PostInventoryActivity(PutAwayWarehouseActivityHeader, false);
        end;
        if (not Location.RequireReceive(Location.Code)) and (not Location.RequirePutaway(Location.Code)) then
            LibraryPurchase.PostPurchaseDocument(OrderPurchaseHeader, true, false)
    end;

    /// <summary>
    /// Creates an item without tracking, creates a purchase order for that item, then creates an inspection
    /// </summary>
    /// <param name="Location"></param>
    ///<param name="PurchaseQuantity"></param>
    /// <param name="PurchaseHeader"></param>
    /// <param name="PurchaseLine"></param>
    /// <param name="OutQltyInspectionHeader"></param>
    internal procedure CreateInspectionFromPurchaseWithUntrackedItem(var Location: Record Location; PurchaseQuantity: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var OutQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        UnitCost: Decimal;
    begin
        UnitCost := LibraryRandom.RandDecInRange(1, 10, 2);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify();

        CreatePurchaseOrder(PurchaseQuantity, Location, Item, PurchaseHeader, PurchaseLine);
        RecordRef.GetTable(PurchaseLine);
        if QltyInspectionCreate.CreateInspection(RecordRef, false) then
            QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
    end;

    /// <summary>
    /// Creates an item with lot tracking, creates a purchase order for that item, then creates an inspection
    /// </summary>
    /// <param name="Location"></param>
    /// <param name="PurchaseQuantity"></param>
    /// <param name="PurchaseHeader"></param>
    /// <param name="PurchaseLine"></param>
    /// <param name="OutQltyInspectionHeader"></param>
    /// <param name="OutReservationEntry"></param>
    internal procedure CreateInspectionFromPurchaseWithLotTrackedItem(var Location: Record Location; PurchaseQuantity: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"; var OutReservationEntry: Record "Reservation Entry")
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SpecTrackingSpecification: Record "Tracking Specification";
        LibraryRandom: Codeunit "Library - Random";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        LocalizedLibraryPurchase: Codeunit "Library - Purchase";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnitCost: Decimal;
    begin
        QltyInspectionUtility.CreateLotTrackedItem(Item);
        UnitCost := LibraryRandom.RandDecInRange(1, 10, 2);
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify();

        LocalizedLibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseQuantity, Location, Item, Vendor, '', PurchaseHeader, PurchaseLine, OutReservationEntry);
        RecordRef.GetTable(PurchaseLine);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(OutReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '') then
            QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
    end;
}
