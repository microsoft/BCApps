// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
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
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

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
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder,HandleCreateTransferOrderMsg')]
    procedure DirectTransferPostingWithWIPItemDoesNotErrorOnQuantity()
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
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 636823] Direct Transfer posting with WIP items should not fail with "quantity not entered" error
        // when Inventory Setup has Direct Transfer Posting = Direct Transfer.
        Initialize();

        // [GIVEN] Inventory Setup with Direct Transfer Posting = Direct Transfer
        SubcontractingMgmtLibrary.SetupInventorySetup();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // [GIVEN] Subcontracting purchase order and transfer order to vendor (no in-transit route = direct transfer)
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

        // [WHEN] Post the direct transfer (transfer order includes both component and WIP lines)
        Codeunit.Run(Codeunit::"TransferOrder-Post Transfer", TransferHeader);

        // [THEN] Direct Trans. Header is created without error (posting succeeds)
        DirectTransHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(DirectTransHeader);
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

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
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder,HandleSubcTransferOrdersList')]
    procedure SubcTransferOrdersActionOnProductionOrderOpensRelatedTransferOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        UnrelatedProductionOrder: Record "Production Order";
        ProductionLocation: Record Location;
        WorkCenter: array[2] of Record "Work Center";
        ExpectedTransferOrderNo: Code[20];
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 638532] The Released Production Order card provides a navigation action to view only its related subcontracting transfer orders.

        // [GIVEN] Subcontracting setup with two released production orders, each ending up with its own subcontracting purchase order and transfer order.
        // The transfer route is location-based (component location -> subcontractor location), so it is created only for the first order and reused by the second.
        SetupSubcontractingForTransferOrderTests(Item, WorkCenter, ProductionLocation);
        ExpectedTransferOrderNo := CreateProductionOrderWithSubcTransferOrder(Item, WorkCenter, ProductionLocation.Code, true, ProductionOrder);
        CreateProductionOrderWithSubcTransferOrder(Item, WorkCenter, ProductionLocation.Code, false, UnrelatedProductionOrder);

        // [WHEN] Invoking the "Subcontracting Transfer Orders" action on the first production order card
        OpenedTransferOrderListNo := '';
        ReleasedProductionOrder.OpenView();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Subc. Transfer Orders".Invoke();
        ReleasedProductionOrder.Close();

        // [THEN] Only the related transfer order is shown - the handler asserts exactly one record, so the unrelated order is excluded
        Assert.AreEqual(
            ExpectedTransferOrderNo, OpenedTransferOrderListNo,
            'The production order card action must open only the related subcontracting transfer order.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder,HandleSubcTransferOrdersList')]
    procedure SubcTransferOrdersActionOnProductionOrdersListOpensRelatedTransferOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        UnrelatedProductionOrder: Record "Production Order";
        ProductionLocation: Record Location;
        WorkCenter: array[2] of Record "Work Center";
        ExpectedTransferOrderNo: Code[20];
        ReleasedProductionOrders: TestPage "Released Production Orders";
    begin
        // [SCENARIO 638532] The Released Production Orders list provides a navigation action to view only the related subcontracting transfer orders.

        // [GIVEN] Subcontracting setup with two released production orders, each ending up with its own subcontracting purchase order and transfer order.
        // The transfer route is location-based (component location -> subcontractor location), so it is created only for the first order and reused by the second.
        SetupSubcontractingForTransferOrderTests(Item, WorkCenter, ProductionLocation);
        ExpectedTransferOrderNo := CreateProductionOrderWithSubcTransferOrder(Item, WorkCenter, ProductionLocation.Code, true, ProductionOrder);
        CreateProductionOrderWithSubcTransferOrder(Item, WorkCenter, ProductionLocation.Code, false, UnrelatedProductionOrder);

        // [WHEN] Invoking the "Subcontracting Transfer Orders" action on the first production order in the list
        OpenedTransferOrderListNo := '';
        ReleasedProductionOrders.OpenView();
        ReleasedProductionOrders.GoToRecord(ProductionOrder);
        ReleasedProductionOrders."Subc. Transfer Orders".Invoke();
        ReleasedProductionOrders.Close();

        // [THEN] Only the related transfer order is shown - the handler asserts exactly one record, so the unrelated order is excluded
        Assert.AreEqual(
            ExpectedTransferOrderNo, OpenedTransferOrderListNo,
            'The production orders list action must open only the related subcontracting transfer order.');
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

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
    [HandlerFunctions('ConfirmHandler')]
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line exists
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), '');
    end;

    [Test]
    procedure CreateSubcOrderFromRtngLineEmptyDefVATProdPostGrp()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        OriginalDefVATProdPostGrp: Code[20];
    begin
        // [SCENARIO 618715] Creating a Subcontracting Purchase Order from Prod. Order Routing Line
        // should succeed even when "Def. VAT Prod. Posting Group" is empty on the Gen. Product Posting Group
        // (US/Sales Tax localization).

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Create subcontracting Work Center (sets Def. VAT Prod. Posting Group during creation)
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Clear "Def. VAT Prod. Posting Group" on the Work Center's Gen. Product Posting Group
        // to simulate US/Sales Tax localization where this field is intentionally empty.
        // Done after all other setup to avoid committing the change during item/production order creation.
        GenProductPostingGroup.Get(WorkCenter[2]."Gen. Prod. Posting Group");
        OriginalDefVATProdPostGrp := GenProductPostingGroup."Def. VAT Prod. Posting Group";
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := '';
        GenProductPostingGroup.Modify();

        // [GIVEN] Create a VAT Posting Setup for the empty VAT Prod. Posting Group
        // so the downstream purchase line validation can find a matching setup
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        if not VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", '') then begin
            VATPostingSetup.Init();
            VATPostingSetup."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
            VATPostingSetup."VAT Prod. Posting Group" := '';
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
            VATPostingSetup."VAT %" := 0;
            VATPostingSetup.Insert();
        end;

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing Line
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine);

        // [THEN] Purchase Line is created successfully
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), 'Purchase Line should be created even when Def. VAT Prod. Posting Group is empty.');

        // [TEARDOWN] Restore original Def. VAT Prod. Posting Group to prevent contaminating other tests
        GenProductPostingGroup.Get(WorkCenter[2]."Gen. Prod. Posting Group");
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := OriginalDefVATProdPostGrp;
        GenProductPostingGroup.Modify();
    end;

    [Test]
    procedure CreateSubcOrderFromRtngLineIgnoresOtherLineComponentsAtSubcLocation()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        // [SCENARIO 639568] Creating a Subcontracting Purchase Order from a Prod. Order Routing Line must only
        // consider the components of that line. Components belonging to a different Prod. Order Line that have
        // already been moved to the vendor's Subcontracting Location must not trigger a false location-conflict warning.

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Item with routing link and a Transfer to Vendor component, and a vendor with a Subc. Location Code
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Released production order whose current line component sits at a normal (non-blank, non-Subc.) location
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // [GIVEN] The routing line we want to create the subcontracting order for
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] A component belonging to ANOTHER Prod. Order Line (same Routing Link Code) has already been moved to
        // the vendor's Subcontracting Location - mirroring the first line whose components are already in transit.
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.FindLast();
        MockTransferToVendorCompOnOtherLine(
            ProdOrderComponent, ProdOrderComponent."Prod. Order Line No." + 10000, Vendor."Subc. Location Code");

        // [WHEN] Create the subcontracting purchase order from the current routing line
        SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine);

        // [THEN] No false "same as Subcontracting Location" confirmation is raised for the current line
        Assert.AreEqual(
            0, LibraryVariableStorage.Length(),
            'No location-conflict confirmation should be raised: the current line components are not at the Subc. Location.');

        // [THEN] The subcontracting purchase order is created (the other line components at the Subc. Location are ignored)
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), 'Subcontracting purchase order should have been created.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line with additional Component for Component Supply Method exists
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
#pragma warning disable AA0210
        ProductionBOMLine.SetRange("Component Supply Method", ProductionBOMLine."Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ProductionBOMLine."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupTransferInfoLine(true);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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
    procedure TestTransferOfComponentSupplyMethodProdBOMLineToProdOrderComp()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Check Transfer of Component Supply Method from Production BOM Line to Prod Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [WHEN] Creating Production Order to Transfer Information
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [THEN] Check if Production BOM Line with additional Component for Component Supply Method exists
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.SetRange("Component Supply Method", ProductionBOMLine."Component Supply Method"::"Vendor-Supplied");
        Assert.RecordIsNotEmpty(ProductionBOMLine);
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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
    procedure TestChangeLocationOnProdOrderCompWithComponentSupplyMethodPurchase()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        ActualLocationCode: Code[10];
    begin
        // [SCENARIO] Check change Location Code by change Component Supply Method in Prod Order Component

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [WHEN] Get actual Location Code and Change Component Supply Method
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComp.SetFilter("Routing Link Code", '<>%1', '');
        ProdOrderComp.FindFirst();
        ActualLocationCode := ProdOrderComp."Location Code";
        ProdOrderComp.Validate("Component Supply Method", ProdOrderComp."Component Supply Method"::"Vendor-Supplied");
        ProdOrderComp.Modify();

        // [THEN] Check if Component Location differs from Origin Location Code ==> Vendor Subcontracting Location Code
        Assert.AreNotEqual(ActualLocationCode, ProdOrderComp."Location Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
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
        ManufacturingSetup: Record "Manufacturing Setup";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        WorkCenter2 := WorkCenter[2];
        WorkCenter2."Subcontractor No." := Vendor."No.";
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        //[GIVEN] Create Production Order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
               ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        //[GIVEN] Create requisition worksheet template
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        //[GIVEN] create Purchase Order from Subcontracting Worksheet
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

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

        ManufacturingSetup.Get();
        ManufacturingSetup."Subcontracting Template Name" := RequisitionLine."Worksheet Template Name";
        ManufacturingSetup."Subcontracting Batch Name" := RequisitionLine."Journal Batch Name";
        ManufacturingSetup.Modify();

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
    [HandlerFunctions('ConfirmHandler')]
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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

        Assert.AreEqual(ExpectedDate, ProdOrderComp."Due Date", '');

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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

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
    [HandlerFunctions('ConfirmHandler,SubcontrDispatchingListDefaultRequestPageHandler')]
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
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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
    [HandlerFunctions('ConfirmHandler')]
    procedure SubcontractingFieldsPopulatedOnIleAfterSubcontractingPurchaseReceipt()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubcWorkCenter: Record "Work Center";
    begin
        // [SCENARIO] Bug 633292 - Output Item Ledger Entry created from posting a subcontracting purchase receipt should have the Subcontracting extension fields populated, so that the Production actions on the Item Ledger Entries page can resolve the linked production order, routing, and components.

        // [GIVEN] Subcontracting setup
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Released Production Order whose only routing operation is a subcontracting one (so receiving the subcontracting PO posts the Output ILE)
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Subcontracting Purchase Order created from the Prod. Order Routing line
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210        
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [WHEN] Receive the subcontracting purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] An Output Item Ledger Entry exists with Subcontracting extension fields populated from the source purchase line
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.FindFirst();

        Assert.AreEqual(
          PurchaseHeader."No.", ItemLedgerEntry."Subc. Purch. Order No.",
          'Item Ledger Entry "Subcontr. Purch. Order No." should equal the originating subcontracting purchase order.');
        Assert.AreEqual(
          PurchaseLine."Line No.", ItemLedgerEntry."Subc. Purch. Order Line No.",
          'Item Ledger Entry "Subcontr. PO Line No." should equal the originating subcontracting purchase line.');
        Assert.AreEqual(
          PurchaseLine."Operation No.", ItemLedgerEntry."Subc. Operation No.",
          'Item Ledger Entry "Operation No." (Subc) should equal the originating purchase line operation.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ProdOFactboxMgmtResolvesProductionOrderForIleFromSubcontractingPurchaseReceipt()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubcWorkCenter: Record "Work Center";
        SubcProdOFactboxMgmt: Codeunit "Subc. ProdO. Factbox Mgmt.";
    begin
        // [SCENARIO] Bug 633292 - Subc. ProdO. Factbox Mgmt. helpers should resolve a positive number of production order routings and components when given an Item Ledger Entry that originated from a subcontracting purchase receipt. Before the fix, the codeunit had no Item Ledger Entry branch in SetProdOrderInformationByVariant and returned 0 for any ILE variant.

        // [GIVEN] Subcontracting setup
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Released Production Order whose only routing operation is a subcontracting one (so receiving the subcontracting PO posts the Output ILE)
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Subcontracting Purchase Order created from the Prod. Order Routing line and posted as received
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210        
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.FindFirst();

        // [WHEN] CalcNoOfProductionOrderRoutings / CalcNoOfProductionOrderComponents are called with the ILE variant
        // [THEN] Both return a positive count, confirming the production order linkage is resolved
        Assert.IsTrue(
          SubcProdOFactboxMgmt.CalcNoOfProductionOrderRoutings(ItemLedgerEntry) > 0,
          'CalcNoOfProductionOrderRoutings should return a positive count for an Item Ledger Entry from a subcontracting receipt.');
        Assert.IsTrue(
          SubcProdOFactboxMgmt.CalcNoOfProductionOrderComponents(ItemLedgerEntry) > 0,
          'CalcNoOfProductionOrderComponents should return a positive count for an Item Ledger Entry from a subcontracting receipt.');
    end;

    [Test]
    [HandlerFunctions('ConfirmArchiveOrderHandler,HandlePurchaseOrderPage')]
    procedure ProdOFactboxMgmtShowsDataAfterProdOrderFinished()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubcWorkCenter: Record "Work Center";
        SubcProdOFactboxMgmt: Codeunit "Subc. ProdO. Factbox Mgmt.";
    begin
        // [SCENARIO 634953] Subcontracting factbox drilldowns should work after production order is finished.
        Initialize();

        // [GIVEN] A released production order with a subcontracting routing operation and a subcontracting purchase order
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] The production order is changed to Finished status
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, "Production Order Status"::Finished, WorkDate(), true);

        // Re-read purchase line (the order still exists because only receipt was posted)
        PurchaseLine.FindFirst();

        // [WHEN] CalcNoOfProductionOrderRoutings / CalcNoOfProductionOrderComponents are called with the Purchase Line
        // [THEN] Both return a positive count even though the production order is now Finished
        Assert.IsTrue(
            SubcProdOFactboxMgmt.CalcNoOfProductionOrderRoutings(PurchaseLine) > 0,
            'CalcNoOfProductionOrderRoutings should return a positive count after the production order is finished.');
        Assert.IsTrue(
            SubcProdOFactboxMgmt.CalcNoOfProductionOrderComponents(PurchaseLine) > 0,
            'CalcNoOfProductionOrderComponents should return a positive count after the production order is finished.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RoutingFactboxMgmtFiltersPurchOrderQtyByRoutingReferenceNo()
    var
        Item: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        SubcWorkCenter: Record "Work Center";
        SubcRoutingFactboxMgmt: Codeunit "Subc. Routing Factbox Mgmt.";
        ExpectedPurchOrderQty: Decimal;
    begin
        // [SCENARIO] Regression test for Subc. Routing Factbox Mgmt.
        // [SCENARIO] GetPurchOrderQtyFromRoutingLine must filter by "Routing Reference No." and not by "Prod. Order Line No.".

        // [GIVEN] A released production order with a subcontracting routing operation and a created subcontracting purchase order
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", SubcWorkCenter."No.");
        ProdOrderRoutingLine.FindFirst();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.FindFirst();

        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(7, 17));
        // Force a mismatch to prove the codeunit does not rely on Prod. Order Line No.
        PurchaseLine."Prod. Order Line No." := ProdOrderRoutingLine."Routing Reference No." + 1;
        PurchaseLine.Modify(true);

        Assert.AreNotEqual(
            ProdOrderRoutingLine."Routing Reference No.", PurchaseLine."Prod. Order Line No.",
            'Test setup failed: Prod. Order Line No. must differ from Routing Reference No.');

        // [WHEN] The factbox helper calculates purchase order quantity from the routing line
        // [THEN] Quantity is returned for the line matched by Routing Reference No.
        ExpectedPurchOrderQty := PurchaseLine.Quantity;
        Assert.AreEqual(
            ExpectedPurchOrderQty,
            SubcRoutingFactboxMgmt.GetPurchOrderQtyFromRoutingLine(ProdOrderRoutingLine),
            'GetPurchOrderQtyFromRoutingLine must filter by Routing Reference No., not by Prod. Order Line No.');
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

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

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
    [HandlerFunctions('ConfirmHandler')]
    procedure Description2CopiedFromProdOrderComponentToPurchaseLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO] Description 2 from Prod. Order Component is propagated to Purchase Line
        // [FEATURE] Bug 620556 - Subcontracting Description 2 alignment

        // [GIVEN] Complete Setup of Manufacturing
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] A Description 2 value is set on the Prod. Order Component with Component Supply Method = Purchase
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        ExpectedDescription2 := 'TestDescription2_Comp';
        ProdOrderComp."Description 2" := ExpectedDescription2;
        ProdOrderComp.Modify();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Description 2 from Prod. Order Component is propagated to the component Purchase Line
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ProdOrderComp."Item No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        Assert.AreEqual(
            ExpectedDescription2, PurchaseLine."Description 2",
            'Description 2 must be propagated from Prod. Order Component to Purchase Line');
    end;

    [Test]
    procedure Description2PopulatedOnRequisitionLineFromCalculateSubcontracts()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        LibraryUtility: Codeunit "Library - Utility";
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO] Description 2 from Prod. Order Routing Line is populated on Requisition Line
        // via Calculate Subcontracts report
        // [FEATURE] Bug 620556 - Subcontracting Description 2 alignment

        // [GIVEN] Complete Setup of Manufacturing
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Description 2 is set on the subcontracting Work Center Name 2
        // (SubcCalcSubcontractsExt copies WorkCenter."Name 2" → RequisitionLine."Description 2")
        ExpectedDescription2 := 'TestDesc2_WC';
        WorkCenter[2].Get(WorkCenter[2]."No.");
        WorkCenter[2].Validate("Name 2", ExpectedDescription2);
        WorkCenter[2].Modify(true);

        // [GIVEN] Create requisition worksheet
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

        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        // [WHEN] Calculate Subcontracts
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        // [THEN] Description 2 on the Requisition Line is populated
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
        Assert.AreEqual(
            ExpectedDescription2, RequisitionLine."Description 2",
            'Description 2 must be populated on the Requisition Line from the subcontracting Work Center');
    end;

    [Test]
    procedure ChangingVendorKeepsProdOrderRoutingLineDescriptions()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        ExpectedDescription: Text[100];
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO 550732] Changing the vendor on a subcontracting requisition line keeps the production routing descriptions
        Initialize();

        // [GIVEN] A released production order with custom descriptions on its subcontracting routing line
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ExpectedDescription := 'Custom subcontracting operation';
        ExpectedDescription2 := 'Custom operation details';
        ProdOrderRoutingLine.Description := ExpectedDescription;
        ProdOrderRoutingLine."Description 2" := ExpectedDescription2;
        ProdOrderRoutingLine.Modify();

        // [GIVEN] The production routing line is suggested on the subcontracting worksheet
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] The vendor is changed on the subcontracting requisition line
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] Both descriptions still come from the production order routing line
        Assert.AreEqual(ExpectedDescription, RequisitionLine.Description, 'The routing line description must be kept when the vendor changes.');
        Assert.AreEqual(ExpectedDescription2, RequisitionLine."Description 2", 'The routing line description 2 must be kept when the vendor changes.');
    end;

    [Test]
    procedure ChangingVendorKeepsBlankRoutingDescriptionAndUsesWorkCenterDescription2()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO 550732] Changing the vendor keeps a blank routing description and uses work center description 2
        Initialize();

        // [GIVEN] A released production order with blank descriptions on its subcontracting routing line
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        ExpectedDescription2 := 'Work center details';
        WorkCenter[2].Validate("Name 2", ExpectedDescription2);
        WorkCenter[2].Modify(true);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        Clear(ProdOrderRoutingLine.Description);
        Clear(ProdOrderRoutingLine."Description 2");
        ProdOrderRoutingLine.Modify();

        // [GIVEN] The production routing line is suggested on the subcontracting worksheet
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Description := 'Description before vendor validation';
        RequisitionLine."Description 2" := 'Description 2 before validation';
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] The vendor is changed on the subcontracting requisition line
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] The description remains blank and description 2 comes from the subcontracting work center
        Assert.AreEqual('', RequisitionLine.Description, 'The blank routing line description must be kept when the vendor changes.');
        Assert.AreEqual(ExpectedDescription2, RequisitionLine."Description 2", 'The work center description 2 must be used when the routing line description 2 is blank.');
    end;

    [Test]
    procedure ChangingVendorUsesWorkCenterDescriptionsWhenRoutingLineNotFound()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        ExpectedDescription: Text[100];
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO 550732] Changing the vendor uses the subcontracting work center descriptions when the routing line is not found
        Initialize();

        // [GIVEN] A released production order with distinct descriptions on its subcontracting work center
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        ExpectedDescription := 'Subcontracting work center';
        ExpectedDescription2 := 'Work center details';
        WorkCenter[2].Validate(Name, ExpectedDescription);
        WorkCenter[2].Validate("Name 2", ExpectedDescription2);
        WorkCenter[2].Modify(true);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] A subcontracting requisition line whose routing operation does not exist
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();
        RequisitionLine."Operation No." := 'NOTFOUND';
        RequisitionLine.Description := 'Description before vendor validation';
        RequisitionLine."Description 2" := 'Description 2 before validation';
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] The vendor is changed on the subcontracting requisition line
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] Both descriptions fall back to the subcontracting work center
        Assert.AreEqual(ExpectedDescription, RequisitionLine.Description, 'The work center description must be used when the routing line is not found.');
        Assert.AreEqual(ExpectedDescription2, RequisitionLine."Description 2", 'The work center description 2 must be used when the routing line is not found.');
    end;

    [Test]
    procedure ChangingVendorUsesWorkCenterDescriptionsWhenRoutingLineWorkCenterDiffers()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        ExpectedDescription: Text[100];
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO 550732] Changing the vendor uses the requisition work center descriptions when the routing line work center differs
        Initialize();

        // [GIVEN] A released production order with distinct descriptions on its subcontracting work center
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        ExpectedDescription := 'Current subcontracting work center';
        ExpectedDescription2 := 'Current work center details';
        WorkCenter[2].Validate(Name, ExpectedDescription);
        WorkCenter[2].Validate("Name 2", ExpectedDescription2);
        WorkCenter[2].Modify(true);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] A subcontracting requisition line and its matching-key routing line with different work centers
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();
        ProdOrderRoutingLine.Get(
            RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.", RequisitionLine."Routing Reference No.",
            RequisitionLine."Routing No.", RequisitionLine."Operation No.");
        ProdOrderRoutingLine."Work Center No." := WorkCenter[1]."No.";
        ProdOrderRoutingLine.Description := 'Mismatched routing description';
        ProdOrderRoutingLine."Description 2" := 'Mismatched routing details';
        ProdOrderRoutingLine.Modify();
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] The vendor is changed on the subcontracting requisition line
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] Both descriptions fall back to the requisition line's subcontracting work center
        Assert.AreEqual(ExpectedDescription, RequisitionLine.Description, 'The requisition work center description must be used when the routing line work center differs.');
        Assert.AreEqual(ExpectedDescription2, RequisitionLine."Description 2", 'The requisition work center description 2 must be used when the routing line work center differs.');
    end;

    [Test]
    procedure CalculateSubcontractsErrorsWhenWorkCenterMissingGenProdPostingGroup()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 635775] Calculate Subcontracts must error up front when the subcontracting Work Center has a blank Gen. Prod. Posting Group
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Manufacturing setup with an item, routing and subcontracting work center
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] The subcontracting Work Center has a blank Gen. Prod. Posting Group
        WorkCenter[2].Get(WorkCenter[2]."No.");
        WorkCenter[2].Validate("Gen. Prod. Posting Group", '');
        WorkCenter[2].Modify(true);

        // [WHEN] Calculate Subcontracts is run on the worksheet
        asserterror RunCalculateSubcontracts();

        // [THEN] It errors immediately instead of deferring to posting time
        Assert.ExpectedError('Gen. Prod. Posting Group must have a value');
    end;

    [Test]
    procedure CreateSubcOrderFromRoutingErrorsWhenWorkCenterMissingGenProdPostingGroup()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 635775] Creating a Subcontracting Order from the Prod. Order Routing must error when the Work Center has a blank Gen. Prod. Posting Group
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Manufacturing setup with an item, routing and subcontracting work center
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] The subcontracting Work Center has a blank Gen. Prod. Posting Group
        WorkCenter[2].Get(WorkCenter[2]."No.");
        WorkCenter[2].Validate("Gen. Prod. Posting Group", '');
        WorkCenter[2].Modify(true);

        // [WHEN] Create Subcontracting Order is invoked from the Prod. Order Routing
        asserterror SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] It errors on the missing Gen. Prod. Posting Group
        Assert.ExpectedError('Gen. Prod. Posting Group must have a value');
    end;

    [Test]
    procedure CalculateSubcontractsErrorsWhenItemBlockedForOutput()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 635775] Calculate Subcontracts must error when the manufactured item is blocked for production output
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Manufacturing setup with an item, routing and subcontracting work center
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] The manufactured item is blocked for production output
        Item.Get(Item."No.");
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Calculate Subcontracts is run on the worksheet
        asserterror RunCalculateSubcontracts();

        // [THEN] It errors because the item is blocked for production output
        Assert.ExpectedError('You cannot produce');
    end;

    [Test]
    procedure CreateSubcOrderFromRoutingErrorsWhenItemBlockedForOutput()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 635775] Creating a Subcontracting Order from the Prod. Order Routing must error when the item is blocked for production output
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Manufacturing setup with an item, routing and subcontracting work center
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] The manufactured item is blocked for production output
        Item.Get(Item."No.");
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Create Subcontracting Order is invoked from the Prod. Order Routing
        asserterror SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] It errors because the item is blocked for production output
        Assert.ExpectedError('You cannot produce');
    end;

    [Test]
    [HandlerFunctions('RoutingLinkCodeDuplicateConfirmHandler')]
    procedure ValidateRoutingLinkCodeOnProdOrderRtngLineShowsConfirmOnce()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 617395] Validating Routing Link Code on a Prod. Order Routing Line shows the
        // duplicate-use confirmation dialog exactly once. The BaseApp OnValidate already performs
        // this check; the Subcontracting extension must not duplicate it.
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Work centers, item with routing and BOM, with a routing link code assigned to the subcontracting routing line
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order whose routing lines inherit the routing link code
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] The prod. order routing line for the subcontracting work center (has a routing link code)
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] The routing link code is validated (re-validates the existing code, which triggers
        // the BaseApp duplicate-use check)
        ConfirmDialogCalledCount := 0;
        ProdOrderRoutingLine.Validate("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");

        // [THEN] The confirmation dialog is shown exactly once — from the BaseApp — not twice
        Assert.AreEqual(
            1, ConfirmDialogCalledCount,
            'Routing Link Code duplicate confirmation must be shown exactly once, not twice');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalcNoOfProductionOrderRoutingsReturnsOneForSubcontractingPurchaseLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        SubcProdOFactboxMgmt: Codeunit "Subc. ProdO. Factbox Mgmt.";
    begin
        // [SCENARIO 634720] CalcNoOfProductionOrderRoutings must filter by Routing No. and Operation No. so the factbox count matches the drill-down (which is always a single routing line for a subcontracting purchase line).

        // [GIVEN] Manufacturing setup with a routing of multiple operations where only the second work center is subcontracting
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        // [GIVEN] A Released Production Order whose routing has more than one operation
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine.Count() > 1, 'Test precondition: routing must have more than one operation to detect the bug.');

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] A Subcontracting Purchase Order created from the routing line of the subcontracting work center
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        // [WHEN] CalcNoOfProductionOrderRoutings is called with the purchase line
        // [THEN] It returns 1, matching the single routing line shown by the drill-down (not the total operations of the prod order line)
        Assert.AreEqual(
          1, SubcProdOFactboxMgmt.CalcNoOfProductionOrderRoutings(PurchaseLine),
          'CalcNoOfProductionOrderRoutings must equal the number of routing lines opened by the drill-down (exactly one for a subcontracting purchase line).');
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

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

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
    procedure PostingSubcontractingTransferSetsSourceFieldsOnPostedHeaders()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 638466] Posting a non-direct subcontracting transfer (ship + receive) propagates Source Type and Source ID to both the Transfer Shipment Header and the Transfer Receipt Header

        // [GIVEN] Standard subcontracting setup with an in-transit transfer route (non-direct)
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        // [GIVEN] Subcontracting purchase order and outbound transfer order to vendor
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

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
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");

        // [GIVEN] Inventory at the source location
        Location.Get(TransferHeader."Transfer-from Code");
        Item.Get(ProdOrderComp."Item No.");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");

        // [WHEN] Posting the outbound transfer shipment
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] The Transfer Shipment Header has Source Type = Subcontracting and Source ID = Vendor No.
        TransferShipmentHeader.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        Assert.RecordIsNotEmpty(TransferShipmentHeader);
        TransferShipmentHeader.FindFirst();
        Assert.AreEqual(
            "Transfer Source Type"::Subcontracting, TransferShipmentHeader."Subc. Source Type",
            'Subc. Source Type must be Subcontracting on Transfer Shipment Header');
        Assert.AreEqual(
            Vendor."No.", TransferShipmentHeader."Source ID",
            'Source ID must be the Vendor No. on Transfer Shipment Header');

        // [WHEN] Posting the inbound transfer receipt
        TransferHeader.Get(TransferHeader."No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] The Transfer Receipt Header has Source Type = Subcontracting and Source ID = Vendor No.
        TransferReceiptHeader.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        Assert.RecordIsNotEmpty(TransferReceiptHeader);
        TransferReceiptHeader.FindFirst();
        Assert.AreEqual(
            "Transfer Source Type"::Subcontracting, TransferReceiptHeader."Subc. Source Type",
            'Subc. Source Type must be Subcontracting on Transfer Receipt Header');
        Assert.AreEqual(
            Vendor."No.", TransferReceiptHeader."Source ID",
            'Source ID must be the Vendor No. on Transfer Receipt Header');
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
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

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateSubcontractingPOForEachProdOrderLineWhenLinesShareRoutingAndOperation()
    var
        Item: Record Item;
        ProductionLocation: array[2] of Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderRtng: TestPage "Prod. Order Routing";
        I: Integer;
        ProdOrderLineNo: array[2] of Integer;
    begin
        // [SCENARIO 634238] When a Released Production Order has multiple Prod. Order lines sharing the same
        // Routing/Operation, creating a Subcontracting Order for the second line must not raise the false
        // "Purchase orders have already been created" warning, and must create/show its own Purchase Order.

        // [GIVEN] Subcontracting setup with direct transfer (no in-transit route)
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        // [GIVEN] One released production order created directly from item
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 0);

        // [GIVEN] No production order lines exist yet for this order
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(0, ProdOrderLine.Count(), 'Expected no production order lines to exist before manually creating them');

        // [GIVEN] Two production order lines on the same production order, on different locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[2]);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[1].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[1] := ProdOrderLine."Line No.";
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[2].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[2] := ProdOrderLine."Line No.";
        Assert.AreNotEqual(ProdOrderLineNo[1], ProdOrderLineNo[2], 'Expected two distinct production order lines');

        // [GIVEN] Refresh the production order to update the routing and component lines
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [GIVEN] The two production-order lines have transfer components on different locations
        for I := 1 to 2 do begin
            ProdOrderRoutingLine.Reset();
            ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo[I]);
            ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
            Assert.RecordCount(ProdOrderRoutingLine, 1);

            ProdOrderRoutingLine.FindFirst();

            ProdOrderRtng.OpenView();
            ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
            ProdOrderRtng.CreateSubcontracting.Invoke();
            ProdOrderRtng.Close();

            Assert.AreEqual('A purchase order was created.\\Do you want to view it?', LibraryVariableStorage.DequeueText(), 'Expected "created" confirmation for each prod order line, not the false "already created" warning');
            LibraryVariableStorage.AssertEmpty();
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesShowSubcontractingPurchOrders,CapturePurchaseOrderPageNo')]
    procedure CreateSubcontractingPONavigatesToOwnPOWhenLinesShareRoutingAndOperation()
    var
        Item: Record Item;
        ProductionLocation: array[2] of Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderRtng: TestPage "Prod. Order Routing";
        I: Integer;
        ProdOrderLineNo: array[2] of Integer;
        OpenedPurchaseOrderNo: Code[20];
    begin
        // [SCENARIO 634238] When a Released Production Order has multiple Prod. Order lines sharing routing/operation,
        // confirming "view them" on the just-created Subcontracting Order must open the PO tied to the invoked
        // routing line, not the unrelated PO of a sibling line.

        // [GIVEN] Subcontracting setup with two prod order lines sharing routing/operation but different Routing Reference No.
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 0);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[2]);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[1].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[1] := ProdOrderLine."Line No.";
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[2].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[2] := ProdOrderLine."Line No.";

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [WHEN] Creating a Subcontracting Order from each routing line and confirming "view them"
        for I := 1 to 2 do begin
            ProdOrderRoutingLine.Reset();
            ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo[I]);
            ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
            ProdOrderRoutingLine.FindFirst();

            ProdOrderRtng.OpenView();
            ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
            ProdOrderRtng.CreateSubcontracting.Invoke();
            ProdOrderRtng.Close();

            // [THEN] The page handler opens the Purchase Order whose line carries this routing line's Routing Reference No.
            OpenedPurchaseOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(OpenedPurchaseOrderNo));
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
            PurchaseLine.SetRange("Document No.", OpenedPurchaseOrderNo);
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            PurchaseLine.SetRange("Routing Reference No.", ProdOrderLineNo[I]);
            Assert.IsFalse(PurchaseLine.IsEmpty(), StrSubstNo(PurchOrderRoutingErr, OpenedPurchaseOrderNo, ProdOrderLineNo[I]));
            LibraryVariableStorage.AssertEmpty();
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesShowSubcontractingPurchOrders,HandlePurchaseOrderPage,HandlePurchaseLinesPage')]
    procedure ShowExistingPurchOrdersOpensListWhenAlreadyCreated()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 633224] First Create Subcontracting Order opens the Purchase Order; running the action again on the same routing line opens the Purchase Lines list.

        // [GIVEN] Manufacturing setup with subcontracting work center, item with routing/BOM, released production order
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Order from the routing line for the first time
        PurchaseOrderPageOpened := false;
        PurchaseLinesPageOpened := false;
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] The Purchase Order card is shown
        Assert.IsTrue(PurchaseOrderPageOpened, 'Purchase Order should open after first creation.');
        Assert.IsFalse(PurchaseLinesPageOpened, 'Purchase Lines list should not open on first creation.');

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.IsFalse(PurchaseLine.IsEmpty(), 'Purchase line should exist for the production order.');

        // [WHEN] Create Subcontracting Order from the same routing line again
        PurchaseOrderPageOpened := false;
        PurchaseLinesPageOpened := false;
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] The Purchase Lines list is shown instead of individual Purchase Order cards
        Assert.IsTrue(PurchaseLinesPageOpened, 'Purchase Lines list should open when purchase orders already exist.');
        Assert.IsFalse(PurchaseOrderPageOpened, 'Purchase Order card should not open when purchase orders already exist.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesShowSubcontractingPurchOrders,HandlePurchaseOrderPage,HandlePurchaseLinesPage')]
    procedure ShowExistingPurchOrdersAfterReceiptDoesNotError()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 637777] Re-running Create Subcontracting Order after fully receiving the existing subcontracting purchase order should offer to view the existing order instead of raising "No Prod. Order Line with Remaining Quantity."

        // [GIVEN] Manufacturing setup with subcontracting work center, item with routing/BOM, released production order, and a created subcontracting purchase order
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] The existing subcontracting purchase order is fully received
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Create Subcontracting Order is invoked again from the same routing line
        PurchaseLinesPageOpened := false;
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] The existing purchase lines are shown and no raw remaining-quantity error is raised
        Assert.IsTrue(PurchaseLinesPageOpened, 'Purchase Lines list should open when the subcontracting purchase order already exists after full receipt.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesShowSubcontractingPurchOrders,CapturePurchaseOrderPageNo,HandlePurchaseLinesPage')]
    procedure CreateSubcontractingPOAfterReceiptOpensNewlyCreatedDeltaPO()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        ReceivedPurchaseOrderNo: Code[20];
        NewPurchaseOrderNo: Code[20];
    begin
        // [SCENARIO 639381] After the existing subcontracting purchase order has been received and the prod. order quantity is increased,
        // Create Subcontracting Order must open the newly created purchase order for the delta, not the old received one.

        // [GIVEN] Subcontracting setup with a released production order (quantity 5)
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] A subcontracting purchase order is created and fully received
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        ReceivedPurchaseOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ReceivedPurchaseOrderNo));

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", ReceivedPurchaseOrderNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", ReceivedPurchaseOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] The prod. order line quantity is increased from 5 to 9
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, 9);
        ProdOrderLine.Modify(true);

        // [WHEN] Create Subcontracting Order is invoked again and both prompts are confirmed
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        NewPurchaseOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(NewPurchaseOrderNo));

        // [THEN] The newly created (delta) purchase order is opened, not the old received one
        Assert.AreNotEqual(ReceivedPurchaseOrderNo, NewPurchaseOrderNo, 'Create Subcontracting Order should open the newly created purchase order, not the already received one.');

        // [THEN] The opened purchase order is the open one (nothing received on it yet)
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", NewPurchaseOrderNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        Assert.AreEqual(0, PurchaseLine."Quantity Received", 'The opened purchase order should be the newly created one with nothing received.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesShowSubcontractingPurchOrders,CapturePurchaseOrderPageNo,HandlePurchaseLinesPage')]
    procedure CreateSubcontractingPOReopensUpdatedExistingOpenPO()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: array[2] of Record "Work Center";
        ExistingPurchaseOrderNo: Code[20];
        ReopenedPurchaseOrderNo: Code[20];
    begin
        // [SCENARIO 639381] When Create Subcontracting Order updates an existing open purchase order (Change Qty.) instead of
        // creating a new one, the confirmation prompt must still open that affected purchase order.

        // [GIVEN] Subcontracting setup with a released production order and an open (not received) subcontracting purchase order
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        ExistingPurchaseOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ExistingPurchaseOrderNo));

        // [GIVEN] The prod. order line quantity is increased from 5 to 9 (existing order stays open)
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, 9);
        ProdOrderLine.Modify(true);

        // [WHEN] Create Subcontracting Order is invoked again (updates the existing open order instead of creating a new one)
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        ReopenedPurchaseOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ReopenedPurchaseOrderNo));

        // [THEN] The same (updated) purchase order is opened
        Assert.AreEqual(ExistingPurchaseOrderNo, ReopenedPurchaseOrderNo, 'Create Subcontracting Order should open the updated existing purchase order.');

        LibraryVariableStorage.AssertEmpty();
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

    [PageHandler]
    procedure HandleSubcTransferOrdersList(var TransferOrders: TestPage "Transfer Orders")
    begin
        Assert.IsTrue(TransferOrders.First(), 'Expected at least one subcontracting transfer order in the list.');
        OpenedTransferOrderListNo := CopyStr(TransferOrders."No.".Value(), 1, MaxStrLen(OpenedTransferOrderListNo));
        Assert.IsFalse(TransferOrders.Next(), 'Expected exactly one subcontracting transfer order in the list.');
        TransferOrders.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmYesShowSubcontractingPurchOrders(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrderPage: TestPage "Purchase Order")
    begin
        PurchaseOrderPageOpened := true;
        PurchaseOrderPage.Close();
    end;

    [PageHandler]
    procedure CapturePurchaseOrderPageNo(var PurchaseOrderPage: TestPage "Purchase Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderPage."No.".Value);
        PurchaseOrderPage.Close();
    end;

    [PageHandler]
    procedure HandlePurchaseLinesPage(var PurchaseLinesPage: TestPage "Purchase Lines")
    begin
        PurchaseLinesPageOpened := true;
        PurchaseLinesPage.Close();
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

    [RequestPageHandler]
    procedure SubcontrDispatchingListDefaultRequestPageHandler(var PurchaseOrderRequestPage: TestRequestPage "Subc. Dispatching List")
    begin
        // Empty handler used to close the request page. We use default settings.
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        case true of
            Question.Contains('Do you really want to change Inventory Account although value entries exist?'),
            Question.Contains('Do you want to create a production order from'),
            Question.Contains('Do you really want to change Inventory Account (Interim) although value entries exist?'):
                Reply := true;
            else
                Reply := false;
        end;
    end;

    [ModalPageHandler]
    procedure GetOrderLinesPurchaseLinesPageHandler(var PurchaseLines: TestPage "Purchase Lines")
    begin
        Assert.IsFalse(PurchaseLines.First(), 'Subcontracting purchase order lines must be excluded from the Get Order Lines selection.');
        PurchaseLines.Cancel().Invoke();
    end;

    [ConfirmHandler]
    procedure RoutingLinkCodeDuplicateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmDialogCalledCount += 1;
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmArchiveOrderHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure SetupSubcontractingForTransferOrderTests(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var ProductionLocation: Record Location)
    var
        MachineCenter: array[2] of Record "Machine Center";
    begin
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation);
        UpdateSubMgmtSetupWithReqWkshTemplate();
    end;

    local procedure CreateProductionOrderWithSubcTransferOrder(Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; ProductionLocationCode: Code[10]; CreateTransferRouteForOrder: Boolean; var ProductionOrder: Record "Production Order"): Code[20]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        SetAllProdOrderTransferComponentLocations(ProductionOrder."No.", ProductionLocationCode);
        // The transfer route is keyed by from/to location, so it must be created only once for a given location pair.
        // Callers that reuse the same locations pass false for subsequent orders to reuse the existing route.
        if CreateTransferRouteForOrder then
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
        Assert.IsTrue(TransferHeader.FindFirst(), 'Expected a subcontracting transfer order for the production order.');
        exit(TransferHeader."No.");
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

    local procedure MockTransferToVendorCompOnOtherLine(TemplateComponent: Record "Prod. Order Component"; NewProdOrderLineNo: Integer; LocationCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Simulate a Transfer to Vendor component that belongs to a different Prod. Order Line and whose
        // Location Code has already been set to the vendor's Subcontracting Location (already in transit).
        ProdOrderComponent := TemplateComponent;
        ProdOrderComponent."Prod. Order Line No." := NewProdOrderLineNo;
        ProdOrderComponent."Line No." := TemplateComponent."Line No." + 10000;
        ProdOrderComponent."Location Code" := LocationCode;
        ProdOrderComponent."Bin Code" := '';
        ProdOrderComponent.Insert();
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

    local procedure CreateItemWithSingleSubcontractingOperation(var Item: Record Item; var SubcWorkCenter: Record "Work Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ComponentItem1: Record Item;
        ComponentItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", true, UnitCostCalculation, '');
        SubcWorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(SubcWorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", SubcWorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryInventory.CreateItem(ComponentItem1);
        LibraryInventory.CreateItem(ComponentItem2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ComponentItem1."No.", ComponentItem2."No.", 1);

        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean;
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

    [Test]
    procedure CopyDocumentDoesNotCopySubcLocationCode()
    var
        FromPurchaseHeader: Record "Purchase Header";
        ToPurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        CopyPurchDoc: Report "Copy Purchase Document";
    begin
        // [SCENARIO 633225] Copy Document should not copy the Subcontracting Location Code to the new purchase order
        Initialize();

        // [GIVEN] A purchase order with Subcontracting Location Code set
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPurchase.CreatePurchaseOrder(FromPurchaseHeader);
        FromPurchaseHeader."Subc. Location Code" := Location.Code;
        FromPurchaseHeader.Modify();

        // [GIVEN] A new target purchase order for the same vendor
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, FromPurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy Document is used to copy the source order (IncludeHeader = true)
        Clear(CopyPurchDoc);
        CopyPurchDoc.SetParameters("Purchase Document Type From"::Order, FromPurchaseHeader."No.", true, false);
        CopyPurchDoc.SetPurchHeader(ToPurchaseHeader);
        CopyPurchDoc.UseRequestPage(false);
        CopyPurchDoc.RunModal();

        // [THEN] Subcontracting Location Code is not copied to the new purchase order
        ToPurchaseHeader.Get(ToPurchaseHeader."Document Type", ToPurchaseHeader."No.");
        Assert.AreEqual('', ToPurchaseHeader."Subc. Location Code", 'Subc. Location Code should not be copied by Copy Document');
    end;

    [Test]
    [HandlerFunctions('ConfirmArchiveOrderHandler,MessageHandler')]
    procedure CopyDocumentFromArchiveDoesNotCopySubcLocationCode()
    var
        FromPurchaseHeader: Record "Purchase Header";
        ToPurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        Location: Record Location;
        ArchiveManagement: Codeunit ArchiveManagement;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        FromDocNo: Code[20];
    begin
        // [SCENARIO 633225] Copy Document from archive should not copy the Subcontracting Location Code to the new purchase order
        Initialize();

        // [GIVEN] A purchase order with Subcontracting Location Code set
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPurchase.CreatePurchaseOrder(FromPurchaseHeader);
        FromPurchaseHeader."Subc. Location Code" := Location.Code;
        FromPurchaseHeader.Modify();
        FromDocNo := FromPurchaseHeader."No.";

        // [GIVEN] The purchase order is archived
        ArchiveManagement.ArchivePurchDocument(FromPurchaseHeader);

        // [GIVEN] A new target purchase order for the same vendor
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, FromPurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy Document is used to copy from the archived order (IncludeHeader = true)
        PurchaseHeaderArchive.SetRange("Document Type", FromPurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", FromDocNo);
        PurchaseHeaderArchive.FindFirst();
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.SetArchDocVal(PurchaseHeaderArchive."Doc. No. Occurrence", PurchaseHeaderArchive."Version No.");
        CopyDocumentMgt.CopyPurchDoc("Purchase Document Type From"::"Arch. Order", FromDocNo, ToPurchaseHeader);

        // [THEN] Subcontracting Location Code is not copied to the new purchase order
        ToPurchaseHeader.Get(ToPurchaseHeader."Document Type", ToPurchaseHeader."No.");
        Assert.AreEqual('', ToPurchaseHeader."Subc. Location Code", 'Subc. Location Code should not be copied from archive by Copy Document');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
    procedure PurchLineFactboxTransferOrderCountExcludesReturnOrder()
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
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
        PurchaseHeaderPage: TestPage "Purchase Order";
        OutboundFromCode: Code[10];
        QtyToShip: Decimal;
    begin
        // [SCENARIO 39] Purchase Line FactBox: No. of Transfer Orders is inflated by the return transfer
        // order, and Return Transfer Order field is blank, when a return to subcontractor is created.

        // [GIVEN] Standard subcontracting setup with an in-transit transfer route
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
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

        // [GIVEN] Outbound Transfer Order created for the subcontracting purchase
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

        // [GIVEN] Items are partially shipped to put them in transit (so AvailableToReturn > 0)
        Location.Get(OutboundFromCode);
        Item.Get(ProdOrderComp."Item No.");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");
        QtyToShip := Round(TransferLine.Quantity / 2, 1, '<');
        TransferLine.Validate("Qty. to Ship", QtyToShip);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] A Return Transfer Order is created
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] A return transfer order is linked to the purchase
        ReturnTransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        ReturnTransferHeader.SetRange("Subc. Return Order", true);
        Assert.IsTrue(ReturnTransferHeader.FindFirst(), 'Return Transfer Order must exist');

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [THEN] No. of Transfer Orders in the FactBox equals 1 — only the outbound order is counted
        Assert.AreEqual(
            1, SubcPurchFactboxMgmt.GetNoOfTransferOrders(PurchaseLine),
            'No. of Transfer Orders must be 1 (outbound only); the return transfer order must not be counted');

        // [THEN] Return Transfer Order No. in the FactBox shows the return order number
        Assert.AreEqual(
            ReturnTransferHeader."No.", SubcPurchFactboxMgmt.GetReturnTransferOrderNo(PurchaseLine),
            'Return Transfer Order No. must match the created return transfer order');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandleTransferOrder')]
    procedure PurchLineFactboxTransferOrderCountIsZeroWhenOnlyReturnExists()
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
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
        PurchaseHeaderPage: TestPage "Purchase Order";
        OutboundFromCode: Code[10];
    begin
        // [SCENARIO 39] Purchase Line FactBox: when the outbound Transfer Order has been fully posted
        // (direct transfer) and only the return transfer order remains, No. of Transfer Orders must
        // be 0 and Return Transfer Order must show the return order number.

        // [GIVEN] Standard subcontracting setup with a direct transfer (no in-transit route)
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
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

        // [GIVEN] Outbound Transfer Order created for the subcontracting purchase (direct transfer)
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

        // [GIVEN] All items are direct-transferred (ship + receive in one step) — outbound lines are consumed
        Location.Get(OutboundFromCode);
        Item.Get(ProdOrderComp."Item No.");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // [WHEN] A Return Transfer Order is created (outbound transfer lines no longer exist)
        PurchaseHeaderPage.GotoKey("Purchase Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] A return transfer order is linked to the purchase
        ReturnTransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        ReturnTransferHeader.SetRange("Subc. Return Order", true);
        Assert.IsTrue(ReturnTransferHeader.FindFirst(), 'Return Transfer Order must exist');

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [THEN] No. of Transfer Orders in the FactBox equals 0 — no outbound transfer lines remain
        Assert.AreEqual(
            0, SubcPurchFactboxMgmt.GetNoOfTransferOrders(PurchaseLine),
            'No. of Transfer Orders must be 0 when only the return transfer order exists');

        // [THEN] Return Transfer Order No. in the FactBox shows the return order number
        Assert.AreEqual(
            ReturnTransferHeader."No.", SubcPurchFactboxMgmt.GetReturnTransferOrderNo(PurchaseLine),
            'Return Transfer Order No. must match the created return transfer order');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TransferOrderActionDisabledOnNonSubcontractingPurchaseLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        NonSubcItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        SubcPurchaseLine: Record "Purchase Line";
        NonSubcPurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [FEATURE] [Subcontracting]
        // [SCENARIO 638531] The "Transfer Order" action on the Purchase Order Subform must be disabled
        // for a non-subcontracting line (no Prod. Order No.) and enabled for a subcontracting line.
        Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();

        // [GIVEN] Work and Machine Centers, an Item with Routing and Prod. BOM configured for Transfer subcontracting
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order with its transfer components located
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // [GIVEN] A subcontracting purchase order is created from the routing (with Prod. Order No. set on the subc. line)
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        SubcPurchaseLine.SetRange("Document Type", SubcPurchaseLine."Document Type"::Order);
        SubcPurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcPurchaseLine.FindFirst();
        PurchaseHeader.Get(SubcPurchaseLine."Document Type", SubcPurchaseLine."Document No.");

        // [GIVEN] A second non-subcontracting line is added to the same purchase order (no Prod. Order No.)
        LibraryInventory.CreateItem(NonSubcItem);
        LibraryPurchase.CreatePurchaseLine(
            NonSubcPurchaseLine, PurchaseHeader, NonSubcPurchaseLine.Type::Item, NonSubcItem."No.", 1);

        // [WHEN] Opening the Purchase Order page
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);

        // [THEN] "Transfer Order" action is enabled on the subcontracting line (Prod. Order No. is set)
        PurchaseOrderPage.PurchLines.GoToRecord(SubcPurchaseLine);
        Assert.IsTrue(
            PurchaseOrderPage.PurchLines."Transfer Order".Enabled(),
            'Transfer Order action must be enabled for a subcontracting purchase line (Prod. Order No. is set).');

        // [THEN] "Transfer Order" action is disabled on the non-subcontracting line (no Prod. Order No.)
        PurchaseOrderPage.PurchLines.GoToRecord(NonSubcPurchaseLine);
        Assert.IsFalse(
            PurchaseOrderPage.PurchLines."Transfer Order".Enabled(),
            'Transfer Order action must be disabled for a non-subcontracting purchase line (no Prod. Order No.).');

        PurchaseOrderPage.Close();
    end;

    [Test]
    procedure GetReceiptLinesBlocksSubcontractingReceiptLine()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // [SCENARIO 632785] Copying a subcontracting service receipt line into a separate purchase document is not
        // supported (Direct Unit Cost, Gen. Prod. Posting Group, etc. are not transferred) and must be blocked.

        // [GIVEN] A purchase invoice and a posted subcontracting receipt line linked to a production order
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        MockSubcontractingPurchRcptLine(PurchRcptLine, false);

        // [WHEN] Getting the subcontracting receipt line into the invoice
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [THEN] It is blocked
        Assert.ExpectedError('subcontracting receipt lines');
    end;

    [Test]
    [HandlerFunctions('GetOrderLinesPurchaseLinesPageHandler')]
    procedure GetOrderLinesExcludesSubcontractingPurchaseOrderLines()
    var
        OrderHeader: Record "Purchase Header";
        OrderLine: Record "Purchase Line";
        InvoiceHeader: Record "Purchase Header";
        InvoiceLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        MatchedOrderLineMgmt: Codeunit "Matched Order Line Mgmt.";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // [SCENARIO 632785] Subcontracting purchase order lines must not appear in the Get Order Lines selection on a
        // separate purchase invoice, because invoicing them there is not supported.

        // [GIVEN] A purchase order line linked to a production order, received but not invoiced
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(OrderHeader, OrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(OrderLine, OrderHeader, OrderLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        OrderLine."Qty. Rcd. Not Invoiced" := OrderLine.Quantity;
        OrderLine."Prod. Order No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(OrderLine."Prod. Order No."));
        OrderLine.Modify();

        // [GIVEN] A separate purchase invoice for the same vendor
        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        InvoiceLine."Document Type" := InvoiceHeader."Document Type";
        InvoiceLine."Document No." := InvoiceHeader."No.";

        // [WHEN] Running Get Order Lines [THEN] the page handler verifies the subcontracting order line is not offered
        MatchedOrderLineMgmt.GetPurchaseOrderLines(InvoiceLine);
    end;

    local procedure MockSubcontractingPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; Undone: Boolean)
    var
        Item: Record Item;
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryInventory.CreateItem(Item);
        PurchRcptLine.Init();
        PurchRcptLine."Document No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchRcptLine."Document No."));
        PurchRcptLine."Line No." := 10000;
        PurchRcptLine.Type := PurchRcptLine.Type::Item;
        PurchRcptLine."No." := Item."No.";
        PurchRcptLine."Prod. Order No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchRcptLine."Prod. Order No."));
        PurchRcptLine."Routing No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchRcptLine."Routing No."));
        PurchRcptLine."Operation No." := '10';
        PurchRcptLine.Quantity := LibraryRandom.RandIntInRange(5, 10);
        PurchRcptLine."Qty. Rcd. Not Invoiced" := PurchRcptLine.Quantity;
        PurchRcptLine.Correction := Undone;
        PurchRcptLine.Insert();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Subcontracting Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        LibraryVariableStorage.Clear();

        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Subcontracting Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Subcontracting Test");
    end;

    local procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
    end;

    local procedure RunCalculateSubcontracts()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
    begin
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();
    end;

    local procedure UpdateSubMgmtSetupTransferInfoLine(Update: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Create Prod. Order Info Line" := Update;
        ManufacturingSetup.Modify();
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

    procedure SelectRequisitionTemplateName(): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        ReqWkshTemplate.SetRange(Recurring, false);
        if not ReqWkshTemplate.FindFirst() then begin
            ReqWkshTemplate.Init();
            ReqWkshTemplate.Validate(
              Name, LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"));
            ReqWkshTemplate.Insert(true);
            ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Subcontracting);
            ReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        OpenedTransferOrderNo: Code[20];
        OpenedTransferOrderListNo: Code[20];
        PurchaseOrderPageOpened: Boolean;
        PurchaseLinesPageOpened: Boolean;
        UnitCostCalculation: Option Time,Units;
        ConfirmDialogCalledCount: Integer;
        AlreadySpecifiedErr: Label 'You cannot open Tracking Specification because this component is already specified in Transfer Order %1.', Comment = '|%1 = Transfer Order No.';
        PurchOrderRoutingErr: Label 'Purchase Order %1 should contain a line tied to Routing Reference No. %2', Comment = '%1 = Purchase Order No., %2 = Routing Reference No.';

}