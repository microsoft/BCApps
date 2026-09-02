// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 139982 "Subc. Pricing Test"
{
    // [FEATURE] Subcontracting Pricing
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
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
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateSubcontractorPrice(Item, WorkCenter[2]."No.", SubcontractorPrice);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

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
    procedure CreatedSubcPurchLineUsesPriceForBackwardScheduledOrderDate()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        EarlierPrice: Decimal;
        LaterPrice: Decimal;
    begin
        // [SCENARIO 648535] A new subcontracting purchase line uses the price valid on its backward-scheduled order date
        Initialize();

        // [GIVEN] A subcontracting operation with adjacent prices before and from WorkDate
        CreateDateEffectiveSubcontractingScenario(Item, ProductionOrder, ProdOrderRoutingLine, EarlierPrice, LaterPrice);

        // [WHEN] A purchase order is created for the subcontracting operation
        CreateSubcontractingPurchaseLine(PurchaseLine, ProdOrderRoutingLine, Item."No.", ProductionOrder."No.");

        // [THEN] The purchase line uses the earlier price valid on its backward-scheduled order date
        Assert.IsTrue(PurchaseLine."Order Date" < WorkDate(), 'The purchase line order date must be backward-scheduled before WorkDate.');
        Assert.AreEqual(EarlierPrice, PurchaseLine."Direct Unit Cost", 'The purchase line must use the subcontractor price valid on its order date.');
    end;

    [Test]
    procedure ExpectedReceiptDateChangeRepricesBackwardScheduledSubcPurchLine()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        NewExpectedReceiptDate: Date;
        EarlierPrice: Decimal;
        LaterPrice: Decimal;
    begin
        // [SCENARIO 648535] Rescheduling a subcontracting purchase line reapplies the date-effective price
        Initialize();

        // [GIVEN] A backward-scheduled subcontracting purchase line using the price valid before WorkDate
        CreateDateEffectiveSubcontractingScenario(Item, ProductionOrder, ProdOrderRoutingLine, EarlierPrice, LaterPrice);
        CreateSubcontractingPurchaseLine(PurchaseLine, ProdOrderRoutingLine, Item."No.", ProductionOrder."No.");
        SubcPriceManagement.GetSubcPriceForPurchLine(PurchaseLine);
        Assert.AreEqual(EarlierPrice, PurchaseLine."Direct Unit Cost", 'The purchase line must initially use the earlier subcontractor price.');
        NewExpectedReceiptDate := CalcDate('<20D>', WorkDate());

        // [WHEN] Expected Receipt Date is moved so Planned Receipt Date backward-schedules Order Date into the later price period
        PurchaseLine.Validate("Expected Receipt Date", NewExpectedReceiptDate);

        // [THEN] The purchase line uses the later price valid on its rescheduled order date
        Assert.IsTrue(PurchaseLine."Order Date" >= WorkDate(), 'The rescheduled purchase line order date must be on or after WorkDate.');
        Assert.AreEqual(LaterPrice, PurchaseLine."Direct Unit Cost", 'The purchase line must use the subcontractor price valid on its rescheduled order date.');
    end;

    [Test]
    procedure PlannedReceiptDateChangeRepricesSubcPurchLine()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        NewPlannedReceiptDate: Date;
        EarlierPrice: Decimal;
        LaterPrice: Decimal;
    begin
        // [SCENARIO 648535] Changing Planned Receipt Date directly reapplies the price for the resulting order date
        Initialize();

        // [GIVEN] A backward-scheduled subcontracting purchase line using the price valid before WorkDate
        CreateDateEffectiveSubcontractingScenario(Item, ProductionOrder, ProdOrderRoutingLine, EarlierPrice, LaterPrice);
        CreateSubcontractingPurchaseLine(PurchaseLine, ProdOrderRoutingLine, Item."No.", ProductionOrder."No.");
        SubcPriceManagement.GetSubcPriceForPurchLine(PurchaseLine);
        Assert.AreEqual(EarlierPrice, PurchaseLine."Direct Unit Cost", 'The purchase line must initially use the earlier subcontractor price.');
        NewPlannedReceiptDate := CalcDate('<20D>', WorkDate());

        // [WHEN] Planned Receipt Date is changed directly
        PurchaseLine.Validate("Planned Receipt Date", NewPlannedReceiptDate);

        // [THEN] The purchase line uses the later price valid on the resulting order date
        Assert.IsTrue(PurchaseLine."Order Date" >= WorkDate(), 'The resulting purchase line order date must be on or after WorkDate.');
        Assert.AreEqual(LaterPrice, PurchaseLine."Direct Unit Cost", 'The purchase line must use the subcontractor price valid on the resulting order date.');
    end;

    [Test]
    procedure OrderDateChangeRepricesSubcPurchLine()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        EarlierPrice: Decimal;
        LaterPrice: Decimal;
    begin
        // [SCENARIO 648535] Changing a subcontracting purchase line order date reapplies the date-effective price
        Initialize();

        // [GIVEN] A backward-scheduled subcontracting purchase line using the price valid before WorkDate
        CreateDateEffectiveSubcontractingScenario(Item, ProductionOrder, ProdOrderRoutingLine, EarlierPrice, LaterPrice);
        CreateSubcontractingPurchaseLine(PurchaseLine, ProdOrderRoutingLine, Item."No.", ProductionOrder."No.");
        SubcPriceManagement.GetSubcPriceForPurchLine(PurchaseLine);
        Assert.AreEqual(EarlierPrice, PurchaseLine."Direct Unit Cost", 'The purchase line must initially use the earlier subcontractor price.');

        // [WHEN] Order Date is changed to WorkDate
        PurchaseLine.Validate("Order Date", WorkDate());

        // [THEN] The purchase line uses the later price valid from WorkDate
        Assert.AreEqual(LaterPrice, PurchaseLine."Direct Unit Cost", 'The purchase line must use the subcontractor price valid on its changed order date.');
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
    procedure StandardTaskCodePropagatedAndDrivesSubcPriceLookup()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionLineWithStdTask: Record "Requisition Line";
        RequisitionLineNoStdTask: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        StandardTask: Record "Standard Task";
        SubcontractorPrice: Record "Subcontractor Price";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        LibraryUtility: Codeunit "Library - Utility";
        PriceWithoutStdTask: Decimal;
        PriceWithStdTask: Decimal;
        SecondOperationNo: Code[10];
    begin
        // [SCENARIO 633226] Standard Task Code propagates from Routing → Prod. Order Routing → Subcontracting Worksheet,
        // is editable on the worksheet, and drives Subcontractor Price lookup. Editing or clearing it on a worksheet
        // line re-applies the matching subcontractor price; carrying out creates Purchase Lines with the correct unit costs.

        Initialize();

        // [GIVEN] Subcontracting setup with a worksheet template
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] Work centers and a manufacturing item with routing and BOM
        //         (helper creates one subcontracting routing line on WorkCenter[2] without a Standard Task)
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, Subcontracting, UnitCostCalculation);
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);

        // [GIVEN] A standard task code
        LibraryManufacturing.CreateStandardTask(StandardTask);

        // [GIVEN] A second subcontracting routing line on the same work center, with the standard task assigned
        SecondOperationNo := AddSubcRoutingLineWithStandardTask(Item."Routing No.", WorkCenter[2]."No.", StandardTask.Code);

        // [GIVEN] Two subcontractor prices for the item / work center / vendor:
        //         - PriceWithoutStdTask, with no Standard Task Code
        //         - PriceWithStdTask = 2 * PriceWithoutStdTask, tied to StandardTask.Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        PriceWithoutStdTask := LibraryRandom.RandIntInRange(50, 200);
        PriceWithStdTask := PriceWithoutStdTask * 2;

        SubcontractorPrice.Reset();
        SubcontractorPrice.SetRange("Vendor No.", Vendor."No.");
        SubcontractorPrice.SetRange("Item No.", Item."No.");
        SubcontractorPrice.DeleteAll();

        Clear(SubcontractorPrice);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter[2]."No.", Vendor."No.", Item."No.", '', '',
            WorkDate(), Item."Base Unit of Measure", 0, Vendor."Currency Code");
        SubcontractorPrice."Direct Unit Cost" := PriceWithoutStdTask;
        SubcontractorPrice.Modify();

        Clear(SubcontractorPrice);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter[2]."No.", Vendor."No.", Item."No.", StandardTask.Code, '',
            WorkDate(), Item."Base Unit of Measure", 0, Vendor."Currency Code");
        SubcontractorPrice."Direct Unit Cost" := PriceWithStdTask;
        SubcontractorPrice.Modify();

        // [GIVEN] A released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [THEN] Standard Task Code is propagated from Routing Line to Prod. Order Routing Line on the second operation
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", SecondOperationNo);
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
            StandardTask.Code, ProdOrderRoutingLine."Standard Task Code",
            'Standard Task Code must be propagated from Routing Line to Prod. Order Routing Line.');

        // [GIVEN] An empty subcontracting worksheet
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

        // [WHEN] Calculate Subcontracts is run on the worksheet
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        // [THEN] On the worksheet line for the operation with a standard task, Standard Task Code is populated
        //        and the standard-task-bound price is applied
        RequisitionLineWithStdTask.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLineWithStdTask.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLineWithStdTask.SetRange("Prod. Order No.", ProductionOrder."No.");
        RequisitionLineWithStdTask.SetRange("Operation No.", SecondOperationNo);
