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
        ManufacturingUserTemplate: Record "Manufacturing User Template";
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
        if not ManufacturingUserTemplate.Get(CopyStr(UserId(), 1, 50)) then
            LibraryPlanning.CreateManufUserTemplate(
                ManufacturingUserTemplate, CopyStr(UserId(), 1, 50),
                ManufacturingUserTemplate."Make Orders"::"All Lines",
                ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
                ManufacturingUserTemplate."Create Production Order"::"Firm Planned",
                ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);

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
    procedure VendorSuppliedCompQtyUpdatedOnPurchOrderReschedule()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        InitialQty: Decimal;
        NewQty: Decimal;
    begin
        // [SCENARIO 637496] When a production order quantity changes and the subcontracting purchase order
        // is rescheduled via the requisition worksheet, the Vendor-Supplied component purchase lines
        // should be updated to reflect the new quantity.

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
        Assert.IsTrue(PurchaseLineComp.FindFirst(), 'Vendor-Supplied component purchase line should exist after initial PO creation.');

        // [WHEN] The production order quantity is increased and refreshed
        NewQty := InitialQty + LibraryRandom.RandIntInRange(3, 7);
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, NewQty);
        ProdOrderLine.Modify(true);

        // [WHEN] CalculateSubcontracts is run again and carried out (reschedule path)
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);

        Assert.IsTrue(
            RequisitionLine."Action Message" in
                [RequisitionLine."Action Message"::"Change Qty.",
                 RequisitionLine."Action Message"::"Resched. & Chg. Qty."],
            'Requisition line should have a Change Qty or Reschedule action message.');

        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        // [THEN] The component purchase line quantity matches the updated component remaining quantity
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProdOrderComponent.FindFirst();

        PurchaseLineComp.FindFirst();
        Assert.AreEqual(
            ProdOrderComponent."Remaining Quantity",
            PurchaseLineComp.Quantity,
            'Vendor-Supplied component purchase line quantity should match the updated production order component remaining quantity.');
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

    [ModalPageHandler]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        UnitCostCalculation: Option Time,Units;
}
