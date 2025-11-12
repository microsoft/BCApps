codeunit 136322 "Jobs - Assemble-to Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Projects] [Assemble-to Order]
        Initialized := false
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryResource: Codeunit "Library - Resource";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        Initialized: Boolean;
        ATOLinkWrongTypeMsg: Label 'Assemble-to Order link record has not expected type of assembly document.';
        CreateAsmForJobErr: Label 'It is not possible to create an assembly order for a job task that is completed.';
        AssembleOrderExistErr: Label 'One or more assembly orders exists for the project %1.\\You must delete the assembly order before you can change the job status.', Comment = 'Project No.';
        RemainingQtyGreaterThanErr: Label 'Remaining Quantity (Base) cannot be more than %1 in Assembly Header Document Type=''%2'',No.=''%3''', Comment = 'Remaining Quantity, Document Type, No.';
        BillableLineTypeErr: Label 'Line Type must not be Billable in Project Planning Line Project No.=''%1'',Project Task No.=''%2'',Line No.=''%3''.';
        ZeroJobContractLineMsg: Label 'Job Contract Entry No. is empty.';
        FieldValueIsNotCorrect: Label '%1 is not correct', Comment = 'Field Name';

    [Test]
    procedure AssemblyOrderIsCreated()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        // [SCENARIO 341952] Verify assembly order is created
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [WHEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [THEN] Verify results
        SetFiltersToATOLink(JobTask, JobPlanningLine, ATOLink);
        Assert.RecordIsNotEmpty(ATOLink);

        ATOLink.FindFirst();
        Assert.AreEqual(ATOLink."Document Type"::Order, ATOLink."Document Type", ATOLinkWrongTypeMsg);
    end;

    [Test]
    procedure AssemblyOrderIsNotCreatedIfApplyUsageLinkIsNotChecked()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 539741] Verify assembly order is not created if Apply Usage Link is not checked
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Set Apply Usage Link to false
        Job.Validate("Apply Usage Link", false);
        Job.Modify(true);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [WHEN] Validate Quantity on Job Planning Line
        asserterror JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));

        // [THEN] Verify results
        Assert.ExpectedTestFieldError(JobPlanningLine.FieldCaption("Usage Link"), '');
    end;

    [Test]
    procedure AssemblyQuoteIsCreatedForQuoteJobStatus()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        // [SCENARIO 341952] Verify assembly quote is created for Quote Job Status
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Change Status on Job to Quote
        Job.Validate("Status", Job.Status::Quote);
        Job.Modify(true);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [WHEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [THEN] Verify results
        SetFiltersToATOLink(JobTask, JobPlanningLine, ATOLink);
        Assert.RecordIsNotEmpty(ATOLink);

        ATOLink.FindFirst();
        Assert.AreEqual(ATOLink."Document Type"::Quote, ATOLink."Document Type", ATOLinkWrongTypeMsg);
    end;

    [Test]
    procedure AssemblyOrderIsDeteledWhenQtyToAssembleIsReset()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        // [SCENARIO 341952] Verify assembly order is deleted when Qty. to Assemble is reset
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [WHEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Validate("Qty. to Assemble", 0);
        JobPlanningLine.Modify(true);

        // [THEN] Verify results
        SetFiltersToATOLink(JobTask, JobPlanningLine, ATOLink);
        Assert.RecordIsEmpty(ATOLink);
    end;

    [Test]
    [HandlerFunctions('JobTransferJobPlanningLinePageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure PostUsageFromJobJournalForAssemblyItem()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        ItemJournalLine: Record "Item Journal Line";
        JobJournalLine: Record "Job Journal Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalTemplate: Record "Job Journal Template";
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 341952] Verify post usage from job journal for assembly item
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Add components to inventory
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem1."No.");
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem2."No.");

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [GIVEN] Create Job Journal Template and Batch
        LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(JobJournalTemplate.Name);
        LibraryVariableStorage.Enqueue(JobJournalBatch.Name);

        // [GIVEN] Create Job Journal Line
        JobPlanningLines.OpenEdit();
        JobPlanningLines.Filter.SetFilter("Job No.", JobPlanningLine."Job No.");
        JobPlanningLines.CreateJobJournalLines.Invoke();

        // [WHEN] Post usage from Job Journal
        JobJournalLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobJournalLine.FindFirst();
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Verify results
        SetFiltersToPostedATOLink(JobTask, JobPlanningLine, PostedATOLink);
        Assert.RecordIsNotEmpty(PostedATOLink);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure AssemblyOrderFromQuoteIsCreatedForOpenJobStatus()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        // [SCENARIO 341952] Verify assembly order from quote is created for Open Job Status
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Change Status on Job to Quote
        Job.Validate("Status", Job.Status::Quote);
        Job.Modify(true);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [WHEN] Change Status on Job to Open
        Job.Validate("Status", Job.Status::Open);
        Job.Modify(true);

        // [THEN] Verify results
        SetFiltersToATOLink(JobTask, JobPlanningLine, ATOLink);
        Assert.RecordIsNotEmpty(ATOLink);

        ATOLink.FindFirst();
        Assert.AreEqual(ATOLink."Document Type"::Order, ATOLink."Document Type", ATOLinkWrongTypeMsg);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure IsNotPossibleToCreateAssemblyOrderForCompletedJobStatus()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 341952] Verify is not possible to create assembly order for Completed Job Status
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Change Status on Job to Completed
        Job.Validate("Status", Job.Status::Completed);
        Job.Modify(true);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [WHEN] Validate Quantity on Job Planning Line
        asserterror JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));

        // [THEN] Verify results
        Assert.ExpectedError(CreateAsmForJobErr);
    end;

    [Test]
    procedure BOMComponentLinesAreCreatedWithExplodeBOM()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 341952] Verify BOM component lines are created with Explode BOM action
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Remove Qty. to Assemble
        JobPlanningLine.Validate("Qty. to Assemble", 0);
        JobPlanningLine.Modify(true);

        // [WHEN] Explode BOM
        Codeunit.Run(Codeunit::"Job-Explode BOM", JobPlanningLine);

        // [THEN] Verify results
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        Assert.RecordCount(JobPlanningLine, 3);
    end;

    [Test]
    procedure LineTypeIsCopiedFromOriginalPlanningLineOnExplodeBOMForTextType()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Type: Enum "Job Planning Line Line Type";
    begin
        // [SCENARIO 556632] Verify Line Type is copied from original planning line on Explode BOM for Text Type
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Save Job Planning Line Type
        Type := JobPlanningLine."Line Type";

        // [GIVEN] Remove Qty. to Assemble
        JobPlanningLine.Validate("Qty. to Assemble", 0);
        JobPlanningLine.Modify(true);

        // [WHEN] Explode BOM
        Codeunit.Run(Codeunit::"Job-Explode BOM", JobPlanningLine);

        // [THEN] Verify results
        FilterJobPlanningLine(JobPlanningLine);
        JobPlanningLine.FindFirst();
        Assert.AreEqual(JobPlanningLine."Line Type", Type, StrSubstNo(FieldValueIsNotCorrect, JobPlanningLine.FieldName("Line Type")));
    end;

    [Test]
    procedure NotPossibleToChangeJobStatusFromOpenIfAssembleOrderExist()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 341952] Verify is not possible to change job status from Open if assemble order exist
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [WHEN] Change Status on Job to Quote
        asserterror Job.Validate("Status", Job.Status::Quote);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(AssembleOrderExistErr, Job."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateInventoryPickForAssemblyItemOnJobPlanningLine()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
        WarehouseActivityLinePick: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 341952] Verify create inventory pick for assembly item on job planning line
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Location with required pick
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item,
            ParentItem."No.", Location.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] Create Inventory Pick for the Job
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [THEN] Make sure 1 line is created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure PostUsageForAssembleItemOnPostingInventoryPick()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        // [SCENARIO 341952] Verify post usage for assemble item on posting inventory pick
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Location with required pick
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Create Warehouse Employee with default location
        CreateDefaultWarehouseEmployee(Location);

        // [GIVEN] Add components to inventory
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem1."No.", Location.Code, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem2."No.", Location.Code, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item,
            ParentItem."No.", Location.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] Create Inventory Pick for the Job
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [GIVEN] Find Warehouse Activity Header 
        FindWarehouseActivityHeader(WarehouseActivityHeader, Job, Location);

        // [WHEN] Inventory Pick is posted
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify results
        SetFiltersToPostedATOLink(JobTask, JobPlanningLine, PostedATOLink);
        Assert.RecordIsNotEmpty(PostedATOLink);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure AssemlyConsumptionEntriesAreNotCreatedOnPostingInventoryPickForAssembledItem()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        // [SCENARIO 506439] Verify assembly consumption entries are not created on posting inventory pick for assembled item
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Location with required pick
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Create Warehouse Employee with default location
        CreateDefaultWarehouseEmployee(Location);

        // [GIVEN] Add components and parent Item to inventory
        CreateAndPostInvtAdjustmentWithUnitCost(ParentItem."No.", Location.Code, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem1."No.", Location.Code, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem2."No.", Location.Code, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line        
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item,
            ParentItem."No.", Location.Code, '', 4);

        // [GIVEN] Set Qty. to Assemble
        JobPlanningLine.Validate("Qty. to Assemble", 3);
        JobPlanningLine.Modify(true);

        // [GIVEN] Create Inventory Pick for the Job
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [GIVEN] Find Warehouse Activity Header 
        FindWarehouseActivityHeader(WarehouseActivityHeader, Job, Location);

        // [GIVEN] Find Warehouse Activity Line
        FindWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine);

        // [GIVEN] Set Qty. to Handle
        WarehouseActivityLine.Validate("Qty. to Handle", 1);
        WarehouseActivityLine.Modify(true);

        // [WHEN] Inventory Pick is posted
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify results
        ItemLedgerEntry.SetRange("Item No.", ParentItem."No.");
        ItemLedgerEntry.SetRange("Remaining Quantity", 0);
        Assert.RecordCount(ItemLedgerEntry, 1);
    end;

    [Test]
    procedure SkipCreatingNewAssembleOrderLinkForExistingAssemblyOrderOnUpdateQty()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 495225] Verify skip creating new assemble order link for existing assembly order on update qty
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [WHEN] Validate Qty. to Assemble on Job Planning Line
        JobPlanningLine.Validate("Qty. to Assemble", JobPlanningLine.Quantity - 1);
        JobPlanningLine.Modify(true);

        // // [THEN] Verify validate Quanity on Job Planning Line
        JobPlanningLine.Validate(Quantity, JobPlanningLine.Quantity + 1);
        JobPlanningLine.Modify(true);
    end;

    [Test]
    procedure AssemblyOrderIsDeteledOnDeleteJobPlanningLine()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        // [SCENARIO 502501] Verify assembly order is deleted on delete job planning line
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [WHEN] Delete Job Planning Line        
        JobPlanningLine.Delete(true);

        // [THEN] Verify results
        SetFiltersToATOLink(JobTask, JobPlanningLine, ATOLink);
        Assert.RecordIsEmpty(ATOLink);
    end;

    [Test]
    procedure QtyToAssembleCanNotBeGreatedThanQuantity()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        // [SCENARIO 502504] Verify Qty. to Assemble can not be greater than Quantity
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [GIVEN] Find Assembly Order Link
        SetFiltersToATOLink(JobTask, JobPlanningLine, ATOLink);
        ATOLink.FindFirst();

        // [WHEN] Try to set Qty. to Assemble greater than Quantity
        asserterror JobPlanningLine.Validate("Qty. to Assemble", JobPlanningLine.Quantity + 1);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(RemainingQtyGreaterThanErr, JobPlanningLine."Remaining Qty. (Base)", ATOLink."Assembly Document Type", ATOLink."Assembly Document No."));
    end;

    [Test]
    procedure QtyToAssembleItsNotAllowedForBillableLineType()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 502504] Verify Qty. to Assemble its not allowed for Billable Line Type
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Change Line Type to Billable and enter Quantity
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [THEN] Verify Qty. to Assemble is empty
        Assert.AreEqual(JobPlanningLine."Qty. to Assemble", 0, 'Qty. to Assemble is not empty');

        // [WHEN] Try to set Qty. to Assemble greater than Quantity
        asserterror JobPlanningLine.Validate("Qty. to Assemble", JobPlanningLine.Quantity);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(BillableLineTypeErr, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
    end;

    [Test]
    procedure QtyToAssembleIsReturnedToZeroOnValidateForResourceOnJobPlanningLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 504326] Verify Qty. to Assemble is returned to zero on validate for Resource on Job Planning Line
        Initialize();

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), LibraryResource.CreateResourceNo(), JobTask);

        // [WHEN] Validate Qty. to Assemble on Job Planning Line
        JobPlanningLine.Validate("Qty. to Assemble", JobPlanningLine.Quantity);

        // [THEN] Verify Qty. to Assemble is empty
        Assert.AreEqual(JobPlanningLine."Qty. to Assemble", 0, 'Qty. to Assemble is not empty');
        Assert.AreEqual(JobPlanningLine."Qty. to Assemble (Base)", 0, 'Qty. to Assemble is not empty');
    end;

    [Test]
    procedure QtyToAssembleIsReturnedToZeroOnValidateForGLAccountOnJobPlanningLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 504326] Verify Qty. to Assemble is returned to zero on validate for G/L Account on Job Planning Line
        Initialize();

        // [GIVEN] G/L account
        GLAccountNo := CreateGLAccount();

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.GLAccountType(), GLAccountNo, JobTask);

        // [WHEN] Validate Qty. to Assemble on Job Planning Line
        JobPlanningLine.Validate("Qty. to Assemble", JobPlanningLine.Quantity);

        // [THEN] Verify Qty. to Assemble is empty
        Assert.AreEqual(JobPlanningLine."Qty. to Assemble", 0, 'Qty. to Assemble is not empty');
        Assert.AreEqual(JobPlanningLine."Qty. to Assemble (Base)", 0, 'Qty. to Assemble is not empty');
    end;

    [Test]
    procedure JobPlanningLineDataAreCopiedToBOMComponentLinesCreatedWithExplodeBOM()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanningDate, PlannedDeliveryDate : Date;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 504537] Verify Job Planning Line Date are copied to BOM Component Lines created with Explode BOM
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Set Document Date on Job Planning Line
        JobPlanningLine.Validate("Document No.", LibraryRandom.RandText(20));
        JobPlanningLine.Modify(true);

        // [GIVEN] Save Job Planning Line data
        PlanningDate := JobPlanningLine."Planning Date";
        PlannedDeliveryDate := JobPlanningLine."Planned Delivery Date";
        DocumentNo := JobPlanningLine."Document No.";

        // [GIVEN] Remove Qty. to Assemble
        JobPlanningLine.Validate("Qty. to Assemble", 0);
        JobPlanningLine.Modify(true);

        // [WHEN] Explode BOM
        Codeunit.Run(Codeunit::"Job-Explode BOM", JobPlanningLine);

        // [THEN] Verify results
        SetFilterOnExplodedJobPlanningLine(JobPlanningLine);
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField("Planning Date", PlanningDate);
        JobPlanningLine.TestField("Planned Delivery Date", PlannedDeliveryDate);
        JobPlanningLine.TestField("Document No.", DocumentNo);
        Assert.IsFalse(JobPlanningLine."Job Contract Entry No." = 0, ZeroJobContractLineMsg);
    end;

    [Test]
    procedure BinCodeIsUpdatedOnAssemblyHeaderOnChangeBinCodeOnJobPlanningLine()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
        ATOLink: Record "Assemble-to-Order Link";
        AssemblyHeader: Record "Assembly Header";
        Bin: array[2] of Record Bin;
    begin
        // [SCENARIO 504547] Verify Bin Code is updated on Assembly Header on change Bin Code on Job Planning Line
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create location with two bins - "B1", "B2".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item,
            ParentItem."No.", Location.Code, Bin[1].Code, LibraryRandom.RandInt(10));

        // [WHEN] Change Bin Code on Job Planning Line
        JobPlanningLine.Validate("Bin Code", Bin[2].Code);
        JobPlanningLine.Modify(true);

        // [THEN] Verify results
        SetFiltersToATOLink(JobTask, JobPlanningLine, ATOLink);
        ATOLink.FindFirst();
        AssemblyHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.");
        AssemblyHeader.TestField("Bin Code", Bin[2].Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure PostInventoryPickForAssemblyItemRelatedToJobPlanningLineWithBin()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
        Bin: Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        // [SCENARIO 504561] Verify post inventory pick for assembly item related to job planning line with bin
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Location with required pick
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);

        // [GIVEN] Create Bin in Location
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Create Warehouse Employee with default location
        CreateDefaultWarehouseEmployee(Location);

        // [GIVEN] Add components to inventory
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem1."No.", Location.Code, Bin.Code, LibraryRandom.RandInt(100), LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem2."No.", Location.Code, Bin.Code, LibraryRandom.RandInt(100), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item,
            ParentItem."No.", Location.Code, Bin.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Create Inventory Pick for the Job
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [GIVEN] Find Warehouse Activity Header 
        FindWarehouseActivityHeader(WarehouseActivityHeader, Job, Location);

        // [WHEN] Inventory Pick is posted
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify results
        SetFiltersToPostedATOLink(JobTask, JobPlanningLine, PostedATOLink);
        Assert.RecordIsNotEmpty(PostedATOLink);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure PostUsageFromJournalWhenJournalLineIsManuallyCreatedForAssemblyItem()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        ItemJournalLine: Record "Item Journal Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [SCENARIO 504541] Verify post usage from journal when journal line is manually created for assembly item
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Add components to inventory
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem1."No.");
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem2."No.");

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

        // [GIVEN] Validate Quantity on Job Planning Line
        JobPlanningLine.Validate("Quantity", LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        // [GIVEN] Create Job Journal Line
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, "Job Line Type"::Budget, 1, JobJournalLine);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.Modify(true);

        // [WHEN] Post usage from Job Journal
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Verify results
        SetFiltersToPostedATOLink(JobTask, JobPlanningLine, PostedATOLink);
        Assert.RecordIsNotEmpty(PostedATOLink);
    end;

    [Test]
    procedure AllowCreatingBillablePlanningLinesForAssemblyItemOnExplodeBOM()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 545976] Allow creating billable planning lines for assembly item on explode BOM
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Billable Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Billable, JobPlanningLine.Type::Item, ParentItem."No.", '', '', LibraryRandom.RandInt(10));

        // [GIVEN] Set Document Date on Job Planning Line
        JobPlanningLine.Validate("Document No.", LibraryRandom.RandText(20));
        JobPlanningLine.Modify(true);

        // [WHEN] Explode BOM
        Codeunit.Run(Codeunit::"Job-Explode BOM", JobPlanningLine);

        // [THEN] Verify results
        SetFilterOnExplodedJobPlanningLine(JobPlanningLine);
        JobPlanningLine.FindFirst();
        Assert.AreEqual(JobPlanningLine."Line Type", JobPlanningLine."Line Type"::Billable, 'Line Type is not Billable');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure PostInventoryPickForAssemblyItemWithAutomaticCostAdjustment()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        InventorySetup: Record "Inventory Setup";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        // [SCENARIO 556206] Verify post inventory pick for assembly item with automatic cost adjustment
        Initialize();

        // [GIVEN] Set Automatic Cost Adjustment on Inventory Setup
        UpdateCostFieldsInInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Always);

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Create Location with required pick
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Create Warehouse Employee with default location
        CreateDefaultWarehouseEmployee(Location);

        // [GIVEN] Add components to inventory
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem1."No.", Location.Code, '', 100, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem1."No.", Location.Code, '', 100, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem2."No.", Location.Code, '', 100, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(CompItem2."No.", Location.Code, '', 100, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item,
            ParentItem."No.", Location.Code, '', 1);

        // [GIVEN] Create Inventory Pick for the Job
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [GIVEN] Find Warehouse Activity Header 
        FindWarehouseActivityHeader(WarehouseActivityHeader, Job, Location);

        // [WHEN] Inventory Pick is posted
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke();

        // [THEN] Verify results
        SetFiltersToPostedATOLink(JobTask, JobPlanningLine, PostedATOLink);
        Assert.RecordIsNotEmpty(PostedATOLink);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure PostJobJournalLinesForTwoPlanningLinesWithSameAssemblyItem()
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ItemJournalLine: Record "Item Journal Line";
        JobJournalLine: Record "Job Journal Line";
        i: Integer;
    begin
        // [SCENARIO 561041] Verify post job journal lines for two planning lines with same assembly item
        Initialize();

        // [GIVEN] Create an assembly item with 2 components.
        CreateAssemblyItemWithBOM(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Add components to inventory
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem1."No.");
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem2."No.");

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(Job, JobTask);

        // [WHEN] Create Job Planning Line and Job Journal Line 2 times
        for i := 1 to 2 do begin
            // Create Job Planning Line
            CreateSimpleJobPlanningLineWithAssemblyItem(JobPlanningLine, JobTask, ParentItem."No.");

            // Validate Quantity on Job Planning Line
            JobPlanningLine.Validate("Quantity", 1);
            JobPlanningLine.Modify(true);

            // Create Job Journal Line
            LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, "Job Line Type"::Budget, 1, JobJournalLine);
            JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            JobJournalLine.Modify(true);
        end;

        // [THEN] Verify Post usage from Job Journal
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Jobs - Assemble-to Order");
        LibrarySetupStorage.Restore();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Jobs - Assemble-to Order");

        UpdateInventorySetup();
        UpdateNoSeries();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Jobs - Assemble-to Order");
    end;

    local procedure UpdateNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Inventory Pick Nos." = '' then
            InventorySetup."Inventory Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        if InventorySetup."Posted Invt. Pick Nos." = '' then
            InventorySetup."Posted Invt. Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup.Modify(true);
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

    local procedure UpdateCostFieldsInInventorySetup(AutomaticCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
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

    local procedure UpdateInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        Evaluate(InventorySetup."Default Safety Lead Time", '<0D>');
        InventorySetup.Modify(true);
    end;

    local procedure SetFiltersToATOLink(JobTask: Record "Job Task"; JobPlanningLine: Record "Job Planning Line"; var ATOLink: Record "Assemble-to-Order Link")
    begin
        ATOLink.SetRange(Type, ATOLink.Type::"Job");
        ATOLink.SetRange("Job No.", JobTask."Job No.");
        ATOLink.SetRange("Job Task No.", JobTask."Job Task No.");
        ATOLink.SetRange("Document Line No.", JobPlanningLine."Line No.");
    end;

    local procedure SetFiltersToPostedATOLink(JobTask: Record "Job Task"; JobPlanningLine: Record "Job Planning Line"; var PostedATOLink: Record "Posted Assemble-to-Order Link")
    begin
        PostedATOLink.SetRange("Job No.", JobTask."Job No.");
        PostedATOLink.SetRange("Job Task No.", JobTask."Job Task No.");
        PostedATOLink.SetRange("Document Line No.", JobPlanningLine."Line No.");
    end;

    local procedure CreateJobAndJobTask(var Job: Record Job; var JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateSimpleJobPlanningLineWithAssemblyItem(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; AssemblyItemNo: Code[20])
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Insert(true);

        JobPlanningLine.Validate("Type", JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", AssemblyItemNo);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithData(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; Number: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, Type, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Number);
        JobPlanningLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            JobPlanningLine.Validate("Bin Code", BinCode);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; No: Code[20]; JobTask: Record "Job Task")
    begin
        // Use Random values for Quantity and Unit Cost because values are not important.
        LibraryJob.CreateJobPlanningLine(LineType, Type, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 20));
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandInt(100));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateAssemblyItemWithBOM(var AssemblyItem: Record Item; var BomComponentItem1: Record Item; var BomComponentItem2: Record Item)
    begin
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", Enum::"Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Modify(true);

        // Create Component Item and set as Assembly BOM
        CreateAssemblyBomComponent(BomComponentItem1, AssemblyItem."No.");
        CreateAssemblyBomComponent(BomComponentItem2, AssemblyItem."No.");
        Commit(); // Save the BOM Component record created above
    end;

    local procedure CreateAssemblyBomComponent(var Item: Record Item; ParentItemNo: Code[20])
    var
        BomComponent: Record "BOM Component";
        BomRecordRef: RecordRef;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        BomComponent.Init();
        BomComponent.Validate(BomComponent."Parent Item No.", ParentItemNo);
        BomRecordRef.GetTable(BomComponent);
        BomComponent.Validate(BomComponent."Line No.", LibraryUtility.GetNewLineNo(BomRecordRef, BomComponent.FieldNo(BomComponent."Line No.")));
        BomComponent.Validate(BomComponent.Type, BomComponent.Type::Item);
        BomComponent.Validate(BomComponent."No.", Item."No.");
        BomComponent.Validate(BomComponent."Quantity per", LibraryRandom.RandInt(10));
        BomComponent.Insert(true);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo,
          LibraryRandom.RandDecInRange(50, 100, 2)); // Use random Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetFilterOnExplodedJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLine.SetFilter(Type, '<>%1', JobPlanningLine.Type::Text);
    end;

    local procedure FilterJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Text);
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; Job: Record Job; Location: Record Location)
    begin
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Assemble to Order", false);
        WarehouseActivityLine.FindFirst();
    end;

    [ModalPageHandler]
    procedure JobTransferJobPlanningLinePageHandler(var JobTransferJobPlanningLine: TestPage "Job Transfer Job Planning Line")
    var
        JobJournalTemplateName: Code[10];
        JobJournalBatchName: Code[10];
    begin
        JobJournalTemplateName := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(JobJournalTemplateName));
        JobJournalBatchName := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(JobJournalBatchName));
        JobTransferJobPlanningLine.JobJournalTemplateName.SetValue(JobJournalTemplateName);
        JobTransferJobPlanningLine.JobJournalBatchName.SetValue(JobJournalBatchName);
        JobTransferJobPlanningLine.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