#pragma warning restore AA0210
        RequisitionLineWithStdTask.FindFirst();
        Assert.AreEqual(
            StandardTask.Code, RequisitionLineWithStdTask."Subc. Standard Task Code",
            'Standard Task Code must be propagated from Prod. Order Routing Line to the Subcontracting Worksheet line.');
        Assert.AreEqual(
            PriceWithStdTask, RequisitionLineWithStdTask."Direct Unit Cost",
            'Subcontractor Price tied to the Standard Task Code must be applied to the worksheet line.');

        // [THEN] On the worksheet line for the operation without a standard task, the un-tagged subcontractor price is applied
        RequisitionLineNoStdTask.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLineNoStdTask.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLineNoStdTask.SetRange("Prod. Order No.", ProductionOrder."No.");
        RequisitionLineNoStdTask.SetFilter("Operation No.", '<>%1', SecondOperationNo);
#pragma warning restore AA0210
        RequisitionLineNoStdTask.FindFirst();
        Assert.AreEqual(
            '', RequisitionLineNoStdTask."Subc. Standard Task Code",
            'Standard Task Code must be empty on the worksheet line that has no standard task on the routing.');
        Assert.AreEqual(
            PriceWithoutStdTask, RequisitionLineNoStdTask."Direct Unit Cost",
            'Subcontractor Price for the un-tagged combination must be applied to the worksheet line.');

        // [WHEN] User clears Standard Task Code on the worksheet line
        RequisitionLineWithStdTask.Validate("Subc. Standard Task Code", '');
        RequisitionLineWithStdTask.Modify(true);

        // [THEN] Direct Unit Cost falls back to the un-tagged subcontractor price
        Assert.AreEqual(
            PriceWithoutStdTask, RequisitionLineWithStdTask."Direct Unit Cost",
            'Clearing Standard Task Code on the worksheet line must re-apply the un-tagged subcontractor price.');

        // [WHEN] User re-sets Standard Task Code on the worksheet line
        RequisitionLineWithStdTask.Validate("Subc. Standard Task Code", StandardTask.Code);
        RequisitionLineWithStdTask.Modify(true);

        // [THEN] Direct Unit Cost is restored to the standard-task-bound subcontractor price
        Assert.AreEqual(
            PriceWithStdTask, RequisitionLineWithStdTask."Direct Unit Cost",
            'Re-setting Standard Task Code on the worksheet line must re-apply the standard-task-bound subcontractor price.');

        // [WHEN] Carry Out Action Message creates the Subcontracting Purchase Order from the worksheet
        Clear(RequisitionLine);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] The purchase line for the operation with a standard task has Direct Unit Cost = PriceWithStdTask
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.SetRange("Operation No.", SecondOperationNo);
        PurchaseLine.FindFirst();
        Assert.AreEqual(
            PriceWithStdTask, PurchaseLine."Direct Unit Cost",
            'Subcontracting Purchase Line for the operation with a standard task must use the standard-task-bound subcontractor price.');

        // [THEN] The purchase line for the operation without a standard task has Direct Unit Cost = PriceWithoutStdTask
        PurchaseLine.SetFilter("Operation No.", '<>%1', SecondOperationNo);
        PurchaseLine.FindFirst();
        Assert.AreEqual(
            PriceWithoutStdTask, PurchaseLine."Direct Unit Cost",
            'Subcontracting Purchase Line for the operation without a standard task must use the un-tagged subcontractor price.');
    end;

    [Test]
    procedure RoutingPriceUsesOrderUoMWhenMultipleUoMPricesExist()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        AltUOMCode: Code[10];
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        PcsPrice, SetPrice : Decimal;
        QtyPerSet: Integer;
    begin
        // [SCENARIO 636059] SetRoutingPriceListCost must select the Subcontractor Price row matching
        // the order's Unit of Measure (with blank fallback). With prices in both Base UoM and an
        // alternative UoM that sorts after it, the routing line must pick the Base UoM price when
        // the order is in Base UoM — not the alphabetically-last alternative-UoM row.
        Initialize();

        // [GIVEN] Item with Base UoM and an alternative UoM (10 base per alt) whose code sorts after the base.
        LibraryInventory.CreateItem(Item);
        QtyPerSet := 10;
        AltUOMCode := CreateUOMCodeSortingAfter(Item."Base Unit of Measure");
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", AltUOMCode, QtyPerSet);

        // [GIVEN] Vendor and Work Center with the vendor as its subcontractor; zero indirect/overhead.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Modify(true);

        // [GIVEN] Two subcontractor prices — Base UoM = 1001, alternative UoM = 1004.
        PcsPrice := 1001;
        SetPrice := 1004;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", PcsPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), AltUOMCode, 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", SetPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged as SetSubcontractorPriceForPriceCalculation would — order in Base UoM.
        InSubcontractorPrice."Vendor No." := Vendor."No.";
        InSubcontractorPrice."Item No." := Item."No.";
        InSubcontractorPrice."Standard Task Code" := '';
        InSubcontractorPrice."Work Center No." := WorkCenter."No.";
        InSubcontractorPrice."Variant Code" := '';
        InSubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
        InSubcontractorPrice."Starting Date" := WorkDate();
        InSubcontractorPrice."Currency Code" := '';

        // [WHEN] SetRoutingPriceListCost runs for a Prod. Order Routing Line of qty 1 in the Base UoM.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] Direct Unit Cost equals the Base UoM price (1001), not the alt-UoM derived 100.40.
        Assert.AreEqual(
            PcsPrice, DirUnitCost,
            'SetRoutingPriceListCost must pick the Subcontractor Price row matching the order''s Unit of Measure.');
    end;

    [Test]
    procedure RoutingPriceUsesLCYWhenForeignCurrencyPriceExists()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        ForeignCurrencyCode: Code[10];
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        LCYPrice: Decimal;
    begin
        // [SCENARIO 638367] SetRoutingPriceListCost must filter Subcontractor Price by Currency Code so the
        // LCY (blank-currency) price drives Calc Standard Cost / Prod. Order Routing, not the alphabetically-last
        // foreign-currency row picked by FindLast() when Currency Code is left unfiltered.
        Initialize();

        // [GIVEN] Item, vendor and a subcontracting work center with zero indirect/overhead.
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);

        // [GIVEN] A foreign currency whose code sorts after the blank LCY code.
        ForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 15, 15);

        // [GIVEN] Two subcontractor prices — LCY = 10 and the foreign currency = 20.
        LCYPrice := 10;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LCYPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, ForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 20);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for an LCY routing line (blank Currency Code).
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, '', '');

        // [WHEN] SetRoutingPriceListCost runs for a routing line of qty 1 in the base UoM.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The LCY price (10) is used, not the foreign-currency price converted to LCY.
        Assert.AreEqual(
            LCYPrice, DirUnitCost,
            'SetRoutingPriceListCost must use the LCY subcontractor price, not a foreign-currency row.');
    end;

    [Test]
    procedure RoutingPriceFallsBackToCatchAllStandardTaskCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Prod. Order Routing path, SetRoutingPriceListCost must fall back to the
        // catch-all (blank Standard Task Code) subcontractor price when the routing line carries a Standard
        // Task Code that has no dedicated price — instead of leaving the routing cost in place.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank task, blank variant).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for a routing line with a Standard Task Code that has no own price.
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, '', 'TASK1');

        // [WHEN] SetRoutingPriceListCost runs.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The catch-all price (333) is applied.
        Assert.AreEqual(
            CatchAllPrice, DirUnitCost,
            'SetRoutingPriceListCost must fall back to the blank-Standard-Task-Code price.');
    end;

    [Test]
    procedure RoutingPriceFallsBackToCatchAllVariantCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Prod. Order Routing path, SetRoutingPriceListCost must fall back to the
        // catch-all (blank Variant Code) subcontractor price when the prod. order line has a Variant Code
        // that has no dedicated price.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank variant, blank task).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for a routing line with a Variant Code that has no own price.
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, 'VAR1', '');

        // [WHEN] SetRoutingPriceListCost runs.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The catch-all price (333) is applied.
        Assert.AreEqual(
            CatchAllPrice, DirUnitCost,
            'SetRoutingPriceListCost must fall back to the blank-Variant-Code price.');
    end;

    [Test]
    procedure RoutingPricePrefersVariantSpecificOverStandardTaskSpecific()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        StandardTask: Record "Standard Task";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        VariantPrice, TaskPrice : Decimal;
    begin
        // [SCENARIO 638400] When a routing line matches BOTH a variant-specific price (blank Standard Task Code)
        // and a standard-task-specific price (blank Variant Code), the lookup must be deterministic. With empty
        // fallback on both fields, FindLast follows the Subcontractor Price primary key order, where Variant Code
        // (field 4) precedes Standard Task Code (field 5), so the variant-specific row wins. This pins that
        // precedence so it stays consistent across the routing, worksheet, and purchase-line lookups.
        Initialize();

        // [GIVEN] Item (with a variant), a standard task, vendor and a subcontracting work center.
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryManufacturing.CreateStandardTask(StandardTask);

        // [GIVEN] A variant-specific price (blank task = 100) and a standard-task-specific price (blank variant = 200).
        VariantPrice := 100;
        TaskPrice := 200;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', ItemVariant.Code, WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", VariantPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", StandardTask.Code, '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", TaskPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for a routing line carrying both the variant and the standard task.
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, ItemVariant.Code, StandardTask.Code);

        // [WHEN] SetRoutingPriceListCost runs.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The variant-specific price (100) wins over the standard-task-specific price (200).
        Assert.AreEqual(
            VariantPrice, DirUnitCost,
            'When both a variant-specific and a standard-task-specific price match, the variant-specific price (per PK order) must win.');
    end;

    [Test]
    procedure WorksheetPriceFallsBackToCatchAllStandardTaskCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Subcontracting Worksheet path, GetSubcPriceForReqLine must fall back to the
        // catch-all (blank Standard Task Code) subcontractor price when the worksheet line carries a Standard
        // Task Code that has no dedicated price.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank task, blank variant).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A worksheet (requisition) line with a Standard Task Code that has no own price.
        StageRequisitionLine(RequisitionLine, Vendor, WorkCenter, Item, '', 'TASK1');

        // [WHEN] GetSubcPriceForReqLine runs.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] The catch-all price (333) is applied to the worksheet line.
        Assert.AreEqual(
            CatchAllPrice, RequisitionLine."Direct Unit Cost",
            'GetSubcPriceForReqLine must fall back to the blank-Standard-Task-Code price.');
    end;

    [Test]
    procedure WorksheetPriceFallsBackToCatchAllVariantCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Subcontracting Worksheet path, GetSubcPriceForReqLine must fall back to the
        // catch-all (blank Variant Code) subcontractor price when the worksheet line has a Variant Code that
        // has no dedicated price.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank variant, blank task).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A worksheet (requisition) line with a Variant Code that has no own price.
        StageRequisitionLine(RequisitionLine, Vendor, WorkCenter, Item, 'VAR1', '');

        // [WHEN] GetSubcPriceForReqLine runs.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] The catch-all price (333) is applied to the worksheet line.
        Assert.AreEqual(
            CatchAllPrice, RequisitionLine."Direct Unit Cost",
            'GetSubcPriceForReqLine must fall back to the blank-Variant-Code price.');
    end;

    [Test]
    procedure ProdOrderRoutingUnitCostUsesLCYWhenForeignCurrencyPriceExists()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ForeignCurrencyCode: Code[10];
        LCYPrice: Decimal;
    begin
        // [SCENARIO 638367] Refreshing a Released Production Order must price the subcontracting Prod. Order
        // Routing line from the LCY (blank-currency) subcontractor price, not from the alphabetically-last
        // foreign-currency price converted to LCY. End-to-end check of the routing path via the
        // OnAfterTransferRoutingLine subscriber -> ApplySubcontractorPricingToProdOrderRouting.
        Initialize();

        // [GIVEN] A subcontracting item with a single-operation routing on a subcontracting work center.
        CreateSubcontractingItemWithSingleOperationRouting(Item, Vendor, WorkCenter, '');

        // [GIVEN] A foreign currency with a non-LCY exchange rate whose code sorts after blank/LCY.
        ForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 15, 15);

        // [GIVEN] Two subcontractor prices for the item/work center/vendor — LCY = 10 and foreign = 20.
        LCYPrice := 10;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LCYPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, ForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 20);
        SubcontractorPrice.Modify(true);

        // [WHEN] A Released Production Order for the item is created and refreshed.
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, Item."No.", 1);

        // [THEN] The Prod. Order Routing line Direct Unit Cost and Unit Cost per equal the LCY price (10).
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Direct Unit Cost",
            'Prod. Order Routing Direct Unit Cost must use the LCY subcontractor price, not a foreign-currency one.');
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Unit Cost per",
            'Prod. Order Routing Unit Cost per must use the LCY subcontractor price, not a foreign-currency one.');
    end;

    [Test]
    procedure ProdOrderRoutingUnitCostUsesLCYAmongMultipleForeignCurrencies()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        FirstForeignCurrencyCode: Code[10];
        SecondForeignCurrencyCode: Code[10];
        LCYPrice: Decimal;
    begin
        // [SCENARIO 638367] Even when several foreign-currency prices exist (all sorting after blank on the
        // primary key), the Prod. Order Routing line must still resolve to the single LCY (blank-currency) price.
        Initialize();

        // [GIVEN] A subcontracting item with a single-operation routing on a subcontracting work center.
        CreateSubcontractingItemWithSingleOperationRouting(Item, Vendor, WorkCenter, '');

        // [GIVEN] Two foreign currencies with non-LCY exchange rates.
        FirstForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 15, 15);
        SecondForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 12, 12);

        // [GIVEN] An LCY price (10) and two foreign-currency prices (20 and 18).
        LCYPrice := 10;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LCYPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, FirstForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 20);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, SecondForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 18);
        SubcontractorPrice.Modify(true);

        // [WHEN] A Released Production Order for the item is created and refreshed.
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, Item."No.", 1);

        // [THEN] The Prod. Order Routing line still resolves to the LCY price (10).
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Direct Unit Cost",
            'Prod. Order Routing Direct Unit Cost must use the LCY price even among multiple foreign-currency prices.');
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Unit Cost per",
            'Prod. Order Routing Unit Cost per must use the LCY price even among multiple foreign-currency prices.');
    end;

    [Test]
    procedure ProdOrderRoutingUnitCostUsesVendorCurrencyPriceWhenVendorHasCurrency()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        VendorCurrencyCode: Code[10];
        LCYPrice: Decimal;
        VendorCurrencyPrice: Decimal;
    begin
        // [SCENARIO 638367] When the subcontractor vendor has a foreign Currency Code and a Subcontractor Price
        // exists in that currency, the Prod. Order Routing line must be priced from the vendor-currency price
        // (converted to LCY) so it stays consistent with the purchase order, not from the blank/LCY price.
        Initialize();

        // [GIVEN] A subcontractor vendor with a foreign currency (1:1 exchange rate) and a subcontracting item.
        VendorCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        CreateSubcontractingItemWithSingleOperationRouting(Item, Vendor, WorkCenter, VendorCurrencyCode);

        // [GIVEN] Two subcontractor prices — LCY = 10 (blank currency) and vendor-currency = 20.
        LCYPrice := 10;
        VendorCurrencyPrice := 20;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LCYPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, VendorCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", VendorCurrencyPrice);
        SubcontractorPrice.Modify(true);

        // [WHEN] A Released Production Order for the item is created and refreshed.
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, Item."No.", 1);

        // [THEN] The Prod. Order Routing line resolves to the vendor-currency price (20), converted 1:1 to LCY.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
            VendorCurrencyPrice, ProdOrderRoutingLine."Direct Unit Cost",
            'Prod. Order Routing Direct Unit Cost must use the vendor-currency subcontractor price, not the blank/LCY one.');
        Assert.AreEqual(
            VendorCurrencyPrice, ProdOrderRoutingLine."Unit Cost per",
            'Prod. Order Routing Unit Cost per must use the vendor-currency subcontractor price, not the blank/LCY one.');
    end;

    local procedure CreateDateEffectiveSubcontractingScenario(var Item: Record Item; var ProductionOrder: Record "Production Order"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var EarlierPrice: Decimal; var LaterPrice: Decimal)
    var
        SubcontractorPrice: Record "Subcontractor Price";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
    begin
        CreateSubcontractingItemWithSingleOperationRouting(Item, Vendor, WorkCenter, '');
        Evaluate(Item."Lead Time Calculation", '<5D>');
        Item.Modify(true);

        EarlierPrice := 100;
        LaterPrice := 200;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', CalcDate('<-1M>', WorkDate()), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Ending Date", CalcDate('<-1D>', WorkDate()));
        SubcontractorPrice.Validate("Direct Unit Cost", EarlierPrice);
        SubcontractorPrice.Modify(true);
        Clear(SubcontractorPrice);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LaterPrice);
        SubcontractorPrice.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, "Production Order Status"::Released, Item, '', '', 1, WorkDate());
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure CreateSubcontractingPurchaseLine(var PurchaseLine: Record "Purchase Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemNo: Code[20]; ProdOrderNo: Code[20])
    var
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine);
        SubcontractingMgmtLibrary.FindSubcPurchLineForProdOrder(PurchaseLine, ItemNo, ProdOrderNo);
    end;

    local procedure CreateItemVendorAndSubcontractingWorkCenter(var Item: Record Item; var Vendor: Record Vendor; var WorkCenter: Record "Work Center")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Modify(true);
    end;

    local procedure CreateSubcontractingItemWithSingleOperationRouting(var Item: Record Item; var Vendor: Record Vendor; var WorkCenter: Record "Work Center"; VendorCurrencyCode: Code[10])
    var
        RoutingNo: Code[20];
    begin
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(VendorCurrencyCode));

        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Modify(true);

        RoutingNo := CreateCertifiedSubcontractingRouting(WorkCenter."No.");

        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateCertifiedSubcontractingRouting(WorkCenterNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

#pragma warning disable AA0210
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
#pragma warning restore AA0210
        CapacityUnitOfMeasure.FindFirst();

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenterNo, '10', 0, 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure AddSubcRoutingLineWithStandardTask(RoutingNo: Code[20]; WorkCenterNo: Code[20]; StandardTaskCode: Code[10]) NewOperationNo: Code[10]
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
#pragma warning disable AA0210
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
#pragma warning restore AA0210
        CapacityUnitOfMeasure.FindFirst();

        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        // Use a number larger than any existing operation so the certification-time ordering check is satisfied.
        NewOperationNo := CopyStr(IncStr(FindLastRoutingOperationNo(RoutingNo)), 1, MaxStrLen(NewOperationNo));

        LibraryManufacturing.CreateRoutingLineSetup(
            RoutingLine, RoutingHeader, WorkCenterNo, NewOperationNo,
            LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Standard Task Code", StandardTaskCode);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure FindLastRoutingOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindLast();
        exit(RoutingLine."Operation No.");
    end;

    local procedure StageInSubcontractorPrice(var InSubcontractorPrice: Record "Subcontractor Price"; Vendor: Record Vendor; WorkCenter: Record "Work Center"; Item: Record Item; VariantCode: Code[10]; StandardTaskCode: Code[10])
    begin
        // Mirrors how SetSubcontractorPriceForPriceCalculation stages the lookup record for a routing line.
        InSubcontractorPrice.Init();
        InSubcontractorPrice."Vendor No." := Vendor."No.";
        InSubcontractorPrice."Item No." := Item."No.";
        InSubcontractorPrice."Standard Task Code" := StandardTaskCode;
        InSubcontractorPrice."Work Center No." := WorkCenter."No.";
        InSubcontractorPrice."Variant Code" := VariantCode;
        InSubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
        InSubcontractorPrice."Starting Date" := WorkDate();
        InSubcontractorPrice."Currency Code" := '';
    end;

    local procedure StageRequisitionLine(var RequisitionLine: Record "Requisition Line"; Vendor: Record Vendor; WorkCenter: Record "Work Center"; Item: Record Item; VariantCode: Code[10]; StandardTaskCode: Code[10])
    begin
        RequisitionLine.Init();
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Variant Code" := VariantCode;
        RequisitionLine."Subc. Standard Task Code" := StandardTaskCode;
        RequisitionLine."Unit of Measure Code" := Item."Base Unit of Measure";
        RequisitionLine."Currency Code" := '';
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 1;
    end;

    [Test]
    procedure WorksheetDirectUnitCostUsesQtyPerUoMNotBaseQtyForUoMConversion()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        QtyPerSet: Integer;
        PriceListUnitCost: Decimal;
    begin
        // [SCENARIO 636078] Calculate Subcontracts must compute Direct Unit Cost on the Subcontracting
        // Worksheet using the per-UoM conversion factor (GetQuantityForUOM()), not the total base
        // quantity (GetQuantityBase()) of the order.

        // [GIVEN] Item with PCS base UoM and a SET alternative UoM (10 PCS per SET).
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyPerSet := 10;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", QtyPerSet);

        // [GIVEN] Vendor and Work Center with the vendor as its subcontractor.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);

        // [GIVEN] A subcontractor price in the blank fallback UoM with Minimum Quantity 1 and Direct
        // Unit Cost 1000 — the blank-UoM row matches the SET line's '%1|%2' UoM filter and exercises
        // the cross-UoM conversion (PriceListUOM resolves to the item's base UoM).
        PriceListUnitCost := 1000;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), '', 1, '');
        SubcontractorPrice.Validate("Direct Unit Cost", PriceListUnitCost);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A staged Requisition Line for 3 SET (= 30 PCS in base UoM).
        RequisitionLine.Init();
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Unit of Measure Code" := ItemUOM.Code;
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 3;

        // [WHEN] The subcontractor price is applied to the requisition line.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] Direct Unit Cost = price-list cost * Qty-per-UoM (1000 * 10 = 10000),
        // not price-list cost * total base quantity (1000 * 30 = 30000 — the pre-fix behavior).
        Assert.AreEqual(
            PriceListUnitCost * QtyPerSet, RequisitionLine."Direct Unit Cost",
            'Direct Unit Cost on the Subcontracting Worksheet must be derived from Qty. per Unit of Measure, not from total base quantity.');

        // [WHEN] The same price is applied to a Requisition Line using the base UoM (no conversion needed).
        Clear(RequisitionLine);
        RequisitionLine.Init();
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Unit of Measure Code" := Item."Base Unit of Measure";
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 30;
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] Direct Unit Cost equals the price-list cost (the same-UoM path is unchanged by the fix).
        Assert.AreEqual(
            PriceListUnitCost, RequisitionLine."Direct Unit Cost",
            'Direct Unit Cost must equal the price-list cost when the worksheet UoM matches the price-list UoM.');
    end;

    [Test]
    procedure ReqLinePriceUsesOrderUoMWhenFixedUOMIsEmpty()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        AltUOMCode: Code[10];
        PcsPrice, SetPrice : Decimal;
        QtyPerSet: Integer;
    begin
        // [SCENARIO 636059] GetSubcPriceForReqLine must filter Subcontractor Prices by the
        // requisition line's Unit of Measure (with blank fallback) even when the caller passes
        // FixedUOM = '' — otherwise the alphabetically-last UoM row wins regardless of the line's UoM.
        Initialize();

        // [GIVEN] Item with Base UoM and an alternative UoM (10 base per alt) whose code sorts after the base.
        LibraryInventory.CreateItem(Item);
        QtyPerSet := 10;
        AltUOMCode := CreateUOMCodeSortingAfter(Item."Base Unit of Measure");
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", AltUOMCode, QtyPerSet);

        // [GIVEN] Vendor and Work Center with the vendor as its subcontractor.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);

        // [GIVEN] Two subcontractor prices — Base UoM = 1001, alternative UoM = 1004.
        PcsPrice := 1001;
        SetPrice := 1004;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", PcsPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), AltUOMCode, 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", SetPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A staged Requisition Line in the Base UoM with FixedUOM = ''.
        RequisitionLine.Init();
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Unit of Measure Code" := Item."Base Unit of Measure";
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 1;

        // [WHEN] GetSubcPriceForReqLine is called with no FixedUOM.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] Direct Unit Cost equals the Base UoM price (1001), not the alt-UoM derived 100.40.
        Assert.AreEqual(
            PcsPrice, RequisitionLine."Direct Unit Cost",
            'GetSubcPriceForReqLine must pick the price row matching the line''s Unit of Measure when FixedUOM is empty.');
    end;

    [Test]
    procedure FactboxCountsBlankUoMPriceWhenPurchLineHasUoM()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        PurchaseLine: Record "Purchase Line";
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
    begin
        // [SCENARIO] A subcontractor price with a blank Unit of Measure Code must be counted
        // in the Purchase Order FactBox when the purchase line specifies a Unit of Measure Code.
        // Previously, the FactBox used SetRange on Unit of Measure Code (exact match), so a
        // blank-UoM price was invisible whenever the purchase line had a specific UoM.
        Initialize();

        // [GIVEN] An item, vendor, and work center linked as a subcontractor.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);

        // [GIVEN] A subcontractor price recorded with a blank Unit of Measure Code.
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), '', 0, '');

        // [GIVEN] A purchase line for the same item/vendor/work center with a specific UoM.
        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := Item."No.";
        PurchaseLine."Buy-from Vendor No." := Vendor."No.";
        PurchaseLine."Work Center No." := WorkCenter."No.";
        PurchaseLine."Unit of Measure Code" := Item."Base Unit of Measure";
        PurchaseLine."Currency Code" := '';
        PurchaseLine."Variant Code" := '';

        // [WHEN] The FactBox counts applicable subcontractor prices.
        // [THEN] The blank-UoM price is counted even though the purchase line has a specific UoM.
        Assert.AreEqual(
            1, SubcPurchFactboxMgmt.CalcNoOfPurchasePrices(PurchaseLine),
            'A subcontractor price with blank Unit of Measure must appear in the FactBox when the purchase line has a specific UoM.');
    end;


    local procedure CreateUOMCodeSortingAfter(BaseUOMCode: Code[10]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
        LibraryUtility: Codeunit "Library - Utility";
        NewCode: Code[10];
    begin
        // LibraryInventory.CreateUnitOfMeasureCode generates a hex-only code (truncated GUID), so
        // any code with a 'Z' prefix is guaranteed to sort after it. This makes the multi-UoM test
        // deterministic — without the fix, FindLast() picks the alt UoM row.
        repeat
            NewCode := CopyStr('Z' + LibraryUtility.GenerateGUID(), 1, MaxStrLen(NewCode));
        until not UnitOfMeasure.Get(NewCode);
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := NewCode;
        UnitOfMeasure.Description := NewCode;
        UnitOfMeasure.Insert(true);
        if UnitOfMeasure.Code <= BaseUOMCode then
            Error('Test setup: generated UoM code %1 must sort after base UoM code %2.', UnitOfMeasure.Code, BaseUOMCode);
        exit(UnitOfMeasure.Code);
    end;

    local procedure SelectRequisitionTemplateName(): Code[10]
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

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Pricing Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
        LibraryVariableStorage.Clear();

        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Pricing Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Pricing Test");
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    procedure DetailedCalculationReportUsesSubcontractorPricing()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SubcontractorPrice: Record "Subcontractor Price";
        SubcPriceAmount: Decimal;
        WorkCenterDirectCost: Decimal;
        XmlParameters: Text;
    begin
        // [SCENARIO 638464] Report "Detailed Calculation" must use subcontractor pricing for
        // work centers with a subcontractor when the Subcontracting app is installed, via
        // the OnAfterGetRecordRoutingLineOnBeforeCalcRoutingCostPerUnit event.
        Initialize();

        // [GIVEN] Item with a routing that has a single Work Center operation.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        WorkCenterDirectCost := 50;
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", WorkCenterDirectCost);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Validate("Unit Cost", WorkCenterDirectCost);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Validate("Lot Size", 1);
        Item.Modify(true);

        // [GIVEN] A subcontractor price of 200 for this item/work center (different from WorkCenter."Direct Unit Cost" of 50).
        SubcPriceAmount := 200;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", SubcPriceAmount);
        SubcontractorPrice.Modify(true);

        // [WHEN] Run the "Detailed Calculation" report (BaseApp 99000756) for this item.
        Commit();
        Item.SetRecFilter();
        XmlParameters := Report.RunRequestPage(Report::"Detailed Calculation");
        LibraryReportDataset.RunReportAndLoad(Report::"Detailed Calculation", Item, XmlParameters);

        // [THEN] The ProdUnitCost in the report dataset equals the subcontractor price (200),
        // not the Work Center's generic Direct Unit Cost (50).
        LibraryReportDataset.AssertElementWithValueExists('ProdUnitCost', SubcPriceAmount);
    end;

    [RequestPageHandler]
    procedure DetailedCalculationRequestPageHandler(var DetailedCalculationRequestPage: TestRequestPage "Detailed Calculation")
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

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        UnitCostCalculation: Option Time,Units;
}