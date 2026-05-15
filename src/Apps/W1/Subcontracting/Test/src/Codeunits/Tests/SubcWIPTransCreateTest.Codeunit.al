// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Planning;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 149911 "Subc. WIP Trans. Create Test"
{
    // [FEATURE] WIP Item Transfer for Subcontracting
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure TransferWIPItemFlagFromRoutingLineToPurchaseLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContracts: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // [SCENARIO] The "Transfer WIP Item" flag set on a Routing Line is propagated through the
        // Prod. Order Routing Line to the Purchase Line when the subcontracting purchase order
        // is created via the Subcontracting Worksheet (Calculate Subcontracts → Carry Out Action).

        // [GIVEN] Complete setup of Manufacturing, Work- and Machine Centers, subcontracting item
        Initialize();

        // [GIVEN] Create work centers and machine centers
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create item with routing and prod. BOM – set "Transfer WIP Item" on routing
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Verify Prod. Order Routing Line carries the flag
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.IsTrue(ProdOrderRoutingLine."Transfer WIP Item",
            'Prod. Order Routing Line must inherit Transfer WIP Item from Routing Line.');

        // [GIVEN] Setup requisition worksheet
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Calculate Subcontracts and Carry Out Action Msg creates Purchase Order
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubContracts.UseRequestPage(false);
        SubcCalculateSubContracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] Purchase Line carries "Transfer WIP Item" = true
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        Assert.IsTrue(PurchaseLine."Transfer WIP Item",
            'Purchase Line must carry "Transfer WIP Item" = true from Prod. Order Routing Line.');
    end;

    [Test]
    procedure TransferWIPItemFlagNotSetWhenRoutingLineHasFlagOff()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContracts: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // [SCENARIO] When "Transfer WIP Item" is NOT set on the Routing Line,
        // the Purchase Line must NOT have the flag set.

        // [GIVEN] Setup
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        // Routing line "Transfer WIP Item" defaults to false – do NOT set it

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Verify flag is false on Prod. Order Routing Line
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.IsFalse(ProdOrderRoutingLine."Transfer WIP Item",
            'Prod. Order Routing Line must NOT have Transfer WIP Item when routing line does not set it.');

        // [GIVEN] Setup worksheet
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Create Purchase Order via Subcontracting Worksheet
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubContracts.UseRequestPage(false);
        SubcCalculateSubContracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] Purchase Line carries "Transfer WIP Item" = false
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        Assert.IsFalse(PurchaseLine."Transfer WIP Item",
            'Purchase Line must NOT carry "Transfer WIP Item" when routing line flag is off.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure WIPAndCompTransferOrderCreatedFromSubcontrPurchOrder_SameLocation()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When a Subcontracting Purchase Order is created for a routing line with
        // "Transfer WIP Item" = true, running "Create Transfer Order to Subcontractor" creates
        // a WIP Transfer Line with "Transfer WIP Item" = true, correct item, quantity, and locations.
        // Component lines and WIP Transfer Lines are created with the same locations.

        // [GIVEN] Complete setup
        Initialize();

        // [GIVEN] Work centers, machine centers, item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Set up component transfer infrastructure
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] A WIP Transfer Line exists with correct properties
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        //Only One transfer header should have been created for both the component and WIP transfer lines
        TransferLine.FindFirst();
        TransferLine.SetFilter("Document No.", '<>%1', TransferLine."Document No.");
        Assert.RecordCount(TransferLine, 0);

        //Only one of the two lines should have the Transfer WIP Item flag set
        TransferLine.SetRange("Document No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Transfer Line must reference the production order parent item.');
        Assert.AreEqual(ProductionOrder.Quantity, TransferLine.Quantity,
            'WIP Transfer Line must have the same quantity as the production order.');

        // [THEN] Transfer header has correct from/to locations
        TransferHeader.Get(TransferLine."Document No.");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Assert.AreEqual(Vendor."Subcontr. Location Code", TransferHeader."Transfer-to Code",
            'WIP Transfer must go TO the subcontractor location.');

        // [TEARDOWN]
        TransferHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrders')]
    procedure WIPAndCompTransferOrderCreatedFromSubcontrPurchOrder_DifferentLocation()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When a Subcontracting Purchase Order is created for a routing line with
        // "Transfer WIP Item" = true, running "Create Transfer Order to Subcontractor" creates
        // a WIP Transfer Line with "Transfer WIP Item" = true, correct item, quantity, and locations.
        // Component lines and WIP Transfer Lines are created with different locations.

        // [GIVEN] Complete setup
        Initialize();

        // [GIVEN] Work centers, machine centers, item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Set up component transfer infrastructure
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No."); //different location for component transfer than WIP transfer
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [WHEN] Create Transfer Order to Subcontractor
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Transfer Lines exists with correct properties
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        //two transfer headers should have been created for both the component and WIP transfer lines
        TransferLine.FindFirst();
        TransferLine.SetFilter("Document No.", '<>%1', TransferLine."Document No.");
        Assert.RecordCount(TransferLine, 1);

        //Only one of the two lines should have the Transfer WIP Item flag set
        TransferLine.SetRange("Document No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        Assert.RecordCount(TransferLine, 1);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Transfer Line must reference the production order parent item.');
        Assert.AreEqual(ProductionOrder.Quantity, TransferLine.Quantity,
            'WIP Transfer Line must have the same quantity as the production order.');

        // [THEN] Transfer header has correct from/to locations
        TransferHeader.Get(TransferLine."Document No.");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Assert.AreEqual(Vendor."Subcontr. Location Code", TransferHeader."Transfer-to Code",
            'WIP Transfer must go TO the subcontractor location.');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure WIPTransferOrderNotCreatedWhenFlagIsOff()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When "Transfer WIP Item" flag is NOT set on the routing line, creating
        // a Transfer Order to Subcontractor must NOT create a WIP Transfer Line.

        // [GIVEN] Setup
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        // Do NOT set Transfer WIP Item on routing line

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [WHEN] Create Purchase Order and Transfer Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] No WIP Transfer Line exists
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Transfer WIP Item", true);
        Assert.RecordIsEmpty(TransferLine);
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure NoWIPTransferCreatedWhenExpectedEqualsPostedQuantity()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When the posted WIP quantity equals the expected quantity at the destination,
        // the CheckCreateWIPTransfer procedure should return false, and no new WIP Transfer Order
        // should be created when "Create Transfer Order to Subcontractor" is invoked again.

        // [GIVEN] Complete setup
        Initialize();

        // [GIVEN] Work centers, machine centers, item with routing + BOM
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Get routing line information
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Create first Subcontracting Purchase Order and Transfer Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [GIVEN] Verify first WIP Transfer Line was created
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Return Order", false);
        Assert.RecordCount(TransferLine, 1);
        TransferLine.FindFirst();

        // [GIVEN] Simulate posting the transfer by creating WIP Ledger Entry with quantity equal to expected quantity
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Vendor."Subcontr. Location Code",
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            WorkCenter[2]."No.", ProductionOrder.Quantity, false);

        // [GIVEN] Delete the first transfer order to allow re-creation attempt
        TransferHeader.Get(TransferLine."Document No.");
        TransferHeader.Delete(true);

        // [WHEN] Attempt to create Transfer Order to Subcontractor again
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        asserterror PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] No WIP Transfer Line is created, and an error message indicates that there is no WIP or components to transfer
        Assert.ExpectedError('Nothing to create. No components or WIP to transfer for the specified subcontracting order.');

        // [TEARDOWN]
        WIPLedgerEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure WIPReturnTransferOrderCreatedWithCorrectLocations()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderLocationCode: Code[10];
        SubcLocationCode: Code[10];
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] After a WIP Transfer Order has been created and posted, creating
        // a Return Transfer Order creates a WIP Return Transfer Line with reversed
        // from/to locations compared to the original WIP Transfer Order.

        // [GIVEN] Complete setup
        Initialize();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Create and refresh production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [WHEN] Create Subcontracting Purchase Order
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Get the WIP Transfer Line and locate the subcontractor location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        SubcLocationCode := Vendor."Subcontr. Location Code";

        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLocationCode := ProdOrderLine."Location Code";

        // [GIVEN] Find the routing line to get operation details
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Mock WIP Ledger Entry at subcontractor location (simulates posted WIP transfer)
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", SubcLocationCode,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            '', LibraryRandom.RandInt(10) + 1, false);

        // [WHEN] Create Return Transfer Order from Subcontractor
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] A WIP Return Transfer Line exists
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Return Order", true);
        Assert.RecordIsNotEmpty(TransferLine);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Return Transfer Line must reference the production order parent item.');
        Assert.AreEqual(WIPLedgerEntry."Quantity (Base)", TransferLine.Quantity,
            'WIP Return Transfer Line must have the same quantity as the WIP Ledger Entry.');

        // [THEN] Return Transfer Header has reversed locations (from subcontractor, to company WH)
        TransferHeader.Get(TransferLine."Document No.");
        Assert.AreEqual(SubcLocationCode, TransferHeader."Transfer-from Code",
            'Return WIP Transfer must come FROM the subcontractor location.');
        Assert.AreEqual(ProdOrderLocationCode, TransferHeader."Transfer-to Code",
            'Return WIP Transfer must go TO the Prod. Order Line location (company WH).');

        // [TEARDOWN]
        WIPLedgerEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure WIPTransferOrderFromSubc1ToSubc2WhenPreviousOpIsSubcontracting()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Subc1LocationCode: Code[10];
        Subc2LocationCode: Code[10];
        WIPQty: Decimal;
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] When a WIP item has been processed at Subcontractor 1 (the immediate previous
        // subcontracting operation), creating a Transfer Order to Subcontractor 2 creates a WIP
        // Transfer Line going FROM Subcontractor 1's location TO Subcontractor 2's location.
        // The quantity on the WIP Transfer Line matches the WIP Ledger Entry at Subcontractor 1.

        // [GIVEN] Complete setup
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Two subcontracting work centers, each with their own vendor and location
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Set "Transfer WIP Item" on Subcontractor 1 and Subcontractor 2 routing line (the current operation)
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[1]."No.", true);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Assign dedicated subcontractor locations to both vendors
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[1]);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create and refresh released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Read subcontractor location codes after all vendor updates
        Vendor1.Get(WorkCenter[1]."Subcontractor No.");
        Vendor2.Get(WorkCenter[2]."Subcontractor No.");
        Subc1LocationCode := Vendor1."Subcontr. Location Code";
        Subc2LocationCode := Vendor2."Subcontr. Location Code";

        // [GIVEN] Locate the Prod. Order line and the routing line for Subcontractor 1 (previous op)
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        ProdOrderRoutingLine.FindLast();

        // [GIVEN] Insert a WIP Ledger Entry at Subcontractor 1's location, simulating that
        // the production item has been processed and is physically at Subcontractor 1
        WIPQty := LibraryRandom.RandInt(10) + 1;
        SubcontractingMgmtLibrary.CreateWIPLedgerEntry(
            WIPLedgerEntry, Item."No.", Subc1LocationCode,
            ProductionOrder, ProdOrderLine, ProdOrderRoutingLine,
            WorkCenter[1]."No.", WIPQty, false);

        // [WHEN] Create Subcontracting Purchase Order for Subcontractor 2's operation
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Order to Subcontractor 2
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] A WIP Transfer Line exists for the production order
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Return Order", false);
        Assert.RecordCount(TransferLine, 1);

        TransferLine.FindFirst();
        Assert.AreEqual(Item."No.", TransferLine."Item No.",
            'WIP Transfer Line must reference the production order parent item.');
        Assert.AreEqual(WIPQty, TransferLine.Quantity,
            'WIP Transfer Line quantity must match the WIP Ledger Entry at Subcontractor 1.');

        // [THEN] Transfer Header must go FROM Subcontractor 1's location TO Subcontractor 2's location
        TransferHeader.Get(TransferLine."Document No.");
        Assert.AreEqual(Subc1LocationCode, TransferHeader."Transfer-from Code",
            'WIP Transfer must come FROM Subcontractor 1''s location (previous subcontracting operation).');
        Assert.AreEqual(Subc2LocationCode, TransferHeader."Transfer-to Code",
            'WIP Transfer must go TO Subcontractor 2''s location.');

        // [TEARDOWN]
        WIPLedgerEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrders')]
    procedure WIPTransferOrdersCreatedForParallelRoutingPredecessors()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        Loc30TransferFound: Boolean;
        ProdOrderLocTransferFound: Boolean;
        Loc30Code: Code[10];
        Loc40Code: Code[10];
        ProdOrderLocationCode: Code[10];
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] For a parallel routing 10 → 20 | 30 → 40 where:
        //   Creating a Transfer Order to Subcontractor for op 40's purchase order
        //   must create TWO separate WIP Transfer Orders:
        //   1. From Prod. Order Line location (our warehouse) → Subc40 location
        //      (path through non-SC op 20; WIP remains at our warehouse)
        //   2. From Subc30 location → Subc40 location
        //      (path through SC op 30; WIP is at Subc30's location)

        // [GIVEN] Complete setup
        Initialize();

        // [GIVEN] Parallel routing with machine centers, work centers and item
        SubcWarehouseLibrary.CreateParallelRoutingItemWithSubcontracting(
            Item, MachineCenter, WorkCenter);

        // [GIVEN] Get subcontractor location codes from work centers
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Loc30Code := Vendor."Subcontr. Location Code";
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Loc40Code := Vendor."Subcontr. Location Code";

        // [GIVEN] Create released production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Set the production order line location to Manufacturing "Components at Location"
        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        ProdOrderLocationCode := ProductionOrder."Location Code";

        // [GIVEN] Create transfer routes for both WIP paths:
        //   1. ProdOrderLocation → Loc40  (non-SC op 20 path: WIP stays at our warehouse)
        CreateAndUpdateTransferRoute(ProdOrderLocationCode, Loc40Code);

        //   2. Loc30 → Loc40  (SC op 30 path: WIP is at Subc30 location)
        CreateAndUpdateTransferRoute(Loc30Code, Loc40Code);

        // [WHEN] Create a subcontracting purchase order for op 40 (the last SC operation)
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Create Transfer Orders to Subcontractor 40 — two parallel predecessors → two transfer orders
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Exactly two WIP Transfer Lines exist (one per parallel predecessor path)
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        // [THEN] The two WIP Transfer Lines belong to two different Transfer Headers
        TransferLine.FindFirst();
        TransferLine.SetFilter("Document No.", '<>%1', TransferLine."Document No.");
        Assert.RecordCount(TransferLine, 1);

        // [THEN] Both WIP Transfer Lines reference the production order parent item,
        //        carry the full production order quantity (parallel routing preset),
        //        and each header delivers TO Subcontractor 40's location
        //        while coming FROM one of the two distinct source locations
        TransferLine.SetRange("Document No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Return Order", false);
        TransferLine.FindSet();
        repeat
            Assert.AreEqual(Item."No.", TransferLine."Item No.",
                'Each WIP Transfer Line must reference the production order parent item.');
            Assert.AreEqual(ProductionOrder.Quantity, TransferLine.Quantity,
                'Each parallel WIP Transfer Line must carry the full production order quantity.');

            TransferHeader.Get(TransferLine."Document No.");
            Assert.AreEqual(Loc40Code, TransferHeader."Transfer-to Code",
                'Both WIP Transfer Orders must go TO Subcontractor 40''s location.');

            if TransferHeader."Transfer-from Code" = ProdOrderLocationCode then
                ProdOrderLocTransferFound := true
            else
                if TransferHeader."Transfer-from Code" = Loc30Code then
                    Loc30TransferFound := true;
        until TransferLine.Next() = 0;

        // [THEN] One WIP transfer originates from our warehouse (non-SC op 20 path)
        Assert.IsTrue(ProdOrderLocTransferFound,
            'A WIP Transfer from the Prod. Order Line location (non-SC op 20 path) to Subc. 40 must exist.');

        // [THEN] One WIP transfer originates from Subcontractor 30''s location (SC op 30 path)
        Assert.IsTrue(Loc30TransferFound,
            'A WIP Transfer from Subcontractor 30''s location (SC op 30 path) to Subc. 40 must exist.');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure WIPTransferCreatedPerProdOrderLineInFamilyProductionOrder()
    var
        Family: Record Family;
        FamilyItem: array[2] of Record Item;
        FamilyLine: array[2] of Record "Family Line";
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContracts: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] A Production Order sourced from a Family with 2 family items shares a single
        // subcontracting routing (Transfer WIP Item = true on the subcontracting operation).
        // For every prod order line one purchase line is created via the subcontracting worksheet.
        // When "Create Transfer Order to Subcontractor" is invoked on the purchase order,
        // a separate WIP Transfer Line is created for each prod order line / family item.

        // [GIVEN] Complete setup
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Create subcontracting work centers and machine centers
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);

        // [GIVEN] Create two plain items that will become the family line output items
        LibraryInventory.CreateItem(FamilyItem[1]);
        LibraryInventory.CreateItem(FamilyItem[2]);

        // [GIVEN] Create a Production Family with both items as family lines
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", FamilyItem[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", FamilyItem[2]."No.", 1);

        // [GIVEN] Build a routing with the subcontracting work center and assign it to the family
        CreateFamilyRoutingWithSubcontractingWC(Family, WorkCenter[2]."No.");

        // [GIVEN] Set "Transfer WIP Item" on the subcontracting routing line
        SetTransferWIPItemOnRoutingLine(Family."Routing No.", WorkCenter[2]."No.", true);

        // [GIVEN] Give WC[2]'s vendor a dedicated subcontracting location
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");

        // [GIVEN] Create a released production order for the family
        // → produces 2 Prod. Order Lines (one per family item), each with the family routing
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Family, Family."No.", LibraryRandom.RandInt(10) + 5);

        SetProdOrderLocationToCompSetupLocationAndRefresh(ProductionOrder);

        // [GIVEN] Create a transfer route from the prod order line location to the subcontractor location
        CreateAndUpdateTransferRoute(GetManufacturingSetupCompLocation(), Vendor."Subcontr. Location Code");
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Calculate Subcontracts: produces one requisition line per prod order routing line (= 2)
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubContracts.UseRequestPage(false);
        SubcCalculateSubContracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        // 2 requisition lines expected – one per family item / prod order line
        Assert.RecordCount(RequisitionLine, 2);
        RequisitionLine.FindFirst();

        // [WHEN] Carry Out Action processes all lines in the batch → creates purchase lines
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] 2 purchase lines exist for the production order – one per prod order line / family item
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        Assert.RecordCount(PurchaseLine, 2);

        // [WHEN] Invoke "Create Transfer Order to Subcontractor" on the purchase order
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [THEN] Exactly 2 WIP Transfer Lines exist – one per family item / prod order line
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.SetRange("Return Order", false);
        Assert.RecordCount(TransferLine, 2);

        // [THEN] Each WIP Transfer Line references one of the two family items
        TransferLine.FindSet();
        repeat
            Assert.IsTrue(
                (TransferLine."Item No." = FamilyItem[1]."No.") or (TransferLine."Item No." = FamilyItem[2]."No."),
                'Each WIP Transfer Line must reference one of the two family items.');
        until TransferLine.Next() = 0;
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        TransfOrderPage.OK().Invoke();
    end;

    [PageHandler]
    procedure HandleTransferOrders(var TransfOrderPage: TestPage "Transfer Orders")
    begin
        TransfOrderPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure HandleCreateTransferOrderMsg(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure DoNotConfirmShowCreatedPurchOrderForSubcontracting(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. WIP Trans. Create Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. WIP Trans. Create Test");

        SubSetupLibrary.InitSetupFields();
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. WIP Trans. Create Test");
    end;

    local procedure SetTransferWIPItemOnRoutingLine(RoutingNo: Code[20]; WorkCenterNo: Code[20]; TransferWIPItem: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine."Transfer WIP Item" := TransferWIPItem;
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure SetProdOrderLocationToCompSetupLocationAndRefresh(var ProductionOrder: Record "Production Order")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ProductionOrder.Validate("Location Code", ManufacturingSetup."Components at Location");
        ProductionOrder.Modify();

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndUpdateTransferRoute(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
            TransferRoute, FromLocationCode, ToLocationCode, Location.Code, '', '');
    end;

    local procedure CreateFamilyRoutingWithSubcontractingWC(var Family: Record Family; WorkCenterNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Creates a minimal serial routing containing only the subcontracting work center
        // and assigns it to the family.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);
    end;

    local procedure GetManufacturingSetupCompLocation(): Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        exit(ManufacturingSetup."Components at Location");
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
}