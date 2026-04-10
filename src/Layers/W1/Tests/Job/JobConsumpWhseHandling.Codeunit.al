codeunit 136320 "Job Consump. Whse. Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Job] [Pick] [Consumption]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        InvtPickActivitiesCreatedMsg: Label 'Number of Invt. Pick activities created';
        QuantityErr: Label 'Quantity must be %1 in %2', Comment = '%1 = Job Planning Line Quantity, %2 = Warehouse Activity Line';

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure JobConsumpAsNoWhseHandling_ThrowsNothingToCreateMsg()
    var
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Job: Record Job;
        MessageShown: Text;
        ThereIsNothingToCreateMsg: Label 'There is nothing to create.';
    begin
        // [SCENARIO] 'There is nothing to create' message is shown when Job Consumption is set to 'No Warehouse Handling'.
        Initialize();

        // [GIVEN] Create needed setup with Job 2 items needed for the job
        CreateJobWithLocationBinsAndTwoComponents(Job, Location, "Job Consump. Whse. Handling"::"No Warehouse Handling", CompItem1, CompItem2);

        // [WHEN] Create Inventory Pick is run for the Job.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [THEN] 'There is nothing to create' message is shown.'.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure JobConsumpAsInvtPick_CreatesInventoryPickLines()
    var
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Job: Record Job;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Job Consumption set to 'Inventory Pick' creates inventory pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with Job 2 items needed for the job
        CreateJobWithLocationBinsAndTwoComponents(Job, Location, "Job Consump. Whse. Handling"::"Inventory Pick", CompItem1, CompItem2);

        // [WHEN] Create Inventory Pick is run for the Job order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [THEN] 2 'Take' inventory pick lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, Job."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,SimpleMessageHandler')]
    procedure JobConsumpAsWhsePickMandatory_CreateWhsePickLines()
    var
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Job: Record Job;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Job Consumption set to 'Warehouse Pick (Mandatory)', creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with Job 2 items needed for the job
        CreateJobWithLocationBinsAndTwoComponents(Job, Location, "Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)", CompItem1, CompItem2);

        // [WHEN] Create Warehouse Pick document lines is run for the Job order.
        Job.CreateWarehousePick();

        // [THEN] 2 'Take' warehouse pick lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, Job."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        // [THEN] 2 'Place' warehouse pick lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, Job."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('WhseSrcCreateDocReqHandler,SimpleMessageHandler')]
    procedure JobConsumpAsWhsePickOptional_CreateWhsePickLines()
    var
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Job: Record Job;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Job Consumption set to 'Warehouse Pick (Optional)', creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with Job 2 items needed for the job
        CreateJobWithLocationBinsAndTwoComponents(Job, Location, "Job Consump. Whse. Handling"::"Warehouse Pick (Optional)", CompItem1, CompItem2);

        // [WHEN] Create Warehouse Pick document lines is run for the Job order.
        Job.CreateWarehousePick();

        // [THEN] 2 'Take' warehouse pick lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, Job."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        // [THEN] 2 'Place' warehouse pick lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, Job."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure RequirePickOrShipDoesNotInfluenceJobConsumptionWhseHandling()
    begin
        RequirePickOrShipDoesNotInfluenceJobConsumptionWhseHandling(false, false);
        RequirePickOrShipDoesNotInfluenceJobConsumptionWhseHandling(false, true);
        RequirePickOrShipDoesNotInfluenceJobConsumptionWhseHandling(true, false);
        RequirePickOrShipDoesNotInfluenceJobConsumptionWhseHandling(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler,JobCalcRemainingUsageHandler,ConfirmHandlerTrue')]
    procedure PickEnforcedWhenWarehousePickIsSet()
    begin
        // Throw error is "Job Consump. Whse. Handling" is set to "Warehouse Pick (mandatory)" and there is no pick.
        asserterror CreateAndPostJobUsage(Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Assert.ExpectedError('remains to be picked.');

        // Allow posting usage if "Job Consump. Whse. Handling" is set to "Inventory Pick" and there is no pick.
        CreateAndPostJobUsage(Enum::"Job Consump. Whse. Handling"::"Inventory Pick");

        // Creating and posting succeeds when "Job Consump. Whse. Handling" is set to "Warehouse Pick (optional)" or "No Warehouse Handling".
        CreateAndPostJobUsage(Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (optional)");
        CreateAndPostJobUsage(Enum::"Job Consump. Whse. Handling"::"No Warehouse Handling");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure EnablingDisablingJobConsumpWhseHandlingOnLocation()
    var
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Job: Record Job;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [SCENARIO] Cannot disable job consump. whse. handling on location if an inventory activity for job usage exists.
        Initialize();

        CreateJobWithLocationBinsAndTwoComponents(Job, Location, "Job Consump. Whse. Handling"::"Inventory Pick", CompItem1, CompItem2);

        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        Commit();
        asserterror Location.Validate("Job Consump. Whse. Handling", "Job Consump. Whse. Handling"::"No Warehouse Handling");

        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityHeader.Delete(true);

        Location.Validate("Job Consump. Whse. Handling", "Job Consump. Whse. Handling"::"No Warehouse Handling");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutAwayPickMvmtRequestPageHandler,InvtPickCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtPickWhseActivityLinesTakesQtyFromJobPlanningLinesWhenCreateInvtPickFromJob()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: array[2] of Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        Job: Record Job;
        JobTask: array[2] of Record "Job Task";
        JobPlanningLine: array[2] of Record "Job Planning Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 540094] When Stan runs Create Inventory Pick from a Job then the Inventory Pick Lines created 
        // Will have Quantity equal to Job Planning Lines Quantity.
        Initialize();

        // [GIVEN] Create an Item and Validate Replenishment System, Reorderding Policy and Reserve.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        // [GIVEN] Create a Location and Validate Require Pick, Bin Mandatory and Job Consump. Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Job Consump. Whse. Handling", Location."Job Consump. Whse. Handling"::"Inventory Pick");
        Location.Modify(true);

        // [GIVEN] Create two Bins.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Create an Item Journal Line.
        LibraryInventory.CreateItemJnlLine(
            ItemJournalLine,
            ItemJournalLine."Entry Type"::"Positive Adjmt.",
            WorkDate(),
            Item."No.",
            LibraryRandom.RandIntInRange(10, 10),
            Location.Code);

        // [GIVEN] Validate Bin Code in Item Journal Line.
        ItemJournalLine.Validate("Bin Code", Bin[1].Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a Job.
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create two Job Tasks.
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);

        // [GIVEN] Create Job Planning Line and Reserve Quantity.
        CreateJobPlanningLineAndReserveQty(JobPlanningLine[1], JobTask[1], Item, Location, Bin[1], LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Create Job Planning Line 2 and Reserve Quantity.
        CreateJobPlanningLineAndReserveQty(JobPlanningLine[2], JobTask[2], Item, Location, Bin[1], LibraryRandom.RandIntInRange(4, 4));
        Commit();

        // [GIVEN] Create Inventory Pick.
        Job.CreateInvtPutAwayPick();

        // [WHEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] Quantity in Warehouse Activity Line must be equal to Quantity in Job Planning Line.
        Assert.AreEqual(
            JobPlanningLine[1].Quantity,
            WarehouseActivityLine.Quantity,
            StrSubstNo(
                QuantityErr,
                JobPlanningLine[1].Quantity,
                WarehouseActivityLine.TableCaption()));

        // [WHEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindLast();

        // [THEN] Quantity in Warehouse Activity Line must be equal to Quantity in Job Planning Line 2.
        Assert.AreEqual(
            JobPlanningLine[2].Quantity,
            WarehouseActivityLine.Quantity,
            StrSubstNo(
                QuantityErr,
                JobPlanningLine[2].Quantity,
                WarehouseActivityLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Consump. Whse. Handling");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Consump. Whse. Handling");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SavePurchasesSetup();

        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Consump. Whse. Handling");
    end;

    procedure RequirePickOrShipDoesNotInfluenceJobConsumptionWhseHandling(RequirePick: Boolean; RequireShipment: Boolean)
    var
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Job Consumption set to 'Inventory Pick' creates inventory pick lines for consumption.
        Initialize();

        // [GIVEN] Create Location with 5 bins.
        CreateLocationSetupWithBins(Location, false, RequirePick, false, RequireShipment, true, 5, false);
        Location.Validate("Job Consump. Whse. Handling", Enum::"Job Consump. Whse. Handling"::"Inventory Pick");
        Location.Modify(true);

        // [GIVEN] Create items needed for the job.
        LibraryInventory.CreateItem(CompItem1);
        LibraryInventory.CreateItem(CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, CompItem1."No.", Location.Code, '', 2);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, CompItem1."No.", Location.Code, '', 2);

        // [WHEN] Create Inventory Pick is run for the Job order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Job Usage", Job."No.", false, true, false);

        // [THEN] 2 'Take' inventory pick lines are created 
        FindWarehouseActivityLine(
          WarehouseActivityLine, Job."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    procedure CreateAndPostJobUsage(JobConsumpWhseHandling: Enum "Job Consump. Whse. Handling")
    var
        CompItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
    begin
        // [SCENARIO] Job Posting fails if pick is mandatory.
        Initialize();

        // [GIVEN] Create Location with 5 bins and set the "Job Consump. Whse. Handling".
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);
        Location.Validate("Job Consump. Whse. Handling", JobConsumpWhseHandling);
        Location.Modify(true);

        // [GIVEN] Create items needed for the job.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] A Job with the item in the planning line
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, CompItem."No.", Location.Code, '', 2);

        // [GIVEN] Create a Job Journal Batch
        CreateJobJournalBatch(JobJournalBatch);

        // [WHEN] "Job Calc. Remaining Usage" is run.
        RunJobCalcRemainingUsage(JobJournalBatch, JobTask);

        // [THEN] Job Journal Line is created.
        FindJobJournalLine(JobJournalLine, JobJournalBatch."Journal Template Name", JobJournalBatch.Name);

        // [GIVEN] Set "Line Type" and "Job Planning Line No." on Job Journal Line.
        JobJournalLine.Validate("Line Type", JobJournalLine."Line Type"::Budget);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.Modify(true);

        // [WHEN] "Job Journal" is posted.
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Job Journal Line is posted or error is thrown.
        // Caller ensures the error is validated
    end;

    local procedure CreateJobWithLocationBinsAndTwoComponents(var Job: Record Job; var Location: Record Location; JobConsumpWhseHandling: Enum "Job Consump. Whse. Handling"; var CompItem1: Record Item; var CompItem2: Record Item)
    var
        Bin: Record Bin;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [GIVEN] Create Location with 5 bins.
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);
        Location.Validate("Job Consump. Whse. Handling", JobConsumpWhseHandling);
        Location.Modify(true);

        // [GIVEN] Create items needed for the job.
        LibraryInventory.CreateItem(CompItem1);
        LibraryInventory.CreateItem(CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line 
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, CompItem1."No.", Location.Code, '', 2);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, CompItem1."No.", Location.Code, '', 2);
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

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure VerifyPickLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ExpectedPickLines: Integer)
    begin
        // [THEN] Expected number of pick lines are created
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Expected number of pick lines are created
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Bin is set
        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateLocationSetupWithBins(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean; NoOfBins: Integer; UseBinRanking: Boolean)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false); // Value required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        if UseBinRanking then begin
            Bin.SetRange("Location Code", Location.Code);
            if Bin.FindSet() then
                repeat
                    Bin.Validate("Bin Ranking", LibraryRandom.RandIntInRange(100, 1000));
                    Bin.Modify(true);
                until Bin.Next() = 0;
        end;
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryInventory.NoSeriesSetup(InventorySetup);
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate1: Record "Item Journal Template"; var ItemJournalBatch1: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate1, ItemJournalTemplateType);
        ItemJournalTemplate1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate1.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch1, ItemJournalTemplate1.Type, ItemJournalTemplate1.Name);
        ItemJournalBatch1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch1.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch1: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch1.Validate("No. Series", NoSeries);
        ItemJournalBatch1.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal;
                                                                                  LocationCode: Code[10];
                                                                                  BinCode: Code[20];
                                                                                  UseTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if UseTracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure FindJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        JobJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        JobJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        JobJournalLine.FindFirst();
    end;

    local procedure CreateJobJournalBatch(var JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
    end;

    local procedure RunJobCalcRemainingUsage(JobJournalBatch: Record "Job Journal Batch"; JobTask: Record "Job Task")
    var
        JobCalcRemainingUsage: Report "Job Calc. Remaining Usage";
        NoSeries: Codeunit "No. Series";
    begin
        JobTask.SetRange("Job No.", JobTask."Job No.");
        JobTask.SetRange("Job Task No.", JobTask."Job Task No.");
        Commit();  // Commit required for batch report.
        Clear(JobCalcRemainingUsage);
        JobCalcRemainingUsage.SetBatch(JobJournalBatch."Journal Template Name", JobJournalBatch.Name);
        JobCalcRemainingUsage.SetDocNo(NoSeries.PeekNextNo(JobJournalBatch."No. Series"));
        JobCalcRemainingUsage.SetTableView(JobTask);
        JobCalcRemainingUsage.Run();
    end;

    local procedure CreateJobPlanningLineAndReserveQty(
        var JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Qty: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Location Code", Location.Code);
        JobPlanningLine.Validate("Bin Code", Bin.Code);
        JobPlanningLine.Validate("Quantity", Qty);
        JobPlanningLine.Modify(true);

        JobPlanningLine.AutoReserve();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure InvtPickCreatedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, InvtPickActivitiesCreatedMsg) > 0, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSrcCreateDocReqHandler(var WhseSourceCreateDocumentReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocumentReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCalcRemainingUsageHandler(var JobCalcRemainingUsage: TestRequestPage "Job Calc. Remaining Usage")
    begin
        JobCalcRemainingUsage.PostingDate.SetValue(Format(WorkDate()));
        JobCalcRemainingUsage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPutAwayPickMvmtRequestPageHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}