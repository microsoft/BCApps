codeunit 136308 "Job Order Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order Tracking] [Job]
        IsInitialized := false;
    end;

    var
        PurchaseLine2: Record "Purchase Line";
        JobPlanningLine2: Record "Job Planning Line";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;
        WrongDocumentError: Label '''Document No is incorrect in Order Tracking: %1 does not contain %2\''.';
        RollBack: Label 'ROLLBACK.';
        ExpectedDate: Date;
        QuantityErr: Label 'Quantity must be %1 in %2.', Comment = '%1= Value, %2=Table Name.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Order Tracking");
        Clear(PurchaseLine2);
        Clear(JobPlanningLine2);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Order Tracking");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Order Tracking");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PlanningLineTrackingPage')]
    [Scope('OnPrem')]
    procedure PlanningLineTracking()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Test Order Tracking Entries from Job Planning Line with Item having Order Tracking Policy Tracking Only.

        // 1. Setup: Create Item with Order Tracking Policy Tracking Only, Purchase Header with Document Type Order, Purchase Line, Job,
        // Job Task and Job Planning Line.
        Initialize();
        PurchaseOrderWithTracking(PurchaseLine, Item."Order Tracking Policy"::"Tracking Only");
        CreateJobPlanningLine(JobPlanningLine);
        ModifyJobPlanningLine(
          JobPlanningLine, PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date", PurchaseLine."Location Code");

        // Assign global variable for verification in page handler.
        PurchaseLine2 := PurchaseLine;
        JobPlanningLine2 := JobPlanningLine;

        // 2. Exercise: Run Order Tracking page from Job Planning Line.
        JobPlanningLine.ShowTracking();

        // 3. Verify: Verify Order Tracking Entry on Order Tracking page handler.

        // 4. Teardown.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PurchaseLineTrackingPage')]
    [Scope('OnPrem')]
    procedure PurchaseLineTracking()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        PurchaseOrderSubform: Page "Purchase Order Subform";
    begin
        // Test Order Tracking Entries from Purchase Line with Item having Order Tracking Policy Tracking Only.

        // 1. Setup: Create Item with Order Tracking Policy Tracking Only, Purchase Header with Document Type Order, Purchase Line, Job,
        // Job Task and Job Planning Line.
        Initialize();
        PurchaseOrderWithTracking(PurchaseLine, Item."Order Tracking Policy"::"Tracking Only");
        CreateJobPlanningLine(JobPlanningLine);
        ModifyJobPlanningLine(
          JobPlanningLine, PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date", PurchaseLine."Location Code");

        // Assign global variable for verification in page handler.
        PurchaseLine2 := PurchaseLine;
        JobPlanningLine2 := JobPlanningLine;

        // 2. Exercise: Run Order Tracking page from Purchase Line.
        PurchaseOrderSubform.SetRecord(PurchaseLine);
        PurchaseOrderSubform.ShowTracking();

        // 3. Verify: Verify Order Tracking Entry on Order Tracking page handler.

        // 4. Teardown.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NoTrackingPage')]
    [Scope('OnPrem')]
    procedure PlanningLineTrackingWithNone()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Test Order Tracking Entries from Job Planning Line with Item having Order Tracking Policy None.

        // 1. Setup: Create Item with Order Tracking Policy None, Purchase Header with Document Type Order, Purchase Line, Job,
        // Job Task and Job Planning Line.
        Initialize();
        PurchaseOrderWithTracking(PurchaseLine, Item."Order Tracking Policy"::None);
        CreateJobPlanningLine(JobPlanningLine);
        ModifyJobPlanningLine(
          JobPlanningLine, PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date", PurchaseLine."Location Code");

        // Assign global variable for verification in page handler.
        JobPlanningLine2 := JobPlanningLine;

        // 2. Exercise: Run Order Tracking page from Job Planning Line.
        JobPlanningLine.ShowTracking();

        // 3. Verify: Verify there are no Order Tracking Entry on Order Tracking page handler.

        // 4. Teardown.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NoTrackingPage')]
    [Scope('OnPrem')]
    procedure PlanningLineTrackingLocation()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // Test Order Tracking Entries from Job Planning Line with Item having Order Tracking Policy Tracking Only with different Locations.

        // 1. Setup: Create Item with Order Tracking Policy Tracking Only, Purchase Header with Document Type Order, Purchase Line,
        // Location, Job, Job Task and Job Planning Line.
        Initialize();
        PurchaseOrderWithTracking(PurchaseLine, Item."Order Tracking Policy"::"Tracking Only");
        LibraryWarehouse.CreateLocation(Location);
        CreateJobPlanningLine(JobPlanningLine);
        ModifyJobPlanningLine(
          JobPlanningLine, PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date", Location.Code);

        // Assign global variable for verification in page handler.
        PurchaseLine2 := PurchaseLine;
        JobPlanningLine2 := JobPlanningLine;

        // 2. Exercise: Run Order Tracking page from Job Planning Line.
        JobPlanningLine.ShowTracking();

        // 3. Verify: Verify there are no Order Tracking Entry on Order Tracking page handler.

        // 4. Teardown.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('AvailableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Check that Dates have no effect on the Order Promising page.

        // 1. Setup: Create Job Planning Line.
        Initialize();
        OrderPromisingOnJobPlanningLine(JobPlanningLine);

        // 2. Exercise.
        JobPlanningLine.ShowOrderPromisingLine();

        // 3. Verify: Verify that date on the Order Promising page. Verification done in 'AvailableToPromisePageHandler'.
    end;

    [Test]
    [HandlerFunctions('CapableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure CapableToPromiseOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Check that Dates on Order Promising page.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        OrderPromisingOnJobPlanningLine(JobPlanningLine);

        // 2. Exercise.
        JobPlanningLine.ShowOrderPromisingLine();

        // 3. Verify: Verify that date on the Order Promising page. Verification done in 'CapableToPromisePageHandler'.
    end;

    [Test]
    [HandlerFunctions('AcceptPageHandler')]
    [Scope('OnPrem')]
    procedure AcceptOnJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Check that Dates are same on the Order Promising page as in JobPlanningLine's Planning Date.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        OrderPromisingOnJobPlanningLine(JobPlanningLine);

        // 2. Exercise.
        JobPlanningLine.ShowOrderPromisingLine();

        // 3. Verify: Verify that date on the Order Promising page. Verification done in 'AcceptPageHandler'.
    end;

    [Test]
    [HandlerFunctions('AvailableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnPlanningLineWithPurchaseOrder()
    begin
        // Check that Dates have no effect on the Order Promising page for Available To Promise with lesser Quantity on Job Planning Line than Purchase Order.

        Initialize();
        CreatePlanningLineWithExpectedDate(LibraryRandom.RandInt(10));  // Used Random value for Quantity.

        // 3. Verify: Verify that dates are same as in JobPlanningLine. Verification done in 'AvailableToPromisePageHandler'.
    end;

    [Test]
    [HandlerFunctions('AcceptPageHandler')]
    [Scope('OnPrem')]
    procedure AcceptOnPlanningLineWithPurchaseOrder()
    begin
        // Check that Dates have no effect on the Order Promising page for Accept with lesser Quantity on Job Planning Line than Purchase Order.

        Initialize();
        CreatePlanningLineWithExpectedDate(LibraryRandom.RandInt(10));  // Used Random value for Quantity.

        // 3. Verify: Verify that date are same as in JobPlanningLine. Verification done in 'AcceptPageHandler'.
    end;

    [Test]
    [HandlerFunctions('AvailableToPromisePageHandler')]
    [Scope('OnPrem')]
    procedure AvailableToPromiseOnPlanningLineWithSupply()
    begin
        // Check that Dates on the Order Promising page for Available To Promise with greater Quantity on Job Planning Line than Purchase Order.

        Initialize();
        CreatePlanningLineWithExpectedDate(LibraryRandom.RandInt(10) + 1000);  // Added here 1000 because Planning Line need greater Quantity than Purchase Line. Used Random value for Quantity.

        // 3. Verify: Verify that dates are same as in JobPlanningLine. Verification done in 'AvailableToPromisePageHandler'.
    end;

    [Test]
    [HandlerFunctions('AcceptPageHandler')]
    [Scope('OnPrem')]
    procedure AcceptOnPlanningLineWithSupply()
    begin
        // Check that Dates on the Order Promising page for Accept with greater Quantity on Job Planning Line than Purchase Order.

        Initialize();
        CreatePlanningLineWithExpectedDate(LibraryRandom.RandInt(10) + 1000);  // Added here 1000 because Planning Line need greater Quantity than Purchase Line. Used Random value for Quantity.

        // 3. Verify: Verify that dates are same as in JobPlanningLine. Verification done in 'AcceptPageHandler'.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanningForJob()
    var
        Location: Record Location;
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        // Check Quantity on Order Planning Worksheet for Job after running Calculate Plan.

        // Setup: Create Job Planning Line with Item having Zero inventory.
        Initialize();
        CreateJobPlanningLine(JobPlanningLine);
        ModifyJobPlanningLine(
          JobPlanningLine, CreateItemWithVendorNo(), LibraryRandom.RandInt(10), WorkDate(),
          LibraryJob.FindLocation(Location));  // Taking random value for Quantity.

        // Exercise: Run Calculate Plan from Order Planning Worksheet.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // Verify: Verify that Requisition Line has same quantity as on Job Planning Line.
        VerifyRequisitionLine(JobPlanningLine."Job No.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderForJobDemand()
    var
        Location: Record Location;
        RequisitionLine: Record "Requisition Line";
        JobPlanningLine: Record "Job Planning Line";
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        // Check Creation of Purchase Order after doing Make Order for Job Demand from Order Planning.

        // Setup: Create Job Planning Line with Item having Zero inventory. Run Calculate Plan from Order Planning Worksheet.
        Initialize();
        CreateJobPlanningLine(JobPlanningLine);
        ModifyJobPlanningLine(
          JobPlanningLine, CreateItemWithVendorNo(), LibraryRandom.RandInt(10), WorkDate(), LibraryJob.FindLocation(Location));
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // Exercise: Make Order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(JobPlanningLine."Job No.");

        // Verify: Verify that Purchase Order has been created with same quantity as on Job Planning Line.
        VerifyPurchaseOrder(JobPlanningLine."Job No.");

        // Tear Down: Delete the earlier created Manufacturing User Template.
        DeleteManufacturingUserTemplate();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanningForJobWithDefaultDimension()
    var
        Location: Record Location;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        RequisitionLine: Record "Requisition Line";
        DefaultDimension: Record "Default Dimension";
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        // [SCENARIO 462769] Job Dimensions are not passed on to Supply documents when using Order Planning

        // [GIVEN] Setup: Create Job Planning Line with Item having Zero inventory.
        Initialize();

        // [GIVEN] Create Job, Add Default Dimension, Job Task, and Job Planning Line.
        LibraryJob.CreateJob(Job);
        CreateDefaultDimForJob(Job."No.", DefaultDimension);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        ModifyJobPlanningLine(
          JobPlanningLine, CreateItemWithVendorNo(), LibraryRandom.RandInt(10), WorkDate(),
          LibraryJob.FindLocation(Location));  // Taking random value for Quantity.

        // [WHEN] Exercise: Run Calculate Plan from Order Planning Worksheet.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [VERIFY] Verify: Verify that Requisition Line has same quantity as on Job Planning Line.
        VerifyDefaultDimensionOnRequisitionLine(Job."No.", DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanningForJobWithDefaultAndJobTaskDimension()
    var
        Location: Record Location;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        RequisitionLine: Record "Requisition Line";
        DefaultDimension: Record "Default Dimension";
        JobTaskDim: Record "Job Task Dimension";
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        // [SCENARIO 464809] Job Task Dimensions are not passed on to Supply documents when using Order Planning

        // [GIVEN] Setup: Create Job Planning Line with Item having Zero inventory.
        Initialize();

        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create Default Job Dimension
        CreateDefaultDimForJob(Job."No.", DefaultDimension);

        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Default Job Task Dimension
        CreateJobTaskDim(JobTaskDim, JobTask);

        // [GIVEN] Creaet Job Planning Line
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);

        // [GIVEN] Update Quantity, Item, Planning Date and Location on Job Planning Line
        ModifyJobPlanningLine(
          JobPlanningLine, CreateItemWithVendorNo(), LibraryRandom.RandInt(10), WorkDate(),
          LibraryJob.FindLocation(Location));  // Taking random value for Quantity.

        // [WHEN] Exercise: Run Calculate Plan from Order Planning Worksheet.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [VERIFY] Verify: Verify that Job Task Dimension including Default Dimension passed to Requisition Line
        VerifyDefaultDimensionOnRequisitionLine(Job."No.", DefaultDimension);
        VerifyJobTaskDimensionOnRequisitionLine(Job."No.", JobTaskDim);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure OrderPlanningCreatesProjectPlanningLineForRecivedItemOnPurchaseOrder()
    var
        Location: Record Location;
        JobPlanningLine: array[2] of Record "Job Planning Line";
        Item: Record Item;
        RequisitionLine: array[2] of Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 534037] Order Planning creates additional Project Planning Line if previous Job Planning Line for the Item was Received only on a Purchase Order.
        Initialize();

        // [GIVEN] Create an Item with Vendor.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Delete old Manufacturing User Template.
        DeleteManufacturingUserTemplateIfExists();

        // [GIVEN] Create Job Planning Line.
        CreateJobPlanningLine(JobPlanningLine[1]);

        // [GIVEN] Modify Job Planning Line with Item, Quantity, Date and Location.
        ModifyJobPlanningLine(
            JobPlanningLine[1],
            Item."No.",
            LibraryRandom.RandIntInRange(10, 15),
            WorkDate(),
            LibraryJob.FindLocation(Location));

        // [GIVEN] Create Inventory Posting Setup and Validate Inventory Account.
        CreateInventoryPostingSetup(Location, Item);

        // [GIVEN] Calculate Order Plan Job.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine[1]);

        // [GIVEN] Make Order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(JobPlanningLine[1]."Job No.");

        // [GIVEN] Find the Purchase Order.
        PurchaseLine.SetRange("No.", JobPlanningLine[1]."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();

        // [GIVEN] Validate Amount Including VAT and Qty. to Receive in Purchase Line.
        PurchaseLine.Validate(PurchaseLine."Amount Including VAT", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);

        // [GIVEN] Find the Purchase Header.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Recive the Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create Job Planning Line.
        CreateJobPlanningLine(JobPlanningLine[2]);

        // [GIVEN] Modify Job Planning Line with Item, Quantity, Date and Location.
        ModifyJobPlanningLine(
            JobPlanningLine[2],
            Item."No.",
            LibraryRandom.RandIntInRange(10, 15),
            WorkDate(),
            LibraryJob.FindLocation(Location));

        // [WHEN] Run Calculate Plan from Order Planning Worksheet.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine[2]);

        // [GIVEN] Find the Requisition Line of the Job.
        RequisitionLine[2].SetRange("Demand Order No.", JobPlanningLine[2]."Job No.");
        RequisitionLine[2].SetRange(Type, RequisitionLine[2].Type::Item);
        RequisitionLine[2].SetRange("No.", JobPlanningLine[2]."No.");
        RequisitionLine[2].SetRange("Location Code", JobPlanningLine[2]."Location Code");
        RequisitionLine[2].FindLast();

        // [THEN] Quantity on Requisition Line must be equal to Quantity on Job Planning Line.
        Assert.AreEqual(
            RequisitionLine[2].Quantity,
            JobPlanningLine[2].Quantity,
            StrSubstNo(
                QuantityErr,
                JobPlanningLine[2].Quantity,
                RequisitionLine[2].TableCaption()));
    end;

    local procedure CreateItemWithVendorNo(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithTrackingPolicy(OrderTrackingPolicy: Enum "Order Tracking Policy"): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // Create Job, Job Task, Job Planning Line.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, LibraryRandom.RandInt(100) + 100, LocationCode,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Used Random to calculate the Expected Receipt Date.
    end;

    local procedure CreatePlanningLineWithPurchaseOrder(var JobPlanningLine: Record "Job Planning Line"; LocationCode: Code[10]; Quantity: Integer)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrder(PurchaseLine, Item."No.", LocationCode);
        CreateJobPlanningLine(JobPlanningLine);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", PurchaseLine."No.");
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate("Planning Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Used Random to calculate the Planning Date.
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreatePlanningLineWithExpectedDate(Quantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
    begin
        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Location.FindFirst();
        CreatePlanningLineWithPurchaseOrder(JobPlanningLine, Location.Code, Quantity);
        ExpectedDate := JobPlanningLine."Planning Date";  // Assign in global variable.

        // 2. Exercise.
        JobPlanningLine.ShowOrderPromisingLine();
    end;

    local procedure DeleteManufacturingUserTemplate()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        ManufacturingUserTemplate.Get(UserId);
        ManufacturingUserTemplate.Delete(true);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; JobNo: Code[20]; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange("Demand Order No.", JobNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option)
    var
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        LibraryPlanning.CreateManufUserTemplate(
          ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned",
          ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure MakeSupplyOrdersActiveOrder(JobNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        RequisitionLine.SetRange("Demand Order No.", JobNo);
        RequisitionLine.FindFirst();
        GetManufacturingUserTemplate(ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order");
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure ModifyJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; Quantity: Decimal; PlanningDate: Date; LocationCode: Code[10])
    begin
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate("Planning Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', PlanningDate));  // Used Random to calculate the Planning Date.
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, Quantity * LibraryUtility.GenerateRandomFraction());
        JobPlanningLine.Modify(true);
    end;

    local procedure PurchaseOrderWithTracking(var PurchaseLine: Record "Purchase Line"; OrderTrackingPolicy: Enum "Order Tracking Policy")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithTrackingPolicy(OrderTrackingPolicy),
          LibraryRandom.RandDec(10, 2));  // Use random for Quantity.
    end;

    local procedure OrderPromisingOnJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        CreateJobPlanningLine(JobPlanningLine);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate("Planning Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Used Random to calculate the Planning Date.
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        JobPlanningLine.Modify(true);
        ExpectedDate := JobPlanningLine."Planning Date";  // Assign in global variable
    end;

    local procedure Teardown()
    begin
        asserterror Error(RollBack);
    end;

    local procedure VerifyDocumentNo(Name: Text[30]; DocumentNo: Text[30])
    begin
        Assert.IsTrue(StrPos(Name, DocumentNo) > 0, StrSubstNo(WrongDocumentError, Name, DocumentNo));
    end;

    local procedure VerifyPurchaseOrder(JobNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.FindFirst();
        Item.Get(JobPlanningLine."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", JobPlanningLine."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Buy-from Vendor No.", Item."Vendor No.");
        PurchaseLine.TestField("Location Code", JobPlanningLine."Location Code");
        PurchaseLine.TestField(Quantity, JobPlanningLine.Quantity);
        PurchaseLine.TestField("Expected Receipt Date", JobPlanningLine."Planning Date");
    end;

    local procedure VerifyRequisitionLine(JobNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.FindFirst();
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", JobPlanningLine."No.", JobPlanningLine."Location Code");
        RequisitionLine.TestField("Due Date", JobPlanningLine."Planning Date");
        RequisitionLine.TestField(Quantity, JobPlanningLine.Quantity);
        RequisitionLine.TestField("Demand Quantity", JobPlanningLine.Quantity);
        RequisitionLine.TestField("Needed Quantity", JobPlanningLine.Quantity);
    end;

    local procedure CreateDefaultDimForJob(JobNo: Code[20]; var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindFirst();
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, JobNo, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
    end;

    local procedure VerifyDefaultDimensionOnRequisitionLine(JobNo: Code[20]; DefaultDimension: Record "Default Dimension")
    var
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.FindFirst();
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", JobPlanningLine."No.", JobPlanningLine."Location Code");
        DimensionSetEntry.SetRange("Dimension Set ID", RequisitionLine."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(DefaultDimension."Dimension Code", DimensionSetEntry."Dimension Code", '');
        Assert.AreEqual(DefaultDimension."Dimension Value Code", DimensionSetEntry."Dimension Value Code", '');
    end;

    local procedure CreateJobTaskDim(var JobTaskDim: Record "Job Task Dimension"; JobTask: Record "Job Task")
    var
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        InsertJobTaskDim(JobTaskDim, JobTask, DimValue);
    end;

    local procedure InsertJobTaskDim(var JobTaskDim: Record "Job Task Dimension"; JobTask: Record "Job Task"; DimValue: Record "Dimension Value")
    begin
        JobTaskDim.Init();
        JobTaskDim.Validate("Job No.", JobTask."Job No.");
        JobTaskDim.Validate("Job Task No.", JobTask."Job Task No.");
        JobTaskDim.Validate("Dimension Code", DimValue."Dimension Code");
        JobTaskDim.Validate("Dimension Value Code", DimValue.Code);
        JobTaskDim.Insert(true);
    end;

    local procedure VerifyJobTaskDimensionOnRequisitionLine(JobNo: Code[20]; JobTaskDimension: Record "Job Task Dimension")
    var
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.FindFirst();
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", JobPlanningLine."No.", JobPlanningLine."Location Code");
        DimensionSetEntry.SetRange("Dimension Set ID", RequisitionLine."Dimension Set ID");
        DimensionSetEntry.FindLast();
        Assert.AreEqual(JobTaskDimension."Dimension Code", DimensionSetEntry."Dimension Code", '');
        Assert.AreEqual(JobTaskDimension."Dimension Value Code", DimensionSetEntry."Dimension Value Code", '');
    end;

    local procedure DeleteManufacturingUserTemplateIfExists()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        if ManufacturingUserTemplate.Get(UserId) then
            ManufacturingUserTemplate.Delete(true);
    end;

    local procedure CreateInventoryPostingSetup(Location: Record Location; Item: Record Item)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if not InventoryPostingSetup.Get(Location.Code, Item."Inventory Posting Group") then begin
            LibraryInventory.CreateInventoryPostingSetup(
                InventoryPostingSetup,
                Location.Code,
                Item."Inventory Posting Group");
            InventoryPostingSetup.Validate("Inventory Account", LibraryERM.CreateGLAccountNo());
            InventoryPostingSetup.Modify(true);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Text: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoTrackingPage(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(JobPlanningLine2.Quantity);
        OrderTracking."Total Quantity".AssertEquals(JobPlanningLine2.Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningLineTrackingPage(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(0);
        OrderTracking."Item No.".AssertEquals(JobPlanningLine2."No.");
        OrderTracking."Total Quantity".AssertEquals(JobPlanningLine2.Quantity);
        OrderTracking.Quantity.AssertEquals(-JobPlanningLine2.Quantity);
        VerifyDocumentNo(OrderTracking.Name.Value, PurchaseLine2."Document No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseLineTrackingPage(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(PurchaseLine2.Quantity - JobPlanningLine2.Quantity);
        OrderTracking."Item No.".AssertEquals(JobPlanningLine2."No.");
        OrderTracking."Total Quantity".AssertEquals(PurchaseLine2.Quantity);
        OrderTracking.Quantity.AssertEquals(JobPlanningLine2.Quantity);
        VerifyDocumentNo(OrderTracking.Name.Value, JobPlanningLine2."Job No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableToPromisePageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.AvailableToPromise.Invoke();
        OrderPromisingLines."Requested Shipment Date".AssertEquals(ExpectedDate);
        OrderPromisingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CapableToPromisePageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();
        OrderPromisingLines."Original Shipment Date".AssertEquals(ExpectedDate);
        OrderPromisingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AcceptPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines."Requested Shipment Date".AssertEquals(ExpectedDate);
        OrderPromisingLines.AcceptButton.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders";

    var
        Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;
}

