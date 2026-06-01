// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 149910 "Subc. WIP Transfer Post Test"
{
    // [FEATURE] Subcontracting Warehouse Combined Scenarios Tests
    Subtype = Test;
    TestType = IntegrationTest;

    [Test]
    procedure CreateTransferOrderWithWIPItemFlag_CreatesSimpleWIPTransferLine()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Create Transfer Order with WIP Item and validate Transfer Line fields
        Initialize();
        // [GIVEN] Valid From and To Locations, In-Transit Location, and WIP Item details
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        LibraryInventory.CreateItem(Item);
        Quantity := 5;

        // [WHEN] Create Transfer Order with WIP Item
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        // [THEN] Assert TransferLine has WIP flag and every base quantity field is 0 as expected for WIP Item
        Assert.AreEqual(TransferLine."Transfer-from Code", FromLocation.Code, 'Transfer Line should have correct From Location');
        Assert.AreEqual(TransferLine."Transfer-to Code", ToLocation.Code, 'Transfer Line should have correct To Location');
        Assert.IsTrue(TransferLine."Transfer WIP Item", 'Transfer Line should have WIP Item flag set');
        Assert.AreEqual(TransferLine.Quantity, Quantity, 'Transfer Line should have correct quantity');
        Assert.AreEqual(TransferLine."Qty. to Ship", Quantity, 'Transfer Line should have correct Qty. to Ship');
        Assert.AreEqual(TransferLine."Qty. to receive", 0, 'Transfer Line should have correct Qty. to receive');
        Assert.AreEqual(TransferLine."Outstanding Quantity", Quantity, 'Transfer Line should have correct Outstanding Quantity');

        Assert.AreEqual(TransferLine."Qty. per Unit of Measure", 0, 'Transfer Line should have 0 in Qty. per Unit of Measure for WIP Item');
        Assert.AreEqual(TransferLine."Quantity (Base)", 0, 'Transfer Line should have 0 in Quantity (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", 0, 'Transfer Line should have 0 in Qty. to Ship (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Transfer Line should have 0 in Qty. to Receive (Base) for WIP Item');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", 0, 'Transfer Line should have 0 in Outstanding Qty. (Base) for WIP Item');
    end;

    [Test]
    procedure ToggleWIPFlag_UpdatesBaseQuantitiesCorrectly()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        QtyPerUOM: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO] Set WIP-Flag, validate base quantities, then unset WIP-Flag and validate quantities again, and repeat to ensure consistent behavior
        Initialize();
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 7;

        // [GIVEN] Transfer order with WIP flag
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        // [WHEN] Remove WIP flag from Transfer Line
        TransferLine.Validate("Transfer WIP Item", false);
        TransferLine.Modify();

        // [THEN] Base quantity fields should be calculated based on Quantity and Qty. per Unit of Measure, and WIP flag should be false
        QtyPerUOM := 1; // Default value if not set
        Assert.IsFalse(TransferLine."Transfer WIP Item", 'Transfer Line should not have WIP Item flag set');
        Assert.AreEqual(TransferLine."Quantity (Base)", Quantity, 'Quantity (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", Quantity, 'Qty. to Ship (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Qty. to Receive (Base) should match Quantity');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", Quantity, 'Outstanding Qty. (Base) should match Quantity');

        // [WHEN] Set WIP flag back on Transfer Line
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Modify();

        // [THEN] Base quantity fields should be reset to 0 and WIP flag should be true again
        Assert.IsTrue(TransferLine."Transfer WIP Item", 'Transfer Line should have WIP Item flag set again');
        Assert.AreEqual(TransferLine."Qty. per Unit of Measure", 0, 'Qty. per Unit of Measure should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Quantity (Base)", 0, 'Quantity (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Qty. to Ship (Base)", 0, 'Qty. to Ship (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Qty. to Receive (Base)", 0, 'Qty. to Receive (Base) should be 0 for WIP again');
        Assert.AreEqual(TransferLine."Outstanding Qty. (Base)", 0, 'Outstanding Qty. (Base) should be 0 for WIP again');
    end;

    [Test]
    procedure PostWIPTransferOrder_ShipPartialReceiveFullReceive()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromReceiveBin, FromPutAwayBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
    begin
        // [SCENARIO] Post WIP Transfer Order: first shipment only, then partial receipt, then remaining receipt
        Initialize();

        // [GIVEN] Transfer Order with WIP Item and bin handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(FromLocation, FromReceiveBin, FromPutAwayBin);
        FromLocation."Require Pick" := false;
        FromLocation."Require Put-away" := false;
        FromLocation."Require Receive" := false;
        FromLocation."Require Shipment" := false;
        FromLocation.Modify();

        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(ToLocation, ToReceiveBin, ToPutAwayBin);
        ToLocation."Require Pick" := false;
        ToLocation."Require Put-away" := false;
        ToLocation."Require Receive" := false;
        ToLocation."Require Shipment" := false;
        ToLocation.Modify();
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        LibraryInventory.CreateItem(Item);
        CreateInventory(Item, FromLocation, FromPutAwayBin, Quantity, '');

        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);
        TransferLine.Validate("Transfer-from Bin Code", FromPutAwayBin.Code);
        TransferLine.Validate("Transfer-to Bin Code", ToReceiveBin.Code);
        TransferLine.Modify();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Post shipment only
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] Transfer Shipment is created and Qty. in Transit equals full quantity. No ItemLedgerEntries should be created since it's a WIP transfer
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Post partial receipt
        TransferLine.Validate("Qty. to receive", PartialQty);
        TransferLine.Modify();
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Partial Transfer Receipt is created, Quantity Received equals partial and remaining is still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should still be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 after partial receipt of WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receive Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receive Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after receive of WIP transfer');

        // [WHEN] Post remaining receipt
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after receive of WIP transfer');
    end;

    [Test]
    [HandlerFunctions('BinMessageHandler,DeleteWhseReceiptConfimHandler')]
    procedure PostWIPTransferOrder_FullWhseHandling_ShipPartialReceiveFullReceive()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromStorageBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
    begin
        // [SCENARIO] Post WIP Transfer Order using warehouse documents (Require Shipment, Receive, Pick, Put-Away all true):
        // ship via warehouse shipment, partial receive and full receive via warehouse receipts.
        // No Warehouse Picks or Put-Aways must be created despite Require Pick and Require Put-Away being enabled.
        Initialize();

        // [GIVEN] From location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(FromLocation, 5);
        LibraryWarehouse.CreateBin(FromStorageBin, FromLocation.Code, 'STORAGE', 'BULK', '');
        FromLocation.Validate("Default Bin Code", FromStorageBin.Code);
        FromLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);

        // [GIVEN] To location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(ToLocation, 5);
        LibraryWarehouse.CreateBin(ToReceiveBin, ToLocation.Code, 'RECEIVE', 'BULK', '');
        LibraryWarehouse.CreateBin(ToPutAwayBin, ToLocation.Code, 'PUTAWAY', 'BULK', '');
        ToLocation.Validate("Receipt Bin Code", ToReceiveBin.Code);
        ToLocation.Validate("Default Bin Code", ToPutAwayBin.Code);
        ToLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ToLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        LibraryInventory.CreateItem(Item);
        CreateInventory(Item, FromLocation, FromStorageBin, Quantity, '');

        // [GIVEN] Transfer Order with WIP Item and bin assignment
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Release Transfer Order and create Warehouse Shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] No Warehouse Pick is created despite Require Pick = true (WIP transfer bypasses pick creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Location Code", FromLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Post Warehouse Shipment
        WarehouseShipmentHeader.SetRange("Location Code", FromLocation.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer Shipment is created with WIP behavior: base quantities are 0, no item/warehouse ledger entries created
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Create Warehouse Receipt for To Location and post partial receive
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQty);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Partial Transfer Receipt created with WIP behavior and remaining quantity still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 for WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after partial receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after partial receive of WIP transfer');

        // [THEN] No Warehouse Put-Away created despite Require Put-Away = true (WIP transfer bypasses put-away creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Create second Warehouse Receipt for remaining quantity and post
        WarehouseReceiptHeader.Find('=');
        WarehouseReceiptHeader.Delete(true);
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after full receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after full receive of WIP transfer');

        // [THEN] Still no Warehouse Put-Away after final receive
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    [HandlerFunctions('BinMessageHandler,DeleteWhseReceiptConfimHandler')]
    procedure PostWIPTransferOrder_FullWhseHandling_SerialTrackedItem()
    var
        FromLocation, ToLocation, InTransitCode : Record Location;
        FromStorageBin, ToReceiveBin, ToPutAwayBin : Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        NewLotNo: Code[50];
        Quantity, PartialQty : Decimal;
        ItemLedgerEntryCountBefore, WarehouseEntryCountBefore : Integer;
        TransferOrder: TestPage "Transfer Order";
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        // [SCENARIO] Post WIP Transfer Order via full-WMS warehouse documents using a serial-tracked item.
        // The item tracking actions on the Transfer Order Subform and the Warehouse Receipt Subform
        // must be Enabled = false for WIP items. Posting succeeds without creating any item or warehouse
        // ledger/tracking entries, and no Warehouse Picks or Put-Aways are generated.
        Initialize();

        // [GIVEN] From location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(FromLocation, 5);
        LibraryWarehouse.CreateBin(FromStorageBin, FromLocation.Code, 'STORAGE', 'BULK', '');
        FromLocation.Validate("Default Bin Code", FromStorageBin.Code);
        FromLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);

        // [GIVEN] To location with all warehouse handling flags enabled
        LibraryWarehouse.CreateFullWMSLocation(ToLocation, 5);
        LibraryWarehouse.CreateBin(ToReceiveBin, ToLocation.Code, 'RECEIVE', 'BULK', '');
        LibraryWarehouse.CreateBin(ToPutAwayBin, ToLocation.Code, 'PUTAWAY', 'BULK', '');
        ToLocation.Validate("Receipt Bin Code", ToReceiveBin.Code);
        ToLocation.Validate("Default Bin Code", ToPutAwayBin.Code);
        ToLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ToLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitCode);
        Quantity := 10;
        PartialQty := 4;

        // [GIVEN] Create lot-tracked item (Lot Warehouse Tracking enabled; Lot Specific = false so that
        // a plain item-journal inventory adjustment can be posted without assigning lot numbers,
        // while warehouse activities still enforce lot numbers — which are skipped for WIP transfers)
        LibraryItemTracking.CreateLotItem(Item);
        NewLotNo := LibraryUtility.GetNextNoFromNoSeries(LibraryUtility.GetGlobalNoSeriesCode(), WorkDate());

        // [GIVEN] Create inventory at From Location
        CreateInventory(Item, FromLocation, FromStorageBin, Quantity, NewLotNo);

        // [GIVEN] Transfer Order with WIP Item flag
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        Commit();
        TransferOrder.OpenEdit();
        TransferOrder.GoToRecord(TransferHeader);
        Assert.IsFalse(TransferOrder.TransferLines.Shipment.Enabled(), 'Shipment action should be disabled on Transfer Order Subform for WIP item');
        Assert.IsFalse(TransferOrder.TransferLines.Receipt.Enabled(), 'Receipt action should be disabled on Transfer Order Subform for WIP item');
        Assert.IsFalse(TransferOrder.TransferLines.Reserve.Enabled(), 'Reserve action should be disabled on Transfer Order Subform for WIP item');
        TransferOrder.Close();

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Release Transfer Order and create Warehouse Shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] No Warehouse Pick is created despite Require Pick = true (WIP transfer bypasses pick creation)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Location Code", FromLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
        Commit();

        // [THEN] Item Tracking Lines action on Warehouse Shipment Subform should be Enabled = false for WIP item (enforced by page extension Subc. Whse Rcpt Subform Ext.)
        WarehouseShipmentHeader.SetRange("Location Code", FromLocation.Code);
        WarehouseShipmentHeader.FindFirst();
        WarehouseShipment.OpenEdit();
        WarehouseShipment.GoToRecord(WarehouseShipmentHeader);
        Assert.IsFalse(WarehouseShipment.WhseShptLines.ItemTrackingLines.Enabled(), 'Item Tracking Lines action should be disabled on Warehouse Shipment Subform for WIP item');
        WarehouseShipment.Close();

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Transfer Shipment created with WIP behavior: base quantities are 0, no item/warehouse ledger entries
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(Quantity, TransferLine."Qty. in Transit", 'Qty. in Transit should equal full quantity after shipment');
        Assert.AreEqual(0, TransferShipmentLine."Quantity (Base)", 'Quantity (Base) on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferShipmentLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Shipment Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after shipment of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after shipment of WIP transfer');

        // [WHEN] Create Warehouse Receipt for To Location
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        // [THEN] Verify via TestPage that ItemTrackingLines action is disabled on Warehouse Receipt Subform
        WarehouseReceiptPage.OpenView();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        Assert.IsFalse(WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Enabled(), 'Item Tracking Lines action should be disabled on Warehouse Receipt Subform for WIP item');
        WarehouseReceiptPage.Close();

        // [WHEN] Post partial receipt
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQty);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Partial Transfer Receipt created with WIP behavior and remaining qty still in transit
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.IsTrue(TransferReceiptHeader.FindFirst(), 'Partial Transfer Receipt should be posted');
        TransferReceiptLine.Get(TransferReceiptHeader."No.", 10000);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(PartialQty, TransferLine."Quantity Received", 'Quantity Received should equal partial quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", 'Qty. Shipped (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferLine."Qty. Received (Base)", 'Qty. Received (Base) should be 0 for WIP transfer');
        Assert.AreEqual(Quantity - PartialQty, TransferLine."Qty. in Transit", 'Qty. in Transit should be remaining quantity after partial receipt');
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", 'Qty. in Transit (Base) should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Quantity (Base)", 'Quantity (Base) on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(0, TransferReceiptLine."Qty. per Unit of Measure", 'Qty. per Unit of Measure on Receipt Line should be 0 for WIP transfer');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after partial receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after partial receive of WIP transfer');

        // [THEN] No Warehouse Put-Away created despite Require Put-Away = true
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [WHEN] Delete consumed receipt and create second Warehouse Receipt for remaining quantity
        WarehouseReceiptHeader.Find('=');
        WarehouseReceiptHeader.Delete(true);
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, ToLocation.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Two Transfer Receipts exist and Transfer Order is deleted (completed)
        Assert.AreEqual(2, TransferReceiptHeader.Count(), 'Two Transfer Receipts should be posted');
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Transfer Order should be deleted after all receipts are posted');
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'No Item Ledger Entries should be created after full receive of WIP transfer');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'No Warehouse Entries should be created after full receive of WIP transfer');

        // [THEN] No Warehouse Put-Away after final receipt
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", ToLocation.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    procedure CalcRegenPlanForPlanWksh_WIPTransferLine_NotConsideredAsDemandOrSupply()
    var
        Customer: Record Customer;
        FromLocation, ToLocation, InTransitCode : Record Location;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Planning Worksheet (Regenerative Plan) does not consider WIP Transfer Lines as demand or supply
        // because all base quantity fields ("Quantity (Base)", "Outstanding Qty. (Base)", etc.) are 0.
        // The planning uses SKU-level configuration with Replenishment System = Transfer.
        Initialize();
        Quantity := 10;

        // [GIVEN] Locations with Transfer Route and In-Transit Location
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(FromLocation);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitCode);

        // [GIVEN] An item with a SKU at ToLocation configured for Transfer replenishment from FromLocation
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A WIP Transfer Order for the item (base quantities = 0)
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitCode.Code, Item, Quantity);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, ToLocation.Code, Item."No.", '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Transfer-from Code", FromLocation.Code);
        StockkeepingUnit.Modify(true);

        // [GIVEN] Verify the WIP Transfer Line has base quantities = 0 (precondition)
        Assert.AreEqual(0, TransferLine."Quantity (Base)", 'Precondition: WIP Transfer Line Quantity (Base) must be 0');
        Assert.AreEqual(0, TransferLine."Outstanding Qty. (Base)", 'Precondition: WIP Transfer Line Outstanding Qty. (Base) must be 0');
        Assert.AreEqual(0, TransferLine."Qty. per Unit of Measure", 'Precondition: WIP Transfer Line Qty. per Unit of Measure must be 0');

        // [GIVEN] A Sales Order creating real demand for the item at the To Location
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, Customer."No.", Item."No.", Quantity, ToLocation.Code, WorkDate());

        // [WHEN] Run Regenerative Plan for Planning Worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
        Commit();

        // [THEN] Requisition Lines are created for the Sales Order demand (Replenishment System = Transfer via SKU)
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::Transfer);
        Assert.IsTrue(RequisitionLine.FindFirst(), 'Planning should create a Requisition Line for the Sales Order demand');

        // [THEN] The planned transfer has the full base quantity (from Sales demand), proving the WIP Transfer Line was NOT used as supply
        Assert.AreEqual(RequisitionLine.Quantity, Quantity, 'Requisition Line Quantity should equal Sales Order quantity');
        Assert.AreEqual(Quantity, RequisitionLine."Quantity (Base)", 'Requisition Line Quantity (Base) should equal Sales demand quantity, proving WIP Transfer was not counted as supply');

        // [WHEN] Delete the Planning Worksheet lines, remove the WIP flag from the transfer line and run planning again
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.DeleteAll(true);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        TransferLine.Validate("Transfer WIP Item", false);
        TransferLine.Modify(true);
        Commit();

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
        Commit();

        // [THEN] The transfer line is now considered by planning because it carries non-zero base quantities. No new Requisition Line should be created since the existing transfer can cover the demand.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [ConfirmHandler]
    procedure DeleteWhseReceiptConfimHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question.Contains('Do you really want to delete the Whse. Receipt') then begin
            Reply := true;
            exit;
        end;
        Error('Unexpected confirmation message.');
    end;

    [MessageHandler]
    procedure BinMessageHandler(Message: Text[1024])
    begin
        if Message.Contains('Transfer order') and Message.Contains('was successfully posted') then
            exit;
        Error('Unexpected Message.');
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. WIP Transfer Post Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. WIP Transfer Post Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. WIP Transfer Post Test");
    end;

    procedure CreateInventory(Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
        ItemJournalLine, Item."No.", Location.Code, Bin.Code, Quantity);

        if LotNo <> '' then
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;
}