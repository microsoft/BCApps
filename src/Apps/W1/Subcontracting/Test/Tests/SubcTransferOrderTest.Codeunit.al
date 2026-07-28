// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
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
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 139993 "Subc. Transfer Order Test"
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
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
    procedure CreateTransferOrderFromSecondSubcontractingOrderOpensReusedTransferOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        ProductionLocation: Record Location;
        FirstTransferOrderNo: Code[20];
        SecondTransferOrderNo: Code[20];
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 634237] Creating transfer order for a second subcontracting PO should create and open a different transfer order.

        // [GIVEN] Subcontracting setup with transfer components and an initial subcontracting order with transfer order already created
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder1, "Production Order Status"::Released, ProductionOrder1."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SetAllProdOrderTransferComponentLocations(ProductionOrder1."No.", ProductionLocation.Code);

        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder1);

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder1."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();
        ReleasedProdOrderRtng.Close();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder1."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader1.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader1);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseHeaderPage.Close();

        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader1."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'Expected transfer order for the first subcontracting purchase order.');
        FirstTransferOrderNo := TransferHeader."No.";
        Assert.AreEqual(PurchaseHeader1."No.", TransferHeader."Subcontr. Purch. Order No.", 'First transfer order must be linked to the first subcontracting purchase order.');

        // [GIVEN] A second released production order for the same subcontracting setup
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder2, "Production Order Status"::Released, ProductionOrder2."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetAllProdOrderTransferComponentLocations(ProductionOrder2."No.", ProductionLocation.Code);

        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder2."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();
        ReleasedProdOrderRtng.Close();

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder2."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Assert.AreNotEqual(PurchaseHeader1."No.", PurchaseHeader2."No.", 'Second production order should create another subcontracting purchase order.');

        // [WHEN] Creating transfer order from the second subcontracting purchase order
        OpenedTransferOrderNo := '';
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader2);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseHeaderPage.Close();

        TransferHeader.Reset();
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader2."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'Expected transfer order for the second subcontracting purchase order.');
        SecondTransferOrderNo := TransferHeader."No.";
        Assert.AreEqual(PurchaseHeader2."No.", TransferHeader."Subcontr. Purch. Order No.", 'Second transfer order must be linked to the second subcontracting purchase order.');

        // [THEN] A new transfer order is opened for the second subcontracting purchase order and contains lines for the second production order
        Assert.AreNotEqual(FirstTransferOrderNo, SecondTransferOrderNo, 'A different subcontracting purchase order must create a new transfer order.');
        Assert.AreEqual(SecondTransferOrderNo, OpenedTransferOrderNo, 'The transfer order opened from the second subcontracting PO must belong to that purchase order.');
        TransferHeader.Get(FirstTransferOrderNo);
        Assert.AreEqual(PurchaseHeader1."No.", TransferHeader."Subcontr. Purch. Order No.", 'First transfer order must remain linked to the first subcontracting purchase order.');
        TransferHeader.Get(SecondTransferOrderNo);
        Assert.AreEqual(PurchaseHeader2."No.", TransferHeader."Subcontr. Purch. Order No.", 'Second transfer order must remain linked to the second subcontracting purchase order.');

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", SecondTransferOrderNo);
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder2."No.");
        Assert.RecordIsNotEmpty(TransferLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
    procedure CannotDeleteSubcontractingOrderWithAssociatedTransferOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
        PurchaseOrderNo: Code[20];
    begin
        // [SCENARIO 630806] Deleting a Subcontracting Order is blocked when an associated Transfer Order exists
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Work and Machine Centers, an Item with Routing and Prod. BOM configured for Transfer subcontracting
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A Released Production Order (not created from a Purchase Order)
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [GIVEN] A Subcontracting Order created from the Production Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseOrderNo := PurchaseHeader."No.";

        // [GIVEN] A Transfer Order created from the Subcontracting Order
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [WHEN] The Subcontracting Order is attempted to be deleted
        asserterror PurchaseHeader.Delete(true);

        // [THEN] An error is raised and the Transfer Order still exists
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseOrderNo);
        Assert.RecordIsNotEmpty(TransferHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
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
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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

        // [THEN] Check if Purchase Line with additional Component for Component Supply Method exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        Assert.RecordIsNotEmpty(TransferLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
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
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", "Component Supply Method"::"Transfer to Vendor");
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

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        //[GIVEN] Keep Location Code for later Check
        TransferFrom := TransferHeader."Transfer-from Code";

        // [THEN] Check if Component Location Code and Transfer Form Code are equal
        Assert.AreEqual(CompLocation, TransferFrom, 'Transfer-from Code is not expected');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
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
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", "Component Supply Method"::"Transfer to Vendor");
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

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");

        //[GIVEN] Keep Location Code for later Check
        TransferFrom := TransferHeader."Transfer-from Code";

        // [THEN] Check if Component Location Code and Transfer Form Code are equal
        Assert.AreEqual(CompLocation, TransferFrom, 'Transfer-from Code is not expected');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder,HandleCreateTransferOrderMsg')]
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
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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

        // [THEN] Check if Purchase Line with additional Component for Component Supply Method exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComp."Line No.");
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

        //[GIVEN] Enable direct transfer for posting
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);

        //[WHEN] Post Transfer Order
        TransferOrder.OpenView();
        TransferOrder.GoToRecord(TransferHeader);
        TransferOrder.Post.Invoke();

        //[WHEN] Create Return Transfer Order
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.SetRange("No.", TransferLine."Document No.");
        TransferHeader.FindFirst();

        //[GIVEN] Keep Transfer Locations values for later Check
        TransferFrom2 := TransferHeader."Transfer-from Code";
        TransferTo2 := TransferHeader."Transfer-to Code";

        //[THEN] Check if Transfer-from and Transfer-to Locations are reversed
        Assert.AreEqual(TransferFrom1, TransferTo2, 'Transfer-from and Transfer-to Locations are reversed');
        Assert.AreEqual(TransferTo1, TransferFrom2, 'Transfer-from and Transfer-to Locations are reversed');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
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
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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

        // [THEN] Check if Purchase Line with additional Component for Component Supply Method exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        Assert.RecordIsNotEmpty(TransferLine);

        ProdOrderCompPage.OpenEdit();
        ProdOrderCompPage.GoToRecord(ProdOrderComp);
        asserterror ProdOrderCompPage."Location Code".SetValue(Location.Code);
        Assert.ExpectedError('The component has already been assigned to the subcontracting transfer order');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
    procedure TestReceiptDateFromTransferOrderLineFromSubcontrPurchOrderIsEquallyToProdOrderCompDueDate()
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
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedDate: Date;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] and Transfer additional Line with marked Component ;
        // [SCENARIO] Expected Error on changing Location Code in Prod. Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        UpdateSubWhseHandlingTimeInSubManagementSetup();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        UpdateProdOrderCompDueDate(ProductionOrder."No.");

        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.FindFirst();

        ManufacturingSetup.Get();

        ExpectedDate := CalcDate(ManufacturingSetup."Subc. Comp. Transfer Lead Time", TransferLine."Receipt Date");

        Assert.AreEqual(ExpectedDate, ProdOrderComp."Due Date", 'Prod. Order Component due date should be recalculated from the transfer receipt date and subcontracting lead time.');

    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
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
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        UpdateProdOrderCompWithLocationAndBinCode(ProductionOrder."No.", LocationCode, BinCode);

        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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

        // [THEN] Check if Purchase Line with additional Component for Component Supply Method exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        TransferHeader.Delete(true);

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        Assert.AreEqual(ProdOrderComp."Location Code", LocationCode, '');
        Assert.AreEqual(ProdOrderComp."Bin Code", BinCode, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
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
        ProdOrderCompPage: TestPage "Prod. Order Components";
        PurchaseHeaderPage: TestPage "Purchase Order";
        ExpectedErrorMsg: Text;
    begin
        // [SCENARIO] Create Subcontracting Transfer Order directly from Subcontracting Purchase Order
        // [SCENARIO] and Transfer additional Line with marked Component ;
        // [SCENARIO] Expected Error on open Item Tracking Lines in Prod. Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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

        // [THEN] Check if Purchase Line with additional Component for Component Supply Method exists, Mock Reservation Entries on TransferLine and try to open Item Tracking Lines from Prod order Comp. Page
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");

        Assert.RecordIsNotEmpty(TransferLine);
        TransferLine.FindFirst();

        MockReservationEntryOnTransferLine(TransferLine, ProdOrderComp);

        ProdOrderCompPage.OpenEdit();
        ProdOrderCompPage.GoToRecord(ProdOrderComp);
        asserterror ProdOrderCompPage.ItemTrackingLines.Invoke();
        ExpectedErrorMsg := StrSubstNo(AlreadySpecifiedErr, TransferLine."Document No.");
        Assert.ExpectedError(ExpectedErrorMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrderReopen')]
    procedure FactboxDrilldownTransferOrderReopenPersists()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        WorkCenter: array[2] of Record "Work Center";
        ProductionLocation: Record Location;
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
        PurchaseHeaderPage: TestPage "Purchase Order";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Bug 634267 - Reopen Transfer Order does not persist when opened from Subcontracting Details Factbox.
        // ShowTransferOrdersAndReturnOrder must open the page on a real database record, so actions like
        // Reopen that modify Rec directly persist after the page closes.

        // [GIVEN] Subcontracting setup with transfer components and a released transfer order
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SetAllProdOrderTransferComponentLocations(ProductionOrder."No.", ProductionLocation.Code);
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();
        ReleasedProdOrderRtng.Close();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseHeaderPage.Close();

        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.FindFirst();
        ReleaseTransferDocument.Release(TransferHeader);
        Assert.AreEqual(TransferHeader.Status::Released, TransferHeader.Status, 'Transfer order should be Released before the test.');

        // [WHEN] Opening the transfer order from the factbox drill-down and performing Reopen
        // The page handler HandleTransferOrderReopen will reopen the transfer order
        PurchaseLine.FindFirst();
        SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder(PurchaseLine, true, false);

        // [THEN] The transfer order status must be Open after closing the page
        TransferHeader.Get(TransferHeader."No.");
        Assert.AreEqual(TransferHeader.Status::Open, TransferHeader.Status,
            'Transfer order status should be Open after Reopen from factbox drill-down. Before the fix, the Reopen modified a marked record and the change was lost.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder,HandleCreateTransferOrderMsg')]
    procedure PostingDirectSubcontractingTransferSetsSourceFieldsOnDirectTransHeader()
    var
        Bin: Record Bin;
        DirectTransHeader: Record "Direct Trans. Header";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 617373] Posting a direct subcontracting transfer correctly propagates Source Type and Source ID to the Direct Trans. Header

        // [GIVEN] Complete manufacturing setup (no in-transit transfer route, so the report creates a Direct Transfer)
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // [GIVEN] Subcontracting purchase order and transfer order to vendor
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");

        Item.Get(ProdOrderComp."Item No.");
        Location.Get(TransferHeader."Transfer-from Code");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");

        // [WHEN] Post the direct transfer
        Codeunit.Run(Codeunit::"TransferOrder-Post Transfer", TransferHeader);

        // [THEN] Direct Trans. Header has Source Type = Subcontracting and Source ID = Vendor No.
        DirectTransHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(DirectTransHeader);
        DirectTransHeader.FindFirst();
        Assert.AreEqual(
            "Transfer Source Type"::Subcontracting, DirectTransHeader."Source Type",
            'Source Type must be Subcontracting on Direct Trans. Header');
        Assert.AreEqual(
            Vendor."No.", DirectTransHeader."Source ID",
            'Source ID must be the Vendor No. on Direct Trans. Header');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
    procedure CreateReturnTransferOrderAfterPartialShipOfOutbound()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
        OutboundFromCode, OutboundToCode : Code[10];
        QtyPartialShip: Decimal;
    begin
        // [SCENARIO] Non-direct (in-transit) transfer: Return from Subcontractor must succeed when the outbound Transfer Order is only partially shipped, and a second Return attempt must be blocked with the existing error.
        // [SCENARIO] Pre-fix the report errored 'Return from Subcontractor has already been created' on the first call because CheckTransferLineExists matched the unrelated outbound line.

        // [GIVEN] Standard subcontracting setup with an in-transit transfer route (non-direct)
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        // [GIVEN] Outbound Subcontracting Transfer Order created from the Purchase Order
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        OutboundFromCode := TransferHeader."Transfer-from Code";
        OutboundToCode := TransferHeader."Transfer-to Code";

        // [GIVEN] Inventory at the source location and the outbound TO is partially shipped via Qty. to Ship (Ship only — items move to in-transit, line stays open with positive Outstanding)
        Location.Get(OutboundFromCode);
        Item.Get(ProdOrderComp."Item No.");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");

        QtyPartialShip := Round(TransferLine.Quantity / 2, 1, '<');
        TransferLine.Validate("Qty. to Ship", QtyPartialShip);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Creating a Return Transfer Order while the outbound TO line is still present (partially shipped)
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] A Return Transfer Order is created with reversed Transfer-from / Transfer-to and quantity capped by the partially-shipped qty
        ReturnTransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        ReturnTransferHeader.SetRange("Subc. Return Order", true);
        Assert.IsTrue(ReturnTransferHeader.FindFirst(), 'Return Transfer Order should be created after partial ship of outbound');
        Assert.AreEqual(OutboundToCode, ReturnTransferHeader."Transfer-from Code", 'Return Transfer-from must be the subcontractor location');
        Assert.AreEqual(OutboundFromCode, ReturnTransferHeader."Transfer-to Code", 'Return Transfer-to must be the original component location');

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", ReturnTransferHeader."No.");
        Assert.IsTrue(TransferLine.FindFirst(), 'Return Transfer Line should exist');
        Assert.AreEqual(QtyPartialShip, TransferLine.Quantity, 'Return quantity should equal the in-transit qty from the partial outbound shipment');

        // [WHEN] Trying to create the Return Transfer Order again, with a Return TO already in place
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        asserterror PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] The duplicate is blocked with the existing error
        Assert.ExpectedError('Nothing to create. No components or WIP items to return for the specified subcontracting order');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
    procedure CreateReturnTransferOrderAfterPartialShipOfOutboundDirectTransfer()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
        OutboundFromCode, OutboundToCode : Code[10];
        QtyPartialShip: Decimal;
    begin
        // [SCENARIO] Direct transfer (no in-transit route): Return from Subcontractor must succeed when the outbound Transfer Order has been partially direct-transferred, and a second Return attempt must be blocked with the existing error.
        // [SCENARIO] In direct-transfer mode Qty. to Ship is forced to equal Quantity, so a partial transfer is achieved by reducing the line Quantity before posting. After the post the items already sit at the subcontractor and the outbound line is consumed.

        // [GIVEN] Standard subcontracting setup WITHOUT an in-transit transfer route — the outbound TO will be Direct Transfer
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        // [GIVEN] Outbound Subcontracting Transfer Order created from the Purchase Order (Direct Transfer because no in-transit route)
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComp."Line No.");
        TransferLine.FindFirst();

        TransferHeader.Get(TransferLine."Document No.");
        OutboundFromCode := TransferHeader."Transfer-from Code";
        OutboundToCode := TransferHeader."Transfer-to Code";

        // [GIVEN] Inventory at the source location and the outbound Quantity is reduced to a partial value, then direct-transferred (Ship+Receive in one operation — items land at the subcontractor location)
        Location.Get(OutboundFromCode);
        Item.Get(ProdOrderComp."Item No.");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");

        QtyPartialShip := Round(TransferLine.Quantity / 2, 1, '<');
        TransferLine.Validate(Quantity, QtyPartialShip);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // [WHEN] Creating a Return Transfer Order while items are now at the subcontractor
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] A Return Transfer Order is created with reversed Transfer-from / Transfer-to and quantity capped by the qty that actually arrived at the subcontractor
        ReturnTransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        ReturnTransferHeader.SetRange("Subc. Return Order", true);
        Assert.IsTrue(ReturnTransferHeader.FindFirst(), 'Return Transfer Order should be created after partial direct transfer');
        Assert.AreEqual(OutboundToCode, ReturnTransferHeader."Transfer-from Code", 'Return Transfer-from must be the subcontractor location');
        Assert.AreEqual(OutboundFromCode, ReturnTransferHeader."Transfer-to Code", 'Return Transfer-to must be the original component location');

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", ReturnTransferHeader."No.");
        Assert.IsTrue(TransferLine.FindFirst(), 'Return Transfer Line should exist');
        Assert.AreEqual(QtyPartialShip, TransferLine.Quantity, 'Return quantity should equal the qty already at the subcontractor');

        // [WHEN] Trying to create the Return Transfer Order again, with a Return TO already in place
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        asserterror PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] The duplicate is blocked with the existing error
        Assert.ExpectedError('Nothing to create. No components or WIP items to return for the specified subcontracting order');
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        OpenedTransferOrderNo := CopyStr(TransfOrderPage."No.".Value(), 1, MaxStrLen(OpenedTransferOrderNo));
        TransfOrderPage.OK().Invoke();
    end;

    [PageHandler]
    procedure HandleTransferOrderReopen(var TransfOrderPage: TestPage "Transfer Order")
    begin
        TransfOrderPage."Reo&pen".Invoke();
        TransfOrderPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure HandleCreateTransferOrderMsg(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        case true of
            Question.Contains('Do you want to create a production order from'):
                Reply := true;
            else
                Reply := false;
        end;
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

    local procedure SetAllProdOrderTransferComponentLocations(ProdOrderNo: Code[20]; LocationCode: Code[10])
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        if ProdOrderComp.FindSet() then
            repeat
                ProdOrderComp.Validate("Location Code", LocationCode);
                ProdOrderComp.Modify(true);
            until ProdOrderComp.Next() = 0;
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

    local procedure UpdateProdOrderCompWithLocationAndBinCode(ProdOrderNo: Code[20]; var LocationCode: Code[10]; var BinCode: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
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
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
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
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
    end;

    local procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean;
                                                                                                           UnitCostCalc: Option;
                                                                                                           CurrencyCode: Code[10])
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

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy";
                                                                             FlushingMethod: Enum "Flushing Method";
                                                                             RoutingNo: Code[20];
                                                                             ProductionBOMNo: Code[20])
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Transfer Order Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        LibraryVariableStorage.Clear();

        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Transfer Order Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Transfer Order Test");
    end;

    local procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
    end;

    local procedure UpdateSubWhseHandlingTimeInSubManagementSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        Evaluate(ManufacturingSetup."Subc. Comp. Transfer Lead Time", '<1D>');
        ManufacturingSetup.Modify();
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

    procedure CreateInventory(Item: Record Item; Location: Record Location; Bin: Record Bin; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
        ItemJournalLine, Item."No.", Location.Code, Bin.Code, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        OpenedTransferOrderNo: Code[20];
        UnitCostCalculation: Option Time,Units;
        AlreadySpecifiedErr: Label 'You cannot open Tracking Specification because this component is already specified in Transfer Order %1.', Comment = '|%1 = Transfer Order No.';

}
