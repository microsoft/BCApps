// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
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
    var
        Item: Record Item;
        ComponentItem: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        SecondProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        LeadTimeCalculation: DateFormula;
        SafetyLeadTimeCalculation: DateFormula;
        ComponentDueDate: array[2] of Date;
        InitialQty: Decimal;
        NewQty: Decimal;
        ComponentIndex: Integer;
    begin
        // [SCENARIO 650504] When a subcontracting purchase order is rescheduled, duplicate Vendor-Supplied
        // components are matched one-to-one and use their own quantities and requirement dates.

        // [GIVEN] A subcontracting setup with two Vendor-Supplied components for the same item and operation
        Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindLast();
        ComponentItem.Get(ProductionBOMLine."No.");

        // [GIVEN] A released production order
        InitialQty := LibraryRandom.RandIntInRange(5, 10);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", InitialQty);
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComponent.FindFirst();
        LibraryManufacturing.CreateProductionOrderComponent(
            SecondProdOrderComponent, ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        SecondProdOrderComponent.Validate("Item No.", ProdOrderComponent."Item No.");
        SecondProdOrderComponent.Validate("Quantity per", 2);
        SecondProdOrderComponent.Validate("Routing Link Code", ProdOrderComponent."Routing Link Code");
        SecondProdOrderComponent.Validate("Component Supply Method", ProdOrderComponent."Component Supply Method");
        SecondProdOrderComponent.Modify(true);

        // [GIVEN] A subcontracting purchase order created via the requisition worksheet
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        // [GIVEN] The vendor-supplied component purchase line exists
        SubcontractingMgmtLibrary.FindSubcPurchLineForProdOrder(PurchaseLine, Item."No.", ProductionOrder."No.");
        SubcontractingMgmtLibrary.FindComponentPurchLine(PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        Assert.IsTrue(PurchaseLineComp.FindFirst(), 'Vendor-Supplied component purchase line should exist after initial PO creation.');
        Assert.AreEqual(2, PurchaseLineComp.Count(), 'Two Vendor-Supplied component purchase lines should exist for the duplicate component item.');
        Evaluate(LeadTimeCalculation, '<2D>');
        Evaluate(SafetyLeadTimeCalculation, '<0D>');
        if PurchaseLineComp.FindSet(true) then
            repeat
                PurchaseLineComp.Validate("Lead Time Calculation", LeadTimeCalculation);
                PurchaseLineComp.Validate("Safety Lead Time", SafetyLeadTimeCalculation);
                PurchaseLineComp.Modify(true);
            until PurchaseLineComp.Next() = 0;

        // [WHEN] The production order quantity and the two component due dates are changed
        NewQty := InitialQty + LibraryRandom.RandIntInRange(3, 7);
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, NewQty);
        ProdOrderLine.Modify(true);

        ComponentDueDate[1] := DMY2Date(7, 10, 2026);
        ComponentDueDate[2] := DMY2Date(9, 10, 2026);
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ComponentIndex := 1;
        if ProdOrderComponent.FindSet(true) then
            repeat
                ProdOrderComponent.Validate("Due Date", ComponentDueDate[ComponentIndex]);
                ProdOrderComponent.Modify(true);
                ComponentIndex += 1;
            until ProdOrderComponent.Next() = 0;

        // [WHEN] CalculateSubcontracts is run again and carried out (reschedule path)
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);

        Assert.IsTrue(
            RequisitionLine."Action Message" in
                [RequisitionLine."Action Message"::"Change Qty.",
                 RequisitionLine."Action Message"::"Resched. & Chg. Qty."],
            'Requisition line should have a Change Qty or Reschedule action message.');

        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        // [THEN] Each purchase line matches one component and has exact backward-scheduled dates
        ProdOrderComponent.FindSet();
        PurchaseLineComp.FindSet();
        Assert.AreEqual(
            ProdOrderComponent.Count(), PurchaseLineComp.Count(),
            'Each Vendor-Supplied component must have one purchase line after rescheduling.');
        repeat
            PurchaseLineComp.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
            PurchaseLineComp.TestField("Expected Receipt Date", ProdOrderComponent."Due Date");
            PurchaseLineComp.TestField("Planned Receipt Date", ProdOrderComponent."Due Date");
            PurchaseLineComp.TestField("Order Date", CalcDate('<-2D>', ProdOrderComponent."Due Date"));
            PurchaseLineComp.Next();
        until ProdOrderComponent.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ComponentPurchLineMismatchNotificationHandler')]
    procedure MissingVendorSuppliedComponentPurchaseLineDoesNotAbortCarryOut()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // [SCENARIO 650504] A missing Vendor-Supplied component purchase line does not abort the worksheet batch.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        PurchaseLineComp.FindFirst();
        PurchaseLineComp.Delete(true);
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Reset();
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        Assert.RecordIsNotEmpty(PurchaseLineComp);
    end;

    [Test]
    [HandlerFunctions('ComponentPurchLineMismatchNotificationHandler')]
    procedure RemainingVendorSuppliedComponentUpdatesItsOwnPurchaseLine()
    var
        ComponentItem: Record Item;
        FirstProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SecondPurchaseLine: Record "Purchase Line";
        SecondProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO 650504] Component rescheduling uses stable component identity after another component is removed.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);

        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComponent.FindSet();
        FirstProdOrderComponent := ProdOrderComponent;
        ProdOrderComponent.Next();
        SecondProdOrderComponent := ProdOrderComponent;

        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        PurchaseLineComp.FindSet();
        PurchaseLineComp.Next();
        SecondPurchaseLine := PurchaseLineComp;

        FirstProdOrderComponent.Delete(true);
        SecondProdOrderComponent.Validate("Quantity per", SecondProdOrderComponent."Quantity per" + 1);
        SecondProdOrderComponent.Validate("Due Date", DMY2Date(15, 10, 2026));
        SecondProdOrderComponent.Modify(true);
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        SecondProdOrderComponent.Get(
            SecondProdOrderComponent.Status, SecondProdOrderComponent."Prod. Order No.",
            SecondProdOrderComponent."Prod. Order Line No.", SecondProdOrderComponent."Line No.");
        SecondPurchaseLine.Get(
            SecondPurchaseLine."Document Type", SecondPurchaseLine."Document No.", SecondPurchaseLine."Line No.");
        SecondPurchaseLine.TestField(Quantity, SecondProdOrderComponent."Remaining Quantity");
        SecondPurchaseLine.TestField("Expected Receipt Date", SecondProdOrderComponent."Due Date");
    end;

    [Test]
    procedure ChangeQuantityPreservesManuallyAdjustedComponentDates()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ManuallyAdjustedDate: Date;
    begin
        // [SCENARIO 650504] A quantity-only action preserves manually adjusted component purchase dates.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        PurchaseLineComp.FindFirst();
        ManuallyAdjustedDate := DMY2Date(20, 10, 2026);
        PurchaseLineComp.Validate("Expected Receipt Date", ManuallyAdjustedDate);
        PurchaseLineComp.Modify(true);
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::"Change Qty.");
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("Expected Receipt Date", ManuallyAdjustedDate);
    end;

    [Test]
    [HandlerFunctions('ComponentPurchLineMismatchNotificationHandler')]
    procedure AmbiguousLegacyComponentPurchaseLinesAreNotAssigned()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // [SCENARIO 650504] Ambiguous legacy component lines are not assigned a persisted component identity.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        PurchaseLineComp.FindSet(true);
        repeat
            ClearComponentPurchaseLineIdentity(PurchaseLineComp);
        until PurchaseLineComp.Next() = 0;
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.FindSet();
        repeat
            PurchaseLineComp.TestField("Subc. Prod. Order Line No.", 0);
            PurchaseLineComp.TestField("Subc. Prod. Ord. Comp Line No.", 0);
        until PurchaseLineComp.Next() = 0;
    end;

    [Test]
    procedure LegacyQuantityChangePreservesManuallyAdjustedComponentDates()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RemovedProdOrderComponent: Record "Prod. Order Component";
        RemovedPurchaseLine: Record "Purchase Line";
        ManuallyAdjustedDate: Date;
    begin
        // [SCENARIO 650504] A unique legacy match initializes source tracking without overwriting manual dates.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        FindDuplicateComponentsAndPurchaseLines(
            ProductionOrder, ComponentItem, PurchaseLine."Document No.",
            ProdOrderComponent, PurchaseLineComp, RemovedProdOrderComponent, RemovedPurchaseLine);
        RemovedProdOrderComponent.Delete(true);
        RemovedPurchaseLine.Delete(true);
        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        ClearComponentPurchaseLineIdentity(PurchaseLineComp);
        ManuallyAdjustedDate := DMY2Date(20, 10, 2026);
        PurchaseLineComp.Validate("Expected Receipt Date", ManuallyAdjustedDate);
        PurchaseLineComp.Modify(true);
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::"Change Qty.");
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("Subc. Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        PurchaseLineComp.TestField("Subc. Prod. Ord. Comp Line No.", ProdOrderComponent."Line No.");
        PurchaseLineComp.TestField("Subc. Prod. Ord. Comp Due Date", ProdOrderComponent."Due Date");
        PurchaseLineComp.TestField("Expected Receipt Date", ManuallyAdjustedDate);
    end;

    [Test]
    [HandlerFunctions('SiblingProductionOrderLineNotificationHandler')]
    procedure SiblingProductionOrderLineIsNotReportedAsOrphan()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SiblingProdOrderComponent: Record "Prod. Order Component";
        SiblingPurchaseLine: Record "Purchase Line";
        ProbeNotification: Notification;
    begin
        // [SCENARIO 650504] A purchase line for a sibling production-order line is outside the orphan count.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        FindDuplicateComponentsAndPurchaseLines(
            ProductionOrder, ComponentItem, PurchaseLine."Document No.",
            ProdOrderComponent, PurchaseLineComp, SiblingProdOrderComponent, SiblingPurchaseLine);
        SiblingProdOrderComponent.Delete(true);
        SiblingPurchaseLine."Subc. Prod. Order Line No." := ProdOrderComponent."Prod. Order Line No." + 10000;
        SiblingPurchaseLine.Modify(true);
        ChangeProductionOrderQuantity(ProductionOrder);
        SiblingProductionOrderLineNotificationRaised := false;

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);
        ProbeNotification.Message := 'Sibling production-order-line notification probe.';
        ProbeNotification.Send();

        Assert.IsFalse(
            SiblingProductionOrderLineNotificationRaised,
            'A component purchase line for a sibling production-order line must not be reported as an orphan.');
        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
    end;

    [Test]
    procedure ExactComponentIdentityWithDifferentItemDoesNotUpdatePurchaseLine()
    var
        ComponentItem: Record Item;
        NewComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SecondProdOrderComponent: Record "Prod. Order Component";
        SecondPurchaseLine: Record "Purchase Line";
        OriginalPurchaseQuantity: Decimal;
    begin
        // [SCENARIO 650504] Stable component identity does not update a purchase line for a replaced item.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        FindDuplicateComponentsAndPurchaseLines(
            ProductionOrder, ComponentItem, PurchaseLine."Document No.",
            ProdOrderComponent, PurchaseLineComp, SecondProdOrderComponent, SecondPurchaseLine);
        OriginalPurchaseQuantity := PurchaseLineComp.Quantity;
        LibraryInventory.CreateItem(NewComponentItem);
        ProdOrderComponent.Validate("Item No.", NewComponentItem."No.");
        ProdOrderComponent.Validate("Quantity per", ProdOrderComponent."Quantity per" + 1);
        ProdOrderComponent.Modify(true);
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("No.", ComponentItem."No.");
        PurchaseLineComp.TestField(Quantity, OriginalPurchaseQuantity);
    end;

    [Test]
    procedure ExactComponentIdentityWithDifferentVariantDoesNotUpdatePurchaseLine()
    var
        ComponentItem: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SecondProdOrderComponent: Record "Prod. Order Component";
        SecondPurchaseLine: Record "Purchase Line";
        OriginalPurchaseQuantity: Decimal;
    begin
        // [SCENARIO 650504] Stable component identity does not update a purchase line for a replaced variant.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        FindDuplicateComponentsAndPurchaseLines(
            ProductionOrder, ComponentItem, PurchaseLine."Document No.",
            ProdOrderComponent, PurchaseLineComp, SecondProdOrderComponent, SecondPurchaseLine);
        OriginalPurchaseQuantity := PurchaseLineComp.Quantity;
        LibraryInventory.CreateItemVariant(ItemVariant, ComponentItem."No.");
        ProdOrderComponent.Validate("Variant Code", ItemVariant.Code);
        ProdOrderComponent.Validate("Quantity per", ProdOrderComponent."Quantity per" + 1);
        ProdOrderComponent.Modify(true);
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("Variant Code", '');
        PurchaseLineComp.TestField(Quantity, OriginalPurchaseQuantity);
    end;

    [Test]
    [HandlerFunctions('ComponentPurchLineMismatchNotificationHandler')]
    procedure OneLegacyPurchaseLineForTwoComponentsIsNotAssigned()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RemovedPurchaseLine: Record "Purchase Line";
        SecondProdOrderComponent: Record "Prod. Order Component";
        OriginalPurchaseQuantity: Decimal;
    begin
        // [SCENARIO 650504] A legacy line is not assigned when two source components can claim it.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        FindDuplicateComponentsAndPurchaseLines(
            ProductionOrder, ComponentItem, PurchaseLine."Document No.",
            ProdOrderComponent, RemovedPurchaseLine, SecondProdOrderComponent, PurchaseLineComp);
        RemovedPurchaseLine.Delete(true);
        ClearComponentPurchaseLineIdentity(PurchaseLineComp);
        OriginalPurchaseQuantity := PurchaseLineComp.Quantity;
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("Subc. Prod. Order Line No.", 0);
        PurchaseLineComp.TestField("Subc. Prod. Ord. Comp Line No.", 0);
        PurchaseLineComp.TestField(Quantity, OriginalPurchaseQuantity);
    end;

    [Test]
    [HandlerFunctions('ComponentPurchLineMismatchNotificationHandler')]
    procedure OneLegacyPurchaseLineForComponentsAcrossOutputsIsNotAssigned()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RemovedPurchaseLine: Record "Purchase Line";
        SiblingProdOrderComponent: Record "Prod. Order Component";
        OriginalPurchaseQuantity: Decimal;
        SiblingProdOrderLineNo: Integer;
    begin
        // [SCENARIO 650504] A legacy line is not assigned when compatible source components exist on different production-order outputs.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        FindDuplicateComponentsAndPurchaseLines(
            ProductionOrder, ComponentItem, PurchaseLine."Document No.",
            ProdOrderComponent, RemovedPurchaseLine, SiblingProdOrderComponent, PurchaseLineComp);
        SiblingProdOrderLineNo := ProdOrderComponent."Prod. Order Line No." + 10000;
        SiblingProdOrderComponent.Rename(
            SiblingProdOrderComponent.Status, SiblingProdOrderComponent."Prod. Order No.",
            SiblingProdOrderLineNo, SiblingProdOrderComponent."Line No.");
        RemovedPurchaseLine.Delete(true);
        ClearComponentPurchaseLineIdentity(PurchaseLineComp);
        OriginalPurchaseQuantity := PurchaseLineComp.Quantity;
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("Subc. Prod. Order Line No.", 0);
        PurchaseLineComp.TestField("Subc. Prod. Ord. Comp Line No.", 0);
        PurchaseLineComp.TestField(Quantity, OriginalPurchaseQuantity);
    end;

    [Test]
    procedure FirstLegacyRescheduleAppliesComponentDueDate()
    var
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RemovedProdOrderComponent: Record "Prod. Order Component";
        RemovedPurchaseLine: Record "Purchase Line";
        NewComponentDueDate: Date;
    begin
        // [SCENARIO 650504] A legacy line's first reschedule applies and tracks the component due date.
        CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
            ProductionOrder, PurchaseLine, ComponentItem, RequisitionWkshName);
        FindDuplicateComponentsAndPurchaseLines(
            ProductionOrder, ComponentItem, PurchaseLine."Document No.",
            ProdOrderComponent, PurchaseLineComp, RemovedProdOrderComponent, RemovedPurchaseLine);
        RemovedProdOrderComponent.Delete(true);
        RemovedPurchaseLine.Delete(true);
        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        ClearComponentPurchaseLineIdentity(PurchaseLineComp);
        NewComponentDueDate := CalcDate('<10D>', ProdOrderComponent."Due Date");
        ProdOrderComponent.Validate("Due Date", NewComponentDueDate);
        ProdOrderComponent.Modify(true);
        PurchaseLine.Validate(
            "Expected Receipt Date", CalcDate('<20D>', PurchaseLine."Expected Receipt Date"));
        PurchaseLine.Modify(true);
        ChangeProductionOrderQuantity(ProductionOrder);

        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        RequisitionLine.TestField(
            "Action Message", RequisitionLine."Action Message"::"Resched. & Chg. Qty.");
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("Expected Receipt Date", NewComponentDueDate);
        PurchaseLineComp.TestField("Subc. Prod. Ord. Comp Due Date", NewComponentDueDate);

        ChangeProductionOrderQuantity(ProductionOrder);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::"Change Qty.");
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        PurchaseLineComp.Get(
            PurchaseLineComp."Document Type", PurchaseLineComp."Document No.", PurchaseLineComp."Line No.");
        PurchaseLineComp.TestField("Expected Receipt Date", NewComponentDueDate);
        PurchaseLineComp.TestField("Subc. Prod. Ord. Comp Due Date", NewComponentDueDate);
    end;

    local procedure ClearComponentPurchaseLineIdentity(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Subc. Prod. Order Line No." := 0;
        PurchaseLine."Subc. Prod. Ord. Comp Line No." := 0;
        PurchaseLine."Subc. Prod. Ord. Comp Due Date" := 0D;
        PurchaseLine.Modify(true);
    end;

    local procedure FindDuplicateComponentsAndPurchaseLines(
        ProductionOrder: Record "Production Order";
        ComponentItem: Record Item;
        PurchaseOrderNo: Code[20];
        var ProdOrderComponent: Record "Prod. Order Component";
        var PurchaseLine: Record "Purchase Line";
        var SecondProdOrderComponent: Record "Prod. Order Component";
        var SecondPurchaseLine: Record "Purchase Line")
    begin
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComponent.FindSet();
        ProdOrderComponent.Next();
        SecondProdOrderComponent := ProdOrderComponent;
        ProdOrderComponent.FindFirst();

        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLine, PurchaseOrderNo, ComponentItem."No.");
        PurchaseLine.SetRange("Subc. Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        PurchaseLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComponent."Line No.");
        PurchaseLine.FindFirst();
        SecondPurchaseLine.Reset();
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            SecondPurchaseLine, PurchaseOrderNo, ComponentItem."No.");
        SecondPurchaseLine.SetRange("Subc. Prod. Order Line No.", SecondProdOrderComponent."Prod. Order Line No.");
        SecondPurchaseLine.SetRange("Subc. Prod. Ord. Comp Line No.", SecondProdOrderComponent."Line No.");
        SecondPurchaseLine.FindFirst();
    end;

    local procedure CreateSubcontractingOrderWithDuplicateVendorSuppliedComponents(
        var ProductionOrder: Record "Production Order";
        var PurchaseLine: Record "Purchase Line";
        var ComponentItem: Record Item;
        var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLineComp: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        SecondProdOrderComponent: Record "Prod. Order Component";
        WorkCenter: array[2] of Record "Work Center";
    begin
        Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(
            WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(
            Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindLast();
        ComponentItem.Get(ProductionBOMLine."No.");
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));

        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComponent.FindFirst();
        LibraryManufacturing.CreateProductionOrderComponent(
            SecondProdOrderComponent, ProdOrderComponent.Status,
            ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        SecondProdOrderComponent.Validate("Item No.", ProdOrderComponent."Item No.");
        SecondProdOrderComponent.Validate("Quantity per", 2);
        SecondProdOrderComponent.Validate("Routing Link Code", ProdOrderComponent."Routing Link Code");
        SecondProdOrderComponent.Validate("Component Supply Method", ProdOrderComponent."Component Supply Method");
        SecondProdOrderComponent.Modify(true);

        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(
            RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);
        SubcontractingMgmtLibrary.FindSubcPurchLineForProdOrder(
            PurchaseLine, Item."No.", ProductionOrder."No.");
        SubcontractingMgmtLibrary.FindComponentPurchLine(
            PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        Assert.AreEqual(
            2, PurchaseLineComp.Count(),
            'Two Vendor-Supplied component purchase lines should exist for the duplicate component item.');
    end;

    local procedure ChangeProductionOrderQuantity(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, ProdOrderLine.Quantity + 1);
        ProdOrderLine.Modify(true);
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

    [SendNotificationHandler]
    procedure ComponentPurchLineMismatchNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(
            'Subcontracting component purchase-line synchronization skipped',
            Notification.Message);
    end;

    [SendNotificationHandler]
    procedure SiblingProductionOrderLineNotificationHandler(var Notification: Notification): Boolean
    begin
        if StrPos(
             Notification.Message,
             'Subcontracting component purchase-line synchronization skipped') > 0
        then
            SiblingProductionOrderLineNotificationRaised := true;
        exit(true);
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
        SiblingProductionOrderLineNotificationRaised: Boolean;
        Subcontracting: Boolean;
        UnitCostCalculation: Option Time,Units;
}
