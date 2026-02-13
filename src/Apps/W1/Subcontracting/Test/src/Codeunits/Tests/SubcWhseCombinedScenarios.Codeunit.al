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
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 140006 "Subc. Whse Combined Scenarios"
{
    // [FEATURE] Subcontracting Warehouse Combined Scenarios Tests
    Subtype = Test;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Combined Scenarios");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Combined Scenarios");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Combined Scenarios");
    end;

    [Test]
    procedure ProdOrderWithLastAndIntermediateOperationsSameVendor()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
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
        Quantity: Decimal;
    begin
        // [SCENARIO] Prod. Order with Last and Intermediate Operations (Same Vendor)
        // [FEATURE] Subcontracting Warehouse Combined Scenarios

        // [GIVEN] Complete Manufacturing Setup with Work Centers, Machine Centers, and Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting - both with same vendor
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Links for both operations
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);

        // [GIVEN] Create Location with Warehouse Handling and Bin Mandatory (Require Receive, Put-away, Bin Mandatory)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Create Warehouse Employee for the location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Configure Vendor with Subcontracting Location
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Orders via Subcontracting Worksheet
        // The worksheet approach combines all lines for the same vendor into one Purchase Order
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);

        // [THEN] Verify Data Consistency: Both operations should be on the same PO (same vendor)
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        Assert.RecordCount(PurchaseLine, 2);

        // [THEN] Verify Purchase Line links to Production Order
        PurchaseLine.FindSet();
        repeat
            Assert.AreEqual(ProductionOrder."No.", PurchaseLine."Prod. Order No.", 'Purchase Line should link to Production Order');
            Assert.AreEqual(Item."Routing No.", PurchaseLine."Routing No.", 'Purchase Line should have correct Routing No.');
        until PurchaseLine.Next() = 0;

        // [WHEN] Create single Warehouse Receipt using "Get Source Documents" to include both lines
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateWarehouseReceiptUsingGetSourceDocuments(WarehouseReceiptHeader, Location.Code);

        // [GIVEN] Set Bin Code on warehouse receipt lines (Get Source Documents doesn't auto-fill like CreateWhseReceiptFromPO)
        SetBinCodeOnWarehouseReceiptLines(WarehouseReceiptHeader, ReceiveBin.Code);

        // [THEN] Verify Data Consistency: Single warehouse receipt created for both lines from same PO
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseReceiptLine, 2);

        // [THEN] Verify Data Consistency: Identify intermediate and last operation lines
        WarehouseReceiptLine.SetRange("Subc. Purchase Line Type", WarehouseReceiptLine."Subc. Purchase Line Type"::NotLastOperation);
        Assert.RecordCount(WarehouseReceiptLine, 1);
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(Item."No.", WarehouseReceiptLine."Item No.", 'Intermediate operation line should have correct item');

        // [THEN] Verify NotLastOperation has zero base quantities (no inventory movement)
        Assert.AreEqual(0, WarehouseReceiptLine."Qty. (Base)", 'NotLastOperation should have zero Qty. (Base)');
        Assert.AreEqual(0, WarehouseReceiptLine."Qty. per Unit of Measure", 'NotLastOperation should have zero Qty. per UoM');

        WarehouseReceiptLine.SetRange("Subc. Purchase Line Type", "Subc. Purchase Line Type"::LastOperation);
        Assert.RecordCount(WarehouseReceiptLine, 1);
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(Item."No.", WarehouseReceiptLine."Item No.", 'Last operation line should have correct item');

        // [THEN] Verify LastOperation has populated base quantities
        Assert.AreEqual(Quantity, WarehouseReceiptLine."Qty. (Base)", 'LastOperation should have correct Qty. (Base)');
        Assert.IsTrue(WarehouseReceiptLine."Qty. per Unit of Measure" > 0, 'LastOperation should have Qty. per UoM > 0');

        // [WHEN] Post warehouse receipt for both lines
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [THEN] Verify Posted Entries: Posted warehouse receipt created
        Assert.AreNotEqual('', PostedWhseReceiptHeader."No.", 'Posted warehouse receipt should be created');

        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(PostedWhseReceiptLine, 2);

        // [THEN] Verify Bin Management: Put-away can only be created for last operation line (Take and Place)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [THEN] Verify Data Consistency: Take line exists with correct bin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(ReceiveBin.Code, WarehouseActivityLine."Bin Code", 'Take line should use receive bin');
        Assert.AreEqual(Quantity, WarehouseActivityLine."Qty. (Base)", 'Take line should have correct quantity');

        // [THEN] Verify Data Consistency: Place line exists with correct bin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(PutAwayBin.Code, WarehouseActivityLine."Bin Code", 'Place line should use put-away bin');
        Assert.AreEqual(Quantity, WarehouseActivityLine."Qty. (Base)", 'Place line should have correct quantity');

        // [WHEN] Post the put-away
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify Posted Entries: All ledger entries correct for both operations
        VerifyLedgerEntriesForCombinedScenario(Item."No.", Quantity, Location.Code);
    end;

    [Test]
    procedure ProdOrderWithMultipleOperationsDifferentVendors()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader1: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptHeader2: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader1: Record "Warehouse Receipt Header";
        WarehouseReceiptHeader2: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Prod. Order with Multiple Operations (Different Vendors)
        // [FEATURE] Subcontracting Warehouse Combined Scenarios

        // [GIVEN] Complete Manufacturing Setup with Work Centers, Machine Centers, and Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(15, 25);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting - different vendors
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Links for both operations
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);

        // [GIVEN] Create Location with Warehouse Handling and Bin Mandatory (Require Receive, Put-away, Bin Mandatory)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Create Warehouse Employee for the location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Configure Vendors with Subcontracting Location
        Vendor1.Get(WorkCenter[1]."Subcontractor No.");
        Vendor1."Subcontr. Location Code" := Location.Code;
        Vendor1."Location Code" := Location.Code;
        Vendor1.Modify();

        Vendor2.Get(WorkCenter[2]."Subcontractor No.");
        Vendor2."Subcontr. Location Code" := Location.Code;
        Vendor2."Location Code" := Location.Code;
        Vendor2.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Orders via Subcontracting Worksheet
        // The worksheet creates one PO per vendor
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader1);

        // [THEN] Find both Purchase Headers - different vendors will have separate POs
        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.SetRange("Buy-from Vendor No.", Vendor1."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader1.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseLine.SetRange("Buy-from Vendor No.", Vendor2."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [THEN] Verify Data Consistency: Separate POs for different vendors
        Assert.AreNotEqual(PurchaseHeader1."No.", PurchaseHeader2."No.", 'Different vendors should have separate Purchase Orders');

        Assert.AreNotEqual(PurchaseHeader1."Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No.", 'Purchase Orders should have different vendors');

        // [WHEN] Create separate Warehouse Receipts for each PO
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader1, WarehouseReceiptHeader1);
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader2, WarehouseReceiptHeader2);

        // [THEN] Verify Data Consistency: Separate warehouse documents for each vendor
        Assert.AreNotEqual(WarehouseReceiptHeader1."No.", WarehouseReceiptHeader2."No.", 'Separate warehouse receipts should be created for different vendors');

        // [THEN] Verify Data Consistency: Each warehouse receipt has correct vendor info
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader1."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(PurchaseHeader1."No.", WarehouseReceiptLine."Source No.", 'First warehouse receipt should link to first PO');

        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader2."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(PurchaseHeader2."No.", WarehouseReceiptLine."Source No.", 'Second warehouse receipt should link to second PO');

        // [WHEN] Post both warehouse receipts independently
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader1, PostedWhseReceiptHeader1);
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader2, PostedWhseReceiptHeader2);

        // [THEN] Verify Posted Entries: All documents processed correctly and independently
        Assert.AreNotEqual('', PostedWhseReceiptHeader1."No.", 'First posted warehouse receipt should be created');
        Assert.AreNotEqual('', PostedWhseReceiptHeader2."No.", 'Second posted warehouse receipt should be created');

        // [THEN] Verify Bin Management: Put-away created only for last operation (Take and Place lines)
        // Only the last operation creates physical inventory movement and warehouse activity lines
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        // Should have Take and Place lines for last operation only (1 vendor x 2 lines = 2 total)
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [THEN] Verify Data Consistency: Take line exists
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [THEN] Verify Data Consistency: Place line exists
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [WHEN] Post both put-aways (get distinct warehouse activity headers)
        WarehouseActivityLine.SetRange("Action Type");
        if WarehouseActivityLine.FindFirst() then begin
            WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        end;

        // Find second put-away if it exists (different warehouse activity number)
        WarehouseActivityLine.SetFilter("No.", '<>%1', WarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindFirst() then begin
            WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        end;

        // [THEN] Verify Data Consistency: All ledger entries correct for both vendors
        VerifyLedgerEntriesForMultiVendorScenario(Item."No.", Quantity, Location.Code);
    end;

    [Test]
    procedure WhseReceiptCreationWithGetSourceDocumentsMultipleProdOrders()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity1: Decimal;
        Quantity2: Decimal;
    begin
        // [SCENARIO] WH Receipt Creation with "Get Source Documents"
        // [FEATURE] Subcontracting Warehouse Combined Scenarios

        // [GIVEN] Complete Manufacturing Setup with Work Centers, Machine Centers, and Item
        Initialize();
        Quantity1 := LibraryRandom.RandIntInRange(10, 15);
        Quantity2 := LibraryRandom.RandIntInRange(15, 20);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting - same vendor
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link for last operation
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling and Bin Mandatory (Require Receive, Put-away, Bin Mandatory)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Create Warehouse Employee for the location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Configure Vendor with Subcontracting Location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create multiple Production Orders
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder1, "Production Order Status"::Released,
            ProductionOrder1."Source Type"::Item, Item."No.", Quantity1, Location.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder2, "Production Order Status"::Released,
            ProductionOrder2."Source Type"::Item, Item."No.", Quantity2, Location.Code);

        // [WHEN] Create Subcontracting Purchase Orders via Subcontracting Worksheet
        // The worksheet combines all lines for the same vendor into one PO
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder1."No.", PurchaseHeader);

        // [THEN] Verify Data Consistency: Both prod orders should create lines on the same PO (same vendor)
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        Assert.RecordCount(PurchaseLine, 2);

        // [WHEN] Use "Get Source Documents" function to create warehouse receipt
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateWarehouseReceiptUsingGetSourceDocuments(WarehouseReceiptHeader, Location.Code);

        // [GIVEN] Set Bin Code on warehouse receipt lines (Get Source Documents doesn't auto-fill like CreateWhseReceiptFromPO)
        SetBinCodeOnWarehouseReceiptLines(WarehouseReceiptHeader, ReceiveBin.Code);

        // [THEN] Verify Data Consistency: Warehouse receipt created with lines from the PO
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseReceiptLine, 2);

        // [THEN] Verify Data Consistency: Lines from the combined PO
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseReceiptLine, 2);

        // [THEN] Verify Data Consistency: Each line has correct data reconciled with original source
        WarehouseReceiptLine.SetRange("Source No.");
        WarehouseReceiptLine.FindSet();
        repeat
            VerifyWarehouseReceiptLineDetails(WarehouseReceiptLine, Item, PurchaseHeader."No.");
        until WarehouseReceiptLine.Next() = 0;

        // [WHEN] Post warehouse receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [THEN] Verify Posted Entries: Subsequent processing correct for each line
        Assert.AreNotEqual('', PostedWhseReceiptHeader."No.", 'Posted warehouse receipt should be created');

        // [THEN] Verify Data Consistency: All ledger entries correct
        VerifyLedgerEntriesForGetSourceDocuments(Item."No.", Location.Code);
    end;

    local procedure VerifyPurchaseLineQuantityBase(PurchaseLine: Record "Purchase Line")
    begin
        //Check real quantity base
        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::LastOperation then begin
            Assert.IsTrue(PurchaseLine."Quantity (Base)" > 0, 'LastOperation Purchase Line should have Quantity (Base) > 0');
            Assert.IsTrue(PurchaseLine."Qty. per Unit of Measure" > 0, 'LastOperation Purchase Line should have Qty. per UoM > 0');
        end else begin
            Assert.AreEqual(0, PurchaseLine."Quantity (Base)", 'NotLastOperation Purchase Line should have zero Quantity (Base)');
            Assert.AreEqual(0, PurchaseLine."Qty. per Unit of Measure", 'NotLastOperation Purchase Line should have zero Qty. per UoM');
        end;
    end;

    local procedure VerifyWarehouseReceiptLineDetails(WarehouseReceiptLine: Record "Warehouse Receipt Line"; Item: Record Item; PurchaseHeaderNo: Code[20])
    begin
        Assert.AreEqual(Item."No.", WarehouseReceiptLine."Item No.", 'Warehouse Receipt Line should have correct item');
        Assert.IsTrue(WarehouseReceiptLine.Quantity > 0, 'Warehouse Receipt Line should have positive quantity');

        // Verify Source Type and Source No.
        Assert.AreEqual(Database::"Purchase Line", WarehouseReceiptLine."Source Type", 'Source Type should be Purchase Line');
        Assert.AreEqual(PurchaseHeaderNo, WarehouseReceiptLine."Source No.", 'Source No. should match Purchase Header No.');

        // Verify Qty. (Base) and Qty. per Unit of Measure based on operation type
        if WarehouseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::LastOperation then begin
            Assert.IsTrue(WarehouseReceiptLine."Qty. (Base)" > 0, 'LastOperation should have Qty. (Base) > 0');
            Assert.IsTrue(WarehouseReceiptLine."Qty. per Unit of Measure" > 0, 'LastOperation should have Qty. per UoM > 0');
        end else begin
            Assert.AreEqual(0, WarehouseReceiptLine."Qty. (Base)", 'NotLastOperation should have zero Qty. (Base)');
            Assert.AreEqual(0, WarehouseReceiptLine."Qty. per Unit of Measure", 'NotLastOperation should have zero Qty. per UoM');
        end;
    end;

    local procedure VerifyLedgerEntriesForCombinedScenario(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        WarehouseEntry: Record Microsoft.Warehouse.Ledger."Warehouse Entry";
    begin
        // Verify Item Ledger Entries and Quantity (Base)
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry total Quantity should equal expected quantity');

        // Verify Capacity Ledger Entries and Output Quantity
        CapacityLedgerEntry.SetRange("Item No.", ItemNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntry.CalcSums("Output Quantity");
        Assert.AreEqual(2 * Quantity, CapacityLedgerEntry."Output Quantity" / CapacityLedgerEntry."Qty. per Unit of Measure", 'Capacity Ledger Entry Output Quantity should equal expected quantity');

        // Verify Warehouse Entries exist (for Put-away scenarios - only for last operation lines)
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        Assert.RecordIsNotEmpty(WarehouseEntry);
    end;

    local procedure VerifyLedgerEntriesForMultiVendorScenario(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Verify Item Ledger Entries and Quantity (Base)
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Item Ledger Entry total Quantity should equal expected quantity');

        // Verify Capacity Ledger Entries and Output Quantity
        CapacityLedgerEntry.SetRange("Item No.", ItemNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);
        CapacityLedgerEntry.CalcSums("Output Quantity");
        Assert.AreEqual(2 * Quantity, CapacityLedgerEntry."Output Quantity", 'Capacity Ledger Entry Output Quantity should equal expected quantity');

        // Verify Warehouse Entries exist (for Put-away scenarios - only for last operation lines)
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        Assert.RecordIsNotEmpty(WarehouseEntry);
    end;

    local procedure VerifyLedgerEntriesForGetSourceDocuments(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Item Ledger Entries
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
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

    local procedure SetBinCodeOnWarehouseReceiptLines(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; BinCode: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        if WarehouseReceiptLine.FindSet() then
            repeat
                if WarehouseReceiptLine."Qty. (Base)" > 0 then begin
                    WarehouseReceiptLine.Validate("Bin Code", BinCode);
                    WarehouseReceiptLine.Modify(true);
                end;
            until WarehouseReceiptLine.Next() = 0;
    end;
}
