// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
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
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 140009 "Subc. Whse Data Integrity"
{
    // [FEATURE] Subcontracting Data Integrity and Validation Tests
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
        HandlingMode: Option Verify,Insert;

    local procedure Initialize()
    begin
        HandlingSerialNo := '';
        HandlingLotNo := '';
        HandlingQty := 0;
        HandlingMode := HandlingMode::Verify;
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Data Integrity");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Data Integrity");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Data Integrity");
    end;

    [Test]
    procedure VerifyCannotDeleteLastRoutingOperationWhenPurchaseOrderExists()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        LastOperationNo: Code[10];
        Quantity: Decimal;
    begin
        // [SCENARIO] System prevents deletion of last routing operation when purchase orders exist
        // [FEATURE] Subcontracting Data Integrity - Prevention of last routing operation deletion

        // [GIVEN] Complete setup with subcontracting infrastructure
        Initialize();
        Quantity := LibraryRandom.RandInt(10) + 5;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order for the last routing operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);

        // [GIVEN] Find the last routing operation
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.SetRange("Next Operation No.", '');
        Assert.RecordIsNotEmpty(ProdOrderRoutingLine);
        ProdOrderRoutingLine.FindFirst();
        LastOperationNo := ProdOrderRoutingLine."Operation No.";

        // [WHEN] Attempt to delete the last routing operation that has associated purchase order
        asserterror ProdOrderRoutingLine.Delete(true);

        // [THEN] The deletion should be prevented - Error message expected
        Assert.ExpectedError('Because the Production Order Routing Line is the last operation after delete, the Purchase Line cannot be of type Not Last Operation. Please delete the Purchase line first before changing the Production Order Routing Line.');
    end;

    [Test]
    procedure VerifyCannotAddRoutingOperationAfterLastWhenPurchaseOrderExists()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        NewRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] System prevents adding routing operation after last operation when purchase orders exist
        // [FEATURE] Subcontracting Data Integrity - Prevention of adding operations after last when PO exists

        // [GIVEN] Complete setup
        Initialize();
        Quantity := LibraryRandom.RandInt(10) + 5;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order for last operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [GIVEN] Find the last routing operation with purchase order
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.SetRange("Next Operation No.", '');
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] Attempt to add a new routing operation after the last operation
        NewRoutingLine.Init();
        NewRoutingLine.Status := ProdOrderRoutingLine.Status;
        NewRoutingLine."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
        NewRoutingLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        NewRoutingLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        NewRoutingLine."Operation No." := '9999';
        NewRoutingLine.Insert(true);
        NewRoutingLine.Validate(Type, ProdOrderRoutingLine.Type::"Work Center");
        asserterror NewRoutingLine.Validate("No.", WorkCenter[1]."No.");

        Assert.ExpectedError('Because the Production Order Routing Line is not the last operation, the Purchase Line cannot be of type Last Operation. Please delete the Purchase line first before changing the Production Order Routing Line.');
    end;

    [Test]
    procedure VerifyCannotChangeOperationNoWhenPurchaseLineExists()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] System prevents changing Operation No. on routing operation when purchase line exists
        // [FEATURE] Subcontracting Data Integrity - Prevention of critical field changes when PO exists

        // [GIVEN] Complete setup with subcontracting infrastructure
        Initialize();
        Quantity := LibraryRandom.RandInt(10) + 5;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order for the routing operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [GIVEN] Find the routing operation with purchase order
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] Attempt to change Operation No. on the routing operation (by renaming)
        asserterror ProdOrderRoutingLine.Rename(
            ProdOrderRoutingLine.Status,
            ProdOrderRoutingLine."Prod. Order No.",
            ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.",
            '9999'); // New operation no.

        // [THEN] The change should be prevented because a purchase line exists
        // Error expected: Cannot rename routing line when purchase line exists
    end;

    [Test]
    procedure VerifyDataIntegrityWhenModifyingLastOperationWithPO()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        OriginalSetupTime: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO] Verify data integrity when modifying last routing operation with associated purchase order
        // [FEATURE] Subcontracting Data Integrity - Modification validation

        // [GIVEN] Complete setup
        Initialize();
        Quantity := LibraryRandom.RandInt(10) + 5;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Purchase Order for last operation
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [GIVEN] Find last routing operation
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.SetRange("Next Operation No.", '');
        ProdOrderRoutingLine.FindFirst();
        OriginalSetupTime := ProdOrderRoutingLine."Setup Time";

        // [WHEN] Attempt to modify fields on the routing operation with associated PO
        // This should maintain referential integrity
        ProdOrderRoutingLine.Validate("Setup Time", OriginalSetupTime + 10);
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Verify the modification was allowed for non-critical fields
        ProdOrderRoutingLine.Get(ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.",
            ProdOrderRoutingLine."Routing Reference No.", ProdOrderRoutingLine."Routing No.",
            ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(OriginalSetupTime + 10, ProdOrderRoutingLine."Setup Time",
            'Setup time should be modifiable');

        // [THEN] Verify purchase order link remains intact
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(ProdOrderRoutingLine."Operation No.", PurchaseLine."Operation No.",
            'Purchase Order link must remain intact after modification');
    end;

    [Test]
    procedure VerifyQuantityReconciliationAfterMultiplePartialReceipts()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WorkCenter: array[2] of Record "Work Center";
        FirstReceiptQty: Decimal;
        SecondReceiptQty: Decimal;
        ThirdReceiptQty: Decimal;
        TotalPostedQty: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO] Verify quantity reconciliation is maintained after multiple partial warehouse receipts
        // [FEATURE] Subcontracting Data Integrity - Quantity Reconciliation

        // [GIVEN] Complete setup with quantity that allows multiple partial receipts
        Initialize();
        TotalQuantity := 30;
        FirstReceiptQty := 10;
        SecondReceiptQty := 12;
        ThirdReceiptQty := TotalQuantity - FirstReceiptQty - SecondReceiptQty; // Remaining 8

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        // [GIVEN] Create Warehouse Employee for the location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Configure Vendor
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create Production Order and Subcontracting Purchase Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", TotalQuantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [WHEN] Post First Partial Receipt
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, FirstReceiptQty, PostedWhseReceiptHeader);

        // [THEN] Verify first receipt quantities
        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.FindFirst();
        Assert.AreEqual(FirstReceiptQty, PostedWhseReceiptLine.Quantity,
            'First posted receipt should have correct quantity');

        // [THEN] Verify base quantity on first posted receipt
        Assert.AreEqual(FirstReceiptQty * PostedWhseReceiptLine."Qty. per Unit of Measure", PostedWhseReceiptLine."Qty. (Base)", 'First posted receipt should have correct Qty. (Base)');

        // [THEN] Verify remaining quantity on warehouse receipt
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(TotalQuantity - FirstReceiptQty, WarehouseReceiptLine."Qty. Outstanding",
            'Outstanding quantity should be correctly reduced after first receipt');

        // [THEN] Verify base quantity outstanding after first receipt
        Assert.AreEqual((TotalQuantity - FirstReceiptQty) * WarehouseReceiptLine."Qty. per Unit of Measure",
            WarehouseReceiptLine."Qty. Outstanding (Base)",
            'Qty. Outstanding (Base) should be correctly calculated after first receipt');

        // [WHEN] Post Second Partial Receipt
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, SecondReceiptQty, PostedWhseReceiptHeader);

        // [THEN] Verify remaining quantity after second receipt
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(ThirdReceiptQty, WarehouseReceiptLine."Qty. Outstanding",
            'Outstanding quantity should be correctly reduced after second receipt');

        // [THEN] Verify base quantity outstanding after second receipt
        Assert.AreEqual(ThirdReceiptQty * WarehouseReceiptLine."Qty. per Unit of Measure",
            WarehouseReceiptLine."Qty. Outstanding (Base)",
            'Qty. Outstanding (Base) should be correctly calculated after second receipt');

        // [WHEN] Post Final Receipt (remaining quantity)
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, ThirdReceiptQty, PostedWhseReceiptHeader);

        // [THEN] Verify total posted quantity across all receipts matches original PO quantity
        TotalPostedQty := 0;
        PostedWhseReceiptLine.Reset();
        PostedWhseReceiptLine.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        PostedWhseReceiptLine.SetRange("Item No.", Item."No.");
        if PostedWhseReceiptLine.FindSet() then
            repeat
                TotalPostedQty += PostedWhseReceiptLine.Quantity;
            until PostedWhseReceiptLine.Next() = 0;

        Assert.AreEqual(TotalQuantity, TotalPostedQty,
            'Total posted quantity across all receipts must equal original PO quantity');

        // [THEN] Verify purchase line outstanding quantity is zero (fully received)
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity",
            'Purchase Line outstanding quantity should be zero after full receipt');
    end;
}
