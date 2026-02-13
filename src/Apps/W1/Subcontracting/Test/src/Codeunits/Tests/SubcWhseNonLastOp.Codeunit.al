// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
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
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 140003 "Subc. Whse Non-Last Op."
{
    // [FEATURE] Subcontracting Warehouse Non-Last Operation Tests
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Non-Last Op.");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Non-Last Op.");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Non-Last Op.");
    end;

    [Test]
    procedure CreateAndPostWhseReceiptForNonLastOperationFullQuantity()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Create and Post WH Receipt for Non-Last Operation (Full Quantity)
        // [FEATURE] Subcontracting Warehouse Receipt - Non-Last Operation

        // [GIVEN] Complete Manufacturing Setup with Work Centers, Machine Centers, and Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing (with non-last operation) and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link for first operation (non-last)
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] Create Location with Warehouse Handling (Require Receive and Put-away)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Create default bin for location
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'DEFAULT', '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

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

        // [WHEN] Create Subcontracting Purchase Order for first operation (non-last)
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [THEN] Verify warehouse receipt line is created with correct data
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseReceiptLine);

        WarehouseReceiptLine.FindFirst();

        // [THEN] Verify Data Consistency: Warehouse receipt line has correct item and quantity
        Assert.AreEqual(Item."No.", WarehouseReceiptLine."Item No.",
            'Warehouse Receipt Line Item No. should match the Production Order Item');
        Assert.AreEqual(Quantity, WarehouseReceiptLine.Quantity,
            'Warehouse Receipt Line Quantity should match the Purchase Order Quantity');

        // [THEN] Verify Subcontracting Line Type is set to Not Last Operation
        Assert.AreEqual("Subc. Purchase Line Type"::NotLastOperation,
            WarehouseReceiptLine."Subc. Purchase Line Type",
            'Warehouse Receipt Line should be marked as Not Last Operation');

        // [THEN] Verify NotLastOperation has zero base quantities (no inventory movement)
        // CRITICAL: For NotLastOperation, base quantities should be zero as there is no physical inventory movement
        Assert.AreEqual(0, WarehouseReceiptLine."Qty. (Base)", 'NotLastOperation should have zero Qty. (Base)');
        Assert.AreEqual(0, WarehouseReceiptLine."Qty. per Unit of Measure", 'NotLastOperation should have zero Qty. per UoM');

        // [WHEN] Post Warehouse Receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [THEN] Verify Posted Entries: Posted warehouse receipt created
        Assert.AreNotEqual('', PostedWhseReceiptHeader."No.",
            'Posted warehouse receipt should be created');

        // [THEN] Verify Posted Entries: Posted warehouse receipt has correct quantity
        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(PostedWhseReceiptLine);
        PostedWhseReceiptLine.FindFirst();

        Assert.AreEqual(Quantity, PostedWhseReceiptLine.Quantity,
            'Posted warehouse receipt line should have correct quantity');
        Assert.AreEqual(0, PostedWhseReceiptLine."Qty. (Base)",
            'Posted warehouse receipt line for NotLastOperation should have zero Qty. (Base)');

        //Test Base Quantity for NotLastOperation is zero
        // [THEN] Verify Quantity Reconciliation: Quantities reconciled between PO and posted receipt
        Assert.AreEqual(PurchaseLine.Quantity, PostedWhseReceiptLine.Quantity,
            'Posted receipt quantity should match purchase order quantity');

        // [THEN] Verify Ledger Entries: Capacity ledger entries created for non-last operation with zero output
        VerifyCapacityLedgerEntriesOutputQuantity(ProductionOrder."No.", WorkCenter[1]."No.", Quantity);

        // [THEN] Verify Ledger Entries: Item ledger entries NOT created for non-last operation
        VerifyItemLedgerEntriesDoNotExist(Item."No.", Location.Code);
    end;

    [Test]
    procedure CreateAndPostWhseReceiptForNonLastOperationPartialQuantity()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        PartialQuantity: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO] Create and Post WH Receipt for Non-Last Operation (Partial Quantity)
        // [FEATURE] Subcontracting Warehouse Receipt - Non-Last Operation Partial Posting

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(20, 40);
        PartialQuantity := Round(Quantity / 2, 1);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link for first operation (non-last)
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] Create Location with Warehouse Handling
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Create default bin for location
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'PARTIAL', '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

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

        // [GIVEN] Create Subcontracting Purchase Order for non-last operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [WHEN] Post Partial Warehouse Receipt
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, PartialQuantity, PostedWhseReceiptHeader);

        // [THEN] Verify Posted Entries: Posted warehouse receipt created for partial quantity
        Assert.AreNotEqual('', PostedWhseReceiptHeader."No.",
            'Posted warehouse receipt should be created');

        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(PostedWhseReceiptLine);
        PostedWhseReceiptLine.FindFirst();

        Assert.AreEqual(PartialQuantity, PostedWhseReceiptLine.Quantity,
            'Posted warehouse receipt line should have correct partial quantity');

        // [THEN] Verify Quantity Reconciliation: Remaining quantity is correct on warehouse receipt
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(Quantity - PartialQuantity, WarehouseReceiptLine."Qty. Outstanding",
            'Warehouse receipt line should have correct outstanding quantity after partial posting');

        // [THEN] Verify Quantity Reconciliation: Original and posted quantities reconciled
        Assert.AreEqual(Quantity, WarehouseReceiptLine.Quantity,
            'Original warehouse receipt quantity should remain unchanged');

        // [THEN] Verify Ledger Entries: Capacity ledger entries created for non-last operation
        VerifyCapacityLedgerEntriesExist(ProductionOrder."No.", WorkCenter[1]."No.");

        // [THEN] Verify Ledger Entries: Item ledger entries NOT created for non-last operation
        VerifyItemLedgerEntriesDoNotExist(Item."No.", Location.Code);
    end;

    [Test]
    procedure PreventPutAwayCreationForNonLastOperation_AllMethods()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WorkCenter: array[2] of Record "Work Center";
        DirectPutAwayPrevented: Boolean;
        WorksheetPutAwayPrevented: Boolean;
        Quantity: Decimal;
    begin
        // [SCENARIO] Prevent Put-away Creation for Non-Last Operation via All Methods
        // [FEATURE] Subcontracting Warehouse Receipt - Put-away Prevention (Combined Test)
        // Tests prevention of put-away creation from both:
        // 1. Direct creation from Posted Warehouse Receipt
        // 2. Put-away Worksheet

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link for first operation (non-last)
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] Create Location with Warehouse Handling and Put-away Worksheet enabled
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Create default bin for location
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'PREVENT-ALL', '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location."Use Put-away Worksheet" := true;
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee for the location (required for put-away worksheet)
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

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

        // [GIVEN] Create Subcontracting Purchase Order for non-last operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create and Post Warehouse Receipt
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // ============================================================
        // METHOD 1: Test Direct Put-away Creation from Posted Whse Receipt
        // ============================================================

        // [WHEN] Attempt to create put-away from posted warehouse receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        // [THEN] Verify put-away creation is prevented (direct method)
        DirectPutAwayPrevented := (WarehouseActivityHeader."No." = '');
        Assert.IsTrue(DirectPutAwayPrevented,
            'Put-away should not be created for non-last operation via direct creation from Posted Whse Receipt');

        // [THEN] Verify no put-away documents exist for this location
        WarehouseActivityHeader.Reset();
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        Assert.RecordIsEmpty(WarehouseActivityHeader, CompanyName);

        // ============================================================
        // METHOD 2: Test Put-away Creation from Put-away Worksheet
        // ============================================================

        // [WHEN] Create Put-away Worksheet
        SubcWarehouseLibrary.CreatePutAwayWorksheet(WhseWorksheetTemplate, WhseWorksheetName, Location.Code);

        // [WHEN] Get Warehouse Documents for Put-away Worksheet
        WorksheetPutAwayPrevented := not TryGetWarehouseDocumentsForPutAwayWorksheet(
            WhseWorksheetTemplate.Name, WhseWorksheetName, Location.Code);

        // [THEN] Verify put-away creation is prevented (worksheet method) - either errors or no lines created
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.SetRange("Item No.", Item."No.");

        // [THEN] No worksheet lines should be created for non-last operation receipts
        Assert.RecordIsEmpty(WhseWorksheetLine, CompanyName);

        // [THEN] Final verification: Ensure both methods prevented put-away creation
        Assert.IsTrue(DirectPutAwayPrevented,
            'Direct put-away creation from Posted Whse Receipt must be prevented for non-last operation');

        // Note: WorksheetPutAwayPrevented may be true (error) or false (success but no lines created)
        // The key verification is that no worksheet lines exist for the non-last operation item
    end;

    [TryFunction]
    local procedure TryGetWarehouseDocumentsForPutAwayWorksheet(WorksheetTemplateName: Code[10]; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        SubcWarehouseLibrary.GetWarehouseDocumentsForPutAwayWorksheet(WorksheetTemplateName, WhseWorksheetName, LocationCode);
    end;

    local procedure VerifyCapacityLedgerEntriesExist(ProdOrderNo: Code[20]; WorkCenterNo: Code[20])
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        // Verify that capacity ledger entries were created for the production order and work center
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenterNo);
        Assert.RecordCount(CapacityLedgerEntry, 1);
    end;

    local procedure VerifyCapacityLedgerEntriesOutputQuantity(ProdOrderNo: Code[20]; WorkCenterNo: Code[20]; ExpectedOutputQuantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        // Verify that capacity ledger entries were created for the production order and work center
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenterNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);

        // Verify the output quantity matches the expected value
        CapacityLedgerEntry.FindFirst();
        Assert.AreEqual(ExpectedOutputQuantity, CapacityLedgerEntry."Output Quantity" / CapacityLedgerEntry."Qty. per Unit of Measure",
            'Capacity Ledger Entry should have correct output quantity');
    end;

    local procedure VerifyItemLedgerEntriesDoNotExist(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify that NO item ledger entries were created for non-last operation
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsEmpty(ItemLedgerEntry, CompanyName);
    end;

    [Test]
    procedure ItemTrackingNotAllowedForNotLastOperationPurchaseLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Item tracking is not available for non-last operation purchase lines
        // [FEATURE] Subcontracting Item Tracking - Error when opening item tracking for non-last operation

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Lot-tracked Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link for FIRST operation (non-last)
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] Create simple Location without Warehouse Handling (so item tracking can be opened directly from purchase line)
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

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

        // [GIVEN] Create Subcontracting Purchase Order for NON-LAST operation (WorkCenter[1])
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [THEN] Verify: Purchase Line is marked as NotLastOperation
        Assert.AreEqual("Subc. Purchase Line Type"::NotLastOperation, PurchaseLine."Subc. Purchase Line Type",
            'Purchase Line should be marked as NotLastOperation');

        // [THEN] Verify: Base quantities are zero for non-last operation (no physical inventory movement)
        Assert.AreEqual(0, PurchaseLine."Quantity (Base)",
            'NotLastOperation Purchase Line should have zero Quantity (Base)');

        // [WHEN] Try to open Item Tracking Lines from Purchase Order Page
        // [THEN] An error should be raised because item tracking is not allowed for non-last operations
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);
        PurchaseOrderPage.PurchLines.GoToRecord(PurchaseLine);
        asserterror PurchaseOrderPage.PurchLines."Item Tracking Lines".Invoke();

        // [THEN] Verify error message indicates item tracking is not available for non-last operation
        Assert.ExpectedError('Item tracking lines can only be viewed for subcontracting purchase lines which are linked to a routing line which is the last operation.');
    end;

    [Test]
    procedure ItemTrackingNotAllowedForNotLastOperationWarehouseReceiptLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO] Item tracking is not available for non-last operation warehouse receipt lines
        // [FEATURE] Subcontracting Item Tracking - Error when opening item tracking for non-last operation from Warehouse Receipt

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Lot-tracked Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link for FIRST operation (non-last)
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");

        // [GIVEN] Create Location with Warehouse Handling (Require Receive)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Create Warehouse Employee for Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

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

        // [GIVEN] Create Subcontracting Purchase Order for NON-LAST operation (WorkCenter[1])
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [THEN] Verify: Warehouse Receipt Line is marked as NotLastOperation
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual("Subc. Purchase Line Type"::NotLastOperation, WarehouseReceiptLine."Subc. Purchase Line Type",
            'Warehouse Receipt Line should be marked as NotLastOperation');

        // [THEN] Verify: Base quantities are zero for non-last operation
        Assert.AreEqual(0, WarehouseReceiptLine."Qty. (Base)",
            'NotLastOperation Warehouse Receipt Line should have zero Qty. (Base)');

        // [WHEN] Try to open Item Tracking Lines from Warehouse Receipt Page
        // [THEN] An error should be raised because item tracking is not allowed for non-last operations
        WarehouseReceiptPage.OpenEdit();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        asserterror WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();

        // [THEN] Verify error message indicates item tracking is not available for non-last operation
        Assert.ExpectedError('Item tracking lines can only be viewed for subcontracting purchase lines which are linked to a routing line which is the last operation.');
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
