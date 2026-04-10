codeunit 136127 "Test Planning/Req.Wksh"
{
    // Test: Planning Worksheet and Requisition Worksheet (Same/same)
    // 
    // ALL THE FOLLOWING TESTS BELOW ARE EACH CARRIED OUT 3 TIMES:
    // 
    // 1) Planning worksheet, option NetChange     (CalculationOption = CalculationOption::PlanningNetChange)
    // 2) Planning worksheet, option Regenerative  (CalculationOption = CalculationOption::PlanningRegenerate)
    // 3) Requisition Worksheet                    (CalculationOption = CalculationOption::Requisition)
    // 
    // The execution order is:
    // 1. CalculationOption = CalculationOption::PlanningNetChange
    // Test 1 > Test 2 > Test 3 > Test 4 > Test 5
    // 2. CalculationOption = CalculationOption::PlanningRegenerate
    // Test 1 > Test 2 > Test 3 > Test 4 > Test 5
    // 3. CalculationOption = CalculationOption::Requisition
    // Test 1 > Test 2 > Test 3 > Test 4 > Test 5
    // 
    // TEST 1 + 6 + 11: (Net change / Regenerative / Requisition worksheet)
    // Plan for Service Demand.
    // - Change setup for Item I to use Reordering Policy "Lot-for-Lot".
    // - Create Service Order for Demand with Quantity X for Item  I with inventory 0.
    // - Run Planning Worksheet
    // - Set Filter to plan for Item I, Start Date and End Date before and after Service
    // - Verify that plan contains purchase order for same amount as order (X).
    // 
    // TEST 2 + 7 + 12:
    // Plan after needed by date on Service Order.
    // - Change setup for Item I to use Reordering Policy "Lot-for-Lot".
    // - Create Service Order for Demand with Quantity X for Item  I with inventory 0. Change Posting date >
    //   than Needed by Date.
    // - Run Planning Worksheet
    // - Set Filter to plan for Item I, Set End Date before Posting Date and After Needed by Date
    // - Verify that plan contains purchase order for same amount as order (X) and the Due Date = Needed By.
    // 
    // TEST 3 + 8 + 13:
    // Multiple Demands on the same day should end up in one purchase order.
    // - Change setup for Item I to use Reordering Policy "Lot-for-Lot".
    // - Create Service Order Demand with Quantity X1, Date=D for Item  I with inventory 0.
    // - Create Sales Order Demand with Quantity X2, Date=D for Item  I
    // - Run Planning Worksheet
    // - Set Filter to plan for Item I, Set End Date before Posting Date and After Needed by Date
    // - Verify that plan contains One purchase order for (X1+X2).
    // 
    // TEST 4 + 9 + 14:
    // Plan for Job Demand.
    // - Change setup for Item I to use Reordering Policy "Lot-for-Lot".
    // - Create a Job, Task Line and Job Planning Line for Demand with Quantity X for Item  I with inventory 0.
    // - Run Planning Worksheet
    // - Set Filter to plan for Item I, Start Date and End Date before and after Planning date on Planning Line
    // - Verify that plan contains purchase order for same amount as planning Line(X).
    // 
    // TEST 5 + 10 + 15:
    // Plan after needed by date on Job.
    // - Change setup for Item I to use Reordering Policy "Lot-for-Lot".
    // - Create a Job, Task Line and Job Planning Line for Demand with Quantity X for Item , Planning Date = D I with inventory 0.
    // - Run Planning Worksheet
    // - Set Filter to plan for Item I, End Date before Planning date on Planning Line
    // - Verify that plan is empty.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Requisition]
    end;

    var
        ItemDescription: Label 'TESTITEMXXX';
        TESTTEXT: Label 'NTF_TEST_NTF_TEST';
        Text001: Label 'No service item has a non-blocked customer and non-blocked item. Execution stops.';
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CalculationOption: Option PlanningRegenerate,PlanningNetChange,Requisition;
        Text003: Label 'Service Order %1 does not exist.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PlanForServiceDemandNetChange()
    var
        ExpectedNumberOfRows: Integer;
        DemandQuantity: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 1
        // Setup
        DemandQuantity := 25;
        ExpectedNumberOfRows := 1;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<5D>', WorkDate());
        CalculationOption := CalculationOption::PlanningNetChange;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateServiceDemand(DemandQuantity);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanAfterNeededByDateNetChange()
    var
        DemandQuantity: Decimal;
        ExpectedNumberOfRows: Integer;
        ServiceOrderNo: Code[20];
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        NewPostingDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 2
        // Setup
        ExpectedNumberOfRows := 1;
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<3D>', WorkDate());
        NewPostingDate := CalcDate('<5D>', WorkDate());
        CalculationOption := CalculationOption::PlanningNetChange;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        ServiceOrderNo := CreateServiceDemand(DemandQuantity);
        ChangePostingDate(ServiceOrderNo, NewPostingDate);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        ValidateRequisitionLineDueDate(ItemNo, GetServiceHeaderOrderDate(ServiceOrderNo));
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleDemandsSameDayNetChang()
    var
        DemandQuantity: Decimal;
        DemandQuantity2: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
        ExpectedNoOfLines: Integer;
    begin
        // TEST 3
        // Setup
        ExpectedNoOfLines := 1;
        DemandQuantity := 25;
        DemandQuantity2 := 30;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<3D>', WorkDate());
        CalculationOption := CalculationOption::PlanningNetChange;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateServiceDemand(DemandQuantity);
        CreateServiceDemand(DemandQuantity2);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNoOfLines, DemandQuantity + DemandQuantity2, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanForJobDemandNetChange()
    var
        DemandQuantity: Decimal;
        ExpectedNumberOfRows: Integer;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 4
        // Setup
        ExpectedNumberOfRows := 1;
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<30D>', WorkDate());
        CalculationOption := CalculationOption::PlanningNetChange;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateJobDemand(DemandQuantity);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanAfterNeededByDateOnJobNetC()
    var
        DemandQuantity: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 5
        // Setup
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-15D>', WorkDate());
        CalculationEndDate := CalcDate('<-10D>', WorkDate());
        CalculationOption := CalculationOption::PlanningNetChange;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateJobDemand(DemandQuantity);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, 0, 0, 'Demand, end date before needed by date');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanForServiceDemandRegenerat()
    var
        ExpectedNumberOfRows: Integer;
        DemandQuantity: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 6
        // Setup
        DemandQuantity := 25;
        ExpectedNumberOfRows := 1;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<5D>', WorkDate());
        CalculationOption := CalculationOption::PlanningRegenerate;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateServiceDemand(DemandQuantity);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanAfterNeededByDateRegenerat()
    var
        DemandQuantity: Decimal;
        ExpectedNumberOfRows: Integer;
        ServiceOrderNo: Code[20];
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        NewPostingDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 7
        // Setup
        ExpectedNumberOfRows := 1;
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<3D>', WorkDate());
        NewPostingDate := CalcDate('<5D>', WorkDate());
        CalculationOption := CalculationOption::PlanningRegenerate;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        ServiceOrderNo := CreateServiceDemand(DemandQuantity);
        ChangePostingDate(ServiceOrderNo, NewPostingDate);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        ValidateRequisitionLineDueDate(ItemNo, GetServiceHeaderOrderDate(ServiceOrderNo));
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleDemandsOnTheSameDayReg()
    var
        ExpectedNoOfLines: Integer;
        DemandQuantity: Decimal;
        DemandQuantity2: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 8
        // Setup
        ExpectedNoOfLines := 1;
        DemandQuantity := 25;
        DemandQuantity2 := 30;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<3D>', WorkDate());
        CalculationOption := CalculationOption::PlanningRegenerate;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateServiceDemand(DemandQuantity);
        CreateServiceDemand(DemandQuantity2);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNoOfLines, DemandQuantity + DemandQuantity2, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanForJobDemandRegenerative()
    var
        DemandQuantity: Decimal;
        ExpectedNumberOfRows: Integer;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 9
        ExpectedNumberOfRows := 1;
        // Setup
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<30D>', WorkDate());
        CalculationOption := CalculationOption::PlanningRegenerate;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateJobDemand(DemandQuantity);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanAfterNeededByDateOnJobRege()
    var
        DemandQuantity: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 10
        // Setup
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-15D>', WorkDate());
        CalculationEndDate := CalcDate('<-10D>', WorkDate());
        CalculationOption := CalculationOption::PlanningRegenerate;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateJobDemand(DemandQuantity);
        // Execute
        CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
        // Validate
        ValidateRequisitionLines(ItemNo, 0, 0, 'Demand, end date before needed by date');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshPlanForServiceDemand()
    var
        ExpectedNumberOfRows: Integer;
        DemandQuantity: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 11
        // Setup
        DemandQuantity := 25;
        ExpectedNumberOfRows := 1;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<5D>', WorkDate());
        CalculationOption := CalculationOption::Requisition;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateServiceDemand(DemandQuantity);
        // Execute
        CalculatePlanRequisitionWorksh(ItemNo, CalculationStartDate, CalculationEndDate);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshPlanAfterNeededByDate()
    var
        DemandQuantity: Decimal;
        ExpectedNumberOfRows: Integer;
        ServiceOrderNo: Code[20];
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        NewPostingDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 12
        // Setup
        ExpectedNumberOfRows := 1;
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<3D>', WorkDate());
        NewPostingDate := CalcDate('<5D>', WorkDate());
        CalculationOption := CalculationOption::Requisition;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        ServiceOrderNo := CreateServiceDemand(DemandQuantity);
        ChangePostingDate(ServiceOrderNo, NewPostingDate);
        // Execute
        CalculatePlanRequisitionWorksh(ItemNo, CalculationStartDate, CalculationEndDate);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        ValidateRequisitionLineDueDate(ItemNo, GetServiceHeaderOrderDate(ServiceOrderNo));
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshMultipleDemandsSameDay()
    var
        ExpectedNoOfLines: Integer;
        DemandQuantity: Decimal;
        DemandQuantity2: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 13
        // Setup
        ExpectedNoOfLines := 1;
        DemandQuantity := 25;
        DemandQuantity2 := 30;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<3D>', WorkDate());
        CalculationOption := CalculationOption::Requisition;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateServiceDemand(DemandQuantity);
        CreateServiceDemand(DemandQuantity2);
        // Execute
        CalculatePlanRequisitionWorksh(ItemNo, CalculationStartDate, CalculationEndDate);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNoOfLines, DemandQuantity + DemandQuantity2, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshPlanForJobDemand()
    var
        DemandQuantity: Decimal;
        ExpectedNumberOfRows: Integer;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 14
        ExpectedNumberOfRows := 1;
        // Setup
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-5D>', WorkDate());
        CalculationEndDate := CalcDate('<30D>', WorkDate());
        CalculationOption := CalculationOption::Requisition;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateJobDemand(DemandQuantity);
        // Execute
        CalculatePlanRequisitionWorksh(ItemNo, CalculationStartDate, CalculationEndDate);
        // Validate
        ValidateRequisitionLines(ItemNo, ExpectedNumberOfRows, DemandQuantity, 'Demand');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWPlanAfterNeededByDateOnJob()
    var
        DemandQuantity: Decimal;
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        ItemNo: Code[20];
    begin
        // TEST 15
        // Setup
        DemandQuantity := 25;
        CalculationStartDate := CalcDate('<-15D>', WorkDate());
        CalculationEndDate := CalcDate('<-10D>', WorkDate());
        CalculationOption := CalculationOption::Requisition;
        ItemNo := InitScenario(CalculationStartDate, CalculationEndDate, CalculationOption);
        CreateJobDemand(DemandQuantity);
        // Execute
        CalculatePlanRequisitionWorksh(ItemNo, CalculationStartDate, CalculationEndDate);
        // Validate
        ValidateRequisitionLines(ItemNo, 0, 0, 'Demand, end date before needed by date');
        // Tear down
        TearDown(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PriceCalcMethodForCalculatePlanRequisitionWorksh()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CalculationStartDate: Date;
        CalculationEndDate: Date;
        PurchDirUnitCost: Decimal;
    begin
        // [SCENARIO 420155] Direct unit cost for 'All Vendors' is picked up for the requisition line generated by "Calculate Plan - Req. Wksh."
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Item 'I', where "Lats Direct Unit Cost" is 301
        PurchDirUnitCost := 300;
        Item.Get(CreateTestItem());
        Item."Last Direct Cost" := PurchDirUnitCost + 1;
        Item.Modify();
        // [GIVEN] Purchase price list for 'All Vendors' for Item 'I', where "Direct Unit Cost" is 300
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine."Direct Unit Cost" := PurchDirUnitCost;
        PriceListLine.Modify();
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify();
        // [GIVEN] posted Sales Order for Item 'I'
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order,
            LibrarySales.CreateCustomerNo(), Item."No.", 15, '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Calculate Plan Requisition Worksheet
        CalculationStartDate := CalcDate('<-CY>', WorkDate());
        CalculationEndDate := CalcDate('<CY>', WorkDate());
        CalculatePlanRequisitionWorksh(Item."No.", CalculationStartDate, CalculationEndDate);

        // [THEN] Direct Unit Cost is 300 (from the price list) 
        SetRequisitionLineFilter(RequisitionLine, Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Direct Unit Cost", PurchDirUnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CalculatePlanRequisitionWorkshHandler')]
    procedure DefaultPriceCalcMethodCalculatePlanRequisitionWorksh()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO 420155] Price calclation method for purchase is set on "Calculate Plan - Req. Wksh." as default.
        Initialize();
        // [GICEN] V16 pricing is disabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation(false);
        // [GIVEN] "Price Calculation Method" is 'Test Price' in Purchase Setup
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Price Calculation Method" := "Price Calculation Method"::"Test Price";
        PurchasesPayablesSetup.Modify();

        // [WHEN] Calculate Plan Requisition Worksheet (use request page)
        CalculatePlanRequisitionWorksh('', CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()), true);

        // [THEN] "Price Calculation Method" on the request page is 'Test Price'
        Assert.AreEqual(
            "Price Calculation Method"::"Test Price".AsInteger(),
            LibraryVariableStorage.DequeueInteger(), 'Price Calc method'); // from CalculatePlanRequisitionWorkshHandler
        // [THEN] "Price Calculation Method" is not visible
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Price Calc method visible');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure InitScenario(CalculationStartDate: Date; CalculationEndDate: Date; CalculationOption: Option PlanningRegenerate,PlanningNetChange,Requisition): Code[20]
    var
        ItemNo: Code[20];
    begin
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        ItemNo := CreateTestItem();
        CleanUpSupplyAndDemand();
        case CalculationOption of
            CalculationOption::PlanningRegenerate,
          CalculationOption::PlanningNetChange:
                CalculatePlanPlanningWorksheet(ItemNo, CalculationStartDate, CalculationEndDate, CalculationOption);
            CalculationOption::Requisition:
                CalculatePlanRequisitionWorksh(ItemNo, CalculationStartDate, CalculationEndDate);
        end;
        ValidateRequisitionLines(ItemNo, 0, 0, 'No demand');
        exit(ItemNo);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Planning/Req.Wksh");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Planning/Req.Wksh");

        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Planning/Req.Wksh");
    end;

    local procedure GetServiceHeaderOrderDate(ServiceOrderNo: Code[20]): Date
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceOrderNo);
        exit(ServiceHeader."Order Date");
    end;

    local procedure GetRequisitionWkshTemplate(): Code[10]
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        Clear(RequisitionWkshName);
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst();
        exit(RequisitionWkshName."Worksheet Template Name");
    end;

    local procedure GetRequisitionWkshBatch(): Code[10]
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        Clear(RequisitionWkshName);
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst();
        exit(RequisitionWkshName.Name);
    end;

    local procedure CreateTestItem(): Code[20]
    var
        ItemRec: Record Item;
        ItemNo: Code[20];
        UnitOfMeasureCode: Code[10];
    begin
        ItemNo := GetItem();
        UnitOfMeasureCode := CreateUnitOfMeasure(ItemNo);
        ItemRec.Get(ItemNo);
        ItemRec.Validate("Base Unit of Measure", UnitOfMeasureCode);
        ItemRec.Validate("Reordering Policy", ItemRec."Reordering Policy"::"Lot-for-Lot");
        ItemRec.Modify(true);
        exit(ItemNo);
    end;

    local procedure CreateUnitOfMeasure(ItemNo: Code[20]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        UnitOfMeasure.FindFirst();
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.Validate("Item No.", ItemNo);
        ItemUnitOfMeasure.Validate(Code, UnitOfMeasure.Code);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", 1);
        if not ItemUnitOfMeasure.Modify() then
            ItemUnitOfMeasure.Insert();
        exit(UnitOfMeasure.Code);
    end;

    local procedure SetRequisitionLineFilter(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        Clear(RequisitionLine);
        RequisitionLine.SetRange("Worksheet Template Name", GetRequisitionWkshTemplate());
        RequisitionLine.SetRange("Journal Batch Name", GetRequisitionWkshBatch());
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
    end;

    local procedure ChangePostingDate(ServiceOrderNo: Code[20]; NewPostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        if not ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceOrderNo) then
            Error(Text003, ServiceOrderNo);
        ServiceHeader.Validate("Posting Date", NewPostingDate);
        ServiceHeader.Modify(true);
    end;

    local procedure CalculatePlanPlanningWorksheet(ItemNo: Code[20]; StartDate: Date; EndDate: Date; CalcOption: Option PlanningRegenerate,PlanningNetChange,Requisition)
    var
        ItemRec: Record Item;
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
    begin
        Clear(CalculatePlanPlanWksh);
        CalculatePlanPlanWksh.SetTemplAndWorksheet(GetRequisitionWkshTemplate(), GetRequisitionWkshBatch(),
          CalcOption = CalcOption::PlanningRegenerate);
        ItemRec.SetRange("No.", ItemNo);
        CalculatePlanPlanWksh.SetTableView(ItemRec);
        CalculatePlanPlanWksh.InitializeRequest(StartDate, EndDate, false);
        CalculatePlanPlanWksh.UseRequestPage := false;
        CalculatePlanPlanWksh.RunModal();
    end;

    local procedure CalculatePlanRequisitionWorksh(ItemNo: Code[20]; StartDate: Date; EndDate: Date)
    begin
        CalculatePlanRequisitionWorksh(ItemNo, StartDate, EndDate, false);
    end;

    local procedure CalculatePlanRequisitionWorksh(ItemNo: Code[20]; StartDate: Date; EndDate: Date; UseRequestPage: Boolean)
    var
        ItemRec: Record Item;
        CalculatePlanReqWksh: Report "Calculate Plan - Req. Wksh.";
    begin
        Clear(CalculatePlanReqWksh);
        CalculatePlanReqWksh.SetTemplAndWorksheet(GetRequisitionWkshTemplate(), GetRequisitionWkshBatch());
        ItemRec.SetRange("No.", ItemNo);
        CalculatePlanReqWksh.SetTableView(ItemRec);
        CalculatePlanReqWksh.InitializeRequest(StartDate, EndDate);
        CalculatePlanReqWksh.UseRequestPage := UseRequestPage;
        if UseRequestPage then
            Commit();
        CalculatePlanReqWksh.RunModal();
    end;

    local procedure ValidateRequisitionLineDueDate(ItemNo: Code[20]; CheckDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SetRequisitionLineFilter(RequisitionLine, ItemNo);
        if RequisitionLine.FindFirst() then
            repeat
                Assert.AreEqual(CheckDate, RequisitionLine."Due Date", 'Requisition Line Due Date');
            until RequisitionLine.Next() = 0;
    end;

    local procedure ValidateRequisitionLines(ItemNo: Code[20]; NoOflinesExpected: Integer; QuantityExpected: Decimal; Descr: Text[100])
    var
        RequisitionLine: Record "Requisition Line";
        "Sum": Decimal;
    begin
        SetRequisitionLineFilter(RequisitionLine, ItemNo);
        Assert.AreEqual(NoOflinesExpected, RequisitionLine.Count, StrSubstNo('Requisition Worksheet Lines %1', Descr));
        Sum := 0;
        if RequisitionLine.FindFirst() then
            repeat
                Sum += RequisitionLine.Quantity;
            until RequisitionLine.Next() = 0;
        Assert.AreEqual(QuantityExpected, Sum, 'Requisition Worksheet Lines Quantity sum');
    end;

    local procedure FindItem(var Item: Record Item): Code[20]
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        if Item.Get(ItemDescription) then
            exit(ItemDescription);

        InventoryPostingGroup.FindFirst();

        Item.Init();
        Item.Validate("No.", ItemDescription);
        Item.Insert(true);
        Item.Validate("Unit Price", 10);
        Item.Validate(Description, ItemDescription);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Validate("Gen. Prod. Posting Group", FindGenProductPostingGroupCode());
        Item.Modify(true);
        exit(ItemDescription);
    end;

    local procedure FindGenProductPostingGroupCode(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GeneralPostingSetup.SetFilter("COGS Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Sales Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GenProductPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");
                if GenProductPostingGroup."Def. VAT Prod. Posting Group" <> '' then
                    exit(GenProductPostingGroup.Code);
            until GeneralPostingSetup.Next() = 0;
    end;

    local procedure GetItem(): Code[20]
    var
        ItemRec: Record Item;
    begin
        exit(FindItem(ItemRec));
    end;

    local procedure CleanUpSupplyAndDemand()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        Job: Record Job;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if SalesHeader.Find('-') then
            repeat
                if SalesHeader."Bill-to Name" = TESTTEXT then
                    SalesHeader.Delete(true);
            until SalesHeader.Next() = 0;

        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        if PurchHeader.Find('-') then
            repeat
                if PurchHeader."Pay-to Name" = TESTTEXT then
                    PurchHeader.Delete(true);
            until PurchHeader.Next() = 0;

        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        if ServiceHeader.Find('-') then
            repeat
                if ServiceHeader."Bill-to Name" = TESTTEXT then
                    ServiceHeader.Delete(true);
            until ServiceHeader.Next() = 0;

        if Job.Find('-') then
            repeat
                if Job."Description 2" = TESTTEXT then
                    Job.Delete(true);
            until Job.Next() = 0;
    end;

    local procedure CreateServiceDemand(ItemQty: Integer): Code[20]
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        NeededBy: Date;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        NeededBy := WorkDate();
        LocationCode := '';
        VariantCode := '';
        FindItem(Item);
        FindServiceItem(ServiceItem);

        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.Insert(true);
        ServiceHeader.Validate("Customer No.", ServiceItem."Customer No.");
        ServiceHeader.Validate("Bill-to Name", TESTTEXT);
        ServiceHeader.Modify();

        ServiceItemLine.Init();
        ServiceItemLine.Validate("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.Validate("Document No.", ServiceHeader."No.");
        ServiceItemLine.Validate("Line No.", 10000);
        ServiceItemLine.Insert(true);
        ServiceItemLine.Validate("Service Item No.", ServiceItem."No.");

        ServiceItemLine.Modify();

        ServiceLine.Init();
        ServiceLine.Validate("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Validate("Line No.", 10000);
        ServiceLine.Validate("Service Item Line No.", 10000);
        ServiceLine.Insert(true);
        ServiceLine.SetHideReplacementDialog(true);
        ServiceLine.Validate(Type, ServiceLine.Type::Item);
        ServiceLine.Validate("No.", Item."No.");
        ServiceLine.Validate(Quantity, ItemQty);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Variant Code", VariantCode);
        ServiceLine.Validate("Needed by Date", NeededBy);
        ServiceLine.Modify();

        exit(ServiceHeader."No.");
    end;

    local procedure CreateJobDemand(ItemQty: Integer): Code[20]
    var
        Item: Record Item;
        Customer: Record Customer;
        JobRec: Record Job;
        JobTaskLineRec: Record "Job Task";
        JobPlanningLineRec: Record "Job Planning Line";
        JobTaskNo: Code[20];
        DocNo: Code[20];
        LocationCode: Code[10];
        VariantCode: Code[10];
        PlanDate: Date;
    begin
        LibrarySales.CreateCustomer(Customer);
        FindItem(Item);
        LocationCode := '';
        VariantCode := '';
        PlanDate := WorkDate();

        JobRec.Init();
        JobRec.Insert(true);
        JobRec.Validate("Apply Usage Link", true);
        JobRec.Validate("Bill-to Customer No.", Customer."No.");
        JobRec.Validate("Description 2", TESTTEXT);
        JobRec.Modify();
        JobTaskNo := '10';
        // Job Task Line:
        JobTaskLineRec.Init();
        JobTaskLineRec.Validate("Job No.", JobRec."No.");
        JobTaskLineRec.Validate("Job Task No.", JobTaskNo);
        JobTaskLineRec.Validate("Job Task Type", JobTaskLineRec."Job Task Type"::Posting);
        JobTaskLineRec.Insert(true);
        // Job Planning Line:
        JobPlanningLineRec.Init();
        JobPlanningLineRec."Job No." := JobRec."No.";
        JobPlanningLineRec."Job Task No." := JobTaskNo;
        JobPlanningLineRec."Line No." := 10;
        JobPlanningLineRec.Validate("Planning Date", PlanDate);
        JobPlanningLineRec.Validate("Usage Link", true);
        JobPlanningLineRec.Insert(true);
        DocNo := DelChr(Format(Today), '=', '-/') + '_' + DelChr(Format(Time), '=', ':');
        JobPlanningLineRec.Validate("Document No.", DocNo);
        JobPlanningLineRec.Validate(Type, JobPlanningLineRec.Type::Item);
        JobPlanningLineRec.Validate("No.", Item."No.");
        JobPlanningLineRec.Validate(Quantity, ItemQty);
        JobPlanningLineRec.Validate("Location Code", LocationCode);
        JobPlanningLineRec.Validate("Variant Code", VariantCode);
        JobPlanningLineRec.Modify();

        exit(JobRec."No.");
    end;

    local procedure FindServiceItem(var ServiceItem: Record "Service Item")
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        ServiceItem.FindFirst();
        repeat
            Customer.Get(ServiceItem."Customer No.");
            Item.Get(ServiceItem."Item No.");
            if (Customer.Blocked = Customer.Blocked::" ") and not Item.Blocked then
                exit;
        until ServiceItem.Next() = 0;
        Error(Text001);
    end;

    local procedure TearDown(ItemNo: Code[20])
    var
        ItemRec: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        CleanUpSupplyAndDemand();
        SetRequisitionLineFilter(RequisitionLine, ItemNo);
        RequisitionLine.DeleteAll(true);
        if ItemRec.Get(ItemNo) then
            ItemRec.Delete(true);
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    procedure CalculatePlanRequisitionWorkshHandler(var CalculatePlanReqWksh: TestRequestPage "Calculate Plan - Req. Wksh.")
    begin
        LibraryVariableStorage.Enqueue(CalculatePlanReqWksh.PriceCalcMethod.AsInteger());
        LibraryVariableStorage.Enqueue(CalculatePlanReqWksh.PriceCalcMethod.Visible());
        CalculatePlanReqWksh.Cancel().Invoke();
    end;
}

