codeunit 136317 "Inv. Pick On Job Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Inventory Pick]
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        LocationWithRequirePickBinMandatory: Record Location;
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        LocationWithRequirePick: Record Location;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        NothingToCreateMsg: Label 'nothing to create';
        SumValueUnequalErr: Label 'The actual value and the expected sum of filtered %1 %2 are not equal', Comment = '%1 = Item Ledger Entries, %2 = Quantity';
        FieldMustNotBeChangedErr: Label 'must not be changed when a %1 for this %2 exists: ';
        DeletionNotPossibleErr: Label 'The %1 cannot be deleted when a related %2 exists.';
        IsInitialized: Boolean;
        ReInitializeJobSetup: Boolean;
        ItemReclassificationErr: Label '%1 Item must be in Reclassification Journal.', Comment = '%1=Item No.';
        LotNoErr: Label 'Lot No. must not be empty.';
        TrackingOption: Option "Assign Lot No.","Assign Serial No.";
        ReservationEntryNotFoundErr: Label 'Reservation Entry should be created for the Job Planning Line';

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostJobJournalWithBinMandatory()
    var
        Item: Record Item;
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 1] Create and post Job Journal from Job with location where 'Require Pick' = Yes and 'Bin Mandatory' = Yes

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has planning line that require the item from a location where 'Require pick' = Yes and 'Bin mandatory' = Yes
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [WHEN] 'Qty to Tranfer to Journal' is set
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToUse);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [THEN] No error is thrown

        // [WHEN] Job Journal Line is created and posted
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, "Job Line Type"::Budget, 1, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] No error is thrown
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostJobJournalWithoutBinMandatory()
    var
        Item: Record Item;
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 2] Create and post Job Journal from Job with location where 'Require Pick' = Yes and 'Bin Mandatory' = No

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = No
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has planning line that require the item from a location where 'Require pick' = Yes and 'Bin mandatory' = No
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePick.Code, '', QtyToUse);

        // [WHEN] 'Qty to Tranfer to Journal' is set
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToUse);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [THEN] No error is thrown

        // [WHEN] Job Journal Line is created and posted
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, "Job Line Type"::Budget, 1, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPickCannotBeCreatedForJobsThatAreNotOpen()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        JobCard: TestPage "Job Card";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 3] Inventory Pick cannot be created for a Job whose status is <> Open

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = No
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which is not Open and has planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePick.Code, '', QtyToUse);

        Job.Get(JobPlanningLine."Job No.");
        Job.Validate(Status, Job.Status::Planning);
        Job.Modify(true);

        // [WHEN] 'Create Inventory Put-away/Pick/Movement' action is invoked
        // [THEN] Error is thrown validating the Job.Status
        JobCard.OpenEdit();
        JobCard.GoToRecord(Job);
        asserterror JobCard."Create Inventory Pick".Invoke();
        Assert.ExpectedTestFieldError(Job.FieldCaption(Status), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPicksCanBeCreatedForAJob()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        JobCard: TestPage "Job Card";
        WarehouseActivityLines: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 4] Inventory Pick can be created for a Job

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which is not Open and has planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);
        Commit();

        // [WHEN] 'Create Inventory Put-away/Pick/Movement' action is invoked
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Warehouse pick lines are created
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Job Usage");
        WarehouseActivityLine.SetRange("Source No.", Job."No.");

        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Source Document", WarehouseActivityLine."Source Document"::"Job Usage");
        WarehouseActivityLine.TestField("Source No.", Job."No.");
        WarehouseActivityLine.TestField("Item No.", Item."No.");
        WarehouseActivityLine.TestField("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityLine.TestField("Bin Code", Bin1.Code);
        WarehouseActivityLine.TestField(Quantity, QtyToUse);

        // [WHEN] 'Put-away/Pick Lines/Movement Lines' action is invoked
        WarehouseActivityLines.Trap();
        JobCard.OpenEdit();
        JobCard.GoToRecord(Job);
        JobCard."Put-away/Pick Lines/Movement Lines".Invoke();

        // [THEN] 'Warehouse Activity Lines' page opens and loads the pick lines
        WarehouseActivityLines."Item No.".AssertEquals(Item."No.");
        WarehouseActivityLines.Quantity.AssertEquals(QtyToUse);
        WarehouseActivityLines.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPicksCanBeCreatedForAJobFromInventoryPickPage()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        JobCard: TestPage "Job Card";
        WarehouseActivityLines: TestPage "Warehouse Activity Lines";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 5] Inventory Pick can be created for a Job through the Inventory Pick page

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which is not Open and has planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [WHEN] 'Create Inventory Put-away/Pick/Movement' action is invoked
        Job.Get(JobPlanningLine."Job No.");
        JobCard.OpenEdit();
        JobCard.GoToRecord(Job);

        InventoryPickPage.OpenNew();
        InventoryPickPage."Location Code".SetValue(LocationWithRequirePickBinMandatory.Code);
        InventoryPickPage.SourceDocument.SetValue(WarehouseActivityHeader."Source Document"::"Job Usage");
        InventoryPickPage."Source No.".SetValue(Job."No.");

        // [THEN] Warehouse pick lines are created
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Job Usage");
        WarehouseActivityLine.SetRange("Source No.", Job."No.");

        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Source Document", WarehouseActivityLine."Source Document"::"Job Usage");
        WarehouseActivityLine.TestField("Source No.", Job."No.");
        WarehouseActivityLine.TestField("Item No.", Item."No.");
        WarehouseActivityLine.TestField("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityLine.TestField("Bin Code", Bin1.Code);
        WarehouseActivityLine.TestField(Quantity, QtyToUse);

        // [WHEN] 'Put-away/Pick Lines/Movement Lines' action is invoked
        WarehouseActivityLines.Trap();
        JobCard."Put-away/Pick Lines/Movement Lines".Invoke();

        // [THEN] 'Warehouse Activity Lines' page opens and loads the pick lines
        WarehouseActivityLines."Item No.".AssertEquals(Item."No.");
        WarehouseActivityLines.Quantity.AssertEquals(QtyToUse);
        WarehouseActivityLines.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PostPicksModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure InventoryPicksCanBePostedForAJob()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        JobCard: TestPage "Job Card";
        WarehouseActivityLines: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 6] Inventory Pick can be posted for a Job

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which is not Open and has planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [WHEN] 'Create Inventory Put-away/Pick/Movement' action is invoked
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] 'Put-away/Pick Lines/Movement Lines' action is invoked
        WarehouseActivityLines.Trap();
        JobCard.OpenEdit();
        JobCard.GoToRecord(Job);
        JobCard."Put-away/Pick Lines/Movement Lines".Invoke();

        LibraryVariableStorage.Enqueue(QtyToUse); // Qty. to Handle
        WarehouseActivityLines.ShowDocument.Invoke();

        WarehouseActivityLines.Close();

        VerifyEntriesAfterPostingInvPick(Job, JobTask);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,JobTransferJobPlanningLineHandler')]
    [Scope('OnPrem')]
    procedure CreateJobJnlForNonInventoryTypesWithoutPicking()
    var
        NonInventoryItem: Record Item;
        ServiceItem: Record Item;
        SNWhseTrackedItem: Record Item;
        SNOnlyTrackedItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Create job journal lines from job planning lines with non-inventory items, Resource and GL Account without having to create picks. Also including items with SN/Warehouse SN tracking enabled.
        // [GIVEN] Location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();

        // [GIVEN] Non-Inventory type of item
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] Service type of item
        LibraryInventory.CreateServiceTypeItem(ServiceItem);

        // [GIVEN] Resource
        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] G/L account
        GLAccountNo := CreateGLAccount();

        // [GIVEN] Whse specific tracked item
        CreateSerialTrackedItem(SNWhseTrackedItem, true);

        // [GIVEN] SN only tracked item
        CreateSerialTrackedItem(SNOnlyTrackedItem, false);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line for the non-inventory, service item, resource, GL account and item with whs tracking enabled.
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, NonInventoryItem."No.", LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ServiceItem."No.", LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine3.Type::Resource, ResourceNo, LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine4.Type::"G/L Account", GLAccountNo, LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine5.Type::Item, SNWhseTrackedItem."No.", LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine5.Type::Item, SNOnlyTrackedItem."No.", LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Transfer job planning lines to job journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine4);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine5);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine6);

        // [THEN] No error is thrown and the job journal lines are created.
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        Assert.RecordCount(JobJournalLine, 6);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreatePickForMultipleJobTasks()
    var
        ResourceNo: Code[20];
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 7] Create inventory pick for multiple job tasks with different type of job planning lines and then verify the records created.
        // [GIVEN] Inventory pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        ResourceNo := LibraryResource.CreateResourceNo();

        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");

        // [GIVEN] Create Multiple job tasks and a Job Planning Line for every job task with the common location and Bin Code
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T2: Type = Resource, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, ResourceNo, LocationWithRequirePickBinMandatory.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T3: Type = Item, Line Type = Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Billable, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T4: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [WHEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Number of inventory pick activity header created for the job is 1
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        Assert.RecordCount(WarehouseActivityHeader, 1);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Number of inventory pick activities created for the job is 2. These include task T1 and task T4.
        WarehouseActivityLinePick.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);

        // [THEN] Verify data in warehouse activity lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable");
        if JobPlanningLine.FindSet() then
            repeat
                VerifyWarehouseActivityLine(JobPlanningLine);
            until JobPlanningLine.Next() = 0;


        // [WHEN] Auto fill Qty to handle on Inventory Pick and Post it along with Job Journal
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify Job Planning Lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        if JobPlanningLine.FindSet() then
            repeat
                if (JobPlanningLine.Type = JobPlanningLine.Type::Item) and ((JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::Budget) or (JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::"Both Budget and Billable")) then begin
                    JobPlanningLine.TestField("Remaining Qty.", 0);
                    JobPlanningLine.TestField("Qty. Posted", JobPlanningLine.Quantity);
                end else
                    JobPlanningLine.TestField("Qty. Posted", 0);
            until JobPlanningLine.Next() = 0;

        // [THEN] Verify Warehouse Entries
        // [THEN] Verify Job Ledger
        // [THEN] Verify Item Ledger Entries
        JobTask.Reset();
        JobTask.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobTask, 4);
        if JobTask.FindSet() then
            repeat
                VerifyEntriesAfterPostingInvPick(Job, JobTask);
            until JobTask.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoErrorWhenLinkedJobJournalLineExistsAndCreatePickIsCalled()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 8] Creating inventory pick succeeds for job with an existing job journal line.
        // [GIVEN] Inventory pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Create Job Journal Lines from Job Planning Line
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [WHEN] Create Inventory Pick for the Job is called
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] No error is thrown and the pick lines are created
        VerifyWarehouseActivityLine(JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('NothingToCreateMessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreatePickAgainAfterPostingFirstPick()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 9] Show Nothing to create message if inventory pick is created again after posting the initial pick.
        // [GIVEN] Inventory pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Auto fill Qty to handle on Inventory Pick and Post Pick, but do not post job journal line
        AutoFillAndPostInventoryPickFromPage(JobPlanningLine);

        // [WHEN] Create Inventory Pick for the Job again.
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Nothing to create message is shown as the item was completely picked.
        Assert.ExpectedMessage(NothingToCreateMsg, LibraryVariableStorage.DequeueText()); //NothingToCreateMsg is Enqueued in NothingToCreateMessageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickAgainAfterAddingAnotherJobTask()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 10] Create Inventory Pick again after adding another Job Task to same Job.
        // [GIVEN] Inventory pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [WHEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] 1 Inventory Pick Header Created
        VerifyWarehouseActivityLine(JobPlanningLine);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordCount(WarehouseActivityLinePick, 1);

        // [WHEN] Create a new Job Planning Line for a new Job Task T2: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [WHEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] 2nd inventory pick created.
        VerifyWarehouseActivityLine(JobPlanningLine);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordCount(WarehouseActivityLinePick, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreatePickForMultipleJobPlanningLines()
    var
        Item: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 11] Create and post inventory pick for a job with 1 job task and multiple job planning lines.
        // [GIVEN] Inventory pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 3 Job Planning Lines
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(100));

        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(100));

        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine3.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(100));

        // [WHEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Number of inventory pick activity header created for the job is 1
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        Assert.RecordCount(WarehouseActivityHeader, 1);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Inventory pick activities should be created.
        WarehouseActivityLinePick.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 3);
        VerifyWarehouseActivityLine(JobPlanningLine1);
        VerifyWarehouseActivityLine(JobPlanningLine2);
        VerifyWarehouseActivityLine(JobPlanningLine3);

        // [WHEN] Auto fill Qty to handle on Inventory Pick and Post it along with Job Journal
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify Job Planning Lines
        // [THEN] Verify Warehouse Entries
        // [THEN] Verify Job Ledger
        // [THEN] Verify Item Ledger Entries
        VerifyEntriesAfterPostingInvPick(Job, JobTask);
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLineHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreatePickForJobPlanningLinesWithPartialJobJnlPosting()
    var
        Item: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
        Line2QtyToPost: Decimal;
        Line3QtyToPost: Decimal;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 12] Create inventory pick for multiple job planning lines and partially posted Job Journal Lines.
        // [GIVEN] Inventory pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 3 Job Planning Lines with different document numbers.
        // [GIVEN] Job Planning Line 1 := Job Task T1: Type = Item, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandIntInRange(10, 100));

        // [GIVEN] Job Planning Line 2 := Job Task T1: Type = Item, Line Type = Budget. Qty to Transfer to Job Journal = Quantity - X;
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::"Budget", JobPlanningLine2.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandIntInRange(10, 100));
        JobPlanningLine2.Validate("Qty. to Transfer to Journal", LibraryRandom.RandInt(5));
        JobPlanningLine2.Modify(true);

        // [GIVEN] Job Planning Line 3 := Job Task T1: Type = Item, Line Type = Budget.
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::"Budget", JobPlanningLine3.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandIntInRange(10, 100));

        // [WHEN] Transfer the first two job planning lines to Job Journal and Post the Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        OpenRelatedJournalAndPost(JobPlanningLine1);
        JobPlanningLine1.Get(JobPlanningLine1."Job No.", JobPlanningLine1."Job Task No.", JobPlanningLine1."Line No."); //Refresh the job planning lines to have the latest information.
        JobPlanningLine2.Get(JobPlanningLine2."Job No.", JobPlanningLine2."Job Task No.", JobPlanningLine2."Line No.");

        Line2QtyToPost := JobPlanningLine2."Remaining Qty.";
        Line3QtyToPost := JobPlanningLine3."Remaining Qty.";

        // [WHEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Number of inventory pick activity header created for the job is 1
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        Assert.RecordCount(WarehouseActivityHeader, 1);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Inventory pick activities should be created for the remaining quantities. These include job planning line 2 (reduced quantity) and job planning line 3.
        WarehouseActivityLinePick.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);
        VerifyWarehouseActivityLine(JobPlanningLine2);
        VerifyWarehouseActivityLine(JobPlanningLine3);

        // [WHEN] Auto fill Qty to handle on Inventory Pick and Post it along with Job Journal
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify Job Planning Line
        // [THEN] Verify Warehouse Entries
        // [THEN] Verify Job Ledger
        // [THEN] Verify Item Ledger Entries
        //VerifyEntriesAfterPostingInvPick(Job, JobTask);
        VerifyItemLedgerEntry(JobPlanningLine2, -Line2QtyToPost);
        VerifyItemLedgerEntry(JobPlanningLine3, -Line3QtyToPost);
        VerifyJobLedgerEntry(JobPlanningLine2, Line2QtyToPost);
        VerifyJobLedgerEntry(JobPlanningLine3, Line3QtyToPost);
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickForJobPlanningLinesWithExistingJobJnlLinesDoesNotThrowError()
    var
        Item: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 13] Create inventory pick throws error when there are job journal lines already present for a job.

        // [GIVEN] Inventory pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 3 Job Planning Lines with different document numbers.
        // [GIVEN] Job Planning Line 1 := Job Task T1: Type = Item, Line Type = Budget.
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandIntInRange(10, 100));

        // [GIVEN] Job Planning Line 2 := Job Task T1: Type = Item, Line Type = Budget.
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::"Budget", JobPlanningLine2.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandIntInRange(10, 100));

        // [GIVEN] Job Planning Line 3 := Job Task T1: Type = Item, Line Type = Budget.
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::"Budget", JobPlanningLine3.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandIntInRange(10, 100));

        // [WHEN] Transfer the all job planning lines to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        // [WHEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Error is not thrown
        VerifyWarehouseActivityLine(JobPlanningLine1);
        VerifyWarehouseActivityLine(JobPlanningLine2);
        VerifyWarehouseActivityLine(JobPlanningLine3);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ModifyNotAllowedJobPlanningLineWithInventoryPick()
    var
        Item: Record Item;
        Item2: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        NewLocation: Record Location;
        NewBin: Record Bin;
        NewBinContent: Record "Bin Content";
        NewItemVariant: Record "Item Variant";
        NewItemUnitOfMeasure: Record "Item Unit of Measure";
        QtyInventory: Integer;
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 14] Some fields are not allowed to modified on Job Planning Lines when there is a linked warehouse activity line
        // [GIVEN] Inventory pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(NewItemVariant, Item."No.");
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(100));

        // [WHEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Inventory pick activity should be created.
        VerifyWarehouseActivityLine(JobPlanningLine);

        // [WHEN] Updating fields on Job Planning Lines
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.

        // [WHEN] Location
        ExpectedErrorMessage := StrSubstNo(FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption());
        LibraryWarehouse.CreateLocationWMS(NewLocation, true, false, true, false, false);
        asserterror JobPlanningLine.Validate("Location Code", NewLocation.Code);
        // [THEN] Modification is not possible.
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Quantity
        asserterror JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10) + JobPlanningLine.Quantity);
        // [THEN] Modification is not possible.
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Bin Code
        LibraryWarehouse.CreateBin(NewBin, LocationWithRequirePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(NewBin.FieldNo(Code), Database::Bin), '', '');
        LibraryWarehouse.CreateBinContent(NewBinContent, LocationWithRequirePickBinMandatory.Code, '', NewBin.Code, Item."No.", '', Item."Base Unit of Measure");
        asserterror JobPlanningLine.Validate("Bin Code", NewBin.Code);
        // [THEN] Modification is not possible.
        Assert.ExpectedError(StrSubstNo(FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption()));

        // [WHEN] Status.
        asserterror JobPlanningLine.Validate(Status, JobPlanningLine.Status::Completed);
        // [THEN] Modification is not possible.
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Variant Code.
        asserterror JobPlanningLine.Validate("Variant Code", NewItemVariant.Code);
        // [THEN] Modification is not possible.
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] No.
        LibraryInventory.CreateItem(Item2);
        asserterror JobPlanningLine.Validate("No.", Item2."No.");
        // [THEN] Modification is not possible.
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Unit of Measure Code.
        LibraryInventory.CreateItemUnitOfMeasureCode(NewItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(10, 100));
        asserterror JobPlanningLine.Validate("Unit of Measure Code", NewItemUnitOfMeasure.Code);
        // [THEN] Modification is not possible.
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Planning Due Date.
        asserterror JobPlanningLine.Validate("Planning Due Date", JobPlanningLine."Planning Due Date" + LibraryRandom.RandInt(10));
        // [THEN] Modification is not possible.
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Deleting job planning line
        asserterror JobPlanningLine.Delete(true);
        // [THEN] Deletion is not possible
        Assert.ExpectedError(StrSubstNo(DeletionNotPossibleErr, JobPlanningLine.TableCaption(), WarehouseActivityLinePick.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentNoOnJobPlanningLineIsInitializedToEmpty()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 15] "Document No." field on Job Planning Line is initialized to Empty.

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Job Planning Line is inserted
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Line No.", 1);
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Insert(true);

        // [THEN] 'Document No.' field is initialized to Job."No."
        JobPlanningLine.TestField("Document No.", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPickUsesJobNoAsDocumentNoOnLedgerEntries()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 16] if Document No. is filled with Job No. on ledger entries when 'Document No.' is not filled on the Job Planning Line.

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has planning line that require the item from a location where 'Require pick' = Yes and 'Bin mandatory' = Yes
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [GIVEN] 'Document No.' is empty
        JobPlanningLine.TestField("Document No.", '');

        // [WHEN] 'Usage Link' is set
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [WHEN] Create Inventory Pick for the Job and post it
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityHeader.FindFirst();

        // [WHEN] Auto fill Qty to handle on Inventory Pick and Post it along with Job Journal
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] No error is thrown and Job No. is used as the Document No.
        FindItemLedgerEntry(ItemLedgerEntry, JobPlanningLine."No.", JobPlanningLine."Job No.", JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        FindJobLedgerEntry(JobLedgerEntry, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Job No.", JobPlanningLine."No.");
        FindWarehouseEntry(WarehouseEntry, JobPlanningLine."Job No.", JobPlanningLine."Job No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPickUsesDocumentNoOnPlanningLineAsDocumentNoOnLedgerEntries()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
        QtyToUse: Integer;
        DocNo: Text;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 17] if Document No. is filled with Document No. on ledger entries when 'Document No.' is filled on the Job Planning Line.

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has planning line that require the item from a location where 'Require pick' = Yes and 'Bin mandatory' = Yes
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [GIVEN] 'Document No.' is not empty
        // [GIVEN] 'Usage Link' is set
        DocNo := LibraryUtility.GenerateRandomCode(JobPlanningLine.FieldNo("Document No."), Database::"Job Planning Line");
        JobPlanningLine.Validate("Document No.", DocNo);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [WHEN] Create Inventory Pick for the Job and post it
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityHeader.FindFirst();

        // [WHEN] Auto fill Qty to handle on Inventory Pick and Post it along with Job Journal
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] No error is thrown and Job No. is used as the Document No.
        FindItemLedgerEntry(ItemLedgerEntry, JobPlanningLine."No.", DocNo, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        FindJobLedgerEntry(JobLedgerEntry, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", DocNo, JobPlanningLine."No.");
        FindWarehouseEntry(WarehouseEntry, JobPlanningLine."Job No.", DocNo);
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLineHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ErrorWhenPostingJobJournalLineIfPickExists()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 18] Error is thrown when posting a Job Journal Line if there is a inventory pick present asociated to the job planning line
        // [GIVEN] Inventory pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [GIVEN] Create Job Journal Lines from Job Planning Line
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [THEN] Warn user effects of linked job journal line.
        asserterror OpenRelatedJournalAndPost(JobPlanningLine);
        Assert.ExpectedError('You cannot post usage for project number');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure NewPickDocCreatedAfterAnIncompletePickPosting()
    var
        Item: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 19] A new pick document can be created if remaining quantity is > 0
        // [GIVEN] Inventory pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine2.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [GIVEN] Do a incomplete inventory pick posting
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine2."Job Contract Entry No."); //This can uniquely identify the line
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get("Warehouse Activity Type"::"Invt. Pick", WarehouseActivityLinePick."No.");

        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage.WhseActivityLines.GoToRecord(WarehouseActivityLinePick);
        InventoryPickPage.WhseActivityLines."Qty. to Handle".SetValue(4);
        InventoryPickPage."P&ost".Invoke();

        InventoryPickPage.Close();

        // [GIVEN] Delete pick document without completing picks
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Create Inventory Pick action is invoked
        JobPlanningLine2.Find();
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] It succeeds and new pick lines are created
        VerifyWarehouseActivityLine(JobPlanningLine2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PickCannotBePostedIfTheBinContentIsEmpty()
    var
        Item: Record Item;
        SerialTrackedItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 20] Pick cannot be posted if the bin content is empty.
        // [GIVEN] Inventory pick relevant Location, normal item and serially tracked item with sufficient quantity in the inventory for a Bin Code
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSerialTrackedItem(SerialTrackedItem, false);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget, Bin Code = 3
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin3.Code, LibraryRandom.RandInt(10));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin3.Code, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] 2 Warehouse Activity Lines are created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);

        // [WHEN] Bin code is set to Bin Code 3.
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityLinePick."Bin Code" := Bin3.Code;
        WarehouseActivityLinePick.Modify();

        // [WHEN] Post Inventory Pick
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityHeader.FindFirst();

        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        asserterror InventoryPickPage."P&ost".Invoke();
        InventoryPickPage.Close();

        // [THEN] Error is thrown and item ledger entries are not created
        Assert.ExpectedError('Bin Content');
        Assert.IsFalse(FindItemLedgerEntry(ItemLedgerEntry, Item."No.", Job."No.", Job."No.", JobTask."Job Task No."), 'Item ledger entries should not be created.');
        Assert.IsFalse(FindItemLedgerEntry(ItemLedgerEntry, SerialTrackedItem."No.", Job."No.", Job."No.", JobTask."Job Task No."), 'Item ledger entries should not be created.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostingIfWarehouseTrackingIsEnabledForSerialTrackedItem()
    var
        Item: Record Item;
        SerialTrackedItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 22] Post successful if setrial number specified
        // [GIVEN] Inventory pick relevant Location, normal item and serially tracked item with sufficient quantity in the inventory for a Bin Code
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSerialTrackedItem(SerialTrackedItem, false);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        ItemLedgerEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", "Item Ledger Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.FindSet();

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, 2);

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] 2 Warehouse Activity Lines are created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);

        // [WHEN] Serial No. field is modified
        WarehouseActivityLinePick.FindFirst();
        asserterror WarehouseActivityLinePick.Validate("Serial No.", ItemLedgerEntry."Serial No.");

        // [THEN] Error is thrown
        Assert.ExpectedError('Warehouse item tracking is not enabled for No.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingEnabledForSNSpecific()
    var
        Item: Record Item;
        SerialTrackedItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 23.0] Items that require item tracking is skipped
        // [GIVEN] Inventory pick relevant Location, normal item and serially tracked item with sufficient quantity in the inventory for a Bin Code
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSerialTrackedItem(SerialTrackedItem, false);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        ItemLedgerEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", "Item Ledger Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.FindSet();

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, 2);

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Make sure 2 lines are created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);

        // [THEN] Warehouse Activity Line is created for the serially tracked item
        WarehouseActivityLinePick.SetRange("Item No.", SerialTrackedItem."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingEnabledForSNAndWMSSpecific()
    var
        Item: Record Item;
        SerialTrackedItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 23.1] SN and WMS specific item tracking is supported for inventory pick
        // [GIVEN] Inventory pick relevant Location, normal item and serially tracked item with sufficient quantity in the inventory for a Bin Code
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSerialTrackedItem(SerialTrackedItem, true);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        ItemLedgerEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", "Item Ledger Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.FindSet();

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, 2);

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Make sure 3 lines are created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 3);

        // [THEN] Warehouse activity line is created for the item with Serial No. tracking
        WarehouseActivityLinePick.SetRange("Item No.", SerialTrackedItem."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLineModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DocumentNoIsJobNoOnJobSetupIsRepectedWhileCreatingJobJnlFromPlanningTrue()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobSetup: Record "Jobs Setup";
        JobPlanningLines: TestPage "Job Planning Lines";
        JobJournal: TestPage "Job Journal";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 24] "Document No. Is Job No." on JobSetup is repected while creating job journal line from job planning line

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();

        // [GIVEN] Job Setup with 'Document No. as Job No.' = true
        JobSetup.Get();
        JobSetup."Document No. Is Job No." := true;
        JobSetup.Modify(true);
        ReInitializeJobSetup := true;

        // [GIVEN] Item with positive adjutment
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has planning line that require the item from a location where 'Require pick' = Yes and 'Bin mandatory' = Yes
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [WHEN] 'Qty to Tranfer to Journal' is set
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToUse);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [WHEN] Job Journal Line is created
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines.CreateJobJournalLines.Invoke();
        JobJournal.Trap();
        JobPlanningLines."&Open Job Journal".Invoke();

        // [THEN] Document No. field is filled with Job No.
        JobJournal."Document No.".AssertEquals(JobPlanningLine."Job No.");
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLineModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DocumentNoIsJobNoOnJobSetupIsRepectedWhileCreatingJobJnlFromPlanningFalse()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobSetup: Record "Jobs Setup";
        JobPlanningLines: TestPage "Job Planning Lines";
        JobJournal: TestPage "Job Journal";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 25] "Document No. Is Job No." on JobSetup is repected while creating job journal line from job planning line

        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();

        // [GIVEN] Job Setup with 'Document No. as Job No.' = false
        JobSetup.Get();
        JobSetup."Document No. Is Job No." := false;
        JobSetup.Modify(true);
        ReInitializeJobSetup := true;

        // [GIVEN] Item with positive adjutment
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which has planning line that require the item from a location where 'Require pick' = Yes and 'Bin mandatory' = Yes
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [WHEN] 'Qty to Tranfer to Journal' is set
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToUse);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);

        // [WHEN] Job Journal Line is created
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine);
        JobPlanningLines.CreateJobJournalLines.Invoke();
        JobJournal.Trap();
        JobPlanningLines."&Open Job Journal".Invoke();

        // [THEN] Document No. is remains empty
        JobJournal."Document No.".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWhseRequestForJobWithoutWInventoryPick()
    var
        Item: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobTask: Record "Job Task";
        WhseRequest: Record "Warehouse Request";
        LocationWithoutInvPick: Record Location;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Warehouse request is deleted when none of the locations on job planning line is inventory pick relevant. Test OnDelete, Validate triggers.
        // [GIVEN] An item with enough inventory on location with and without inventory pick required.
        Initialize();
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(LocationWithoutInvPick, false, false, false, false, false);

        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, 1000, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithoutInvPick.Code, '', 1000, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line for location without inventory pick.
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithoutInvPick.Code, '', QtyToUse);

        // [THEN] No Warehouse Request is created.
        WhseRequest.SetRange("Source No.", JobPlanningLine1."Job No.");
        Assert.RecordIsEmpty(WhseRequest);

        // [WHEN] Create a job planning line for location with inventory pick.
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyToUse);

        // [THEN] 1 Warehouse Request is created.
        WhseRequest.SetRange("Source No.", JobPlanningLine1."Job No.");
        WhseRequest.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        Assert.RecordCount(WhseRequest, 1);

        // [WHEN] Location on Job Planning Line 2 is updated to Location without inventory pick required
        JobPlanningLine2.Validate("Location Code", LocationWithoutInvPick.Code);
        JobPlanningLine2.Modify(true);

        // [THEN] The Warehouse Request is deleted.
        WhseRequest.Reset();
        WhseRequest.SetRange("Source No.", JobPlanningLine1."Job No.");
        Assert.RecordIsEmpty(WhseRequest);

        // [WHEN] Location on Job Planning Line 2 is updated to Location with inventory pick required
        JobPlanningLine2.Validate("Location Code", LocationWithRequirePickBinMandatory.Code);
        JobPlanningLine2.Modify(true);

        // [THEN] 1 Warehouse Request is created.
        WhseRequest.SetRange("Source No.", JobPlanningLine1."Job No.");
        WhseRequest.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        Assert.RecordCount(WhseRequest, 1);

        // [WHEN] Job Planning Line 2 is deleted
        JobPlanningLine2.Delete(true);

        // [THEN] The Warehouse Request is deleted.
        WhseRequest.Reset();
        WhseRequest.SetRange("Source No.", JobPlanningLine1."Job No.");
        Assert.RecordIsEmpty(WhseRequest);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BinCodeIsAutoFilledBasedOnAvailability()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventoryBin1: Integer;
        QtyInventoryBin2: Integer;
        QtyPlanningLine: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Post succeeds when selected bin on planning line does not have sufficient quantity
        // [GIVEN] Inventory pick relevant Location, item with insufficient quantity in one Bin and sufficient quantity in another Bin
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventoryBin1 := 1;
        QtyInventoryBin2 := 100;
        QtyPlanningLine := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventoryBin1, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, QtyInventoryBin2, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyPlanningLine);

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Make sure 2 lines are created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);

        // [WHEN] Inventory Pick is posted
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityHeader.FindFirst();

        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Error is not thrown and item ledger entries are created
        Assert.IsTrue(FindItemLedgerEntry(ItemLedgerEntry, Item."No.", Job."No.", Job."No.", JobTask."Job Task No."), 'Item ledger entries should be created.');
        Assert.RecordCount(ItemLedgerEntry, 2);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(-QtyPlanningLine, ItemLedgerEntry.Quantity, 'Sum of Quantity on Item Ledger Entries is incorrect.');

        // [THEN] Verify Warehouse Entries
        Assert.IsTrue(FindWarehouseEntry(WarehouseEntry, Job."No.", Job."No."), 'Warehouse entries not found');
        Assert.RecordCount(WarehouseEntry, 2);

        WarehouseEntry.SetRange("Bin Code", Bin1.Code);
        Assert.RecordCount(WarehouseEntry, 1);
        Assert.AreEqual(-QtyInventoryBin1, WarehouseEntry.Quantity, 'Quantity should be 1.');

        FindWarehouseEntry(WarehouseEntry, Job."No.", Job."No.");
        WarehouseEntry.SetRange("Bin Code", Bin2.Code);
        WarehouseEntry.FindFirst();
        Assert.RecordCount(WarehouseEntry, 1);
        Assert.AreEqual(-(QtyPlanningLine - QtyInventoryBin1), WarehouseEntry.Quantity, 'Quantity should be 9.');

        // [THEN] Verify Job Ledger Entries
        FindJobLedgerEntry(JobLedgerEntry, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Job No.", JobPlanningLine."No.");
        Assert.RecordCount(JobLedgerEntry, 2);

        JobLedgerEntry.SetRange("Bin Code", Bin1.Code);
        Assert.RecordCount(JobLedgerEntry, 1);
        Assert.AreEqual(QtyInventoryBin1, JobLedgerEntry.Quantity, 'Quantity should be 1.');

        FindJobLedgerEntry(JobLedgerEntry, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Job No.", JobPlanningLine."No.");
        JobLedgerEntry.SetRange("Bin Code", Bin2.Code);
        JobLedgerEntry.FindFirst();
        Assert.RecordCount(JobLedgerEntry, 1);
        Assert.AreEqual(QtyPlanningLine - QtyInventoryBin1, JobLedgerEntry.Quantity, 'Quantity should be 9.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BinSelectedOnPickLineIsUsedWhilePostingPickLines()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        InventoryPickPage: TestPage "Inventory Pick";
        QtyInventoryBin1: Integer;
        QtyInventoryBin2: Integer;
        QtyPlanningLine: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 20] Bin selected on pick line is used while posting pick lines
        // [GIVEN] Inventory pick relevant Location, item with sufficient quantity in the inventory on 2 bins
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventoryBin1 := 10;
        QtyInventoryBin2 := 100;
        QtyPlanningLine := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventoryBin1, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, QtyInventoryBin2, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyPlanningLine);

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Make sure 1 line is created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 1);

        // [GIVEN] Change the Bin
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityLinePick.Validate("Bin Code", Bin2.Code);
        WarehouseActivityLinePick.Modify(true);

        // [WHEN] Inventory Pick is posted
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityHeader.FindFirst();

        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify the bin code selected on pick lines is used for posting
        Assert.IsTrue(FindItemLedgerEntry(ItemLedgerEntry, Item."No.", Job."No.", Job."No.", JobTask."Job Task No."), 'Item ledger entries should be created.');
        Assert.RecordCount(ItemLedgerEntry, 1);

        FindWarehouseEntry(WarehouseEntry, Job."No.", Job."No.");
        WarehouseEntry.TestField("Bin Code", Bin2.Code);
        Assert.RecordCount(WarehouseEntry, 1);

        FindJobLedgerEntry(JobLedgerEntry, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Job No.", JobPlanningLine."No.");
        JobLedgerEntry.TestField("Bin Code", Bin2.Code);
        Assert.RecordCount(JobLedgerEntry, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreate,MessageHandler')]
    procedure GetBinContentInItemReclassificationForSerialSameLot()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        BinCode: array[2] of Code[20];
        LotNo: Code[50];
    begin
        // [SCENARIO 548400] Get Bin Content in Item Reclassification runs for both Serial Number Specific Tracking and FreeEntry Lot Number exists.
        Initialize();

        // [GIVEN] Create Item Tracking Code,
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);

        // [GIVEN] Create Item with Tracking Code.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Warehouse Location.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);

        // [GIVEN] Update Warehouse No Series in Warehouse Setup.
        UpdateWarehouseNoSeries();

        // [GIVEN] Create Number of Bins in a Location.
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandIntInRange(5, 10), false);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Find and store two Bins.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        BinCode[1] := Bin.Code;
        Bin.FindLast();
        BinCode[2] := Bin.Code;

        // [GIVEN] Create and Store Lot No.
        LotNo := LibraryERM.CreateNoSeriesCode();
        LibraryVariableStorage.Enqueue(LotNo);

        // [GIVEN] Create Item Journal Line and Validate Location, Bin Code, Unit Cost.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(2, 2));
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", BinCode[1]);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Open Item Tracking Code and assign Serial No. and Lot No.
        ItemJournalLine.OpenItemTrackingLines(false);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create Sales Line and Validate Location.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(2, 2));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Release Sales Document.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Line.
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesHeader."Document Type".AsInteger());
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Bin Code", BinCode[2]);
        WarehouseShipmentLine.Modify(true);

        // [GIVEN] Find Warehouse Shipment Header and Validate Bin Code.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        WarehouseShipmentHeader.Validate("Bin Code", BinCode[2]);
        WarehouseShipmentHeader.Modify(true);

        // [GIVEN] Release Warehouse Shipment.
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Create Warehouse Pick.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [GIVEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.FindLast();

        // [GIVEN] Find Warehouse Activity Header and update Registering No. Series.
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityHeader."Registering No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseActivityHeader.Modify(true);

        // [GIVEN] Register Warehouse Activity.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Create Item Journal Line and Validate Location, Bin Code, and Unit Cost.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(2, 2));
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", BinCode[1]);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Store Lot No.
        LibraryVariableStorage.Enqueue(LotNo);

        // [GIVEN] Open Item Tracking Lines and assign Serial No. and Lot No.
        ItemJournalLine.OpenItemTrackingLines(false);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Select Item Journal Template.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);

        // [GIVEN] Select Item Journal Batch.
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Transfer, ItemJournalTemplate.Name);

        // [GIVEN] Create Item Journal Line and Validate Posting Date.
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Posting Date", WorkDate());

        // [GIVEN] Find Bin Content.
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Bin Code", BinCode[1]);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();

        // [WHEN] Get Bin Content in Item Journal Line is executed.
        LibraryWarehouse.WhseGetBinContentFromItemJournalLine(BinContent, ItemJournalLine);

        // [THEN] Item Journal Line should have Item we created.
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Location Code", Location.Code);
        ItemJournalLine.FindLast();

        Assert.AreEqual(
            ItemJournalLine."Item No.",
            Item."No.",
            StrSubstNo(
                ItemReclassificationErr,
                Item."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,SelectItemTrackingLinesPageHandler')]
    procedure ItemTrackingPopulatedGetBinContentInItemReclassification()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        Location: Record Location;
        ItemJournalLines: TestPage "Item Journal Lines";
        BinCode: array[2] of Code[20];
    begin
        // [SCENARIO 561622] Item Tracking is populated by Get Bin Content in the Item Reclassification Journal.
        Initialize();

        // [GIVEN] Create Item Tracking Code.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);

        // [GIVEN] Create Item with Tracking Code.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Warehouse Location.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);

        // [GIVEN] Update Warehouse No Series in Warehouse Setup.
        UpdateWarehouseNoSeries();

        // [GIVEN] Create Number of Bins in a Location.
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandIntInRange(7, 10), false);

        // [GIVEN] Find and store two Bins.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        BinCode[1] := Bin.Code;
        Bin.FindLast();
        BinCode[2] := Bin.Code;

        // [GIVEN] Create Item Journal Line and Validate Location, Bin Code, Unit Cost.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, BinCode[1], LibraryRandom.RandIntInRange(6, 6));
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify(true);

        // [GIVEN] Open Item Tracking Code and assign Serial No. and Lot No.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        ItemJournalLines.OpenEdit();
        ItemJournalLines.GoToRecord(ItemJournalLine);
        ItemJournalLines."Item &Tracking Lines".Invoke();
        ItemJournalLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and Post Item Reclassification Journal.
        CreateAndPostItemReclassificationJournalLine(Item."No.", Location.Code, BinCode[1], BinCode[2]);

        // [GIVEN] Select Item Journal Template.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);

        // [GIVEN] Select Item Journal Batch.
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Transfer, ItemJournalTemplate.Name);

        // [GIVEN] Create Item Journal Line and Validate Posting Date.
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Posting Date", WorkDate());

        // [GIVEN] Find Bin Content.
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();

        // [WHEN] Get Bin Content in Item Journal Line is executed.
        LibraryWarehouse.WhseGetBinContentFromItemJournalLine(BinContent, ItemJournalLine);

        // [THEN] Find Item Journal Line.
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Location Code", Location.Code);
        ItemJournalLine.FindLast();

        // [THEN] Item Journal Line should have Item Tracking Code.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,ConfirmHandlerTrue')]
    procedure UpdateReservationAsSurplusWhenUpdateJobStatusAsOpen()
    var
        SNOnlyTrackedItem: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 564205] Check Reservation Entry when update Project Status from 'Quote' to 'Open' for SN tracked Item.
        Initialize();

        // [GIVEN] SN only tracked item
        CreateSerialTrackedItem(SNOnlyTrackedItem, false);

        // [GIVEN] A job with a task
        CreateQuoteJobWithJobTask(JobTask, Job);

        // [GIVEN] Create a job planning line.
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, SNOnlyTrackedItem."No.", LocationWithRequirePick.Code, '', 1);

        // [GIVEN] Assign Serial No. to the Job Planning Line
        LibraryVariableStorage.Enqueue(TrackingOption::"Assign Serial No.");
        JobPlanningLine.OpenItemTrackingLines();

        // [WHEN] Update Project Status from 'Quote' to 'Open'
        Job.Validate(Status, Job."Status"::Open);
        job.Modify(true);

        // [THEN] Reservation Entry should be created for the Job Planning Line
        Assert.IsTrue(FilterReserveationEntry(JobPlanningLine), ReservationEntryNotFoundErr);
    end;

    local procedure CreateDefaultWarehouseEmployee(var NewDefaultLocation: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange(Default, true);
        if WarehouseEmployee.FindFirst() then begin
            if WarehouseEmployee."Location Code" <> NewDefaultLocation.Code then begin
                WarehouseEmployee.Delete(true);
                LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, NewDefaultLocation.Code, true);
            end;
        end
        else
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, NewDefaultLocation.Code, true);
    end;

    local procedure CreateSerialTrackedItem(var Item: Record Item; WMSSpecific: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        if not WMSSpecific then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            ItemTrackingCode.Validate("SN Warehouse Tracking", false);
            ItemTrackingCode.Modify(true);
        end;
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Inv. Pick On Job Planning");
        LibrarySetupStorage.Restore();
        LibraryJob.DeleteJobJournalTemplate();

        if not IsInitialized then begin
            LibraryWarehouse.CreateLocationWMS(LocationWithRequirePickBinMandatory, true, false, true, false, false);
            LibraryWarehouse.CreateBin(Bin1, LocationWithRequirePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(Bin1.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateBin(Bin2, LocationWithRequirePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(Bin2.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateBin(Bin3, LocationWithRequirePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(Bin3.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateLocationWMS(LocationWithRequirePick, false, false, true, false, false);
        end;

        CreateDefaultWarehouseEmployee(LocationWithRequirePickBinMandatory);

        if ReInitializeJobSetup then begin
            DummyJobsSetup.Get();
            DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
            DummyJobsSetup."Apply Usage Link by Default" := true;
            DummyJobsSetup."Job Nos." := LibraryJob.GetJobTestNoSeries();
            DummyJobsSetup."Document No. Is Job No." := true;
            DummyJobsSetup.Modify();
            ReInitializeJobSetup := false;
        end;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Inv. Pick On Job Planning");

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        NoSeries.Get(LibraryJob.GetJobTestNoSeries());
        NoSeries."Manual Nos." := true;
        NoSeries.Modify();

        LibrarySetupStorage.Save(Database::"Inventory Setup");
        LibrarySetupStorage.Save(Database::"Purchases & Payables Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Inv. Pick On Job Planning");
    end;

    local procedure VerifyWarehouseActivityLine(JobPlanningLine: Record "Job Planning Line")
    var
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No."); //This can uniquely identify the line
        Assert.RecordIsNotEmpty(WarehouseActivityLinePick);
        if WarehouseActivityLinePick.FindSet() then
            repeat
                WarehouseActivityLinePick.TestField("Source No.", JobPlanningLine."Job No.");
                WarehouseActivityLinePick.TestField("Source Type", Database::"Job");
                WarehouseActivityLinePick.TestField("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
                WarehouseActivityLinePick.TestField("Activity Type", WarehouseActivityLinePick."Activity Type"::"Invt. Pick");
                WarehouseActivityLinePick.TestField("Location Code", JobPlanningLine."Location Code");
                WarehouseActivityLinePick.TestField("Item No.", JobPlanningLine."No.");
                WarehouseActivityLinePick.TestField(Quantity, JobPlanningLine."Remaining Qty.");
                WarehouseActivityLinePick.TestField("Qty. Handled", 0);
                WarehouseActivityLinePick.TestField("Bin Code", JobPlanningLine."Bin Code");
            until WarehouseActivityLinePick.Next() = 0;
    end;

    local procedure OpenJobAndCreateInventoryPick(Job: Record Job)
    begin
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);
    end;

    local procedure OpenRelatedJournalAndPost(JobPlanningLine: Record "Job Planning Line")
    var
        JobJournalPage: TestPage "Job Journal";
    begin
        OpenRelatedJobJournal(JobJournalPage, JobPlanningLine);
        JobJournalPage."P&ost".Invoke(); //Needs ConfirmHandlerTrue, MessageHandler
        JobJournalPage.Close();
    end;

    local procedure OpenRelatedJobJournal(var JobJournalPage: TestPage "Job Journal"; JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLinePage: TestPage "Job Planning Lines";
    begin
        JobPlanningLinePage.OpenEdit();
        JobPlanningLinePage.GoToRecord(JobPlanningLine);
        JobJournalPage.Trap();
        JobPlanningLinePage."&Open Job Journal".Invoke();
        JobPlanningLinePage.Close();
    end;

    local procedure TransferToJobJournalFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLinePage: TestPage "Job Planning Lines";
    begin
        JobPlanningLinePage.OpenEdit();
        JobPlanningLinePage.GoToRecord(JobPlanningLine);
        JobPlanningLinePage.CreateJobJournalLines.Invoke(); //Needs JobTransferJobPlanningLineHandler Handler
        JobPlanningLinePage.Close();
    end;

    local procedure AutoFillAndPostInventoryPickFromPage(JobPlanningLine: Record "Job Planning Line")
    var
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Invt. Pick", WarehouseActivityLinePick."No.");
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke(); //Needs confirmation handler
    end;

    local procedure VerifyEntriesAfterPostingInvPick(Job: Record Job; JobTask: Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        if JobPlanningLine.FindSet() then
            repeat
                JobPlanningLine.TestField("Remaining Qty.", 0);
                VerifyItemLedgerEntry(JobPlanningLine, -JobPlanningLine.Quantity);
                VerifyJobLedgerEntry(JobPlanningLine, JobPlanningLine.Quantity);
                VerifyWarehouseEntry(JobPlanningLine);
                AssertTempJobJournalLineIsDeleted(JobPlanningLine);
            until JobPlanningLine.Next() = 0;
    end;

    local procedure VerifyWarehouseEntry(JobPlanningLine: Record "Job Planning Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
        SumOfPostedQty: Decimal;
    begin
        WarehouseEntry.SetRange("Whse. Document No.", JobPlanningLine."Job No.");
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Job);
        WarehouseEntry.SetRange("Whse. Document Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseEntry.FindSet();
        repeat
            WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
            WarehouseEntry.TestField("Location Code", JobPlanningLine."Location Code");
            WarehouseEntry.TestField("Bin Code", JobPlanningLine."Bin Code");
            WarehouseEntry.TestField("Source Code", '');
            SumOfPostedQty += WarehouseEntry.Quantity
        until WarehouseEntry.Next() = 0;
        Assert.Equal(JobPlanningLine."Qty. Posted", -SumOfPostedQty);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; DocumentNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20]): Boolean
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Job No.", JobNo);
        ItemLedgerEntry.SetRange("Job Task No.", JobTaskNo);
        exit(ItemLedgerEntry.FindFirst());
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; DocumentNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20]; ExpectedQuantity: Decimal): Boolean
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Job No.", JobNo);
        ItemLedgerEntry.SetRange("Job Task No.", JobTaskNo);
        ItemLedgerEntry.SetRange(Quantity, ExpectedQuantity);
        exit(ItemLedgerEntry.FindFirst());
    end;

    local procedure VerifyItemLedgerEntry(JobPlanningLine: Record "Job Planning Line"; ExpectedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
    begin
        if not FindItemLedgerEntry(ItemLedgerEntry, JobPlanningLine."No.", JobPlanningLine."Job No.", JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", ExpectedQuantity) then
            Assert.AreEqual(ExpectedQuantity, TotalQuantity, StrSubstNo(SumValueUnequalErr, ItemLedgerEntry.TableCaption(), ItemLedgerEntry.FieldCaption(ItemLedgerEntry.Quantity)));
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobNo: Code[20]; TaskNo: Code[20]; DocumentNo: Code[20]; ItemNo: Code[20]): Boolean
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("No.", ItemNo);
        JobLedgerEntry.SetRange("Job Task No.", TaskNo);
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        exit(JobLedgerEntry.FindFirst());
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobNo: Code[20]; TaskNo: Code[20]; DocumentNo: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal): Boolean
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("No.", ItemNo);
        JobLedgerEntry.SetRange("Job Task No.", TaskNo);
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange(Quantity, ExpectedQuantity);
        exit(JobLedgerEntry.FindFirst());
    end;

    local procedure FindWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; JobNo: Code[20]; DocumentNo: Code[20]): Boolean
    begin

        WarehouseEntry.SetRange("Whse. Document No.", JobNo);
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Job);
        WarehouseEntry.SetRange("Source No.", DocumentNo);
        exit(WarehouseEntry.FindFirst());
    end;

    local procedure VerifyJobLedgerEntry(JobPlanningLine: Record "Job Planning Line"; ExpectedQuantity: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        TotalQuantity: Decimal;
    begin
        if not FindJobLedgerEntry(JobLedgerEntry, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Job No.", JobPlanningLine."No.", ExpectedQuantity) then
            Assert.AreEqual(ExpectedQuantity, TotalQuantity, StrSubstNo(SumValueUnequalErr, JobLedgerEntry.TableCaption(), JobLedgerEntry.FieldCaption(JobLedgerEntry.Quantity)));
    end;

    local procedure AssertTempJobJournalLineIsDeleted(JobPlanningLine: Record "Job Planning Line")
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Journal Template Name", '');
        JobJournalLine.SetRange("Journal Batch Name", '');
        JobJournalLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.RecordIsEmpty(JobJournalLine);
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job, CreateCustomer(''));  // Blank value for Currency Code.
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";

        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        exit(GLAccount."No.");
    end;

    local procedure CreateAndPostInvtAdjustmentWithUnitCost(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateJobPlanningLineWithData(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; Number: Code[20]; LocationCode: Code[10]; BinCode: Code[10]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, Type, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Number);
        JobPlanningLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            JobPlanningLine.Validate("Bin Code", BinCode);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
        Commit();
    end;

    local procedure UpdateWarehouseNoSeries()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        if WarehouseSetup.Get() then begin
            WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
            WarehouseSetup."Whse. Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
            WarehouseSetup.Modify(true);
        end else begin
            WarehouseSetup.Init();
            WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
            WarehouseSetup."Whse. Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
            WarehouseSetup.Insert(true);
        end;
    end;

    local procedure CreateAndPostItemReclassificationJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLines: TestPage "Item Journal Lines";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo, LibraryRandom.RandIntInRange(2, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("New Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", FromBinCode);
        ItemJournalLine.Validate("New Bin Code", ToBinCode);

        ItemJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        ItemJournalLines.OpenEdit();
        ItemJournalLines.GoToRecord(ItemJournalLine);
        ItemJournalLines."Item &Tracking Lines".Invoke();

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingToCreateMessageHandler(Message: Text[1024])
    begin
        if Message.Contains(NothingToCreateMsg) then
            LibraryVariableStorage.Enqueue(NothingToCreateMsg);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferJobPlanningLineHandler(var JobTransferJobPlanLine: TestPage "Job Transfer Job Planning Line")
    var
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
    begin
        if JobTransferJobPlanLine.JobJournalTemplateName.Value = '' then begin
            JobJournalTemplate.SetRange("Page ID", PAGE::"Job Journal");
            JobJournalTemplate.SetRange(Recurring, false);
            JobJournalTemplate.FindFirst();
            JobTransferJobPlanLine.JobJournalTemplateName.Value := JobJournalTemplate.Name;
        end else
            JobJournalTemplate.Get(JobTransferJobPlanLine.JobJournalTemplateName.Value);

        if JobTransferJobPlanLine.JobJournalBatchName.Value = '' then begin
            JobJournalBatch.SetRange("Journal Template Name", JobJournalTemplate.Name);
            JobJournalBatch.FindFirst();
            JobTransferJobPlanLine.JobJournalBatchName.Value := JobJournalBatch.Name;
        end;

        JobTransferJobPlanLine.OK().Invoke();
    end;

    local procedure CreateAndPostInvtAdjustmentWithSNTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.OpenItemTrackingLines(false); //ItemTrackingLinesAssignPageHandler required.
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateQuoteJobWithJobTask(var JobTask: Record "Job Task"; var Job: Record Job)
    begin
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate(Status, Job."Status"::Quote);
        job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure FilterReserveationEntry(JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetCurrentKey("Source Type", "Source Subtype", "Source ID");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source Subtype", 2);
        ReservationEntry.SetRange("Source ID", JobPlanningLine."Job No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", JobPlanningLine."No.");

        exit(not ReservationEntry.IsEmpty());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesAssignPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign &Serial No.".Invoke(); // AssignSerialNoEnterQtyPageHandler required.
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignSerialNoEnterQtyPageHandler(var EnterQuantityPage: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostPicksModalPageHandler(var InventoryPick: TestPage "Inventory Pick")
    var
        QtyToHandle: Integer;
    begin
        QtyToHandle := LibraryVariableStorage.DequeueInteger();
        InventoryPick.WhseActivityLines."Qty. to Handle".SetValue(QtyToHandle);
        InventoryPick."P&ost".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferJobPlanningLineModalPageHandler(var JobTransferJobPlanningLine: TestPage "Job Transfer Job Planning Line")
    begin
        JobTransferJobPlanningLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Lot: Variant;
    begin
        Lot := LibraryVariableStorage.DequeueText();
        ItemTrackingLines."Assign Serial No.".Invoke();
        ItemTrackingLines."Lot No.".SetValue(Lot);
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryRandom.RandIntInRange(2, 2));
    end;

    [ModalPageHandler]
    procedure EnterQuantityToCreate(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemReclassification: Boolean;
        VerifyItemTrackingCode: Boolean;
    begin
        ItemReclassification := LibraryVariableStorage.DequeueBoolean();
        VerifyItemTrackingCode := LibraryVariableStorage.DequeueBoolean();

        if not ItemReclassification then
            ItemTrackingLines."Assign &Lot No.".Invoke()
        else begin
            ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingLines."New Lot No.".SetValue(LibraryERM.CreateNoSeriesCode());
        end;

        if VerifyItemTrackingCode then
            Assert.AreNotEqual(ItemTrackingLines."ItemTrackingCode.Code".Value(), '', LotNoErr);

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectItemTrackingLinesPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;
}
