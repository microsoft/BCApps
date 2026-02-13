// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
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
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 140002 "Subc. Whse Partial Last Op"
{
    // [FEATURE] Subcontracting Warehouse Partial Posting - Last Operation Tests
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Whse Partial Last Op");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Whse Partial Last Op");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Whse Partial Last Op");
    end;

    [Test]
    procedure PartialWhseReceiptPostingForLastOperation()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
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
        // [SCENARIO] Post partial quantity of warehouse receipt for Last Operation
        // [FEATURE] Subcontracting Warehouse Partial Posting - Last Operation

        // [GIVEN] Complete Manufacturing Setup with Work Centers, Machine Centers, and Item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        PartialQuantity := Round(Quantity / 2, 1);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling and Bin Mandatory (Require Receive, Put-away, Bin Mandatory)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Configure Vendor with Subcontracting Location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [WHEN] Post Partial Warehouse Receipt
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, PartialQuantity, PostedWhseReceiptHeader);

        // [THEN] Verify Posted Entries: Posted warehouse receipt created for partial quantity
        Assert.AreNotEqual('', PostedWhseReceiptHeader."No.",
            'Posted warehouse receipt should be created');

        // [THEN] Verify Quantity Reconciliation: Posted warehouse receipt has correct partial quantity
        VerifyPostedWhseReceiptQuantity(PostedWhseReceiptHeader, Item."No.", PartialQuantity);

        // [THEN] Verify Quantity Reconciliation: Remaining quantity is correct on warehouse receipt
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(Quantity - PartialQuantity, WarehouseReceiptLine."Qty. Outstanding",
            'Warehouse receipt line should have correct outstanding quantity after partial posting');

        // [THEN] Verify base quantity is correctly calculated from quantity and UoM
        Assert.AreEqual(Quantity * WarehouseReceiptLine."Qty. per Unit of Measure",
            WarehouseReceiptLine."Qty. (Base)",
            'Qty. (Base) should equal Quantity * Qty. per Unit of Measure');

        // [THEN] Verify base quantity outstanding is correctly calculated after partial posting
        Assert.AreEqual((Quantity - PartialQuantity) * WarehouseReceiptLine."Qty. per Unit of Measure",
            WarehouseReceiptLine."Qty. Outstanding (Base)",
            'Qty. Outstanding (Base) should be correctly calculated after partial posting');
    end;

    [Test]
    procedure PartialPutAwayPostingForLastOperation()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WorkCenter: array[2] of Record "Work Center";
        PartialPutAwayQty: Decimal;
        PartialReceiptQty: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO] Post partial quantity of put-away created from partially received warehouse receipt for Last Operation
        // [FEATURE] Subcontracting Warehouse Partial Posting - Last Operation

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(20, 40);
        PartialReceiptQty := Round(Quantity / 2, 1);
        PartialPutAwayQty := Round(PartialReceiptQty / 2, 1);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling and Bin Mandatory (Require Receive, Put-away, Bin Mandatory)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Configure Vendor with Subcontracting Location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create and Post Partial Warehouse Receipt
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, PartialReceiptQty, PostedWhseReceiptHeader);

        // [GIVEN] Create Put-away from Posted Warehouse Receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        // [WHEN] Post Partial Put-away
        SubcWarehouseLibrary.PostPartialPutAway(WarehouseActivityHeader, PartialPutAwayQty);

        // [THEN] Verify Posted Entries: Item ledger entry is created for partial quantity
        VerifyItemLedgerEntry(Item."No.", PartialReceiptQty, Location.Code);

        // [THEN] Verify Posted Entries: Capacity ledger entry is created for partial quantity
        VerifyCapacityLedgerEntry(WorkCenter[2]."No.", PartialReceiptQty);

        // [THEN] Verify Bin Management: Inventory updated for partial quantity
        VerifyBinContents(Location.Code, PutAwayBin.Code, Item."No.", PartialPutAwayQty);

        // [THEN] Verify Quantity Reconciliation: Put-away has correct outstanding quantity
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        if WarehouseActivityLine.FindFirst() then
            Assert.AreEqual(PartialReceiptQty - PartialPutAwayQty,
                WarehouseActivityLine."Qty. Outstanding",
                'Put-away line should have correct outstanding quantity after partial posting');
    end;

    [Test]
    procedure MultiStepPartialPostingForLastOperation()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptHeader2: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityHeader2: Record "Warehouse Activity Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WorkCenter: array[2] of Record "Work Center";
        FirstPutAwayQty: Decimal;
        FirstReceiptQty: Decimal;
        SecondPutAwayQty: Decimal;
        SecondReceiptQty: Decimal;
        ThirdPutAwayQty: Decimal;
        ThirdReceiptQty: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO] Post single order in multiple partial steps until full quantity processed for Last Operation
        // [FEATURE] Subcontracting Warehouse Multi-step Partial Posting - Last Operation

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        TotalQuantity := LibraryRandom.RandIntInRange(30, 60);
        FirstReceiptQty := Round(TotalQuantity * 0.3, 1);
        SecondReceiptQty := Round(TotalQuantity * 0.4, 1);
        ThirdReceiptQty := TotalQuantity - FirstReceiptQty - SecondReceiptQty;

        FirstPutAwayQty := Round(FirstReceiptQty * 0.5, 1);
        SecondPutAwayQty := FirstReceiptQty - FirstPutAwayQty;
        ThirdPutAwayQty := SecondReceiptQty;

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling and Bin Mandatory (Require Receive, Put-away, Bin Mandatory)
        // Creates both Receive Bin (for warehouse receipt) and Put-away Bin (for put-away destination)
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Configure Vendor with Subcontracting Location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
                 ProductionOrder, "Production Order Status"::Released,
                 ProductionOrder."Source Type"::Item, Item."No.", TotalQuantity, Location.Code);

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        // [WHEN] Step 1: Post first partial warehouse receipt
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, FirstReceiptQty, PostedWhseReceiptHeader);

        // [THEN] Verify Quantity Reconciliation: First receipt quantity is correct
        VerifyPostedWhseReceiptQuantity(PostedWhseReceiptHeader, Item."No.", FirstReceiptQty);

        // [WHEN] Step 2: Create and post first partial put-away
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);
        SubcWarehouseLibrary.PostPartialPutAway(WarehouseActivityHeader, FirstPutAwayQty);

        // [THEN] Verify Quantity Reconciliation: First put-away quantity is correct
        VerifyItemLedgerEntry(Item."No.", FirstReceiptQty, Location.Code);
        VerifyBinContents(Location.Code, PutAwayBin.Code, Item."No.", FirstPutAwayQty);

        // [WHEN] Step 3: Post remaining quantity from first put-away
        SubcWarehouseLibrary.PostPartialPutAway(WarehouseActivityHeader, SecondPutAwayQty);

        // [THEN] Verify Quantity Reconciliation: Cumulative quantity is correct
        VerifyItemLedgerEntry(Item."No.", FirstReceiptQty, Location.Code);
        VerifyBinContents(Location.Code, PutAwayBin.Code, Item."No.", FirstPutAwayQty + SecondPutAwayQty);

        // [WHEN] Step 4: Post second partial warehouse receipt
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, SecondReceiptQty, PostedWhseReceiptHeader2);

        // [THEN] Verify Quantity Reconciliation: Second receipt quantity is correct
        VerifyPostedWhseReceiptQuantity(PostedWhseReceiptHeader2, Item."No.", SecondReceiptQty);

        // [WHEN] Step 5: Create and post second put-away (full quantity)
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader2, WarehouseActivityHeader2);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader2);

        // [THEN] Verify Quantity Reconciliation: Total posted quantity through all steps
        VerifyItemLedgerEntry(Item."No.",
            FirstReceiptQty + SecondReceiptQty, Location.Code);
        VerifyCapacityLedgerEntry(WorkCenter[2]."No.",
            FirstReceiptQty + SecondReceiptQty);
        VerifyBinContents(Location.Code, PutAwayBin.Code, Item."No.",
            FirstReceiptQty + SecondReceiptQty);
        // [WHEN] Step 6: Post remaining warehouse receipt
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader);

        // [WHEN] Step 7: Create and post final put-away
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify Data Consistency: Final quantities match original order quantity
        VerifyItemLedgerEntry(Item."No.", TotalQuantity, Location.Code);
        VerifyCapacityLedgerEntry(WorkCenter[2]."No.", TotalQuantity);
        VerifyBinContents(Location.Code, PutAwayBin.Code, Item."No.", TotalQuantity);

        // [THEN] Verify UoM: Base quantity calculations are correct across all documents
        VerifyUoMBaseQuantityCalculations(Item."No.", TotalQuantity, Location.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure PartialLotPostingWithItemTrackingAndPutAwayRecreation()
    var
        PutAwayBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
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
        LotNo1: Code[50];
        LotNo2: Code[50];
        PartialQtyLot1: Decimal;
        PartialQtyLot2: Decimal;
        PartialQtyToReceive: Decimal;
        TotalQuantity: Decimal;
        WarehouseReceiptPage: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO] Comprehensive item tracking test: partial lot posting with put-away recreation and quantity matching validation
        // [FEATURE] Subcontracting Item Tracking - Multiple lots with partial posting, put-away deletion/recreation, and quantity validation

        // [GIVEN] Complete Manufacturing Setup
        Initialize();
        TotalQuantity := LibraryRandom.RandIntInRange(30, 60);
        PartialQtyLot1 := Round(TotalQuantity * 0.3, 1);
        PartialQtyLot2 := Round(TotalQuantity * 0.3, 1);
        PartialQtyToReceive := Round(TotalQuantity * 0.4, 1);

        // [GIVEN] Create Work Centers and Machine Centers with Subcontracting
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create Lot-tracked Item with Routing and Production BOM
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);

        // [GIVEN] Update BOM and Routing with Routing Link
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] Create Location with Warehouse Handling and Bins
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandlingAndBins(Location, ReceiveBin, PutAwayBin);

        // [GIVEN] Create Warehouse Employee for Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Configure Vendor with Subcontracting Location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] Create and Refresh Production Order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", TotalQuantity, Location.Code);

        // [GIVEN] Setup Requisition Worksheet Template
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Create Subcontracting Purchase Order
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Warehouse Receipt from Purchase Order
        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);

        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        // [GIVEN] Generate lot numbers for multiple lot tracking
        LotNo1 := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");
        LotNo2 := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");

        // [WHEN] Insert first Lot Number with partial quantity
        HandlingMode := HandlingMode::Insert;
        HandlingLotNo := LotNo1;
        HandlingQty := PartialQtyLot1;

        WarehouseReceiptPage.OpenEdit();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [WHEN] Insert second Lot Number with partial quantity
        HandlingLotNo := LotNo2;
        HandlingQty := PartialQtyLot2;

        WarehouseReceiptPage.OpenEdit();
        WarehouseReceiptPage.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceiptPage.WhseReceiptLines.GoToRecord(WarehouseReceiptLine);
        WarehouseReceiptPage.WhseReceiptLines.ItemTrackingLines.Invoke();
        WarehouseReceiptPage.Close();

        // [WHEN] Post partial warehouse receipt with both lots
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, PartialQtyLot1 + PartialQtyLot2, PostedWhseReceiptHeader);

        // [THEN] Verify: Posted warehouse receipt has correct partial quantity
        VerifyPostedWhseReceiptQuantity(PostedWhseReceiptHeader, Item."No.", PartialQtyLot1 + PartialQtyLot2);

        // [WHEN] Create Put-away from Posted Warehouse Receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        // [THEN] Verify: Put-away lines exist with correct lot numbers
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        Assert.AreEqual(2, WarehouseActivityLine.Count(), 'Should have 2 Place lines for 2 lots');

        VerifyWarehouseActivityLineForLot(WarehouseActivityHeader, LotNo1, PartialQtyLot1);
        VerifyWarehouseActivityLineForLot(WarehouseActivityHeader, LotNo2, PartialQtyLot2);

        // [WHEN] Delete the Put-away to test recreation functionality
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Recreate Put-away from Posted Warehouse Receipt
        SubcWarehouseLibrary.CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader, WarehouseActivityHeader);

        // [THEN] Verify: Recreated Put-away has same lot tracking information
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        Assert.AreEqual(2, WarehouseActivityLine.Count(), 'Recreated Put-away should have 2 Place lines for 2 lots');

        VerifyWarehouseActivityLineForLot(WarehouseActivityHeader, LotNo1, PartialQtyLot1);
        VerifyWarehouseActivityLineForLot(WarehouseActivityHeader, LotNo2, PartialQtyLot2);

        // [THEN] Verify: Remaining quantity on Warehouse Receipt is correct
        WarehouseReceiptHeader.Find();
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(TotalQuantity - PartialQtyLot1 - PartialQtyLot2, WarehouseReceiptLine."Qty. Outstanding",
            'Remaining quantity on Warehouse Receipt Line should be correct');

        // [WHEN] Post the recreated Put-away
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify: Bin contents are correct for both lots
        VerifyBinContentsForLot(Location.Code, PutAwayBin.Code, Item."No.", LotNo1, PartialQtyLot1);
        VerifyBinContentsForLot(Location.Code, PutAwayBin.Code, Item."No.", LotNo2, PartialQtyLot2);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; ExpectedQuantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQuantity, ItemLedgerEntry.Quantity,
            'Item Ledger Entry should have correct output quantity');
    end;

    local procedure VerifyCapacityLedgerEntry(WorkCenterNo: Code[20]; ExpectedQuantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange(Type, CapacityLedgerEntry.Type::"Work Center");
        CapacityLedgerEntry.SetRange("No.", WorkCenterNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);

        CapacityLedgerEntry.CalcSums("Output Quantity");
        Assert.AreEqual(ExpectedQuantity, CapacityLedgerEntry."Output Quantity",
            'Capacity Ledger Entry should have correct output quantity');
    end;

    local procedure VerifyBinContents(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        Assert.RecordIsNotEmpty(BinContent);

        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        Assert.AreEqual(ExpectedQuantity, BinContent.Quantity,
            'Bin contents should show correct quantity after put-away posting');
    end;

    local procedure VerifyUoMBaseQuantityCalculations(ItemNo: Code[20]; ExpectedQuantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQuantity, ItemLedgerEntry.Quantity,
            'UoM base quantity calculations should be correct across all documents');
    end;

    local procedure VerifyWarehouseActivityLineForLot(WarehouseActivityHeader: Record "Warehouse Activity Header"; LotNo: Code[50]; ExpectedQuantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(ExpectedQuantity, WarehouseActivityLine.Quantity,
            'Warehouse Activity Line should have correct quantity for lot ' + LotNo);
    end;

    local procedure VerifyReservationEntryQuantityForLot(ItemNo: Code[20]; LotNo: Code[50]; ExpectedQuantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetFilter("Quantity (Base)", '<>0');
        Assert.RecordIsNotEmpty(ReservationEntry);

        ReservationEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(ExpectedQuantity, Abs(ReservationEntry."Quantity (Base)"),
            'Reservation Entry should have correct quantity for lot ' + LotNo);
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
