codeunit 134381 "ERM Dimension Priority"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE]  [Dimension] [Dimension Priority]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        SystemActionTriggers: Codeunit "System Action Triggers";
        LibraryAssembly: Codeunit "Library - Assembly";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        WrongDimValueCodeErr: Label 'Wrong dimension value code.';
        DefaultDimPrioritiesNotificationIdTxt: Label '69CE42D9-0580-4907-8BC9-0EEB59DA96C9', Locked = true;
        ItemAvaibilityIsLowNotificationIdTxt: Label '2712ad06-c48b-4c20-820e-347a60c9ad00', Locked = true;
        AvailWarningYesMsg: Label 'Avail. warning should be Yes';
        AvailWarningNoMsg: Label 'Avail. warning should be No';
        DueDateBeforeWDFromLineMsg: Label 'Due Date %1 is before work date %2.';
        DueDateBeforeWDFromHeaderMsg: Label 'Due Date %1 is before work date %2 in one or more of the assembly lines.';
        NewLineDueDate: Date;
        TestMethodName: Text[30];
        Step: Integer;
        TestVSTF257960A: Label 'VSTF257960A';
        DimensionCodeErr: Label 'Dimension Code must be %1 in %2.', Comment = '%1= Dimension Value Code,%2= Table Name';

    [Test]
    [Scope('OnPrem')]
    procedure PriorityAccount()
    begin
        DifferentPriority(1, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriorityCustomer()
    begin
        DifferentPriority(2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityChangeCustomer()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
    begin
        Initialize();
        GetGLBalancedBatch(GenJournalBatch);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // Create default dimension codes for Customer and G/L Account
        CreateDefaultDimensionCodes(CustomerNo, GenJournalBatch."Bal. Account No.");

        // Setup priorities
        SetupDimensionPriority(LibraryERM.FindGeneralJournalSourceCode(), 1, 1);

        // Find default dimension codes
        FindDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo);

        // Create a journal line
        ClearJournalBatch(GenJournalBatch);
        CreateGeneralJnlLine(GenJournalLine, GenJournalBatch, CustomerNo);

        // Update customer on journal line
        GenJournalLine.Validate("Account No.", CustomerNo);
        GenJournalLine.Modify(true);

        // Verify dimensions
        VerifyDimensionSetID(DefaultDimension, GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityChangeAccount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
    begin
        Initialize();
        GetGLBalancedBatch(GenJournalBatch);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // Create default dimension codes for Customer and G/L Account
        CreateDefaultDimensionCodes(CustomerNo, GenJournalBatch."Bal. Account No.");

        // Setup priorities
        SetupDimensionPriority(LibraryERM.FindGeneralJournalSourceCode(), 1, 1);

        // Find default dimension codes
        FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GenJournalBatch."Bal. Account No.");

        // Create a journal line
        ClearJournalBatch(GenJournalBatch);
        CreateGeneralJnlLine(GenJournalLine, GenJournalBatch, CustomerNo);

        // Update account on journal line
        GenJournalLine.Validate("Bal. Account No.", GenJournalLine."Bal. Account No.");
        GenJournalLine.Modify(true);

        // Verify dimensions
        VerifyDimensionSetID(DefaultDimension, GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupDefaultDimensionPriority()
    var
        SourceCode: Code[10];
    begin
        // Test setup default dimension priority.

        // Setup: Find Source Code.
        Initialize();
        SourceCode := LibraryERM.FindGeneralJournalSourceCode();

        // Exercise: Create default dimension priority 1 for Customer, 1 for Vendor and  2 for G/L Account with source code.
        SetDefaultDimensionPriority(SourceCode);

        // Verify: Verify default dimension priority for Customer, Vendor and G/L Account with Source Code must exist.
        VerifyDefaultDimensionPriority(SourceCode);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PriorityReqWkshAndCarryOutAction()
    var
        DimValueArray: array[3] of Code[20];
        DimensionCode: Code[20];
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        // Test that purchase order created by carry out action from requisition worskeet has correct dimensions according to dimension in requisition worksheet

        Initialize();
        SetupDimensionPriorityForPurchSrcCode();
        DimensionCode := CreateDimensionValues(DimValueArray);
        VendNo := CreateVendorWithPurchaserAndDefDim(DimensionCode, DimValueArray);
        ItemNo := CreateItemWithReplenishmentPociliyAndDefDim(DimensionCode, DimValueArray[3], VendNo);
        CreateReqLineAndCarryOutAction(ItemNo);
        VerifyDimValueInPurchLine(VendNo, DimensionCode, DimValueArray[1]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReqWkshCarryOutActionWithChangedDim()
    var
        RequisitionLine: Record "Requisition Line";
        DimValueArray: array[3] of Code[20];
        DimensionCode: Code[20];
        VendNo: Code[20];
        ItemNo: Code[20];
        PrevGlobalDimCode: Code[20];
        ExpectedDimValue: Code[20];
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] purchase order line created by carry out action from requisition worskeet with changed dimension has dimension value from requisition worksheet

        // Setup.
        Initialize();
        LibraryDimension.InitGlobalDimChange();
        SetupDimensionPriorityForPurchSrcCode();
        DimensionCode := CreateDimensionValues(DimValueArray);
        PrevGlobalDimCode := SetupGlobalDimension(1, DimensionCode);
        VendNo := CreateVendorWithPurchaserAndDefDim(DimensionCode, DimValueArray);
        ItemNo := CreateItemWithReplenishmentPociliyAndDefDim(DimensionCode, DimValueArray[3], VendNo);
        ExpectedDimValue := CreateReqLineWithCustomDimVal(RequisitionLine, ItemNo, DimensionCode);

        // Exercise.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // Verify.
        VerifyDimValueInPurchLine(VendNo, DimensionCode, ExpectedDimValue);
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");

        // Teardown.
        SetupGlobalDimension(1, PrevGlobalDimCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job's Dimension Values if it has higher priority and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job Task's Dimension Values if it has higher priority and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 2, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource's Dimension Values if Job has lower priority and line has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource's Dimension Values if Job has lower priority and line has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if no priority specified and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 0, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if if no priority specified and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 0, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoJobPriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if Resource only has priority and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoJobPriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if Resource only has priority and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoResourcePriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job's Dimension Values if Job has only priority and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoResourcePriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job Task's Dimension Values if Job has only priority and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 2, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job's Dimension Values if Job has the same priority as Resource and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job Task's Dimension Values if Job has the same priority as Resource and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderDimPrioritySalesPerson()
    var
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        SalesPersonCode: Code[20];
        ServiceContractCode: Code[20];
        CustomerCode: Code[20];
        ReturnDim: Code[20];
    begin
        // [FEATURE] [Service Order]
        // [SCENARIO 380432] Inherit Sales Person's dimension if Sales Person Dimension priority is higher then Service Contract one
        Initialize();

        // [GIVEN] Sales Person "SP" with default dimension "DD1" where Priority = 1
        SetServiceDimensionPriorities(1, 2);
        LibraryDimension.CreateDimension(Dimension);
        ReturnDim := CreateSalesPersonWithDimAndPriority(SalesPersonCode, Dimension.Code);

        // [GIVEN] Service Contract with dimension value "DD2" where Priority = 2
        CreateServiceContractWithDimAndPriority(ServiceContractCode, CustomerCode, Dimension.Code);

        // [GIVEN] Service Quote with Sales Person "SP"
        CreateServiceQuotaWithSalesPerson(ServiceHeader, CustomerCode, SalesPersonCode);

        // [WHEN] Assign Service Contract to Service Quote
        ServiceHeader.Validate("Contract No.", ServiceContractCode);

        // [THEN] Service Quote dimension value is "DD1"
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceHeader."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", ReturnDim);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderDimPriorityServiceContract()
    var
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        SalesPersonCode: Code[20];
        ServiceContractCode: Code[20];
        CustomerCode: Code[20];
        ReturnDim: Code[20];
    begin
        // [FEATURE] [Service Order]
        // [SCENARIO 380432] Inherit Service Contract dimension if Service Contract Dimension priority is higher then Sales Person's one
        Initialize();

        // [GIVEN] Sales Person "SP" with default dimension "DD1" where Priority = 2
        SetServiceDimensionPriorities(2, 1);
        LibraryDimension.CreateDimension(Dimension);
        CreateSalesPersonWithDimAndPriority(SalesPersonCode, Dimension.Code);

        // [GIVEN] Service Contract with dimension value "DD2" where Priority = 1
        ReturnDim := CreateServiceContractWithDimAndPriority(ServiceContractCode, CustomerCode, Dimension.Code);

        // [GIVEN] Service Quote with Sales Person "SP"
        CreateServiceQuotaWithSalesPerson(ServiceHeader, CustomerCode, SalesPersonCode);

        // [WHEN] Assign Service Contract to Service Quote
        ServiceHeader.Validate("Contract No.", ServiceContractCode);

        // [THEN] Service Quote dimension value is "DD2"
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceHeader."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", ReturnDim);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderSameDimPriorities()
    var
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        SalesPersonCode: Code[20];
        ServiceContractCode: Code[20];
        CustomerCode: Code[20];
        ReturnDim: Code[20];
    begin
        // [FEATURE] [Service Order]
        // [SCENARIO 380432] Inherit Service Contract dimension if Service Contract Dimension priority it the same as Sales Person's one
        Initialize();

        // [GIVEN] Sales Person "SP" with default dimension "DD1" where Priority = 1
        SetServiceDimensionPriorities(1, 1);
        LibraryDimension.CreateDimension(Dimension);
        CreateSalesPersonWithDimAndPriority(SalesPersonCode, Dimension.Code);

        // [GIVEN] Service Contract with dimension value "DD2" where Priority = 1
        ReturnDim := CreateServiceContractWithDimAndPriority(ServiceContractCode, CustomerCode, Dimension.Code);

        // [GIVEN] Service Quote with Sales Person "SP"
        CreateServiceQuotaWithSalesPerson(ServiceHeader, CustomerCode, SalesPersonCode);

        // [WHEN] Assign Service Contract to Service Quote
        ServiceHeader.Validate("Contract No.", ServiceContractCode);

        // [THEN] Service Quote dimension value is "DD2"
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceHeader."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", ReturnDim);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriorityPurchaseLineWithItemDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Dimension] [Job] [Purchase]
        // [SCENARIO 257952] Purchase line with job sets the Item Dimension Value if it has the highest Dimension Priority.
        Initialize();

        // [GIVEN] Default Dimension Priorities for Source Code = PURCHASE are set as 1 for Item and 2 for Job.
        SetPurchaseDimensionPriorities(1, 2);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [WHEN] Create Purchase Line with Item and Job Task.
        CreatePurchaseLineWithItemAndJobTask(PurchaseLine, Item, JobTask);

        // [THEN] Purchase Line Dimension Value = "IDV".
        VerifyPurchaseLineDimensionValue(PurchaseLine, ItemDimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriorityPurchaseLineWithJobDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Dimension] [Job] [Purchase]
        // [SCENARIO 257952] Purchase line with job sets the Job Dimension Value if it has the highest Dimension Priority.
        Initialize();

        // [GIVEN] Default Dimension Priorities for Source Code = PURCHASE are set as 1 for Job and 2 for Item.
        SetPurchaseDimensionPriorities(2, 1);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [WHEN] Create Purchase Line with Item and Job Task.
        CreatePurchaseLineWithItemAndJobTask(PurchaseLine, Item, JobTask);

        // [THEN] Purchase Line Dimension Value = "JDV".
        VerifyPurchaseLineDimensionValue(PurchaseLine, JobDimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningLineWithItemDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Dimension] [Job] [Sales]
        // [SCENARIO 257952] Sales line created from Job Planning Line sets the Item Dimension Value if it has the highest Dimension Priority.
        Initialize();

        // [GIVEN] Default Dimension Priorities for Source Code = SALES are set as 1 for Item and 2 for Job.
        SetSalesDimensionPriorities(1, 2);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [GIVEN] Job Planning Line for Item with Job Task.
        CreateJobPlanningLineWithItemAndJobTask(JobPlanningLine, JobTask, Item."No.");
        Commit();

        // [WHEN] Create Sales Invoice from Job Planning Line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Line Dimension Value = "IDV".
        FindSalesLineFromJobPlanningLine(SalesLine, JobPlanningLine);
        VerifySalesLineDimensionValue(SalesLine, ItemDimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningLineWithJobDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Dimension] [Job] [Sales]
        // [SCENARIO 257952] Sales line created from Job Planning Line sets the Job Dimension Value if it has the highest Dimension Priority.
        Initialize();

        // [GIVEN] Default Dimension Priorities for Source Code = SALES are set as 1 for Job and 2 for Item.
        SetSalesDimensionPriorities(2, 1);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [GIVEN] Job Planning Line for Item with Job Task.
        CreateJobPlanningLineWithItemAndJobTask(JobPlanningLine, JobTask, Item."No.");
        Commit();

        // [WHEN] Create Sales Invoice from Job Planning Line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Line Dimension Value = "JDV".
        FindSalesLineFromJobPlanningLine(SalesLine, JobPlanningLine);
        VerifySalesLineDimensionValue(SalesLine, JobDimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure VerifyGlobalDimensionIsSetFromPurchaserRelatedToVendorForPurchaseOrderCreatedFromReqWorksheet()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARION: 453034] Verify Global dimension on Purchase Line from Purchaser related to Vendor for Purchase Order created from Req. Worksheet 
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Setup Dimension Priority For Purchaser
        SetupDimensionPriorityForPurchSrcCode();

        // [GIVEN] Create dimensions with Value and set to Shortcut Dimension 1 Code on General Ledger Setup
        CreateDimensionAndSetupOnGeneralLedgerSetup(DimensionValue);

        // [GIVEN] Create Vendor with Purchaser
        CreateVendorWithPurchaserAndDefDim(Vendor, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Create Item with SKU
        CreateItemWithSKU(Item, Vendor);

        // [GIVEN] Create Sales Order
        CreateSalesOrderForItem(Item);

        // [WHEN] Calculate Plan for Req. Worksheet and Carry Out Req. Worksheet
        // [HANDLER] MsgHandler
        CreateReqLineAndCarryOutAction(Item);

        // [THEN] Verify Dimension Value in Purchase Line
        VerifyDimValueInPurchLine(Vendor, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    [Test]
    procedure VerifyDefaultDimensionPrioritiesLinesAreInitialized()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimPriorities: TestPage "Default Dimension Priorities";
    begin
        // [SCENARION: 455113] Verify Default Dim. Priorities lines are initialized
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Return Source Code Setup
        SourceCodeSetup.Get();

        // [GIVEN] Clear Default Dim. Priorities for Sales Source Code
        DeleteSalesSourceCodeRecords(SourceCodeSetup);

        // [GIVEN] Open Default Dimension Priorities for Sales Source Code
        OpenDefaultDimPriorities(DefaultDimPriorities, SourceCodeSetup);

        // [WHEN] Initialize Default Dim. Priorities for Sales Source Code
        DefaultDimPriorities.Initialize.Invoke();

        // [THEN] Verify records are created with priority
        VerifyDefaultDimensionPriority(SourceCodeSetup);
    end;

    [Test]
    procedure VerifyMissingDefaultDimensionPrioritiesNotificationIsEnabled()
    var
        MyNotifications: Record "My Notifications";
        Enabled: Boolean;
    begin
        // [SCENARION: 455113] When GetNotificationStatus business event in System Action Triggers is raised
        // for an enabled notification, the enabled status is returned

        // [GIVEN] Enabled notification
        MyNotifications.DeleteAll();
        MyNotifications.InsertDefault(DefaultDimPrioritiesNotificationIdTxt, '', '', true);

        // [THEN] Verify Notification Exist
        VerifyNotificationExists();

        // [THEN] Verify Notification is Enabled
        VerifyNotificationIsEnabled();

        // [WHEN] Raised GetNotificationStatus Event
        SystemActionTriggers.GetNotificationStatus(DefaultDimPrioritiesNotificationIdTxt, Enabled);

        // [THEN] The notification is enabled
        Assert.IsTrue(Enabled, 'Notification status must be true for enabled notification');
    end;

    [Test]
    procedure VerifyDefDimensionsOnProdOrderComponentLine()
    var
        Dimension: Record Dimension;
        CompDimensionValue: Record "Dimension Value";
        ProdDimensionValue: Record "Dimension Value";
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO 462109] Verify def. dimensions on Prod. Order Component when Default Dimension Priority are setup and when there is no priority
        Initialize();

        // [GIVEN] Create Dimension and set as Global Dimension 1
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetGlobalDimensionCode(1, Dimension.Code);

        // [GIVEN] Component Item with Default Dimension Value 
        CreateItemWithDefaultDimension(CompItem, CompDimensionValue, Dimension.Code);

        // [GIVEN] Create Production BOM
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);

        // [GIVEN] Create Prod. Item
        CreateItemWithDefaultDimension(ProdItem, ProdDimensionValue, Dimension.Code);
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create Prod. Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);

        // [WHEN] Refresh Production Order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);

        // Find Prod. Order Line and Component
        FindProdOrderLine(ProdOrderLine, ProductionOrder, ProdItem."No.");
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");

        // [THEN] Verify Dimension on Prod. Order Component from Prod. Order Line
        Assert.IsTrue(ProdOrderComponent."Shortcut Dimension 1 Code" = ProdDimensionValue.Code, 'Dimensions are not equal.');
        Assert.IsTrue(ProdOrderLine."Shortcut Dimension 1 Code" = ProdDimensionValue.Code, 'Dimensions are not equal.');
        Assert.IsTrue(ProdOrderLine."Shortcut Dimension 1 Code" = ProdOrderComponent."Shortcut Dimension 1 Code", 'Dimensions are not equal.');

        // [GIVEN] Define Dimension Priority for Prod. Order Source Code
        SetupDimensionPriorityForProductionSourceCode();

        // [WHEN] Refresh Prod. Order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);

        // Find Prod. Order Line and Component
        FindProdOrderLine(ProdOrderLine, ProductionOrder, ProdItem."No.");
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");

        // [THEN] Verify Dimension on Prod. Order Component from Component Item
        Assert.IsTrue(ProdOrderComponent."Shortcut Dimension 1 Code" = CompDimensionValue.Code, 'Dimensions are not equal.');
        Assert.IsTrue(ProdOrderLine."Shortcut Dimension 1 Code" = ProdDimensionValue.Code, 'Dimensions are not equal.');
        Assert.IsFalse(ProdOrderLine."Shortcut Dimension 1 Code" = ProdOrderComponent."Shortcut Dimension 1 Code", 'Dimensions are equal.');
    end;

    [Test]
    [HandlerFunctions('DueDateBeforeWorkDateMsgHandler')]
    procedure AvailWarningAssemblyOrdersConsideringDueDates()
    var
        AsmHeader: Record "Assembly Header";
        AsmHeader2: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        AssemblySetup: Record "Assembly Setup";
        BOMComponent: Record "BOM Component";
        ComponentItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        MyNotifications: Record "My Notifications";
        ProductItem: Record Item;
        Newworkdate: Date;
    begin
        // [SCENARIO 565695] Avail. Warning on Assembly Orders are now considering Demand for the Component only for selected Assembly Order.
        Initialize();

        // [GIVEN] Set Item Avaibility Is Low Notification Enabled.
        SetMyNotificationsSetup(MyNotifications);

        // [GIVEN] Create New Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Validate "Default Location for Orders" in Assembly Setup for New Created Location.
        AssemblySetup.Get();
        AssemblySetup.Validate("Default Location for Orders", Location.Code);
        AssemblySetup.Modify(true);

        // [GIVEN] Validate "Components at Location" in Manufacturing Setup for New Created Location.
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Components at Location", Location.Code);
        ManufacturingSetup.Modify(true);

        // [GIVEN] Created Component Item
        LibraryInventory.CreateItem(ComponentItem);

        // [GIVEN] Created Master Item and Assembly Component for Master Item
        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::Purchase);
        ProductItem.Validate("Manufacturing Policy", ProductItem."Manufacturing Policy"::"Make-to-Stock");
        ProductItem.Modify(true);
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, ComponentItem."No.", ProductItem."No.", '', 0, 2, true);

        // [GIVEN] Created 1st Assembly Order
        MakeAsmOrder(AsmHeader, ProductItem, 1, WorkDate(), Location.Code);

        // [WHEN] Get Assemblyline and Validate Quantity 
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.ShowAvailabilityWarning();
        AsmLine.Validate(Quantity, AsmLine.Quantity);

        // [THEN] 1st Check "Avail. Warning" on Assemblyline for 1st Assembly Order
        Assert.IsTrue(AsmLine."Avail. Warning", AvailWarningYesMsg);


        // [GIVEN] Created and Post Item Journal for Component Item
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentItem."No.", Location.Code, '', 2);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Get Assemblyline and Validate Quantity for 1st Assembly Order
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.ShowAvailabilityWarning();
        AsmLine.Validate(Quantity, AsmLine.Quantity);

        // [THEN] 2nd Check "Avail. Warning" on Assemblyline for 1st Assembly Order
        Assert.IsFalse(AsmLine."Avail. Warning", AvailWarningNoMsg);

        // [GIVEN] Recall All Notifications
        NotificationLifecycleMgt.RecallAllNotifications();

        // [GIVEN] Set 2nd New Work Date.
        Newworkdate := CalcDate('<1W>', WorkDate());
        WorkDate(Newworkdate);

        // [GIVEN] Make 2nd Assembly Order 
        MakeAsmOrder(AsmHeader2, ProductItem, 3, Newworkdate, Location.Code);

        // [WHEN] Get Assemblyline and Validate Quantity for 2nd Assembly Order
        AsmLine.Get(AsmHeader2."Document Type", AsmHeader2."No.", 10000);
        AsmLine.ShowAvailabilityWarning();
        AsmLine.Validate(Quantity, AsmLine.Quantity);

        // [THEN] 1st Check "Avail. Warning" on Assemblyline for 2nd Assembly Order
        Assert.IsTrue(AsmLine."Avail. Warning", AvailWarningYesMsg);

        // [WHEN] Get Assemblyline and Validate Quantity for 1st Assembly Order
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        AsmLine.ShowAvailabilityWarning();
        AsmLine.Validate(Quantity, AsmLine.Quantity);

        // [THEN] 3rd Check "Avail. Warning" on Assemblyline for 1st Assembly Order
        Assert.IsFalse(AsmLine."Avail. Warning", AvailWarningNoMsg);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure ProdOrderComponentDimensionsInPlanningWorksheet()
    var
        Dimension: Record Dimension;
        CompDimensionValue: Record "Dimension Value";
        ProdDimensionValue: Record "Dimension Value";
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        ReqWkshTemplateName: Code[10];
        Direction: Option Forward,Backward;
    begin
        // [SCENARIO 598811] Verify production order component dimensions are correctly transferred to planning worksheet components
        Initialize();

        // [GIVEN] Create Dimension and set as Global Dimension 1.
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.SetGlobalDimensionCode(1, Dimension.Code);

        // [GIVEN] Component Item with Default Dimension Value (e.g., SALESPERSON = JO)
        CreateItemWithDefaultDimension(CompItem, CompDimensionValue, Dimension.Code);

        // [GIVEN] Create Production BOM
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Create Prod. Item with different Default Dimension Value.
        CreateItemWithDefaultDimension(ProdItem, ProdDimensionValue, Dimension.Code);
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create Planning Worksheet Template and Name.
        ReqWkshTemplateName := LibraryPlanning.SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplateName);

        // [WHEN] Create Planning Line for Parent Item.
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplateName, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ProdItem."No.");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Modify(true);

        // [WHEN] Refresh Planning Line to create Componenets.
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // [GIVEN] Find Planning Component
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningComponent.SetRange("Item No.", CompItem."No.");
        PlanningComponent.FindFirst();

        // [THEN] Verify Planning Component has Component Item's dimension.
        Assert.AreEqual(
            CompDimensionValue.Code,
            PlanningComponent."Shortcut Dimension 1 Code",
            StrSubstNo(
                DimensionCodeErr,
                CompDimensionValue.Code,
                PlanningComponent.TableCaption()));

        // [THEN] Verify Requisition Line still has Parent Item's dimension
        Assert.AreEqual(
            ProdDimensionValue.Code,
            RequisitionLine."Shortcut Dimension 1 Code",
            StrSubstNo(
                DimensionCodeErr,
                ProdDimensionValue.Code,
                RequisitionLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Priority");
        // Lazy Setup.
        LibraryDimension.InitGlobalDimChange();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Priority");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ClearDimensionCombinations();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Priority");
    end;

    local procedure DifferentPriority(CustomerPri: Integer; GLAccountPri: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
    begin
        Initialize();
        GetGLBalancedBatch(GenJournalBatch);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // Create default dimension codes for Customer and G/L Account
        CreateDefaultDimensionCodes(CustomerNo, GenJournalBatch."Bal. Account No.");

        // Setup priorities
        SetupDimensionPriority(LibraryERM.FindGeneralJournalSourceCode(), CustomerPri, GLAccountPri);

        // Find default dimension codes
        if CustomerPri < GLAccountPri then
            FindDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo)
        else
            FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GenJournalBatch."Bal. Account No.");

        // Create a journal line
        ClearJournalBatch(GenJournalBatch);
        CreateGeneralJnlLine(GenJournalLine, GenJournalBatch, CustomerNo);

        // Verify dimensions
        VerifyDimensionSetID(DefaultDimension, GenJournalLine."Dimension Set ID");
    end;

    local procedure PriorityJobJnlLineWithDefaultDim(TableIDs: array[2] of Integer; Priorities: array[2] of Integer; ExpectedDimValueIndex: Integer; FillJobTaskNo: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        DefaultDimension: Record "Default Dimension";
        ResourceNo: Code[20];
        DimValueArray: array[3] of Code[20];
        DimensionCode: Code[20];
    begin
        // Setup.
        Initialize();

        SetupDimensionPriorityForJobJnlSrcCode(TableIDs, Priorities);
        DimensionCode := CreateDimensionValues(DimValueArray);
        LibraryJob.CreateJob(Job);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, Job."No.", DimensionCode, DimValueArray[1]);
        LibraryJob.CreateJobTask(Job, JobTask);
        if FillJobTaskNo then
            UpdateJobTaskDimension(JobTask, DimensionCode, DimValueArray[2]);
        ResourceNo := LibraryJob.CreateConsumable("Job Planning Line Type"::Resource);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Resource, ResourceNo, DimensionCode, DimValueArray[3]);

        // Exercise.
        if not FillJobTaskNo then
            JobTask."Job Task No." := '';
        CreateJobJnlLine(JobTask, ResourceNo);

        // Verify.
        VerifyDimValueInJobJnlLine(Job."No.", JobTask."Job Task No.", DimensionCode, DimValueArray[ExpectedDimValueIndex]);
    end;

    local procedure CreateVendorWithPurchaserAndDefDim(DimensionCode: Code[20]; DimensionValueCode: array[3] of Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        Purchaser: Record "Salesperson/Purchaser";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(Purchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", Purchaser.Code, DimensionCode, DimensionValueCode[1]);

        Vendor.Validate("Purchaser Code", Purchaser.Code);
        Vendor.Modify(true);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Vendor, Vendor."No.", DimensionCode, DimensionValueCode[2]);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithReplenishmentPociliyAndDefDim(DimensionCode: Code[20]; DimensionValueCode: Code[20]; VendNo: Code[20]): Code[20]
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Quantity", 1);
        Item.Validate("Vendor No.", VendNo);
        Item.Modify(true);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, Item."No.", DimensionCode, DimensionValueCode);
        exit(Item."No.");
    end;

    local procedure CreateItemWithDefaultDimension(var Item: Record Item; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, Item."No.", DimensionCode, DimensionValue.Code);
    end;

    local procedure CreateJobTaskWithDefaultDimension(var JobTask: Record "Job Task"; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    var
        Job: Record Job;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryJob.CreateJob(Job);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, Job."No.", DimensionCode, DimensionValue.Code);
        LibraryJob.CreateJobTask(Job, JobTask);
        UpdateJobTaskDimension(JobTask, DimensionCode, DimensionValue.Code);
    end;

    local procedure CreateSalesPersonWithDimAndPriority(var SalespersonCode: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code,
          DimensionValue."Dimension Code", DimensionValue.Code);
        SalespersonCode := SalespersonPurchaser.Code;
        exit(DimensionValue.Code);
    end;

    local procedure CreateServiceContractWithDimAndPriority(var ServiceContractCode: Code[20]; var CustomerCode: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        ServiceContractHeader: Record "Service Contract Header";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        CreateServiceContract(ServiceContractHeader);
        ServiceContractHeader."Dimension Set ID" :=
          LibraryDimension.CreateDimSet(ServiceContractHeader."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        ServiceContractHeader.Modify();
        ServiceContractCode := ServiceContractHeader."Contract No.";
        CustomerCode := ServiceContractHeader."Customer No.";
        exit(DimensionValue.Code);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Init();
        ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Contract;
        ServiceContractHeader."Contract No." :=
          LibraryUtility.GenerateRandomCode(ServiceContractHeader.FieldNo("Contract No."), DATABASE::"Service Contract Header");
        ServiceContractHeader.Status := ServiceContractHeader.Status::Signed;
        ServiceContractHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceContractHeader.Insert();
        Commit();
    end;

    local procedure CreateServiceQuotaWithSalesPerson(var ServiceHeader: Record "Service Header"; CustomerCode: Code[20]; SalespersonCode: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, CustomerCode);
        ServiceHeader.Validate("Salesperson Code", SalespersonCode);
        ServiceHeader.Modify(true);
    end;

    local procedure CreatePurchaseLineWithItemAndJobTask(var PurchaseLine: Record "Purchase Line"; Item: Record Item; JobTask: Record "Job Task")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithItemAndJobTask(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; ItemNo: Code[20])
    begin
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure FindDefaultDimension(var DefaultDimension: Record "Default Dimension"; TableID: Integer; No: Code[20])
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.FindSet();
    end;

    local procedure SetupDimensionPriority(SourceCode: Code[10]; CustomerPriority: Integer; GLAccountPriority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        // Clear priorities setup
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll();
        // Setup new priorities
        DefaultDimensionPriority.Validate("Source Code", SourceCode);
        CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::Customer, CustomerPriority);
        CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::"G/L Account", GLAccountPriority);
    end;

    local procedure SetupDimensionPriorityForPurchSrcCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        SourceCodeSetup.Get();
        DefaultDimensionPriority.SetRange("Source Code", SourceCodeSetup.Purchases);
        DefaultDimensionPriority.DeleteAll();

        DefaultDimensionPriority.Validate("Source Code", SourceCodeSetup.Purchases);
        CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::"Salesperson/Purchaser", 1);
        CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::Vendor, 2);
        CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::Item, 3);
    end;

    local procedure SetupDimensionPriorityForJobJnlSrcCode(TableIDs: array[2] of Integer; Priorities: array[2] of Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimensionPriority: Record "Default Dimension Priority";
        i: Integer;
    begin
        SourceCodeSetup.Get();
        DefaultDimensionPriority.SetRange("Source Code", SourceCodeSetup."Job Journal");
        DefaultDimensionPriority.DeleteAll();

        DefaultDimensionPriority.Validate("Source Code", SourceCodeSetup."Job Journal");
        for i := 1 to ArrayLen(TableIDs) do
            CreateDefaultDimPriority(DefaultDimensionPriority, TableIDs[i], Priorities[i]);
    end;

    local procedure CreateDefaultDimPriority(var DefaultDimPriority: Record "Default Dimension Priority"; TableID: Integer; Priority: Integer)
    begin
        if (TableID = 0) or (Priority = 0) then
            exit;

        DefaultDimPriority.Validate("Table ID", TableID);
        DefaultDimPriority.Validate(Priority, Priority);
        DefaultDimPriority.Insert(true);
    end;

    local procedure ClearDimensionCombinations()
    var
        DimensionCombination: Record "Dimension Combination";
    begin
        DimensionCombination.DeleteAll(true);
    end;

    local procedure CreateDimensionValues(var DimensionValueArray: array[3] of Code[20]): Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to 3 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            DimensionValueArray[i] := DimensionValue.Code;
        end;
        exit(DimensionValue."Dimension Code");
    end;

    local procedure CreateDefaultDimensionCodes(CustomerNo: Code[20]; GLAccount: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        i: Integer;
    begin
        // Clear existing dimension setup to make room for our new setup
        ClearDefaultDimensionCodes(DATABASE::Customer, CustomerNo);
        ClearDefaultDimensionCodes(DATABASE::"G/L Account", GLAccount);

        // Setup special dimension values such that all cases exists:
        // Case 1: Dimension exist in customer, but not in Account
        // Case 2: Opposite of Case 1
        // Case 3: Dimension exists in both with same value
        // Case 4: Dimension exists in both with different value

        i := 0;
        Dimension.FindSet();
        repeat
            if i < Dimension.Count - 1 then
                LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo, Dimension.Code,
                  GetDimensionValueCode(Dimension.Code, 1));
            if i > 0 then
                LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GLAccount, Dimension.Code,
                  GetDimensionValueCode(Dimension.Code, i mod 2));
            i += 1;
        until Dimension.Next() = 0;
    end;

    local procedure ClearDefaultDimensionCodes(TableID: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.DeleteAll(true);
    end;

    local procedure ClearDefaultDimensionPriorities(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll(true);
    end;

    local procedure GetDimensionValueCode(DimensionCode: Code[20]; Number: Integer): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindSet();
        DimensionValue.Next(Number);
        exit(DimensionValue.Code);
    end;

    local procedure GetGLBalancedBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure ClearJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; CustomerNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer,
          CustomerNo,
          -LibraryRandom.RandInt(1000));
    end;

    local procedure CreateJobJnlLine(JobTask: Record "Job Task"; ResourceNo: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        JobJournalLine: Record "Job Journal Line";
    begin
        SourceCodeSetup.Get();
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Budget, JobTask, JobJournalLine);
        JobJournalLine.Validate("Source Code", SourceCodeSetup."Job Journal");
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Modify(true);
    end;

    local procedure UpdateJobTaskDimension(JobTask: Record "Job Task"; DimensionCode: Code[20]; DimensionValue: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        JobTaskDimension.Get(JobTask."Job No.", JobTask."Job Task No.", DimensionCode);
        JobTaskDimension.Validate("Dimension Value Code", DimensionValue);
        JobTaskDimension.Modify(true);
    end;

    local procedure CreateReqLineAndCarryOutAction(ItemNo: Code[20])
    var
        ReqLine: Record "Requisition Line";
    begin
        CreateReqLine(ReqLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(ReqLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CreateReqLineWithCustomDimVal(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        CreateReqLine(RequisitionLine, ItemNo);
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        RequisitionLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        RequisitionLine.Modify();
        exit(DimensionValue.Code);
    end;

    local procedure SetupGlobalDimension(DimIndex: Integer; NewDimCode: Code[20]) PrevDimCode: Code[20]
    var
        DimCodes: array[2] of Code[20];
    begin
        DimCodes[1] := LibraryERM.GetGlobalDimensionCode(1);
        DimCodes[2] := LibraryERM.GetGlobalDimensionCode(2);
        PrevDimCode := DimCodes[DimIndex];
        DimCodes[DimIndex] := NewDimCode;
        LibraryDimension.RunChangeGlobalDimensions(DimCodes[1], DimCodes[2]);
    end;

    local procedure SetServiceDimensionPriorities(SalesPersonPriority: Integer; ServiceContractPriority: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ClearDefaultDimensionPriorities(SourceCodeSetup."Service Management");
        CreateDefaultDimensionPriority(SourceCodeSetup."Service Management", DATABASE::"Salesperson/Purchaser", SalesPersonPriority);
        CreateDefaultDimensionPriority(SourceCodeSetup."Service Management", DATABASE::"Service Contract Header", ServiceContractPriority);
    end;

    local procedure SetPurchaseDimensionPriorities(ItemPriority: Integer; JobPriority: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ClearDefaultDimensionPriorities(SourceCodeSetup.Purchases);
        CreateDefaultDimensionPriority(SourceCodeSetup.Purchases, DATABASE::Item, ItemPriority);
        CreateDefaultDimensionPriority(SourceCodeSetup.Purchases, DATABASE::Job, JobPriority);
    end;

    local procedure SetSalesDimensionPriorities(ItemPriority: Integer; JobPriority: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ClearDefaultDimensionPriorities(SourceCodeSetup.Sales);
        CreateDefaultDimensionPriority(SourceCodeSetup.Sales, DATABASE::Item, ItemPriority);
        CreateDefaultDimensionPriority(SourceCodeSetup.Sales, DATABASE::Job, JobPriority);
    end;

    local procedure CreateReqLine(var ReqLine: Record "Requisition Line"; ItemNo: Code[20])
    var
        Item: Record Item;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        ReqWkshTemplate."Increment Batch Name" := true;
        ReqWkshTemplate.Modify();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        Item.Get(ItemNo);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate(), WorkDate());
        FindReqLine(ReqLine, Item."No.");
    end;

    local procedure FindReqLine(var ReqLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", ItemNo);
        ReqLine.FindFirst();
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; VendNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange("Buy-from Vendor No.", VendNo);
        PurchHeader.FindLast();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.FindFirst();
    end;

    local procedure FindJobJnlLine(var JobJournalLine: Record "Job Journal Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        JobJournalLine.SetRange("Job No.", JobNo);
        JobJournalLine.SetRange("Job Task No.", JobTaskNo);
        JobJournalLine.FindSet();
    end;

    local procedure FindSalesLineFromJobPlanningLine(var SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice);
        JobPlanningLineInvoice.FindFirst();
        SalesLine.SetRange("Document No.", JobPlanningLineInvoice."Document No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.FindFirst();
    end;

    local procedure SetTablePriority(var TableIDs: array[2] of Integer; var Priorities: array[2] of Integer; TableID: Integer; Priority: Integer; Index: Integer)
    begin
        TableIDs[Index] := TableID;
        Priorities[Index] := Priority;
    end;

    local procedure VerifyDimensionSetID(var DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Compare dimension set on the "Customer" / "G/L Account" to that on the journal line
        DefaultDimension.FindSet();
        repeat
            DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
            DimensionSetEntry.SetRange("Dimension Code", DefaultDimension."Dimension Code");
            DimensionSetEntry.FindFirst();
            Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DefaultDimension."Dimension Value Code", 'Dimension value mismatch');
        until DefaultDimension.Next() = 0;
    end;

    local procedure CreateDefaultDimensionPriority(SourceCode: Code[10]; TableID: Integer; Priority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, TableID);
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Modify(true);
    end;

    local procedure FindDefaultDimensionPriority(var DefaultDimensionPriority: Record "Default Dimension Priority"; SourceCode: Code[10]; TableID: Integer)
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.SetRange("Table ID", TableID);
        DefaultDimensionPriority.FindFirst();
    end;

    local procedure SetDefaultDimensionPriority(SourceCode: Code[10])
    begin
        // Create default dimension priority 1 for Customer, 1 for Vendor and  2 for G/L Account must created with source code.
        ClearDefaultDimensionPriorities(SourceCode);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::Customer, 1);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::Vendor, 1);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::"G/L Account", 2);
    end;

    local procedure SetMyNotificationsSetup(var MyNotifications: Record "My Notifications")
    begin
        if MyNotifications.Get(UserId, ItemAvaibilityIsLowNotificationIdTxt) then begin
            MyNotifications.Validate(Enabled, true);
            MyNotifications.Modify(true);
        end else
            MyNotifications.InsertDefault(ItemAvaibilityIsLowNotificationIdTxt, '', '', true);
    end;

    local procedure MakeAsmOrder(var AsmHeader: Record "Assembly Header"; ParentItem: Record Item; Qty: Decimal; DueDate: Date; LocationCode: Code[10])
    begin
        Clear(AsmHeader);
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader.Insert(true);
        AsmHeader.Validate("Due Date", DueDate);
        AsmHeader.Validate("Location Code", LocationCode);
        AsmHeader.Validate("Item No.", ParentItem."No.");
        AsmHeader.Validate(Quantity, Qty);
        AsmHeader.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [MessageHandler]
    procedure MsgHandler(Message: Text)
    begin
    end;

    local procedure VerifyDefaultDimensionPriority(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        // Verify default dimension priority 1 for Customer, 1 for Vendor and  2 for G/L Account must created with source code.
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, DATABASE::Customer);
        DefaultDimensionPriority.TestField(Priority, 1);
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, DATABASE::Vendor);
        DefaultDimensionPriority.TestField(Priority, 1);
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, DATABASE::"G/L Account");
        DefaultDimensionPriority.TestField(Priority, 2);
    end;

    local procedure VerifyDimValueInPurchLine(VendNo: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        PurchLine: Record "Purchase Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        FindPurchLine(PurchLine, VendNo);
        DimensionSetEntry.Get(PurchLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", WrongDimValueCodeErr);
    end;

    local procedure VerifyDimValueInJobJnlLine(JobNo: Code[20]; JobTaskNo: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        JobJournalLine: Record "Job Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        FindJobJnlLine(JobJournalLine, JobNo, JobTaskNo);
        DimensionSetEntry.Get(JobJournalLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", WrongDimValueCodeErr);
    end;

    local procedure VerifyPurchaseLineDimensionValue(PurchaseLine: Record "Purchase Line"; DimensionValueCode: Code[20])
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, PurchaseLine."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifySalesLineDimensionValue(SalesLine: Record "Sales Line"; DimensionValueCode: Code[20])
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, SalesLine."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifyDimValueInPurchLine(var Vendor: Record Vendor; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        PurchLine: Record "Purchase Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        FindPurchLine(PurchLine, Vendor."No.");
        DimensionSetEntry.Get(PurchLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", WrongDimValueCodeErr);
    end;

    local procedure CreateSalesOrderForItem(var Item: Record Item)
    var
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateReqLineAndCarryOutAction(var Item: Record Item)
    var
        ReqLine: Record "Requisition Line";
    begin
        CreateReqLine(ReqLine, Item);
        LibraryPlanning.CarryOutReqWksh(ReqLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CreateReqLine(var ReqLine: Record "Requisition Line"; var Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateReqWkshTemplateName(RequisitionWkshName, ReqWkshTemplate);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate(), WorkDate());
        FindReqLine(ReqLine, Item);
    end;

    local procedure FindReqLine(var ReqLine: Record "Requisition Line"; var Item: Record Item)
    begin
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", Item."No.");
        ReqLine.FindFirst();
    end;

    local procedure CreateReqWkshTemplateName(var RequisitionWkshName: Record "Requisition Wksh. Name"; var ReqWkshTemplate: Record "Req. Wksh. Template")
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateDimensionAndSetupOnGeneralLedgerSetup(var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryERM.SetGlobalDimensionCode(1, DimensionValue."Dimension Code");
    end;

    local procedure CreateVendorWithPurchaserAndDefDim(var Vendor: Record Vendor; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        Purchaser: Record "Salesperson/Purchaser";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(Purchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", Purchaser.Code, DimensionCode, DimensionValueCode);
        Vendor.Validate("Purchaser Code", Purchaser.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateItemWithSKU(var Item: Record Item; var Vendor: Record Vendor)
    var
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');
        SKU.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::"Lot-for-Lot");
        SKU.Modify(true);
    end;

    local procedure VerifyNotificationExists()
    var
        MyNotifications: Record "My Notifications";
    begin
        Assert.IsTrue(MyNotifications.Get(UserId, DefaultDimPrioritiesNotificationIdTxt), 'Notification should be present in My Notifications');
    end;

    local procedure VerifyNotificationIsEnabled()
    var
        MyNotifications: Record "My Notifications";
    begin
        Assert.IsTrue(MyNotifications.IsEnabled(DefaultDimPrioritiesNotificationIdTxt), 'Notification should be enabled');
    end;

    local procedure VerifyDefaultDimensionPriority(var SourceCodeSetup: Record "Source Code Setup")
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        // Verify default dimension priority 1 for Customer and 2 for Item.
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCodeSetup.Sales, DATABASE::Customer);
        DefaultDimensionPriority.TestField(Priority, 1);
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCodeSetup.Sales, DATABASE::"Item");
        DefaultDimensionPriority.TestField(Priority, 2);
    end;

    local procedure DeleteSalesSourceCodeRecords(var SourceCodeSetup: Record "Source Code Setup")
    var
        DefaultDimPriority: Record "Default Dimension Priority";
    begin
        DefaultDimPriority.SetRange("Source Code", SourceCodeSetup.Sales);
        DefaultDimPriority.DeleteAll();
    end;

    local procedure OpenDefaultDimPriorities(var DefaultDimPriorities: TestPage "Default Dimension Priorities"; var SourceCodeSetup: Record "Source Code Setup")
    begin
        DefaultDimPriorities.OpenEdit();
        DefaultDimPriorities.CurrentSourceCode.SetValue(SourceCodeSetup.Sales);
    end;

    local procedure SetupDimensionPriorityForProductionSourceCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        SourceCodeSetup.Get();
        DefaultDimensionPriority.SetRange("Source Code", SourceCodeSetup."Production Order");
        DefaultDimensionPriority.DeleteAll();
        DefaultDimensionPriority.Validate("Source Code", SourceCodeSetup."Production Order");
        CreateDefaultDimPriority(DefaultDimensionPriority, Database::Item, 1);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToInvoiceHandler(var RequestPage: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        RequestPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure DueDateBeforeWorkDateMsgHandler(Msg: Text[1024])
    var
        MessageTextFromHeader: Text[1024];
        MessageTextFromLine: Text[1024];
    begin
        MessageTextFromHeader := StrSubstNo(DueDateBeforeWDFromHeaderMsg, NewLineDueDate, WorkDate());
        MessageTextFromLine := StrSubstNo(DueDateBeforeWDFromLineMsg, NewLineDueDate, WorkDate());
        case TestMethodName of
            TestVSTF257960A:
                case Step of
                    1, 9:
                        begin
                            Assert.IsTrue(
                              StrPos(Msg, MessageTextFromHeader) > 0, StrSubstNo('Wrong message: %1 \Expected: %2', Msg, MessageTextFromHeader));
                            exit;
                        end;
                    10:
                        begin
                            Assert.IsTrue(
                              StrPos(Msg, MessageTextFromLine) > 0, StrSubstNo('Wrong message: %1 \Expected: %2', Msg, MessageTextFromLine));
                            exit;
                        end;
                end;
            else
                exit; // for other test methods.
        end;

        Assert.Fail(StrSubstNo('Message at Step %1 not expected.', Step));
    end;
}

