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
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 140007 "Subc. Whse Location Config"
{
    // [FEATURE] Subcontracting - Location Configuration Tests
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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Location Config");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Location Config");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Location Config");
    end;

    [Test]
    procedure LocationWithRequirePutawayDisabled_DirectInventoryUpdateAndLedgerVerification()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        TotalItemLedgerQty: Decimal;
    begin
        // [SCENARIO] Process subcontracting receipt in location where put-away is not required and verify all ledger entries are correct
        // [FEATURE] Subcontracting - Location Configuration

        // [GIVEN] Complete Setup of Manufacturing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 15);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Production BOM and Routing
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Require Receive enabled but Require Put-away disabled
        SubcWarehouseLibrary.CreateLocationWithRequireReceiveOnly(Location);

        // [GIVEN] Create Warehouse Employee for the location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Configure Vendor with Location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [WHEN] Post Warehouse Receipt
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Verify: Posting warehouse receipt directly updates inventory
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        Assert.RecordIsNotEmpty(PostedWhseReceiptHeader);
        PostedWhseReceiptHeader.FindFirst();

        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(PostedWhseReceiptLine);
        PostedWhseReceiptLine.FindFirst();

        // [THEN] Verify: No put-away document created
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [THEN] Verify: Item Ledger Entry is created with correct quantity
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity,
            'Item Ledger Entry Quantity should match the posted quantity');

        // [THEN] Verify: Capacity Ledger Entry exists
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);

        // [THEN] Verify: Output Quantity in Capacity Ledger Entry
        CapacityLedgerEntry.CalcSums("Output Quantity");
        Assert.AreEqual(Quantity, CapacityLedgerEntry."Output Quantity", 'Capacity Ledger Entry Output Quantity should match the expected quantity');

        // [THEN] Verify: Quantity Reconciliation - all quantities posted correctly
        Assert.AreEqual(Quantity, PostedWhseReceiptLine.Quantity,
            'Posted Warehouse Receipt Line should have the full quantity');
        Assert.AreEqual(PostedWhseReceiptLine.Quantity * PostedWhseReceiptLine."Qty. per Unit of Measure", PostedWhseReceiptLine."Qty. (Base)",
            'Qty. (Base) should equal Quantity * Qty. per Unit of Measure');

        // [THEN] Verify: Item Ledger Entries are correct with production order linkage
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        TotalItemLedgerQty := 0;
        if ItemLedgerEntry.FindSet() then
            repeat
                TotalItemLedgerQty += ItemLedgerEntry.Quantity;
            until ItemLedgerEntry.Next() = 0;

        Assert.AreEqual(Quantity, TotalItemLedgerQty,
            'Total Item Ledger Entry Quantity should match posted quantity');

        // [THEN] Verify: Capacity Ledger Entries exist and are correct
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);
    end;

    [Test]
    procedure LocationWithRequirePutawayDisabled_NonLastOperation()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Process subcontracting receipt for non-last operation in location where put-away is not required
        // [FEATURE] Subcontracting - Location Configuration - Non-Last Operation

        // [GIVEN] Complete Setup of Manufacturing
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 15);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Production BOM and Routing (non-last operation)
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);

        // [GIVEN] Create Location with Require Receive enabled but Require Put-away disabled
        SubcWarehouseLibrary.CreateLocationWithRequireReceiveOnly(Location);

        // [GIVEN] Create Warehouse Employee for the location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Configure Vendor with Location (using first work center for non-last operation)
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order for non-last operation (WorkCenter[1])
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [WHEN] Post Warehouse Receipt
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Verify: Posted warehouse receipt exists
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        Assert.RecordIsNotEmpty(PostedWhseReceiptHeader);
        PostedWhseReceiptHeader.FindFirst();

        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(PostedWhseReceiptLine);
        PostedWhseReceiptLine.FindFirst();

        // [THEN] Verify: No put-away document created for non-last operation
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [THEN] Verify: NO Item Ledger Entry is created for non-last operation
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsEmpty(ItemLedgerEntry);

        // [THEN] Verify: Capacity Ledger Entry exists for non-last operation
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);

        // [THEN] Verify: Quantity Reconciliation
        Assert.AreEqual(Quantity, PostedWhseReceiptLine.Quantity,
            'Posted Warehouse Receipt Line should have the full quantity');
        Assert.AreEqual(PostedWhseReceiptLine.Quantity * PostedWhseReceiptLine."Qty. per Unit of Measure", PostedWhseReceiptLine."Qty. (Base)",
            'Qty. (Base) should equal Quantity * Qty. per Unit of Measure');
    end;

    [Test]
    procedure LocationWithBinMandatoryOnly_StandardPostingProcess()
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
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Verify standard posting process and bin handling for Bin Mandatory Only location
        // [FEATURE] Subcontracting - Location Configuration

        // [GIVEN] Complete Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create Manufacturing Setup
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Bin Mandatory only
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(Location);

        // [GIVEN] Create a bin for the location
        LibraryWarehouse.CreateBin(Bin, Location.Code,
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), '', '');

        // [GIVEN] Configure Vendor
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Update Purchase Line with Bin Code (simulating user input)
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Release Purchase Document
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Verify: No Warehouse Receipt can be created (location has Bin Mandatory but not Require Receive)
        VerifyNoWarehouseReceiptCreated(PurchaseHeader);

        // [WHEN] Post Purchase Order directly (standard posting)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify: Item Ledger Entry created with correct bin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.FindFirst();

        // [THEN] Verify: Inventory updated in correct bin
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code",
            'Item Ledger Entry should have correct location');
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity,
            'Item Ledger Entry should have correct quantity');

        // [THEN] Verify: Capacity Ledger Entry created
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);
    end;

    [Test]
    procedure LocationWithBinMandatoryOnly_NonLastOperation()
    var
        Bin: Record Bin;
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Verify standard posting process for non-last operation with Bin Mandatory Only location
        // [FEATURE] Subcontracting - Location Configuration - Non-Last Operation

        // [GIVEN] Complete Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Create Manufacturing Setup
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);

        // [GIVEN] Create Location with Bin Mandatory only
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(Location);

        // [GIVEN] Create a bin for the location
        LibraryWarehouse.CreateBin(Bin, Location.Code,
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), '', '');

        // [GIVEN] Configure Vendor (using first work center for non-last operation)
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order for non-last operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Update Purchase Line with Bin Code (simulating user input)
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Order directly (standard posting)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify: NO Item Ledger Entry created for non-last operation
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsEmpty(ItemLedgerEntry);

        // [THEN] Verify: Capacity Ledger Entry created for non-last operation
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[1]."No.", Quantity);
    end;

    local procedure VerifyNoWarehouseReceiptCreated(PurchaseHeader: Record "Purchase Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        // Verify that no warehouse request exists for this purchase order
        WarehouseRequest.SetRange("Source Type", Database::"Purchase Line");
        WarehouseRequest.SetRange("Source Subtype", PurchaseHeader."Document Type".AsInteger());
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(WarehouseRequest);
    end;
}
