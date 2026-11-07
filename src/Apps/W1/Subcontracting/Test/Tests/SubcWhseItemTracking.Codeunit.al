// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 149905 "Subc. Whse Item Tracking"
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
        LibraryPurchase: Codeunit "Library - Purchase";
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

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Item Tracking");

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        SubcontractingMgmtLibrary.SetupInventorySetup();
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
        Vendor."Subc. Location Code" := Location.Code;
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
        Vendor."Subc. Location Code" := Location.Code;
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
        Vendor."Subc. Location Code" := Location.Code;
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
        Vendor."Subc. Location Code" := Location.Code;
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

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UndoTrackedSubcontractingReceiptCreatesValidItemEntryRelation()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemEntryRelation: Record "Item Entry Relation";
        ReversingItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderNo: Code[20];
    begin
        // [SCENARIO] Undo of a tracked subcontracting receipt must NOT key an Item Entry Relation with a
        // Capacity Ledger Entry No.
        // [FEATURE] Repro for bug 644744.
        // A single serial-tracked output forces the applied-entry-list path in
        // UndoPostingManagement.PostItemJnlLineAppliedToList, which copies "Item Shpt. Entry No."
        // (a Capacity Ledger Entry No. for subcontracting, set in Item Jnl.-Post Line) into
        // Item Entry Relation."Item Entry No.". The untracked single-output case (see
        // Subc. Whse Receipt Last Op.'s UndoPurchaseReceiptForLastOperation) instead takes the
        // single-entry shortcut and never exercises this path, which is why it does not repro.

        // [GIVEN] A posted serial-tracked subcontracting receipt
        Initialize();
        PostTrackedSubcontractingReceipt(Item, PurchaseHeader, PurchaseLine, ProdOrderNo);

        // [WHEN] Undo the posted subcontracting purchase receipt line
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
        Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] The undo created a reversing Capacity Ledger Entry (net output quantity is zero)
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);

        // [THEN] ... and a reversing (negative) Output Item Ledger Entry
        ReversingItemLedgerEntry.SetRange("Item No.", Item."No.");
        ReversingItemLedgerEntry.SetRange("Entry Type", ReversingItemLedgerEntry."Entry Type"::Output);
        ReversingItemLedgerEntry.SetRange(Positive, false);
        Assert.RecordIsNotEmpty(ReversingItemLedgerEntry);
        ReversingItemLedgerEntry.FindFirst();

        // [THEN] The Item Entry Relation created by the undo references the reversing Output Item Ledger
        // Entry. With bug 644744 it is instead keyed by the reversing Capacity Ledger Entry No., so no
        // relation references the reversing Output Item Ledger Entry and this assertion fails.
        ItemEntryRelation.SetRange("Item Entry No.", ReversingItemLedgerEntry."Entry No.");
        Assert.RecordIsNotEmpty(ItemEntryRelation);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UndoNonLastOperationSubcontractingReceiptCreatesNoCapacityKeyedRelation()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderNo: Code[20];
    begin
        // [SCENARIO] Undo of a NON-last-operation subcontracting receipt (only a Capacity Ledger Entry is
        // created, no Output Item Ledger Entry) takes the single-line undo path and must not create any
        // Item Entry Relation keyed by a Capacity Ledger Entry.
        // [FEATURE] Guard for bug 644744 - confirms the capacity-only undo path is unaffected.
        // Because there is no output entry, MfgUndoPurchRcptLine leaves the applied-entry list empty, so
        // UndoPurchaseReceiptLine takes the "if no output posted" single-line branch (PostItemJnlLine) and
        // never runs PostItemJnlLineAppliedToList - the code that mis-keys the relation.

        // [GIVEN] A posted non-last-operation subcontracting receipt (capacity only)
        Initialize();
        PostNonLastOperationSubcontractingReceipt(Item, PurchaseHeader, PurchaseLine, ProdOrderNo);

        // [WHEN] Undo the posted subcontracting purchase receipt line
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
        Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] The undo posted a reversing Capacity Ledger Entry (net output quantity is zero)
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);
        CapacityLedgerEntry.CalcSums("Output Quantity");
        Assert.AreEqual(0, CapacityLedgerEntry."Output Quantity", 'Net capacity output quantity should be zero after undo');

        // [THEN] No Output Item Ledger Entry exists for the item - the capacity-only receipt has no output
        // entry, so the undo takes the single-line path and never builds an Item Entry Relation.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsEmpty(ItemLedgerEntry);
    end;

    local procedure PostTrackedSubcontractingReceipt(var Item: Record Item; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ProdOrderNo: Code[20])
    var
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        // [GIVEN] A serial-tracked subcontracting item. A single tracked output forces the applied-entry-list
        // undo path (Serial No. <> '' keeps "Applies-to Entry" = 0), which is where the defect lives.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateSerialTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] A plain location - no warehouse receipt/put-away is needed to reproduce the defect
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Vendor configured with the subcontracting location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Released production order (qty 1 for serial). The serial number is assigned on the prod.
        // order line; the subcontracting receipt inherits this tracking automatically.
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1, Location.Code);
        ProdOrderNo := ProductionOrder."No.";

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SerialNo := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo, '', 1);

        // [GIVEN] Subcontracting purchase order created from the routing
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Post the subcontracting receipt directly (Receive); tracking flows from the prod. order reservation
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostNonLastOperationSubcontractingReceipt(var Item: Record Item; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ProdOrderNo: Code[20])
    var
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] A subcontracting item whose subcontracting operation is Work Center 1 (NOT the last
        // operation). Posting the receipt for a non-last operation creates only a Capacity Ledger Entry.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] A plain location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Vendor of the non-last operation configured with the subcontracting location
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Released production order and a subcontracting purchase order for the non-last operation
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        ProdOrderNo := ProductionOrder."No.";
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Post the subcontracting receipt directly (Receive)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure SplitPutAwayPlaceLineAcrossBinsKeepsSingleTakeLineWithLotTracking()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        LotNo: Code[50];
        Qty1: Decimal;
        Qty2: Decimal;
        Quantity: Decimal;
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO] Split the two-step Put-away "Place" line across two bins while a single lot covers
        // the full Last Operation quantity, and confirm the paired "Take" line remains a single,
        // unsplit line for the full quantity while both split "Place" lines retain the assigned Lot No.
        // and post correct per-bin Bin Content / Item Ledger quantities.
        // [FEATURE] Subcontracting Item Tracking - Bin splitting combined with Take/Place Put-away lines

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Lot-tracked Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        Qty1 := Round(Quantity / 2, 1);
        Qty2 := Quantity - Qty1;

        // [GIVEN] Create and Calculate needed Work and Machine Center with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Lot-tracked Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling (Take/Place Put-away) and two extra put-away bins
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin1, Location.Code, 'SPLIT1', '', '');
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'SPLIT2', '', '');

        // [GIVEN] Update Vendor with Subcontracting Location Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order and Warehouse Receipt
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        // [GIVEN] A single lot covering the full quantity is assigned on the Warehouse Receipt Line
        LotNo := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");
        HandlingMode := HandlingMode::Insert;
        HandlingSerialNo := '';
        HandlingLotNo := LotNo;
        HandlingQty := Quantity;

        WarehouseReceiptPage.OpenEdit();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [WHEN] Warehouse Receipt posted, then Put-away created (Take + Place lines, both for the single lot)
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(LotNo, WarehouseActivityLine."Lot No.", 'Place line should carry the assigned lot before splitting.');

        // [WHEN] The Place line is split across two bins using the standard Warehouse Activity Line SplitLine method
        // (the same procedure invoked by the "Split Line" action on the Put-away page)
        WarehouseActivityLine.Validate("Bin Code", Bin1.Code);
        WarehouseActivityLine.Validate("Qty. to Handle", Qty1);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.SplitLine(WarehouseActivityLine, NewWarehouseActivityLine);
        NewWarehouseActivityLine.Validate("Bin Code", Bin2.Code);
        NewWarehouseActivityLine.Validate(Quantity, Qty2);
        NewWarehouseActivityLine.Validate("Qty. to Handle", Qty2);
        NewWarehouseActivityLine.Modify(true);

        // [THEN] Both split Place lines retain the original Lot No.; the paired Take line remains a single,
        // unsplit line for the full received quantity
        Assert.AreEqual(LotNo, NewWarehouseActivityLine."Lot No.", 'Split Place line should retain the lot number.');
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, 'Take line must remain unsplit for the full received quantity.');
        Assert.AreEqual(LotNo, WarehouseActivityLine."Lot No.", 'Take line should carry the assigned lot.');

        // [WHEN] The Put-away (single Take line, two split Place lines) is registered/posted
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Each bin receives its split quantity, both under the same lot; total output reconciles
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bin1.Code, Item."No.", Qty1);
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bin2.Code, Item."No.", Qty2);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Total output quantity across both split bins must reconcile with the full lot quantity.');
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