// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 140005 "Subc. Whse Item Tracking"
{
    // [FEATURE] Subcontracting Item Tracking Integration Tests
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        HandlingLotNo: Code[50];
        HandlingSerialNo: Code[50];
        HandlingQty: Decimal;
        HandlingSourceType: Integer;
        HandlingMode: Option Verify,Insert;

    local procedure Initialize()
    begin
        HandlingSerialNo := '';
        HandlingLotNo := '';
        HandlingQty := 0;
        HandlingMode := HandlingMode::Verify;
        HandlingSourceType := 0;
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Item Tracking");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Item Tracking");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Item Tracking");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure FullProcessWithSerialTrackingFromProdOrderLine()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        SerialNo: Code[50];
        Quantity: Decimal;
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO] Full Process with Serial Tracking from Production Order Line
        // [FEATURE] Subcontracting Item Tracking - Last Operation with Serial Numbers

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Serial-tracked Item
        Initialize();
        Quantity := 1; // Serial tracking requires quantity of 1

        // [GIVEN] Create and Calculate needed Work and Machine Center with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Serial-tracked Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateSerialTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Update Vendor with Subcontracting Location Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Assign Serial Number to Production Order Line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        SerialNo := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo, '', Quantity);

        // [GIVEN] Update Subcontracting Management Setup with Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [THEN] Verify Data Consistency: Item tracking is propagated to Warehouse Receipt
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        Assert.AreEqual(Item."No.", WarehouseReceiptLine."Item No.",
            'Item No. should match on Warehouse Receipt Line');

        // [THEN] Verify Data Consistency: Reservation entries exist for warehouse receipt
        HandlingSerialNo := SerialNo;
        HandlingLotNo := '';
        HandlingQty := Quantity;

        // [GIVEN] Create Warehouse Employee for Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        WarehouseReceiptPage.OpenView();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [WHEN] Post Warehouse Receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [WHEN] Create Put-away from Posted Warehouse Receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        // [THEN] Verify Data Consistency: Item tracking is propagated to Put-away
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        Assert.AreEqual(Item."No.", WarehouseActivityLine."Item No.", 'Item No. should match on Put-away Line');
        Assert.AreEqual(SerialNo, WarehouseActivityLine."Serial No.", 'Serial No. should be propagated to Put-away Line');

        // [WHEN] Post Put-away
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify Posted Entries: Item Ledger Entry contains correct serial number
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Serial No.", SerialNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry Quantity should match');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Item Ledger Entry Location Code should match');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure FullProcessWithLotTrackingFromProdOrderLine()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        LotNo: Code[50];
        Quantity: Decimal;
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO] Full Process with Lot Tracking from Production Order Line
        // [FEATURE] Subcontracting Item Tracking - Last Operation with Lot Numbers

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Lot-tracked Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create and Calculate needed Work and Machine Center with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Lot-tracked Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Update Vendor with Subcontracting Location Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Assign Lot Number to Production Order Line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        LotNo := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNo, Quantity);

        // [GIVEN] Update Subcontracting Management Setup with Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [THEN] Verify Data Consistency: Item tracking information is consistent across all documents
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        // [THEN] Verify Data Consistency: Reservation entries exist for warehouse receipt with lot number
        HandlingSerialNo := '';
        HandlingLotNo := LotNo;
        HandlingQty := Quantity;

        // [GIVEN] Create Warehouse Employee for Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        WarehouseReceiptPage.OpenView();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [WHEN] Post Warehouse Receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [WHEN] Create Put-away from Posted Warehouse Receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        // [THEN] Verify Data Consistency: Item tracking is correctly passed to the put-away
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        Assert.AreEqual(LotNo, WarehouseActivityLine."Lot No.",
            'Lot No. should be propagated to Put-away Line');

        // [WHEN] Post Put-away
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify Posted Entries: All posted entries correctly reflect assigned item tracking
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry Quantity should match');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Item Ledger Entry Location Code should match');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure FullProcessWithLotTrackingFromWhseReceiptLine()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        LotNo: Code[50];
        Quantity: Decimal;
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO] Full Process with Lot Tracking from Warehouse Receipt Line
        // [FEATURE] Subcontracting Item Tracking - Assign tracking at warehouse receipt stage

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Lot-tracked Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create and Calculate needed Work and Machine Center with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Lot-tracked Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Update Vendor with Subcontracting Location Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Update Subcontracting Management Setup with Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [WHEN] Assign Lot Number at Warehouse Receipt Line stage using Item Tracking Lines page
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        LotNo := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");

        // [GIVEN] Create Warehouse Employee for Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [WHEN] Insert item tracking via page
        HandlingMode := HandlingMode::Insert;
        HandlingSerialNo := '';
        HandlingLotNo := LotNo;
        HandlingQty := Quantity;

        WarehouseReceiptPage.OpenEdit();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [THEN] Verify item tracking is correctly assigned and source type is Prod. Order Line
        HandlingMode := HandlingMode::Verify;
        HandlingSourceType := Database::"Prod. Order Line";

        WarehouseReceiptPage.OpenView();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [WHEN] Post Warehouse Receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [WHEN] Create Put-away from Posted Warehouse Receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        // [THEN] Verify Data Consistency: Item tracking is correctly passed to put-away
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        Assert.AreEqual(LotNo, WarehouseActivityLine."Lot No.",
            'Lot No. should be propagated to Put-away Line');

        // [WHEN] Post Put-away
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify Posted Entries: Posted entries correctly reflect assigned item tracking
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry Quantity should match');
        Assert.AreEqual(LotNo, ItemLedgerEntry."Lot No.", 'Item Ledger Entry Lot No. should match');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure ItemTrackingForNonLastOperations()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        LotNo: Code[50];
        Quantity: Decimal;
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO] Item Tracking for Non-Last Operations
        // [FEATURE] Subcontracting Item Tracking - Intermediate Operations with Lot Numbers

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Lot-tracked Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create and Calculate needed Work and Machine Center with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Lot-tracked Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);

        // [GIVEN] Create Location with Warehouse Handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Create Warehouse Employee for Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Update Vendor with Subcontracting Location Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Assign Lot Number to Production Order Line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        LotNo := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNo, Quantity);

        // [GIVEN] Update Subcontracting Management Setup with Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order for intermediate operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [THEN] Verify Data Consistency: Item tracking is correctly handled on warehouse receipt
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        Assert.AreEqual(WarehouseReceiptLine."Subc. Purchase Line Type"::LastOperation,
            WarehouseReceiptLine."Subc. Purchase Line Type",
            'Warehouse Receipt Line should be marked as Intermediate Operation');

        // [THEN] Verify Data Consistency: Reservation entries exist for non-last operation
        HandlingSerialNo := '';
        HandlingLotNo := LotNo;
        HandlingQty := Quantity;

        WarehouseReceiptPage.OpenView();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [WHEN] Post Warehouse Receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [THEN] Verify Posted Entries: Posted entries reflect correct item tracking
        PostedWhseReceiptLine.SetRange("Item No.", Item."No.");
        PostedWhseReceiptLine.FindFirst();

        PostedWhseReceiptHeader.Get(PostedWhseReceiptLine."No.");

        // [THEN] Verify Posted Entries: Item ledger entries contain correct lot number
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry Quantity should match for non-last operation');
        Assert.AreEqual(LotNo, ItemLedgerEntry."Lot No.", 'Item Ledger Entry Lot No. should match for non-last operation');
    end;

    local procedure VerifyPostedWhseReceiptQuantity(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        Assert.RecordIsNotEmpty(PostedWhseReceiptLine);

        PostedWhseReceiptLine.FindFirst();
        Assert.AreEqual(ExpectedQuantity, PostedWhseReceiptLine.Quantity,
            'Posted warehouse receipt line should have correct quantity');
    end;

    local procedure VerifyItemLedgerEntryForLot(ItemNo: Code[20]; LotNo: Code[50]; ExpectedQuantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQuantity, ItemLedgerEntry.Quantity,
            'Item Ledger Entry should have correct quantity for lot ' + LotNo);
    end;

    local procedure VerifyBinContentsForLot(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; ExpectedQuantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Lot No. Filter", LotNo);
        Assert.RecordIsNotEmpty(BinContent);

        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        Assert.AreEqual(ExpectedQuantity, BinContent.Quantity,
            'Bin contents should show correct quantity for lot ' + LotNo + ' after put-away posting');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        case HandlingMode of
            HandlingMode::Verify:
                begin
                    ItemTrackingLines.First();
                    if HandlingSerialNo <> '' then
                        Assert.AreEqual(HandlingSerialNo, Format(ItemTrackingLines."Serial No.".Value), 'Serial No. mismatch');
                    if HandlingLotNo <> '' then
                        Assert.AreEqual(HandlingLotNo, Format(ItemTrackingLines."Lot No.".Value), 'Lot No. mismatch');

                    Assert.AreEqual(HandlingQty, ItemTrackingLines."Quantity (Base)".AsDecimal(), 'Quantity mismatch');

                    if HandlingSourceType <> 0 then begin
                        ReservationEntry.SetRange("Serial No.", Format(ItemTrackingLines."Serial No.".Value));
                        ReservationEntry.SetRange("Lot No.", Format(ItemTrackingLines."Lot No.".Value));
                        ReservationEntry.FindFirst();
                        Assert.AreEqual(HandlingSourceType, ReservationEntry."Source Type",
                            'Reservation Entry Source Type should be Prod. Order Line');
                    end;
                end;
            HandlingMode::Insert:
                begin
                    ItemTrackingLines.New();
                    if HandlingSerialNo <> '' then
                        ItemTrackingLines."Serial No.".SetValue(HandlingSerialNo);
                    if HandlingLotNo <> '' then
                        ItemTrackingLines."Lot No.".SetValue(HandlingLotNo);

                    ItemTrackingLines."Quantity (Base)".SetValue(HandlingQty);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;
}
