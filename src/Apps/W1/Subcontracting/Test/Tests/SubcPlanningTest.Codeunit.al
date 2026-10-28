// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Calendar;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 139996 "Subc. Planning Test"
{
    // [FEATURE] Subcontracting Planning
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure TransferWIPItemFromRoutingVersionThroughPlanning()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PlanningRoutingLine: Record "Planning Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 648937] Transfer WIP settings from a routing version are retained through planning and production order creation
        Initialize();

        // [GIVEN] Manufactured item "I" with a certified subcontracting routing version that transfers the WIP item
        SubcontractingMgmtLibrary.SetupInventorySetup();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        CreateCertifiedRoutingVersionWithTransferWIPItem(Item."Routing No.", WorkCenter[2]."No.", RoutingLine);

        // [GIVEN] Planning worksheet line "P" for item "I" is refreshed
        CreateAndRefreshPlanningLine(Item, Location, RequisitionWkshName, RequisitionLine);

        // [THEN] Planning line "P" uses the certified routing version and retains its WIP transfer settings
        Assert.AreEqual(RoutingLine."Version Code", RequisitionLine."Routing Version Code", 'The planning line should use the certified routing version.');
        FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine, WorkCenter[2]."No.");
        VerifyTransferWIPItemFields(PlanningRoutingLine."Transfer WIP Item", PlanningRoutingLine."Transfer Description", PlanningRoutingLine."Transfer Description 2");

        // [WHEN] Planning line "P" is carried out as a firm planned production order
        CarryOutPlanningLine(RequisitionLine);

        // [THEN] The production order routing line retains the WIP transfer settings
        FindProdOrderRoutingLine(ProdOrderRoutingLine, Item."No.", WorkCenter[2]."No.");
        VerifyTransferWIPItemFields(ProdOrderRoutingLine."Transfer WIP Item", ProdOrderRoutingLine."Transfer Description", ProdOrderRoutingLine."Transfer Description 2");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure TransferWIPItemFromBaseRoutingThroughPlanning()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PlanningRoutingLine: Record "Planning Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 648937] Transfer WIP settings from a base routing are retained through planning and production order creation
        Initialize();

        // [GIVEN] Manufactured item "I" with a certified subcontracting base routing that transfers the WIP item
        SubcontractingMgmtLibrary.SetupInventorySetup();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SetTransferWIPItemOnBaseRoutingLine(Item."Routing No.", WorkCenter[2]."No.", RoutingLine);

        // [GIVEN] Planning worksheet line "P" for item "I" is refreshed
        CreateAndRefreshPlanningLine(Item, Location, RequisitionWkshName, RequisitionLine);

        // [THEN] Planning line "P" uses the base routing and retains its WIP transfer settings
        Assert.AreEqual('', RequisitionLine."Routing Version Code", 'The planning line should use the base routing.');
        FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine, WorkCenter[2]."No.");
        VerifyTransferWIPItemFields(PlanningRoutingLine."Transfer WIP Item", PlanningRoutingLine."Transfer Description", PlanningRoutingLine."Transfer Description 2");

        // [WHEN] Planning line "P" is carried out as a firm planned production order
        CarryOutPlanningLine(RequisitionLine);

        // [THEN] The production order routing line retains the WIP transfer settings
        FindProdOrderRoutingLine(ProdOrderRoutingLine, Item."No.", WorkCenter[2]."No.");
        VerifyTransferWIPItemFields(ProdOrderRoutingLine."Transfer WIP Item", ProdOrderRoutingLine."Transfer Description", ProdOrderRoutingLine."Transfer Description 2");
    end;

    [Test]
    procedure TestTransferComponentSupplyMethodAndVendorLocationIntoPlanningComponent()
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PlanningComponent: Record "Planning Component";
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ReqWkshTemplateName: Code[10];
        Direction: Option Forward,Backward;
    begin
        // [SCENARIO] Create Sales Order and test Planning Component

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
        Item."Reordering Policy" := "Reordering Policy"::Order;
        Item.Modify();

        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Consignment at Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

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
        PlanningComponent.TestField("Component Supply Method", "Component Supply Method"::"Consignment at Vendor");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        PlanningComponent.TestField("Location Code", Vendor."Subc. Location Code");

        // [WHEN] A Planning Worksheet line is added manually for the same item and Refresh Planning Line is run (bug 637499 repro)
        ReqWkshTemplateName := LibraryPlanning.SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplateName, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10) + 5);
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // [THEN] The Subcontracting Type (Component Supply Method) is copied from the Production BOM Line to the Planning Component
        Clear(PlanningComponent);
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningComponent.SetRange("Item No.", ProductionBOMLine."No.");
        PlanningComponent.FindFirst();
        PlanningComponent.TestField("Component Supply Method", "Component Supply Method"::"Consignment at Vendor");
        // [THEN] and the component is relocated to the subcontractor location, matching the Production Order behavior
        PlanningComponent.TestField("Location Code", Vendor."Subc. Location Code");
    end;

    [Test]
    procedure PurchaseSubcTypeProdOrderCompExcludedFromPlanning()
    var
        ComponentItem: Record Item;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 630597] Prod. Order Components with Component Supply Method "Purchase" should be
        // excluded from planning engines because they will be purchased later via the subcontracting
        // purchase order.

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Create subcontracting Work/Machine Centers
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM (2 component items)
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        // [GIVEN] Assign Routing Link Code between subcontracting routing line and last BOM line
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        // [GIVEN] Set Component Supply Method = Vendor-Supplied on the linked BOM line
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        // [GIVEN] Set up vendor with subcontracting location
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Set component item reordering policy to Lot-for-Lot (already done during creation)
        // [GIVEN] Create inventory for the component item so planning considers it
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindLast();
        ComponentItem.Get(ProductionBOMLine."No.");
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create and refresh Released Production Order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Verify prod. order component with Purchase Component Supply Method exists
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComp.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComp.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
        Assert.RecordIsNotEmpty(ProdOrderComp);

        // [WHEN] Run Regenerative Plan for the component item
        ComponentItem.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [THEN] No requisition line is suggested for the component with Vendor-Supplied component supply method
        RequisitionLine.SetRange("No.", ComponentItem."No.");
        Assert.RecordIsEmpty(RequisitionLine);

        // [WHEN] Changing the Component Supply Method to None and run planning again
        SubcontractingMgmtLibrary.UpdateProdOrderComponentWithComponentSupplyMethod(ProductionOrder, "Component Supply Method"::Empty);
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [THEN] Requisition line is suggested for the component with None component supply method
        RequisitionLine.SetRange("No.", ComponentItem."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    [Test]
    procedure VendorSuppliedComponentVisibleInPlanningWorksheetAfterRefresh()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PlanningComponent: Record "Planning Component";
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshName: Record "Requisition Wksh. Name";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ReqWkshTemplateName: Code[10];
        Direction: Option Forward,Backward;
    begin
        // [SCENARIO 640113] Lines with Subcontracting Type = Vendor Supplied should appear in Planning
        // Worksheet components when refreshing from Production BOM so consumption can be registered.

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        // [GIVEN] Assign Routing Link Code between subcontracting routing line and last BOM line
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        // [GIVEN] Set Component Supply Method = Vendor-Supplied on the linked BOM line
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        // [GIVEN] Set up vendor with subcontracting location
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A Planning Worksheet line is added manually for the item
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ReqWkshTemplateName := LibraryPlanning.SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplateName, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10) + 5);
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Modify(true);

        // [WHEN] Refresh Planning Line is run
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // [THEN] The component with Vendor-Supplied type is present in Planning Components
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindLast();
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningComponent.SetRange("Item No.", ProductionBOMLine."No.");
        Assert.RecordIsNotEmpty(PlanningComponent);

        // [THEN] The Component Supply Method is correctly transferred
        PlanningComponent.FindFirst();
        PlanningComponent.TestField("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
        // [THEN] The component is relocated to the subcontractor location for consumption registration
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        PlanningComponent.TestField("Location Code", Vendor."Subc. Location Code");

        // [THEN] No separate replenishment Requisition Line is generated for the vendor-supplied component item
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("No.", ProductionBOMLine."No.");
        Assert.RecordIsEmpty(RequisitionLine);

        // [TEAR DOWN] Clean up the Planning Worksheet lines and names
        RequisitionLine.Reset();
        RequisitionLine.DeleteAll(true);
        ReqWkshName.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure VendorSuppliedPlanningComponentNotPlannedSeparately()
    var
        ComponentItem: Record Item;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PlanningComponent: Record "Planning Component";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        ReqWkshTemplateName: Code[10];
        Direction: Option Forward,Backward;
    begin
        // [SCENARIO] Planning Components with Component Supply Method = Vendor-Supplied must not
        // generate separate demand when CalcRegenPlan is run for the component item, because
        // vendor-supplied components are purchased through the subcontracting purchase order.

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        // [GIVEN] Assign Routing Link Code between subcontracting routing line and last BOM line
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");

        // [GIVEN] Set Component Supply Method = Vendor-Supplied on the linked BOM line
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        // [GIVEN] Set up vendor with subcontracting location
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A Planning Worksheet line for the parent item is refreshed, creating Planning Components
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ReqWkshTemplateName := LibraryPlanning.SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplateName, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10) + 5);
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // [GIVEN] The component item from the BOM with Vendor-Supplied supply method
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindLast();
        ComponentItem.Get(ProductionBOMLine."No.");

        // [WHEN] Run Regenerative Plan for the component item
        ComponentItem.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [THEN] No requisition line is suggested for the Vendor-Supplied component
        RequisitionLine.SetRange("No.", ComponentItem."No.");
        Assert.RecordIsEmpty(RequisitionLine);

        // [THEN] The Vendor-Supplied Planning Component still exists in the planning worksheet (the planning
        // run must not remove it — it is needed for consumption registration in the production order)
        PlanningComponent.SetRange("Item No.", ComponentItem."No.");
        Assert.RecordIsNotEmpty(PlanningComponent);
        PlanningComponent.FindFirst();
        PlanningComponent.TestField("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");

        // [WHEN] Carry out the parent item's planning line to create a planned production order
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        CarryOutPlanningLine(RequisitionLine);

        // [THEN] The created planned production order contains the Vendor-Supplied component
        // (carrying out the planning line must not strip the component from the production order)
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.SetRange(Status, "Production Order Status"::"Firm Planned");
        ProductionOrder.FindFirst();
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
        Assert.RecordIsNotEmpty(ProdOrderComponent);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");

        // [WHEN] Changing the Prod. Order Component's supply method to Empty
        // (Planning Components are gone after carry-out; use the Prod. Order Component)
        ProdOrderComponent."Component Supply Method" := "Component Supply Method"::Empty;
        ProdOrderComponent.Modify();

        // [WHEN] Run Regenerative Plan again for the component item
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [THEN] Requisition line is now suggested for the component
        RequisitionLine.SetRange("No.", ComponentItem."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);

        // [TEAR DOWN] Clean up the Planning Worksheet lines and names
        RequisitionLine.Reset();
        RequisitionLine.DeleteAll(true);
        RequisitionWkshName.DeleteAll(true);
    end;

    [Test]
    procedure VendorSuppliedPurchLineNotCancelledByPlanning()
    var
        ComponentItem: Record Item;
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 650344] Planning must not cancel a Vendor-Supplied component line on a subcontracting purchase order.
        Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] A released production order with a Vendor-Supplied component linked to a subcontracting operation
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] A subcontracting purchase order containing the Vendor-Supplied component line
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
#pragma warning disable AA0210
        ProductionBOMLine.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();
        ComponentItem.Get(ProductionBOMLine."No.");

        SubcontractingMgmtLibrary.FindSubcPurchLineForProdOrder(PurchaseLine, Item."No.", ProductionOrder."No.");
        SubcontractingMgmtLibrary.FindComponentPurchLine(PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        PurchaseLineComp.FindFirst();
        PurchaseLineComp.TestField("Subc. Prod. Order No.", ProductionOrder."No.");

        // [WHEN] Regenerative planning is calculated for the Vendor-Supplied component
        ComponentItem.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [THEN] Planning does not suggest cancelling the component purchase line
        RequisitionLine.Reset();
        RequisitionLine.SetRange("No.", ComponentItem."No.");
        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::Cancel);
        Assert.RecordIsEmpty(RequisitionLine);

        // [THEN] The Vendor-Supplied component purchase line remains linked to the production order
        PurchaseLineComp.FindFirst();
        PurchaseLineComp.TestField("Subc. Prod. Order No.", ProductionOrder."No.");
    end;

    [Test]
    procedure VendorSuppliedCompQtyUpdatedOnPurchOrderReschedule()
    begin
        VerifyVendorSuppliedComponentCreationAndRescheduling('<10D>', '', '', '<10D>');
    end;

    [Test]
    procedure VendorSuppliedCompItemVendorLeadTimeOnReschedule()
    begin
        VerifyVendorSuppliedComponentCreationAndRescheduling('<10D>', '<7D>', '<5D>', '<5D>');
    end;

    [Test]
    procedure VendorSuppliedCompSKULeadTimeOnReschedule()
    begin
        VerifyVendorSuppliedComponentCreationAndRescheduling('<10D>', '<7D>', '', '<7D>');
    end;

    [Test]
    procedure VendorSuppliedCompVendorLeadTimeOnReschedule()
    begin
        VerifyVendorSuppliedComponentCreationAndRescheduling('', '', '', '<20D>');
    end;

    local procedure VerifyVendorSuppliedComponentCreationAndRescheduling(ItemLeadTime: Text[30]; SKULeadTime: Text[30]; ItemVendorLeadTime: Text[30]; ExpectedLeadTime: Text[30])
    var
        Item: Record Item;
        ComponentItem: Record Item;
        ItemVendor: Record "Item Vendor";
        StockkeepingUnit: Record "Stockkeeping Unit";
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderComponent2: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ComponentDueDate: Date;
        InitialQty: Decimal;
        NewQty: Decimal;
        ExpectedComponentCount: Integer;
        InitialComponentPurchaseLineErr: Label 'Each vendor-supplied component must have its own purchase line after initial PO creation.';
        ComponentPurchaseLineQuantityErr: Label 'The component purchase line quantity should match its production component.';
        ComponentPurchaseLineDueDateErr: Label 'The component purchase line due date should match its production component.';
        ExpectedVendorSuppliedComponentCountErr: Label 'The test requires two matching vendor-supplied production components.';
        RescheduledComponentPurchaseLineErr: Label 'Rescheduling must update the purchase line linked to each production component.';
        RescheduledComponentPurchaseLineQuantityErr: Label 'Each vendor-supplied component purchase line quantity should match its production component after rescheduling.';
        RescheduledComponentPurchaseLineDateErr: Label 'Each vendor-supplied component purchase line date should match its production component after rescheduling.';
        ExpectedRescheduledComponentCountErr: Label 'Rescheduling must update both matching vendor-supplied component lines.';
    begin
        // [SCENARIO 637496] Worksheet creation and rescheduling keep duplicate vendor-supplied components
        // mapped to separate purchase lines with exact dates and standard purchase lead-time precedence.

        // [GIVEN] A subcontracting setup with a Vendor-Supplied component
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order
        InitialQty := LibraryRandom.RandIntInRange(5, 10);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", InitialQty);

        // [GIVEN] Two matching vendor-supplied components with separate quantities and due dates
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProdOrderComponent.FindFirst();
        ComponentItem.Get(ProdOrderComponent."Item No.");
        Clear(ComponentItem."Lead Time Calculation");
        if ItemLeadTime <> '' then
            Evaluate(ComponentItem."Lead Time Calculation", ItemLeadTime);
        Evaluate(ComponentItem."Safety Lead Time", '<3D>');
        ComponentItem.Modify(true);
        Location.Get(ProdOrderComponent."Location Code");
        BaseCalendar.Code := CopyStr(
            LibraryUtility.GenerateRandomCode(BaseCalendar.FieldNo(Code), Database::"Base Calendar"),
            1, MaxStrLen(BaseCalendar.Code));
        BaseCalendar.Name := 'Component Purchase';
        BaseCalendar.Insert();
        BaseCalendarChange."Base Calendar Code" := BaseCalendar.Code;
        ComponentDueDate := CalcDate('<30D>', WorkDate());
        BaseCalendarChange.Validate(Date, CalcDate('<-2D>', ComponentDueDate));
        BaseCalendarChange.Description := 'Handling calendar test';
        BaseCalendarChange.Nonworking := true;
        BaseCalendarChange.Insert(true);
        Evaluate(Location."Inbound Whse. Handling Time", '<2D>');
        Location."Base Calendar Code" := BaseCalendar.Code;
        Location.Modify(true);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Evaluate(Vendor."Lead Time Calculation", '<20D>');
        Vendor."Base Calendar Code" := BaseCalendar.Code;
        Vendor.Modify(true);
        if SKULeadTime <> '' then begin
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(
                StockkeepingUnit, Location.Code, ComponentItem."No.", ProdOrderComponent."Variant Code");
            Evaluate(StockkeepingUnit."Lead Time Calculation", SKULeadTime);
            Evaluate(StockkeepingUnit."Safety Lead Time", '<3D>');
            StockkeepingUnit.Modify(true);
        end;
        if ItemVendorLeadTime <> '' then begin
            LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", ComponentItem."No.");
            ItemVendor.Validate("Variant Code", ProdOrderComponent."Variant Code");
            Evaluate(ItemVendor."Lead Time Calculation", ItemVendorLeadTime);
            ItemVendor.Modify(true);
        end;
        ProdOrderComponent."Due Date" := ComponentDueDate;
        ProdOrderComponent.Modify(true);

        ProdOrderComponent2.Init();
        ProdOrderComponent2.TransferFields(ProdOrderComponent);
        ProdOrderComponent2."Line No." += 10000;
        ProdOrderComponent2."Expected Quantity" += 5;
        ProdOrderComponent2."Expected Qty. (Base)" += 5;
        ProdOrderComponent2."Remaining Quantity" += 5;
        ProdOrderComponent2."Remaining Qty. (Base)" += 5;
        ProdOrderComponent2."Due Date" := CalcDate('<1D>', ComponentDueDate);
        ProdOrderComponent2.Insert();

        // [GIVEN] A subcontracting purchase order created via the requisition worksheet
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        // [GIVEN] The vendor-supplied component purchase line exists
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
#pragma warning disable AA0210
        ProductionBOMLine.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();
        ComponentItem.Get(ProductionBOMLine."No.");

        SubcontractingMgmtLibrary.FindSubcPurchLineForProdOrder(PurchaseLine, Item."No.", ProductionOrder."No.");
        SubcontractingMgmtLibrary.FindComponentPurchLine(PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        ProdOrderComponent.FindSet();
        repeat
            PurchaseLineComp.Reset();
            SubcontractingMgmtLibrary.FindComponentPurchLine(PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
            PurchaseLineComp.SetRange("Subc. Prod. Comp. Line No.", ProdOrderComponent."Line No.");
            Assert.IsTrue(PurchaseLineComp.FindFirst(), InitialComponentPurchaseLineErr);
            Assert.AreEqual(ProdOrderComponent."Remaining Quantity", PurchaseLineComp.Quantity, ComponentPurchaseLineQuantityErr);
            Assert.AreEqual(ProdOrderComponent."Due Date", PurchaseLineComp."Expected Receipt Date", ComponentPurchaseLineDueDateErr);
            AssertVendorSuppliedComponentPurchaseDates(ProdOrderComponent, PurchaseLineComp, Location, Vendor, BaseCalendar, ExpectedLeadTime);
            ExpectedComponentCount += 1;
        until ProdOrderComponent.Next() = 0;
        Assert.AreEqual(2, ExpectedComponentCount, ExpectedVendorSuppliedComponentCountErr);

        // Simulate component purchase lines created before the component identity was stored.
        PurchaseLineComp.Reset();
        PurchaseLineComp.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLineComp.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLineComp.SetRange(Type, PurchaseLineComp.Type::Item);
#pragma warning disable AA0210
        PurchaseLineComp.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLineComp.SetRange("Subc. Prod. Order Line No.", RequisitionLine."Prod. Order Line No.");
        PurchaseLineComp.SetRange("Subc. Operation No.", RequisitionLine."Operation No.");
        if PurchaseLineComp.FindSet() then
            repeat
                PurchaseLineComp."Subc. Prod. Comp. Line No." := 0;
                PurchaseLineComp.Modify();
            until PurchaseLineComp.Next() = 0;

        // [WHEN] The production order quantity is increased and refreshed
        NewQty := InitialQty + LibraryRandom.RandIntInRange(3, 7);
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, NewQty);
        ProdOrderLine.Modify(true);

        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ExpectedComponentCount := 0;
        ProdOrderComponent.FindSet();
        repeat
            ExpectedComponentCount += 1;
            ProdOrderComponent."Remaining Quantity" := ProdOrderComponent."Remaining Quantity" + ExpectedComponentCount;
            ProdOrderComponent."Due Date" := CalcDate('<' + Format(30 + ExpectedComponentCount) + 'D>', WorkDate());
            ProdOrderComponent.Modify();
        until ProdOrderComponent.Next() = 0;

        // [WHEN] CalculateSubcontracts is run again and carried out (reschedule path)
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);

        Assert.IsTrue(
            RequisitionLine."Action Message" in
                [RequisitionLine."Action Message"::"Change Qty.",
                 RequisitionLine."Action Message"::"Resched. & Chg. Qty."],
            'Requisition line should have a Change Qty or Reschedule action message.');

        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        // [THEN] Rescheduling updates each component's own purchase line quantity and dates
        ExpectedComponentCount := 0;
        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProdOrderComponent.FindSet();
        repeat
            PurchaseLineComp.Reset();
            SubcontractingMgmtLibrary.FindComponentPurchLine(PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
            PurchaseLineComp.SetRange("Subc. Prod. Comp. Line No.", ProdOrderComponent."Line No.");
            Assert.IsTrue(PurchaseLineComp.FindFirst(), RescheduledComponentPurchaseLineErr);
            Assert.AreEqual(
                ProdOrderComponent."Remaining Quantity",
                PurchaseLineComp.Quantity,
                RescheduledComponentPurchaseLineQuantityErr);
            Assert.AreEqual(
                ProdOrderComponent."Due Date",
                PurchaseLineComp."Expected Receipt Date",
                RescheduledComponentPurchaseLineDateErr);
            AssertVendorSuppliedComponentPurchaseDates(ProdOrderComponent, PurchaseLineComp, Location, Vendor, BaseCalendar, ExpectedLeadTime);
            ExpectedComponentCount += 1;
        until ProdOrderComponent.Next() = 0;
        Assert.AreEqual(2, ExpectedComponentCount, ExpectedRescheduledComponentCountErr);
    end;

    [Test]
    procedure VendorSuppliedCompQtyUpdatedOnFamilyPurchOrderReschedule()
    var
        Family: Record Family;
        FamilyLine: Record "Family Line";
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        ExactPurchaseLineComp: Record "Purchase Line";
        ExistingPurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCompFactboxMgmt: Codeunit "Subc. Comp. Factbox Mgmt.";
        InitialQuantity: Decimal;
        NewComponentQuantity: Decimal;
        NewComponentDueDate: Date;
        FamilyRoutingReferenceErr: Label 'The Family routing reference should be zero.';
        FamilyProdOrderLineReferenceErr: Label 'The Family production-order line number must differ from the routing reference.';
        InitialComponentPurchaseLineErr: Label 'The component purchase line should store the actual production-order line number.';
        FamilyRescheduleActionErr: Label 'The Family requisition line should request a component quantity or date reschedule.';
        MigratedComponentPurchaseLineErr: Label 'Rescheduling should migrate the legacy routing reference and component identity.';
        FamilyComponentQuantityErr: Label 'The Family component purchase quantity should be updated.';
        FamilyComponentDateErr: Label 'The Family component purchase date should be updated.';
        LegacyFamilyComponentOutstandingQuantityErr: Label 'An unambiguous legacy Family component purchase line should remain visible in the outstanding quantity.';
        MixedFamilyComponentOutstandingQuantityErr: Label 'An unambiguous legacy Family component purchase line should be included together with exact-identity lines.';
    begin
        // [SCENARIO] A vendor-supplied component is rescheduled for a Family output whose production line number differs from the shared routing reference.
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", 1);
        Family.Validate("Routing No.", Item."Routing No.");
        Family.Modify(true);

        InitialQuantity := LibraryRandom.RandIntInRange(5, 10);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Family, Family."No.", InitialQuantity);

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(0, ProdOrderRoutingLine."Routing Reference No.", FamilyRoutingReferenceErr);
        Assert.IsTrue(
            ProdOrderLine."Line No." <> ProdOrderRoutingLine."Routing Reference No.",
            FamilyProdOrderLineReferenceErr);

        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        SubcontractingMgmtLibrary.FindSubcPurchLineForProdOrder(PurchaseLine, Item."No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProdOrderComponent.FindFirst();
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ProdOrderComponent."Item No.");
        PurchaseLineComp.SetRange("Subc. Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchaseLineComp.SetRange("Subc. Prod. Comp. Line No.", ProdOrderComponent."Line No.");
        Assert.IsTrue(PurchaseLineComp.FindFirst(), InitialComponentPurchaseLineErr);

        // Simulate a component purchase line created before the line-number field was corrected.
        PurchaseLineComp."Subc. Prod. Order Line No." := ProdOrderRoutingLine."Routing Reference No.";
        PurchaseLineComp."Subc. Prod. Comp. Line No." := 0;
        PurchaseLineComp.Modify();
        Assert.AreEqual(
            PurchaseLineComp."Outstanding Qty. (Base)",
            SubcCompFactboxMgmt.GetPurchOrderOutstandingQtyBaseFromProdOrderComp(ProdOrderComponent),
            LegacyFamilyComponentOutstandingQuantityErr);

        // Mixed identities: an exact-identity line must not hide the unambiguous legacy line.
        ExactPurchaseLineComp := PurchaseLineComp;
        ExistingPurchaseLine.SetRange("Document Type", PurchaseLineComp."Document Type");
        ExistingPurchaseLine.SetRange("Document No.", PurchaseLineComp."Document No.");
        ExistingPurchaseLine.FindLast();
        ExactPurchaseLineComp."Line No." := ExistingPurchaseLine."Line No." + 10000;
        ExactPurchaseLineComp."Subc. Prod. Order Line No." := ProdOrderLine."Line No.";
        ExactPurchaseLineComp."Subc. Prod. Comp. Line No." := ProdOrderComponent."Line No.";
        ExactPurchaseLineComp.Insert();
        Assert.AreEqual(
            PurchaseLineComp."Outstanding Qty. (Base)" + ExactPurchaseLineComp."Outstanding Qty. (Base)",
            SubcCompFactboxMgmt.GetPurchOrderOutstandingQtyBaseFromProdOrderComp(ProdOrderComponent),
            MixedFamilyComponentOutstandingQuantityErr);
        ExactPurchaseLineComp.Delete();

        ProdOrderLine.Validate(Quantity, InitialQuantity + 1);
        ProdOrderLine.Modify(true);
        ProdOrderComponent.FindFirst();
        NewComponentQuantity := ProdOrderComponent."Remaining Quantity" + 1;
        NewComponentDueDate := CalcDate('<30D>', WorkDate());
        ProdOrderComponent."Remaining Quantity" := NewComponentQuantity;
        ProdOrderComponent."Due Date" := NewComponentDueDate;
        ProdOrderComponent.Modify();

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        Assert.IsTrue(
            RequisitionLine."Action Message" in
                [RequisitionLine."Action Message"::"Change Qty.",
                 RequisitionLine."Action Message"::"Resched. & Chg. Qty."],
            FamilyRescheduleActionErr);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Reset();
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ProdOrderComponent."Item No.");
        PurchaseLineComp.SetRange("Subc. Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchaseLineComp.SetRange("Subc. Prod. Comp. Line No.", ProdOrderComponent."Line No.");
        Assert.IsTrue(PurchaseLineComp.FindFirst(), MigratedComponentPurchaseLineErr);
        Assert.AreEqual(NewComponentQuantity, PurchaseLineComp.Quantity, FamilyComponentQuantityErr);
        Assert.AreEqual(NewComponentDueDate, PurchaseLineComp."Expected Receipt Date", FamilyComponentDateErr);
    end;

    [Test]
    procedure AmbiguousLegacyFamilyComponentLineIsNotMigratedToAnotherOutput()
    var
        Family: Record Family;
        FamilyLine: array[2] of Record "Family Line";
        Item: Record Item;
        SecondOutputItem: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComponent: array[2] of Record "Prod. Order Component";
        MovedProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLineComp: array[2] of Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCompFactboxMgmt: Codeunit "Subc. Comp. Factbox Mgmt.";
        InitialQuantity: Decimal;
        NewComponentQuantity: Decimal;
        NewComponentDueDate: Date;
        OutputIndex: Integer;
        OriginalPurchaseQuantity: array[2] of Decimal;
        OriginalPurchaseDueDate: array[2] of Date;
        AmbiguousFamilyPurchaseOrderErr: Label 'Both Family outputs must share one subcontracting purchase order for this regression.';
        FamilyOutputPurchaseLineErr: Label 'Each Family output must have its own vendor-supplied component purchase line.';
        FamilyOutputSharedComponentErr: Label 'Both Family outputs must share the same vendor-supplied component.';
        AmbiguousLegacyPurchaseLineQuantityErr: Label 'Rescheduling one Family output must not overwrite an ambiguous legacy component purchase line.';
        AmbiguousLegacyPurchaseLineDateErr: Label 'Rescheduling one Family output must not overwrite the date on an ambiguous legacy component purchase line.';
        AmbiguousLegacyPurchaseLineIdentityErr: Label 'An ambiguous legacy component purchase line must not be relinked to another Family output.';
        FamilyOutputRescheduleActionErr: Label 'The second Family output should have a quantity or date reschedule action.';
        FamilyComponentOutstandingQuantityErr: Label 'The Family component outstanding quantity should use the actual production-line identity.';
    begin
        // [SCENARIO] Rescheduling one Family output does not migrate a legacy component purchase line shared by multiple outputs.
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibraryInventory.CreateItem(SecondOutputItem);
        SecondOutputItem.Validate("Production BOM No.", Item."Production BOM No.");
        SecondOutputItem.Modify(true);

        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", SecondOutputItem."No.", 1);
        Family.Validate("Routing No.", Item."Routing No.");
        Family.Modify(true);

        InitialQuantity := LibraryRandom.RandIntInRange(5, 10);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Family, Family."No.", InitialQuantity);

        for OutputIndex := 1 to 2 do begin
            ProdOrderLine[OutputIndex].SetRange(Status, ProductionOrder.Status);
            ProdOrderLine[OutputIndex].SetRange("Prod. Order No.", ProductionOrder."No.");
            if OutputIndex = 1 then
                ProdOrderLine[OutputIndex].SetRange("Item No.", Item."No.")
            else
                ProdOrderLine[OutputIndex].SetRange("Item No.", SecondOutputItem."No.");
            Assert.IsTrue(ProdOrderLine[OutputIndex].FindFirst(), FamilyOutputPurchaseLineErr);

            ProdOrderComponent[OutputIndex].SetRange(Status, ProductionOrder.Status);
            ProdOrderComponent[OutputIndex].SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderComponent[OutputIndex].SetRange("Prod. Order Line No.", ProdOrderLine[OutputIndex]."Line No.");
