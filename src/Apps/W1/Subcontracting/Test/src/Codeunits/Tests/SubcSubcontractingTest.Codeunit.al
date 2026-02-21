// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Planning;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Structure;

codeunit 139989 "Subc. Subcontracting Test"
{
    // [FEATURE] Subcontracting Management
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure InsertRecordOnOpenPageSubcontractingManagementSetup()
    var
        SubcontractingMgmtSetupPage: TestPage "Subc. Management Setup";
    begin
        // [SCENARIO] OnOpenPage should create a record in Subcontracting Setup

        // [GIVEN] No Record exists in Subcontracting Setup
        Initialize();
        RemoveSubcontractingManagementSetupRecord();
        CheckNoSubcontractingManagementSetupRecordExist();

        // [WHEN] Open Subcontracting Setup Page
        SubcontractingMgmtSetupPage.OpenView();
        SubcontractingMgmtSetupPage.Close();

        // [THEN] A Record should exist in Subcontracting Setup
        CheckSubcontractingManagementSetupRecordExist();

        // [TEARDOWN]
        Clear(IsInitialized);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure TestCreationOfPurchOrderFromRtngLineWithSubcontractor()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order directly from Prod. Order Routing Line

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line exists
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), '');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure TestCreationOfPurchOrderFromRtngLineWithSubcontractorWithAddLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order directly from Prod. Order Routing Line
        // [SCENARIO] and Transfer additional Line with marked Component;

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Purchase);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line with additional Component for Subcontracting Type exists
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
#pragma warning disable AA0210
        ProductionBOMLine.SetRange("Subcontracting Type", ProductionBOMLine."Subcontracting Type"::Purchase);
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ProductionBOMLine."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), '');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure TestCreationOfSubcontractingPurchOrderFromRtngLineWithAddInfoLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order directly from Prod. Order Routing Line
        // [SCENARIO] and Transfer additional Information Line;

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupTransferInfoLine(true);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line with Additional Information Exists
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.SetRange("Prod. Order No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();

        ProdOrderRtngLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRtngLine.FindFirst();
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderRtngLine."Prod. Order No.", ProdOrderRtngLine."Routing Reference No.");

        Assert.AreEqual(ProdOrderLine.Description, PurchaseLine.Description, '');

        // [TEARDOWN]
        UpdateSubMgmtSetupTransferInfoLine(false);
    end;

    [Test]
    procedure TestTransferOfSubcontractingTypeProdBOMLineToProdOrderComp()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Check Transfer of Subcontracting Type from Production BOM Line to Prod Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Purchase);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [WHEN] Creating Production Order to Transfer Information
        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [THEN] Check if Production BOM Line with additional Component for Subcontracting Type exists
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.SetRange("Subcontracting Type", ProductionBOMLine."Subcontracting Type"::Purchase);
        Assert.RecordIsNotEmpty(ProductionBOMLine);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure TestCreationOfSubcontrTransferOrderFromSubcontrPurchOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] and Transfer additional Line with marked Component ;

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateManufacturingSetupWithSubcontractingLocation();
        SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Check if Purchase Line with additional Component for Subcontracting Type exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        Assert.RecordIsNotEmpty(TransferLine);

        // [TEARDOWN]
        UpdateSubMgmtSetupDirectTransfer(false);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure TestLocationInSubContractorTransferOrderAndComponentLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        CompLocation, TransferFrom : Code[10];
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] check if Component Line Location Code and Transfer Form Code are equal

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateManufacturingSetupWithSubcontractingLocation();
        SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", "Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        //[GIVEN] Keep Location Code for later Check
        CompLocation := ProdOrderComp."Location Code";

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        //[GIVEN] Keep Location Code for later Check
        TransferFrom := TransferHeader."Transfer-from Code";

        // [THEN] Check if Component Location Code and Transfer Form Code are equal
        Assert.AreEqual(CompLocation, TransferFrom, 'Transfer-from Code is not expected');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure TestLocationInSubContractorTransferOrderAndComponentLineWithChangeCompLineLocation()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        CompLocation, TransferFrom : Code[10];
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] Change Component Location Code and check if Component Line Location Code and Transfer Form Code are equal

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateManufacturingSetupWithSubcontractingLocation();
        SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", "Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        ProdOrderComp."Location Code" := Location.Code;
        ProdOrderComp.Modify();

        //[GIVEN] Keep Location Code for later Check
        CompLocation := ProdOrderComp."Location Code";

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");

        //[GIVEN] Keep Location Code for later Check
        TransferFrom := TransferHeader."Transfer-from Code";

        // [THEN] Check if Component Location Code and Transfer Form Code are equal
        Assert.AreEqual(CompLocation, TransferFrom, 'Transfer-from Code is not expected');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,HandleCreateTransferOrderMsg')]
    procedure CheckTransferOrderFromSubcontrAndReturnTransferOrderFromSubcontractorPurchOrder()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        TransferFrom1, TransferFrom2, TransferTo1, TransferTo2 : Code[10];
        PurchaseHeaderPage: TestPage "Purchase Order";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO]  Post transfer Order and Create Return Transfer Order
        // [SCENARIO] check if Transfer-from and Transfer-to Locations are reversed

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateManufacturingSetupWithSubcontractingLocation();
        SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Check if Purchase Line with additional Component for Subcontracting Type exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.SetRange("No.", TransferLine."Document No.");
        TransferHeader.FindFirst();

        //[GIVEN]create Inventory for Transfer
        Item.Get(ProdOrderComp."Item No.");
        Location.Get(TransferHeader."Transfer-from Code");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");

        //[GIVEN] Keep Transfer Locations values for later Check
        TransferFrom1 := TransferHeader."Transfer-from Code";
        TransferTo1 := TransferHeader."Transfer-to Code";

        //[WHEN] Post Transfer Order
        TransferOrder.OpenView();
        TransferOrder.GoToRecord(TransferHeader);
        TransferOrder.Post.Invoke();

        //[WHEN] Create Return Transfer Order
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.SetRange("No.", TransferLine."Document No.");
        TransferHeader.FindFirst();

        //[GIVEN] Keep Transfer Locations values for later Check
        TransferFrom2 := TransferHeader."Transfer-from Code";
        TransferTo2 := TransferHeader."Transfer-to Code";

        //[THEN] Check if Transfer-from and Transfer-to Locations are reversed
        Assert.AreEqual(TransferFrom1, TransferTo2, 'Transfer-from and Transfer-to Locations are reversed');
        Assert.AreEqual(TransferTo1, TransferFrom2, 'Transfer-from and Transfer-to Locations are reversed');

        // [TEARDOWN]
        UpdateSubMgmtSetupDirectTransfer(false);
    end;

    [Test]
    procedure TestChangeLocationOnProdOrderCompWithSubcontractingTypePurchase()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        ActualLocationCode: Code[10];
    begin
        // [SCENARIO] Check change Location Code by change Subcontracting Type in Prod Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [WHEN] Get actual Location Code and Change Subcontracting Type
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComp.SetFilter("Routing Link Code", '<>%1', '');
        ProdOrderComp.FindFirst();
        ActualLocationCode := ProdOrderComp."Location Code";
        ProdOrderComp.Validate("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Purchase);
        ProdOrderComp.Modify();

        // [THEN] Check if Component Location differs from Origin Location Code ==> Vendor Subcontracting Location Code
        Assert.AreNotEqual(ActualLocationCode, ProdOrderComp."Location Code", '');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess')]

    procedure CheckGenPostGroupInSubContWorksheetAndSubConRoutingLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubManagementSetup: Record "Subc. Management Setup";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        CalculateSubContract: Report "Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        LibraryUtility: Codeunit "Library - Utility";
        GenBusPostingGroup1, GenBusPostingGroup2 : Code[20];
        ProdPostingGroup1, ProdPostingGroup2 : Code[20];
        VATBusPostingGroup1, VATBusPostingGroup2 : Code[20];
        VATProdPostingGroup1, VATProdPostingGroup2 : Code[20];
        ProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Check Gen. Prod. Posting Group value for Subcontracting Purchase Order

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();
        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        WorkCenter2 := WorkCenter[2];
        WorkCenter2."Subcontractor No." := Vendor."No.";
        Vendor."Subcontr. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        //[GIVEN] Create Production Order
        CreateAndRefreshProductionOrder(
               ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        //[GIVEN] Create requisition worksheet template
        ReqWkshTemplate.DeleteAll(true);
        ReqWkshTemplate.Name := SelectRequisitionTemplateName();
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.Validate(
          Name,
          CopyStr(
            LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo(Name), Database::"Requisition Wksh. Name"),
            1, LibraryUtility.GetFieldLength(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Name))));
        RequisitionWkshName.Insert(true);

        //[GIVEN] create Purchase Order from Subcontracting Worksheet
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        CalculateSubContract.SetWkShLine(RequisitionLine);
        CalculateSubContract.UseRequestPage(false);
        CalculateSubContract.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        Assert.AreEqual(ProductionOrder."No.", RequisitionLine."Prod. Order No.", 'Prod. Order No. has not found');

        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        //[GIVEN] Keep Posting Groups values for later Check
        ProdPostingGroup1 := PurchaseLine."Gen. Prod. Posting Group";
        GenBusPostingGroup1 := PurchaseLine."Gen. Bus. Posting Group";
        VATBusPostingGroup1 := PurchaseLine."VAT Bus. Posting Group";
        VATProdPostingGroup1 := PurchaseLine."VAT Prod. Posting Group";

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        //[GIVEN] Delete Purchase Order
        PurchaseHeader.Delete(true);
        Commit();

        SubManagementSetup.Get();
        SubManagementSetup."Subcontracting Template Name" := RequisitionLine."Worksheet Template Name";
        SubManagementSetup."Subcontracting Batch Name" := RequisitionLine."Journal Batch Name";
        SubManagementSetup.Modify();

        // [GIVEN] Create Subcontracting Purchase Order from Prod. Order Routing
        WorkCenter2 := WorkCenter[2];
        WorkCenter2."Subcontractor No." := Vendor."No.";
        WorkCenter2.Modify();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRtng.OpenView();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        ProdOrderRtng.CreateSubcontracting.Invoke();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        //[GIVEN] Keep Posting Groups values for later Check
        ProdPostingGroup2 := PurchaseLine."Gen. Prod. Posting Group";
        GenBusPostingGroup2 := PurchaseLine."Gen. Bus. Posting Group";
        VATBusPostingGroup2 := PurchaseLine."VAT Bus. Posting Group";
        VATProdPostingGroup2 := PurchaseLine."VAT Prod. Posting Group";

        //[THEN] Check if Posting Groups values is the same as Standard
        Assert.AreEqual(ProdPostingGroup1, ProdPostingGroup2, 'Gen. Prod. Posting Group is not Expected');
        Assert.AreEqual(GenBusPostingGroup1, GenBusPostingGroup2, 'Gen. Bus. Posting Group is not Expected');
        Assert.AreEqual(VATBusPostingGroup1, VATBusPostingGroup2, 'VAT Bus. Posting Group is not Expected');
        Assert.AreEqual(VATProdPostingGroup1, VATProdPostingGroup2, 'VAT Prod. Posting Group');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess')]
    procedure CheckGenPostGroupInSubContWorksheetAndSubConInPurchLineFunktion()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RoutingLink: Record "Routing Link";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        CalculateSubContract: Report "Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        LibraryUtility: Codeunit "Library - Utility";
        GenBusPostingGroup1, GenBusPostingGroup2 : Code[20];
        ItemNoOriginPurchLine: Code[20];
        ProdPostingGroup1, ProdPostingGroup2 : Code[20];
        VATBusPostingGroup1, VATBusPostingGroup2 : Code[20];
        VATProdPostingGroup1, VATProdPostingGroup2 : Code[20];
        PurchOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Check change Location Code by change Subcontracting Type in Prod Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();
        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        WorkCenter2 := WorkCenter[2];
        WorkCenter2."Subcontractor No." := Vendor."No.";
        Vendor."Subcontr. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        //[GIVEN] Create Production Order
        CreateAndRefreshProductionOrder(
               ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        //[GIVEN] Create requisition worksheet template
        ReqWkshTemplate.DeleteAll(true);
        ReqWkshTemplate.Name := SelectRequisitionTemplateName();
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.Validate(
          Name,
          CopyStr(
            LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo(Name), Database::"Requisition Wksh. Name"),
            1, LibraryUtility.GetFieldLength(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Name))));
        RequisitionWkshName.Insert(true);

        //[GIVEN] create Purchase Order from Subcontracting Worksheet
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        CalculateSubContract.SetWkShLine(RequisitionLine);
        CalculateSubContract.UseRequestPage(false);
        CalculateSubContract.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        Assert.AreEqual(ProductionOrder."No.", RequisitionLine."Prod. Order No.", 'Prod. Order No. has not found');

        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        //[GIVEN] Keep Gen. Prod. Posting Group value for later Check
        ProdPostingGroup1 := PurchaseLine."Gen. Prod. Posting Group";
        GenBusPostingGroup1 := PurchaseLine."Gen. Bus. Posting Group";
        VATBusPostingGroup1 := PurchaseLine."VAT Bus. Posting Group";
        VATProdPostingGroup1 := PurchaseLine."VAT Prod. Posting Group";

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        //[GIVEN] Delete Purchase Order
        PurchaseHeader.Delete(true);
        Commit();

        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        UpdateSubMgmtRoutingLink(RoutingLink.Code);
        WorkCenter2 := WorkCenter[2];
        UpdateSubMgmtCommonWorkCenter(WorkCenter2."No.");

        //[GIVEN] Create Subcontracting Purchase Order from Purch
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        ItemNoOriginPurchLine := PurchaseLine."No.";
        PurchaseLine.Modify(true);
        Commit();
        PurchOrder.OpenEdit();
        PurchOrder.GoToRecord(PurchaseHeader);
        PurchOrder.PurchLines.CreateProdOrder.Invoke();

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("No.", ItemNoOriginPurchLine);
        PurchaseLine.FindFirst();

        ProdPostingGroup2 := PurchaseLine."Gen. Prod. Posting Group";
        GenBusPostingGroup2 := PurchaseLine."Gen. Bus. Posting Group";
        VATBusPostingGroup2 := PurchaseLine."VAT Bus. Posting Group";
        VATProdPostingGroup2 := PurchaseLine."VAT Prod. Posting Group";

        //[THEN] Check if Gen. Prod. Posting Group is the same as Standard
        Assert.AreEqual(ProdPostingGroup1, ProdPostingGroup2, 'Gen. Prod. Posting Group is not Expected');
        Assert.AreEqual(GenBusPostingGroup1, GenBusPostingGroup2, 'Gen. Bus. Posting Group is not Expected');
        Assert.AreEqual(VATBusPostingGroup1, VATBusPostingGroup2, 'VAT Bus. Posting Group is not Expected');
        Assert.AreEqual(VATProdPostingGroup1, VATProdPostingGroup2, 'VAT Prod. Posting Group');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure TestTransferProdOrderRtngCommentByCreationOfSubcontrPurchOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order
        // [SCENARIO] and test Transfer of Prod Order Rtng. Comment to PurchLine HTML Text;

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // Create Comment Line
        ProdOrderRtngLine.SetRange(Status, ProdOrderRtngLine.Status::Released);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRtngLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRtngLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderRtngCommentLine(ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.", ProdOrderRtngLine."Routing Reference No.", ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Operation No.");

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRtngLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();

        // [THEN] Get transferred Rtng Comment Text
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderRtngLine."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderRtngLine."Routing Reference No.");
        PurchaseLine.FindLast();

        PurchCommentLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchCommentLine.SetRange("No.", PurchaseLine."Document No.");
        PurchCommentLine.SetRange("Document Line No.", PurchaseLine."Line No.");

        Assert.IsFalse(PurchaseLine.IsEmpty(), 'Purchase Comment Line must be filled');

        // [TEARDOWN]
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure TestExpectedErrorOnChangingLocationCodeInProdOrderCompWithTransferOrderFromSubcontrPurchOrder()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderCompPage: TestPage "Prod. Order Components";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] and Transfer additional Line with marked Component ;
        // [SCENARIO] Expected Error on changing Location Code in Prod. Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateManufacturingSetupWithSubcontractingLocation();
        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Check if Purchase Line with additional Component for Subcontracting Type exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        Assert.RecordIsNotEmpty(TransferLine);

        ProdOrderCompPage.OpenEdit();
        ProdOrderCompPage.GoToRecord(ProdOrderComp);
        asserterror ProdOrderCompPage."Location Code".SetValue(Location.Code);
        Assert.ExpectedError('The component has already been assigned to the subcontracting transfer order');

        // [TEARDOWN]
        UpdateSubMgmtSetupDirectTransfer(false);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure TestReceiptDateFromTransferOrderLineFromSubcontrPurchOrderIsEquallyToProdOrderCompDueDate()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubcontractingManagementSetup: Record "Subc. Management Setup";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        ExpectedDate: Date;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] and Transfer additional Line with marked Component ;
        // [SCENARIO] Expected Error on changing Location Code in Prod. Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateSubWhseHandlingTimeInSubManagementSetup();
        UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        UpdateProdOrderCompDueDate(ProductionOrder."No.");

        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Compare Due Date from Prod Order Comp with Receipt Date from Subc. Transfer Line
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.FindFirst();

        SubcontractingManagementSetup.Get();

        ExpectedDate := CalcDate(SubcontractingManagementSetup."Subc. Inb. Whse. Handling Time", TransferLine."Receipt Date");

        Assert.AreEqual(ExpectedDate, ProdOrderComp."Due Date", '');

        // [TEARDOWN]
        UpdateSubMgmtSetupDirectTransfer(false);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure TestLocationAndBinCodeIsSetFromOriginBinCodeAfterDeletingTransferOrder()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        LocationCode: Code[10];
        BinCode: Code[20];
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] and Transfer additional Line with marked Component ;
        // [SCENARIO] Expected Bin Code is filled with Original Bin Code

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationAndBinCode(ProductionOrder."No.", LocationCode, BinCode);

        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Check if Purchase Line with additional Component for Subcontracting Type exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        TransferHeader.Delete(true);

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        Assert.AreEqual(ProdOrderComp."Location Code", LocationCode, '');
        Assert.AreEqual(ProdOrderComp."Bin Code", BinCode, '');

        // [TEARDOWN]
        UpdateSubMgmtSetupDirectTransfer(false);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure CheckBtnTrackingSpecificationOnProdOrderCompOnExistingReserveInTransferLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        AlreadySpecifiedErr: Label 'You cannot open Tracking Specification because this component is already specified in Transfer Order %1.',
