codeunit 137293 "SCM Inventory Miscellaneous"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;
        AutomaticReservationConfirmMsg: Label 'Automatic reservation is not possible.';
        HandlingErr: Label 'Nothing to handle.';
        GlobalDocumentNo: Code[20];
        NothingToCreateMsg: Label 'There is nothing to create.';
        PickActivitiesMsg: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
        TransferOrderDeleteMsg: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 - Transfer Order No.';
        TransferOrderShippingNotErr: Label 'Transfer order should not be completely shipped.';
        TransferOrderShippingErr: Label 'Transfer order should be completely shipped.';
        TransferOrderReceiptErr: Label 'Transfer order should not be completely received.';
        TransferOrderReceiptLineErr: Label 'Transfer line should be completely received.';
        TransferOrderReceiptLineNotErr: Label 'Transfer line is not completely received.';
        TransferOrderShipBatchPostErr: Label 'Transfer Order is not shipped during batch post';
        TransferOrderReceiveBatchPostErr: Label 'Transfer Order is not received during batch post';
        GlobalDocumentNo2: Code[20];
        GlobalQuantity: Decimal;
        GlobalQuantity2: Decimal;
        GlobalMessageCounter: Integer;
        WrongNumberOfOrdersToPrintErr: Label 'Wrong number of transfer orders to print';
        CurrentSaveValuesId: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLinesForDemandLocation()
    var
        Location: Record Location;
    begin
        // Verify Planning Lines for demand location after posting Item Journal and Calculate Regenerative Plan.
        Initialize();
        CreateLocation(Location, false, false, false, false);
        RequisitionLineWithItemJournal(Location.Code, Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLinesForNonDemandLocation()
    var
        ParentItem: Record Item;
        Location: Record Location;
        Location2: Record Location;
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Verify Planning Lines for non demand location after posting Item Journal and Calculate Regenerative Plan.

        // Setup: Update Sales Receivables Setup and Manufacturing Setup. Create two locations. Create Parent Item and Child Item with Variants. Post Negative Adjmt. for Parent Item.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();

        CreateLocation(Location, false, false, false, false);
        CreateLocation(Location2, false, false, false, false);

        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateDemandAsNegativeAdjustment(ParentItem, Location.Code, Quantity);
        FindProductionBOMLine(ProductionBOMLine, ParentItem."Production BOM No.");

        // Exercise: Calculate Regenerative Plan.
        RunCalculateRegenerativePlan(StrSubstNo('%1|%2', ParentItem."No.", ProductionBOMLine."No."), Location2.Code);

        // Verify: Verify Calculated Planning Lines.
        FindRequisitionLine(RequisitionLine, ParentItem."No.", Location2.Code);
        Assert.RecordIsEmpty(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionBOMLine."No.", Location2.Code);
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLinesForBlankLocation()
    var
        Location: Record Location;
    begin
        // Verify Planning Lines for blank location after posting Item Journal and Calculate Regenerative Plan.
        Initialize();
        CreateLocation(Location, false, false, false, false);
        RequisitionLineWithItemJournal(Location.Code, '');  // Use blank for Location Code.
    end;

    local procedure RequisitionLineWithItemJournal(LocationCode: Code[10]; LocationCode2: Code[10])
    var
        ParentItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        Quantity: Decimal;
    begin
        // Setup: Update Sales Receivables Setup and Manufacturing Setup. Create Parent Item and Child Item with Variants. Post Negative Adjmt. for Parent Item.
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();

        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateDemandAsNegativeAdjustment(ParentItem, LocationCode, Quantity);
        FindProductionBOMLine(ProductionBOMLine, ParentItem."Production BOM No.");

        // Exercise: Calculate Regenerative Plan.
        RunCalculateRegenerativePlan(StrSubstNo('%1|%2', ParentItem."No.", ProductionBOMLine."No."), LocationCode2);

        // Verify: Verify Calculated Planning Lines.
        VerifyRequisitionLine(ParentItem."No.", LocationCode, Quantity, '');  // Use blank value for Variant Code.
        VerifyRequisitionLine(ProductionBOMLine."No.", LocationCode, Quantity, ProductionBOMLine."Variant Code");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningLinesForDemandLocationWithPoductionForcast()
    var
        Location: Record Location;
    begin
        // Verify Planning Lines for demand location after creating Production Forecast and Calculate Regenerative Plan.
        Initialize();
        CreateLocation(Location, false, false, false, false);
        RequisitionLineWithForecast(Location.Code, Location.Code);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ForecastWithVariantCodeCreatesReqLineWithVariantCodeWhenVariantSwitchIsONInManufSetup()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastEntry2: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Verify Planning Lines for Production Forecast with Item Variant when 'Use forecast on Variants' is ON and Calculate Regenerative Plan is invoked.

        // Setup: Update Sales Receivables Setup and Manufacturing Setup. 
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();

        // Setup: Create Item with Variants.
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Setup: Create Production Forecast for the first item variant.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", '', ItemVariant.Code, Quantity);

        // Setup: Create Production Forecast for the second item variant.
        LibraryManufacturing.CreateProductionForecastEntry(
                    ProductionForecastEntry2,
                    ProductionForecastEntry."Production Forecast Name",
                    Item."No.", '', ProductionForecastEntry."Forecast Date", false);
        ProductionForecastEntry2.Validate("Variant Code", ItemVariant2.Code);
        ProductionForecastEntry2.Validate("Forecast Quantity (Base)", Quantity * 2);
        ProductionForecastEntry2.Modify(true);

        // Exercise: Calculate Regenerative Plan.
        EnqueueFilters(Item."No.", '', '');
        OpenPlanWkshPageForCalcRegenPlan(CreateRequisitionWorksheetName(PAGE::"Planning Worksheet"));

        // Verify: Verify Calculated Planning Lines.
        FindRequisitionLine(RequisitionLine, Item."No.", '');
        Assert.RecordIsNotEmpty(RequisitionLine);

        // Verify: There are 2 planning lines created
        Assert.RecordCount(RequisitionLine, 2);

        // Verify: The Planning line creted for the first variant
        RequisitionLine.SetRange("Variant Code", ItemVariant.Code);
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        RequisitionLine.TestField("Replenishment System", RequisitionLine."Replenishment System"::Purchase);

        // Verify: The Planning line creted for the second variant
        RequisitionLine.SetRange("Variant Code", ItemVariant2.Code);
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity * 2);
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        RequisitionLine.TestField("Replenishment System", RequisitionLine."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandlerExtended,CarryOutActionMsgPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcOrderPlanRecalculateReqPlanWithFrozenZone()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        BatchName: Code[10];
    begin
        // [FEATURE] [Planning Worksheet] [Production Order] 
        // [SCENARIO 502388] Calculate Order Plan and Recalculate Requisition Plan for Item with Frozen period. 
        // Calculation have the issue just with specific scenario with exact values for dates and Rescheduling Period.
        Initialize();

        // [GIVEN] Create Item with Replenishment System as Prod. Order and Reordering Policy as Lot-for-Lot.
        // [GIVEN] Set Rescheduling Period as 215D as with that exact value system had an issue.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        Item."Reordering Policy" := Item."Reordering Policy"::"Lot-for-Lot";
        Evaluate(Item."Rescheduling Period", '215D');
        Item.Modify();

        // [GIVEN] Create Sales Order with 3 lines same item, different shipment dates.
        CreateSalesOrderWithSameItemAndDifferentShipmentDate(Item);

        // [GIVEN] Calculate Regen Plan for first 2 lines.
        BatchName := CreateRequisitionWorksheetName(PAGE::"Planning Worksheet");
        EnqueueFiltersForCalcRegenPlan(CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()), Item."No.", '', '');
        OpenPlanWkshPageForCalcRegenPlan(BatchName);

        FindRequisitionLine(RequisitionLine, Item."No.", '');
        Assert.AreEqual(RequisitionLine.Count, 2, 'Requisition Line Count is' + Format(RequisitionLine.Count));

        // [GIVEN] Accept and Carry Out Action
        OpenPlanWkshPageForCalcPlanAndCarryOutAction(BatchName);

        // [WHEN] Calculate Regen Plan for 3rd line.
        EnqueueFiltersForCalcRegenPlan(DMY2Date(2, 12, Date2DMY(WorkDate(), 3)), CalcDate('<CY+1Y>', WorkDate()), Item."No.", '', '');
        OpenPlanWkshPageForCalcRegenPlan(BatchName);

        // [THEN] Verify that system generate just one line for the 3rd line of sales order.
        FindRequisitionLine(RequisitionLine, Item."No.", '');
        RequisitionLine.FindLast();
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.TestField("Quantity", 20);
    end;

    local procedure CreateSalesOrderWithSameItemAndDifferentShipmentDate(Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithShipmentDate(SalesHeader, Item."No.", 10, DMY2Date(1, 7, Date2DMY(WorkDate(), 3)));
        CreateSalesLineWithShipmentDate(SalesHeader, Item."No.", 15, DMY2Date(1, 12, Date2DMY(WorkDate(), 3)));
        CreateSalesLineWithShipmentDate(SalesHeader, Item."No.", 20, DMY2Date(1, 2, Date2DMY(WorkDate(), 3) + 1));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesLineWithShipmentDate(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify();
    end;

    local procedure EnqueueFiltersForCalcRegenPlan(FromDate: Date; ToDate: Date; ItemFilter: Text; LocationFilter: Text; VariantFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(FromDate);
        LibraryVariableStorage.Enqueue(ToDate);
        LibraryVariableStorage.Enqueue(ItemFilter);
        LibraryVariableStorage.Enqueue(LocationFilter);
        if VariantFilter <> '' then
            LibraryVariableStorage.Enqueue(VariantFilter);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ForecastWithVariantCodeCreatesReqLineWithoutVariantCodeWhenVariantSwitchIsOFFInManufSetup()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastEntry2: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Verify Planning Lines for Production Forecast with Item Variant when 'Use forecast on Variants' is OFF and Calculate Regenerative Plan is invoked.

        // Setup: Update Sales Receivables Setup and Manufacturing Setup. 
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();

        // Setup: Create Item with Variants.
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Setup: Create Production Forecast for the first item variant.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", '', ItemVariant.Code, Quantity);

        // Setup: Create Production Forecast for the second item variant.
        LibraryManufacturing.CreateProductionForecastEntry(
            ProductionForecastEntry2,
            ProductionForecastEntry."Production Forecast Name",
            Item."No.", '', ProductionForecastEntry."Forecast Date", false);
        ProductionForecastEntry2.Validate("Variant Code", ItemVariant2.Code);
        ProductionForecastEntry2.Validate("Forecast Quantity (Base)", Quantity * 2);
        ProductionForecastEntry2.Modify(true);

        // Setup: Switch OFF 'Use forecast on Variants'
        LibraryPlanning.SetUseForecastOnVariants(false);

        // Exercise: Calculate Regenerative Plan.
        EnqueueFilters(Item."No.", '', '');
        OpenPlanWkshPageForCalcRegenPlan(CreateRequisitionWorksheetName(PAGE::"Planning Worksheet"));

        // Verify: Verify Calculated Planning Lines.
        FindRequisitionLine(RequisitionLine, Item."No.", '');
        Assert.RecordIsNotEmpty(RequisitionLine);

        // Verify: There is 1 planning line created
        Assert.RecordCount(RequisitionLine, 1);

        // Verify: The Planning line created has empty varint code
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity + (Quantity * 2));
        RequisitionLine.TestField("Variant Code", '');
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        RequisitionLine.TestField("Replenishment System", RequisitionLine."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoPlanningLinesCreatedWhenVariantForecastingIsONAndNoForecastEntriesWithVariantsExist()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProductionForecastEntry: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        Location: Record Location;
        Quantity: Decimal;
    begin
        // Verify Planning Lines for Production Forecast with Item Variant when 'Use forecast on Variants' is ON and Calculate Regenerative Plan is invoked.

        // Setup: Update Sales Receivables Setup and Manufacturing Setup. 
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();
        CreateLocation(Location, false, false, false, false);

        // Setup: Create Item with Variants.
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Setup: Create Production Forecast for item with empty variant.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", Location.Code, '', Quantity);

        // Setup: Switch ON 'Use forecast on Variants'
        LibraryPlanning.SetUseForecastOnVariants(true);

        // Exercise: Calculate Regenerative Plan.
        EnqueueFilters(Item."No.", Location.Code, ItemVariant.Code);
        OpenPlanWkshPageForCalcRegenPlan(CreateRequisitionWorksheetName(PAGE::"Planning Worksheet"));

        // Verify: Verify Calculated Planning Lines.
        FindRequisitionLine(RequisitionLine, Item."No.", Location.Code);
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,MessageHandler,PlanningErrorLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoPlanningLinesCreatedWhenVariantForecastingIsOFFAndNoForecastEntriesWithVariantsExist()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProductionForecastEntry: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        Location: Record Location;
        Quantity: Decimal;
    begin
        // Verify Planning Lines for Production Forecast with Item Variant when 'Use forecast on Variants' is OFF and Calculate Regenerative Plan is invoked.

        // Setup: Update Sales Receivables Setup and Manufacturing Setup. 
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();
        CreateLocation(Location, false, false, false, false);

        // Setup: Create Item with Variants.
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Setup: Create Production Forecast for item with empty variant.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", Location.Code, '', Quantity);

        // Setup: Switch OFF 'Use forecast on Variants'
        LibraryPlanning.SetUseForecastOnVariants(false);

        // Exercise: Calculate Regenerative Plan.
        EnqueueFilters(Item."No.", Location.Code, ItemVariant.Code);
        OpenPlanWkshPageForCalcRegenPlan(CreateRequisitionWorksheetName(PAGE::"Planning Worksheet"));

        // Verify: Verify Calculated Planning Lines.
        FindRequisitionLine(RequisitionLine, Item."No.", Location.Code);
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningLinesCreatedWhenVariantForecastingIsONAndForecastEntriesWithNoVariantsExist()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProductionForecastEntry: Record "Production Forecast Entry";
        //ProductionForecastEntry2: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        Location: Record Location;
        Quantity: Decimal;
    begin
        // Verify Planning Lines for Production Forecast with Item Variant when 'Use forecast on Variants' is OFF and Calculate Regenerative Plan is invoked.

        // Setup: Update Sales Receivables Setup and Manufacturing Setup. 
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();
        CreateLocation(Location, false, false, false, false);

        // Setup: Create Item with Variants.
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Setup: Create Production Forecast for the first item variant.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", Location.Code, '', Quantity);

        // Setup: Switch OFF 'Use forecast on Variants' on Manufacturing Setup
        LibraryPlanning.SetUseForecastOnVariants(true);

        // Exercise: Calculate Regenerative Plan.
        EnqueueFilters(Item."No.", Location.Code, '');
        OpenPlanWkshPageForCalcRegenPlan(CreateRequisitionWorksheetName(PAGE::"Planning Worksheet"));

        // Verify: Verify Calculated Planning Lines.
        FindRequisitionLine(RequisitionLine, Item."No.", Location.Code);
        Assert.RecordIsNotEmpty(RequisitionLine);

        // Verify: There is 1 planning line created
        Assert.RecordCount(RequisitionLine, 1);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningLinesForNonDemandLocationWithPoductionForcast()
    var
        ParentItem: Record Item;
        Location: Record Location;
        Location2: Record Location;
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Verify Planning Lines for non demand location after creating Production Forecast and Calculate Regenerative Plan.

        // Setup: Update Sales Receivables Setup and Manufacturing Setup. Create two locations. Create Parent Item and Child Item with Variant. Create Production Forecast for Parent Item.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();

        CreateLocation(Location, false, false, false, false);
        CreateLocation(Location2, false, false, false, false);

        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateDemandAsForecast(ParentItem, Location.Code, Quantity);
        FindProductionBOMLine(ProductionBOMLine, ParentItem."Production BOM No.");

        // Exercise: Calculate Regenerative Plan.
        EnqueueFilters(StrSubstNo('%1|%2', ParentItem."No.", ProductionBOMLine."No."), Location2.Code, '');
        OpenPlanWkshPageForCalcRegenPlan(CreateRequisitionWorksheetName(PAGE::"Planning Worksheet"));

        // Verify: Verify Calculated Planning Lines.
        FindRequisitionLine(RequisitionLine, ParentItem."No.", Location2.Code);
        Assert.RecordIsEmpty(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionBOMLine."No.", Location2.Code);
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningLinesForBlankLocationWithPoductionForcast()
    var
        Location: Record Location;
    begin
        // Verify Planning Lines for blank location after creating Production Forecast and Calculate Regenerative Plan.

        Initialize();
        CreateLocation(Location, false, false, false, false);
        RequisitionLineWithForecast(Location.Code, '');  // Use blank for Location Code.
    end;

    local procedure RequisitionLineWithForecast(LocationCode: Code[10]; LocationCode2: Code[10])
    var
        ParentItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        Quantity: Decimal;
    begin
        // Setup: Update Sales Receivables Setup and Manufacturing Setup. Create two locations. Create Parent Item and Child Item with Variant. Create Production Forecast for Parent Item.
        Quantity := LibraryRandom.RandInt(10);  // Use Random value for Quantity.
        SetupSalesAndManufacturingSetup();

        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateDemandAsForecast(ParentItem, LocationCode, Quantity);
        FindProductionBOMLine(ProductionBOMLine, ParentItem."Production BOM No.");
        EnqueueFilters(StrSubstNo('%1|%2', ParentItem."No.", ProductionBOMLine."No."), LocationCode2, '');

        // Exercise: Calculate Regenerative Plan.
        OpenPlanWkshPageForCalcRegenPlan(CreateRequisitionWorksheetName(PAGE::"Planning Worksheet"));

        // Verify: Verify Calculated Planning Lines.
        VerifyRequisitionLine(ParentItem."No.", LocationCode, Quantity, '');  // Use blank value for Variant Code.
        VerifyRequisitionLine(ProductionBOMLine."No.", LocationCode, Quantity, ProductionBOMLine."Variant Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotCompletelyShippedOnPostTransferOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
        Delta: Decimal;
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378398] Field "Completely Shipped" in Tranfer Header should be FALSE when line with partly shipped exist.
        Initialize();

        // [GIVEN] Create Item and Location.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Delta := LibraryRandom.RandInt(99);
        Quantity := LibraryRandom.RandIntInRange(Delta + 1, 200);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [WHEN] Post partly shipping in transfer order.
        CreateTransferHeaderAndTransferLineWithChangedQtytoShip(
          TransferHeader, TransferLine, Item."No.", Location.Code, Quantity, Quantity - Delta);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        TransferHeader.CalcFields("Completely Shipped");

        // [THEN] "Completely Shipped" field in Tranfer Header should be FALSE.
        Assert.IsFalse(TransferHeader."Completely Shipped", TransferOrderShippingNotErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompletelyShippedOnPostTransferOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
        Delta: Decimal;
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378398] Field "Completely Shipped" in Tranfer Header should be TRUE when all lines in it are completely shipped.
        Initialize();

        // [GIVEN] Create Item and Location.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Delta := LibraryRandom.RandInt(99);
        Quantity := LibraryRandom.RandIntInRange(Delta + 1, 200);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [WHEN] Post completely shipping in transfer order.
        CreateTransferHeaderAndTransferLine(TransferHeader, TransferLine, Item."No.", Location.Code, Quantity);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        TransferHeader.CalcFields("Completely Shipped");

        // [THEN] "Completely Shipped" field in Tranfer Header should be TRUE.
        Assert.IsTrue(TransferHeader."Completely Shipped", TransferOrderShippingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompletelyReceivedOnPostTransferOrder()
    var
        Item: array[2] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: array[2] of Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
        Delta: Decimal;
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378398] Field "Completely Received" in Tranfer Header should be FALSE whenever the Transfer Order isn't post completely.
        Initialize();

        // [GIVEN] Create Location.
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Create Item1 and Item2.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create and post Item Journal Line for having items in inventory.
        Delta := LibraryRandom.RandInt(99);
        Quantity := LibraryRandom.RandIntInRange(Delta + 1, 200);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item[1]."No.", Location.Code, Quantity, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item[2]."No.", Location.Code, Quantity, false);

        // [GIVEN] Post shipping and receipt in transfer order partly for line with Item2 and completely for line with Item1.
        CreateAndPostShippingAndReceiptInTransferOrderWithTwoLines(
          TransferHeader, TransferLine, Item, Location.Code, Quantity, Quantity - Delta);

        // [GIVEN] "Completely Received" field in Tranfer Header should be FALSE.
        Assert.IsFalse(TransferHeader."Completely Received", TransferOrderReceiptErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompletelyReceivedOnPostTransferOrderLines()
    var
        Item: array[2] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: array[2] of Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
        Delta: Decimal;
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378398] Field "Completely Received" in Tranfer Line should be TRUE when received quantity equal to quantity in Tranfer Line.
        Initialize();

        // [GIVEN] Create Location.
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Create Item1 and Item2.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create and post Item Journal Line for having items in inventory.
        Delta := LibraryRandom.RandInt(99);
        Quantity := LibraryRandom.RandIntInRange(Delta + 1, 200);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item[1]."No.", Location.Code, Quantity, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item[2]."No.", Location.Code, Quantity, false);

        // [GIVEN] Post shipping and receipt in transfer order completely for line with Item1 and partly for line with Item2.
        CreateAndPostShippingAndReceiptInTransferOrderWithTwoLines(
          TransferHeader, TransferLine, Item, Location.Code, Quantity, Quantity - Delta);

        // [GIVEN] "Completely Received" field in Tranfer Line should be TRUE.
        Assert.IsTrue(TransferLine[1]."Completely Received", TransferOrderReceiptLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotCompletelyReceivedOnPostTransferOrderLines()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
        Delta: Decimal;
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378398] Field "Completely Received" in Tranfer Line should be FALSE when received quantity isn't equal to quantity in Tranfer Line.
        Initialize();

        // [GIVEN] Create Item and Location.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Delta := LibraryRandom.RandInt(99);
        Quantity := LibraryRandom.RandIntInRange(Delta + 1, 200);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [GIVEN] Post shipping and receipt in transfer order partly for line with Item.
        CreateAndPostShippingAndReceiptInTransferOrder(TransferLine, Item."No.", Location.Code, Quantity, Quantity - Delta);

        // [GIVEN] "Completely Received" field in Tranfer Line should be FALSE.
        Assert.IsFalse(TransferLine."Completely Received", TransferOrderReceiptLineNotErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BatchPostTransferOrders')]
    procedure BatchPostShipTransferOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        TransferLine2: Record "Transfer Line";
        BatchPostTransferOrders: Report "Batch Post Transfer Orders";
        TransferHeaderFilter: Text[100];
        Quantity: Decimal;
        TransferFilterLbl: Label '%1|%2', Comment = '%1 = Transfer Header code, %2 = Transfer Header code';
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Batch Post Tranfser Order without any errors.
        Initialize();

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Quantity := LibraryRandom.RandDec(100, 0);  // Use Random value for Quantity.
        CreateItem(Item, Item."Replenishment System"::" ");
        CreateLocation(Location, false, false, false, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [GIVEN] Craeate and release Transfer Orders.
        CreateAndReleaseTransferOrder(TransferLine, Item."No.", Location.Code, false, false, Quantity / 2, false);
        CreateAndReleaseTransferOrder(TransferLine2, Item."No.", Location.Code, false, false, Quantity / 2, false);
        TransferHeaderFilter := StrSubstNo(TransferFilterLbl, TransferLine."Document No.", TransferLine2."Document No.");

        // [WHEN] Batch Post Transfer Order - Ship
        Commit();
        LibraryVariableStorage.Enqueue(TransferHeaderFilter);
        LibraryVariableStorage.Enqueue(0);
        BatchPostTransferOrders.Run();

        // [THEN] All transfer orders are shipped
        Assert.AreEqual(Quantity, TransferShipmentLineTotalQuantity(TransferHeaderFilter), TransferOrderShipBatchPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BatchPostTransferOrders')]
    procedure BatchPostDirectTransferTransferOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        TransferLine2: Record "Transfer Line";
        BatchPostTransferOrders: Report "Batch Post Transfer Orders";
        TransferHeaderFilter: Text[100];
        Quantity: Decimal;
        TransferFilterLbl: Label '%1|%2', Comment = '%1 = Transfer Header code, %2 = Transfer Header code';
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Batch Post Tranfser Order without any errors.
        Initialize();

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Quantity := LibraryRandom.RandDec(100, 0);  // Use Random value for Quantity.
        CreateItem(Item, Item."Replenishment System"::" ");
        CreateLocation(Location, false, false, false, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [GIVEN] Craeate and release Transfer Orders.
        CreateAndReleaseTransferOrder(TransferLine, Item."No.", Location.Code, false, false, Quantity / 2, true);
        CreateAndReleaseTransferOrder(TransferLine2, Item."No.", Location.Code, false, false, Quantity / 2, true);
        TransferHeaderFilter := StrSubstNo(TransferFilterLbl, TransferLine."Document No.", TransferLine2."Document No.");

        // [WHEN] Batch Post Transfer Order
        Commit();
        LibraryVariableStorage.Enqueue(TransferHeaderFilter);
        LibraryVariableStorage.Enqueue(1);
        BatchPostTransferOrders.Run();

        // [THEN] if all transfer orders are shipped and received
        Assert.AreEqual(Quantity, TransferReceiptLineTotalQuantity(TransferHeaderFilter), TransferOrderReceiveBatchPostErr);
        Assert.AreEqual(Quantity, TransferShipmentLineTotalQuantity(TransferHeaderFilter), TransferOrderShipBatchPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BatchPostTransferOrders')]
    procedure BatchPostReceiveTransferOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        TransferLine2: Record "Transfer Line";
        BatchPostTransferOrders: Report "Batch Post Transfer Orders";
        TransferHeaderFilter: Text[100];
        Quantity: Decimal;
        TransferFilterLbl: Label '%1|%2', Comment = '%1 = Transfer Header code, %2 = Transfer Header code';
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Batch Post Tranfser Order without any errors.
        Initialize();

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Quantity := LibraryRandom.RandDec(100, 0);  // Use Random value for Quantity.
        CreateItem(Item, Item."Replenishment System"::" ");
        CreateLocation(Location, false, false, false, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [GIVEN] Create and release Transfer Orders.
        CreateAndReleaseTransferOrder(TransferLine, Item."No.", Location.Code, false, false, Quantity / 2, false);
        CreateAndReleaseTransferOrder(TransferLine2, Item."No.", Location.Code, false, false, Quantity / 2, false);
        TransferHeaderFilter := StrSubstNo(TransferFilterLbl, TransferLine."Document No.", TransferLine2."Document No.");

        // [WHEN] Batch Post Transfer Order - Ship
        Commit();
        LibraryVariableStorage.Enqueue(TransferHeaderFilter);
        LibraryVariableStorage.Enqueue(0);
        BatchPostTransferOrders.Run();

        // [WHEN] Batch Post Transfer Order - Receive
        Commit();
        LibraryVariableStorage.Enqueue(TransferHeaderFilter);
        LibraryVariableStorage.Enqueue(1);
        BatchPostTransferOrders.Run();

        // [THEN] All transfer orders are shipped
        Assert.AreEqual(Quantity, TransferReceiptLineTotalQuantity(TransferHeaderFilter), TransferOrderShipBatchPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BatchPostTransferOrders,ErrorMessageTransferOrderPageHandler')]
    procedure BatchPostReceiveTransferOrderWithTwoNotShipped()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        TransferLine2: Record "Transfer Line";
        TransferLine3: Record "Transfer Line";
        BatchPostTransferOrders: Report "Batch Post Transfer Orders";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        TransferHeaderFilter: Text[100];
        Quantity: Decimal;
        TransferFilterLbl: Label '%1|%2|%3', Comment = '%1 = Transfer Header code, %2 = Transfer Header code, %3 = Transfer Header code';
        ExpectedErrorMsg: Label 'An error or warning occured during operation Batch post Transfer Order record.', Locked = true;
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Batch Post three Tranfser Orders with option receive and two orders aren't shipped.
        Initialize();

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Quantity := 15;  // Use Random value for Quantity.
        CreateItem(Item, Item."Replenishment System"::" ");
        CreateLocation(Location, false, false, false, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [GIVEN] Create and release Transfer Orders.
        CreateAndReleaseTransferOrder(TransferLine, Item."No.", Location.Code, false, false, Quantity / 3, false);
        CreateAndReleaseTransferOrder(TransferLine2, Item."No.", Location.Code, false, false, Quantity / 3, false);
        CreateAndReleaseTransferOrder(TransferLine3, Item."No.", Location.Code, false, false, Quantity / 3, false);
        TransferHeaderFilter := StrSubstNo(TransferFilterLbl, TransferLine."Document No.", TransferLine2."Document No.", TransferLine3."Document No.");

        // [WHEN] Batch Post only one Transfer Order - Ship
        Commit();
        LibraryVariableStorage.Enqueue(TransferLine."Document No.");
        LibraryVariableStorage.Enqueue(0);
        BatchPostTransferOrders.Run();

        // [WHEN] Batch Post all Transfer Order - Receive
        Commit();
        LibraryVariableStorage.Enqueue(TransferHeaderFilter);
        LibraryVariableStorage.Enqueue(1);
        BatchPostTransferOrders.Run();

        // [THEN] An error is expected
        Assert.AreEqual(ExpectedErrorMsg, LibraryVariableStorage.DequeueText(), TransferOrderReceiveBatchPostErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BatchPostTransferOrders,ErrorMessageTransferOrderPageHandler')]
    procedure BatchPostShipTransferOrderWithNoQuantity()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        TransferLine2: Record "Transfer Line";
        TransferLine3: Record "Transfer Line";
        BatchPostTransferOrders: Report "Batch Post Transfer Orders";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        TransferHeaderFilter: Text[100];
        Quantity: Decimal;
        TransferFilterLbl: Label '%1|%2|%3', Comment = '%1 = Transfer Header code, %2 = Transfer Header code, %3 = Transfer Header code';
        ExpectedErrorMsg: Label 'An error or warning occured during operation Batch post Transfer Order record.', Locked = true;
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Batch Post three Tranfser Orders with option ship and one Transfer Order has quantity zero.
        Initialize();

        // [GIVEN] Create and post Item Journal Line for having item in inventory.
        Quantity := 10;  // Use Random value for Quantity.
        CreateItem(Item, Item."Replenishment System"::" ");
        CreateLocation(Location, false, false, false, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // [GIVEN] Create and release Transfer Orders.
        CreateTransferOrder(TransferLine, Item."No.", Location.Code, false, false, Quantity / 2, false);
        CreateTransferOrder(TransferLine2, Item."No.", Location.Code, false, false, 0, false);
        CreateTransferOrder(TransferLine3, Item."No.", Location.Code, false, false, Quantity / 2, false);
        TransferHeaderFilter := StrSubstNo(TransferFilterLbl, TransferLine."Document No.", TransferLine2."Document No.", TransferLine3."Document No.");

        // [WHEN] Batch Post all Transfer Orders - Ship
        Commit();
        LibraryVariableStorage.Enqueue(TransferHeaderFilter);
        LibraryVariableStorage.Enqueue(0);
        BatchPostTransferOrders.Run();

        // [THEN] One Transfer Order has an error
        Assert.AreEqual(ExpectedErrorMsg, LibraryVariableStorage.DequeueText(), TransferOrderReceiveBatchPostErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler')]
    [Scope('OnPrem')]
    procedure GetWarehouseDocumentOnPickWorksheet()
    var
        Customer: Record Customer;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Verify Pick Worksheet after Get Warehouse Documents functionality.

        // Setup: Create initial setup for Pick Worksheet.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);  // Use Random value for Quantity.
        CreateFullWarehouseSetup(Location);
        GlobalDocumentNo :=
          CreateInitialSetupForPickWorksheet(SalesLine, CreateCustomer('', Customer.Reserve::Never), Location.Code, Quantity);  // Assign in global variable.

        // Exercise: Invoke Get Warehouse Documents from Pick Worksheet.
        GetWarehouseDocumentFromPickWorksheet();

        // Verify: Verify Pick Worksheet Line.
        VerifyPickWorksheet(SalesLine, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler,MessageHandler,AutomaticReservationConfirmHandler,CreatePickHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ReserverdQuantityOnSalesOrderAfterPick()
    var
        Customer: Record Customer;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerNo: Code[20];
        Quantity: Decimal;
        QuantityToHandle: Decimal;
    begin
        // Verify Reserved Quantity on Sales Line after creating Pick from Pick Worksheet when Customer has Reserve as Always.

        // Setup: Create initial setup for Pick Worksheet. Get Warehouse Document and create Pick. Create Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);  // Use Random value for Quantity.
        CreateFullWarehouseSetup(Location);

        // Create Setup for Pick Worksheet, Get Warehous document and Create Pick.
        CustomerNo := CreateCustomer(Location.Code, Customer.Reserve::Always);
        GlobalDocumentNo := CreateInitialSetupForPickWorksheet(SalesLine, CustomerNo, Location.Code, Quantity);  // Assign in global variable.
        QuantityToHandle := Quantity - SalesLine.Quantity;
        CreatePickFromPickWorksheet();

        CreateSalesOrder(SalesLine, CustomerNo, SalesLine."No.", Location.Code, 1);  // Quantity is not important.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise: Enter Quantity on Sales Order page.
        OpenSalesOrderToEnterQuantity(SalesHeader."No.", Quantity);

        // Verify: Verify Reserved Quantity on Sales Line.
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", QuantityToHandle);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler,MessageHandler,CreatePickHandler,AutomaticReservationConfirmHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PickWorksheetWithReservation()
    var
        Customer: Record Customer;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Quantity: Decimal;
        QuantityToHandle: Decimal;
        CustomerNo: Code[20];
    begin
        // Verify Pick Worksheet Line after Get Warehouse Documents functionality when Customer has Reserve as Always.

        // Setup: Create initial setup for Pick Worksheet. Get Warehouse Document and Create Pick. Create and release Sales Order and Warehouse Shipment.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);  // Use Random value for Quantity.
        CreateFullWarehouseSetup(Location);

        // Create Setup for Pick Worksheet, Get Warehous document and Create Pick.
        CustomerNo := CreateCustomer(Location.Code, Customer.Reserve::Always);
        CreateInitialSetupForPickWorksheet(SalesLine, CustomerNo, Location.Code, Quantity);
        QuantityToHandle := Quantity - SalesLine.Quantity;
        CreatePickFromPickWorksheet();

        // Create Sales Order, Release Order and Warehouse Shipment.
        CreateSalesOrder(SalesLine, CustomerNo, SalesLine."No.", Location.Code, 1);  // Quantity is not important.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        OpenSalesOrderToEnterQuantity(SalesHeader."No.", Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesLine);
        GlobalDocumentNo := WarehouseShipmentHeader."No.";  // Assign in global variable.

        // Exercise: Invoke Get Warehouse Documents from Pick Worksheet.
        GetWarehouseDocumentFromPickWorksheet();

        // Verify: Verify Pick Worksheet Line.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", Location.Code);
        VerifyPickWorksheet(SalesLine, QuantityToHandle);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleWarehouseShipmentFromSalesOrder()
    var
        Location: Record Location;
        Location2: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Verify multiple Warehouse Shipments created from Sales Order.

        // Setup: Create and release Sales Order with multiple lines.
        Initialize();
        CreateLocation(Location, true, true, false, false);
        CreateLocation(Location2, true, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location2.Code, false);

        CreateSalesOrderWithMultipleLines(SalesHeader, Location.Code, Location2.Code);

        // Exercise: Create Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify created Warehouse Shipments.
        FindWhseShipmentNo(SalesHeader."No.", Location.Code);
        FindWhseShipmentNo(SalesHeader."No.", Location2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrder()
    var
        Location: Record Location;
        Location2: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Verify Warehouse Shipment is created from Sales Order after adding a new Sales Line.

        // Setup: Create and release Sales Order with multiple lines and create Warehouse Shipment. Add new Sales Line.
        Initialize();
        CreateLocation(Location, true, true, false, false);
        CreateLocation(Location2, true, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location2.Code, false);

        CreateSalesOrderWithMultipleLines(SalesHeader, Location.Code, Location2.Code);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", Location2.Code);
        CreateAndUpdateSalesLine(SalesLine, SalesHeader, SalesLine."No.", LibraryRandom.RandDec(100, 2), Location2.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Create Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify created Warehouse Shipments.
        FindWhseShipmentNo(SalesHeader."No.", Location2.Code);
    end;

    [Test]
    [HandlerFunctions('PickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromTransferOrder()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // Verify Inventory Pick created from Transfer Order.

        // Setup: Create Transfer Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateInitialSetupForTransferOrder(TransferLine, Item."No.", true, false, false, false);

        // Exercise: Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferLine."Document No.", false, true, false);

        // Verify: Verify Inventory Pick created from Transfer Order.
        VerifyInventoryPutAwayPick(
          TransferLine."Document No.", TransferLine."Transfer-from Code", TransferLine."Item No.", TransferLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure RecreatePickFromTransferOrder()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // Verify Inventory Pick is not created again from Transfer Order if it is already created.

        // Setup: Create Transfer Order and create Inventory Pick.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateInitialSetupForTransferOrder(TransferLine, Item."No.", true, false, false, false);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferLine."Document No.", false, true, false);

        // Exercise: Re-create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferLine."Document No.", false, true, false);

        // Verify: Verification done in PickActivitiesMessageHandler.
    end;

    [Test]
    [HandlerFunctions('TransferOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayFromTransferOrder()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Verify Inventory Put-away created from Transfer Order.

        // Setup: Create and Ship Transfer Order. Create Warehouse Receipt.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateInitialSetupForTransferOrder(TransferLine, Item."No.", false, false, true, true);

        TransferHeader.Get(TransferLine."Document No.");
        GlobalDocumentNo := TransferHeader."No.";  // Assign in Global variable.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        SelectWarehouseReceiptLine(WarehouseReceiptLine, TransferHeader."No.", WarehouseReceiptLine."Source Document"::"Inbound Transfer");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify Inventory Put-away created from Transfer Order.
        VerifyInventoryPutAwayPick(TransferHeader."No.", TransferLine."Transfer-to Code", TransferLine."Item No.", TransferLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TransferLineDimension()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // Verify Dimension on Transfer Line.

        // Setup: Create Item with Dimension and Post Item Journal Line.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random value for Quantity.
        CreateItem(Item, Item."Replenishment System"::" ");
        UpdateItemDimension(DefaultDimension, Item."No.");
        CreateLocation(Location, false, false, false, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity, false);

        // Exercise.
        CreateAndReleaseTransferOrder(TransferLine, Item."No.", Location.Code, false, false, Quantity, false);

        // Verify: Verify Dimension on Transfer Line.
        VerifyDimensionOnTransferLine(DefaultDimension, TransferLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationOutboundWhseHandlingTime()
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
    begin
        // Verify Planned Shipment Date on Sales Line after setting the Outbound Whse. Handling Time on Location.

        // Setup: Create and modify Location for Outbound Whse. Handling Time and Create Item.
        Initialize();
        CreateAndModifyLocation(Location);
        CreateItem(Item, Item."Replenishment System"::Purchase);

        // Exercise.
        CreateSalesOrder(
          SalesLine, CreateCustomer(Location.Code, Customer.Reserve::Optional), Item."No.", Location.Code, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Verify.
        SalesLine.TestField("Planned Shipment Date", CalcDate(Location."Outbound Whse. Handling Time", SalesLine."Shipment Date"));
    end;

    [Test]
    [HandlerFunctions('PickActivitiesMessageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AssignTrackingToInventoryPickAndPost()
    var
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LotNo: Code[50];
    begin
        // Verify Tracking on Posted Inventory Pick when Tracking is assigned on Inventory Pick.

        // Setup: Post Item with tracking. Create and release Transfer Order. Create Inventory Pick. Assign Tracking to Inventory Pick.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID(); // for ItemTrackingLinesPageHandler
        LibraryVariableStorage.Enqueue(LotNo);
        CreateWarehouseActivityHeader(WarehouseActivityHeader, TransferLine, LotNo);

        // Exercise: Post Inventory Pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // Verify: Verify Posted Inventory Pick created from Transfer Order.
        VerifyPostedInventoryPick(
          TransferLine."Document No.", TransferLine."Transfer-from Code", TransferLine."Item No.", TransferLine.Quantity, LotNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PickActivitiesMessageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AssignTrackingToTransferOrderAndPostInventoryPick()
    var
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
    begin
        // Verify Tracking on Posted Inventory Pick when Tracking is assigned on Transfer Order.

        // Setup: Post Item with Tracking. Create and release Transfer Order. Assign Tracking to Transfer Order. Create Inventory Pick.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo); // for ItemTrackingLinesPageHandler
        LibraryVariableStorage.Enqueue(LotNo); // for ItemTrackingLinesPageHandler
        CreateInitialSetupForTransferOrder(TransferLine, CreateLotTrackedItem(), true, true, false, false);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferLine."Document No.", false, true, false);
        FindWarehouseActivityNo(WarehouseActivityLine, TransferLine."Document No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // Exercise: Post Inventory Pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // Verify: Verify Posted Inventory Pick created from Transfer Order.
        VerifyPostedInventoryPick(
          TransferLine."Document No.", TransferLine."Transfer-from Code", TransferLine."Item No.", TransferLine.Quantity, LotNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderOutboundWhseHandlingTime()
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        HandlingTime: DateFormula;
    begin
        // Verify Planned Delivery Date and Planned Shipment Date on Sales Line after setting the Outbound Whse. Handling Time on Location Card and Sales Order.

        // Setup: Create and modify Location for Outbound Whse. Handling Time and Create Item.
        Initialize();
        CreateAndModifyLocation(Location);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateSalesOrder(
          SalesLine, CreateCustomer(Location.Code, Customer.Reserve::Optional), Item."No.", Location.Code, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        Evaluate(HandlingTime, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');  // Use Random value for Outbound Whse. Handling Time.
        SalesHeader.Validate("Outbound Whse. Handling Time", HandlingTime);
        SalesHeader.Modify(true);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // Verify.
        SalesLine.TestField("Planned Delivery Date", CalcDate(SalesHeader."Outbound Whse. Handling Time", SalesLine."Shipment Date"));
        SalesLine.TestField("Planned Shipment Date", CalcDate(SalesHeader."Outbound Whse. Handling Time", SalesLine."Shipment Date"));
    end;

    [Test]
    [HandlerFunctions('CalculatePlanReqWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionLineForItemWithSKU()
    var
        Location: Record Location;
        RequisitionLine: Record "Requisition Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Quantity: Decimal;
    begin
        // Verify Requisition Line is created for Transfer when Item involved in Sales Order has SKU parameters set.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        LibraryWarehouse.CreateLocation(Location);
        SetupForRequisitionWorksheet(StockkeepingUnit, Location.Code, Quantity);

        // Exercise: Open Requisition Worksheet for Calculate Plan and Carry Out Action Message.
        OpenReqWkshPageForCalcPlanAndCarryOutAction(CreateRequisitionWorksheetName(PAGE::"Req. Worksheet"), false);

        // Verify: Verify Quantity on Requisition Line which is created for Transfer.
        FindRequisitionLine(RequisitionLine, StockkeepingUnit."Item No.", Location.Code);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Replenishment System", StockkeepingUnit."Replenishment System");
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanReqWkshRequestPageHandler,CarryOutActionMsgRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderCreatedFromRequisitionWorksheet()
    var
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Quantity: Decimal;
    begin
        // Verify Tranfer Order is created using Requisition Worksheet when Item involved in Sales Order has SKU parameters set.

        // Setup.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        SetupForRequisitionWorksheet(StockkeepingUnit, Location.Code, Quantity);

        // Exercise: Open Requisition Worksheet for Calculate Plan and Carry Out Action Message.
        OpenReqWkshPageForCalcPlanAndCarryOutAction(CreateRequisitionWorksheetName(PAGE::"Req. Worksheet"), true);

        // Verify: Verify that Transfer Order is created and verify Quantity on Transfer Line.
        VerifyTransferOrder(StockkeepingUnit."Transfer-from Code", Location.Code, StockkeepingUnit."Item No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailablePurchaseLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnSalesOrderWithMultipleLines()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
        LocationCode: Code[10];
    begin
        // Verify Reservation On Sales Order With Multiple Lines.

        // Setup: Create Location, Purchase Orders and sales Order.
        Initialize();
        LocationCode := CreateLocationWithBin();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);
        CreateAndReleasePurchaseOrder(PurchaseLine, Item."No.", LocationCode, LibraryRandom.RandDec(10, 2));  // Use random for Quantity.
        CreateAndReleasePurchaseOrder(PurchaseLine2, Item."No.", LocationCode, LibraryRandom.RandDec(10, 2));  // Use random for Quantity.

        // Assign values in global variables to verify in 'AvailablePurchaseLinesPageHandler'.
        GlobalDocumentNo := PurchaseLine."Document No.";
        GlobalDocumentNo2 := PurchaseLine2."Document No.";
        GlobalQuantity := PurchaseLine.Quantity;
        GlobalQuantity2 := PurchaseLine2.Quantity;
        CreateAndModifySalesOrder(SalesLine, LocationCode, Item."No.");

        // Exercise: Open Reservation page from Sales Order to Drilldown Total Quantity.
        OpenSalesOrderToReserve(SalesLine."Document No.");

        // Verification done in AvailablePurchaseLinesPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickErrorWithoutRegisterPutAway()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Verify handling error when PutAway is created but not Registered.

        // Setup: Create Location and Warehouse Employee, Wharehouse Receipt and Warehouse Shipment.
        Initialize();
        CreateWhseReceiptAndWhseShipmentWithBin(WarehouseReceiptLine, WarehouseShipmentLine);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        // Exercise.
        asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify handling error when PutAway is created but not Registered.
        Assert.ExpectedError(HandlingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOnWarehouseActivityLine()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinCode: Code[20];
    begin
        // Verify Bin Code on created Pick after Put Away is Registered.

        // Setup: Create Warehouse Receipt and Warehouse Shipment, Register Put Away.
        Initialize();
        CreateWhseReceiptAndWhseShipmentWithBin(WarehouseReceiptLine, WarehouseShipmentLine);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        BinCode := RegisterWarehouseActivitywithBin(WarehouseReceiptLine."Source No.");

        // Exercise.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify Bin Code on Warehouse Pick.
        VerifyBinOnWarehousePick(WarehouseShipmentLine."Location Code", BinCode, WarehouseShipmentLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentBeforeShippingSalesOrder()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinCode: Code[20];
    begin
        // Verify Bin Content after Put Away is Registered but before posting Sales Order.

        // Setup: Create Warehouse Receipt and Warehouse Shipment, Register Put Away.
        Initialize();
        CreateWhseReceiptAndWhseShipmentWithBin(WarehouseReceiptLine, WarehouseShipmentLine);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        BinCode := RegisterWarehouseActivitywithBin(WarehouseReceiptLine."Source No.");

        // Exercise.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify Bin Content before Shipping Sales Order.
        VerifyBinContent(BinCode, WarehouseReceiptLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageCombinesTransfersWithCombineTransferOrdersOption()
    var
        FromLocation: Record Location;
        FromLocation2: Record Location;
        ToLocation: Record Location;
        TransferRoute: Record "Transfer Route";
        Item: array[3] of Record Item;
        TempTransferHeaderToPrint: Record "Transfer Header" temporary;
        ReorderQty: Decimal;
        ItemFilter: Text;
    begin
        // [FEATURE] [Planning Worksheet] [Combine Transfer Orders]
        // [SCENARIO 130474] Transfer orders with the same from- and to- locations are combined when carrying out requisition plan with "Combine Transfer Orders" option

        // [GIVEN] 3 locations: L1, L2, L3
        CreateLocation(FromLocation, false, false, false, false);
        CreateLocation(FromLocation2, false, false, false, false);
        CreateLocation(ToLocation, false, false, false, false);

        CreateAndModifyTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code);
        CreateAndModifyTransferRoute(TransferRoute, FromLocation2.Code, ToLocation.Code);

        ReorderQty := LibraryRandom.RandDec(100, 2);
        // [GIVEN] Item I1 with SKU on location L3, replenished by transfer from location L1
        CreateItemWithFixedReorderSKU(Item[1], ToLocation.Code, FromLocation.Code, ReorderQty * 2, ReorderQty);
        // [GIVEN] Item I2 with SKU on location L3, replenished by transfer from location L1
        CreateItemWithFixedReorderSKU(Item[2], ToLocation.Code, FromLocation.Code, ReorderQty * 2, ReorderQty);
        // [GIVEN] Item I3 with SKU on location L3, replenished by transfer from location L2
        CreateItemWithFixedReorderSKU(Item[3], ToLocation.Code, FromLocation2.Code, ReorderQty * 2, ReorderQty);

        ItemFilter := StrSubstNo('%1|%2|%3', Item[1]."No.", Item[2]."No.", Item[3]."No.");
        // [GIVEN] Calculate regenerative plan
        RunCalculateRegenerativePlan(ItemFilter, ToLocation.Code);
        // [WHEN] Carry out requisition messages with "Combine Transfer Orders" = TRUE
        CarryOutRequisitionLines(ItemFilter, true, TempTransferHeaderToPrint);

        // [THEN] 2 transfer orders are prepared for printing
        Assert.AreEqual(2, TempTransferHeaderToPrint.Count, WrongNumberOfOrdersToPrintErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageDoesNotCombineTransfersNoCombineTransferOrdersOption()
    var
        FromLocation: Record Location;
        FromLocation2: Record Location;
        ToLocation: Record Location;
        TransferRoute: Record "Transfer Route";
        Item: array[3] of Record Item;
        TempTransferHeaderToPrint: Record "Transfer Header" temporary;
        ReorderQty: Decimal;
        ItemFilter: Text;
    begin
        // [FEATURE] [Planning Worksheet] [Combine Transfer Orders]
        // [SCENARIO 130474] Transfer orders with the same from- and to- locations are not combined when carrying out requisition plan without "Combine Transfer Orders" option

        // [GIVEN] 3 locations: L1, L2, L3
        CreateLocation(FromLocation, false, false, false, false);
        CreateLocation(FromLocation2, false, false, false, false);
        CreateLocation(ToLocation, false, false, false, false);

        CreateAndModifyTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code);
        CreateAndModifyTransferRoute(TransferRoute, FromLocation2.Code, ToLocation.Code);

        ReorderQty := LibraryRandom.RandDec(100, 2);
        // [GIVEN] Item I1 with SKU on location L3, replenished by transfer from location L1
        CreateItemWithFixedReorderSKU(Item[1], ToLocation.Code, FromLocation.Code, ReorderQty * 2, ReorderQty);
        // [GIVEN] Item I2 with SKU on location L3, replenished by transfer from location L1
        CreateItemWithFixedReorderSKU(Item[2], ToLocation.Code, FromLocation.Code, ReorderQty * 2, ReorderQty);
        // [GIVEN] Item I3 with SKU on location L3, replenished by transfer from location L2
        CreateItemWithFixedReorderSKU(Item[3], ToLocation.Code, FromLocation2.Code, ReorderQty * 2, ReorderQty);

        ItemFilter := StrSubstNo('%1|%2|%3', Item[1]."No.", Item[2]."No.", Item[3]."No.");
        // [GIVEN] Calculate regenerative plan
        RunCalculateRegenerativePlan(ItemFilter, ToLocation.Code);
        // [WHEN] Carry out requisition messages with "Combine Transfer Orders" = FALSE
        CarryOutRequisitionLines(ItemFilter, false, TempTransferHeaderToPrint);

        // [THEN] 3 transfer orders are prepared for printing
        Assert.AreEqual(3, TempTransferHeaderToPrint.Count, WrongNumberOfOrdersToPrintErr);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,CarryOutActionMsgPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgCombinesTransfersWhenReqLinesAreFiltered()
    var
        LocationFrom: Record Location;
        LocationTo: array[2] of Record Location;
        TransferRoute: Record "Transfer Route";
        Item: array[2] of Record Item;
        SKU: Record "Stockkeeping Unit";
        TransferHeader: Record "Transfer Header";
        PlanningWorksheet: TestPage "Planning Worksheet";
        PlanWkshtName: Code[10];
        ItemFilter: Text;
        ReorderQty: Decimal;
        i: Integer;
        j: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Combine Transfer Orders]
        // [SCENARIO 222611] Transfer orders should be combined when carrying out action message in requisition worksheet filtered by 'Carry Out Action Message' field.
        Initialize();

        // [GIVEN] Locations "L1", "L2", "L3" with transfer routes "L1" -> "L2" and "L1" -> "L3".
        LibraryWarehouse.CreateLocation(LocationFrom);
        for j := 1 to ArrayLen(LocationTo) do begin
            LibraryWarehouse.CreateLocation(LocationTo[j]);
            CreateAndModifyTransferRoute(TransferRoute, LocationFrom.Code, LocationTo[j].Code);
        end;

        // [GIVEN] Items "I1" and "I2".
        // [GIVEN] Stockkeeping units for both items on locations "L2" and "L3".
        // [GIVEN] The SKUs are set to be replenished by transfers from "L1".
        ReorderQty := LibraryRandom.RandInt(10);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            ItemFilter += Item[i]."No." + '|';
            for j := 1 to ArrayLen(LocationTo) do begin
                CreateAndUpdateStockKeepingUnit(SKU, Item[i], LocationTo[j].Code, LocationFrom.Code);
                UpdateSKUReorderingPolicy(SKU, SKU."Reordering Policy"::"Fixed Reorder Qty.", 0, ReorderQty);
            end;
        end;
        ItemFilter := CopyStr(ItemFilter, 1, StrLen(ItemFilter) - 1);

        // [GIVEN] Regenerative plan is calculated for "I1" and "I2".
        PlanWkshtName := CreateRequisitionWorksheetName(PAGE::"Planning Worksheet");
        EnqueueFilters(ItemFilter, '', '');
        Commit();
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(PlanWkshtName);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();

        // [GIVEN] "Accept Action Message" is set on all planning lines.
        PlanningWorksheet.Last();
        repeat
            PlanningWorksheet."Accept Action Message".SetValue(Format(true));
        until not PlanningWorksheet.Previous();

        // [GIVEN] Filter the planning worksheet by "Accept Action Message" = TRUE.
        PlanningWorksheet.FILTER.SetFilter("Accept Action Message", Format(true));

        // [WHEN] Carry out action message for the planning worksheet with enabled "Combine Transfer Orders".
        Commit();
        LibraryVariableStorage.Enqueue(true);
        PlanningWorksheet.CarryOutActionMessage.Invoke();

        // [THEN] One transfer order is created for each route - "L1" -> "L3" and "L2" -> "L3".
        FilterTransferOrder(TransferHeader, LocationFrom.Code, LocationTo[1].Code);
        Assert.RecordCount(TransferHeader, 1);

        FilterTransferOrder(TransferHeader, LocationFrom.Code, LocationTo[2].Code);
        Assert.RecordCount(TransferHeader, 1);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRPH,MessageHandler,TransferReceiptReportDataHandler')]
    [Scope('OnPrem')]
    procedure PrintInboundTransfer()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Location: Record Location;
        FileManagement: Codeunit "File Management";
        ReceiptFileName: Text;
    begin
        // [FEATURE] [Transfer Order] [Warehouse] [Put-away] [Report]
        // [SCENARIO 375628] Post and print Inbound Transfer Warehouse Activity

        // [GIVEN] Warehouse Put-away Activity Header obtained from transfer shipment
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateInitialSetupForTransferOrder(TransferLine, Item."No.", false, false, false, true);
        TransferHeader.Get(TransferLine."Document No.");
        Location.Get(TransferHeader."Transfer-to Code");
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Modify(true);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        TransferHeader.CreateInvtPutAwayPick();
        WarehouseActivityHeader.SetRange("Location Code", TransferHeader."Transfer-to Code");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // Arguments for TransferReceiptReportDataHandler
        ReceiptFileName := FileManagement.ServerTempFileName('xlsx');
        LibraryVariableStorage.Enqueue(TransferHeader."Transfer-from Code");
        LibraryVariableStorage.Enqueue(ReceiptFileName);

        // [WHEN] Post and Print Acitivity
        LibraryWarehouse.PostAndPrintInventoryActivity(WarehouseActivityHeader, false, true);

        // [THEN] Report output file created
        LibraryReportValidation.SetFullFileName(ReceiptFileName);
        LibraryReportValidation.VerifyCellValueByRef('G', 17, 1, FindReceiptNoByLocation(TransferHeader."Transfer-from Code"));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PickActivitiesMessageHandler,ItemTrackingLinesPageHandler,TransferShipmentReportDataHandler')]
    [Scope('OnPrem')]
    procedure PrintOutboundTransfer()
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        FileManagement: Codeunit "File Management";
        LotNo: Code[50];
        ShipmentFileName: Text;
    begin
        // [FEATURE] [Transfer Order] [Warehouse] [Pick] [Report]
        // [SCENARIO 375628] Post and print Outbound Transfer Warehouse Activity

        // [GIVEN] Warehouse Pick Activity Header obtained from transfer shipment
        Initialize();
        LotNo := LibraryUtility.GenerateGUID(); // for ItemTrackingLinesPageHandler
        LibraryVariableStorage.Enqueue(LotNo);
        CreateWarehouseActivityHeader(WarehouseActivityHeader, TransferLine, LotNo);
        TransferHeader.Get(TransferLine."Document No.");

        // Arguments for TransferShipmentReportDataHandler
        ShipmentFileName := FileManagement.ServerTempFileName('xlsx');
        LibraryVariableStorage.Enqueue(TransferHeader."Transfer-from Code");
        LibraryVariableStorage.Enqueue(ShipmentFileName);

        // [WHEN] Post and Print Acitivity
        LibraryWarehouse.PostAndPrintInventoryActivity(WarehouseActivityHeader, false, true);

        // [THEN] Report output file created
        LibraryReportValidation.SetFullFileName(ShipmentFileName);
        LibraryReportValidation.VerifyCellValueByRef('H', 20, 1, FindShipmentNoByLocation(TransferHeader."Transfer-from Code"));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CombineTransferOrdersForItemsWithDifferentLowLevelCode()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        ToLocation2: Record Location;
        TransferRoute: Record "Transfer Route";
        Item: array[2] of Record Item;
        PlannedItem: Record Item;
        SKU: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
        TransferHeader: Record "Transfer Header";
        PlanningWorksheet: TestPage "Planning Worksheet";
        i: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Combine Transfer Orders]
        // [SCENARIO 498757] Transfer orders with the same from- and to- locations are combined regardless of the low-level code of the items.

        // [GIVEN] 3 locations: L1, L2, L3.
        // [GIVEN] Transfer routes L1 -> L2 and L1 -> L3.
        CreateLocation(FromLocation, false, false, false, false);
        CreateLocation(ToLocation, false, false, false, false);
        CreateLocation(ToLocation2, false, false, false, false);
        CreateAndModifyTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code);
        CreateAndModifyTransferRoute(TransferRoute, FromLocation.Code, ToLocation2.Code);

        // [GIVEN] Items I1, I2 with different low-level codes.
        // [GIVEN] Stockkeeping units for both items on locations L2 and L3.
        // [GIVEN] Set Replenishment System to Transfer from L1 for both items.
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            Item[i].Validate("Low-Level Code", i);
            Item[i].Modify(true);
            CreateAndUpdateStockKeepingUnit(SKU, Item[i], ToLocation.Code, FromLocation.Code);
            UpdateSKUReorderingPolicy(SKU, SKU."Reordering Policy"::"Fixed Reorder Qty.", 20, 10);
            CreateAndUpdateStockKeepingUnit(SKU, Item[i], ToLocation2.Code, FromLocation.Code);
            UpdateSKUReorderingPolicy(SKU, SKU."Reordering Policy"::"Fixed Reorder Qty.", 20, 10);
        end;

        // [GIVEN] Calculate regenerative plan and accept action message.
        PlannedItem.SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        PlannedItem.SetFilter("Location Filter", '%1|%2', ToLocation.Code, ToLocation2.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(PlannedItem, WorkDate(), WorkDate());
        RequisitionLine.SetFilter("No.", PlannedItem.GetFilter("No."));
        RequisitionLine.FindSet();
        RequisitionLine.ModifyAll("Accept Action Message", true);

        // [WHEN] Carry out action message with "Combine Transfer Orders" = true.
        Commit();
        LibraryVariableStorage.Enqueue(true);
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(RequisitionLine."Journal Batch Name");
        PlanningWorksheet.CarryOutActionMessage.Invoke();

        // [THEN] 2 transfer orders have been created.
        TransferHeader.SetRange("Transfer-from Code", FromLocation.Code);
        Assert.RecordCount(TransferHeader, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Miscellaneous");
        ClearGlobalVariable();
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);

        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);

        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Miscellaneous");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Miscellaneous");
    end;

    local procedure OpenPlanWkshPageForCalcRegenPlan(Name: Code[10])
    var
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        Commit();
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure OpenPlanWkshPageForCalcPlanAndCarryOutAction(Name: Code[10])
    var
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        Commit();
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
        PlanningWorksheet.Last();
        repeat
            PlanningWorksheet."Accept Action Message".SetValue(Format(true));
        until not PlanningWorksheet.Previous();

        // [GIVEN] Filter the planning worksheet by "Accept Action Message" = TRUE.
        PlanningWorksheet.FILTER.SetFilter("Accept Action Message", Format(true));

        // [WHEN] Carry out action message for the planning worksheet with enabled "Combine Transfer Orders".
        Commit();
        LibraryVariableStorage.Enqueue(true);
        PlanningWorksheet.CarryOutActionMessage.Invoke();
    end;

    local procedure OpenReqWkshPageForCalcPlanAndCarryOutAction(Name: Code[10]; CarryOutAction: Boolean)
    var
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        Commit();
        ReqWorksheet.OpenEdit();
        ReqWorksheet.CurrentJnlBatchName.SetValue(Name);
        ReqWorksheet.CalculatePlan.Invoke();  // Open report on Handler CalculatePlanReqWkshRequestPageHandler.
        if CarryOutAction then
            ReqWorksheet.CarryOutActionMessage.Invoke();  // Open report on Handler CarryOutActionMsgRequestPageHandler.
        ReqWorksheet.OK().Invoke();
    end;

    local procedure CarryOutRequisitionLines(ItemNoFilter: Text; CombineTransferOrders: Boolean; var TempTransferHeader: Record "Transfer Header" temporary)
    var
        RequisitionLine: Record "Requisition Line";
        CarryOutAction: Codeunit "Carry Out Action";
        Choice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
    begin
        CarryOutAction.SetSplitTransferOrders(not CombineTransferOrders);
        CarryOutAction.SetParameters(
          "Planning Create Source Type"::Transfer, Choice::"Make Trans. Orders & Print",
          RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");

        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetFilter("No.", ItemNoFilter);
        RequisitionLine.ModifyAll("Accept Action Message", true);
        RequisitionLine.FindSet();
        repeat
            CarryOutAction.Run(RequisitionLine);
        until RequisitionLine.Next() = 0;

        CarryOutAction.GetTransferOrdersToPrint(TempTransferHeader);
    end;

    local procedure ClearGlobalVariable()
    begin
        // Clear Global variables.
        GlobalMessageCounter := 0;
        GlobalDocumentNo := '';
        GlobalDocumentNo2 := '';
        GlobalQuantity := 0;
        GlobalQuantity2 := 0;
    end;

    local procedure CreateBin(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');  // Use blank value for Zone Code and Bin Type Code.
        exit(Bin.Code);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20]; VariantCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use blank value for Version Code and 1 for Quantity per.
        ProductionBOMLine.Validate("Variant Code", VariantCode);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndModifyLocation(var Location: Record Location)
    begin
        CreateLocation(Location, false, false, false, false);
        Evaluate(Location."Outbound Whse. Handling Time", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');  // Use Random value for Outbound Whse. Handling Time.
        Location.Modify(true);
    end;

    local procedure CreateAndModifySalesOrder(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        Customer: Record Customer;
    begin
        CreateSalesOrder(SalesLine, CreateCustomer(LocationCode, Customer.Reserve::Optional), ItemNo, LocationCode, 1);  // Use 1 for Quantity since it is not important.
        SalesLine.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Add Random Days to Shipment date.
        SalesLine.Modify(true);
    end;

    local procedure CreateAndModifyTransferRoute(var TransferRoute: Record "Transfer Route"; TransferFrom: Code[10]; TransferTo: Code[10])
    var
        InTransitLocation: Record Location;
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');  // Use Random value for Shipping Time.
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
          TransferRoute, TransferFrom, TransferTo, InTransitLocation.Code, ShippingAgent.Code, ShippingAgentServices.Code);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);  // Integer value is required for Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesLine, CustomerNo, ItemNo, LocationCode, Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; LocationCode: Code[10]; RequireReceive: Boolean; RequirePutaway: Boolean; Quantity: Decimal; DirectTransfer: Boolean)
    var
        Location: Record Location;
        Location2: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        CreateLocationWithPostingSetup(Location, false, false, RequireReceive, RequirePutaway);
        LibraryWarehouse.CreateInTransitLocation(Location2);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationCode, Location.Code, Location2.Code);
        if DirectTransfer then
            TransferHeader.Validate("Direct Transfer", true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; LocationCode: Code[10]; RequireReceive: Boolean; RequirePutaway: Boolean; Quantity: Decimal; DirectTransfer: Boolean)
    var
        TransferHeader: Record "Transfer Header";
    begin
        CreateTransferOrder(TransferLine, ItemNo, LocationCode, RequireReceive, RequirePutaway, Quantity, DirectTransfer);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndPostShippingAndReceiptInTransferOrder(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; QtytoReceive: Decimal)
    var
        TransferHeader: Record "Transfer Header";
    begin
        CreateTransferHeaderAndTransferLineWithChangedQtytoShip(TransferHeader, TransferLine, ItemNo, LocationCode, Quantity, QtytoReceive);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        SetQtyToReceiveInTransferLine(TransferLine, QtytoReceive);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);
        TransferLine.Find();
    end;

    local procedure CreateAndPostShippingAndReceiptInTransferOrderWithTwoLines(var TransferHeader: Record "Transfer Header"; var TransferLine: array[2] of Record "Transfer Line"; Item: array[2] of Record Item; LocationCode: Code[10]; Quantity: Decimal; QtytoReceive: Decimal)
    begin
        CreateTransferHeaderAndTransferLineWithChangedQtytoShip(
          TransferHeader, TransferLine[2], Item[2]."No.", LocationCode, Quantity, QtytoReceive);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[1], Item[1]."No.", Quantity);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        SetQtyToReceiveInTransferLine(TransferLine[2], QtytoReceive);
        SetQtyToReceiveInTransferLine(TransferLine[1], Quantity);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);
        TransferLine[1].Find();
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(FindWhseShipmentNo(SalesHeader."No.", SalesLine."Location Code"));
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndUpdateProductionForecast(var ProductionForecastEntry: Record "Production Forecast Entry"; Name: Code[10]; Date: Date; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, Name, ItemNo, '', Date, false);
        ProductionForecastEntry.Validate("Location Code", LocationCode);
        ProductionForecastEntry.Validate("Variant Code", VariantCode);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", Quantity);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateAndUpdateProductionBOM(var ParentItem: Record Item; ChildItemNo: Code[20]; VariantCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ParentItem."Base Unit of Measure", ChildItemNo, VariantCode);
        UpdateItem(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateAndUpdateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndUpdateStockKeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item; LocationCode: Code[10]; TransferFromCode: Code[10])
    begin
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);  // Use False for Item InInventory Only and Replace Previous SKUs fields.
        StockkeepingUnit.Get(LocationCode, Item."No.", '');  // Use blank value for Variant Code.
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWithFixedReorderSKU(var Item: Record Item; LocationCode: Code[10]; TransferFromCode: Code[10]; ReorderPoint: Decimal; ReorderQty: Decimal)
    var
        SKU: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndUpdateStockKeepingUnit(SKU, Item, LocationCode, TransferFromCode);
        UpdateSKUReorderingPolicy(SKU, SKU."Reordering Policy"::"Fixed Reorder Qty.", ReorderPoint, ReorderQty);
    end;

    local procedure CreateLocationWithBin(): Code[10]
    var
        Location: Record Location;
    begin
        CreateLocation(Location, true, true, true, true);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateCustomer(LocationCode: Code[10]; Reserve: Enum "Reserve Method"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationCode);
        Customer.Validate(Reserve, Reserve);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateDemandAsNegativeAdjustment(var ParentItem: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        ChildItem: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
    begin
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase);
        LibraryInventory.CreateItemVariant(ItemVariant, ChildItem."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, ChildItem."No.");
        UpdateItemWithBOMAndPostItemJournal(ParentItem, ChildItem."No.", LocationCode, ItemVariant.Code, Quantity);
    end;

    local procedure CreateDemandAsForecast(var ParentItem: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        ChildItem: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase);
        LibraryInventory.CreateItemVariant(ItemVariant, ChildItem."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, ChildItem."No.");
        CreateAndUpdateProductionBOM(ParentItem, ChildItem."No.", ItemVariant.Code);
        CreateProductionForecastSetup(ProductionForecastEntry, ParentItem."No.", LocationCode, Quantity);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateInitialSetupForPickWorksheet(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseLine, LocationCode, Quantity);
        PostWarehouseReceipt(PurchaseLine."Document No.");
        RegisterWarehouseActivity(PurchaseLine."Document No.");
        CreateAndReleaseSalesOrder(SalesLine, CustomerNo, PurchaseLine."No.", PurchaseLine."Location Code", Quantity / 2);  // Take half of Purchase Quantity.
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesLine);
        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure CreateInitialSetupForTransferOrder(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; RequirePick: Boolean; Tracking: Boolean; RequireReceive: Boolean; RequirePutaway: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandInt(100);  // Use Integer Random value for Lot Tracked Item Quantity.
        CreateLocationWithPostingSetup(Location, false, RequirePick, false, false);
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Location.Code, Quantity, Tracking);
        CreateAndReleaseTransferOrder(TransferLine, ItemNo, Location.Code, RequireReceive, RequirePutaway, Quantity, false);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);

        // Lot-for-Lot Planning parameters.
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
    end;

    local procedure CreateLocation(var Location: Record Location; RequireShipment: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequirePutaway: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Put-away", RequirePutaway);
        Location.Modify(true);
    end;

    local procedure CreateLocationWithPostingSetup(var Location: Record Location; RequireShipment: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequirePutaway: Boolean)
    begin
        CreateLocation(Location, RequireShipment, RequirePick, RequireReceive, RequirePutaway);
    end;

    local procedure CreateLotTrackedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, '', '', CreateLotTrackingCode());
        exit(Item."No.");
    end;

    local procedure CreateLotTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePickFromPickWorksheet()
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        GetWarehouseDocumentFromPickWorksheet();
        PickWorksheet.OpenEdit();
        Commit();
        PickWorksheet.CreatePick.Invoke();
        PickWorksheet.OK().Invoke();
    end;

    local procedure CreateProductionForecastSetup(var ProductionForecastEntry: Record "Production Forecast Entry"; ParentItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateProductionForecastSetup(ProductionForecastEntry, ParentItemNo, LocationCode, '', Quantity);
    end;

    local procedure CreateProductionForecastSetup(var ProductionForecastEntry: Record "Production Forecast Entry"; ParentItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal)
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        // Calculate Forecast Date earlier than WORKDATE using Ranndom value.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateDemandForecastSetup(ProductionForecastName.Name, true, true);
        CreateAndUpdateProductionForecast(
          ProductionForecastEntry, ProductionForecastName.Name, CalcDate('<' + Format(-LibraryRandom.RandInt(20)) + 'D>', WorkDate()),
          ParentItemNo, LocationCode, VariantCode, Quantity);
    end;

    local procedure CreateRequisitionWorksheetName(PageID: Integer): Code[10]
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange("Page ID", PageID);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        exit(RequisitionWkshName.Name);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateAndUpdateSalesLine(SalesLine, SalesHeader, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesOrderWithMultipleLines(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Create and release Sales Order with multiple lines with Random Quantity.
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', Customer.Reserve::Never), Item."No.", LocationCode, LibraryRandom.RandDec(100, 2));  // Use blank value for Location Code.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateAndUpdateSalesLine(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), LocationCode2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateTransferHeaderAndTransferLine(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        Location: array[2] of Record Location;
    begin
        CreateLocationWithPostingSetup(Location[1], false, false, false, false);
        LibraryWarehouse.CreateInTransitLocation(Location[2]);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationCode, Location[1].Code, Location[2].Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateTransferHeaderAndTransferLineWithChangedQtytoShip(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; QtytoShip: Decimal)
    begin
        CreateTransferHeaderAndTransferLine(TransferHeader, TransferLine, ItemNo, LocationCode, Quantity);
        TransferLine.Validate("Qty. to Ship", QtytoShip);
        TransferLine.Modify(true);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; Quantity: Decimal)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndReleasePurchaseOrder(PurchaseLine, Item."No.", LocationCode, Quantity);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateAndModifyWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        SelectWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.Validate("Bin Code", CreateBin(LocationCode));
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure CreateAndModifyWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        SelectWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.Validate("Bin Code", CreateBin(LocationCode));
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure CreateWhseReceiptAndWhseShipmentWithBin(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEmployee: Record "Warehouse Employee";
        LocationCode: Code[10];
    begin
        // Create Location and Warehouse Employee.
        LocationCode := CreateLocationWithBin();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);

        // Create and Post Warehouse Receipt.
        CreateAndReleasePurchaseOrder(PurchaseLine, Item."No.", LocationCode, LibraryRandom.RandDec(10, 2));  // Use random for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreateAndModifyWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader, LocationCode);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Create Warehouse Shipment Line.
        CreateAndReleaseSalesOrder(
          SalesLine, CreateCustomer(LocationCode, Customer.Reserve::Optional), Item."No.", LocationCode, LibraryRandom.RandDec(10, 2));  // Take half of Purchase Quantity.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateAndModifyWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader, LocationCode);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure CreateWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TransferLine: Record "Transfer Line"; LotNo: Code[50])
    var
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateInitialSetupForTransferOrder(TransferLine, CreateLotTrackedItem(), true, true, false, false);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferLine."Document No.", false, true, false);
        FindWarehouseActivityNo(WarehouseActivityLine, TransferLine."Document No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
    end;

    local procedure SetQtyToReceiveInTransferLine(var TransferLine: Record "Transfer Line"; Quantity: Decimal)
    begin
        TransferLine.Find();
        TransferLine.Validate("Qty. to Receive", Quantity);
        TransferLine.Modify(true);
    end;

    local procedure EnqueueFilters(ItemFilter: Text; LocationFilter: Text; VariantFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(ItemFilter);
        LibraryVariableStorage.Enqueue(LocationFilter);
        if VariantFilter <> '' then
            LibraryVariableStorage.Enqueue(VariantFilter);
    end;

    local procedure FilterTransferOrder(var TransferHeader: Record "Transfer Header"; TransferFromCode: Code[10]; TransferToCode: Code[10])
    begin
        TransferHeader.SetRange("Transfer-from Code", TransferFromCode);
        TransferHeader.SetRange("Transfer-to Code", TransferToCode);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
    end;

    local procedure FindProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LocationCode: Code[10])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Location Code", LocationCode);
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWhseShipmentNo(SourceNo: Code[20]; LocationCode: Code[10]): Code[20]
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        WarehouseShipmentLine.FindFirst();
        exit(WarehouseShipmentLine."No.");
    end;

    local procedure FindShipmentNoByLocation(LocationCode: Code[10]): Code[20]
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader.SetRange("Transfer-from Code", LocationCode);
        TransferShipmentHeader.FindFirst();
        exit(TransferShipmentHeader."No.");
    end;

    local procedure FindReceiptNoByLocation(LocationCode: Code[10]): Code[20]
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        TransferReceiptHeader.SetRange("Transfer-from Code", LocationCode);
        TransferReceiptHeader.FindFirst();
        exit(TransferReceiptHeader."No.");
    end;

    local procedure GetWarehouseDocumentFromPickWorksheet()
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        PickWorksheet.OpenEdit();
        PickWorksheet."Get Warehouse Documents".Invoke();
        PickWorksheet.OK().Invoke();
    end;

    local procedure OpenSalesOrderToEnterQuantity(No: Code[20]; Quantity: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesOrder.OK().Invoke();
    end;

    local procedure OpenSalesOrderToReserve(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Commit();
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Reserve.Invoke();
    end;

    local procedure PostItemJournalLine(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, LocationCode, Quantity);
        if Tracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehouseActivitywithBin(SourceNo: Code[20]): Code[20]
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Bin Code", CreateBin(WarehouseActivityLine."Location Code"));
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        exit(WarehouseActivityLine."Bin Code");
    end;

    local procedure RunCalculateRegenerativePlan(ItemFilter: Text; LocationCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter);
        Item.Validate("Location Filter", LocationCode);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));  // Dates based on WORKDATE.
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SelectWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure SelectWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure SetupForRequisitionWorksheet(var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10]; Quantity: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        TransferRoute: Record "Transfer Route";
    begin
        // Create Transfer Route, create Item and StockKeeping Unit. Create Sales Order.
        LibraryWarehouse.CreateLocation(Location);
        CreateAndModifyTransferRoute(TransferRoute, Location.Code, LocationCode);
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndUpdateStockKeepingUnit(StockkeepingUnit, Item, LocationCode, Location.Code);
        CreateSalesOrder(SalesLine, CreateCustomer(Location.Code, Customer.Reserve::Optional), Item."No.", LocationCode, Quantity);
        EnqueueFilters(Item."No.", LocationCode, '');
    end;

    local procedure SetupSalesAndManufacturingSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        UpdateSalesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning", false);
        LibraryPlanning.SetDefaultSafetyLeadTime('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        LibraryPlanning.SetCombinedMPSMRPCalculation(true);
    end;

    local procedure UpdateDemandForecastSetup(CurrentDemandForecast: Code[10]; UseForecastOnLocations: Boolean; UseForecastOnVariants: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Current Demand Forecast", CurrentDemandForecast);
        InventorySetup.Validate("Use Forecast on Locations", UseForecastOnLocations);
        InventorySetup.Validate("Use Forecast on Variants", UseForecastOnVariants);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateItemDimension(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure UpdateItemWithBOMAndPostItemJournal(var ParentItem: Record Item; ChildItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ParentItem."Base Unit of Measure", ChildItemNo, VariantCode);
        UpdateItem(ParentItem, ProductionBOMHeader."No.");
        PostItemJournalLine(ItemJournalLine."Entry Type"::"Negative Adjmt.", ParentItem."No.", LocationCode, Quantity, false);
    end;

    local procedure UpdateSalesSetup(CreditWarnings: Option; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateSKUReorderingPolicy(var SKU: Record "Stockkeeping Unit"; ReorderingPolicy: Enum "Reordering Policy"; ReorderPoint: Decimal; ReorderQty: Decimal)
    begin
        SKU.Validate("Reordering Policy", ReorderingPolicy);
        SKU.Validate("Reorder Point", ReorderPoint);
        SKU.Validate("Reorder Quantity", ReorderQty);
        SKU.Modify(true);
    end;

    local procedure VerifyDimensionOnTransferLine(DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyInventoryPutAwayPick(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPickWorksheet(SalesLine: Record "Sales Line"; QtyToHandle: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Item No.", SalesLine."No.");
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField(Quantity, SalesLine.Quantity);
        WhseWorksheetLine.TestField("Qty. to Handle", QtyToHandle);
        WhseWorksheetLine.TestField("Destination No.", SalesLine."Sell-to Customer No.");
    end;

    local procedure VerifyPostedInventoryPick(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Location Code", LocationCode);
        PostedInvtPickLine.FindFirst();
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField(Quantity, Quantity);
        PostedInvtPickLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyRequisitionLine(No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, No, LocationCode);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Variant Code", VariantCode);
    end;

    local procedure VerifyTransferOrder(TransferFromCode: Code[10]; TransferToCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        FilterTransferOrder(TransferHeader, TransferFromCode, TransferToCode);
        TransferHeader.FindFirst();
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
        TransferLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyBinOnWarehousePick(LocationCode: Code[10]; TakeBinCode: Code[20]; PlaceBinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", TakeBinCode);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", PlaceBinCode);
    end;

    local procedure VerifyBinContent(BinCode: Code[20]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
    end;

    local procedure TransferShipmentLineTotalQuantity(TransferHeaderFilter: Text[100]): Decimal
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
        TotalShipped: Decimal;
    begin
        TransferShipmentLine.SetFilter("Transfer Order No.", TransferHeaderFilter);
        if TransferShipmentLine.FindSet() then
            repeat
                TotalShipped += TransferShipmentLine.Quantity;
            until TransferShipmentLine.Next() = 0;

        exit(TotalShipped);
    end;

    local procedure TransferReceiptLineTotalQuantity(TransferHeaderFilter: Text[100]): Decimal
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
        TotalReceived: Decimal;
    begin
        TransferReceiptLine.SetFilter("Transfer Order No.", TransferHeaderFilter);
        if TransferReceiptLine.FindSet() then
            repeat
                TotalReceived += TransferReceiptLine.Quantity;
            until TransferReceiptLine.Next() = 0;

        exit(TotalReceived);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AutomaticReservationConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, AutomaticReservationConfirmMsg) > 0, ConfirmMessage);
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailablePurchaseLinesPageHandler(var AvailablePurchaseLines: TestPage "Available - Purchase Lines")
    begin
        AvailablePurchaseLines.FILTER.SetFilter("Document No.", GlobalDocumentNo);
        AvailablePurchaseLines."Outstanding Qty. (Base)".AssertEquals(GlobalQuantity);
        AvailablePurchaseLines.FILTER.SetFilter("Document No.", GlobalDocumentNo2);
        AvailablePurchaseLines."Outstanding Qty. (Base)".AssertEquals(GlobalQuantity2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        CurrentSaveValuesId := REPORT::"Calculate Plan - Plan. Wksh.";

        CalculatePlanPlanWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalculatePlanPlanWksh.Item.SetFilter("Location Filter", LibraryVariableStorage.DequeueText());
        if LibraryVariableStorage.Length() = 1 then
            CalculatePlanPlanWksh.Item.SetFilter("Variant Filter", LibraryVariableStorage.DequeueText());
        CalculatePlanPlanWksh.StartingDate.SetValue(CalcDate('<-CM>', WorkDate()));
        CalculatePlanPlanWksh.EndingDate.SetValue(CalcDate('<CM>', WorkDate()));
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandlerExtended(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        CurrentSaveValuesId := REPORT::"Calculate Plan - Plan. Wksh.";

        CalculatePlanPlanWksh.StartingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CalculatePlanPlanWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalculatePlanPlanWksh.Item.SetFilter("Location Filter", LibraryVariableStorage.DequeueText());
        if LibraryVariableStorage.Length() = 1 then
            CalculatePlanPlanWksh.Item.SetFilter("Variant Filter", LibraryVariableStorage.DequeueText());
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanReqWkshRequestPageHandler(var CalculatePlanReqWksh: TestRequestPage "Calculate Plan - Req. Wksh.")
    begin
        CurrentSaveValuesId := REPORT::"Calculate Plan - Req. Wksh.";

        CalculatePlanReqWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalculatePlanReqWksh.Item.SetFilter("Location Filter", LibraryVariableStorage.DequeueText());
        CalculatePlanReqWksh.StartingDate.SetValue(CalcDate('<-CY>', WorkDate()));
        CalculatePlanReqWksh.EndingDate.SetValue(CalcDate('<CY>', WorkDate()));
        CalculatePlanReqWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgRequestPageHandler(var CarryOutActionMsgReq: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        CurrentSaveValuesId := REPORT::"Carry Out Action Msg. - Req.";
        CarryOutActionMsgReq.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgPlanRequestPageHandler(var CarryOutActionMsgPlan: TestRequestPage "Carry Out Action Msg. - Plan.")
    begin
        CarryOutActionMsgPlan.TransOrderChoice.SetValue(1);
        CarryOutActionMsgPlan.CombineTransferOrders.SetValue(LibraryVariableStorage.DequeueBoolean());
        CarryOutActionMsgPlan.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickHandler(var CreatePick: TestRequestPage "Create Pick")
    begin
        CurrentSaveValuesId := REPORT::"Create Pick";
        CreatePick.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
        ItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickActivitiesMessageHandler(Message: Text[1024])
    begin
        GlobalMessageCounter += 1;
        case GlobalMessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, PickActivitiesMsg) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, NothingToCreateMsg) > 0, Message)
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionHandler(var PickSelection: TestPage "Pick Selection")
    begin
        PickSelection.FILTER.SetFilter("Document No.", GlobalDocumentNo);
        PickSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Total Quantity".DrillDown();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TransferOrderMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, StrSubstNo(TransferOrderDeleteMsg, GlobalDocumentNo)) > 0, Message)
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure TransferShipmentReportDataHandler(var TransferShipment: Report "Transfer Shipment")
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader.Get(FindShipmentNoByLocation(CopyStr(LibraryVariableStorage.DequeueText(), 1, 20)));
        TransferShipmentHeader.SetRecFilter();
        TransferShipment.SetTableView(TransferShipmentHeader);
        TransferShipment.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure TransferReceiptReportDataHandler(var TransferReceipt: Report "Transfer Receipt")
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        TransferReceiptHeader.Get(FindReceiptNoByLocation(CopyStr(LibraryVariableStorage.DequeueText(), 1, 20)));
        TransferReceiptHeader.SetRecFilter();
        TransferReceipt.SetTableView(TransferReceiptHeader);
        TransferReceipt.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPutawayPickMvmtRPH(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CurrentSaveValuesId := REPORT::"Create Invt Put-away/Pick/Mvmt";
        CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogModalPageHandler(var PlanningErrorLog: TestPage "Planning Error Log")
    begin
        PlanningErrorLog.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ErrorMessageTransferOrderPageHandler(var TransferOrderNotification: Notification): Boolean;
    begin
        LibraryVariableStorage.Enqueue(TransferOrderNotification.Message);
    end;

    [RequestPageHandler]
    procedure BatchPostTransferOrders(var BatchPostTransferOrders: TestRequestPage "Batch Post Transfer Orders")
    var
        TransferOrderPost: Variant;
        TransferHeader: Variant;
    begin
        LibraryVariableStorage.Dequeue(TransferHeader);
        BatchPostTransferOrders."Transfer Header".SetFilter("No.", TransferHeader);
        LibraryVariableStorage.Dequeue(TransferOrderPost);
        BatchPostTransferOrders.TransferOption.SetValue(TransferOrderPost);
        BatchPostTransferOrders.OK().Invoke();
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [RecallNotificationHandler]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

