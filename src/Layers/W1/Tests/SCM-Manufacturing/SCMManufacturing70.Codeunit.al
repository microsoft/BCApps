// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Setup;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Journal;
using System.TestLibraries.Utilities;
using Microsoft.Foundation.NoSeries;
using Microsoft.Manufacturing.Routing;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Planning;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Manufacturing.Family;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Setup;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Manufacturing.Journal;
using System.Utilities;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Posting;

codeunit 137063 "SCM Manufacturing 7.0"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [SCM]
        Initialized := false;
    end;

    var
        InventorySetup: Record "Inventory Setup";
        LocationBlue: Record Location;
        LocationGreen: Record Location;
        LocationInTransit: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        CapacityItemJournalTemplate: Record "Item Journal Template";
        CapacityItemJournalBatch: Record "Item Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        ErrorDoNotMatchErr: Label 'Expected error: ''%1''\Actual error: ''%2''', Locked = true;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        DimensionErr: Label 'The %1 must be %2 for %3 %4 for %5 %6. Currently it''s %7.', Comment = '%1 = "Dimension value code" caption, %2 = expected "Dimension value code" value, %3 = "Dimension code" caption, %4 = "Dimension Code" value, %5 = Table caption (Vendor), %6 = Table value (XYZ), %7 = current "Dimension value code" value', Locked = true;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Initialized: Boolean;
        PlanningLinesErr: Label 'Wrong number of Planning Lines.';
        ReservationEntriesErr: Label 'Wrong number of Reservation Entries.';
        UntrackedPlanningElementsErr: Label 'Wrong number of untracked planning elements.';
        ReorderPointTxt: Label 'Reorder Point';
        ReorderQuantityTxt: Label 'Reorder Quantity';
        LowLevelCodeQst: Label 'Calculate low-level code';
        RoutingStatusQst: Label 'then all related allocated capacity will be deleted';
        NumberOfLineErr: Label 'Number of line must be same.';
        StatusTxt: Label 'Status must be';
        CertifiedTxt: Label 'Certified';
        NoDimensionExpectedErr: Label 'No of dimensions expected.';
        DimensionValueErr: Label 'Dimension Value Code must be same.';
        ReleasedProdOrderTxt: Label 'Released Prod. Order';
        ItemJournalLineErr: Label 'Wrong number of Item Journal Lines.';
        EffectiveCapacityErr: Label 'Effective Capacity must be match with Needed Time.';
        ErrorMsg: Label 'No. of records are not equal in %1 and %2.', Locked = true;
        ItemTracking: Option "None",AssignSerial,SelectSerial,VerifyValue;
        TrackingOption: Option AssignLotNo,SelectEntries;
        TrackingQuantity: Decimal;
        StartingDateTimeErr: Label 'Starting Date Time must be greater or equal';
        FinishedStatusQst: Label '\\  * Some consumption is still missing.\\ Do you still want to finish the order?';
        ModifyRtngErr: Label 'You cannot modify Routing No. %1 because there is at least one %2 associated with it.', Locked = true;
        DeleteRtngErr: Label 'You cannot delete Prod. Order Line %1 because there is at least one %2 associated with it.', Locked = true;
        ExpectedReceiptDateErr: Label 'The change leads to a date conflict with existing reservations.';
        WrongDueDateErr: Label 'Wrong Due Date.';
        DimensionValueOutputErr: Label 'Dimension Value should be %1 in Output Journal Line', Locked = true;
        FieldErr: Label 'Wrong %1 in %2', Locked = true;
        IncorrectQtyOnEndingDateErr: Label 'Incorrect Quantity planned for given Ending Date.';
        WrongVersionCodeErr: Label 'Wrong version code.';
        ItemPlannedForExactDemandTxt: Label 'The item is planned to cover the exact demand.';
        SubcontractingDescriptionErr: Label 'The description in Subcontracting Worksheet must be from Work Center if available.';
        ProductionStatusErr: Label 'Selected Production Order must be released.';
        QuanityPerErrorLbl: Label '%1 must be %2 in %3', Comment = '%1 = "Quantity Per", %2 = Expected Value, %3 = Table Caption';
        OperationNoErr: Label 'Operation No. must be equal to %1', Comment = '%1 = Operation No.';

    [Test]
    [Scope('OnPrem')]
    procedure B7419_RefreshPlanningLine()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RequisitionLine: Record "Requisition Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Direction: Option Forward,Backward;
        QuantityPer: Integer;
    begin
        // Verify Planning Worksheet Routing No. after refreshing the Item on Requisition line and Run Refresh Planning Line.
        // Setup: Create Item Hierarchy and Routing setup.
        Initialize();
        QuantityPer := LibraryRandom.RandInt(10);
        CreateItemHierarchy(ProductionBOMHeader, ParentItem, ChildItem, QuantityPer);
        CreateAndCertifyRoutingSetup(RoutingHeader, RoutingLine);
        UpdateItem(ParentItem, ParentItem.FieldNo("Routing No."), RoutingHeader."No.");
        UpdateItem(ParentItem, ParentItem.FieldNo("Reordering Policy"), ParentItem."Reordering Policy"::"Lot-for-Lot");
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        UpdateRequisitionLine(RequisitionLine, ParentItem."No.");

        // Exercise: Refresh Planning Line.
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // Verify: Verify Planning Routing Line with Details.
        VerifyPlanningRoutingLine(RoutingHeader, RequisitionWkshName, ChildItem."No.", QuantityPer);

        // Exercise: Update Requisition Line and Refresh Planning Line.
        RequisitionLine.Get(RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, 10000);
        RequisitionLine.Validate("No.", ParentItem."No.");
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // Verify: Verify Planning Routing Line with Details.
        VerifyPlanningRoutingLine(RoutingHeader, RequisitionWkshName, ChildItem."No.", QuantityPer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure B7510_CalculateLowLevelCode()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        GrandProductionBOMHeader: Record "Production BOM Header";
        GrandParentItem: Record Item;
    begin
        // Verify Low level Code after changing status of Production BOM Version.
        // Setup: Create two level of Item Hierarchy.
        Initialize();
        CreateItemHierarchy(ProductionBOMHeader, ParentItem, ChildItem, LibraryRandom.RandInt(5));
        CreateItemHierarchy(GrandProductionBOMHeader, GrandParentItem, ParentItem, LibraryRandom.RandInt(5));
        LibraryVariableStorage.Enqueue(LowLevelCodeQst);  // Enqueue value for Confirm Handler.
        LibraryPlanning.CalculateLowLevelCode();

        // Exercise: Create Production BOM Version and change Status.
        CreateBOMVersionAndCertify(ProductionBOMHeader."No.", ParentItem."Base Unit of Measure");

        // Verify: Verify Low Level Code.
        VerifyBOMHeaderLLC(ProductionBOMHeader."No.", 2);  // Value is important for Test.

        // Exercise.
        LibraryVariableStorage.Enqueue(LowLevelCodeQst);  // Enqueue value for Confirm Handler.
        LibraryPlanning.CalculateLowLevelCode();

        // Verify: Verify Low Level Code.
        VerifyBOMHeaderLLC(ProductionBOMHeader."No.", 2);  // Value is important for Test.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure B7568_ChangeProdOrderRouting()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RunTime: Decimal;
        OperationNo: Code[10];
        OperationNo2: Code[10];
    begin
        // Routing is type parallel and first Operation is finished then verify to change or validate Run Time in Production Order Routing.
        // Setup: Create Routing with type Parallel and Production Order.
        Initialize();
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        CreateWorkCenterSetup(WorkCenter2, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        RunTime := 10 + LibraryRandom.RandDec(10, 2);
        OperationNo2 := Format(10 + LibraryRandom.RandInt(10));

        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Parallel, RoutingLine.Type::"Work Center");
        OperationNo := RoutingLine."Operation No.";
        RoutingLine.Validate("Next Operation No.", OperationNo2);
        UpdateRoutingLine(RoutingLine, 1, RunTime, 0);  // Setup Time value important.

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo2, RoutingLine.Type::"Work Center", WorkCenter2."No.");
        RoutingLine.Validate("Previous Operation No.", OperationNo);
        UpdateRoutingLine(RoutingLine, 1, RunTime, 0);  // Setup Time value important.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);
        LibraryVariableStorage.Enqueue(RoutingStatusQst);  // Enqueue value for Confirm Handler.

        // Exercise: Change the Routing Status of first operation to Finished.
        ModifyProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder, RoutingHeader."No.", OperationNo);

        // Verify: Verify that Run Time value can be changed in second Operation in Prod Order Routing Line.
        VerifyRunTime(OperationNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B7612_OutputJnlWithDimValue()
    var
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        WorkCenter: Record "Work Center";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        DimensionValue2: Record "Dimension Value";
    begin
        // Verify Posting an output journal with Dimension Value Posting, which has been set on the Work Center Card.
        // Setup: Create Routing Setup and Work Center with Dimension.
        Initialize();
        CreateAndCertifyRoutingSetup(RoutingHeader, RoutingLine);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");
        SelectWorkCenter(WorkCenter, RoutingHeader."No.");
        UpdateWorkCenterWithDimension(DimensionValue, DimensionValue2, WorkCenter."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);
        OutputJournalExplodeRouting(ProductionOrder);
        ChangeDimensionItemJournalLine(ItemJournalLine, WorkCenter."No.", DimensionValue2);
        UpdateItemJournalLine(ItemJournalLine, WorkCenter."No.");

        // Exercise: Post Item Journal.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Dimension Error Message.
        Assert.AreNotEqual(
          StrPos(GetLastErrorText, StrSubstNo(DimensionErr, DefaultDimension.FieldCaption("Dimension Value Code"), DimensionValue.Code, DimensionValue.FieldCaption("Dimension Code"), DimensionValue."Dimension Code", WorkCenter.TableCaption, WorkCenter."No.", DimensionValue2.Code)), 0,
          StrSubstNo(
            ErrorDoNotMatchErr, StrSubstNo(DimensionErr, DefaultDimension.FieldCaption("Dimension Value Code"), DimensionValue.Code, DimensionValue.FieldCaption("Dimension Code"), DimensionValue."Dimension Code", WorkCenter.TableCaption, WorkCenter."No.", DimensionValue2.Code),
            GetLastErrorText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B28000_UntrackedPlanning()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        ActualCount: Integer;
    begin
        // Test the Untracked Quantity in Untracked Planning Element after calculate Plan.
        // Setup.
        Initialize();
        RequisitionLine.DeleteAll(true);
        CreateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", false,
          10 + LibraryRandom.RandInt(10), 40 + LibraryRandom.RandInt(10), 0, '');

        // Exercise: Calculate Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Requisition line, Reservation Entry and Untracked Planning Element.
        VerifyRequisitionLine(Item);
        VerifyReservationEntry(Item);
        ActualCount := UntrackedPlanningElement.Count();
        Assert.AreEqual(2, ActualCount, UntrackedPlanningElementsErr);  // Value is important for Test.
        VerifyUntrackedPlanningElement(Item."No.", ReorderPointTxt, Item."Reorder Point", 0);  // Value is important for Test.
        VerifyUntrackedPlanningElement(Item."No.", ReorderQuantityTxt, Item."Reorder Quantity", Item."Reorder Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B29178_OrderComponentWithDim()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        // Verify Dimensions from Planning Component copied to Production Order Component.
        // Setup: Create Item with Dimensions, Production BOM and Sales Order.
        Initialize();
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::" ", false, 0, 0, 0, '');
        UpdateItemWithDimensions(ChildItem, DimensionValue, DimensionValue2);
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        CreateProductionBOMAndCertify(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.",
          LibraryRandom.RandInt(5));
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", '');

        // Exercise: Run Planning Worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // Verify: Verify Quantity and Dates in Requisition line.
        VerifyValueInRequisitionLine(ParentItem, SalesLine.Quantity, SalesHeader."Order Date");

        // Exercise: Run Carry Out Action Messages to create a Production Order.
        CarryOutActionMsgForItem(ParentItem."No.");

        // Verify: Verify Dimension in Production Order Component.
        VerifyProdOrderComponent(ParentItem."No.", ChildItem."No.", DimensionValue.Code, DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B31974_PlanningWithBlockedItem()
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
    begin
        // [SCENARIO 161274] Cannot add a blocked item to a prod order (modified existing test)
        // [GIVEN] Blocked Item
        Initialize();
        CreateItemHierarchy(ProductionBOMHeader, ParentItem, ChildItem, LibraryRandom.RandInt(5));
        UpdateItem(ChildItem, ChildItem.FieldNo(Blocked), true);

        // [WHEN] Creating a Prod Order with blocked item
        asserterror CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);

        // [THEN] Error expected because of blocked item
        Assert.ExpectedTestFieldError(ChildItem.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B37979_CalcPlanForReqWksh()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        LeadTimeCalc: DateFormula;
    begin
        // Verify the value after Calculating Plan - Requisition Worksheet.
        // Setup: Create Item and Purchase Order.
        Initialize();
        RequisitionLine.DeleteAll(true);
        CreateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Maximum Qty.", false,
          10 + LibraryRandom.RandInt(5), 0, 1000 + LibraryRandom.RandInt(10), '');
        Evaluate(LeadTimeCalc, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        UpdateItem(Item, Item.FieldNo("Lead Time Calculation"), LeadTimeCalc);
        UpdateItem(Item, Item.FieldNo("Manufacturing Policy"), Item."Manufacturing Policy"::"Make-to-Stock");
        UpdateItem(Item, Item.FieldNo("Order Multiple"), 100 + LibraryRandom.RandInt(5));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Order Date", CalcDate('<' + '-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Expected Receipt Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        PurchaseLine.Modify(true);

        // Exercise: Run Calculation Plan for Req Worksheet.
        CalculatePlanForReqWksh(Item, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // Verify: Verify Quantity and Dates in Requisition line.
        VerifyDateAndQuantityReqLine(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B42752_CalcPlanForParentItem()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TimeBucket: DateFormula;
        QuantityPer: Integer;
    begin
        // Verify Requisition Line and Planning Component after calculate plan using Parent Item.
        // Setup:
        Initialize();
        QuantityPer := LibraryRandom.RandInt(3);
        CreateItem(
          ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::"Maximum Qty.", false,
          25 + LibraryRandom.RandInt(10), 0, 200 + LibraryRandom.RandInt(10), '');
        Evaluate(TimeBucket, '<1W>');
        UpdateItem(ChildItem, ChildItem.FieldNo("Time Bucket"), TimeBucket);
        UpdateItem(ChildItem, ChildItem.FieldNo("Safety Stock Quantity"), 20 + LibraryRandom.RandInt(5));

        CreateItem(
          ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::"Fixed Reorder Qty.", false,
          20 + LibraryRandom.RandInt(10), 30 + LibraryRandom.RandInt(10), 0, '');
        CreateProductionBOMAndCertify(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", QuantityPer);
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(ParentItem, ParentItem.FieldNo("Safety Stock Quantity"), 10 + LibraryRandom.RandInt(10));

        // Exercise: Calculate Plan for Parent Item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // Verify: Verify Requisition Line and Planning Component for Parent Item and Child Item.
        VerifyRequisitionLineDetails(ParentItem);
        VerifyPlanningComponentDetails(ParentItem, ChildItem, QuantityPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B42752_CalcPlanForChildItem()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TimeBucket: DateFormula;
        QuantityPer: Integer;
    begin
        // Verify Requisition Line after calculate plan using Child Item.
        // Setup:
        Initialize();
        QuantityPer := LibraryRandom.RandInt(3);
        CreateItem(
          ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::"Maximum Qty.", false,
          25 + LibraryRandom.RandInt(10), 0, 200 + LibraryRandom.RandInt(10), '');
        Evaluate(TimeBucket, '<1W>');
        UpdateItem(ChildItem, ChildItem.FieldNo("Time Bucket"), TimeBucket);
        UpdateItem(ChildItem, ChildItem.FieldNo("Safety Stock Quantity"), 20 + LibraryRandom.RandInt(5));

        CreateItem(
          ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::"Fixed Reorder Qty.", false,
          20 + LibraryRandom.RandInt(10), 30 + LibraryRandom.RandInt(10), 0, '');
        CreateProductionBOMAndCertify(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", QuantityPer);
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(ParentItem, ParentItem.FieldNo("Safety Stock Quantity"), 10 + LibraryRandom.RandInt(10));
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // Exercise: Calculate Plan for Child Item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(ChildItem, WorkDate(), WorkDate());

        // Verify: Verify Requisition Line for Child Item.
        VerifyMultipleRequisitionLine(ParentItem, ChildItem, QuantityPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B42538_RefreshProdOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
        ActualCount: Integer;
    begin
        // Verify Production Order Line and Production Order Component line after Refresh Released Production Order.
        // Setup:
        Initialize();
        RequisitionLine.DeleteAll(true);
        CreateMultipleItems(
          Item2, Item3, Item, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item."No.", 1);
        UpdateItem(Item2, Item2.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Exercise: Create and Refresh Released Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Item, false);

        // Verify: Verify the Production Order line and Production Order Component.
        FilterProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ActualCount := ProdOrderLine.Count();
        Assert.AreEqual(1, ActualCount, NumberOfLineErr);  // Value is important for Test.

        FilterProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ActualCount := ProdOrderComponent.Count();
        Assert.AreEqual(1, ActualCount, NumberOfLineErr);  // Value is important for Test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B42538_ChangeUserIDOnReqLine()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        Quantity: Integer;
        UserID: Code[50];
    begin
        // Verify Requisition Line after Changing User ID in Requisition Line.
        // Setup.
        Initialize();
        RequisitionLine.DeleteAll(true);
        Quantity := LibraryRandom.RandInt(10);
        CreateMultipleItems(
          Item2, Item3, Item, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item."No.", 1);
        UpdateItem(Item2, Item2.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, ProductionOrder."Source Type"::Item, false);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Exercise: Change Requisition Line for another User.
        UserID := LibraryUtility.GenerateGUID();
        RequisitionLine.SetRange("Demand Order No.", ProductionOrder."No.");
        RequisitionLine.ModifyAll("User ID", UserID);

        // Verify: Verify Requisition Line for new User.
        VerifyRequisitionLineForUser(UserID, ProductionOrder."No.", Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B42538_UserIDOnReqLine()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        Quantity: Integer;
    begin
        // Verify Requisition Line with User ID after Calculating Order Plan.
        // Setup.
        Initialize();
        RequisitionLine.DeleteAll(true);
        Quantity := LibraryRandom.RandInt(10);
        CreateMultipleItems(
          Item2, Item3, Item, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item."No.", 1);
        UpdateItem(Item2, Item2.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, ProductionOrder."Source Type"::Item, false);

        // Exercise: Calculate Order Plan.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify: Verify Requisition Line for User.
        VerifyRequisitionLineForUser(UserId, ProductionOrder."No.", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure B42538_MakePurchOrderReqLine()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        Quantity: Integer;
    begin
        // Verify Purchase Line after making Purchase Order form Requisition line.
        // Setup.
        Initialize();
        RequisitionLine.DeleteAll(true);
        Quantity := LibraryRandom.RandInt(10);
        CreateMultipleItems(
          Item2, Item3, Item, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item."No.", 1);
        UpdateItem(Item2, Item2.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, ProductionOrder."Source Type"::Item, false);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        LibraryPurchase.CreateVendor(Vendor);
        UpdateRequisitionLineWithSupplyFrom(ProductionOrder."No.", Item."No.", Vendor."No.");
        FilterRequisitionLine(RequisitionLine, Item."No.");

        // Exercise: Make Purchase Order form Requisition line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"All Lines",
          ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders");

        // Verify: Verify Purchase Line with No and Quantity.
        VerifyPurchaseLine(Vendor."No.", Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_RefreshProdOrderSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Verify Production Order line after refreshing Released Production Order for Subcontracting.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        // Exercise: Create and Refresh Released Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Item, false);

        // Verify: Verify Production Order line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_RoutingStatusNotCertifiedSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Verify Error message after refreshing Released Production Order for Subcontracting if Routing Status not certified.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Item, false);

        // Modify Routing Status not certified.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");

        // Exercise: Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Error message.
        Assert.IsFalse((StrPos(GetLastErrorText, StatusTxt) = 0) or (StrPos(GetLastErrorText, CertifiedTxt) = 0), GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_ProdBOMStatusNotCertifiedSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Verify Error message after refreshing Released Production Order for Subcontracting if Production BOM Status not certified.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Item, false);

        // Modify Production BOM status not certified.
        ProductionBOMHeader.Find();
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");

        // Exercise: Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Error message.
        Assert.IsFalse((StrPos(GetLastErrorText, StatusTxt) = 0) or (StrPos(GetLastErrorText, CertifiedTxt) = 0), GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_CalcSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        RequisitionLine: Record "Requisition Line";
        OperationNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Requisition Line after Calculation of Subcontracting.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        OperationNo := Format(10 + LibraryRandom.RandInt(10));
        Quantity := LibraryRandom.RandInt(10);
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, ProductionOrder."Source Type"::Item, false);

        // Exercise: Calculation of Subcontracting.
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Operation No in Requisition Line.
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);
        RequisitionLine.TestField("Operation No.", OperationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44327_PostPurchOrderSubcontracting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        OperationNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Capacity Ledger Entry after Carry out action message of subcontracting and post Purchase Order.
        // Setup: Create a new Work Center for subcontracting.
        Initialize();
        OperationNo := Format(10 + LibraryRandom.RandInt(10));
        Quantity := LibraryRandom.RandInt(10);
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, ProductionOrder."Source Type"::Item, false);
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);

        // Exercise: Run Carry out action message of subcontracting.
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // Verify: Verify Line Amount in Purchase Line.
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Line Amount", Quantity * WorkCenter."Direct Unit Cost");

        // Exercise: Posting Purchase Order with Subcontracting.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Capacity Ledger Entry.
        VerifyCapacityLedgerEntry(WorkCenter, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44714_CopyDimOnJournalLines()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        DefaultDimension: Record "Default Dimension";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        LineNoOfWorkCenter: Integer;
        LineNoOfWorkCenter2: Integer;
        LineDimSetID: Integer;
        LineDimSetID2: Integer;
    begin
        // Verify Dimension Copied on Journal line after changing Work Center.
        // Setup:
        Initialize();
        CreateMultipleWorkCenterSetup(WorkCenter, WorkCenter2, RoutingHeader);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5),
          ProductionOrder."Source Type"::Item, false);
        CreateDimensionWithValue(DimensionValue, DimensionValue2);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Work Center", WorkCenter."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Work Center", WorkCenter2."No.", DimensionValue2."Dimension Code", DimensionValue2.Code);
        OutputJournalExplodeRouting(ProductionOrder);
        LineNoOfWorkCenter := SelectJournalLineNos(ProductionOrder, WorkCenter."No.");
        LineNoOfWorkCenter2 := SelectJournalLineNos(ProductionOrder, WorkCenter2."No.");
        LineDimSetID := SelectJournalLineDimSetID(LineNoOfWorkCenter);

        // Exercise: Change Work Center No on Journal Line.
        ChangeWorkCenterOnJournalLine(LineNoOfWorkCenter2, WorkCenter."No.");
        LineDimSetID2 := SelectJournalLineDimSetID(LineNoOfWorkCenter2);

        // Verify: Verify Dimension Code Values for the Work Centers.
        VerifyDimensions(LineDimSetID, 1, DimensionValue."Dimension Code", DimensionValue.Code);
        VerifyDimensions(LineDimSetID2, 1, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44714_ChangeWorkCenterWithDim()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        DefaultDimension: Record "Default Dimension";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        Dimension2: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValue3: Record "Dimension Value";
        LineNoOfWorkCenter2: Integer;
        LineDimSetID2: Integer;
    begin
        // Verify Dimension Copied on Journal line after changing Work Center and added dimension on journal Line.
        // Setup.
        Initialize();
        CreateMultipleWorkCenterSetup(WorkCenter, WorkCenter2, RoutingHeader);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5),
          ProductionOrder."Source Type"::Item, false);
        CreateDimensionWithValue(DimensionValue, DimensionValue2);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Work Center", WorkCenter."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Work Center", WorkCenter2."No.", DimensionValue2."Dimension Code", DimensionValue2.Code);
        OutputJournalExplodeRouting(ProductionOrder);
        LineNoOfWorkCenter2 := SelectJournalLineNos(ProductionOrder, WorkCenter2."No.");
        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionValue(DimensionValue3, Dimension2.Code);

        // Exercise: Add Dimension on Journal line and Change Work Center No.
        AddDimensionOnJournalLine(LineNoOfWorkCenter2, DimensionValue3."Dimension Code", DimensionValue3.Code);
        ChangeWorkCenterOnJournalLine(LineNoOfWorkCenter2, WorkCenter."No.");
        LineDimSetID2 := SelectJournalLineDimSetID(LineNoOfWorkCenter2);

        // Verify: Verify new Dimension for Work Center in Dimension Set Entry.
        VerifyDimensions(LineDimSetID2, 1, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B44714_ChangeWorkCenterWithoutDim()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        DefaultDimension: Record "Default Dimension";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        LineNoOfWorkCenter2: Integer;
        LineDimSetID2: Integer;
    begin
        // Verify Dimension Copied on Journal line after changing Work Center and no dimension on Work Center.
        // Setup.
        Initialize();
        CreateMultipleWorkCenterSetup(WorkCenter, WorkCenter2, RoutingHeader);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5),
          ProductionOrder."Source Type"::Item, false);
        CreateDimensionWithValue(DimensionValue, DimensionValue2);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Work Center", WorkCenter2."No.", DimensionValue2."Dimension Code", DimensionValue2.Code);
        OutputJournalExplodeRouting(ProductionOrder);
        LineNoOfWorkCenter2 := SelectJournalLineNos(ProductionOrder, WorkCenter2."No.");

        // Exercise: Change Work Center No.
        ChangeWorkCenterOnJournalLine(LineNoOfWorkCenter2, WorkCenter."No.");
        LineDimSetID2 := SelectJournalLineDimSetID(LineNoOfWorkCenter2);

        // Verify: Verify new Dimension for Work Center in Dimension Set Entry.
        Assert.AreEqual(0, LineDimSetID2, NoDimensionExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B45291_CalcPlanForMultipleItems()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ActualCount: Integer;
    begin
        // Verify Requisition line after calculating plan for multiple items.
        // Setup: Create items and Sales Order.
        Initialize();
        SalesReceivablesSetup.Get();
        RequisitionLine.DeleteAll(true);
        LibrarySales.SetStockoutWarning(false);
        CreateMultipleItems(
          Item, Item2, Item3, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::"Lot-for-Lot", true);
        CreateSalesOrderWithMultipleLine(Item."No.", Item2."No.", Item3."No.", LocationBlue.Code);

        Item.SetFilter("No.", '%1|%2|%3', Item."No.", Item2."No.", Item3."No.");
        Item.SetRange("Location Filter", LocationBlue.Code);

        // Exercise: Run Planning Worksheet for three Items.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        RequisitionLine.ModifyAll("Accept Action Message", true);

        // Verify: Verify Requisition Line should be three lines (Two lines for Production Order).
        ActualCount := RequisitionLine.Count();
        Assert.AreEqual(3, ActualCount, NumberOfLineErr);  // Value is important for Test.
        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        ActualCount := RequisitionLine.Count();
        Assert.AreEqual(2, ActualCount, NumberOfLineErr);  // Value is important for Test.

        // Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B45291_CalcCarryOutActionMsgPlan()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ActualCount: Integer;
    begin
        // Verify Requisition line after Run Carry Out Action Msg Plan for Production Order.
        // Setup: Create items and Sales Order.
        Initialize();
        SalesReceivablesSetup.Get();
        RequisitionLine.DeleteAll(true);
        LibrarySales.SetStockoutWarning(false);
        CreateMultipleItems(
          Item, Item2, Item3, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::"Lot-for-Lot", true);
        CreateSalesOrderWithMultipleLine(Item."No.", Item2."No.", Item3."No.", LocationBlue.Code);

        Item.SetFilter("No.", '%1|%2|%3', Item."No.", Item2."No.", Item3."No.");
        Item.SetRange("Location Filter", LocationBlue.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        RequisitionLine.ModifyAll("Accept Action Message", true);

        // Exercise: Run Carry Out Action Msg Plan for Production Order line.
        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // Verify: Verify Requisition Line should be one line.
        Clear(RequisitionLine);
        ActualCount := RequisitionLine.Count();
        Assert.AreEqual(1, ActualCount, NumberOfLineErr);  // Value is important for Test.

        // Teardown: Rollback Stockout Warning to default value on Sales & Receivables Setup.
        LibrarySales.SetStockoutWarning(SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B7479_ChangeItemOnProdComponent()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
    begin
        // Verify Prodcution Order Component after changing Item on Prodcution Order Component.
        // Setup: Create Items, Production BOM, Create Production Order and Refresh.
        Initialize();
        CreateMultipleItems(
          Item3, Item2, Item, Item."Replenishment System"::Purchase, Item."Replenishment System"::"Prod. Order",
          Item."Reordering Policy"::" ", false);
        UpdateItemWithUnitOfMeasure(UnitOfMeasure, Item2."No.");

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", LibraryRandom.RandInt(10));  // Using Random for Quantity Per.
        UpdateProductionBOMLine(ProductionBOMLine, UnitOfMeasure.Code);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);// Using Random for Quantity.

        // Exercise: Change Item on Prodcution Order Component.
        ChangeItemOnProdOrderComponent(ProductionOrder, Item2."No.", Item3."No.");

        // Verify: Verify Item on Prodcution Order Component.
        VerifyProdOrderComponentDetails(Item3, ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('ReleasedProdOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure B7615_ChangeFlushingMethodOnProdComponent()
    var
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Finish Production line after Changing Flusing Bethod both Routings and Components line and change Status.

        // [GIVEN] Two variants for an Item.
        Initialize();
        CreateItemHierarchy(ProductionBOMHeader, ParentItem, ChildItem, 1);
        LibraryInventory.CreateItemVariant(ItemVariant, ParentItem."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, ParentItem."No.");
        CreateAndCertifyRoutingSetup(RoutingHeader, RoutingLine);
        UpdateItem(ParentItem, ParentItem.FieldNo("Routing No."), RoutingHeader."No.");
        UpdateItemInventory(ChildItem."No.", ChildItem."No.");

        // [GIVEN] Sales Order with both Variant.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, ParentItem."No.", '', ItemVariant.Code, LibraryRandom.RandDec(10, 2));
        CreateSalesLine(SalesHeader, SalesLine2, ParentItem."No.", '', ItemVariant2.Code, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Released Production Order from Sales Order.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ProjectOrder);

        // [GIVEN] All Flushing Methods changed to Backward for both Routings and Components.
        UpdateFlushingMethodOnProdOrderRoutingLine(ProductionOrder, SalesHeader."No.");
        UpdateFlushingMethodOnProdOrderComponent(ProductionOrder, SalesHeader."No.");

        // [WHEN] Finish Production Order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Production Order line correct for both Variant.
        VerifyProdOrderLine(ProductionOrder."No.", ParentItem."No.", ItemVariant.Code, SalesLine.Quantity);
        VerifyProdOrderLine(ProductionOrder."No.", ParentItem."No.", ItemVariant2.Code, SalesLine2.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B18019_DifferentUOMOnProductionBOMError()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Verify Error message when assign Production BOM to Item if Production BOM have different Unit of Measure.
        // Setup.
        Initialize();
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // Create a new Production BOM with differnt Unit of Measure.
        CreateProductionBOMAndCertify(
          ProductionBOMHeader, UnitOfMeasure.Code, ProductionBOMLine.Type::Item, Item2."No.", LibraryRandom.RandInt(10));  // Using Random for Quantity Per.

        // Exercise: Assign Production BOM to item.
        asserterror Item.Validate("Production BOM No.", ProductionBOMHeader."No.");

        // Verify: Verify Error message.
        Assert.ExpectedErrorCannotFind(Database::"Item Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B18019_ChangeUOMOnProductionBOMError()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Verify Error message when change different Unit of Measure on Production BOM as assigned Item.
        // Setup.
        Initialize();
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        CreateProductionBOMAndCertify(
          ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", LibraryRandom.RandInt(10));  // Using Random for Quantity Per.
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        // Change UOM of Production BOM and assign Production BOM to item.
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Exercise: Change UOM of Production BOM.
        asserterror ProductionBOMHeader.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        // Verify: Verify Error message.
        Assert.ExpectedErrorCannotFind(Database::"Item Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B32912_ProductionOrderwithFamily()
    var
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        InbWhseHandlingTime: Text[30];
        ExpectedEndingDate: Date;
        DueDate: Date;
        ShopCalendarCode: Code[10];
    begin
        // Verify Due date for Family on Production order after Refresh Production order.
        // Setup: Create Family and Production Order.
        Initialize();
        CreateFamilySetup(Family);
        InbWhseHandlingTime := UpdateLocation(LocationBlue, '<1D>');
        DueDate := CalcDate('<WD4>', WorkDate());
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Family, Family."No.", 1);
        UpdateProductionOrder(ProductionOrder, LocationBlue.Code, DueDate);

        // Exercise.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Prodcution Order.
        ProductionOrder.Get(ProductionOrder.Status::Planned, ProductionOrder."No.");
        ProductionOrder.TestField("Source Type", ProductionOrder."Source Type"::Family);
        ProductionOrder.TestField("Source No.", Family."No.");
        ProductionOrder.TestField("Due Date", DueDate);
        InventorySetup.Get();
        ExpectedEndingDate := CalcDate('<' + '-' + Format(LocationBlue."Inbound Whse. Handling Time") + '>',
            CalcDate('<' + '-' + Format(InventorySetup."Default Safety Lead Time") + '>', ProductionOrder."Due Date"));

        ShopCalendarCode := GetShopCalendarCodeForProductionOrder(ProductionOrder);
        while not CheckShopCalendarWorkingDay(ShopCalendarCode, ExpectedEndingDate) do
            ExpectedEndingDate -= 1;
        ProductionOrder.TestField("Ending Date", ExpectedEndingDate);
        UpdateLocation(LocationBlue, InbWhseHandlingTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B45301_PostCapacityJournal()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenter: Record "Work Center";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Number of Capacity Journal Line after creating Capacity Journal and Post.
        // Setup.
        Initialize();
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);

        // Exercise: Create a new line in Capacity Journal.
        CreateCapacityJournalLine(ItemJournalLine, WorkCenter."No.");

        // Verify: Verify number of Item Journal Lines.
        ItemJournalLine.SetRange("Journal Template Name", CapacityItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", CapacityItemJournalBatch.Name);
        Assert.AreEqual(1, ItemJournalLine.Count, ItemJournalLineErr);

        // Exercise: Post Capacity Journal.
        LibraryInventory.PostItemJournalLine(CapacityItemJournalBatch."Journal Template Name", CapacityItemJournalBatch.Name);

        // Verify: Verify number of Item Journal Lines.
        ItemJournalLine.SetRange("Journal Template Name", CapacityItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", CapacityItemJournalBatch.Name);
        Assert.AreEqual(0, ItemJournalLine.Count, ItemJournalLineErr);  // Zero for No line for Item Journal.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B29203_NeededTimeOnProductionOrderCapacity()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // Verify Capacity (Effective), Needed Time on Calendar Entry and Production Order Capacity Need after Refresh Firm Planned Production Order.
        // Setup: Create Item, Work Center and Routing Header.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, '');

        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        UpdateWorkCenterWithEfficiency(WorkCenter);
        CreateCapacityConstrainedResource(WorkCenter."No.");

        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        UpdateRoutingLine(RoutingLine, 1, 20, 0);  // Value is important for Test.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        // Exercise: Create an Refresh Firm Planned Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", 100 + LibraryRandom.RandInt(1000),
          ProductionOrder."Source Type"::Item, false);  // Large Value.

        // Verify: Verify Capacity (Effective), Needed Time on Calendar Entry and Production Order Capacity Need.
        VerifyProdOrderCapacityNeed(WorkCenter."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B29289_ReplanProductionOrderWithVariant()
    var
        Parent: Record Item;
        Component: Record Item;
        Item3: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // Verify Variant Code on Production Order Line after Replan Production Order.
        // Setup: Create Items, Production BOM and Production Order.
        Initialize();
        CreateMultipleItems(
          Parent, Component, Item3, Parent."Replenishment System"::"Prod. Order", Parent."Replenishment System"::Purchase,
          Parent."Reordering Policy"::" ", false);
        LibraryInventory.CreateItemVariant(ItemVariant, Component."No.");

        CreateProductionBOMAndCertify(
          ProductionBOMHeader, Parent."Base Unit of Measure", ProductionBOMLine.Type::Item, Component."No.", LibraryRandom.RandInt(5));  // Using Random for Quantity Per.
        UpdateItem(Parent, Parent.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Parent."No.", LibraryRandom.RandInt(5),
          ProductionOrder."Source Type"::Item, false);
        UpdateVariantCodeOnProdOrderComponent(Component."No.", ItemVariant.Code);

        // Exercise: Replan Production Order.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // Verify: Verify Variant Code on Production Order Line and Production Order
        VerifyVarinetOfProdOrderLineAndProductionOrder(ProdOrderLine, Component, ProductionOrder, ItemVariant);

        // Refresh the Production Order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Variant Code on Production Order Line and Production Order after refreshing
        VerifyVarinetOfProdOrderLineAndProductionOrder(ProdOrderLine, Component, ProductionOrder, ItemVariant);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B32771_CapableToPromiseOnSalesOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionBOMHeader2: Record "Production BOM Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        OldReqTemplateType: Enum "Req. Worksheet Template Type";
    begin
        // Verify Quantity on Requisition Line after Calculate Capable to Promise on Sales Order.
        // Setup : Create Items, Multiple Production BOM and Sales Order.
        Initialize();
        OldReqTemplateType := ChangeTypeInReqWkshTemplate(ReqWkshTemplate.Type::Planning);
        CreateShipmentItem(Item, RoutingHeader);

        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order", Item2."Reordering Policy"::" ", false, 0, 0, 0, '');
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item2."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMHeader."No.", Format(LibraryRandom.RandInt(10)), Item2."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code", ProductionBOMLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(5));  // Using Random for Quantity Per.
        CertifiedStatusOnProductionBOMVersion(ProductionBOMVersion);

        CreateProductionBOMAndCertify(
          ProductionBOMHeader2, Item2."Base Unit of Measure", ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader."No.", 1);
        UpdateItem(Item2, Item2.FieldNo("Routing No."), RoutingHeader."No.");
        UpdateItem(Item2, Item2.FieldNo("Production BOM No."), ProductionBOMHeader2."No.");
        CreateSalesOrder(SalesHeader, SalesLine, Item2."No.", '');

        // Exercise: Calculate Capable to Promise.
        CalcCapableToPromise(TempOrderPromisingLine, SalesHeader);

        // Verify: Verify Quantity on Requisition Line.
        VerifyQuantityOnRequisitionLine(Item2."No.", RequisitionLine."Replenishment System"::"Prod. Order", SalesLine.Quantity);
        VerifyQuantityOnRequisitionLine(
          Item."No.", RequisitionLine."Replenishment System"::Purchase, ProductionBOMLine."Quantity per" * SalesLine.Quantity);

        // Restore Order Promising Setup
        ChangeTypeInReqWkshTemplate(OldReqTemplateType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EarliestShipmentDateAfterPurchaseOrderReleased()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        LeadDateFormula: DateFormula;
    begin
        Initialize();
        RequisitionLine.DeleteAll(true);
        CreateShipmentItem(Item, RoutingHeader);
        Evaluate(LeadDateFormula, '<21D>'); // 21D
        Item.Validate("Lead Time Calculation", LeadDateFormula);
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", true);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", '');

        // Exercise: Calculate Capable to Promise.
        CalcCapableToPromise(TempOrderPromisingLine, SalesHeader);

        // Verify: Verify Earliest Shipment Dates on Order Promising Line.
        Evaluate(LeadDateFormula, '<22D>'); // 21D +1 Day to Lead Time.
        VerifyEarliestShipmentDate(
          CalcDate(LeadDateFormula, WorkDate()),
          TempOrderPromisingLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableToPromiseEarliestShipmentDate()
    var
        Item: Record Item;
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
        Quantity: Integer;
        LeadDatesFormula: DateFormula;
    begin
        // Preparatiom
        Initialize();
        Quantity := LibraryRandom.RandInt(10);

        // Create test item and post stock purchase
        Evaluate(LeadDatesFormula, '<21D>');
        CreateStockItem(Item, Item."Replenishment System"::Purchase, LeadDatesFormula);
        PostItemStockPurchase(Item, Quantity, '', ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // Create sales order with different shpipment dates in lines and excee
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        Evaluate(LeadDatesFormula, '<25D>');
        CreateSalesLineWithShipmentDate(SalesHeader, Item."No.", '', Quantity, CalcDate(LeadDatesFormula, WorkDate()), true);
        CreateSalesLineWithShipmentDate(SalesHeader, Item."No.", '', Quantity, WorkDate(), false);

        // Exercise: Calculate Available to Promise.
        AvailabilityManagement.SetSourceRecord(TempOrderPromisingLine, SalesHeader);
        AvailabilityManagement.CalcAvailableToPromise(TempOrderPromisingLine);

        // Verify: Verify Earliest Shipment Dates on Order Promising Lines.
        // "Earliest Shipment Date" = "Original Shipment Date" on the order promising line for the reserved sales line.
        TempOrderPromisingLine.FindSet();
        VerifyEarliestShipmentDate(0D, TempOrderPromisingLine);
        TempOrderPromisingLine.Next();
        VerifyEarliestShipmentDate(CalcDate(LeadDatesFormula, WorkDate()), TempOrderPromisingLine);
    end;

    [Normal]
    local procedure B308740_ChangeWaitTime(Forward: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ManufacturingSetup: Record "Manufacturing Setup";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLine1: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        ExpEndingDate: Date;
        ExpEndingTime: Time;
        OperationNo: Code[10];
    begin
        // Setup: Create Routing and Production Order.
        Initialize();
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Hours, 080000T, 230000T);
        CreateWorkCenterSetup(WorkCenter2, CapacityUnitOfMeasure.Type::Hours, 080000T, 120000T);

        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Normal Starting Time", 080000T);
        ManufacturingSetup.Validate("Normal Ending Time", 230000T);
        ManufacturingSetup.Modify(true);

        LibraryPlanning.SetDefaultSafetyLeadTime('<0D>');

        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        UpdateRoutingLine(RoutingLine, 0, 1, 12);
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine1, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenter2."No.");
        UpdateRoutingLine(RoutingLine1, 0, 4, 0);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", 1, ProductionOrder."Source Type"::Item, Forward);

        // Exercise: Modify the wait time for the first routing line to force the routing line to end at midnight next day.
        FilterProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", RoutingLine."Operation No.");
        ProdOrderRoutingLine.FindFirst();

        ExpEndingTime := ProdOrderRoutingLine."Starting Time";
        ExpEndingDate := ProdOrderRoutingLine."Starting Date" + 1;
        if Forward then
            ProdOrderRoutingLine.Validate("Wait Time", 15)
        else
            ProdOrderRoutingLine.Validate("Wait Time", 4);
        ProdOrderRoutingLine.Modify(true);
        ExpEndingTime += (ProdOrderRoutingLine."Run Time" + ProdOrderRoutingLine."Wait Time") * 3600000;

        // Verify: Verify that End date time is correct when forcing the routing to finish at midnight.
        Assert.AreEqual(
          ExpEndingDate, ProdOrderRoutingLine."Ending Date", 'Wrong Ending Date for order ' + ProdOrderRoutingLine."Prod. Order No.");
        Assert.AreEqual(
          ExpEndingTime, ProdOrderRoutingLine."Ending Time", 'Wrong Ending Time for order ' + ProdOrderRoutingLine."Prod. Order No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B308740_BackwardPlanning()
    begin
        B308740_ChangeWaitTime(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B308740_ForwardPlanning()
    begin
        B308740_ChangeWaitTime(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingCompForRelProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Update Inventory Setup and Create an Item with Production BOM and Routing attached. Create a Released Production Order with Random Quantity.
        Initialize();
        CreateRoutingSetup(RoutingHeader);
        CreateProdItem(Item, RoutingHeader."No.");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));

        // Exercise: Refresh the Released Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Components and Routings count for Production Order.
        VerifyCountForProductionOrderComponent(ProductionOrder."No.", Item."Production BOM No.");
        VerifyCountForProductionOrderRouting(ProductionOrder."No.", Item."Routing No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnProductionOrderForFamily()
    var
        ProductionOrder: Record "Production Order";
        Family: Record Family;
    begin
        // Setup.
        Initialize();
        CreateFamilySetup(Family);

        // Exercise: Create and Refresh Firm Planned Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Family."No.", LibraryRandom.RandInt(10),
          ProductionOrder."Source Type"::Family, false);

        // Verify: Verify the Quantity on Firm Planned Production Order.
        VerifyQtyOnProdOrder(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure B30656_TransferOrderWithTracking()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create LFLItem With Tracking Code,Create Transfer Route,Stockkeeping Units,Create and Post Item Journal,Create Sales and Transfer Order.
        Initialize();
        Quantity := 10 + LibraryRandom.RandInt(10);  // Using Large Random Value.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Lot-for-Lot", true, 0, 0, 0, '');
        UpdateTrackingCodeOnItem(Item, ItemTrackingCode.Code);
        UpdatePlanningParametersOnItem(Item);
        CreateTransferRoute(LocationBlue.Code, LocationGreen.Code, LocationInTransit.Code);

        CreateMultipleStockKeepingUnit(Item."No.", LocationBlue.Code, LocationGreen.Code);
        SetReplSystemTransferOnSKU(LocationGreen.Code, Item."No.", LocationBlue.Code);

        ItemTracking := ItemTracking::AssignSerial;  // Assign Global Variable for Page handler.
        CreateAndPostItemJournalLineWithTracking(Item."No.", LocationBlue.Code, Quantity);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", LocationGreen.Code, '', Quantity + LibraryRandom.RandInt(10));

        ItemTracking := ItemTracking::SelectSerial; // Assign Global Variable.
        CreateAndPostTransferOrder(TransferHeader, TransferLine, LocationBlue.Code, LocationGreen.Code, Item."No.", Quantity);  // Psot Ship

        // Exercise. Calculate Plan.
        CalculatePlanForReqWksh(
          Item, CalcDate('<' + Format(LibraryRandom.RandInt(5) + 10) + 'D>', WorkDate()),
          CalcDate('<' + Format(LibraryRandom.RandInt(5) + 20) + 'D>', WorkDate()));

        // Verify. Verify Receipt Tracking line on Transfer Order and Requisition line for different Location.
        ItemTracking := ItemTracking::VerifyValue;  // Assign Global Variable for Page handler.
        TrackingQuantity := TransferLine.Quantity;  // Assign Global Variable for Page handler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Inbound); // Open Tracking Page on Page handler ItemTrackingPageHandler.
        VerifyRequisitionLineForLocation(Item."No.", LocationGreen.Code);
        VerifyRequisitionLineForLocation(Item."No.", LocationBlue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalForReleasedProdOrderFlushingBackward()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify ILE for Output after posting Output (exploded Routing on Output Journal) for Released Production Order.

        // Setup.
        Initialize();
        ProductionOrderWithOutputAndConsumption(false);  // Change Status as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ConsumptionJournalWithProductionOrderStatusFinished()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify ILE for Consumption after posting Output (exploded Routing on Output Journal) and finishing Production Order.

        // Setup.
        Initialize();
        ProductionOrderWithOutputAndConsumption(true);  // Change Status as True.
    end;

    local procedure ProductionOrderWithOutputAndConsumption(ChangeStatus: Boolean)
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocNoIsProdOrderNo: Boolean;
    begin
        // Create Work Center, Create Items, Update Items Inventory and Create Production BOM and Certify.
        DocNoIsProdOrderNo := UpdateManufacturingSetup(false);
        CreateWorkCenter(WorkCenter);
        UpdateFlushingMethodOnWorkCenter(WorkCenter, WorkCenter."Flushing Method"::Backward);
        CreateMultipleItems(
          Item, Item2, Item3, Item."Replenishment System"::"Prod. Order", Item3."Replenishment System"::"Prod. Order",
          Item."Reordering Policy"::"Fixed Reorder Qty.", true);
        UpdateItem(Item2, Item2.FieldNo("Flushing Method"), Item2."Flushing Method"::Backward);
        UpdateItemInventory(Item2."No.", Item3."No.");
        CreateProductionBOMWithMultipleLinesAndCertify(
          ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", Item3."No.",
          LibraryRandom.RandInt(5));
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Create and Refresh Released Production Order. Explode Routing on Output Journal.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);
        OutputJournalExplodeRouting(ProductionOrder);

        // Exercise: Post Output Journal. Change Production Order Status from Released to Finished.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        if ChangeStatus then begin
            LibraryVariableStorage.Enqueue(FinishedStatusQst);  // Enqueue Value for Confirm Handler.
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        end;

        // Verify: Verify Item Ledger Entry - Entry Type Consumption for Finished Production Order.Verify Item Ledger Entry - Entry Type Output for Released Production Order.
        if ChangeStatus then
            VerifyItemLedgerEntryForConsumption(Item2."No.", ItemLedgerEntry."Entry Type"::Consumption)
        else
            VerifyItemLedgerEntryForOutput(Item."No.", ProductionOrder.Quantity, ItemLedgerEntry."Entry Type"::Output);

        // Tear Down.
        UpdateManufacturingSetup(DocNoIsProdOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderStartingDateTime()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Work Center, Create Items.
        Initialize();
        CreateWorkCenter(WorkCenter);
        CreateMultipleItems(
          Item, Item2, Item3, Item."Replenishment System"::"Prod. Order", Item3."Replenishment System"::"Prod. Order",
          Item."Reordering Policy"::Order, false);

        // Update Manufacturing Policy On Items,
        UpdateItem(Item, Item.FieldNo("Manufacturing Policy"), Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item2, Item2.FieldNo("Manufacturing Policy"), Item2."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item3, Item3.FieldNo("Manufacturing Policy"), Item3."Manufacturing Policy"::"Make-to-Order");

        // Create Production BOM with Multiple lines.
        CreateProductionBOMWithMultipleLinesAndCertify(
          ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", Item3."No.", 1);
        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        UpdateRoutingLine(RoutingLine, LibraryRandom.RandInt(50), LibraryRandom.RandInt(50), 0);  // Random values for Setup Time and RunTime.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // Update Production BOM No and Routing on Item.
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(10, 2));
        UpdateProductionOrder(ProductionOrder, '', WorkDate());  // Location Code as Blank.

        // Exercise: Refresh Released Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Starting Date-Time on Production Order Line.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        VerifyProdOrderLineForStartingDateTime(ProductionOrder."No.", ProductionOrder."Starting Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateSubcontractForReleasedProdOrderWithVariantCode()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Work Center for subcontracting and create Item.
        Initialize();
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(LibraryRandom.RandInt(10)));  // Using Random value for OperationNo.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");

        // Create Released Production Order and update Variant Code on Production Line.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        CreateAndUpdateVariantCodeOnProductionOrderLine(ProdOrderLine);
        WorkCenter.SetRange("No.", WorkCenter."No.");

        // Exercise: Calculate Subcontract.
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Variant Code in Requisition Line.
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);
        RequisitionLine.TestField("Variant Code", ProdOrderLine."Variant Code");
    end;

    [Test]
    [HandlerFunctions('ProductionBOMPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateProdOrderWithSKUWithRoutingAndProdBOMNo()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        StockkeepingUnitCard: TestPage "Stockkeeping Unit Card";
        StockkeepingUnitList: TestPage "Stockkeeping Unit List";
    begin
        // Check assignment of Routing No. and Production BOM No. from SKU
        // Setup: Create Item, Routing Header and Production BOM
        // [SCENARIO 555088] "Production BOM" action opens Production BOM page. Also "Prod. Active BOM Version" does the same, when there is no version.
        Initialize();

        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        UpdateItem(ChildItem, ChildItem.FieldNo(Reserve), ChildItem.Reserve::Always);
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        CreateProductionBOMAndCertify(
            ProductionBOMHeader, ParentItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", LibraryRandom.RandInt(5));

        // Create Item Variant and SKU without Rounting No. and Prod. BOM No.
        CreateRoutingSetup(RoutingHeader);
        LibraryInventory.CreateItemVariant(ItemVariant, ParentItem."No.");
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, ParentItem."No.", ItemVariant.Code);
        StockkeepingUnit.Validate("Routing No.", RoutingHeader."No.");
        StockkeepingUnit.Validate("Production BOM No.", ProductionBOMHeader."No.");
        StockkeepingUnit.Modify();

        // Exercise: Create Released Production Order and update Variant Code on Production Line.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Variant Code", ItemVariant.Code);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify();
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Routing No. in Prod. Order Line come from SKU
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.TestField("Variant Code", ProductionOrder."Variant Code");
        ProdOrderLine.TestField("Routing No.", StockkeepingUnit."Routing No.");
        ProdOrderLine.TestField("Production BOM No.", StockkeepingUnit."Production BOM No.");

        // [WHEN] Open Production BOM page from Stockkeeping Unit Card.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        StockkeepingUnitCard.OpenEdit();
        StockkeepingUnitCard.GotoRecord(StockkeepingUnit);
        StockkeepingUnitCard."Production BOM".Invoke();
        StockkeepingUnitCard.Close();

        // [Verify] Verify Production BOM is opened through "ProductionBOMPageHandler".

        // [WHEN] Open Production BOM Version page from Stockkeeping Unit Card.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        StockkeepingUnitCard.OpenEdit();
        StockkeepingUnitCard.GotoRecord(StockkeepingUnit);
        StockkeepingUnitCard."Prod. Active BOM Version".Invoke();
        StockkeepingUnitCard.Close();

        // [Verify] Verify Production BOM is opened through "ProductionBOMPageHandler".

        // [WHEN] Open Production BOM page from Stockkeeping Unit List.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        StockkeepingUnitList.OpenView();
        StockkeepingUnitList.GotoRecord(StockkeepingUnit);
        StockkeepingUnitList."Production BOM".Invoke();
        StockkeepingUnitList.Close();

        // [Verify] Verify Production BOM is opened through "ProductionBOMPageHandler".

        // [WHEN] Open Production BOM Version page from Stockkeeping Unit List.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        StockkeepingUnitList.OpenView();
        StockkeepingUnitList.GotoRecord(StockkeepingUnit);
        StockkeepingUnitList."Prod. Active BOM Version".Invoke();
        StockkeepingUnitList.Close();

        // [Verify] Verify Production BOM is opened through "ProductionBOMPageHandler".
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateProdOrderWithSKUWithoutRoutingAndProdBOMNo()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Check assignment of Routing No. and Production BOM No. from Parent  Item
        // Setup: Create Item, Routing Header and Production BOM
        Initialize();

        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        UpdateItem(ChildItem, ChildItem.FieldNo(Reserve), ChildItem.Reserve::Always);
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        CreateProductionBOMAndCertify(
            ProductionBOMHeader, ParentItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", LibraryRandom.RandInt(5));
        CreateRoutingSetup(RoutingHeader);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Validate("Routing No.", RoutingHeader."No.");
        ParentItem.Modify();

        // Create Item Variant and SKU without Rounting No. and Prod. BOM No. different from Item fields
        LibraryInventory.CreateItemVariant(ItemVariant, ParentItem."No.");
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, ParentItem."No.", ItemVariant.Code);

        // Exercise: Create Released Production Order and update Variant Code on Production Line.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Variant Code", ItemVariant.Code);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify();
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Routing No. in Prod. Order Line comes from Parent Item
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.TestField("Variant Code", ProductionOrder."Variant Code");
        ProdOrderLine.TestField("Routing No.", ParentItem."Routing No.");
        ProdOrderLine.TestField("Production BOM No.", ParentItem."Production BOM No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF304018()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompCmtLine: Record "Prod. Order Comp. Cmt Line";
    begin
        // Setup: Create Item tree and Routing setup.
        Initialize();
        CreateItemHierarchy(ProductionBOMHeader, ParentItem, ChildItem, LibraryRandom.RandInt(10));

        // Add long description field for Prod. Order and Prod Order Component.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.",
          LibraryRandom.RandDec(10, 2));
        ProductionOrder.Description :=
          PadStr('', LibraryUtility.GetFieldLength(DATABASE::"Production Order", ProductionOrder.FieldNo(Description)), 'A');
        ProductionOrder."Description 2" :=
          PadStr('', LibraryUtility.GetFieldLength(DATABASE::"Production Order", ProductionOrder.FieldNo("Description 2")), 'A');
        ProductionOrder.Modify();

        ProdOrderComponent.Init();
        ProdOrderComponent.Status := ProductionOrder.Status;
        ProdOrderComponent."Prod. Order No." := ProductionOrder."No.";
        ProdOrderComponent."Prod. Order Line No." := 10000;
        ProdOrderComponent."Line No." := 10000;
        ProdOrderComponent.Insert();
        ProdOrderComponent."Item No." := ChildItem."No.";
        ProdOrderComponent."Quantity per" := LibraryRandom.RandDec(10, 2);
        ProdOrderComponent.Description :=
          PadStr('', LibraryUtility.GetFieldLength(DATABASE::"Prod. Order Component", ProdOrderComponent.FieldNo(Description)), 'A');
        ProdOrderComponent.Modify();

        // Verify: There is no overflow error when retrieving the caption.
        ProdOrderCompCmtLine.Init();
        ProdOrderCompCmtLine.Status := ProdOrderComponent.Status;
        ProdOrderCompCmtLine."Prod. Order No." := ProdOrderComponent."Prod. Order No.";
        ProdOrderCompCmtLine."Prod. Order Line No." := ProdOrderComponent."Prod. Order Line No.";
        ProdOrderCompCmtLine."Prod. Order BOM Line No." := ProdOrderComponent."Line No.";
        ProdOrderCompCmtLine.Insert();

        ProdOrderCompCmtLine.SetRange(Status, ProdOrderComponent.Status);
        ProdOrderCompCmtLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderCompCmtLine.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ProdOrderCompCmtLine.SetRange("Prod. Order BOM Line No.", ProdOrderComponent."Line No.");

        ProdOrderCompCmtLine.Caption();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRtngOnProdOrdLnWithSubcontr()
    var
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check error when modifying routing No. on subcontracted Prod. Order line
        // Setup: Create 2 released prod. order lines, subcontract the first line
        Initialize();

        SetupProdOrdLnWithSubContr(ProdOrderLine);
        CreateRoutingSetup(RoutingHeader);

        // Get the first Prod. order line
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // Exercise
        asserterror ProdOrderLine.Validate("Routing No.", RoutingHeader."No.");

        // Verify: Existing Error Message
        Assert.AreEqual(StrSubstNo(ModifyRtngErr, ProdOrderLine."Routing No.", PurchaseLine.TableCaption()), GetLastErrorText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteProdOrdLnWithSubcontr()
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check error when deleting subcontracted Prod. Order line
        // Setup: Create 2 released prod. order lines, subcontract the first line
        Initialize();
        SetupProdOrdLnWithSubContr(ProdOrderLine);

        // Get the first Prod. order line
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // Exercise
        asserterror ProdOrderLine.Delete(true);

        // Verify: Existing Error Message
        Assert.AreEqual(StrSubstNo(DeleteRtngErr, ProdOrderLine."Line No.", PurchaseLine.TableName), GetLastErrorText, '');
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure DateConflictWhenOrderToOrderLink()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        VendorNo: Code[20];
    begin
        // Verify Confirm message when Order-to-order link cannot be met after date change.

        // Setup: Create Items, Production BOM.
        Initialize();
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        UpdateItem(ChildItem, ChildItem.FieldNo(Reserve), ChildItem.Reserve::Always);
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        CreateProductionBOMAndCertify(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.",
          LibraryRandom.RandInt(5));
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandDec(10, 2),
          ProductionOrder."Source Type"::Item, false);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        VendorNo := MakeSupplyOrdersFromRequisitionLine(ProductionOrder."No.", ChildItem."No.");

        // Exercise: Update Expected Receipt Date greater than Purchase Header Due Date on Purchase Lines Page.
        asserterror UpdateExpectedReceiptDateOnPurchaseLinesPage(VendorNo);

        // Verify: Verification done in ConfirmHandlerTRUE Handler.
        Assert.IsTrue(StrPos(GetLastErrorText, ExpectedReceiptDateErr) > 0, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderWithLateDueDate()
    begin
        // Create Production Order with Item which has WorkCenter in routing with empty month in Calendar, due date
        // should be in empty month. Then refresh Production Order, and verify that Due Date is not changed.

        ManipulateProdOrderWithLateDueDate(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateProdOrderLetDueDateDecrease()
    begin
        // Create Production Order with Item which has WorkCenter in routing with empty month in Calendar, due date
        // should be in empty month. Then recalculate Production Order, and let due date decrease, and verify that
        // Due Date is changed.

        ManipulateProdOrderWithLateDueDate(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateProdOrderBlockDueDateDecrease()
    begin
        // Create Production Order with Item which has WorkCenter in routing with empty month in Calendar, due date
        // should be in empty month. Then recalculate Production Order, and block due date decrease, and verify that
        // Due Date is not changed.

        ManipulateProdOrderWithLateDueDate(false, false);
    end;

    local procedure ManipulateProdOrderWithLateDueDate(RefreshViaReport: Boolean; LetDueDateDecrease: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        DueDate: Date;
    begin
        // Create Production Order with Item which has WorkCenter in routing with empty month in Calendar, due date
        // should be in empty month. Then Refresh / Replan Production Order, and verify that Due Date is changed / not changed.

        // Setup: Create Item for Production Order.
        Initialize();
        SetupItemForProduction(Item);

        // Exercise.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item,
          Item."No.", LibraryRandom.RandDec(10, 2));
        DueDate := ProductionOrder."Due Date";
        RefreshProductionOrder(ProductionOrder, RefreshViaReport, LetDueDateDecrease);

        // Verify.
        VerifyDueDate(ProductionOrder, DueDate, not LetDueDateDecrease);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler,ConfirmHandler,ProdOrderComponentsHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostingOutputJournalDifferentBOM()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup;
        Initialize();

        CreateAndUpdateItems(ParentItem, ChildItem);
        CreateProductionBOMWithUOM(ParentItem, ChildItem);

        // Exercise:
        CreatePostItemJournal(ItemJournalLine, ChildItem."No.");

        CreateAndRefreshProdOrderWithItemTracking(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem, 2,
          ProductionOrder."Source Type"::Item);

        OutputJournalExplodeRoutingAndPostJournal(ProductionOrder);

        // Verify output item ledger entries.
        VerifyItemLedgerEntryForOutput(ParentItem."No.", ProductionOrder.Quantity, ItemLedgerEntry."Entry Type"::Output);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DueDateRespectedForProductionOrderToOrderLink()
    var
        TopItem: Record Item;
        ChildItem: array[3] of Record Item;
        BottomItem: Record Item;
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QtyPer: Decimal;
        RunTime: Integer;
    begin
        // [FEATURE] [Component Item] [Calculate Regenerative Plan] [Due Date]
        // [SCENARIO 364485] Component Item "Ending Date" equals to earliest "Starting Date" for Parent Items in Requisition Line after planning.

        // [GIVEN] Create Production Items: "Top", which consists of "Child1", "Child2", "Child3", each "Child" Item consists of "Component" Item.
        // [GIVEN] "Top" Item has "Make-to-Order" Manufacturing Policy
        Initialize();

        RunTime := LibraryRandom.RandIntInRange(10, 20);

        CreateItem(
          ComponentItem, ComponentItem."Replenishment System"::Purchase,
          ComponentItem."Reordering Policy"::"Lot-for-Lot", false, 0, 0, 0, '');

        CreateProductionBOM(
          ProductionBOMHeader, ProductionBOMLine, ComponentItem."Base Unit of Measure",
          ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        QtyPer := LibraryRandom.RandIntInRange(1, 3);

        CreateMakeToOrderItem(BottomItem, ProductionBOMHeader."No.", 1, RunTime);
        CreateProductionBOM(
          ProductionBOMHeader, ProductionBOMLine, BottomItem."Base Unit of Measure",
          ProductionBOMLine.Type::Item, BottomItem."No.", 4 * QtyPer);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] "Child*" Items have "Make-to-Order" Manufacturing Policy, and have a Routing with different RunTime.
        CreateMakeToOrderItem(ChildItem[1], ProductionBOMHeader."No.", 7, 3 * RunTime);
        CreateMakeToOrderItem(ChildItem[2], ProductionBOMHeader."No.", 7, 2 * RunTime);
        CreateMakeToOrderItem(ChildItem[3], ProductionBOMHeader."No.", 7, RunTime);

        CreateProductionBOM(
          ProductionBOMHeader, ProductionBOMLine, ChildItem[1]."Base Unit of Measure",
          ProductionBOMLine.Type::Item, ChildItem[1]."No.", QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem[2]."No.", QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem[3]."No.", QtyPer);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        CreateMakeToOrderItem(TopItem, ProductionBOMHeader."No.", 7, RunTime);

        // [GIVEN] Create Sales Order with Item "Top", planned delivery date 4 months forward from WORKDATE.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, TopItem."No.", '', '', LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Validate("Planned Delivery Date", CalcDate('<+4M>', WorkDate()));
        SalesLine.Modify(true);

        // [WHEN] Calculate Regenerative Plan
        ComponentItem.SetRange("No.", BottomItem."No.", TopItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-6M>', WorkDate()), CalcDate('<+6M>', WorkDate()));

        // [THEN] Component Item "Ending Date" equals to "Starting Date" for "Child*" Items.
        VerifyRequisitionLineDueDates(
          BottomItem."No.", StrSubstNo('%1|%2|%3', ChildItem[1]."No.", ChildItem[2]."No.", ChildItem[3]."No."), 4 * QtyPer);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BOMVersionBasedOnProductionOrderDueDate()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionBOMVersion: Record "Production BOM Version";
        DueDate: Date;
        ComponentQuantity: Decimal;
    begin
        // [FEATURE] [Calculate Regenerative Plan] [Carry Out Action Message] [BOM] [BOM Version] [Due Date]
        // [SCENARIO 364356] Carry Out Action Message creates Production Order with BOM Version on Due Date.

        // [GIVEN] Create production Item "Parent" with BOM of 1 "Component" Item.
        Initialize();

        CreateItem(
          ComponentItem, ComponentItem."Replenishment System"::Purchase,
          ComponentItem."Reordering Policy"::"Lot-for-Lot", false, 0, 0, 0, '');

        CreateProductionBOM(
          ProductionBOMHeader, ProductionBOMLine, ComponentItem."Base Unit of Measure",
          ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        CreateMakeToOrderItem(ParentItem, ProductionBOMHeader."No.", 1, 100);

        // [GIVEN] Create BOM Version with future Starting Date "X", modified "Qty. Per" = "A"
        DueDate := CalcDate('<+10D>', WorkDate());
        ComponentQuantity := LibraryRandom.RandIntInRange(5, 10);

        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMHeader."No.",
          Format(LibraryRandom.RandInt(10)), ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code",
          ProductionBOMLine.Type::Item, ComponentItem."No.", ComponentQuantity);
        CertifiedStatusOnProductionBOMVersion(ProductionBOMVersion);

        // [GIVEN] Create Sales Order with "Parent" Item of Quantity 1, Due Date = "X".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Due Date", DueDate);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, ParentItem."No.", '', '', 1);

        // [GIVEN] Calculate Regenerative Plan
        ParentItem.SetRange("No.", ParentItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [WHEN] Carry Out Action Message
        CarryOutActionMsgForItem(ParentItem."No.");

        // [THEN] Production Order Component Item is of Quantity "A".
        VerifyProdOrderComponentQuantity(ParentItem."No.", ComponentItem."No.", ComponentQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnOutputJournal()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        DimensionValue: array[4] of Record "Dimension Value";
    begin
        // Verify Dimension should be taken from the Production Order line when manually create a Output Journal

        // Setup: Create Item with Routing
        Initialize();
        CreateAndCertifyRoutingSetup(RoutingHeader, RoutingLine);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingHeader."No.");

        // Create 2 Dimensions, per Dimension with 2 Dimension Values. Add the 2 Dimensions on Work Center.
        UpdateWorkCenterWithDimension(DimensionValue[1], DimensionValue[2], RoutingLine."Work Center No.");
        UpdateWorkCenterWithDimension(DimensionValue[3], DimensionValue[4], RoutingLine."Work Center No.");

        // Create and Refresh Production Order, update the Dimension Value for 1st Dimension
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5),
          ProductionOrder."Source Type"::Item, false);
        AddDimensionOnProductionLine(ProductionOrder."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // Exercise: Create a Output Jounal for Production Order
        CreateOutputJournal(ProductionOrder, ItemJournalLine, RoutingLine."Operation No.");

        // Verify: Verify Dimension Value should be taken from the Production Order line if exist, otherwise, taken from Work Center Card
        VerifyDimensionValuesInItemJournal(DimensionValue, ItemJournalLine."Dimension Set ID");

        // Exercise: Clear the Work Center No. in Item Journal Line
        ItemJournalLine.Validate("Work Center No.", '');
        ItemJournalLine.Modify(true);

        // Verify: Verify Dimension Value should be taken from the Production Order line if exist, otherwise, taken from Work Center Card
        VerifyDimensionValuesInItemJournal(DimensionValue, ItemJournalLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DueDatesEqualForProductionOrderToOrderLink()
    var
        TopItem: Record Item;
        ChildItem: array[3] of Record Item;
        BottomItem: Record Item;
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QtyPer: Decimal;
        RunTime: Integer;
    begin
        // [FEATURE] [Component Item] [Calculate Regenerative Plan] [Due Date]
        // [SCENARIO 364485] Component Item "Ending Date" equals to "Starting Date" for Parent Items, if they have the same "Starting Date", in Requisition Line after planning.

        // [GIVEN] Create Production Items: "Top", which consists of "Child1", "Child2", "Child3", each "Child" Item consists of "Component" Item.
        // [GIVEN] "Top" Item have "Make-to-Order" Manufacturing Policy
        Initialize();

        RunTime := LibraryRandom.RandIntInRange(10, 20);

        CreateItem(
          ComponentItem, ComponentItem."Replenishment System"::Purchase,
          ComponentItem."Reordering Policy"::"Lot-for-Lot", false, 0, 0, 0, '');

        CreateProductionBOM(
          ProductionBOMHeader, ProductionBOMLine, ComponentItem."Base Unit of Measure",
          ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        QtyPer := LibraryRandom.RandIntInRange(1, 3);

        CreateMakeToOrderItem(BottomItem, ProductionBOMHeader."No.", 1, RunTime);
        CreateProductionBOM(
          ProductionBOMHeader, ProductionBOMLine, BottomItem."Base Unit of Measure",
          ProductionBOMLine.Type::Item, BottomItem."No.", 4 * QtyPer);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] "Child*" Items have "Make-to-Order" Manufacturing Policy, and have a Routing with the same RunTime.
        CreateMakeToOrderItem(ChildItem[1], ProductionBOMHeader."No.", 7, RunTime);
        CreateMakeToOrderItem(ChildItem[2], ProductionBOMHeader."No.", 7, RunTime);
        CreateMakeToOrderItem(ChildItem[3], ProductionBOMHeader."No.", 7, RunTime);

        CreateProductionBOM(
          ProductionBOMHeader, ProductionBOMLine, ChildItem[1]."Base Unit of Measure",
          ProductionBOMLine.Type::Item, ChildItem[1]."No.", QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem[2]."No.", QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem[3]."No.", QtyPer);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        CreateMakeToOrderItem(TopItem, ProductionBOMHeader."No.", 7, RunTime);

        // [GIVEN] Create Sales Order with Item "Top", planned delivery date 4 months forward from WORKDATE.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, TopItem."No.", '', '', LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Validate("Planned Delivery Date", CalcDate('<+4M>', WorkDate()));
        SalesLine.Modify(true);

        // [WHEN] Calculate Regenerative Plan
        ComponentItem.SetRange("No.", BottomItem."No.", TopItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(ComponentItem, CalcDate('<-6M>', WorkDate()), CalcDate('<+6M>', WorkDate()));

        // [THEN] Component Item "Ending Date" equals to "Starting Date" for "Child*" Items.
        VerifyRequisitionLineDueDates(
          BottomItem."No.", StrSubstNo('%1|%2|%3', ChildItem[1]."No.", ChildItem[2]."No.", ChildItem[3]."No."), 4 * QtyPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRoutingVersionNoSeries()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        ExpectedVersionNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Routing Version]
        // [SCENARIO 158148] Can create Routing Version with default "No. Series" if "Starting No." length > 10.

        // [GIVEN] "No. Series" with "Starting No." of length > 10
        Initialize();
        // [GIVEN] Createt Routing with "No. Series"
        RoutingHeader.Init();
        RoutingHeader.Validate("Version Nos.", CreateLongNoSeries(ExpectedVersionNo));
        RoutingHeader.Insert(true);
        // [WHEN] Create new Version for Routing
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingHeader."No.");
        RoutingVersion.Insert(true);
        // [THEN] "Version Code" equals to "Starting No." of "No. Series"
        Assert.AreEqual(RoutingVersion."Version Code", ExpectedVersionNo, WrongVersionCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTProductionBOMVersionNoSeries()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ExpectedVersionNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Production BOM Version]
        // [SCENARIO 158148] Can create Production BOM Version with default "No. Series" if "Starting No." length > 10.

        // [GIVEN] "No. Series" with "Starting No." of length > 10
        Initialize();
        // [GIVEN] Create Production BOM with "No. Series"
        ProductionBOMHeader.Init();
        ProductionBOMHeader.Validate("Version Nos.", CreateLongNoSeries(ExpectedVersionNo));
        ProductionBOMHeader.Insert(true);
        // [WHEN] Create new Version for Production BOM
        ProductionBOMVersion.Init();
        ProductionBOMVersion.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMVersion.Insert(true);
        // [THEN] "Version Code" equals to "Starting No." of "No. Series"
        Assert.AreEqual(ProductionBOMVersion."Version Code", ExpectedVersionNo, WrongVersionCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReValidatingUnitOfMeasureCodeOnProdBOMLine()
    var
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Production BOM] [UT]
        // [SCENARIO 377362] Re-Validating Unit of Measure Code to itself should be possible for any Type of Production BOM Line
        Initialize();

        // [GIVEN] Production BOM Line with Type = "Production BOM" and Unit of Measure = "X"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        MockProdBOMLineWithUoM(ProductionBOMLine, UnitOfMeasure.Code);

        // [WHEN] Re-Validate Unit of Measure to "X"
        ProductionBOMLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] Unit of Measure Code is "X"
        ProductionBOMLine.TestField("Unit of Measure Code", UnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingVersionIsBasedOnTheDueDateField()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RoutingNo: Code[20];
    begin
        // [FEATURE] [Routing Version] [Planning Worksheet]
        // [SCENARIO 379350] Production Order Routing Line should be created from record Routing Version on carrying out Production Order Proposal from Planning Worksheet.
        Initialize();

        // [GIVEN] Item and Routing Version.
        CreateItemAndRoutingVersion(Item, RoutingNo);
        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", '');
        // [GIVEN] Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Carry Out Action Messages to create a Production Order.
        CarryOutActionMsgForItem(Item."No.");

        // [THEN] Verify Production Order Routing Line should show line from Routing version.
        VerifyProdOrderRoutingLineIsNotEmpty(RoutingNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapableToPromiseWhenQueueTimeUOMAsDay()
    var
        WorkCenter: Record "Work Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        OldReqTemplateType: Enum "Req. Worksheet Template Type";
        MachineCenterNo: Code[20];
        RoutingNo: Code[20];
        ExpectedShipmentDate: Date;
        QueueTime: Decimal;
    begin
        // [FEATURE] [Machine Center] [Routing] [Queue Time] [Production]
        // [SCENARIO 379754] "Calculate Capable to Promise" should be performed when Type of UOM in the 1st Routing Line as Days and Type of Queue Time UOM in the 2nd Routing Line as Minutes.
        Initialize();
        OldReqTemplateType := ChangeTypeInReqWkshTemplate(ReqWkshTemplate.Type::Planning);

        // [GIVEN] Work Center with Capacity Unit Of Measure having Type as Days.
        CreateWorkCenterFullWorkingWeekCalendar(WorkCenter, CapacityUnitOfMeasure.Type::Days, 160000T, 235959T);
        // [GIVEN] Work Center including Machine Center with Queue Time more than 7 hours and all other time = 0.
        QueueTime := LibraryRandom.RandIntInRange(420, 450);
        MachineCenterNo := CreateMachineCenterWithQueueTime(QueueTime);
        // [GIVEN] Routing with two Sequential Operations (1 - Work Center, 2 - Machine Center).
        RoutingNo := CreateRoutingWithSequentialOperations(WorkCenter."No.", MachineCenterNo);
        // [GIVEN] Item using Routing.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, RoutingNo);
        // [GIVEN] Create Sales Order for Item.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code);

        // [WHEN] Calculate Capable to Promise.
        CalcCapableToPromise(TempOrderPromisingLine, SalesHeader);

        // [THEN] "Earliest Shipment Date" is calculated as "Original Shipment Date" + <1D> according to "Queue Time".
        InventorySetup.Get();
        ExpectedShipmentDate :=
          CalcDate('<' + Format(InventorySetup."Default Safety Lead Time") + '>',
            CalcDate('<' + Format(LocationBlue."Inbound Whse. Handling Time") + '>',
              CalcDate('<1D>', TempOrderPromisingLine."Original Shipment Date")));
        VerifyEarliestShipmentDate(ExpectedShipmentDate, TempOrderPromisingLine);
        ChangeTypeInReqWkshTemplate(OldReqTemplateType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateSubcontractsForMultilineProductionOrder()
    var
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Production] [Subcontracting] [Calculate Subcontracts]
        // [SCENARIO 380493] "Calculate Subcontracts" in subcontracting worksheet creates worksheet lines for multiline production order

        // [GIVEN] Subcontracting work center "W", routing "R" including work center "W"
        // [GIVEN] Production order with two lines, both with routing "R"
        Initialize();
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Two requisition lines created - one worksheet line per production order line
        Assert.RecordCount(RequisitionLine, 2);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindSet();
        repeat
            VerifyProdOrderRequisitionLine(ProdOrderLine);
        until ProdOrderLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMComponentCommentsAreCopiedToProdOrderComponentOnCarryOutMessage()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        ProductionOrder: Record "Production Order";
        Index: Integer;
    begin
        // [FEATURE] [Production BOM] [Planning Worksheet] [Production Order] [Comments]
        // [SCENARIO 314997] Production BOM component comments are transferred for Production Order component line on Carry Out Message
        Initialize();

        // [GIVEN] Parent Item "Parent" that is manufactured from Child Item "Child"
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        UpdateItem(ParentItem, ParentItem.FieldNo("Manufacturing Policy"), ParentItem."Manufacturing Policy"::"Make-to-Order");
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::Order, false, 0, 0, 0, '');
        UpdateItem(ChildItem, ChildItem.FieldNo("Vendor No."), LibraryPurchase.CreateVendorNo());

        // [GIVEN] Production BOM "ProdBOM" is assigned to "Parent" and consist of "Child"
        CreateProductionBOM(
            ProductionBOMHeader, ProductionBOMLine, ParentItem."Base Unit of Measure",
            ProductionBOMLine.Type::Item, ChildItem."No.", LibraryRandom.RandInt(5));
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // [GIVEN] 3 comments added for "ProdBOM" line containing "Text1" "Text2" and "Text3"
        for Index := 1 to LibraryRandom.RandIntInRange(2, 5) do
            LibraryManufacturing.CreateProductionBOMCommentLine(ProductionBOMLine);

        // [GIVEN] Sales Order created as a demand for ParentItem
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", '');

        // [GIVEN] Regenerative plan calculated for "Parent"
        ParentItem.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // [WHEN] Carry Out message for "Parent"
        CarryOutActionMsgForItem(ParentItem."No.");

        // [THEN] Comments "Text1" "Text2" "Text3" have been added to the component of production order comments
        FindProductionOrder(ProductionOrder, ParentItem."No.", ProductionOrder."Source Type"::Item);
        Assert.IsTrue(FindProdBOMCompCommentLines(ProductionBOMLine, ProductionBOMCommentLine), 'Comments expected');
        repeat
            VerifyCommentForProdOrderComponent(ProductionOrder."No.", ProductionBOMCommentLine.Comment);
        until ProductionBOMCommentLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMComponentCommentsAreCopiedToProdOrderComponentOnProdOrderRefresh()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        ProductionOrder: Record "Production Order";
        Index: Integer;
    begin
        // [FEATURE] [Production BOM] [Refresh Production Order] [Production Order] [Comments]
        // [SCENARIO 314997] Production BOM component comments are transferred for Production Order component line on Production Order Refresh
        Initialize();

        // [GIVEN] Parent Item "Parent" that is manufactured from Child Item "Child"
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ChildItem);

        // [GIVEN] Production BOM "ProdBOM" is assigned to "Parent" and consist of "Child"
        CreateProductionBOM(
            ProductionBOMHeader, ProductionBOMLine, ParentItem."Base Unit of Measure",
            ProductionBOMLine.Type::Item, ChildItem."No.", LibraryRandom.RandInt(5));
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // [GIVEN] 3 comments added for "ProdBOM" line containing "Text1" "Text2" and "Text3"
        for Index := 1 to LibraryRandom.RandIntInRange(2, 5) do
            LibraryManufacturing.CreateProductionBOMCommentLine(ProductionBOMLine);

        // [WHEN] Production Order created for "ParentItem" and refreshed
        CreateAndRefreshProdOrder(
            ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandDec(10, 2),
            ProductionOrder."Source Type"::Item, false);

        // [THEN] Comments "Text1" "Text2" "Text3" have been added to the component of Production Order comments
        Assert.IsTrue(FindProdBOMCompCommentLines(ProductionBOMLine, ProductionBOMCommentLine), 'Comments expected');
        repeat
            VerifyCommentForProdOrderComponent(ProductionOrder."No.", ProductionBOMCommentLine.Comment);
        until ProductionBOMCommentLine.Next() = 0;
    end;

    [Test]
    procedure VendorItemNoWhenCalculateSubcontractsItemVendorCatalog()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ItemVendor: Record "Item Vendor";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts] [Item Vendor]
        // [SCENARIO 395878] Vendor Item No. is set from Item Vendor Catalog for Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and Vendor Item No. = "Item". Item Vendor Catalog for Item "I" and Vendor "SV" with Vendor Item No. = "ItemVendorCatalog".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, LibraryUtility.GenerateGUID());
        CreateItemVendor(ItemVendor, WorkCenter."Subcontractor No.", Item."No.", LibraryUtility.GenerateGUID());

        // [GIVEN] Refreshed Production order for Item "I".
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2),
          ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and Vendor Item No. = "ItemVendorCatalog" is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoWhenCalculateSubcontractsSKUAndNoItemVendorCatalog()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts] [SKU]
        // [SCENARIO 395878] Vendor Item No. is set from Item's SKU for Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet and there is no Item Vendor Catalog.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and Vendor Item No. = "Item". There is no Item Vendor Catalog for Item "I" and Vendor "SV".
        // [GIVEN] SKU with Vendor Item No. = "StockKeepingUnit" for Item "I" and Location "L".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, LibraryUtility.GenerateGUID());
        CreateStockKeepingUnit(StockkeepingUnit, Item, LocationGreen.Code);
        UpdateVendorItemNoOnSKU(StockkeepingUnit, LibraryUtility.GenerateGUID());

        // [GIVEN] Refreshed Production order with Location "L" for Item "I".
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateProductionOrder(ProductionOrder, StockkeepingUnit."Location Code", WorkDate());
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and Vendor Item No. = "StockKeepingUnit" is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", StockkeepingUnit."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoWhenCalculateSubcontractsNoItemVendorCatalogNoSKU()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts]
        // [SCENARIO 395878] Vendor Item No. is set from Item for Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet and there is no Item Vendor Catalog and SKU.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and Vendor Item No. = "Item". There is no Item Vendor Catalog for Item "I" and Vendor "SV". There is no SKU for Item "I".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, LibraryUtility.GenerateGUID());

        // [GIVEN] Refreshed Production order for Item "I".
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2),
          ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and Vendor Item No. = "Item" is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", Item."Vendor Item No.");
    end;

    [Test]
    procedure VendorItemNoBlankWhenCalculateSubcontractsNoItemVendorCatalogNoSKUBlankItem()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Vendor Item No.] [Subcontracting] [Calculate Subcontracts]
        // [SCENARIO 395878] Vendor Item No. is blank in Requisition Line when it is created by Calculate Subcontracts from Subcontracting Worksheet and there is no Item Vendor Catalog and SKU; Item."Vendor Item No." is blank.
        Initialize();

        // [GIVEN] Subcontracting Work Center "W" with Subcontractor "SV". Routing "R" that contains line with Work Center "W".
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Item "I" with Routing "R" and blank Vendor Item No.. There is no Item Vendor Catalog for Item "I" and Vendor "SV". There is no SKU for Item "I".
        CreateProdItem(Item, RoutingHeader."No.");
        UpdateVendorItemNoOnItem(Item, '');

        // [GIVEN] Refreshed Production order for Item "I".
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2),
          ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts"
        CalculateSubcontractOrder(RequisitionLine, WorkCenter."No.", ProductionOrder);

        // [THEN] Requisition Line with Vendor "SV" and blank Vendor Item No. is created.
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
        RequisitionLine.TestField("Vendor Item No.", '');
    end;

    [Test]
    procedure VerifyQtyOnConsumptionLedgerEntryForComponentWithDifferentUoM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        CompItem, ProdItem : Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 467829] Verify Qty. on Consumption Ledger Entry for Component with different UoM
        Initialize();

        // [GIVEN] New Unit of Measure
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create Component Item with different UoM
        CreateCompItem(CompItem, CompItem."Flushing Method"::Backward, 0.00001);

        // [GIVEN] Create Item Unit of Measure
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, CompItem."No.", UnitofMeasure.Code, 0.00824);

        // [GIVEN] Create Production BOM
        CreateProdBOM(ProductionBOMHeader, CompItem."Base Unit of Measure", 0.3, CompItem."No.", ItemUnitofMeasure.Code, Format(100));

        // [GIVEN] Create Routing
        CreateCertifiedRoutingForWorkCenter(RoutingHeader, Format(100), Format(100));

        // [GIVEN] Create Production Item
        CreateProdItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order", ProdItem."Reordering Policy"::" ", RoutingHeader."No.", ProductionBOMHeader."No.");

        // [GIVEN] Create and Post Item Journal
        CreateAndPostItemJournalLine(CompItem."No.", 100);

        // [GIVEN] Create Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1260);

        // [GIVEN] Refresh Production Order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Post Production Order
        PostProductionJournal(ProductionOrder);

        // [THEN] Verify Qty on Consumption Ledger Entry for Component with different UoM
        VerifyItemLedgerEntry(CompItem."No.", false, -3.11472, 0);
    end;

    [Test]
    procedure AttentionMessageWhenPlanningMinimalSupplyForMissingSKU()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
    begin
        // [SCENARIO 485125] Attention message when planning minimal supply for missing SKU.
        Initialize();

        // [GIVEN] Item set up for fixed reorder planning. Reorder Quantity = 100.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", false, 10, 100, 0, '');

        // [GIVEN] Sales order for quantity = 10 at location "BLUE".
        // [GIVEN] Note that SKU does not exist for location "BLUE".
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code);

        // [WHEN] Calculate regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Attention message is added in Untracked Planning Elements pointing out that the planning system only covers the exact demand (10 pcs).
        RequisitionLine.SetRange("Location Code", LocationBlue.Code);
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
        UntrackedPlanningElement.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        UntrackedPlanningElement.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        UntrackedPlanningElement.Setrange("Worksheet Line No.", RequisitionLine."Line No.");
        UntrackedPlanningElement.SetFilter(Source, '*' + ItemPlannedForExactDemandTxt + '*');
        Assert.RecordIsNotEmpty(UntrackedPlanningElement);
    end;

    [Test]
    procedure AttentionMessageWhenPlanningMinimalSupplyForMissingLocation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
    begin
        // [SCENARIO 485125] Attention message when planning minimal supply for missing location.
        Initialize();

        // [GIVEN] Set "Location Mandatory" = true in Inventory Setup.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Item set up for fixed reorder planning. Reorder Quantity = 100.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", false, 10, 100, 0, '');

        // [GIVEN] Sales order for quantity = 10 at location <blank>.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", '');

        // [WHEN] Calculate regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Attention message is added in Untracked Planning Elements pointing out that the planning system only covers the exact demand (10 pcs).
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
        UntrackedPlanningElement.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        UntrackedPlanningElement.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        UntrackedPlanningElement.Setrange("Worksheet Line No.", RequisitionLine."Line No.");
        UntrackedPlanningElement.SetFilter(Source, '*' + ItemPlannedForExactDemandTxt + '*');
        Assert.RecordIsNotEmpty(UntrackedPlanningElement);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentWithZeroQuantityPer()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        TimeBucket: DateFormula;
        QuantityPer: Integer;
    begin
        // [SCENARIO 498825] Components in Planning worksheet is considering the components in the BOM if the Quantity per is zero
        Initialize();

        // [GIVEN] Define Quantity per
        QuantityPer := LibraryRandom.RandInt(3);

        // [GIVEN] Create Child Item 1
        CreateItem(
          ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::"Maximum Qty.", false,
          25 + LibraryRandom.RandInt(10), 0, 200 + LibraryRandom.RandInt(10), '');

        // [GIVEN] Create Child Item 2
        CreateItem(
        ChildItem2, ChildItem."Replenishment System"::Purchase, ChildItem2."Reordering Policy"::"Maximum Qty.", false,
        25 + LibraryRandom.RandInt(10), 0, 200 + LibraryRandom.RandInt(10), '');

        // [GIVEN] Update Time Bucket and Safety Bucket Quantity for Child Item 1
        Evaluate(TimeBucket, '<1W>');
        UpdateItem(ChildItem, ChildItem.FieldNo("Time Bucket"), TimeBucket);
        UpdateItem(ChildItem, ChildItem.FieldNo("Safety Stock Quantity"), 20 + LibraryRandom.RandInt(5));

        // [GIVEN] Create Parent Item
        CreateItem(
          ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::"Fixed Reorder Qty.", false,
          20 + LibraryRandom.RandInt(10), 30 + LibraryRandom.RandInt(10), 0, '');

        // [GIVEN] Create Production BOM and Certify it
        CreateProductionBOMWithTwoCoponentAndCertify(
        ProductionBOMHeader, ParentItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", ChildItem2."No.", QuantityPer);

        // [GIVEN] Update Production BOM and Safety Stock Quantity on Parent Item
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(ParentItem, ParentItem.FieldNo("Safety Stock Quantity"), 10 + LibraryRandom.RandInt(10));

        //[THEN] Run  "Calc. Item Plan - Plan Wksh." report
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // [VERIFY] Verify Requisition Detail
        VerifyRequisitionLineDetails(ParentItem);

        // [VERIFY] Vertify Quantity Per on Planning Component
        VerifyPlanningComponentWithZeroQuantityPer(ChildItem2)
    end;

    [Test]
    procedure OrderDateIsCalculatedCorrectlyIfLeadTimeCalculationIsGreaterThanOneYearForItemOnCalcPlanFromReqWorksheet()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 539761] Order Date is calculated correctly for Lead Time Calculation greater than one year on Calculate Plan from Req Worksheet
        Initialize();
        RequisitionLine.DeleteAll(true);

        // [GIVEN] Create Item with Lead Time Calculation greater than one year
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", false, 1, 1, 0, '');
        UpdateItem(Item, Item.FieldNo("Lead Time Calculation"), '<2Y>');
        UpdateItem(Item, Item.FieldNo("Manufacturing Policy"), Item."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Create Purchase Order and post Purchase Receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Run Calculation Plan from Req Worksheet for created Item
        CalculatePlanForReqWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Verify Order Date in Requisition line is calculated correctly
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Order Date", CalcDate('<-CY>', WorkDate()));
    end;

    [Test]
    procedure SubcontractingWorksheetDescriptionIsPopulatedFromWorkCenter()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: array[2] of Record Item;
        RequisitionLine: Record "Requisition Line";
        OperationNo: Code[10];
        Quantity: Decimal;
        WorkCenterName: Text;
    begin
        // [SCENARIO 540333] When the work Center changed in Subcontracting Worksheet the description is populated.
        Initialize();

        // [GIVEN] Store Operation No., Quantity and Work Center Description in a variable.
        OperationNo := Format(10 + LibraryRandom.RandInt(10));
        Quantity := LibraryRandom.RandInt(10);
        WorkCenterName := LibraryRandom.RandText(50);

        // [GIVEN] Create a Subcontracting Setup and Validate Name.
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);
        WorkCenter.Validate("Name 2", WorkCenterName);
        WorkCenter.Modify(true);

        // [GIVEN] Create two Items with Routing No.
        CreateItem(
            Item[1], Item[1]."Replenishment System"::"Prod. Order", Item[1]."Reordering Policy"::" ",
            false, 0, 0, 0, RoutingHeader."No.");
        CreateItem(
            Item[2], Item[2]."Replenishment System"::"Prod. Order", Item[2]."Reordering Policy"::" ",
            false, 0, 0, 0, RoutingHeader."No.");

        // [GIVEN] Create Production BOM and Certify.
        CreateProductionBOMAndCertify(
            ProductionBOMHeader, Item[1]."Base Unit of Measure",
            ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Validate Routing No. in Item.
        Item[1].Validate("Routing No.", RoutingHeader."No.");
        Item[1].Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrder(
            ProductionOrder, ProductionOrder.Status::Released, Item[1]."No.", Quantity,
            ProductionOrder."Source Type"::Item, false);

        // [GIVEN] Calculate Subcontracting for Work Center.
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Find the Requisition Line of Production Order.
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();

        // [WHEN] Validate Item No. into different Item and Validate Work Center No.
        RequisitionLine.Validate("No.", Item[2]."No.");
        RequisitionLine.Validate("Work Center No.", WorkCenter."No.");
        RequisitionLine.Modify(true);

        // [THEN] Description must be as same as Work Center Name.
        Assert.AreEqual(RequisitionLine.Description, WorkCenter.Name, SubcontractingDescriptionErr);
    end;

    [Test]
    [HandlerFunctions('ChangeStatusOnProdOrder')]
    procedure ChangeProductionOrderStatusUtilizeSelectFunctionality()
    var
        ProductionOrder: array[4] of Record "Production Order";
        Item: array[4] of Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ChangeProductionOrderStatus: TestPage "Change Production Order Status";
    begin
        // [SCENARIO 535695] Change Production Order Status utilize the Select Functionality when changing Firm Planned Production Orders to Released status.
        Initialize();

        // [GIVEN] Create Multiple Items.
        CreateMultipleItem(Item);

        // [GIVEN] Create Production BOM and Certify them.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader[1], Item[3]."No.", LibraryRandom.RandInt(1));
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader[2], Item[4]."No.", LibraryRandom.RandInt(1));

        // [GIVEN] Create Multiple Production Item for Item "X" and "Y".
        MakeMultipleProductionItem(Item, ProductionBOMHeader);

        // [GIVEN] Create Production Order "X".
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder[1], ProductionOrder[1].Status::"Firm Planned",
            ProductionOrder[1]."Source Type"::Item, Item[1]."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Refresh Production Order "X".
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[1], false, true, true, true, false);

        // [GIVEN] Create Production Order "Y".
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder[2], ProductionOrder[2].Status::"Firm Planned",
            ProductionOrder[2]."Source Type"::Item, Item[2]."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Refresh Production Order "Y".
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[2], false, true, true, true, false);

        // [GIVEN] Open Change Production Order Status and Select "Y" Production Order.
        ChangeProductionOrderStatus.OpenEdit();
        ChangeProductionOrderStatus.ProdOrderStatus.SetValue(ProductionOrder[2].Status::"Firm Planned");
        ChangeProductionOrderStatus.Filter.SetFilter("No.", ProductionOrder[2]."No.");
        ChangeProductionOrderStatus.Next();

        // [WHEN] Invoke Change Status.
        ChangeProductionOrderStatus."Change &Status".Invoke();

        // [THEN] Selected Production Order status must change to Released.
        ProductionOrder[4].SetRange("Firm Planned Order No.", ProductionOrder[2]."No.");
        ProductionOrder[4].FindFirst();
        Assert.AreEqual(ProductionOrder[4].Status, ProductionOrder[1].Status::Released, ProductionStatusErr);
    end;

    [Test]
    procedure ComponentWithNegativeAndZeroQuantityPerInPlannedProdOrder()
    var
        ParentItem: Record Item;
        ChildItem: array[6] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ChildItemCode: array[6] of Code[20];
        QuantityPer: array[6] of Integer;
        i: Integer;
    begin
        // [SCENARIO 527492] Production BOM Components is considering Negative and Zero Quantity in Production Order
        // When Production Order Created from Planning Worksheet.
        Initialize();

        // [GIVEN] Create Parent Item.
        CreateItem(
            ParentItem, ParentItem."Replenishment System"::"Prod. Order",
            ParentItem."Reordering Policy"::Order, false,
            0, 0, 0, '');

        // [GIVEN] Create Child Items and save it in Variables.
        for i := 1 to 6 do
            ChildItemCode[i] := LibraryInventory.CreateItem(ChildItem[i]);

        // [GIVEN] Generate Quantities and save it in Variables.
        GenerateQtys(QuantityPer);

        // [GIVEN] Create Production BOM and Certify it.
        CreateProductionBOMWithSixComponentAndCertify(
            ProductionBOMHeader, ParentItem."Base Unit of Measure",
            ProductionBOMLine.Type::Item, ChildItemCode, QuantityPer);

        // [GIVEN] Update Production BOM on Parent Item.
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // [GIVEN] Create a Sales Order of Parent Item and Release the same.
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", '');
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Calculate Regenerative Plan
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // [WHEN] Carry Out Action Message
        CarryOutActionMsgForItem(ParentItem."No.");

        // [THEN] Verify Production Order Component Items Quantity Per.
        for i := 1 to 6 do
            VerifyProdOrderComponentQuantities(ParentItem."No.", ChildItemCode[i], QuantityPer[i]);
    end;

    [Test]
    procedure RefreshProdOrderReportForFamilyCreatesProdOrderLinesAsPerUOMOfItems()
    var
        Family: Record Family;
        FamilyLine: Record "Family Line";
        Item: array[2] of Record Item;
        ItemUnitOfMeasure: array[4] of Record "Item Unit of Measure";
        UnitOfMeasure: array[4] of Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 556431] When Stan runs Refresh Production Order action from a
        // Released Production Order having Source Type as Family then Prod. Order Lines
        // are created as per Unit of Measure Codes of Items.
        Initialize();

        // [GIVEN] Create Item [1].
        LibraryInventory.CreateItem(Item[1]);

        // [GIVEN] Create Item [2].
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create Unit of Measure Code [1] and Item Unit of Measure [1].
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[1]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[1], Item[1]."No.",
            UnitOfMeasure[1].Code, LibraryRandom.RandIntInRange(50, 50));

        // [GIVEN] Create Unit of Measure Code [2] and Item Unit of Measure [2].
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[2]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[2], Item[1]."No.",
            UnitOfMeasure[2].Code, LibraryRandom.RandInt(0));

        // [GIVEN] Create Unit of Measure Code [3] and Item Unit of Measure [3].
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[3]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[3], Item[1]."No.",
            UnitOfMeasure[3].Code, LibraryRandom.RandDecInDecimalRange(0.2, 0.2, 1));

        // [GIVEN] Create Unit of Measure Code [4] and Item Unit of Measure [4].
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[4]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[4], Item[2]."No.",
            UnitOfMeasure[4].Code, LibraryRandom.RandIntInRange(3, 3));

        // [GIVEN] Create a Family.
        LibraryManufacturing.CreateFamily(Family);

        // [GIVEN] Create Family Lines.
        CreateFamilyLines(
            Family,
            Item[1],
            Item[2],
            UnitOfMeasure[1],
            UnitOfMeasure[2],
            UnitOfMeasure[3],
            UnitOfMeasure[4]);

        // [GIVEN] Create and Refresh Production Order.
        LibraryManufacturing.CreateAndRefreshProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Family,
            Family."No.",
            LibraryRandom.RandIntInRange(10, 10));

        // [GIVEN] Find Family Line.
        FamilyLine.SetRange("Family No.", Family."No.");
        FamilyLine.SetRange("Item No.", Item[1]."No.");
        FamilyLine.SetRange("Unit of Measure Code", UnitOfMeasure[2].Code);
        FamilyLine.FindFirst();

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item[1]."No.");
        ProdOrderLine.SetRange("Unit of Measure Code", UnitOfMeasure[2].Code);
        ProdOrderLine.FindFirst();

        // [THEN] Quantity of Prod. Order Line is equal to Quanity of Production Order * Quantity of Family Line.
        Assert.AreEqual(
            ProductionOrder.Quantity * FamilyLine.Quantity,
            ProdOrderLine.Quantity,
            StrSubstNo(
                QuanityPerErrorLbl,
                FamilyLine.FieldCaption(Quantity),
                ProductionOrder.Quantity * FamilyLine.Quantity,
                FamilyLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldSkipThoseItemsIfProductionBlockedIsOutputOnItem()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should skip those item if "Production Blocked" is Output on "Item".
        Initialize();

        // [GIVEN] Delete Prod. Order Routing Lines.
        ProdOrderRoutingLine.DeleteAll(false);

        // [GIVEN] Create Production Order with SubContracting Work Center.
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder);

        // [GIVEN] Update "Production Blocked" on Item.
        Item.Get(ProductionOrder."Source No.");
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be no requisition line if "Production Blocked" is Output on "Item".
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        Assert.RecordCount(RequisitionLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldCreateOnlyThoseLinesIfProductionBlockedIsBlankOnItem()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: array[2] of Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should create only those lines if "Production Blocked" is blank on "Item".
        Initialize();

        // [GIVEN] Create Production Order with SubContracting Work Center.
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder[1]);

        // [GIVEN] Create another Production Order with SubContracting Work Center.
        CreateProdOrderWithSubcontractWorkCenter(WorkCenter, ProductionOrder[2]);

        // [GIVEN] Update "Production Blocked" on Item.
        Item.Get(ProductionOrder[1]."Source No.");
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be two requisition lines if "Production Blocked" is blank on "Item".
        RequisitionLine.SetRange("No.", ProductionOrder[2]."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder[2].Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder[2]."No.");
        Assert.RecordCount(RequisitionLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldSkipThoseItemsIfProductionBlockedIsOutputOnItemVariant()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ItemVariant: Record "Item Variant";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should skip those item if "Production Blocked" is Output on "Item Variant".
        Initialize();

        // [GIVEN] Create Work Center.
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Create Item With Rounting.
        CreateProdItem(Item, RoutingHeader."No.");

        // [GIVEN] Create Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Released production order with Variant Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Variant Code", ItemVariant.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Update "Production Blocked" on "Item Variant".
        ItemVariant.Validate("Production Blocked", ItemVariant."Production Blocked"::Output);
        ItemVariant.Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be no requisition line if "Production Blocked" is Output on "Item Variant".
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        Assert.RecordCount(RequisitionLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculateSubContractsShouldCreateOnlyThoseLinesIfProductionBlockedIsBlankOnItemVariant()
    var
        Item: array[2] of Record Item;
        WorkCenter: Record "Work Center";
        ItemVariant: array[2] of Record "Item Variant";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: array[2] of Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 382546] Verify "Calculate Subcontracts" should create only those lines if "Production Blocked" is blank on "Item Variant".
        Initialize();

        // [GIVEN] Create Work Center.
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));

        // [GIVEN] Create Item and Item Variant With Rounting.
        CreateProdItem(Item[1], RoutingHeader."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item[1]."No.");

        // [GIVEN] Create another Item and Item Variant With Rounting.
        CreateProdItem(Item[2], RoutingHeader."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item[2]."No.");

        // [GIVEN] Create Released production order with Variant Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder[1], ProductionOrder[1].Status::Released, ProductionOrder[1]."Source Type"::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        ProductionOrder[1].Validate("Variant Code", ItemVariant[1].Code);
        ProductionOrder[1].Modify(true);

        // [GIVEN] Create another Released production order with Variant Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder[2], ProductionOrder[2].Status::Released, ProductionOrder[2]."Source Type"::Item, Item[2]."No.", LibraryRandom.RandInt(10));
        ProductionOrder[2].Validate("Variant Code", ItemVariant[2].Code);
        ProductionOrder[2].Modify(true);

        // [GIVEN] Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[1], false, true, true, true, false);

        // [GIVEN] Refresh another Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[2], false, true, true, true, false);

        // [GIVEN] Update "Production Blocked" on "Item Variant".
        ItemVariant[1].Validate("Production Blocked", ItemVariant[1]."Production Blocked"::Output);
        ItemVariant[1].Modify(true);

        // [WHEN] Run subcontracting worksheet and execute "Calculate Subcontracts".
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);

        // [VERIFY] Verify there should be one requisition line if "Production Blocked" is blank on "Item Variant".
        RequisitionLine.SetRange("No.", ProductionOrder[2]."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder[2].Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder[2]."No.");
        Assert.RecordCount(RequisitionLine, 1);
    end;

    [Test]
    procedure ProdutionBOMVersionIsCertifedIfAnotherVersionIsClosedContainBOMLoop()
    var
        ChildItem: Record Item;
        GrandParentItem: Record Item;
        GrandProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: array[2] of Record "Production BOM Version";
    begin
        // [SCENARIO 537287] New version of production BOM gets certified if there is another closed version containing BOM loop.
        Initialize();

        // [GIVEN] Create two level of Item Hierarchy.
        CreateItemHierarchy(ProductionBOMHeader, ParentItem, ChildItem, LibraryRandom.RandInt(5));
        CreateItemHierarchy(GrandProductionBOMHeader, GrandParentItem, ParentItem, LibraryRandom.RandInt(5));

        // [GIVEN] Create version one of production bom, add parent item and marked status as closed.
        CreateBOMVersionAndClosed(ParentItem, ProductionBOMVersion[1], ProductionBOMHeader);

        // [GIVEN] Create version two of production bom.
        CreateBOMVersionUsingCopyBOM(ParentItem."Base Unit of Measure", ProductionBOMVersion[2], ProductionBOMHeader, Format(LibraryRandom.RandIntInRange(2, 2)));

        // [WHEN] When update quantity in version two of bom.
        FindProductionBOMLine(ProductionBOMHeader, ProductionBOMVersion[2], ChildItem."No.", ProductionBOMLine);
        UpdateProductionBOMLineByField(ProductionBOMLine, ProductionBOMLine.FieldNo(Quantity), LibraryRandom.RandIntInRange(3, 5));

        // [THEN] Version two of production bom gets certified.
        UpdateStatusOnProductionBOMVersion(ProductionBOMVersion[2], ProductionBOMVersion[2].Status::Certified);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySubConWorkSheetOrderByOperationNo()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        WorkCenter: array[2] of Record "Work Center";
        WorkCenter2: Record "Work Center";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        OperationNo: array[2] of Code[10];
    begin
        // [SCENARIO 561326] Subcontracting Worksheet -  order of the lines is based on the "Operation No"
        Initialize();

        // [GIVEN] Create multiple subcontracting setup with multiple Work Center
        CreateMultipleSubcontractingSetup(WorkCenter, RoutingHeader, OperationNo);

        // [GIVEN] Create one Production Item and two Raw Item
        CreateMultipleItems(
          Item, Item3, Item2, Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase,
          Item."Reordering Policy"::" ", false);

        // [GIVEN] Create Production BOM and certify it
        CreateProductionBOMAndCertify(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", 1);

        // [GIVEN] Update Production BOM No. and Routing on Item
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        // [GIVEN] Create Released Production order
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), ProductionOrder."Source Type"::Item, false);

        // [WHEN] Run "Calculate Subcontracts" report
        WorkCenter2.SetFilter("No.", '%1|%2', WorkCenter[1]."No.", WorkCenter[2]."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter2);

        // [THEN] Verify Operation No. on Requisition Line will be in order of routing
        VerifyOperationNoOnRequisitionLineForProductionOrder(ProductionOrder, OperationNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderWhenProdBOMHasStartingEndingDate()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO 557289] When refreshing Production orders and using starting/ending dates on Production BOM Line
        // in a Released production order document pick correct component.
        Initialize();

        // [GIVEN] Create Work Center
        CreateWorkCenter(WorkCenter);

        // [GIVEN] Create Main Item and its component item
        CreateMultipleItems(
          Item, Item2, Item3, Item."Replenishment System"::"Prod. Order", Item3."Replenishment System"::"Prod. Order",
          Item."Reordering Policy"::Order, false);

        // [GIVEN] Update Manufacturing Policy On Items,
        UpdateItem(Item, Item.FieldNo("Manufacturing Policy"), Item."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item2, Item2.FieldNo("Manufacturing Policy"), Item2."Manufacturing Policy"::"Make-to-Order");
        UpdateItem(Item3, Item3.FieldNo("Manufacturing Policy"), Item3."Manufacturing Policy"::"Make-to-Order");

        // [GIVEN] Create Production BOM with Multiple lines.
        CreateProductionBOMWithStartingEndingDate(ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLine.Type::Item, Item2."No.", Item3."No.", 1);

        // [GIVEN] Create routing with multiple routing line
        CreateRoutingWithMultipleRoutingLine(RoutingHeader, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");

        // [GIVEN] Update Production BOM No and Routing on Item.
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingHeader."No.");

        // [GIVEN] Create Released Production Order of quantity 100
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 100);

        // [GIVEN] Update Due date near to starting  date of first component
        UpdateProductionOrder(ProductionOrder, '', CalcDate('<-10D>', WorkDate()));  // Location Code as Blank.

        // [WHEN] Refresh Released Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Find the Production Order Component and its should be first component Item2
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder, Item2."No.");
        Assert.RecordIsNotEmpty(ProdOrderComponent);

        // [WHEN] Again Refresh Released Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Find the Production Order Component and its should be same as previous component Item2
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder, Item2."No.");
        Assert.RecordIsNotEmpty(ProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('ChangeStatusOnProdOrderToFinished,ErrorMessageHandler')]
    procedure ChangeProductionOrderStatusWithoutVariantCode()
    var
        ProductionOrder: array[4] of Record "Production Order";
        Item: array[4] of Record Item;
        ItemVariant: array[2] of Record "Item Variant";
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ReleasedProductionOrders: TestPage "Released Production Orders";
    begin
        // [SCENARIO 598660] Changing the Status of Released Production Orders to Finished from the List of Released Production Orders will stop the process when Variant Code is missing.
        Initialize();

        // [GIVEN] Create Multiple Items.
        CreateMultipleItem(Item);

        // [GIVEN] Update "Variant Mandatory if Exists" on Item "X".
        Item[1].Validate("Variant Mandatory if Exists", Item[1]."Variant Mandatory if Exists"::Yes);
        Item[1].Modify(true);

        // [GIVEN] Create Production BOM and Certify them.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader[1], Item[3]."No.", LibraryRandom.RandInt(1));
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader[2], Item[4]."No.", LibraryRandom.RandInt(1));

        // [GIVEN] Create Multiple Production Item for Item "X" and "Y".
        MakeMultipleProductionItem(Item, ProductionBOMHeader);

        // [GIVEN] Create Item Variants for Item "X".
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item[1]."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item[1]."No.");

        // [GIVEN] Create Production Order "X".
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder[1], ProductionOrder[1].Status::Released,
            ProductionOrder[1]."Source Type"::Item, Item[1]."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Refresh Production Order "X".
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[1], false, true, true, true, false);

        // [GIVEN] Create Production Order "Y".
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder[2], ProductionOrder[2].Status::Released,
            ProductionOrder[2]."Source Type"::Item, Item[2]."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Refresh Production Order "Y".
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[2], false, true, true, true, false);

        // [GIVEN] Open Change Production Order Status and Select "X" Production Order.
        ReleasedProductionOrders.OpenEdit();
        ReleasedProductionOrders.GoToRecord(ProductionOrder[1]);

        // [WHEN] Invoke Change Status.
        ReleasedProductionOrders."Change &Status".Invoke();

        // [THEN] Selected Production Order should not be processed and Error message should be shown.
        ProductionOrder[3].SetRange("No.", ProductionOrder[1]."No.");
        ProductionOrder[3].FindFirst();
        Assert.RecordIsNotEmpty(ProductionOrder[1]);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manufacturing 7.0");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manufacturing 7.0");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        NoSeriesSetup();
        ItemJournalSetup();
        CapacityJournalSetup();
        OutputJournalSetup();
        CreateLocationSetup();
        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manufacturing 7.0");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        // Location -Blue.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // Location -Green.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationGreen);
        LocationGreen.Validate("Require Put-away", true);
        LocationGreen.Validate("Require Receive", true);
        LocationGreen.Validate("Require Pick", true);
        LocationGreen.Validate("Require Shipment", true);
        LocationGreen.Modify(true);

        // Location -Intransit.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationInTransit);
        LocationInTransit.Validate("Use As In-Transit", true);
        LocationInTransit.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
    end;

    local procedure OutputJournalSetup()
    begin
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        OutputItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        OutputItemJournalTemplate.Modify(true);

        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        OutputItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        OutputItemJournalBatch.Modify(true);
    end;

    local procedure CapacityJournalSetup()
    begin
        CapacityItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(CapacityItemJournalTemplate, CapacityItemJournalTemplate.Type::Capacity);
        CapacityItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        CapacityItemJournalTemplate.Modify(true);

        CapacityItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          CapacityItemJournalBatch, CapacityItemJournalTemplate.Type, CapacityItemJournalTemplate.Name);
        CapacityItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        CapacityItemJournalBatch.Modify(true);
    end;

    local procedure CreateSubcontractingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header"; OperationNo: Code[10])
    var
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenterSetup(MachineCenter, WorkCenter."No.");
        CreateRouting(RoutingHeader, RoutingLine, MachineCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Machine Center");
        UpdateRoutingLine(RoutingLine, LibraryRandom.RandInt(15), LibraryRandom.RandInt(15), 0);

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Wait Time", LibraryRandom.RandInt(5));
        RoutingLine.Modify(true);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure SetupItemForProduction(var Item: Record Item)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        LotAccumulationPeriod: DateFormula;
        ReschedulingPeriod: DateFormula;
        RunTime: Decimal;
    begin
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        RunTime := 10 + LibraryRandom.RandDec(10, 2);
        ClearWorkCenterCalendar(WorkCenter, CalcDate('<-CM>', WorkDate()), CalcDate('<+CM>', WorkDate()));

        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        UpdateRoutingLine(RoutingLine, 0, RunTime, 0);  // Setup Time value important.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        CreateItem(
          Item, Item."Replenishment System"::"Prod. Order",
          Item."Reordering Policy"::"Lot-for-Lot", false, 0, 0, 0, RoutingHeader."No.");
        Evaluate(LotAccumulationPeriod, '<1D>');
        Evaluate(ReschedulingPeriod, '<1D>');
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriod);
        Item.Validate("Rescheduling Period", ReschedulingPeriod);
        Item.Modify(true);
    end;

    local procedure MakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; CreatePurchaseOrder: Enum "Planning Create Purchase Order")
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders, CreatePurchaseOrder);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure MakeSupplyOrdersFromRequisitionLine(ProductionOrderNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateRequisitionLineWithSupplyFrom(ProductionOrderNo, ItemNo, Vendor."No.");
        FilterRequisitionLine(RequisitionLine, ItemNo);
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"All Lines",
          ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders");
        exit(Vendor."No.");
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreatePurchaseOrder: Enum "Planning Create Purchase Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, CreatePurchaseOrder,
              ManufacturingUserTemplate."Create Production Order"::" ",
              ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure SelectWorkCenter(var WorkCenter: Record "Work Center"; RoutingNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.FindFirst();
        WorkCenter.Get(RoutingLine."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean; ReorderPoint: Decimal; ReorderQuantity: Decimal; MaximumInventory: Decimal; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateStockItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; LeadDatesFormula: DateFormula)
    var
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Validate("Lead Time Calculation", LeadDatesFormula);
        Item.Modify(true);
    end;

    local procedure CreateMakeToOrderItem(var Item: Record Item; ProductionBOMNo: Code[20]; DampenerDays: Integer; RunTime: Integer)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<+5M>', WorkDate()));
        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        UpdateRoutingLine(RoutingLine, 0, RunTime, 0); // Run Time
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::Order, false, 0, 0, 0, RoutingHeader."No.");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Evaluate(Item."Dampener Period", '<' + Format(DampenerDays) + 'D>');
        Item.Modify(true);
    end;

    local procedure CreateMultipleItems(var Item: Record Item; var Item2: Record Item; var Item3: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReplenishmentSystem2: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean)
    begin
        CreateItem(Item, ReplenishmentSystem, ReorderingPolicy, IncludeInventory, 0, 0, 0, '');
        CreateItem(Item2, ReplenishmentSystem, ReorderingPolicy, IncludeInventory, 0, 0, 0, '');
        CreateItem(Item3, ReplenishmentSystem2, ReorderingPolicy, IncludeInventory, 0, 0, 0, '');
    end;

    local procedure RefreshProductionOrder(var ProductionOrder: Record "Production Order"; ViaReport: Boolean; LetDueDateDecrease: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        Direction: Option Forward,Backward;
    begin
        // Just refresh production order in order to create lines
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        if not ViaReport then // Calculate it again
            begin
            ProdOrderLine.SetRange(Status, ProductionOrder.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            if ProdOrderLine.Find('-') then
                repeat
                    CalculateProdOrder.Calculate(ProdOrderLine, Direction::Backward, true, true, false, LetDueDateDecrease)
                until ProdOrderLine.Next() = 0;
        end;
    end;

    local procedure CreateAndUpdateItems(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        RoutingHeader: Record "Routing Header";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CreateItemWithUOM(ParentItem, UnitOfMeasure.Code, ParentItem."Replenishment System"::"Prod. Order");
        RoutingHeader.FindFirst();
        ParentItem.Validate("Routing No.", RoutingHeader."No.");
        ParentItem.Modify(true);

        CreateItemWithUOM(ChildItem, ParentItem."Base Unit of Measure", ChildItem."Replenishment System"::Purchase);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ChildItem."No.", UnitOfMeasure.Code, LibraryRandom.RandInt(5));

        ChildItem.Validate("Flushing Method", ChildItem."Flushing Method"::Backward);
        LibraryItemTracking.AddLotNoTrackingInfo(ChildItem);
    end;

    local procedure CreateItemWithUOM(var Item: Record Item; UnitOfMeasureCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasureCode, 1);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Replenishment System", ReplenishmentSystem);
    end;

    local procedure UpdateItem(var Item: Record Item; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Item based on Field and its corresponding value.
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(Item);
        Item.Modify(true);
    end;

    local procedure UpdateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Production Order Component based on Field and its corresponding value.
        RecRef.GetTable(ProdOrderComponent);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(ProdOrderComponent);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        RequisitionWkshName.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateLongNoSeries(var StartingNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        StartingNo := 'X0000000000000001'; // specific value, length > 10
        LibraryUtility.CreateNoSeriesLine(
          NoSeriesLine, NoSeries.Code, StartingNo, IncStr(StartingNo));
        exit(NoSeries.Code);
    end;

    local procedure ChangeDimensionItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; WorkCenterNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        DimSetID: Integer;
    begin
        ItemJournalLine.SetRange("Work Center No.", WorkCenterNo);
        ItemJournalLine.FindFirst();
        DimSetID := ItemJournalLine."Dimension Set ID";
        ItemJournalLine.Validate(
          "Dimension Set ID", LibraryDimension.EditDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code));
        ItemJournalLine.Modify(true);
    end;

    local procedure FindItemJournalBatch(var ItemJournalBatch2: Record "Item Journal Batch")
    var
        ItemJournalTemplate2: Record "Item Journal Template";
    begin
        ItemJournalTemplate2.SetRange(Type, ItemJournalTemplate2.Type::Output);
        ItemJournalTemplate2.FindFirst();
        ItemJournalBatch2.SetRange("Journal Template Name", ItemJournalTemplate2.Name);
        ItemJournalBatch2.FindFirst();
    end;

    local procedure FindRequisitionLineForProductionOrder(var RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order")
    begin
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindFirst();
    end;

    local procedure UpdateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; WorkCenterNo: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.FindFirst();
        ItemJournalLine.SetRange("Work Center No.", WorkCenterNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateRequisitionLineWithSupplyFrom(DemandOrderNo: Code[20]; No: Code[20]; SupplyFrom: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Supply From", SupplyFrom);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateProductionBOMHeaderStatus(var ProductionBOMHeader: Record "Production BOM Header"; Status: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProductionOrder(var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; DueDate: Date)
    begin
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
    end;

    local procedure CalcCapableToPromise(var TempOrderPromisingLine: Record "Order Promising Line" temporary; var SalesHeader: Record "Sales Header")
    var
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        AvailabilityManagement.SetSourceRecord(TempOrderPromisingLine, SalesHeader);
        AvailabilityManagement.CalcCapableToPromise(TempOrderPromisingLine, SalesHeader."No.");
    end;

    local procedure CalculateSubcontractOrder(var RequisitionLine: Record "Requisition Line"; WorkCenterNo: Code[20]; ProductionOrder: Record "Production Order")
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetRange("No.", WorkCenterNo);
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
        FindRequisitionLineForProductionOrder(RequisitionLine, ProductionOrder);
    end;

    local procedure CarryOutActionMsgForItem(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure ChangeTypeInReqWkshTemplate(NewReqTemplateType: Enum "Req. Worksheet Template Type") OldReqTemplateType: Enum "Req. Worksheet Template Type"
    var
        RequisitionLine: Record "Requisition Line";
        OrderPromisingSetup: Record "Order Promising Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        RequisitionLine.DeleteAll(true);
        OrderPromisingSetup.Get();
        ReqWkshTemplate.Get(OrderPromisingSetup."Order Promising Template");
        OldReqTemplateType := ReqWkshTemplate.Type;
        ReqWkshTemplate.Type := NewReqTemplateType;
        ReqWkshTemplate.Modify();
    end;

    local procedure CreateItemHierarchy(var ProductionBOMHeader: Record "Production BOM Header"; var ParentItem: Record Item; var ChildItem: Record Item; QuantityPer: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        if ChildItem."No." = '' then
            CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::" ", false, 0, 0, 0, '');
        if ParentItem."No." = '' then
            CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::" ", false, 0, 0, 0, '');
        if ProductionBOMHeader."No." = '' then
            LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure")
        else
            UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("Version Code", '');
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ChildItem."No.");
        if not ProductionBOMLine.FindFirst() then
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem."No.", QuantityPer)
        else begin
            ProductionBOMLine.Validate("Quantity per", QuantityPer);
            ProductionBOMLine.Modify(true);
        end;
        UpdateItem(ParentItem, ParentItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        ParentItem.Get(ParentItem."No.");
        ChildItem.Get(ChildItem."No.");
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; SourceType: Enum "Prod. Order Source Type"; Forward: Boolean)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, Forward, true, true, true, false);
    end;

    local procedure CreateAndRefreshProdOrderWithItemTracking(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; Item1: Record Item; Quantity: Decimal; SourceType: Enum "Prod. Order Source Type")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, Item1."No.", Quantity);
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.Validate("Source No.", Item1."No.");

        ProdOrderLine.Status := ProdOrderLine.Status::"Firm Planned";
        ProdOrderLine.Init();
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Item No." := Item1."No.";
        ProdOrderLine."Unit of Measure Code" := Item1."Base Unit of Measure";
        ProdOrderLine.Validate(Quantity, LibraryRandom.RandInt(5));
        ProdOrderLine."Due Date" := WorkDate();
        ProdOrderLine.Insert();
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrder."No.");
        ReleasedProductionOrder.First();
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        ReleasedProductionOrder.ProdOrderLines.Components.Invoke();
    end;

    local procedure CreateAndCertifyRoutingSetup(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        UpdateRoutingLine(RoutingLine, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), 0);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateWorkCenterSetup(var WorkCenter: Record "Work Center"; CapacityType: Enum "Capacity Type"; StartTime: Time; EndTime: Time)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        CapacityUnitOfMeasure.SetRange(Type, CapacityType);
        CapacityUnitOfMeasure.FindFirst();
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", UpdateShopCalendarWorkingDays(StartTime, EndTime));
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', WorkDate()), CalcDate('<2M>', WorkDate()));
    end;

    local procedure CreateMachineCenterSetup(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(10, 1));
    end;

    local procedure CreateMachineCenterWithQueueTime(QueueTime: Decimal): Code[20]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        CreateWorkCenterFullWorkingWeekCalendar(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(10, 1));

        MachineCenter.Validate("Queue Time", QueueTime);
        MachineCenter.Validate("Queue Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        MachineCenter.Modify(true);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1W>', WorkDate()), CalcDate('<1W>', WorkDate()));
        exit(MachineCenter."No.");
    end;

    local procedure CreateMultipleWorkCenterSetup(var WorkCenter: Record "Work Center"; var WorkCenter2: Record "Work Center"; var RoutingHeader: Record "Routing Header")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        CreateWorkCenterSetup(WorkCenter2, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(10)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(10 + LibraryRandom.RandInt(10)), RoutingLine.Type::"Work Center", WorkCenter2."No.");
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateProdOrderWithSubcontractWorkCenter(var WorkCenter: Record "Work Center"; var ProductionOrder: Record "Production Order")
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
    begin
        CreateSubcontractingSetup(WorkCenter, RoutingHeader, Format(10 + LibraryRandom.RandInt(10)));
        CreateProdItem(Item, RoutingHeader."No.");

        // Create a released Prod. Order, create 2 Prod. Order lines, calculate routings
        SetupProdOrdWithRtng(ProductionOrder, Item."No.");
    end;

    local procedure CreateRoutingWithSequentialOperations(WorkCenterNo: Code[20]; MachineCenterNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Machine Center", MachineCenterNo);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        exit(RoutingHeader."No.");
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateSubcontractor(Vendor);
        CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandInt(5));
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);
    end;

    local procedure CreateWorkCenterFullWorkingWeekCalendar(var WorkCenter: Record "Work Center"; UOMType: Enum "Capacity Unit of Measure"; FromTime: Time; ToTime: Time)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, UOMType);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(FromTime, ToTime));
        WorkCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
    end;

    local procedure CreateFamilySetup(var Family: Record Family)
    var
        Item: Record Item;
        Item2: Record Item;
        RoutingHeader: Record "Routing Header";
    begin
        CreateProdItem(Item, '');
        CreateProdItem(Item2, '');
        CreateRoutingSetup(RoutingHeader);
        CreateFamily(Family, RoutingHeader."No.", Item."No.", Item2."No.");
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20]; VendorItemNo: Text[20])
    begin
        ItemVendor.Init();
        ItemVendor.Validate("Vendor No.", VendorNo);
        ItemVendor.Validate("Item No.", ItemNo);
        ItemVendor.Validate("Vendor Item No.", VendorItemNo);
        ItemVendor.Insert(true);
    end;

    local procedure CreateStockKeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item; LocationCode: Code[10])
    begin
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
        StockkeepingUnit.Get(LocationCode, Item."No.", '');
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure FindProdBOMCompCommentLines(ProductionBOMLine: Record "Production BOM Line"; var ProductionBOMCommentLine: Record "Production BOM Comment Line"): Boolean
    begin
        ProductionBOMCommentLine.SetRange("Production BOM No.", ProductionBOMLine."Production BOM No.");
        ProductionBOMCommentLine.SetRange("Version Code", ProductionBOMLine."Version Code");
        ProductionBOMCommentLine.SetRange("BOM Line No.", ProductionBOMLine."Line No.");
        exit(ProductionBOMCommentLine.FindSet());
    end;

    local procedure FilterRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        Clear(RequisitionLine);
        RequisitionLine.FilterGroup(2);
        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Worksheet Template Name", '');
        RequisitionLine.FilterGroup(0);
    end;

    local procedure FilterProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
    end;

    local procedure FilterProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
    end;

    local procedure FilterProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange(Status, Status);
    end;

    local procedure OutputJournalExplodeRouting(ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournal(ProductionOrder, ItemJournalLine, '');
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure CreateOutputJournal(ProductionOrder: Record "Production Order"; var ItemJournalLine: Record "Item Journal Line"; OperationNo: Code[10])
    var
        ItemJournalTemplate2: Record "Item Journal Template";
        ItemJournalBatch2: Record "Item Journal Batch";
    begin
        FindItemJournalBatch(ItemJournalBatch2);
        ItemJournalTemplate2.Get(ItemJournalBatch2."Journal Template Name");
        LibraryInventory.ClearItemJournal(ItemJournalTemplate2, ItemJournalBatch2);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name, ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Item No.", ProductionOrder."Source No.");
        if OperationNo <> '' then
            ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure OutputJournalExplodeRoutingAndPostJournal(ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate2: Record "Item Journal Template";
        ItemJournalBatch2: Record "Item Journal Batch";
    begin
        FindItemJournalBatch(ItemJournalBatch2);
        ItemJournalTemplate2.Get(ItemJournalBatch2."Journal Template Name");
        LibraryInventory.ClearItemJournal(ItemJournalTemplate2, ItemJournalBatch2);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name, ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Document No.", NoSeriesBatch.GetNextNo(ItemJournalBatch2."No. Series", ItemJournalLine."Posting Date"));
        ItemJournalLine.Modify(true);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name);
    end;

    local procedure ClearWorkCenterCalendar(WorkCenter: Record "Work Center"; FromDate: Date; ToDate: Date)
    var
        CalendarEntry: Record "Calendar Entry";
    begin
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
        CalendarEntry.SetRange("No.", WorkCenter."No.");
        CalendarEntry.SetRange(Date, FromDate, ToDate);
        CalendarEntry.DeleteAll();
    end;

    local procedure CalculatePlanForReqWksh(var Item: Record Item; StartDate: Date; EndDate: Date)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.FindFirst();
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure CreateItemAndRoutingVersion(var Item: Record Item; var RoutingNo: Code[20])
    var
        RoutingVersion: Record "Routing Version";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingNo := RoutingHeader."No.";
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::Order, false, 0, 0, 0, RoutingHeader."No.");
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", RoutingHeader."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, RoutingVersion."Version Code", '', RoutingLine.Type::"Work Center", WorkCenter."No.");

        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        RoutingVersion.Validate("Starting Date", WorkDate());
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
    end;

    local procedure CreateProductionBOMAndCertify(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QuantityPer: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateProductionBOM(ProductionBOMHeader, ProductionBOMLine, BaseUnitOfMeasure, Type, No, QuantityPer);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QuantityPer: Integer)
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, QuantityPer);
    end;

    local procedure CreateProductionBOMWithMultipleLinesAndCertify(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityPer: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLine2: Record "Production BOM Line";
    begin
        CreateProductionBOM(ProductionBOMHeader, ProductionBOMLine, BaseUnitOfMeasure, Type, ItemNo, QuantityPer);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine2, '', Type, ItemNo2, QuantityPer);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionBOMWithUOM(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RoutingLink: Record "Routing Link";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ChildItem."Base Unit of Measure");
        ProductionBOMHeader.Validate("Unit of Measure Code", ParentItem."Base Unit of Measure");
        ProductionBOMHeader.Modify(true);

        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
          ChildItem."No.", LibraryRandom.RandDecInDecimalRange(0.2, 0.7, 1));

        ItemUnitOfMeasure.SetRange("Item No.", ChildItem."No.");
        ItemUnitOfMeasure.FindLast();

        ProductionBOMLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        RoutingLink.FindLast();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, LocationCode, '', LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesOrderWithMultipleLine(ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo2, LocationCode, '', LibraryRandom.RandInt(10));
        CreateSalesLine(SalesHeader, SalesLine, ItemNo3, LocationCode, '', LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Release: Boolean)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendor(Vendor));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        if Release then
            LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateBOMVersionAndCertify(ProductionBOMNo: Code[20]; BaseUnitOfMeasure: Code[10])
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo, Format(LibraryRandom.RandInt(10)), BaseUnitOfMeasure);
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure UpdateItemWithDimensions(var Item: Record Item; var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
        Dimension3: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionValue3: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        Dimension.Get(GeneralLedgerSetup."Shortcut Dimension 1 Code");
        Dimension2.Get(GeneralLedgerSetup."Shortcut Dimension 2 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension2.Code);
        LibraryDimension.CreateDimension(Dimension3);
        LibraryDimension.CreateDimensionValue(DimensionValue3, Dimension3.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, Item."No.", Dimension.Code, DimensionValue.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, Item."No.", Dimension2.Code, DimensionValue2.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, Item."No.", Dimension3.Code, '');
    end;

    local procedure UpdateWorkCenterWithDimension(var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value"; WorkCenterNo: Code[20])
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Work Center", WorkCenterNo, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnWorkCenter(var WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method")
    begin
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Due Date", WorkDate());
        RequisitionLine.Validate("Ending Date", RequisitionLine."Due Date");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, 100 + LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo2, 100 + LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateRoutingLine(var RoutingLine: Record "Routing Line"; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal)
    begin
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Modify(true);
    end;

    local procedure ModifyProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; OperationNo: Code[10])
    begin
        FilterProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.Validate("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure AddDimensionOnJournalLine(LineNo: Integer; DimCode: Code[20]; DimValue: Code[20]): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        DimSetID: Integer;
        NewDimSetID: Integer;
    begin
        DimSetID := SelectJournalLineDimSetID(LineNo);
        NewDimSetID := LibraryDimension.CreateDimSet(DimSetID, DimCode, DimValue);

        ItemJournalLine.SetRange("Line No.", LineNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Dimension Set ID", NewDimSetID);
        ItemJournalLine.Modify(true);
        exit(ItemJournalLine."Dimension Set ID");
    end;

    local procedure AddDimensionOnProductionLine(ProdOrderNo: Code[20]; DimCode: Code[20]; DimValue: Code[20]): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
        NewDimSetID: Integer;
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
        NewDimSetID := LibraryDimension.CreateDimSet(ProdOrderLine."Dimension Set ID", DimCode, DimValue);
        ProdOrderLine.Validate("Dimension Set ID", NewDimSetID);
        ProdOrderLine.Modify(true);

        exit(ProdOrderLine."Dimension Set ID");
    end;

    local procedure SelectJournalLineNos(ProductionOrder: Record "Production Order"; WorkCenterCode: Code[20]): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch2: Record "Item Journal Batch";
    begin
        // get the line numbers for the output journal lines
        FindItemJournalBatch(ItemJournalBatch2);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch2."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch2.Name);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("No.", WorkCenterCode);
        ItemJournalLine.FindFirst();
        exit(ItemJournalLine."Line No.");
    end;

    local procedure ChangeWorkCenterOnJournalLine(LineNo: Integer; No: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch2: Record "Item Journal Batch";
    begin
        FindItemJournalBatch(ItemJournalBatch2);
        ItemJournalLine.Get(ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name, LineNo);
        ItemJournalLine.Validate("No.", No);
        ItemJournalLine.Modify(true);
    end;

    local procedure SelectJournalLineDimSetID(LineNo: Integer): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // get the DimSetID numbers for the output journal lines
        ItemJournalLine.SetRange("Line No.", LineNo);
        ItemJournalLine.FindFirst();
        exit(ItemJournalLine."Dimension Set ID");
    end;

    local procedure UpdateItemWithUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure"; ItemNo: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, LibraryRandom.RandInt(10));
    end;

    local procedure UpdateProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; UnitOfMeasureCode: Code[10])
    begin
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::Length);
        ProductionBOMLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProductionBOMLine.Validate(Length, LibraryRandom.RandInt(10));
        ProductionBOMLine.Modify(true);
    end;

    local procedure ChangeItemOnProdOrderComponent(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder, ItemNo);
        UpdateProdOrderComponent(ProdOrderComponent, ProdOrderComponent.FieldNo("Item No."), ItemNo2);
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        FilterProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure MockProdBOMLineWithUoM(var ProductionBOMLine: Record "Production BOM Line"; UnitOfMeasureCode: Code[10])
    begin
        ProductionBOMLine.Init();
        ProductionBOMLine."No." := LibraryUtility.GenerateGUID();
        ProductionBOMLine.Type := ProductionBOMLine.Type::"Production BOM";
        ProductionBOMLine."Unit of Measure Code" := UnitOfMeasureCode;
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithShipmentDate(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ShipmentDate: Date; AutoReserveLine: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
        if AutoReserveLine then
            LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; SourceType: Enum "Prod. Order Source Type")
    begin
        ProductionOrder.SetRange("Source Type", SourceType);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindLast();
    end;

    local procedure UpdateFlushingMethodOnProdOrderRoutingLine(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrder(ProductionOrder, SourceNo, ProductionOrder."Source Type"::"Sales Header");
        FilterProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderRoutingLine.FindSet();
        repeat
            ProdOrderRoutingLine.Validate("Flushing Method", ProdOrderRoutingLine."Flushing Method"::Backward);
            ProdOrderRoutingLine.Modify(true);
        until ProdOrderRoutingLine.Next() = 0;
    end;

    local procedure UpdateFlushingMethodOnProdOrderComponent(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrder(ProductionOrder, SourceNo, ProductionOrder."Source Type"::"Sales Header");
        FilterProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderComponent.FindSet();
        repeat
            UpdateProdOrderComponent(
              ProdOrderComponent, ProdOrderComponent.FieldNo("Flushing Method"), ProdOrderComponent."Flushing Method"::Backward);
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure CertifiedStatusOnProductionBOMVersion(ProductionBOMVersion: Record "Production BOM Version")
    begin
        ProductionBOMVersion.Validate("Starting Date", WorkDate());
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CreateCapacityJournalLine(var ItemJournalLine: Record "Item Journal Line"; No: Code[20])
    begin
        LibraryInventory.ClearItemJournal(CapacityItemJournalTemplate, CapacityItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, CapacityItemJournalBatch."Journal Template Name", CapacityItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Output, '', 0); // Zero used for Quantity.
        ItemJournalLine.Validate(Type, ItemJournalLine.Type::"Work Center");
        ItemJournalLine.Validate("No.", No);
        ItemJournalLine.Validate("Stop Time", LibraryRandom.RandInt(5));
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateFamily(var Family: Record Family; RoutingNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        FamilyLine: Record "Family Line";
    begin
        // Random values not important for test.
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingNo);
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo2, LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");

        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial, RoutingLine.Type::"Work Center");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20]; Type: Option; RoutingLineType: Enum "Capacity Type Routing")
    var
        OperationNo: Code[10];
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, Type);

        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLineType, WorkCenterNo);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random value important for test.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
    end;

    local procedure CreateProdItem(var Item: Record Item; RoutingNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
    begin
        // Create Child Items.
        CreateItemsWithInventory(ChildItemNo, ChildItemNo2);

        // Create Production BOM.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 1);  // Value important.

        // Create parent Item and attach Routing and Production BOM.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, '');
        UpdateItem(Item, Item.FieldNo("Routing No."), RoutingNo);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
    end;

    local procedure CreateShipmentItem(var Item: Record Item; var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        LeadTimeCalc: DateFormula;
    begin
        CreateAndCertifyRoutingSetup(RoutingHeader, RoutingLine);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ", false, 0, 0, 0, '');
        Evaluate(LeadTimeCalc, '<' + Format(LibraryRandom.RandInt(20)) + 'D>');
        UpdateItem(Item, Item.FieldNo("Lead Time Calculation"), LeadTimeCalc);
        UpdateItem(Item, Item.FieldNo(Critical), true);
    end;

    local procedure CreateItemsWithInventory(var ChildItemNo: Code[20]; var ChildItemNo2: Code[20])
    var
        Item: Record Item;
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, '');
        ChildItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::" ", false, 0, 0, 0, '');
        ChildItemNo2 := Item."No.";

        // Update Inventory for Item, random value important for test.
        UpdateItemInventory(ChildItemNo, ChildItemNo2)
    end;

    local procedure CreateCapacityConstrainedResource(WorkCenterNo: Code[20])
    var
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
    begin
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenterNo);
        CapacityConstrainedResource.Validate("Critical Load %", 100);  // Value important for Test.
        CapacityConstrainedResource.Modify(true);
    end;

    local procedure CreatePostItemJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        Item: Record Item;
        ItemJournal: TestPage "Item Journal";
    begin
        Item.Get(ItemNo);
        ItemJournalBatch.FindFirst();
        ItemJournalBatch.Validate("No. Series", '');
        ItemJournalBatch.Modify(true);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 1);

        ItemJournalLine.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(5, 10));
        ItemJournalLine.Modify(true);

        Commit();
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalLine."Journal Batch Name");

        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        ItemJournal.ItemTrackingLines.Invoke();
        ItemJournal.Post.Invoke();
    end;

    local procedure UpdateShopCalendarWorkingDays(StartTime: Time; EndTime: Time): Code[10]
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ShopCalendar: Record "Shop Calendar";
        WorkShift: Record "Work Shift";
        ShopCalendarCode: Code[10];
        WorkShiftCode: Code[10];
    begin
        // Create Shop Calendar Working Days using with boundary values daily work shift.
        ShopCalendarCode := LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        WorkShiftCode := LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);

        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Monday, WorkShiftCode, StartTime, EndTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Tuesday, WorkShiftCode, StartTime, EndTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Wednesday, WorkShiftCode, StartTime, EndTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Thursday, WorkShiftCode, StartTime, EndTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Friday, WorkShiftCode, StartTime, EndTime);

        exit(ShopCalendarCode);
    end;

    local procedure UpdateWorkCenterWithEfficiency(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.Validate(Capacity, 1);  // Value important for Test.
        WorkCenter.Validate(Efficiency, 100);  // Value important for Test.
        WorkCenter.Modify(true);
    end;

    local procedure UpdateVariantCodeOnProdOrderComponent(ItemNo: Code[20]; VariantCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        UpdateProdOrderComponent(ProdOrderComponent, ProdOrderComponent.FieldNo("Variant Code"), VariantCode);
    end;

    local procedure UpdateLocation(var Location: Record Location; NewInbWhseHandlingTime: Text[30]) OldInbWhseHandlingTime: Text[30]
    begin
        OldInbWhseHandlingTime := Format(Location."Inbound Whse. Handling Time");
        Evaluate(Location."Inbound Whse. Handling Time", NewInbWhseHandlingTime);
        Location.Validate("Inbound Whse. Handling Time");
        Location.Modify(true);
    end;

    local procedure CapacityEffectiveOnCalendarEntry(WorkCenterNo: Code[20]): Decimal
    var
        CalendarEntry: Record "Calendar Entry";
    begin
        CalendarEntry.SetCurrentKey("Capacity Type", "No.", Date, "Starting Time", "Ending Time", "Work Shift Code");
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
        CalendarEntry.SetRange("No.", WorkCenterNo);
        CalendarEntry.SetRange(Date, CalcDate('<-WD1>', WorkDate() - LibraryRandom.RandIntInRange(1, 3))); // Value important for Test.
        CalendarEntry.CalcSums("Capacity (Effective)");
        exit(CalendarEntry."Capacity (Effective)");
    end;

    local procedure NeededTimeOnProdOrderCapacityNeed(WorkCenterNo: Code[20]): Decimal
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetCurrentKey("Work Center No.", Date, Active, "Starting Date-Time");
        ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderCapacityNeed.SetRange(Date, CalcDate('<-WD1>', WorkDate() - LibraryRandom.RandIntInRange(1, 3))); // Value important for Test.
        ProdOrderCapacityNeed.CalcSums("Needed Time");
        exit(ProdOrderCapacityNeed."Needed Time");
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity);
        ItemJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking on Page Handler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10]; InTransit: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
        TransferRoute.Validate("In-Transit Code", InTransit);
        TransferRoute.Modify(true);
    end;

    local procedure UpdateTrackingCodeOnItem(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure UpdatePlanningParametersOnItem(var Item: Record Item)
    var
        ReschedulePeriod: DateFormula;
        LotAccumulationPeriod: DateFormula;
    begin
        Evaluate(ReschedulePeriod, '<1W>');
        Evaluate(LotAccumulationPeriod, '<1W>');
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Validate("Rescheduling Period", ReschedulePeriod);
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriod);
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandInt(5) + 5);  // Random Value required.
        Item.Modify(true);
    end;

    local procedure UpdateManufacturingSetup(NewDocNoIsProdOrderNo: Boolean) DocNoIsProdOrderNo: Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        DocNoIsProdOrderNo := ManufacturingSetup."Doc. No. Is Prod. Order No.";
        ManufacturingSetup.Validate("Doc. No. Is Prod. Order No.", NewDocNoIsProdOrderNo);
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateMultipleStockKeepingUnit(ItemNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Item.SetFilter("Location Filter", '%1|%2', LocationCode, LocationCode2);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
    end;

    local procedure SetReplSystemTransferOnSKU(LocationCode: Code[10]; ItemNo: Code[20]; TransferFrom: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFrom);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateAndPostTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure CreateAndUpdateVariantCodeOnProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ProdOrderLine."Item No.");
        ProdOrderLine.Validate("Variant Code", ItemVariant.Code);
        ProdOrderLine.Modify(true);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    begin
        FilterProdOrderLine(ProdOrderLine, Status, ProductionOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure SetupProdOrdWithRtng(var ProdOrd: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        LineQuantity: array[2] of Decimal;
    begin
        LineQuantity[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        LineQuantity[2] := LibraryRandom.RandDecInRange(30, 40, 2);
        LibraryManufacturing.CreateProductionOrder(
          ProdOrd, ProdOrd.Status::Released, ProdOrd."Source Type"::Item, ItemNo,
          LineQuantity[1] + LineQuantity[2]);

        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrd.Status, ProdOrd."No.", ItemNo, '', '', LineQuantity[1]);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrd.Status, ProdOrd."No.", ItemNo, '', '', LineQuantity[2]);
        LibraryManufacturing.RefreshProdOrder(ProdOrd, false, false, true, false, false); // Do not recalculate lines when refreshing the order
    end;

    local procedure SetupProdOrdLnWithSubContr(var ProdOrdLn: Record "Prod. Order Line")
    var
        ProdOrd: Record "Production Order";
        ReqLn: Record "Requisition Line";
        WorkCtr: Record "Work Center";
    begin
        CreateProdOrderWithSubcontractWorkCenter(WorkCtr, ProdOrd);
        CalculateSubcontractOrder(ReqLn, WorkCtr."No.", ProdOrd);

        LibraryPlanning.CarryOutAMSubcontractWksh(ReqLn);
        FindProdOrderLine(ProdOrdLn, ProdOrd.Status, ProdOrd."No.");
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure UpdateExpectedReceiptDateOnPurchaseLinesPage(BuyFromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.Validate("Due Date", PurchaseHeader."Posting Date");
        PurchaseHeader.Modify(true);
        Clear(PurchaseOrder);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseOrder.PurchLines."Expected Receipt Date".SetValue(
          CalcDate(StrSubstNo('%1D', LibraryRandom.RandInt(5)), PurchaseHeader."Due Date"));
        PurchaseOrder.Close();
    end;

    local procedure UpdateVendorItemNoOnItem(var Item: Record Item; VendorItemNo: Text[20])
    begin
        Item.Validate("Vendor Item No.", VendorItemNo);
        Item.Modify(true);
    end;

    local procedure UpdateVendorItemNoOnSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; VendorItemNo: Text[20])
    begin
        StockkeepingUnit.Validate("Vendor Item No.", VendorItemNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure PostItemStockPurchase(Item: Record Item; Quantity: Decimal; LocationCode: Code[10]; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType,
          Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure VerifyDueDate(ProductionOrder: Record "Production Order"; DueDate: Date; ShouldBeEqual: Boolean)
    begin
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        if ShouldBeEqual then
            Assert.AreEqual(DueDate, ProductionOrder."Due Date", WrongDueDateErr)
        else
            Assert.AreNotEqual(DueDate, ProductionOrder."Due Date", WrongDueDateErr)
    end;

    local procedure VerifyUntrackedPlanningElement(ItemNo: Code[20]; Source: Text[200]; ParameterValue: Decimal; UntrackedQuantity: Decimal)
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
    begin
        UntrackedPlanningElement.SetRange("Item No.", ItemNo);
        UntrackedPlanningElement.SetRange(Source, Source);
        UntrackedPlanningElement.FindFirst();
        UntrackedPlanningElement.TestField("Parameter Value", ParameterValue);
        UntrackedPlanningElement.TestField("Untracked Quantity", UntrackedQuantity);
        UntrackedPlanningElement.TestField(Source, Source);
    end;

    local procedure VerifyRequisitionLine(Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.AreEqual(1, RequisitionLine.Count, PlanningLinesErr);
        RequisitionLine.TestField(Quantity, Item."Reorder Quantity");
        RequisitionLine.TestField("Due Date", LibraryPlanning.SetSafetyWorkDate());
    end;

    local procedure VerifyQuantityRequisitionLine(RequisitionLine: Record "Requisition Line"; Quantity: Decimal; DueDate: Date)
    begin
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Due Date", DueDate);
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::New);
    end;

    local procedure VerifyPlanningComponent(PlanningComponent: Record "Planning Component"; ExpectedQuantity: Decimal; DueDate: Date)
    begin
        PlanningComponent.TestField("Expected Quantity", ExpectedQuantity);
        PlanningComponent.TestField("Due Date", DueDate);
    end;

    local procedure VerifyReservationEntry(Item: Record Item)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", Item."No.");
        Assert.AreEqual(1, ReservationEntry.Count, ReservationEntriesErr);  // Value is important for Test.
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", Item."Reorder Quantity");
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
    end;

    local procedure VerifyProdOrderComponent(SourceNo: Code[20]; ItemNo: Code[20]; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();

        FilterProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField("Item No.", ItemNo);
        ProdOrderComponent.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        ProdOrderComponent.TestField("Shortcut Dimension 2 Code", ShortcutDimension2Code)
    end;

    local procedure VerifyProdOrderComponentQuantity(SourceNo: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();

        FilterProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField("Item No.", ItemNo);
        ProdOrderComponent.TestField(Quantity, ExpectedQuantity);
    end;

    local procedure VerifyDateAndQuantityReqLine(Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionLineQuantity: Decimal;
        Counter: Integer;
    begin
        // Calculation for Requisition Line Quantity.
        while (RequisitionLineQuantity < Item."Maximum Inventory") do begin
            RequisitionLineQuantity := Item."Order Multiple" * Counter;
            Counter += 1;
        end;

        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        RequisitionLine.TestField(Quantity, RequisitionLineQuantity);
        InventorySetup.Get();
        RequisitionLine.TestField(
          "Due Date", CalcDate(InventorySetup."Default Safety Lead Time", CalcDate(Item."Lead Time Calculation", WorkDate())));
    end;

    local procedure VerifyValueInRequisitionLine(Item: Record Item; Quantity: Decimal; OrderDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Due Date", CalcDate(Item."Lead Time Calculation", WorkDate()));
        InventorySetup.Get();
        RequisitionLine.TestField(
          "Order Date", CalcDate('<' + '-' + Format(InventorySetup."Default Safety Lead Time") + '>', OrderDate));
    end;

    local procedure VerifyPlanningRoutingLine(RoutingHeader: Record "Routing Header"; RequisitionWkshName: Record "Requisition Wksh. Name"; ItemNo: Code[20]; Quantity: Integer)
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
        PlanningComponent: Record "Planning Component";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        SelectWorkCenter(WorkCenter, RoutingHeader."No.");
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindFirst();

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionWkshName.Name);
        PlanningComponent.FindFirst();
        PlanningComponent.TestField("Item No.", ItemNo);
        PlanningComponent.TestField(Quantity, Quantity);  // Value is important for Test.

        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionWkshName.Name);
        PlanningRoutingLine.FindFirst();
        PlanningRoutingLine.TestField("Operation No.", RoutingLine."Operation No.");
        PlanningRoutingLine.TestField(Type, PlanningRoutingLine.Type::"Work Center");
        PlanningRoutingLine.TestField("Work Center No.", WorkCenter."No.");
        PlanningRoutingLine.TestField("Run Time", RoutingLine."Run Time");
    end;

    local procedure VerifyProdOrderRoutingLineIsNotEmpty(RoutingNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        Assert.RecordIsNotEmpty(ProdOrderRoutingLine);
    end;

    local procedure VerifyBOMHeaderLLC(No: Code[20]; LowLevelCode: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Get(No);
        ProductionBOMHeader.TestField("Low-Level Code", LowLevelCode);
    end;

    local procedure VerifyRunTime(OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandDec(10, 2));
    end;

    local procedure VerifyCapacityLedgerEntry(WorkCenter: Record "Work Center"; Quantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenter."No.");
        Assert.AreEqual(1, CapacityLedgerEntry.Count, NumberOfLineErr);
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntry.CalcFields("Direct Cost");
        CapacityLedgerEntry.TestField("Direct Cost", Quantity * WorkCenter."Direct Unit Cost");
    end;

    local procedure VerifyDimensions(JnlLineDimSetID: Integer; NoOfDimensions: Integer; DimCodes: Text[250]; DimValueCodes: Text[250])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        I: Integer;
    begin
        if JnlLineDimSetID > 0 then
            DimensionSetEntry.SetRange("Dimension Set ID", JnlLineDimSetID);
        Assert.AreEqual(NoOfDimensions, DimensionSetEntry.Count, NoDimensionExpectedErr);

        if NoOfDimensions > 0 then
            for I := 1 to NoOfDimensions do begin
                DimensionSetEntry.SetRange("Dimension Code", SelectStr(I, DimCodes));
                DimensionSetEntry.FindFirst();
                Assert.AreEqual(SelectStr(I, DimValueCodes), DimensionSetEntry."Dimension Value Code", DimensionValueErr);
            end;
    end;

    local procedure VerifyDimensionValuesInItemJournal(DimensionValue: array[4] of Record "Dimension Value"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        i: Integer;
    begin
        for i := 2 to 3 do begin
            DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
            DimensionSetEntry.SetRange("Dimension Code", DimensionValue[i]."Dimension Code");
            DimensionSetEntry.FindFirst();
            Assert.AreEqual(
              DimensionValue[i].Code, DimensionSetEntry."Dimension Value Code", StrSubstNo(DimensionValueOutputErr, DimensionValue[i].Code));
        end;
    end;

    local procedure VerifyRequisitionLineForUser(UserID: Code[50]; DemandOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("User ID", UserID);
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange("Worksheet Template Name", '');
        Assert.AreEqual(2, RequisitionLine.Count, NumberOfLineErr);
        RequisitionLine.FindLast();
        RequisitionLine.TestField("No.", ItemNo);
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRequisitionLineDetails(Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.FindSet();
        InventorySetup.Get();
        VerifyQuantityRequisitionLine(
          RequisitionLine, Item."Reorder Quantity", CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
        RequisitionLine.Next();
        VerifyQuantityRequisitionLine(RequisitionLine, Item."Safety Stock Quantity", WorkDate());
    end;

    local procedure VerifyPlanningComponentDetails(Item: Record Item; Item2: Record Item; QuantityPer: Decimal)
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Item No.", Item2."No.");
        PlanningComponent.FindSet();
        VerifyPlanningComponent(PlanningComponent, Item."Reorder Quantity" * QuantityPer, WorkDate());
        PlanningComponent.Next();
        InventorySetup.Get();
        VerifyPlanningComponent(
          PlanningComponent, Item."Safety Stock Quantity" * QuantityPer,
          CalcDate('<' + '-' + Format(InventorySetup."Default Safety Lead Time") + '>', WorkDate()));
    end;

    local procedure VerifyMultipleRequisitionLine(Item: Record Item; Item2: Record Item; QuantityPer: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", Item2."No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.FindSet();
        InventorySetup.Get();
        VerifyQuantityRequisitionLine(
          RequisitionLine, Item."Safety Stock Quantity" * QuantityPer,
          CalcDate('<' + '-' + Format(InventorySetup."Default Safety Lead Time") + '>', WorkDate()));
        RequisitionLine.Next();
        VerifyQuantityRequisitionLine(
          RequisitionLine, Item2."Maximum Inventory" - Item2."Safety Stock Quantity",
          CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
        RequisitionLine.Next();
        VerifyQuantityRequisitionLine(RequisitionLine, Item."Reorder Quantity" * QuantityPer + Item2."Safety Stock Quantity", WorkDate());
    end;

    local procedure VerifyPurchaseLine(BuyFromVendorNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        Assert.AreEqual(1, PurchaseLine.Count, NumberOfLineErr);  // Value is important for Test.
        PurchaseLine.FindLast();
        PurchaseLine.TestField("No.", No);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyEarliestShipmentDate(ExpectedDate: Date; TempOrderPromisingLine: Record "Order Promising Line" temporary)
    begin
        Assert.AreEqual(
          ExpectedDate,
          TempOrderPromisingLine."Earliest Shipment Date",
          StrSubstNo(
            FieldErr,
            TempOrderPromisingLine.TableCaption(),
            TempOrderPromisingLine.FieldCaption("Earliest Shipment Date")));
    end;

    local procedure VerifyProdOrderComponentDetails(Item: Record Item; ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Verify Component Line is refreshed after updating Item No.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder, Item."No.");
        ProdOrderComponent.TestField("Unit of Measure Code", Item."Base Unit of Measure");
        ProdOrderComponent.TestField(Length, 0);
        ProdOrderComponent.TestField("Calculation Formula", ProdOrderComponent."Calculation Formula"::" ");
    end;

    local procedure VerifyProdOrderLine(ProdOrderNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FilterProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Finished, ProdOrderNo);
        ProdOrderLine.SetRange("Variant Code", VariantCode);
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField("Item No.", ItemNo);
        ProdOrderLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyProdOrderLineForStartingDateTime(ProductionOrderNo: Code[20]; ProdOrderStartingDateTime: DateTime)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FilterProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrderNo);
        ProdOrderLine.FindSet();
        repeat
            Assert.IsTrue(ProdOrderStartingDateTime <= ProdOrderLine."Starting Date-Time", StartingDateTimeErr);
        until ProdOrderLine.Next() = 0;
    end;

    local procedure VerifyProdOrderCapacityNeed(WorkCenterNo: Code[20])
    var
        ActualTime: Decimal;
    begin
        ActualTime := CapacityEffectiveOnCalendarEntry(WorkCenterNo) - NeededTimeOnProdOrderCapacityNeed(WorkCenterNo);
        Assert.AreEqual(0, ActualTime, EffectiveCapacityErr);
    end;

    local procedure VerifyQuantityOnRequisitionLine(ItemNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System"; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Replenishment System", ReplenishmentSystem);
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyCountForProductionOrderComponent(ProdOrderNo: Code[20]; ProductionBOMNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        FilterProdOrderComponent(ProdOrderComponent, ProdOrderComponent.Status::Released, ProdOrderNo);
        Assert.AreEqual(
          ProductionBOMLine.Count, ProdOrderComponent.Count,
          StrSubstNo(ErrorMsg, ProductionBOMLine.TableCaption(), ProdOrderComponent.TableCaption()));
    end;

    local procedure VerifyCountForProductionOrderRouting(ProdOrderNo: Code[20]; RoutingNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        FilterProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine.Status::Released, ProdOrderNo);
        Assert.AreEqual(
          RoutingLine.Count, ProdOrderRoutingLine.Count, StrSubstNo(ErrorMsg, ProdOrderRoutingLine.TableCaption(), RoutingLine.TableCaption()));
    end;

    local procedure VerifyQtyOnProdOrder(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        FamilyLine: Record "Family Line";
    begin
        // Check Quantity on Firm Planned Production Order Line is the product of the quantity on the Production Order Header and the quantity on the Family Line.
        FamilyLine.SetRange("Family No.", ProductionOrder."Source No.");
        FamilyLine.FindSet();
        repeat
            FilterProdOrderLine(ProdOrderLine, ProdOrderLine.Status::"Firm Planned", ProductionOrder."No.");
            ProdOrderLine.SetRange("Item No.", FamilyLine."Item No.");
            ProdOrderLine.FindFirst();
            ProdOrderLine.TestField(Quantity, (ProductionOrder.Quantity * FamilyLine.Quantity));
        until FamilyLine.Next() = 0;
    end;

    local procedure VerifyRequisitionLineForLocation(ItemNo: Code[20]; LocationCode: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Variant Code", '');
        RequisitionLine.SetRange("Location Code", LocationCode);
        Assert.AreEqual(2, RequisitionLine.Count, NumberOfLineErr);  // Value requried.
    end;

    local procedure VerifyProdOrderRequisitionLine(ProdOrderLine: Record "Prod. Order Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        RequisitionLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        RequisitionLine.FindFirst();

        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        RequisitionLine.TestField("No.", ProdOrderLine."Item No.");
        RequisitionLine.TestField(Quantity, ProdOrderLine.Quantity);
        RequisitionLine.TestField("Replenishment System", RequisitionLine."Replenishment System"::"Prod. Order");
    end;

    local procedure VerifyItemLedgerEntryForOutput(ItemNo: Code[20]; Quantity: Decimal; EntryType: Enum "Item Ledger Document Type")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Entry Type", EntryType);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntryForConsumption(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Entry Type", EntryType);
    end;

    local procedure VerifyRequisitionLineDueDates(ComponentItemNo: Code[20]; ParentItemFilter: Text; QtyPer: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
        TotalQty: Decimal;
        StartingDate: Date;
        StartingTime: Time;
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetFilter("No.", ParentItemFilter);
        RequisitionLine.FindSet();
        StartingDate := RequisitionLine."Starting Date";
        StartingTime := RequisitionLine."Starting Time";
        repeat
            TotalQty += RequisitionLine.Quantity * QtyPer;
        until RequisitionLine.Next() = 0;

        RequisitionLine.SetRange("No.", ComponentItemNo);
        RequisitionLine.SetRange("Ending Date", StartingDate);
        RequisitionLine.SetRange("Ending Time", StartingTime);
        RequisitionLine.FindFirst();
        Assert.AreEqual(TotalQty, RequisitionLine.Quantity, IncorrectQtyOnEndingDateErr);
    end;

    local procedure VerifyCommentForProdOrderComponent(ProductionOrderNo: Code[20]; CommentText: Text[80])
    var
        ProdOrderCompCmtLine: Record "Prod. Order Comp. Cmt Line";
    begin
        ProdOrderCompCmtLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderCompCmtLine.SetRange(Comment, CommentText);
        Assert.RecordIsNotEmpty(ProdOrderCompCmtLine);
    end;

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProductionJournalMgt.InitSetupValues();
        ProductionJournalMgt.SetTemplateAndBatchName();
        ProductionJournalMgt.CreateJnlLines(ProductionOrder, ProdOrderLine."Line No.");
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Document No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Flushing Method", ItemJournalLine."Flushing Method"::Manual);
        ItemJournalLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    local procedure CreateCertifiedRoutingForWorkCenter(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RoutingLinkCode: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenterNo, LibraryUtility.GenerateGUID(), 0, 10);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateProdItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; RoutingNo: Code[20]; ProdBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Production BOM No.", ProdBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CreateProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; QtyPer: Decimal; ItemNo: Code[20]; ItemUoMCode: Code[10]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QtyPer);
        ProductionBOMLine.Validate("Unit of Measure Code", ItemUoMCode);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify();
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateCompItem(var Item: Record Item; FlushingType: Enum "Flushing Method"; RoundPrecision: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Flushing Method", FlushingType);
        Item.Validate("Rounding Precision", RoundPrecision);
        Item.Modify(true);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Positive: Boolean; Quantity: Decimal; RemainingQty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, Positive);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQty);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Positive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, Positive);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure CreateMultipleSubcontractingSetup(
    var WorkCenter: array[2] of Record "Work Center";
    var RoutingHeader: Record "Routing Header";
    var OperationNo: array[2] of Code[10]
    )
    var
        WorkCenterNo: array[2] of Code[20];
        RoutingHeaderNo: Code[20];
    begin
        Create2WorkCenter(WorkCenter, WorkCenterNo);
        CreateRoutingWithSequentialOperations(WorkCenterNo, OperationNo, RoutingHeaderNo);
        RoutingHeader.Get(RoutingHeaderNo);
    end;

    local procedure Create2WorkCenter(var WorkCenter: array[2] of Record "Work Center"; var WorkCenterNo: array[2] of Code[20])
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Vendor: Record Vendor;
        i: Integer;
    begin
        LibraryPurchase.CreateSubcontractor(Vendor);
        CreateWorkCenterSetup(WorkCenter[1], CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        CreateWorkCenterSetup(WorkCenter[2], CapacityUnitOfMeasure.Type::Minutes, 160000T, 235959T);
        for i := 1 to ArrayLen(WorkCenter) do begin
            WorkCenterNo[i] := WorkCenter[i]."No.";
            WorkCenter[i].Validate("Unit Cost Calculation", WorkCenter[i]."Unit Cost Calculation"::Time);
            WorkCenter[i].Validate("Subcontractor No.", Vendor."No.");
            WorkCenter[i].Modify(true);
        end;
    end;

    local procedure CreateRoutingWithSequentialOperations(
        WorkCenterNo: array[2] of Code[20];
        var OperationNo: array[2] of Code[10];
        var RoutingHeaderNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo[2]);
        OperationNo[1] := RoutingLine."Operation No.";
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo[1]);
        OperationNo[2] := RoutingLine."Operation No.";
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        RoutingHeaderNo := RoutingHeader."No.";
    end;

    local procedure VerifyOperationNoOnRequisitionLineForProductionOrder(
        ProductionOrder: Record "Production Order";
        OperationNo: array[2] of Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("No.", ProductionOrder."Source No.");
        RequisitionLine.SetRange("Ref. Order Status", ProductionOrder.Status);
        RequisitionLine.SetRange("Ref. Order No.", ProductionOrder."No.");
        RequisitionLine.FindSet();

        Assert.AreEqual(OperationNo[1], RequisitionLine."Operation No.", StrSubstNo(OperationNoErr, OperationNo[1]));
        RequisitionLine.Next();
        Assert.AreEqual(OperationNo[2], RequisitionLine."Operation No.", StrSubstNo(OperationNoErr, OperationNo[1]));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LineCount: Integer;
    begin
        // Assign Serial no based on requirments.
        case ItemTracking of
            ItemTracking::AssignSerial:
                ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
            ItemTracking::SelectSerial:
                begin
                    ItemTrackingLines."Select Entries".Invoke();  // Open Item Tracking Summary for Select Line.
                    ItemTrackingLines.OK().Invoke();
                end;
            ItemTracking::VerifyValue: // Using For Transfer Receipt.
                begin
                    ItemTrackingLines.Last();
                    repeat
                        ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(1);  // For Serial No.
                        LineCount += 1;
                    until not ItemTrackingLines.Previous();
                    Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineErr);  // Verify Number of line Tracking Line.
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(AreSameMessages(Message, ReleasedProdOrderTxt), Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);
        TrackingOption := OptionValue;
        case TrackingOption of
            TrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ChangeStatusOnProdOrder(var ChangeStatusonProductionOrder: TestPage "Change Status on Prod. Order")
    var
        ProductionOrder: Record "Production Order";
    begin
        ChangeStatusonProductionOrder.FirmPlannedStatus.SetValue(ProductionOrder.Status::Released);
        ChangeStatusonProductionOrder.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionBOMPageHandler(var ProductionBOM: TestPage "Production BOM")
    begin
        ProductionBOM."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    procedure ChangeStatusOnProdOrderToFinished(var ChangeStatusonProductionOrder: TestPage "Change Status on Prod. Order")
    var
        ProductionOrder: Record "Production Order";
    begin
        ChangeStatusonProductionOrder.FirmPlannedStatus.SetValue(ProductionOrder.Status::Finished);
        ChangeStatusonProductionOrder.Yes().Invoke();
    end;

    [ModalPageHandler]
    procedure ErrorMessageHandler(var ErrorMessage: TestPage "Error Messages")
    begin
        ErrorMessage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable
        Assert.IsTrue(AreSameMessages(Question, ExpectedMessage), Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderComponentsHandler(var ProdOrderComponents: TestPage "Prod. Order Components")
    begin
        ProdOrderComponents.ItemTrackingLines.Invoke();
        ProdOrderComponents.OK().Invoke();
    end;

    local procedure GetShopCalendarCodeForProductionOrder(ProductionOrder: Record "Production Order"): Code[10]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        ShopCalendar: Record "Shop Calendar";
    begin
        ProdOrderRoutingLine.SetCurrentKey("Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        if not ProdOrderRoutingLine.FindFirst() then
            exit;

        if not WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then
            exit;

        if ShopCalendar.Get(WorkCenter."Shop Calendar Code") then
            exit(ShopCalendar.Code);
    end;

    local procedure CheckShopCalendarWorkingDay(ShopCalendarCode: Code[10]; WorkingDate: Date): Boolean
    var
        Date: Record Date;
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetRange("Period Start", WorkingDate);
        Date.FindFirst();

        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);
        ShopCalendarWorkingDays.SetRange(Day, Date."Period No." - 1);
        exit(not ShopCalendarWorkingDays.IsEmpty());
    end;

    local procedure VerifyVarinetOfProdOrderLineAndProductionOrder(ProdOrderLine: Record "Prod. Order Line"; Component: Record Item; ProductionOrder: Record "Production Order"; ItemVariant: Record "Item Variant")
    begin
        // Verify: Verify Variant Code on Production Order Line.
        ProdOrderLine.SetRange("Item No.", Component."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.TestField("Variant Code", ItemVariant.Code);

        // Verify: Verify Variant Code on Production Order.
        ProductionOrder.SetRange("Source No.", Component."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Variant Code", ItemVariant.Code);
    end;

    local procedure CreateProductionBOMWithTwoCoponentAndCertify(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; ChildItemNo: Code[20]; ChildItemNo2: Code[20]; QuantityPer: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo, QuantityPer);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo2, 0);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure VerifyPlanningComponentWithZeroQuantityPer(ChildItem2: Record Item)
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Item No.", ChildItem2."No.");
        PlanningComponent.FindFirst();
        Assert.AreEqual(0, PlanningComponent."Quantity per", '');
    end;

    local procedure CreateMultipleItem(var Item: array[4] of Record Item)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Item) do
            LibraryInventory.CreateItem(Item[i]);
    end;

    local procedure MakeMultipleProductionItem(var Item: array[4] of Record Item; var ProductionBOMHeader: array[2] of Record "Production BOM Header")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ProductionBOMHeader) do begin
            Item[i].Validate("Replenishment System", Item[i]."Replenishment System"::"Prod. Order");
            Item[i].Validate("Manufacturing Policy", Item[i]."Manufacturing Policy"::"Make-to-Order");
            Item[i].Validate("Production BOM No.", ProductionBOMHeader[i]."No.");
            Item[i].Modify(true);
        end;
    end;

    local procedure GenerateQtys(var QuantityPer: array[6] of Integer)
    begin
        QuantityPer[1] := LibraryRandom.RandInt(0);
        QuantityPer[2] := LibraryRandom.RandInt(0);
        QuantityPer[3] := -LibraryRandom.RandInt(0);
        QuantityPer[4] := -LibraryRandom.RandInt(0);
        QuantityPer[5] := -LibraryRandom.RandInt(0);
        QuantityPer[6] := LibraryRandom.RandInt(0) - 1;
    end;

    local procedure CreateProductionBOMWithSixComponentAndCertify(
        var ProductionBOMHeader: Record "Production BOM Header";
        BaseUnitOfMeasure: Code[10];
        Type: Enum "Production BOM Line Type";
        ChildItemNo: array[6] of Code[20];
        QuantityPer: array[6] of Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo[1], QuantityPer[1]);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo[2], QuantityPer[2]);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo[3], QuantityPer[3]);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo[4], QuantityPer[4]);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo[5], QuantityPer[5]);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ChildItemNo[6], QuantityPer[6]);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure VerifyProdOrderComponentQuantities(SourceNo: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();

        FindProdOrderComponent(ProdOrderComponent, ProductionOrder, ItemNo);
        Assert.AreEqual(
            ExpectedQuantity,
            ProdOrderComponent."Quantity per",
            StrSubstNo(
                QuanityPerErrorLbl,
                ProdOrderComponent.FieldCaption("Quantity per"),
                ExpectedQuantity,
                ProdOrderComponent.TableCaption()));
    end;

    local procedure CreateFamilyLines(
        Family: Record Family;
        Item: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
        UnitOfMeasure3: Record "Unit of Measure";
        UnitOfMeasure4: Record "Unit of Measure")
    var
        FamilyLine: array[5] of Record "Family Line";
    begin
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item."No.", LibraryRandom.RandIntInRange(6, 6));
        FamilyLine[1].Validate("Unit of Measure Code", UnitOfMeasure2.Code);
        FamilyLine[1].Modify(true);

        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item2."No.", LibraryRandom.RandIntInRange(3, 3));
        FamilyLine[2].Validate("Unit of Measure Code", UnitOfMeasure4.Code);
        FamilyLine[2].Modify(true);

        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item."No.", LibraryRandom.RandIntInRange(4, 4));
        FamilyLine[3].Validate("Unit of Measure Code", UnitOfMeasure.Code);
        FamilyLine[3].Modify(true);

        LibraryManufacturing.CreateFamilyLine(FamilyLine[4], Family."No.", Item."No.", LibraryRandom.RandIntInRange(6, 6));
        FamilyLine[4].Validate("Unit of Measure Code", UnitOfMeasure3.Code);
        FamilyLine[4].Modify(true);
    end;

    local procedure CreateBOMVersionAndClosed(
        ParentItem: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header")
    begin
        CreateBOMVersionUsingCopyBOM(ParentItem."Base Unit of Measure", ProductionBOMVersion, ProductionBOMHeader, Format(LibraryRandom.RandInt(0)));
        AddProductionBOMLine(ProductionBOMHeader, ProductionBOMVersion, ParentItem."No.");
        UpdateStatusOnProductionBOMVersion(ProductionBOMVersion, ProductionBOMVersion.Status::Closed);
    end;

    local procedure CreateBOMVersionUsingCopyBOM(
        BaseUnitOfMeasure: Code[10];
        var ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header"; VersionCode: Code[20])
    var
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, ProductionBOMHeader."No.",
            VersionCode, BaseUnitOfMeasure);
        ProductionBOMCopy.CopyBOM(
            ProductionBOMVersion."Production BOM No.", '',
            ProductionBOMHeader, ProductionBOMVersion."Version Code");
    end;

    local procedure AddProductionBOMLine(ProductionBOMHeader: Record "Production BOM Header"; ProductionBOMVersion: Record "Production BOM Version"; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code",
            ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandInt(0));
    end;

    local procedure UpdateStatusOnProductionBOMVersion(var ProductionBOMVersion: Record "Production BOM Version"; Status: Enum "BOM Status")
    begin
        ProductionBOMVersion.Validate(Status, Status);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure FindProductionBOMLine(
        ProductionBOMHeader: Record "Production BOM Header"; ProductionBOMVersion: Record "Production BOM Version";
        ItemNo: Code[20]; var ProductionBOMLine: Record "Production BOM Line");
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("Version Code", ProductionBOMVersion."Version Code");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemNo);
        ProductionBOMLine.FindLast();
    end;

    local procedure UpdateProductionBOMLineByField(var ProductionBOMLine: Record "Production BOM Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(ProductionBOMLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(ProductionBOMLine);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateProductionBOMWithStartingEndingDate(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityPer: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLine2: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, ItemNo, QuantityPer);
        ProductionBOMLine."Starting Date" := CalcDate('<-1M>', WorkDate());
        ProductionBOMLine."Ending Date" := CalcDate('<-1M+15D>', WorkDate());
        ProductionBOMLine.Modify();
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine2, '', Type, ItemNo2, QuantityPer);
        ProductionBOMLine2."Starting Date" := CalcDate('<-1M+16D>', WorkDate());
        ProductionBOMLine2."Ending Date" := CalcDate('<5D>', WorkDate());
        ProductionBOMLine2.Modify();
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateRoutingWithMultipleRoutingLine(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; Type: Option; RoutingLineType: Enum "Capacity Type Routing")
    var
        RoutingLine: array[3] of Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, Type);
        CreateRoutingLineWithRunTimeSetupTime(RoutingHeader, RoutingLine[1], WorkCenterNo, RoutingLineType);
        CreateRoutingLineWithRunTimeSetupTime(RoutingHeader, RoutingLine[2], WorkCenterNo, RoutingLineType);
        CreateRoutingLineWithRunTimeSetupTime(RoutingHeader, RoutingLine[3], WorkCenterNo, RoutingLineType);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingLineWithRunTimeSetupTime(RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20]; RoutingLineType: Enum "Capacity Type Routing")
    var
        OperationNo: Code[10];
    begin
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLineType, WorkCenterNo);
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(50));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(50));
        RoutingLine.Modify(true);
    end;
}