Comment = '|%1 = Transfer Order No.';
        ProdOrderCompPage: TestPage "Prod. Order Components";
        PurchaseHeaderPage: TestPage "Purchase Order";
        ExpectedErrorMsg: Text;
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] and Transfer additional Line with marked Component ;
        // [SCENARIO] Expected Error on open Item Tracking Lines in Prod. Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Check if Purchase Line with additional Component for Subcontracting Type exists, Mock Reservation Entries on TransferLine and try to open Item Tracking Lines from Prod order Comp. Page
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        Assert.RecordIsNotEmpty(TransferLine);
        TransferLine.FindFirst();

        MockReservationEntryOnTransferLine(TransferLine, ProdOrderComp);

        ProdOrderCompPage.OpenEdit();
        ProdOrderCompPage.GoToRecord(ProdOrderComp);
        asserterror ProdOrderCompPage.ItemTrackingLines.Invoke();
        ExpectedErrorMsg := StrSubstNo(AlreadySpecifiedErr, TransferLine."Document No.");
        Assert.ExpectedError(ExpectedErrorMsg);

        // [TEARDOWN]
        UpdateSubMgmtSetupDirectTransfer(false);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure TestCheckSubcontractorPriceInFactbox()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: array[2] of Record "Work Center";
        SubPurchaseLineFactbox: TestPage "Subc. Purchase Line Factbox";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order directly from Prod. Order Routing Line
        // Check if No of SubcontractorPrices is displayed

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateSubcontractorPrice(Item, WorkCenter[2]."No.", SubcontractorPrice);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line exists
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        SubPurchaseLineFactbox.OpenView();
        SubPurchaseLineFactbox.GoToRecord(PurchaseLine);
        Assert.AreEqual(SubPurchaseLineFactbox.SubcontractingPrices.Value, Format(SubcontractorPrice.Count()), '');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,SubcontrDispatchingListDefaultRequestPageHandler')]
    procedure TestSubcontrDispatchingList()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        XmlParameters: Text;
    begin
        // [SCENARIO] Create Subcontracting and check Subcontr Dispatching List

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupDirectTransfer(true);

        UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();

        // [THEN] Print Subcontr Dispatching List
        PurchaseHeader.SetRecFilter();
        XmlParameters := Report.RunRequestPage(Report::"Subc. Dispatching List");
        LibraryReportDataset.RunReportAndLoad(Report::"Subc. Dispatching List", PurchaseHeader, XmlParameters);
        // [THEN] the company address line is blank
        LibraryReportDataset.AssertElementWithValueExists('SubcAddrInfoLine', '');
        // [THEN] an exemplary footer element is blank
        LibraryReportDataset.AssertElementWithValueExists('SubcCompanyAddress1', '');
        LibraryReportDataset.AssertElementWithValueExists('Prod__Order_Routing_Line__Prod__Order_No__', ProductionOrder."No.");
    end;

    [Test]
    procedure TestTransferSubcontractingTypeAndVendorLocationIntoPlanningComponent()
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PlanningComponent: Record "Planning Component";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Create Sales Order and test Planning Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        Item."Reordering Policy" := "Reordering Policy"::Order;
        Item.Modify();

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Purchase);

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Order, Customer."No.", Item."No.", 5, Location.Code, WorkDate());

        // [WHEN]
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindLast();
        PlanningComponent.SetRange("Item No.", ProductionBOMLine."No.");
        PlanningComponent.FindFirst();

        // [THEN]
        Assert.Equal(ProductionBOMLine."Subcontracting Type", PlanningComponent."Subcontracting Type");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Assert.Equal(Vendor."Subcontr. Location Code", PlanningComponent."Location Code");
    end;

    [Test]
    procedure TestPostItemChargeAssignedToSubcontractingLing_ValueEntryWithCapacityRelation()
    var
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        ValueEntry: Record "Value Entry";
    begin
        // [SCENARIO] When a Purchase Order is created and the item charge is assigned to a subcontracting line, the value entry should be created with the capacity relation, not with item ledger entry relation.
        // The subcontracting purchase (service) line is created and posted. A new purchase line of type item charge is created, with assignment to subcontracting rcpt line. The the second purchase order is posted
        // and the ledger entries were checked.

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        SetupInventorySetup();

        //[GIVEN] Setup Item Charge Assignment Subcontracting
        SubManagementSetup.Get();
        SubManagementSetup.RefItemChargeToRcptSubLines := true;
        SubManagementSetup.Modify();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Create Subcontracting Purchase Order with Prod Order and Post
        CreateSubcontractingPurchOrderPostAndGetPurchRcptLine(PurchRcptLine);

        // [GIVEN] Create Item Charge Purchase Line and Item Charge Assignment
        CreateItemChargeOrderLine(PurchaseHeader, PurchaseLine, ItemCharge);
        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchaseLine, ItemCharge, "Purchase Applies-to Document Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.", PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        ItemChargeAssignmentPurch.Insert(true);

        // [WHEN] Post Purchase Order with Item Charge
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        //[THEN] Check Value Entry
        ValueEntry.FindLast();
        Assert.AreEqual(0, ValueEntry."Item Ledger Entry No.", 'Item Ledger Entry No. must be zero on value entry.');
        Assert.AreNotEqual(0, ValueEntry."Capacity Ledger Entry No.", 'Capacity Ledger Entry No. must be filled on value entry.');
        Assert.AreEqual("Inventory Order Type"::Production, ValueEntry."Order Type", 'Order Type must be Production on value entry.');
        Assert.AreEqual(0, ValueEntry."Invoiced Quantity", 'Invoiced Quantity must be zero on value entry.');
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        TransfOrderPage.OK().Invoke();
    end;

    [PageHandler]
    procedure HandleWarehouseReceipt(var WhseReceipt: TestPage "Warehouse Receipt")
    begin
        WhseReceipt.OK().Invoke();
    end;

    [MessageHandler]
    procedure HandleCreatedWarehouseReceiptMsg(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    procedure HandleCreateTransferOrderMsg(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure DoNotConfirmShowCreatedPurchOrderForSubcontracting(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RequestPageHandler]
    procedure SubcontrDispatchingListDefaultRequestPageHandler(var PurchaseOrderRequestPage: TestRequestPage "Subc. Dispatching List")
    begin
        // Empty handler used to close the request page. We use default settings.
    end;

    [ConfirmHandler]
    procedure DoConfirmCreateProdOrderForSubcontractingProcess(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            Question.Contains('Do you want to create a production order from'):
                Reply := true;
            else
                Reply := false;
        end;
    end;

    local procedure RemoveSubcontractingManagementSetupRecord()
    var
        SubcontractingManagementSetup: Record "Subc. Management Setup";
    begin
        SubcontractingManagementSetup.DeleteAll();
    end;

    local procedure CheckNoSubcontractingManagementSetupRecordExist()
    begin
        Assert.TableIsEmpty(Database::"Subc. Management Setup");
    end;

    local procedure CheckSubcontractingManagementSetupRecordExist()
    begin
        Assert.TableIsNotEmpty(Database::"Subc. Management Setup");
    end;

    local procedure CreateAndCalculateNeededWorkAndMachineCenter(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
        MachineCenterNo: Code[20];
        MachineCenterNo2: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // [GIVEN] Create and Calculate needed Work and Machine Center
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not Subcontracting, UnitCostCalculation, '');
        WorkCenter[1].Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[1].Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo2, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[2].Get(MachineCenterNo2);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        if Subcontracting then
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", Subcontracting, UnitCostCalculation, '')
        else
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not Subcontracting, UnitCostCalculation, '');
        WorkCenter[2].Get(WorkCenterNo2);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    local procedure CreateItemForProductionIncludeRoutingAndProdBOM(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        NoSeries: Codeunit "No. Series";
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ProductionBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        ManufacturingSetup.SetLoadFields("Routing Nos.");
        ManufacturingSetup.Get();
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.", WorkDate(), true);

        LibraryMfgManagement.CreateRouting(RoutingNo, MachineCenter[1]."No.", MachineCenter[2]."No.", WorkCenter[1]."No.", WorkCenter[2]."No.");

        // Create Items with Flushing method - Manual with the Parent Item containing Routing No. and Production BOM No.

        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo2 := Item."No.";
        Clear(Item);

        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo, ItemNo2, 1); // value important.

        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", RoutingNo, ProductionBOMNo);
    end;

    local procedure UpdateProdBomAndRoutingWithRoutingLink(Item: Record Item; WorkCenterNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.Init();
        RoutingLink.Validate(Code, CopyStr(Item."Production BOM No.", 1, 10));
        RoutingLink.Insert(true);

        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProdBomWithSubcontractingType(Item: Record Item; SubcontractingType: Enum "Subcontracting Type")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine."Subcontracting Type" := SubcontractingType;
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProdOrderCompWithLocationCode(ProdOrderNo: Code[20])
    var
        Location: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ProdOrderComp."Location Code" := Location.Code;
        ProdOrderComp.Modify();
    end;

    local procedure UpdateProdOrderCompWithLocationAndBinCode(ProdOrderNo: Code[20]; var LocationCode: Code[10]; var BinCode: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Bin Mandatory" := true;
        Location.Modify();
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        ProdOrderComp."Location Code" := Location.Code;
        ProdOrderComp."Bin Code" := Bin.Code;
        ProdOrderComp.Modify();

        LocationCode := Location.Code;
        BinCode := Bin.Code;
    end;

    local procedure UpdateProdOrderCompDueDate(ProdOrderNo: Code[20])
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        ProdOrderComp."Due Date" := CalcDate('<+10D>', WorkDate());
        ProdOrderComp.Modify();
    end;

    local procedure UpdateVendorWithSubcontractingLocationCode(WorkCenter: Record "Work Center")
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
    end;

    procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean; UnitCostCalc: Option; CurrencyCode: Code[10])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center with required fields where random is used, values not important for test.
        LibraryMfgManagement.CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);

        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalc);

        if Subcontract then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateSubcontractingPurchOrderPostAndGetPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        WorkCenter2 := WorkCenter[2];
        WorkCenter2."Subcontractor No." := Vendor."No.";
        Vendor."Subcontr. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);

        Codeunit.Run(Codeunit::"Subc. Create Prod. Ord. Opt.", PurchaseLine);

        EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure EnsureGeneralPostingSetupIsValid(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then begin
            if GeneralPostingSetup.Blocked then begin
                GeneralPostingSetup.Blocked := false;
                GeneralPostingSetup.Modify();
            end;
            exit;
        end;

        GeneralPostingSetup.Init();
        GeneralPostingSetup."Gen. Bus. Posting Group" := GenBusPostingGroup;
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup;
        GeneralPostingSetup.Insert();
        GeneralPostingSetup.SuggestSetupAccounts();
    end;

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20])
    begin
        // Create Item with required fields where random values not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(10), ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 2));
        Item.Modify(true);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Subcontracting Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Subcontracting Test");

        SubSetupLibrary.InitSetupFields();
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Subcontracting Test");
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderSourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProdOrderStatus, ProdOrderSourceType, SourceNo, Quantity);
    end;

    local procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        LibraryMfgManagement.CreateLaborReqWkshTemplateAndNameAndUpdateSetup();
    end;

    local procedure UpdateSubMgmtSetupTransferInfoLine(Update: Boolean)
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Create Prod. Order Info Line" := Update;
        EsMgmtSetup.Modify();
    end;

    local procedure UpdateSubMgmtSetupDirectTransfer(Update: Boolean)
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Direct Transfer" := Update;
        EsMgmtSetup.Modify();
    end;

    local procedure UpdateSubMgmtSetup_ComponentAtLocation(CompAtLocation: Enum "Components at Location")
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Component at Location" := CompAtLocation;
        EsMgmtSetup.Modify();
    end;

    local procedure CreateSubcontractingOrderFromProdOrderRtngPage(RoutingNo: Code[20]; WorkCenterNo: Code[20])
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        ProdOrderRtngLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRtngLine.FindFirst();

        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRtngLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();
    end;

    local procedure UpdateSubWhseHandlingTimeInSubManagementSetup()
    var
        SubManagementSetup: Record "Subc. Management Setup";
    begin
        if not SubManagementSetup.Get() then
            exit;

        Evaluate(SubManagementSetup."Subc. Inb. Whse. Handling Time", '<1D>');
        SubManagementSetup.Modify();
    end;

    local procedure SetupInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        LibraryUtility: Codeunit "Library - Utility";
    begin
        if not InventorySetup.Get() then
            InventorySetup.Init();

        LibraryInventory.NoSeriesSetup(InventorySetup);
        InventorySetup."Inventory Put-away Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    local procedure MockReservationEntryOnTransferLine(TransferLine: Record "Transfer Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.DeleteAll();
        ReservationEntry.Init();
        ReservationEntry."Source Type" := Database::"Transfer Line";
        ReservationEntry."Source ID" := TransferLine."Document No.";
        ReservationEntry."Source Ref. No." := TransferLine."Line No.";
        ReservationEntry."Item No." := ProdOrderComponent."Item No.";
        ReservationEntry."Variant Code" := ProdOrderComponent."Variant Code";
        ReservationEntry.Insert();
    end;

    local procedure CreateTransferRoute(WorkCenter: Record "Work Center"; ProductionOrder: Record "Production Order")
    var
        TransitLocation: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        TransferRoute: Record "Transfer Route";
        Vendor: Record Vendor;
    begin
        Vendor.Get(WorkCenter."Subcontractor No.");
        ProdOrderComp.SetRange(Status, ProductionOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, ProdOrderComp."Location Code", Vendor."Subcontr. Location Code", TransitLocation.Code, '', '');
    end;

    local procedure UpdateManufacturingSetupWithSubcontractingLocation()
    var
        Location: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ManufacturingSetup.Get();
        ManufacturingSetup."Components at Location" := Location.Code;
        ManufacturingSetup.Modify();
        UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Manufacturing);
    end;

    procedure CreateInventory(Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
        ItemJournalLine, Item."No.", Location.Code, Bin.Code, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateSubMgmtRoutingLink(RtngLink: Code[10])
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Rtng. Link Code Purch. Prov." := RtngLink;
        EsMgmtSetup.Modify();
    end;

    local procedure UpdateSubMgmtCommonWorkCenter(WorkCenterNo: Code[20])
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Common Work Center No." := WorkCenterNo;
        EsMgmtSetup.Modify();
    end;

    local procedure CreateItemChargeOrderLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ItemCharge: Record "Item Charge")
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    procedure SelectRequisitionTemplateName(): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"For. Labor");
        ReqWkshTemplate.SetRange(Recurring, false);
        if not ReqWkshTemplate.FindFirst() then begin
            ReqWkshTemplate.Init();
            ReqWkshTemplate.Validate(
              Name, LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"));
            ReqWkshTemplate.Insert(true);
            ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::"For. Labor");
            ReqWkshTemplate."Page ID" := Page::"Subcontracting Worksheet";
            ReqWkshTemplate.Modify(true);
        end;
        exit(ReqWkshTemplate.Name);
    end;

    var
        WorkCenter2: Record "Work Center";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        UnitCostCalculation: Option Time,Units;
}