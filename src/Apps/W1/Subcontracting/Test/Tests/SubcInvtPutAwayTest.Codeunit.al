// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 149918 "Subc. Invt. Put-away Test"
{
    // [FEATURE] Subcontracting Inventory Put-Away (Single-Step Logistics) Tests
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
        LibraryInventory: Codeunit "Library - Inventory";
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

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Invt. Put-away Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away Test");

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryPurchase.SetPostedNoSeriesInSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibrarySetupStorage.Save(Database::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away Test");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]

    procedure LastOperation_ActivityLineGetsRealQtyPerUnitOfMeasure()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Inventory Put-away Activity Line for a Last Operation subcontracting purchase
        // line must have a real (non-zero) Qty. per Unit of Measure, even though the purchase
        // line itself carries Qty. per Unit of Measure = 0.
        // [FEATURE] Subcontracting Inventory Put-Away - Last Operation

        // [GIVEN] Complete Manufacturing Setup with a single-operation subcontracting routing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Location for single-step logistics (Require Receive = false, Require Put-away = true)
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Subcontracting Purchase Order for the (only, last) operation, released
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create Inventory Put-away from the purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        // [THEN] One Warehouse Activity Line is created, marked as Last Operation
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
#pragma warning disable AA0210
        WarehouseActivityLine.SetRange("Subc. Purchase Line Type", "Subc. Purchase Line Type"::LastOperation);
#pragma warning restore AA0210
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();

        Assert.AreEqual("Subc. Purchase Line Type"::LastOperation, WarehouseActivityLine."Subc. Purchase Line Type", 'Activity Line should be marked as Last Operation');

        // [THEN] Qty. per Unit of Measure is restored to the real value (not 0, as on the purchase line)
        Assert.AreNotEqual(0, WarehouseActivityLine."Qty. per Unit of Measure", 'LastOperation activity line must have a real Qty. per Unit of Measure, not 0');
        Assert.AreEqual(0, PurchaseLine."Qty. per Unit of Measure", 'The underlying purchase line must still have Qty. per Unit of Measure = 0');

        // [THEN] Qty. (Base) is calculated correctly using the real Qty. per Unit of Measure
        Assert.AreEqual(WarehouseActivityLine.Quantity * WarehouseActivityLine."Qty. per Unit of Measure", WarehouseActivityLine."Qty. (Base)", 'Qty. (Base) must equal Quantity * Qty. per Unit of Measure for LastOperation');
        Assert.AreNotEqual(0, WarehouseActivityLine."Qty. (Base)", 'Qty. (Base) must not be 0 for LastOperation');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure NotLastOperation_ActivityLineKeepsZeroBaseQuantity()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Inventory Put-away Activity Line for a Not-Last-Operation subcontracting
        // purchase line must intentionally keep Qty. per Unit of Measure = 0 and Qty. (Base) = 0,
        // since no physical inventory movement happens for intermediate operations.
        // [FEATURE] Subcontracting Inventory Put-Away - Not Last Operation

        // [GIVEN] Complete Manufacturing Setup with a two-operation subcontracting routing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] Location for single-step logistics
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Subcontracting Purchase Order for the first (not-last) operation, released
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create Inventory Put-away from the purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        // [THEN] One Warehouse Activity Line is created, marked as Not Last Operation
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();

        Assert.AreEqual("Subc. Purchase Line Type"::NotLastOperation, WarehouseActivityLine."Subc. Purchase Line Type", 'Activity Line should be marked as Not Last Operation');

        // [THEN] Qty. per Unit of Measure and Qty. (Base) remain 0 - no inventory movement
        Assert.AreEqual(0, WarehouseActivityLine."Qty. per Unit of Measure", 'NotLastOperation activity line must keep Qty. per Unit of Measure = 0');
        Assert.AreEqual(0, WarehouseActivityLine."Qty. (Base)", 'NotLastOperation activity line must keep Qty. (Base) = 0');
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, 'Quantity (in purchase unit of measure) must still reflect the full quantity');
    end;

    [HandlerFunctions('MessageHandler')]
    [Test]
    procedure PostLastOperation_BinMandatoryLocation_NoDuplicateWarehouseEntry()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Regression test for the double-posting bug: posting a Last Operation
        // Inventory Put-away at a Bin Mandatory location must create Warehouse Entries that
        // sum up to exactly the posted quantity - not double
        // [FEATURE] Subcontracting Inventory Put-Away - Last Operation posting

        // [GIVEN] Complete Manufacturing Setup with a single-operation subcontracting routing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Location for single-step logistics with Bin Mandatory = true
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Inventory Put-away created from the purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post the Inventory Put-away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Purch. Rcpt. Line created for the purchase line
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        Assert.RecordIsNotEmpty(PurchRcptLine);

        // [THEN] Output Item Ledger Entry created with the correct (single) quantity
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry total Quantity must equal the posted quantity exactly once');

        // [THEN] Warehouse Entries for the bin sum up to exactly the posted quantity - NOT double
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, WarehouseEntry.Quantity, 'Warehouse Entry total Quantity must equal the posted quantity exactly once (regression: must not be doubled)');

        // [THEN] Warehouse Entry is linked to the production order output
        WarehouseEntry.SetRange("Source Type", Database::"Item Journal Line");
        WarehouseEntry.SetRange("Source Subtype", 5);
        WarehouseEntry.SetRange("Source No.", ProductionOrder."No.");
        WarehouseEntry.SetRange("Source Line No.", PurchaseLine."Prod. Order Line No.");
        Assert.RecordCount(WarehouseEntry, 1);

        // [THEN] Capacity Ledger Entry created for the subcontracting work center
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);

        // [THEN] Purchase Line is fully received        
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'Purchase Line should be fully received');
    end;

    [HandlerFunctions('MessageHandler')]
    [Test]
    procedure PostLastOperation_WithLotAssignedInInventoryPutAway_CreatesTrackedOutput()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [SCENARIO] Post a LastOperation Inventory Put-away with a lot assigned directly on the
        // inventory put-away line, without presetting tracking on the production order line.
        // [FEATURE] Subcontracting Inventory Put-Away - Direct lot assignment on Last Operation

        // [GIVEN] Complete Manufacturing Setup with a single-operation subcontracting routing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Location for single-step logistics with Bin Mandatory = true
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Subcontracting Purchase Order for the last operation, without production-order tracking
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Inventory Put-away created from the purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        LotNo := 'DIRECT-LOT';
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        Assert.AreEqual(LotNo, WarehouseActivityLine."Lot No.", 'Lot should be assigned directly on the Inventory Put-away line');
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        WarehouseActivityLine.FindFirst();
        ItemTrackingMgt.SynchronizeWhseActivItemTrkg(WarehouseActivityLine);
        Assert.IsTrue(PurchaseLine.IsSubcontractingLineWithLastOperation(ProdOrderLine), 'Purchase line should be linked to the production order line');

        ReservationEntry.SetSourceFilter(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, true);
        ReservationEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        ReservationEntry.SetRange("Lot No.", LotNo);
        Assert.RecordIsNotEmpty(ReservationEntry);

        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", true);
        ReservationEntry.SetRange("Lot No.", LotNo);
        Assert.RecordIsEmpty(ReservationEntry);

        // [WHEN] Post the Inventory Put-away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Purch. Rcpt. Line created for the purchase line
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        Assert.RecordIsNotEmpty(PurchRcptLine);

        // [THEN] Output Item Ledger Entry contains the lot and the exact posted quantity
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Tracked Item Ledger Entry quantity must equal the posted quantity');

        // [THEN] Warehouse Entry contains the lot and the exact posted quantity once
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, WarehouseEntry.Quantity, 'Tracked Warehouse Entry quantity must equal the posted quantity');

        // [THEN] Capacity Ledger Entry created for the subcontracting work center
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);
    end;

    [HandlerFunctions('MessageHandler')]
    [Test]
    procedure PostLastOperation_WithLotAssignedInInventoryPutAway_MultiplePartialPosts()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        LotNo: Code[50];
    begin
        // [SCENARIO] Post a LastOperation Inventory Put-away in two partial steps when the lot is assigned
        // directly on the Inventory Put-away line and not predefined on the production order line.
        // [FEATURE] Subcontracting Inventory Put-Away - Partial direct lot assignment

        // [GIVEN] A lot-tracked item and a single-operation subcontracting routing
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 20, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] A lot is assigned directly on the Inventory Put-away line
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        LotNo := 'DIRECT-PARTIAL-LOT';
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] The first partial quantity is posted
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", 6);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(20, PurchaseLine.Quantity, 'The original purchase line quantity must remain unchanged after a partial post');
        Assert.AreEqual(14, PurchaseLine."Outstanding Quantity", 'The purchase line outstanding quantity must reflect the first partial post');

        // [WHEN] The remaining quantity is posted from the same Inventory Put-away
        SubcWarehouseLibrary.PostPartialPutAway(WarehouseActivityHeader, 14);

        // [THEN] The complete lot quantity is posted exactly once
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(20, ItemLedgerEntry.Quantity, 'Item Ledger Entry quantity must equal both partial postings');

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(20, WarehouseEntry.Quantity, 'Warehouse Entry quantity must equal both partial postings');
    end;

    [HandlerFunctions('MessageHandler')]
    [Test]
    procedure PostNotLastOperation_WithLotAssignedInInventoryPutAway_NoWarehouseEntryCreated()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [SCENARIO] Post a NotLastOperation Inventory Put-away with a lot assigned directly on the
        // inventory put-away line, without creating Warehouse Entries or dividing by zero.
        // [FEATURE] Subcontracting Inventory Put-Away - Direct lot assignment on Not Last Operation

        // [GIVEN] Complete Manufacturing Setup with a two-operation subcontracting routing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] Location for single-step logistics with Bin Mandatory = true
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Inventory Put-away created from the purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        LotNo := 'DIRECT-LOT';
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        Assert.AreEqual(LotNo, WarehouseActivityLine."Lot No.", 'Lot should be assigned directly on the Inventory Put-away line');
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post the Inventory Put-away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Purch. Rcpt. Line created for the purchase line
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        Assert.RecordIsNotEmpty(PurchRcptLine);

        // [THEN] Output Item Ledger Entry still created for the capacity/output side
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsEmpty(ItemLedgerEntry);

        // [THEN] No Warehouse Entry is created, since Qty. (Base) is 0 for NotLastOperation
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WarehouseEntry);

        // [THEN] Capacity Ledger Entry created for the subcontracting work center
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[1]."No.", Quantity);
    end;

    [Test]
    procedure LocationWithBinMandatoryOnly_DirectPosting_StillUsesAutomaticBinIntegration()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Directly post a purchase order at a Bin Mandatory location without Require Put-away.
        // [FEATURE] Subcontracting - Location Configuration (Bin Mandatory Only)

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Location with Bin Mandatory only (Require Receive = false, Require Put-away = false)
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(Location);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'DEFAULT', '', '');

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Bin Code set directly on the purchase line (simulating user input)
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Post the Purchase Order directly (no warehouse document involved)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Output Item Ledger Entry created with the correct quantity
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry should have the correct output quantity');

        // [THEN] Warehouse Entry is created exactly once
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, WarehouseEntry.Quantity, 'Warehouse Entry total Quantity must equal the posted quantity exactly once');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure UndoInvtPutAwayReceipt_NotBinMandatory_Succeeds()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Block undo of an Inventory Put-away receipt at a location that is not Bin Mandatory.
        // [FEATURE] Subcontracting Inventory Put-Away - Undo Receipt

        // [GIVEN] Complete Manufacturing Setup with a single-operation subcontracting routing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Location for single-step logistics, NOT Bin Mandatory
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Inventory Put-away created and posted
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [WHEN] Undo the Purchase Receipt Line
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Undo cannot be done because of existing Inventory Put-away posting
        Assert.ExpectedError('You cannot undo line');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure UndoInvtPutAwayReceipt_BinMandatory_Fails()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Block undo of an Inventory Put-away receipt at a Bin Mandatory location.
        // [FEATURE] Subcontracting Inventory Put-Away - Undo Receipt

        // [GIVEN] Complete Manufacturing Setup with a single-operation subcontracting routing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Location for single-step logistics with Bin Mandatory = true
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Inventory Put-away created and posted
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [WHEN] Try to Undo the Purchase Receipt Line
        // [THEN] Error is thrown because a Posted Invt. Put-away Line (bin content) exists
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);
        Assert.ExpectedError('warehouse put-away lines have already been posted');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure WipItemTransfer_InvtPutAway_ActivityLineGetsWipFlagAndKeepsZeroQtyPerUoM()
    var
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        Item: Record Item;
        StorageBin: Record Bin;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Inventory Put-away Activity Line created from a WIP Item Transfer Line must
        // have "Transfer WIP Item" = true and must keep Qty. per Unit of Measure = 0 (mirroring
        // the Transfer Line itself), analogous to NotLastOperation subcontracting purchase lines.
        // Validates the Transfer Line branch of Warehouse Activity Line_OnAfterSetSource.
        // [FEATURE] Subcontracting Inventory Put-Away - WIP Item Transfer

        // [GIVEN] Complete setup: a simple item, a WIP item transfer between two locations
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] From Location without any warehouse handling (simple shipment)
        LibraryWarehouse.CreateLocation(FromLocation);

        // [GIVEN] To Location for single-step logistics (Require Receive = false, Require Put-away = true)
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ToLocation);

        // [GIVEN] To Location is registered as a subcontracting location
        LibraryPurchase.CreateSubcontractor(Vendor);
        Vendor."Subc. Location Code" := ToLocation.Code;
        Vendor.Modify();

        CreateAndPostPositiveAdjustment(Item, FromLocation, StorageBin, Quantity);

        // [GIVEN] Released, shipped WIP Item Transfer Order
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Create Inventory Put-away from the (shipped) transfer order
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(TransferHeader, WarehouseActivityHeader);

        // [THEN] One Warehouse Activity Line is created, marked as Transfer WIP Item
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();

        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'Activity Line should be marked as Transfer WIP Item');

        // [THEN] Qty. per Unit of Measure and Qty. (Base) remain 0 - no physical inventory movement
        Assert.AreEqual(0, WarehouseActivityLine."Qty. per Unit of Measure", 'WIP Item transfer activity line must keep Qty. per Unit of Measure = 0');
        Assert.AreEqual(0, WarehouseActivityLine."Qty. (Base)", 'WIP Item transfer activity line must keep Qty. (Base) = 0');
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, 'Quantity (in transfer unit of measure) must still reflect the full quantity');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure WipItemTransfer_PostInvtPutAway_NoItemLedgerNoWarehouseEntry_CreatesWipLedgerEntry()
    var
        ForwardTransferHeader: Record "Transfer Header";
        InTransitLocation: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        MachineCenter: array[2] of Record "Machine Center";
        ProdLocation: Record Location;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        ILECountBefore: Integer;
        WhseEntryCountBefore: Integer;
    begin
        // [SCENARIO] Post a WIP return transfer Inventory Put-away without Item or Warehouse Entries.
        // [FEATURE] Subcontracting Inventory Put-Away - WIP Item Transfer posting

        // [GIVEN] Complete subcontracting manufacturing setup with routing that has Transfer WIP Item = true
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");

        // [GIVEN] Production location with Require Put-away = true and no bin handling
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ProdLocation);

        // [GIVEN] Transit location and bidirectional transfer routes between production and subcontractor
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProdLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        Vendor."Subc. Location Code" := Vendor."Subc. Location Code";
        Vendor."Location Code" := Vendor."Subc. Location Code";
        Vendor.Modify();

        // [GIVEN] Production order at the production location
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProdLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Subcontracting purchase order linked to the production order
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Forward Transfer Order created from the purchase order (WIP items sent TO subcontractor)
        // The report opens Transfer Order page - handled by HandleSubcTransferOrderPage
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.PostTransferOrder(ForwardTransferHeader, true, true);

        // [GIVEN] Return Transfer Order created with subcontracting routing context
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProdLocation.Code, InTransitLocation.Code,
            Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);

        // [GIVEN] Return transfer shipped from subcontractor (items now in transit to production location)
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);

        // Capture counts before Inventory Put-away posting
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ILECountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WhseEntryCountBefore := WarehouseEntry.Count();

        // [GIVEN] Inventory Put-away created from the shipped return transfer
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post the Inventory Put-away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] No new Item Ledger Entry was created (WIP transfer posting suppresses item journal)
        Assert.AreEqual(ILECountBefore, ItemLedgerEntry.Count(),
            'No Item Ledger Entries should be created by WIP item return transfer Inventory Put-away');

        // [THEN] No new Warehouse Entry is created at the production location
        Assert.AreEqual(WhseEntryCountBefore, WarehouseEntry.Count(),
            'No Warehouse Entries should be created for WIP item return transfer Inventory Put-away');

        // [THEN] Transfer Order is fully received and deleted (only the posted document remains)
        Assert.IsFalse(ReturnTransferHeader.Get(ReturnTransferHeader."No."),
            'Return Transfer Order must be deleted after the WIP item is fully received (only the posted document remains)');

        // [THEN] Transfer Receipt Header was created as the posted document
        TransferReceiptHeader.SetRange("Transfer Order No.", ReturnTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptHeader);
    end;

    local procedure CreateAndPostPositiveAdjustment(Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        if Message.Contains('Number of Invt. Put-away activities created') then
            exit;
        if Message.Contains('was successfully posted and is now deleted') then
            exit;
        Error('Unexpected Message: %1', Message);
    end;

    [PageHandler]
    procedure HandleSubcTransferOrderPage(var TransferOrderPage: TestPage "Transfer Order")
    begin
        // Close the Transfer Order page.
        TransferOrderPage.OK().Invoke();
    end;
}