// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
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
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 140004 "Subc. Whse Put-Away Worksheet"
{
    // [FEATURE] Subcontracting Warehouse Put-away Worksheet Tests
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Put-Away Worksheet");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Put-Away Worksheet");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Put-Away Worksheet");
    end;

    [Test]
    procedure CreateSinglePutAwayFromMultiplePostedWhseReceipts()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: array[2] of Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: array[2] of Record "Posted Whse. Receipt Header";
        ProductionOrder: array[2] of Record "Production Order";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: array[2] of Record "Warehouse Receipt Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: array[2] of Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO] Create Single Put-away from Multiple Posted WH Receipts
        // [FEATURE] Subcontracting Warehouse Put-away Worksheet

        // [GIVEN] Complete Manufacturing Setup with Work Centers, Machine Centers, and Items
        Initialize();
        Quantity[1] := LibraryRandom.RandIntInRange(5, 10);
        Quantity[2] := LibraryRandom.RandIntInRange(5, 10);
        TotalQuantity := Quantity[1] + Quantity[2];

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create First Item with its own Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item[1], WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item[1], WorkCenter[2]."No.");

        // [GIVEN] Create Second Item with its own Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item[2], WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item[2], WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling and Bin Mandatory (Require Receive, Put-away, Bin Mandatory)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Enable Put-away Worksheet - required to use worksheet flow instead of auto-creating put-away
        Location."Use Put-away Worksheet" := true;
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee for the location (required for put-away worksheet)
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Configure Vendor with Subcontracting Location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create First Production Order and Subcontracting Purchase Order for Item[1]
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder[1], "Production Order Status"::Released,
            ProductionOrder[1]."Source Type"::Item, Item[1]."No.", Quantity[1], Location.Code);

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item[1]."Routing No.", WorkCenter[2]."No.", PurchaseLine[1]);
        PurchaseHeader[1].Get(PurchaseLine[1]."Document Type", PurchaseLine[1]."Document No.");

        // [GIVEN] Create Second Production Order and Subcontracting Purchase Order for Item[2]
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder[2], "Production Order Status"::Released,
            ProductionOrder[2]."Source Type"::Item, Item[2]."No.", Quantity[2], Location.Code);

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item[2]."Routing No.", WorkCenter[2]."No.", PurchaseLine[2]);
        PurchaseHeader[2].Get(PurchaseLine[2]."Document Type", PurchaseLine[2]."Document No.");

        // [GIVEN] Create and Post First Warehouse Receipt
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader[1], WarehouseReceiptHeader[1]);
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader[1], PostedWhseReceiptHeader[1]);

        // [GIVEN] Create and Post Second Warehouse Receipt
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader[2], WarehouseReceiptHeader[2]);
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader[2], PostedWhseReceiptHeader[2]);

        // [WHEN] Create Put-away Worksheet
        SubcWarehouseLibrary.CreatePutAwayWorksheet(WhseWorksheetTemplate, WhseWorksheetName, Location.Code);

        // [WHEN] Get Warehouse Documents into Put-away Worksheet
        SubcWarehouseLibrary.GetWarehouseDocumentsForPutAwayWorksheet(WhseWorksheetTemplate.Name, WhseWorksheetName, Location.Code);

        // [THEN] Verify worksheet correctly consolidates lines from multiple receipts
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.SetFilter("Item No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        Assert.RecordIsNotEmpty(WhseWorksheetLine);

        // [THEN] Verify worksheet shows aggregated quantities
        WhseWorksheetLine.CalcSums(Quantity);
        Assert.AreEqual(TotalQuantity, WhseWorksheetLine.Quantity,
            'Worksheet should consolidate quantities from multiple posted receipts');

        // [WHEN] Create Put-away from worksheet
        SubcWarehouseLibrary.CreatePutAwayFromWorksheet(WhseWorksheetName, WarehouseActivityHeader);

        // [THEN] Verify Quantity Reconciliation: Single put-away document created with aggregated quantities
        Assert.AreNotEqual('', WarehouseActivityHeader."No.",
            'Put-away document should be created from worksheet');
        Assert.AreEqual(WarehouseActivityHeader.Type::"Put-away", WarehouseActivityHeader.Type,
            'Activity type should be Put-away');

        // [THEN] Verify put-away lines have correct aggregated quantities
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(TotalQuantity, WarehouseActivityLine.Quantity,
            'Put-away should have correctly aggregated quantities from multiple receipts');

        // [THEN] Verify Bin Management: Bin assignment logic correctly applied
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        Assert.RecordIsNotEmpty(WarehouseActivityLine);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(PutAwayBin.Code, WarehouseActivityLine."Bin Code",
            'Put-away should assign correct default bin');

        // [THEN] Verify Data Consistency: Both items are present in put-away lines
        WarehouseActivityLine.SetRange("Action Type");
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        Assert.RecordIsNotEmpty(WarehouseActivityLine);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(Item[1]."Base Unit of Measure", WarehouseActivityLine."Unit of Measure Code",
            'Put-away should have correct unit of measure for Item[1]');

        WarehouseActivityLine.SetRange("Item No.", Item[2]."No.");
        Assert.RecordIsNotEmpty(WarehouseActivityLine);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(Item[2]."Base Unit of Measure", WarehouseActivityLine."Unit of Measure Code",
            'Put-away should have correct unit of measure for Item[2]');

        // [THEN] Verify Data Consistency: Location is consistent
        Assert.AreEqual(Location.Code, WarehouseActivityHeader."Location Code",
            'Put-away location should match source documents');
    end;
}
