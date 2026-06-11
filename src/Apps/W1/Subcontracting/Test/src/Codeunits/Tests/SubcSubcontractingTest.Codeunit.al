// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Planning;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
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
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

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
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

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

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

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
    [Scope('OnPrem')]
    procedure DeleteWorkCenterWithPricesDeletesRelatedPrices()
    var
        Item: Record Item;
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
        WorkCenterNo: Code[20];
    begin
        // [SCENARIO 620643] Deleting a Work Center deletes all associated Subcontractor Prices

        // [GIVEN] A work center with a subcontractor and multiple Subcontractor Prices
        Initialize();
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);
        LibraryInventory.CreateItem(Item);
        WorkCenterNo := WorkCenter."No.";
        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrice, WorkCenterNo, WorkCenter."Subcontractor No.", Item."No.", '', '', WorkDate(), '', 0, '');
        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrice, WorkCenterNo, WorkCenter."Subcontractor No.", Item."No.", '', '', WorkDate(), '', 10, '');

        // [WHEN] The work center is deleted
        WorkCenter.Delete(true);

        // [THEN] All Subcontractor Prices for the work center are deleted
        SubcontractorPrice.SetRange("Work Center No.", WorkCenterNo);
        Assert.IsTrue(SubcontractorPrice.IsEmpty(), 'Subcontractor prices must be deleted when work center is deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemWithPricesDeletesRelatedPrices()
    var
        Item: Record Item;
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
        ItemNo: Code[20];
    begin
        // [SCENARIO 620643] Deleting an Item deletes all associated Subcontractor Prices

        // [GIVEN] An item with multiple Subcontractor Prices
        Initialize();
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrice, WorkCenter."No.", WorkCenter."Subcontractor No.", ItemNo, '', '', WorkDate(), '', 0, '');
        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrice, WorkCenter."No.", WorkCenter."Subcontractor No.", ItemNo, '', '', WorkDate(), '', 10, '');

        // [WHEN] The item is deleted
        Item.Delete(true);

        // [THEN] All Subcontractor Prices for the item are deleted
        SubcontractorPrice.SetRange("Item No.", ItemNo);
        Assert.IsTrue(SubcontractorPrice.IsEmpty(), 'Subcontractor prices must be deleted when item is deleted');
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
    procedure TestTransferComponentSupplyMethodAndVendorLocationIntoPlanningComponent()
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
        SubcontractingMgmtLibrary.SetupInventorySetup();

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
        Assert.Equal(ProductionBOMLine."Component Supply Method", PlanningComponent."Component Supply Method");
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Assert.Equal(Vendor."Subc. Location Code", PlanningComponent."Location Code");
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
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM (2 component items)
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] Assign Routing Link Code between subcontracting routing line and last BOM line
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

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
        UpdateProdOrderComponentWithComponentSupplyMethod(ProductionOrder, "Component Supply Method"::Empty);
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [THEN] Requisition line is suggested for the component with None component supply method
        RequisitionLine.SetRange("No.", ComponentItem."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);
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
        EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

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
        EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
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
        EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
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
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

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

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

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

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrderPage: TestPage "Purchase Order")
    begin
        PurchaseOrderPageOpened := true;
        PurchaseOrderPage.Close();
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
            Question.Contains('Do you want to create a production order from'):
                Reply := true;
            else
                Reply := false;
        end;
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

    procedure UpdateProdOrderComponentWithComponentSupplyMethod(ProductionOrder: Record "Production Order"; ComponentSupplyMethod: Enum "Component Supply Method")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComp.ModifyAll("Component Supply Method", ComponentSupplyMethod);
    end;

    var
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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        PurchaseOrderPageOpened: Boolean;
        UnitCostCalculation: Option Time,Units;
        ConfirmDialogCalledCount: Integer;

}
