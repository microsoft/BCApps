codeunit 136318 "Whse. Pick On Job Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Warehouse Pick]
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        SourceBin: Record Bin;
        DestinationBin: Record Bin;
        LocationWithWhsePick: Record Location;
        LocationWithDirectedPutawayAndPick: Record Location;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        Assert: Codeunit Assert;
        QtyRemainsToBePickedErr: Label 'quantity of %1 remains to be picked', Comment = '%1 = 100';
        WhseCompletelyPickedErr: Label 'All of the items on the project planning lines are completely picked.';
        WhseNoItemsToPickErr: Label 'There are no items to pick on the project planning lines.';
        FieldMustNotBeChangedErr: Label 'must not be changed when a %1 for this %2 exists: ', Comment = '%1 = Table 1 caption, %2 = Table 2 caption';
        DeletionNotPossibleErr: Label 'The %1 cannot be deleted when a related %2 exists.', Comment = '%1 = Table 1 caption, %2 = Table 2 caption';
        OneWhsePickHeaderCreatedErr: Label 'Only one warehouse activity header created.';
        WarehousePickActionTypeTotalErr: Label 'Total number of %1 %2 for warehouse pick lines should be equal to %3', Comment = '%1 = Warehouse Activity Type, %2 = Pick, %3 = 100';
        WarehouseEntryTotalErr: Label 'Warehouse Entry for the warehouse pick should have %1 entries for %2', Comment = '%1 = 10, %2 = Bin Code';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('JobTransferFromJobPlanLineHandler')]
    procedure JobJournalCannotBePostedForIncompletePicks()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobPlanningLinePage: TestPage "Job Planning Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Job journal cannot be posted for job planning lines which are relevant for warehouse picks without completely picking all the items.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes, 'Require Shipment' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with planning line with item, location and a different bin code
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] Change quantity to transfer to journal to less than quantity
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToUse - 1);
        JobPlanningLine.Modify(true);

        // [WHEN] Create job journal line from job planning line
        JobPlanningLinePage.OpenEdit();
        JobPlanningLinePage.GoToRecord(JobPlanningLine);
        asserterror JobPlanningLinePage.CreateJobJournalLines.Invoke();

        // [THEN] Error: Qty X remains to be picked.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, JobPlanningLine."Qty. to Transfer to Journal"));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure JobJournalPostWithoutLinkToPlanningLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Posting of Job journal line with a job is possible if the journal line is not linked to any job planning line irrespective of completely picked.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes, 'Require Shipment' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with planning line with item, location and a different bin code
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] Create job journal line in job journal line for the given job task without the Link to the planning line.
        LibraryJob.CreateJobJournalLine("Job Line Type"::Budget, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate("Location Code", JobPlanningLine."Location Code");
        JobJournalLine.Validate("Bin Code", SourceBin.Code);
        JobJournalLine.Validate("Job Planning Line No.", 0);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobJournalLine.Modify(true);
        Commit(); //Require to save the Job Journal Template needed during posting.

        JobJournalLine.Modify(true);

        // [THEN] We can post job journal line without any errors.
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckJobJournalLineFieldsLinkingToPlanningLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Check for remaining quantity to be picked when manually creating Job Journal Line for a linked Job planning line.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes, 'Require Shipment' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with planning line with item, location and a different bin code
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] Create job journal line for the given job task with the Link to planning line with 0 quantity.
        LibraryJob.CreateJobJournalLine("Job Line Type"::Budget, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate("Location Code", JobPlanningLine."Location Code");
        JobJournalLine.Validate("Bin Code", SourceBin.Code);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No."); //Link to job planning line
        Commit();

        // [WHEN] Updating the quantity
        QtyToUse := LibraryRandom.RandInt(100);
        asserterror JobJournalLine.Validate(Quantity, QtyToUse);

        // [THEN] Error: Qty X remains to be picked.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, QtyToUse));

        // [WHEN] Modify the job journal line by removing link to the planning line and add some quantity.
        JobJournalLine.Validate("Job Planning Line No.", 0);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobJournalLine.Modify(true);

        // [WHEN] Add the link to an existing job planning line
        asserterror JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");

        // [THEN] Error: Qty X remains to be picked.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, JobJournalLine.Quantity));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickCannotBeCreatedForJobsThatAreNotOpen()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Warehouse pick can only be created of jobs that are in status Open.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = No
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job which is not Open and has planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        Job.Get(JobPlanningLine."Job No.");
        Job.Validate(Status, Job.Status::Planning);
        Job.Modify(true);

        // [WHEN] 'Create Warehouse Pick' action is invoked
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] Error is thrown validating the Job.Status
        Assert.ExpectedTestFieldError(Job.FieldCaption(Status), Format(Job.Status::Open));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue,AutoFillAndRegisterPickModalPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePicksCanBeRegisteredForAJob()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Register warehouse picks that are created for a Job.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [THEN] Pick Qty / Pick Qty (Base) = 0; Qty Picked / Qty Picked (Base) = 0 and Completely Picked = No
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLine(JobPlanningLine);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] Open Related Warehouse Pick Lines
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Autofill quantity and Register pick.
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in AutoFillAndRegisterPickModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, QtyToUse, QtyToUse, JobPlanningLine.Quantity, true);

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure PostJobAfterRegisteringWarehousePicks()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WarehouseEntry: Record "Warehouse Entry";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Post the registered warehouse picks created for a Job.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Autofill quantity and Register related warehouse pick.
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, QtyToUse, QtyToUse, JobPlanningLine.Quantity, true);

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);

        // [WHEN] Transfer to planning lines to job journal and post
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] New Warehouse Entry is created with negative adjustment
        VerifyWarehouseEntry(WarehouseEntry."Source Document"::"Job Jnl.", WarehouseEntry."Entry Type"::"Negative Adjmt.", JobPlanningLine."No.", JobPlanningLine."Location Code", JobPlanningLine."Bin Code", JobPlanningLine."Unit of Measure Code", -JobPlanningLine."Qty. to Transfer to Journal")
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobJnlQuantityNotGreaterThanQtyPickedWithBins()
    var
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Job journal line cannot have quantity more than picked quantity linked to the job planning line irrespective of the bin code.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes, 'Require Shipment' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with planning line with item, location and a different bin code
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Autofill quantity and Register related warehouse pick.
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.

        // [WHEN] Create job journal line in job journal line for the given job task with the Link to planning line.
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, "Job Line Type"::Budget, 1, JobJournalLine);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No."); //Link to job planning line
        JobJournalLine.Validate("Location Code", JobPlanningLine."Location Code");
        Commit();

        // [WHEN] SourceBin is assigned to the job journal line
        JobJournalLine.Validate("Bin Code", SourceBin.Code);
        JobJournalLine.Modify(true);

        // [WHEN] Update quantity on job journal line to more than picked quantity.
        QtyToUse += LibraryRandom.RandInt(100);
        asserterror JobJournalLine.Validate(Quantity, QtyToUse);

        // [THEN] Error: Qty X remains to be picked.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, QtyToUse - JobPlanningLine."Qty. Picked"));

        // [WHEN] DestinationBin is assigned to the job journal line from the job planning line.
        JobJournalLine."Bin Code" := JobPlanningLine."Bin Code";
        JobJournalLine.Modify(true);

        // [WHEN] Update quantity on job journal line to more than picked quantity.
        QtyToUse += LibraryRandom.RandInt(100);
        asserterror JobJournalLine.Validate(Quantity, QtyToUse);

        // [THEN] Error: Qty X remains to be picked.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, QtyToUse - JobPlanningLine."Qty. Picked"));
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ModifyNotAllowedJobPlanningLineWithWarehousePick()
    var
        Item: Record Item;
        Item2: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        NewLocation: Record Location;
        NewBin: Record Bin;
        NewItemVariant: Record "Item Variant";
        NewItemUnitOfMeasure: Record "Item Unit of Measure";
        QtyInventory: Integer;
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Some fields are not allowed to be modified on Job Planning Lines when there is a linked warehouse pick line.
        // [GIVEN] Warehouse pick relevant Location and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(NewItemVariant, Item."No.");
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(100));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Updating fields on Job Planning Lines
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        ExpectedErrorMessage := StrSubstNo(FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption());

        // [WHEN] Create new Location with Bin Mandatory = Yes and Require Pick = Yes and update Location Code
        LibraryWarehouse.CreateLocationWMS(NewLocation, true, false, true, false, false);
        asserterror JobPlanningLine.Validate("Location Code", NewLocation.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Quantity
        asserterror JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10) + JobPlanningLine.Quantity);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Bin Code
        LibraryWarehouse.CreateBin(NewBin, LocationWithWhsePick.Code, LibraryUtility.GenerateRandomCode(NewBin.FieldNo(Code), Database::Bin), '', '');
        asserterror JobPlanningLine.Validate("Bin Code", NewBin.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(StrSubstNo(FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption()));

        // [WHEN] Update Status
        asserterror JobPlanningLine.Validate(Status, JobPlanningLine.Status::Completed);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Variant Code
        asserterror JobPlanningLine.Validate("Variant Code", NewItemVariant.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update No.
        LibraryInventory.CreateItem(Item2);
        asserterror JobPlanningLine.Validate("No.", Item2."No.");
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Unit of Measure Code
        LibraryInventory.CreateItemUnitOfMeasureCode(NewItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(10, 100));
        asserterror JobPlanningLine.Validate("Unit of Measure Code", NewItemUnitOfMeasure.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Planning Due Date
        asserterror JobPlanningLine.Validate("Planning Due Date", JobPlanningLine."Planning Due Date" + LibraryRandom.RandInt(10));
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Deleting job planning line
        asserterror JobPlanningLine.Delete(true);
        // [THEN] Deletion is not possible
        Assert.ExpectedError(StrSubstNo(DeletionNotPossibleErr, JobPlanningLine.TableCaption(), WarehouseActivityLinePick.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler')]
    [Scope('OnPrem')]
    procedure PicksCreatedIrrespectiveOfJobPlanningStatus()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        QtyInventory: Integer;
        QtyToUse: Integer;
        RandomStatus: Enum "Job Planning Line Status";
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Job planning line status is not respected when Creating warehouse pick for a Job .
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] Job planning line status is set randomly
        RandomStatus := Enum::"Job Planning Line Status".FromInteger(RandomStatus.Ordinals.Get(LibraryRandom.RandInt(JobPlanningLine.Status.Ordinals.Count())));
        JobPlanningLine.Validate(Status, RandomStatus);
        JobPlanningLine.Modify(true);
        Commit(); //Needed as Report "Whse.-Source - Create Document" is later executed modally.

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLine(JobPlanningLine);
    end;

    // Partial and the increase quantity on planning line after posting pick.

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,JobTransferFromJobPlanLineHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateWhsePickForMultipleJobTasks()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ResourceNo: Code[20];
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Create Warehouse pick for multiple job tasks with different type of job planning lines and then verify the records created.
        // [GIVEN] Warehouse pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        ResourceNo := LibraryResource.CreateResourceNo();

        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");

        // [GIVEN] Create Multiple job tasks and a Job Planning Line for every job task with the common location and Bin Code 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T2: Type = Resource, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, ResourceNo, LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T3: Type = Item, Line Type = Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Billable, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T4: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Number of warehouse pick activities created for the job is 2 * 2 = 4. These include "Action Type" Take and Place for task T1 and task T4.
        WarehouseActivityLinePick.SetRange("Source No.", JobPlanningLine."Job No.");
        Assert.RecordCount(WarehouseActivityLinePick, 4);

        // [THEN] Pick Qty is updated
        // [THEN] Verify data in warehouse activity lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable");
        Assert.RecordCount(JobPlanningLine, 2);
        if JobPlanningLine.FindSet() then
            repeat
                VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, 0, JobPlanningLine.Quantity, false);
                VerifyWarehousePickActivityLine(JobPlanningLine);
            until JobPlanningLine.Next() = 0;

        // [WHEN] Auto fill Qty to handle on Warehouse Pick
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [WHEN] Transfer lines to job journal for the T1 and T4 job planning lines and post
        JobPlanningLine.FindSet();
        repeat
            TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
            OpenRelatedJournalAndPost(JobPlanningLine);
        until JobPlanningLine.Next() = 0;

        // [THEN] Verify Job Planning Lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobPlanningLine, 4);
        JobPlanningLine.FindSet();
        repeat
            if (JobPlanningLine.Type = JobPlanningLine.Type::Item) and ((JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::Budget) or (JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::"Both Budget and Billable")) then
                VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, true)
            else begin
                JobPlanningLine.TestField("Qty. Picked", 0);
                JobPlanningLine.TestField("Qty. Picked (Base)", 0);
                JobPlanningLine.TestField("Completely Picked", false);
                JobPlanningLine.TestField("Qty. Posted", 0);
            end;
        until JobPlanningLine.Next() = 0;

        // [THEN] Verify Warehouse Entries
        JobTask.Reset();
        JobTask.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobTask, 4);
        if JobTask.FindSet() then
            repeat
                VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
            until JobTask.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('JobTransferFromJobPlanLineHandler,WhseSrcCreateDocReqHandler,MessageHandler,RegisterPickForOneModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateAnotherPickForPartialJobJournalLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] It is possible to Create warehouse pick for job with an existing entry in job journal line for partially picked items.
        // [GIVEN] Warehouse pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandIntInRange(11, 100));

        // [GIVEN] Warehouse Picks Are Created
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Fill partial quantity and Register pick.
        QtyToUse := LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(QtyToUse);
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in RegisterPickForOneModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Job planning lines picked quantity is updated correctly
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity - QtyToUse, JobPlanningLine.Quantity - QtyToUse, QtyToUse, QtyToUse, JobPlanningLine.Quantity, false);

        // [WHEN] Create Job Journal Lines from Job Planning Line for the partially picked quantity.
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToUse);
        JobPlanningLine.Modify(true);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [WHEN] Auto fill and try to post the remaining Warehouse Picks for the Job
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [THEN] No error is thrown
        // [THEN] Job planning lines picked quantity is updated correctly
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.

        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, JobPlanningLine.Quantity, JobPlanningLine.Quantity, JobPlanningLine.Quantity, true);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue')]
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
        // [SCENARIO] Show Nothing to create message if Warehouse pick is created again after posting the initial pick.
        // [GIVEN] Warehouse pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Auto fill Qty to handle on Warehouse Pick and Register Pick, but do not post job journal line
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [WHEN] Create Warehouse Pick for the Job again.
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] Nothing to handle error message is shown as the item was completely picked.
        Assert.ExpectedError(WhseCompletelyPickedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickErrWhenThereIsNoQtyToPick()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
        ResourceNo: Code[20];
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Show nothing to create message if Warehouse pick is created job planning lines with 0 quantity along with a job planning line of type resource with some quantity.
        // [GIVEN] Warehouse pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line with 0 quantity.
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, 0);
        // [GIVEN] Job Planning Line for Job Task T1: Type = Resource, Line Type = Budget and some quantity
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Resource, ResourceNo, LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] Nothing to handle error message is shown as there are no items to be picked.
        Assert.ExpectedError(WhseNoItemsToPickErr);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickAgainAfterAddingAnotherJobTask()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader1: Record "Warehouse Activity Header";
        WarehouseActivityHeader2: Record "Warehouse Activity Header";
        WarehouseActivityLinePick1: Record "Warehouse Activity Line";
        WarehouseActivityLinePick2: Record "Warehouse Activity Line";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Create Warehouse Pick again after adding another Job Task to same Job.
        // [GIVEN] Warehouse pick relevant Location, item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] 1st Warehouse Pick created
        VerifyWarehousePickActivityLine(JobPlanningLine);
        WarehouseActivityLinePick1.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick1.FindFirst();

        WarehouseActivityHeader1.Get(WarehouseActivityHeader1.Type::Pick, WarehouseActivityLinePick1."No.");

        // [WHEN] Create a new Job Planning Line for a new Job Task T2: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] 2nd Warehouse pick with created.
        VerifyWarehousePickActivityLine(JobPlanningLine);
        WarehouseActivityLinePick2.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick2.FindFirst();

        WarehouseActivityHeader2.Get(WarehouseActivityHeader2.Type::Pick,
        WarehouseActivityLinePick2."No.");

        //[THEN] Two separate warehouse activity headers are created
        Assert.AreNotEqual(WarehouseActivityHeader1."No.", WarehouseActivityHeader2."No.", OneWhsePickHeaderCreatedErr);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue')]
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
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Create and register warehouse picks for a job with 1 job task and multiple job planning lines.
        // [GIVEN] Warehouse pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 3 Job Planning Lines
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(100));

        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(100));

        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine3.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(100));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Number of warehouse pick activity header created for the job is 1
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine1."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        WarehouseActivityHeader.TestField("Location Code", DestinationBin."Location Code");

        // [THEN] Warehouse pick activities should be created.
        Clear(WarehouseActivityLinePick);
        WarehouseActivityLinePick.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 3 * 2); //2 for each job planning line
        VerifyWarehousePickActivityLine(JobPlanningLine1);
        VerifyWarehousePickActivityLine(JobPlanningLine2);
        VerifyWarehousePickActivityLine(JobPlanningLine3);

        // [WHEN] Auto fill Qty to handle on Warehouse Pick and Post it along with Job Journal
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine1);

        // [THEN] Verify Warehouse Entries
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CannotCreatePickWhenJobPlanningLineIsFullyPosted()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        Location: Record Location;
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Cannot create pick when job planning line is fully posted.
        // [GIVEN] Location L, resource R and item I with sufficient quantity in the inventory.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', LibraryRandom.RandInt(100));

        // [GIVEN] Job Journal Line is created and posted from the Job Planning Line.
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [WHEN] Create Warehouse Pick for the Job
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] Error: All of the items on the job planning lines are completely picked.
        Assert.ExpectedError(WhseCompletelyPickedErr);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CreatePickCreatesPickForRemainingQtyOnJobPlanningLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        Location: Record Location;
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Create pick creates pick for remaining qty on job planning line.
        // [GIVEN] Location L, resource R and item I with sufficient quantity in the inventory.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);

        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', LibraryRandom.RandInt(100));

        // [GIVEN] Job Journal Line is created from the Job Planning Line and partially posted.
        JobPlanningLine."Qty. to Transfer to Journal" := JobPlanningLine.Quantity - 1;
        JobPlanningLine.Modify();
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);
        JobPlanningLine.Find();

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Number of warehouse pick activity header created for the job is 1
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        WarehouseActivityHeader.TestField("Location Code", Location.Code);

        // [THEN] Pick quantity is equal to the remaining quantity on the planning line
        VerifyWarehousePickActivityLine(JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CreateWhsePickForJobOnLocationWithPickOptional()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        Location: Record Location;
        QtyInventory: Integer;
    begin
        // [BUG 459828]  WhsePick/Jobs- system calculates Qty To Pick wrong
        // [SCENARIO] Create pick calculates Qty to Pick while considering what was consumed (with and without picks)
        Initialize();

        // [GIVEN] Location L with Picking not required, resource R and item I with sufficient quantity in the inventory.
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job.
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Line with qty. of 2
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', 2);

        // [WHEN] Job Journal Line with qty 1 is created and partially posted.
        JobPlanningLine."Qty. to Transfer to Journal" := 1;
        JobPlanningLine.Modify();
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Qty. Picked is updated to 1 as Qty. Picked (0) < Qty. Posted (1)
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 1);
        JobPlanningLine.TestField("Qty. Picked", 1);

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");

        // [THEN] Pick quantity is 1
        Assert.AreEqual(1, WarehouseActivityLinePick.Quantity, 'Expected Qty To Pick to be 1 after using item 1 without pick out of 2');

        // [GIVEN] The pick is registered
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] The quantity on the Job Planning Line is changed to 3
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.Validate(Quantity, 3);
        JobPlanningLine.Modify();

        // [WHEN] Job Journal Line with qty 1 is created and partially posted.
        JobPlanningLine."Qty. to Transfer to Journal" := 1;
        JobPlanningLine.Modify();
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Qty. Picked is updated to 2 as Qty. Picked (1) < Qty. Posted (2)
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 2);
        JobPlanningLine.TestField("Qty. Picked", 2);

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");

        // [THEN] The quantity of the pick is 1 (One was used w.o. pick. One was used with pick. One is left to pick)
        Assert.AreEqual(1, WarehouseActivityLinePick.Quantity, 'Expected Qty to pick to be 1, since only 1 item is left to be used.');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CreateWhsePickForJobOnLocationWithPickOptionalPartialPosting()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        Location: Record Location;
        QtyInventory: Integer;
    begin
        // [BUG 459828]  WhsePick/Jobs- system calculates Qty To Pick wrong
        // [SCENARIO] Create pick is allowed only for quantity not yet picked or consumed. Register Pick, Partially post job planning line and update job planning line quantity and create pick.
        Initialize();

        // [GIVEN] Location L with Picking not required, resource R and item I with sufficient quantity in the inventory.
        LibraryInventory.CreateItem(Item);
        QtyInventory := 100;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job.
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Line with qty. of 2
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', 2);

        // [WHEN] Register Pick for 2 Quantity
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Qty. Picked is updated to 2
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 0);
        JobPlanningLine.TestField("Qty. Picked", 2);

        // [GIVEN] Update the Job Planning Line Quantity to 10
        JobPlanningLine.Validate(Quantity, 10);

        // [WHEN] Transfer and Partially Post 4 quantities for the planning line
        JobPlanningLine.Validate("Qty. to Transfer to Journal", 4);
        JobPlanningLine.Modify();
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Qty. Picked is updated to 4 as Qty. Picked (2) < Qty. Posted (4)
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 4);
        JobPlanningLine.TestField("Qty. Picked", 4);

        // [WHEN] Create warehouse pick
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();

        // [THEN] The max available quantity for picking is total quantity (10) - Qty. Picked (4) - Pick Qty. (0) = 6
        Assert.AreEqual(6, WarehouseActivityLinePick.Quantity, 'Expected Qty to pick to be 6, since 6 quantity is left to be picked.');

        // [GIVEN] Delete the warehouse pick document without registering.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Transfer and Partially Post 3 more quantities for the planning line
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.Validate("Qty. to Transfer to Journal", 3);
        JobPlanningLine.Modify();
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Qty. Picked is updated to 7 as Qty. Picked (4) < Qty. Posted (7)
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 7);
        JobPlanningLine.TestField("Qty. Picked", 7);

        // [WHEN] Create warehouse pick
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();

        // [THEN] The max available quantity for picking is total quantity (10) - Qty. Picked (7) - Pick Qty. (0) = 3
        Assert.AreEqual(3, WarehouseActivityLinePick.Quantity, 'Expected Qty to pick to be 3, since 3 quantity is left to be picked.');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CreateWhsePickNotAllowedForConsumedItemOnJobPlanningLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        Location: Record Location;
        QtyInventory: Integer;
    begin
        // [BUG 459828]  WhsePick/Jobs- system calculates Qty To Pick wrong
        // [SCENARIO] Create pick is allowed only for quantity not yet picked or consumed. It is not possible to register pick for consumed items. Register Partial Pick, Completely post job planning line and try creating pick.
        Initialize();

        // [GIVEN] Location L with Picking not required, resource R and item I with sufficient quantity in the inventory.
        LibraryInventory.CreateItem(Item);
        QtyInventory := 100;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job.
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Line with qty. of 10
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', 10);

        // [WHEN] Register Pick for 7 Quantity
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityLinePick.Validate("Qty. to Handle", 7);
        WarehouseActivityLinePick.Modify();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Qty. Picked is updated to 7
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 0);
        JobPlanningLine.TestField("Qty. Picked", 7);

        // [WHEN] Transfer and Post all the quantity on the planning line
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Qty. Picked is updated to 10 as Qty. Picked (7) < Qty. Posted (10)
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 10);
        JobPlanningLine.TestField("Qty. Picked", 10);

        // [WHEN] Create new warehouse pick
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] Error: All of the items on the job planning lines are completely picked.
        Assert.ExpectedError(WhseCompletelyPickedErr);

        // [WHEN] Register warehouse pick from existing pick document
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Registering pick for the consumed document is not allowed.
        Assert.ExpectedError('is partially or completely consumed');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CreateWhsePickForJobOnLocationWithPickOptionalAndPickQty()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        Location: Record Location;
        QtyInventory: Integer;
    begin
        // [BUG 459828]  WhsePick/Jobs- system calculates Qty To Pick wrong
        // [SCENARIO] Create pick is allowed only for quantity not yet picked or consumed. Partially Register Pick, Partially post job planning line and update job planning line quantity and create pick.
        Initialize();

        // [GIVEN] Location L with Picking not required, resource R and item I with sufficient quantity in the inventory.
        LibraryInventory.CreateItem(Item);
        QtyInventory := 100;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job.
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Line with qty. of 10
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', 10);

        // [GIVEN] Register Pick for 2 Quantity
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityLinePick.Validate("Qty. to Handle", 2);
        WarehouseActivityLinePick.Modify();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Qty. Picked is updated to 2
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 0);
        JobPlanningLine.TestField("Qty. Picked", 2);

        // [WHEN] Transfer and Partially Post 7 quantities for the planning line
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.Validate("Qty. to Transfer to Journal", 7);
        JobPlanningLine.Modify();
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);
        JobPlanningLine.FindFirst();

        // [THEN] Outstanding Pick Quantity is 8
        JobPlanningLine.CalcFields("Pick Qty. (Base)");
        Assert.AreEqual(8, JobPlanningLine."Pick Qty. (Base)", 'Expected "Pick Qty. (Base)" to be 8.');

        // [THEN] Qty. Picked is updated to 7 as Qty. Picked (2) < Qty. Posted (7)
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 7);
        JobPlanningLine.TestField("Qty. Picked", 7);

        // [WHEN] Create warehouse pick
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] There is nothing more to pick.
        Assert.ExpectedError('Nothing');

        // [WHEN] Update the Job Planning Line Quantity to 15
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        asserterror JobPlanningLine.Validate(Quantity, 15);

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError('Quantity must not be changed');

        // [GIVEN] Delete the warehouse pick document without registering.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Post the remaining 3 quantities for the planning line
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);
        JobPlanningLine.FindFirst();

        // [THEN] Qty. Picked is updated to 10 as Qty. Picked (7) < Qty. Posted (10)
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField("Qty. Posted", 10);
        JobPlanningLine.TestField("Qty. Picked", 10);

        // [WHEN] Update the Job Planning Line Quantity to 15
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.Validate(Quantity, 15);
        JobPlanningLine.Modify();

        // [WHEN] Create warehouse pick
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();

        // [THEN] The max available quantity for picking is total quantity (15) - Qty. Picked (10) - Pick Qty. (0) = 5
        Assert.AreEqual(5, WarehouseActivityLinePick.Quantity, 'Expected Qty to pick to be 5, since 5 quantity is left to be picked.');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure PicksCanBeRegisteredForLocWithoutRequirePickAndShip()
    var
        Item: Record Item;
        Location1: Record Location;
        Location2: Record Location;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Creation of warehouse picks is possible for job planning line with location without require shipment and require pick.
        // [GIVEN] Non warehouse pick relevant Location, and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job. Location1 without require pick and require ship. Location2 with only require Pick.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location1, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(Location2, false, false, true, false, false);
        Location2."Job Consump. Whse. Handling" := Location2."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location2.Modify(true);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location1.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location2.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 2 Job Planning Lines with Location1, Location2
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", Location1.Code, '', LibraryRandom.RandInt(100));

        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, Item."No.", Location2.Code, '', LibraryRandom.RandInt(100));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick activity lines are created for the all the Job Planning Lines
        VerifyWarehousePickActivityLine(JobPlanningLine1);
        VerifyWarehousePickActivityLine(JobPlanningLine2);

        // [WHEN] Autofill quantity and Register related warehouse pick for location 1.
        CreateDefaultWarehouseEmployee(Location1);
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine1);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine1.Get(JobPlanningLine1."Job No.", JobPlanningLine1."Job Task No.", JobPlanningLine1."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine1, 0, 0, JobPlanningLine1.Quantity, JobPlanningLine1.Quantity, JobPlanningLine1.Quantity, true);

        // [WHEN] Transfer to planning lines to job journal and post
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] No error is thrown.

        // [WHEN] Autofill quantity and Register related warehouse pick for location 2.
        CreateDefaultWarehouseEmployee(Location2);
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine2);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine2.Get(JobPlanningLine2."Job No.", JobPlanningLine2."Job Task No.", JobPlanningLine2."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine2, 0, 0, JobPlanningLine2.Quantity, JobPlanningLine2.Quantity, JobPlanningLine2.Quantity, true);

        // [WHEN] Transfer to planning lines to job journal and post
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        OpenRelatedJournalAndPost(JobPlanningLine2);

        // [THEN] No error is thrown.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreatePickReqHandler,ConfirmHandlerTrue,AutoFillAndRegisterPickModalPageHandler,PickSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndRegisterWhsePicksUsingPickWorksheet()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        PickWorksheetPage: TestPage "Pick Worksheet";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Register warehouse picks that are created for a Job using pick worksheet.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);
        JobPlanningLine.AutoReserve();

        // [THEN] Pick Qty / Pick Qty (Base) = 0; Qty Picked / Qty Picked (Base) = 0 and Completely Picked = No
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler
        Commit(); //Needed as CreatePick report is executed modally.

        // [THEN] Warehouse Worksheet lines are created.
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Job);
        WhseWorksheetLine.SetRange("Whse. Document No.", JobTask."Job No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordCount(WhseWorksheetLine, 1);

        // [WHEN] Pick Worksheet is used to create the pick documents
        PickWorksheetPage.CreatePick.Invoke();
        PickWorksheetPage.Close();

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLine(JobPlanningLine);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] Open Related Warehouse Pick Lines
        Job.Get(JobPlanningLine."Job No.");
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Autofill quantity and Register pick.
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in AutoFillAndRegisterPickModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, QtyToUse, QtyToUse, JobPlanningLine.Quantity, true);

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreatePickReqHandler,PickSelectionModalPageHandler,ItemTrackingLinesModalPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryHandler')]
    procedure CreateAndRegisterWhsePicksWithItemTrackingUsingPickWorksheet()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PickWorksheetPage: TestPage "Pick Worksheet";
        SerialNos: List of [Code[50]];
        SerialNo: Code[50];
        Qty: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO 459118] Create and register warehouse picks using pick worksheet for job planning line with item tracking.
        Initialize();
        Qty := 2;

        // [GIVEN] Location with required shipment and pick.
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Serial no.-tracked item.
        CreateSerialTrackedItem(Item, true);

        // [GIVEN] Post 2 serial nos. "S1" and "S2" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty);
        LibraryVariableStorage.Enqueue(0);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        GetListOfPostedSerialNos(SerialNos, Item."No.");

        // [GIVEN] Job, job task, and job planning line for 2 pcs.
        // [GIVEN] Select serial nos. "S1" and "S2" on the job planning line.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(
          JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.",
          Location.Code, '', Qty);
        LibraryVariableStorage.Enqueue(1);
        JobPlanningLine.OpenItemTrackingLines();

        // [GIVEN] Open pick worksheet and pull the job planning line using "Get Warehouse Documents".
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke();

        // [WHEN] Create pick from pick worksheet.
        Commit();
        PickWorksheetPage.CreatePick.Invoke();
        PickWorksheetPage.Close();

        // [THEN] Warehouse pick is created.
        // [THEN] Serial numbers "S1" and "S2" are selected on the pick lines.
        WarehouseActivityLine.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        foreach SerialNo in SerialNos do begin
            WarehouseActivityLine.SetRange("Serial No.", SerialNo);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.TestField(Quantity, 1);
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PickSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure CannotCreatePicksUsingPickWorksheetForNonInventoryItems()
    var
        NonInventoryItem: Record Item;
        ServiceItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobTask: Record "Job Task";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PickWorksheetPage: TestPage "Pick Worksheet";
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Cannot create warehouse picks for job planning lines with non-inventory items, Resource and GL Account without having to create picks.
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

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line for the non-inventory, service item, resource, GL account and item with whs tracking enabled.
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, NonInventoryItem."No.", LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ServiceItem."No.", LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine3.Type::Resource, ResourceNo, LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine4.Type::"G/L Account", GLAccountNo, LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine1."Job No.");
        LibraryVariableStorage.Enqueue(LocationWithWhsePick.Code);
        asserterror PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler 

        // [THEN] No warehouse worksheet lines are created.
        Assert.ExpectedError('no Warehouse Worksheet Lines created');
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Job);
        WhseWorksheetLine.SetRange("Whse. Document No.", JobTask."Job No.");
        Assert.RecordIsEmpty(WhseWorksheetLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickRequestIsDeletedOnJobCompletion()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WhsePickRequest: Record "Whse. Pick Request";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Related Warehouse Pick Request should be deleted on completion of the job
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Add multiple job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [THEN] Warehouse Pick Request is created for the job
        WhsePickRequest.SetRange("Document No.", JobPlanningLine."Job No.");
        WhsePickRequest.SetRange("Document Subtype", 0);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        Assert.RecordCount(WhsePickRequest, 1);

        // [WHEN] Job status is changed to complete
        Job.Get(JobPlanningLine."Job No.");
        Job.Validate(Status, Job.Status::Completed);

        // [THEN] Related Warehouse Pick Request is deleted
        Assert.RecordIsEmpty(WhsePickRequest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickRequestIsDeletedOnJobDeletion()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WhsePickRequest: Record "Whse. Pick Request";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Related Warehouse Pick Request should be deleted on deleting the job
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        LibraryInventory.CreateItem(Item);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Add multiple job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [THEN] Warehouse Pick Request is created for the job
        WhsePickRequest.SetRange("Document No.", JobPlanningLine."Job No.");
        WhsePickRequest.SetRange("Document Subtype", 0);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        Assert.RecordCount(WhsePickRequest, 1);

        // [WHEN] Job is deleted
        Job.Get(JobPlanningLine."Job No.");
        Job.Delete(true);

        // [THEN] Related Warehouse Pick Request is deleted
        Assert.RecordIsEmpty(WhsePickRequest);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CannotPostJobJnlAfterUpgradingLocationToWhsePick()
    var
        LocationSilver: Record Location;
        Bin1: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Job journal posting is not allowed after upgrading the location to require warehouse pick.
        // [GIVEN] Location that is not warehouse pick relevant, item with available inventory in that location with a bin code
        Initialize();
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin1, LocationSilver.Code, LibraryUtility.GenerateRandomCode(Bin1.FieldNo(Code), DATABASE::Bin), '', '');
        LibraryWarehouse.CreateBin(Bin2, LocationSilver.Code, LibraryUtility.GenerateRandomCode(Bin2.FieldNo(Code), DATABASE::Bin), '', '');
        LibraryInventory.CreateItem(Item);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationSilver.Code, Bin1.Code, 1000, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Job is created with a Job Planning Line of type Budget and Item with some quantity available at the location
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationSilver.Code, Bin2.Code, LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Job Journal Line is created from the Job Planning Line.
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [WHEN] Location is updated to require Pick and Require Shipment.
        LocationSilver.Validate("Require Shipment", true);
        LocationSilver.Validate("Require Pick", true);
        LocationSilver.Validate("Job Consump. Whse. Handling", "Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        LocationSilver.Modify(true);

        // [WHEN] Job Journal Line is posted.
        asserterror OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Error is expected as not enough quantity is picked for that item.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, JobPlanningLine.Quantity));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CreateJobJnlForNonInventoryTypesWithoutPicking()
    var
        NonInventoryItem: Record Item;
        ServiceItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Create job journal lines from job planning lines with non-inventory items, Resource and GL Account without having to create picks.
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

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line for the non-inventory, service item, resource and GL account.
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, NonInventoryItem."No.", LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ServiceItem."No.", LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine3.Type::Resource, ResourceNo, LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine4.Type::"G/L Account", GLAccountNo, LocationWithWhsePick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Transfer job planning lines to job journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine4);

        // [THEN] No error is thrown and 4 job journal lines are created.
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        Assert.RecordCount(JobJournalLine, 4);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure PostJobAfterRegisteringWarehousePicksWithoutBin()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        LocationWMSWithoutBin: Record Location;
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Post the registered warehouse picks created for a Job without Bin.
        // [GIVEN] An item with enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = No
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(LocationWMSWithoutBin, false, false, true, false, true);
        CreateDefaultWarehouseEmployee(LocationWMSWithoutBin);

        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWMSWithoutBin.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWMSWithoutBin.Code, '', QtyToUse);

        // [THEN] Pick Qty / Pick Qty (Base) = 0; Qty Picked / Qty Picked (Base) = 0 and Completely Picked = No
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLine(JobPlanningLine);

        // [WHEN] Autofill quantity and Register related warehouse pick.
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, QtyToUse, QtyToUse, JobPlanningLine.Quantity, true);

        // [THEN] Warehouse entry should not be created.
        asserterror VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);

        // [WHEN] Transfer to planning lines to job journal and post
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] No error is thrown.   
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhsePicksCreatedForJobWithItemTrackingWithoutBin()
    var
        Item: Record Item;
        LocationWMS: Record Location;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Warehouse picks can be created for items with SN tracking without Bin.
        // [GIVEN] An item with SN tracking and enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = No
        Initialize();
        CreateSerialTrackedItem(Item, true);
        LibraryWarehouse.CreateLocationWMS(LocationWMS, false, false, true, false, true);
        CreateDefaultWarehouseEmployee(LocationWMS);

        QtyInventory := 50;
        CreateAndPostInvtAdjustmentWithSNTracking(Item."No.", LocationWMS.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line with the SN tracked item
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWMS.Code, '', QtyToUse);

        // [THEN] Pick Qty / Pick Qty (Base) = 0; Qty Picked / Qty Picked (Base) = 0 and Completely Picked = No
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created and nothing to handle error is not thrown.
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhsePicksCreatedForJobWithItemTrackingWithBin()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Warehouse picks can be created for items with SN tracking with bin.
        // [GIVEN] An item with SN tracking and enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        CreateSerialTrackedItem(Item, true);

        QtyInventory := 50;
        CreateAndPostInvtAdjustmentWithSNTracking(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line with the SN tracked item
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created and there is nothing to handle error is not thrown.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue,AutoFillAndRegisterPickModalPageHandler,ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler')]
    [Scope('OnPrem')]
    procedure WhsePicksCanBeRegisteredForJobWithItemTrackingWithBin()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Job: Record Job;
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Warehouse picks can be created for items with SN tracking with bin.
        // [GIVEN] An item with SN tracking and enough inventory on location with 'Require pick' = Yes and 'Bin mandatory' = Yes
        Initialize();
        CreateSerialTrackedItem(Item, true);

        QtyInventory := 5;
        CreateAndPostInvtAdjustmentWithSNTracking(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line with the SN tracked item
        QtyToUse := 5;
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLineWithSN(JobPlanningLine);

        // [WHEN] Assign Serial Numbers on Warehouse Pick Lines
        AssignSNWhsePickLines(JobPlanningLine);

        // [WHEN] Open Related Warehouse Pick Lines
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Autofill quantity and Register pick.
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in AutoFillAndRegisterPickModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, true);

        // [THEN] Reservation Entries are created.
        VerifyWhsePickReservationEntry(JobPlanningLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWhsePickRequestForJobWithoutWarehousePick()
    var
        Item: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobTask: Record "Job Task";
        WhsePickRequest: Record "Whse. Pick Request";
        LocationWithoutWhsePick: Record Location;
        QtyToUse: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Warehouse picks request is deleted when none of the locations on job planning line is warehouse pick relevant. Test OnDelete, Validate triggers.
        // [GIVEN] An item with enough inventory on location with and without warehouse pick required.
        Initialize();
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(LocationWithoutWhsePick, false, false, false, false, false);
        LocationWithoutWhsePick."Job Consump. Whse. Handling" := Enum::"Job Consump. Whse. Handling"::"No Warehouse Handling";
        LocationWithoutWhsePick.Modify();

        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, 1000, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithoutWhsePick.Code, '', 1000, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line for location without warehouse pick.
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithoutWhsePick.Code, '', QtyToUse);

        // [THEN] No Warehouse Pick Request is created.
        WhsePickRequest.SetRange("Document No.", JobPlanningLine1."Job No.");
        Assert.RecordIsEmpty(WhsePickRequest);

        // [WHEN] Create a job planning line for location with warehouse pick.
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, QtyToUse);

        // [THEN] 1 Warehouse Pick Request is created.
        WhsePickRequest.SetRange("Document No.", JobPlanningLine1."Job No.");
        WhsePickRequest.SetRange("Location Code", LocationWithWhsePick.Code);
        Assert.RecordCount(WhsePickRequest, 1);

        // [WHEN] Location on Job Planning Line 2 is updated to Location without warehouse pick required
        JobPlanningLine2.Validate("Location Code", LocationWithoutWhsePick.Code);
        JobPlanningLine2.Modify(true);

        // [THEN] The Warehouse Pick Request is deleted.
        WhsePickRequest.Reset();
        WhsePickRequest.SetRange("Document No.", JobPlanningLine1."Job No.");
        Assert.RecordIsEmpty(WhsePickRequest);

        // [WHEN] Location on Job Planning Line 2 is updated to Location with warehouse pick required
        JobPlanningLine2.Validate("Location Code", LocationWithWhsePick.Code);
        JobPlanningLine2.Modify(true);

        // [THEN] 1 Warehouse Pick Request is created.
        WhsePickRequest.SetRange("Document No.", JobPlanningLine1."Job No.");
        WhsePickRequest.SetRange("Location Code", LocationWithWhsePick.Code);
        Assert.RecordCount(WhsePickRequest, 1);

        // [WHEN] Job Planning Line 2 is deleted
        JobPlanningLine2.Delete(true);

        // [THEN] The Warehouse Pick Request is deleted.
        WhsePickRequest.Reset();
        WhsePickRequest.SetRange("Document No.", JobPlanningLine1."Job No.");
        Assert.RecordIsEmpty(WhsePickRequest);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WarehouseRequestRestoredWhenReopeningJob()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseRequest: Record "Warehouse Request";
        Location: Record Location;
        BinSource: Record Bin;
        BinDestination: Record Bin;
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Warehouse requests should be restored when changing job status from complete, 
        // otherwise we cannot create a pick.
        Initialize();

        // [GIVEN] A location requiring bin & pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(
            BinSource,
            Location.Code,
            LibraryUtility.GenerateRandomCode(BinSource.FieldNo(Code), Database::Bin),
            '',
            ''
        );
        LibraryWarehouse.CreateBin(
            BinDestination,
            Location.Code,
            LibraryUtility.GenerateRandomCode(BinDestination.FieldNo(Code), Database::Bin),
            '',
            ''
        );

        // [GIVEN] An item.
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(
            Item."No.", Location.Code, BinSource.Code, QtyInventory, LibraryRandom.RandDec(10, 2)
        );

        // [GIVEN] A job with a job task
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Adding a job planning line
        CreateJobPlanningLineWithData(
            JobPlanningLine,
            JobTask,
            "Job Planning Line Line Type"::Budget,
            JobPlanningLine.Type::Item, Item."No.",
            Location.Code,
            BinDestination.Code,
            LibraryRandom.RandInt(100)
        );

        // [THEN] A warehouse request is created.
        WarehouseRequest.SetRange("Source No.", Job."No.");
        Assert.AreEqual(1, WarehouseRequest.Count(), 'Expected warehouse request to exist.');

        // [WHEN] Marking job as complete.
        Job.Validate(Status, Job.Status::Completed);

        // [THEN] The warehouse request is deleted.
        WarehouseRequest.SetRange("Source No.", Job."No.");
        Assert.AreEqual(0, WarehouseRequest.Count(), 'Expected warehouse request to be deleted.');

        // [WHEN] Marking job as open.
        Job.Validate(Status, Job.Status::Open);

        // [THEN] A warehouse request is created.
        WarehouseRequest.SetRange("Source No.", Job."No.");
        Assert.AreEqual(1, WarehouseRequest.Count(), 'Expected warehouse request to exist.');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotDeleteOrCompleteJobWithWhseActivityLines()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ExpectedErrorMessage: Text;
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Try to delete or complete the job for which outstanding warehouse picks exists.
        // [GIVEN] Warehouse pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithWhsePick.Code, SourceBin.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Lines
        CreateJobPlanningLineWithData(
            JobPlanningLine,
            JobTask,
            "Job Planning Line Line Type"::Budget,
            JobPlanningLine.Type::Item,
            Item."No.",
            LocationWithWhsePick.Code,
            DestinationBin.Code,
            LibraryRandom.RandInt(100)
        );

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Job status is changed to complete
        Job.Get(JobPlanningLine."Job No.");

        asserterror Job.Validate(Status, Job.Status::Completed);

        // [THEN] Status cannot be changed to completed because outstanding warehouse pick exists for the job
        ExpectedErrorMessage := StrSubstNo(
            FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption()
        );
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Job is deleted
        asserterror Job.Delete(true);

        // [THEN] Job cannot be deleted because outstanding warehouse pick exists for the job 
        ExpectedErrorMessage := StrSubstNo(
            DeletionNotPossibleErr, JobPlanningLine.TableCaption(), WarehouseActivityLinePick.TableCaption()
        );
        Assert.ExpectedError(ExpectedErrorMessage);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PickSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure CannotChangeStatusOrDeleteJobWhenWhseWorksheetLinesExist()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        PickWorksheetPage: TestPage "Pick Worksheet";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Create pick from warehouse worksheet should fail if job is deleted or completed.
        // [GIVEN] Warehouse pick relevant Location, resource R and item I with sufficient quantity in the inventory for a Bin Code.
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 1000;
        CreateAndPostInvtAdjustmentWithUnitCost(
            Item."No.",
            LocationWithWhsePick.Code,
            SourceBin.Code,
            QtyInventory,
            LibraryRandom.RandDec(10, 2)
        );
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Lines
        CreateJobPlanningLineWithData(
            JobPlanningLine,
            JobTask,
            "Job Planning Line Line Type"::Budget,
            JobPlanningLine.Type::Item,
            Item."No.",
            LocationWithWhsePick.Code,
            DestinationBin.Code,
            LibraryRandom.RandInt(100)
        );

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler
        PickWorksheetPage.Close();

        // [WHEN] Job status is changed to complete.
        Job.Get(JobPlanningLine."Job No.");
        asserterror Job.Validate(Status, Job.Status::Completed);

        // [THEN] An error is thrown.
        Assert.ExpectedError('Status must not be changed when a Whse. Worksheet');

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler
        PickWorksheetPage.Close();

        // [WHEN] Job is deleted.
        asserterror Job.Delete(true);

        // [THEN] An error is thrown.
        Assert.ExpectedError('The Project Planning Line cannot be deleted when a related Whse. Worksheet');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCardJobToBinUI()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Zone: Record Zone;
        LocationCard: TestPage "Location Card";
    begin
        // [FEATURE] 430026 Location -> To-Job Bin Code
        // [SCENARIO] Location Card UI To-Job Bin Code is enabled for Bin Mandatory and also for Directed put-away and Pick.
        // [GIVEN] Location with Bin Mandatory = False.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Bin1 is setup for to the location.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateRandomCode(Bin[1].FieldNo(Code), Database::Bin), '', '');
        Commit(); //Needed to execute statements after the expected errors.

        // [WHEN] To-Job Bin code on Location is set to Bin1.
        asserterror Location.Validate("To-Job Bin Code", Bin[1].Code);

        // [THEN] Error: Bin Mandatory must be true.
        Assert.ExpectedError(Location.FieldCaption(Location."Bin Mandatory"));

        // [WHEN] Open Location Card.
        LocationCard.OpenEdit();
        LocationCard.GoToRecord(Location);

        // [THEN] To-Job Bin Code must be disabled.
        Assert.IsFalse(LocationCard."To-Job Bin Code".Enabled(), 'To-Job Bin Code must not be enabled as Bin Mandatory is false');

        // [WHEN] Bin Mandatory is set to true.
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        // [THEN] To-Job Bin Code must be enabled.
        LocationCard.GoToRecord(Location);
        Assert.IsTrue(LocationCard."To-Job Bin Code".Enabled(), 'To-Job Bin Code must be enabled as Bin Mandatory is true');

        // [THEN] Bin[1] can be set as To-Job Bin Code.
        LocationCard."To-Job Bin Code".SetValue(Bin[1].Code);

        // [WHEN] Directed Put-Away and Pick is set to true.
        LocationCard."Directed Put-away and Pick".SetValue(true);

        // [THEN] To-Job Bin Code must be enabled for Directed Put-Away and Pick location.
        Assert.IsTrue(LocationCard."To-Job Bin Code".Enabled(), 'To-Job Bin Code must be enabled as Directed Put-away and Pick is enabled');

        // [THEN] To-Job Bin Code value is retained.
        Assert.AreEqual(Bin[1].Code, LocationCard."To-Job Bin Code".Value(), 'To-Job Bin Code must retain value as Directed Put-away and Pick is enabled');
        LocationCard.Close();

        // [WHEN] Setting Bin[2] as To-Job Bin Code.
        LibraryWarehouse.CreateZone(Zone, 'ZONE', Location.Code, LibraryWarehouse.SelectBinType(false, false, false, false), '', '', 0, false);
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateRandomCode(Bin[2].FieldNo(Code), Database::Bin), Zone.Code, Zone."Bin Type Code");

        Location.Get(Location.Code);
        Location.Validate("To-Job Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [THEN] To-Job Bin Code value is updated.
        Assert.AreEqual(Bin[2].Code, Location."To-Job Bin Code", 'To-Job Bin Code must update value as Directed Put-away and Pick is enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationToJobBinIsUsedForItemJobPlanningLine()
    var
        Item: Record Item;
        Location: Record Location;
        Bin1: Record Bin;
        ToJobBin: Record Bin;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 430026 Location -> To-Job Bin Code
        // [SCENARIO] To-Job Bin Code is used when creating job planning line.
        // [GIVEN] Location with Bin Mandatory and Item I
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create 1 Job task
        CreateJobWithJobTask(JobTask);

        // [GIVEN] To-Job Bin code on Location is set to ''.
        Location.Validate("To-Job Bin Code", '');

        // [WHEN] Create Job Planning Line Type: Item
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', LibraryRandom.RandInt(100));

        // [THEN] Job Planning Line has no bin.
        JobPlanningLine.TestField("Bin Code", '');

        // [GIVEN] Add sufficient quantity in the inventory for item for the given Location and Bin Code 1.
        QtyInventory := 10;
        LibraryWarehouse.CreateBin(Bin1, Location.Code, LibraryUtility.GenerateRandomCode(Bin1.FieldNo(Code), Database::Bin), '', '');
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", Location.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        // [WHEN] Create Job Planning Line Type: Item
        Clear(JobPlanningLine);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', LibraryRandom.RandInt(100));

        // [THEN] Based on availability, Bin1 is selected as the Bin Code for the Job Planning Line.
        JobPlanningLine.TestField("Bin Code", Bin1.Code);

        // [GIVEN] ToJobBin is added to the location.
        LibraryWarehouse.CreateBin(ToJobBin, Location.Code, LibraryUtility.GenerateRandomCode(ToJobBin.FieldNo(Code), Database::Bin), '', '');

        // [WHEN] To-Job Bin code on Location is set to ToJobBin.Code.
        Location.Validate("To-Job Bin Code", ToJobBin.Code);
        Location.Modify(true);

        // [WHEN] Create Job Planning Line Type: Item
        Clear(JobPlanningLine);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", Location.Code, '', LibraryRandom.RandInt(100));

        // [THEN] Bin code on Job Planning Line = ToJobBin
        JobPlanningLine.TestField("Bin Code", ToJobBin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationToJobBinIsIgnoredForNonItemJobPlanningLine()
    var
        NonInventoryItem: Record Item;
        ServiceItem: Record Item;
        Location: Record Location;
        ToJobBin: Record Bin;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] 430026 Location -> To-Job Bin Code
        // [SCENARIO] To-Job Bin Code is not used when creating job planning line for non-inventory items, resource and GL account.
        // [GIVEN] Location with Bin Mandatory and Item I
        // [GIVEN] A Job.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Non-Inventory type of item
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] Service type of item
        LibraryInventory.CreateServiceTypeItem(ServiceItem);

        // [GIVEN] Resource
        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] G/L account
        GLAccountNo := CreateGLAccount();

        // [GIVEN] Create 1 Job task
        CreateJobWithJobTask(JobTask);

        // [GIVEN] To-Job Bin code on Location is set to ToJobBin.Code.
        LibraryWarehouse.CreateBin(ToJobBin, Location.Code, LibraryUtility.GenerateRandomCode(ToJobBin.FieldNo(Code), Database::Bin), '', '');
        Location.Validate("To-Job Bin Code", ToJobBin.Code);
        Location.Modify(true);

        // [WHEN] Create Job Planning Line for Non-Inventory Item
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, NonInventoryItem."No.", Location.Code, '', LibraryRandom.RandInt(100));

        // [THEN] Job Planning Line has no bin.
        JobPlanningLine.TestField("Bin Code", '');

        // [WHEN] Create Job Planning Line for Service Item
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, ServiceItem."No.", Location.Code, '', LibraryRandom.RandInt(100));

        // [THEN] Job Planning Line has no bin.
        JobPlanningLine.TestField("Bin Code", '');

        // [WHEN] Create Job Planning Line for a Resource
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Resource, ResourceNo, Location.Code, '', LibraryRandom.RandInt(100));

        // [THEN] Job Planning Line has no bin.
        JobPlanningLine.TestField("Bin Code", '');

        // [WHEN] Create Job Planning Line for GL account
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::"G/L Account", GLAccountNo, Location.Code, '', LibraryRandom.RandInt(100));

        // [THEN] Job Planning Line has no bin.
        JobPlanningLine.TestField("Bin Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectedPutAwayAndPickIsSupported()
    var
        Item: Record Item;
        Location: Record Location;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        LocationCard: TestPage "Location Card";
    begin
        // [SCENARIO] Location with Directed Put-away and Pick is supported for Job.
        // [GIVEN] Location with Directed Put-away and Pick
        // [GIVEN] A Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LocationCard.OpenEdit();
        LocationCard.GoToRecord(Location);
        LocationCard."Directed Put-away and Pick".SetValue(true);
        LocationCard.Close();

        // [GIVEN] Create 1 Job task
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Job Planning Line Type: Item
        LibraryJob.CreateJobPlanningLine("Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [WHEN] Add location with Directed Put-away and Pick
        JobPlanningLine.Validate("Location Code", Location.Code);

        // [THEN] Location is updated
        Assert.AreEqual(JobPlanningLine."Location Code", Location.Code, 'Location with Directed Put-away and Pick must be supported for Job Planning Line');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    procedure CreateAndRegisterPickForReservedJobPlanningLine()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 446213] Create pick from reserved job planning line.
        Initialize();

        // [GIVEN] Post inventory to a location with required shipment and pick.
        LibraryInventory.CreateItem(Item);
        CreateAndPostInvtAdjustmentWithUnitCost(
          Item."No.", LocationWithWhsePick.Code, SourceBin.Code, LibraryRandom.RandIntInRange(20, 40), 0);

        // [GIVEN] Create job, job task, and job planning line.
        // [GIVEN] Auto reserve the job planning line from the inventory.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(
          JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget,
          JobPlanningLine.Type::Item, Item."No.", LocationWithWhsePick.Code, DestinationBin.Code, LibraryRandom.RandInt(10));
        JobPlanningLine.AutoReserve();

        // [WHEN] Create warehouse pick.
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] The pick has been created.
        JobPlanningLine.Find();
        JobPlanningLine.CalcFields("Pick Qty.");
        JobPlanningLine.TestField("Pick Qty.", JobPlanningLine.Quantity);

        // [THEN] The pick can be successfully registered.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        JobPlanningLine.Find();
        JobPlanningLine.TestField("Qty. Picked", JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue,AutoFillAndRegisterPickModalPageHandler')]
    procedure WarehousePicksCanBeRegisteredForAJob_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Register warehouse picks that are created for a Job. Cannot change Bin Code.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [THEN] Pick Qty / Pick Qty (Base) = 0; Qty Picked / Qty Picked (Base) = 0 and Completely Picked = No
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLine(JobPlanningLine);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] Open Related Warehouse Pick Lines
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Autofill quantity and Register pick.
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in AutoFillAndRegisterPickModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, QtyToUse, QtyToUse, JobPlanningLine.Quantity, true);

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    procedure PostJobAfterRegisteringWarehousePicks_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseEntry: Record "Warehouse Entry";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Post the registered warehouse picks created for a Job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Autofill quantity and Register related warehouse pick.
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, QtyToUse, QtyToUse, JobPlanningLine.Quantity, true);

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);

        // [WHEN] Transfer to planning lines to job journal and post
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] New Warehouse Entry is created with negative adjustment
        VerifyWarehouseEntry(WarehouseEntry."Source Document"::"Job Jnl.", WarehouseEntry."Entry Type"::"Negative Adjmt.", JobPlanningLine."No.", JobPlanningLine."Location Code", JobPlanningLine."Bin Code", JobPlanningLine."Unit of Measure Code", -JobPlanningLine."Qty. to Transfer to Journal")
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue')]
    procedure JobJnlQuantityNotGreaterThanQtyPickedWithBins_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        BinContent: Record "Bin Content";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Job journal line cannot have quantity more than picked quantity linked to the job planning line irrespective of the bin code.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        BinContent.SetRange("Location Code", LocationWithDirectedPutawayAndPick.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();

        // [GIVEN] A job with planning line with item, location and a different bin code
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Autofill quantity and Register related warehouse pick.
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.

        // [WHEN] Create job journal line in job journal line for the given job task with the Link to planning line.
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, "Job Line Type"::Budget, 1, JobJournalLine);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No."); //Link to job planning line
        JobJournalLine.Validate("Location Code", JobPlanningLine."Location Code");
        Commit();

        // [WHEN] SourceBin is assigned to the job journal line
        JobJournalLine.Validate("Bin Code", BinContent."Bin Code");
        JobJournalLine.Modify(true);

        // [WHEN] Update quantity on job journal line to more than picked quantity.
        QtyToUse += LibraryRandom.RandInt(100);
        asserterror JobJournalLine.Validate(Quantity, QtyToUse);

        // [THEN] Error: Qty X remains to be picked.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, QtyToUse - JobPlanningLine."Qty. Picked"));

        // [WHEN] DestinationBin is assigned to the job journal line from the job planning line.
        JobJournalLine."Bin Code" := JobPlanningLine."Bin Code";
        JobJournalLine.Modify(true);

        // [WHEN] Update quantity on job journal line to more than picked quantity.
        QtyToUse += LibraryRandom.RandInt(100);
        asserterror JobJournalLine.Validate(Quantity, QtyToUse);

        // [THEN] Error: Qty X remains to be picked.
        Assert.ExpectedError(StrSubstNo(QtyRemainsToBePickedErr, QtyToUse - JobPlanningLine."Qty. Picked"));
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    procedure ModifyNotAllowedJobPlanningLineWithWarehousePick_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Item2: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        NewLocation: Record Location;
        NewBin: Record Bin;
        NewItemVariant: Record "Item Variant";
        NewItemUnitOfMeasure: Record "Item Unit of Measure";
        Zone: Record Zone;
        QtyInventory: Integer;
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Some fields are not allowed to be modified on Job Planning Lines when there is a linked warehouse pick line.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(NewItemVariant, Item."No.");
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(100));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Updating fields on Job Planning Lines
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        ExpectedErrorMessage := StrSubstNo(FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption());

        // [WHEN] Create new Location with Bin Mandatory = Yes and Require Pick = Yes
        LibraryWarehouse.CreateLocationWMS(NewLocation, true, false, true, false, false);
        asserterror JobPlanningLine.Validate("Location Code", NewLocation.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Create new Location with Bin Mandatory = Yes and Require Pick = Yes and update Location Code
        asserterror JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10) + JobPlanningLine.Quantity);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Bin Code
        LibraryWarehouse.CreateZone(Zone, 'ZONE', LocationWithDirectedPutawayAndPick.Code, LibraryWarehouse.SelectBinType(false, false, false, false), '', '', 0, false);
        LibraryWarehouse.CreateBin(NewBin, LocationWithDirectedPutawayAndPick.Code, LibraryUtility.GenerateRandomCode(NewBin.FieldNo(Code), Database::Bin), Zone.Code, Zone."Bin Type Code");
        asserterror JobPlanningLine.Validate("Bin Code", NewBin.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(StrSubstNo(FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption()));

        // [WHEN] Update Status
        asserterror JobPlanningLine.Validate(Status, JobPlanningLine.Status::Completed);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Variant Code
        asserterror JobPlanningLine.Validate("Variant Code", NewItemVariant.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update No.
        LibraryInventory.CreateItem(Item2);
        asserterror JobPlanningLine.Validate("No.", Item2."No.");
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Unit of Measure Code
        LibraryInventory.CreateItemUnitOfMeasureCode(NewItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(10, 100));
        asserterror JobPlanningLine.Validate("Unit of Measure Code", NewItemUnitOfMeasure.Code);
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Update Planning Due Date
        asserterror JobPlanningLine.Validate("Planning Due Date", JobPlanningLine."Planning Due Date" + LibraryRandom.RandInt(10));
        // [THEN] Modification is not possible
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Deleting job planning line
        asserterror JobPlanningLine.Delete(true);
        // [THEN] Deletion is not possible
        Assert.ExpectedError(StrSubstNo(DeletionNotPossibleErr, JobPlanningLine.TableCaption(), WarehouseActivityLinePick.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler')]
    procedure PicksCreatedIrrespectiveOfJobPlanningStatus_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        QtyInventory: Integer;
        QtyToUse: Integer;
        RandomStatus: Enum "Job Planning Line Status";
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Job planning line status is not respected when Creating warehouse pick for a Job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [WHEN] Job planning line status is set randomly
        RandomStatus := Enum::"Job Planning Line Status".FromInteger(RandomStatus.Ordinals.Get(LibraryRandom.RandInt(JobPlanningLine.Status.Ordinals.Count())));
        JobPlanningLine.Validate(Status, RandomStatus);
        JobPlanningLine.Modify(true);
        Commit(); //Needed as Report "Whse.-Source - Create Document" is later executed modally.

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLine(JobPlanningLine);
    end;

    // Partial and the increase quantity on planning line after posting pick.

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,JobTransferFromJobPlanLineHandler,MessageHandler,ConfirmHandlerTrue')]
    procedure CreateWhsePickForMultipleJobTasks_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ResourceNo: Code[20];
        QtyInventory: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Create Warehouse pick for multiple job tasks with different type of job planning lines and then verify the records created.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] Resource R
        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] A Job
        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");

        // [GIVEN] Create Multiple job tasks and a Job Planning Line for every job task with the common location and Bin Code 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T2: Type = Resource, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, ResourceNo, LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T3: Type = Item, Line Type = Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Billable, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] Job Planning Line for Job Task T4: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Number of warehouse pick activities created for the job is 2 * 2 = 4. These include "Action Type" Take and Place for task T1 and task T4.
        WarehouseActivityLinePick.SetRange("Source No.", JobPlanningLine."Job No.");
        Assert.RecordCount(WarehouseActivityLinePick, 4);

        // [THEN] Pick Qty is updated
        // [THEN] Verify data in warehouse activity lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable");
        Assert.RecordCount(JobPlanningLine, 2);
        if JobPlanningLine.FindSet() then
            repeat
                VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, 0, JobPlanningLine.Quantity, false);
                VerifyWarehousePickActivityLine(JobPlanningLine);
            until JobPlanningLine.Next() = 0;

        // [WHEN] Auto fill Qty to handle on Warehouse Pick
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [WHEN] Transfer lines to job journal for the T1 and T4 job planning lines and post
        JobPlanningLine.FindSet();
        repeat
            TransferToJobJournalFromJobPlanningLine(JobPlanningLine);
            OpenRelatedJournalAndPost(JobPlanningLine);
        until JobPlanningLine.Next() = 0;

        // [THEN] Verify Job Planning Lines
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobPlanningLine, 4);
        JobPlanningLine.FindSet();
        repeat
            if (JobPlanningLine.Type = JobPlanningLine.Type::Item) and ((JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::Budget) or (JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::"Both Budget and Billable")) then
                VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, true)
            else begin
                JobPlanningLine.TestField("Qty. Picked", 0);
                JobPlanningLine.TestField("Qty. Picked (Base)", 0);
                JobPlanningLine.TestField("Completely Picked", false);
                JobPlanningLine.TestField("Qty. Posted", 0);
            end;
        until JobPlanningLine.Next() = 0;

        // [THEN] Verify Warehouse Entries
        JobTask.Reset();
        JobTask.SetRange("Job No.", Job."No.");
        Assert.RecordCount(JobTask, 4);
        if JobTask.FindSet() then
            repeat
                VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
            until JobTask.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('JobTransferFromJobPlanLineHandler,WhseSrcCreateDocReqHandler,MessageHandler,RegisterPickForOneModalPageHandler,ConfirmHandlerTrue')]
    procedure CreateAnotherPickForPartialJobJournalLine_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] It is possible to Create warehouse pick for job with an existing entry in job journal line for partially picked items.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandIntInRange(11, 100));

        // [GIVEN] Warehouse Picks Are Created
        OpenJobAndCreateWarehousePick(Job);
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Fill partial quantity and Register pick.
        QtyToUse := LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(QtyToUse);
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in RegisterPickForOneModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Job planning lines picked quantity is updated correctly
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity - QtyToUse, JobPlanningLine.Quantity - QtyToUse, QtyToUse, QtyToUse, JobPlanningLine.Quantity, false);

        // [WHEN] Create Job Journal Lines from Job Planning Line for the partially picked quantity.
        JobPlanningLine.Validate("Qty. to Transfer to Journal", QtyToUse);
        JobPlanningLine.Modify(true);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [WHEN] Auto fill and try to post the remaining Warehouse Picks for the Job
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [THEN] No error is thrown
        // [THEN] Job planning lines picked quantity is updated correctly
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, JobPlanningLine.Quantity, JobPlanningLine.Quantity, JobPlanningLine.Quantity, true);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue')]
    procedure CreatePickAgainAfterPostingFirstPick_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        QtyInventory: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Show Nothing to create message if Warehouse pick is created again after posting the initial pick.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Auto fill Qty to handle on Warehouse Pick and Register Pick, but do not post job journal line
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine);

        // [WHEN] Create Warehouse Pick for the Job again.
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] Nothing to handle error message is shown as the item was completely picked.
        Assert.ExpectedError(WhseCompletelyPickedErr);
    end;

    [Test]
    procedure CreatePickErrWhenThereIsNoQtyToPick_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        QtyInventory: Integer;
        ResourceNo: Code[20];
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Show nothing to create message if Warehouse pick is created job planning lines with 0 quantity along with a job planning line of type resource with some quantity.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] Resource R
        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line with 0 quantity.
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', 0);
        // [GIVEN] Job Planning Line for Job Task T1: Type = Resource, Line Type = Budget and some quantity
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Resource, ResourceNo, LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        asserterror OpenJobAndCreateWarehousePick(Job);

        // [THEN] Nothing to handle error message is shown as there are no items to be picked.
        Assert.ExpectedError(WhseNoItemsToPickErr);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    procedure CreatePickAgainAfterAddingAnotherJobTask_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityHeader: array[2] of Record "Warehouse Activity Header";
        WarehouseActivityLinePick: array[2] of Record "Warehouse Activity Line";
        QtyInventory: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Create Warehouse Pick again after adding another Job Task to same Job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] 1st Warehouse Pick created
        VerifyWarehousePickActivityLine(JobPlanningLine);
        WarehouseActivityLinePick[1].SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick[1].FindFirst();

        WarehouseActivityHeader[1].Get(WarehouseActivityHeader[1].Type::Pick, WarehouseActivityLinePick[1]."No.");

        // [WHEN] Create a new Job Planning Line for a new Job Task T2: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] 2nd Warehouse pick with created.
        VerifyWarehousePickActivityLine(JobPlanningLine);
        WarehouseActivityLinePick[2].SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick[2].FindFirst();

        WarehouseActivityHeader[2].Get(WarehouseActivityHeader[2].Type::Pick, WarehouseActivityLinePick[2]."No.");

        //[THEN] Two separate warehouse activity headers are created
        Assert.AreNotEqual(WarehouseActivityHeader[1]."No.", WarehouseActivityHeader[2]."No.", OneWhsePickHeaderCreatedErr);
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler,ConfirmHandlerTrue')]
    procedure CreatePickForMultipleJobPlanningLines_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        QtyInventory: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Create and register warehouse picks for a job with 1 job task and multiple job planning lines.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 3 Job Planning Lines
        CreateJobPlanningLineWithData(JobPlanningLine[1], JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine[1].Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(100));
        CreateJobPlanningLineWithData(JobPlanningLine[2], JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine[2].Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(100));
        CreateJobPlanningLineWithData(JobPlanningLine[3], JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine[3].Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(100));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Number of warehouse pick activity header created for the job is 1
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine[1]."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        WarehouseActivityHeader.TestField("Location Code", LocationWithDirectedPutawayAndPick.Code);

        // [THEN] Warehouse pick activities should be created.
        Clear(WarehouseActivityLinePick);
        WarehouseActivityLinePick.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 3 * 2); //2 for each job planning line
        VerifyWarehousePickActivityLine(JobPlanningLine[1]);
        VerifyWarehousePickActivityLine(JobPlanningLine[2]);
        VerifyWarehousePickActivityLine(JobPlanningLine[3]);

        // [WHEN] Auto fill Qty to handle on Warehouse Pick and Post it along with Job Journal
        AutoFillAndRegisterWhsePickFromPage(JobPlanningLine[1]);

        // [THEN] Verify Warehouse Entries
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreatePickReqHandler,ConfirmHandlerTrue,AutoFillAndRegisterPickModalPageHandler,PickSelectionModalPageHandler')]
    procedure CreateAndRegisterWhsePicksUsingPickWorksheet_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        PickWorksheetPage: TestPage "Pick Worksheet";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Register warehouse picks that are created for a Job using pick worksheet.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);
        JobPlanningLine.AutoReserve();

        // [THEN] Pick Qty / Pick Qty (Base) = 0; Qty Picked / Qty Picked (Base) = 0 and Completely Picked = No
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler
        Commit(); //Needed as CreatePick report is executed modally.

        // [THEN] Warehouse Worksheet lines are created.
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Job);
        WhseWorksheetLine.SetRange("Whse. Document No.", JobTask."Job No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordCount(WhseWorksheetLine, 1);

        // [WHEN] Pick Worksheet is used to create the pick documents
        PickWorksheetPage.CreatePick.Invoke();
        PickWorksheetPage.Close();

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLine(JobPlanningLine);

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, JobPlanningLine.Quantity, JobPlanningLine.Quantity, 0, 0, JobPlanningLine.Quantity, false);

        // [WHEN] Open Related Warehouse Pick Lines
        Job.Get(JobPlanningLine."Job No.");
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Autofill quantity and Register pick.
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in AutoFillAndRegisterPickModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Pick Qty / Pick Qty (Base), Qty Picked / Qty Picked (Base) and Completely Picked are filled.
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."); //Refresh the job planning lines to have the latest information.
        VerifyJobPlanningLineQuantities(JobPlanningLine, 0, 0, QtyToUse, QtyToUse, JobPlanningLine.Quantity, true);

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, false);
    end;

    [Test]
    [HandlerFunctions('PickSelectionModalPageHandler')]
    procedure CannotCreatePicksUsingPickWorksheetForNonInventoryItems_DirectedPutAwayAndPick()
    var
        NonInventoryItem: Record Item;
        ServiceItem: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: array[4] of Record "Job Planning Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PickWorksheetPage: TestPage "Pick Worksheet";
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Cannot create warehouse picks for job planning lines with non-inventory items, Resource and GL Account without having to create picks.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Non-Inventory type of item
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] Service type of item
        LibraryInventory.CreateServiceTypeItem(ServiceItem);

        // [GIVEN] Resource
        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] G/L account
        GLAccountNo := CreateGLAccount();

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line for the non-inventory, service item, resource, GL account and item with whs tracking enabled.
        CreateJobPlanningLineWithData(JobPlanningLine[1], JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine[1].Type::Item, NonInventoryItem."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine[2], JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine[2].Type::Item, ServiceItem."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine[3], JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine[3].Type::Resource, ResourceNo, LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        CreateJobPlanningLineWithData(JobPlanningLine[4], JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine[4].Type::"G/L Account", GLAccountNo, LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine[1]."Job No.");
        LibraryVariableStorage.Enqueue(LocationWithDirectedPutawayAndPick.Code);
        asserterror PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler 

        // [THEN] No warehouse worksheet lines are created.
        Assert.ExpectedError('no Warehouse Worksheet Lines created');
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Job);
        WhseWorksheetLine.SetRange("Whse. Document No.", JobTask."Job No.");
        Assert.RecordIsEmpty(WhseWorksheetLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure WhsePickRequestIsDeletedOnJobCompletion_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WhsePickRequest: Record "Whse. Pick Request";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Related Warehouse Pick Request should be deleted on completion of the job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Add multiple job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [THEN] Warehouse Pick Request is created for the job
        WhsePickRequest.SetRange("Document No.", JobPlanningLine."Job No.");
        WhsePickRequest.SetRange("Document Subtype", 0);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        Assert.RecordCount(WhsePickRequest, 1);

        // [WHEN] Job status is changed to complete
        Job.Get(JobPlanningLine."Job No.");
        Job.Validate(Status, Job.Status::Completed);

        // [THEN] Related Warehouse Pick Request is deleted
        Assert.RecordIsEmpty(WhsePickRequest);
    end;

    [Test]
    procedure WhsePickRequestIsDeletedOnJobDeletion_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WhsePickRequest: Record "Whse. Pick Request";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Related Warehouse Pick Request should be deleted on deleting the job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Add multiple job planning line that require the item from a created location
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [THEN] Warehouse Pick Request is created for the job
        WhsePickRequest.SetRange("Document No.", JobPlanningLine."Job No.");
        WhsePickRequest.SetRange("Document Subtype", 0);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        Assert.RecordCount(WhsePickRequest, 1);

        // [WHEN] Job is deleted
        Job.Get(JobPlanningLine."Job No.");
        Job.Delete(true);

        // [THEN] Related Warehouse Pick Request is deleted
        Assert.RecordIsEmpty(WhsePickRequest);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure WarehouseRequestRestoredWhenReopeningJob_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WhsePickRequest: Record "Whse. Pick Request";
        QtyInventory: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Warehouse requests should be restored when changing job status from complete, otherwise we cannot create a pick.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A job with a job task
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Adding a job planning line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(100));

        // [THEN] A warehouse request is created.
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        WhsePickRequest.SetRange("Document No.", Job."No.");
        Assert.AreEqual(1, WhsePickRequest.Count(), 'Expected warehouse pick request to exist.');

        // [WHEN] Marking job as complete.
        Job.Validate(Status, Job.Status::Completed);

        // [THEN] The warehouse request is deleted.
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        WhsePickRequest.SetRange("Document No.", Job."No.");
        Assert.AreEqual(0, WhsePickRequest.Count(), 'Expected warehouse pick request to be deleted.');

        // [WHEN] Marking job as open.
        Job.Validate(Status, Job.Status::Open);

        // [THEN] A warehouse request is created.
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        WhsePickRequest.SetRange("Document No.", Job."No.");
        Assert.AreEqual(1, WhsePickRequest.Count(), 'Expected warehouse pick request to exist.');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    procedure CannotDeleteOrCompleteJobWithWhseActivityLines_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        QtyInventory: Integer;
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Try to delete or complete the job for which outstanding warehouse picks exists.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Lines
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(100));

        // [WHEN] Create Warehouse Pick for the Job
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Job status is changed to complete
        Job.Get(JobPlanningLine."Job No.");

        asserterror Job.Validate(Status, Job.Status::Completed);

        // [THEN] Status cannot be changed to completed because outstanding warehouse pick exists for the job
        ExpectedErrorMessage := StrSubstNo(FieldMustNotBeChangedErr, WarehouseActivityLinePick.TableCaption(), JobPlanningLine.TableCaption());
        Assert.ExpectedError(ExpectedErrorMessage);

        // [WHEN] Job is deleted
        asserterror Job.Delete(true);

        // [THEN] Job cannot be deleted because outstanding warehouse pick exists for the job 
        ExpectedErrorMessage := StrSubstNo(
            DeletionNotPossibleErr, JobPlanningLine.TableCaption(), WarehouseActivityLinePick.TableCaption());
        Assert.ExpectedError(ExpectedErrorMessage);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PickSelectionModalPageHandler')]
    procedure CannotChangeStatusOrDeleteJobWhenWhseWorksheetLinesExist_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PickWorksheetPage: TestPage "Pick Worksheet";
        QtyInventory: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Create pick from warehouse worksheet should fail if job is deleted or completed.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        QtyInventory := LibraryRandom.RandIntInRange(800, 1000);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] A Job
        LibraryJob.CreateJob(Job, CreateCustomer(''));

        // [GIVEN] Create 1 Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] 1 Job Planning Lines
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(100));

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler
        PickWorksheetPage.Close();

        // [WHEN] Job status is changed to complete.
        Job.Get(JobPlanningLine."Job No.");
        asserterror Job.Validate(Status, Job.Status::Completed);

        // [THEN] An error is thrown.
        Assert.ExpectedError('Status must not be changed when a Whse. Worksheet');

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke(); //Handled in PickSelectionModalPageHandler
        PickWorksheetPage.Close();

        // [WHEN] Job is deleted.
        asserterror Job.Delete(true);

        // [THEN] An error is thrown.
        Assert.ExpectedError('The Project Planning Line cannot be deleted when a related Whse. Worksheet');
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,MessageHandler')]
    procedure CreateAndRegisterPickForReservedJobPlanningLine_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [WMS] [Reservation] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Create pick from reserved job planning line.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with enough inventory on location with "Directed Put-away and Pick"
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", LibraryRandom.RandIntInRange(20, 40), LocationWithDirectedPutawayAndPick.Code, false);

        // [GIVEN] Create job, job task, and job planning line.
        // [GIVEN] Auto reserve the job planning line from the inventory.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', LibraryRandom.RandInt(10));
        JobPlanningLine.AutoReserve();

        // [WHEN] Create warehouse pick.
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] The pick has been created.
        JobPlanningLine.Find();
        JobPlanningLine.CalcFields("Pick Qty.");
        JobPlanningLine.TestField("Pick Qty.", JobPlanningLine.Quantity);

        // [THEN] The pick can be successfully registered.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        JobPlanningLine.Find();
        JobPlanningLine.TestField("Qty. Picked", JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreatePickReqHandler,PickSelectionModalPageHandler,ItemTrackingLinesModalPageHandler,AssignSerialNoEnterQtyPageHandler')]
    procedure CreateAndRegisterWhsePicksWithItemTrackingUsingPickWorksheet_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PickWorksheetPage: TestPage "Pick Worksheet";
        SerialNos: List of [Code[50]];
        SerialNo: Code[50];
        Qty: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Create and register warehouse picks using pick worksheet for job planning line with item tracking.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with SN tracking and enough inventory on location with "Directed Put-away and Pick"
        CreateSerialTrackedItem(Item, true);
        Qty := 2;

        // [GIVEN] Post 2 serial nos. "S1" and "S2" to inventory.
        LibraryVariableStorage.Enqueue(0);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", Qty, LocationWithDirectedPutawayAndPick.Code, true);
        GetListOfPostedSerialNos(SerialNos, Item."No.");

        // [GIVEN] Job, job task, and job planning line for 2 pcs.
        // [GIVEN] Select serial nos. "S1" and "S2" on the job planning line.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', Qty);
        LibraryVariableStorage.Enqueue(2);
        foreach SerialNo in SerialNos do
            LibraryVariableStorage.Enqueue(SerialNo);
        JobPlanningLine.OpenItemTrackingLines();

        // [GIVEN] Open pick worksheet and pull the job planning line using "Get Warehouse Documents".
        PickWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(JobPlanningLine."Job No.");
        LibraryVariableStorage.Enqueue(JobPlanningLine."Location Code");
        PickWorksheetPage."Get Warehouse Documents".Invoke();

        // [WHEN] Create pick from pick worksheet.
        Commit();
        PickWorksheetPage.CreatePick.Invoke();
        PickWorksheetPage.Close();

        // [THEN] Warehouse pick is created.
        // [THEN] Serial numbers "S1" and "S2" are selected on the pick lines.
        WarehouseActivityLine.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        foreach SerialNo in SerialNos do begin
            WarehouseActivityLine.SetRange("Serial No.", SerialNo);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.TestField(Quantity, 1);
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler')]
    procedure WhsePicksCreatedForJobWithItemTrackingWithBin_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Warehouse picks can be created for items with SN tracking with bin.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with SN tracking and enough inventory on location with "Directed Put-away and Pick"
        CreateSerialTrackedItem(Item, true);
        QtyInventory := LibraryRandom.RandIntInRange(40, 50);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, true);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line with the SN tracked item
        QtyToUse := LibraryRandom.RandIntInRange(2, 10);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created and there is nothing to handle error is not thrown.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandler,ConfirmHandlerTrue,AutoFillAndRegisterPickModalPageHandler,ItemTrackingLinesAssignPageHandler,AssignSerialNoEnterQtyPageHandler')]
    procedure WhsePicksCanBeRegisteredForJobWithItemTrackingWithBin_DirectedPutAwayAndPick()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLinesPage: TestPage "Warehouse Activity Lines";
        QtyInventory: Integer;
        QtyToUse: Integer;
    begin
        // [FEATURE] [WMS] Support directed put-away and pick warehouses with projects.
        // [SCENARIO 485770] Warehouse picks can be created for items with SN tracking with bin.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location with "Directed Put-away and Pick"
        CreateDefaultWarehouseEmployee(LocationWithDirectedPutawayAndPick);

        // [GIVEN] Ensure empty Bin in Pick zone
        CreateEmptyPickBin();

        // [GIVEN] An item with SN tracking and enough inventory on location with "Directed Put-away and Pick"
        CreateSerialTrackedItem(Item, true);
        QtyInventory := LibraryRandom.RandIntInRange(4, 7);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", QtyInventory, LocationWithDirectedPutawayAndPick.Code, true);

        // [GIVEN] A job with a task
        CreateJobWithJobTask(JobTask);

        // [WHEN] Create a job planning line with the SN tracked item
        QtyToUse := QtyInventory;
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, Item."No.", LocationWithDirectedPutawayAndPick.Code, '', QtyToUse);

        // [WHEN] 'Create Warehouse Pick' action is invoked from the job card
        Job.Get(JobPlanningLine."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Warehouse pick lines are created
        VerifyWarehousePickActivityLineWithSN(JobPlanningLine);

        // [WHEN] Assign Serial Numbers on Warehouse Pick Lines
        AssignSNWhsePickLines(JobPlanningLine);

        // [WHEN] Open Related Warehouse Pick Lines
        WarehouseActivityLinesPage.Trap();
        OpenRelatedWarehousePicksForJob(Job);

        // [WHEN] Open related Warehouse Pick Card, Autofill quantity and Register pick.
        WarehouseActivityLinesPage.ShowDocument.Invoke(); //Handled in AutoFillAndRegisterPickModalPageHandler
        WarehouseActivityLinesPage.Close();

        // [THEN] Warehouse entry is created
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, true);

        // [THEN] Reservation Entries are created.
        VerifyWhsePickReservationEntry(JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSrcCreateDocReqHandlerWithLocationFilter,WarehouseEmployeeHandler')]
    procedure LocationFilterOnAssignedUserIdWhenUsingWarehousePick()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        Location: array[3] of Record Location;
        WarehouseEmployee: array[3] of Record "Warehouse Employee";
        JobCardPage: TestPage "Job Card";
        i: Integer;
    begin
        // [SCENARIO 545978] Filter on assigning User ID when creating a Warehouse Pick from a Project Card.
        Initialize();

        // [GIVEN] Create Warehouse Location and Employee with Location.
        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocationWMS(Location[i], false, true, true, true, true);

            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee[i], Location[i].Code, false);
            WarehouseEmployee[i].Validate("Location Code", Location[i].Code);
            WarehouseEmployee[i].Modify(true);
        end;

        // [GIVEN] Store Warehouse Employee User Id.
        LibraryVariableStorage.Enqueue(WarehouseEmployee[1]."User ID");

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Inventory of an Item on the Location.
        CreateAndPostInvtAdjustmentWithUnitCost(
            Item."No.", Location[1].Code, '',
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create a Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Validate Location Code in Job.
        Job.Get(JobTask."Job No.");
        Job.Validate("Location Code", Location[1].Code);
        Job.Modify(true);

        // [WHEN] Create Job Planning Line for Job Task with Item and Location.
        CreateJobPlanningLineWithData(
            JobPlanningLine,
            JobTask,
            "Job Planning Line Line Type"::"Both Budget and Billable",
            JobPlanningLine.Type::Item,
            Item."No.",
            Location[1].Code,
            '',
            LibraryRandom.RandInt(10));

        // [THEN] Assigned User Id should be able to select while creating Warehouse Pick.
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage."Create Warehouse Pick".Invoke();
    end;

    procedure AssignSNWhsePickLines(JobPlanningLine: Record "Job Planning Line")
    var
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        ItemTrackingEntries: Record "Item Ledger Entry";
        Counter: Integer;
    begin
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindSet();
        ItemTrackingEntries.SetRange("Item No.", WarehouseActivityLinePick."Item No.");
        ItemTrackingEntries.FindSet();
        repeat
            Counter += 1;
            WarehouseActivityLinePick.Validate("Serial No.", ItemTrackingEntries."Serial No.");
            WarehouseActivityLinePick.Modify(true);
            if (JobPlanningLine."Bin Code" = '') or (Counter mod 2 = 0) then
                ItemTrackingEntries.Next(); //Use the same serial number of take and place activity type or use new serial number when BinCode = ''.
        until (WarehouseActivityLinePick.Next() = 0);
    end;

    local procedure CreateSerialTrackedItem(var Item: Record Item; WMSSpecific: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        if WMSSpecific then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            ItemTrackingCode.Validate("SN Warehouse Tracking", true);
            ItemTrackingCode.Modify(true);
        end;
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

    local procedure VerifyWhsePickReservationEntry(var JobPlanningLine: Record "Job Planning Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", JobPlanningLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", JobPlanningLine."Job No.");
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordCount(ReservationEntry, JobPlanningLine.Quantity);
        ReservationEntry.FindSet();
        repeat
            Assert.AreEqual(-1, ReservationEntry.Quantity, 'The Quantity on the Reservation Entry should be equal to -1');
        until ReservationEntry.Next() = 0;
    end;

    local procedure TestWhsePickLineFieldsForJobPlanningLine(var WarehouseActivityPickLine: Record "Warehouse Activity Line"; var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
    begin
        WarehouseActivityPickLine.TestField("Source No.", JobPlanningLine."Job No.");
        WarehouseActivityPickLine.TestField("Source Type", Database::Job);
        WarehouseActivityPickLine.TestField("Source Document", WarehouseActivityPickLine."Source Document"::"Job Usage");
        WarehouseActivityPickLine.TestField("Activity Type", WarehouseActivityPickLine."Activity Type"::Pick);
        WarehouseActivityPickLine.TestField("Location Code", JobPlanningLine."Location Code");
        WarehouseActivityPickLine.TestField("Item No.", JobPlanningLine."No.");
        WarehouseActivityPickLine.TestField("Qty. Handled", 0);

        Job.SetLoadFields("Sell-to Customer No.");
        Job.Get(JobPlanningLine."Job No.");
        WarehouseActivityPickLine.TestField("Destination Type", WarehouseActivityPickLine."Destination Type"::Customer);
        WarehouseActivityPickLine.TestField("Destination No.", Job."Sell-to Customer No.");
    end;

    local procedure CountWarehouseActivityTypeSpaceAndBins(var WarehouseActivityPickLine: Record "Warehouse Activity Line"; var JobPlanningLine: Record "Job Planning Line"; var CountSourceBin: Integer; var CountDestinationBin: Integer; var CountActivityTypeSpace: Integer)
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
    begin
        case WarehouseActivityPickLine."Action Type" of
            WarehouseActivityPickLine."Action Type"::Take:
                begin
                    Location.SetLoadFields("Directed Put-away and Pick");
                    Location.Get(JobPlanningLine."Location Code");
                    if not Location."Directed Put-away and Pick" then begin
                        FindDefaultBinContent(BinContent, JobPlanningLine."No.", JobPlanningLine."Location Code");
                        WarehouseActivityPickLine.TestField("Bin Code", BinContent."Bin Code"); //Take from Default Bin
                    end else
                        WarehouseActivityPickLine.TestField("Bin Code");
                    CountSourceBin += 1
                end;

            WarehouseActivityPickLine."Action Type"::Place:
                begin
                    WarehouseActivityPickLine.TestField("Bin Code", JobPlanningLine."Bin Code"); //Place in the destination Bin
                    CountDestinationBin += 1
                end;
            WarehouseActivityPickLine."Action Type"::" ":
                begin
                    WarehouseActivityPickLine.TestField("Bin Code", '');
                    WarehouseActivityPickLine.TestField("Bin Code", JobPlanningLine."Bin Code");
                    CountActivityTypeSpace += 1;
                end;
        end;
    end;

    local procedure VerifyWarehousePickActivityLine(JobPlanningLine: Record "Job Planning Line")
    var
        WarehouseActivityPickLine: Record "Warehouse Activity Line";
        CountSourceBin: Integer;
        CountDestinationBin: Integer;
        CountActivityTypeSpace: Integer;
    begin
        WarehouseActivityPickLine.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No."); //This can uniquely identify the line
        WarehouseActivityPickLine.FindSet();
        repeat
            TestWhsePickLineFieldsForJobPlanningLine(WarehouseActivityPickLine, JobPlanningLine);
            CountWarehouseActivityTypeSpaceAndBins(WarehouseActivityPickLine, JobPlanningLine, CountSourceBin, CountDestinationBin, CountActivityTypeSpace);
            WarehouseActivityPickLine.TestField(Quantity, JobPlanningLine."Remaining Qty.");
        until WarehouseActivityPickLine.Next() = 0;

        VerifyWhseActivityTypeAndBinsCount(JobPlanningLine, CountSourceBin, CountDestinationBin, CountActivityTypeSpace, false);
    end;

    local procedure VerifyWarehousePickActivityLineWithSN(JobPlanningLine: Record "Job Planning Line")
    var
        WarehouseActivityPickLine: Record "Warehouse Activity Line";
        CountSourceBin: Integer;
        CountDestinationBin: Integer;
        CountActivityTypeSpace: Integer;
    begin
        WarehouseActivityPickLine.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No."); //This can uniquely identify the line
        WarehouseActivityPickLine.FindSet();
        repeat
            TestWhsePickLineFieldsForJobPlanningLine(WarehouseActivityPickLine, JobPlanningLine);
            CountWarehouseActivityTypeSpaceAndBins(WarehouseActivityPickLine, JobPlanningLine, CountSourceBin, CountDestinationBin, CountActivityTypeSpace);
            WarehouseActivityPickLine.TestField(Quantity, 1)
        until WarehouseActivityPickLine.Next() = 0;

        VerifyWhseActivityTypeAndBinsCount(JobPlanningLine, CountSourceBin, CountDestinationBin, CountActivityTypeSpace, true);
    end;

    local procedure VerifyWhseActivityTypeAndBinsCount(var JobPlanningLine: Record "Job Planning Line"; CountSourceBin: Integer; CountDestinationBin: Integer; CountActivityTypeSpace: Integer; SNSpecificTracking: Boolean)
    begin
        if SNSpecificTracking then //One warehouse pick line created for every quantity on the job planning line.
            if JobPlanningLine."Bin Code" = '' then
                AssertCountsAreEqual(JobPlanningLine."Remaining Qty.", CountActivityTypeSpace, 0, CountSourceBin, 0, CountDestinationBin)
            else
                AssertCountsAreEqual(0, CountActivityTypeSpace, JobPlanningLine."Remaining Qty.", CountSourceBin, JobPlanningLine."Remaining Qty.", CountDestinationBin);

        if not SNSpecificTracking then //One warehouse pick line created for one job planning line.
            if JobPlanningLine."Bin Code" = '' then
                AssertCountsAreEqual(1, CountActivityTypeSpace, 0, CountSourceBin, 0, CountDestinationBin)
            else
                AssertCountsAreEqual(0, CountActivityTypeSpace, 1, CountSourceBin, 1, CountDestinationBin);
    end;

    local procedure AssertCountsAreEqual(CountActivityTypeSpaceExp: Integer; CountActivityTypeSpaceAct: Integer; CountSourceBinExp: Integer; CountSourceBinAct: Integer; CountDestinationBinExp: Integer; CountDestinationBinAct: Integer)
    var
        WarehouseActivityPickLine: Record "Warehouse Activity Line";
    begin
        Assert.AreEqual(CountActivityTypeSpaceExp, CountActivityTypeSpaceAct, StrSubstNo(WarehousePickActionTypeTotalErr, WarehouseActivityPickLine.FieldCaption(WarehouseActivityPickLine."Activity Type"), WarehouseActivityPickLine."Activity Type"::Pick, CountActivityTypeSpaceExp));

        Assert.AreEqual(CountSourceBinExp, CountSourceBinAct, StrSubstNo(WarehousePickActionTypeTotalErr, WarehouseActivityPickLine.FieldCaption(WarehouseActivityPickLine."Action Type"), WarehouseActivityPickLine."Action Type"::Take, CountSourceBinExp));

        Assert.AreEqual(CountDestinationBinExp, CountDestinationBinAct, StrSubstNo(WarehousePickActionTypeTotalErr, WarehouseActivityPickLine.FieldCaption(WarehouseActivityPickLine."Action Type"), WarehouseActivityPickLine."Action Type"::Place, CountDestinationBinExp));
    end;

    local procedure FindDefaultBinContent(var BinContent: Record "Bin Content"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange(Default, true);
        if BinContent.FindFirst() then;
    end;

    local procedure GetListOfPostedSerialNos(var SerialNos: List of [Code[50]]; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Clear(SerialNos);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetFilter("Serial No.", '<>%1', '');
        ItemLedgerEntry.FindSet();
        repeat
            SerialNos.Add(ItemLedgerEntry."Serial No.");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure OpenJobAndCreateWarehousePick(Job: Record Job)
    var
        JobCardPage: TestPage "Job Card";
    begin
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage."Create Warehouse Pick".Invoke();
        JobCardPage.Close();
    end;

    local procedure OpenRelatedWarehousePicksForJob(Job: Record Job)
    var
        JobCardPage: TestPage "Job Card";
    begin
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage."Put-away/Pick Lines/Movement Lines".Invoke();
        JobCardPage.Close();
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
        JobPlanningLinePage.CreateJobJournalLines.Invoke(); //Needs JobTransferFromJobPlanLineHandler Handler
        JobPlanningLinePage.Close();
    end;

    local procedure AutoFillAndRegisterWhsePickFromPage(JobPlanningLine: Record "Job Planning Line")
    var
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehousePickPage: TestPage "Warehouse Pick";
    begin
        WarehouseActivityLinePick.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseActivityLinePick.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLinePick."No.");
        WarehousePickPage.OpenEdit();
        WarehousePickPage.GoToRecord(WarehouseActivityHeader);
        WarehousePickPage."Autofill Qty. to Handle".Invoke();
        WarehousePickPage.RegisterPick.Invoke(); //Needs confirmation handler
    end;

    local procedure VerifyWhseEntriesAfterRegisterPick(Job: Record Job; JobTask: Record "Job Task"; SNSpecificTracking: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable");
        if JobPlanningLine.FindSet() then
            repeat
                if SNSpecificTracking then
                    VerifyWhseEntryForRegisteredPickWithSN(JobPlanningLine)
                else
                    VerifyWhseEntryForRegisteredPick(JobPlanningLine);
            until JobPlanningLine.Next() = 0;
    end;

    local procedure FindWarehouseEntriesForJob(var WarehouseEntry: Record "Warehouse Entry"; var JobPlanningLine: Record "Job Planning Line")
    begin
        WarehouseEntry.SetRange("Item No.", JobPlanningLine."No.");
        WarehouseEntry.SetRange("Source No.", JobPlanningLine."Job No.");
        WarehouseEntry.SetRange("Source Type", DATABASE::Job);
        WarehouseEntry.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WarehouseEntry.SetRange("Source Subline No.", JobPlanningLine."Line No."); //Link job planning line to warehouse entry for registered pick
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Job);
        WarehouseEntry.SetRange("Whse. Document No.", JobPlanningLine."Job No.");
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Job Usage");
        WarehouseEntry.SetRange("Location Code", JobPlanningLine."Location Code");
        WarehouseEntry.FindFirst();
    end;

    local procedure VerifyWhseEntryForRegisteredPick(JobPlanningLine: Record "Job Planning Line")
    var
        Location: Record Location;
        WarehouseEntry: Record "Warehouse Entry";
        CountSourceBin: Integer;
        CountDestinationBin: Integer;
        DestinationBinCode, SourceBinCode : Code[20];
    begin
        FindWarehouseEntriesForJob(WarehouseEntry, JobPlanningLine);
        Assert.RecordCount(WarehouseEntry, 2); //2 lines per planning line is created in warehouse entry

        Location.SetLoadFields("Directed Put-away and Pick");
        Location.Get(JobPlanningLine."Location Code");
        if not Location."Directed Put-away and Pick" then begin
            SourceBinCode := SourceBin.Code;
            DestinationBinCode := DestinationBin.Code;
        end else begin
            SourceBinCode := '';
            DestinationBinCode := JobPlanningLine."Bin Code";
        end;

        WarehouseEntry.FindSet();
        repeat
            // take from source bin and place it in destination bin.
            case WarehouseEntry."Bin Code" of
                DestinationBinCode:
                    begin
                        WarehouseEntry.TestField("Bin Code", JobPlanningLine."Bin Code");
                        WarehouseEntry.TestField(Quantity, JobPlanningLine."Qty. Picked (Base)");
                        CountDestinationBin += 1;
                    end;
                SourceBinCode:
                    begin
                        WarehouseEntry.TestField(Quantity, -JobPlanningLine."Qty. Picked (Base)");
                        CountSourceBin += 1;
                    end;
            end;
        until WarehouseEntry.Next() = 0;

        // 2 lines are created for each job planning line
        if SourceBinCode <> '' then
            Assert.AreEqual(1, CountSourceBin, StrSubstNo(WarehouseEntryTotalErr, 1, SourceBinCode));
        if DestinationBinCode <> '' then
            Assert.AreEqual(1, CountDestinationBin, StrSubstNo(WarehouseEntryTotalErr, 1, DestinationBinCode));
    end;

    local procedure VerifyWhseEntryForRegisteredPickWithSN(JobPlanningLine: Record "Job Planning Line")
    var
        Location: Record Location;
        WarehouseEntry: Record "Warehouse Entry";
        CountSourceBin: Integer;
        CountDestinationBin: Integer;
        DestinationBinCode, SourceBinCode : Code[20];
    begin
        FindWarehouseEntriesForJob(WarehouseEntry, JobPlanningLine);
        Assert.RecordCount(WarehouseEntry, 2 * JobPlanningLine.Quantity); //2 * quantity on the job planning line

        Location.SetLoadFields("Directed Put-away and Pick");
        Location.Get(JobPlanningLine."Location Code");
        if not Location."Directed Put-away and Pick" then begin
            SourceBinCode := SourceBin.Code;
            DestinationBinCode := DestinationBin.Code;
        end else begin
            SourceBinCode := '';
            DestinationBinCode := JobPlanningLine."Bin Code";
        end;

        WarehouseEntry.FindSet();
        repeat
            // take from source bin and place it in destination bin.
            case WarehouseEntry."Bin Code" of
                DestinationBinCode:
                    begin
                        WarehouseEntry.TestField("Bin Code", JobPlanningLine."Bin Code");
                        WarehouseEntry.TestField(Quantity, 1);
                        CountDestinationBin += 1;
                    end;
                SourceBinCode:
                    begin
                        WarehouseEntry.TestField(Quantity, -1);
                        CountSourceBin += 1;
                    end;
            end;
        until WarehouseEntry.Next() = 0;

        // 2 lines are created for each quantity per job planning line.
        if SourceBinCode <> '' then
            Assert.AreEqual(JobPlanningLine.Quantity, CountSourceBin, StrSubstNo(WarehouseEntryTotalErr, JobPlanningLine.Quantity, SourceBinCode));
        if DestinationBinCode <> '' then
            Assert.AreEqual(JobPlanningLine.Quantity, CountDestinationBin, StrSubstNo(WarehouseEntryTotalErr, JobPlanningLine.Quantity, DestinationBinCode));
    end;

    local procedure VerifyWarehouseEntry(SourceDocument: Enum "Warehouse Journal Source Document"; EntryType: Option; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Source Document", SourceDocument);
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Location Code", LocationCode);
        WarehouseEntry.TestField("Bin Code", BinCode);
        WarehouseEntry.TestField("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseEntry.TestField(Quantity, Quantity);
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
        end else
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, NewDefaultLocation.Code, true);
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Whse. Pick On Job Planning");
        LibrarySetupStorage.Restore();
        LibraryJob.DeleteJobJournalTemplate();

        if not IsInitialized then begin
            LibraryWarehouse.CreateLocationWMS(LocationWithWhsePick, true, false, true, false, true);
            LibraryWarehouse.CreateBin(SourceBin, LocationWithWhsePick.Code, LibraryUtility.GenerateRandomCode(SourceBin.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateBin(DestinationBin, LocationWithWhsePick.Code, LibraryUtility.GenerateRandomCode(DestinationBin.FieldNo(Code), Database::Bin), '', '');

            LibraryWarehouse.CreateFullWMSLocation(LocationWithDirectedPutawayAndPick, 1);
            LocationWithDirectedPutawayAndPick.Validate("To-Job Bin Code", LocationWithDirectedPutawayAndPick."To-Production Bin Code");
            LocationWithDirectedPutawayAndPick.Modify(true);
        end;

        CreateDefaultWarehouseEmployee(LocationWithWhsePick);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Whse. Pick On Job Planning");

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        NoSeries.Get(LibraryJob.GetJobTestNoSeries());
        NoSeries."Manual Nos." := true;
        NoSeries.Modify();

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := true;
        DummyJobsSetup."Job Nos." := LibraryJob.GetJobTestNoSeries();
        DummyJobsSetup.Modify();

        LibrarySetupStorage.Save(Database::"Inventory Setup");
        LibrarySetupStorage.Save(Database::"Warehouse Setup");
        LibrarySetupStorage.Save(Database::"Purchases & Payables Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Whse. Pick On Job Planning");
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

    local procedure VerifyJobPlanningLineQuantities(JobPlanningLine: Record "Job Planning Line"; PickQty: Decimal; PickQtyBase: Decimal; QtyPicked: Decimal; QtyPickedBase: Decimal; RemainingQty: Decimal; CompletelyPicked: Boolean)
    begin
        JobPlanningLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
        JobPlanningLine.TestField("Pick Qty.", PickQty);
        JobPlanningLine.TestField("Pick Qty. (Base)", PickQtyBase);
        JobPlanningLine.TestField("Qty. Picked", QtyPicked);
        JobPlanningLine.TestField("Qty. Picked (Base)", QtyPickedBase);
        JobPlanningLine.TestField("Remaining Qty.", RemainingQty);
        JobPlanningLine.TestField("Completely Picked", CompletelyPicked);
    end;

    local procedure CreateJobPlanningLineWithData(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; Number: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, Type, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Number);
        JobPlanningLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            JobPlanningLine.Validate("Bin Code", BinCode);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Validate("Document No.", CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(JobPlanningLine."Document No.")));
        JobPlanningLine.Modify(true);
        Commit();
    end;

    local procedure CreateEmptyPickBin()
    var
        Zone: Record Zone;
        NewPickBin: Record Bin;
    begin
        LibraryWarehouse.FindZone(Zone, LocationWithDirectedPutawayAndPick.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.CreateBin(NewPickBin, LocationWithDirectedPutawayAndPick.Code, LibraryUtility.GenerateRandomCode(NewPickBin.FieldNo(Code), Database::Bin), Zone.Code, Zone."Bin Type Code");
    end;

    local procedure CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseItemTracking: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, ItemNo, Quantity, LocationCode, UseItemTracking);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseItemTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", ItemNo, Quantity, LocationCode, UseItemTracking);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.", ItemNo);
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, ItemTracking);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        if UseTracking then
            PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, ItemNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; ItemNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferFromJobPlanLineHandler(var JobTransferJobPlanLine: TestPage "Job Transfer Job Planning Line")
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSrcCreateDocReqHandler(var CreatePickReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickReqHandler(var CreatePickReqPage: TestRequestPage "Create Pick")
    begin
        CreatePickReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WhseSrcCreateDocReqHandlerWithLocationFilter(var CreatePickReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickReqPage.AssignedID.Lookup();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AutoFillAndRegisterPickModalPageHandler(var WarehousePickPage: TestPage "Warehouse Pick")
    begin
        WarehousePickPage."Autofill Qty. to Handle".Invoke();
        WarehousePickPage.RegisterPick.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RegisterPickForOneModalPageHandler(var WarehousePickPage: TestPage "Warehouse Pick")
    var
        QtyToHandle: Integer;
    begin
        QtyToHandle := LibraryVariableStorage.DequeueInteger();
        WarehousePickPage.WhseActivityLines.First();
        WarehousePickPage.WhseActivityLines."Qty. to Handle".SetValue(QtyToHandle);
        WarehousePickPage.WhseActivityLines.Next();
        WarehousePickPage.WhseActivityLines."Qty. to Handle".SetValue(QtyToHandle);
        WarehousePickPage.RegisterPick.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionModalPageHandler(var PickSelection: TestPage "Pick Selection")
    var
        JobNo: Code[20];
        LocationCode: Code[10];
    begin
        JobNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(JobNo));
        LocationCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LocationCode));
        PickSelection.GoToKey("Warehouse Pick Request Document Type"::Job, 0, JobNo, LocationCode);
        PickSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesAssignPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign &Serial No.".Invoke(); // AssignSerialNoEnterQtyPageHandler required.
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                ItemTrackingLines."Assign &Serial No.".Invoke();
            1:
                ItemTrackingLines."Select Entries".Invoke();
            2:
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignSerialNoEnterQtyPageHandler(var EnterQuantityPage: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WarehouseEmployeeHandler(var WarehouseEmployeeList: TestPage "Warehouse Employee List")
    begin
        Assert.AreNotEqual(WarehouseEmployeeList."User ID".Value(), '', '');
    end;
}