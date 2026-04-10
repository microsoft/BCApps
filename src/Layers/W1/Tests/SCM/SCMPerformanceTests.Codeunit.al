codeunit 137380 "SCM Performance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Performance]
        isInitialized := false;
    end;

    var
        CodeCoverage: Record "Code Coverage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        isInitialized: Boolean;
        NotLinearCCErr: Label 'Computational cost is not linear.';
        LogNPerformanceExpectedErr: Label 'Computational cost must be O(Log(N))';
        FunctionMustBeHitOnlyOnceErr: Label 'Function %1 must be hit only once', Comment = '%1 = Function name';
        FunctionMustNotBeCalledErr: Label 'Function %1 must not be called when %2 and %3 are both 0', Comment = '%1 = Function name, %2 = field caption "Cubage", %3 = field caption "Weight"';
        NotConstantCalcErr: Label 'Computational complexity must be constant';
        NotQuadraticCalcErr: Label 'Time complexity must not be worse than quadratic';

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ThousandSerialNos()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateLargeNumberOfSN(1000, ReservationEntry."Item Tracking"::"Serial No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure FiveThousandSerialNos()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateLargeNumberOfSN(5000, ReservationEntry."Item Tracking"::"Serial No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure TenThousandSerialNos()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateLargeNumberOfSN(10000, ReservationEntry."Item Tracking"::"Serial No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ThousandSerialNosWLot()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateLargeNumberOfSN(1000, ReservationEntry."Item Tracking"::"Lot and Serial No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure FiveThousandSerialNosWLot()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateLargeNumberOfSN(5000, ReservationEntry."Item Tracking"::"Lot and Serial No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure TenThousandSerialNosWLot()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateLargeNumberOfSN(10000, ReservationEntry."Item Tracking"::"Lot and Serial No.");
    end;

    [Test]
    [HandlerFunctions('PostJournalWithSNTrackingHandler,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionWithTrackingPerformance()
    var
        SubasmItem: Record Item;
        OutputItem: Record Item;
        SmallNoOfItems: Integer;
        MediumNoOfItems: Integer;
        LargeNoOfItems: Integer;
        SmallNoResult: Integer;
        MediumNoResult: Integer;
        LargeNoResult: Integer;
    begin
        // [SCENARIO 360821] Poor performance when posting consumption of a produced item in the same prod. order if both items are tracked by serial no.
        Initialize();

        SmallNoOfItems := 10;
        MediumNoOfItems := 50;
        LargeNoOfItems := 100;

        // [GIVEN] Output item and subassembly item are tracked by serial no.
        CreateOutputAndSubassemblyItems(OutputItem, SubasmItem);

        // [WHEN] Subassembly item is produced and consumed in the same production order
        CodeCoverageMgt.StartApplicationCoverage();
        SmallNoResult := PostTrackedOutputAndConsumption(OutputItem, SubasmItem, SmallNoOfItems);
        MediumNoResult := PostTrackedOutputAndConsumption(OutputItem, SubasmItem, MediumNoOfItems);
        LargeNoResult := PostTrackedOutputAndConsumption(OutputItem, SubasmItem, LargeNoOfItems);
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] Function computational complexity is linear
        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(
            SmallNoOfItems, MediumNoOfItems, LargeNoOfItems, SmallNoResult, MediumNoResult, LargeNoResult), NotLinearCCErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NegativeSurplusApplicationPerformance()
    var
        Argument: array[3] of Integer;
        FunctionValue: array[3] of Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 362340] Item tracking performance is better than linear when large negative surplus is posted
        Initialize();

        CodeCoverageMgt.StartApplicationCoverage();

        Argument[1] := 100;
        Argument[2] := 500;
        Argument[3] := 1000;

        // [GIVEN] Item with item tracking policy "Tracking Only"
        // [WHEN] Negative adjustmentis is applied to an inventory surplus
        FunctionValue[1] := CreatePostSalesOrder(Argument[1]);
        FunctionValue[2] := CreatePostSalesOrder(Argument[2]);
        FunctionValue[3] := CreatePostSalesOrder(Argument[3]);

        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] Function computational complexity is O(LogX)
        Assert.IsTrue(
          LibraryCalcComplexity.IsLogN(
            Argument[1], Argument[2], Argument[3], FunctionValue[1], FunctionValue[2], FunctionValue[3]), LogNPerformanceExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CyclicalLopCheckedOnceWhenConsumingOutputFromAnotherProdOrder()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        Qty: Integer;
        I: Integer;
        NoOfHits: Integer;
    begin
        // [FEATURE] [Manufacturing]
        // [SCENARIO 375615] Cyclical loop check is run only once when consuming several ILE's posted as output from one production order

        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Production order "P1" producing item "I"
        Qty := LibraryRandom.RandIntInRange(2, 5);
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProdOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine[1], ProdOrder, Item."No.");

        // [GIVEN] Post output from production order, splitting it in several entries, 1 item in each output entry
        for I := 1 to Qty do
            LibraryManufacturing.POSTOutput(ProdOrderLine[1], 1, WorkDate(), Item."Unit Cost");

        // [GIVEN] Another production order "P2" consuming item "I"
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProdOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine[2], ProdOrder, Item."No.");

        // [WHEN] Post consumption in production order "P2"
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryManufacturing.POSTConsumption(ProdOrderLine[2], Item, '', '', Qty, WorkDate(), Item."Unit Cost");
        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits :=
          GetCodeCoverageForObject(
            CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Jnl.-Post Line", 'ItemApplnEntry.CheckIsCyclicalLoop');

        // [THEN] Item ledger entries are checked for cyclical loops only once
        Assert.AreEqual(1, NoOfHits, StrSubstNo(FunctionMustBeHitOnlyOnceErr, 'CheckIsCyclicalLoop'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetReceiptLinesInvoiceDiscountRecalculatedOnce()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NoOfHits: Integer;
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines] [Invoice Discount]
        // [SCENARIO 378207] Invoice disount should be recalculated only once per document when copying lines from purchase receipt

        Initialize();
        EnablePurchInvDiscountCalculation();

        // [GIVEN] Create purchase order, quantity = "X"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);

        // [GIVEN] Set quantity to receive = "X" / 2, post receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [GIVEN] Receive remaining quantity
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CodeCoverageMgt.StartApplicationCoverage();
        // [GIVEN] Create purchase invoice
        // [WHEN] Run "Get Receipt Lines"
        GetPurchaseReceiptLines(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");

        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits :=
          GetCodeCoverageForObject(
            CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Purch.-Calc.Discount", 'CalculateInvoiceDiscount');

        // [THEN] Invoice discount calculation is called once
        Assert.AreEqual(1, NoOfHits, StrSubstNo(FunctionMustBeHitOnlyOnceErr, 'CalculateInvoiceDiscount'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderCapacityNeedRecalculatedOnce()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoOfHits: Integer;
        ShipmentDate: Date;
        SendAheadQty: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Planning Worksheet] [Prod. Order] [Send-Ahead Quantity]
        // [SCENARIO 379844] Prod. Order Capacity Need should be recalculated only once per Item when Calculate Reg. Plan

        Initialize();

        // [GIVEN] Item have Routing with "Send-Ahead Quantity".
        SendAheadQty := CreateSendAheadItem(Item);

        // [GIVEN] Quantity in Demand is greater than "Send-Ahead Quantity"
        SalesQty := SendAheadQty * LibraryRandom.RandIntInRange(2, 10);

        ShipmentDate := CreateSalesOrderWithOneLine(SalesHeader, SalesLine, Item."No.", SalesQty);

        CodeCoverageMgt.StartApplicationCoverage();

        // [WHEN] Calculate Regenerative Plan for Planning Worksheet for demand
        CalcRegenPlanForPlanWkshWithItemFilterAndPeriod(Item."No.", WorkDate(), ShipmentDate);

        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Inventory Profile Offsetting", 'PlngLnMgt.Calculate');

        // [THEN] Prod. Order Capacity Need calculation is called once
        Assert.AreEqual(1, NoOfHits, StrSubstNo(FunctionMustBeHitOnlyOnceErr, 'PlngLnMgt.Calculate'));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerSetLotNo')]
    [Scope('OnPrem')]
    procedure PostingWhseReceiptWithManyLinesAndItemTrackingHasLinearComplexity()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        Item: Record Item;
        NoOfLines: array[3] of Integer;
        NoOfHits: array[3] of Integer;
    begin
        // [FEATURE] [Warehouse] [Receipt] [Item Tracking]
        // [SCENARIO 204197] Computational complexity of a warehouse receipt posting with item tracking is linear depending on the number of document lines

        Initialize();

        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, true, false);

        NoOfLines[1] := 1;
        NoOfLines[2] := 5;
        NoOfLines[3] := 10;

        CodeCoverageMgt.StartApplicationCoverage();
        PostWhseReceiptFromPurchaseOrder(Location.Code, Item."No.", NoOfLines[1]);
        NoOfHits[1] :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Tracking Management", 'InsertWhseItemTrkgLines');

        PostWhseReceiptFromPurchaseOrder(Location.Code, Item."No.", NoOfLines[2]);
        NoOfHits[2] :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Tracking Management", 'InsertWhseItemTrkgLines') -
          NoOfHits[1];

        PostWhseReceiptFromPurchaseOrder(Location.Code, Item."No.", NoOfLines[3]);
        NoOfHits[3] :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Tracking Management", 'InsertWhseItemTrkgLines') -
          NoOfHits[1] - NoOfHits[2];

        CodeCoverageMgt.StopApplicationCoverage();

        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(NoOfLines[1], NoOfLines[2], NoOfLines[3], NoOfHits[1], NoOfHits[2], NoOfHits[3]), NotLinearCCErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailCubageAndWeightNotCalculatedForUndefinedUoM()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        NoOfHits: Integer;
    begin
        // [FEATURE] [Warehouse] [Put-away] [Bin]
        // [SCENARIO 211220] Cubage and weight available in bin should not be calculated when a put-away unit of measure does not have cubage and weight defined

        Initialize();

        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        UpdateMaxCubageAndWeightOnPutAwayBin(Location.Code);

        // [GIVEN] Item "I" with a default unit of measure that has both "Weight" and "Cubage" = 0
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order for the item "I" on a WMS location
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(),
          Item."No.", 1, Location.Code, WorkDate());

        // [GIVEN] Create a warehouse receipt
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));

        // [WHEN] Post the warehouse receipt
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits := GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Create Put-away", 'CalcCubageAndWeight');

        // [THEN] Calculation of available cuabage and weight is not called
        Assert.AreEqual(
          0, NoOfHits, StrSubstNo(
            FunctionMustNotBeCalledErr, 'CalcCubageAndWeight',
            ItemUnitOfMeasure.FieldCaption(Cubage), ItemUnitOfMeasure.FieldCaption(Weight)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandOverviewDoesNotCheckEntriesForItemsNotInScope()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempAvailCalcOverview: Record "Availability Calc. Overview" temporary;
        CalcAvailabilityOverview: Codeunit "Calc. Availability Overview";
        NoOfHits: Integer;
    begin
        // [FEATURE] [Demand Overview]
        // [SCENARIO 215433] Page 5830 "Demand Overview" should check item entries only for items included in the demand scope

        Initialize();

        // [GIVEN] Two items "ItemA" and "ItemB"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Demand (sales order) for item "ItemB"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        CalcAvailabilityOverview.SetParameters("Demand Order Source Type"::"Sales Demand", SalesHeader."No.");

        // [WHEN] Run "Demand Overview"
        CodeCoverageMgt.StartApplicationCoverage();
        CalcAvailabilityOverview.Run(TempAvailCalcOverview);
        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Calc. Availability Overview", 'EntriesExist');

        // [THEN] Function EntriesExist has been called only once
        Assert.AreEqual(1, NoOfHits, StrSubstNo(FunctionMustBeHitOnlyOnceErr, 'EntriesExist'));
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueChangeValueEditor')]
    [Scope('OnPrem')]
    procedure ChangeItemAttributeValue()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemCard: TestPage "Item Card";
        I: Integer;
        NoOfHitsOneItem: Integer;
        NoOfHitsManyItems: Integer;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 235152] Performance of updating item attribute value should be independent of the number of attribute values

        Initialize();

        // [GIVEN] Item "I1" with attribute "A" and attribute value "V"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Open attribute editor for the item "I" and change attribute value from "V" to "Z"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        ItemCard.OpenView();
        ItemCard.GotoKey(Item."No.");

        CodeCoverageMgt.StartApplicationCoverage();
        ItemCard.Attributes.Invoke();
        CodeCoverageMgt.StopApplicationCoverage();

        NoOfHitsOneItem :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Table, DATABASE::"Item Attribute Value", '');

        // [GIVEN] 10 items with different values of attribue "A"
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());
        for I := 1 to 10 do begin
            LibraryInventory.CreateItem(Item);
            LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());
            LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);
        end;

        // [WHEN] Open the attribue editor for one of the items and change its value
        ItemCard.GotoKey(Item."No.");

        CodeCoverageMgt.StartApplicationCoverage();
        ItemCard.Attributes.Invoke();
        CodeCoverageMgt.StopApplicationCoverage();

        NoOfHitsManyItems :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Table, DATABASE::"Item Attribute Value", '');

        // [THEN] Peformance of the operation is constant and does not depend on the number of items and attribute values
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHitsOneItem, NoOfHitsManyItems), NotConstantCalcErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemCategoryAttributeValue()
    var
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        I: Integer;
        NoOfHitsOneItem: Integer;
        NoOfHitsManyItems: Integer;
    begin
        // [FEATURE] [Item Attribute] [Item Category]
        // [SCENARIO 235152] Performance of deleting item category attribute value should be independent of the number of items the value is mapped on

        Initialize();

        // [GIVEN] Item category with attribute "A", attribute value "V"
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItemAttributeValueMapping(
          DATABASE::"Item Category", ItemCategory.Code, ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Create one item in the category "C"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Modify(true);

        TempItemAttributeValue := ItemAttributeValue;
        TempItemAttributeValue.Insert();

        // [WHEN] Delete attribute value mapping for the category "C"
        CodeCoverageMgt.StartApplicationCoverage();
        ItemAttributeManagement.DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValue, ItemCategory.Code);
        CodeCoverageMgt.StopApplicationCoverage();

        NoOfHitsOneItem :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Table, DATABASE::"Item Attribute Value Mapping", '');

        // [GIVEN] Create 10 items in the category "C"
        for I := 1 to 10 do begin
            LibraryInventory.CreateItem(Item);
            Item.Validate("Item Category Code", ItemCategory.Code);
            Item.Modify(true);
        end;

        // [WHEN] Delete attribute value mapping for the category "C"
        CodeCoverageMgt.StartApplicationCoverage();
        ItemAttributeManagement.DeleteCategoryItemsAttributeValueMapping(TempItemAttributeValue, ItemCategory.Code);
        CodeCoverageMgt.StopApplicationCoverage();

        NoOfHitsManyItems :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Table, DATABASE::"Item Attribute Value Mapping", '');

        // [THEN] Peformance of the operation is constant and does not depend on the number of items
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHitsOneItem, NoOfHitsManyItems), NotConstantCalcErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateDescriptionOnCreateRequisitionLine()
    var
        Item: Record Item;
        NoOfHits: Integer;
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO 281340] Function UpdateDescription must be called only once when creating a new requisition line

        Initialize();

        // [GIVEN] Item with planning setup and unsatisfied demand
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(100, 2));
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        CodeCoverageMgt.StartApplicationCoverage();

        // [WHEN] Calculate requsition plan for the item
        LibraryPlanning.CalcRequisitionPlanForReqWksh(Item, WorkDate(), WorkDate());

        // [THEN] New requisition line is created, UpdateDescription was called once
        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Table, DATABASE::"Requisition Line", 'UpdateDescription;');

        Assert.AreEqual(1, NoOfHits, StrSubstNo(FunctionMustBeHitOnlyOnceErr, 'UpdateDescription'));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure InsertMultipleSerialNosOnPurchaseLineBoundToTransferOrder()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        PurchaseLine: Record "Purchase Line";
        DummyReservEntry: Record "Reservation Entry";
        NoOfSerialNos: Integer;
        NoOfHits: Integer;
    begin
        // [FEATURE] [Transfer] [Purchase] [Order-to-Order Binding] [Item Tracking]
        // [SCENARIO 283223] Function SynchronizeItemTracking2 in codeunit 6500, that pushes item tracking from outbound transfer to the inbound, is called only once when a user sets item tracking on purchase with order-to-order binding to the transfer.
        Initialize();

        NoOfSerialNos := 1000;

        // [GIVEN] Serial no.-tracked item "I" with "Order" reordering policy.
        LibraryItemTracking.CreateSerialItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Transfer order for 1000 pcs of "I".
        CreateTransferOrder(TransferHeader, Item."No.", NoOfSerialNos);

        // [GIVEN] Calculate regenerative plan and carry out action message for item "I".
        Item.SetRecFilter();
        Item.SetRange("Location Filter", TransferHeader."Transfer-from Code");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        CarryOutActionMsgOnPlanningWksh(Item."No.");

        // [GIVEN] The planning engine creates a purchase and establishes an order-to-order link to the transfer.
        FindPurchaseLine(PurchaseLine, Item."No.");

        CodeCoverageMgt.StartApplicationCoverage();

        // [WHEN] Open item tracking lines on the purchase line and assign 1000 serial nos.
        LibraryVariableStorage.Enqueue(DummyReservEntry."Item Tracking"::"Serial No.");
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] SynchronizeItemTracking2 function in codeunit 6500 is called only once.
        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Tracking Management", 'SynchronizeItemTracking2');

        Assert.AreEqual(1, NoOfHits, StrSubstNo(FunctionMustBeHitOnlyOnceErr, 'SynchronizeItemTracking2'));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostingPurchaseWithMultipleSerialNosBoundToTransferOrder()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DummyReservEntry: Record "Reservation Entry";
        NoOfSerialNos: array[2] of Integer;
        NoOfHits: array[2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Transfer] [Purchase] [Order-to-Order Binding] [Item Tracking]
        // [SCENARIO 283223] Number of calls of SynchronizeItemTracking functions during posting of purchase order bound to transfer order does not depend on number of item tracking lines on purchase line.
        Initialize();

        NoOfSerialNos[1] := 10;
        NoOfSerialNos[2] := 100;

        for i := 1 to 2 do begin
            Clear(Item);
            Clear(TransferHeader);
            Clear(PurchaseHeader);
            Clear(PurchaseLine);

            // [GIVEN] Serial no.-tracked items "I", "J" with "Order" reordering policy.
            LibraryItemTracking.CreateSerialItem(Item);
            Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
            Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
            Item.Modify(true);

            // [GIVEN] Two transfer orders: 10 pcs of "I", 100 pcs of "J".
            CreateTransferOrder(TransferHeader, Item."No.", NoOfSerialNos[i]);

            // [GIVEN] Calculate regenerative plan and carry out action message for items "I" and "J".
            Item.SetRecFilter();
            Item.SetRange("Location Filter", TransferHeader."Transfer-from Code");
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
            CarryOutActionMsgOnPlanningWksh(Item."No.");

            // [GIVEN] The planning engine creates a purchase order for each item and establishes an order-to-order link to the corresponding transfer.
            // [GIVEN] Open item tracking lines on the purchase line with item "I" and assign 10 serial nos.
            // [GIVEN] Open item tracking lines on the purchase line with item "J" and assign 100 serial nos.
            FindPurchaseLine(PurchaseLine, Item."No.");
            LibraryVariableStorage.Enqueue(DummyReservEntry."Item Tracking"::"Serial No.");
            PurchaseLine.OpenItemTrackingLines();

            // [WHEN] Successively post the purchase orders with "Receive" option and enabled Code Coverage in order to count calls of SynchronizeItemTracking function in Codeunit 6500.
            CodeCoverageMgt.StartApplicationCoverage();
            PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
            CodeCoverageMgt.StopApplicationCoverage();

            NoOfHits[i] :=
              GetCodeCoverageForObject(
                CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Tracking Management", 'SynchronizeItemTracking');
        end;

        // [THEN] The number of function calls is constant and does not depend on number of item tracking lines on a purchase line.
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHits[1], NoOfHits[2]), NotConstantCalcErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshingProductionOrderForBigFamily()
    var
        ProductionOrder: Record "Production Order";
        FamilyNo: array[2] of Code[20];
        Qty: Decimal;
        NoOfHits: array[2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Family] [Production Order]
        // [SCENARIO 291614] The number of times the program updates Date and Time on a production order does not depend on number of lines in the production order.
        Initialize();

        // [GIVEN] Two Families - one with 10 components, another with 100 components.
        FamilyNo[1] := CreateFamily(10);
        FamilyNo[2] := CreateFamily(100);
        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] The scenario is run twice to collect the statistics.
        for i := 1 to ArrayLen(FamilyNo) do begin
            Clear(ProductionOrder);

            // [GIVEN] Create production order with "Source Type" = Family.
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, FamilyNo[i], Qty);

            // [WHEN] Refresh the production order with activated Code Coverage in order to calculate how many times UpdateDateTime function is called for the production order.
            CodeCoverageMgt.StartApplicationCoverage();
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
            CodeCoverageMgt.StopApplicationCoverage();

            NoOfHits[i] :=
              GetCodeCoverageForObject(
                CodeCoverage."Object Type"::Table, DATABASE::"Production Order", 'UpdateDateTime');
        end;

        // [THEN] The number of function calls is constant and does not depend on number of prod. order lines.
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHits[1], NoOfHits[2]), NotConstantCalcErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculatingWhseAdjustmentForMultipleSerialNos()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        NoOfSN: Integer;
        Iterations: Integer;
        Sign: Integer;
        i: Integer;
    begin
        // [FEATURE] [Warehouse Adjustment] [Adjustment Bin] [Warehouse Item Journal] [Item Tracking]
        // [SCENARIO 317711] Warehouse entries are grouped by serial nos. before they are bufferized to calculate warehouse adjustment.
        Initialize();

        NoOfSN := 10;
        Iterations := 11; // must be odd number in order the sum of quantity for each serial no. will not be 0.

        // [GIVEN] Location with directed put-away and pick.
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);

        // [GIVEN] Serial no. tracked item.
        LibraryItemTracking.CreateSerialItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Step 1.
        // [GIVEN] Create whse. item journal line, quantity = 10.
        // [GIVEN] Assign serial nos. S1, S2, ..., S10.
        // [GIVEN] Register the warehouse adjustment.

        // [GIVEN] Step 2.
        // [GIVEN] Create whse. item journal line, quantity = -10.
        // [GIVEN] Assign serial nos. S1, S2, ..., S10.
        // [GIVEN] Register the warehouse adjustment.

        // [GIVEN] Repeat "Step 1" 6 times and "Step 2" 5 times.
        // [GIVEN] Thus, we make 11 warehouse entries for each serial no.
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        Sign := 1;
        for i := 1 to Iterations do begin
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
              Location.Code, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Sign * NoOfSN);
            LibraryVariableStorage.Enqueue(NoOfSN);
            WarehouseJournalLine.OpenItemTrackingLines();
            LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, false);
            Sign *= -1;
        end;

        // [WHEN] Open item journal and run "Calculate Whse. Adjustment" with activated code coverage in order to count how many times the buffer is updated.
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), LibraryUtility.GenerateGUID());
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] "Qty. to Handle" is updated in the buffer 10 times that is equal to the number of serial nos.
        Assert.AreEqual(
          NoOfSN,
          GetCodeCoverageForObject(
            CodeCoverage."Object Type"::Report, REPORT::"Calculate Whse. Adjustment", 'Qty. to Handle *:'), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LookingThroughOnlyAdjustedSerialNosWhenCollectingItemTrackingForWhseAdjmt()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        NoOfSN: Integer;
        Iterations: Integer;
        Sign: Integer;
        i: Integer;
    begin
        // [FEATURE] [Warehouse Adjustment] [Adjustment Bin] [Warehouse Item Journal] [Item Tracking]
        // [SCENARIO 317711] Calculate whse. adjustment looks through only serial nos. being adjusted when collecting item tracking for a new item journal line.
        Initialize();

        NoOfSN := 10;
        Iterations := 10;

        // [GIVEN] Location with directed put-away and pick.
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);

        // [GIVEN] Serial no. tracked item.
        LibraryItemTracking.CreateSerialItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Step 1.
        // [GIVEN] Create whse. item journal line, quantity = 10.
        // [GIVEN] Assign serial nos. S1, S2, ..., S10.
        // [GIVEN] Register the warehouse adjustment.

        // [GIVEN] Step 2.
        // [GIVEN] Create whse. item journal line, quantity = -10.
        // [GIVEN] Assign serial nos. S1, S2, ..., S10.
        // [GIVEN] Register the warehouse adjustment.

        // [GIVEN] Repeat "Step 1" 5 times and "Step 2" 5 times.
        // [GIVEN] Thus, we make 10 warehouse entries for each serial no.
        // [GIVEN] The sum of each serial no. = 0, so they does not need to be posted in item journal.
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        Sign := 1;
        for i := 1 to Iterations do begin
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
              Location.Code, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Sign * NoOfSN);
            LibraryVariableStorage.Enqueue(NoOfSN);
            WarehouseJournalLine.OpenItemTrackingLines();
            LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, false);
            Sign *= -1;
        end;

        // [GIVEN] Create one whse. item journal line, quantity = 1, assign one serial no. "S1".
        // [GIVEN] Register the warehouse adjustment.
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
          Location.Code, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        LibraryVariableStorage.Enqueue(1);
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, false);

        // [WHEN] Open item journal and run "Calculate Whse. Adjustment" with activated code coverage in order to count how many serial nos. are looked through to collect item tracking.
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), LibraryUtility.GenerateGUID());
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] Only warehouse entries with Serial no. = "S1" are looked through.
        Assert.AreEqual(
          1,
          GetCodeCoverageForObject(
            CodeCoverage."Object Type"::Report, REPORT::"Calculate Whse. Adjustment",
            'WarehouseEntry.SETRANGE*"Serial No."*"Serial No."'), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RegisteringPutAwayWithMultipleSerialNos()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DummyReservEntry: Record "Reservation Entry";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        NoOfSN: array[2] of Integer;
        NoOfHits: array[4] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Put-away] [Item Tracking]
        // [SCENARIO 316492] Poor performance on registering put-away with multiple serial nos.
        Initialize();

        // [GIVEN] Two sets of serial nos. - "S1".."S10", and "T1".."T100".
        NoOfSN[1] := 10;
        NoOfSN[2] := 100;

        // [GIVEN] Location with directed put-away and pick.
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Serial no. tracked item.
        LibraryItemTracking.CreateSerialItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] This section is run twice - the first time for the set "S", the second time for the set "T".
        for i := 1 to ArrayLen(NoOfSN) do begin
            // [GIVEN] Purchase order, assign serial nos.
            LibraryPurchase.CreatePurchaseDocumentWithItem(
              PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", NoOfSN[i], Location.Code, WorkDate());
            LibraryVariableStorage.Enqueue(DummyReservEntry."Item Tracking"::"Serial No.");
            PurchaseLine.OpenItemTrackingLines();

            // [GIVEN] Create and post warehouse receipt.
            LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
            LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
            WarehouseReceiptHeader.Get(
              LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No."));
            LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

            // [GIVEN] A warehouse put-away is created.
            LibraryWarehouse.FindWhseActivityBySourceDoc(
              WarehouseActivityHeader,
              DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");
            LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

            // [WHEN] Turn on Code Coverage and register the put-away. Count the number of times the posted warehouse receipt header and line are updated.
            CodeCoverageMgt.StartApplicationCoverage();
            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
            CodeCoverageMgt.StopApplicationCoverage();

            NoOfHits[i] :=
              GetCodeCoverageForObject(
                CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Whse.-Activity-Register", 'UpdateWhseDocHeader');
            NoOfHits[i + ArrayLen(NoOfSN)] :=
              GetCodeCoverageForObject(
                CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Whse.-Activity-Register", 'UpdatePostedWhseRcptLine');
        end;

        // [THEN] The number of updates does not depend on the number of lines in the put-away.
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHits[1], NoOfHits[2]), NotConstantCalcErr);
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHits[3], NoOfHits[4]), NotConstantCalcErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAdjustmentWhenManyPosEntriesAppliedToFewNegEntries()
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        NoOfEntries: array[3] of Integer;
        NoOfHits: array[3] of Integer;
        TryNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Application]
        // [SCENARIO 341830] Poor cost adjustment performance when many inbound item entries are applied to few outbound entries.
        Initialize();

        NoOfEntries[1] := 4;
        NoOfEntries[2] := 40;
        NoOfEntries[3] := 400;

        for TryNo := 1 to ArrayLen(NoOfEntries) do begin
            LibraryInventory.CreateItem(Item);

            LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
            LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

            // [GIVEN] Try 1: Post 4 positive adjustment entries for item.
            // [GIVEN] Try 2: Post 40 positive adjustment entries for item.
            // [GIVEN] Try 3: Post 400 positive adjustment entries for item.
            for i := 1 to NoOfEntries[TryNo] do begin
                LibraryInventory.CreateItemJournalLine(
                  ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
                  ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
                ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
                ItemJournalLine.Modify(true);
            end;
            LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

            // [GIVEN] Post 2 negative adjustment entries, each for half the item inventory.
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", NoOfEntries[TryNo] / 2);
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", NoOfEntries[TryNo] / 2);
            LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

            // [WHEN] Turn on code coverage and run the cost adjustment.
            CodeCoverageMgt.StartApplicationCoverage();
            LibraryCosting.AdjustCostItemEntries(Item."No.", '');
            CodeCoverageMgt.StopApplicationCoverage();
            NoOfHits[TryNo] :=
              GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Inventory Adjustment", 'CalcNewAdjustedCost');
        end;

        // [THEN] The computational complexity of the outbound entries cost calculation linearly depends on the number of positive adjustments.
        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(NoOfEntries[1], NoOfEntries[2], NoOfEntries[3], NoOfHits[1], NoOfHits[2], NoOfHits[3]),
          NotLinearCCErr);
    end;

    [Test]
    procedure CertifyRoutingWhenEachOperationPointsToTwoNext()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        OperationNo: Code[10];
        NextOperationNo: Code[30];
        NoOfEntries: array[4] of Integer;
        NoOfHits: array[4] of Integer;
        TryNo: Integer;
        i: Integer;
    begin
        Initialize();

        NoOfEntries[1] := 10;
        NoOfEntries[2] := 20;
        NoOfEntries[3] := 30;
        NoOfEntries[4] := 40;

        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        for TryNo := 1 to ArrayLen(NoOfEntries) do begin
            // [GIVEN] Try 1: Routing with 10 lines. Next Operation No. for 01 is '02|03', for 02 is '03|04',..,for 09 is '10', 10 is ''.
            // [GIVEN] Try 2: Routing with 20 lines. Next Operation No. for 01 is '02|03', for 02 is '03|04',..,for 19 is '20', 20 is ''.
            // [GIVEN] Try 3: Routing with 40 lines. Next Operation No. for 01 is '02|03', for 02 is '03|04',..,for 39 is '40', 40 is ''.
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);

            OperationNo := '00';
            for i := 1 to NoOfEntries[TryNo] do begin
                OperationNo := IncStr(OperationNo);
                NextOperationNo := StrSubstNo('%1|%2', IncStr(OperationNo), IncStr(IncStr(OperationNo)));
                if i = NoOfEntries[TryNo] - 1 then
                    NextOperationNo := IncStr(OperationNo);
                if i = NoOfEntries[TryNo] then
                    NextOperationNo := '';
                CreateRoutingLineForWorkCenter(RoutingLine, RoutingHeader, OperationNo, WorkCenter."No.", NextOperationNo);
            end;

            // [WHEN] Turn on code coverage and certify routing.
            CodeCoverageMgt.StartApplicationCoverage();
            UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
            CodeCoverageMgt.StopApplicationCoverage();
            NoOfHits[TryNo] :=
                GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, Codeunit::"Check Routing Lines", 'NameValueBufferEnqueue');
        end;

        // [THEN] Time complexity of certifying routing is better than O(n^2), where n is a number of routing lines that point to the next two lines.
        Assert.IsTrue(
            LibraryCalcComplexity.IsQuadratic(NoOfEntries[1], NoOfEntries[2], NoOfEntries[3], NoOfEntries[4], NoOfHits[1], NoOfHits[2], NoOfHits[3], NoOfHits[4]),
            NotQuadraticCalcErr);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Performance Tests");
        CodeCoverageMgt.StopApplicationCoverage();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Performance Tests");

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        LibraryNotificationMgt.DisableAllNotifications();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Performance Tests");
    end;

    [Normal]
    local procedure CreateLargeNumberOfSN(NoOfSerialNos: Integer; TrackingOption: Enum "Item Tracking Entry Type")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
    begin
        // Setup.
        Initialize();
        Item.Get(
          CreateTrackedItem(LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, true)));
        ReservationEntry.DeleteAll(); // Switch on or off if we want to execute on a clean db.

        // Purchase component with IT.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CheckUpdateVATCalcType(PurchaseHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", NoOfSerialNos);
        UpdateGeneralPostingSetup(PurchaseLine);
        LibraryVariableStorage.Enqueue(TrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();

        // Execute: Try to assign a large number of serial nos in the page handler.

        // Verify: Serial nos. have been created.
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
        Assert.AreEqual(NoOfSerialNos, ReservationEntry.Count, 'Unexpected item tracking entries were created in TAB337.');

        ReservationEntry.SetRange("Item Tracking", TrackingOption);
        Assert.AreEqual(
          NoOfSerialNos, ReservationEntry.Count,
          'Not all expected item tracking entries were created in TAB337.' + ReservationEntry.GetFilters);

        ReservationEntry.FindFirst();
        ReservationEntry2.SetRange("Item No.", Item."No.");
        ReservationEntry2.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry2.SetRange("Item Tracking", TrackingOption);
        ReservationEntry2.SetRange("Lot No.", ReservationEntry."Lot No.");
        Assert.AreEqual(NoOfSerialNos, ReservationEntry2.Count, 'More than one lot no. was created by the batch job.');
    end;

    local procedure CreateItemTrackingCode(SNSpecific: Boolean; LOTSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LOTSpecific);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; Quantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);
        PostInventoryAdjustment(Item."No.", Quantity);
    end;

    local procedure CreateOutputAndSubassemblyItems(var OutputItem: Record Item; var SubasmItem: Record Item)
    var
        ComponentItem: Record Item;
    begin
        LibraryInventory.CreateItemSimple(ComponentItem, ComponentItem."Costing Method"::Average, LibraryPatterns.RandCost(ComponentItem));
        CreateSNTrackedItemWithProduction(SubasmItem, ComponentItem);
        CreateSNTrackedItemWithProduction(OutputItem, SubasmItem);
    end;

    local procedure CreateFamily(NoOfComponents: Integer): Code[20]
    var
        Family: Record Family;
        FamilyLine: Record "Family Line";
        i: Integer;
    begin
        LibraryManufacturing.CreateFamily(Family);
        for i := 1 to NoOfComponents do
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        exit(Family."No.");
    end;

    local procedure CreatePostSalesOrder(Quantity: Decimal) NoOfLinesHit: Integer
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateItemWithInventory(Item, 1);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);

        NoOfLinesHit := GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Reservation Engine Mgt.", '');
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        NoOfLinesHit :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Reservation Engine Mgt.", '') - NoOfLinesHit;
    end;

    local procedure CreateSNTrackedItemWithProduction(var Item: Record Item; ComponentItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        Item.Get(CreateTrackedItem('', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false)));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);

        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, Item, ComponentItem, 1, '');
    end;

    local procedure CreateTrackedItem(LotNos: Code[20]; SerialNos: Code[20]; ItemTrackingCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode);
        exit(Item."No.");
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; Qty: Decimal)
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
    end;

    local procedure UpdateGeneralPostingSetup(PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        if GeneralPostingSetup."Purch. Account" = '' then begin
            GeneralPostingSetup.Validate("Purch. Account", GLAccount."No.");
            GeneralPostingSetup.Modify(true);
        end;
    end;

    local procedure CheckUpdateVATCalcType(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        if VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Full VAT" then
            exit;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup.Modify();
    end;

    local procedure EnablePurchInvDiscountCalculation()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate("Calc. Inv. Discount", true);
        PurchSetup.Modify(true);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
    end;

    local procedure GetPurchaseReceiptLines(PurchaseOrderNo: Code[20]; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure PostInventoryAdjustment(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);
    end;

    local procedure PostProductionJournal(ProductionOrder: Record "Production Order"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdJnlMgt: Codeunit "Production Journal Mgt";
    begin
        LibraryVariableStorage.Enqueue(Format(EntryType));
        FindProdOrderLine(ProdOrderLine, ProductionOrder, ItemNo);

        ProdJnlMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure PostTrackedOutputAndConsumption(OutputItem: Record Item; SubasmItem: Record Item; Quantity: Decimal) NoOfLinesHit: Integer
    var
        ProductionOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, OutputItem, '', '', Quantity, WorkDate());
        PostProductionJournal(ProductionOrder, ItemJnlLine."Entry Type"::Output, SubasmItem."No.");

        NoOfLinesHit := GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Tracking Management", '');
        PostProductionJournal(ProductionOrder, ItemJnlLine."Entry Type"::Consumption, OutputItem."No.");
        NoOfLinesHit :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Item Tracking Management", '') - NoOfLinesHit;
    end;

    [Scope('OnPrem')]
    procedure CreateSendAheadItem(var Item: Record Item): Decimal
    begin
        CreateSetupItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        exit(CreateSendAheadRoutingAndUpdateItem(Item));
    end;

    local procedure CreateSetupItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateSendAheadRoutingAndUpdateItem(Item: Record Item) SendAheadQty: Decimal
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        SendAheadQty := LibraryRandom.RandIntInRange(2, 5);
        CreateSendAheadRoutingLine(RoutingLine, RoutingHeader, LibraryUtility.GenerateGUID(), WorkCenter."No.", SendAheadQty);
        CreateSendAheadRoutingLine(RoutingLine, RoutingHeader, LibraryUtility.GenerateGUID(), WorkCenter."No.", 0);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateSendAheadRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; OperationNo: Code[10]; CenterNo: Code[20]; SendAheadQty: Decimal)
    begin
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQty);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingLineForWorkCenter(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; OperationNo: Code[10]; WorkCenterNo: Code[20]; NextOperationNo: Code[30])
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, "Capacity Type Routing"::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithOneLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal) ShipmentDate: Date
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        ShipmentDate := WorkDate() + LibraryRandom.RandIntInRange(30, 60); // up to 1 - 2 month after WORKDATE
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanWkshWithItemFilterAndPeriod(ItemFilter: Text; FromDate: Date; ToDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter);
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, FromDate, ToDate, true);
    end;

    local procedure CarryOutActionMsgOnPlanningWksh(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.ModifyAll("Accept Action Message", true);
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure PostWhseReceiptFromPurchaseOrder(LocationCode: Code[10]; ItemNo: Code[20]; NoOfLines: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        I: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);

        for I := 1 to NoOfLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
            PurchaseLine.OpenItemTrackingLines();
        end;

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptHeader.SetRange("Location Code", LocationCode);
        WarehouseReceiptHeader.FindFirst();

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ReservationEntry: Record "Reservation Entry";
        OptionValue: Variant;
        TrackingOption: Enum "Item Tracking Entry Type";
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := "Item Tracking Entry Type".FromInteger(OptionValue);  // To convert Variant into Option.
        case TrackingOption of
            ReservationEntry."Item Tracking"::"Serial No.":
                begin
                    LibraryVariableStorage.Enqueue(false); // Create new lot no = false.
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
            ReservationEntry."Item Tracking"::"Lot and Serial No.":
                begin
                    LibraryVariableStorage.Enqueue(true); // Create new lot no = true.
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerSetLotNo(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(1);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        BooleanValue: Variant;
        NewLotNo: Boolean;
    begin
        LibraryVariableStorage.Dequeue(BooleanValue);  // Dequeue variable.
        NewLotNo := BooleanValue;
        EnterQuantityToCreate.CreateNewLotNo.SetValue(NewLotNo);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostJournalWithSNTrackingHandler(var ProductionJournalPage: TestPage "Production Journal")
    var
        ReservEntry: Record "Reservation Entry";
        ItemJnlLine: Record "Item Journal Line";
        EntryType: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryType);

        ProductionJournalPage.FILTER.SetFilter("Entry Type", EntryType);
        ProductionJournalPage.First();

        if ProductionJournalPage."Entry Type".AsInteger() = ItemJnlLine."Entry Type"::Output.AsInteger() then
            LibraryVariableStorage.Enqueue(ReservEntry."Item Tracking"::"Serial No.")
        else
            LibraryVariableStorage.Enqueue(ReservEntry."Item Tracking"::None);
        ProductionJournalPage.ItemTrackingLines.Invoke();

        ProductionJournalPage.Post.Invoke();
        ProductionJournalPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        NoOfSN: Integer;
        i: Integer;
    begin
        NoOfSN := LibraryVariableStorage.DequeueInteger();
        for i := 1 to NoOfSN do begin
            WhseItemTrackingLines."Serial No.".SetValue(Format(i));
            WhseItemTrackingLines.Quantity.SetValue(1);
            WhseItemTrackingLines.Next();
        end;
    end;

    local procedure UpdateMaxCubageAndWeightOnPutAwayBin(LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        Bin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));
        Bin.SetRange("Cross-Dock Bin", false);
        Bin.FindLast();

        Bin.Validate("Maximum Cubage", LibraryRandom.RandInt(100));
        Bin.Validate("Maximum Weight", LibraryRandom.RandInt(100));
        Bin.Modify(true);
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueChangeValueEditor(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    begin
        ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(LibraryUtility.GenerateGUID());
        ItemAttributeValueEditor.OK().Invoke();
    end;
}

