// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
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
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 139981 "Subc. Location Handler Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Enhanced Subcontracting Location Handler
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        CreateSubcontractingOrderAnywayQst: Label 'Do you want to create the Subcontracting Order anyway?';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Location Handler Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Location Handler Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        LibrarySetupStorage.Save(Database::"Inventory Setup");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Location Handler Test");
    end;

    [Test]
    procedure TestGetComponentsLocationCode_Purchase()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        CompLocationCode: Code[10];
    begin
        // [SCENARIO] GetComponentsLocationCode returns Purchase Line Location when Setup is Purchase
        Initialize();

        // [GIVEN] Sub Management Setup "Subc. Default Comp. Location" is Purchase
        UpdateSubManagementSetup("Components at Location"::Purchase);

        // [GIVEN] A Purchase Line with a Location
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, '');
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify();

        // [WHEN] GetComponentsLocationCode is called
        CompLocationCode := SubcontractingMgmt.GetComponentsLocationCode(PurchaseLine);

        // [THEN] The returned location code is the Purchase Line Location
        Assert.AreEqual(Location.Code, CompLocationCode, 'Component Location Code should match Purchase Line Location');
    end;

    [Test]
    procedure TestGetComponentsLocationCode_Company()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        CompLocationCode: Code[10];
    begin
        // [SCENARIO] GetComponentsLocationCode returns Company Location when Setup is Company
        Initialize();

        // [GIVEN] Sub Management Setup "Subc. Default Comp. Location" is Company
        UpdateSubManagementSetup("Components at Location"::Company);

        // [GIVEN] Company Information has a Location
        LibraryWarehouse.CreateLocation(Location);
        UpdateCompanyInformation(Location.Code);

        // [WHEN] GetComponentsLocationCode is called
        CompLocationCode := SubcontractingMgmt.GetComponentsLocationCode(PurchaseLine);

        // [THEN] The returned location code is the Company Location
        Assert.AreEqual(Location.Code, CompLocationCode, 'Component Location Code should match Company Location');
    end;

    [Test]
    procedure TestGetComponentsLocationCode_Manufacturing()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        CompLocationCode: Code[10];
    begin
        // [SCENARIO] GetComponentsLocationCode returns Manufacturing Location when Setup is Manufacturing
        Initialize();

        // [GIVEN] Sub Management Setup "Subc. Default Comp. Location" is Manufacturing
        UpdateSubManagementSetup("Components at Location"::Manufacturing);

        // [GIVEN] Manufacturing Setup has a Location
        LibraryWarehouse.CreateLocation(Location);
        UpdateManufacturingSetup(Location.Code);

        // [GIVEN] A Purchase Line (Location doesn't matter)
        PurchaseLine.Init();

        // [WHEN] GetComponentsLocationCode is called
        CompLocationCode := SubcontractingMgmt.GetComponentsLocationCode(PurchaseLine);

        // [THEN] The returned location code is the Manufacturing Location
        Assert.AreEqual(Location.Code, CompLocationCode, 'Component Location Code should match Manufacturing Location');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure TestTransferOrderCreation_SameLocation()
    var
        Item: Record Item;
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
        TransitLocation: Record Location;
        Vendor: Record Vendor;
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
    begin
        // [SCENARIO] Transfer Order creation uses Origin Location if Component Location equals Subcontractor Location
        Initialize();

        // [GIVEN] Locations: Subcontractor and Original
        LibraryWarehouse.CreateLocation(LocationSub);
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location.Code, LocationSub.Code, TransitLocation.Code, '', '');

        // [GIVEN] Subcontracting Scenario Setup
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, LibraryRandom.RandInt(10), LocationSub.Code, Location.Code);

        // [WHEN] Running the Create Subcontracting Transfer Order report
        Commit(); // Report requires commit
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] Transfer Order is created from Origin Location to Subcontractor Location
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'Transfer Order should be created');
        Assert.AreEqual(Location.Code, TransferHeader."Transfer-from Code", 'Transfer-from Code should be Origin Location');
        Assert.AreEqual(LocationSub.Code, TransferHeader."Transfer-to Code", 'Transfer-to Code should be Subcontractor Location');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure DirectTransferFromRequireShipmentLocationWithoutRoute()
    var
        Item: Record Item;
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
    begin
        // [SCENARIO 648949] Without a transfer route, a require-shipment source uses Shipment and Receipt from Inventory Setup.
        Initialize();

        // [GIVEN] Subcontractor and Original locations; the Original location requires a shipment; no in-transit transfer route exists.
        LibraryWarehouse.CreateLocation(LocationSub);
        LibraryWarehouse.CreateLocation(Location);
        Location."Require Shipment" := true;
        Location.Modify(true);

        // [GIVEN] Inventory Setup posts direct transfers via Shipment and Receipt
        SetInventoryDirectTransferPostingType("Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Subcontracting Scenario Setup (component at the subcontractor location, original at the require-shipment location)
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, LibraryRandom.RandInt(10), LocationSub.Code, Location.Code);

        // [WHEN] Running the Create Subcontracting Transfer Order report
        Commit(); // Report requires commit
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] The transfer uses the original source location and the posting mode from Inventory Setup
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'A transfer order should be created without a transfer route.');
        TransferHeader.TestField("Transfer-from Code", Location.Code);
        TransferHeader.TestField("Transfer-to Code", LocationSub.Code);
        TransferHeader.TestField("Direct Transfer", true);
        TransferHeader.TestField("Direct Transfer Posting", "Direct Transfer Posting Type"::"Shipment and Receipt");
        TransferHeader.TestField("In-Transit Code", '');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,WarehouseMessageHandler')]
    procedure DirectTransferFromRequireShipmentLocationPostsShipmentAndReceipt()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 648949] A subcontracting component transfer posts shipment and receipt through a warehouse shipment.
        Initialize();
        Quantity := 10;

        // [GIVEN] A source location that only requires warehouse shipment
        // [GIVEN] A subcontractor location without warehouse requirements
        // [GIVEN] An explicit direct transfer route using Shipment and Receipt
        // [GIVEN] A subcontracting purchase order with a Transfer to Vendor component
        // [GIVEN] The full component quantity in inventory at the source
        CreateComponentWarehouseTransferSetup(PurchaseHeader, ProdOrderComp, Item, Location, LocationSub, Quantity);

        // [WHEN] The report creates the component transfer
        CreateDirectShipmentAndReceiptTransfer(PurchaseHeader, TransferHeader, TransferLine);

        // [THEN] The transfer has the component quantity, locations, and production context
        TransferHeader.TestField("Transfer-from Code", Location.Code);
        TransferHeader.TestField("Transfer-to Code", LocationSub.Code);
        TransferLine.TestField("Transfer WIP Item", false);
        TransferLine.TestField(Quantity, Quantity);
        TransferLine.TestField("Subc. Prod. Order No.", ProdOrderComp."Prod. Order No.");

        // [WHEN] The warehouse shipment is posted
        PostSubcontractingWarehouseShipment(TransferHeader);

        // [THEN] Shipment and receipt move the full component quantity to the subcontractor
        VerifyPostedShipmentAndReceipt(TransferLine, TransferShipmentLine, TransferReceiptLine);
        TransferShipmentLine.TestField("Quantity (Base)", Quantity);
        TransferReceiptLine.TestField("Quantity (Base)", Quantity);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(-Quantity, ItemLedgerEntry.Quantity, 'The full component quantity should leave the source.');
        ItemLedgerEntry.SetRange("Location Code", LocationSub.Code);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'The full component quantity should reach the subcontractor.');

        // [THEN] The component is at the subcontractor with nothing outstanding or in transit
        ProdOrderComp.Find();
        ProdOrderComp.TestField("Location Code", LocationSub.Code);
        ProdOrderComp.TestField("Subc. Original Location Code", Location.Code);
        ProdOrderComp.SetRange("Subc. Purchase Order Filter", PurchaseHeader."No.");
        ProdOrderComp.CalcFields("Subc. Qty.on TransOrder (Base)", "Subc. Qty. in Transit (Base)", "Subc. Qty. transf. to Subcontr");
        ProdOrderComp.TestField("Subc. Qty.on TransOrder (Base)", 0);
        ProdOrderComp.TestField("Subc. Qty. in Transit (Base)", 0);
        ProdOrderComp.TestField("Subc. Qty. transf. to Subcontr", Quantity);
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,WarehouseMessageHandler')]
    procedure DirectTransferFromRequirePickLocationPostsShipmentAndReceipt()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // [SCENARIO 648949] A subcontracting component transfer posts shipment and receipt through an inventory pick.
        Initialize();
        Quantity := 10;

        // [GIVEN] A bin-mandatory source location requiring only inventory picking
        // [GIVEN] A subcontractor location without warehouse requirements
        // [GIVEN] An explicit direct transfer route using Shipment and Receipt
        // [GIVEN] A subcontracting purchase order with a Transfer to Vendor component
        // [GIVEN] The full component quantity in the source bin
        CreateComponentInventoryPickSetup(PurchaseHeader, ProdOrderComp, Item, Location, LocationSub, Bin, Quantity);

        // [WHEN] The report creates the component transfer
        CreateDirectShipmentAndReceiptTransfer(PurchaseHeader, TransferHeader, TransferLine);

        // [THEN] The transfer has the component quantity, locations, and production context
        TransferHeader.TestField("Transfer-from Code", Location.Code);
        TransferHeader.TestField("Transfer-to Code", LocationSub.Code);
        TransferLine.TestField("Transfer WIP Item", false);
        TransferLine.TestField(Quantity, Quantity);
        TransferLine.TestField("Subc. Prod. Order No.", ProdOrderComp."Prod. Order No.");

        // [WHEN] An inventory pick is created and posted for the transfer
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(TransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Shipment and receipt move the full component quantity out of the source bin to the subcontractor
        VerifyPostedShipmentAndReceipt(TransferLine, TransferShipmentLine, TransferReceiptLine);
        TransferShipmentLine.TestField("Quantity (Base)", Quantity);
        TransferShipmentLine.TestField("Transfer-from Bin Code", Bin.Code);
        TransferReceiptLine.TestField("Quantity (Base)", Quantity);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(-Quantity, ItemLedgerEntry.Quantity, 'The full component quantity should leave the source.');
        ItemLedgerEntry.SetRange("Location Code", LocationSub.Code);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'The full component quantity should reach the subcontractor.');
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        Assert.AreEqual(0, WarehouseEntry."Qty. (Base)", 'No component quantity should remain in the source bin.');

        // [THEN] The component is at the subcontractor with nothing outstanding or in transit
        ProdOrderComp.Find();
        ProdOrderComp.TestField("Location Code", LocationSub.Code);
        ProdOrderComp.TestField("Subc. Original Location Code", Location.Code);
        ProdOrderComp.SetRange("Subc. Purchase Order Filter", PurchaseHeader."No.");
        ProdOrderComp.CalcFields("Subc. Qty.on TransOrder (Base)", "Subc. Qty. in Transit (Base)", "Subc. Qty. transf. to Subcontr");
        ProdOrderComp.TestField("Subc. Qty.on TransOrder (Base)", 0);
        ProdOrderComp.TestField("Subc. Qty. in Transit (Base)", 0);
        ProdOrderComp.TestField("Subc. Qty. transf. to Subcontr", Quantity);
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,WarehouseMessageHandler')]
    procedure DirectTransferFromDirectedWarehousePostsShipmentAndReceipt()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 648949] A subcontracting component transfer posts shipment and receipt after a directed warehouse pick.
        Initialize();
        Quantity := 10;

        // [GIVEN] A source location with Directed Put-away and Pick
        // [GIVEN] A subcontractor location without warehouse requirements
        // [GIVEN] An explicit direct transfer route using Shipment and Receipt
        // [GIVEN] A subcontracting purchase order with a Transfer to Vendor component
        // [GIVEN] The full component quantity in a pickable source bin
        CreateComponentDirectedWarehouseSetup(PurchaseHeader, ProdOrderComp, Item, Location, LocationSub, Bin, Quantity);

        // [WHEN] The report creates the component transfer
        CreateDirectShipmentAndReceiptTransfer(PurchaseHeader, TransferHeader, TransferLine);

        // [THEN] The transfer has the component quantity, locations, and production context
        TransferHeader.TestField("Transfer-from Code", Location.Code);
        TransferHeader.TestField("Transfer-to Code", LocationSub.Code);
        TransferLine.TestField("Transfer WIP Item", false);
        TransferLine.TestField(Quantity, Quantity);
        TransferLine.TestField("Subc. Prod. Order No.", ProdOrderComp."Prod. Order No.");

        // [WHEN] A warehouse shipment is created for the transfer
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentLine.SetRange("Source Type", Database::"Transfer Line");
        WarehouseShipmentLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        // [WHEN] The warehouse pick is created and registered
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Source Type", Database::"Transfer Line");
        WarehouseActivityLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseActivityLine.SetRange("Source Line No.", TransferLine."Line No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The full component quantity has been picked for the shipment
        WarehouseShipmentLine.Find();
        WarehouseShipmentLine.TestField("Qty. Picked", Quantity);

        // [WHEN] The warehouse shipment is posted
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Shipment and receipt move the full component quantity to the subcontractor
        VerifyPostedShipmentAndReceipt(TransferLine, TransferShipmentLine, TransferReceiptLine);
        TransferShipmentLine.TestField("Quantity (Base)", Quantity);
        TransferShipmentLine.TestField("Transfer-from Bin Code", Location."Shipment Bin Code");
        TransferReceiptLine.TestField("Quantity (Base)", Quantity);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(-Quantity, ItemLedgerEntry.Quantity, 'The full component quantity should leave the source.');
        ItemLedgerEntry.SetRange("Location Code", LocationSub.Code);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'The full component quantity should reach the subcontractor.');

        // [THEN] No component quantity remains in the pick or shipment bin
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        Assert.AreEqual(0, WarehouseEntry."Qty. (Base)", 'No component quantity should remain in the pick bin.');
        WarehouseEntry.SetRange("Bin Code", Location."Shipment Bin Code");
        WarehouseEntry.CalcSums("Qty. (Base)");
        Assert.AreEqual(0, WarehouseEntry."Qty. (Base)", 'No component quantity should remain in the shipment bin.');

        // [THEN] The component is at the subcontractor with nothing outstanding or in transit
        ProdOrderComp.Find();
        ProdOrderComp.TestField("Location Code", LocationSub.Code);
        ProdOrderComp.TestField("Subc. Original Location Code", Location.Code);
        ProdOrderComp.SetRange("Subc. Purchase Order Filter", PurchaseHeader."No.");
        ProdOrderComp.CalcFields("Subc. Qty.on TransOrder (Base)", "Subc. Qty. in Transit (Base)", "Subc. Qty. transf. to Subcontr");
        ProdOrderComp.TestField("Subc. Qty.on TransOrder (Base)", 0);
        ProdOrderComp.TestField("Subc. Qty. in Transit (Base)", 0);
        ProdOrderComp.TestField("Subc. Qty. transf. to Subcontr", Quantity);
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder,WarehouseMessageHandler')]
    procedure DirectWIPTransferFromRequireShipmentLocationWithoutRoute()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        Quantity: Decimal;
    begin
        // [SCENARIO 640958] A WIP-only transfer without a route posts from a require-shipment location using Shipment and Receipt.
        Initialize();
        Quantity := 10;

        // [GIVEN] A source location that only requires warehouse shipment
        // [GIVEN] A subcontractor location without warehouse requirements
        // [GIVEN] No transfer route and Inventory Setup using Shipment and Receipt
        // [GIVEN] A subcontracting purchase order with WIP to transfer and no component transfers
        CreateWIPWarehouseTransferSetup(PurchaseHeader, ProdOrder, Item, Location, LocationSub, Quantity);

        // [WHEN] The report creates the WIP transfer
        CreateDirectShipmentAndReceiptTransfer(PurchaseHeader, TransferHeader, TransferLine);

        // [THEN] The transfer has the WIP quantity, locations, and production context
        TransferHeader.TestField("Transfer-from Code", Location.Code);
        TransferHeader.TestField("Transfer-to Code", LocationSub.Code);
        TransferLine.TestField("Transfer WIP Item", true);
        TransferLine.TestField(Quantity, Quantity);
        TransferLine.TestField("Subc. Prod. Order No.", ProdOrder."No.");

        // [WHEN] The warehouse shipment is posted
        PostSubcontractingWarehouseShipment(TransferHeader);

        // [THEN] Shipment and receipt move WIP without creating physical inventory entries
        VerifyPostedShipmentAndReceipt(TransferLine, TransferShipmentLine, TransferReceiptLine);
        TransferShipmentLine.TestField("Quantity (Base)", 0);
        TransferReceiptLine.TestField("Quantity (Base)", 0);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(ItemLedgerEntry);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseEntry);
        WIPLedgerEntry.SetRange("Prod. Order Status", ProdOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrder."No.");
        WIPLedgerEntry.SetRange("Location Code", LocationSub.Code);
        WIPLedgerEntry.SetRange("In Transit", false);
        WIPLedgerEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(Quantity, WIPLedgerEntry."Quantity (Base)", 'The received WIP quantity should be at the subcontractor.');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure DirectTransferFromRequireShipmentLocationAllowedWithDirectTransferPosting()
    var
        Item: Record Item;
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
    begin
        // [SCENARIO 640958] A require-shipment source still supports one-step Direct Transfer posting from Inventory Setup.
        Initialize();

        // [GIVEN] Subcontractor and Original locations; the Original location requires a shipment; no in-transit route exists.
        LibraryWarehouse.CreateLocation(LocationSub);
        LibraryWarehouse.CreateLocation(Location);
        Location."Require Shipment" := true;
        Location.Modify(true);

        // [GIVEN] Inventory Setup posts direct transfers via Direct Transfer
        SetInventoryDirectTransferPostingType("Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Subcontracting Scenario Setup
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, LibraryRandom.RandInt(10), LocationSub.Code, Location.Code);

        // [WHEN] Running the Create Subcontracting Transfer Order report
        Commit(); // Report requires commit
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] A direct transfer order is created (not blocked)
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'A transfer order should be created when Inventory Setup uses Direct Transfer posting.');
        Assert.IsTrue(TransferHeader."Direct Transfer", 'The created transfer order should be a direct transfer.');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure InTransitRouteWithDirectTransferUsesInTransitCode()
    var
        Item: Record Item;
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
        TransitLocation: Record Location;
        Vendor: Record Vendor;
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
    begin
        // [SCENARIO 640958] A transfer route flagged Direct Transfer with Shipment and Receipt posting and an In-Transit
        //                 Code creates a transfer order that keeps the Direct Transfer flag, the posting type, and the In-Transit Code.
        Initialize();

        // [GIVEN] Subcontractor and Original locations and an in-transit location
        LibraryWarehouse.CreateLocation(LocationSub);
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);

        // [GIVEN] Inventory Setup posts direct transfers via Shipment and Receipt
        SetInventoryDirectTransferPostingType("Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] A transfer route from Original to Subcontractor with an In-Transit Code, flagged Direct Transfer (Shipment and Receipt posting)
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location.Code, LocationSub.Code, TransitLocation.Code, '', '');
        TransferRoute.Validate("Direct Transfer", true);
        TransferRoute.Modify(true);

        // [GIVEN] Subcontracting Scenario Setup
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, LibraryRandom.RandInt(10), LocationSub.Code, Location.Code);

        // [WHEN] Running the Create Subcontracting Transfer Order report
        Commit(); // Report requires commit
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] The transfer order keeps the route's Direct Transfer flag, Shipment and Receipt posting, and In-Transit Code
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'A transfer order should be created.');
        Assert.IsTrue(TransferHeader."Direct Transfer", 'The created transfer order should keep the route''s Direct Transfer flag.');
        Assert.AreEqual(
            "Direct Transfer Posting Type"::"Shipment and Receipt", TransferHeader."Direct Transfer Posting",
            'The transfer order should keep the route''s Direct Transfer Posting.');
        Assert.AreEqual(TransitLocation.Code, TransferHeader."In-Transit Code", 'The transfer order should keep the route''s In-Transit Code.');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure TestTransferOrderCreation_PostAndRecreate()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        LocationSub: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
        TransitLocation: Record Location;
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
        QtyFirstTransfer: Decimal;
        QtyRemaining: Decimal;
        QtyTotal: Decimal;
    begin
        // [SCENARIO] Create Transfer Order, reduce quantity, post, and create new Transfer Order for remaining
        Initialize();

        QtyTotal := 10;
        QtyFirstTransfer := 4;
        QtyRemaining := QtyTotal - QtyFirstTransfer;

        // [GIVEN] Locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSub);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location.Code, LocationSub.Code, TransitLocation.Code, '', '');


        // [GIVEN] Subcontracting Scenario Setup
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, QtyTotal, Location.Code, '');

        // [GIVEN] Inventory for the component at Origin Location (needed for posting transfer)
        LibraryInventory.CreateItemJournalLineInItemTemplate(
            ItemJournalLine, Item."No.", Location.Code, '', QtyTotal);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Running the Create Subcontracting Transfer Order report (1st time)
        Commit();
        Clear(CreateSubCTransfOrder);
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] Transfer Order 1 is created for full quantity
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'Transfer Order 1 should be created');

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        Assert.AreEqual(QtyTotal, TransferLine.Quantity, 'Initial Transfer Quantity should be total quantity');

        // [WHEN] Reduce Quantity on Transfer Order and Post
        TransferLine.Validate(Quantity, QtyFirstTransfer);
        TransferLine.Modify();
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true); // Ship and Receive

        // [WHEN] Running the Create Subcontracting Transfer Order report (2nd time)
        Commit();
        Clear(CreateSubCTransfOrder);
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] Transfer Order 2 is created for remaining quantity
        TransferHeader.Reset();
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open); // Find the new open one
        Assert.IsTrue(TransferHeader.FindFirst(), 'Transfer Order 2 should be created');

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        Assert.AreEqual(QtyRemaining, TransferLine.Quantity, 'Second Transfer Quantity should be remaining quantity');
    end;

    [Test]
    [HandlerFunctions('ConfirmCreateSubcOrderAnyway_No')]
    procedure CreateSubcOrderFromRtngLine_BlankCompLocation_UserDeclines()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        NoOfCreatedPurchOrder: Integer;
    begin
        // [SCENARIO] Bug 633228: When a Transfer-type Prod. Order Component has a blank Location Code,
        // creating a Subcontracting Order from the routing line raises a confirmation. If the user
        // declines, no Purchase Order is created.

        // [GIVEN] Manufacturing setup with subcontracting work center, item, and Transfer-type BOM line
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5, '');
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Transfer-type Prod. Order Component has a blank Location Code
        SetTransferProdOrderCompLocationCode(ProductionOrder."No.", '');

        // [WHEN] Create Subcontracting Order from Prod. Order Routing; the user declines the "anyway" confirmation
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        NoOfCreatedPurchOrder := SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine);

        // [THEN] No Purchase Order is created
        Assert.AreEqual(0, NoOfCreatedPurchOrder, 'No Purchase Order should be created when user declines.');
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.RecordIsEmpty(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmCreateSubcOrderAnyway_No')]
    procedure CreateSubcOrderFromRtngLine_CompLocationEqualsSubcLocation_UserDeclines()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        NoOfCreatedPurchOrder: Integer;
    begin
        // [SCENARIO] Bug 633228: When a Transfer-type Prod. Order Component has Location Code equal to
        // the vendor's Subcontracting Location Code, creating a Subcontracting Order from the routing
        // line raises a confirmation. If the user declines, no Purchase Order is created.

        // [GIVEN] Manufacturing setup with subcontracting work center, item, and Transfer-type BOM line
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5, '');
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Transfer-type Prod. Order Component Location Code equals the vendor's Subcontracting Location Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SetTransferProdOrderCompLocationCode(ProductionOrder."No.", Vendor."Subc. Location Code");

        // [WHEN] Create Subcontracting Order from Prod. Order Routing; the user declines the "anyway" confirmation
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        NoOfCreatedPurchOrder := SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine);

        // [THEN] No Purchase Order is created
        Assert.AreEqual(0, NoOfCreatedPurchOrder, 'No Purchase Order should be created when user declines.');
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.RecordIsEmpty(PurchaseLine);
    end;

    [Test]
    procedure ValidateVendorSubcontrLocationCode_BinMandatoryLocation_RaisesError()
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        // [SCENARIO 633208] Setting Vendor."Subcontr. Location Code" to a Bin Mandatory location raises an error immediately
        Initialize();

        // [GIVEN] A location with Bin Mandatory enabled
        LibraryWarehouse.CreateLocation(Location);
        Location."Bin Mandatory" := true;
        Location.Modify(true);

        // [GIVEN] A vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] / [THEN] Validating "Subc. Location Code" to a Bin Mandatory location raises an error immediately
        asserterror Vendor.Validate("Subc. Location Code", Location.Code);
        Assert.ExpectedError('Bin Mandatory');
    end;

    [Test]
    procedure ValidatePurchHeaderSubcLocationCode_BinMandatoryLocation_RaisesError()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 633208] Setting PurchaseHeader."Subc. Location Code" to a Bin Mandatory location raises an error immediately
        Initialize();

        // [GIVEN] A location with Bin Mandatory enabled
        LibraryWarehouse.CreateLocation(Location);
        Location."Bin Mandatory" := true;
        Location.Modify(true);

        // [GIVEN] A Purchase Header
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");

        // [WHEN] / [THEN] Validating "Subc. Location Code" to a Bin Mandatory location raises an error immediately
        asserterror PurchaseHeader.Validate("Subc. Location Code", Location.Code);
        Assert.ExpectedError('Bin Mandatory');
    end;

    [Test]
    procedure CreateSubcOrderFromRtngLineUsesProdOrderLineLocation()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        WorkCenterLocation: Record Location;
    begin
        // [SCENARIO 635072] Creating a Subcontracting Order from a routing line uses the Prod. Order Line location, not the Work Center location.
        Initialize();

        // [GIVEN] A subcontracting work center with a Location Code
        LibraryWarehouse.CreateLocation(WorkCenterLocation);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        WorkCenter[2]."Location Code" := WorkCenterLocation.Code;
        WorkCenter[2]."Open Shop Floor Bin Code" := '';
        WorkCenter[2].Modify();

        // [GIVEN] A released production order whose location differs from the work center location
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5, '');
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Creating the subcontracting order from the routing line
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [THEN] The purchase line uses the Prod. Order Line location, not the Work Center location
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        Assert.AreEqual(
          ProdOrderLine."Location Code", PurchaseLine."Location Code",
          'Subcontracting order must use the Prod. Order Line location.');
        Assert.AreNotEqual(
          WorkCenter[2]."Location Code", PurchaseLine."Location Code",
          'Subcontracting order must not use the Work Center location.');
    end;

    local procedure CreateComponentWarehouseTransferSetup(var PurchaseHeader: Record "Purchase Header"; var ProdOrderComp: Record "Prod. Order Component"; var Item: Record Item; var Location: Record Location; var LocationSub: Record Location; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        CreateComponentTransferSetup(PurchaseHeader, ProdOrderComp, Item, Location, LocationSub, Quantity);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateComponentInventoryPickSetup(var PurchaseHeader: Record "Purchase Header"; var ProdOrderComp: Record "Prod. Order Component"; var Item: Record Item; var Location: Record Location; var LocationSub: Record Location; var Bin: Record Bin; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'PICK', '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);
        CreateComponentTransferSetup(PurchaseHeader, ProdOrderComp, Item, Location, LocationSub, Quantity);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateComponentDirectedWarehouseSetup(var PurchaseHeader: Record "Purchase Header"; var ProdOrderComp: Record "Prod. Order Component"; var Item: Record Item; var Location: Record Location; var LocationSub: Record Location; var Bin: Record Bin; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 5);
        LibraryWarehouse.FindBin(Bin, Location.Code, 'PICK', 1);
        CreateComponentTransferSetup(PurchaseHeader, ProdOrderComp, Item, Location, LocationSub, Quantity);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", Quantity, false);
    end;

    local procedure CreateComponentTransferSetup(var PurchaseHeader: Record "Purchase Header"; var ProdOrderComp: Record "Prod. Order Component"; var Item: Record Item; Location: Record Location; var LocationSub: Record Location; Quantity: Decimal)
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        TransferRoute: Record "Transfer Route";
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSub);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        SetInventoryDirectTransferPostingType("Direct Transfer Posting Type"::"Shipment and Receipt");
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location.Code, LocationSub.Code, '', '', '');
        TransferRoute.Validate("Direct Transfer", true);
        TransferRoute.Validate("Direct Transfer Posting", "Direct Transfer Posting Type"::"Shipment and Receipt");
        TransferRoute.Modify(true);

        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, Quantity, Location.Code, '');
    end;

    local procedure CreateWIPWarehouseTransferSetup(var PurchaseHeader: Record "Purchase Header"; var ProdOrder: Record "Production Order"; var Item: Record Item; var Location: Record Location; var LocationSub: Record Location; Quantity: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSub);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        SetInventoryDirectTransferPostingType("Direct Transfer Posting Type"::"Shipment and Receipt");
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, Quantity, Location.Code, '');
        ProdOrderComp.Delete(true);
        ProdOrderRtngLine."Transfer WIP Item" := true;
        ProdOrderRtngLine.Modify();
    end;

    local procedure CreateDirectShipmentAndReceiptTransfer(PurchaseHeader: Record "Purchase Header"; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
    begin
        Commit();
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.AreEqual(1, TransferHeader.Count(), 'Exactly one subcontracting transfer should be created.');
        TransferHeader.FindFirst();
        TransferHeader.TestField("Direct Transfer", true);
        TransferHeader.TestField("Direct Transfer Posting", "Direct Transfer Posting Type"::"Shipment and Receipt");
        TransferHeader.TestField("In-Transit Code", '');
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        Assert.AreEqual(1, TransferLine.Count(), 'The transfer should contain exactly one line.');
        TransferLine.FindFirst();
    end;

    local procedure VerifyPostedShipmentAndReceipt(TransferLine: Record "Transfer Line"; var TransferShipmentLine: Record "Transfer Shipment Line"; var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
#pragma warning disable AA0210
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferLine."Document No.");
#pragma warning restore AA0210
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.Get(TransferShipmentHeader."No.", TransferLine."Line No.");
        TransferShipmentLine.TestField(Quantity, TransferLine.Quantity);
        TransferShipmentLine.TestField("Transfer WIP Item", TransferLine."Transfer WIP Item");
        TransferShipmentLine.TestField("Subc. Purch. Order No.", TransferLine."Subc. Purch. Order No.");
#pragma warning disable AA0210
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferLine."Document No.");
#pragma warning restore AA0210
        TransferReceiptHeader.FindFirst();
        TransferReceiptLine.Get(TransferReceiptHeader."No.", TransferLine."Line No.");
        TransferReceiptLine.TestField(Quantity, TransferLine.Quantity);
        TransferReceiptLine.TestField("Transfer WIP Item", TransferLine."Transfer WIP Item");
        TransferReceiptLine.TestField("Subc. Purch. Order No.", TransferLine."Subc. Purch. Order No.");
    end;

    local procedure PostSubcontractingWarehouseShipment(var TransferHeader: Record "Transfer Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentLine.SetRange("Source Type", Database::"Transfer Line");
        WarehouseShipmentLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure UpdateSubManagementSetup(ComponentAtLocation: Enum "Components at Location")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;
        ManufacturingSetup."Subc. Default Comp. Location" := ComponentAtLocation;
        ManufacturingSetup.Modify();
    end;

    local procedure UpdateManufacturingSetup(LocationCode: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Components at Location" := LocationCode;
        ManufacturingSetup.Modify();
    end;

    local procedure UpdateCompanyInformation(LocationCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Location Code" := LocationCode;
        CompanyInformation.Modify();
    end;

    local procedure CreateSubcontractingSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var Vendor: Record Vendor; var LocationSub: Record Location; var Item: Record Item; Qty: Decimal; CompLocationCode: Code[10]; CompOrigLocationCode: Code[10])
    var
        RoutingLink: Record "Routing Link";
    begin
        if Vendor."No." = '' then begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor."Subc. Location Code" := LocationSub.Code;
            Vendor.Modify();
        end;

        LibraryInventory.CreateItem(Item);

        LibraryManufacturing.CreateProductionOrder(ProdOrder, "Production Order Status"::Released, ProdOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrder.Status, ProdOrder."No.", Item."No.", '', CompLocationCode, Qty);

        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComp, ProdOrder.Status, ProdOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComp.Validate("Item No.", Item."No.");
        ProdOrderComp.Validate(Quantity, Qty);
        ProdOrderComp.Validate("Quantity per", 1);
        ProdOrderComp."Location Code" := CompLocationCode;
        if CompOrigLocationCode <> '' then
            ProdOrderComp."Subc. Original Location Code" := CompOrigLocationCode;
        ProdOrderComp."Component Supply Method" := ProdOrderComp."Component Supply Method"::"Transfer to Vendor";
        ProdOrderComp."Routing Link Code" := RoutingLink.Code;
        ProdOrderComp.Modify();

        CreateProdOrderRoutingLine(ProdOrderRtngLine, ProdOrder, ProdOrderLine, RoutingLink.Code);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, Item."No.", Qty);
        PurchaseLine."Prod. Order No." := ProdOrder."No.";
        PurchaseLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        PurchaseLine."Routing No." := ProdOrderRtngLine."Routing No.";
        PurchaseLine."Operation No." := ProdOrderRtngLine."Operation No.";
        PurchaseLine."Routing Reference No." := ProdOrderRtngLine."Routing Reference No.";
        // Mirror SetSubcontractingLineType() since fields are assigned directly (no Validate trigger).
        // The single routing line created here is the last operation, so the type is LastOperation.
        PurchaseLine."Subc. Purchase Line Type" := PurchaseLine."Subc. Purchase Line Type"::LastOperation;
        PurchaseLine.Modify();
    end;

    local procedure CreateProdOrderRoutingLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderRtngLine.FindLast() then
            OperationNo := IncStr(ProdOrderRtngLine."Operation No.")
        else
            OperationNo := '10';

        ProdOrderRtngLine.Init();
        ProdOrderRtngLine.Status := ProdOrder.Status;
        ProdOrderRtngLine."Prod. Order No." := ProdOrder."No.";
        ProdOrderRtngLine."Routing Reference No." := ProdOrderLine."Line No.";
        ProdOrderRtngLine."Operation No." := OperationNo;
        ProdOrderRtngLine."Routing Link Code" := RoutingLinkCode;
        ProdOrderRtngLine.Insert();
    end;

    local procedure UpdateProdBomWithComponentSupplyMethod(Item: Record Item; ComponentSupplyMethod: Enum "Component Supply Method")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine."Component Supply Method" := ComponentSupplyMethod;
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateVendorWithSubcontractingLocationCode(WorkCenter: Record "Work Center")
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
    end;

    local procedure SetTransferProdOrderCompLocationCode(ProdOrderNo: Code[20]; LocationCode: Code[10])
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        ProdOrderComp."Location Code" := LocationCode;
        ProdOrderComp.Modify();
    end;

    [ConfirmHandler]
    procedure ConfirmCreateSubcOrderAnyway_No(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(CreateSubcontractingOrderAnywayQst, Question);
        Reply := false;
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
    end;

    [MessageHandler]
    procedure WarehouseMessageHandler(Message: Text[1024])
    begin
    end;

    local procedure SetInventoryDirectTransferPostingType(PostingType: Enum "Direct Transfer Posting Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting Type", PostingType);
        InventorySetup.Modify(true);
    end;
}