#pragma warning disable AA0210
            ProdOrderComponent[OutputIndex].SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
            Assert.IsTrue(ProdOrderComponent[OutputIndex].FindFirst(), FamilyOutputPurchaseLineErr);
        end;
        Assert.AreEqual(
            ProdOrderComponent[1]."Item No.",
            ProdOrderComponent[2]."Item No.",
            FamilyOutputSharedComponentErr);

        // Give the second output a different component line number than the first one.
        MovedProdOrderComponent := ProdOrderComponent[2];
        MovedProdOrderComponent."Line No." := ProdOrderComponent[1]."Line No." + 10000;
        MovedProdOrderComponent.Insert();
        ProdOrderComponent[2].Delete();
        ProdOrderComponent[2].SetRange("Line No.", MovedProdOrderComponent."Line No.");
        Assert.IsTrue(ProdOrderComponent[2].FindFirst(), FamilyOutputPurchaseLineErr);

        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        for OutputIndex := 1 to 2 do begin
            PurchaseLineComp[OutputIndex].SetRange("Document Type", PurchaseLineComp[OutputIndex]."Document Type"::Order);
            PurchaseLineComp[OutputIndex].SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
            PurchaseLineComp[OutputIndex].SetRange("Subc. Prod. Order Line No.", ProdOrderLine[OutputIndex]."Line No.");
            PurchaseLineComp[OutputIndex].SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
            PurchaseLineComp[OutputIndex].SetRange("Subc. Prod. Comp. Line No.", ProdOrderComponent[OutputIndex]."Line No.");
            PurchaseLineComp[OutputIndex].SetRange("No.", ProdOrderComponent[OutputIndex]."Item No.");
            Assert.IsTrue(PurchaseLineComp[OutputIndex].FindFirst(), FamilyOutputPurchaseLineErr);
            OriginalPurchaseQuantity[OutputIndex] := PurchaseLineComp[OutputIndex].Quantity;
            OriginalPurchaseDueDate[OutputIndex] := PurchaseLineComp[OutputIndex]."Expected Receipt Date";
            Assert.AreEqual(
                PurchaseLineComp[OutputIndex]."Outstanding Qty. (Base)",
                SubcCompFactboxMgmt.GetPurchOrderOutstandingQtyBaseFromProdOrderComp(ProdOrderComponent[OutputIndex]),
                FamilyComponentOutstandingQuantityErr);
        end;
        Assert.AreEqual(
            PurchaseLineComp[1]."Document No.",
            PurchaseLineComp[2]."Document No.",
            AmbiguousFamilyPurchaseOrderErr);

        // Simulate legacy purchase lines that only stored the shared routing reference.
        for OutputIndex := 1 to 2 do begin
            PurchaseLineComp[OutputIndex]."Subc. Prod. Order Line No." := ProdOrderRoutingLine."Routing Reference No.";
            PurchaseLineComp[OutputIndex]."Subc. Prod. Comp. Line No." := 0;
            PurchaseLineComp[OutputIndex].Modify();
        end;

        // Reschedule the second output first, where a routing-reference match cannot identify its purchase line.
        ProdOrderLine[2].Validate(Quantity, InitialQuantity + 1);
        ProdOrderLine[2].Modify(true);
        ProdOrderComponent[2].FindFirst();
        NewComponentQuantity := ProdOrderComponent[2]."Remaining Quantity" + 3;
        NewComponentDueDate := CalcDate('<30D>', WorkDate());
        ProdOrderComponent[2]."Remaining Quantity" := NewComponentQuantity;
        ProdOrderComponent[2]."Due Date" := NewComponentDueDate;
        ProdOrderComponent[2].Modify();

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        RequisitionLine.SetRange("Prod. Order Line No.", ProdOrderLine[2]."Line No.");
        Assert.IsTrue(RequisitionLine.FindFirst(), FamilyOutputPurchaseLineErr);
        Assert.IsTrue(
            RequisitionLine."Action Message" in
                [RequisitionLine."Action Message"::"Change Qty.",
                 RequisitionLine."Action Message"::"Resched. & Chg. Qty."],
            FamilyOutputRescheduleActionErr);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        for OutputIndex := 1 to 2 do begin
            PurchaseLineComp[OutputIndex].Get(
                PurchaseLineComp[OutputIndex]."Document Type",
                PurchaseLineComp[OutputIndex]."Document No.",
                PurchaseLineComp[OutputIndex]."Line No.");
            Assert.AreEqual(
                OriginalPurchaseQuantity[OutputIndex],
                PurchaseLineComp[OutputIndex].Quantity,
                AmbiguousLegacyPurchaseLineQuantityErr);
            Assert.AreEqual(
                OriginalPurchaseDueDate[OutputIndex],
                PurchaseLineComp[OutputIndex]."Expected Receipt Date",
                AmbiguousLegacyPurchaseLineDateErr);
            Assert.AreEqual(
                ProdOrderRoutingLine."Routing Reference No.",
                PurchaseLineComp[OutputIndex]."Subc. Prod. Order Line No.",
                AmbiguousLegacyPurchaseLineIdentityErr);
            Assert.AreEqual(0, PurchaseLineComp[OutputIndex]."Subc. Prod. Comp. Line No.", AmbiguousLegacyPurchaseLineIdentityErr);
        end;
    end;

    local procedure AssertVendorSuppliedComponentPurchaseDates(ProdOrderComponent: Record "Prod. Order Component"; PurchaseLine: Record "Purchase Line"; Location: Record Location; Vendor: Record Vendor; BaseCalendar: Record "Base Calendar"; ExpectedLeadTime: Text[30])
    var
        CustomizedCalendarChange: array[2] of Record "Customized Calendar Change";
        CalendarManagement: Codeunit "Calendar Management";
        ExpectedPlannedReceiptDate: Date;
        ExpectedOrderDate: Date;
        ExpectedDateFormula: DateFormula;
        SafetyLeadTimeAssertMsg: Label 'The component purchase line must use the explicit safety lead time.';
        InboundHandlingTimeAssertMsg: Label 'The component purchase line must use the location inbound handling time.';
        LeadTimeAssertMsg: Label 'Purchase lead time must follow Item Vendor, SKU, Item, then Vendor precedence.';
        PlannedReceiptDateAssertMsg: Label 'Planned receipt date must include exactly three days safety lead time and two days inbound handling time with the location calendar.';
        OrderDateAssertMsg: Label 'Order date must use the expected purchase lead time and respect the vendor and location calendars.';
    begin
        Evaluate(ExpectedDateFormula, '<3D>');
        Assert.AreEqual(ExpectedDateFormula, PurchaseLine."Safety Lead Time", SafetyLeadTimeAssertMsg);
        Evaluate(ExpectedDateFormula, '<2D>');
        Assert.AreEqual(ExpectedDateFormula, PurchaseLine."Inbound Whse. Handling Time", InboundHandlingTimeAssertMsg);
        Evaluate(ExpectedDateFormula, ExpectedLeadTime);
        Assert.AreEqual(ExpectedDateFormula, PurchaseLine."Lead Time Calculation", LeadTimeAssertMsg);
        CustomizedCalendarChange[1].SetSource(
            CustomizedCalendarChange[1]."Source Type"::Location, Location.Code, '', BaseCalendar.Code);
        ExpectedPlannedReceiptDate :=
            CalendarManagement.CalcDateBOC2('<5D>', ProdOrderComponent."Due Date", CustomizedCalendarChange, false);
        CustomizedCalendarChange[1].SetSource(
            CustomizedCalendarChange[1]."Source Type"::Vendor, Vendor."No.", '', BaseCalendar.Code);
        CustomizedCalendarChange[2].SetSource(
            CustomizedCalendarChange[2]."Source Type"::Location, Location.Code, '', BaseCalendar.Code);

        Assert.AreEqual(
            ExpectedPlannedReceiptDate, PurchaseLine."Planned Receipt Date",
            PlannedReceiptDateAssertMsg);
        ExpectedOrderDate :=
            CalendarManagement.CalcDateBOC2(ExpectedLeadTime, ExpectedPlannedReceiptDate, CustomizedCalendarChange, true);
        Assert.AreEqual(
            ExpectedOrderDate,
            PurchaseLine."Order Date",
            OrderDateAssertMsg);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Planning Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Planning Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Planning Test");
    end;

    local procedure CreateCertifiedRoutingVersionWithTransferWIPItem(RoutingNo: Code[20]; WorkCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingVersion: Record "Routing Version";
        SourceRoutingLine: Record "Routing Line";
        VersionRoutingLine: Record "Routing Line";
        VersionCode: Code[20];
    begin
        VersionCode := 'V1';
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingNo, VersionCode);

        SourceRoutingLine.SetRange("Routing No.", RoutingNo);
        SourceRoutingLine.SetRange("Version Code", '');
        SourceRoutingLine.FindSet();
        repeat
            VersionRoutingLine.Init();
            VersionRoutingLine.TransferFields(SourceRoutingLine, true);
            VersionRoutingLine."Version Code" := RoutingVersion."Version Code";
            VersionRoutingLine.Insert(true);
        until SourceRoutingLine.Next() = 0;

        SetTransferWIPItemOnRoutingLine(RoutingNo, RoutingVersion."Version Code", WorkCenterNo, RoutingLine);
        RoutingVersion.Validate("Starting Date", WorkDate());
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
    end;

    local procedure SetTransferWIPItemOnBaseRoutingLine(RoutingNo: Code[20]; WorkCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        SetTransferWIPItemOnRoutingLine(RoutingNo, '', WorkCenterNo, RoutingLine);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure SetTransferWIPItemOnRoutingLine(RoutingNo: Code[20]; VersionCode: Code[20]; WorkCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", VersionCode);
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine.Validate("Transfer WIP Item", true);
        RoutingLine.Validate("Transfer Description", 'WIP transfer description');
        RoutingLine.Validate("Transfer Description 2", 'WIP transfer description 2');
        RoutingLine.Modify(true);
    end;

    local procedure CreateAndRefreshPlanningLine(Item: Record Item; var Location: Record Location; var RequisitionWkshName: Record "Requisition Wksh. Name"; var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplateName: Code[10];
        Direction: Option Forward,Backward;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ReqWkshTemplateName := LibraryPlanning.SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplateName, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10) + 5);
        RequisitionLine.Validate("Location Code", Location.Code);
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Modify(true);

        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);
        RequisitionLine.Find();
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line"; WorkCenterNo: Code[20])
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.SetRange(Type, PlanningRoutingLine.Type::"Work Center");
        PlanningRoutingLine.SetRange("No.", WorkCenterNo);
        PlanningRoutingLine.FindFirst();
    end;

    local procedure CarryOutPlanningLine(var RequisitionLine: Record "Requisition Line")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        if not ManufacturingUserTemplate.Get(CopyStr(UserId(), 1, 50)) then
            LibraryPlanning.CreateManufUserTemplate(
                ManufacturingUserTemplate, CopyStr(UserId(), 1, 50),
                ManufacturingUserTemplate."Make Orders"::"All Lines",
                ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
                ManufacturingUserTemplate."Create Production Order"::"Firm Planned",
                ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");

        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Firm Planned Order Nos."));
        RequisitionLine.SetRecFilter();
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemNo: Code[20]; WorkCenterNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.FindFirst();

        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.SetRange("No.", WorkCenterNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure VerifyTransferWIPItemFields(TransferWIPItem: Boolean; TransferDescription: Text[100]; TransferDescription2: Text[50])
    begin
        Assert.IsTrue(TransferWIPItem, 'Transfer WIP Item should be enabled.');
        Assert.AreEqual('WIP transfer description', TransferDescription, 'Transfer Description should be retained.');
        Assert.AreEqual('WIP transfer description 2', TransferDescription2, 'Transfer Description 2 should be retained.');
    end;

    [ModalPageHandler]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        UnitCostCalculation: Option Time,Units;
}
