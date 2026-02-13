// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
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
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 140001 "Subc. Whse Put-Away LastOp."
{
    // [FEATURE] Subcontracting Warehouse Put-away - Last Operation Tests
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

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Put-Away LastOp.");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Put-Away LastOp.");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Put-Away LastOp.");
    end;

    [Test]
    procedure RecreatePutAwayFromPostedWhseReceipt()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        VendorLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityHeader2: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WorkCenter: array[2] of Record "Work Center";
        FirstPutAwayNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO] Recreate Put-away from Posted WH Receipt
        // [FEATURE] Subcontracting Warehouse Put-away - Recreate Put-away

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 15);

        // [GIVEN] Create Work Centers and Manufacturing Setup
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Production BOM and Routing
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Warehouse Location with bins (Bin Mandatory enabled for Take/Place lines)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Configure Vendor
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(VendorLocation);
        Vendor.Modify();

        // [GIVEN] Create Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order and Warehouse Receipt
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [GIVEN] Post Warehouse Receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [GIVEN] Create Put-away from Posted Warehouse Receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);
        FirstPutAwayNo := WarehouseActivityHeader."No.";

        // [WHEN] Delete the created put-away
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("No.", FirstPutAwayNo);
        WarehouseActivityLine.DeleteAll(true);
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Recreate put-away from posted warehouse receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader2);

        // [THEN] Verify new put-away creation succeeds
        Assert.AreNotEqual('', WarehouseActivityHeader2."No.",
            'New put-away document should be created');
        Assert.AreNotEqual(FirstPutAwayNo, WarehouseActivityHeader2."No.",
            'New put-away should have different number than deleted one');

        // [THEN] Verify Data Consistency: New put-away has correct data
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader2."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordIsNotEmpty(WarehouseActivityLine);
        WarehouseActivityLine.FindFirst();

        Assert.AreEqual(Item."No.", WarehouseActivityLine."Item No.",
            'Recreated put-away should have correct item');
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity,
            'Recreated put-away should have correct quantity');
        Assert.AreEqual(Item."Base Unit of Measure", WarehouseActivityLine."Unit of Measure Code",
            'Recreated put-away should have correct UoM');
    end;

    [Test]
    procedure CreatePutAwayFromPutAwayWorksheetForLastOperation()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        VendorLocation: Record Location;
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
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO] Create Put-away from Put-away Worksheet for Last Operation
        // [FEATURE] Subcontracting Warehouse Put-away - Put-away Worksheet

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create Work Centers and Manufacturing Setup
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Production BOM and Routing
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Warehouse Location with bins (Bin Mandatory enabled for Take/Place lines)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Enable Put-away Worksheet - required to use worksheet flow instead of auto-creating put-away
        Location."Use Put-away Worksheet" := true;
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee for the location (required for put-away worksheet)
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Configure Vendor
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(VendorLocation);
        Vendor.Modify();

        // [GIVEN] Create Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order and Warehouse Receipt
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [GIVEN] Post Warehouse Receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [WHEN] Create Put-away Worksheet
        SubcWarehouseLibrary.CreatePutAwayWorksheet(WhseWorksheetTemplate, WhseWorksheetName, Location.Code);

        // [WHEN] Get Warehouse Documents into Put-away Worksheet
        SubcWarehouseLibrary.GetWarehouseDocumentsForPutAwayWorksheet(WhseWorksheetTemplate.Name, WhseWorksheetName, Location.Code);

        // [THEN] Verify worksheet identifies source correctly
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        Assert.RecordIsNotEmpty(WhseWorksheetLine);

        WhseWorksheetLine.FindFirst();
        Assert.AreEqual(Item."No.", WhseWorksheetLine."Item No.",
            'Worksheet line should identify correct item from posted receipt');
        Assert.AreEqual(Quantity, WhseWorksheetLine.Quantity,
            'Worksheet line should show correct quantity');

        // [WHEN] Create Put-away from worksheet
        SubcWarehouseLibrary.CreatePutAwayFromWorksheet(WhseWorksheetName, WarehouseActivityHeader);

        // [THEN] Verify created put-away is accurate
        Assert.AreNotEqual('', WarehouseActivityHeader."No.",
            'Put-away should be created from worksheet');

        // [THEN] Verify Data Consistency: Put-away has correct data
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(Item."No.", WarehouseActivityLine."Item No.",
            'Put-away created from worksheet should have correct item');
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity,
            'Put-away created from worksheet should have correct quantity');

        // [THEN] Verify all quantities are reconciled using Qty. (Base) = Quantity * Qty. per Unit of Measure
        Assert.AreEqual(WarehouseActivityLine.Quantity * WarehouseActivityLine."Qty. per Unit of Measure", WarehouseActivityLine."Qty. (Base)",
            'Qty. (Base) should equal Quantity * Qty. per Unit of Measure');
    end;
}
