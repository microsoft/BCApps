codeunit 137074 "SCM Capacity Requirements"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Capacity] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        CalendarMgt: Codeunit "Shop Calendar Management";
        IsInitialized: Boolean;
        GreaterEqualZeroError: Label 'The value must be greater than or equal to 0.';
        FirmPlannedProductionOrderCreated: Label 'Firm Planned Prod. Order';
        ProdOrderLineQuantityError: Label 'Quantity must have a value in Prod. Order Line';
        MachineCenterNoError: Label 'Operation %1 does not have a work center or a machine center defined';
        TopItemTotalCostErr: Label 'Total Cost for top item Line No. = %1 is not correct in BOM Cost Shares';
        WorkCenterWarningErr: Label 'Warning for Work Center Line No. = %1 is not correct in BOM Cost Shares';
        WorkCenterTotalCostErr: Label 'Total Cost for Work Center Line No. = %1 is not correct in BOM Cost Shares';
        BOMCostShareQtyErr: Label 'Wrong BOM Cost Share "Qty. per Parent" value';
        BOMCostShareCapCostErr: Label 'Wrong BOM Cost Share "Rolled-Up Capacity Cost"  value';
        TheGapErr: Label 'The gap for %1: %2 %3', Comment = '%1 - Work Center Code, %2 - Gap begin, %3 - Gap end.';
        PutawayActivitiesCreatedMsg: Label 'Number of Invt. Put-away activities created';
        InboundWhseRequestCreatedMsg: Label 'Inbound Whse. Requests are created.';
        OutputQuantityMustMatchErr: Label 'Output Quantity muct match.';
        CapacityErr: Label '%1 must be %2 in %3', Comment = '%1 = Capacity, %2 = value, %3 = WorkCenterGroupLoadlines';
        ProdOrderNeedQtyErr: Label '%1 must be %2 in %3', Comment = '%1 = Prod. Order Need (Qty.), %2 = value, %3 = WorkCenterGroupLoadlines';
        Description2Err: Label 'Description must not be blank in %1.', Comment = '%1 = Table Caption.';
        EndingTimeErr: Label 'Ending Time must be equal to %1', Comment = '%1 = Ending Time';
        UniCostCalculationErr: Label 'Unit Cost Calculation must be %1 in %2', Comment = '%1 = Field Value, %2 = Prod. Order Routing Line';

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterLoadWithFirmPlannedProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        WorkCenterLoad: TestPage "Work Center Load";
        CapacityAvailable: Decimal;
        CapacityEfficiency: Decimal;
    begin
        // Setup: Create Production Item with Routing.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());

        // Calculate Capacity values for verifying Capacity on Page - Work Center Load.
        FindWorkCenter(WorkCenter, Item."Routing No.");
        CalculateCapacity(CapacityAvailable, CapacityEfficiency, WorkCenter, ProductionOrder."Starting Date");

        // Exercise: Open Work Center page.
        OpenWorkCenterLoadPage(WorkCenterLoad, WorkCenter."No.");

        // Verify: Verify Capacity Available and Capacity Efficiency on Page - Work Center Load.
        VerifyWorkCenterLoad(WorkCenterLoad, ProductionOrder."Starting Date", CapacityAvailable, CapacityEfficiency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithNegativeEfficiencyError()
    begin
        // Setup.
        Initialize();
        MachineCenterWithNegativeCapacityAndEfficiency(true);  // Efficiency as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithNegativeCapacityError()
    begin
        // Setup.
        Initialize();
        MachineCenterWithNegativeCapacityAndEfficiency(false);  // Efficiency as False.
    end;

    local procedure MachineCenterWithNegativeCapacityAndEfficiency(Efficiency: Boolean)
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        MachineCenterCard: TestPage "Machine Center Card";
    begin
        // Create Work Center and Machine Center.
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        OpenMachineCenterCard(MachineCenterCard, MachineCenter."No.");

        // Exercise: Update Efficiency and Capacity with negative value on Machine Center Card Page. Use page because Efficiency and Capacity Field Property Min Value defined as 0.
        if Efficiency then
            asserterror MachineCenterCard.Efficiency.SetValue(-LibraryRandom.RandDec(10, 2))
        else
            asserterror MachineCenterCard.Capacity.SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify Error message when updating negative value.
        Assert.ExpectedError(GreaterEqualZeroError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithZeroCapacityAndCalculateMachineCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center. Create Machine Center with Zero Capacity.
        Initialize();
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", 0);  // Capacity as 0 required.

        // Exercise: Calculate Machine Center Calendar.
        asserterror LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));

        // Verify: Verify Error message for Machine Center Capacity zero.
        Assert.ExpectedTestFieldError(MachineCenter.FieldCaption(Capacity), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterWithZeroEfficiencyAndCalculateMachineCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center. Create Machine Center with Zero Efficiency.
        Initialize();
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(100, 2));
        UpdateMachineCenterWithZeroEfficiency(MachineCenter);

        // Exercise: Calculate Machine Center Calendar.
        asserterror LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));

        // Verify: Verify Error message for Machine Center Efficiency zero.
        Assert.ExpectedTestFieldError(MachineCenter.FieldCaption(Efficiency), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithZeroCapacityAndCalculateWorkCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Work Center with Zero Capacity.
        Initialize();
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        UpdateWorkCenterWithZeroCapacity(WorkCenter);

        // Exercise: Calculate Work Center Calendar.
        asserterror LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));

        // Verify: Verify Error message for Work Center Capacity zero.
        Assert.ExpectedTestFieldError(WorkCenter.FieldCaption(Capacity), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithZeroEfficiencyAndCalculateWorkCenterCalendarError()
    var
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Work Center with Zero Efficiency.
        Initialize();
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        UpdateWorkCenterWithZeroEfficiency(WorkCenter);

        // Exercise: Calculate Work Center Calendar.
        asserterror LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));

        // Verify: Verify Error message for Work Center Efficiency zero.
        Assert.ExpectedTestFieldError(WorkCenter.FieldCaption(Efficiency), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithNegativeEfficiencyError()
    begin
        // Setup.
        Initialize();
        WorkCenterWithNegativeCapacityAndEfficiency(true);  // Efficiency as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithNegativeCapacityError()
    begin
        // Setup.
        Initialize();
        WorkCenterWithNegativeCapacityAndEfficiency(false);  // Efficiency as False.
    end;

    local procedure WorkCenterWithNegativeCapacityAndEfficiency(Efficiency: Boolean)
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // Create Work Center.
        CreateWorkCenter(WorkCenter);
        OpenWorkCenterCard(WorkCenterCard, WorkCenter."No.");

        // Exercise: Update Efficiency and Capacity with negative value on Work Center Card Page. Use page because Efficiency and Capacity Field Property Min Value defined as 0.
        if Efficiency then
            asserterror WorkCenterCard.Efficiency.SetValue(-LibraryRandom.RandDec(10, 2))
        else
            asserterror WorkCenterCard.Capacity.SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify Error message when updating negative value.
        Assert.ExpectedError(GreaterEqualZeroError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingWithBlockedMachineCenterError()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Work Center and Create Blocked Machine Center. Create Routing Header.
        Initialize();
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(100, 2));
        UpdateMachineCenterBlocked(MachineCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Exercise: Create Routing line with Blocked Machine Center.
        asserterror CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", MachineCenter."No.", false);

        // Verify: Verify Error message for Blocked Machine Center.
        Assert.ExpectedTestFieldError(MachineCenter.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingWithBlockedWorkCenterError()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Blocked Work Center. Create Routing Header.
        Initialize();
        CreateWorkCenter(WorkCenter);
        UpdateWorkCenterBlocked(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Exercise: Create Routing line with Blocked Work Center.
        asserterror CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", false);

        // Verify: Verify Error message for Blocked Work Center.
        Assert.ExpectedTestFieldError(WorkCenter.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler')]
    [Scope('OnPrem')]
    procedure CalculateStandardCostForItemWithRouting()
    var
        Item: Record Item;
        ChildItem: Record Item;
        RoutingLine: Record "Routing Line";
        ProductionBOMLine: Record "Production BOM Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        StandardCost: Decimal;
    begin
        // Setup: Create Production Item with Routing. Update Costing Method as Standard on Items.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        FindProductionBOMLine(ProductionBOMLine, Item."Production BOM No.");
        ChildItem.Get(ProductionBOMLine."No.");
        UpdateStandardCostingMethodOnItem(Item);
        UpdateStandardCostingMethodOnItem(ChildItem);

        // Update Unit Cost Per on Routing Line and update Unit Cost Calculation on Work Center.
        UpdateUnitCostPerOnRoutingLineAndReCertify(RoutingLine, Item."Routing No.");
        UpdateUnitCostCalculationOnWorkCenter(RoutingLine."No.");

        // Calculation of Standard Cost for verification.
        StandardCost := RoutingLine."Unit Cost per" + ChildItem."Standard Cost" * ProductionBOMLine."Quantity per";

        // Exercise: Calculate Standard Cost.
        CalculateStandardCost.CalcItem(Item."No.", false);  // Use Assembly List - False.

        // Verify: Verify New Standard Cost on Item record updated after Calculate Standard Cost.
        Item.Get(Item."No.");
        Item.TestField("Standard Cost", StandardCost);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithMoveAndWaitTime()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        SalesHeader: Record "Sales Header";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Production Item with Routing and Sales Order.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");

        // Exercise: Create Firm Planned Production Order from Sales Order.
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);

        // Verify: Verify Move Time and Wait Time on Production Order Routing Line.
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");
        VerifyOperationsTimeOnProdOrderRoutingLine(ProdOrderLine."Prod. Order No.", Item."Routing No.", RoutingLine.Type::"Work Center");
        VerifyOperationsTimeOnProdOrderRoutingLine(
          ProdOrderLine."Prod. Order No.", Item."Routing No.", RoutingLine.Type::"Machine Center");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithStartingDateAndTimeForFirmPlannedProdOrderFromSalesOrder()
    begin
        // Setup.
        Initialize();
        ProdOrderRoutingLineWithStartingDateAndTime(true);  // Firm Planned Prod Order From Sales Order as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithStartingDateAndTimeForFirmPlannedProdOrder()
    begin
        // Setup.
        Initialize();
        ProdOrderRoutingLineWithStartingDateAndTime(false);  // Firm Planned Prod Order From Sales Order as False.
    end;

    local procedure ProdOrderRoutingLineWithStartingDateAndTime(FirmPlannedProdOrderFromSalesOrder: Boolean)
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
    begin
        // Create Production Item with Routing and Firm Planned Production Order.
        CreateProductionItemWithRoutingSetup(Item, false);
        if FirmPlannedProdOrderFromSalesOrder then begin
            CreateSalesOrder(SalesHeader, Item."No.");
            CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);
        end else
            CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");

        // Exercise: Update Starting Date and Starting Time on Production Order Line different from previous value.
        UpdateStartingDateAndTimeOnProdOrderLine(ProdOrderLine);

        // Verify: Verify Starting Date and Starting Time on Production Order Routing Line.
        VerifyStartingDateAndTimeOnProdOrderRoutingLine(ProdOrderLine, Item."Routing No.", RoutingLine.Type::"Machine Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithoutCalculateLineZeroQuantityError()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Production Item with Routing and Sales Order.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());

        // Update Quantity as Zero on Production Order Line.
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");
        UpdateProdOrderLineWithZeroQuantity(ProdOrderLine);

        // Exercise: Refresh Production Order with Calculate Line - False.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Error message for Zero Production Order line Quantity.
        Assert.ExpectedError(ProdOrderLineQuantityError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderCapacityNeedWithFirmPlannedProdOrderFromSalesOrderForWorkCenter()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenterLoad: TestPage "Work Center Load";
        ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need";
    begin
        // Setup: Create Item with routing Setup and Sales Order. Create Firm Planned Production Order from Sales Order.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");

        // Open Work Center Load Page.
        FindWorkCenter(WorkCenter, Item."Routing No.");
        OpenWorkCenterLoadPage(WorkCenterLoad, WorkCenter."No.");
        FilterOnWorkCenterLoadPage(WorkCenterLoad, ProdOrderLine."Starting Date");
        ProdOrderCapacityNeedPage.Trap();

        // Exercise: Drilldown Allocated Quantity on Work Center Load Page and Open Prod Order Capacity Need Page.
        WorkCenterLoad.MachineCenterLoadLines.AllocatedQty.DrillDown();

        // Verify: Verify Allocated Time on Production Order Capacity Need Page.
        VerifyProdOrderCapacityNeed(
          ProdOrderCapacityNeedPage, ProdOrderCapacityNeed.Type::"Work Center", WorkCenter."No.", ProdOrderLine."Starting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderCapacityNeedWithFirmPlannedProdOrderFromSalesOrderForMachineCenter()
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderLine: Record "Prod. Order Line";
        MachineCenterLoad: TestPage "Machine Center Load";
        ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need";
    begin
        // Setup: Create Item with routing Setup and Sales Order. Create Firm Planned Production Order from Sales Order.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");

        // Open Machine Center Load page.
        FindRoutingLine(RoutingLine, Item."Routing No.", RoutingLine.Type::"Machine Center");
        OpenMachineCenterLoadPage(MachineCenterLoad, RoutingLine."No.");
        FilterOnMachineCenterLoadPage(MachineCenterLoad, ProdOrderLine."Starting Date");
        ProdOrderCapacityNeedPage.Trap();

        // Exercise: Drilldown Allocated Quantity on Machine Center Load Page and Open Prod Order Capacity Need Page.
        MachineCenterLoad.MachineCLoadLines.AllocatedQty.DrillDown();

        // Verify: Verify Allocated Time on Production Order Capacity Need Page.
        VerifyProdOrderCapacityNeed(
          ProdOrderCapacityNeedPage, ProdOrderCapacityNeed.Type::"Machine Center", RoutingLine."No.", ProdOrderLine."Starting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineWithSendAheadQuantity()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Item with routing Setup and Sales Order. Create Firm Planned Production Order from Sales Order.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader);

        // Update Send Ahead Quantity on Routing Line.
        UpdateSendAheadQuantityOnRoutingLineAndReCertify(Item."Routing No.");
        FindFirmPlannedProdOrderLine(ProdOrderLine, Item."No.");
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");

        // Exercise: Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Verify: Verify Send Ahead Quantity on Production Order Routing Line.
        VerifySendAheadQuantityOnProdOrderRoutingLine(
          ProductionOrder."No.", Item."Routing No.", ProdOrderRoutingLine.Type::"Machine Center");
        VerifySendAheadQuantityOnProdOrderRoutingLine(ProductionOrder."No.", Item."Routing No.", ProdOrderRoutingLine.Type::"Work Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineWithOperationsTimeAndCalcRegenPlan()
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Item with routing Setup and Reorder Policy as Lot For Lot. Create Sales Order.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        UpdateLotForLotReorderingPolicyOnItem(Item);
        CreateSalesOrder(SalesHeader, Item."No.");

        // Exercise: Calculate Plan for Planning Worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Move Time and Wait Time on Planning Routing Line.
        VerifyOperationsTimeOnPlanningRoutingLine(Item."Routing No.", RoutingLine.Type::"Work Center");
        VerifyOperationsTimeOnPlanningRoutingLine(Item."Routing No.", RoutingLine.Type::"Machine Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineWithSendAheadQuantityAndCalcRegenPlan()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        // Setup: Create Item with routing Setup and Reorder Policy as Lot For Lot. Update Send Ahead Quantity on Routing line and Create Sales Order.
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, false);
        UpdateLotForLotReorderingPolicyOnItem(Item);

        UpdateSendAheadQuantityOnRoutingLineAndReCertify(Item."Routing No.");
        CreateSalesOrder(SalesHeader, Item."No.");

        // Exercise: Calculate Plan for Planning Worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Send Ahead Quantity on Planning Routing Line.
        VerifySendAheadQuantityOnPlanningRoutingLine(Item."Routing No.", PlanningRoutingLine.Type::"Work Center");
        VerifySendAheadQuantityOnPlanningRoutingLine(Item."Routing No.", PlanningRoutingLine.Type::"Machine Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingWithoutMachineCenterError()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Routing Header, Routing Line.
        Initialize();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", '', false);  // Machine Center No. should be empty.

        // Exercise: Update Routing Status to Certified.
        asserterror UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        // Verify: Verify Machine Center No. blank error when change Status of Routing.
        Assert.ExpectedError(StrSubstNo(MachineCenterNoError, RoutingLine."Operation No."));
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler,BOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure RunBOMCostSharesForItemWithUnitCostCalcuWorkCenterOnRtngLine()
    var
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        Item: Record Item;
        RoutingLine: Record "Routing Line";
    begin
        // Setup: Create Production Item with Routing without filling Setup Time/Run Time/Wait Time/Move Time.
        Initialize();
        CreateProductionItemWithoutRoutingTime(Item);

        // Update Unit Cost Per on Routing Line and update Unit Cost Calculation on Work Center.
        UpdateUnitCostPerOnRoutingLineAndReCertify(RoutingLine, Item."Routing No.");
        UpdateUnitCostCalculationOnWorkCenter(RoutingLine."No.");

        // Exercise: Calculate Standard Cost.
        CalculateStandardCost.CalcItem(Item."No.", false);  // Use Assembly List - False.

        Item.Get(Item."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(RoutingLine."Routing No.");
        LibraryVariableStorage.Enqueue('');

        RunBOMCostSharesPage(Item);

        // Verify: Cost fields on BOM Cost Shares page: In BOMCostSharesPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyOperationDateOnProdRoutingLine()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        ProdOrder: Record "Production Order";
        MachineCenter: Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        StartingDateTime: DateTime;
    begin
        // Setup: Create Production Item with Routing, create and refresh Firm Planned Production Order.
        CreateProductionItemWithRoutingSetup(Item, false);
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProdOrder, Item."No.", LibraryRandom.RandIntInRange(5, 100), WorkDate());
        FindRoutingLine(RoutingLine, ProdOrder."Routing No.", RoutingLine.Type::"Machine Center");
        MachineCenter.Get(RoutingLine."No.");

        // Exercise: Update Send-Ahead Quantity, Concurrent Capacities and Starting Date-Time on the first Prod. Order Routing Line.
        UpdateProdOrderRoutingLine(
          ProdOrderRoutingLine, ProdOrder."No.", RoutingLine.Type, RoutingLine."No.",
          ProdOrder.Quantity - LibraryRandom.RandInt(4), MachineCenter.Capacity); // Send-Ahead Quantity should be less than ProdOrder.Quantity.

        StartingDateTime :=
          ProdOrderRoutingLine."Starting Date-Time" +
          Round(
            (ProdOrderRoutingLine."Setup Time" + ProdOrderRoutingLine."Wait Time" + ProdOrderRoutingLine."Move Time" +
             ProdOrderRoutingLine."Run Time" * ProdOrderRoutingLine."Send-Ahead Quantity" /
             ProdOrderRoutingLine."Concurrent Capacities") *
            CalendarMgt.TimeFactor(MachineCenter."Setup Time Unit of Meas. Code"), 1);

        // Verify: Verify Starting Date-Time on the second Production Order Routing Line.
        VerifyStartingDateTimeOnProdOrderRoutingLine(
          ProdOrder."Routing No.", ProdOrder."No.", RoutingLine.Type::"Work Center", StartingDateTime);
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesVerifyQtyPageHandler')]
    [Scope('OnPrem')]
    procedure CheckBOMCostShareLineQtyWithMultipleUOM()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ExpectedQty: Decimal;
    begin
        // Verify BOM Cost Shares "Qty. per Parent" value when multiple UOM is used
        Initialize();
        CreateProductionItemWithRoutingSetup(Item, true);
        FindRoutingLine(RoutingLine, Item."Routing No.", RoutingLine.Type::"Machine Center");
        FindWorkCenter(WorkCenter, Item."Routing No.");

        ExpectedQty :=
          Round(
            CalcRoutingLineQtyBase(RoutingLine) /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            0.0001);

        LibraryVariableStorage.Enqueue(RoutingLine."No.");
        LibraryVariableStorage.Enqueue(ExpectedQty);
        RunBOMCostSharesPage(Item);

        // Verify Quantity field on BOM Cost Shares page: In BOMCostSharesVerifyQtyPageHandler.
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler,BOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure BOMCostSharePageBlankItemFilter()
    var
        ItemFilter: Record Item;
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [FEATURE] [BOM Cost Share]
        // [SCENARIO 377878] BOM Cost Share Page should not calculate Tree for Items without BOM and Routing
        Initialize();

        // [GIVEN] Item "X" without BOM and Routing
        CreateItem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Item "Y" with Routing and BOM
        CreateProductionItemWithoutRoutingTime(Item);
        CalculateStandardCost.CalcItem(Item."No.", false);
        FindRoutingLine(RoutingLine, Item."Routing No.", RoutingLine.Type::"Work Center");
        Item.Get(Item."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(RoutingLine."Routing No.");
        LibraryVariableStorage.Enqueue('');

        // [WHEN] Run BOM Cost Share Page with ItemFilter blank
        ItemFilter.Init();
        RunBOMCostSharesPage(ItemFilter);

        // [THEN] Cost fields for Item "Y" are calculated where Item "X" is not considered
        // Verify through BOMCostSharesPageHandler
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesCapCostHandler')]
    [Scope('OnPrem')]
    procedure BOMCostShareDifferentTimeUnit()
    var
        Item: Record Item;
        RoutingNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        // [FEATURE] [BOM Cost Share] [Rounding]
        // [SCENARIO 377848] BOM Cost Shares should increase rounding precision while transmission time unit
        Initialize();

        // [GIVEN] Work Center "W" with Unit of Measure Code = "Hours" and Direct Unit Cost = 10000
        WorkCenterNo := CreateWorkCenterWithDirectCost(10000);

        // [GIVEN] Routing "R" with Work Center "W" and Run time = 60 Minutes
        RoutingNo := CreateRoutingWithRunTime(WorkCenterNo, 60);

        // [GIVEN] Item "I" with Routing "R"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);

        // [WHEN] Run Cost Share for Item "I"
        LibraryVariableStorage.Enqueue(WorkCenterNo);
        LibraryVariableStorage.Enqueue(10000);
        RunBOMCostSharesPage(Item);

        // [THEN] BOM Cost Share is created with Rolled-Up Capacity Cost = 10000
        // Verify in BOMCostSharesCapCostHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConcurrentCapacitiesOnProdOrderRoutingLine()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        ProdOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 378850] Concurrent Capacities of Prod. Order Routing Line should not be blank if Capacity is greater then 1
        Initialize();

        // [GIVEN] Machine Center "M" with "Capacity" > 1 and "Concurrent Capacities" = 0
        CreateProductionItemWithRoutingSetup(Item, false);

        // [GIVEN] Create and refresh Production Order
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProdOrder, Item."No.", LibraryRandom.RandIntInRange(5, 100), WorkDate());

        // [WHEN] Set "Routing No." to "M" on Prod. Order Routing Line
        FindRoutingLine(RoutingLine, ProdOrder."Routing No.", RoutingLine.Type::"Machine Center");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrder."No.", RoutingLine.Type, RoutingLine."No.");
        ProdOrderRoutingLine.Validate("No.");

        // [THEN] Concurrent Capacity is 1
        ProdOrderRoutingLine.TestField("Concurrent Capacities", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOSerialBackward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order backward for item with serial routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Backward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, false);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOSerialBackward()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan backward for item with serial routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 100, '', WorkDate());

        // [WHEN] Calculate regenerative plan backward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOSerialForward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order forward for item with serial routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Forward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, true);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOSerialForward()
    var
        Item: Record Item;
        WorkCenterCode: array[2] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan forward for item with serial routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Fixed Reorder Qty.", 100);

        // [WHEN] Calculate regenerative plan forward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOParallelBackward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order backward for item with parallel routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Backward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, false);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOParallelBackward()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan backward for item with parallel routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 100, '', WorkDate());

        // [WHEN] Calculate regenerative plan backward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPOParallelForward()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when refresh production order forward for item with parallel routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Refresh Planned Production Order for "I" Forward
        CreateAndRefreshPlannedProductionOrder(ProdOrder, Item."No.", 100, true);

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanPOParallelForward()
    var
        Item: Record Item;
        WorkCenterCode: array[4] of Code[10];
    begin
        // [FEATURE] [Capacity] [Routing] [Production Order] [Send-ahead]
        // [SCENARIO 220589] No time gaps for "Prod. Order Capacity Need" occur when calculate regenerative plan forward for item with parallel routing with send-ahead quantity
        Initialize();

        // [GIVEN] Production Item "I" with Parallel Routing with Send-ahead Quantity, round-the-clock shop calendar
        CreateProductionItemWithParallelRouting(Item, WorkCenterCode, Item."Reordering Policy"::"Fixed Reorder Qty.", 100);

        // [WHEN] Calculate regenerative plan forward for "I" Production Order
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] "Prod. Order Capacity Need" hasn't time gaps for single routing line
        VerifyProdOrderCapacityNeedTime(WorkCenterCode, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWithZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWithNonZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is later than "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Prod. Order Routing Line" for the residual quantity.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenEndTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 286758] Refresh Release Production Order in Backward direction in case of End Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . {          } --> operational hours
        // .   |------------|
        // .       |------------|
        // [THEN] "Starting Time" and "Ending Time" of "Prod. Order Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Backward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWithSendAheadAndWaitTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 360987] Refresh Release Production Order in Backward direction in case of "Wait Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 360;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200131D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Wait Time, can be outside of working hours
        // .        |-----------|
        // [THEN] "Wait Time" is added to the end of production period for every Send-ahead lot of "Prod. Order Routing Line", but it affects only the next "Prod. Order Routing Line".
        // [THEN] "Wait Time" does not affect the production of the next lot of the current "Prod. Order Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Wait Time" is added once to the end of production period of the current "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200128D, 134500T), CreateDateTime(20200129D, 162500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200129D, 111000T), CreateDateTime(20200130D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Wait Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200128D, 134500T), CreateDateTime(20200129D, 102500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200129D, 111000T), CreateDateTime(20200129D, 170000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 170000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardProdOrderWithSendAheadAndMoveTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 360987] Refresh Release Production Order in Backward direction in case of "Move Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Move Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 0;
            MoveTime[i] := 360;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200131D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Move Time, only working hours
        // .        |-----------|
        // [THEN] "Move Time" is added to the end of production period for every Send-ahead lot of "Prod. Order Routing Line", but it affects only the next "Prod. Order Routing Line".
        // [THEN] "Move Time" does not affect the production of the next lot of the current "Prod. Order Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Move Time" is added once to the end of production period of the current "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200128D, 112000T), CreateDateTime(20200129D, 140000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200129D, 091000T), CreateDateTime(20200130D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200128D, 112000T), CreateDateTime(20200128D, 130000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200129D, 091000T), CreateDateTime(20200129D, 150000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 170000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWithZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWithNonZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is later than "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200124D, 080000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Planning Routing Line" for the residual quantity.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenEndTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 286758] Refresh Planning Line in Backward direction in case of End Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . {          } --> operational hours
        // .  |------------|
        // .      |------------|
        // [THEN] "Starting Time" and "Ending Time" of "Planning Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Backward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize();

        // [GIVEN] Production Item "I" with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time" of "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWithSendAheadAndWaitTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 360987] Refresh Planning Line in Backward direction in case of "Wait Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 360;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200131D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Wait Time, can be outside of working hours
        // .        |-----------|
        // [THEN] "Wait Time" is added to the end of production period for every Send-ahead lot of "Planning Routing Line", but it affects only the next "Planning Routing Line".
        // [THEN] "Wait Time" does not affect the production of the next lot of the current "Planning Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Wait Time" is added once to the end of production period of the current "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200128D, 134500T), CreateDateTime(20200129D, 162500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200129D, 111000T), CreateDateTime(20200130D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Wait Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200128D, 134500T), CreateDateTime(20200129D, 102500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200129D, 111000T), CreateDateTime(20200129D, 170000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 170000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackwardPlanningLineWithSendAheadAndMoveTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 360987] Refresh Planning Line in Backward direction in case of "Move Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Move Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 0;
            MoveTime[i] := 360;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200131D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Move Time, only working hours
        // .        |-----------|
        // [THEN] "Move Time" is added to the end of production period for every Send-ahead lot of "Planning Routing Line", but it affects only the next "Planning Routing Line".
        // [THEN] "Move Time" does not affect the production of the next lot of the current "Planning Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Move Time" is added once to the end of production period of the current "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200128D, 112000T), CreateDateTime(20200129D, 140000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200129D, 091000T), CreateDateTime(20200130D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200128D, 112000T), CreateDateTime(20200128D, 130000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200129D, 091000T), CreateDateTime(20200129D, 150000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200129D, 220000T), CreateDateTime(20200130D, 170000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 180, 120, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := (4 - i) * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time = 12:00.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithNonZeroSendAhead()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is later than "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time = 12:00.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Prod. Order Routing Line" is earlier than "Starting Date-Time" of the next "Prod. Order Routing Line".
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is equal to "Starting Date-Time" of the next "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Due Date is 23.01.20, Starting Time is 10:44.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200123D, 104400T);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Prod. Order Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Prod. Order Routing Line" for the residual quantity.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenStartTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of Start Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 6 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 6;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 23.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200123D, 120000T);

        // .   |------------|
        // .       |------------|
        // . {   } --> operational hours
        // [THEN] "Starting Time" and "Ending Time" of "Prod. Order Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithSendAheadAndSetupTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of "Setup Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Setup Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 3;
            WaitTime[i] := 0;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Setup Time" is added to the start of production period for every "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Wait Time" + "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], SetupTime[i] + 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time" of "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithWaitMoveTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 291307] Refresh Release Production Order in Forward direction in case of "Wait Time" > 0 and "Move Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 2; "Move Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 2;
            MoveTime[i] := 3;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Wait Time" and "Move Time" are added to the end of production period for every "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 112000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 101000T), CreateDateTime(20200128D, 080300T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130800T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Wait Time" + "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200127D, 101000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130300T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithSendAheadAndWaitTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 360987] Refresh Release Production Order in Forward direction in case of "Wait Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 360;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 12:05.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 120500T);

        // . |--|-----|
        // .    |---|   --> Wait Time, can be outside of working hours
        // .        |-----------|
        // [THEN] "Wait Time" is added to the end of production period for every Send-ahead lot of "Prod. Order Routing Line", but it affects only the next "Prod. Order Routing Line".
        // [THEN] "Wait Time" does not affect the production of the next lot of the current "Prod. Order Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Wait Time" is added once to the end of production period of the current "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 120500T), CreateDateTime(20200127D, 194500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200128D, 080000T), CreateDateTime(20200128D, 195000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200128D, 165500T), CreateDateTime(20200129D, 175500T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Wait Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 120500T), CreateDateTime(20200127D, 134500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200128D, 080000T), CreateDateTime(20200128D, 135000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200128D, 165500T), CreateDateTime(20200129D, 115500T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardProdOrderWithSendAheadAndMoveTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 360987] Refresh Release Production Order in Forward direction in case of "Move Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Move Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 0;
            MoveTime[i] := 360;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 12:05.
        CreateAndRefreshForwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200127D, 120500T);

        // . |--|-----|
        // .    |---|   --> Move Time, only working hours
        // .        |-----------|
        // [THEN] "Move Time" is added to the end of production period for every Send-ahead lot of "Prod. Order Routing Line", but it affects only the next "Prod. Order Routing Line".
        // [THEN] "Move Time" does not affect the production of the next lot of the current "Prod. Order Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Move Time" is added once to the end of production period of the current "Prod. Order Routing Line".
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 120500T), CreateDateTime(20200129D, 094500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200128D, 133500T), CreateDateTime(20200129D, 162500T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200129D, 133000T), CreateDateTime(20200130D, 143000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 120500T), CreateDateTime(20200127D, 134500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200128D, 133500T), CreateDateTime(20200129D, 102500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[3],
          CreateDateTime(20200129D, 133000T), CreateDateTime(20200130D, 083000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Send-Ahead = 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity = 0 and "Run Time" 180, 120, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := (4 - i) * 60;
            SendAheadQty[i] := 0;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200124D, 090000T), CreateDateTime(20200127D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithNonZeroSendAhead()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Send-Ahead > 0 and "Run Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 10, 35, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line" by value "Run Time" * "Send-Ahead Qty".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is later than "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenSendAheadLargerOrderQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Send-Ahead > Quantify of a Production Order.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 13, 15 and "Run Time" 60, 120, 180 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            RunTime[i] := i * 60;
            SendAheadQty[i] := i * 2 + 11;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 17.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200117D, 120000T);

        // . |----|
        // .      |-------|
        // [THEN] "Starting Date-Time" of "Planning Routing Line" is earlier than "Starting Date-Time" of the next "Planning Routing Line".
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is equal to "Starting Date-Time" of the next "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200117D, 120000T), CreateDateTime(20200121D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200121D, 120000T), CreateDateTime(20200123D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200123D, 160000T), CreateDateTime(20200127D, 160000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenEndTimePrevLargerEndTimeNext()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of End Time of the previous line is later than Start Time of the next line for the residual quantity.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 2, 5 and "Run Time" 70, 93, 90 minutes.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        SetRunTime(RunTime, 70, 93, 90);
        SendAheadQty[1] := 2;
        SendAheadQty[2] := 5;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 23.01.20, Starting Time is 10:44.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200123D, 104400T);

        // . |-------------|
        // .     |-------|----|
        // .             {    } --> (Residual Quantity * Run Time), i.e. 5 * 90 = 450;  Starting Time of the Residual Qty for the last Route line is 23:00 - 450 = 15:30.
        // .                               Ending Time for the Previous line with working hours 08:00 - 16:00 is (23:00 - 10 * 90) + (10 - 5) * 93 = 08:00 + 465 = 15:45.
        // [THEN] "Ending Date-Time" of "Planning Routing Line" is earlier than or equal to "Starting Date-Time" of the next "Planning Routing Line" for the residual quantity.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 104400T), CreateDateTime(20200127D, 122400T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 153000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 080000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenStartTimeIsOutOfWorkingHours()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of Start Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers with operational hours: 08:00 - 23:00, 08:00 - 16:00, 09:00 - 14:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 6;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 160000T, 090000T, 140000T);
        CreateProductionItemWithSerialRoutingSendAhead(
          Item, WorkCenterCode, RunTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 23.01.20, Starting Time is 12:00.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200123D, 120000T);

        // .   |------------|
        // .       |------------|
        // . {   } --> operational hours
        // [THEN] "Starting Time" and "Ending Time" of "Planning Routing Line" are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200123D, 120000T), CreateDateTime(20200124D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200124D, 080000T), CreateDateTime(20200127D, 120000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 090000T), CreateDateTime(20200128D, 140000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithSendAheadAndSetupTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of "Setup Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Setup Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 3;
            WaitTime[i] := 0;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Setup Time" is added to the start of the production period for every "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100800T), CreateDateTime(20200128D, 080100T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 175800T), CreateDateTime(20200128D, 130100T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to "Setup Time" + Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name",
              WorkCenterCode[i], SetupTime[i] + 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWhenConcurrentCapacitiesLargerThanOne()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        WorkCenterEfficiency: array[3] of Decimal;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of "Concurrent Capacities" > 1 and Efficiency < 100.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 2, 35, 120 minutes; "Concurrent Capacities" = 1, 2, 2; Efficiency = 20, 50, 100.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            SendAheadQty[i] := i * 2 + 1;
            WorkCenterEfficiency[i] := 10 * i * i + 10;
        end;
        SetRunTime(RunTime, 2, 35, 120);
        SetConcurrentCapacities(ConcurrentCapacities, 1, 2, 2);

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingConcurrentCapacities(
          Item, WorkCenterCode, SetupTime, RunTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time = 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Concurrent Capacities" and Efficiency of Work Center are considered in calculation of "Starting Time" and "Ending Time".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 100500T), CreateDateTime(20200127D, 155500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithWaitMoveTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 291307] Refresh Planning Line in Forward direction in case of "Wait Time" > 0 and "Move Time" > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 2; "Move Time" = 3.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 16:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 2;
            MoveTime[i] := 3;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 160000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 09:35.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 093500T);

        // . |-------|
        // .     |-----------|
        // [THEN] "Wait Time" and "Move Time" are added to the end of production period for every "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 112000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 101000T), CreateDateTime(20200128D, 080300T));   // Wait Time is out of working hours
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130800T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Wait Time" + "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 093500T), CreateDateTime(20200127D, 111500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200127D, 101000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200127D, 180300T), CreateDateTime(20200128D, 130300T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithSendAheadAndWaitTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 360987] Refresh Planning Line in Forward direction in case of "Wait Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Wait Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 360;
            MoveTime[i] := 0;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 12:05.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 120500T);

        // . |--|-----|
        // .    |---|   --> Wait Time, can be outside of working hours
        // .        |-----------|
        // [THEN] "Wait Time" is added to the end of production period for every Send-ahead lot of "Planning Routing Line", but it affects only the next "Planning Routing Line".
        // [THEN] "Wait Time" does not affect the production of the next lot of the current "Planning Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Wait Time" is added once to the end of production period of the current "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 120500T), CreateDateTime(20200127D, 194500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200128D, 080000T), CreateDateTime(20200128D, 195000T));   // Wait Time is out of working hours
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200128D, 165500T), CreateDateTime(20200129D, 175500T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Wait Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 120500T), CreateDateTime(20200127D, 134500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200128D, 080000T), CreateDateTime(20200128D, 135000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200128D, 165500T), CreateDateTime(20200129D, 115500T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshForwardPlanningLineWithSendAheadAndMoveTime()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 360987] Refresh Planning Line in Forward direction in case of "Move Time" > "Run Time" * Send-ahead Quantity > 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 10, 35, 60 minutes; "Move Time" = 360.
        // [GIVEN] Three Work Centers with operational hours: 09:00 - 14:00, 08:00 - 17:00, 08:00 - 23:00.
        for i := 1 to ArrayLen(RunTime) do begin
            SetupTime[i] := 0;
            WaitTime[i] := 0;
            MoveTime[i] := 360;
            RunTime[i] := i * 25 - 15;
            SendAheadQty[i] := i * 2 + 1;
        end;
        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 090000T, 140000T, 080000T, 170000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Starting Date is 27.01.20, Starting Time is 12:05.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200127D, 120500T);

        // . |--|-----|
        // .    |---|   --> Move Time, only working hours
        // .        |-----------|
        // [THEN] "Move Time" is added to the end of production period for every Send-ahead lot of "Planning Routing Line", but it affects only the next "Planning Routing Line".
        // [THEN] "Move Time" does not affect the production of the next lot of the current "Planning Routing Line", i.e. current Work Center works without delays.
        // [THEN] "Move Time" is added once to the end of production period of the current "Planning Routing Line".
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200127D, 120500T), CreateDateTime(20200129D, 094500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200128D, 133500T), CreateDateTime(20200129D, 162500T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200129D, 133000T), CreateDateTime(20200130D, 143000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
          CreateDateTime(20200127D, 120500T), CreateDateTime(20200127D, 134500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
          CreateDateTime(20200128D, 133500T), CreateDateTime(20200129D, 102500T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
          RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
          CreateDateTime(20200129D, 133000T), CreateDateTime(20200130D, 083000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
              RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncreaseEndingTimeManuallyProdOrderRoutingLineWithRunMoveTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        WorkCenterStartTime: array[3] of Time;
        WorkCenterEndTime: array[3] of Time;
        DummySetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        DummyWaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        DummySendAheadQty: array[3] of Integer;
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 363120] Set "Ending Date-Time" of Prod. Order Routing Line manually to increase production time in case < 0.00001 ms of Run Time remains unallocated.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with "Run Time" 7 minutes and "Move Time" 960 minutes (16 hours) for the first Routing Line.
        // [GIVEN] Three Work Centers with operational hours 08:00 - 23:00, each of them works for 15 hours per day.
        MoveTime[1] := 960;
        RunTime[1] := 7;
        RunTime[2] := 10;
        RunTime[3] := 10;

        SetWorkCentersOperationalHours(WorkCenterStartTime, WorkCenterEndTime, 080000T, 230000T, 080000T, 230000T, 080000T, 230000T);
        CreateProductionItemWithSerialRoutingSetupWaitMoveTime(
          Item, WorkCenterCode, DummySetupTime, RunTime, DummyWaitTime, MoveTime,
          DummySendAheadQty, WorkCenterStartTime, WorkCenterEndTime, 20200129D);

        // [GIVEN] Firm Planned Production Order for "I" with Quantity = 21, that was refreshed in Backward direction. Due Date is 29.01.20, this is Wednesday.
        // [GIVEN] Three Prod. Order Routing Lines are created, the first one has Starting Date-Time = "27.01.2020 12:33", Enging Date-Time = "28.01.2020 16:00".
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 21, 20200129D);

        // [GIVEN] "Schedule Manually" is set for the first Prod. Order Routing Line of Firm Planned Production Order.
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        UpdateScheduleManuallyOnProdOrderRoutingLine(ProdOrderRoutingLine, true);
        ProdOrderRoutingLine.Validate("Ending Date-Time", CreateDateTime(20200130D, 080000T));  // set "Ending Date-Time" > "29.01.20 22:20" first to avoid bug with allocation

        // [WHEN] Set "Ending Date-Time" of the first Prod. Order Routing Line to "29.01.2020 22:20"; 1427 minutes of Work Center time is allocated to produce Item "I".
        ProdOrderRoutingLine.Validate("Ending Date-Time", CreateDateTime(20200129D, 222000T));
        ProdOrderRoutingLine.Modify(true);

        // [THEN] The second Prod. Order Routing Line starts at 22:20 on 29.01.20, it starts at the same time as the first Prod. Order Routing Line ends.
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200127D, 123300T), CreateDateTime(20200129D, 222000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
          ProdOrderRoutingLine, CreateDateTime(20200129D, 222000T), CreateDateTime(20200130D, 105000T));

        // [THEN] Total "Run Time" 21 * 7 = 147 minutes of the first Prod. Order Routing Line is evenly distributed over 1427 minutes of allocated Work Center time.
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[1],
          CreateDateTime(20200127D, 123300T), CreateDateTime(20200128D, 211954.443T));  // Ending Time is 21:19:54.443 due to rounding
        VerifyCapacityNeedFirstStartLastEndDateTime(
          ProductionOrder."No.", '', WorkCenterCode[2],
          CreateDateTime(20200129D, 222000T), CreateDateTime(20200130D, 105000T));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputJnlLineSetupTimeLessThanTotalCapNeedAllocTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post a line with Setup Time from Output Journal in case Setup Time < total Allocated Time of Prod. Order Capacity Need of Prod. Order Routing Line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Setup Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 100, 0, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I", that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Setup" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, 40);

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = 70.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 70, 0);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] First Prod. Order Capacity Need has Allocated Time = 0. Second Prod. Order Capacity Need has Allocated Time = 40 - (70 - 60) = 30.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 0, 30);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputJnlLineSetupTimeLargerThanTotalCapNeedAllocTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post a line with Setup Time from Output Journal in case Setup Time > total Allocated Time of Prod. Order Capacity Need of Prod. Order Routing Line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Setup Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 100, 0, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I", that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Setup" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, 40);

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = 120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 120, 0);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] First and second Prod. Order Capacity Need records has Allocated Time = 0.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputJnlLineSetupTimeIsNegative()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post a line with Setup Time from Output Journal in case Setup Time < 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Setup Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 100, 0, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I", that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Setup" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, 40);

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = -70.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", -70, 0);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Setup Time is added to Allocated Time of the first Prod. Order Capacity Need, Allocated Time = 60 + 70 = 130. Second Prod. Order Capacity Need remains unchanged.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 130, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTwoOutputJnlLinesSetupTimesAreEqualWithOppositeSign()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post two lines with Setup Time from Output Journal in case Setup Time values are equal to 120 and -120.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Setup Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 100, 0, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I", that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Setup" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, 40);

        // [GIVEN] Posted Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = 120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 120, 0);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = -120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", -120, 0);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Allocated Time of both Prod. Order Capacity Need records remains the same, Allocated Time values are equal to 60 and 40.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTwoOutputJnlLinesSetupTimesWithOppositeSignSmallerPositive()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post two lines with Setup Time from Output Journal in case Setup Time values are equal to 120 and -200.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Setup Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 100, 0, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I", that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Setup" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, 40);

        // [GIVEN] Posted Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = 120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 120, 0);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = -200.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", -200, 0);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Difference between Setup Time of Output lines is added to Allocated Time of the first Prod. Order Capacity Need, Allocated Time = 60 + (200 - 120) = 140.
        // [THEN] Allocated Time of the second Prod. Order Capacity Need remains the same as the original one.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 140, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostThreeOutputJnlLinesSetupTimesWithOppositeSign()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post three lines with Setup Time from Output Journal in case Setup Time values are equal to 70, 10 and -200.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Setup Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 100, 0, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I", that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Setup" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, 40);

        // [GIVEN] Two posted Output Journal Lines with Order No. "RPO", Operation No. "10" and Setup Time values 70 and 10.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 70, 0);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 10, 0);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Setup Time = -200.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", -200, 0);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Difference between Setup Time of Output lines is added to Allocated Time of the first Prod. Order Capacity Need, Allocated Time = 60 + (200 - 70 - 10) = 180.
        // [THEN] Allocated Time of the second Prod. Order Capacity Need remains the same as the original one.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", 180, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputJnlLineRunTimeLessThanTotalCapNeedAllocTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post a line with Run Time from Output Journal in case Run Time < total Allocated Time of Prod. Order Capacity Need of Prod. Order Routing Line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 0, 100, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I" with Quantity = 1, that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Run" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", 1, 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 60, 40);

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = 70.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, 70);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] First Prod. Order Capacity Need has Allocated Time = 0. Second Prod. Order Capacity Need has Allocated Time = 40 - (70 - 60) = 30.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 0, 30);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputJnlLineRunTimeLargerThanTotalCapNeedAllocTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post a line with Run Time from Output Journal in case Run Time > total Allocated Time of Prod. Order Capacity Need of Prod. Order Routing Line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 0, 100, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I" with Quantity = 1, that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Run" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", 1, 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 60, 40);

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = 120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, 120);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] First and second Prod. Order Capacity Need records has Allocated Time = 0.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputJnlLineRunTimeIsNegative()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post a line with Run Time from Output Journal in case Run Time < 0.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 0, 100, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I" with Quantity = 1, that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Run" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", 1, 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 60, 40);

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = -70.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, -70);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Run Time is added to Allocated Time of the first Prod. Order Capacity Need, Allocated Time = 60 + 70 = 130. Second Prod. Order Capacity Need remains unchanged.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 130, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTwoOutputJnlLinesRunTimesAreEqualWithOppositeSign()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post two lines with Run Time from Output Journal in case Run Time values are equal to 120 and -120.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 0, 100, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I" with Quantity = 1, that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Run" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", 1, 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 60, 40);

        // [GIVEN] Posted Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = 120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, 120);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = -120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, -120);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Allocated Time of both Prod. Order Capacity Need records remains the same, Allocated Time values are equal to 60 and 40.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 60, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTwoOutputJnlLinesRunTimesWithOppositeSignSmallerPositive()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post two lines with Run Time from Output Journal in case Run Time values are equal to 120 and -200.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 0, 100, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I" with Quantity = 1, that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Run" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", 1, 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 60, 40);

        // [GIVEN] Posted Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = 120.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, 120);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = -200.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, -200);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Difference between Run Time of Output lines is added to Allocated Time of the first Prod. Order Capacity Need, Allocated Time = 60 + (200 - 120) = 140.
        // [THEN] Allocated Time of the second Prod. Order Capacity Need remains the same as the original one.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 140, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostThreeOutputJnlLinesRunTimesWithOppositeSign()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Routing] [Production Order] [Output Journal]
        // [SCENARIO 364361] Post three lines with Run Time from Output Journal in case Run Time values are equal to 70, 10 and -200.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 100.
        // [GIVEN] Work Center with operational hours 08:00 - 09:00, it works 1 hour per day.
        CreateProductionItemWithOneLineRouting(Item, 0, 100, 0, 0, 080000T, 090000T, 20200127D);

        // [GIVEN] Released Production Order "RPO" for Item "I" with Quantity = 1, that was refreshed in Forward direction. Starting Date is 27.01.20, Starting Time is 08:00.
        // [GIVEN] Prod. Order Routing Line with Operation "10" is created. Two Prod. Order Capacity Need lines with Time Type = "Run" and Allocated Time 60 and 40 are created.
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", 1, 20200127D, 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 60, 40);

        // [GIVEN] Two posted Output Journal Lines with Order No. "RPO", Operation No. "10" and Run Time values 70 and 10.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, 70);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, 10);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [GIVEN] Output Journal Line with Order No. "RPO", Operation No. "10" and Run Time = -200.
        CreateOutputJnlLineWithSetupRunTime(ItemJnlLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", 0, -200);

        // [WHEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        // [THEN] Difference between Run Time of Output lines is added to Allocated Time of the first Prod. Order Capacity Need, Allocated Time = 60 + (200 - 70 - 10) = 180.
        // [THEN] Allocated Time of the second Prod. Order Capacity Need remains the same as the original one.
        VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", 180, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NeededTimeNotChangedWhenRecalculateRoutingAfterOutputPosted()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        Qty: Decimal;
        SetupTime: Decimal;
        RunTime: Decimal;
    begin
        // [FEATURE] [Routing] [Production Order] [Output]
        // [SCENARIO 367806] Needed Time on Capacity Need does not change when a user posts output and recalculates routing.
        // [SCENARIO 367806] Allocated Time on Capacity Need is recalculated with the consideration of posted output.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);
        SetupTime := LibraryRandom.RandIntInRange(10, 20);
        RunTime := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Production item with routing. "Setup Time" = 10, "Run Time" = 20.
        // [GIVEN] Released production order for 150 pcs. Refresh.
        // [GIVEN] Check capacity need for setup time: "Allocated Time" = 10, "Needed Time" = 10.
        // [GIVEN] Check capacity need for run time: "Allocated Time" = 3000 (150 * 20), "Needed Time" = 3000.
        CreateProductionItemWithOneLineRouting(Item, SetupTime, RunTime, 0, 0, 080000T, 160000T, WorkDate());
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", Qty, WorkDate(), 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", SetupTime, SetupTime);
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", RunTime * Qty, RunTime * Qty);

        // [GIVEN] Post output for 75 pcs, setup time = 5, run time = 1500.
        CreateAndPostOutputJnlLine(ProdOrderRoutingLine, Item."No.", Qty / 2, SetupTime / 2, RunTime * Qty / 2);

        // [WHEN] Change "Due Date" on the production order to recalculate routing.
        ProductionOrder.Find();
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", CalcDate('<-1M>', ProductionOrder."Due Date"));
        ProductionOrder.Modify(true);

        // [THEN] "Input Quantity" on the prod. order routing line = 150.
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Input Quantity", Qty);

        // [THEN] Verify capacity need for setup time: "Allocated Time" = 5, "Needed Time" = 10.
        // [THEN] Verify capacity need for run time: "Allocated Time" = 1500, "Needed Time" = 3000.
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", SetupTime / 2, SetupTime);
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", RunTime * Qty / 2, RunTime * Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocatedTimeRestoredAfterNegativeOutputPostedAndRoutingRecalcd()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
        SetupTime: Decimal;
        RunTime: Decimal;
    begin
        // [FEATURE] [Routing] [Production Order] [Output]
        // [SCENARIO 367806] Allocated Time on Capacity Need is restored when a user posts output and reverses it back.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);
        SetupTime := LibraryRandom.RandIntInRange(10, 20);
        RunTime := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Production item with routing. "Setup Time" = 10, "Run Time" = 20.
        // [GIVEN] Released production order for 150 pcs. Refresh.
        CreateProductionItemWithOneLineRouting(Item, SetupTime, RunTime, 0, 0, 080000T, 160000T, WorkDate());
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", Qty, WorkDate(), 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");

        // [GIVEN] Post output for 75 pcs, setup time = 5, run time = 1500.
        CreateAndPostOutputJnlLine(ProdOrderRoutingLine, Item."No.", Qty / 2, SetupTime / 2, RunTime * Qty / 2);

        // [GIVEN] Change "Due Date" on the production order to recalculate routing.
        ProductionOrder.Find();
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", CalcDate('<-1M>', ProductionOrder."Due Date"));
        ProductionOrder.Modify(true);

        // [WHEN] Post a reversed output for -75 pcs, setup time = -5, run time = -1500.
        CreateOutputJnlLineWithSetupRunTime(
          ItemJournalLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", -SetupTime / 2, -RunTime * Qty / 2);
        ItemJournalLine.Validate("Output Quantity", -Qty / 2);
        ItemJournalLine.Validate("Applies-to Entry", FindLastItemLedgEntryForOutput(Item."No.", true));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] "Input Quantity" on the prod. order routing line = 150.
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Input Quantity", Qty);

        // [THEN] Verify capacity need for setup time: "Allocated Time" = 10, "Needed Time" = 10.
        // [THEN] Verify capacity need for run time: "Allocated Time" = 3000, "Needed Time" = 3000.
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", SetupTime, SetupTime);
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", RunTime * Qty, RunTime * Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocatedTimeRestoreAfterPartiallyReversedOutput()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
        SetupTime: Decimal;
        RunTime: Decimal;
    begin
        // [FEATURE] [Routing] [Production Order] [Output]
        // [SCENARIO 367806] Restore allocated Time on Capacity Need when a user posts output and partially reverses it.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);
        SetupTime := LibraryRandom.RandIntInRange(10, 20);
        RunTime := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Production item with routing. "Setup Time" = 10, "Run Time" = 20.
        // [GIVEN] Released production order for 150 pcs. Refresh.
        CreateProductionItemWithOneLineRouting(Item, SetupTime, RunTime, 0, 0, 080000T, 160000T, WorkDate());
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", Qty, WorkDate(), 080000T);
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");

        // [GIVEN] Post output for 150 pcs, setup time = 10, run time = 3000.
        CreateAndPostOutputJnlLine(ProdOrderRoutingLine, Item."No.", Qty, SetupTime, RunTime * Qty);

        // [GIVEN] Change "Due Date" on the production order to recalculate routing.
        ProductionOrder.Find();
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", CalcDate('<-1M>', ProductionOrder."Due Date"));
        ProductionOrder.Modify(true);

        // [WHEN] Post a reversed output for -75 pcs, setup time = -5, run time = -1500.
        CreateOutputJnlLineWithSetupRunTime(
          ItemJournalLine, ProductionOrder."No.", Item."No.", ProdOrderRoutingLine."Operation No.", -SetupTime / 2, -RunTime * Qty / 2);
        ItemJournalLine.Validate("Output Quantity", -Qty / 2);
        ItemJournalLine.Validate("Applies-to Entry", FindLastItemLedgEntryForOutput(Item."No.", true));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] "Input Quantity" on the prod. order routing line = 150.
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Input Quantity", Qty);

        // [THEN] Verify capacity need for setup time: "Allocated Time" = 5, "Needed Time" = 10.
        // [THEN] Verify capacity need for run time: "Allocated Time" = 1500, "Needed Time" = 3000.
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Setup Time", SetupTime / 2, SetupTime);
        VerifyCapacityNeedTime(ProdOrderRoutingLine, ProdOrderCapacityNeed."Time Type"::"Run Time", RunTime * Qty / 2, RunTime * Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackProdOrderWithSendAheadWhenRunTimeEndsInDifferentShift()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        ShopCalendarCode: array[3] of Code[10];
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 380176] Refresh Release Production Order in Backward direction in case of two shifts and when End Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers, each with two shifts, there is no break between shifts.
        // [GIVEN] Operational hours: 09:00 - 13:00 - 14:00, 08:00 - 12:00 - 16:00, 08:00 - 18:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;
        ShopCalendarCode[1] := CreateTwoShiftsShopCalendarWeekDays(090000T, 130000T, 130000T, 140000T);
        ShopCalendarCode[2] := CreateTwoShiftsShopCalendarWeekDays(080000T, 120000T, 120000T, 160000T);
        ShopCalendarCode[3] := CreateTwoShiftsShopCalendarWeekDays(080000T, 180000T, 180000T, 230000T);

        CreateProductionItemWithSerialRoutingShopCalendar(
            Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ShopCalendarCode, 20200128D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200128D);

        // . {          } --> operational hours
        // .   |------------|
        // .       |------------|
        // [THEN] "Ending Time" of "Prod. Order Routing Line" is between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Ending Date-Time" of first and second Prod. Order Routing Lines is 27.01.20 14:00 and 27.01.20 16:00 respectively.
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyProdOrderStartEndDateTime(
            ProdOrderRoutingLine, CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
            ProdOrderRoutingLine, CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
            ProdOrderRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Prod. Order Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[1],
            CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[2],
            CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[3],
            CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
                ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackProdOrderWithSendAheadWhenMoveTimeEndsInDifferentShift()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        ShopCalendarCode: array[3] of Code[10];
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 380176] Refresh Release Production Order in Backward direction in case of two shifts and when Move Time ends ouside of working hours.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 90, 72, 60 minutes; "Move Time" = 60.
        // [GIVEN] Three Work Centers, each with two shifts, there is no break between shifts.
        // [GIVEN] Operational hours: 09:00 - 13:00 - 14:00, 08:00 - 12:00 - 16:00, 08:00 - 18:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SetRunTime(MoveTime, 60, 60, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;
        ShopCalendarCode[1] := CreateTwoShiftsShopCalendarWeekDays(090000T, 130000T, 130000T, 140000T);
        ShopCalendarCode[2] := CreateTwoShiftsShopCalendarWeekDays(080000T, 120000T, 120000T, 160000T);
        ShopCalendarCode[3] := CreateTwoShiftsShopCalendarWeekDays(080000T, 180000T, 180000T, 230000T);

        CreateProductionItemWithSerialRoutingShopCalendar(
            Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ShopCalendarCode, 20200131D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Move Time, only working hours
        // .        |-----------|
        // [THEN] "Ending Time" of "Prod. Order Routing Line" is between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Ending Date-Time" of first and second Prod. Order Routing Lines is 30.01.20 13:48 and 30.01.20 16:00 respectively.
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyProdOrderStartEndDateTime(
             ProdOrderRoutingLine, CreateDateTime(20200127D, 124800T), CreateDateTime(20200130D, 134800T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
            ProdOrderRoutingLine, CreateDateTime(20200129D, 110000T), CreateDateTime(20200130D, 160000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
             ProdOrderRoutingLine, CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[1],
            CreateDateTime(20200127D, 124800T), CreateDateTime(20200130D, 124800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[2],
            CreateDateTime(20200129D, 110000T), CreateDateTime(20200130D, 150000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[3],
            CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 220000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
                ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackProdOrderWithSendAheadWhenWaitTimeEndsInDifferentShift()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenterCode: array[3] of Code[20];
        ShopCalendarCode: array[3] of Code[10];
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead]
        // [SCENARIO 380176] Refresh Release Production Order in Backward direction in case of two shifts and when Wait Time ends ouside of working hours.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 90, 72, 60 minutes; "Wait Time" = 60.
        // [GIVEN] Three Work Centers, each with two shifts, there is no break between shifts.
        // [GIVEN] Operational hours: 09:00 - 13:00 - 14:00, 08:00 - 12:00 - 16:00, 08:00 - 18:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SetRunTime(WaitTime, 60, 60, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;
        ShopCalendarCode[1] := CreateTwoShiftsShopCalendarWeekDays(090000T, 130000T, 130000T, 140000T);
        ShopCalendarCode[2] := CreateTwoShiftsShopCalendarWeekDays(080000T, 120000T, 120000T, 160000T);
        ShopCalendarCode[3] := CreateTwoShiftsShopCalendarWeekDays(080000T, 180000T, 180000T, 230000T);

        CreateProductionItemWithSerialRoutingShopCalendar(
            Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ShopCalendarCode, 20200131D);

        // [WHEN] Create Firm Planned Production Order for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardFirmPlannedProductionOrder(ProductionOrder, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Wait Time, can be outside of working hours
        // .        |-----------|
        // [THEN] "Ending Time" of "Prod. Order Routing Line" is between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Ending Date-Time" of first and second Prod. Order Routing Lines is 30.01.20 14:48 and 30.01.20 17:00 respectively.
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        VerifyProdOrderStartEndDateTime(
            ProdOrderRoutingLine, CreateDateTime(20200127D, 134800T), CreateDateTime(20200130D, 144800T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
            ProdOrderRoutingLine, CreateDateTime(20200129D, 120000T), CreateDateTime(20200130D, 170000T));
        GetNextProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderRoutingLine."Next Operation No.");
        VerifyProdOrderStartEndDateTime(
            ProdOrderRoutingLine, CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Prod. Order Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Prod. Order Routing Line" by value "Wait Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[1],
            CreateDateTime(20200127D, 134800T), CreateDateTime(20200130D, 134800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[2],
            CreateDateTime(20200129D, 120000T), CreateDateTime(20200130D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            ProductionOrder."No.", '', WorkCenterCode[3],
            CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 220000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Prod. Order Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
                ProductionOrder."No.", '', WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackPlanLineWithSendAheadWhenRunTimeEndsInDifferentShift()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        ShopCalendarCode: array[3] of Code[10];
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 380176] Refresh Planning Line in Backward direction in case of two shifts and when End Time of the line is later than "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5 and "Run Time" 90, 72, 60 minutes.
        // [GIVEN] Three Work Centers, each with two shifts, there is no break between shifts.
        // [GIVEN] Operational hours: 09:00 - 13:00 - 14:00, 08:00 - 12:00 - 16:00, 08:00 - 18:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;
        ShopCalendarCode[1] := CreateTwoShiftsShopCalendarWeekDays(090000T, 130000T, 130000T, 140000T);
        ShopCalendarCode[2] := CreateTwoShiftsShopCalendarWeekDays(080000T, 120000T, 120000T, 160000T);
        ShopCalendarCode[3] := CreateTwoShiftsShopCalendarWeekDays(080000T, 180000T, 180000T, 230000T);

        CreateProductionItemWithSerialRoutingShopCalendar(
            Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ShopCalendarCode, 20200128D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 28.01.20, this is Tuesday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200128D);

        // . {          } --> operational hours
        // .  |------------|
        // .      |------------|
        // [THEN] "Ending Time" of "Planning Routing Line" is between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Ending Date-Time" of first and second Planning Routing Lines is 27.01.20 14:00 and 27.01.20 16:00 respectively.
        FindFirstPlanningRoutingLine(PlanningRoutingLine, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] "Starting Time" and "Ending Time" of Capacity Need are between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are equal to "Ending Time" and "Ending Date" of "Planning Routing Line".
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
            CreateDateTime(20200123D, 090000T), CreateDateTime(20200127D, 140000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
            CreateDateTime(20200124D, 120000T), CreateDateTime(20200127D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
            CreateDateTime(20200127D, 130000T), CreateDateTime(20200127D, 230000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
                RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackPlanLineWithSendAheadWhenMoveTimeEndsInDifferentShift()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        ShopCalendarCode: array[3] of Code[10];
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 380176] Refresh Planning Line in Backward direction in case of two shifts and when Move Time ends ouside of working hours.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 90, 72, 60 minutes; "Move Time" = 60.
        // [GIVEN] Three Work Centers, each with two shifts, there is no break between shifts.
        // [GIVEN] Operational hours: 09:00 - 13:00 - 14:00, 08:00 - 12:00 - 16:00, 08:00 - 18:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SetRunTime(MoveTime, 60, 60, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;
        ShopCalendarCode[1] := CreateTwoShiftsShopCalendarWeekDays(090000T, 130000T, 130000T, 140000T);
        ShopCalendarCode[2] := CreateTwoShiftsShopCalendarWeekDays(080000T, 120000T, 120000T, 160000T);
        ShopCalendarCode[3] := CreateTwoShiftsShopCalendarWeekDays(080000T, 180000T, 180000T, 230000T);

        CreateProductionItemWithSerialRoutingShopCalendar(
            Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ShopCalendarCode, 20200131D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Forward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Move Time, only working hours
        // .        |-----------|
        // [THEN] "Ending Time" of "Planning Routing Line" is between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Ending Date-Time" of first and second Planning Routing Lines is 30.01.20 13:48 and 30.01.20 16:00 respectively.
        FindFirstPlanningRoutingLine(PlanningRoutingLine, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200127D, 124800T), CreateDateTime(20200130D, 134800T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200129D, 110000T), CreateDateTime(20200130D, 160000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Move Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
            CreateDateTime(20200127D, 124800T), CreateDateTime(20200130D, 124800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
            CreateDateTime(20200129D, 110000T), CreateDateTime(20200130D, 150000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
            CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 220000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
                RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshBackPlanLineWithSendAheadWhenWaitTimeEndsInDifferentShift()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenterCode: array[3] of Code[20];
        ShopCalendarCode: array[3] of Code[10];
        SetupTime: array[3] of Decimal;
        RunTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        SendAheadQty: array[3] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Routing] [Planning] [Send-Ahead]
        // [SCENARIO 380176] Refresh Planning Line in Backward direction in case of two shifts and when Wait Time ends ouside of working hours.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with Send-ahead Quantity 3, 5; "Run Time" 90, 72, 60 minutes; "Wait Time" = 60.
        // [GIVEN] Three Work Centers, each with two shifts, there is no break between shifts.
        // [GIVEN] Operational hours: 09:00 - 13:00 - 14:00, 08:00 - 12:00 - 16:00, 08:00 - 18:00 - 23:00.
        SetRunTime(RunTime, 90, 72, 60);
        SetRunTime(WaitTime, 60, 60, 60);
        SendAheadQty[1] := 3;
        SendAheadQty[2] := 5;
        ShopCalendarCode[1] := CreateTwoShiftsShopCalendarWeekDays(090000T, 130000T, 130000T, 140000T);
        ShopCalendarCode[2] := CreateTwoShiftsShopCalendarWeekDays(080000T, 120000T, 120000T, 160000T);
        ShopCalendarCode[3] := CreateTwoShiftsShopCalendarWeekDays(080000T, 180000T, 180000T, 230000T);

        CreateProductionItemWithSerialRoutingShopCalendar(
            Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ShopCalendarCode, 20200131D);

        // [WHEN] Create Planning Line for "I" with Quantity = 10 and Refresh it in Backward direction. Due Date is 31.01.20, this is Friday.
        CreateAndRefreshBackwardPlanningLine(RequisitionLine, Item."No.", 10, 20200131D);

        // . |--|-----|
        // .    |---|   --> Wait Time, can be outside of working hours
        // .        |-----------|
        // [THEN] "Ending Time" of "Planning Routing Line" is between "Starting Time" and "Ending Time" of "Shop Calendar Working Days" of WorkCenter.
        // [THEN] "Ending Date-Time" of first and second Planning Routing Lines is 30.01.20 14:48 and 30.01.20 17:00 respectively.
        FindFirstPlanningRoutingLine(PlanningRoutingLine, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200127D, 134800T), CreateDateTime(20200130D, 144800T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200129D, 120000T), CreateDateTime(20200130D, 170000T));
        GetNextPlanningRoutingLine(PlanningRoutingLine, PlanningRoutingLine."Next Operation No.");
        VerifyPlanningLineStartEndDateTime(
            PlanningRoutingLine, CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 230000T));

        // [THEN] "Starting Time" and Date of the first Capacity Need are equal to "Starting Time" and "Starting Date" of "Planning Routing Line".
        // [THEN] "Ending Time" and Date of the last Capacity Need are earlier than "Ending Time" and "Ending Date" of "Planning Routing Line" by value "Wait Time".
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[1],
            CreateDateTime(20200127D, 134800T), CreateDateTime(20200130D, 134800T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[2],
            CreateDateTime(20200129D, 120000T), CreateDateTime(20200130D, 160000T));
        VerifyCapacityNeedFirstStartLastEndDateTime(
            RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[3],
            CreateDateTime(20200130D, 120000T), CreateDateTime(20200130D, 220000T));

        // [THEN] Sum of "Allocated Time" of Capacity Need lines for Work Center is equal to Planning Line Quantity multiply by "Run time" of a Routing Line.
        for i := 1 to ArrayLen(RunTime) do
            VerifyCapacityNeedTotalAllocatedTime(
                RequisitionLine."Ref. Order No.", PlanningRoutingLine."Worksheet Template Name", WorkCenterCode[i], 10 * RunTime[i]);
    end;

    [Test]
    procedure CombineConsequentCapacityNeedsToSpeedUpSendAhead()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        WorkCenterCode: array[2] of Code[10];
        Forward: Boolean;
        Qty: Decimal;
    begin
        // [FEATURE] [Send-Ahead]
        // [SCENARIO 452654] Combine consequent capacity need entries to speed up calculating production order with send-ahead routing.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 150);

        // [GIVEN] Production item with routing.
        // [GIVEN] Routing consists of two work centers, each is set up for three shifts - - 0-8 hrs, 8-16 hrs, 16-24 hrs.
        // [GIVEN] The first work center has "Send-Ahead Quantity" and "Run Time" = "X".
        CreateProductionItemWithSerialRoutingReorder(Item, WorkCenterCode, Item."Reordering Policy"::"Lot-for-Lot", 0);

        // [WHEN] Create production order for "Y" qty. and calculate routing backward and then forward.
        for Forward := false to true do begin
            CreateAndRefreshPlannedProductionOrder(ProductionOrder, Item."No.", Qty, Forward);

            // [THEN] Sum of allocated capacity for the first work center = "X" * "Y".
            ProdOrderCapacityNeed.Reset();
            ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterCode[1]);
            ProdOrderCapacityNeed.FindFirst();
            FindRoutingLine(RoutingLine, ProdOrderCapacityNeed."Routing No.", "Capacity Type Routing"::"Work Center");
            ProdOrderCapacityNeed.CalcSums("Allocated Time");
            ProdOrderCapacityNeed.TestField("Allocated Time", Qty * RoutingLine."Run Time");

            // [THEN] Capacity needs are combined within each work shift.
            ProdOrderCapacityNeed.SetRange("Allocated Time", 8);
            ProdOrderCapacityNeed.FindFirst();
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OutputJournalShouldPostCapacityLedgerEntryWithOutputQuantity()
    var
        Item: Record Item;
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        MachineCenter2: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        OutputQuantity: Decimal;
    begin
        // [SCENARIO 494569] When posting a capacity entry in an output journal you receive the error Warehouse handling is required
        Initialize();

        // [GIVEN] Create Location with Bin and Warehouse Employee Setup.
        CreateLocationWithBinAndWarehouseEmployeeSetup(Location, Bin, WarehouseEmployee);

        // [GIVEN] Create Work Center with Work Center Group Code.
        CreateWorkCenterWithWorkCenterGroupCode(WorkCenter);

        // [GIVEN] Create Machine Center with Calendar.
        CreateMachineCenterWithCalendar(MachineCenter, WorkCenter);

        // [GIVEN] Create Machine Center 2 with Calendar.
        CreateMachineCenterWithCalendar(MachineCenter2, WorkCenter);

        // [GIVEN] Create Routing with two Machine Centers.
        CreateRoutingWithTwoMachineCenters(MachineCenter, MachineCenter2, RoutingHeader);

        // [GIVEN] Create Item with Routing.
        CreateItemWithRouting(Item, RoutingHeader);

        // [GIVEN] Create Released Production Order and Refresh it.
        LibraryVariableStorage.Enqueue(InboundWhseRequestCreatedMsg);
        LibraryVariableStorage.Enqueue(PutawayActivitiesCreatedMsg);
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item, Location.Code, Bin.Code, 1);

        // [GIVEN] Create Inbound Whse Request From Released Production Order.
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        // [GIVEN] Create Inventory Put-Away from Inventory Put Pick Movement. 
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        // [GIVEN] Generate and save Output Quantity in a Variable.
        OutputQuantity := LibraryRandom.RandInt(0);

        // [GIVEN] Create Output Journal Line and Validate Output Quantity.
        CreateOutputJnlLineWithSetupRunTime(ItemJournalLine, ProductionOrder."No.", Item."No.", Format(LibraryRandom.RandIntInRange(10, 10)), LibraryRandom.RandInt(0), LibraryRandom.RandIntInRange(10, 10));
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post Output Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Find Capacity Ledger Entry.
        CapacityLedgerEntry.SetRange("Item No.", Item."No.");
        CapacityLedgerEntry.FindFirst();

        // [VERIFY] Verify Output Quantity of Capacity Ledger Entry match with Output Quantity of Output Journal Line.
        Assert.AreEqual(OutputQuantity, CapacityLedgerEntry."Output Quantity", OutputQuantityMustMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterGroupLoadLinesCapacityShowsSumOfWorkCenterLoadCapacity()
    var
        Item: Record Item;
        Location: Record Location;
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenter, WorkCenter2 : Record "Work Center";
        WorkCenterGroup: Record "Work Center Group";
        RoutingHeader: Record "Routing Header";
        Routingline: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        WorkCenterLoad: TestPage "Work Center Load";
        WorkCenterGroupLoad: TestPage "Work Center Group Load";
        Capacity, Capacity2, TotalCapacity : Decimal;
        RunTime, RunTime2, TotalRunTime : Decimal;
        ShopCalendarCode: Code[10];
        CurrentWorkDate: Date;
    begin
        // [SCENARIO 525882] Work Center Group Load page of a Work Center Group shows correct Capacity and Allocated (Qty.) which is the sum of Capacities (shown when Calculate Work Center Calendar) of all Work Centers having that particular Work Center Group Code in them.
        Initialize();

        // [GIVEN] Set Work Date as Today and Set Working Day in Work Date.
        CurrentWorkDate := WorkDate();
        WorkDate(Today);
        WorkDate(SetWorkingDayInWorkDate());

        // [GIVEN] Create Capacity Unit of Measure.
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes);

        // [GIVEN] Create Work Center Group.
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);

        // [GIVEN] Create Shop Calendar.
        ShopCalendarCode := CreateShopCalendar(080000T, 160000T);

        // [GIVEN] Create Work Center with Work Center Group Code.
        CreateWorkCenterWithWorkCenterGrpCode(WorkCenter, WorkCenterGroup.Code, ShopCalendarCode, LibraryRandom.RandIntInRange(3, 3), CapacityUnitOfMeasure.Code);

        // [GIVEN] Create Work Center 2 with Work Center Group Code.
        CreateWorkCenterWithWorkCenterGrpCode(WorkCenter2, WorkCenterGroup.Code, ShopCalendarCode, LibraryRandom.RandInt(0), CapacityUnitOfMeasure.Code);

        // [GIVEN] Calculate Work Center Calendar for Work Center.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CM-1M>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [GIVEN] Calculate Work Center Calendar for Work Center 2.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter2, CalcDate('<-CM-1M>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [GIVEN] Open Work Center Load page of Work Center.
        OpenWorkCenterLoadPage(WorkCenterLoad, WorkCenter."No.");

        // [GIVEN] Generate and save Capacity of Work Center Load in a Variable.
        Capacity := WorkCenterLoad.MachineCenterLoadLines.Capacity.AsDecimal();
        WorkCenterLoad.Close();

        // [GIVEN] Open Work Center Load page of Work Center 2.
        OpenWorkCenterLoadPage(WorkCenterLoad, WorkCenter2."No.");

        // [GIVEN] Generate and save Capacity of Work Center 2 Load in a Variable.
        Capacity2 := WorkCenterLoad.MachineCenterLoadLines.Capacity.AsDecimal();
        WorkCenterLoad.Close();

        // [GIVEN] Generate and save Total Capacity of both Work Center's Load in a Variable.
        TotalCapacity := Capacity + Capacity2;

        // [WHEN] Open Work Center Group Load page.
        OpenWorkCenterGroupLoadPage(WorkCenterGroupLoad, WorkCenterGroup.Code);
        WorkCenterGroupLoad.PeriodType.SetValue("Analysis Period Type"::Day);
        WorkCenterGroupLoad.AmountType.SetValue("Analysis Amount Type"::"Net Change");
        WorkCenterGroupLoad.WorkCtrGroupLoadLines.Filter.SetFilter("Period Start", Format(WorkDate()));

        // [THEN] Capacity in Work Center Group Load Lines is equal to Total Capacity of both Work Center's Load.
        Assert.AreEqual(
          TotalCapacity,
          WorkCenterGroupLoad.WorkCtrGroupLoadLines.Capacity.AsDecimal(),
          StrSubstNo(
            CapacityErr,
            WorkCenterGroupLoad.WorkCtrGroupLoadLines.Capacity.Caption(),
            TotalCapacity,
            WorkCenterGroupLoad.WorkCtrGroupLoadLines.Caption()));

        // [GIVEN] Close Work Center Group Load page.
        WorkCenterGroupLoad.Close();

        // [GIVEN] Create Routing Header.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Create Routing Line and Validate Run Time.
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, Routingline, '', Format(LibraryRandom.RandInt(0)), Routingline.Type::"Work Center", WorkCenter."No.");
        Routingline.Validate("Run Time", LibraryRandom.RandIntInRange(60, 60));
        Routingline.Modify(true);

        // [GIVEN] Generate and save Run Time of first Routing Line in a Variable.
        RunTime := Routingline."Run Time";

        // [GIVEN] Create another Routing Line and Validate Run Time.
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, Routingline, '', Format(LibraryRandom.RandIntInRange(2, 2)), Routingline.Type::"Work Center", WorkCenter2."No.");
        Routingline.Validate("Run Time", LibraryRandom.RandIntInRange(30, 30));
        Routingline.Modify(true);

        // [GIVEN] Generate and save Run Time of second Routing Line in a Variable.
        RunTime2 := Routingline."Run Time";

        // [GIVEN] Generate and save Total Run Time of both Routing Lines in a Variable.
        TotalRunTime := RunTime + RunTime2;

        // [GIVEN] Update Routing Status.
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create Item and Validate Routing No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Released Production Order and Refresh it.
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item, Location.Code, '', LibraryRandom.RandInt(0));

        // [WHEN] Open Work Center Group Load page.
        OpenWorkCenterGroupLoadPage(WorkCenterGroupLoad, WorkCenterGroup.Code);
        WorkCenterGroupLoad.PeriodType.SetValue("Analysis Period Type"::Day);
        WorkCenterGroupLoad.AmountType.SetValue("Analysis Amount Type"::"Net Change");
        WorkCenterGroupLoad.WorkCtrGroupLoadLines.Filter.SetFilter("Period Start", Format(ProductionOrder."Starting Date"));

        // [THEN] Prod. Order Need (Qty.) in Work Center Group Load Lines is equal to Total Run Time of both Routing Lines.
        Assert.AreEqual(
          TotalRunTime,
          WorkCenterGroupLoad.WorkCtrGroupLoadLines."WorkCenterGroup.""Prod. Order Need (Qty.)""".AsDecimal(),
          StrSubstNo(
            ProdOrderNeedQtyErr,
            WorkCenterGroupLoad.WorkCtrGroupLoadLines."WorkCenterGroup.""Prod. Order Need (Qty.)""".Caption(),
            TotalRunTime,
            WorkCenterGroupLoad.WorkCtrGroupLoadLines.Caption()));

        WorkDate(CurrentWorkDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithoutExpectedMessage')]
    [Scope('OnPrem')]
    procedure Description2InFirmPlannedProdOrderIsPopulatedFromSO()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 538824] Description 2 is populated from Sales Line when Firm Planned Prod. Order is created from Sales Order.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item Reference for the Item and Validate Reference No. and Desciption 2.
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", ItemReference."Reference Type"::" ", '');
        ItemReference.Validate("Reference No.", Item."No.");
        ItemReference.Validate("Description 2", LibraryRandom.RandText(20));
        ItemReference.Insert(true);

        // [GIVEN] Create a Sales Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [GIVEN] Create a Sales Line and Validate Item Referene No.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Item Reference No.", ItemReference."Reference No.");
        SalesLine.Modify(true);

        // [WHEN] Create Production Order from Sales Order.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
          SalesHeader,
          ProductionOrder.Status::"Firm Planned",
          "Create Production Order Type"::ItemOrder);

        // [THEN] Description 2 in Production Order must be same as Description 2 in Sales Line.
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.FindLast();
        Assert.AreEqual(
          ProductionOrder."Description 2",
          ItemReference."Description 2",
          StrSubstNo(
            Description2Err,
            ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyEndingDateTimeProductionOrderWhenOutputPostedTwoTimes()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        ExpectedTime: Integer;
        OutputQty: Integer;
        TotalQty: Integer;
    begin
        // [SCENARIO 556711] Ending Date/Time in Production Order Line is calculated, when remaining Quantity lower than the Quantity
        Initialize();

        // [GIVEN] Assign TotalQty and OutputQty
        TotalQty := LibraryRandom.RandInt(60);
        OutputQty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Production Item  with single routing line and Work Center, SetupTime=0, runtime=1 and WaitTime=0
        CreateProductionItemWithRouting(Item, 0, 1, 0, 0, WorkDate());

        // [GIVEN] Create Production Order and releases it with given quantity and time should be 08:00 AM
        CreateAndRefreshForwardReleasedProductionOrder(ProductionOrder, Item."No.", TotalQty, WorkDate(), 080000T);

        // [GIVEN] Find first Prod. Order Routing Line
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");

        // [GIVEN] Create and post output of less than 10 quantity
        CreateAndPostOutputJnlLine(ProdOrderRoutingLine, Item."No.", OutputQty, 0, 0);

        // [WHEN] Find the first Prod. Order Line and validate the "Starting Date-Time" with same value
        FindFirstProdOrderLine(ProductionOrder, ProdOrderLine);
        ProdOrderLine.Validate("Starting Date-Time", ProdOrderLine."Starting Date-Time");

        // [WHEN] Save the Expected time in integer format
        ExpectedTime := (ProdOrderLine."Ending Time" - ProdOrderLine."Starting Time") / 60000;

        // [THEN] Verify expected time should be same as Output quantity deducted from Production Order quantity, runtime is 1
        Assert.AreEqual(ExpectedTime, TotalQty - OutputQty, EndingTimeErr);
    end;

    [Test]
    procedure ProductionOrderRoutingLineUnitCostCalculationMachineCenter()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenterCode: Code[20];
    begin
        // [SCENARIO 593788] Production Order Routing Line has Unit Cost Calculation from the Machine Center after adding Machine Center to the Prod. Order Routing Line.
        Initialize();

        // [GIVEN] Create a Work Center.
        CreateWorkCenter(WorkCenter);

        // [GIVEN] Calculate Work Center Calendar.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, WorkDate() - 30, WorkDate() + 30);

        // [GIVEN] Create Macine Center with Calendar.
        CreateMachineCenterWithCalendar(MachineCenter, WorkCenter);

        // [GIVEN] Create Production Item  with single routing line and Work Center, SetupTime=0, runtime=1 and WaitTime=0
        CreateProductionItemWithRouting(
          Item,
          LibraryRandom.RandIntInRange(0, 0),
          LibraryRandom.RandIntInRange(1, 1),
          LibraryRandom.RandIntInRange(0, 0),
          LibraryRandom.RandIntInRange(0, 0),
          WorkDate());

        // [GIVEN] Create Work Center with Shop Calendar.
        WorkCenterCode := CreateWorkCenterWithShopCalendar(CapacityUnitOfMeasure.Type::Minutes, CreateShopCalendar(), LibraryRandom.RandIntInRange(100, 100), LibraryRandom.RandIntInRange(1, 1), WorkDate());

        // [GIVEN] Create a Production Item.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");

        // [GIVEN] Create Routing with Machine Center.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateRoutingLineWithSendAhead(
          RoutingLine,
          RoutingHeader,
          RoutingLine.Type::"Work Center",
          WorkCenterCode,
          0,
          0,
          0,
          0,
          0,
          0,
          LibraryUtility.GenerateRandomText(5),
          '',
          '');

        // [GIVEN] Update Routing Status and Assign Routing No. to Item.
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [GIVEN] Create Production Order and releases it with given quantity and time.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder,
          ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item,
          Item."No.",
          LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Set Starting Date, Starting Time and Due Date to Production Order.
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Starting Date", WorkDate());
        ProductionOrder.Validate("Starting Time", Time());
        ProductionOrder.Validate("Due Date", WorkDate() + 1);
        ProductionOrder.Modify(true);

        // [GIVEN] Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Find first Prod. Order Routing Line
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");

        // [WHEN] Insert Prod. Order Routing Line, Validate Type and No. with Machine Center.
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Validate("Operation No.", LibraryUtility.GenerateRandomText(3));
        ProdOrderRoutingLine.Validate(Type, ProdOrderRoutingLine.Type::"Machine Center");
        ProdOrderRoutingLine.Validate("No.", MachineCenter."No.");
        ProdOrderRoutingLine.Insert();

        // [THEN] Verify Unit Cost Calculation on Prod. Order Routing Line for Machine Center is Time.
        Assert.AreEqual(
          ProdOrderRoutingLine."Unit Cost Calculation"::Time,
          ProdOrderRoutingLine."Unit Cost Calculation",
          StrSubstNo(
            UniCostCalculationErr,
            ProdOrderRoutingLine."Unit Cost Calculation"::Time,
            ProdOrderRoutingLine.Caption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Capacity Requirements");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Capacity Requirements");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        CalendarMgt.ClearInternals(); // clear single instance codeunit vars to avoid influence of other test codeunits
        Commit();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Capacity Requirements");
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Standard Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReorderQuantity: Decimal)
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithSerialRoutingReorder(var Item: Record Item; var WorkCenterCode: array[2] of Code[10]; ReorderingPolicy: Enum "Reordering Policy"; ReorderQuantity: Decimal)
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateProductionItem(Item, ReorderingPolicy, ReorderQuantity);
        CreateSerialRoutingWithSendAhead(RoutingHeader, WorkCenterCode);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithSerialRoutingSendAhead(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; RunTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; DueDate: Date)
    var
        SetupTime: array[3] of Decimal;
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        WorkCenterEfficiency: array[3] of Decimal;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(RunTime) do begin
            WorkCenterEfficiency[i] := 100;
            ConcurrentCapacities[i] := 1;
            SetupTime[i] := 0;
            WaitTime[i] := 0;
            MoveTime[i] := 0;
        end;
        CreateProductionItemWithSerialRouting(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, DueDate);
    end;

    local procedure CreateProductionItemWithSerialRoutingSetupWaitMoveTime(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; WaitTime: array[3] of Decimal; MoveTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; DueDate: Date)
    var
        WorkCenterEfficiency: array[3] of Decimal;
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(RunTime) do begin
            WorkCenterEfficiency[i] := 100;
            ConcurrentCapacities[i] := 1;
        end;
        CreateProductionItemWithSerialRouting(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, DueDate);
    end;

    local procedure CreateProductionItemWithSerialRoutingConcurrentCapacities(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; ConcurrentCapacities: array[3] of Decimal; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; WorkCenterEfficiency: array[3] of Decimal; DueDate: Date)
    var
        WaitTime: array[3] of Decimal;
        MoveTime: array[3] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(RunTime) do begin
            WaitTime[i] := 0;
            MoveTime[i] := 0;
        end;
        CreateProductionItemWithSerialRouting(
          Item, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities,
          WorkCenterStartTime, WorkCenterEndTime, WorkCenterEfficiency, DueDate);
    end;

    local procedure CreateProductionItemWithSerialRoutingShopCalendar(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; WaitTime: array[3] of Decimal; MoveTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; ShopCalendarCode: array[3] of Code[10]; DueDate: Date)
    var
        RoutingHeader: Record "Routing Header";
        ConcurrentCapacities: array[3] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(RunTime) do begin
            ConcurrentCapacities[i] := 1;
            WorkCenterCode[i] :=
              CreateWorkCenterWithShopCalendar(
                "Capacity Unit of Measure"::Minutes, ShopCalendarCode[i], 100, ConcurrentCapacities[i], DueDate);
        end;
        CreateProductionItem(Item, Item."Reordering Policy"::"Lot-for-Lot", 0);
        CreateSerialRoutingWithSendAheadAndWorkDays(
            RoutingHeader, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithSerialRouting(var Item: Record Item; var WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; WaitTime: array[3] of Decimal; MoveTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; ConcurrentCapacities: array[3] of Decimal; WorkCenterStartTime: array[3] of Time; WorkCenterEndTime: array[3] of Time; WorkCenterEfficiency: array[3] of Decimal; DueDate: Date)
    var
        RoutingHeader: Record "Routing Header";
        i: Integer;
    begin
        for i := 1 to ArrayLen(WorkCenterStartTime) do
            WorkCenterCode[i] :=
              CreateWorkCenterWithShopCalendar(
                "Capacity Unit of Measure"::Minutes,
                LibraryManufacturing.UpdateShopCalendarWorkingDaysCustomTime(WorkCenterStartTime[i], WorkCenterEndTime[i]),
                WorkCenterEfficiency[i], ConcurrentCapacities[i], DueDate);
        CreateProductionItem(Item, Item."Reordering Policy"::"Lot-for-Lot", 0);
        CreateSerialRoutingWithSendAheadAndWorkDays(
          RoutingHeader, WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQty, ConcurrentCapacities);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithOneLineRouting(var Item: Record Item; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; WorkCenterStartTime: Time; WorkCenterEndTime: Time; DueDate: Date)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUOM: Record "Capacity Unit of Measure";
        WorkCenterCode: Code[20];
    begin
        WorkCenterCode :=
          CreateWorkCenterWithShopCalendar(
            CapacityUOM.Type::Minutes,
            LibraryManufacturing.UpdateShopCalendarWorkingDaysCustomTime(WorkCenterStartTime, WorkCenterEndTime), 100, 1, DueDate);
        CreateProductionItem(Item, Item."Reordering Policy"::"Lot-for-Lot", 0);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, 0, 1, '10', '', '');
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithParallelRouting(var Item: Record Item; var WorkCenterCode: array[4] of Code[10]; ReorderingPolicy: Enum "Reordering Policy"; ReorderQuantity: Decimal)
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateProductionItem(Item, ReorderingPolicy, ReorderQuantity);
        CreateParallelRoutingWithSendAhead(RoutingHeader, WorkCenterCode);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithRoutingSetup(var Item: Record Item; IsMultipleUOM: Boolean)
    var
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Replenishment System"::Purchase);
        CreateRoutingSetup(RoutingHeader, IsMultipleUOM);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithoutRoutingTime(var Item: Record Item)
    var
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Replenishment System"::Purchase);
        CreateRoutingWithoutTimeSetup(RoutingHeader);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);  // Quantity per as 1.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header"; IsMultipleUOM: Boolean)
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", MachineCenter."No.", IsMultipleUOM);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", IsMultipleUOM);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateSerialRoutingWithSendAhead(var RoutingHeader: Record "Routing Header"; var WorkCenterCode: array[2] of Code[20])
    var
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := CreateThreeShiftsShopCalendar();
        WorkCenterCode[1] := CreateWorkCenterWithShopCalendar("Capacity Unit of Measure"::Hours, ShopCalendarCode, 100, 1, WorkDate());
        WorkCenterCode[2] := CreateWorkCenterWithShopCalendar("Capacity Unit of Measure"::Hours, ShopCalendarCode, 100, 1, WorkDate());
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[1], 0, 0.12121, 0, 0, 6, 1, '10', '', '');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[2], 0, 2.5, 0, 0, 0, 1, '20', '', '');
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateSerialRoutingWithSendAheadAndWorkDays(var RoutingHeader: Record "Routing Header"; WorkCenterCode: array[3] of Code[20]; SetupTime: array[3] of Decimal; RunTime: array[3] of Decimal; WaitTime: array[3] of Decimal; MoveTime: array[3] of Decimal; SendAheadQty: array[3] of Integer; ConcurrentCapacities: array[3] of Decimal)
    var
        RoutingLine: Record "Routing Line";
        OperationNo: Code[10];
        PrevOperationNo: Code[10];
        NextOperationNo: Code[10];
        i: Integer;
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 3 downto 1 do begin
            OperationNo := Format(i * 10);
            PrevOperationNo := Format((i - 1) * 10);
            CreateRoutingLineWithSendAhead(
              RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center",
              WorkCenterCode[i], SetupTime[i], RunTime[i], WaitTime[i], MoveTime[i], SendAheadQty[i], ConcurrentCapacities[i],
              OperationNo, PrevOperationNo, NextOperationNo);
            NextOperationNo := OperationNo;
        end;
        RoutingLine."Previous Operation No." := '';
        RoutingLine.Modify();
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateParallelRoutingWithSendAhead(var RoutingHeader: Record "Routing Header"; var WorkCenterCode: array[4] of Code[20])
    var
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
        i: Integer;
    begin
        ShopCalendarCode := CreateThreeShiftsShopCalendar();
        for i := 1 to ArrayLen(WorkCenterCode) do
            WorkCenterCode[i] := CreateWorkCenterWithShopCalendar("Capacity Unit of Measure"::Hours, ShopCalendarCode, 100, 1, WorkDate());
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[1], 0, 2.5, 0, 0, 0, 1, '10', '', '20|30');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[2], 0, 0.12121, 0, 0, 6, 1, '20', '', '40');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[3], 0, 2.5, 0, 0, 0, 1, '30', '', '40');
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode[4], 0, 2.5, 0, 0, 0, 1, '40', '', '');
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingWithoutTimeSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
        OperationNo: Code[10];
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenter."No.");
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingWithRunTime(WorkCenterNo: Code[20]; RunTime: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
        CapacityUnitOfMeasure.FindFirst();

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        exit(RoutingHeader."No.");
    end;

    local procedure CreateWorkCenterWithDirectCost(DirectCost: Decimal): Code[20]
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenter: Record "Work Center";
    begin
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Hours);
        CapacityUnitOfMeasure.FindFirst();

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Direct Unit Cost", DirectCost);
        WorkCenter.Modify(true);

        exit(WorkCenter."No.");
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(100, 2));
        MachineCenter.Validate("Setup Time", LibraryRandom.RandDec(10, 2));
        MachineCenter.Validate("Wait Time", LibraryRandom.RandDec(10, 2));
        MachineCenter.Validate("Move Time", LibraryRandom.RandDec(10, 2));
        MachineCenter.Validate(Capacity, LibraryRandom.RandIntInRange(3, 5));
        // Any value except 1.
        MachineCenter.Modify(true);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; Type: Enum "Capacity Type Routing"; No: Code[20]; IsMultipleUOM: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, Type, No);
        RoutingLine.Validate("Setup Time", LibraryRandom.RandDec(10, 2));
        RoutingLine.Validate("Run Time", LibraryRandom.RandDec(10, 2));
        RoutingLine.Validate("Wait Time", LibraryRandom.RandDec(10, 2));
        RoutingLine.Validate("Move Time", LibraryRandom.RandDec(10, 2));
        if IsMultipleUOM then begin
            LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::"100/Hour");
            RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
            LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes);
            RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
            LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Hours);
            RoutingLine.Validate("Wait Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
            LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Days);
            RoutingLine.Validate("Move Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        end;
        RoutingLine.Modify(true)
    end;

    local procedure CreateRoutingLineWithSendAhead(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; Type: Enum "Capacity Type Routing"; No: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; SendAhead: Integer; ConcurrentCapacities: Decimal; OperationNo: Code[10]; PrevOperationNo: Code[10]; NextOperationNo: Code[10])
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, Type, No);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Validate("Move Time", MoveTime);
        RoutingLine.Validate("Send-Ahead Quantity", SendAhead);
        RoutingLine.Validate("Concurrent Capacities", ConcurrentCapacities);
        RoutingLine.Validate("Previous Operation No.", PrevOperationNo);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Modify(true)
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure CreateWorkCenterWithShopCalendar(UOMType: Enum "Capacity Unit of Measure"; ShopCalendarCode: Code[10]; Efficiency: Decimal; Capacity: Decimal; DueDate: Date): Code[20]
    var
        WorkCenter: Record "Work Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, UOMType);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate(Efficiency, Efficiency);
        WorkCenter.Validate(Capacity, Capacity);
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', DueDate), CalcDate('<+2M>', DueDate));
        exit(WorkCenter."No.");
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

    local procedure FindLastItemLedgEntryForOutput(ItemNo: Code[20]; IsPositive: Boolean): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure CreateAndRefreshBackwardFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshForwardFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; StartingDate: Date; StartingTime: Time)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Starting Date", StartingDate);
        ProductionOrder.Validate("Starting Time", StartingTime);
        ProductionOrder.Validate("Due Date", StartingDate + 1);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
    end;

    local procedure CreateAndRefreshPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; Forward: Boolean)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, Forward, true, true, true, false);
    end;

    local procedure CreateAndRefreshBackwardPlanningLine(var RequisitionLine: Record "Requisition Line"; SourceNo: Code[20]; Quantity: Decimal; DueDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Direction: Option Forward,Backward;
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", SourceNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.SetCurrFieldNo(RequisitionLine.FieldNo("Due Date"));
        RequisitionLine.Validate("Due Date", DueDate);
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);
    end;

    local procedure CreateAndRefreshForwardPlanningLine(var RequisitionLine: Record "Requisition Line"; SourceNo: Code[20]; Quantity: Decimal; StartingDate: Date; StartingTime: Time)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Direction: Option Forward,Backward;
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", SourceNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Validate("Starting Date", StartingDate);
        RequisitionLine.Validate("Starting Time", StartingTime);
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Forward, true, true);
    end;

    local procedure CreateAndRefreshForwardReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; StartingDate: Date; StartingTime: Time)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Starting Date", StartingDate);
        ProductionOrder.Validate("Starting Time", StartingTime);
        ProductionOrder.Validate("Due Date", StartingDate + 1);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
    end;

    local procedure CreateThreeShiftsShopCalendar(): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShiftCodes: array[3] of Code[10];
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        CreateThreeWorkShifts(WorkShiftCodes);
        UpdateThreeShiftsShopCalendarWorkingDays(ShopCalendar.Code, WorkShiftCodes);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateThreeWorkShifts(var WorkShiftCodes: array[3] of Code[10])
    var
        WorkShift: Record "Work Shift";
        i: Integer;
    begin
        for i := 1 to ArrayLen(WorkShiftCodes) do begin
            LibraryManufacturing.CreateWorkShiftCode(WorkShift);
            WorkShiftCodes[i] := WorkShift.Code;
        end;
    end;

    local procedure CreateTwoShiftsShopCalendarWeekDays(FirstShiftStartTime: Time; FirstShiftEndTime: Time; SecondShiftStartTime: Time; SecondShiftEndTime: Time): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShift: Record "Work Shift";
        ShopCalendWorkDays: Record "Shop Calendar Working Days";
        WorkShiftCode: Code[10];
        Day: Integer;
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        WorkShiftCode := LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        for Day := ShopCalendWorkDays.Day::Monday to ShopCalendWorkDays.Day::Friday do
            LibraryManufacturing.CreateShopCalendarWorkingDays(ShopCalendWorkDays, ShopCalendar.Code, Day, WorkShiftCode, FirstShiftStartTime, FirstShiftEndTime);

        WorkShiftCode := LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        for Day := ShopCalendWorkDays.Day::Monday to ShopCalendWorkDays.Day::Friday do
            LibraryManufacturing.CreateShopCalendarWorkingDays(ShopCalendWorkDays, ShopCalendar.Code, Day, WorkShiftCode, SecondShiftStartTime, SecondShiftEndTime);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateOutputJnlLineWithSetupRunTime(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; ProdOrderRtngLineOperationNo: Code[10]; SetupTime: Decimal; RunTime: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Output, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);

        ItemJournalLine.Validate("Operation No.", ProdOrderRtngLineOperationNo);
        ItemJournalLine.Validate("Setup Time", SetupTime);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostOutputJnlLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemNo: Code[20]; Qty: Decimal; SetupTime: Decimal; RunTime: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJnlLineWithSetupRunTime(
          ItemJournalLine, ProdOrderRoutingLine."Prod. Order No.", ItemNo, ProdOrderRoutingLine."Operation No.", SetupTime, RunTime);
        ItemJournalLine.Validate("Output Quantity", Qty);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure OpenWorkCenterLoadPage(var WorkCenterLoad: TestPage "Work Center Load"; WorkCenterNo: Code[20])
    var
        WorkCenterCard: TestPage "Work Center Card";
    begin
        OpenWorkCenterCard(WorkCenterCard, WorkCenterNo);
        WorkCenterLoad.Trap();
        WorkCenterCard."Lo&ad".Invoke();
    end;

    local procedure OpenMachineCenterLoadPage(var MachineCenterLoad: TestPage "Machine Center Load"; MachineCenterNo: Code[20])
    var
        MachineCenterCard: TestPage "Machine Center Card";
    begin
        OpenMachineCenterCard(MachineCenterCard, MachineCenterNo);
        MachineCenterLoad.Trap();
        MachineCenterCard."Lo&ad".Invoke();
    end;

    local procedure OpenMachineCenterCard(var MachineCenterCard: TestPage "Machine Center Card"; No: Code[20])
    begin
        MachineCenterCard.OpenEdit();
        MachineCenterCard.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenWorkCenterCard(var WorkCenterCard: TestPage "Work Center Card"; No: Code[20])
    begin
        WorkCenterCard.OpenEdit();
        WorkCenterCard.FILTER.SetFilter("No.", No);
    end;

    local procedure UpdateMachineCenterBlocked(var MachineCenter: Record "Machine Center")
    begin
        // Block Machine Center.
        MachineCenter.Validate(Blocked, true);
        MachineCenter.Modify(true);
    end;

    local procedure UpdateWorkCenterBlocked(var WorkCenter: Record "Work Center")
    begin
        // Block Work Center.
        WorkCenter.Validate(Blocked, true);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateMachineCenterWithZeroEfficiency(var MachineCenter: Record "Machine Center")
    begin
        MachineCenter.Validate(Efficiency, 0);  // Set Zero Efficiency.
        MachineCenter.Modify(true);
    end;

    local procedure UpdateWorkCenterWithZeroEfficiency(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.Validate(Efficiency, 0);  // Set Zero Efficiency.
        WorkCenter.Modify(true);
    end;

    local procedure UpdateWorkCenterWithZeroCapacity(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.Validate(Capacity, 0);  // Set Zero Capacity.
        WorkCenter.Modify(true);
    end;

    local procedure UpdateThreeShiftsShopCalendarWorkingDays(ShopCalendarCode: Code[10]; WorkShiftCodes: array[3] of Code[10])
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        DoW: Integer;
    begin
        for DoW := ShopCalendarWorkingDays.Day::Monday to ShopCalendarWorkingDays.Day::Sunday do begin
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCodes[1], 000000T, 080000T);
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCodes[2], 080000T, 160000T);
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCodes[3], 160000T, 235959T);
        end;
    end;

    local procedure CalculateCapacity(var CapacityAvailable: Decimal; var CapacityEfficiency: Decimal; WorkCenter: Record "Work Center"; StartingDate: Date)
    begin
        // Calculate Capacity Available and Capacity Efficiency values.
        WorkCenter.SetRange("Date Filter", StartingDate);
        WorkCenter.CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");
        CapacityAvailable := WorkCenter."Capacity (Effective)" - WorkCenter."Prod. Order Need (Qty.)";
        if WorkCenter."Capacity (Effective)" <> 0 then
            CapacityEfficiency := Round(WorkCenter."Prod. Order Need (Qty.)" / WorkCenter."Capacity (Effective)" * 100, 0.1);  // Calculation formula taken from Page - Work Center Load Lines.
    end;

    local procedure CalcRoutingLineQtyBase(RoutingLine: Record "Routing Line"): Decimal
    begin
        exit(
              RoutingLine."Setup Time" * CalendarMgt.TimeFactor(RoutingLine."Setup Time Unit of Meas. Code") +
              RoutingLine."Run Time" * CalendarMgt.TimeFactor(RoutingLine."Run Time Unit of Meas. Code") +
              RoutingLine."Wait Time" * CalendarMgt.TimeFactor(RoutingLine."Wait Time Unit of Meas. Code") +
              RoutingLine."Move Time" * CalendarMgt.TimeFactor(RoutingLine."Move Time Unit of Meas. Code"));
    end;

    local procedure FindWorkCenter(var WorkCenter: Record "Work Center"; RoutingNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, RoutingLine.Type::"Work Center");
        WorkCenter.Get(RoutingLine."No.");
    end;

    local procedure FindRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; Type: Enum "Capacity Type Routing")
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange(Type, Type);
        RoutingLine.FindFirst();
    end;

    local procedure SetWorkCentersOperationalHours(var StartTime: array[3] of Time; var EndTime: array[3] of Time; FromTime1: Time; ToTime1: Time; FromTime2: Time; ToTime2: Time; FromTime3: Time; ToTime3: Time)
    begin
        StartTime[1] := FromTime1;
        EndTime[1] := ToTime1;
        StartTime[2] := FromTime2;
        EndTime[2] := ToTime2;
        StartTime[3] := FromTime3;
        EndTime[3] := ToTime3;
    end;

    local procedure SetRunTime(var RunTime: array[3] of Decimal; RunTime1: Decimal; RunTime2: Decimal; RunTime3: Decimal)
    begin
        RunTime[1] := RunTime1;
        RunTime[2] := RunTime2;
        RunTime[3] := RunTime3;
    end;

    local procedure SetConcurrentCapacities(var ConcurrentCapacities: array[3] of Decimal; ConcurrCap1: Decimal; ConcurrCap2: Decimal; ConcurrCap3: Decimal)
    begin
        ConcurrentCapacities[1] := ConcurrCap1;
        ConcurrentCapacities[2] := ConcurrCap2;
        ConcurrentCapacities[3] := ConcurrCap3;
    end;

    local procedure UpdateStatusOnRoutingHeader(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateStandardCostingMethodOnItem(var Item: Record Item)
    begin
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Modify(true);
    end;

    local procedure UpdateUnitCostCalculationOnWorkCenter(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Get(WorkCenterNo);
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Specific Unit Cost", true);
        WorkCenter.Modify(true);
    end;

    local procedure FindProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure UpdateUnitCostPerOnRoutingLine(var RoutingLine: Record "Routing Line")
    begin
        RoutingLine.Validate("Unit Cost per", LibraryRandom.RandDec(10, 2));
        RoutingLine.Modify(true);
    end;

    local procedure UpdateUnitCostPerOnRoutingLineAndReCertify(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingNo);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::New);
        FindRoutingLine(RoutingLine, RoutingNo, RoutingLine.Type::"Work Center");
        UpdateUnitCostPerOnRoutingLine(RoutingLine);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure UpdateSendAheadQuantityOnRoutingLineAndReCertify(RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(RoutingNo);
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::New);
        UpdateSendAheadQuantityOnRoutingLine(RoutingNo, RoutingLine.Type::"Work Center");
        UpdateSendAheadQuantityOnRoutingLine(RoutingNo, RoutingLine.Type::"Machine Center");
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure UpdateSendAheadQuantityOnRoutingLine(RoutingNo: Code[20]; Type: Enum "Capacity Type")
    var
        RoutingLine: Record "Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        RoutingLine.Validate("Send-Ahead Quantity", LibraryRandom.RandDec(10, 2));
        RoutingLine.Modify(true);
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure FindFirstProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindFirstPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; WorksheetTemplateName: Code[10]; WorksheetLineNo: Integer)
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", WorksheetTemplateName);
        PlanningRoutingLine.SetRange("Worksheet Line No.", WorksheetLineNo);
        PlanningRoutingLine.FindFirst();
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; Type: Enum "Capacity Type"; No: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange(Type, Type);
        ProdOrderRoutingLine.SetRange("No.", No);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindFirmPlannedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; Type: Enum "Capacity Type"; No: Code[20])
    begin
        PlanningRoutingLine.SetRange(Type, Type);
        PlanningRoutingLine.SetRange("No.", No);
        PlanningRoutingLine.FindFirst();
    end;

    local procedure FindFirstProdOrderCapacityNeedWithTimeType(var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type")
    begin
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapacityNeed.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        ProdOrderCapacityNeed.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapacityNeed.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapacityNeed.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapacityNeed.SetRange("Time Type", TimeType);
        ProdOrderCapacityNeed.FindFirst();
    end;

    local procedure GetNextProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; NextOperationNo: Code[30])
    begin
        ProdOrderRoutingLine.SetRange("Operation No.", CopyStr(NextOperationNo, 1, MaxStrLen(ProdOrderRoutingLine."Operation No.")));
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure GetNextPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; NextOperationNo: Code[30])
    begin
        PlanningRoutingLine.SetRange("Operation No.", CopyStr(NextOperationNo, 1, MaxStrLen(PlanningRoutingLine."Operation No.")));
        PlanningRoutingLine.FindFirst();
    end;

    local procedure UpdateStartingDateAndTimeOnProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.Validate("Starting Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        ProdOrderLine.Validate("Starting Time", Time);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateProdOrderLineWithZeroQuantity(var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.Validate(Quantity, 0);  // Set Zero Quantity.
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; Type: Enum "Capacity Type Routing"; RoutingLineNo: Code[20]; SendAheadQuantity: Decimal; ConcurrentCapacities: Decimal)
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo, Type, RoutingLineNo);
        ProdOrderRoutingLine.Validate("Send-Ahead Quantity", SendAheadQuantity);
        ProdOrderRoutingLine.Validate("Concurrent Capacities", ConcurrentCapacities);
        ProdOrderRoutingLine.Validate("Starting Date", CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        ProdOrderRoutingLine.Validate("Starting Time", 080000T);
        // To make sure the Starting Time of the next Operation won't exceed the ending time of current working day.
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure CreateFirmPlannedProductionOrderFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryVariableStorage.Enqueue(FirmPlannedProductionOrderCreated);  // Enqueue value for Message Handler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
              SalesHeader, ProductionOrder.Status::"Firm Planned", "Create Production Order Type"::ProjectOrder);
    end;

    local procedure FilterOnWorkCenterLoadPage(var WorkCenterLoad: TestPage "Work Center Load"; PeriodStart: Date)
    var
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
    begin
        WorkCenterLoad.PeriodType.SetValue(PeriodType::Day);
        WorkCenterLoad.AmountType.SetValue(AmountType::"Net Change");
        WorkCenterLoad.MachineCenterLoadLines.FILTER.SetFilter("Period Start", Format(PeriodStart));
    end;

    local procedure FilterOnMachineCenterLoadPage(var MachineCenterLoad: TestPage "Machine Center Load"; PeriodStart: Date)
    var
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
    begin
        MachineCenterLoad.PeriodType.SetValue(PeriodType::Day);
        MachineCenterLoad.AmountType.SetValue(AmountType::"Net Change");
        MachineCenterLoad.MachineCLoadLines.FILTER.SetFilter("Period Start", Format(PeriodStart));
    end;

    local procedure UpdateLotForLotReorderingPolicyOnItem(var Item: Record Item)
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure UpdateScheduleManuallyOnProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ScheduleManually: Boolean)
    begin
        ProdOrderRoutingLine.Validate("Schedule Manually", ScheduleManually);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure VerifyWorkCenterLoad(WorkCenterLoad: TestPage "Work Center Load"; PeriodStart: Date; CapacityAvailable: Decimal; CapacityEfficiency: Decimal)
    begin
        // Verify Work Center Load Page.
        FilterOnWorkCenterLoadPage(WorkCenterLoad, PeriodStart);
        WorkCenterLoad.MachineCenterLoadLines.CapacityAvailable.AssertEquals(CapacityAvailable);
        WorkCenterLoad.MachineCenterLoadLines.CapacityEfficiency.AssertEquals(CapacityEfficiency);
    end;

    local procedure VerifyOperationsTimeOnProdOrderRoutingLine(ProductionOrderNo: Code[20]; RoutingNo: Code[20]; Type: Enum "Capacity Type Routing")
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo, Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Wait Time", RoutingLine."Wait Time");
        ProdOrderRoutingLine.TestField("Move Time", RoutingLine."Move Time");
    end;

    local procedure VerifyOperationsTimeOnPlanningRoutingLine(RoutingNo: Code[20]; Type: Enum "Capacity Type Routing")
    var
        RoutingLine: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindPlanningRoutingLine(PlanningRoutingLine, Type, RoutingLine."No.");
        PlanningRoutingLine.TestField("Wait Time", RoutingLine."Wait Time");
        PlanningRoutingLine.TestField("Move Time", RoutingLine."Move Time");
    end;

    local procedure VerifySendAheadQuantityOnPlanningRoutingLine(RoutingNo: Code[20]; Type: Enum "Capacity Type")
    var
        RoutingLine: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindPlanningRoutingLine(PlanningRoutingLine, Type, RoutingLine."No.");
        PlanningRoutingLine.TestField("Send-Ahead Quantity", RoutingLine."Send-Ahead Quantity");
    end;

    local procedure VerifySendAheadQuantityOnProdOrderRoutingLine(ProdOrderNo: Code[20]; RoutingNo: Code[20]; Type: Enum "Capacity Type")
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo, Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Send-Ahead Quantity", RoutingLine."Send-Ahead Quantity");
    end;

    local procedure VerifyStartingDateAndTimeOnProdOrderRoutingLine(ProdOrderLine: Record "Prod. Order Line"; RoutingNo: Code[20]; Type: Enum "Capacity Type Routing")
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine."Prod. Order No.", Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Starting Time", ProdOrderLine."Starting Time");
        ProdOrderRoutingLine.TestField("Starting Date", ProdOrderLine."Starting Date");
    end;

    local procedure VerifyProdOrderCapacityNeed(ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need"; Type: Enum "Capacity Type"; No: Code[20]; StartingDate: Date)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeedPage.FILTER.SetFilter(Type, Format(Type));
        ProdOrderCapacityNeed.SetRange("Requested Only", false);
        ProdOrderCapacityNeed.SetRange("No.", No);
        ProdOrderCapacityNeed.SetRange(Date, StartingDate);
        ProdOrderCapacityNeed.FindSet();
        repeat
            ProdOrderCapacityNeedPage.FILTER.SetFilter("Time Type", Format(ProdOrderCapacityNeed."Time Type"));
            ProdOrderCapacityNeedPage."Allocated Time".AssertEquals(ProdOrderCapacityNeed."Allocated Time");
        until ProdOrderCapacityNeed.Next() = 0;
    end;

    local procedure VerifyStartingDateTimeOnProdOrderRoutingLine(RoutingNo: Code[20]; ProdOrderNo: Code[20]; Type: Enum "Capacity Type Routing"; StartingDateTime: DateTime)
    var
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindRoutingLine(RoutingLine, RoutingNo, Type);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo, Type, RoutingLine."No.");
        ProdOrderRoutingLine.TestField("Starting Date-Time", StartingDateTime);
    end;

    local procedure VerifyProdOrderCapacityNeedTime(WorkCenterCode: array[4] of Code[10]; WorkCenterCount: Integer)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        i: Integer;
        EndingDateTime: DateTime;
        ZeroEndingDateTime: DateTime;
    begin
        ProdOrderCapacityNeed.SetCurrentKey(Type, "No.", "Starting Date-Time", "Ending Date-Time", Active);
        for i := 1 to WorkCenterCount do begin
            ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterCode[i]);
            ProdOrderCapacityNeed.FindSet();
            EndingDateTime := ProdOrderCapacityNeed."Starting Date-Time";
            if DT2Time(EndingDateTime) = 235959T then
                ZeroEndingDateTime := CreateDateTime(DT2Date(EndingDateTime) + 1, 0T);
            repeat
                Assert.IsTrue(
                  (ProdOrderCapacityNeed."Starting Date-Time" = EndingDateTime) or
                  (ProdOrderCapacityNeed."Starting Date-Time" = ZeroEndingDateTime),
                  StrSubstNo(TheGapErr, WorkCenterCode[i], ProdOrderCapacityNeed."Starting Date-Time", EndingDateTime));
                EndingDateTime := ProdOrderCapacityNeed."Ending Date-Time";
                ZeroEndingDateTime := 0DT;
                if DT2Time(EndingDateTime) - 235959T < 1000 then
                    ZeroEndingDateTime := CreateDateTime(DT2Date(EndingDateTime) + 1, 0T);
            until ProdOrderCapacityNeed.Next() = 0;
        end;
    end;

    local procedure VerifyCapacityNeedFirstStartLastEndDateTime(ProdOrderNo: Code[20]; WorksheetTemplateName: Code[10]; WorkCenterCode: Code[20]; ExpectedFirstCapNeedStartDateTime: DateTime; ExpectedLastCapNeedEndDateTime: DateTime)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetCurrentKey(Type, "No.", "Starting Date-Time", "Ending Date-Time", Active);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", WorksheetTemplateName);
        ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterCode);
        ProdOrderCapacityNeed.FindFirst();
        ProdOrderCapacityNeed.TestField(Date, DT2Date(ExpectedFirstCapNeedStartDateTime));
        ProdOrderCapacityNeed.TestField("Starting Time", DT2Time(ExpectedFirstCapNeedStartDateTime));
        ProdOrderCapacityNeed.FindLast();
        ProdOrderCapacityNeed.TestField(Date, DT2Date(ExpectedLastCapNeedEndDateTime));
        ProdOrderCapacityNeed.TestField("Ending Time", DT2Time(ExpectedLastCapNeedEndDateTime));
    end;

    local procedure VerifyCapacityNeedTotalAllocatedTime(ProdOrderNo: Code[20]; WorksheetTemplateName: Code[10]; WorkCenterCode: Code[20]; ExpectedTotalAllocatedTime: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", WorksheetTemplateName);
        ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenterCode);
        ProdOrderCapacityNeed.CalcSums("Allocated Time");
        Assert.AreEqual(
          ExpectedTotalAllocatedTime, ProdOrderCapacityNeed."Allocated Time",
          'Wrong allocated time in capacity need for the production order or the planning line.');
    end;

    local procedure VerifyCapacityNeedAllocatedTimeForTwoLines(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; ExpectedAllocatedTime1: Decimal; ExpectedAllocatedTime2: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        FindFirstProdOrderCapacityNeedWithTimeType(ProdOrderCapacityNeed, ProdOrderRoutingLine, TimeType);
        ProdOrderCapacityNeed.TestField("Allocated Time", ExpectedAllocatedTime1);
        ProdOrderCapacityNeed.SetRange(Date, ProdOrderCapacityNeed.Date + 1);
        ProdOrderCapacityNeed.FindFirst();  // find next line
        ProdOrderCapacityNeed.TestField("Allocated Time", ExpectedAllocatedTime2);
    end;

    local procedure VerifyCapacityNeedTime(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; AllocatedTime: Decimal; NeededTime: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        FindFirstProdOrderCapacityNeedWithTimeType(ProdOrderCapacityNeed, ProdOrderRoutingLine, TimeType);
        ProdOrderCapacityNeed.CalcSums("Allocated Time", "Needed Time");
        ProdOrderCapacityNeed.TestField("Allocated Time", AllocatedTime);
        ProdOrderCapacityNeed.TestField("Needed Time", NeededTime);
    end;

    local procedure VerifyProdOrderStartEndDateTime(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ExpectedStartingDateTime: DateTime; ExpectedEndingDateTime: DateTime)
    begin
        ProdOrderRoutingLine.TestField("Starting Date-Time", ExpectedStartingDateTime);
        ProdOrderRoutingLine.TestField("Ending Date-Time", ExpectedEndingDateTime);
    end;

    local procedure VerifyPlanningLineStartEndDateTime(PlanningRoutingLine: Record "Planning Routing Line"; ExpectedStartingDateTime: DateTime; ExpectedEndingDateTime: DateTime)
    begin
        PlanningRoutingLine.TestField("Starting Date-Time", ExpectedStartingDateTime);
        PlanningRoutingLine.TestField("Ending Date-Time", ExpectedEndingDateTime);
    end;

    local procedure RunBOMCostSharesPage(var Item: Record Item)
    var
        BOMCostShares: Page "BOM Cost Shares";
    begin
        BOMCostShares.InitItem(Item);
        BOMCostShares.Run();
    end;

    local procedure CreateLocationWithBinAndWarehouseEmployeeSetup(
      var Location: Record Location;
      var Bin: Record Bin;
      var WarehouseEmployee: Record "Warehouse Employee")
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Default Bin Selection", Location."Default Bin Selection"::"Last-Used Bin");
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Modify(true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, Format(LibraryRandom.RandText(4)), '', '');

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateShopCalendar(StartingTime: Time; EndingTime: Time): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        CreateShopCalendarWorkingDays(ShopCalendarCode, StartingTime, EndingTime);
        exit(ShopCalendarCode);
    end;

    local procedure CreateShopCalendarWorkingDays(ShopCalendarCode: Code[10]; StartingTime: Time; EndingTime: Time)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkShift: Record "Work Shift";
        WorkShiftCode: Code[10];
    begin
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);
        WorkShiftCode := LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Monday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Tuesday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Wednesday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Thursday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Friday, WorkShiftCode, StartingTime, EndingTime);
    end;

    local procedure CreateReleasedProdOrderAndRefresh(
      var ProductionOrder: Record "Production Order";
      Item: Record Item;
      LocationCode: Code[10];
      BinCode: Code[20];
      Qty: Integer)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateWorkCenterWithWorkCenterGroupCode(var WorkCenter: Record "Work Center")
    var
        WorkCenterGroup: Record "Work Center Group";
    begin
        LibraryManufacturing.CreateWorkCenterGroup(WorkCenterGroup);

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Work Center Group Code", WorkCenterGroup.Code);
        WorkCenter.Validate("Shop Calendar Code", CreateShopCalendar(080000T, 160000T));
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(1.20, 1.20, 2));
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDecInDecimalRange(1.20, 1.20, 2));
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Time);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Manual);
        WorkCenter.Validate(Capacity, LibraryRandom.RandIntInRange(3, 3));
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachineCenterWithCalendar(var MachineCenter: Record "Machine Center"; var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenter."No.", LibraryRandom.RandInt(0));
        MachineCenter.Validate("Flushing Method", MachineCenter."Flushing Method"::Manual);
        MachineCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        MachineCenter.Modify(true);
    end;

    local procedure CreateRoutingWithTwoMachineCenters(
      var MachineCenter: Record "Machine Center";
      var MachineCenter2: Record "Machine Center";
      var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader,
          RoutingLine,
          '',
          Format(LibraryRandom.RandIntInRange(10, 10)),
          RoutingLine.Type::"Machine Center",
          MachineCenter."No.");

        RoutingLine.Validate("Setup Time", LibraryRandom.RandIntInRange(20, 20));
        RoutingLine.Validate("Run Time", LibraryRandom.RandIntInRange(15, 15));
        RoutingLine.Modify(true);

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader,
          RoutingLine2,
          '',
          Format(LibraryRandom.RandIntInRange(20, 20)),
          RoutingLine2.Type::"Machine Center",
          MachineCenter2."No.");

        RoutingLine2.Validate("Setup Time", LibraryRandom.RandIntInRange(20, 20));
        RoutingLine2.Validate("Run Time", LibraryRandom.RandIntInRange(18, 18));
        RoutingLine2.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; var RoutingHeader: Record "Routing Header")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure OpenWorkCenterGroups(var WorkCenterGroups: TestPage "Work Center Groups"; WorkCenterGroupCode: Code[10])
    begin
        WorkCenterGroups.OpenEdit();
        WorkCenterGroups.FILTER.SetFilter("Code", WorkCenterGroupCode);
    end;

    local procedure OpenWorkCenterGroupLoadPage(var WorkCenterGroupLoad: TestPage "Work Center Group Load"; WorkCenterGroupCode: Code[10])
    var
        WorkCenterGroups: TestPage "Work Center Groups";
    begin
        OpenWorkCenterGroups(WorkCenterGroups, WorkCenterGroupCode);
        WorkCenterGroupLoad.Trap();
        WorkCenterGroups."Lo&ad".Invoke();
    end;

    local procedure CreateWorkCenterWithWorkCenterGrpCode(
      var WorkCenter: Record "Work Center";
      WorkCenterGroupCode: Code[10];
      ShopCalendarCode: Code[10];
      Capacity: Decimal;
      UnitOfMeasureCode: Code[10])
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Work Center Group Code", WorkCenterGroupCode);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Manual);
        WorkCenter.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WorkCenter.Validate(Capacity, Capacity);
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Modify(true);
    end;

    local procedure SetWorkingDayInWorkDate(): Date
    begin
        if Date2DWY(WorkDate(), 1) in [1, 6, 7] then
            exit(CalcDate('<3D>', WorkDate()));
    end;

    local procedure CreateProductionItemWithRouting(var Item: Record Item; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; DueDate: Date)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUOM: Record "Capacity Unit of Measure";
        WorkCenterCode: Code[20];
    begin
        WorkCenterCode := CreateWorkCenterWithShopCalendar(CapacityUOM.Type::Minutes, CreateShopCalendar(), 100, 1, DueDate);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithSendAhead(
          RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterCode, SetupTime, RunTime, WaitTime, MoveTime, 0, 1, '10', '', '');
        UpdateStatusOnRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateShopCalendar(): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShift: Record "Work Shift";
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        UpdateShiftsShopCalendarWorkingDays(ShopCalendar.Code, WorkShift.Code);
        exit(ShopCalendar.Code);
    end;

    local procedure UpdateShiftsShopCalendarWorkingDays(ShopCalendarCode: Code[10]; WorkShiftCode: Code[10])
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        DoW: Integer;
    begin
        for DoW := ShopCalendarWorkingDays.Day::Monday to ShopCalendarWorkingDays.Day::Sunday do
            LibraryManufacturing.CreateShopCalendarWorkingDays(
              ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCode, 000000T, 235959T);
    end;

    local procedure FindFirstProdOrderLine(ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ProductionOrder."Source No.");
        ProdOrderLine.FindFirst();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStandardCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level.
        Choice := 2;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        Item: Record Item;
        BOMBuffer: Record "BOM Buffer";
        RoutingLine: Record "Routing Line";
        VariantVar1: Variant;
        VariantVar2: Variant;
        VariantVar3: Variant;
        ItemNo: Code[20];
        RoutingNo: Code[20];
        ExpWarning: Text;
    begin
        LibraryVariableStorage.Dequeue(VariantVar1);
        LibraryVariableStorage.Dequeue(VariantVar2);
        LibraryVariableStorage.Dequeue(VariantVar3);

        ItemNo := VariantVar1;
        Item.Get(ItemNo);
        RoutingNo := VariantVar2;
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst();
        ExpWarning := VariantVar3;

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.FILTER.SetFilter("No.", ItemNo);
        BOMCostShares.First();
        Assert.AreEqual(Item."Standard Cost", BOMCostShares."Total Cost".AsDecimal(), StrSubstNo(TopItemTotalCostErr, ItemNo));

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::"Work Center"));
        BOMCostShares.FILTER.SetFilter("No.", RoutingLine."Work Center No.");
        BOMCostShares.First();

        Assert.AreEqual(ExpWarning, Format(BOMCostShares.HasWarning), StrSubstNo(WorkCenterWarningErr, RoutingLine."Work Center No."));
        Assert.AreEqual(
          RoutingLine."Unit Cost per", BOMCostShares."Total Cost".AsDecimal(),
          StrSubstNo(WorkCenterTotalCostErr, RoutingLine."Work Center No."));
        BOMCostShares.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesVerifyQtyPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        BOMBuffer: Record "BOM Buffer";
        Variant: Variant;
        MachineCenterNo: Code[20];
        ExpectedQty: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        MachineCenterNo := Variant;
        LibraryVariableStorage.Dequeue(Variant);
        ExpectedQty := Variant;

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::"Machine Center"));
        BOMCostShares.FILTER.SetFilter("No.", MachineCenterNo);
        BOMCostShares.First();
        Assert.AreEqual(ExpectedQty, BOMCostShares."Qty. per Parent".AsDecimal(), BOMCostShareQtyErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesCapCostHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        BOMBuffer: Record "BOM Buffer";
        WorkCenterNo: Text;
        ExpectedCapCost: Decimal;
    begin
        WorkCenterNo := LibraryVariableStorage.DequeueText();
        ExpectedCapCost := LibraryVariableStorage.DequeueDecimal();

        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::"Work Center"));
        BOMCostShares.FILTER.SetFilter("No.", WorkCenterNo);
        BOMCostShares.First();
        Assert.AreEqual(ExpectedCapCost, BOMCostShares."Rolled-up Capacity Cost".AsDecimal(), BOMCostShareCapCostErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMessage), Message);
    end;

    [MessageHandler]
    procedure MessageHandlerWithoutExpectedMessage(Message: Text[1024])
    begin

    end;
}

