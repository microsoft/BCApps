codeunit 136319 "Job Item Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Pick] [Item Tracking]
        // Common Item Tracking Codes:
        // SNALL - SN Tracking =True
        // SNWMS - SN tracking = true and SN WMS = true
        // SNJOB - SN tracking = false, Neg.Adj.inbound/outbound = true
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        LocationWithRequirePickBinMandatory: Record Location;
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        WhseBin1: Record Bin;
        WhseBin2: Record Bin;
        WhseBin3: Record Bin;
        LocationWithRequirePick: Record Location;
        LocationRequireWhsePick: Record Location;
        LocationRequireWhsePickBinMandatory: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        Assert: Codeunit Assert;
        ItemTrackingHandlerAction: Option Assign,AssignSpecific,AssignSpecificLot,AssignMultiple,Select,NothingToHandle,SelectWithQtyToHandle,ChangeSelection,ChangeSelectionLot,ChangeSelectionLotLast,ChangeSelectionQty,AssignLot;
        IsInitialized: Boolean;
        ReInitializeJobSetup: Boolean;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntriesOfTypeSurplusCreatedWhenCreatedFromJobPlanningLines()
    var
        Item: Record Item;
        SerialTrackedItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Reservation entries of reservation status 'Surplus' is created when reserved from 'Job Planning Lines' page
        // [GIVEN] Inventory pick relevant Location, normal item and serially tracked item with sufficient quantity in the inventory for a Bin Code
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSerialTrackedItem(SerialTrackedItem, false);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, SerialTrackedItem."No.", LocationWithRequirePick.Code, '', 2);

        // [GIVEN] Create Inventory Pick for the Job
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines(); // ItemTrackingLinesAssignPageHandler

        // [THEN] Reservation Entries are created
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", JobPlanningLine2."Job No.");
        ReservationEntry.SetRange("Item No.", JobPlanningLine2."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine2."Job Contract Entry No.");

        Assert.RecordCount(ReservationEntry, 2);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure EmptySerialNoForSerialTrackedItemThrowsErrorOnPosting()
    var
        Item: Record Item;
        SerialTrackedItem: Record Item;
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
        // [SCENARIO] Empty serial number on serial tracked item throws error while posting
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
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, SerialTrackedItem."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Create Inventory Pick for the Job
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Make sure 2 lines are created
        WarehouseActivityLinePick.SetRange("Source Type", Database::Job);
        WarehouseActivityLinePick.SetRange("Source Document", WarehouseActivityLinePick."Source Document"::"Job Usage");
        WarehouseActivityLinePick.SetRange("Source No.", Job."No.");
        Assert.RecordCount(WarehouseActivityLinePick, 2);

        // [GIVEN] Serial No. field is empty
        WarehouseActivityLinePick.ModifyAll("Serial No.", '');

        // [WHEN] Inventory Pick is posted
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", Job."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Error: Posting is not possible without assigning a Serial Number
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        InventoryPickPage.AutofillQtyToHandle.Invoke();
        asserterror InventoryPickPage."P&ost".Invoke();
        Assert.ExpectedError('You must assign a serial number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenItemTrackingCalledOnNonTrackedItemOnJobPlanningLine()
    var
        Item: Record Item;
        SerialTrackedItem: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Error is thrown when 'Item Tracking' is called on Job Planning Line where the selected item is not setup to be tracked
        // [GIVEN] Inventory pick relevant Location, normal item and serially tracked item with sufficient quantity in the inventory for a Bin Code
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSerialTrackedItem(SerialTrackedItem, true);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [WHEN] 'Item Tracking Lines' is opened
        asserterror JobPlanningLine1.OpenItemTrackingLines();

        // [THEN] Error is thrown
        Assert.ExpectedError('must have a value in');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenItemTrackingCalledOnBillableJobPlanningLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Error is thrown when 'Item Tracking' is called on Job Planning Line where Line Type is Billable
        // [GIVEN] Inventory pick relevant Location, normal item with sufficient quantity in the inventory with Bin Code
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with both the created item in the planning line
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Billable
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Billable, JobPlanningLine.Type::Item, Item."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, LibraryRandom.RandInt(10));

        // [WHEN] 'Item Tracking Lines' is opened
        asserterror JobPlanningLine.OpenItemTrackingLines();

        // [THEN] Error is thrown
        Assert.ExpectedError('Line Type must be');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenItemTrackingCalledOnNonItemJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryResource: codeunit "Library - Resource";
        ResourceNo: Code[20];
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Error is thrown when 'Item Tracking' is called on Job Planning Line where Type is not Item
        // [GIVEN] Inventory pick relevant Location, normal item with sufficient quantity in the inventory with Bin Code
        Initialize();

        ResourceNo := LibraryResource.CreateResourceNo();

        // [GIVEN] A Job with a Resource in the planning line
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Resource, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Resource, ResourceNo, LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        // [WHEN] 'Item Tracking Lines' is opened
        asserterror JobPlanningLine.OpenItemTrackingLines();

        // [THEN] Error is thrown
        Assert.ExpectedError('must be equal to');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,JobTransferFromJobPlanLineHandler,MessageHandler,ConfirmHandlerTrue,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure TransferringFromPlanningLineToJournalLineTransfersItemTracking()
    var
        SerialTrackedItem: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ReservationEntry: Record "Reservation Entry";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Transferring from job planning line to job journal line transfers ItemTracking
        // [GIVEN] Location, serial tracked item with sufficient quantity in the inventory
        Initialize();

        CreateSerialTrackedItem(SerialTrackedItem, true);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with the item in the planning line
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, SerialTrackedItem."No.", LocationWithRequirePick.Code, '', LibraryRandom.RandInt(10));

        // [GIVEN] 'Item Tracking Lines' is opened
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine.OpenItemTrackingLines();

        // [WHEN] Creating Job Journal Lines from Job Planning Lines
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [THEN] Reservation entries are also transferred
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");

        // [WHEN] Post Job Journal -> verify tracking is handled
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange(Type, JobJournalLine.Type::Item);
        JobJournalLine.SetRange("Line Type", JobJournalLine."Line Type"::Budget);
        Assert.RecordCount(JobJournalLine, 1);
        JobJournalLine.FindFirst();

        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Reservation Entries are deleted
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", SerialTrackedItem."No.");
        Assert.RecordCount(ReservationEntry, 0);

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,JobTransferFromJobPlanLineHandler,MessageHandler,ConfirmHandlerTrue,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateTransferredSNAndPostJobJournalDeletesAllReservationEntries()
    var
        SerialTrackedItem: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ProspectSerialNo: Code[50];
        SurplusSerialNo: Code[50];
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Modifying and Posting the Job Journal with the transferred ItemTracking with serial no. from Job Planning Line deletes all the related reservation entries.
        // [GIVEN] Location, serial tracked item with sufficient quantity in the inventory
        Initialize();

        CreateSerialTrackedItem(SerialTrackedItem, true);
        QtyInventory := 2;
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with the item in the planning line
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, SerialTrackedItem."No.", LocationWithRequirePick.Code, '', 1);

        // [GIVEN] 'Item Tracking Lines' is opened
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine.OpenItemTrackingLines();

        // [WHEN] Creating Job Journal Lines from Job Planning Lines
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [THEN] Reservation entries are also transferred
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");

        // [WHEN] Update item tracking on Job Journal Line
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange(Type, JobJournalLine.Type::Item);
        JobJournalLine.SetRange("Line Type", JobJournalLine."Line Type"::Budget);
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelection);
        LibraryVariableStorage.Enqueue(GetUnassignedSerialNo(SerialTrackedItem, LocationWithRequirePick.Code));
        JobJournalLine.OpenItemTrackingLines(false);

        // [THEN] There are two reservation entries with different serial numbers. First for Surplus (JobPlanningLine), Second for Prospect (JobJournalLine)
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");
        ReservationEntry.FindFirst();
        SurplusSerialNo := ReservationEntry."Serial No.";

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");
        ReservationEntry.FindFirst();
        ProspectSerialNo := ReservationEntry."Serial No.";

        Assert.AreNotEqual(ProspectSerialNo, SurplusSerialNo, StrSubstNo('Reservation entry should have different serial number for %1', ReservationEntry."Reservation Status"::Prospect));

        // [WHEN] Post Job Journal
        JobJournalLine.FindFirst();
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Reservation Entries are deleted including intermediate reservation entries created for Item Journal Lines.
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", SerialTrackedItem."No.");
        Assert.RecordCount(ReservationEntry, 0);

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobTransferFromJobPlanLineHandler,MessageHandler,ConfirmHandlerTrue,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateTransferredLotNoAndPostJobJournalDeletesAllReservationEntries()
    var
        LotTrackedItem: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ProspectLotNo: Code[50];
        SurplusLotNo: Code[50];
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Modifying and Posting the Job Journal with the transferred ItemTracking with lot no. from Job Planning Line deletes all the related reservation entries.
        // [GIVEN] Location, lot tracked item with sufficient quantity in the inventory
        Initialize();

        CreateLotTrackedItem(LotTrackedItem, true);
        QtyInventory := 2;
        CreateAndPostInvtAdjustmentWithLotTracking(LotTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(LotTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with the item in the planning line
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, LotTrackedItem."No.", LocationWithRequirePick.Code, '', 1);

        // [GIVEN] 'Item Tracking Lines' is opened
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine.OpenItemTrackingLines();

        // [WHEN] Creating Job Journal Lines from Job Planning Lines
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [THEN] Reservation entries are also transferred
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", LotTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");

        // [WHEN] Update item tracking on Job Journal Line
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange(Type, JobJournalLine.Type::Item);
        JobJournalLine.SetRange("Line Type", JobJournalLine."Line Type"::Budget);
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelectionLot);
        LibraryVariableStorage.Enqueue(GetUnassignedLotNo(LotTrackedItem, LocationWithRequirePick.Code));
        JobJournalLine.OpenItemTrackingLines(false);

        // [THEN] There are two reservation entries with different lot numbers. First for Surplus (JobPlanningLine), Second for Prospect (JobJournalLine)
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", LotTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");
        ReservationEntry.FindFirst();
        SurplusLotNo := ReservationEntry."Lot No.";

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");
        ReservationEntry.FindFirst();
        ProspectLotNo := ReservationEntry."Lot No.";

        Assert.AreNotEqual(ProspectLotNo, SurplusLotNo, StrSubstNo('Reservation entry should have different lot number for %1', ReservationEntry."Reservation Status"::Prospect));

        // [WHEN] Post Job Journal
        JobJournalLine.FindFirst();
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Reservation Entries are deleted including intermediate reservation entries created for Item Journal Lines.
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", LotTrackedItem."No.");
        Assert.RecordCount(ReservationEntry, 0);

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,JobTransferFromJobPlanLineHandler,MessageHandler,ConfirmHandlerTrue,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SplitLotNoAndPostTransferredJobJournalDeletesAllReservationEntries()
    var
        LotTrackedItem: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ReservationEntry: Record "Reservation Entry";
        UnusedLotNo: Code[50];
        LotNumbersUsed: List of [Code[50]];
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Splitting and Posting the Job Journal with the transferred ItemTracking with lot no. from Job Planning Line deletes all the related reservation entries.
        // [GIVEN] Location, lot tracked item with sufficient quantity in the inventory
        Initialize();
        CreateLotTrackedItem(LotTrackedItem, true);
        QtyInventory := 4;
        // 3 Lots are assigned.
        CreateAndPostInvtAdjustmentWithLotTracking(LotTrackedItem."No.", LocationWithRequirePick.Code, '', 4, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(LotTrackedItem."No.", LocationWithRequirePick.Code, '', 2, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(LotTrackedItem."No.", LocationWithRequirePick.Code, '', 2, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with the item in the planning line
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine.Type::Item, LotTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [GIVEN] 'Item Tracking Lines' is opened
        // Item tracking is assigned as Lot1 = Qty 3; Lot2 = Qty 1
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine.OpenItemTrackingLines(); //Creates Lot 1 with Qty 4
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelectionQty);
        LibraryVariableStorage.Enqueue(3);
        JobPlanningLine.OpenItemTrackingLines(); //Creates Lot 1 with Qty 3

        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSpecificLot);
        UnusedLotNo := GetUnassignedLotNo(LotTrackedItem, LocationWithRequirePick.Code);
        LibraryVariableStorage.Enqueue(UnusedLotNo);
        LibraryVariableStorage.Enqueue(1);
        JobPlanningLine.OpenItemTrackingLines(); //Creates Lot 2 with Qty 1

        // [WHEN] Creating Job Journal Lines from Job Planning Lines
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [THEN] Reservation entries are also transferred (2 lots created)
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", LotTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, 2);

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, 2);

        // [WHEN] Split the item tracking on Job Journal Line into
        // Lot1: Qty 3
        // Lot3: Qty 1
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange(Type, JobJournalLine.Type::Item);
        JobJournalLine.SetRange("Line Type", JobJournalLine."Line Type"::Budget);
        JobJournalLine.FindFirst();

        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelectionLotLast);
        UnusedLotNo := GetUnassignedLotNo(LotTrackedItem, LocationWithRequirePick.Code);
        LibraryVariableStorage.Enqueue(UnusedLotNo);
        JobJournalLine.OpenItemTrackingLines(false);

        // [THEN] There are 4 reservation entries with 3 lot numbers.
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", LotTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, 2);
        ReservationEntry.FindSet();
        repeat
            if not LotNumbersUsed.Contains(ReservationEntry."Lot No.") then
                LotNumbersUsed.Add(ReservationEntry."Lot No.");
        until ReservationEntry.Next() = 0;

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        Assert.RecordCount(ReservationEntry, 2);
        ReservationEntry.FindSet();
        repeat
            if not LotNumbersUsed.Contains(ReservationEntry."Lot No.") then
                LotNumbersUsed.Add(ReservationEntry."Lot No.");
        until ReservationEntry.Next() = 0;

        Assert.AreEqual(3, LotNumbersUsed.Count, 'Three different lot numbers should have been used.');

        // [WHEN] Post Job Journal
        JobJournalLine.FindFirst();
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Reservation Entries are deleted including intermediate reservation entries created for Item Journal Lines.
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", LotTrackedItem."No.");
        Assert.RecordCount(ReservationEntry, 0);

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,JobTransferToSalesInvoiceReqHandler,MessageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenOpeningItemTrackingFromSalesInvoice()
    var
        SerialTrackedItem: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        JobPlanningLinesPage: TestPage "Job Planning Lines";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Serial Number information is not transferred to Invoice. Item tracking line cannot be opened for the line transferred to Sales Invoice.
        // [GIVEN] Location, serial tracked item with sufficient quantity in the inventory
        Initialize();

        CreateSerialTrackedItem(SerialTrackedItem, true);
        QtyInventory := 1;
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] A Job with a task
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = Item, Line Type = Both Budget and Billable
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, SerialTrackedItem."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [GIVEN] 'Item Tracking Lines' is opened
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine.OpenItemTrackingLines();

        // [THEN] Reservation entries are created
        ReservationEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");

        // [WHEN] Create Sales Invoice
        JobPlanningLinesPage.OpenEdit();
        JobPlanningLinesPage.GoToRecord(JobPlanningLine);
        JobPlanningLinesPage."Create &Sales Invoice".Invoke(); //JobTransferToSalesInvoiceReqHandler

        // [WHEN] Open the created Sales Invoice
        SalesLine.SetRange("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
        SalesLine.FindFirst();

        // [THEN] Item tracking lines cannot be opened for the transferred line
        asserterror SalesLine.OpenItemTrackingLines();
        Assert.ExpectedError('You cannot use item tracking');

        // [THEN] Reservation Entries is not changed
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Item No.", SerialTrackedItem."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        Assert.RecordCount(ReservationEntry, JobPlanningLine."Quantity (Base)");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferFromJobPlanLineHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnJobPlanningLinePropagatedToJobJnlLinesBlnkLocation()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Item tracking from Job planning line is propagated to job journal lines for blank locations
        // [GIVEN] Job planning lines with ItemSNAll, ItemSNWMS, ItemNegAdj
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 10;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);
        // [GIVEN] 3 Job Planning Lines for Job Task T1, Location= Blank, Line Type = Budget, for the given items
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", '', '', LibraryRandom.RandInt(QtyInventory));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", '', '', LibraryRandom.RandInt(QtyInventory));
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", '', '', LibraryRandom.RandInt(QtyInventory));

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 1 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 3 and a new serial number is assigned for ItemNegAdj
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();

        // [THEN] Reservation entries are updated
        VerifyReservationEntry(JobPlanningLine1, JobPlanningLine1.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, JobPlanningLine2.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine3, JobPlanningLine3.Quantity, -1, ReservationStatus::Surplus);

        // [WHEN] Job Planning Lines are transferred to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        // [THEN] Reservation entry is created with source as job journal line
        // [THEN] Reservation entries created for Job journal line has the same serial numbers assigned.
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        Assert.RecordCount(JobJournalLine, 3);
        MatchResEntriesAfterTransferToJobJnl(JobJournalLine); // Reservation Entries are not transferred to Job Journal

        // [WHEN] Post job journal lines for all the planning lines.
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] Serial numbers in Job Planning Lines are consumed i.e. Reservation Entries are updated.
        ReservationEntry.SetRange("Source ID", JobTask."Job No.");
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferFromJobPlanLineHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingIsReplacedOnJobJnlLinesBlnkLocation()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyInventory: Integer;
        SerialNo1: Code[20];
        SerialNo2: Code[20];
        SerialNo3: Code[20];
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Item tracking from Job planning line is propagated to job journal lines for blank locations and replaced in job journal.
        // [GIVEN] Job planning lines with ItemSNAll, ItemSNWMS, ItemNegAdj
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 5;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);
        // [GIVEN] 3 Job Planning Lines for Job Task T1, Location= Blank, Line Type = Budget, for the given items and quantity = 2
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", '', '', 2);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", '', '', 2);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", '', '', 2);

        // [GIVEN] Job Planning Line Quantity to Transfer is set to 1.
        JobPlanningLine1.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine1.Modify(true);
        JobPlanningLine2.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine2.Modify(true);
        JobPlanningLine3.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine3.Modify(true);

        // [WHEN] Assign serial numbers using item tracking page on job planning line and update Qty. To Handle to 0 for second serial no.
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::SelectWithQtyToHandle);
            LibraryVariableStorage.Enqueue(1);
            LibraryVariableStorage.Enqueue(0);
            JobPlanningLine.OpenItemTrackingLines();
        until JobPlanningLine.Next() = 0;

        // [WHEN] Job Planning Lines are transferred to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        // [WHEN] Serial Number is replaced on Job Journal Line
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine1."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelection);
        SerialNo1 := GetUnassignedSerialNo(ItemSNAll);
        LibraryVariableStorage.Enqueue(SerialNo1);
        JobJournalLine.OpenItemTrackingLines(false);

        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine2."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelection);
        SerialNo2 := GetUnassignedSerialNo(ItemSNWMS);
        LibraryVariableStorage.Enqueue(SerialNo2);
        JobJournalLine.OpenItemTrackingLines(false);

        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine3."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelection);
        SerialNo3 := GetUnassignedSerialNo(ItemNegAdj);
        LibraryVariableStorage.Enqueue(SerialNo3);
        JobJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post job journal lines for all the planning lines.
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] Posting is sucessful and all the job journal lines are deleted
        JobJournalLine.SetRange("Job Planning Line No.");
        asserterror JobJournalLine.FindSet();

        // [THEN] Item Ledger Entries have the serial number that was set on JobJournalLine
        FindItemLedgerEntry(ItemLedgerEntry, ItemSNAll."No.", JobTask."Job No.", JobTask."Job No.", JobTask."Job Task No.");
        ItemLedgerEntry.TestField("Serial No.", SerialNo1);

        FindItemLedgerEntry(ItemLedgerEntry, ItemSNWMS."No.", JobTask."Job No.", JobTask."Job No.", JobTask."Job Task No.");
        ItemLedgerEntry.TestField("Serial No.", SerialNo2);

        FindItemLedgerEntry(ItemLedgerEntry, ItemNegAdj."No.", JobTask."Job No.", JobTask."Job No.", JobTask."Job Task No.");
        ItemLedgerEntry.TestField("Serial No.", SerialNo3);

        // [THEN] Reservation Entries exist for Serial number with Qty. To Handle = 0.
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source ID", JobTask."Job No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Qty. to Handle (Base)", 0);
        Assert.RecordCount(ReservationEntry, 3);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferFromJobPlanLineHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure SerialNumbersAsignedOnJobJnlLineBlnkLocation()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Serial Numbers are consumed from Job Journal Line.
        // [GIVEN] Job planning lines with ItemSNAll
        Initialize();

        // [GIVEN] No job journal lines exist
        JobJournalLine.DeleteAll();
        ReservationEntry.DeleteAll();

        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 5;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);
        // [GIVEN] 3 Job Planning Lines for Job Task T1, Location= Blank, Line Type = Budget, for the given items and quantity = 2
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", '', '', LibraryRandom.RandInt(QtyInventory));
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", '', '', LibraryRandom.RandInt(QtyInventory));
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", '', '', LibraryRandom.RandInt(QtyInventory));

        // [GIVEN] Job Planning Lines are transferred to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        // [WHEN] Serial Number is assigned in the transferred Job Journal Line
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
            JobJournalLine.OpenItemTrackingLines(false);
        until JobJournalLine.Next() = 0;

        // [THEN] Reservation entries are updated
        Assert.RecordCount(JobJournalLine, 3);
        JobJournalLine.FindSet();
        repeat
            VerifyReservationEntry(JobJournalLine, JobJournalLine."Quantity (Base)", -1, ReservationStatus::Prospect);
        until JobJournalLine.Next() = 0;

        // [WHEN] Post job journal lines for all the planning lines.
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] New serial numbers in Job Journal Lines are consumed i.e. Reservation Entries are updated.
        ReservationEntry.SetRange("Source ID", JobTask."Job No.");
        Assert.RecordCount(ReservationEntry, 0);

        // [WHEN] Item Tracking is Opened on Job Planning Line
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::NothingToHandle);
            JobPlanningLine.OpenItemTrackingLines();
        until JobPlanningLine.Next() = 0;

        // [THEN] Item tracking line is empty.
        ReservationEntry.SetRange("Source ID", JobTask."Job No.");
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferFromJobPlanLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteJobJournalLineAfterAssigningSNBlnkLocation()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Serial Numbers are assigned on job Journal Line and then job journal line is deleted.
        // [GIVEN] Job planning lines with ItemSNAll
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 5;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);
        // [GIVEN] 3 Job Planning Lines for Job Task T1, Location= Blank, Line Type = Budget, for the given items and quantity = 2
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", '', '', LibraryRandom.RandInt(QtyInventory) - 1);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", '', '', LibraryRandom.RandInt(QtyInventory) - 1);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", '', '', LibraryRandom.RandInt(QtyInventory) - 1);

        // [GIVEN] Job Planning Lines are transferred to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        // [GIVEN] Serial Number is assigned in the transferred Job Journal Line
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
            JobJournalLine.OpenItemTrackingLines(false);
        until JobJournalLine.Next() = 0;

        // [WHEN] Delete Job Journal Lines.
        asserterror JobJournalLine.DeleteAll(true);

        // [THEN] Deletion fails and error suggests user to delete the existing item tracking
        Assert.ExpectedError('You must delete the existing item tracking');

        // [WHEN] Item tracking information is deleted.
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        ReservationEntry.DeleteAll(true);

        // [WHEN] Delete Job Journal Lines.
        JobJournalLine.DeleteAll(true);

        // [THEN] Item tracking line is empty.
        ReservationEntry.SetRange("Source ID", JobTask."Job No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferFromJobPlanLineHandler,ReservationPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenPostingJobJnlLineWithItemTrackingAndNonSpecificReservationExists()
    var
        ItemSNALLTracked: Record Item;
        ItemSNWMSTracked: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        JobPlanningLines: TestPage "Job Planning Lines";
        ItemNos: DotNet ArrayList;
        Qtys: DotNet ArrayList;
        QtyInventory: Integer;
        SerialNo1: Code[20];
        SerialNo2: Code[20];
        SerialNo3: Code[20];
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Posting 'Job Journal Line' with item tracking throws error when non-specific reservation exists
        Initialize();

        // [GIVEN] No job journal lines exist
        JobJournalLine.DeleteAll();
        ItemJournalLine.DeleteAll();
        ReservationEntry.DeleteAll();

        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true
        CreateSerialTrackedItem(ItemSNAllTracked, false);
        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true and SN WMS = true
        CreateSerialTrackedItem(ItemSNWMSTracked, true);
        // [GIVEN] Tracked item with Item Tracking Code - Neg. Adj. Inbnd. = true and Neg. Adj. Outbnd. = true
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);

        // [GIVEN] Positive adjust inventory for the created items with empty location
        QtyInventory := 20;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNALLTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMSTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with a task
        CreateJobWithJobTask(JobTask);

        CreateJobPlanningLine(JobPlanningLine1, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNALLTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine2, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNWMSTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine3, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemNegAdj."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 1 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();

        // [GIVEN] Setup data for creating job journal lines
        ItemNos := ItemNos.ArrayList();
        Qtys := Qtys.ArrayList();

        ItemNos.Add(ItemSNALLTracked."No.");
        ItemNos.Add(ItemSNWMSTracked."No.");
        ItemNos.Add(ItemNegAdj."No.");
        Qtys.Add(1);
        Qtys.Add(1);
        Qtys.Add(1);

        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine1);
        LibraryVariableStorage.Enqueue(false);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine2);
        LibraryVariableStorage.Enqueue(false);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine3);
        LibraryVariableStorage.Enqueue(false);
        JobPlanningLines.Reserve.Invoke();

        // [WHEN] Job Planning Lines are transferred to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        // [WHEN] Serial Number is replaced on Job Journal Line
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine1."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelection);
        SerialNo1 := GetUnassignedSerialNo(ItemSNAllTracked);
        LibraryVariableStorage.Enqueue(SerialNo1);
        JobJournalLine.OpenItemTrackingLines(false);

        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine2."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelection);
        SerialNo2 := GetUnassignedSerialNo(ItemSNWMSTracked);
        LibraryVariableStorage.Enqueue(SerialNo2);
        JobJournalLine.OpenItemTrackingLines(false);

        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine3."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::ChangeSelection);
        SerialNo3 := GetUnassignedSerialNo(ItemNegAdj);
        LibraryVariableStorage.Enqueue(SerialNo3);
        JobJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post job journal lines for all the planning lines.
        LibraryVariableStorage.Enqueue(true);
        asserterror OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] Error is thrown
        Assert.ExpectedError('accounts for more than the quantity you have entered');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenPostingItemJnlLineWithItemTrackingAndNonSpecificReservationExists()
    var
        ItemSNALLTracked: Record Item;
        ItemSNWMSTracked: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        JobPlanningLines: TestPage "Job Planning Lines";
        ItemNos: DotNet ArrayList;
        Qtys: DotNet ArrayList;
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Posting 'Item Journal Line' with item tracking throws error when non-specific reservation exists
        Initialize();

        // [GIVEN] No job journal lines exist
        JobJournalLine.DeleteAll();

        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true
        CreateSerialTrackedItem(ItemSNAllTracked, false);
        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true and SN WMS = true
        CreateSerialTrackedItem(ItemSNWMSTracked, true);
        // [GIVEN] Tracked item with Item Tracking Code - Neg. Adj. Inbnd. = true and Neg. Adj. Outbnd. = true
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);

        // [GIVEN] Positive adjust inventory for the created items with emoty location
        QtyInventory := 20;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNALLTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMSTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with a task
        CreateJobWithJobTask(JobTask);

        CreateJobPlanningLine(JobPlanningLine1, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNALLTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine2, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNWMSTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine3, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemNegAdj."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 1 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned TODO
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();

        // [GIVEN] Setup data for creating job journal lines
        ItemNos := ItemNos.ArrayList();
        Qtys := Qtys.ArrayList();

        ItemNos.Add(ItemSNALLTracked."No.");
        ItemNos.Add(ItemSNWMSTracked."No.");
        ItemNos.Add(ItemNegAdj."No.");
        Qtys.Add(1);
        Qtys.Add(1);
        Qtys.Add(1);

        // [WHEN] Non-specific reservation is called
        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine1);
        LibraryVariableStorage.Enqueue(false);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine2);
        LibraryVariableStorage.Enqueue(false);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine3);
        LibraryVariableStorage.Enqueue(false);
        JobPlanningLines.Reserve.Invoke();

        // [THEN] Verify that the existing reservation entires has not changed
        ReservationEntry.SetRange("Item No.", JobPlanningLine1."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Quantity (Base)", -1);
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine1."Job Contract Entry No.");

        Assert.RecordCount(ReservationEntry, 1);
        ReservationEntry.FindFirst();

        // [WHEN] Create Item Journal Lines are created, tracking info duplicated and posted
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemSNALLTracked."No.", '', '', 1);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSpecific);
        LibraryVariableStorage.Enqueue(ReservationEntry."Serial No.");
        LibraryVariableStorage.Enqueue(true);
        ItemJournalLine.OpenItemTrackingLines(false);

        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error is thrown
        Assert.ExpectedError('cannot be fully applied.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ErrorInPostingIfItemIsDoubleReserved()
    var
        ItemSNALLTracked: Record Item;
        ItemSNWMSTracked: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        JobPlanningLines: TestPage "Job Planning Lines";
        ItemNos: DotNet ArrayList;
        Qtys: DotNet ArrayList;
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Posting 'Job Journal Line' with item tracking creates job planning lines with tracking info
        Initialize();

        // [GIVEN] No job journal lines exist
        JobJournalLine.DeleteAll();
        ReservationEntry.DeleteAll();
        ItemJournalLine.DeleteAll();

        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true
        CreateSerialTrackedItem(ItemSNAllTracked, false);
        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true and SN WMS = true
        CreateSerialTrackedItem(ItemSNWMSTracked, true);
        // [GIVEN] Tracked item with Item Tracking Code - Neg. Adj. Inbnd. = true and Neg. Adj. Outbnd. = true
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);

        // [GIVEN] Positive adjust inventory for the created items with emoty location
        QtyInventory := 20;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNALLTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMSTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with a task
        CreateJobWithJobTask(JobTask);

        CreateJobPlanningLine(JobPlanningLine1, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNALLTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine2, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNWMSTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine3, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemNegAdj."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 1 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned TODO
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();

        // [GIVEN] Setup data for creating job journal lines
        ItemNos := ItemNos.ArrayList();
        Qtys := Qtys.ArrayList();

        ItemNos.Add(ItemSNALLTracked."No.");
        ItemNos.Add(ItemSNWMSTracked."No.");
        ItemNos.Add(ItemNegAdj."No.");
        Qtys.Add(1);
        Qtys.Add(1);
        Qtys.Add(1);

        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine1);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine2);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine3);
        JobPlanningLines.Reserve.Invoke();

        // Get and verify that the reservation entires has not changed
        ReservationEntry.SetRange("Item No.", JobPlanningLine1."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Quantity (Base)", -1);
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine1."Job Contract Entry No.");

        Assert.RecordCount(ReservationEntry, 1);
        ReservationEntry.FindFirst();

        // [WHEN] Create Item Journal Lines are created, tracking info duplicated and and posted
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemSNALLTracked."No.", '', '', 1);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSpecific);
        LibraryVariableStorage.Enqueue(ReservationEntry."Serial No.");
        ItemJournalLine.OpenItemTrackingLines(false);

        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error i thrown - Item Tracking Serial No. xxxxxxx Lot No. xxx Package No. xxxx for Item No. xxxx Variant cannot be fully applied.
        Assert.ExpectedError('cannot be fully applied.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,JobTransferFromJobPlanLineHandler,ReservationPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostingJobJournalLineWithItemTrackingCreatesJobPlanningLineWithTrackingInfo()
    var
        ItemSNALLTracked: Record Item;
        ItemSNWMSTracked: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJournalLine: Record "Item Journal Line";
        JobPlanningLines: TestPage "Job Planning Lines";
        ItemNos: DotNet ArrayList;
        Qtys: DotNet ArrayList;
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Posting 'Job Journal Line' with item tracking creates job planning lines with tracking info
        Initialize();

        // [GIVEN] No job journal lines exist
        JobJournalLine.DeleteAll();
        ReservationEntry.DeleteAll();
        ItemJournalLine.DeleteAll();

        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true
        CreateSerialTrackedItem(ItemSNAllTracked, false);
        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true and SN WMS = true
        CreateSerialTrackedItem(ItemSNWMSTracked, true);
        // [GIVEN] Tracked item with Item Tracking Code - Neg. Adj. Inbnd. = true and Neg. Adj. Outbnd. = true
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);

        // [GIVEN] Positive adjust inventory for the created items with emoty location
        QtyInventory := 20;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNALLTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMSTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with a task
        CreateJobWithJobTask(JobTask);

        CreateJobPlanningLine(JobPlanningLine1, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNALLTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine2, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemSNWMSTracked."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateJobPlanningLine(JobPlanningLine3, "Job Planning Line Line Type"::Budget, "Job Planning Line Type"::Item, JobTask, ItemNegAdj."No.", 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 1 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line 2 and serial numbers are assigned TODO
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();

        // [GIVEN] Setup data for creating job journal lines
        ItemNos := ItemNos.ArrayList();
        Qtys := Qtys.ArrayList();

        ItemNos.Add(ItemSNALLTracked."No.");
        ItemNos.Add(ItemSNWMSTracked."No.");
        ItemNos.Add(ItemNegAdj."No.");
        Qtys.Add(1);
        Qtys.Add(1);
        Qtys.Add(1);

        JobPlanningLines.OpenEdit();
        JobPlanningLines.GoToRecord(JobPlanningLine1);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine2);
        JobPlanningLines.Reserve.Invoke();
        JobPlanningLines.GoToRecord(JobPlanningLine3);
        JobPlanningLines.Reserve.Invoke();

        // [WHEN] Create Job Journal Lines are created, tracking info added and posted
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [WHEN] Item Tracking action is invoked on Job Planning Lines page
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::NothingToHandle);

        // [THEN] Qty to Handle is 0
        JobPlanningLine1.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostJobJournalLineWithItemTrackingAndNoPlanningLine()
    var
        ItemSNALLTracked: Record Item;
        ItemSNWMSTracked: Record Item;
        ItemJobUsageTracked: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemNos: DotNet ArrayList;
        Qtys: DotNet ArrayList;
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Posting 'Job Journal Line' with item tracking and no job planning lines works as expected
        Initialize();

        // [GIVEN] No job journal lines exist
        JobJournalLine.DeleteAll();
        ReservationEntry.DeleteAll();
        ItemJournalLine.DeleteAll();

        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true
        CreateSerialTrackedItem(ItemSNAllTracked, false);
        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = true and SN WMS = true
        CreateSerialTrackedItem(ItemSNWMSTracked, true);
        // [GIVEN] Tracked item with Item Tracking Code - SN Tracking = false, Neg. Adj Inbound/Outbound = true
        CreateNegAdjTrackedItemWithSN(ItemJobUsageTracked);

        // [GIVEN] Positive adjust inventory for the created items with emoty location
        QtyInventory := 20;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNALLTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMSTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemJobUsageTracked."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with a task
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Setup data for creating job journal lines
        ItemNos := ItemNos.ArrayList();
        Qtys := Qtys.ArrayList();

        ItemNos.Add(ItemSNALLTracked."No.");
        ItemNos.Add(ItemSNWMSTracked."No.");
        ItemNos.Add(ItemJobUsageTracked."No.");
        Qtys.Add(2);
        Qtys.Add(2);
        Qtys.Add(2);

        // [WHEN] Create Job Journal Lines are created, tracking info added and posted
        CreateJobJournalAssignTrackingInfoAndPost(JobTask, ItemNos, Qtys);

        // [THEN] Job planning lines are create with tracking information
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.RecordCount(JobPlanningLine, 6);

        // [WHEN] Item Tracking action is invoked on Job Planning Lines page
        JobPlanningLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::NothingToHandle);

        // [THEN] Qty to Handle is 0
        JobPlanningLine.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferFromJobPlanLineHandler,ConfirmHandlerTrue,MessageHandler,PostedItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesOnCompletedJobPlanningLineShowsPostedSerialNos()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyInventory: Integer;
        SerialNo: Code[20];
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Invoking Item Tracking Lines on completed Job Planning Line shows posted item tracking information
        Initialize();

        // [GIVEN] No job journal lines exist
        JobJournalLine.DeleteAll();
        ReservationEntry.DeleteAll();

        // [GIVEN] Items with enough inventory
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 5;
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", '', '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 3 Job Planning Lines for Job Task T1, Location= Blank, Line Type = Budget, for the given items and quantity = 1
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", '', '', 1);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ItemSNWMS."No.", '', '', 1);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine3.Type::Item, ItemNegAdj."No.", '', '', 1);

        // [GIVEN] Job Planning Lines are transferred to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        // [WHEN] Serial Number is assigned in the transferred Job Journal Line
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
            JobJournalLine.OpenItemTrackingLines(false);
        until JobJournalLine.Next() = 0;

        // [WHEN] Post job journal lines for all the planning lines.
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [WHEN] Item Tracking is Opened on Job Planning Line
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.ModifyAll(Status, JobPlanningLine.Status::Completed, true);

        // [THEN] Item tracking information from the posted item ledger entry is shown.
        JobPlanningLine.FindSet();
        ItemLedgerEntry.SetRange("Job No.", JobPlanningLine1."Job No.");
        ItemLedgerEntry.SetRange("Job Task No.", JobPlanningLine1."Job Task No.");
        repeat
            ItemLedgerEntry.SetRange("Order Line No.", JobPlanningLine."Job Contract Entry No.");
            ItemLedgerEntry.FindFirst();
            SerialNo := ItemLedgerEntry."Serial No.";
            LibraryVariableStorage.Enqueue(SerialNo);
            JobPlanningLine.OpenItemTrackingLines();
        until JobPlanningLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AssignSerialNumberOnInventoryPickPage() //Test12
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        QtyInventory: Integer;
        SerialNo: Code[20];
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Serial Numbers for SN Warehouse tracking items can be assigned on Inventory Pick page before posting inventory pick.

        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePickBinMandatory Bin1
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 1; //This is set to one, otherwise we need to split the lines on Inventory Pick Page.

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustment(ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustment(ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 6 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [GIVEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Post Inventory Pick for ItemNegAdj after setting Qty. to handle.
        SetItemQtyToHandleOnWhsActLine(ItemNegAdj, QtyInventory);
        Commit(); //After the below error, Qty. to Handle gets reset.
        asserterror PostInventoryPickFromPage(JobPlanningLine3."Job No.", JobPlanningLine3."Location Code", false);
        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must assign a serial number');

        asserterror PostInventoryPickFromPage(JobPlanningLine6."Job No.", JobPlanningLine6."Location Code", false);
        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must assign a serial number');

        // [WHEN] Assign serial number for ItemNegAdj
        WarehouseActivityLine.SetRange("Item No.", ItemNegAdj."No.");
        WarehouseActivityLine.FindFirst();
        asserterror WarehouseActivityLine.Validate("Serial No.", LibraryRandom.RandText(1));

        // [THEN] Error: SN Warehouse Tracking is disabled for the Item tracking code
        Assert.ExpectedError('Warehouse item tracking is not enabled');

        // [WHEN] Reset Qty. to handle for ItemNegAdj and Set Qty. to handle for ItemSNAll.
        SetItemQtyToHandleOnWhsActLine(ItemNegAdj, 0);
        SetItemQtyToHandleOnWhsActLine(ItemSNAll, QtyInventory);
        Commit(); //After the below error, Qty. to Handle gets reset.

        // [WHEN] Post Inventory Pick for ItemSNAll with bin mandatory
        asserterror PostInventoryPickFromPage(JobPlanningLine1."Job No.", JobPlanningLine1."Location Code", false);
        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must assign a serial number');

        // [WHEN] Post Inventory Pick for ItemSNAll without bin
        asserterror PostInventoryPickFromPage(JobPlanningLine4."Job No.", JobPlanningLine4."Location Code", false);
        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must assign a serial number');

        // [WHEN] Assign serial number for ItemSNAll
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemSNAll."No.");
        WarehouseActivityLine.FindFirst();
        asserterror WarehouseActivityLine.Validate("Serial No.", LibraryRandom.RandText(1));

        // [THEN] Error: SN Warehouse Tracking is disabled for the Item tracking code
        Assert.ExpectedError('Warehouse item tracking is not enabled');

        // [WHEN]  Reset Qty. to handle for ItemSNAll and Set Qty. to handle for ItemSNWMS.
        SetItemQtyToHandleOnWhsActLine(ItemSNAll, 0);
        SetItemQtyToHandleOnWhsActLine(ItemSNWMS, QtyInventory);
        Commit(); //After the below error, Qty. to Handle gets reset.

        // [WHEN] Post Inventory Pick for ItemSNWMS with bin mandatory
        asserterror PostInventoryPickFromPage(JobPlanningLine2."Job No.", JobPlanningLine2."Location Code", false);
        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must have a value in');

        // [WHEN] Post Inventory Pick for ItemSNWMS without bin
        asserterror PostInventoryPickFromPage(JobPlanningLine5."Job No.", JobPlanningLine5."Location Code", false);
        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must have a value in');

        // [WHEN] Assign serial number for ItemSNWMS
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemSNWMS."No.");
        WarehouseActivityLine.FindSet();
        repeat
            //Get an unassigned serial number
            SerialNo := GetUnassignedSerialNo(ItemSNWMS, WarehouseActivityLine."Location Code");

            // Assign the serial number
            WarehouseActivityLine.Validate("Serial No.", SerialNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Post Inventory Pick for ItemSNWMS
        PostInventoryPickFromPage(JobPlanningLine2."Job No.", JobPlanningLine2."Location Code", false);
        PostInventoryPickFromPage(JobPlanningLine5."Job No.", JobPlanningLine5."Location Code", false);

        // [THEN] No error is thrown and reservation entries are consumed.
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TransferSNFromJobPlanningLinesToInventoryPick() //Test13
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Inventory Pick can be posted when Serial numbers are assigned on Job Planning Lines.

        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePickBinMandatory Bin1
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 1; //This is set to one, otherwise we need to split the lines on Inventory Pick Page.

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 6 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [GIVEN] Serial numbers are assigned on all the Job planning lines
        // [GIVEN] 'Item Tracking Lines' is opened for Job Planning Line and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine4.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine5.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine6.OpenItemTrackingLines();

        // [WHEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [THEN] Serial Number is copied only to warehouse activity line for ItemSNWMS i.e. Quantity on JobPlanningLine2 and JobPlanningLine4
        WarehouseActivityLine.SetRange("Item No.", ItemSNWMS."No.");
        WarehouseActivityLine.SetFilter("Serial No.", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, JobPlanningLine2.Quantity + JobPlanningLine4.Quantity);
        WarehouseActivityLine.FindSet();
        repeat
            ReservationEntry.SetRange("Item No.", WarehouseActivityLine."Item No.");
            ReservationEntry.SetRange("Location Code", WarehouseActivityLine."Location Code");
            ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
            ReservationEntry.FindFirst();
            Assert.AreEqual(ReservationEntry."Serial No.", WarehouseActivityLine."Serial No.", 'Serial number assigned on job planning line for ItemSNWMS should be copied to WarehouseActivityLine.');
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] AutoFill Qty. to handle and Post Inventory Pick for LocationWithRequirePickBinMandatory
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, true);

        // [THEN] No error is thrown and Reservation entries are removed for location LocationWithRequirePickBinMandatory.
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine3, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, JobPlanningLine4.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, JobPlanningLine5.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine6, JobPlanningLine5.Quantity, -1, ReservationStatus::Surplus);

        // [WHEN] AutoFill Qty. to handle and Post Inventory Pick for LocationWithRequirePick
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, true);

        // [THEN] No error is thrown and Reservation entries are removed for location LocationWithRequirePick.
        VerifyReservationEntry(JobPlanningLine4, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine6, 0, 0, ReservationStatus::Surplus);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TransferSNFromJobPlanLinesToInventoryPickRequiresSplit()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Splitting of lines is required for posting Inventory Pick when Serial numbers are assigned on Job Planning Lines with quantity greater than 1.

        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePickBinMandatory Bin1
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 5;

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 6 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [GIVEN] Serial numbers are assigned on all the Job planning lines
        // [GIVEN] 'Item Tracking Lines' is opened for Job Planning Line and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine4.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine5.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine6.OpenItemTrackingLines();

        // [WHEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Split the lines
        // [WHEN] AutoFill Qty. to handle and Post Inventory Pick for LocationWithRequirePickBinMandatory
        SplitAndPostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, true);

        // [THEN] No error is thrown and Reservation entries are removed for location LocationWithRequirePickBinMandatory.
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine3, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, JobPlanningLine4.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, JobPlanningLine5.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine6, JobPlanningLine5.Quantity, -1, ReservationStatus::Surplus);

        // [WHEN] Split the lines
        // [WHEN] AutoFill Qty. to handle and Post Inventory Pick for LocationWithRequirePick
        SplitAndPostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, true);

        // [THEN] No error is thrown and Reservation entries are removed for location LocationWithRequirePick.
        VerifyReservationEntry(JobPlanningLine4, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine6, 0, 0, ReservationStatus::Surplus);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPartialInventoryPickForSNTransferredFromJobPlanningLines()
    var
        ItemAll: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
        QtyToHandle: Integer;
        counter: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Partial posting of Inventory Picks is possible for SN tracking transferred from Job Planning Line

        // [GIVEN] Job planning line with ItemAll Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemAll Location LocationWithRequirePickBinMandatory Bin1

        Initialize();
        CreateSerialTrackedItem(ItemAll, true);
        QtyInventory := 5;
        QtyToHandle := 2;

        CreateAndPostInvtAdjustmentWithSNTracking(ItemAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemAll."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 2 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemAll."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [WHEN] Serial numbers are assigned on all the Job planning lines
        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and Serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [THEN] There are no lines with Reservation Status = "Prospect"
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);

        // [GIVEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Partial Inventory Pick lines are handled for ItemAll at LocationWithRequirePickBinMandatory
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemAll."No.");
        WarehouseActivityLine.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", 1);
            WarehouseActivityLine.Modify(true);
            WarehouseActivityLine.Next();
            counter += 1;
        until counter = QtyToHandle;

        // [WHEN] Partial Inventory Pick lines are handled for ItemAll at LocationWithRequirePick
        Clear(WarehouseActivityLine);
        counter := 0;
        WarehouseActivityLine.SetRange("Item No.", ItemAll."No.");
        WarehouseActivityLine.SetRange("Location Code", LocationWithRequirePick.Code);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", 1);
            WarehouseActivityLine.Modify(true);
            WarehouseActivityLine.Next();
            counter += 1;
        until counter = QtyToHandle;

        // [WHEN] Partial Inventory Picks is posted for LocationWithRequirePickBinMandatory
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, false);

        // [THEN] No error is thrown and remaining Reservation entry exists with status as Surplus.
        VerifyReservationEntry(JobPlanningLine1, QtyInventory - QtyToHandle, -1, ReservationStatus::Surplus);

        // [THEN] Intermediate entry with reservation status "Prospect" should not exist after posting Job Journal Line.
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);

        // [WHEN] Partial Inventory Picks is posted for LocationWithRequirePick
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, false);

        // [THEN] No error is thrown and remaining Reservation entry exists with status as Surplus.
        VerifyReservationEntry(JobPlanningLine2, QtyInventory - QtyToHandle, -1, ReservationStatus::Surplus);

        // [THEN] Intermediate entry with reservation status "Prospect" should not exist after posting Job Journal Line.
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPartialInventoryPickForLotTransferredFromJobPlanningLines()
    var
        ItemLotAll: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
        QtyToHandle: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Partial posting of Inventory Picks is possible for Lot tracking transferred from Job Planning Line

        // [GIVEN] Job planning line with ItemLotAll Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemLotAll Location LocationWithRequirePickBinMandatory Bin1

        Initialize();
        CreateLotTrackedItem(ItemLotAll, true);
        QtyInventory := 5;
        QtyToHandle := 2;

        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 2 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotAll."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [WHEN] Lot numbers are assigned on all the Job planning lines
        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and Lot numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [THEN] Reservation entries exists for the tracked items with status Surplus.
        VerifyReservationEntry(JobPlanningLine1, 1, -QtyInventory, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 1, -QtyInventory, ReservationStatus::Surplus);

        // [THEN] There are no lines with Reservation Status = "Prospect"
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);

        // [GIVEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Partial quantity is handled for Inventory Pick lines with ItemLotAll
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemLotAll."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Partial Inventory Picks is posted for LocationWithRequirePickBinMandatory
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, false);

        // [THEN] No error is thrown and 1 Reservation entry exists for the remaining quantity with status as Surplus.
        VerifyReservationEntry(JobPlanningLine1, 1, -(QtyInventory - QtyToHandle), ReservationStatus::Surplus);

        // [THEN] Intermediate entry with reservation status "Prospect" should not exist after posting Job Journal Line.
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);

        // [WHEN] Partial Inventory Picks is posted for LocationWithRequirePick
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, false);

        // [THEN] No error is thrown and 1 Reservation entry exists for the remaining quantity with status as Surplus.
        VerifyReservationEntry(JobPlanningLine2, 1, -(QtyInventory - QtyToHandle), ReservationStatus::Surplus);

        // [THEN] Intermediate entry with reservation status "Prospect" should not exist after posting Job Journal Line.
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure QtyToHandleDoesNotMatchItemTrackingOnJobPlanningLineForLotWithSplitError()
    var
        ItemLotAll1: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
        QtyOnJobPlanningLine: Integer;
        QtyToHandle: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines for Lot
        // [SCENARIO] Qty to Handle on inventory pick should match the Qty on item tracking lines on Job Planning Line.

        // [GIVEN] Job planning line with ItemLotAll1 Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemLotAll1 Location LocationWithRequirePick

        Initialize();
        CreateLotTrackedItem(ItemLotAll1, false);
        QtyInventory := 4;
        QtyOnJobPlanningLine := 3;
        QtyToHandle := 1;

        // [GIVEN] Split the Inventory for ItemLotAll1 between two different lots by setting Qty = QtyInventory/2
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory / 2, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePick.Code, '', QtyInventory / 2, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory / 2, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePick.Code, '', QtyInventory / 2, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 2 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotAll1."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyOnJobPlanningLine);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ItemLotAll1."No.", LocationWithRequirePick.Code, '', QtyOnJobPlanningLine);

        // [WHEN] Lot numbers are assigned on all the Job planning lines
        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and Lot numbers are assigned. ItemLotAll1 has inventory split across two lots.
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [THEN] Reservation entries exists for the tracked items with status Surplus with Quantity = 3;
        VerifyReservationEntryQtySum(JobPlanningLine1, 2, -QtyOnJobPlanningLine, ReservationStatus::Surplus);
        VerifyReservationEntryQtySum(JobPlanningLine2, 2, -QtyOnJobPlanningLine, ReservationStatus::Surplus);

        // [THEN] There are no lines with Reservation Status = "Prospect"
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);

        // [GIVEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Set Qty To Handle to 1 for all the lines.
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemLotAll1."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Split the first line and set Qty to handle = QtyToHandle
        SplitFirstLineInInvPickPage(Job."No.", LocationWithRequirePickBinMandatory.Code);
        SplitFirstLineInInvPickPage(Job."No.", LocationWithRequirePick.Code);

        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemLotAll1."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Post Inventory Pick for LocationWithRequirePickBinMandatory
        Commit(); //committing before the error.
        asserterror PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, false);

        // [THEN] Error is thrown that quantity to handle in item tracking does not match with the inventory pick quantity
        Assert.ExpectedError(StrSubstNo('%1 in the item tracking assigned', WarehouseActivityLine.FieldCaption(WarehouseActivityLine."Qty. to Handle (Base)")));

        // [WHEN] Post Inventory Pick for LocationWithRequirePick
        asserterror PostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, false);

        // [THEN] Error is thrown that quantity to handle in item tracking does not match with the inventory pick quantity
        Assert.ExpectedError(StrSubstNo('%1 in the item tracking assigned', WarehouseActivityLine.FieldCaption(WarehouseActivityLine."Qty. to Handle (Base)")));

        // [WHEN] Post Inventory Pick for LocationWithRequirePickBinMandatory with Handling Full Quantity
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, true);
        // [WHEN] Post Inventory Pick for LocationWithRequirePick with Handling Full Quantity
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, true);

        // [THEN] Reservation entries are updated and no error is thrown
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostInventoryPickForLotTransferredFromJobPlanningLinesWithSplit()
    var
        ItemLotAll1: Record Item;
        ItemLotAll2: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
        QtyOnJobPlanningLine: Integer;
        QtyToHandle: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Posting of Inventory Picks is possible after splitting for Lot tracking transferred from Job Planning Line

        // [GIVEN] Job planning line with ItemLotAll1 Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemLotAll1 Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemLotAll2 Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemLotAll2 Location LocationWithRequirePick

        Initialize();
        CreateLotTrackedItem(ItemLotAll1, false);
        CreateLotTrackedItem(ItemLotAll2, false);
        QtyInventory := 2;
        QtyOnJobPlanningLine := 2;
        QtyToHandle := 1;

        // [GIVEN] Split the Inventory for ItemLotAll1 between two different lots by setting Qty = QtyInventory/2
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory / 2, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePick.Code, '', QtyInventory / 2, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory / 2, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll1."No.", LocationWithRequirePick.Code, '', QtyInventory / 2, LibraryRandom.RandDec(10, 2));

        // [GIVEN] ItemAll2 is assigned 1 Lot.
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll2."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll2."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 4 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotAll1."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyOnJobPlanningLine);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ItemLotAll1."No.", LocationWithRequirePick.Code, '', QtyOnJobPlanningLine);

        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine3.Type::Item, ItemLotAll2."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyOnJobPlanningLine);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine4.Type::Item, ItemLotAll2."No.", LocationWithRequirePick.Code, '', QtyOnJobPlanningLine);

        // [WHEN] Lot numbers are assigned on all the Job planning lines
        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and Lot numbers are assigned. ItemLotAll1 has inventory split across two lots.
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine4.OpenItemTrackingLines();

        // [THEN] Reservation entries exists for the tracked items with status Surplus with Quantity = 3;
        VerifyReservationEntryQtySum(JobPlanningLine1, 2, -QtyOnJobPlanningLine, ReservationStatus::Surplus);
        VerifyReservationEntryQtySum(JobPlanningLine2, 2, -QtyOnJobPlanningLine, ReservationStatus::Surplus);

        VerifyReservationEntry(JobPlanningLine3, 1, -QtyOnJobPlanningLine, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, 1, -QtyOnJobPlanningLine, ReservationStatus::Surplus);

        // [THEN] There are no lines with Reservation Status = "Prospect"
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine3, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine4, 0, 0, ReservationStatus::Prospect);

        // [GIVEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Set Qty To Handle to 1 for all the lines.
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetFilter("Item No.", '= %1|%2', ItemLotAll1."No.", ItemLotAll2."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Split the first line and set Qty to handle = QtyToHandle
        SplitFirstLineInInvPickPage(Job."No.", LocationWithRequirePickBinMandatory.Code);
        SplitFirstLineInInvPickPage(Job."No.", LocationWithRequirePick.Code);

        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetFilter("Item No.", '= %1|%2', ItemLotAll1."No.", ItemLotAll2."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Post Inventory Pick for LocationWithRequirePickBinMandatory
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, false);

        // [WHEN] Post Inventory Pick for LocationWithRequirePick
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, false);

        // [THEN] No error is thrown and Reservation entries are removed for location LocationWithRequirePickBinMandatory.
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine3, 1, -(QtyOnJobPlanningLine - QtyToHandle), ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, 1, -(QtyOnJobPlanningLine - QtyToHandle), ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine3, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine4, 0, 0, ReservationStatus::Prospect);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPartialInventoryPickForLotFromJobPlanningLinesWithNegAdjLot()
    var
        ItemLotAll: Record Item;
        ItemLotNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
        QtyToHandle: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Partial posting of Inventory Picks is possible for Lot tracking transferred from Job Planning Lines for Lot Specific tracking and not assigning Lot No. for item with negative Lot adjustment.

        // [GIVEN] Job planning line with ItemLotAll Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemLotAll Location LocationWithRequirePickBinMandatory Bin1

        Initialize();
        CreateLotTrackedItem(ItemLotAll, true);
        CreateNegAdjTrackedItemWithLot(ItemLotNegAdj);

        QtyInventory := 5;
        QtyToHandle := 2;

        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithLotTracking(ItemLotAll."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(ItemLotNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(ItemLotNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 4 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotAll."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemLotNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [WHEN] Lot numbers are assigned on the Job planning lines with ItemLotAll
        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and Lot numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();

        // [THEN] Reservation entries exists for the tracked items with status Surplus.
        VerifyReservationEntry(JobPlanningLine1, 1, -QtyInventory, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 1, -QtyInventory, ReservationStatus::Surplus);

        // [THEN] There are no lines with Reservation Status = "Prospect"
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);


        // [WHEN]  Assign different Lot numbers are assigned on the Job planning lines with ItemLotNegAdj
        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and Lot numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignLot);
        JobPlanningLine3.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignLot);
        JobPlanningLine4.OpenItemTrackingLines();

        // [THEN] Reservation entries exists for the tracked items with status Surplus.
        VerifyReservationEntry(JobPlanningLine3, 1, -QtyInventory, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, 1, -QtyInventory, ReservationStatus::Surplus);

        // [THEN] There are no lines with Reservation Status = "Prospect"
        VerifyReservationEntry(JobPlanningLine3, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine4, 0, 0, ReservationStatus::Prospect);

        // [GIVEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Partial quantity is handled for all Inventory Pick lines
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetFilter("Item No.", '= %1|%2', ItemLotAll."No.", ItemLotNegAdj."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Partial Inventory Picks is posted for LocationWithRequirePickBinMandatory
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, false);

        // [THEN] No error is thrown and 1 Reservation entry exists for the remaining quantity with status as Surplus.
        VerifyReservationEntry(JobPlanningLine1, 1, -(QtyInventory - QtyToHandle), ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine3, 1, -(QtyInventory - QtyToHandle), ReservationStatus::Surplus);

        // [THEN] Intermediate entry with reservation status "Prospect" should not exist after posting Job Journal Line.
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine3, 0, 0, ReservationStatus::Prospect);

        // [WHEN] Partial Inventory Picks is posted for LocationWithRequirePick
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, false);

        // [THEN] No error is thrown and 1 Reservation entry exists for the remaining quantity with status as Surplus.
        VerifyReservationEntry(JobPlanningLine2, 1, -(QtyInventory - QtyToHandle), ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, 1, -(QtyInventory - QtyToHandle), ReservationStatus::Surplus);

        // [THEN] Intermediate entry with reservation status "Prospect" should not exist after posting Job Journal Line.
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Prospect);
        VerifyReservationEntry(JobPlanningLine4, 0, 0, ReservationStatus::Prospect);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure CannotPostRelatedJobJournalAfterPostingInventoryPick()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Related job journal cannot be posted after posting the Inventory Pick as the serial numbers would be consumed while posting inventory pick.

        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePick
        // [GIVEN] Job planning line with ItemSNAll Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemSNWMS Location LocationWithRequirePickBinMandatory Bin1
        // [GIVEN] Job planning line with ItemNegAdj Location LocationWithRequirePickBinMandatory Bin1
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 5;

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 6 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNWMS."No.", LocationWithRequirePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemNegAdj."No.", LocationWithRequirePick.Code, '', QtyInventory);

        // [GIVEN] Serial numbers are assigned on all the Job planning lines
        // [GIVEN] 'Item Tracking Lines' is opened for Job Planning Line and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine2.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine3.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine4.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine5.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine6.OpenItemTrackingLines();

        // [WHEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Job Planning Lines are transferred to Job Journal
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine4);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine5);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine6);
        Commit(); //Needed to continue after the errors below.

        // [THEN] Reservation entry is created with source as job journal line
        // [THEN] Reservation entries created for Job journal line has the same serial numbers assigned.
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        Assert.RecordCount(JobJournalLine, 6);
        MatchResEntriesAfterTransferToJobJnl(JobJournalLine); // Reservation Entries are not transferred to Job Journal

        // [WHEN] Post job journal lines for the planning lines.
        // [THEN] Error: Items not picked and therefore we cannot post job usage.
        asserterror OpenRelatedJournalAndPost(JobPlanningLine1);
        Assert.ExpectedError('You cannot post usage for project number');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine2);
        Assert.ExpectedError('You cannot post usage for project number');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine3);
        Assert.ExpectedError('You cannot post usage for project number');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine4);
        Assert.ExpectedError('You cannot post usage for project number');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine5);
        Assert.ExpectedError('You cannot post usage for project number');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine6);
        Assert.ExpectedError('You cannot post usage for project number');

        // [WHEN] Split the lines
        // [WHEN] AutoFill Qty. to handle and Post Inventory Pick for LocationWithRequirePickBinMandatory
        SplitAndPostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, true);

        // [THEN] No error is thrown and Reservation entries are removed for location LocationWithRequirePickBinMandatory.
        VerifyReservationEntry(JobPlanningLine1, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine3, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, JobPlanningLine4.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, JobPlanningLine5.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine6, JobPlanningLine5.Quantity, -1, ReservationStatus::Surplus);

        // [WHEN] Split the lines
        // [WHEN] AutoFill Qty. to handle and Post Inventory Pick for LocationWithRequirePick
        SplitAndPostInventoryPickFromPage(Job."No.", LocationWithRequirePick.Code, true);

        // [THEN] No error is thrown and Reservation entries are removed for location LocationWithRequirePick.
        VerifyReservationEntry(JobPlanningLine4, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, 0, 0, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine6, 0, 0, ReservationStatus::Surplus);

        Commit(); //Needed to continue after the errors below.

        // [WHEN] Post the related job journal lines for all the planning lines.
        // [THEN] The same serial cannot be used for the posting the journal lines.
        asserterror OpenRelatedJournalAndPost(JobPlanningLine1);
        Assert.ExpectedError('cannot be fully applied');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine2);
        Assert.ExpectedError('cannot be fully applied');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine3);
        Assert.ExpectedError('cannot be fully applied');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine4);
        Assert.ExpectedError('cannot be fully applied');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine5);
        Assert.ExpectedError('cannot be fully applied');

        asserterror OpenRelatedJournalAndPost(JobPlanningLine6);
        Assert.ExpectedError('cannot be fully applied');
    end;

    [Test]
    [HandlerFunctions('JobTransferFromJobPlanLineHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue,WhseSrcCreateDocReqHandler')]
    [Scope('OnPrem')]
    procedure AssignSerialNumberOnWarehousePickPage() //Test14
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
        Iteration: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Serial Numbers for SN Warehouse tracking items can be assigned on Warehouse Pick page before registering warehouse pick.

        // [GIVEN] Job planning line with ItemSNAll Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemSNWMS Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemNegAdj Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemSNAll Location LocationRequireWhsePickBinMandatory WhseBin1
        // [GIVEN] Job planning line with ItemSNWMS Location LocationRequireWhsePickBinMandatory WhseBin1
        // [GIVEN] Job planning line with ItemNegAdj Location LocationRequireWhsePickBinMandatory WhseBin1
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := LibraryRandom.RandInt(3);

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 6 Job Planning Lines for Job Task T1, Line Type = Budget, Bin = WhseBin2 for location with bin mandatory.
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ItemSNWMS."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine3.Type::Item, ItemNegAdj."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine4.Type::Item, ItemSNAll."No.", LocationRequireWhsePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine5.Type::Item, ItemSNWMS."No.", LocationRequireWhsePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine6.Type::Item, ItemNegAdj."No.", LocationRequireWhsePick.Code, '', QtyInventory);

        // [GIVEN] Warehouse Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [WHEN] Register Warehouse Pick without Serial Number for both locations.
        Commit(); //After the below error, Qty. to Handle gets reset.
        asserterror RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePickBinMandatory.Code, false);

        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must have a value in');

        asserterror RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePick.Code, false);
        // [THEN] Error: Serial Number is not assigned
        Assert.ExpectedError('must have a value in');

        // [WHEN] Assign serial number for ItemNegAdj
        WarehouseActivityLine.SetRange("Item No.", ItemNegAdj."No.");
        WarehouseActivityLine.FindFirst();
        asserterror WarehouseActivityLine.Validate("Serial No.", LibraryRandom.RandText(1));

        // [THEN] Error: SN Warehouse Tracking is disabled for the Item tracking code
        Assert.ExpectedError('Warehouse item tracking is not enabled');

        // [WHEN] Assign serial number for ItemSNAll
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemSNAll."No.");
        WarehouseActivityLine.FindFirst();
        asserterror WarehouseActivityLine.Validate("Serial No.", LibraryRandom.RandText(1));

        // [THEN] Error: SN Warehouse Tracking is disabled for the Item tracking code
        Assert.ExpectedError('Warehouse item tracking is not enabled');

        // [WHEN] Assign serial number for ItemSNWMS
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemSNWMS."No.");
        WarehouseActivityLine.FindSet();
        Iteration := 0;
        repeat
            //Get the serial number for take and pick action
            if (Iteration mod 2 = 0) then begin
                ItemLedgerEntry.SetRange("Item No.", WarehouseActivityLine."Item No.");
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
                ItemLedgerEntry.SetRange("Location Code", WarehouseActivityLine."Location Code");
                ItemLedgerEntry.FindFirst();
            end;
            // Assign the same serial number for take and pick action
            WarehouseActivityLine.Validate("Serial No.", ItemLedgerEntry."Serial No.");
            WarehouseActivityLine.Modify(true);
            Iteration += 1;
        until WarehouseActivityLine.Next() = 0;

        // [WHEN] Register Warehouse Pick for LocationRequireWhsePickBinMandatory
        RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePickBinMandatory.Code, false);

        // [WHEN] Register Warehouse Pick for LocationRequireWhsePick
        RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePick.Code, false);

        // [THEN] Reservation entries are created for ItemSNWMS. Number of entires created =  JobPlanningLine2.Quantity + JobPlanningLine5.Quantity
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source Subtype", 2);
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        Assert.RecordCount(ReservationEntry, JobPlanningLine2.Quantity + JobPlanningLine5.Quantity);

        VerifyReservationEntry(JobPlanningLine2, JobPlanningLine2.Quantity, -1, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, JobPlanningLine5.Quantity, -1, ReservationStatus::Surplus);

        // [THEN] Verify Warehouse Entries after Registering Picks
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, true, WhseBin1.Code);

        // [WHEN] Transfer Job Planning Lines to the Job Journal Lines
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine4);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine5);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine6);

        // [WHEN] Select Serial Number for the transferred Job Journal Lines
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
            JobJournalLine.OpenItemTrackingLines(false);
        until JobJournalLine.Next() = 0;

        // [THEN] Prospect Reservation entries are created for all the quantities on Job Journal Lines transferred from Job planning lines.
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus::Prospect);
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        Assert.RecordCount(ReservationEntry, JobPlanningLine1.Quantity + JobPlanningLine2.Quantity + JobPlanningLine3.Quantity + JobPlanningLine4.Quantity + JobPlanningLine5.Quantity + JobPlanningLine6.Quantity);

        JobJournalLine.FindSet();
        repeat
            VerifyReservationEntry(JobJournalLine, JobJournalLine.Quantity, -1, ReservationStatus::Prospect);
        until JobJournalLine.Next() = 0;

        // [WHEN] Job Journal is posted for the job.
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] No error is thrown and reservation entries are consumed.
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('JobTransferFromJobPlanLineHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue,WhseSrcCreateDocReqHandler')]
    [Scope('OnPrem')]
    procedure TransferSNFromJobPlanningLinesToWarehousePick() //Test15
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Warehouse Pick can be registered when Serial numbers are assigned on Job Planning Lines.

        // [GIVEN] Job planning line with ItemSNAll Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemSNWMS Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemNegAdj Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemSNAll Location LocationRequireWhsePickBinMandatory WhseBin1
        // [GIVEN] Job planning line with ItemSNWMS Location LocationRequireWhsePickBinMandatory WhseBin1
        // [GIVEN] Job planning line with ItemNegAdj Location LocationRequireWhsePickBinMandatory WhseBin1
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 1;

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 6 Job Planning Lines for Job Task T1, Line Type = Budget, Bin = WhseBin2 for location with bin mandatory.
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ItemSNWMS."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine3.Type::Item, ItemNegAdj."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine4.Type::Item, ItemSNAll."No.", LocationRequireWhsePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine5.Type::Item, ItemSNWMS."No.", LocationRequireWhsePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine6.Type::Item, ItemNegAdj."No.", LocationRequireWhsePick.Code, '', QtyInventory);

        // [WHEN] Serial numbers are assigned on all the Job planning lines
        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSpecific);
        LibraryVariableStorage.Enqueue(GetUnassignedSerialNo(ItemSNAll));
        JobPlanningLine1.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSpecific);
        LibraryVariableStorage.Enqueue(GetUnassignedSerialNo(ItemSNWMS));
        JobPlanningLine2.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSpecific);
        LibraryVariableStorage.Enqueue(GetUnassignedSerialNo(ItemNegAdj));
        JobPlanningLine3.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine4.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine5.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine6.OpenItemTrackingLines();

        // [THEN] Prospect Reservation entries are created for all the items.
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationStatus::Surplus);
        Assert.RecordCount(ReservationEntry, JobPlanningLine1.Quantity + JobPlanningLine2.Quantity + JobPlanningLine3.Quantity + JobPlanningLine4.Quantity + JobPlanningLine5.Quantity + JobPlanningLine6.Quantity);

        // [WHEN] Warehouse Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Serial Numbers are assigned on all the lines including Take and Pick lines where Bin is mandatory on location.
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        Assert.RecordCount(WarehouseActivityLine, (2 * (JobPlanningLine1.Quantity + JobPlanningLine2.Quantity + JobPlanningLine3.Quantity)) + JobPlanningLine4.Quantity + JobPlanningLine5.Quantity + JobPlanningLine6.Quantity);
        WarehouseActivityLine.SetFilter("Serial No.", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, (2 * (JobPlanningLine1.Quantity + JobPlanningLine2.Quantity + JobPlanningLine3.Quantity)) + JobPlanningLine4.Quantity + JobPlanningLine5.Quantity + JobPlanningLine6.Quantity);

        // [WHEN] Register Warehouse Pick for LocationRequireWhsePickBinMandatory
        RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePickBinMandatory.Code, false);

        // [WHEN] Register Warehouse Pick for LocationRequireWhsePick
        RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePick.Code, false);

        // [THEN] No new Reservation entries are created as Surplus
        Clear(ReservationEntry);
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        Assert.RecordCount(ReservationEntry, JobPlanningLine1.Quantity + JobPlanningLine2.Quantity + JobPlanningLine3.Quantity + JobPlanningLine4.Quantity + JobPlanningLine5.Quantity + JobPlanningLine6.Quantity);

        ReservationEntry.SetRange("Reservation Status", ReservationStatus::Prospect);
        Assert.RecordCount(ReservationEntry, 0);

        // [THEN] Verify Warehouse Entries after Registering Picks
        VerifyWhseEntriesAfterRegisterPick(Job, JobTask, true, WhseBin1.Code);

        // [WHEN] Transfer Job Planning Lines to the Job Journal Lines
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine4);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine5);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine6);

        // [WHEN] Job Journal is posted for the job.
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] No error is thrown and reservation entries are consumed.
        Clear(ReservationEntry);
        ReservationEntry.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        Assert.RecordCount(ReservationEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler,ConfirmHandlerTrue,WhseSrcCreateDocReqHandler,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure PartialWarehousePickAndPost()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNo1: Code[50];
        SerialNo2: Code[50];
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Partial warehouse pick and post does not throw errors.

        // [GIVEN] Serial tracked item with enough inventory in location where warehouse pick and shipment is enabled and bin is mandatory
        Initialize();
        CreateSerialTrackedItem(Item, true);
        CreateAndPostInvtAdjustmentWithSNTracking(Item."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, 10, 1);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        // [GIVEN] Save Serial numbers
        SerialNo1 := ItemLedgerEntry."Serial No.";
        ItemLedgerEntry.Next();
        SerialNo2 := ItemLedgerEntry."Serial No.";

        // [GIVEN] A Job with the item in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(
            JobPlanningLine,
            JobTask,
            "Job Planning Line Line Type"::Budget,
            JobPlanningLine.Type::Item,
            Item."No.",
            LocationRequireWhsePickBinMandatory.Code,
            WhseBin2.Code,
            3
        );

        // [GIVEN] Warehouse Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [GIVEN] Select serial number for quantity 2(2 takes and 2 places) and set quantity to handle on the last line to 0 without setting serial number
        SetItemQtyToHandleOnWhsPickAction(Item, 1, true, true, LocationRequireWhsePickBinMandatory.Code);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindSet(true);
        WarehouseActivityLine.Validate("Serial No.", SerialNo1);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Serial No.", SerialNo1);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Serial No.", SerialNo2);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Serial No.", SerialNo2);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Qty. to Handle", 0);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Qty. to Handle", 0);
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Register pick
        RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePickBinMandatory.Code, false);

        // [WHEN] Picked quantities are transferred to the journal and posted
        JobPlanningLine.Find();
        JobPlanningLine.Validate("Qty. to Transfer to Journal", 2);
        JobPlanningLine.Modify(true);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [THEN] Posting runs without errors
        OpenRelatedJournalAndPost(JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('JobTransferFromJobPlanLineHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandlerTrue,WhseSrcCreateDocReqHandler')]
    [Scope('OnPrem')]
    procedure CannotTransferPartialTrackedQtyToJobJournal()
    var
        ItemSNAll: Record Item;
        ItemSNWMS: Record Item;
        ItemNegAdj: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobPlanningLine3: Record "Job Planning Line";
        JobPlanningLine4: Record "Job Planning Line";
        JobPlanningLine5: Record "Job Planning Line";
        JobPlanningLine6: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
    begin
        // [FEATURE] 427973 [WMS] Support Item Tracking for Inventory Pick and Warehouse Pick scenarios for Job Planning Lines
        // [SCENARIO] Cannot transfer to job journal for lower quantity than the SN tracked quantity for a job planning line

        // [GIVEN] Job planning line with ItemSNAll Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemSNWMS Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemNegAdj Location LocationRequireWhsePick
        // [GIVEN] Job planning line with ItemSNAll Location LocationRequireWhsePickBinMandatory WhseBin1
        // [GIVEN] Job planning line with ItemSNWMS Location LocationRequireWhsePickBinMandatory WhseBin1
        // [GIVEN] Job planning line with ItemNegAdj Location LocationRequireWhsePickBinMandatory WhseBin1
        Initialize();
        CreateSerialTrackedItem(ItemSNAll, false);
        CreateSerialTrackedItem(ItemSNWMS, true);
        CreateNegAdjTrackedItemWithSN(ItemNegAdj);
        QtyInventory := 2;

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin1.Code, QtyInventory, LibraryRandom.RandDec(10, 2));

        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNAll."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemSNWMS."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemNegAdj."No.", LocationRequireWhsePick.Code, '', QtyInventory, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 6 Job Planning Lines for Job Task T1, Line Type = Budget, Bin = WhseBin2 for location with bin mandatory.
        CreateJobPlanningLineWithData(JobPlanningLine1, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine1.Type::Item, ItemSNAll."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine2, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine2.Type::Item, ItemSNWMS."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine3, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine3.Type::Item, ItemNegAdj."No.", LocationRequireWhsePickBinMandatory.Code, WhseBin2.Code, QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine4, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine4.Type::Item, ItemSNAll."No.", LocationRequireWhsePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine5, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine5.Type::Item, ItemSNWMS."No.", LocationRequireWhsePick.Code, '', QtyInventory);
        CreateJobPlanningLineWithData(JobPlanningLine6, JobTask, "Job Planning Line Line Type"::Budget, JobPlanningLine6.Type::Item, ItemNegAdj."No.", LocationRequireWhsePick.Code, '', QtyInventory);

        // [GIVEN] Serial numbers are assigned on all the Job planning lines
        // [GIVEN] 'Item Tracking Lines' is opened for Job Planning Line and serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignMultiple);
        LibraryVariableStorage.Enqueue(QtyInventory);
        LibraryVariableStorage.Enqueue(ItemSNAll."No.");
        LibraryVariableStorage.Enqueue(LocationRequireWhsePickBinMandatory.Code);
        JobPlanningLine1.OpenItemTrackingLines();

        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignMultiple);
        LibraryVariableStorage.Enqueue(QtyInventory);
        LibraryVariableStorage.Enqueue(ItemSNWMS."No.");
        LibraryVariableStorage.Enqueue(LocationRequireWhsePickBinMandatory.Code);
        JobPlanningLine2.OpenItemTrackingLines();

        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignMultiple);
        LibraryVariableStorage.Enqueue(QtyInventory);
        LibraryVariableStorage.Enqueue(ItemNegAdj."No.");
        LibraryVariableStorage.Enqueue(LocationRequireWhsePickBinMandatory.Code);
        JobPlanningLine3.OpenItemTrackingLines();

        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine4.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine5.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine6.OpenItemTrackingLines();

        // [GIVEN] Warehouse Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [THEN] Serial Numbers are assigned on all the lines (Take and Pick lines).
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2|%3', ItemSNAll."No.", ItemSNWMS."No.", ItemNegAdj."No.");
        WarehouseActivityLine.SetFilter("Serial No.", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, (2 * (JobPlanningLine1.Quantity + JobPlanningLine2.Quantity + JobPlanningLine3.Quantity)) + JobPlanningLine4.Quantity + JobPlanningLine5.Quantity + JobPlanningLine6.Quantity);

        // [WHEN] Set Qty. To Handle to 0
        SetItemQtyToHandleOnWhsActLine(ItemSNAll, 0);
        SetItemQtyToHandleOnWhsActLine(ItemSNWMS, 0);
        SetItemQtyToHandleOnWhsActLine(ItemNegAdj, 0);

        // [WHEN] Handle 1 SN for each item in LocationWithRequirePickBinMandatory.
        SetItemQtyToHandleOnWhsPickAction(ItemSNAll, 1, true, true, LocationRequireWhsePickBinMandatory.Code);
        SetItemQtyToHandleOnWhsPickAction(ItemSNWMS, 1, true, true, LocationRequireWhsePickBinMandatory.Code);
        SetItemQtyToHandleOnWhsPickAction(ItemNegAdj, 1, true, true, LocationRequireWhsePickBinMandatory.Code);

        // [WHEN] Handle 1 SN for each item in LocationWithRequirePick.
        SetItemQtyToHandleOnWhsPickAction(ItemSNAll, 1, false, false, LocationRequireWhsePick.Code);
        SetItemQtyToHandleOnWhsPickAction(ItemSNWMS, 1, false, false, LocationRequireWhsePick.Code);
        SetItemQtyToHandleOnWhsPickAction(ItemNegAdj, 1, false, false, LocationRequireWhsePick.Code);

        // [WHEN] Register Warehouse Pick for LocationRequireWhsePickBinMandatory
        RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePickBinMandatory.Code, false);

        // [WHEN] Register Warehouse Pick for LocationRequireWhsePick
        RegisterWarehousePickFromPage(Job."No.", LocationRequireWhsePick.Code, false);

        // [THEN] Quantity to Handle is updated to 1 on Reservation Entries
        VerifyReservationEntry(JobPlanningLine1, 2, -1, -2, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine2, 2, -1, -2, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine3, 2, -1, -2, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine4, 2, -1, -2, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine5, 2, -1, -2, ReservationStatus::Surplus);
        VerifyReservationEntry(JobPlanningLine6, 2, -1, -2, ReservationStatus::Surplus);

        // [WHEN] Transfer Job Planning Lines with SN specific tracking to the Job Journal Lines
        JobPlanningLine1.Find();
        JobPlanningLine1.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine1.Modify(true);
        asserterror TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);

        // [THEN] Error is thrown to adjust the item tracking or reenter the correct quantity
        Assert.ExpectedError('must adjust the existing item tracking');

        JobPlanningLine2.Find();
        JobPlanningLine2.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine2.Modify(true);
        asserterror TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);

        // [THEN] Error is thrown to adjust the item tracking or reenter the correct quantity
        Assert.ExpectedError('must adjust the existing item tracking');

        JobPlanningLine4.Find();
        JobPlanningLine4.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine4.Modify(true);
        asserterror TransferToJobJournalFromJobPlanningLine(JobPlanningLine4);

        // [THEN] Error is thrown to adjust the item tracking or reenter the correct quantity
        Assert.ExpectedError('must adjust the existing item tracking');

        JobPlanningLine5.Find();
        JobPlanningLine5.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine5.Modify(true);
        asserterror TransferToJobJournalFromJobPlanningLine(JobPlanningLine5);

        // [THEN] Error is thrown to adjust the item tracking or reenter the correct quantity
        Assert.ExpectedError('must adjust the existing item tracking');

        // [WHEN] Transfer Job Planning Lines with Non SN specific tracking to the Job Journal Lines
        JobPlanningLine3.Find();
        JobPlanningLine3.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine3.Modify(true);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine3);

        JobPlanningLine6.Find();
        JobPlanningLine6.Validate("Qty. to Transfer to Journal", 1);
        JobPlanningLine6.Modify(true);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine6);

        // [THEN] 1 Reservation entry per job planning line (total = 2) is copied to Job Journal Line.
        ReservationEntry.SetRange("Item No.", ItemNegAdj."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        Assert.RecordCount(ReservationEntry, 2);

        // [WHEN] Job Journal is posted for the job.
        OpenRelatedJournalAndPost(JobPlanningLine3);
        OpenRelatedJournalAndPost(JobPlanningLine6);

        // [THEN] Prospect Reservation entries are deleted.
        ReservationEntry.SetRange("Item No.", ItemNegAdj."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        Assert.RecordCount(ReservationEntry, 0);

        // [THEN] There is one remaining reservation entry for Negative Adj. Item per job planning line (total = 2)
        ReservationEntry.SetRange("Item No.", ItemNegAdj."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        Assert.RecordCount(ReservationEntry, 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure ErrorWhenDeletingJobWithItemTrackingLinesAndDecliningItemTrackingDeletionOption()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [SCENARIO] When deleting a job with associated item tracking lines, a dialog asking if you want to delete
        // the item tracking lines appears. Rejecting this should result in an error with no deletion occuring.
        Initialize();
        CreateSerialTrackedItem(Item, false);
        CreateAndPostInvtAdjustmentWithSNTracking(Item."No.", LocationWithRequirePick.Code, '', 10, 1);

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(
            JobPlanningLine,
            JobTask,
            "Job Planning Line Line Type"::Budget,
            JobPlanningLine.Type::Item,
            Item."No.",
            LocationWithRequirePick.Code,
            '',
            2
        );

        // [GIVEN] Create Inventory Pick for the Job
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine.OpenItemTrackingLines(); // ItemTrackingLinesAssignPageHandler

        // [WHEN] Deleting job and rejecting delete item tracking dialog.
        asserterror Job.Delete(true);

        // [THEN] An error is thrown.
        Assert.ExpectedError('Item tracking is defined for item');

        // [THEN] Reservation Entries are not deleted.
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", JobPlanningLine."Job No.");
        ReservationEntry.SetRange("Item No.", JobPlanningLine."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordCount(ReservationEntry, 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobItemTrackingLinesDeletedWhenAcceptingItemTrackingDeletionOption()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [SCENARIO] When deleting a job with associated item tracking lines, a dialog asking if you want to delete
        // the item tracking lines appears. Accepting this should result in the job and item tracking lines being deleted.
        Initialize();
        CreateSerialTrackedItem(Item, false);
        CreateAndPostInvtAdjustmentWithSNTracking(Item."No.", LocationWithRequirePick.Code, '', 10, 1);

        // [GIVEN] A Job with both the items in the planning lines
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create job tasks and a Job Planning Line
        // [GIVEN] Job Planning Line for Job Task T1: Type = SerialTrackedItem, Line Type = Budget
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithData(
            JobPlanningLine,
            JobTask,
            "Job Planning Line Line Type"::Budget,
            JobPlanningLine.Type::Item,
            Item."No.",
            LocationWithRequirePick.Code,
            '',
            2
        );

        // [GIVEN] Create Inventory Pick for the Job
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobPlanningLine.OpenItemTrackingLines(); // ItemTrackingLinesAssignPageHandler

        // [WHEN] Deleting job and accepting delete item tracking dialog.
        Job.Delete(true);

        // [THEN] Reservation Entries are deleted.
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", JobPlanningLine."Job No.");
        ReservationEntry.SetRange("Item No.", JobPlanningLine."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferToSalesInvoiceRequestPageHandler,MessageHandler,JobTransferFromJobPlanLineHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure S455935_PostJobJournalPartiallyForSerialItemTracking()
    var
        SerialTrackedItem: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // [FEATURE] [Serial Item Tracking] [Job] [Job Planning Line] [Sales Invoice] [Job Journal]
        // [SCENARIO 455935] "Job Journal" created from "Job Planning Lines" can be posted after serial numbers are assigned.
        Initialize();

        // [GIVEN] Create serial tracked Item.
        CreateSerialTrackedItem(SerialTrackedItem, false);

        // [GIVEN] Create Location without WMS.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post positive adjustment of 10 serial numbers of Item to Location.
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", Location.Code, '', 10, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with "Apply Usage Link".
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create Job Task.
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line for Job Task: Type = Item, No. = SerialTrackedItem, Line Type = "Both Budget and Billable", Quantity = 3.
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, SerialTrackedItem."No.", Location.Code, '', 3);

        // [GIVEN] Create and post Sales Invoice from Job Planning Lines.
        CreateAndPostSalesInvoiceFromJobPlanningLine(JobPlanningLine);

        // [GIVEN] Transfer Job Planning Lines to Job Journal.
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [GIVEN] Set serial numbers in Job Journal Line for Item.
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select); // ItemTrackingSummaryPageHandler
        JobJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post Job Journal Line for Job Planning Line.
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Verify that there are 3 Job Ledger Entries with "Serial No." values.
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.SetFilter("Serial No.", '<>%1', '');
        Assert.RecordCount(JobLedgerEntry, 3);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayPickMvmtRequestPageHandler,ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RegisterInventoryPickForJobWithSNTrackedItemAndMultipleBins()
    var
        ItemAll: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationStatus: Enum "Reservation Status";
        QtyInventory: Integer;
        QtyToHandle: Integer;
        counter: Integer;
    begin
        // [SCENARIO 498962]  No Error Message when regestering an Inventory Pick from a Job if the item has Serial tracking and the number of Tracking is greater than 1
        Initialize();

        // [GIVEN] Create Serial Tracked Item
        CreateSerialTrackedItem(ItemAll, true);

        // [GIVEN] Set Inventory and Qty. to Handle to 3
        QtyInventory := 3;
        QtyToHandle := 3;

        // [GIVEN] Create Inventory upto 3 in different Bins
        CreateAndPostInvtAdjustmentWithSNTracking(ItemAll."No.", LocationWithRequirePickBinMandatory.Code, Bin1.Code, 1, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemAll."No.", LocationWithRequirePickBinMandatory.Code, Bin2.Code, 1, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithSNTracking(ItemAll."No.", LocationWithRequirePickBinMandatory.Code, Bin3.Code, 1, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with job tasks
        CreateJobWithJobTask(JobTask);

        // [GIVEN] 2 Job Planning Lines for Job Task T1, Line Type = Budget
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, ItemAll."No.", LocationWithRequirePickBinMandatory.Code, '', QtyInventory);

        // [WHEN] 'Item Tracking Lines' is opened for Job Planning Line and Serial numbers are assigned
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignMultiple);
        LibraryVariableStorage.Enqueue(QtyInventory);
        LibraryVariableStorage.Enqueue(ItemAll."No.");
        LibraryVariableStorage.Enqueue(LocationWithRequirePickBinMandatory.Code);
        JobPlanningLine.OpenItemTrackingLines();

        // [GIVEN] Inventory Picks are created for the job.
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateInventoryPick(Job);

        // [WHEN] Inventory Pick lines are handled for ItemAll at LocationWithRequirePickBinMandatory
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Item No.", ItemAll."No.");
        WarehouseActivityLine.SetRange("Location Code", LocationWithRequirePickBinMandatory.Code);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", 1);
            WarehouseActivityLine.Modify(true);
            WarehouseActivityLine.Next();
            counter += 1;
        until counter = QtyToHandle;

        // [WHEN] Inventory Picks is posted for LocationWithRequirePickBinMandatory
        PostInventoryPickFromPage(Job."No.", LocationWithRequirePickBinMandatory.Code, false);

        // [THEN] No error is thrown and remaining Reservation entry exists with status as Surplus.
        VerifyReservationEntry(JobPlanningLine, QtyInventory - QtyToHandle, -1, ReservationStatus::Surplus);

        // [THEN] Intermediate entry with reservation status "Prospect" should not exist after posting Job Journal Line.
        VerifyReservationEntry(JobPlanningLine, 0, 0, ReservationStatus::Prospect);
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Inv. Pick On Job Planning");
        LibrarySetupStorage.Restore();
        LibraryJob.DeleteJobJournalTemplate();
        LibraryVariableStorage.Clear();

        if not IsInitialized then begin
            // Location Setup for Inventory Pick
            LibraryWarehouse.CreateLocationWMS(LocationWithRequirePickBinMandatory, true, false, true, false, false);
            LibraryWarehouse.CreateBin(Bin1, LocationWithRequirePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(Bin1.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateBin(Bin2, LocationWithRequirePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(Bin2.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateBin(Bin3, LocationWithRequirePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(Bin3.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateLocationWMS(LocationWithRequirePick, false, false, true, false, false);
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWithRequirePick.Code, false);

            // Location Setup for Warehouse Pick
            LibraryWarehouse.CreateLocationWMS(LocationRequireWhsePickBinMandatory, true, false, true, false, true);
            LibraryWarehouse.CreateBin(WhseBin1, LocationRequireWhsePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(WhseBin1.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateBin(WhseBin2, LocationRequireWhsePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(WhseBin2.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateBin(WhseBin3, LocationRequireWhsePickBinMandatory.Code, LibraryUtility.GenerateRandomCode(WhseBin3.FieldNo(Code), Database::Bin), '', '');
            LibraryWarehouse.CreateLocationWMS(LocationRequireWhsePick, false, false, true, false, true);
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRequireWhsePickBinMandatory.Code, false);
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRequireWhsePick.Code, false);
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
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
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

    local procedure GetUnassignedSerialNo(Item: Record Item): Code[50]
    begin
        exit(GetUnassignedSerialNo(Item, ''));
    end;

    local procedure GetUnassignedSerialNo(Item: Record Item; LocationCode: Code[10]): Code[50]
    var
        SerialNos: DotNet ArrayList;
    begin
        SerialNos := SerialNos.ArrayList();

        GetUnassignedSerialNos(Item."No.", LocationCode, 1, SerialNos);
        exit(SerialNos.Item(0));
    end;

    local procedure GetUnassignedSerialNos(ItemNo: Code[20]; LocationCode: Code[10]; HowMany: Integer; SerialNos: DotNet ArrayList)
    var
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoOfNos: Integer;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Quantity, 1);
        if LocationCode <> '' then
            ItemLedgerEntry.SetRange("Location Code", LocationCode);
        if ItemLedgerEntry.FindSet() then begin
            ReservationEntry.SetRange("Item No.", ItemNo);
            repeat
                ReservationEntry.SetRange("Serial No.", ItemLedgerEntry."Serial No.");
                if ReservationEntry.IsEmpty then begin
                    SerialNos.Add(ItemLedgerEntry."Serial No.");
                    NoOfNos += 1;
                    if NoOfNos >= HowMany then
                        exit;
                end;
            until ItemLedgerEntry.Next() = 0;
        end;
    end;

    local procedure GetUnassignedLotNo(Item: Record Item; LocationCode: Code[10]): Code[50]
    var
        LotNos: DotNet ArrayList;
    begin
        LotNos := LotNos.ArrayList();

        GetUnassignedLotNos(Item."No.", LocationCode, 1, LotNos);
        exit(LotNos.Item(0));
    end;

    local procedure GetUnassignedLotNos(ItemNo: Code[20]; LocationCode: Code[10]; HowMany: Integer; LotNos: DotNet ArrayList)
    var
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NoOfNos: Integer;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        if LocationCode <> '' then
            ItemLedgerEntry.SetRange("Location Code", LocationCode);
        if ItemLedgerEntry.FindSet() then begin
            ReservationEntry.SetRange("Item No.", ItemNo);
            repeat
                ReservationEntry.SetRange("Lot No.", ItemLedgerEntry."Lot No.");
                if ReservationEntry.IsEmpty then begin
                    LotNos.Add(ItemLedgerEntry."Lot No.");
                    NoOfNos += 1;
                    if NoOfNos >= HowMany then
                        exit;
                end;
            until ItemLedgerEntry.Next() = 0;
        end;
    end;

    local procedure VerifyWhseEntriesAfterRegisterPick(Job: Record Job; JobTask: Record "Job Task"; SNSpecificTracking: Boolean; SourceBin: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Line Type", '%1|%2', JobPlanningLine."Line Type"::Budget, JobPlanningLine."Line Type"::"Both Budget and Billable");
        if JobPlanningLine.FindSet() then
            repeat
                if SNSpecificTracking and (JobPlanningLine."Bin Code" <> '') then
                    VerifyWhseEntryForRegisteredPickWithSN(JobPlanningLine, SourceBin, JobPlanningLine."Bin Code");
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

    local procedure VerifyWhseEntryForRegisteredPickWithSN(JobPlanningLine: Record "Job Planning Line"; SourceBin: Code[20]; DestinationBin: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
        CountSourceBin: Integer;
        CountDestinationBin: Integer;
        WarehouseEntryTotalErr: Label 'Warehouse Entry for the warehouse pick should have %1 entries for %2', Comment = '%1 = 10, %2 = Bine Code';
    begin
        FindWarehouseEntriesForJob(WarehouseEntry, JobPlanningLine);
        Assert.RecordCount(WarehouseEntry, 2 * JobPlanningLine.Quantity); //2 * quantity on the job planning line
        WarehouseEntry.FindSet();
        repeat
            // take from source bin and place it in destination bin.
            case WarehouseEntry."Bin Code" of
                DestinationBin:
                    begin
                        WarehouseEntry.TestField("Bin Code", JobPlanningLine."Bin Code");
                        WarehouseEntry.TestField(Quantity, 1);
                        CountDestinationBin += 1;
                    end;
                SourceBin:
                    begin
                        WarehouseEntry.TestField(Quantity, -1);
                        CountSourceBin += 1;
                    end;
            end;
        until WarehouseEntry.Next() = 0;

        // 2 lines are created for each quantity per job planning line.
        Assert.AreEqual(JobPlanningLine.Quantity, CountSourceBin, StrSubstNo(WarehouseEntryTotalErr, JobPlanningLine.Quantity, SourceBin));
        Assert.AreEqual(JobPlanningLine.Quantity, CountDestinationBin, StrSubstNo(WarehouseEntryTotalErr, JobPlanningLine.Quantity, DestinationBin));
    end;

    local procedure OpenJobAndCreateWarehousePick(Job: Record Job)
    var
        JobCardPage: TestPage "Job Card";
    begin
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage."Create Warehouse Pick".Invoke(); // Needs WhseSrcCreateDocReqHandler
        JobCardPage.Close();
    end;

    // Set quantity to handle for all the warehouse activity lines containing the given item.
    local procedure SetItemQtyToHandleOnWhsActLine(var Item: Record Item; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    // Naive way to Set quantity to handle to 1 for first n warehouse pick action lines containing the given item and Location.
    local procedure SetItemQtyToHandleOnWhsPickAction(var Item: Record Item; NumberOfLines: Integer; ActionTake: Boolean; ActionPlace: Boolean; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ActionType: Enum "Warehouse Action Type";
        Iteration: Integer;
    begin
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindSet();

        if ActionPlace and ActionTake then
            NumberOfLines := 2 * NumberOfLines;
        repeat
            if ActionTake and (WarehouseActivityLine."Action Type" = ActionType::Take) then
                WarehouseActivityLine.Validate("Qty. to Handle", 1);
            if ActionPlace and (WarehouseActivityLine."Action Type" = ActionType::Place) then
                WarehouseActivityLine.Validate("Qty. to Handle", 1);
            if WarehouseActivityLine."Action Type" = ActionType::" " then
                WarehouseActivityLine.Validate("Qty. to Handle", 1);
            if WarehouseActivityLine.Modify(true) then;
            Iteration += 1;
            if Iteration >= NumberOfLines then
                exit;
        until WarehouseActivityLine.Next() = 0;
    end;

    //Reservation entries for every job planning line is matched against reservation entries of every related job journal line.
    local procedure MatchResEntriesAfterTransferToJobJnl(var JobJournalLine: Record "Job Journal Line")
    var
        ResEntryPlanningLine: Record "Reservation Entry";
        ResEntryJobJnlLine: Record "Reservation Entry";
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobJournalLine.FindSet();
        repeat
            Clear(ResEntryPlanningLine);
            ResEntryPlanningLine.SetRange("Source ID", JobJournalLine."Job No.");
            ResEntryPlanningLine.SetRange("Source Type", Database::"Job Planning Line");
            JobPlanningLine.Get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No.");
            ResEntryPlanningLine.SetRange("Source Ref. No.", JobPlanningLine."Job Contract Entry No.");

            Clear(ResEntryJobJnlLine);
            ResEntryJobJnlLine.SetRange("Source ID", 'JOB');
            ResEntryJobJnlLine.SetRange("Source Type", Database::"Job Journal Line");

            ResEntryPlanningLine.FindSet();
            repeat
                ResEntryJobJnlLine.SetRange("Serial No.", ResEntryPlanningLine."Serial No."); //Check for same serial number.
                ResEntryJobJnlLine.SetRange("Reservation Status", ResEntryJobJnlLine."Reservation Status"::Prospect);
                Assert.RecordCount(ResEntryJobJnlLine, 1);
            until ResEntryPlanningLine.Next() = 0;
        until JobJournalLine.Next() = 0;
    end;

    local procedure VerifyReservationEntryQtySum(var JobPlanningLine: Record "Job Planning Line"; ExpectedCount: Integer; ExpectedQtySum: Decimal; ReservationStatus: Enum "Reservation Status")
    var
        ReservationEntry: Record "Reservation Entry";
        ActualQtySum: Decimal;
    begin
        ReservationEntry.SetRange("Item No.", JobPlanningLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", JobPlanningLine."Job No.");
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine."Job Contract Entry No.");
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        Assert.RecordCount(ReservationEntry, ExpectedCount);
        if ExpectedCount > 0 then begin
            ReservationEntry.FindSet();
            repeat
                ActualQtySum += ReservationEntry.Quantity;
            until ReservationEntry.Next() = 0;
            Assert.AreEqual(ExpectedQtySum, ActualQtySum, StrSubstNo('The Sum of Quantity on the Reservation Entries should be equal to %1', ExpectedQtySum));
        end;
    end;

    local procedure VerifyReservationEntry(var JobPlanningLine: Record "Job Planning Line"; ExpectedCount: Integer; ExpectedQty: Decimal; ReservationStatus: Enum "Reservation Status")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", JobPlanningLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", JobPlanningLine."Job No.");
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine."Job Contract Entry No.");
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        Assert.RecordCount(ReservationEntry, ExpectedCount);
        if ExpectedCount > 0 then begin
            ReservationEntry.FindSet();
            repeat
                Assert.AreEqual(ExpectedQty, ReservationEntry.Quantity, StrSubstNo('The Quantity on the Reservation Entry should be equal to %1', ExpectedQty));
            until ReservationEntry.Next() = 0;
        end;
    end;

    local procedure VerifyReservationEntry(var JobPlanningLine: Record "Job Planning Line"; ExpectedCount: Integer; ExpectedQty: Decimal; ExpectedQtyToHandleSum: Decimal; ReservationStatus: Enum "Reservation Status")
    var
        ReservationEntry: Record "Reservation Entry";
        ActualQtyToHandleSum: Decimal;
    begin
        ReservationEntry.SetRange("Item No.", JobPlanningLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", JobPlanningLine."Job No.");
        ReservationEntry.SetRange("Source Ref. No.", JobPlanningLine."Job Contract Entry No.");
        Assert.RecordCount(ReservationEntry, ExpectedCount);
        if ExpectedCount > 0 then begin
            ReservationEntry.FindSet();
            repeat
                Assert.AreEqual(ExpectedQty, ReservationEntry.Quantity, StrSubstNo('The Quantity on the Reservation Entry should be equal to %1', ExpectedQty));
                ReservationEntry.TestField("Reservation Status", ReservationStatus);
                ActualQtyToHandleSum += ReservationEntry."Qty. to Handle (Base)";
            until ReservationEntry.Next() = 0;
            Assert.AreEqual(ExpectedQtyToHandleSum, ActualQtyToHandleSum, StrSubstNo('Quantity to handle on the Reservation Entry should be equal to %1', ExpectedQtyToHandleSum));
        end;
    end;

    local procedure VerifyReservationEntry(var JobJournalLine: Record "Job Journal Line"; ExpectedCount: Integer; ExpectedQty: Decimal; ReservationStatus: Enum "Reservation Status")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", JobJournalLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Job Journal Line");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetRange("Source ID", 'JOB'); //TODO: Correct this.
        ReservationEntry.SetRange("Source Ref. No.", JobJournalLine."Line No.");
        Assert.RecordCount(ReservationEntry, ExpectedCount);
        if ExpectedCount > 0 then begin
            ReservationEntry.FindSet();
            repeat
                Assert.AreEqual(ExpectedQty, ReservationEntry.Quantity, StrSubstNo('The Quantity on the Reservation Entry should be equal to %1', ExpectedQty));
                ReservationEntry.TestField("Reservation Status", ReservationStatus);
            until ReservationEntry.Next() = 0;
        end;
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
    procedure JobTransferToSalesInvoiceReqHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.CreateNewInvoice.SetValue(true);
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    local procedure PostInventoryPickFromPage(JobNo: Code[20]; LocationCode: Code[10]; AutoFillQtyToHandle: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", JobNo);
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);
        if AutoFillQtyToHandle then
            InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke(); //Needs confirmation handler
    end;

    local procedure SplitAndPostInventoryPickFromPage(JobNo: Code[20]; LocationCode: Code[10]; AutoFillQtyToHandle: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", JobNo);
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);

        //Split all the lines
        InventoryPickPage.WhseActivityLines.First();
        repeat
            InventoryPickPage.WhseActivityLines."Qty. to Handle".SetValue(1);
            if InventoryPickPage.WhseActivityLines.Quantity.AsDecimal() > 1 then
                InventoryPickPage.WhseActivityLines.SplitWhseActivityLine.Invoke();
        until InventoryPickPage.WhseActivityLines.Next() = false;

        if AutoFillQtyToHandle then
            InventoryPickPage.AutofillQtyToHandle.Invoke();
        InventoryPickPage."P&ost".Invoke(); //Needs confirmation handler
    end;

    local procedure SplitFirstLineInInvPickPage(JobNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        InventoryPickPage: TestPage "Inventory Pick";
    begin
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityHeader.SetRange("Source No.", JobNo);
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        InventoryPickPage.OpenEdit();
        InventoryPickPage.GoToRecord(WarehouseActivityHeader);

        //Split all the lines
        InventoryPickPage.WhseActivityLines.First();
        InventoryPickPage.WhseActivityLines."Qty. to Handle".SetValue(1);
        InventoryPickPage.WhseActivityLines.SplitWhseActivityLine.Invoke();
    end;

    local procedure RegisterWarehousePickFromPage(JobNo: Code[20]; LocationCode: Code[10]; AutoFillQtyToHandle: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePickPage: TestPage "Warehouse Pick";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Job Usage");
        WarehouseActivityLine.SetRange("Source No.", JobNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        WarehousePickPage.OpenEdit();
        WarehousePickPage.GoToRecord(WarehouseActivityHeader);
        if AutoFillQtyToHandle then
            WarehousePickPage."Autofill Qty. to Handle".Invoke();
        WarehousePickPage.RegisterPick.Invoke(); //Needs confirmation handler
    end;

    local procedure CreateJobJournalAssignTrackingInfoAndPost(JobTask: Record "Job Task"; ItemNos: DotNet ArrayList; Qtys: DotNet ArrayList)
    var
        JobJournalPage: TestPage "Job Journal";
        I: Integer;
    begin
        if ItemNos.Count = 0 then
            exit;
        if ItemNos.Count <> Qtys.Count then
            Error('Number of ItemNos elements should be equal to number of Qtys array');

        CreateJobJournalAndAssignTrackingInfo(JobJournalPage, JobTask, ItemNos.Item(0), Qtys.Item(0));
        for I := 1 to ItemNos.Count - 1 do
            AddJobJournalAndAssignTrackingInfo(JobJournalPage, JobTask, ItemNos.Item(i), Qtys.Item(i));

        JobJournalPage."P&ost".Invoke(); //Needs ConfirmHandlerTrue, MessageHandler
        JobJournalPage.Close();
    end;

    local procedure CreateJobJournalAndAssignTrackingInfo(var JobJournalPage: TestPage "Job Journal"; JobTask: Record "Job Task"; ItemNo: Code[10]; Qty: Integer)
    begin
        JobJournalPage.OpenEdit();
        JobJournalPage.New();
        JobJournalPage."Job No.".SetValue(JobTask."Job No.");
        JobJournalPage."Job Task No.".SetValue(JobTask."Job Task No.");
        JobJournalPage."Line Type".SetValue("Job Line Type"::Budget);
        JobJournalPage.Type.SetValue("Job Journal Line Type"::Item);
        JobJournalPage."No.".SetValue(ItemNo);
        JobJournalPage.Quantity.SetValue(Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobJournalPage.ItemTrackingLines.Invoke();
    end;

    local procedure AddJobJournalAndAssignTrackingInfo(var JobJournalPage: TestPage "Job Journal"; JobTask: Record "Job Task"; ItemNo: Code[10]; Qty: Integer)
    begin
        JobJournalPage.New();
        JobJournalPage."Job No.".SetValue(JobTask."Job No.");
        JobJournalPage."Job Task No.".SetValue(JobTask."Job Task No.");
        JobJournalPage."Line Type".SetValue("Job Line Type"::Budget);
        JobJournalPage.Type.SetValue("Job Journal Line Type"::Item);
        JobJournalPage."No.".SetValue(ItemNo);
        JobJournalPage.Quantity.SetValue(Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select);
        JobJournalPage.ItemTrackingLines.Invoke();
    end;

    local procedure OpenJobAndCreateInventoryPick(Job: Record Job)
    var
        JobCardPage: TestPage "Job Card";
    begin
        Commit();
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage."Create Inventory Pick".Invoke(); //Needs MessageHandler
        JobCardPage.Close();
    end;

    local procedure CreateDefaultWarehouseEmployee(var NewDefaultLocation: Record Location)
    var
        WarehouseEmp: Record "Warehouse Employee";
    begin
        WarehouseEmp.SetRange(Default, true);
        if WarehouseEmp.FindFirst() then begin
            if WarehouseEmp."Location Code" <> NewDefaultLocation.Code then begin
                WarehouseEmp.Delete(true);
                LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmp, NewDefaultLocation.Code, true);
            end;
        end
        else
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmp, NewDefaultLocation.Code, true);
    end;

    local procedure CreateSerialTrackedItem(var Item: Record Item; WMSSpecific: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateSerialItem(Item);
        if not WMSSpecific then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            ItemTrackingCode.Validate("SN Warehouse Tracking", false);
            ItemTrackingCode.Modify(true);
        end;
    end;

    local procedure CreateLotTrackedItem(var Item: Record Item; WMSSpecific: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateLotItem(Item);
        if not WMSSpecific then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            ItemTrackingCode.Validate("Lot Warehouse Tracking", false);
            ItemTrackingCode.Modify(true);
        end;
    end;

    local procedure CreateNegAdjTrackedItemWithSN(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("SN Neg. Adjmt. Inb. Tracking", true);
        ItemTrackingCode.Validate("SN Neg. Adjmt. Outb. Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateNegAdjTrackedItemWithLot(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Neg. Adjmt. Inb. Tracking", true);
        ItemTrackingCode.Validate("Lot Neg. Adjmt. Outb. Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; DocumentNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20]): Boolean
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Job No.", JobNo);
        ItemLedgerEntry.SetRange("Job Task No.", JobTaskNo);
        exit(ItemLedgerEntry.FindFirst());
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

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; ConsumableType: Enum "Job Planning Line Type"; JobTask: Record "Job Task"; No: Code[20]; Quantity: Decimal; UnitCost: Decimal; UnitPrice: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Validate("Unit Cost", UnitCost);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);
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

    local procedure CreateJobPlanningLineWithData(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; Number: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
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

    local procedure CreateAndPostSalesInvoiceFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; JobNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure CreateAndPostInvtAdjustmentWithSNTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Assign);
        ItemJournalLine.OpenItemTrackingLines(false); //ItemTrackingSummaryPageHandler required.
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostInvtAdjustmentWithLotTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignLot);
        ItemJournalLine.OpenItemTrackingLines(false); //ItemTrackingSummaryPageHandler required.
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostInvtAdjustment(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNos: DotNet ArrayList;
        ActionOption: Integer;
        SerialNo: Text;
        LotNo: Text;
        ItemNo: Code[20];
        LocationCode: Code[10];
        HowMany: Integer;
    begin
        ActionOption := LibraryVariableStorage.DequeueInteger();
        case ActionOption of
            ItemTrackingHandlerAction::Assign:
                ItemTrackingLines."Assign &Serial No.".Invoke(); // AssignSerialNoEnterQtyPageHandler required.
            ItemTrackingHandlerAction::AssignLot:
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingHandlerAction::AssignSpecific:
                begin
                    SerialNo := LibraryVariableStorage.DequeueText();
                    ItemTrackingLines.First();
                    ItemTrackingLines."Serial No.".SetValue(SerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                end;
            ItemTrackingHandlerAction::AssignSpecificLot:
                begin
                    LotNo := LibraryVariableStorage.DequeueText();
                    ItemTrackingLines.Last();
                    if ItemTrackingLines.Next() then; //Assign the lot number at the end.
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingHandlerAction::Select:
                ItemTrackingLines."Select Entries".Invoke(); // ItemTrackingSummaryPageHandler
            ItemTrackingHandlerAction::NothingToHandle:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(0);
                end;
            ItemTrackingHandlerAction::SelectWithQtyToHandle:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.First();
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueInteger());
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueInteger());
                end;
            ItemTrackingHandlerAction::ChangeSelection:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                end;
            ItemTrackingHandlerAction::ChangeSelectionLot:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                end;
            ItemTrackingHandlerAction::ChangeSelectionLotLast:
                begin
                    ItemTrackingLines.Last();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                end;
            ItemTrackingHandlerAction::ChangeSelectionQty:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueText());
                end;
            ItemTrackingHandlerAction::AssignMultiple:
                begin
                    HowMany := LibraryVariableStorage.DequeueInteger();
                    ItemNo := LibraryVariableStorage.DequeueText();
                    LocationCode := LibraryVariableStorage.DequeueText();
                    SerialNos := SerialNos.ArrayList();
                    GetUnassignedSerialNos(ItemNo, LocationCode, HowMany, SerialNos);
                    ItemTrackingLines.First();
                    foreach SerialNo in SerialNos do begin
                        ItemTrackingLines."Serial No.".SetValue(SerialNo);
                        ItemTrackingLines."Quantity (Base)".SetValue(1);
                        ItemTrackingLines."Qty. to Handle (Base)".SetValue(1);
                        ItemTrackingLines.Next();
                    end;
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesModalPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        SerialNo: Code[20];
    begin
        SerialNo := LibraryVariableStorage.DequeueText();
        PostedItemTrackingLines.First();
        PostedItemTrackingLines."Serial No.".AssertEquals(SerialNo);
        PostedItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignSerialNoEnterQtyPageHandler(var EnterQuantityPage: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPutawayPickMvmtRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;
}
